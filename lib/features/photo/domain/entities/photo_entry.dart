import 'package:equatable/equatable.dart';

final class PhotoEntry extends Equatable {
  final int id;
  final String? ownerUserId;
  final DateTime createdAt;
  final String fileName;
  final String filePath;
  final String? description;
  final String? deviceName;
  final String? projectName;
  final int? projectId;
  final DateTime dateIndexed;

  const PhotoEntry({
    required this.id,
    required this.ownerUserId,
    required this.createdAt,
    required this.fileName,
    required this.filePath,
    required this.description,
    required this.deviceName,
    required this.projectName,
    required this.projectId,
    required this.dateIndexed,
  });

  @override
  List<Object?> get props => [
    id,
    ownerUserId,
    createdAt,
    fileName,
    filePath,
    description,
    deviceName,
    projectName,
    projectId,
    dateIndexed,
  ];
}
