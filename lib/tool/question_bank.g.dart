// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_bank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      json['index'] as String,
      json['title'] as String,
    )
      ..note = json['note'] as String?
      ..children = (json['children'] as List<dynamic>?)
          ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList()
      ..questions = (json['questions'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList();

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'index': instance.index,
      'title': instance.title,
      'note': instance.note,
      'children': instance.children,
      'questions': instance.questions,
    };

QuestionBankData _$QuestionBankDataFromJson(Map<String, dynamic> json) =>
    QuestionBankData()
      ..displayName = json['displayName'] as String?
      ..data = (json['data'] as List<dynamic>?)
          ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList()
      ..id = json['id'] as String?
      ..version = (json['version'] as num?)?.toInt();

Map<String, dynamic> _$QuestionBankDataToJson(QuestionBankData instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'data': instance.data,
      'id': instance.id,
      'version': instance.version,
    };
