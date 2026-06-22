import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:life_log/features/work_log/presentation/widgets/day_cell.dart';

void main() {
  testWidgets('DayCell avoids overflow in short default widget viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 90,
                  height: 46,
                  child: DayCell(
                    day: DateTime(2026, 5, 12),
                    focusedDay: DateTime(2026, 5, 1),
                    selectedDay: DateTime(2026, 5, 12),
                    calendarFormat: CalendarFormat.month,
                    isDark: false,
                    textPrimary: Colors.black,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    expect(tester.takeException(), isNull);
  });

  test('DayCell renders from explicit props instead of controller cache', () {
    final source = File(
      'lib/features/work_log/presentation/widgets/day_cell.dart',
    ).readAsStringSync();
    final legacyWidget = File('lib/modules/work_log/widgets/day_cell.dart');

    expect(source, isNot(contains("package:get/get.dart")));
    expect(source, isNot(contains("work_log_model.dart")));
    expect(source, contains('WorkLogEntry? event'));
    expect(source, contains('WorkLogDayMetadata? metadata'));
    expect(source, isNot(contains('Lunar.fromDate')));
    expect(source, isNot(contains('HolidayUtil.getHoliday')));
    expect(source, isNot(contains('WorkLogController')));
    expect(source, isNot(contains('Obx')));
    expect(source, isNot(contains('logic.')));
    expect(source, contains('selectedDay'));
    expect(source, contains('calendarFormat'));
    expect(legacyWidget.existsSync(), isFalse);
  });
}
