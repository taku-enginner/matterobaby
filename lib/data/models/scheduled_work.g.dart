// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_work.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduledWorkAdapter extends TypeAdapter<ScheduledWork> {
  @override
  final int typeId = 2;

  @override
  ScheduledWork read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScheduledWork(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      createdAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ScheduledWork obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduledWorkAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
