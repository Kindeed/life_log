// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_conflict_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncConflictRecordCollection on Isar {
  IsarCollection<SyncConflictRecord> get syncConflictRecords =>
      this.collection();
}

const SyncConflictRecordSchema = CollectionSchema(
  name: r'SyncConflictRecord',
  id: -6035372110509361303,
  properties: {
    r'conflictType': PropertySchema(
      id: 0,
      name: r'conflictType',
      type: IsarType.string,
    ),
    r'detectedAt': PropertySchema(
      id: 1,
      name: r'detectedAt',
      type: IsarType.dateTime,
    ),
    r'entityName': PropertySchema(
      id: 2,
      name: r'entityName',
      type: IsarType.string,
    ),
    r'entitySyncId': PropertySchema(
      id: 3,
      name: r'entitySyncId',
      type: IsarType.string,
    ),
    r'localId': PropertySchema(id: 4, name: r'localId', type: IsarType.string),
    r'localUpdatedAt': PropertySchema(
      id: 5,
      name: r'localUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'localVersion': PropertySchema(
      id: 6,
      name: r'localVersion',
      type: IsarType.long,
    ),
    r'message': PropertySchema(id: 7, name: r'message', type: IsarType.string),
    r'remoteId': PropertySchema(
      id: 8,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'remoteUpdatedAt': PropertySchema(
      id: 9,
      name: r'remoteUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'remoteVersion': PropertySchema(
      id: 10,
      name: r'remoteVersion',
      type: IsarType.long,
    ),
    r'resolution': PropertySchema(
      id: 11,
      name: r'resolution',
      type: IsarType.string,
    ),
    r'resolvedAt': PropertySchema(
      id: 12,
      name: r'resolvedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _syncConflictRecordEstimateSize,
  serialize: _syncConflictRecordSerialize,
  deserialize: _syncConflictRecordDeserialize,
  deserializeProp: _syncConflictRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'entityName': IndexSchema(
      id: -1749110902930819992,
      name: r'entityName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityName',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'entitySyncId': IndexSchema(
      id: 4521005945948128129,
      name: r'entitySyncId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entitySyncId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncConflictRecordGetId,
  getLinks: _syncConflictRecordGetLinks,
  attach: _syncConflictRecordAttach,
  version: '3.1.0+1',
);

int _syncConflictRecordEstimateSize(
  SyncConflictRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.conflictType.length * 3;
  bytesCount += 3 + object.entityName.length * 3;
  {
    final value = object.entitySyncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.message.length * 3;
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.resolution;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncConflictRecordSerialize(
  SyncConflictRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.conflictType);
  writer.writeDateTime(offsets[1], object.detectedAt);
  writer.writeString(offsets[2], object.entityName);
  writer.writeString(offsets[3], object.entitySyncId);
  writer.writeString(offsets[4], object.localId);
  writer.writeDateTime(offsets[5], object.localUpdatedAt);
  writer.writeLong(offsets[6], object.localVersion);
  writer.writeString(offsets[7], object.message);
  writer.writeString(offsets[8], object.remoteId);
  writer.writeDateTime(offsets[9], object.remoteUpdatedAt);
  writer.writeLong(offsets[10], object.remoteVersion);
  writer.writeString(offsets[11], object.resolution);
  writer.writeDateTime(offsets[12], object.resolvedAt);
}

SyncConflictRecord _syncConflictRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncConflictRecord();
  object.conflictType = reader.readString(offsets[0]);
  object.detectedAt = reader.readDateTime(offsets[1]);
  object.entityName = reader.readString(offsets[2]);
  object.entitySyncId = reader.readStringOrNull(offsets[3]);
  object.id = id;
  object.localId = reader.readStringOrNull(offsets[4]);
  object.localUpdatedAt = reader.readDateTimeOrNull(offsets[5]);
  object.localVersion = reader.readLongOrNull(offsets[6]);
  object.message = reader.readString(offsets[7]);
  object.remoteId = reader.readStringOrNull(offsets[8]);
  object.remoteUpdatedAt = reader.readDateTimeOrNull(offsets[9]);
  object.remoteVersion = reader.readLongOrNull(offsets[10]);
  object.resolution = reader.readStringOrNull(offsets[11]);
  object.resolvedAt = reader.readDateTimeOrNull(offsets[12]);
  return object;
}

P _syncConflictRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readStringOrNull(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncConflictRecordGetId(SyncConflictRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncConflictRecordGetLinks(
  SyncConflictRecord object,
) {
  return [];
}

void _syncConflictRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  SyncConflictRecord object,
) {
  object.id = id;
}

extension SyncConflictRecordQueryWhereSort
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QWhere> {
  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncConflictRecordQueryWhere
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QWhereClause> {
  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
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

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
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

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  entityNameEqualTo(String entityName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityName', value: [entityName]),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  entityNameNotEqualTo(String entityName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityName',
                lower: [],
                upper: [entityName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityName',
                lower: [entityName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityName',
                lower: [entityName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityName',
                lower: [],
                upper: [entityName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  entitySyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entitySyncId', value: [null]),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  entitySyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'entitySyncId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  entitySyncIdEqualTo(String? entitySyncId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'entitySyncId',
          value: [entitySyncId],
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterWhereClause>
  entitySyncIdNotEqualTo(String? entitySyncId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entitySyncId',
                lower: [],
                upper: [entitySyncId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entitySyncId',
                lower: [entitySyncId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entitySyncId',
                lower: [entitySyncId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entitySyncId',
                lower: [],
                upper: [entitySyncId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SyncConflictRecordQueryFilter
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QFilterCondition> {
  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conflictType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conflictType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conflictType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conflictType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conflictType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conflictType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conflictType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conflictType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conflictType', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  conflictTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conflictType', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  detectedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'detectedAt', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  detectedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'detectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  detectedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'detectedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  detectedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'detectedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityName', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entityNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityName', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'entitySyncId'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'entitySyncId'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entitySyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entitySyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entitySyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entitySyncId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entitySyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entitySyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entitySyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entitySyncId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entitySyncId', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  entitySyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entitySyncId', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localId'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localId'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localId', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localId', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localUpdatedAt'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localUpdatedAt'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localUpdatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localUpdatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localUpdatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localVersion'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localVersion'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localVersionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localVersion', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localVersionGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localVersionLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  localVersionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'message',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'message',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'message', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'message', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteId'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteId'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'remoteId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'remoteId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteId', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'remoteId', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteUpdatedAt'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteUpdatedAt'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteUpdatedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteUpdatedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteUpdatedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteUpdatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteUpdatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteUpdatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteVersionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteVersion'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteVersionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteVersion'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteVersionEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteVersion', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteVersionGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteVersionLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteVersion',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  remoteVersionBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteVersion',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolution'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolution'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolution',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'resolution',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'resolution',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolution', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolutionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'resolution', value: ''),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolvedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'resolvedAt'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolvedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'resolvedAt'),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolvedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'resolvedAt', value: value),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolvedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'resolvedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolvedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'resolvedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterFilterCondition>
  resolvedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'resolvedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SyncConflictRecordQueryObject
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QFilterCondition> {}

extension SyncConflictRecordQueryLinks
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QFilterCondition> {}

extension SyncConflictRecordQuerySortBy
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QSortBy> {
  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByConflictType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictType', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByConflictTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictType', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByDetectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByDetectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByEntityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByEntityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByEntitySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entitySyncId', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByEntitySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entitySyncId', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByLocalUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByLocalVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByLocalVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByRemoteUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByRemoteVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByRemoteVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByResolution() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByResolutionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  sortByResolvedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.desc);
    });
  }
}

extension SyncConflictRecordQuerySortThenBy
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QSortThenBy> {
  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByConflictType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictType', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByConflictTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictType', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByDetectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByDetectedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByEntityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByEntityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByEntitySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entitySyncId', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByEntitySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entitySyncId', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByLocalId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByLocalIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localId', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByLocalUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByLocalVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByLocalVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localVersion', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByRemoteUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByRemoteVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByRemoteVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByResolution() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByResolutionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolution', Sort.desc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.asc);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QAfterSortBy>
  thenByResolvedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resolvedAt', Sort.desc);
    });
  }
}

extension SyncConflictRecordQueryWhereDistinct
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct> {
  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByConflictType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'conflictType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByDetectedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedAt');
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByEntityName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByEntitySyncId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entitySyncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByLocalId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByLocalUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localUpdatedAt');
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByLocalVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localVersion');
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByMessage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByRemoteId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteUpdatedAt');
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByRemoteVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteVersion');
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByResolution({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resolution', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncConflictRecord, SyncConflictRecord, QDistinct>
  distinctByResolvedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resolvedAt');
    });
  }
}

extension SyncConflictRecordQueryProperty
    on QueryBuilder<SyncConflictRecord, SyncConflictRecord, QQueryProperty> {
  QueryBuilder<SyncConflictRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncConflictRecord, String, QQueryOperations>
  conflictTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conflictType');
    });
  }

  QueryBuilder<SyncConflictRecord, DateTime, QQueryOperations>
  detectedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedAt');
    });
  }

  QueryBuilder<SyncConflictRecord, String, QQueryOperations>
  entityNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityName');
    });
  }

  QueryBuilder<SyncConflictRecord, String?, QQueryOperations>
  entitySyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entitySyncId');
    });
  }

  QueryBuilder<SyncConflictRecord, String?, QQueryOperations>
  localIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localId');
    });
  }

  QueryBuilder<SyncConflictRecord, DateTime?, QQueryOperations>
  localUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localUpdatedAt');
    });
  }

  QueryBuilder<SyncConflictRecord, int?, QQueryOperations>
  localVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localVersion');
    });
  }

  QueryBuilder<SyncConflictRecord, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<SyncConflictRecord, String?, QQueryOperations>
  remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<SyncConflictRecord, DateTime?, QQueryOperations>
  remoteUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteUpdatedAt');
    });
  }

  QueryBuilder<SyncConflictRecord, int?, QQueryOperations>
  remoteVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteVersion');
    });
  }

  QueryBuilder<SyncConflictRecord, String?, QQueryOperations>
  resolutionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolution');
    });
  }

  QueryBuilder<SyncConflictRecord, DateTime?, QQueryOperations>
  resolvedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resolvedAt');
    });
  }
}
