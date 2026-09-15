import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/capture/application/capture_coordinator.dart';
import 'package:life_log/features/capture/capture_feature_di.dart';
import 'package:life_log/features/capture/domain/capture_draft.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/data/legacy_evidence_repository_adapter.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_launcher.dart';
import 'package:life_log/features/photo/presentation/capture_dialog.dart';
import 'package:life_log/features/photo/presentation/photo_add_action_launcher.dart';

/// 统一恢复因系统杀死遗失的媒体采集数据并协调界面路由。
///
/// 替代原先分散且并发的 `recoverLostPhotoData` 与 `recoverLostEvidenceData`。
/// 流程：
/// 1. 解析当前登录账户与会话纪元，构建 [CaptureOwnerContext]；
/// 2. 调用 [CaptureCoordinator.recoverLostData] 检索并沙箱暂存遗失媒体；
/// 3. 根据恢复草稿的 [CapturePurpose] 分发路由：
///    - [CapturePurpose.photo]：唤起照片归档对话框；
///    - [CapturePurpose.evidence]：根据 [CaptureDraft.editTargetId] 区分是原地更新已有凭证（彻底解决 U290）还是新增凭证。
Future<void> recoverLostCaptureData(
  GlobalKey<NavigatorState> navigatorKey, {
  CaptureCoordinator? coordinator,
  AuthService? authService,
  CaptureOwnerContext? currentOwner,
}) async {
  if (coordinator == null &&
      !serviceLocator.isRegistered<CaptureCoordinator>()) {
    try {
      await configureCaptureFeatureDependencies();
    } catch (e, stackTrace) {
      _logError('初始化采集协调器依赖失败', e, stackTrace);
      return;
    }
  }

  final activeCoordinator =
      coordinator ??
      (serviceLocator.isRegistered<CaptureCoordinator>()
          ? serviceLocator<CaptureCoordinator>()
          : null);
  if (activeCoordinator == null) {
    _logWarning('CaptureCoordinator 未注册，跳过采集恢复');
    return;
  }

  final activeAuth =
      authService ??
      (serviceLocator.isRegistered<AuthService>()
          ? serviceLocator<AuthService>()
          : null);

  final owner =
      currentOwner ??
      CaptureOwnerContext(
        ownerUserId: activeAuth?.userId,
        sessionEpoch: activeAuth?.sessionEpoch ?? 0,
      );

  final List<CaptureDraft> recoveredDrafts;
  try {
    recoveredDrafts = await activeCoordinator.recoverLostData(owner);
  } catch (error, stackTrace) {
    _logError('恢复采集数据失败', error, stackTrace);
    return;
  }

  if (recoveredDrafts.isEmpty) return;

  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    _logWarning('发现恢复采集数据，但当前界面上下文尚不可用');
    return;
  }

  for (final draft in recoveredDrafts) {
    if (!context.mounted) break;
    await _handleRecoveredDraft(
      context,
      navigatorKey,
      activeCoordinator,
      owner,
      draft,
    );
  }
}

Future<void> _handleRecoveredDraft(
  BuildContext context,
  GlobalKey<NavigatorState> navigatorKey,
  CaptureCoordinator coordinator,
  CaptureOwnerContext owner,
  CaptureDraft draft,
) async {
  switch (draft.purpose) {
    case CapturePurpose.photo:
      await _handleRecoveredPhotoDraft(
        context,
        navigatorKey,
        coordinator,
        owner,
        draft,
      );
    case CapturePurpose.evidence:
      await _handleRecoveredEvidenceDraft(
        context,
        navigatorKey,
        coordinator,
        owner,
        draft,
      );
  }
}

