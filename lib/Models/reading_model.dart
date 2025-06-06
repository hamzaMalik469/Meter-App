class ReadingModel {
  final String id; // <-- Important: document ID
  final double latestReading;
  final double consumedUnits;
  final String readingDate;

  ReadingModel({
    required this.id,
    required this.latestReading,
    required this.consumedUnits,
    required this.readingDate,
  });

  factory ReadingModel.fromMap(Map<String, dynamic> data, String id) {
    return ReadingModel(
      id: id,
      latestReading: (data['latestReading'] ?? 0.0).toDouble(),
      consumedUnits: (data['consumedUnits'] ?? 0.0).toDouble(),
      readingDate: data['readingDate'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latestReading': latestReading,
      'consumedUnits': consumedUnits,
      'readingDate': readingDate,
    };
  }
}
