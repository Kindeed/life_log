import 'package:life_log/common/utils/date_utils.dart';
import 'package:lunar/lunar.dart';

enum WorkLogDayMetadataKind { lunar, festival, solarTerm }

final class WorkLogDayMetadata {
  final DateTime day;
  final String text;
  final WorkLogDayMetadataKind kind;
  final bool? holidayIsWork;

  const WorkLogDayMetadata({
    required this.day,
    required this.text,
    required this.kind,
    required this.holidayIsWork,
  });
}

WorkLogDayMetadata buildWorkLogDayMetadata(DateTime day) {
  final localDay = dateOnlyLocal(day);
  final lunar = Lunar.fromDate(localDay);
  final festivals = lunar.getFestivals();
  final jieQi = lunar.getJieQi();
  final holiday = HolidayUtil.getHoliday(
    '${localDay.year}-${localDay.month.toString().padLeft(2, '0')}-${localDay.day.toString().padLeft(2, '0')}',
  );

  if (jieQi.isNotEmpty) {
    return WorkLogDayMetadata(
      day: localDay,
      text: jieQi,
      kind: WorkLogDayMetadataKind.solarTerm,
      holidayIsWork: holiday?.isWork(),
    );
  }
  if (festivals.isNotEmpty) {
    return WorkLogDayMetadata(
      day: localDay,
      text: festivals[0],
      kind: WorkLogDayMetadataKind.festival,
      holidayIsWork: holiday?.isWork(),
    );
  }
  return WorkLogDayMetadata(
    day: localDay,
    text: lunar.getDayInChinese(),
    kind: WorkLogDayMetadataKind.lunar,
    holidayIsWork: holiday?.isWork(),
  );
}
