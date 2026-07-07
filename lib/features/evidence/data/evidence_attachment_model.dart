import 'package:isar/isar.dart';

part 'evidence_attachment_model.g.dart';

@collection
class EvidenceAttachment {
  Id id = Isar.autoIncrement;

  String? ownerUserId;

  @Index()
  late String syncId;

  @Index()
  late String evidenceSyncId;

  @Index()
  int? evidenceLocalId;

  String? localPath;

  String? remoteStoragePath;

  late String originalFileName;

  String? contentHash;

  int? sizeBytes;

  String? mimeType;

  @enumerated
  EvidenceAttachmentUploadState uploadState =
      EvidenceAttachmentUploadState.pending;

  late DateTime createdAt;

  late DateTime updatedAt;

  DateTime? uploadedAt;

  @Index()
  DateTime? deletedAt;

  String? failureMessage;
}

enum EvidenceAttachmentUploadState {
  pending,
  uploading,
  uploaded,
  failed,
  deleted,
}
