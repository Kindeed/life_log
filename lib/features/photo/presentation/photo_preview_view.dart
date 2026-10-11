import 'dart:io';

import 'package:flutter/material.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/app_spacing.dart';
import 'package:life_log/common/widgets/app_bottom_sheet.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_form_feedback.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/update_photo_description.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/presentation/photo_display_preferences.dart';

class PhotoPreviewView extends StatefulWidget {
  final List<PhotoEntry> photos;
  final int initialIndex;

  const PhotoPreviewView({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoPreviewView> createState() => _PhotoPreviewViewState();
}

class _PhotoPreviewViewState extends State<PhotoPreviewView> {
  late final PageController _pageController;
  late int _index;
  final _savedDescriptions = <int, String>{};
  final _latestPhotos = <int, PhotoEntry>{};
  bool _descriptionSaving = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photoAt(_index);
    final displayPreferences = serviceLocator<PhotoDisplayPreferences>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1}/${widget.photos.length}'),
        actions: [
          IconButton(
            tooltip: '编辑备注',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: _descriptionSaving
                ? null
                : () => _editDescription(photo),
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deletePhoto(photo),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = _photoAt(index);
                return Hero(
                  tag: 'photo-${item.id}',
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.file(
                        File(item.filePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: displayPreferences,
              builder: (context, _) {
                final current = _photoAt(_index);
                final description = _description(current).trim();
                final showGps =
                    displayPreferences.showGpsMetadata &&
                    current.gpsLatitude != null &&
                    current.gpsLongitude != null;
                if (description.isEmpty && !showGps) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.lg,
                  child: SafeArea(
                    top: false,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.3,
                      ),
                      child: DecoratedBox(
                        key: const ValueKey('photo-preview-metadata'),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.68),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: SingleChildScrollView(
                          key: ValueKey('photo-preview-metadata-${current.id}'),
                          primary: false,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (description.isNotEmpty)
                                Semantics(
                                  label: '照片备注',
                                  child: Text(
                                    description,
                                    key: const ValueKey(
                                      'photo-preview-description',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          height: 1.5,
                                        ),
                                  ),
                                ),
                              if (description.isNotEmpty && showGps)
                                const SizedBox(height: AppSpacing.sm),
                              if (showGps)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        'GPS ${current.gpsLatitude!.toStringAsFixed(6)}, ${current.gpsLongitude!.toStringAsFixed(6)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white70,
                                              height: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _description(PhotoEntry photo) =>
      _savedDescriptions[photo.id] ?? photo.description ?? '';

  PhotoEntry _photoAt(int index) =>
      _latestPhotos[widget.photos[index].id] ?? widget.photos[index];

  Future<void> _refreshRenamedPhoto(
    PhotoEntry original,
    ScaffoldMessengerState messenger,
  ) async {
    if (!serviceLocator.isRegistered<LoadPhotoEntries>()) return;
    final result = await serviceLocator<LoadPhotoEntries>().call();
    if (!mounted) return;
    PhotoEntry? refreshed;
    for (final candidate in result.valueOrNull ?? const <PhotoEntry>[]) {
      if (candidate.id == original.id &&
          candidate.ownerUserId == original.ownerUserId &&
          candidate.projectId == original.projectId &&
          candidate.projectName == original.projectName &&
          candidate.createdAt.isAtSameMomentAs(original.createdAt)) {
        refreshed = candidate;
        break;
      }
    }
    if (refreshed != null) {
      setState(() => _latestPhotos[original.id] = refreshed!);
    } else if (messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('备注已保存，但照片预览刷新失败，请返回项目后重新打开。')),
      );
    }
  }

  Future<void> _deletePhoto(PhotoEntry photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除照片'),
        content: const Text('确定删除这张照片吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await serviceLocator<DeletePhotoEntries>().call([photo]);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('删除失败：${failure.message}')),
      );
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _editDescription(PhotoEntry photo) {
    if (_descriptionSaving) return;
    showAppBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PhotoDescriptionEditorSheet(
        initialText: _description(photo),
        onSave: (value) => _saveDescription(
          photo,
          value,
          sheetContext,
          ScaffoldMessenger.of(context),
        ),
      ),
    );
  }

  Future<String?> _saveDescription(
    PhotoEntry photo,
    String value,
    BuildContext sheetContext,
    ScaffoldMessengerState messenger,
  ) async {
    if (_descriptionSaving) return null;
    setState(() => _descriptionSaving = true);
    try {
      final result = await serviceLocator<UpdatePhotoDescription>().call(
        photo,
        value,
      );
      if (!mounted) return null;
      final failure = result.failureOrNull;
      if (failure != null) {
        if (sheetContext.mounted &&
            ModalRoute.of(sheetContext)?.isCurrent == true) {
          return failure.message;
        }
        if (messenger.mounted) {
          messenger.showSnackBar(SnackBar(content: Text(failure.message)));
        }
        return null;
      }

      setState(() => _savedDescriptions[photo.id] = value);

      final oldPathToEvict = result.valueOrNull;
      if (oldPathToEvict != null) {
        imageCache.evict(FileImage(File(photo.filePath)));
        imageCache.evict(FileImage(File(oldPathToEvict)));
        await _refreshRenamedPhoto(photo, messenger);
      }
      if (!mounted) return null;
      if (sheetContext.mounted &&
          ModalRoute.of(sheetContext)?.isCurrent == true) {
        Navigator.of(sheetContext).pop();
      }
      return null;
    } finally {
      if (mounted) setState(() => _descriptionSaving = false);
    }
  }
}

class _PhotoDescriptionEditorSheet extends StatefulWidget {
  final String initialText;
  final Future<String?> Function(String) onSave;

  const _PhotoDescriptionEditorSheet({
    required this.initialText,
    required this.onSave,
  });

  @override
  State<_PhotoDescriptionEditorSheet> createState() =>
      _PhotoDescriptionEditorSheetState();
}

class _PhotoDescriptionEditorSheetState
    extends State<_PhotoDescriptionEditorSheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: '编辑照片备注',
      scrollable: true,
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) AppFormFeedback(message: _error!),
          AppTextField(
            controller: _controller,
            enabled: !_saving,
            autofocus: true,
            hintText: '备注',
            prefixIcon: const Icon(Icons.edit_note_rounded),
            maxLines: 3,
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: _saving ? '正在保存…' : '保存备注',
              icon: Icons.save_rounded,
              onPressed: _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final error = await widget.onSave(_controller.text.trim());
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
