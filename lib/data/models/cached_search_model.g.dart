// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_search_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedSearchModelCollection on Isar {
  IsarCollection<CachedSearchModel> get cachedSearchModels => this.collection();
}

const CachedSearchModelSchema = CollectionSchema(
  name: r'CachedSearchModel',
  id: 148576385154330401,
  properties: {
    r'cachedAt': PropertySchema(
      id: 0,
      name: r'cachedAt',
      type: IsarType.dateTime,
    ),
    r'isExpired': PropertySchema(
      id: 1,
      name: r'isExpired',
      type: IsarType.bool,
    ),
    r'query': PropertySchema(
      id: 2,
      name: r'query',
      type: IsarType.string,
    ),
    r'resultsJson': PropertySchema(
      id: 3,
      name: r'resultsJson',
      type: IsarType.string,
    ),
    r'ttlMinutes': PropertySchema(
      id: 4,
      name: r'ttlMinutes',
      type: IsarType.long,
    )
  },
  estimateSize: _cachedSearchModelEstimateSize,
  serialize: _cachedSearchModelSerialize,
  deserialize: _cachedSearchModelDeserialize,
  deserializeProp: _cachedSearchModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'query': IndexSchema(
      id: -3238105102146786367,
      name: r'query',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'query',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    ),
    r'cachedAt': IndexSchema(
      id: -699654806693614168,
      name: r'cachedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'cachedAt',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedSearchModelGetId,
  getLinks: _cachedSearchModelGetLinks,
  attach: _cachedSearchModelAttach,
  version: '3.1.0+1',
);

int _cachedSearchModelEstimateSize(
  CachedSearchModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.query.length * 3;
  bytesCount += 3 + object.resultsJson.length * 3;
  return bytesCount;
}

void _cachedSearchModelSerialize(
  CachedSearchModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeBool(offsets[1], object.isExpired);
  writer.writeString(offsets[2], object.query);
  writer.writeString(offsets[3], object.resultsJson);
  writer.writeLong(offsets[4], object.ttlMinutes);
}

CachedSearchModel _cachedSearchModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedSearchModel();
  object.cachedAt = reader.readDateTime(offsets[0]);
  object.id = id;
  object.query = reader.readString(offsets[2]);
  object.resultsJson = reader.readString(offsets[3]);
  object.ttlMinutes = reader.readLongOrNull(offsets[4]);
  return object;
}

P _cachedSearchModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedSearchModelGetId(CachedSearchModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedSearchModelGetLinks(
    CachedSearchModel object) {
  return [];
}

void _cachedSearchModelAttach(
    IsarCollection<dynamic> col, Id id, CachedSearchModel object) {
  object.id = id;
}

extension CachedSearchModelByIndex on IsarCollection<CachedSearchModel> {
  Future<CachedSearchModel?> getByQuery(String query) {
    return getByIndex(r'query', [query]);
  }

  CachedSearchModel? getByQuerySync(String query) {
    return getByIndexSync(r'query', [query]);
  }

  Future<bool> deleteByQuery(String query) {
    return deleteByIndex(r'query', [query]);
  }

  bool deleteByQuerySync(String query) {
    return deleteByIndexSync(r'query', [query]);
  }

  Future<List<CachedSearchModel?>> getAllByQuery(List<String> queryValues) {
    final values = queryValues.map((e) => [e]).toList();
    return getAllByIndex(r'query', values);
  }

  List<CachedSearchModel?> getAllByQuerySync(List<String> queryValues) {
    final values = queryValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'query', values);
  }

  Future<int> deleteAllByQuery(List<String> queryValues) {
    final values = queryValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'query', values);
  }

  int deleteAllByQuerySync(List<String> queryValues) {
    final values = queryValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'query', values);
  }

  Future<Id> putByQuery(CachedSearchModel object) {
    return putByIndex(r'query', object);
  }

  Id putByQuerySync(CachedSearchModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'query', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByQuery(List<CachedSearchModel> objects) {
    return putAllByIndex(r'query', objects);
  }

  List<Id> putAllByQuerySync(List<CachedSearchModel> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'query', objects, saveLinks: saveLinks);
  }
}

