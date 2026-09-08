import 'package:equatable/equatable.dart';

/// 采集目标业务用途。
enum CapturePurpose {
  /// 现场照片
  photo,

  /// 费用凭证
  evidence,
}

/// 采集状态机状态枚举。
enum CaptureState {
  /// 已初始化就绪，等待调起采集
  prepared,

  /// 系统相机或照片/文件选择器处于活跃状态
  pickerActive,

  /// 媒体文件已安全暂存至内部沙箱目录
  staged,

  /// 用户正在编辑元数据（描述、项目、金额等）
  editing,

  /// 正在提交入库
  committing,

  /// 已成功提交入库（终态）
  committed,

  /// 已取消或主动放弃（终态）
  cancelled,

  /// 发生可恢复错误（等待重试或恢复）
  recoverableFailure;

  /// 是否为不可再迁移的终态。
  bool get isTerminal =>
      this == CaptureState.committed || this == CaptureState.cancelled;

  /// 是否为活跃进行中的状态。
  bool get isActive => !isTerminal;

  /// 是否为可恢复错误状态。
  bool get isRecoverable => this == CaptureState.recoverableFailure;
}

/// 采集任务的账户与会话归属上下文。
///
/// 用于在采集生命周期中追踪所有者，并防止在系统选择器或相机前台切换账号时发生交叉写入。
final class CaptureOwnerContext extends Equatable {
  /// 拥有者用户 ID，为 null 时表示当前为本地未登录账户。
  final String? ownerUserId;

  /// 会话纪元序号，用于防止账号切换交叉写入。
  final int sessionEpoch;

  const CaptureOwnerContext({this.ownerUserId, this.sessionEpoch = 0});

  /// 检查是否与另一个归属上下文一致（严格匹配 ownerUserId 与 sessionEpoch）。
  bool matches(CaptureOwnerContext other) =>
      ownerUserId == other.ownerUserId && sessionEpoch == other.sessionEpoch;

