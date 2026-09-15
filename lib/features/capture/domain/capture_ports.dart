import 'package:equatable/equatable.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';

/// 采集提交落库结果实体。
final class CommitResult extends Equatable {
  /// 关联的采集任务 ID。
  final String taskId;

  /// 业务用途（现场照片/费用凭证）。
  final CapturePurpose purpose;

  /// 持久化生成的实体本地 ID（Isar local ID）。
  final int committedId;

  /// 是否为就地更新已有实体（例如编辑已有凭证或替换照片，对应 U290）。
  final bool isUpdate;

  /// 提交落库完成时间。
  final DateTime committedAt;

  /// 提交结果的补充元数据（如最终持久化文件路径等）。
  final Map<String, dynamic> metadata;

  const CommitResult({
    required this.taskId,
    required this.purpose,
    required this.committedId,
    this.isUpdate = false,
    required this.committedAt,
    this.metadata = const {},
  });

  CommitResult copyWith({
    String? taskId,
    CapturePurpose? purpose,
    int? committedId,
    bool? isUpdate,
    DateTime? committedAt,
    Map<String, dynamic>? metadata,
  }) {
    return CommitResult(
      taskId: taskId ?? this.taskId,
      purpose: purpose ?? this.purpose,
      committedId: committedId ?? this.committedId,
      isUpdate: isUpdate ?? this.isUpdate,
      committedAt: committedAt ?? this.committedAt,
      metadata: metadata != null ? Map.unmodifiable(metadata) : this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'purpose': purpose.name,
    'committedId': committedId,
    'isUpdate': isUpdate,
    'committedAt': committedAt.toIso8601String(),
    'metadata': metadata,
  };

  factory CommitResult.fromMap(Map<String, dynamic> map) {
    return CommitResult(
      taskId: map['taskId'] as String,
      purpose: CapturePurpose.values.byName(map['purpose'] as String),
      committedId: (map['committedId'] as num).toInt(),
      isUpdate: map['isUpdate'] as bool? ?? false,
      committedAt: DateTime.parse(map['committedAt'] as String),
      metadata: Map<String, dynamic>.from(
        (map['metadata'] as Map?) ?? const {},
      ),
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    purpose,
    committedId,
    isUpdate,
    committedAt,
    metadata,
  ];
}

/// 乐观并发控制（CAS）写入冲突异常。
class CaptureCasConflictException implements Exception {
  /// 发生冲突的任务 ID。
  final String taskId;

  /// 待写入草稿声明的期望版本。
  final int expectedRevision;

  /// 存储层当前存在的实际版本号（若已不存在或已删除则为 null）。
  final int? actualRevision;

  /// 异常详情描述。
  final String message;

  const CaptureCasConflictException({
    required this.taskId,
    required this.expectedRevision,
    this.actualRevision,
    this.message =
        'Optimistic concurrency CAS conflict occurred while writing capture draft.',
  });

  @override
  String toString() =>
      'CaptureCasConflictException(taskId: $taskId, expectedRevision: $expectedRevision, '
      'actualRevision: $actualRevision, message: $message)';
}

/// 采集设备会话正忙（已被占用）异常。
class AcquisitionBusyException implements Exception {
  /// 异常详情。
  final String message;

  /// 当前持有独占会话的任务 ID（若已知）。
  final String? activeTaskId;

  const AcquisitionBusyException({
    this.message = 'Another capture acquisition session is already active.',
    this.activeTaskId,
  });

  @override
  String toString() =>
      'AcquisitionBusyException(message: $message, activeTaskId: $activeTaskId)';
}

/// 采集提交落库失败异常。
class CaptureCommitException implements Exception {
  /// 任务 ID。
  final String taskId;

  /// 异常说明。
  final String message;

  /// 底层导致失败的原因。
  final Object? cause;

  const CaptureCommitException({
    required this.taskId,
    required this.message,
    this.cause,
  });

  @override
  String toString() =>
      'CaptureCommitException(taskId: $taskId, message: $message, cause: $cause)';
}

/// 采集日志/草稿持久化端口契约。
///
/// 维护采集任务的临时草稿状态机日志，支持基于 revision 的 CAS 乐观并发原子更新，
/// 支撑进程崩溃恢复与多任务跟踪。
abstract interface class CaptureJournalPort {
  /// 基于乐观并发 CAS 版本号原子写入采集草稿。
  ///
  /// 当 [draft.revision] 为 1 时表示新增首版草稿（此时存储层不应存在既有草稿）；
  /// 当 [draft.revision] > 1 时，存储层既有草稿的 revision 必须等于 `draft.revision - 1`。
  /// 若版本不满足预期，必须抛出 [CaptureCasConflictException]。
  Future<void> writeDraft(CaptureDraft draft);

  /// 读取指定任务 ID 的采集草稿。
  ///
  /// 若草稿不存在则返回 `null`。
  Future<CaptureDraft?> readDraft(String taskId);

  /// 查询所有未完成（[CaptureDraft.isActive] 为 true）的活跃草稿。
  ///
  /// [ownerUserId] 可选：
  /// - 若传入指定 ID，仅返回该用户所属的活跃草稿；
  /// - 若传入 `null` 或缺省，可由实现策略决定返回本地无账户或全部活跃草稿。
  Future<List<CaptureDraft>> listActiveDrafts({String? ownerUserId});

  /// 移除已终态或废弃的采集草稿。
  Future<void> removeDraft(String taskId);
}

/// 采集源类型。
enum AcquisitionSource {
  /// 调起设备相机拍照
  camera,

  /// 调起系统相册或文件选择器
  gallery,
}

/// 设备采集抽象端口契约。
///
/// 负责调起系统相机或相册选择器，并维护全局单会话独占，防止并发调起导致系统服务冲突。
abstract interface class AcquisitionPort {
  /// 当前是否已存在活跃的采集独占会话。
  bool get isSessionActive;

  /// 调起设备相机或相册选择器采集图像。
  ///
  /// 全局保证单会话独占；若当前已有未释放的采集会话正在进行，应抛出 [AcquisitionBusyException]。
  /// 采集成功返回临时原始文件路径；用户放弃或取消操作时返回 `null`。
  Future<String?> acquireMedia({
    required String taskId,
    required AcquisitionSource source,
  });

  /// 检索 Android 进程因低内存杀死后遗留的丢失相机采集结果。
  ///
  /// 若无未消费的丢失数据则返回空列表。
  Future<List<String>> retrieveLostData();

  /// 释放或重置当前的采集独占会话锁。
  Future<void> releaseSession({required String taskId});
}

/// 采集沙箱暂存区端口契约。
///
/// 管理采集阶段的临时文件沙箱复制与命名隔离，避免临时原图丢失或产生孤儿文件。
/// 【安全性与硬约束】：
/// - 严禁删除相册原图或外部原始文件！
/// - 清理操作仅限于内部沙箱暂存目录中与任务关联的独占临时文件。
abstract interface class StagingPort {
  /// 将外部临时文件安全复制（Stage）至任务沙箱私有目录，并生成唯一安全文件名。
  ///
  /// 返回暂存后的私有沙箱文件绝对路径。
  /// 此操作仅执行文件复制，绝不修改或删除 [sourcePath] 指向的原图。
  Future<String> stageFile({
    required String taskId,
    required String sourcePath,
    CapturePurpose? purpose,
  });

  /// 批量暂存多个文件至任务私有沙箱。
  Future<List<String>> stageFiles({
    required String taskId,
    required List<String> sourcePaths,
    CapturePurpose? purpose,
  });

  /// 获取指定任务在沙箱暂存区中的所有文件绝对路径。
  Future<List<String>> getStagedFiles(String taskId);

  /// 清理指定任务在沙箱暂存区独占的所有临时文件。
  ///
  /// 仅在沙箱暂存目录下执行清理，绝不触碰相册原图。
  Future<void> clearTaskStaging(String taskId);

  /// 从沙箱暂存区中移除指定的单个暂存文件。
  ///
  /// 实现必须校验 [stagedPath] 确实属于内部沙箱暂存目录，防止越界删除。
  Future<void> removeStagedFile(String stagedPath);
}

/// 采集数据落库持久化端口契约。
///
/// 负责将 [CaptureDraft] 正式写入业务数据库（照片或费用凭证），并提供幂等回查机制，
/// 防止“DB写入成功但日志清理/更新失败”时由于异常重试导致重复落库。
abstract interface class CommitPort {
  /// 将采集草稿正式提交落库并完成持久化存储。
  ///
  /// 若发现该 [draft.taskId] 已落库，应走幂等处理并返回已有记录结果。
  Future<CommitResult> commit(CaptureDraft draft);

  /// 幂等回查：检查指定任务是否已持久化落库。
  ///
  /// 通过 [taskId] 与 [owner] 进行精确匹配回查。
  /// 若已落库则返回对应的 [CommitResult]，若尚未入库则返回 `null`。
  Future<CommitResult?> findCommitted(String taskId, CaptureOwnerContext owner);
}
