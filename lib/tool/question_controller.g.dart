// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_controller.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SectionUserDataAdapter extends TypeAdapter<SectionUserData> {
  @override
  final int typeId = 2;

  @override
  SectionUserData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SectionUserData()
      ..lastLearnTime = fields[0] as int
      ..learnTimes = fields[1] as int;
  }

  @override
  void write(BinaryWriter writer, SectionUserData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lastLearnTime)
      ..writeByte(1)
      ..write(obj.learnTimes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectionUserDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
