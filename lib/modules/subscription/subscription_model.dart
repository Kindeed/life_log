import 'package:isar/isar.dart';

part 'subscription_model.g.dart';

@collection
class Subscription {
  Id id = Isar.autoIncrement;

  late String name;      
  
  double? price; // 价格

  @enumerated
  // 【修改点 1】类型改为 SubscriptionCycle，默认值也对应修改
  SubscriptionCycle cycle = SubscriptionCycle.monthly; 

  late DateTime nextPaymentDate; 

  // --- 保留你原有的字段 ---
  int reminderDays = 1;  
  String? note;          
  int? sortIndex; 
}

// 【修改点 2】枚举名称改为 SubscriptionCycle (配合统计页面的代码)
enum SubscriptionCycle {
  monthly,
  yearly,
  oneTime, // 保留了你原有的 oneTime
}