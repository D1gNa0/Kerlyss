// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playlist_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPlaylistModelCollection on Isar {
  IsarCollection<PlaylistModel> get playlistModels => this.collection();
}

const PlaylistModelSchema = CollectionSchema(
  name: r'PlaylistModel',
  id: -3528207141634668389,
  properties: {
    r'autoDownloadNewTracks': PropertySchema(
      id: 0,
      name: r'autoDownloadNewTracks',
      type: IsarType.bool,
    ),
    r'coverArtUrl': PropertySchema(
      id: 1,
      name: r'coverArtUrl',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isRealtimeSynced': PropertySchema(
      id: 3,
      name: r'isRealtimeSynced',
      type: IsarType.bool,
    ),
    r'lastSyncedAt': PropertySchema(
      id: 4,
      name: r'lastSyncedAt',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 5,
      name: r'name',
      type: IsarType.string,
    ),
    r'songIds': PropertySchema(
      id: 6,
      name: r'songIds',
      type: IsarType.stringList,
    ),
    r'spotifySourceUrl': PropertySchema(
      id: 7,
      name: r'spotifySourceUrl',
      type: IsarType.string,
    )
  },
  estimateSize: _playlistModelEstimateSize,
  serialize: _playlistModelSerialize,
  deserialize: _playlistModelDeserialize,
  deserializeProp: _playlistModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _playlistModelGetId,
  getLinks: _playlistModelGetLinks,
  attach: _playlistModelAttach,
  version: '3.1.0+1',
);

int _playlistModelEstimateSize(
  PlaylistModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.coverArtUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.songIds.length * 3;
  {
    for (var i = 0; i < object.songIds.length; i++) {
      final value = object.songIds[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.spotifySourceUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _playlistModelSerialize(
  PlaylistModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoDownloadNewTracks);
  writer.writeString(offsets[1], object.coverArtUrl);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeBool(offsets[3], object.isRealtimeSynced);
  writer.writeDateTime(offsets[4], object.lastSyncedAt);
  writer.writeString(offsets[5], object.name);
  writer.writeStringList(offsets[6], object.songIds);
  writer.writeString(offsets[7], object.spotifySourceUrl);
}

PlaylistModel _playlistModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlaylistModel();
  object.autoDownloadNewTracks = reader.readBool(offsets[0]);
  object.coverArtUrl = reader.readStringOrNull(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.isRealtimeSynced = reader.readBool(offsets[3]);
  object.lastSyncedAt = reader.readDateTimeOrNull(offsets[4]);
  object.name = reader.readString(offsets[5]);
  object.songIds = reader.readStringList(offsets[6]) ?? [];
  object.spotifySourceUrl = reader.readStringOrNull(offsets[7]);
  return object;
}

P _playlistModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readStringList(offset) ?? []) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playlistModelGetId(PlaylistModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playlistModelGetLinks(PlaylistModel object) {
  return [];
}

void _playlistModelAttach(
    IsarCollection<dynamic> col, Id id, PlaylistModel object) {
  object.id = id;
}

extension PlaylistModelByIndex on IsarCollection<PlaylistModel> {
  Future<PlaylistModel?> getByName(String name) {
    return getByIndex(r'name', [name]);
  }

  PlaylistModel? getByNameSync(String name) {
    return getByIndexSync(r'name', [name]);
  }

  Future<bool> deleteByName(String name) {
    return deleteByIndex(r'name', [name]);
  }

  bool deleteByNameSync(String name) {
    return deleteByIndexSync(r'name', [name]);
  }

  Future<List<PlaylistModel?>> getAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndex(r'name', values);
  }

  List<PlaylistModel?> getAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'name', values);
  }

  Future<int> deleteAllByName(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'name', values);
  }

  int deleteAllByNameSync(List<String> nameValues) {
    final values = nameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'name', values);
  }

  Future<Id> putByName(PlaylistModel object) {
    return putByIndex(r'name', object);
  }

  Id putByNameSync(PlaylistModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'name', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByName(List<PlaylistModel> objects) {
    return putAllByIndex(r'name', objects);
  }

  List<Id> putAllByNameSync(List<PlaylistModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'name', objects, saveLinks: saveLinks);
  }
}

extension PlaylistModelQueryWhereSort
    on QueryBuilder<PlaylistModel, PlaylistModel, QWhere> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PlaylistModelQueryWhere
    on QueryBuilder<PlaylistModel, PlaylistModel, QWhereClause> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> nameEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterWhereClause> nameNotEqualTo(
      String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }
}

