import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_sheet_scaffold.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/modules/photo/photo_controller.dart';
import 'package:life_log/modules/photo/photo_model.dart';

class PhotoPreviewView extends StatefulWidget {
  final List<PhotoItem> photos;
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
            onPressed: () => PhotoController.to.deletePhoto(photo),
          ),
        ],
      ),
      body: PageView.builder(
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
    );
  }

  void _editDescription(PhotoItem photo) {
    Get.bottomSheet(
      _PhotoDescriptionEditorSheet(
        initialText: photo.description ?? '',
        onSave: (value) => PhotoController.to.updatePhotoDescription(
          photo,
          value,
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
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
