// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sleep_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SleepLogAdapter extends TypeAdapter<SleepLog> {
  @override
  final typeId = 13;

  @override
  SleepLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SleepLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      bedtime: fields[2] as DateTime,
      wakeTime: fields[3] as DateTime,
      avoidedScreentime: fields[4] == null ? false : fields[4] as bool,
      quality: fields[5] == null ? 5 : (fields[5] as num).toInt(),
      mood: fields[6] as String?,
      notes: fields[7] as String?,
      morningErection: fields[8] as bool?,
      period: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, SleepLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.bedtime)
      ..writeByte(3)
      ..write(obj.wakeTime)
      ..writeByte(4)
      ..write(obj.avoidedScreentime)
      ..writeByte(5)
      ..write(obj.quality)
      ..writeByte(6)
      ..write(obj.mood)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.morningErection)
      ..writeByte(9)
      ..write(obj.period);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
