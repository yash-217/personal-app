import 'package:hive_ce/hive_ce.dart';

class SleepLog extends HiveObject {
  final String id;
  final DateTime date;
  final DateTime bedtime;
  final DateTime wakeTime;
  final bool avoidedScreentime;
  final int quality; // 1-10
  final String? mood;
  final String? notes;
  final int? morningErection; // 0-5 rating (null if not applicable)
  final bool? period;

  SleepLog({
    required this.id,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    this.avoidedScreentime = false,
    this.quality = 5,
    this.mood,
    this.notes,
    this.morningErection,
    this.period,
  });

  /// Duration in minutes
  int get durationMinutes => wakeTime.difference(bedtime).inMinutes;

  /// Formatted duration like "7h 30m"
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  SleepLog copyWith({
    String? id,
    DateTime? date,
    DateTime? bedtime,
    DateTime? wakeTime,
    bool? avoidedScreentime,
    int? quality,
    String? mood,
    String? notes,
    int? morningErection,
    bool? period,
  }) {
    return SleepLog(
      id: id ?? this.id,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      avoidedScreentime: avoidedScreentime ?? this.avoidedScreentime,
      quality: quality ?? this.quality,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
      morningErection: morningErection ?? this.morningErection,
      period: period ?? this.period,
    );
  }
}

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
      morningErection: fields[8] is num
          ? (fields[8] as num).toInt()
          : (fields[9] is num ? (fields[9] as num).toInt() : null),
      period: fields[9] is bool
          ? fields[9] as bool?
          : (fields[8] is bool ? fields[8] as bool? : null),
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
