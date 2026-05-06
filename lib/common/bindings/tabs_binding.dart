import 'package:get/get.dart';
import '../../modules/tabs/tabs_controller.dart';
import '../../modules/work_log/work_log_controller.dart';
import '../../modules/work_log/work_log_repository.dart';
import '../../modules/subscription/subscription_controller.dart';
import '../../modules/subscription/subscription_repository.dart';
import '../../modules/photo/photo_controller.dart';
import '../../modules/photo/photo_repository.dart';
import '../../modules/evidence/evidence_controller.dart';
import '../../modules/evidence/evidence_repository.dart';
import '../../modules/expense/expense_record_controller.dart';
import '../../modules/expense/expense_record_repository.dart';
import '../../modules/project/project_controller.dart';
import '../../modules/project/project_repository.dart';
import '../../modules/statistics/statistics_controller.dart';
import '../../modules/profile/profile_controller.dart';

class TabsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TabsController(), fenix: true);
    Get.lazyPut(() => WorkLogRepository(), fenix: true);
    Get.lazyPut(() => WorkLogController(), fenix: true);
    Get.lazyPut(() => SubscriptionRepository(), fenix: true);
    Get.lazyPut(() => SubscriptionController(), fenix: true);
    Get.lazyPut(() => ProjectRepository(), fenix: true);
    Get.lazyPut(() => ProjectController(), fenix: true);
    Get.lazyPut(() => ExpenseRecordRepository(), fenix: true);
    Get.lazyPut(() => ExpenseRecordController(), fenix: true);
    Get.lazyPut(() => PhotoRepository(), fenix: true);
    Get.lazyPut(() => PhotoController(), fenix: true);
    Get.lazyPut(() => EvidenceRepository(), fenix: true);
    Get.lazyPut(() => EvidenceController(), fenix: true);
    Get.lazyPut(() => StatisticsController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
  }
}
