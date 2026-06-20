import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryImportView extends StatefulWidget {
  const GalleryImportView({super.key});

  @override
  State<GalleryImportView> createState() => _GalleryImportViewState();
}

class _GalleryImportViewState extends State<GalleryImportView> {
  final List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  AssetPathEntity? _path;

  static const int _pageSize = 80;

  @override
  void initState() {
    super.initState();
    _loadInitialAssets();
  }

  Future<void> _loadInitialAssets() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("请授予照片权限后再导入")));
      }
      return;
    }

    final paths = await PhotoManager.getAssetPathList(
      onlyAll: true,
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (!mounted) return;
    if (paths.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    _path = paths.first;
    await _loadMoreAssets();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_path == null || _isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final newAssets = await _path!.getAssetListPaged(
      page: _page,
      size: _pageSize,
    );

    if (!mounted) return;
    setState(() {
      _page++;
      _assets.addAll(newAssets);
      _hasMore = newAssets.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  Future<void> _selectAsset(AssetEntity asset) async {
    final file = await asset.loadFile();
    if (file == null || !await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("无法读取这张照片")));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(GalleryImportResult(asset: asset, file: file));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("选择照片"),
        actions: const [
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: PhotoManager.openSetting,
            tooltip: "权限设置",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
          ? Center(
              child: Text(
                "没有可导入的照片",
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >
                    notification.metrics.maxScrollExtent - 600) {
                  _loadMoreAssets();
                }
                return false;
              },
              child: GridView.builder(
                padding: EdgeInsets.all(4.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.w,
                  mainAxisSpacing: 4.h,
                ),
                itemCount: _assets.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= _assets.length) {
                    return Center(
                      child: SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final asset = _assets[index];
                  return _AssetTile(
                    asset: asset,
                    onTap: () => _selectAsset(asset),
                  );
                },
              ),
            ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 20.h),
        color: theme.cardColor,
        child: Text(
          "导入成功后会请求删除原相册照片，系统会弹出确认框。",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }
}

class GalleryImportResult {
  final AssetEntity asset;
  final File file;

  GalleryImportResult({required this.asset, required this.file});
}

class _AssetTile extends StatelessWidget {
  final AssetEntity asset;
  final VoidCallback onTap;

  const _AssetTile({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize.square(300)),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            color: Theme.of(context).cardColor,
            child: data == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : Image.memory(data, fit: BoxFit.cover),
          ),
        );
      },
    );
  }
}
