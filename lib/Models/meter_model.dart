// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';
import 'package:hive/hive.dart';

part 'meter_model.g.dart';

@HiveType(typeId: 0)
class MeterModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String number;

  @HiveField(3)
  final String billingDate;

  @HiveField(4)
  final double billingReading;

  @HiveField(5)
  double latestReading;

  @HiveField(6)
  double consumedUnits;

  @HiveField(7)
  String readingDate;

  @HiveField(8)
  bool synced;

  MeterModel({
    required this.id,
    required this.name,
    required this.number,
    required this.billingDate,
    required this.billingReading,
    this.latestReading = 0.0,
    this.consumedUnits = 0.0,
    this.readingDate = "",
    this.synced = false,
  });

  factory MeterModel.fromMap(Map<String, dynamic> data) {
    return MeterModel(
      id: data['id'],
      name: data['name'],
      number: data['number'],
      billingDate: data['billingDate'],
      billingReading: data['billingReading'],
      latestReading: data['latestReading'],
      consumedUnits: data['consumedUnits'],
      readingDate: data['readingDate'],
      synced: data['synced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'number': number,
      'billingDate': billingDate,
      'billingReading': billingReading,
      'latestReading': latestReading,
      'consumedUnits': consumedUnits,
      'readingDate': readingDate,
      'synced': synced,
    };
  }

  MeterModel copyWith({
    String? id,
    String? name,
    String? number,
    String? billingDate,
    double? billingReading,
    double? latestReading,
    double? consumedUnits,
    String? readingDate,
    bool? synced,
  }) {
    return MeterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      billingDate: billingDate ?? this.billingDate,
      billingReading: billingReading ?? this.billingReading,
      latestReading: latestReading ?? this.latestReading,
      consumedUnits: consumedUnits ?? this.consumedUnits,
      readingDate: readingDate ?? this.readingDate,
      synced: synced ?? this.synced,
    );
  }

  String toJson() => json.encode(toMap());

  factory MeterModel.fromJson(String source) =>
      MeterModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'MeterModel(id: $id, name: $name, number: $number, billingDate: $billingDate, billingReading: $billingReading, latestReading: $latestReading, consumedUnits: $consumedUnits, readingDate: $readingDate, synced: $synced)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MeterModel &&
        other.id == id &&
        other.name == name &&
        other.number == number &&
        other.billingDate == billingDate &&
        other.billingReading == billingReading &&
        other.latestReading == latestReading &&
        other.consumedUnits == consumedUnits &&
        other.readingDate == readingDate &&
        other.synced == synced;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    number.hashCode ^
    billingDate.hashCode ^
    billingReading.hashCode ^
    latestReading.hashCode ^
    consumedUnits.hashCode ^
    readingDate.hashCode ^
    synced.hashCode;
  }
}