  CaptureOwnerContext copyWith({
    String? ownerUserId,
    bool clearOwnerUserId = false,
    int? sessionEpoch,
  }) {
    return CaptureOwnerContext(
      ownerUserId: clearOwnerUserId ? null : (ownerUserId ?? this.ownerUserId),
      sessionEpoch: sessionEpoch ?? this.sessionEpoch,
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerUserId': ownerUserId,
    'sessionEpoch': sessionEpoch,
  };

  factory CaptureOwnerContext.fromMap(Map<String, dynamic> map) {
    return CaptureOwnerContext(
      ownerUserId: map['ownerUserId'] as String?,
      sessionEpoch: (map['sessionEpoch'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [ownerUserId, sessionEpoch];
}

/// 独立采集草稿不可变领域实体。
///
/// 封装完整的采集生命周期状态、归属上下文、暂存路径及乐观并发版本号。
final class CaptureDraft extends Equatable {
  /// 全局唯一任务 ID (UUID)。
  final String taskId;

  /// 账户与会话归属上下文。
  final CaptureOwnerContext ownerContext;

  /// 业务用途（现场照片/费用凭证）。
  final CapturePurpose purpose;

  /// 关联的项目本地 ID（可选）。
  final int? projectLocalId;

  /// 若为编辑既有凭证/照片换图，则包含原记录 ID（解决 U290 进程重启丢失原记录标识问题）。
  final int? editTargetId;

  /// 用户输入的临时草稿值（文本、金额、备注等）。
  final Map<String, dynamic> draftValues;

  /// 暂存至应用私有沙箱内部的媒体文件路径列表（解决原图删除及孤儿文件问题）。
  final List<String> stagedPaths;

  /// 当前采集生命周期状态。
  final CaptureState state;

  /// 乐观并发控制（CAS）版本号，每次变更单调递增。
  final int revision;

  /// 草稿创建时间戳。
  final DateTime createdAt;

  /// 最近更新时间戳。
  final DateTime updatedAt;

  /// 错误或失败原因描述（当处于 [CaptureState.recoverableFailure] 时有效）。
  final String? failureReason;

  const CaptureDraft({
    required this.taskId,
    required this.ownerContext,
    required this.purpose,
    this.projectLocalId,
    this.editTargetId,
    this.draftValues = const {},
    this.stagedPaths = const [],
    this.state = CaptureState.prepared,
    this.revision = 1,
    required this.createdAt,
    required this.updatedAt,
    this.failureReason,
  });

  /// 创建初始草稿的工厂方法。
  factory CaptureDraft.create({
    required String taskId,
    required CaptureOwnerContext ownerContext,
    required CapturePurpose purpose,
    int? projectLocalId,
    int? editTargetId,
    Map<String, dynamic> draftValues = const {},
    List<String> stagedPaths = const [],
    CaptureState state = CaptureState.prepared,
    int revision = 1,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? failureReason,
  }) {
    final now = DateTime.now();
    return CaptureDraft(
      taskId: taskId,
      ownerContext: ownerContext,
      purpose: purpose,
      projectLocalId: projectLocalId,
      editTargetId: editTargetId,
      draftValues: Map.unmodifiable(draftValues),
      stagedPaths: List.unmodifiable(stagedPaths),
      state: state,
      revision: revision,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      failureReason: failureReason,
    );
  }

  /// 是否为终态（已提交或已取消）。
  bool get isTerminal => state.isTerminal;

  /// 是否为进行中活跃草稿。
  bool get isActive => state.isActive;

  /// 是否处于可恢复错误状态。
  bool get isRecoverable => state.isRecoverable;

  /// 检查是否允许从当前状态迁移至目标状态 [next]。
  bool canTransitionTo(CaptureState next) {
    if (state.isTerminal) return false;
    if (next == state) return true;

    return switch (state) {
      CaptureState.prepared => switch (next) {
        CaptureState.pickerActive ||
        CaptureState.cancelled ||
        CaptureState.recoverableFailure => true,
        _ => false,
      },
      CaptureState.pickerActive => switch (next) {
        CaptureState.staged ||
        CaptureState.cancelled ||
        CaptureState.recoverableFailure ||
        CaptureState.prepared => true,
        _ => false,
      },
      CaptureState.staged => switch (next) {
        CaptureState.editing ||
        CaptureState.committing ||
        CaptureState.pickerActive ||
        CaptureState.cancelled ||
        CaptureState.recoverableFailure => true,
        _ => false,
      },
      CaptureState.editing => switch (next) {
        CaptureState.committing ||
        CaptureState.pickerActive ||
        CaptureState.staged ||
        CaptureState.cancelled ||
        CaptureState.recoverableFailure => true,
        _ => false,
      },
      CaptureState.committing => switch (next) {
        CaptureState.committed ||
        CaptureState.recoverableFailure ||
        CaptureState.editing => true,
        _ => false,
      },
      CaptureState.recoverableFailure => switch (next) {
        CaptureState.prepared ||
        CaptureState.pickerActive ||
        CaptureState.staged ||
        CaptureState.editing ||
        CaptureState.committing ||
        CaptureState.cancelled => true,
        _ => false,
      },
      CaptureState.committed || CaptureState.cancelled => false,
    };
  }

  /// 执行状态迁移校验并返回更新后的草稿副本。
  ///
  /// 若无法合法迁移至 [next]，则抛出 [StateError]。
  /// 成功时默认自增 [revision] 并刷新 [updatedAt]。
  CaptureDraft transitionTo(
    CaptureState next, {
    int? revision,
    DateTime? updatedAt,
    String? failureReason,
    bool clearFailureReason = false,
    Map<String, dynamic>? draftValues,
    List<String>? stagedPaths,
    int? projectLocalId,
    bool clearProjectLocalId = false,
    int? editTargetId,
    bool clearEditTargetId = false,
  }) {
    if (!canTransitionTo(next)) {
      throw StateError(
        'Illegal state transition for CaptureDraft(taskId: $taskId): '
        'cannot transition from $state to $next.',
      );
    }
    final shouldClearFailure =
        clearFailureReason ||
        (next != CaptureState.recoverableFailure && failureReason == null);
    return copyWith(
      state: next,
      revision: revision ?? (this.revision + 1),
      updatedAt: updatedAt ?? DateTime.now(),
      failureReason: failureReason,
      clearFailureReason: shouldClearFailure,
      draftValues: draftValues,
      stagedPaths: stagedPaths,
      projectLocalId: projectLocalId,
      clearProjectLocalId: clearProjectLocalId,
      editTargetId: editTargetId,
      clearEditTargetId: clearEditTargetId,
    );
  }

  /// 复制并更新部分属性。
  CaptureDraft copyWith({
    String? taskId,
    CaptureOwnerContext? ownerContext,
    CapturePurpose? purpose,
    int? projectLocalId,
    bool clearProjectLocalId = false,
    int? editTargetId,
    bool clearEditTargetId = false,
    Map<String, dynamic>? draftValues,
    List<String>? stagedPaths,
    CaptureState? state,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? failureReason,
    bool clearFailureReason = false,
  }) {
    return CaptureDraft(
      taskId: taskId ?? this.taskId,
      ownerContext: ownerContext ?? this.ownerContext,
      purpose: purpose ?? this.purpose,
      projectLocalId: clearProjectLocalId
          ? null
          : (projectLocalId ?? this.projectLocalId),
      editTargetId: clearEditTargetId
          ? null
          : (editTargetId ?? this.editTargetId),
      draftValues: draftValues != null
          ? Map.unmodifiable(draftValues)
          : this.draftValues,
      stagedPaths: stagedPaths != null
          ? List.unmodifiable(stagedPaths)
          : this.stagedPaths,
      state: state ?? this.state,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      failureReason: clearFailureReason
          ? null
          : (failureReason ?? this.failureReason),
    );
  }

  Map<String, dynamic> toMap() => {
    'taskId': taskId,
    'ownerContext': ownerContext.toMap(),
    'purpose': purpose.name,
    'projectLocalId': projectLocalId,
    'editTargetId': editTargetId,
    'draftValues': draftValues,
    'stagedPaths': stagedPaths,
    'state': state.name,
    'revision': revision,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'failureReason': failureReason,
  };

  factory CaptureDraft.fromMap(Map<String, dynamic> map) {
    return CaptureDraft(
      taskId: map['taskId'] as String,
      ownerContext: CaptureOwnerContext.fromMap(
        Map<String, dynamic>.from(map['ownerContext'] as Map),
      ),
      purpose: CapturePurpose.values.byName(map['purpose'] as String),
      projectLocalId: (map['projectLocalId'] as num?)?.toInt(),
      editTargetId: (map['editTargetId'] as num?)?.toInt(),
      draftValues: Map<String, dynamic>.from(
        (map['draftValues'] as Map?) ?? const {},
      ),
      stagedPaths: List<String>.from(
        (map['stagedPaths'] as Iterable?) ?? const [],
      ),
      state: CaptureState.values.byName(map['state'] as String),
      revision: (map['revision'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      failureReason: map['failureReason'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    taskId,
    ownerContext,
    purpose,
    projectLocalId,
    editTargetId,
    draftValues,
    stagedPaths,
    state,
    revision,
    createdAt,
    updatedAt,
    failureReason,
  ];
}
