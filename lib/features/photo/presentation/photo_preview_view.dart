import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/photo/application/delete_photo_entries.dart';
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
    final photo = widget.photos[_index];
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
            onPressed: () => _editDescription(photo),
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _deletePhoto(photo),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final item = widget.photos[index];
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
              final current = widget.photos[_index];
              if (!displayPreferences.showGpsMetadata ||
                  current.gpsLatitude == null ||
                  current.gpsLongitude == null) {
                return const SizedBox.shrink();
              }
              return Positioned(
                left: 16.w,
                right: 16.w,
                bottom: 22.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.68),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'GPS ${current.gpsLatitude!.toStringAsFixed(6)}, ${current.gpsLongitude!.toStringAsFixed(6)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(PhotoEntry photo) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await serviceLocator<DeletePhotoEntries>().call([photo]);
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _editDescription(PhotoEntry photo) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _PhotoDescriptionEditorSheet(
        initialText: photo.description ?? '',
        onSave: (value) => _saveDescription(
          photo,
          value,
          Navigator.of(sheetContext),
          ScaffoldMessenger.of(context),
        ),
      ),
    );
  }

  Future<void> _saveDescription(
    PhotoEntry photo,
    String value,
    NavigatorState sheetNavigator,
    ScaffoldMessengerState messenger,
  ) async {
    final result = await serviceLocator<UpdatePhotoDescription>().call(
      photo,
      value,
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    final oldPathToEvict = result.valueOrNull;
    if (oldPathToEvict != null) {
      imageCache.evict(FileImage(File(photo.filePath)));
      imageCache.evict(FileImage(File(oldPathToEvict)));
    }
    sheetNavigator.pop();
  }
}

class _PhotoDescriptionEditorSheet extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onSave;

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
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: _controller,
            autofocus: true,
            hintText: '备注',
            prefixIcon: const Icon(Icons.edit_note_rounded),
            maxLines: 3,
          ),
          SizedBox(height: 18.h),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: '保存备注',
              icon: Icons.save_rounded,
              onPressed: () => widget.onSave(_controller.text.trim()),
            ),
          ),
        ],
      ),
    );
  }
}
