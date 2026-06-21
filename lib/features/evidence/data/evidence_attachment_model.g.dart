// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_attachment_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEvidenceAttachmentCollection on Isar {
  IsarCollection<EvidenceAttachment> get evidenceAttachments =>
      this.collection();
}

const EvidenceAttachmentSchema = CollectionSchema(
  name: r'EvidenceAttachment',
  id: 9031872104821019275,
  properties: {
    r'contentHash': PropertySchema(
      id: 0,
      name: r'contentHash',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 2,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'evidenceLocalId': PropertySchema(
      id: 3,
      name: r'evidenceLocalId',
      type: IsarType.long,
    ),
    r'evidenceSyncId': PropertySchema(
      id: 4,
      name: r'evidenceSyncId',
      type: IsarType.string,
    ),
    r'failureMessage': PropertySchema(
      id: 5,
      name: r'failureMessage',
      type: IsarType.string,
    ),
    r'localPath': PropertySchema(
      id: 6,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'mimeType': PropertySchema(
      id: 7,
      name: r'mimeType',
      type: IsarType.string,
    ),
    r'originalFileName': PropertySchema(
      id: 8,
      name: r'originalFileName',
      type: IsarType.string,
    ),
    r'ownerUserId': PropertySchema(
      id: 9,
      name: r'ownerUserId',
      type: IsarType.string,
    ),
    r'remoteStoragePath': PropertySchema(
      id: 10,
      name: r'remoteStoragePath',
      type: IsarType.string,
    ),
    r'sizeBytes': PropertySchema(
      id: 11,
      name: r'sizeBytes',
      type: IsarType.long,
    ),
    r'syncId': PropertySchema(id: 12, name: r'syncId', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 13,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uploadState': PropertySchema(
      id: 14,
      name: r'uploadState',
      type: IsarType.byte,
      enumMap: _EvidenceAttachmentuploadStateEnumValueMap,
    ),
    r'uploadedAt': PropertySchema(
      id: 15,
      name: r'uploadedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _evidenceAttachmentEstimateSize,
  serialize: _evidenceAttachmentSerialize,
  deserialize: _evidenceAttachmentDeserialize,
  deserializeProp: _evidenceAttachmentDeserializeProp,
  idName: r'id',
  indexes: {
    r'syncId': IndexSchema(
      id: 7538593479801827566,
      name: r'syncId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'syncId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'evidenceSyncId': IndexSchema(
      id: -8839145859803490500,
      name: r'evidenceSyncId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'evidenceSyncId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'evidenceLocalId': IndexSchema(
      id: 8036843316767648937,
      name: r'evidenceLocalId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'evidenceLocalId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'deletedAt': IndexSchema(
      id: -8969437169173379604,
      name: r'deletedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deletedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _evidenceAttachmentGetId,
  getLinks: _evidenceAttachmentGetLinks,
  attach: _evidenceAttachmentAttach,
  version: '3.1.0+1',
);

int _evidenceAttachmentEstimateSize(
  EvidenceAttachment object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.contentHash;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.evidenceSyncId.length * 3;
  {
    final value = object.failureMessage;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mimeType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.originalFileName.length * 3;
  {
    final value = object.ownerUserId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.remoteStoragePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.syncId.length * 3;
  return bytesCount;
}

void _evidenceAttachmentSerialize(
  EvidenceAttachment object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.contentHash);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDateTime(offsets[2], object.deletedAt);
  writer.writeLong(offsets[3], object.evidenceLocalId);
  writer.writeString(offsets[4], object.evidenceSyncId);
  writer.writeString(offsets[5], object.failureMessage);
  writer.writeString(offsets[6], object.localPath);
  writer.writeString(offsets[7], object.mimeType);
  writer.writeString(offsets[8], object.originalFileName);
  writer.writeString(offsets[9], object.ownerUserId);
  writer.writeString(offsets[10], object.remoteStoragePath);
  writer.writeLong(offsets[11], object.sizeBytes);
  writer.writeString(offsets[12], object.syncId);
  writer.writeDateTime(offsets[13], object.updatedAt);
  writer.writeByte(offsets[14], object.uploadState.index);
  writer.writeDateTime(offsets[15], object.uploadedAt);
}

EvidenceAttachment _evidenceAttachmentDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EvidenceAttachment();
  object.contentHash = reader.readStringOrNull(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[2]);
  object.evidenceLocalId = reader.readLongOrNull(offsets[3]);
  object.evidenceSyncId = reader.readString(offsets[4]);
  object.failureMessage = reader.readStringOrNull(offsets[5]);
  object.id = id;
  object.localPath = reader.readStringOrNull(offsets[6]);
  object.mimeType = reader.readStringOrNull(offsets[7]);
  object.originalFileName = reader.readString(offsets[8]);
  object.ownerUserId = reader.readStringOrNull(offsets[9]);
  object.remoteStoragePath = reader.readStringOrNull(offsets[10]);
  object.sizeBytes = reader.readLongOrNull(offsets[11]);
  object.syncId = reader.readString(offsets[12]);
  object.updatedAt = reader.readDateTime(offsets[13]);
  object.uploadState =
      _EvidenceAttachmentuploadStateValueEnumMap[reader.readByteOrNull(
        offsets[14],
      )] ??
      EvidenceAttachmentUploadState.pending;
  object.uploadedAt = reader.readDateTimeOrNull(offsets[15]);
  return object;
}

P _evidenceAttachmentDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readString(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (_EvidenceAttachmentuploadStateValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              EvidenceAttachmentUploadState.pending)
          as P;
    case 15:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _EvidenceAttachmentuploadStateEnumValueMap = {
  'pending': 0,
  'uploading': 1,
  'uploaded': 2,
  'failed': 3,
  'deleted': 4,
};
const _EvidenceAttachmentuploadStateValueEnumMap = {
  0: EvidenceAttachmentUploadState.pending,
  1: EvidenceAttachmentUploadState.uploading,
  2: EvidenceAttachmentUploadState.uploaded,
  3: EvidenceAttachmentUploadState.failed,
  4: EvidenceAttachmentUploadState.deleted,
};

Id _evidenceAttachmentGetId(EvidenceAttachment object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _evidenceAttachmentGetLinks(
  EvidenceAttachment object,
) {
  return [];
}

void _evidenceAttachmentAttach(
  IsarCollection<dynamic> col,
  Id id,
  EvidenceAttachment object,
) {
  object.id = id;
}

extension EvidenceAttachmentByIndex on IsarCollection<EvidenceAttachment> {
  Future<EvidenceAttachment?> getBySyncId(String syncId) {
    return getByIndex(r'syncId', [syncId]);
  }

  EvidenceAttachment? getBySyncIdSync(String syncId) {
    return getByIndexSync(r'syncId', [syncId]);
  }

  Future<bool> deleteBySyncId(String syncId) {
    return deleteByIndex(r'syncId', [syncId]);
  }

  bool deleteBySyncIdSync(String syncId) {
    return deleteByIndexSync(r'syncId', [syncId]);
  }

  Future<List<EvidenceAttachment?>> getAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'syncId', values);
  }

  List<EvidenceAttachment?> getAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'syncId', values);
  }

  Future<int> deleteAllBySyncId(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'syncId', values);
  }

  int deleteAllBySyncIdSync(List<String> syncIdValues) {
    final values = syncIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'syncId', values);
  }

  Future<Id> putBySyncId(EvidenceAttachment object) {
    return putByIndex(r'syncId', object);
  }

  Id putBySyncIdSync(EvidenceAttachment object, {bool saveLinks = true}) {
    return putByIndexSync(r'syncId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySyncId(List<EvidenceAttachment> objects) {
    return putAllByIndex(r'syncId', objects);
  }

  List<Id> putAllBySyncIdSync(
    List<EvidenceAttachment> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'syncId', objects, saveLinks: saveLinks);
  }
}

extension EvidenceAttachmentQueryWhereSort
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QWhere> {
  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhere>
  anyEvidenceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'evidenceLocalId'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhere>
  anyDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAt'),
      );
    });
  }
}

extension EvidenceAttachmentQueryWhere
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QWhereClause> {
  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  syncIdEqualTo(String syncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'syncId', value: [syncId]),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  syncIdNotEqualTo(String syncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncId',
                lower: [],
                upper: [syncId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncId',
                lower: [syncId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncId',
                lower: [syncId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'syncId',
                lower: [],
                upper: [syncId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceSyncIdEqualTo(String evidenceSyncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'evidenceSyncId',
          value: [evidenceSyncId],
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceSyncIdNotEqualTo(String evidenceSyncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceSyncId',
                lower: [],
                upper: [evidenceSyncId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceSyncId',
                lower: [evidenceSyncId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceSyncId',
                lower: [evidenceSyncId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceSyncId',
                lower: [],
                upper: [evidenceSyncId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'evidenceLocalId', value: [null]),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'evidenceLocalId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdEqualTo(int? evidenceLocalId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'evidenceLocalId',
          value: [evidenceLocalId],
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdNotEqualTo(int? evidenceLocalId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceLocalId',
                lower: [],
                upper: [evidenceLocalId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceLocalId',
                lower: [evidenceLocalId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceLocalId',
                lower: [evidenceLocalId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'evidenceLocalId',
                lower: [],
                upper: [evidenceLocalId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdGreaterThan(int? evidenceLocalId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'evidenceLocalId',
          lower: [evidenceLocalId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdLessThan(int? evidenceLocalId, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'evidenceLocalId',
          lower: [],
          upper: [evidenceLocalId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  evidenceLocalIdBetween(
    int? lowerEvidenceLocalId,
    int? upperEvidenceLocalId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'evidenceLocalId',
          lower: [lowerEvidenceLocalId],
          includeLower: includeLower,
          upper: [upperEvidenceLocalId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [null]),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtEqualTo(DateTime? deletedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [deletedAt]),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtNotEqualTo(DateTime? deletedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtGreaterThan(DateTime? deletedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [deletedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtLessThan(DateTime? deletedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [],
          upper: [deletedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterWhereClause>
  deletedAtBetween(
    DateTime? lowerDeletedAt,
    DateTime? upperDeletedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [lowerDeletedAt],
          includeLower: includeLower,
          upper: [upperDeletedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension EvidenceAttachmentQueryFilter
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QFilterCondition> {
  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'contentHash'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'contentHash'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contentHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contentHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contentHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contentHash',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contentHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contentHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contentHash',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contentHash',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentHash', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  contentHashIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contentHash', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  deletedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  deletedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceLocalIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'evidenceLocalId'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceLocalIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'evidenceLocalId'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceLocalIdEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'evidenceLocalId', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceLocalIdGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'evidenceLocalId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceLocalIdLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'evidenceLocalId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceLocalIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'evidenceLocalId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'evidenceSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'evidenceSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'evidenceSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'evidenceSyncId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'evidenceSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'evidenceSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'evidenceSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'evidenceSyncId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'evidenceSyncId', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  evidenceSyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'evidenceSyncId', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'failureMessage'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'failureMessage'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'failureMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'failureMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'failureMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'failureMessage',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'failureMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'failureMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'failureMessage',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'failureMessage',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'failureMessage', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  failureMessageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'failureMessage', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localPath'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localPath'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localPath', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localPath', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'mimeType'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'mimeType'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mimeType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mimeType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mimeType', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  mimeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mimeType', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalFileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'originalFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'originalFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'originalFileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'originalFileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'originalFileName', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  originalFileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'originalFileName', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ownerUserId'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ownerUserId'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerUserId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerUserId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerUserId', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  ownerUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerUserId', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteStoragePath'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteStoragePath'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteStoragePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteStoragePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteStoragePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteStoragePath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteStoragePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteStoragePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteStoragePath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteStoragePath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteStoragePath', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  remoteStoragePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteStoragePath', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  sizeBytesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sizeBytes'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  sizeBytesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sizeBytes'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  sizeBytesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sizeBytes', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  sizeBytesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sizeBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  sizeBytesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sizeBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  sizeBytesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sizeBytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'syncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'syncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'syncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'syncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'syncId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncId', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'syncId', value: ''),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadStateEqualTo(EvidenceAttachmentUploadState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uploadState', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadStateGreaterThan(
    EvidenceAttachmentUploadState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uploadState',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadStateLessThan(
    EvidenceAttachmentUploadState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uploadState',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadStateBetween(
    EvidenceAttachmentUploadState lower,
    EvidenceAttachmentUploadState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uploadState',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'uploadedAt'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'uploadedAt'),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uploadedAt', value: value),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uploadedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uploadedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterFilterCondition>
  uploadedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uploadedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension EvidenceAttachmentQueryObject
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QFilterCondition> {}

extension EvidenceAttachmentQueryLinks
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QFilterCondition> {}

extension EvidenceAttachmentQuerySortBy
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QSortBy> {
  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByContentHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentHash', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByContentHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentHash', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByEvidenceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceLocalId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByEvidenceLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceLocalId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByEvidenceSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceSyncId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByEvidenceSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceSyncId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByFailureMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureMessage', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByFailureMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureMessage', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByMimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByMimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByOriginalFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileName', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByOriginalFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileName', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByRemoteStoragePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByRemoteStoragePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortBySizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByUploadState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadState', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByUploadStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadState', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  sortByUploadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.desc);
    });
  }
}

extension EvidenceAttachmentQuerySortThenBy
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QSortThenBy> {
  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByContentHash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentHash', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByContentHashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentHash', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByEvidenceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceLocalId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByEvidenceLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceLocalId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByEvidenceSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceSyncId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByEvidenceSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'evidenceSyncId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByFailureMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureMessage', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByFailureMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failureMessage', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByMimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByMimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByOriginalFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileName', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByOriginalFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalFileName', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByRemoteStoragePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByRemoteStoragePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteStoragePath', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenBySizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sizeBytes', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByUploadState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadState', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByUploadStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadState', Sort.desc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.asc);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QAfterSortBy>
  thenByUploadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uploadedAt', Sort.desc);
    });
  }
}

extension EvidenceAttachmentQueryWhereDistinct
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct> {
  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByContentHash({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentHash', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByEvidenceLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'evidenceLocalId');
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByEvidenceSyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'evidenceSyncId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByFailureMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'failureMessage',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByLocalPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByMimeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mimeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByOriginalFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'originalFileName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByOwnerUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUserId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByRemoteStoragePath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'remoteStoragePath',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctBySizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sizeBytes');
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctBySyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByUploadState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadState');
    });
  }

  QueryBuilder<EvidenceAttachment, EvidenceAttachment, QDistinct>
  distinctByUploadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uploadedAt');
    });
  }
}

extension EvidenceAttachmentQueryProperty
    on QueryBuilder<EvidenceAttachment, EvidenceAttachment, QQueryProperty> {
  QueryBuilder<EvidenceAttachment, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EvidenceAttachment, String?, QQueryOperations>
  contentHashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentHash');
    });
  }

  QueryBuilder<EvidenceAttachment, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<EvidenceAttachment, DateTime?, QQueryOperations>
  deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<EvidenceAttachment, int?, QQueryOperations>
  evidenceLocalIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evidenceLocalId');
    });
  }

  QueryBuilder<EvidenceAttachment, String, QQueryOperations>
  evidenceSyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'evidenceSyncId');
    });
  }

  QueryBuilder<EvidenceAttachment, String?, QQueryOperations>
  failureMessageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failureMessage');
    });
  }

  QueryBuilder<EvidenceAttachment, String?, QQueryOperations>
  localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<EvidenceAttachment, String?, QQueryOperations>
  mimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mimeType');
    });
  }

  QueryBuilder<EvidenceAttachment, String, QQueryOperations>
  originalFileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalFileName');
    });
  }

  QueryBuilder<EvidenceAttachment, String?, QQueryOperations>
  ownerUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUserId');
    });
  }

  QueryBuilder<EvidenceAttachment, String?, QQueryOperations>
  remoteStoragePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteStoragePath');
    });
  }

  QueryBuilder<EvidenceAttachment, int?, QQueryOperations> sizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sizeBytes');
    });
  }

  QueryBuilder<EvidenceAttachment, String, QQueryOperations> syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<EvidenceAttachment, DateTime, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<
    EvidenceAttachment,
    EvidenceAttachmentUploadState,
    QQueryOperations
  >
  uploadStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadState');
    });
  }

  QueryBuilder<EvidenceAttachment, DateTime?, QQueryOperations>
  uploadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uploadedAt');
    });
  }
}
