// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProjectCollection on Isar {
  IsarCollection<Project> get projects => this.collection();
}

final ProjectSchema = CollectionSchema(
  name: r'Project',
  id: int.parse('3302999628838485849'),
  properties: {
    r'config': PropertySchema(
      id: 0,
      name: r'config',
      type: IsarType.object,
      target: r'ProjectConfigSchema',
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'duration': PropertySchema(
      id: 2,
      name: r'duration',
      type: IsarType.double,
    ),
    r'height': PropertySchema(
      id: 3,
      name: r'height',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'projectId': PropertySchema(
      id: 5,
      name: r'projectId',
      type: IsarType.string,
    ),
    r'segments': PropertySchema(
      id: 6,
      name: r'segments',
      type: IsarType.objectList,
      target: r'VideoSegmentSchema',
    ),
    r'status': PropertySchema(
      id: 7,
      name: r'status',
      type: IsarType.string,
    ),
    r'thumbnailPath': PropertySchema(
      id: 8,
      name: r'thumbnailPath',
      type: IsarType.string,
    ),
    r'trimEnd': PropertySchema(
      id: 9,
      name: r'trimEnd',
      type: IsarType.double,
    ),
    r'trimStart': PropertySchema(
      id: 10,
      name: r'trimStart',
      type: IsarType.double,
    ),
    r'videoPath': PropertySchema(
      id: 11,
      name: r'videoPath',
      type: IsarType.string,
    ),
    r'width': PropertySchema(
      id: 12,
      name: r'width',
      type: IsarType.long,
    ),
    r'words': PropertySchema(
      id: 13,
      name: r'words',
      type: IsarType.objectList,
      target: r'WordSchema',
    )
  },
  estimateSize: _projectEstimateSize,
  serialize: _projectSerialize,
  deserialize: _projectDeserialize,
  deserializeProp: _projectDeserializeProp,
  idName: r'id',
  indexes: {
    r'projectId': IndexSchema(
      id: int.parse('3305656282123791113'),
      name: r'projectId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'ProjectConfigSchema': ProjectConfigSchemaSchema,
    r'StyleConfigSchema': StyleConfigSchemaSchema,
    r'HighlightStyleSchema': HighlightStyleSchemaSchema,
    r'SubtitleConfigSchema': SubtitleConfigSchemaSchema,
    r'WordSchema': WordSchemaSchema,
    r'EmojiConfigSchema': EmojiConfigSchemaSchema,
    r'VideoSegmentSchema': VideoSegmentSchemaSchema
  },
  getId: _projectGetId,
  getLinks: _projectGetLinks,
  attach: _projectAttach,
  version: '3.3.2',
);

int _projectEstimateSize(
  Project object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 +
      ProjectConfigSchemaSchema.estimateSize(
          object.config, allOffsets[ProjectConfigSchema]!, allOffsets);
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.projectId.length * 3;
  {
    final list = object.segments;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[VideoSegmentSchema]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              VideoSegmentSchemaSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  bytesCount += 3 + object.status.length * 3;
  {
    final value = object.thumbnailPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.videoPath.length * 3;
  bytesCount += 3 + object.words.length * 3;
  {
    final offsets = allOffsets[WordSchema]!;
    for (var i = 0; i < object.words.length; i++) {
      final value = object.words[i];
      bytesCount += WordSchemaSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _projectSerialize(
  Project object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeObject<ProjectConfigSchema>(
    offsets[0],
    allOffsets,
    ProjectConfigSchemaSchema.serialize,
    object.config,
  );
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeDouble(offsets[2], object.duration);
  writer.writeLong(offsets[3], object.height);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.projectId);
  writer.writeObjectList<VideoSegmentSchema>(
    offsets[6],
    allOffsets,
    VideoSegmentSchemaSchema.serialize,
    object.segments,
  );
  writer.writeString(offsets[7], object.status);
  writer.writeString(offsets[8], object.thumbnailPath);
  writer.writeDouble(offsets[9], object.trimEnd);
  writer.writeDouble(offsets[10], object.trimStart);
  writer.writeString(offsets[11], object.videoPath);
  writer.writeLong(offsets[12], object.width);
  writer.writeObjectList<WordSchema>(
    offsets[13],
    allOffsets,
    WordSchemaSchema.serialize,
    object.words,
  );
}

Project _projectDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Project();
  object.config = reader.readObjectOrNull<ProjectConfigSchema>(
        offsets[0],
        ProjectConfigSchemaSchema.deserialize,
        allOffsets,
      ) ??
      ProjectConfigSchema();
  object.createdAt = reader.readDateTime(offsets[1]);
  object.duration = reader.readDouble(offsets[2]);
  object.height = reader.readLong(offsets[3]);
  object.id = id;
  object.name = reader.readString(offsets[4]);
  object.projectId = reader.readString(offsets[5]);
  object.segments = reader.readObjectList<VideoSegmentSchema>(
    offsets[6],
    VideoSegmentSchemaSchema.deserialize,
    allOffsets,
    VideoSegmentSchema(),
  );
  object.status = reader.readString(offsets[7]);
  object.thumbnailPath = reader.readStringOrNull(offsets[8]);
  object.trimEnd = reader.readDouble(offsets[9]);
  object.trimStart = reader.readDouble(offsets[10]);
  object.videoPath = reader.readString(offsets[11]);
  object.width = reader.readLong(offsets[12]);
  object.words = reader.readObjectList<WordSchema>(
        offsets[13],
        WordSchemaSchema.deserialize,
        allOffsets,
        WordSchema(),
      ) ??
      [];
  return object;
}

P _projectDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readObjectOrNull<ProjectConfigSchema>(
            offset,
            ProjectConfigSchemaSchema.deserialize,
            allOffsets,
          ) ??
          ProjectConfigSchema()) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readObjectList<VideoSegmentSchema>(
        offset,
        VideoSegmentSchemaSchema.deserialize,
        allOffsets,
        VideoSegmentSchema(),
      )) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readObjectList<WordSchema>(
            offset,
            WordSchemaSchema.deserialize,
            allOffsets,
            WordSchema(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _projectGetId(Project object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _projectGetLinks(Project object) {
  return [];
}

void _projectAttach(IsarCollection<dynamic> col, Id id, Project object) {
  object.id = id;
}

extension ProjectByIndex on IsarCollection<Project> {
  Future<Project?> getByProjectId(String projectId) {
    return getByIndex(r'projectId', [projectId]);
  }

  Project? getByProjectIdSync(String projectId) {
    return getByIndexSync(r'projectId', [projectId]);
  }

  Future<bool> deleteByProjectId(String projectId) {
    return deleteByIndex(r'projectId', [projectId]);
  }

  bool deleteByProjectIdSync(String projectId) {
    return deleteByIndexSync(r'projectId', [projectId]);
  }

  Future<List<Project?>> getAllByProjectId(List<String> projectIdValues) {
    final values = projectIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'projectId', values);
  }

  List<Project?> getAllByProjectIdSync(List<String> projectIdValues) {
    final values = projectIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'projectId', values);
  }

  Future<int> deleteAllByProjectId(List<String> projectIdValues) {
    final values = projectIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'projectId', values);
  }

  int deleteAllByProjectIdSync(List<String> projectIdValues) {
    final values = projectIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'projectId', values);
  }

  Future<Id> putByProjectId(Project object) {
    return putByIndex(r'projectId', object);
  }

  Id putByProjectIdSync(Project object, {bool saveLinks = true}) {
    return putByIndexSync(r'projectId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProjectId(List<Project> objects) {
    return putAllByIndex(r'projectId', objects);
  }

  List<Id> putAllByProjectIdSync(List<Project> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'projectId', objects, saveLinks: saveLinks);
  }
}

extension ProjectQueryWhereSort on QueryBuilder<Project, Project, QWhere> {
  QueryBuilder<Project, Project, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProjectQueryWhere on QueryBuilder<Project, Project, QWhereClause> {
  QueryBuilder<Project, Project, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Project, Project, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idBetween(
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

  QueryBuilder<Project, Project, QAfterWhereClause> projectIdEqualTo(
      String projectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectId',
        value: [projectId],
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> projectIdNotEqualTo(
      String projectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProjectQueryFilter
    on QueryBuilder<Project, Project, QFilterCondition> {
  QueryBuilder<Project, Project, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> createdAtGreaterThan(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> createdAtLessThan(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> createdAtBetween(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> durationEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'duration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> durationGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'duration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> durationLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'duration',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> durationBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'duration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> heightEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> heightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> heightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> heightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<Project, Project, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'projectId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'projectId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'projectId',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'segments',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'segments',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'segments',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'segments',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'segments',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'segments',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      segmentsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'segments',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'segments',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'thumbnailPath',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      thumbnailPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'thumbnailPath',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      thumbnailPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thumbnailPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thumbnailPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thumbnailPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> thumbnailPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thumbnailPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      thumbnailPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thumbnailPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimEndEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trimEnd',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimEndGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trimEnd',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimEndLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trimEnd',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimEndBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trimEnd',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimStartEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'trimStart',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimStartGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'trimStart',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimStartLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'trimStart',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> trimStartBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'trimStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'videoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'videoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'videoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'videoPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'videoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'videoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'videoPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'videoPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'videoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> videoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'videoPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> widthEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> widthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> widthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'width',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> widthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'width',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'words',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension ProjectQueryObject
    on QueryBuilder<Project, Project, QFilterCondition> {
  QueryBuilder<Project, Project, QAfterFilterCondition> config(
      FilterQuery<ProjectConfigSchema> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'config');
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> segmentsElement(
      FilterQuery<VideoSegmentSchema> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'segments');
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> wordsElement(
      FilterQuery<WordSchema> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'words');
    });
  }
}

extension ProjectQueryLinks
    on QueryBuilder<Project, Project, QFilterCondition> {}

extension ProjectQuerySortBy on QueryBuilder<Project, Project, QSortBy> {
  QueryBuilder<Project, Project, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByTrimEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimEnd', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByTrimEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimEnd', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByTrimStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimStart', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByTrimStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimStart', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension ProjectQuerySortThenBy
    on QueryBuilder<Project, Project, QSortThenBy> {
  QueryBuilder<Project, Project, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duration', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByThumbnailPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByThumbnailPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'thumbnailPath', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByTrimEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimEnd', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByTrimEndDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimEnd', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByTrimStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimStart', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByTrimStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'trimStart', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByVideoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByVideoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'videoPath', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByWidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'width', Sort.desc);
    });
  }
}

extension ProjectQueryWhereDistinct
    on QueryBuilder<Project, Project, QDistinct> {
  QueryBuilder<Project, Project, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duration');
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByProjectId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByThumbnailPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'thumbnailPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByTrimEnd() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trimEnd');
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByTrimStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'trimStart');
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByVideoPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByWidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'width');
    });
  }
}

