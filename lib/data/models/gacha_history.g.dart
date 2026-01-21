// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gacha_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GachaHistoryAdapter extends TypeAdapter<GachaHistory> {
  @override
  final int typeId = 4;

  @override
  GachaHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GachaHistory(
      id: fields[0] as String,
      rewardId: fields[1] as String,
      rewardName: fields[2] as String,
      spunAt: fields[3] as DateTime,
      isTestMode: fields[4] == null ? false : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GachaHistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rewardId)
      ..writeByte(2)
      ..write(obj.rewardName)
      ..writeByte(3)
      ..write(obj.spunAt)
      ..writeByte(4)
      ..write(obj.isTestMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GachaHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
