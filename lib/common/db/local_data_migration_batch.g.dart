// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_data_migration_batch.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalDataMigrationBatchCollection on Isar {
  IsarCollection<LocalDataMigrationBatch> get localDataMigrationBatchs =>
      this.collection();
}

const LocalDataMigrationBatchSchema = CollectionSchema(
  name: r'LocalDataMigrationBatch',
  id: -2010957898742444838,
  properties: {
    r'completedAt': PropertySchema(
      id: 0,
      name: r'completedAt',
      type: IsarType.dateTime,
    ),
    r'fromOwner': PropertySchema(
      id: 1,
      name: r'fromOwner',
      type: IsarType.string,
    ),
    r'recordCount': PropertySchema(
      id: 2,
      name: r'recordCount',
      type: IsarType.long,
    ),
    r'startedAt': PropertySchema(
      id: 3,
      name: r'startedAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(id: 4, name: r'status', type: IsarType.string),
    r'toUserId': PropertySchema(
      id: 5,
      name: r'toUserId',
      type: IsarType.string,
    ),
  },
  estimateSize: _localDataMigrationBatchEstimateSize,
  serialize: _localDataMigrationBatchSerialize,
  deserialize: _localDataMigrationBatchDeserialize,
  deserializeProp: _localDataMigrationBatchDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _localDataMigrationBatchGetId,
  getLinks: _localDataMigrationBatchGetLinks,
  attach: _localDataMigrationBatchAttach,
  version: '3.1.0+1',
);

int _localDataMigrationBatchEstimateSize(
  LocalDataMigrationBatch object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.fromOwner;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.toUserId.length * 3;
  return bytesCount;
}

void _localDataMigrationBatchSerialize(
  LocalDataMigrationBatch object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.completedAt);
  writer.writeString(offsets[1], object.fromOwner);
  writer.writeLong(offsets[2], object.recordCount);
  writer.writeDateTime(offsets[3], object.startedAt);
  writer.writeString(offsets[4], object.status);
  writer.writeString(offsets[5], object.toUserId);
}

LocalDataMigrationBatch _localDataMigrationBatchDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalDataMigrationBatch();
  object.completedAt = reader.readDateTimeOrNull(offsets[0]);
  object.fromOwner = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.recordCount = reader.readLong(offsets[2]);
  object.startedAt = reader.readDateTime(offsets[3]);
  object.status = reader.readString(offsets[4]);
  object.toUserId = reader.readString(offsets[5]);
  return object;
}

P _localDataMigrationBatchDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localDataMigrationBatchGetId(LocalDataMigrationBatch object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localDataMigrationBatchGetLinks(
  LocalDataMigrationBatch object,
) {
  return [];
}

void _localDataMigrationBatchAttach(
  IsarCollection<dynamic> col,
  Id id,
  LocalDataMigrationBatch object,
) {
  object.id = id;
}

extension LocalDataMigrationBatchQueryWhereSort
    on QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QWhere> {
  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalDataMigrationBatchQueryWhere
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QWhereClause
        > {
  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterWhereClause
  >
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

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterWhereClause
  >
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
}

extension LocalDataMigrationBatchQueryFilter
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QFilterCondition
        > {
  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  completedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'completedAt'),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  completedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'completedAt'),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  completedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'completedAt', value: value),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  completedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  completedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'completedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  completedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'completedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fromOwner'),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fromOwner'),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fromOwner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fromOwner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fromOwner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fromOwner',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fromOwner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fromOwner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fromOwner',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fromOwner',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fromOwner', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  fromOwnerIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fromOwner', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  recordCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'recordCount', value: value),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  recordCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'recordCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  recordCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'recordCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  recordCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'recordCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  startedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'startedAt', value: value),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  startedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'startedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  startedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'startedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  startedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'startedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'toUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'toUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'toUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'toUserId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'toUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'toUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'toUserId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'toUserId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'toUserId', value: ''),
      );
    });
  }

  QueryBuilder<
    LocalDataMigrationBatch,
    LocalDataMigrationBatch,
    QAfterFilterCondition
  >
  toUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'toUserId', value: ''),
      );
    });
  }
}

extension LocalDataMigrationBatchQueryObject
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QFilterCondition
        > {}

extension LocalDataMigrationBatchQueryLinks
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QFilterCondition
        > {}

extension LocalDataMigrationBatchQuerySortBy
    on QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QSortBy> {
  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByFromOwner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromOwner', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByFromOwnerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromOwner', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByRecordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByRecordCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByToUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toUserId', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  sortByToUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toUserId', Sort.desc);
    });
  }
}

extension LocalDataMigrationBatchQuerySortThenBy
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QSortThenBy
        > {
  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByCompletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByFromOwner() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromOwner', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByFromOwnerDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fromOwner', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByRecordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByRecordCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'recordCount', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByStartedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startedAt', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByToUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toUserId', Sort.asc);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QAfterSortBy>
  thenByToUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toUserId', Sort.desc);
    });
  }
}

extension LocalDataMigrationBatchQueryWhereDistinct
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QDistinct
        > {
  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QDistinct>
  distinctByCompletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completedAt');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QDistinct>
  distinctByFromOwner({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fromOwner', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QDistinct>
  distinctByRecordCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'recordCount');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QDistinct>
  distinctByStartedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startedAt');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QDistinct>
  distinctByStatus({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalDataMigrationBatch, LocalDataMigrationBatch, QDistinct>
  distinctByToUserId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toUserId', caseSensitive: caseSensitive);
    });
  }
}

extension LocalDataMigrationBatchQueryProperty
    on
        QueryBuilder<
          LocalDataMigrationBatch,
          LocalDataMigrationBatch,
          QQueryProperty
        > {
  QueryBuilder<LocalDataMigrationBatch, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, DateTime?, QQueryOperations>
  completedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completedAt');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, String?, QQueryOperations>
  fromOwnerProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fromOwner');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, int, QQueryOperations>
  recordCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'recordCount');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, DateTime, QQueryOperations>
  startedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startedAt');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, String, QQueryOperations>
  statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<LocalDataMigrationBatch, String, QQueryOperations>
  toUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toUserId');
    });
  }
}
