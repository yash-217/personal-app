// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'body_metrics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BodyMetricsAdapter extends TypeAdapter<BodyMetrics> {
  @override
  final typeId = 7;

  @override
  BodyMetrics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BodyMetrics(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      weight: (fields[2] as num).toDouble(),
      bodyFatPercentage: fields[3] == null ? 0 : (fields[3] as num).toDouble(),
      bmi: fields[5] == null ? 0 : (fields[5] as num).toDouble(),
      bodyFatMass: fields[6] == null ? 0 : (fields[6] as num).toDouble(),
      totalBodyWater: fields[7] == null ? 0 : (fields[7] as num).toDouble(),
      protein: fields[8] == null ? 0 : (fields[8] as num).toDouble(),
      minerals: fields[9] == null ? 0 : (fields[9] as num).toDouble(),
      visceralFatLevel: fields[10] == null ? 0 : (fields[10] as num).toDouble(),
      basalMetabolicRate: fields[11] == null
          ? 0
          : (fields[11] as num).toDouble(),
      waistHipRatio: fields[12] == null ? 0 : (fields[12] as num).toDouble(),
      recommendedCalorieIntake: fields[13] == null
          ? 0
          : (fields[13] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, BodyMetrics obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.weight)
      ..writeByte(3)
      ..write(obj.bodyFatPercentage)
      ..writeByte(5)
      ..write(obj.bmi)
      ..writeByte(6)
      ..write(obj.bodyFatMass)
      ..writeByte(7)
      ..write(obj.totalBodyWater)
      ..writeByte(8)
      ..write(obj.protein)
      ..writeByte(9)
      ..write(obj.minerals)
      ..writeByte(10)
      ..write(obj.visceralFatLevel)
      ..writeByte(11)
      ..write(obj.basalMetabolicRate)
      ..writeByte(12)
      ..write(obj.waistHipRatio)
      ..writeByte(13)
      ..write(obj.recommendedCalorieIntake);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BodyMetricsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
