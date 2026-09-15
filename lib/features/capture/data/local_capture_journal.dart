import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';
import 'package:path/path.dart' as p;

/// 异步互斥锁，确保同一实例内文件读写操作按 FIFO 顺序串行执行。
class _AsyncLock {
  Future<void>? _lastOperation;

  Future<T> synchronized<T>(Future<T> Function() action) {
    final previous = _lastOperation;
    final completer = Completer<void>();
    _lastOperation = completer.future;

    return Future.sync(() async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      return await action();
    }).whenComplete(() {
      completer.complete();
    });
  }
}

/// 基于本地 JSON 文件的采集草稿日志持久化实现。
///
/// 具备：
/// - 写入时原子写与覆盖（先写入 `.tmp`，flush 后通过 rename 原子覆盖）；
/// - 崩溃恢复与损坏容错（主文件损坏时尝试从 `.tmp` 恢复或清理）；
/// - 严格乐观并发控制（CAS，基于 revision 校验）；
/// - 活跃草稿多维度查询与归属过滤。
class LocalCaptureJournal implements CaptureJournalPort {
  /// 默认日志文件名。
  static const String defaultFileName = 'capture_journal.json';

  /// 临时写入文件后缀。
  static const String tempSuffix = '.tmp';

  /// 存储目录。
  final Directory storageDirectory;

  /// 日志文件名。
  final String fileName;

  final _AsyncLock _lock = _AsyncLock();

  LocalCaptureJournal(this.storageDirectory, {this.fileName = defaultFileName});

  /// 主日志文件绝对路径。
  String get mainFilePath => p.join(storageDirectory.path, fileName);

  /// 临时写入文件绝对路径。
  String get tmpFilePath =>
      p.join(storageDirectory.path, '$fileName$tempSuffix');

  @override
  Future<void> writeDraft(CaptureDraft draft) {
    return _lock.synchronized(() async {
      final drafts = await _loadDraftsLocked();
      final existing = drafts[draft.taskId];

      if (existing == null) {
        if (draft.revision != 1) {
          throw CaptureCasConflictException(
            taskId: draft.taskId,
            expectedRevision: draft.revision - 1,
            actualRevision: null,
            message:
                'Cannot create draft with revision ${draft.revision}, expected 1.',
          );
        }
      } else {
        if (draft.revision == 1) {
          throw CaptureCasConflictException(
            taskId: draft.taskId,
            expectedRevision: 0,
            actualRevision: existing.revision,
            message:
                'Draft already exists with revision ${existing.revision}, cannot overwrite with revision 1.',
          );
        }
        if (existing.revision != draft.revision - 1) {
          throw CaptureCasConflictException(
            taskId: draft.taskId,
            expectedRevision: draft.revision - 1,
            actualRevision: existing.revision,
            message:
                'CAS revision mismatch for taskId ${draft.taskId}: expected ${draft.revision - 1}, but found ${existing.revision}.',
          );
        }
      }

      drafts[draft.taskId] = draft;
      await _persistDraftsLocked(drafts);
    });
  }

  @override
  Future<CaptureDraft?> readDraft(String taskId) {
    return _lock.synchronized(() async {
      final drafts = await _loadDraftsLocked();
      return drafts[taskId];
    });
  }

  @override
  Future<List<CaptureDraft>> listActiveDrafts({
    String? ownerUserId,
    bool onlyUnowned = false,
  }) {
    return _lock.synchronized(() async {
      final drafts = await _loadDraftsLocked();
      return drafts.values.where((draft) {
        if (!draft.isActive) return false;
        if (ownerUserId != null) {
          return draft.ownerContext.ownerUserId == ownerUserId;
        }
        if (onlyUnowned) {
          return draft.ownerContext.ownerUserId == null;
        }
        return true;
      }).toList();
    });
  }

  @override
  Future<void> removeDraft(String taskId) {
    return _lock.synchronized(() async {
      final drafts = await _loadDraftsLocked();
      if (drafts.containsKey(taskId)) {
        drafts.remove(taskId);
        await _persistDraftsLocked(drafts);
      }
    });
  }

