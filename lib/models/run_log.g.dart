// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RunLogAdapter extends TypeAdapter<RunLog> {
  @override
  final typeId = 4;

  @override
  RunLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RunLog(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      distanceKm: (fields[2] as num).toDouble(),
      durationSeconds: (fields[3] as num).toInt(),
      elevationGain: (fields[4] as num?)?.toDouble(),
      source: fields[5] == null ? 'manual' : fields[5] as String,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RunLog obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.distanceKm)
      ..writeByte(3)
      ..write(obj.durationSeconds)
      ..writeByte(4)
      ..write(obj.elevationGain)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
