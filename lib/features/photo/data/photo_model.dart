import 'package:isar/isar.dart';

part 'photo_model.g.dart';

@collection
class PhotoItem {
  Id id = Isar.autoIncrement;

  String? ownerUserId; // 本地账号隔离，不参与云同步

  late DateTime createdAt; // 拍摄时间

  late String fileName; // 文件名: IMG_20230101_Device_Desc.jpg

  late String filePath; // 物理存储路径 (绝对路径)

  String? description; // 用户输入的描述

  String? deviceName; // 设备名称

  String? projectName; // 所属项目 (文件夹名称)

  int? projectId; // 本地项目 ID，不参与云同步

  // 索引字段，方便按项目或时间查询
  @Index()
  late DateTime dateIndexed;
}
