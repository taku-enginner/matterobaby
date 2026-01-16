// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 1;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      periodStartDate: fields[0] as DateTime,
      notificationsEnabled: fields[1] as bool,
      weeklyGoalDays: fields[2] as int,
      reminderHour: fields[3] as int,
      reminderMinute: fields[4] as int,
      reminderDays: (fields[5] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5],
      shareCode: fields[6] as String?,
      shareCodeCreatedAt: fields[7] as DateTime?,
      scheduledWeekdays: (fields[8] as List?)?.cast<int>() ?? const [],
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.periodStartDate)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.weeklyGoalDays)
      ..writeByte(3)
      ..write(obj.reminderHour)
      ..writeByte(4)
      ..write(obj.reminderMinute)
      ..writeByte(5)
      ..write(obj.reminderDays)
      ..writeByte(6)
      ..write(obj.shareCode)
      ..writeByte(7)
      ..write(obj.shareCodeCreatedAt)
      ..writeByte(8)
      ..write(obj.scheduledWeekdays);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
