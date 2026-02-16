// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final typeId = 3;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      targetMuscleGroups: (fields[2] as List).cast<String>(),
      exerciseIds: (fields[3] as List).cast<String>(),
      completed: fields[4] == null ? false : fields[4] as bool,
      performance: fields[5] == null
          ? const {}
          : (fields[5] as Map).map(
              (dynamic k, dynamic v) =>
                  MapEntry(k as String, (v as List).cast<WorkoutSet>()),
            ),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.targetMuscleGroups)
      ..writeByte(3)
      ..write(obj.exerciseIds)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.performance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final typeId = 12;

  @override
  WorkoutSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSet(
      weightLbs: (fields[0] as num).toDouble(),
      weightKg: (fields[1] as num).toDouble(),
      reps: (fields[2] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.weightLbs)
      ..writeByte(1)
      ..write(obj.weightKg)
      ..writeByte(2)
      ..write(obj.reps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
