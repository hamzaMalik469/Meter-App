import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/meter_model.dart';
import '../models/reading_model.dart';

class MeterProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<MeterModel> _meters = [];
  final List<ReadingModel> _readings = [];

  List<MeterModel> get meters => _meters;
  List<ReadingModel> get readings => _readings;

  bool _isError = false;
  bool get isError => _isError;

  // Fetch readings for a specific meter
  Future<void> fetchReadings(String meterId) async {
    try {
      final snapshot = await _firestore
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings')
          .orderBy('timestamp', descending: true)
          .get();

      _readings.clear();

      for (var doc in snapshot.docs) {
        _readings.add(ReadingModel.fromMap(doc.data(), doc.id)); // Pass doc.id
      }

      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error fetching readings: $e");
    }
  }

  Future<void> updateMeter(MeterModel updatedMeter) async {
    try {
      await _firestore
          .collection('meters')
          .doc(updatedMeter.id)
          .update(updatedMeter.toMap());

      final index = _meters.indexWhere((m) => m.id == updatedMeter.id);
      if (index != -1) {
        _meters[index] = updatedMeter;
        notifyListeners();
      }
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error updating meter: $e");
    }
  }

  Future<void> deleteMeter(String meterId) async {
    try {
      // Delete all subcollection readings first
      final readingsRef = _firestore
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings');
      final readingsSnapshot = await readingsRef.get();
      for (var doc in readingsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the meter
      await _firestore.collection('meters').doc(meterId).delete();

      _meters.removeWhere((meter) => meter.id == meterId);
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error deleting meter: $e");
    }
  }

  // Add a new meter
  void addMeter(String name, String number, String billingDate,
      double billingReading) async {
    final id = const Uuid().v4();
    final newMeter = MeterModel(
      id: id,
      name: name,
      number: number,
      billingDate: billingDate,
      billingReading: billingReading,
      latestReading: 0.0,
      consumedUnits: 0.0,
      readingDate: "",
    );

    try {
      await _firestore.collection('meters').doc(id).set(newMeter.toMap());

      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
    }
  }

  // Update meter with new reading
  void updateLatestReading(
      String id, double latestReading, String readingDate) async {
    final meter = _meters.firstWhere((m) => m.id == id);
    meter.latestReading = latestReading;
    meter.readingDate = readingDate;
    meter.consumedUnits = latestReading - meter.billingReading;

    try {
      final latestReadingRef = _firestore
          .collection('meters')
          .doc(id)
          .collection('latest_readings')
          .doc();

      await latestReadingRef.set({
        'latestReading': latestReading,
        'consumedUnits': meter.consumedUnits,
        'readingDate': readingDate,
        'timestamp': Timestamp.now(),
      });

      await _firestore.collection('meters').doc(id).update({
        'latestReading': latestReading,
        'consumedUnits': meter.consumedUnits,
        'readingDate': readingDate
      });
      fetchMeters();

      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error updating meter reading: $e");
    }
  }

  // Edit an existing reading
  Future<void> editReading({
    required String meterId,
    required String docId,
    required double latestReading,
    required String readingDate,
  }) async {
    try {
      final readingRef = _firestore
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings')
          .doc(docId);

      // Get the old reading first
      final oldSnapshot = await readingRef.get();
      final oldData = oldSnapshot.data();
      if (oldData == null) return;

      final oldConsumedUnits = oldData['consumedUnits'] ?? 0.0;

      // Get the meter to calculate new consumed units
      final meterDoc = await _firestore.collection('meters').doc(meterId).get();
      final billingReading = meterDoc.data()?['billingReading'] ?? 0.0;

      final newConsumedUnits = latestReading - billingReading;

      // Update the reading
      await readingRef.update({
        'latestReading': latestReading,
        'readingDate': readingDate,
        'consumedUnits': newConsumedUnits,
      });

      // Update the meter's total consumed units
      final currentTotalUnits = meterDoc.data()?['consumedUnits'] ?? 0.0;
      final adjustedTotalUnits =
          (currentTotalUnits - oldConsumedUnits + newConsumedUnits)
              .clamp(0.0, double.infinity);

      await _firestore.collection('meters').doc(meterId).update({
        'latestReading': latestReading,
        'readingDate': readingDate,
        'consumedUnits': adjustedTotalUnits,
      });

      await fetchReadings(meterId);
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error editing reading: $e");
    }
  }

  // Delete a reading
  Future<void> deleteReading(String meterId, String readingId) async {
    try {
      final readingDocRef = _firestore
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings')
          .doc(readingId);

      // Get the reading data first
      final readingSnapshot = await readingDocRef.get();
      if (!readingSnapshot.exists) return;

      final deletedReading = readingSnapshot.data();
      final deletedConsumedUnits = deletedReading?['consumedUnits'] ?? 0.0;

      // Delete the reading
      await readingDocRef.delete();

      // Get current meter data
      final meterDocRef = _firestore.collection('meters').doc(meterId);
      final meterSnapshot = await meterDocRef.get();
      final meterData = meterSnapshot.data();
      if (meterData != null) {
        final currentConsumedUnits = meterData['consumedUnits'] ?? 0.0;
        final newConsumedUnits = currentConsumedUnits - deletedConsumedUnits;

        await meterDocRef.update({
          'consumedUnits': newConsumedUnits < 0 ? 0.0 : newConsumedUnits,
        });
      }

      // Refetch readings for UI update
      await fetchReadings(meterId);
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error deleting reading: $e");
    }
  }

  // Fetch all meters
  Future<void> fetchMeters() async {
    try {
      final snapshot = await _firestore.collection('meters').get();
      _meters.clear();
      for (var doc in snapshot.docs) {
        _meters.add(MeterModel.fromMap(doc.data()));
      }
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error fetching meters: $e");
    }
  }
}
