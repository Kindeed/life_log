import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/evidence/data/evidence_file_utils.dart';
import 'package:life_log/features/evidence/data/evidence_parse_service.dart';

void main() {
  test('evidence parse utilities live under the feature data boundary', () {
    expect(
      File('lib/features/evidence/data/evidence_file_utils.dart').existsSync(),
      isTrue,
    );
    expect(
      File(
        'lib/features/evidence/data/evidence_parse_service.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('lib/modules/evidence/evidence_file_utils.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/modules/evidence/evidence_parse_service.dart').existsSync(),
      isFalse,
    );
  });

  test('evidence file utilities infer supported types', () {
    expect(evidenceExtensionForPath('invoice.PDF'), '.pdf');
    expect(evidenceMimeTypeForPath('invoice.PDF'), 'application/pdf');
    expect(evidenceMimeTypeForPath('receipt.png'), 'image/png');
    expect(evidenceMimeTypeForPath('sheet.xlsx'), contains('spreadsheetml'));
    expect(isEvidenceParseablePath('invoice.pdf'), isTrue);
    expect(isEvidenceParseablePath('sheet.xlsx'), isFalse);
  });

  test('parseText extracts common Chinese invoice fields', () {
    final result = EvidenceParseService().parseText('''
电子发票
发票号码: 12345678901234567890
开票日期: 2026年05月28日
项目名称: 住宿费
购买方名称: 上海示例采购有限公司
购买方纳税人识别号: 91310000123456789X
销售方名称: 上海示例科技有限公司
价税合计（小写）￥1,234.56
''');

    expect(result.amount, 1234.56);
    expect(result.evidenceDate, DateTime(2026, 5, 28));
    expect(result.merchant, '上海示例科技有限公司');
    expect(result.currency, 'CNY');
    expect(result.invoiceNumber, '12345678901234567890');
    expect(result.buyerName, '上海示例采购有限公司');
    expect(result.buyerTaxId, '91310000123456789X');
    expect(result.consumptionSummary, '住宿费 2026-05-28');
    expect(
      result.noteLines,
      containsAll([
        '消费内容：住宿费 2026-05-28',
        '购买方：上海示例采购有限公司',
        '纳税号：91310000123456789X',
        '发票号：12345678901234567890',
      ]),
    );
  });

  test('parseText extracts train route and time summary', () {
    final result = EvidenceParseService().parseText('''
铁路电子客票
旅客姓名: 张三
北京南站-上海虹桥站
车次 G123
乘车日期 2026-06-01 08:35
票价 ¥553.00
''');

    expect(result.amount, 553.00);
    expect(result.evidenceDate, DateTime(2026, 6, 1));
    expect(result.buyerName, '张三');
    expect(result.travelRoute, '北京南 → 上海虹桥');
    expect(result.travelTime, '2026-06-01 08:35');
    expect(result.consumptionSummary, '北京南 → 上海虹桥 2026-06-01 08:35');
  });

  test(
    'parseText ignores station pinyin and uses travel date for rail ticket',
    () {
      final result = EvidenceParseService().parseText('''
电子发票(铁路电子客票)
发票号码: 26419138702000376667
开票日期: 2026年06月01日
广州站
Guangzhou
G5133
阳江北站
Yangjiangbei
2026年05月21日 12:08开
票价: ￥148.00
购买方名称: 航天长征火箭技术有限公司
统一社会信用代码: 9110302700238431D
''');

      expect(result.amount, 148.00);
      expect(result.travelRoute, '广州 → 阳江北');
      expect(result.travelTime, '2026-05-21 12:08');
      expect(result.consumptionSummary, '广州 → 阳江北 2026-05-21 12:08');
      expect(result.buyerName, '航天长征火箭技术有限公司');
      expect(result.buyerTaxId, '9110302700238431D');
    },
  );

  test(
    'parseText extracts rail route when stations and train are on one line',
    () {
      final result = EvidenceParseService().parseText('''
电子发票（铁路电子客票）
发票号码:26419138702000376667
开票日期:2026年06月01日
广州站                  G5133                            阳江北站
Guangzhou                                             Yangjiangbei
2026年05月21日     12:08开      04车04A号                          二等座
票价:￥148.00
购买方名称:航天长征火箭技术有限公司
统一社会信用代码:91110302700238431D
''');

      expect(result.amount, 148.00);
      expect(result.travelRoute, '广州 → 阳江北');
      expect(result.travelTime, '2026-05-21 12:08');
      expect(result.consumptionSummary, '广州 → 阳江北 2026-05-21 12:08');
      expect(result.buyerName, '航天长征火箭技术有限公司');
      expect(result.buyerTaxId, '91110302700238431D');
      expect(result.buyerNameValid, isTrue);
      expect(result.buyerTaxIdValid, isTrue);
      expect(result.noteLines, contains('校验：购买方名称已识别；统一社会信用代码校验通过'));
    },
  );

  test('parseText flags invalid unified social credit code checksum', () {
    final result = EvidenceParseService().parseText('''
电子发票
购买方名称: 上海示例采购有限公司
统一社会信用代码: 91310000123456789X
''');

    expect(result.buyerName, '上海示例采购有限公司');
    expect(result.buyerTaxId, '91310000123456789X');
    expect(result.buyerNameValid, isTrue);
    expect(result.buyerTaxIdValid, isFalse);
    expect(result.noteLines, contains('校验：购买方名称已识别；统一社会信用代码校验未通过'));
  });
}
