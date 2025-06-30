// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingModelAdapter extends TypeAdapter<ReadingModel> {
  @override
  final int typeId = 1;

  @override
  ReadingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingModel(
      id: fields[0] as String,
      latestReading: fields[1] as double,
      consumedUnits: fields[2] as double,
      readingDate: fields[3] as String,
      timestamp: fields[4] as DateTime,
      meterId: fields[5] as String,
      synced: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latestReading)
      ..writeByte(2)
      ..write(obj.consumedUnits)
      ..writeByte(3)
      ..write(obj.readingDate)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.meterId)
      ..writeByte(6)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
