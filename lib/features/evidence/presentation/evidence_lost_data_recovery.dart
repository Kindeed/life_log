import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/evidence/presentation/evidence_editor_launcher.dart';

enum EvidencePendingPickerSource { camera, gallery }

final class EvidencePendingPickerStore {
  static const _activeKey = 'evidence.pendingPicker.active';
  static const _projectKey = 'evidence.pendingPicker.projectName';
  static const _sourceKey = 'evidence.pendingPicker.source';

  final GetStorage _storage;

  EvidencePendingPickerStore({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  Future<void> rememberLaunch({
    required EvidencePendingPickerSource source,
    String? initialProject,
  }) async {
    final normalizedProject = initialProject?.trim();
    await _storage.write(_activeKey, true);
    await _storage.write(_sourceKey, source.name);
    if (normalizedProject == null || normalizedProject.isEmpty) {
      await _storage.remove(_projectKey);
    } else {
      await _storage.write(_projectKey, normalizedProject);
    }
  }

  bool get hasPendingLaunch => _storage.read<bool>(_activeKey) == true;

  String? readProject() {
    final value = _storage.read<String>(_projectKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  EvidencePendingPickerSource? readSource() {
    final value = _storage.read<String>(_sourceKey);
    if (value == null) return null;
    for (final source in EvidencePendingPickerSource.values) {
      if (source.name == value) return source;
    }
    return null;
  }

  Future<void> clear() async {
    await _storage.remove(_activeKey);
    await _storage.remove(_projectKey);
    await _storage.remove(_sourceKey);
  }
}

Future<void> recoverLostEvidenceData(
  GlobalKey<NavigatorState> navigatorKey, {
  ImagePicker? picker,
  EvidencePendingPickerStore? pendingPickerStore,
}) async {
  if (!Platform.isAndroid) return;

  final activeStore = pendingPickerStore ?? EvidencePendingPickerStore();
  if (!activeStore.hasPendingLaunch) return;

  final activePicker = picker ?? ImagePicker();
  final pendingProject = activeStore.readProject();
  final pendingSource = activeStore.readSource();

  final LostDataResponse response;
  try {
    response = await activePicker.retrieveLostData();
  } catch (error, stackTrace) {
    _logError('恢复凭证选择结果失败', error, stackTrace);
    return;
  }

  if (response.isEmpty) {
    await activeStore.clear();
    return;
  }

  await activeStore.clear();

  final exception = response.exception;
  if (exception != null) {
    _logError('凭证选择返回异常', exception, StackTrace.current);
    _showSnack(
      navigatorKey,
      '恢复凭证图片失败: ${exception.message ?? exception.code}',
    );
    return;
  }

  final files = response.files ?? [if (response.file != null) response.file!];
  if (files.isEmpty) return;

  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    _logWarning('发现凭证恢复图片，但当前界面尚不可用');
    return;
  }

  final file = files.first;
  await showEvidenceEditorSheet(
    context,
    initialProject: pendingProject,
    sourcePath: file.path,
    sourceExtension: _sourceExtension(file.path, pendingSource),
  );
}

String? _sourceExtension(
  String path,
  EvidencePendingPickerSource? pendingSource,
) {
  final dotIndex = path.lastIndexOf('.');
  if (dotIndex >= 0 && dotIndex < path.length - 1) {
    return path.substring(dotIndex + 1).toLowerCase();
  }
  return switch (pendingSource) {
    EvidencePendingPickerSource.camera => 'jpg',
    EvidencePendingPickerSource.gallery => null,
    null => null,
  };
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
    serviceLocator<LogService>().warning('Evidence', message);
  }
}

void _logError(String message, Object error, StackTrace stackTrace) {
  if (serviceLocator.isRegistered<LogService>()) {
    serviceLocator<LogService>().error(
      'Evidence',
      '$message: $error',
      stackTrace,
    );
  }
}
