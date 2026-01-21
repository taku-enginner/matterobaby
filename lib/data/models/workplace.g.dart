// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workplace.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkplaceAdapter extends TypeAdapter<Workplace> {
  @override
  final int typeId = 5;

  @override
  Workplace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workplace(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      createdAt: fields[3] as DateTime,
      isDefault: fields[4] == null ? false : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Workplace obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isDefault);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkplaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
