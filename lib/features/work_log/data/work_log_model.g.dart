// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_log_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetWorkLogCollection on Isar {
  IsarCollection<WorkLog> get workLogs => this.collection();
}

const WorkLogSchema = CollectionSchema(
  name: r'WorkLog',
  id: 9172451265745087192,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'date': PropertySchema(id: 1, name: r'date', type: IsarType.dateTime),
    r'deletedAt': PropertySchema(
      id: 2,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'expenses': PropertySchema(
      id: 3,
      name: r'expenses',
      type: IsarType.double,
    ),
    r'isDirty': PropertySchema(id: 4, name: r'isDirty', type: IsarType.bool),
    r'isReimbursed': PropertySchema(
      id: 5,
      name: r'isReimbursed',
      type: IsarType.bool,
    ),
    r'location': PropertySchema(
      id: 6,
      name: r'location',
      type: IsarType.string,
    ),
    r'note': PropertySchema(id: 7, name: r'note', type: IsarType.string),
    r'overtimeHours': PropertySchema(
      id: 8,
      name: r'overtimeHours',
      type: IsarType.double,
    ),
    r'ownerUserId': PropertySchema(
      id: 9,
      name: r'ownerUserId',
      type: IsarType.string,
    ),
    r'pendingDelete': PropertySchema(
      id: 10,
      name: r'pendingDelete',
      type: IsarType.bool,
    ),
    r'projectId': PropertySchema(
      id: 11,
      name: r'projectId',
      type: IsarType.long,
    ),
    r'projectName': PropertySchema(
      id: 12,
      name: r'projectName',
      type: IsarType.string,
    ),
    r'projectStageName': PropertySchema(
      id: 13,
      name: r'projectStageName',
      type: IsarType.string,
    ),
    r'projectSyncId': PropertySchema(
      id: 14,
      name: r'projectSyncId',
      type: IsarType.string,
    ),
    r'remoteId': PropertySchema(id: 15, name: r'remoteId', type: IsarType.long),
    r'remoteUpdatedAt': PropertySchema(
      id: 16,
      name: r'remoteUpdatedAt',
      type: IsarType.dateTime,
    ),
    r'remoteVersion': PropertySchema(
      id: 17,
      name: r'remoteVersion',
      type: IsarType.long,
    ),
    r'syncId': PropertySchema(id: 18, name: r'syncId', type: IsarType.string),
    r'syncedAt': PropertySchema(
      id: 19,
      name: r'syncedAt',
      type: IsarType.dateTime,
    ),
    r'transport': PropertySchema(
      id: 20,
      name: r'transport',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 21,
      name: r'type',
      type: IsarType.byte,
      enumMap: _WorkLogtypeEnumValueMap,
    ),
    r'updatedAt': PropertySchema(
      id: 22,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },
  estimateSize: _workLogEstimateSize,
  serialize: _workLogSerialize,
  deserialize: _workLogDeserialize,
  deserializeProp: _workLogDeserializeProp,
  idName: r'id',
  indexes: {
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
    r'projectId': IndexSchema(
      id: 3305656282123791113,
      name: r'projectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'projectSyncId': IndexSchema(
      id: -4233159093434817676,
      name: r'projectSyncId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectSyncId',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'projectName': IndexSchema(
      id: 7457588439029069741,
      name: r'projectName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectName',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
    r'projectStageName': IndexSchema(
      id: -4550830919915173385,
      name: r'projectStageName',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectStageName',
          type: IndexType.hash,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},
  getId: _workLogGetId,
  getLinks: _workLogGetLinks,
  attach: _workLogAttach,
  version: '3.1.0+1',
);

int _workLogEstimateSize(
  WorkLog object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.location;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.ownerUserId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.projectName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.projectStageName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.projectSyncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.syncId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.transport;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _workLogSerialize(
  WorkLog object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeDateTime(offsets[1], object.date);
  writer.writeDateTime(offsets[2], object.deletedAt);
  writer.writeDouble(offsets[3], object.expenses);
  writer.writeBool(offsets[4], object.isDirty);
  writer.writeBool(offsets[5], object.isReimbursed);
  writer.writeString(offsets[6], object.location);
  writer.writeString(offsets[7], object.note);
  writer.writeDouble(offsets[8], object.overtimeHours);
  writer.writeString(offsets[9], object.ownerUserId);
  writer.writeBool(offsets[10], object.pendingDelete);
  writer.writeLong(offsets[11], object.projectId);
  writer.writeString(offsets[12], object.projectName);
  writer.writeString(offsets[13], object.projectStageName);
  writer.writeString(offsets[14], object.projectSyncId);
  writer.writeLong(offsets[15], object.remoteId);
  writer.writeDateTime(offsets[16], object.remoteUpdatedAt);
  writer.writeLong(offsets[17], object.remoteVersion);
  writer.writeString(offsets[18], object.syncId);
  writer.writeDateTime(offsets[19], object.syncedAt);
  writer.writeString(offsets[20], object.transport);
  writer.writeByte(offsets[21], object.type.index);
  writer.writeDateTime(offsets[22], object.updatedAt);
}

WorkLog _workLogDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = WorkLog();
  object.createdAt = reader.readDateTimeOrNull(offsets[0]);
  object.date = reader.readDateTime(offsets[1]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[2]);
  object.expenses = reader.readDoubleOrNull(offsets[3]);
  object.id = id;
  object.isDirty = reader.readBool(offsets[4]);
  object.isReimbursed = reader.readBool(offsets[5]);
  object.location = reader.readStringOrNull(offsets[6]);
  object.note = reader.readStringOrNull(offsets[7]);
  object.overtimeHours = reader.readDoubleOrNull(offsets[8]);
  object.ownerUserId = reader.readStringOrNull(offsets[9]);
  object.pendingDelete = reader.readBool(offsets[10]);
  object.projectId = reader.readLongOrNull(offsets[11]);
  object.projectName = reader.readStringOrNull(offsets[12]);
  object.projectStageName = reader.readStringOrNull(offsets[13]);
  object.projectSyncId = reader.readStringOrNull(offsets[14]);
  object.remoteId = reader.readLongOrNull(offsets[15]);
  object.remoteUpdatedAt = reader.readDateTimeOrNull(offsets[16]);
  object.remoteVersion = reader.readLong(offsets[17]);
  object.syncId = reader.readStringOrNull(offsets[18]);
  object.syncedAt = reader.readDateTimeOrNull(offsets[19]);
  object.transport = reader.readStringOrNull(offsets[20]);
  object.type =
      _WorkLogtypeValueEnumMap[reader.readByteOrNull(offsets[21])] ??
      LogType.work;
  object.updatedAt = reader.readDateTimeOrNull(offsets[22]);
  return object;
}

P _workLogDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readBool(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (reader.readLongOrNull(offset)) as P;
    case 16:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 20:
      return (reader.readStringOrNull(offset)) as P;
    case 21:
      return (_WorkLogtypeValueEnumMap[reader.readByteOrNull(offset)] ??
              LogType.work)
          as P;
    case 22:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _WorkLogtypeEnumValueMap = {
  'work': 0,
  'rest': 1,
  'leave': 2,
  'businessTrip': 3,
};
const _WorkLogtypeValueEnumMap = {
  0: LogType.work,
  1: LogType.rest,
  2: LogType.leave,
  3: LogType.businessTrip,
};

Id _workLogGetId(WorkLog object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _workLogGetLinks(WorkLog object) {
  return [];
}

void _workLogAttach(IsarCollection<dynamic> col, Id id, WorkLog object) {
  object.id = id;
}

extension WorkLogQueryWhereSort on QueryBuilder<WorkLog, WorkLog, QWhere> {
  QueryBuilder<WorkLog, WorkLog, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhere> anyDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhere> anyProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'projectId'),
      );
    });
  }
}

extension WorkLogQueryWhere on QueryBuilder<WorkLog, WorkLog, QWhereClause> {
  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> idBetween(
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [null]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtIsNotNull() {
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtEqualTo(
    DateTime? deletedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [deletedAt]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtNotEqualTo(
    DateTime? deletedAt,
  ) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtGreaterThan(
    DateTime? deletedAt, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtLessThan(
    DateTime? deletedAt, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> deletedAtBetween(
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

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectId', value: [null]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdEqualTo(
    int? projectId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectId', value: [projectId]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdNotEqualTo(
    int? projectId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [],
                upper: [projectId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [projectId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [projectId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectId',
                lower: [],
                upper: [projectId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdGreaterThan(
    int? projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [projectId],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdLessThan(
    int? projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [],
          upper: [projectId],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectIdBetween(
    int? lowerProjectId,
    int? upperProjectId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectId',
          lower: [lowerProjectId],
          includeLower: includeLower,
          upper: [upperProjectId],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectSyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectSyncId', value: [null]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectSyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectSyncId',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectSyncIdEqualTo(
    String? projectSyncId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'projectSyncId',
          value: [projectSyncId],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectSyncIdNotEqualTo(
    String? projectSyncId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectSyncId',
                lower: [],
                upper: [projectSyncId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectSyncId',
                lower: [projectSyncId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectSyncId',
                lower: [projectSyncId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectSyncId',
                lower: [],
                upper: [projectSyncId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectName', value: [null]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectName',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectNameEqualTo(
    String? projectName,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'projectName',
          value: [projectName],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectNameNotEqualTo(
    String? projectName,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectName',
                lower: [],
                upper: [projectName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectName',
                lower: [projectName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectName',
                lower: [projectName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectName',
                lower: [],
                upper: [projectName],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectStageNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'projectStageName', value: [null]),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause>
  projectStageNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'projectStageName',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectStageNameEqualTo(
    String? projectStageName,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'projectStageName',
          value: [projectStageName],
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterWhereClause> projectStageNameNotEqualTo(
    String? projectStageName,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectStageName',
                lower: [],
                upper: [projectStageName],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectStageName',
                lower: [projectStageName],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectStageName',
                lower: [projectStageName],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'projectStageName',
                lower: [],
                upper: [projectStageName],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension WorkLogQueryFilter
    on QueryBuilder<WorkLog, WorkLog, QFilterCondition> {
  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> createdAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'createdAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> createdAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'createdAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> createdAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> createdAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> createdAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> createdAtBetween(
    DateTime? lower,
    DateTime? upper, {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> dateEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'date', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'date',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'date',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> deletedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> deletedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> deletedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> deletedAtBetween(
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> expensesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'expenses'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> expensesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'expenses'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> expensesEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'expenses',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> expensesGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expenses',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> expensesLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expenses',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> expensesBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expenses',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> idBetween(
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> isDirtyEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isDirty', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> isReimbursedEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isReimbursed', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'location'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'location'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'location',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'location',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'location',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'location', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> locationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'location', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'note'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'note'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'note',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'note',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'note',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'note', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> overtimeHoursIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'overtimeHours'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  overtimeHoursIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'overtimeHours'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> overtimeHoursEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'overtimeHours',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  overtimeHoursGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'overtimeHours',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> overtimeHoursLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'overtimeHours',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> overtimeHoursBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'overtimeHours',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ownerUserId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ownerUserId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdGreaterThan(
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdLessThan(
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdBetween(
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> ownerUserIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerUserId', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  ownerUserIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerUserId', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> pendingDeleteEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pendingDelete', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'projectId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'projectId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'projectId', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'projectId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'projectId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'projectId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'projectName'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'projectName'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'projectName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'projectName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'projectName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'projectName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'projectName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'projectName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'projectName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'projectName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'projectName', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'projectName', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'projectStageName'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'projectStageName'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectStageNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'projectStageName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'projectStageName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'projectStageName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectStageNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'projectStageName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'projectStageName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'projectStageName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'projectStageName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectStageNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'projectStageName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'projectStageName', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectStageNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'projectStageName', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'projectSyncId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectSyncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'projectSyncId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'projectSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectSyncIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'projectSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'projectSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'projectSyncId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'projectSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'projectSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'projectSyncId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'projectSyncId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> projectSyncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'projectSyncId', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  projectSyncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'projectSyncId', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteId', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  remoteUpdatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'remoteUpdatedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  remoteUpdatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'remoteUpdatedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteUpdatedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteUpdatedAt', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteUpdatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteUpdatedAtBetween(
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteVersionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteVersion', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition>
  remoteVersionGreaterThan(int value, {bool include = false}) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteVersionLessThan(
    int value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> remoteVersionBetween(
    int lower,
    int upper, {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'syncId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'syncId'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdGreaterThan(
    String? value, {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdLessThan(
    String? value, {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdBetween(
    String? lower,
    String? upper, {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncId', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'syncId', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'syncedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'syncedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'syncedAt', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'syncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'syncedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> syncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'syncedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'transport'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'transport'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'transport',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'transport',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'transport',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'transport',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'transport',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'transport',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'transport',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'transport',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'transport', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> transportIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'transport', value: ''),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> typeEqualTo(
    LogType value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> typeGreaterThan(
    LogType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> typeLessThan(
    LogType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> typeBetween(
    LogType lower,
    LogType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> updatedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> updatedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'updatedAt'),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> updatedAtEqualTo(
    DateTime? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> updatedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> updatedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
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

  QueryBuilder<WorkLog, WorkLog, QAfterFilterCondition> updatedAtBetween(
    DateTime? lower,
    DateTime? upper, {
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
}

extension WorkLogQueryObject
    on QueryBuilder<WorkLog, WorkLog, QFilterCondition> {}

extension WorkLogQueryLinks
    on QueryBuilder<WorkLog, WorkLog, QFilterCondition> {}

extension WorkLogQuerySortBy on QueryBuilder<WorkLog, WorkLog, QSortBy> {
  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenses', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByExpensesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenses', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByIsReimbursed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReimbursed', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByIsReimbursedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReimbursed', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeHours', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByOvertimeHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeHours', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByPendingDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectName', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectName', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectStageName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectStageName', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectStageNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectStageName', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectSyncId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByProjectSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectSyncId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByRemoteUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByRemoteVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByRemoteVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByTransport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByTransportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension WorkLogQuerySortThenBy
    on QueryBuilder<WorkLog, WorkLog, QSortThenBy> {
  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenses', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByExpensesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expenses', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByIsDirtyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isDirty', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByIsReimbursed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReimbursed', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByIsReimbursedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isReimbursed', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByLocation() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByLocationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'location', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeHours', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByOvertimeHoursDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'overtimeHours', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByOwnerUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByOwnerUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerUserId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByPendingDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pendingDelete', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectName', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectName', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectStageName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectStageName', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectStageNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectStageName', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectSyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectSyncId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByProjectSyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectSyncId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByRemoteUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteUpdatedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByRemoteVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByRemoteVersionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteVersion', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenBySyncId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenBySyncIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncId', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenBySyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncedAt', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByTransport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByTransportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'transport', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension WorkLogQueryWhereDistinct
    on QueryBuilder<WorkLog, WorkLog, QDistinct> {
  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByExpenses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expenses');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByIsDirty() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isDirty');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByIsReimbursed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isReimbursed');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByLocation({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'location', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByNote({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByOvertimeHours() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'overtimeHours');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByOwnerUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerUserId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByPendingDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pendingDelete');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByProjectName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByProjectStageName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'projectStageName',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByProjectSyncId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'projectSyncId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByRemoteUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteUpdatedAt');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByRemoteVersion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteVersion');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctBySyncId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctBySyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncedAt');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByTransport({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'transport', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<WorkLog, WorkLog, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension WorkLogQueryProperty
    on QueryBuilder<WorkLog, WorkLog, QQueryProperty> {
  QueryBuilder<WorkLog, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<WorkLog, DateTime?, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<WorkLog, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<WorkLog, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<WorkLog, double?, QQueryOperations> expensesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expenses');
    });
  }

  QueryBuilder<WorkLog, bool, QQueryOperations> isDirtyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isDirty');
    });
  }

  QueryBuilder<WorkLog, bool, QQueryOperations> isReimbursedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isReimbursed');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> locationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'location');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<WorkLog, double?, QQueryOperations> overtimeHoursProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'overtimeHours');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> ownerUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerUserId');
    });
  }

  QueryBuilder<WorkLog, bool, QQueryOperations> pendingDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pendingDelete');
    });
  }

  QueryBuilder<WorkLog, int?, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> projectNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectName');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> projectStageNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectStageName');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> projectSyncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectSyncId');
    });
  }

  QueryBuilder<WorkLog, int?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<WorkLog, DateTime?, QQueryOperations> remoteUpdatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteUpdatedAt');
    });
  }

  QueryBuilder<WorkLog, int, QQueryOperations> remoteVersionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteVersion');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> syncIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncId');
    });
  }

  QueryBuilder<WorkLog, DateTime?, QQueryOperations> syncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncedAt');
    });
  }

  QueryBuilder<WorkLog, String?, QQueryOperations> transportProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'transport');
    });
  }

  QueryBuilder<WorkLog, LogType, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<WorkLog, DateTime?, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