  /// 加载草稿并在读取损坏或存在残余 `.tmp` 时进行容错恢复/清理。
  Future<Map<String, CaptureDraft>> _loadDraftsLocked() async {
    final mainFile = File(mainFilePath);
    final tmpFile = File(tmpFilePath);

    final mainExists = await mainFile.exists();
    final tmpExists = await tmpFile.exists();

    if (!mainExists && !tmpExists) {
      return <String, CaptureDraft>{};
    }

    if (mainExists) {
      try {
        final content = await mainFile.readAsString();
        final drafts = _parseContent(content);
        // 主文件完整可用，如果存在 .tmp 说明为上次未完成写入遗留，进行清理
        if (tmpExists) {
          try {
            await tmpFile.delete();
          } catch (_) {}
        }
        return drafts;
      } catch (_) {
        // 主文件损坏或解析失败，尝试从 .tmp 恢复
        if (tmpExists) {
          try {
            final tmpContent = await tmpFile.readAsString();
            final drafts = _parseContent(tmpContent);
            // .tmp 文件有效，原子恢复替换主文件
            await _atomicReplace(tmpFile, mainFile);
            return drafts;
          } catch (_) {
            // .tmp 亦损坏，删除无效的 .tmp
            try {
              await tmpFile.delete();
            } catch (_) {}
          }
        }
        return <String, CaptureDraft>{};
      }
    }

    // 主文件不存在，但 .tmp 存在
    if (tmpExists) {
      try {
        final tmpContent = await tmpFile.readAsString();
        final drafts = _parseContent(tmpContent);
        // .tmp 文件有效，恢复为主文件
        await _atomicReplace(tmpFile, mainFile);
        return drafts;
      } catch (_) {
        // 无效 .tmp 清理
        try {
          await tmpFile.delete();
        } catch (_) {}
        return <String, CaptureDraft>{};
      }
    }

    return <String, CaptureDraft>{};
  }

  /// 解析 JSON 文本为 Map<String, CaptureDraft>。
  Map<String, CaptureDraft> _parseContent(String content) {
    if (content.trim().isEmpty) {
      return <String, CaptureDraft>{};
    }
    final decoded = jsonDecode(content);
    final Map<dynamic, dynamic> draftsRaw;
    if (decoded is Map<String, dynamic> && decoded.containsKey('drafts')) {
      final raw = decoded['drafts'];
      draftsRaw = raw is Map ? raw : const {};
    } else if (decoded is Map) {
      draftsRaw = decoded;
    } else {
      throw const FormatException('Invalid journal JSON structure');
    }

    final result = <String, CaptureDraft>{};
    for (final entry in draftsRaw.entries) {
      try {
        final map = Map<String, dynamic>.from(entry.value as Map);
        final draft = CaptureDraft.fromMap(map);
        result[draft.taskId] = draft;
      } catch (_) {
        // 忽略单条损坏记录，确保其余数据可读
      }
    }
    return result;
  }

  /// 持久化草稿：写入 `.tmp` -> flush -> 原子 rename 覆盖。
  Future<void> _persistDraftsLocked(Map<String, CaptureDraft> drafts) async {
    if (!await storageDirectory.exists()) {
      await storageDirectory.create(recursive: true);
    }
    final mainFile = File(mainFilePath);
    final tmpFile = File(tmpFilePath);

    final data = {
      'version': 1,
      'drafts': drafts.map((key, draft) => MapEntry(key, draft.toMap())),
    };
    final jsonString = jsonEncode(data);

    // 1. 写入临时文件并 flush
    await tmpFile.writeAsString(jsonString, flush: true);

    // 2. 原子 rename 覆盖目标主文件
    await _atomicReplace(tmpFile, mainFile);
  }

  /// 跨平台安全原子替换文件。
  Future<void> _atomicReplace(File sourceTmp, File target) async {
    try {
      await sourceTmp.rename(target.path);
    } on FileSystemException {
      // 在部分平台（如 Windows 目标文件已存在或被短暂锁定时），若直接 rename 抛出异常，进行健壮回退
      if (await target.exists()) {
        try {
          await target.delete();
        } catch (_) {}
      }
      try {
        await sourceTmp.rename(target.path);
      } catch (_) {
        await sourceTmp.copy(target.path);
        try {
          await sourceTmp.delete();
        } catch (_) {}
      }
    }
  }
}