extension PlaylistModelQueryFilter
    on QueryBuilder<PlaylistModel, PlaylistModel, QFilterCondition> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      autoDownloadNewTracksEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoDownloadNewTracks',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'coverArtUrl',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'coverArtUrl',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'coverArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'coverArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'coverArtUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'coverArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'coverArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'coverArtUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'coverArtUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'coverArtUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      coverArtUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'coverArtUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      isRealtimeSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isRealtimeSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      lastSyncedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      lastSyncedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSyncedAt',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      lastSyncedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      lastSyncedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      lastSyncedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSyncedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      lastSyncedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSyncedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'songIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'songIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'songIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'songIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'songIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'songIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'songIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'songIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'songIds',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'songIds',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'songIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'songIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'songIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'songIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'songIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      songIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'songIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'spotifySourceUrl',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'spotifySourceUrl',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spotifySourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'spotifySourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'spotifySourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'spotifySourceUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'spotifySourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'spotifySourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'spotifySourceUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'spotifySourceUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'spotifySourceUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterFilterCondition>
      spotifySourceUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'spotifySourceUrl',
        value: '',
      ));
    });
  }
}

extension PlaylistModelQueryObject
    on QueryBuilder<PlaylistModel, PlaylistModel, QFilterCondition> {}

extension PlaylistModelQueryLinks
    on QueryBuilder<PlaylistModel, PlaylistModel, QFilterCondition> {}

extension PlaylistModelQuerySortBy
    on QueryBuilder<PlaylistModel, PlaylistModel, QSortBy> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByAutoDownloadNewTracks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDownloadNewTracks', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByAutoDownloadNewTracksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDownloadNewTracks', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByCoverArtUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverArtUrl', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByCoverArtUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverArtUrl', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByIsRealtimeSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRealtimeSynced', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByIsRealtimeSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRealtimeSynced', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortBySpotifySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifySourceUrl', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      sortBySpotifySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifySourceUrl', Sort.desc);
    });
  }
}

extension PlaylistModelQuerySortThenBy
    on QueryBuilder<PlaylistModel, PlaylistModel, QSortThenBy> {
  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByAutoDownloadNewTracks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDownloadNewTracks', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByAutoDownloadNewTracksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoDownloadNewTracks', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByCoverArtUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverArtUrl', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByCoverArtUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'coverArtUrl', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByIsRealtimeSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRealtimeSynced', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByIsRealtimeSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isRealtimeSynced', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenByLastSyncedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSyncedAt', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenBySpotifySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifySourceUrl', Sort.asc);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QAfterSortBy>
      thenBySpotifySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spotifySourceUrl', Sort.desc);
    });
  }
}

extension PlaylistModelQueryWhereDistinct
    on QueryBuilder<PlaylistModel, PlaylistModel, QDistinct> {
  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct>
      distinctByAutoDownloadNewTracks() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoDownloadNewTracks');
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct> distinctByCoverArtUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'coverArtUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct>
      distinctByIsRealtimeSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isRealtimeSynced');
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct>
      distinctByLastSyncedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSyncedAt');
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct> distinctBySongIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'songIds');
    });
  }

  QueryBuilder<PlaylistModel, PlaylistModel, QDistinct>
      distinctBySpotifySourceUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spotifySourceUrl',
          caseSensitive: caseSensitive);
    });
  }
}

extension PlaylistModelQueryProperty
    on QueryBuilder<PlaylistModel, PlaylistModel, QQueryProperty> {
  QueryBuilder<PlaylistModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlaylistModel, bool, QQueryOperations>
      autoDownloadNewTracksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoDownloadNewTracks');
    });
  }

  QueryBuilder<PlaylistModel, String?, QQueryOperations> coverArtUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'coverArtUrl');
    });
  }

  QueryBuilder<PlaylistModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<PlaylistModel, bool, QQueryOperations>
      isRealtimeSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isRealtimeSynced');
    });
  }

  QueryBuilder<PlaylistModel, DateTime?, QQueryOperations>
      lastSyncedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSyncedAt');
    });
  }

  QueryBuilder<PlaylistModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<PlaylistModel, List<String>, QQueryOperations>
      songIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'songIds');
    });
  }

  QueryBuilder<PlaylistModel, String?, QQueryOperations>
      spotifySourceUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spotifySourceUrl');
    });
  }
}
