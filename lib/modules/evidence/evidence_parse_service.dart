import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'evidence_file_utils.dart';

class EvidenceParseResult {
  final String rawText;
  final double? amount;
  final DateTime? evidenceDate;
  final String? merchant;
  final String? currency;
  final String? invoiceNumber;
  final String? consumptionSummary;
  final String? buyerName;
  final String? buyerTaxId;
  final String? travelRoute;
  final String? travelTime;
  final String? serviceItem;

  const EvidenceParseResult({
    required this.rawText,
    this.amount,
    this.evidenceDate,
    this.merchant,
    this.currency,
    this.invoiceNumber,
    this.consumptionSummary,
    this.buyerName,
    this.buyerTaxId,
    this.travelRoute,
    this.travelTime,
    this.serviceItem,
  });

  bool get hasAnyField =>
      amount != null ||
      evidenceDate != null ||
      merchant != null ||
      currency != null ||
      invoiceNumber != null ||
      consumptionSummary != null ||
      buyerName != null ||
      buyerTaxId != null ||
      travelRoute != null ||
      travelTime != null ||
      serviceItem != null;

  List<String> get noteLines {
    final lines = <String>[];
    if (consumptionSummary != null) {
      lines.add('消费内容：$consumptionSummary');
    } else {
      final route = travelRoute;
      final time = travelTime;
      final service = serviceItem;
      if (route != null && time != null) {
        lines.add('消费内容：$route $time');
      } else if (route != null) {
        lines.add('消费内容：$route');
      } else if (service != null) {
        lines.add('消费内容：$service');
      }
    }
    if (buyerName != null) lines.add('购买方：$buyerName');
    if (buyerTaxId != null) lines.add('纳税号：$buyerTaxId');
    if (invoiceNumber != null) lines.add('发票号：$invoiceNumber');
    return lines;
  }
}

class EvidenceParseService extends GetxService {
  static EvidenceParseService get to => Get.find();

  Future<EvidenceParseResult> parseFile(String path) async {
    if (kIsWeb || !_isSupportedPlatform) {
      throw UnsupportedError('当前平台暂不支持本地凭证解析');
    }
    if (!isEvidenceParseablePath(path)) {
      throw UnsupportedError('仅支持解析图片或 PDF 凭证');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('凭证文件不存在', path);
    }

    final text = isEvidencePdfPath(path)
        ? await _recognizePdf(path)
        : await _recognizeImage(path);
    return parseText(text);
  }

  EvidenceParseResult parseText(String text) {
    final normalized = _normalizeText(text);
    return EvidenceParseResult(
      rawText: text,
      amount: _extractAmount(normalized),
      evidenceDate: _extractDate(normalized),
      merchant: _extractMerchant(normalized),
      currency: _extractCurrency(normalized),
      invoiceNumber: _extractInvoiceNumber(normalized),
      consumptionSummary: _extractConsumptionSummary(normalized),
      buyerName: _extractBuyerName(normalized),
      buyerTaxId: _extractBuyerTaxId(normalized),
      travelRoute: _extractTravelRoute(normalized),
      travelTime: _extractTravelTime(normalized),
      serviceItem: _extractServiceItem(normalized),
    );
  }

