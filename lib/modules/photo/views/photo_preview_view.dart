import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              await PhotoController.to.deletePhoto(photo);
              if (mounted) Get.back();
            },
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
}
