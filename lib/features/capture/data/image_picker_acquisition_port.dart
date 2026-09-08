import 'package:image_picker/image_picker.dart';
import 'package:life_log/features/capture/domain/capture_ports.dart';

/// 基于官方 [ImagePicker] 的设备媒体采集系统层适配器。
///
/// 具备：
/// - 单会话全局互斥锁，防止并发调起相机/相册造成系统服务与界面冲突；
/// - 发生异常或完成操作时自动释放会话锁；
/// - Android 低内存杀死后通过 [retrieveLostData] 检索未处理的媒体文件。
class ImagePickerAcquisitionPort implements AcquisitionPort {
  final ImagePicker _picker;
  bool _isSessionActive = false;
  String? _activeTaskId;

  ImagePickerAcquisitionPort({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  @override
  bool get isSessionActive => _isSessionActive;

  /// 当前持有会话锁的任务 ID（若有）。
  String? get activeTaskId => _activeTaskId;

  @override
  Future<String?> acquireMedia({
    required String taskId,
    AcquisitionSource? source,
    bool? isCamera,
  }) async {
    if (_isSessionActive) {
      throw AcquisitionBusyException(
        message: 'Another capture acquisition session is already active.',
        activeTaskId: _activeTaskId,
      );
    }

    _isSessionActive = true;
    _activeTaskId = taskId;

    final resolvedSource =
        source ??
        ((isCamera ?? true)
            ? AcquisitionSource.camera
            : AcquisitionSource.gallery);

    try {
      final imageSource = switch (resolvedSource) {
        AcquisitionSource.camera => ImageSource.camera,
        AcquisitionSource.gallery => ImageSource.gallery,
      };

      final pickedFile = await _picker.pickImage(source: imageSource);
      return pickedFile?.path;
    } finally {
      _isSessionActive = false;
      _activeTaskId = null;
    }
  }

  @override
  Future<List<String>> retrieveLostData() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return const [];
      }
      final files =
          response.files ?? [if (response.file != null) response.file!];
      return files.map((file) => file.path).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> releaseSession({required String taskId}) async {
    if (_activeTaskId == null || _activeTaskId == taskId) {
      _isSessionActive = false;
      _activeTaskId = null;
    }
  }
}
