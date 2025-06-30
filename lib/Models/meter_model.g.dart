// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meter_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeterModelAdapter extends TypeAdapter<MeterModel> {
  @override
  final int typeId = 0;

  @override
  MeterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeterModel(
      id: fields[0] as String,
      name: fields[1] as String,
      number: fields[2] as String,
      billingDate: fields[3] as String,
      billingReading: fields[4] as double,
      latestReading: fields[5] as double,
      consumedUnits: fields[6] as double,
      readingDate: fields[7] as String,
      synced: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MeterModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.number)
      ..writeByte(3)
      ..write(obj.billingDate)
      ..writeByte(4)
      ..write(obj.billingReading)
      ..writeByte(5)
      ..write(obj.latestReading)
      ..writeByte(6)
      ..write(obj.consumedUnits)
      ..writeByte(7)
      ..write(obj.readingDate)
      ..writeByte(8)
      ..write(obj.synced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
