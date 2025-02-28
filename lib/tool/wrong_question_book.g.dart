// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wrong_question_book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionUserDataAdapter extends TypeAdapter<QuestionUserData> {
  @override
  final int typeId = 1;

  @override
  QuestionUserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionUserData(
      fields[0] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionUserData obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.tryCompleteTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionUserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
