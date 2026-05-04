import 'package:isar/isar.dart';

part 'photo_model.g.dart';

@collection
class PhotoItem {
  Id id = Isar.autoIncrement;

  late DateTime createdAt; // 拍摄时间

  late String fileName; // 文件名: IMG_20230101_Device_Desc.jpg

  late String filePath; // 物理存储路径 (绝对路径)

  String? description; // 用户输入的描述

  String? deviceName; // 设备名称

  String? projectName; // 所属项目 (文件夹名称)

  // 旧版本本地库没有该字段，保持可空以兼容升级迁移。
  @Index()
  DateTime? dateIndexed;
}
