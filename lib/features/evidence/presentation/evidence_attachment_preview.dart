import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:pdfx/pdfx.dart';

class EvidenceAttachmentPreview extends StatelessWidget {
  final ExpenseEvidence item;
  final double? width;
  final double height;

  const EvidenceAttachmentPreview({
    super.key,
    required this.item,
    this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final path = item.localFilePath;
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        color: theme.colorScheme.surfaceContainerHighest,
        child: path == null || !File(path).existsSync()
            ? _placeholder(theme, Icons.receipt_long_rounded, '未找到本机文件')
            : isEvidenceImagePath(path)
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _placeholder(theme, Icons.broken_image_rounded, '无法显示图片'),
              )
            : isEvidencePdfPath(path) && width == null
            ? _PdfAttachmentPreview(path: path)
            : _FileAttachmentPreview(path: path),
      ),
    );
  }

  Widget _placeholder(ThemeData theme, IconData icon, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 28.sp),
        SizedBox(height: 8.h),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}

class _PdfAttachmentPreview extends StatefulWidget {
  final String path;

  const _PdfAttachmentPreview({required this.path});

  @override
  State<_PdfAttachmentPreview> createState() => _PdfAttachmentPreviewState();
}

class _PdfAttachmentPreviewState extends State<_PdfAttachmentPreview> {
  late final PdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(document: PdfDocument.openFile(widget.path));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PdfView(
      controller: _controller,
      scrollDirection: Axis.vertical,
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        pageLoaderBuilder: (_) =>
            const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _) => _FileAttachmentPreview(path: widget.path),
      ),
    );
  }
}

class _FileAttachmentPreview extends StatelessWidget {
  final String path;

  const _FileAttachmentPreview({required this.path});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isEvidencePdfPath(path)
                ? Icons.picture_as_pdf_rounded
                : Icons.insert_drive_file_rounded,
            color: theme.colorScheme.onSurfaceVariant,
            size: 34.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            evidenceFileName(path),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            evidenceAttachmentTypeLabel(path),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
