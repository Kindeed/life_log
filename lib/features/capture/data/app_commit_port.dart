import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';
import 'package:life_log/features/evidence/application/save_evidence_entry.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';

/// 采集数据落库系统层适配器。
///
/// 串联驱动：
/// - [SavePhotoFromPath]：将暂存照片持久化写入本地照片库，严格保持 `deleteSource: false`，
///   交由 [StagingPort] 统一沙箱生命周期管理；
/// - [SaveEvidenceEntry]：将暂存凭证或草稿持久化入库，通过 [CaptureDraft.editTargetId]
///   区分新增与原地更新（彻底闭环 U290）；
/// - 提供幂等回查机制，防止重复提交。
class AppCommitPort implements CommitPort {
  final SavePhotoFromPath _savePhotoFromPath;
  final SaveEvidenceEntry _saveEvidenceEntry;
  final EvidenceRepositoryPort? _evidenceRepository;
  final Map<String, CommitResult> _committedCache = {};

  AppCommitPort({
    required SavePhotoFromPath savePhotoFromPath,
    required SaveEvidenceEntry saveEvidenceEntry,
    EvidenceRepositoryPort? evidenceRepository,
    Map<String, CommitResult>? initialCache,
  }) : _savePhotoFromPath = savePhotoFromPath,
       _saveEvidenceEntry = saveEvidenceEntry,
       _evidenceRepository = evidenceRepository {
    if (initialCache != null) {
      _committedCache.addAll(initialCache);
    }
  }

  @override
  Future<CommitResult> commit(CaptureDraft draft) async {
    switch (draft.purpose) {
      case CapturePurpose.photo:
        return _commitPhoto(draft);
      case CapturePurpose.evidence:
        return _commitEvidence(draft);
    }
  }

  Future<CommitResult> _commitPhoto(CaptureDraft draft) async {
    if (draft.stagedPaths.isEmpty) {
      throw CaptureCommitException(
        taskId: draft.taskId,
        message: 'No staged photo path found in capture draft.',
      );
    }

    final tempPath = draft.stagedPaths.first;
    final projectName =
        (draft.draftValues['projectName'] as String?)?.trim() ??
        (draft.draftValues['project'] as String?)?.trim() ??
        '';
    final description =
        (draft.draftValues['description'] as String?)?.trim() ??
        (draft.draftValues['desc'] as String?)?.trim() ??
        '';
    final deviceName =
        (draft.draftValues['deviceName'] as String?)?.trim() ?? 'Unknown';
    final capturedAtRaw = draft.draftValues['capturedAt'];
    final DateTime? capturedAt = switch (capturedAtRaw) {
      final DateTime dt => dt,
      final String s => DateTime.tryParse(s),
      _ => null,
    };
    final capturedAtSource = draft.draftValues['capturedAtSource'] as String?;
    final gpsLatitude = (draft.draftValues['gpsLatitude'] as num?)?.toDouble();
    final gpsLongitude = (draft.draftValues['gpsLongitude'] as num?)
        ?.toDouble();

    // 硬约束：deleteSource 必须为 false！
    // 沙箱暂存区源文件由 StagingPort 独占统一安全管理，绝不可在此破坏。
    final result = await _savePhotoFromPath(
      tempPath: tempPath,
      projectName: projectName,
      description: description,
      deviceName: deviceName,
      deleteSource: false,
      capturedAt: capturedAt,
      capturedAtSource: capturedAtSource,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
    );

    final failure = result.failureOrNull;
    if (failure != null) {
      throw CaptureCommitException(
        taskId: draft.taskId,
        message: failure.message,
        cause: failure.cause,
      );
    }

    final entry = result.valueOrNull!;
    final commitResult = CommitResult(
      taskId: draft.taskId,
      purpose: draft.purpose,
      committedId: entry.id,
      isUpdate: draft.editTargetId != null,
      committedAt: DateTime.now(),
      metadata: {
        'fileName': entry.fileName,
        'filePath': entry.filePath,
        'projectName': entry.projectName,
        if (entry.description != null) 'description': entry.description,
      },
    );

    _cacheCommit(draft.taskId, draft.ownerContext, commitResult);
    return commitResult;
  }