Future<void> _handleRecoveredPhotoDraft(
  BuildContext context,
  GlobalKey<NavigatorState> navigatorKey,
  CaptureCoordinator coordinator,
  CaptureOwnerContext owner,
  CaptureDraft draft,
) async {
  final stagedPath = draft.stagedPaths.firstOrNull;
  if (stagedPath == null) return;

  String? initialProject =
      (draft.draftValues['projectName'] as String?)?.trim() ??
      (draft.draftValues['project'] as String?)?.trim();
  if (initialProject == null && draft.projectLocalId != null) {
    if (serviceLocator.isRegistered<DbService>()) {
      try {
        final project = await serviceLocator<DbService>().getProject(
          draft.projectLocalId!,
        );
        initialProject = project?.name;
      } catch (_) {}
    }
  }

  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  showCaptureDialog(
    context,
    initialProject: initialProject,
    onConfirm: (projectName, description) async {
      try {
        await coordinator.updateDraftValues(draft.taskId, owner, {
          'projectName': projectName,
          'description': description,
          'capturedAt': DateTime.now().toIso8601String(),
          'capturedAtSource': 'cameraRecovered',
        });
        await coordinator.commit(draft.taskId, owner);
        _showSnack(navigatorKey, '照片已保存至: $projectName');
      } catch (error, stackTrace) {
        _logError('提交恢复照片失败', error, stackTrace);
        try {
          await savePhotoFromCapturePath(
            messenger: messenger,
            tempPath: stagedPath,
            projectName: projectName,
            description: description,
            capturedAt: DateTime.now(),
            capturedAtSource: 'cameraRecovered',
            onSaved: null,
          );
        } catch (_) {}
        _showSnack(navigatorKey, '保存恢复照片失败: $error');
      }
    },
  );
}

Future<void> _handleRecoveredEvidenceDraft(
  BuildContext context,
  GlobalKey<NavigatorState> navigatorKey,
  CaptureCoordinator coordinator,
  CaptureOwnerContext owner,
  CaptureDraft draft,
) async {
  final stagedPath = draft.stagedPaths.firstOrNull;
  if (stagedPath == null) return;

  String? sourceExtension;
  final dotIndex = stagedPath.lastIndexOf('.');
  if (dotIndex >= 0 && dotIndex < stagedPath.length - 1) {
    sourceExtension = stagedPath.substring(dotIndex + 1).toLowerCase();
  }

  ExpenseEvidence? existing;
  if (draft.editTargetId != null) {
    if (serviceLocator.isRegistered<DbService>()) {
      try {
        existing = await serviceLocator<DbService>().getEvidence(
          draft.editTargetId!,
        );
      } catch (_) {}
    }
    if (existing == null &&
        serviceLocator.isRegistered<EvidenceRepositoryPort>()) {
      try {
        final draftData = await serviceLocator<EvidenceRepositoryPort>()
            .getEditDraft(draft.editTargetId!);
        if (draftData != null) {
          existing = draftData.entry.toLegacyExpenseEvidence();
        }
      } catch (_) {}
    }
  }

  String? initialProject =
      existing?.projectName ??
      (draft.draftValues['projectName'] as String?)?.trim() ??
      (draft.draftValues['project'] as String?)?.trim();
  if (initialProject == null && draft.projectLocalId != null) {
    if (serviceLocator.isRegistered<DbService>()) {
      try {
        final project = await serviceLocator<DbService>().getProject(
          draft.projectLocalId!,
        );
        initialProject = project?.name;
      } catch (_) {}
    }
  }

  if (!context.mounted) return;
  unawaited(
    showEvidenceEditorSheet(
      context,
      existing: existing,
      initialProject: initialProject,
      sourcePath: stagedPath,
      sourceExtension: sourceExtension,
    ).then((_) async {
      try {
        final current = await coordinator.getDraft(draft.taskId);
        if (current != null && !current.state.isTerminal) {
          await coordinator.abandon(draft.taskId, owner);
        }
      } catch (_) {}
    }),
  );
}

void _showSnack(GlobalKey<NavigatorState> navigatorKey, String message) {
  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  ScaffoldMessenger.maybeOf(
    context,
  )?.showSnackBar(SnackBar(content: Text(message)));
}

void _logWarning(String message) {
  if (serviceLocator.isRegistered<LogService>()) {
    serviceLocator<LogService>().warning('CaptureRecovery', message);
  }
}

void _logError(String message, Object error, StackTrace stackTrace) {
  if (serviceLocator.isRegistered<LogService>()) {
    serviceLocator<LogService>().error(
      'CaptureRecovery',
      '$message: $error',
      stackTrace,
    );
  }
}
