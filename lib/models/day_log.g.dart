// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DayLogAdapter extends TypeAdapter<DayLog> {
  @override
  final typeId = 2;

  @override
  DayLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DayLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      activities: (fields[2] as List).cast<ActivityType>(),
      sessionId: fields[3] as String?,
      runLogId: fields[4] as String?,
      steps: (fields[5] as num?)?.toInt(),
      walkDistanceKm: (fields[6] as num?)?.toDouble(),
      plankSeconds: (fields[7] as num?)?.toInt(),
      pushupsCount: (fields[8] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DayLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.activities)
      ..writeByte(3)
      ..write(obj.sessionId)
      ..writeByte(4)
      ..write(obj.runLogId)
      ..writeByte(5)
      ..write(obj.steps)
      ..writeByte(6)
      ..write(obj.walkDistanceKm)
      ..writeByte(7)
      ..write(obj.plankSeconds)
      ..writeByte(8)
      ..write(obj.pushupsCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityTypeAdapter extends TypeAdapter<ActivityType> {
  @override
  final typeId = 1;

  @override
  ActivityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityType.gym;
      case 1:
        return ActivityType.run;
      case 2:
        return ActivityType.swim;
      case 3:
        return ActivityType.football;
      case 4:
        return ActivityType.tt;
      case 5:
        return ActivityType.badminton;
      case 6:
        return ActivityType.hockey;
      default:
        return ActivityType.gym;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityType obj) {
    switch (obj) {
      case ActivityType.gym:
        writer.writeByte(0);
      case ActivityType.run:
        writer.writeByte(1);
      case ActivityType.swim:
        writer.writeByte(2);
      case ActivityType.football:
        writer.writeByte(3);
      case ActivityType.tt:
        writer.writeByte(4);
      case ActivityType.badminton:
        writer.writeByte(5);
      case ActivityType.hockey:
        writer.writeByte(6);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