  bool get _isSupportedPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  Future<String> _recognizeImage(String path) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.chinese);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(path),
      );
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  Future<String> _recognizePdf(String path) async {
    final document = await PdfDocument.openFile(path);
    final tempDir = await getTemporaryDirectory();
    final chunks = <String>[];
    try {
      final pages = document.pagesCount.clamp(0, 3);
      for (var pageNumber = 1; pageNumber <= pages; pageNumber++) {
        final page = await document.getPage(pageNumber);
        try {
          final image = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
          );
          if (image == null) continue;
          final imagePath = p.join(
            tempDir.path,
            'lifelog_evidence_${DateTime.now().microsecondsSinceEpoch}_$pageNumber.jpg',
          );
          await File(imagePath).writeAsBytes(image.bytes, flush: true);
          chunks.add(await _recognizeImage(imagePath));
          try {
            await File(imagePath).delete();
          } catch (_) {}
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }
    return chunks.join('\n');
  }

  String _normalizeText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  double? _extractAmount(String text) {
    final patterns = [
      RegExp(
        r'(?:价税合计|小写|合计金额|金额合计|应付金额|实付金额|付款金额)[^\d¥￥]{0,16}[¥￥]?\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'[¥￥]\s*([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:金额|合计)[^\d]{0,10}([0-9]+(?:,[0-9]{3})*(?:\.[0-9]{1,2})?)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text).toList();
      if (matches.isEmpty) continue;
      final values = matches
          .map((match) => match.group(1)?.replaceAll(',', ''))
          .whereType<String>()
          .map(double.tryParse)
          .whereType<double>()
          .where((value) => value >= 0)
          .toList();
      if (values.isNotEmpty) {
        values.sort();
        return values.last;
      }
    }
    return null;
  }

  DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'(?:开票日期|日期)[^\d]{0,8}(\d{4})[年/-](\d{1,2})[月/-](\d{1,2})日?'),
      RegExp(r'(\d{4})[年/-](\d{1,2})[月/-](\d{1,2})日?'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (year == null || month == null || day == null) continue;
      if (month < 1 || month > 12 || day < 1 || day > 31) continue;
      return DateTime(year, month, day);
    }
    return null;
  }

  String? _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final patterns = [
      RegExp(r'(?:销售方名称|销方名称|收款方|商户名称|商家|销售方)[:：]?\s*(.+)'),
      RegExp(r'(?:名称)[:：]?\s*(.+)'),
    ];
    for (final pattern in patterns) {
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        final value = match?.group(1)?.trim();
        final cleaned = _cleanMerchant(value);
        if (cleaned != null) return cleaned;
      }
    }
    return null;
  }

  String? _extractBuyerName(String text) {
    final patterns = [
      RegExp(r'(?:购买方名称|购方名称|购买方|购方|付款方|客户名称|单位名称)[:：]?\s*(.+)'),
      RegExp(
        r'(?:旅客姓名|乘机人|乘车人|入住人|姓名)[:：]?\s*([\u4e00-\u9fa5A-Za-z·\s]{2,24})',
      ),
    ];
    return _firstCleanLineValue(text, patterns);
  }

  String? _extractBuyerTaxId(String text) {
    final compact = text.replaceAll(' ', '');
    final patterns = [
      RegExp(
        r'(?:购买方纳税人识别号|购方纳税人识别号|纳税人识别号|统一社会信用代码|税号)[:：]?\s*([A-Z0-9]{12,24})',
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(compact);
      final value = match?.group(1);
      if (value != null && value.length >= 12) return value;
    }
    return null;
  }

  String? _extractServiceItem(String text) {
    final patterns = [
      RegExp(r'(?:项目名称|服务名称|商品名称|货物或应税劳务、服务名称|应税服务名称)[:：]?\s*(.+)'),
      RegExp(r'(?:住宿费|餐饮服务|餐费|火车票|铁路客票|机票|航空运输|船票|出租车|网约车|停车费|过路费)'),
    ];
    for (final pattern in patterns) {
      final value = _firstCleanLineValue(text, [pattern]);
      if (value != null) return value;
      final match = pattern.firstMatch(text);
      final direct = match?.group(0)?.trim();
      if (direct != null && direct.isNotEmpty) return direct;
    }
    return null;
  }

  String? _extractTravelRoute(String text) {
    final railRoute = _extractRailRouteFromLines(text);
    if (railRoute != null) return railRoute;

    final compact = text.replaceAll(' ', '');
    final labelledPatterns = [
      RegExp(r'(?:出发地|出发站|始发站|起点|起飞城市)[:：]?([\u4e00-\u9fa5A-Za-z]{2,12})'),
      RegExp(r'(?:目的地|到达站|终点|到达城市)[:：]?([\u4e00-\u9fa5A-Za-z]{2,12})'),
    ];
    final from = labelledPatterns[0].firstMatch(compact)?.group(1);
    final to = labelledPatterns[1].firstMatch(compact)?.group(1);
    if (from != null && to != null && from != to) return '$from → $to';

    final routePatterns = [
      RegExp(
        r'([\u4e00-\u9fa5]{2,12})(?:站|机场|港)?(?:至|到|—|－|-|→)([\u4e00-\u9fa5]{2,12})(?:站|机场|港)?',
      ),
    ];
    for (final pattern in routePatterns) {
      final match = pattern.firstMatch(text);
      final start = _cleanPlace(match?.group(1));
      final end = _cleanPlace(match?.group(2));
      if (start != null && end != null && start != end) return '$start → $end';
    }
    return null;
  }

  String? _extractTravelTime(String text) {
    final date = _extractTravelDate(text) ?? _extractDate(text);
    final timeMatch = RegExp(r'(\d{1,2})[:：](\d{2})').firstMatch(text);
    if (date == null && timeMatch == null) return null;
    final parts = <String>[];
    if (date != null) {
      parts.add(
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      );
    }
    if (timeMatch != null) {
      final hour = timeMatch.group(1)!.padLeft(2, '0');
      final minute = timeMatch.group(2)!;
      parts.add('$hour:$minute');
    }
    return parts.join(' ');
  }

  String? _extractRailRouteFromLines(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    final trainIndex = lines.indexWhere(
      (line) =>
          RegExp(r'\b[GDCZTK]\d{2,5}\b', caseSensitive: false).hasMatch(line),
    );
    if (trainIndex < 0) return null;

    final sameLineRoute = _railRouteFromTrainLine(lines[trainIndex]);
    if (sameLineRoute != null) return sameLineRoute;

    String? before;
    for (var index = trainIndex - 1; index >= 0; index--) {
      before = _stationNameFromLine(lines[index]);
      if (before != null) break;
    }

    String? after;
    for (var index = trainIndex + 1; index < lines.length; index++) {
      after = _stationNameFromLine(lines[index]);
      if (after != null) break;
    }

    if (before != null && after != null && before != after) {
      return '$before → $after';
    }
    return null;
  }

  String? _railRouteFromTrainLine(String line) {
    if (!RegExp(r'\b[GDCZTK]\d{2,5}\b', caseSensitive: false).hasMatch(line)) {
      return null;
    }
    final stationMatches = RegExp(
      r'([\u4e00-\u9fa5]{2,12})(站|机场|港)',
    ).allMatches(line).toList();
    if (stationMatches.length < 2) return null;

    final start = _cleanPlace(stationMatches.first.group(0));
    final end = _cleanPlace(stationMatches.last.group(0));
    if (start == null || end == null || start == end) return null;
    return '$start → $end';
  }

  String? _stationNameFromLine(String line) {
    if (RegExp(r'[A-Za-z]{3,}').hasMatch(line) &&
        !RegExp(r'[\u4e00-\u9fa5]').hasMatch(line)) {
      return null;
    }
    final match = RegExp(r'([\u4e00-\u9fa5]{2,12})(站|机场|港)').firstMatch(line);
    return _cleanPlace(match?.group(0));
  }

  DateTime? _extractTravelDate(String text) {
    final patterns = [
      RegExp(
        r'(?:乘车日期|乘车时间|发车日期|发车时间|出发日期|起飞日期|航班日期|入住日期)[^\d]{0,8}(\d{4})[年/-](\d{1,2})[月/-](\d{1,2})日?',
      ),
      RegExp(r'(\d{4})[年/-](\d{1,2})[月/-](\d{1,2})日?\s+\d{1,2}[:：]\d{2}'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (year == null || month == null || day == null) continue;
      if (month < 1 || month > 12 || day < 1 || day > 31) continue;
      return DateTime(year, month, day);
    }
    return null;
  }

  String? _extractConsumptionSummary(String text) {
    final route = _extractTravelRoute(text);
    final time = _extractTravelTime(text);
    final service = _extractServiceItem(text);
    if (route != null && time != null) return '$route $time';
    if (route != null) return route;
    if (service != null && time != null) return '$service $time';
    return service;
  }

  String? _firstCleanLineValue(String text, List<RegExp> patterns) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    for (final pattern in patterns) {
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        final value = match?.groupCount == 0
            ? match?.group(0)
            : match?.group(1);
        final cleaned = _cleanGenericValue(value);
        if (cleaned != null) return cleaned;
      }
    }
    return null;
  }

  String? _cleanGenericValue(String? value) {
    if (value == null) return null;
    final cleaned = value
        .replaceAll(RegExp(r'(纳税人识别号|统一社会信用代码|税号|地址|电话|开户行).*$'), '')
        .replaceAll(RegExp(r'[|｜*]+'), '')
        .trim();
    if (cleaned.length < 2) return null;
    return cleaned.length > 48 ? cleaned.substring(0, 48).trim() : cleaned;
  }

  String? _cleanPlace(String? value) {
    final cleaned = _cleanGenericValue(
      value,
    )?.replaceAll(RegExp(r'(出发|到达|始发|终点|站|机场|港)$'), '').trim();
    if (cleaned == null || cleaned.length < 2) return null;
    return cleaned;
  }

  String? _cleanMerchant(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value
        .replaceAll(RegExp(r'(纳税人识别号|开户行|地址|电话).*$'), '')
        .trim();
    if (cleaned.length < 2) return null;
    return cleaned.length > 40 ? cleaned.substring(0, 40).trim() : cleaned;
  }

  String? _extractCurrency(String text) {
    if (text.contains('人民币') || text.contains('¥') || text.contains('￥')) {
      return 'CNY';
    }
    return null;
  }

  String? _extractInvoiceNumber(String text) {
    final patterns = [
      RegExp(r'(?:发票号码|发票号|票据号码|票据号)[:：]?\s*([A-Z0-9]{6,24})'),
      RegExp(r'(?:No\.?|NO\.?)\s*([A-Z0-9]{6,24})', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text.replaceAll(' ', ''));
      final value = match?.group(1);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
