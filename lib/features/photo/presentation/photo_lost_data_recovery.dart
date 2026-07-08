import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/presentation/capture_dialog.dart';
import 'package:life_log/features/photo/presentation/photo_add_action_launcher.dart';

Future<void> recoverLostPhotoData(
  GlobalKey<NavigatorState> navigatorKey, {
  ImagePicker? picker,
  PhotoPendingCaptureStore? pendingCaptureStore,
}) async {
  if (!Platform.isAndroid) return;

  final activePicker = picker ?? ImagePicker();
  final activeStore = pendingCaptureStore ?? PhotoPendingCaptureStore();
  final pendingProject = activeStore.readProject();
  if (pendingProject == null) return;

  final LostDataResponse response;
  try {
    response = await activePicker.retrieveLostData();
  } catch (error, stackTrace) {
    _logError('恢复相机结果失败', error, stackTrace);
    return;
  }

  if (response.isEmpty) {
    await activeStore.clear();
    return;
  }

  await activeStore.clear();

  final exception = response.exception;
  if (exception != null) {
    _logError('相机返回异常', exception, StackTrace.current);
    _showSnack(
      navigatorKey,
      '恢复相机照片失败: ${exception.message ?? exception.code}',
    );
    return;
  }

  final files = response.files ?? [if (response.file != null) response.file!];
  if (files.isEmpty) return;

  final context = navigatorKey.currentContext;
  if (context == null || !context.mounted) {
    _logWarning('发现相机恢复照片，但当前界面尚不可用');
    return;
  }

  final messenger = ScaffoldMessenger.maybeOf(context);
  final file = files.first;
  showCaptureDialog(
    context,
    initialProject: pendingProject,
    onConfirm: (projectName, description) => savePhotoFromCapturePath(
      messenger: messenger,
      tempPath: file.path,
      projectName: projectName,
      description: description,
      capturedAt: DateTime.now(),
      capturedAtSource: 'cameraRecovered',
      onSaved: null,
    ),
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
    serviceLocator<LogService>().warning('Photo', message);
  }
}

void _logError(String message, Object error, StackTrace stackTrace) {
  if (serviceLocator.isRegistered<LogService>()) {
    serviceLocator<LogService>().error('Photo', '$message: $error', stackTrace);
  }
}