extension ProjectQueryProperty
    on QueryBuilder<Project, Project, QQueryProperty> {
  QueryBuilder<Project, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Project, ProjectConfigSchema, QQueryOperations>
      configProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'config');
    });
  }

  QueryBuilder<Project, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<Project, double, QQueryOperations> durationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duration');
    });
  }

  QueryBuilder<Project, int, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }

  QueryBuilder<Project, List<VideoSegmentSchema>?, QQueryOperations>
      segmentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'segments');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Project, String?, QQueryOperations> thumbnailPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'thumbnailPath');
    });
  }

  QueryBuilder<Project, double, QQueryOperations> trimEndProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trimEnd');
    });
  }

  QueryBuilder<Project, double, QQueryOperations> trimStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'trimStart');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> videoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoPath');
    });
  }

  QueryBuilder<Project, int, QQueryOperations> widthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'width');
    });
  }

  QueryBuilder<Project, List<WordSchema>, QQueryOperations> wordsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'words');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

final ProjectConfigSchemaSchema = Schema(
  name: r'ProjectConfigSchema',
  id: int.parse('-6740856976698978087'),
  properties: {
    r'animation': PropertySchema(
      id: 0,
      name: r'animation',
      type: IsarType.string,
    ),
    r'background': PropertySchema(
      id: 1,
      name: r'background',
      type: IsarType.string,
    ),
    r'emojiPack': PropertySchema(
      id: 2,
      name: r'emojiPack',
      type: IsarType.string,
    ),
    r'highlightStyle': PropertySchema(
      id: 3,
      name: r'highlightStyle',
      type: IsarType.object,
      target: r'HighlightStyleSchema',
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'shadow': PropertySchema(
      id: 5,
      name: r'shadow',
      type: IsarType.string,
    ),
    r'stroke': PropertySchema(
      id: 6,
      name: r'stroke',
      type: IsarType.string,
    ),
    r'style': PropertySchema(
      id: 7,
      name: r'style',
      type: IsarType.object,
      target: r'StyleConfigSchema',
    ),
    r'subs': PropertySchema(
      id: 8,
      name: r'subs',
      type: IsarType.object,
      target: r'SubtitleConfigSchema',
    )
  },
  estimateSize: _projectConfigSchemaEstimateSize,
  serialize: _projectConfigSchemaSerialize,
  deserialize: _projectConfigSchemaDeserialize,
  deserializeProp: _projectConfigSchemaDeserializeProp,
);

int _projectConfigSchemaEstimateSize(
  ProjectConfigSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.animation.length * 3;
  {
    final value = object.background;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.emojiPack;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 +
      HighlightStyleSchemaSchema.estimateSize(
          object.highlightStyle, allOffsets[HighlightStyleSchema]!, allOffsets);
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.shadow.length * 3;
  bytesCount += 3 + object.stroke.length * 3;
  bytesCount += 3 +
      StyleConfigSchemaSchema.estimateSize(
          object.style, allOffsets[StyleConfigSchema]!, allOffsets);
  bytesCount += 3 +
      SubtitleConfigSchemaSchema.estimateSize(
          object.subs, allOffsets[SubtitleConfigSchema]!, allOffsets);
  return bytesCount;
}

void _projectConfigSchemaSerialize(
  ProjectConfigSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.animation);
  writer.writeString(offsets[1], object.background);
  writer.writeString(offsets[2], object.emojiPack);
  writer.writeObject<HighlightStyleSchema>(
    offsets[3],
    allOffsets,
    HighlightStyleSchemaSchema.serialize,
    object.highlightStyle,
  );
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.shadow);
  writer.writeString(offsets[6], object.stroke);
  writer.writeObject<StyleConfigSchema>(
    offsets[7],
    allOffsets,
    StyleConfigSchemaSchema.serialize,
    object.style,
  );
  writer.writeObject<SubtitleConfigSchema>(
    offsets[8],
    allOffsets,
    SubtitleConfigSchemaSchema.serialize,
    object.subs,
  );
}

