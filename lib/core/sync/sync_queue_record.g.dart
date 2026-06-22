// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncQueueRecordCollection on Isar {
  IsarCollection<SyncQueueRecord> get syncQueueRecords => this.collection();
}

const SyncQueueRecordSchema = CollectionSchema(
  name: r'SyncQueueRecord',
  id: -9010864966180489763,
  properties: {
    r'attemptCount': PropertySchema(
      id: 0,
      name: r'attemptCount',
      type: IsarType.long,
    ),
    r'entityKey': PropertySchema(
      id: 1,
      name: r'entityKey',
      type: IsarType.string,
    ),
    r'entityName': PropertySchema(
      id: 2,
      name: r'entityName',
      type: IsarType.string,
    ),
    r'lastAttemptAt': PropertySchema(
      id: 3,
      name: r'lastAttemptAt',
      type: IsarType.dateTime,
    ),
    r'lastError': PropertySchema(
      id: 4,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'nextAttemptAt': PropertySchema(
      id: 5,
      name: r'nextAttemptAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _syncQueueRecordEstimateSize,
  serialize: _syncQueueRecordSerialize,
  deserialize: _syncQueueRecordDeserialize,
  deserializeProp: _syncQueueRecordDeserializeProp,
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
    r'entityKey': IndexSchema(
      id: -9036825346649120373,
      name: r'entityKey',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityKey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _syncQueueRecordGetId,
  getLinks: _syncQueueRecordGetLinks,
  attach: _syncQueueRecordAttach,
  version: '3.1.0+1',
);

int _syncQueueRecordEstimateSize(
  SyncQueueRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityKey.length * 3;
  bytesCount += 3 + object.entityName.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncQueueRecordSerialize(
  SyncQueueRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.attemptCount);
  writer.writeString(offsets[1], object.entityKey);
  writer.writeString(offsets[2], object.entityName);
  writer.writeDateTime(offsets[3], object.lastAttemptAt);
  writer.writeString(offsets[4], object.lastError);
  writer.writeDateTime(offsets[5], object.nextAttemptAt);
}

SyncQueueRecord _syncQueueRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncQueueRecord();
  object.attemptCount = reader.readLong(offsets[0]);
  object.entityKey = reader.readString(offsets[1]);
  object.entityName = reader.readString(offsets[2]);
  object.id = id;
  object.lastAttemptAt = reader.readDateTimeOrNull(offsets[3]);
  object.lastError = reader.readStringOrNull(offsets[4]);
  object.nextAttemptAt = reader.readDateTime(offsets[5]);
  return object;
}

P _syncQueueRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncQueueRecordGetId(SyncQueueRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncQueueRecordGetLinks(SyncQueueRecord object) {
  return [];
}

void _syncQueueRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  SyncQueueRecord object,
) {
  object.id = id;
}

extension SyncQueueRecordQueryWhereSort
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QWhere> {
  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncQueueRecordQueryWhere
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QWhereClause> {
  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause>
  entityNameEqualTo(String entityName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityName', value: [entityName]),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause>
  entityKeyEqualTo(String entityKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityKey', value: [entityKey]),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterWhereClause>
  entityKeyNotEqualTo(String entityKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [],
                upper: [entityKey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [entityKey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [entityKey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityKey',
                lower: [],
                upper: [entityKey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SyncQueueRecordQueryFilter
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QFilterCondition> {
  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  attemptCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attemptCount', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  attemptCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attemptCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  attemptCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attemptCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  attemptCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attemptCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityKey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityKey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityKey', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityKey', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityName', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  entityNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityName', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
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

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastAttemptAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastAttemptAt'),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastAttemptAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastAttemptAt'),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastAttemptAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastAttemptAt', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastAttemptAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastAttemptAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastAttemptAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastAttemptAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastAttemptAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastAttemptAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastError',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastError',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  nextAttemptAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextAttemptAt', value: value),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  nextAttemptAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextAttemptAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  nextAttemptAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextAttemptAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterFilterCondition>
  nextAttemptAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextAttemptAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SyncQueueRecordQueryObject
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QFilterCondition> {}

extension SyncQueueRecordQueryLinks
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QFilterCondition> {}

extension SyncQueueRecordQuerySortBy
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QSortBy> {
  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByEntityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByEntityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByEntityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByEntityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByLastAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByLastAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  sortByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }
}

extension SyncQueueRecordQuerySortThenBy
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QSortThenBy> {
  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByAttemptCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'attemptCount', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByEntityKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByEntityKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityKey', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByEntityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByEntityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityName', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByLastAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByLastAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastAttemptAt', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.asc);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QAfterSortBy>
  thenByNextAttemptAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextAttemptAt', Sort.desc);
    });
  }
}

extension SyncQueueRecordQueryWhereDistinct
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct> {
  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct>
  distinctByAttemptCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attemptCount');
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct>
  distinctByEntityKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityKey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct>
  distinctByEntityName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct>
  distinctByLastAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastAttemptAt');
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct>
  distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncQueueRecord, SyncQueueRecord, QDistinct>
  distinctByNextAttemptAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextAttemptAt');
    });
  }
}

extension SyncQueueRecordQueryProperty
    on QueryBuilder<SyncQueueRecord, SyncQueueRecord, QQueryProperty> {
  QueryBuilder<SyncQueueRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncQueueRecord, int, QQueryOperations> attemptCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attemptCount');
    });
  }

  QueryBuilder<SyncQueueRecord, String, QQueryOperations> entityKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityKey');
    });
  }

  QueryBuilder<SyncQueueRecord, String, QQueryOperations> entityNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityName');
    });
  }

  QueryBuilder<SyncQueueRecord, DateTime?, QQueryOperations>
  lastAttemptAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastAttemptAt');
    });
  }

  QueryBuilder<SyncQueueRecord, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<SyncQueueRecord, DateTime, QQueryOperations>
  nextAttemptAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextAttemptAt');
    });
  }
}
