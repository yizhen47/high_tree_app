// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_bank.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleQuestionData _$SingleQuestionDataFromJson(Map<String, dynamic> json) =>
    SingleQuestionData(
      json['question'] as Map<String, dynamic>,
      json['fromId'] as String,
      json['fromDisplayName'] as String,
    )
      ..fromKonwledgePoint = (json['fromKonwledgePoint'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..fromKonwledgeIndex = (json['fromKonwledgeIndex'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

Map<String, dynamic> _$SingleQuestionDataToJson(SingleQuestionData instance) =>
    <String, dynamic>{
      'fromKonwledgePoint': instance.fromKonwledgePoint,
      'fromKonwledgeIndex': instance.fromKonwledgeIndex,
      'question': instance.question,
      'fromId': instance.fromId,
      'fromDisplayName': instance.fromDisplayName,
    };

Section _$SectionFromJson(Map<String, dynamic> json) => Section(
      json['index'] as String,
      json['title'] as String,
    )
      ..note = json['note'] as String?
      ..image = json['image'] as String?
      ..children = (json['children'] as List<dynamic>?)
          ?.map((e) => Section.fromJson(e as Map<String, dynamic>))
          .toList()
      ..questions = (json['questions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList()
      ..videos =
          (json['videos'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..fromKonwledgePoint = (json['fromKonwledgePoint'] as List<dynamic>)
          .map((e) => e as String)
          .toList()
      ..fromKonwledgeIndex = (json['fromKonwledgeIndex'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

Map<String, dynamic> _$SectionToJson(Section instance) => <String, dynamic>{
      'index': instance.index,
      'title': instance.title,
      'note': instance.note,
      'image': instance.image,
      'children': instance.children,
      'questions': instance.questions,
      'videos': instance.videos,
      'fromKonwledgePoint': instance.fromKonwledgePoint,
      'fromKonwledgeIndex': instance.fromKonwledgeIndex,
    };
