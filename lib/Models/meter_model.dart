// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class MeterModel {
  final String id;
  final String name;
  final String number;
  final String billingDate;
  final double billingReading;
  double latestReading;
  double consumedUnits;
  String readingDate;

  MeterModel({
    required this.id,
    required this.name,
    required this.number,
    required this.billingDate,
    required this.billingReading,
    this.latestReading = 0.0,
    this.consumedUnits = 0.0,
    this.readingDate = "",
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
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'number': number,
      'billingDate': billingDate,
      'billingReading': billingReading,
      'latestReading': latestReading,
      'consumedUnits': consumedUnits,
      'readingDate': readingDate,
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
    );
  }

  String toJson() => json.encode(toMap());

  factory MeterModel.fromJson(String source) =>
      MeterModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'MeterModel(id: $id, name: $name, number: $number, billingDate: $billingDate, billingReading: $billingReading, latestReading: $latestReading, consumedUnits: $consumedUnits, readingDate: $readingDate)';
  }

  @override
  bool operator ==(covariant MeterModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.number == number &&
        other.billingDate == billingDate &&
        other.billingReading == billingReading &&
        other.latestReading == latestReading &&
        other.consumedUnits == consumedUnits &&
        other.readingDate == readingDate;
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
        readingDate.hashCode;
  }
}
