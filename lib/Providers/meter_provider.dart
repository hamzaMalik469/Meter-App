import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/meter_model.dart';
import '../models/reading_model.dart';

class MeterProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<MeterModel> _meters = [];
  final List<ReadingModel> _readings = [];

  List<MeterModel> get meters => _meters;
  List<ReadingModel> get readings => _readings;

  bool _isError = false;
  bool get isError => _isError;

  final Box<MeterModel> meterBox;
  final Box<ReadingModel> readingBox;

  String get _userId => _auth.currentUser?.uid ?? '';
  bool _isInitialized = false;

  MeterProvider({
    required this.meterBox,
    required this.readingBox,
  });

  Future<void> init() async {
    if (_isInitialized) return;
    await fetchMeters();
    await syncAllData();
    _isInitialized = true;
  }

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> syncAllData() async {
    for (final meter in _meters.where((m) => !m.synced)) {
      await _trySyncMeter(meter);
    }
    for (final reading in readingBox.values.where((r) => !r.synced)) {
      await _trySyncReading(reading.meterId, reading);
    }
  }

  Future<void> _trySyncMeter(MeterModel meter) async {
    final connected = await _isConnected();
    if (!connected || meter.synced) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meter.id)
          .set(meter.toMap());
      meter.synced = true;
      meterBox.put(meter.id, meter);
    } catch (e) {
      print("Error syncing meter: $e");
    }
  }

  Future<void> _trySyncReading(String meterId, ReadingModel reading) async {
    final connected = await _isConnected();
    if (!connected || reading.synced) return;

    try {
      final meterRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId);
      await meterRef
          .collection('latest_readings')
          .doc(reading.id)
          .set(reading.toMap());
      await meterRef.update({
        'latestReading': reading.latestReading,
        'readingDate': reading.readingDate,
        'consumedUnits': reading.consumedUnits,
      });

      reading.synced = true;
      readingBox.put(reading.id, reading);

      final meter = _meters.firstWhere((m) => m.id == meterId);
      meter.synced = true;
      meterBox.put(meter.id, meter);
    } catch (e) {
      print("Error syncing reading: $e");
    }
  }

  Future<void> fetchMeters() async {
    try {
      // 1️⃣ Fetch from Hive first
      final localBox = await Hive.openBox<MeterModel>('meters');
      _meters = localBox.values.toList();

      notifyListeners(); // Notify UI with local data first

      // 2️⃣ Then fetch from Firestore (for latest sync)
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .get();

      final firestoreMeters = <MeterModel>[];

      for (var doc in snapshot.docs) {
        final meter = MeterModel.fromMap(doc.data());
        firestoreMeters.add(meter);

        // Sync Firestore data into Hive (update or add)
        await localBox.put(meter.id, meter);
      }

      _meters = firestoreMeters;
      _isError = false;
      notifyListeners(); // Notify again with updated Firestore data
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error fetching meters: $e");
    }
  }

  Future<void> fetchReadings(String meterId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings')
          .orderBy('timestamp', descending: true)
          .get();

      _readings.clear();
      for (var doc in snapshot.docs) {
        _readings.add(ReadingModel.fromMap(doc.data(), doc.id));
      }
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error fetching readings: $e");
    }
  }

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
      readingDate: '',
      synced: false,
    );

    _meters.add(newMeter);
    meterBox.put(id, newMeter);
    notifyListeners();

    await _trySyncMeter(newMeter);
  }

  Future<void> updateMeter(MeterModel updatedMeter) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(updatedMeter.id)
          .update(updatedMeter.toMap());

      final index = _meters.indexWhere((m) => m.id == updatedMeter.id);
      if (index != -1) {
        _meters[index] = updatedMeter;
        meterBox.put(updatedMeter.id, updatedMeter);
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
      final readingsRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings');
      final readingsSnapshot = await readingsRef.get();
      for (var doc in readingsSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .delete();

      _meters.removeWhere((meter) => meter.id == meterId);
      meterBox.delete(meterId);
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error deleting meter: $e");
    }
  }

  void updateLatestReading(
      String id, double latestReading, String readingDate) async {
    final meter = _meters.firstWhere((m) => m.id == id);
    meter.latestReading = latestReading;
    meter.readingDate = readingDate;
    meter.consumedUnits = latestReading - meter.billingReading;
    meter.synced = false;

    meterBox.put(meter.id, meter);

    final readingId = const Uuid().v4();
    final newReading = ReadingModel(
      id: readingId,
      latestReading: latestReading,
      readingDate: readingDate,
      consumedUnits: meter.consumedUnits,
      timestamp: DateTime.now(),
      synced: false,
      meterId: id,
    );

    readingBox.put(readingId, newReading);

    await fetchMeters();
    notifyListeners();

    await _trySyncReading(id, newReading);
  }

  Future<void> editReading({
    required String meterId,
    required String docId,
    required double latestReading,
    required String readingDate,
  }) async {
    try {
      final readingRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings')
          .doc(docId);

      final oldSnapshot = await readingRef.get();
      final oldData = oldSnapshot.data();
      if (oldData == null) return;

      final oldConsumedUnits = oldData['consumedUnits'] ?? 0.0;

      final meterDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .get();
      final billingReading = meterDoc.data()?['billingReading'] ?? 0.0;

      final newConsumedUnits = latestReading - billingReading;

      await readingRef.update({
        'latestReading': latestReading,
        'readingDate': readingDate,
        'consumedUnits': newConsumedUnits,
      });

      final currentTotalUnits = meterDoc.data()?['consumedUnits'] ?? 0.0;
      final adjustedTotalUnits =
          (currentTotalUnits - oldConsumedUnits + newConsumedUnits)
              .clamp(0.0, double.infinity);

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .update({
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

  Future<void> deleteReading(String meterId, String readingId) async {
    try {
      final readingDocRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId)
          .collection('latest_readings')
          .doc(readingId);

      final readingSnapshot = await readingDocRef.get();
      if (!readingSnapshot.exists) return;

      final deletedReading = readingSnapshot.data();
      final deletedConsumedUnits = deletedReading?['consumedUnits'] ?? 0.0;

      await readingDocRef.delete();

      final meterDocRef = _firestore
          .collection('users')
          .doc(_userId)
          .collection('meters')
          .doc(meterId);
      final meterSnapshot = await meterDocRef.get();
      final meterData = meterSnapshot.data();
      if (meterData != null) {
        final currentConsumedUnits = meterData['consumedUnits'] ?? 0.0;
        final newConsumedUnits = currentConsumedUnits - deletedConsumedUnits;

        await meterDocRef.update({
          'consumedUnits': newConsumedUnits < 0 ? 0.0 : newConsumedUnits,
        });
      }

      await fetchReadings(meterId);
      notifyListeners();
    } catch (e) {
      _isError = true;
      notifyListeners();
      print("Error deleting reading: $e");
    }
  }
}
