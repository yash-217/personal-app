// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weight_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeightEntryAdapter extends TypeAdapter<WeightEntry> {
  @override
  final typeId = 5;

  @override
  WeightEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeightEntry(
      id: fields[0] as String,
      exerciseId: fields[1] as String,
      date: fields[2] as DateTime,
      weight: (fields[3] as num).toDouble(),
      reps: (fields[4] as num?)?.toInt(),
      sets: (fields[5] as num?)?.toInt(),
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, WeightEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.reps)
      ..writeByte(5)
      ..write(obj.sets)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeightEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
