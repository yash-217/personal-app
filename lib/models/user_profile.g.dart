// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final typeId = 6;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      name: fields[0] as String,
      age: (fields[1] as num).toInt(),
      height: (fields[2] as num).toDouble(),
      weight: (fields[3] as num).toDouble(),
      gender: fields[4] as String,
      weeklyGoal: fields[5] == null ? 4 : (fields[5] as num).toInt(),
      weightUnit: fields[6] == null ? 'kg' : fields[6] as String,
      birthDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.age)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.gender)
      ..writeByte(5)
      ..write(obj.weeklyGoal)
      ..writeByte(6)
      ..write(obj.weightUnit)
      ..writeByte(7)
      ..write(obj.birthDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
