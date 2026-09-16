import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('More owns the secondary destination directory', () {
    final source = File(
      'lib/features/more/presentation/more_view.dart',
    ).readAsStringSync();

    expect(source, contains("title: '个人与账户'"));
    expect(source, contains('ProfileView'));
    expect(source, isNot(contains('SyncCenterView')));
    expect(source, isNot(contains('云同步中心')));
    expect(source, isNot(contains('DeveloperView')));
    expect(source, contains("title: '记录与分析'"));
    expect(source, contains("title: '工具'"));
    expect(source, contains("title: '应用'"));
    expect(source, contains("title: '全部费用记录'"));
    expect(source, contains("title: '统计面板'"));
    expect(source, contains("title: '订阅管理'"));
    expect(source, contains("title: '遥测计算器'"));
    expect(source, contains("title: '外观设置'"));
    expect(source, contains("title: '数据备份与恢复'"));
    expect(source, contains("title: '关于应用'"));
  });

  test('quick action labels are shared and canonical', () {
    final source = File(
      'lib/features/more/presentation/quick_action_contract.dart',
    ).readAsStringSync();

    expect(source, contains("addPhoto = '添加照片'"));
    expect(source, contains("recordExpense = '记录支出'"));
    expect(source, contains("addEvidence = '添加凭证'"));
    expect(source, contains("recordWorkLog = '记录工时'"));
  });
}