  Future<CommitResult> _commitEvidence(CaptureDraft draft) async {
    final stagedPath = draft.stagedPaths.firstOrNull;
    final projectName =
        (draft.draftValues['projectName'] as String?)?.trim() ??
        (draft.draftValues['project'] as String?)?.trim() ??
        '默认项目';

    final amountRaw = draft.draftValues['amount'];
    final double? amount = switch (amountRaw) {
      final num n => n.toDouble(),
      final String s when s.trim().isNotEmpty => double.tryParse(s.trim()),
      _ => null,
    };

    final merchant = (draft.draftValues['merchant'] as String?)?.trim();
    final note =
        (draft.draftValues['note'] as String?)?.trim() ??
        (draft.draftValues['remark'] as String?)?.trim();
    final currency =
        (draft.draftValues['currency'] as String?)?.trim() ?? 'CNY';

    final categoryRaw = draft.draftValues['category'];
    final EvidenceEntryCategory category = switch (categoryRaw) {
      final EvidenceEntryCategory c => c,
      final String name => EvidenceEntryCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase() || c.label == name,
        orElse: () => EvidenceEntryCategory.invoice,
      ),
      _ => EvidenceEntryCategory.invoice,
    };

    final statusRaw = draft.draftValues['status'];
    final EvidenceEntryStatus status = switch (statusRaw) {
      final EvidenceEntryStatus s => s,
      final String name => EvidenceEntryStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == name.toLowerCase() || s.label == name,
        orElse: () => EvidenceEntryStatus.pending,
      ),
      _ => EvidenceEntryStatus.pending,
    };

    final evidenceDateRaw =
        draft.draftValues['evidenceDate'] ?? draft.draftValues['capturedAt'];
    final DateTime evidenceDate = switch (evidenceDateRaw) {
      final DateTime dt => dt,
      final String s => DateTime.tryParse(s) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    final tripDateRaw = draft.draftValues['tripDate'];
    final DateTime? tripDate = switch (tripDateRaw) {
      final DateTime dt => dt,
      final String s => DateTime.tryParse(s),
      _ => null,
    };

    final projectStageName = (draft.draftValues['projectStageName'] as String?)
        ?.trim();
    final projectId =
        draft.projectLocalId ??
        (draft.draftValues['projectId'] as num?)?.toInt();
    final projectSyncId = draft.draftValues['projectSyncId'] as String?;

    final isUpdate = draft.editTargetId != null;
    final entryId = draft.editTargetId ?? 0;

    String? sourceExtension;
    if (stagedPath != null && stagedPath.isNotEmpty) {
      final dotIndex = stagedPath.lastIndexOf('.');
      if (dotIndex >= 0 && dotIndex < stagedPath.length - 1) {
        sourceExtension = stagedPath.substring(dotIndex + 1).toLowerCase();
      }
    }

    final entry = EvidenceEntry(
      id: entryId,
      projectName: projectName,
      projectId: projectId,
      projectSyncId: projectSyncId,
      projectStageName: projectStageName,
      evidenceDate: evidenceDate,
      amount: amount,
      currency: currency,
      category: category,
      status: status,
      merchant: merchant,
      note: note,
      tripDate: tripDate,
    );

    final result = await _saveEvidenceEntry(
      entry,
      markDirty: true,
      sourcePath: stagedPath,
      sourceExtension: sourceExtension,
    );

    final failure = result.failureOrNull;
    if (failure != null) {
      throw CaptureCommitException(
        taskId: draft.taskId,
        message: failure.message,
        cause: failure.cause,
      );
    }

    int committedId = entryId;
    if (committedId == 0 && _evidenceRepository != null) {
      try {
        final entries = await _evidenceRepository.getAllEntries();
        if (entries.isNotEmpty) {
          committedId = entries.last.id;
        }
      } catch (_) {}
    }

    final commitResult = CommitResult(
      taskId: draft.taskId,
      purpose: draft.purpose,
      committedId: committedId,
      isUpdate: isUpdate,
      committedAt: DateTime.now(),
      metadata: {
        'projectName': projectName,
        if (amount != null) 'amount': amount,
        if (stagedPath != null) 'attachmentPath': stagedPath,
        if (merchant != null) 'merchant': merchant,
        if (note != null) 'note': note,
      },
    );

    _cacheCommit(draft.taskId, draft.ownerContext, commitResult);
    return commitResult;
  }

  @override
  Future<CommitResult?> findCommitted(
    String taskId,
    CaptureOwnerContext owner,
  ) async {
    final key = _cacheKey(taskId, owner);
    return _committedCache[key];
  }

  String _cacheKey(String taskId, CaptureOwnerContext owner) =>
      '$taskId:${owner.ownerUserId}:${owner.sessionEpoch}';

  void _cacheCommit(
    String taskId,
    CaptureOwnerContext owner,
    CommitResult result,
  ) {
    _committedCache[_cacheKey(taskId, owner)] = result;
  }
}
