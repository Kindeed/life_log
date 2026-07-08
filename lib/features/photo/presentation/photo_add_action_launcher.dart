import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_log/common/services/log_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/save_photo_from_path.dart';
import 'package:life_log/features/photo/presentation/capture_dialog.dart';
import 'package:life_log/features/photo/presentation/gallery_import_view.dart';
import 'package:photo_manager/photo_manager.dart';

final class PhotoPendingCaptureStore {
  static const _projectKey = 'photo.pendingCapture.projectName';

  final GetStorage _storage;

  PhotoPendingCaptureStore({GetStorage? storage})
    : _storage = storage ?? GetStorage();

  Future<void> rememberProject(String? projectName) async {
    final normalized = projectName?.trim();
    if (normalized == null || normalized.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(_projectKey, normalized);
  }

  String? readProject() {
    final value = _storage.read<String>(_projectKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> clear() {
    return _storage.remove(_projectKey);
  }
}

Future<void> capturePhotoWithSystemCamera(
  BuildContext context, {
  String? initialProject,
  Future<void> Function()? onSaved,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final pendingCaptureStore = PhotoPendingCaptureStore();
  await pendingCaptureStore.rememberProject(initialProject);
  try {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
    );
    if (image == null) {
      await pendingCaptureStore.clear();
      return;
    }

    await pendingCaptureStore.clear();
    if (!context.mounted) return;

    final activeMessenger = ScaffoldMessenger.maybeOf(context);
    showCaptureDialog(
      context,
      initialProject: initialProject,
      onConfirm: (projectName, description) => _savePhotoFromPath(
        messenger: activeMessenger,
        tempPath: image.path,
        projectName: projectName,
        description: description,
        sourceAssetId: null,
        capturedAt: DateTime.now(),
        capturedAtSource: 'cameraNow',
        onSaved: onSaved,
      ),
    );
  } catch (error, stackTrace) {
    await pendingCaptureStore.clear();
    _logError('无法打开系统相机', error, stackTrace);
    _showSnack(messenger, '无法打开系统相机: $error');
  }
}

Future<void> importPhotoFromGallery(
  BuildContext context, {
  String? initialProject,
  Future<void> Function()? onSaved,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final result = await Navigator.of(context).push<GalleryImportResult>(
      MaterialPageRoute<GalleryImportResult>(
        builder: (_) => const GalleryImportView(),
      ),
    );
    if (result == null || !context.mounted) return;

    final latLng = await _galleryLatLng(result.asset);
    if (!context.mounted) return;
    showCaptureDialog(
      context,
      initialProject: initialProject,
      onConfirm: (projectName, description) => _savePhotoFromPath(
        messenger: messenger,
        tempPath: result.file.path,
        projectName: projectName,
        description: description,
        sourceAssetId: result.asset.id,
        capturedAt: result.asset.createDateTime,
        capturedAtSource: 'gallery',
        gpsLatitude: latLng?.latitude,
        gpsLongitude: latLng?.longitude,
        onSaved: onSaved,
      ),
    );
  } catch (error, stackTrace) {
    _logError('无法导入相册照片', error, stackTrace);
    _showSnack(messenger, '无法导入相册照片: $error');
  }
}

Future<void> savePhotoFromCapturePath({
  required ScaffoldMessengerState? messenger,
  required String tempPath,
  required String projectName,
  required String description,
  DateTime? capturedAt,
  String? capturedAtSource,
  required Future<void> Function()? onSaved,
}) {
  return _savePhotoFromPath(
    messenger: messenger,
    tempPath: tempPath,
    projectName: projectName,
    description: description,
    sourceAssetId: null,
    capturedAt: capturedAt,
    capturedAtSource: capturedAtSource,
    onSaved: onSaved,
  );
}

Future<void> _savePhotoFromPath({
  required ScaffoldMessengerState? messenger,
  required String tempPath,
  required String projectName,
  required String description,
  required String? sourceAssetId,
  DateTime? capturedAt,
  String? capturedAtSource,
  double? gpsLatitude,
  double? gpsLongitude,
  required Future<void> Function()? onSaved,
}) async {
  try {
    final result = await serviceLocator<SavePhotoFromPath>().call(
      tempPath: tempPath,
      projectName: projectName,
      description: description,
      deviceName: await _deviceName(),
      deleteSource: sourceAssetId == null,
      capturedAt: capturedAt,
      capturedAtSource: capturedAtSource,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      _showSnack(messenger, failure.message);
      return;
    }

    final entry = result.valueOrNull!;
    final deleteWarning = sourceAssetId == null
        ? null
        : await _deleteSourceGalleryAsset(sourceAssetId);

    try {
      await onSaved?.call();
    } catch (error, stackTrace) {
      _logError('刷新照片列表失败', error, stackTrace);
    }

    if (deleteWarning != null) {
      _showSnack(messenger, deleteWarning);
    } else {
      _showSnack(messenger, '照片已保存至: ${entry.projectName}');
    }
    _logInfo('保存照片 ${entry.fileName} (${entry.projectName})');
  } catch (error, stackTrace) {
    _logError('保存照片失败', error, stackTrace);
    _showSnack(messenger, '保存照片失败: $error');
  }
}

Future<LatLng?> _galleryLatLng(AssetEntity asset) async {
  try {
    return asset.latLng ?? await asset.latlngAsync();
  } catch (error, stackTrace) {
    _logError('读取相册 GPS 元数据失败', error, stackTrace);
    return asset.latLng;
  }
}

Future<String> _deviceName() async {
  try {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    }
  } catch (error, stackTrace) {
    _logError('获取设备信息失败', error, stackTrace);
  }
  return 'UnknownDevice';
}

Future<String?> _deleteSourceGalleryAsset(String sourceAssetId) async {
  try {
    final deletedIds = await PhotoManager.editor.deleteWithIds([sourceAssetId]);
    if (deletedIds.isEmpty) {
      return '照片已归档，但系统相册原图仍保留';
    }
    return null;
  } catch (error, stackTrace) {
    _logError('删除系统相册原图失败', error, stackTrace);
    return '照片已归档，但删除系统相册原图失败: $error';
  }
}

void _showSnack(ScaffoldMessengerState? messenger, String message) {
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void _logInfo(String message) {
  if (serviceLocator.isRegistered<LogService>()) {
    serviceLocator<LogService>().info('Photo', message);
  }
}

void _logError(String message, Object error, StackTrace stackTrace) {
  if (serviceLocator.isRegistered<LogService>()) {
    serviceLocator<LogService>().error('Photo', '$message: $error', stackTrace);
  }
}