ProjectConfigSchema _projectConfigSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProjectConfigSchema();
  object.animation = reader.readString(offsets[0]);
  object.background = reader.readStringOrNull(offsets[1]);
  object.emojiPack = reader.readStringOrNull(offsets[2]);
  object.highlightStyle = reader.readObjectOrNull<HighlightStyleSchema>(
        offsets[3],
        HighlightStyleSchemaSchema.deserialize,
        allOffsets,
      ) ??
      HighlightStyleSchema();
  object.name = reader.readString(offsets[4]);
  object.shadow = reader.readString(offsets[5]);
  object.stroke = reader.readString(offsets[6]);
  object.style = reader.readObjectOrNull<StyleConfigSchema>(
        offsets[7],
        StyleConfigSchemaSchema.deserialize,
        allOffsets,
      ) ??
      StyleConfigSchema();
  object.subs = reader.readObjectOrNull<SubtitleConfigSchema>(
        offsets[8],
        SubtitleConfigSchemaSchema.deserialize,
        allOffsets,
      ) ??
      SubtitleConfigSchema();
  return object;
}

P _projectConfigSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readObjectOrNull<HighlightStyleSchema>(
            offset,
            HighlightStyleSchemaSchema.deserialize,
            allOffsets,
          ) ??
          HighlightStyleSchema()) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readObjectOrNull<StyleConfigSchema>(
            offset,
            StyleConfigSchemaSchema.deserialize,
            allOffsets,
          ) ??
          StyleConfigSchema()) as P;
    case 8:
      return (reader.readObjectOrNull<SubtitleConfigSchema>(
            offset,
            SubtitleConfigSchemaSchema.deserialize,
            allOffsets,
          ) ??
          SubtitleConfigSchema()) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension ProjectConfigSchemaQueryFilter on QueryBuilder<ProjectConfigSchema,
    ProjectConfigSchema, QFilterCondition> {
  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'animation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'animation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'animation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'animation',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'animation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'animation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'animation',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'animation',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'animation',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      animationIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'animation',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'background',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'background',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'background',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'background',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'background',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'background',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'background',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'background',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'background',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'background',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'background',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      backgroundIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'background',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emojiPack',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emojiPack',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emojiPack',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emojiPack',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emojiPack',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emojiPack',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emojiPack',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emojiPack',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emojiPack',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emojiPack',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emojiPack',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      emojiPackIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emojiPack',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      nameEqualTo(
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

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
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

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
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

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      nameBetween(
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

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
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

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
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

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shadow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'shadow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'shadow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'shadow',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'shadow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'shadow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'shadow',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'shadow',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'shadow',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      shadowIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'shadow',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stroke',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stroke',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stroke',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stroke',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stroke',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stroke',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stroke',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stroke',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stroke',
        value: '',
      ));
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      strokeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stroke',
        value: '',
      ));
    });
  }
}

