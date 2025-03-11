// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_controller.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ManualSectionEntryAdapter extends TypeAdapter<ManualSectionEntry> {
  @override
  final int typeId = 4;

  @override
  ManualSectionEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ManualSectionEntry(
      fields[0] as String,
      fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ManualSectionEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.bankId)
      ..writeByte(1)
      ..write(obj.sectionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManualSectionEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
      ..learnTimes = fields[1] as int
      ..alreadyCompleteQuestion = fields[2] as int
      ..allNeedCompleteQuestion = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, SectionUserData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lastLearnTime)
      ..writeByte(1)
      ..write(obj.learnTimes)
      ..writeByte(2)
      ..write(obj.alreadyCompleteQuestion)
      ..writeByte(3)
      ..write(obj.allNeedCompleteQuestion);
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

class BankLearnDataAdapter extends TypeAdapter<BankLearnData> {
  @override
  final int typeId = 3;

  @override
  BankLearnData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BankLearnData()
      ..needLearnSectionNum = fields[0] as int
      ..alreadyLearnSectionNum = fields[1] as int;
  }

  @override
  void write(BinaryWriter writer, BankLearnData obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.needLearnSectionNum)
      ..writeByte(1)
      ..write(obj.alreadyLearnSectionNum);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankLearnDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
