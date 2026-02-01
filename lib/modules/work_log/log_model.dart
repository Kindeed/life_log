import 'package:isar/isar.dart';

part 'log_model.g.dart';

@collection
class WorkLog {
  Id id = Isar.autoIncrement;

  late DateTime date; // 日期

  @enumerated
  late LogType type; // 类型：工作/休假/出差

  double? overtimeHours; // 加班时长
  
  String? location; // 出差地点 / 请假类型
  
  String? transport; // 交通工具
  
  double? expenses; // 垫付金额

  // --- 【新增】是否已报销 ---
  bool isReimbursed = false; 

  String? note; // 备注
}

enum LogType {
  work,        // 工作
  rest,        // 休息
  leave,       // 请假
  businessTrip // 出差
}