extension ProjectConfigSchemaQueryObject on QueryBuilder<ProjectConfigSchema,
    ProjectConfigSchema, QFilterCondition> {
  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      highlightStyle(FilterQuery<HighlightStyleSchema> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'highlightStyle');
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      style(FilterQuery<StyleConfigSchema> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'style');
    });
  }

  QueryBuilder<ProjectConfigSchema, ProjectConfigSchema, QAfterFilterCondition>
      subs(FilterQuery<SubtitleConfigSchema> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'subs');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

final StyleConfigSchemaSchema = Schema(
  name: r'StyleConfigSchema',
  id: int.parse('5792689272170590595'),
  properties: {
    r'color': PropertySchema(
      id: 0,
      name: r'color',
      type: IsarType.string,
    ),
    r'fontFamily': PropertySchema(
      id: 1,
      name: r'fontFamily',
      type: IsarType.string,
    ),
    r'fontSize': PropertySchema(
      id: 2,
      name: r'fontSize',
      type: IsarType.double,
    ),
    r'fontWeight': PropertySchema(
      id: 3,
      name: r'fontWeight',
      type: IsarType.string,
    ),
    r'highlightBackground': PropertySchema(
      id: 4,
      name: r'highlightBackground',
      type: IsarType.bool,
    ),
    r'left': PropertySchema(
      id: 5,
      name: r'left',
      type: IsarType.double,
    ),
    r'letterSpacing': PropertySchema(
      id: 6,
      name: r'letterSpacing',
      type: IsarType.double,
    ),
    r'lineHeight': PropertySchema(
      id: 7,
      name: r'lineHeight',
      type: IsarType.double,
    ),
    r'textTransform': PropertySchema(
      id: 8,
      name: r'textTransform',
      type: IsarType.string,
    ),
    r'top': PropertySchema(
      id: 9,
      name: r'top',
      type: IsarType.double,
    )
  },
  estimateSize: _styleConfigSchemaEstimateSize,
  serialize: _styleConfigSchemaSerialize,
  deserialize: _styleConfigSchemaDeserialize,
  deserializeProp: _styleConfigSchemaDeserializeProp,
);

