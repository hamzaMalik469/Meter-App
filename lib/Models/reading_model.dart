import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'reading_model.g.dart';

@HiveType(typeId: 1)
class ReadingModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double latestReading;

  @HiveField(2)
  final double consumedUnits;

  @HiveField(3)
  final String readingDate;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String meterId;

  @HiveField(6)
  final bool synced;

  ReadingModel({
    required this.id,
    required this.latestReading,
    required this.consumedUnits,
    required this.readingDate,
    required this.timestamp,
    required this.meterId,
    this.synced = false,
  });

  factory ReadingModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return ReadingModel(
      id: id ?? data['id'],
      latestReading: (data['latestReading'] ?? 0.0).toDouble(),
      consumedUnits: (data['consumedUnits'] ?? 0.0).toDouble(),
      readingDate: data['readingDate'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      meterId: data['meterId'] ?? '',
      synced: data['synced'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latestReading': latestReading,
      'consumedUnits': consumedUnits,
      'readingDate': readingDate,
      'timestamp': timestamp,
      'meterId': meterId,
      'synced': synced,
    };
  }

  /// CopyWith method for immutability
  ReadingModel copyWith({
    String? id,
    double? latestReading,
    double? consumedUnits,
    String? readingDate,
    DateTime? timestamp,
    String? meterId,
    bool? synced,
  }) {
    return ReadingModel(
      id: id ?? this.id,
      latestReading: latestReading ?? this.latestReading,
      consumedUnits: consumedUnits ?? this.consumedUnits,
      readingDate: readingDate ?? this.readingDate,
      timestamp: timestamp ?? this.timestamp,
      meterId: meterId ?? this.meterId,
      synced: synced ?? this.synced,
    );
  }
}
