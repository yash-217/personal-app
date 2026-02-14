// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_routine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutRoutineAdapter extends TypeAdapter<WorkoutRoutine> {
  @override
  final typeId = 10;

  @override
  WorkoutRoutine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutRoutine(
      id: fields[0] as String,
      name: fields[1] as String,
      exerciseIds: (fields[2] as List).cast<String>(),
      color: (fields[3] as num).toInt(),
      targetMuscles: fields[4] == null
          ? const []
          : (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutRoutine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.exerciseIds)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.targetMuscles);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutRoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