int _styleConfigSchemaEstimateSize(
  StyleConfigSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.color.length * 3;
  bytesCount += 3 + object.fontFamily.length * 3;
  bytesCount += 3 + object.fontWeight.length * 3;
  bytesCount += 3 + object.textTransform.length * 3;
  return bytesCount;
}

void _styleConfigSchemaSerialize(
  StyleConfigSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.color);
  writer.writeString(offsets[1], object.fontFamily);
  writer.writeDouble(offsets[2], object.fontSize);
  writer.writeString(offsets[3], object.fontWeight);
  writer.writeBool(offsets[4], object.highlightBackground);
  writer.writeDouble(offsets[5], object.left);
  writer.writeDouble(offsets[6], object.letterSpacing);
  writer.writeDouble(offsets[7], object.lineHeight);
  writer.writeString(offsets[8], object.textTransform);
  writer.writeDouble(offsets[9], object.top);
}

StyleConfigSchema _styleConfigSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StyleConfigSchema();
  object.color = reader.readString(offsets[0]);
  object.fontFamily = reader.readString(offsets[1]);
  object.fontSize = reader.readDouble(offsets[2]);
  object.fontWeight = reader.readString(offsets[3]);
  object.highlightBackground = reader.readBoolOrNull(offsets[4]);
  object.left = reader.readDouble(offsets[5]);
  object.letterSpacing = reader.readDoubleOrNull(offsets[6]);
  object.lineHeight = reader.readDoubleOrNull(offsets[7]);
  object.textTransform = reader.readString(offsets[8]);
  object.top = reader.readDouble(offsets[9]);
  return object;
}