extension CachedSearchModelQueryWhereSort
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QWhere> {
  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhere>
      anyCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'cachedAt'),
      );
    });
  }
}

extension CachedSearchModelQueryWhere
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QWhereClause> {
  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
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

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      queryEqualTo(String query) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'query',
        value: [query],
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      queryNotEqualTo(String query) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'query',
              lower: [],
              upper: [query],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'query',
              lower: [query],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'query',
              lower: [query],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'query',
              lower: [],
              upper: [query],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      cachedAtEqualTo(DateTime cachedAt) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cachedAt',
        value: [cachedAt],
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      cachedAtNotEqualTo(DateTime cachedAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cachedAt',
              lower: [],
              upper: [cachedAt],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cachedAt',
              lower: [cachedAt],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cachedAt',
              lower: [cachedAt],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cachedAt',
              lower: [],
              upper: [cachedAt],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      cachedAtGreaterThan(
    DateTime cachedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cachedAt',
        lower: [cachedAt],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      cachedAtLessThan(
    DateTime cachedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cachedAt',
        lower: [],
        upper: [cachedAt],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterWhereClause>
      cachedAtBetween(
    DateTime lowerCachedAt,
    DateTime upperCachedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cachedAt',
        lower: [lowerCachedAt],
        includeLower: includeLower,
        upper: [upperCachedAt],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedSearchModelQueryFilter
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QFilterCondition> {
  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      cachedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      cachedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      cachedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cachedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      cachedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cachedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
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

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      isExpiredEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isExpired',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'query',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'query',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'query',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'query',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'query',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'query',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'query',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'query',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'query',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      queryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'query',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resultsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'resultsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'resultsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'resultsJson',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'resultsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'resultsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'resultsJson',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'resultsJson',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'resultsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      resultsJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'resultsJson',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      ttlMinutesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ttlMinutes',
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      ttlMinutesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ttlMinutes',
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      ttlMinutesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ttlMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      ttlMinutesGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ttlMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      ttlMinutesLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ttlMinutes',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterFilterCondition>
      ttlMinutesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ttlMinutes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CachedSearchModelQueryObject
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QFilterCondition> {}

extension CachedSearchModelQueryLinks
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QFilterCondition> {}

extension CachedSearchModelQuerySortBy
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QSortBy> {
  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'query', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'query', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByResultsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByResultsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByTtlMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttlMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      sortByTtlMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttlMinutes', Sort.desc);
    });
  }
}

extension CachedSearchModelQuerySortThenBy
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QSortThenBy> {
  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByIsExpiredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isExpired', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByQuery() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'query', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByQueryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'query', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByResultsJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByResultsJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'resultsJson', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByTtlMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttlMinutes', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QAfterSortBy>
      thenByTtlMinutesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ttlMinutes', Sort.desc);
    });
  }
}

extension CachedSearchModelQueryWhereDistinct
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QDistinct> {
  QueryBuilder<CachedSearchModel, CachedSearchModel, QDistinct>
      distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QDistinct>
      distinctByIsExpired() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isExpired');
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QDistinct> distinctByQuery(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'query', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QDistinct>
      distinctByResultsJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'resultsJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CachedSearchModel, CachedSearchModel, QDistinct>
      distinctByTtlMinutes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ttlMinutes');
    });
  }
}

extension CachedSearchModelQueryProperty
    on QueryBuilder<CachedSearchModel, CachedSearchModel, QQueryProperty> {
  QueryBuilder<CachedSearchModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedSearchModel, DateTime, QQueryOperations>
      cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<CachedSearchModel, bool, QQueryOperations> isExpiredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isExpired');
    });
  }

  QueryBuilder<CachedSearchModel, String, QQueryOperations> queryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'query');
    });
  }

  QueryBuilder<CachedSearchModel, String, QQueryOperations>
      resultsJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'resultsJson');
    });
  }

  QueryBuilder<CachedSearchModel, int?, QQueryOperations> ttlMinutesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ttlMinutes');
    });
  }
}
