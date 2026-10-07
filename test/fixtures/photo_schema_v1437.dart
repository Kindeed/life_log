// Frozen v1.4.37 schema/codec for a real on-disk upgrade regression.
// Copied from that release's generated source; never used by production.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, unnecessary_cast, unnecessary_null_checks
import 'package:isar_community/isar.dart';
import 'package:life_log/features/photo/data/photo_model.dart';

const LegacyPhotoItemSchema = CollectionSchema(
  name: r'PhotoItem',
  id: -5773752777889886468,
  properties: {
    r'capturedAt': PropertySchema(
      id: 0,
      name: r'capturedAt',
      type: IsarType.dateTime,
    ),
    r'capturedAtSource': PropertySchema(
      id: 1,
      name: r'capturedAtSource',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'dateIndexed': PropertySchema(
      id: 3,
      name: r'dateIndexed',
      type: IsarType.dateTime,
    ),
    r'description': PropertySchema(
      id: 4,
      name: r'description',
      type: IsarType.string,
    ),
    r'deviceName': PropertySchema(
      id: 5,
      name: r'deviceName',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 6,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'filePath': PropertySchema(
      id: 7,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'gpsLatitude': PropertySchema(
      id: 8,
      name: r'gpsLatitude',
      type: IsarType.double,
    ),
    r'gpsLongitude': PropertySchema(
      id: 9,
      name: r'gpsLongitude',
      type: IsarType.double,
    ),
    r'ownerUserId': PropertySchema(
      id: 10,
      name: r'ownerUserId',
      type: IsarType.string,
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
  },

  estimateSize: _photoItemEstimateSize,
  serialize: _photoItemSerialize,
  deserialize: _photoItemDeserialize,
  deserializeProp: _photoItemDeserializeProp,
  idName: r'id',
  indexes: {
    r'dateIndexed': IndexSchema(
      id: 2835159620137769758,
      name: r'dateIndexed',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dateIndexed',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _photoItemGetId,
  getLinks: _photoItemGetLinks,
  attach: _photoItemAttach,
  version: '3.3.2',
);

int _photoItemEstimateSize(
  PhotoItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.capturedAtSource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.deviceName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.fileName.length * 3;
  bytesCount += 3 + object.filePath.length * 3;
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
  return bytesCount;
}

void _photoItemSerialize(
  PhotoItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.capturedAt);
  writer.writeString(offsets[1], object.capturedAtSource);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeDateTime(offsets[3], object.dateIndexed);
  writer.writeString(offsets[4], object.description);
  writer.writeString(offsets[5], object.deviceName);
  writer.writeString(offsets[6], object.fileName);
  writer.writeString(offsets[7], object.filePath);
  writer.writeDouble(offsets[8], object.gpsLatitude);
  writer.writeDouble(offsets[9], object.gpsLongitude);
  writer.writeString(offsets[10], object.ownerUserId);
  writer.writeLong(offsets[11], object.projectId);
  writer.writeString(offsets[12], object.projectName);
}

PhotoItem _photoItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PhotoItem();
  object.capturedAt = reader.readDateTimeOrNull(offsets[0]);
  object.capturedAtSource = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.dateIndexed = reader.readDateTime(offsets[3]);
  object.description = reader.readStringOrNull(offsets[4]);
  object.deviceName = reader.readStringOrNull(offsets[5]);
  object.fileName = reader.readString(offsets[6]);
  object.filePath = reader.readString(offsets[7]);
  object.gpsLatitude = reader.readDoubleOrNull(offsets[8]);
  object.gpsLongitude = reader.readDoubleOrNull(offsets[9]);
  object.id = id;
  object.ownerUserId = reader.readStringOrNull(offsets[10]);
  object.projectId = reader.readLongOrNull(offsets[11]);
  object.projectName = reader.readStringOrNull(offsets[12]);
  return object;
}

P _photoItemDeserializeProp<P>(
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
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _photoItemGetId(PhotoItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _photoItemGetLinks(PhotoItem object) {
  return [];
}

void _photoItemAttach(IsarCollection<dynamic> col, Id id, PhotoItem object) {
  object.id = id;
}