P _styleConfigSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readBoolOrNull(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension StyleConfigSchemaQueryFilter
    on QueryBuilder<StyleConfigSchema, StyleConfigSchema, QFilterCondition> {
  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'color',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'color',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'color',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'color',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      colorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'color',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontFamily',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fontFamily',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fontFamily',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontFamily',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontFamilyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fontFamily',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontSizeEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontSizeGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontSizeLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontSize',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontSizeBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontWeight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'fontWeight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'fontWeight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'fontWeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'fontWeight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'fontWeight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'fontWeight',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'fontWeight',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'fontWeight',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      fontWeightIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'fontWeight',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      highlightBackgroundIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'highlightBackground',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      highlightBackgroundIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'highlightBackground',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      highlightBackgroundEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'highlightBackground',
        value: value,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      leftEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'left',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      leftGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'left',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      leftLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'left',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      leftBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'left',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      letterSpacingIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'letterSpacing',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      letterSpacingIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'letterSpacing',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      letterSpacingEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'letterSpacing',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      letterSpacingGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'letterSpacing',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      letterSpacingLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'letterSpacing',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      letterSpacingBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'letterSpacing',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      lineHeightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lineHeight',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      lineHeightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lineHeight',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      lineHeightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lineHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      lineHeightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lineHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      lineHeightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lineHeight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      lineHeightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lineHeight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textTransform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'textTransform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'textTransform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'textTransform',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'textTransform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'textTransform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'textTransform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'textTransform',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'textTransform',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      textTransformIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'textTransform',
        value: '',
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      topEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'top',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      topGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'top',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      topLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'top',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<StyleConfigSchema, StyleConfigSchema, QAfterFilterCondition>
      topBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'top',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension StyleConfigSchemaQueryObject
    on QueryBuilder<StyleConfigSchema, StyleConfigSchema, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

final HighlightStyleSchemaSchema = Schema(
  name: r'HighlightStyleSchema',
  id: int.parse('7428994506526584903'),
  properties: {
    r'mainColor': PropertySchema(
      id: 0,
      name: r'mainColor',
      type: IsarType.string,
    ),
    r'secondColor': PropertySchema(
      id: 1,
      name: r'secondColor',
      type: IsarType.string,
    ),
    r'thirdColor': PropertySchema(
      id: 2,
      name: r'thirdColor',
      type: IsarType.string,
    )
  },
  estimateSize: _highlightStyleSchemaEstimateSize,
  serialize: _highlightStyleSchemaSerialize,
  deserialize: _highlightStyleSchemaDeserialize,
  deserializeProp: _highlightStyleSchemaDeserializeProp,
);

int _highlightStyleSchemaEstimateSize(
  HighlightStyleSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.mainColor.length * 3;
  bytesCount += 3 + object.secondColor.length * 3;
  bytesCount += 3 + object.thirdColor.length * 3;
  return bytesCount;
}

void _highlightStyleSchemaSerialize(
  HighlightStyleSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.mainColor);
  writer.writeString(offsets[1], object.secondColor);
  writer.writeString(offsets[2], object.thirdColor);
}

HighlightStyleSchema _highlightStyleSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HighlightStyleSchema();
  object.mainColor = reader.readString(offsets[0]);
  object.secondColor = reader.readString(offsets[1]);
  object.thirdColor = reader.readString(offsets[2]);
  return object;
}

P _highlightStyleSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension HighlightStyleSchemaQueryFilter on QueryBuilder<HighlightStyleSchema,
    HighlightStyleSchema, QFilterCondition> {
  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mainColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mainColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mainColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mainColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mainColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mainColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
          QAfterFilterCondition>
      mainColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mainColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
          QAfterFilterCondition>
      mainColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mainColor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mainColor',
        value: '',
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> mainColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mainColor',
        value: '',
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secondColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secondColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secondColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'secondColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'secondColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
          QAfterFilterCondition>
      secondColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'secondColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
          QAfterFilterCondition>
      secondColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'secondColor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondColor',
        value: '',
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> secondColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'secondColor',
        value: '',
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thirdColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'thirdColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'thirdColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'thirdColor',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'thirdColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'thirdColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
          QAfterFilterCondition>
      thirdColorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'thirdColor',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
          QAfterFilterCondition>
      thirdColorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'thirdColor',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'thirdColor',
        value: '',
      ));
    });
  }

  QueryBuilder<HighlightStyleSchema, HighlightStyleSchema,
      QAfterFilterCondition> thirdColorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'thirdColor',
        value: '',
      ));
    });
  }
}

extension HighlightStyleSchemaQueryObject on QueryBuilder<HighlightStyleSchema,
    HighlightStyleSchema, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

final SubtitleConfigSchemaSchema = Schema(
  name: r'SubtitleConfigSchema',
  id: int.parse('-5380182524522609790'),
  properties: {
    r'chunkLineMaxLength': PropertySchema(
      id: 0,
      name: r'chunkLineMaxLength',
      type: IsarType.long,
    ),
    r'chunkSize': PropertySchema(
      id: 1,
      name: r'chunkSize',
      type: IsarType.long,
    )
  },
  estimateSize: _subtitleConfigSchemaEstimateSize,
  serialize: _subtitleConfigSchemaSerialize,
  deserialize: _subtitleConfigSchemaDeserialize,
  deserializeProp: _subtitleConfigSchemaDeserializeProp,
);

int _subtitleConfigSchemaEstimateSize(
  SubtitleConfigSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _subtitleConfigSchemaSerialize(
  SubtitleConfigSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.chunkLineMaxLength);
  writer.writeLong(offsets[1], object.chunkSize);
}

SubtitleConfigSchema _subtitleConfigSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubtitleConfigSchema();
  object.chunkLineMaxLength = reader.readLong(offsets[0]);
  object.chunkSize = reader.readLong(offsets[1]);
  return object;
}

P _subtitleConfigSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SubtitleConfigSchemaQueryFilter on QueryBuilder<SubtitleConfigSchema,
    SubtitleConfigSchema, QFilterCondition> {
  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkLineMaxLengthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkLineMaxLength',
        value: value,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkLineMaxLengthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chunkLineMaxLength',
        value: value,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkLineMaxLengthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chunkLineMaxLength',
        value: value,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkLineMaxLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chunkLineMaxLength',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkSizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'chunkSize',
        value: value,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkSizeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'chunkSize',
        value: value,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkSizeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'chunkSize',
        value: value,
      ));
    });
  }

  QueryBuilder<SubtitleConfigSchema, SubtitleConfigSchema,
      QAfterFilterCondition> chunkSizeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'chunkSize',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SubtitleConfigSchemaQueryObject on QueryBuilder<SubtitleConfigSchema,
    SubtitleConfigSchema, QFilterCondition> {}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

final VideoSegmentSchemaSchema = Schema(
  name: r'VideoSegmentSchema',
  id: int.parse('2829660435382776970'),
  properties: {
    r'end': PropertySchema(
      id: 0,
      name: r'end',
      type: IsarType.double,
    ),
    r'isDeleted': PropertySchema(
      id: 1,
      name: r'isDeleted',
      type: IsarType.bool,
    ),
    r'start': PropertySchema(
      id: 2,
      name: r'start',
      type: IsarType.double,
    )
  },
  estimateSize: _videoSegmentSchemaEstimateSize,
  serialize: _videoSegmentSchemaSerialize,
  deserialize: _videoSegmentSchemaDeserialize,
  deserializeProp: _videoSegmentSchemaDeserializeProp,
);

int _videoSegmentSchemaEstimateSize(
  VideoSegmentSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _videoSegmentSchemaSerialize(
  VideoSegmentSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.end);
  writer.writeBool(offsets[1], object.isDeleted);
  writer.writeDouble(offsets[2], object.start);
}

VideoSegmentSchema _videoSegmentSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = VideoSegmentSchema();
  object.end = reader.readDoubleOrNull(offsets[0]);
  object.isDeleted = reader.readBoolOrNull(offsets[1]);
  object.start = reader.readDoubleOrNull(offsets[2]);
  return object;
}

P _videoSegmentSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension VideoSegmentSchemaQueryFilter
    on QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QFilterCondition> {
  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      endIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'end',
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      endIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'end',
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      endEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'end',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      endGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'end',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      endLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'end',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      endBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'end',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      isDeletedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'isDeleted',
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      isDeletedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'isDeleted',
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      isDeletedEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isDeleted',
        value: value,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      startIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'start',
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      startIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'start',
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      startEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'start',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      startGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'start',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      startLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'start',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QAfterFilterCondition>
      startBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'start',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension VideoSegmentSchemaQueryObject
    on QueryBuilder<VideoSegmentSchema, VideoSegmentSchema, QFilterCondition> {}
