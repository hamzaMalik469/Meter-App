import 'dart:io';

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
  List<String> _owners = [];
  String? _selectedOwnerId;
  final List<ReadingModel> _readings = [];

  List<MeterModel> get meters => _meters;
  List<String> get owners => _owners;
  String? get selectedOwner => _selectedOwnerId;
  List<ReadingModel> get readings => _readings;

  bool _isError = false;
  bool get isError => _isError;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
    await fetchMeters(); // Hive → UI first
    await getOwners();
    if (await _isConnected()) {
      await _syncToFirebase(); // Push any local unsynced up
      await _syncFromFirebase(); // Cloud → Hive (merge) then UI
    }

    _isInitialized = true;
  }

  // Get meters for a specific owner
  List<MeterModel> getMetersByOwner(String owner) {
    return _meters.where((m) => m.owner == owner).toList();
  }

  // Get all owners
  Future<void> getOwners() async {
    final seen = <String>{};
    try {
      _isLoading = true;
      notifyListeners();
      _owners = _meters
          .map((m) => m.owner)
          .where((o) => o.isNotEmpty)
          .where((o) => seen.add(o)) // ensures uniqueness
          .toList();

      // Only set default if not selected yet or current is missing
      if (_owners.isNotEmpty &&
          (_selectedOwnerId == null || !_owners.contains(_selectedOwnerId))) {
        _selectedOwnerId = _owners.first;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {}

    notifyListeners();
  }

  // Set owner of which display meters
  void setSelectedOwner(String owner) {
    _selectedOwnerId = owner;
    notifyListeners();
  }

  // -------------------------
  // Connectivity helpers
  // -------------------------
  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) return false;
    try {
      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  // -------------------------
  // Sorting helper (pinned first, then isOn)
  // -------------------------
  void _sortMeters() {
    _meters.sort((a, b) {
      if (a.isPin != b.isPin) return b.isPin ? 1 : -1; // true first
      if (a.isOn != b.isOn) return b.isOn ? 1 : -1; // true first
      return 0;
    });
  }

  // -------------------------
  // Public: batch sync both ways (kept for compatibility)
  // -------------------------
  Future<void> syncAllData() async {
    if (await _isConnected()) {
      await _syncToFirebase();
      await _syncFromFirebase();
    }
  }

  // -------------------------
  // PUSH: Local (Hive) → Firebase
  // -------------------------
  Future<void> _syncToFirebase() async {
    if (!await _isConnected() || _userId.isEmpty) return;

    try {
      // Push meters
      for (final meter in meterBox.values.where((m) => m.synced == false)) {
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('meters')
            .doc(meter.id)
            .set(meter.toMap(), SetOptions(merge: true));

        meter.synced = true;
        await meterBox.put(meter.id, meter);
      }

      // Push readings
      for (final reading in readingBox.values.where((r) => r.synced == false)) {
        final meterRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('meters')
            .doc(reading.meterId);

        await meterRef
            .collection('latest_readings')
            .doc(reading.id)
            .set(reading.toMap(), SetOptions(merge: true));

        // Also ensure meter aggregates are in sync (best-effort)
        final meter = meterBox.get(reading.meterId);
        if (meter != null) {
          await meterRef.update({
            'latestReading': meter.latestReading,
            'readingDate': meter.readingDate,
            'consumedUnits': meter.consumedUnits,
          });
        }

        final updated = reading.copyWith(synced: true);
        await readingBox.put(reading.id, updated);
      }
    } catch (e) {
      debugPrint('Sync to Firebase failed: $e');
    }
  }

  // -------------------------
  // PULL: Firebase → Local (Hive) and then UI
  // -------------------------
  Future<void> _syncFromFirebase() async {
    _isLoading = true;
    notifyListeners();
    if (!await _isConnected() || _userId.isEmpty) return;

    try {
      final ref =
          _firestore.collection('users').doc(_userId).collection('meters');

      final pinnedSnap = await ref
          .where('isPin', isEqualTo: true)
          .orderBy('isOn', descending: true)
          .get();

      final otherSnap = await ref
          .where('isPin', isEqualTo: false)
          .orderBy('isOn', descending: true)
          .get();

      final docs = [...pinnedSnap.docs, ...otherSnap.docs];

      if (docs.isNotEmpty) {
        for (var doc in docs) {
          final meter = MeterModel.fromMap(doc.data());
          // Cloud is source of truth for these docs → mark synced true
          meter.synced = true;
          await meterBox.put(meter.id, meter);
        }
        // Reload UI from Hive after merge
        _meters = meterBox.values.toList();
        _sortMeters();

        await getOwners(); // 🔹 refresh owners here

        _isError = false;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isError = true;
      _isLoading = false;
      notifyListeners();
      debugPrint('Sync from Firebase failed: $e');
      notifyListeners();
    }
  }

  // Fetch meters from hive and display on UI
  Future<void> fetchMeters() async {
    _isLoading = true;
    notifyListeners();
    try {
      _meters = meterBox.values.toList();
      _sortMeters();

      _isError = false;
    } catch (e) {
      _isError = true;

      debugPrint('Error loading meters from Hive: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReadings(String meterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1) Hive first
      final localReadings = readingBox.values
          .where((r) => r.meterId == meterId)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _readings
        ..clear()
        ..addAll(localReadings);
      notifyListeners();

      // 2) Refresh from cloud (only this meter) → merge → reload from Hive
      if (await _isConnected() && _userId.isNotEmpty) {
        final snapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('meters')
            .doc(meterId)
            .collection('latest_readings')
            .orderBy('timestamp', descending: true)
            .get();

        for (var doc in snapshot.docs) {
          final reading =
              ReadingModel.fromMap(doc.data(), doc.id).copyWith(synced: true);
          await readingBox.put(reading.id, reading);
        }

        final updated = readingBox.values
            .where((r) => r.meterId == meterId)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _readings
          ..clear()
          ..addAll(updated);
      }

      _isError = false;
    } catch (e) {
      _isError = true;
      debugPrint('Error fetching readings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------------------------
  // CRUD: METERS (Hive first)
  // -------------------------
  void addMeter(String name, String owner, String number, String billingDate,
      double billingReading) async {
    final id = const Uuid().v4();
    final newMeter = MeterModel(
      id: id,
      name: name,
      owner: owner,
      number: number,
      billingDate: billingDate,
      billingReading: billingReading,
      latestReading: 0.0,
      consumedUnits: 0.0,
      readingDate: '',
      synced: false,
      isOn: true,
      isPin: false,
    );

    _meters.add(newMeter);
    await meterBox.put(id, newMeter);
    _sortMeters();

    // 🔹 Refresh owners list here
    await getOwners();

    notifyListeners();

    await _syncToFirebase(); // push later, best-effort
  }

  Future<void> updateMeter(MeterModel updatedMeter) async {
    try {
      // Hive first
      final idx = _meters.indexWhere((m) => m.id == updatedMeter.id);
      if (idx != -1) _meters[idx] = updatedMeter;
      updatedMeter.synced = false;
      await meterBox.put(updatedMeter.id, updatedMeter);
      _sortMeters();

      // 🔹 Refresh owners list here
      await getOwners();

      notifyListeners();

      await _syncToFirebase();
    } catch (e) {
      _isError = true;
      debugPrint('Error updating meter: $e');
      notifyListeners();
    }
  }

  Future<void> deleteMeter(String meterId) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Delete locally first
      _meters.removeWhere((m) => m.id == meterId);
      await meterBox.delete(meterId);

      // Also remove related readings locally
      final toDelete =
          readingBox.values.where((r) => r.meterId == meterId).toList();
      for (final r in toDelete) {
        await readingBox.delete(r.id);
      }

      _sortMeters();

      // 🔹 Refresh owners list here
      await getOwners();

      notifyListeners();

      // Try remote delete (no tombstone here; same behavior you had)
      if (await _isConnected() && _userId.isNotEmpty) {
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
      }
    } catch (e) {
      _isError = true;
      debugPrint('Error deleting meter: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  void toggleMeterStatus(String meterId, bool newValue) async {
    final meter = meterBox.get(meterId);
    if (meter != null) {
      final updated = meter.copyWith(isOn: newValue, synced: false);
      await meterBox.put(meterId, updated);

      final index = _meters.indexWhere((m) => m.id == meterId);
      if (index != -1) _meters[index] = updated;
      _sortMeters();
      notifyListeners();

      await _syncToFirebase();
    }
  }

  void toggleMeterPinStatus(String meterId, bool newValue) async {
    final meter = meterBox.get(meterId);
    if (meter != null) {
      final updated = meter.copyWith(isPin: newValue, synced: false);
      await meterBox.put(meterId, updated);

      final index = _meters.indexWhere((m) => m.id == meterId);
      if (index != -1) _meters[index] = updated;
      _sortMeters();
      notifyListeners();

      await _syncToFirebase();
    }
  }

  // -------------------------
  // CRUD: READINGS (Hive first)
  // -------------------------
  Future<void> updateLatestReading(
      String id, double latestReading, String readingDate) async {
    // Update meter locally
    final meter = _meters.firstWhere((m) => m.id == id);
    meter.latestReading = latestReading;
    meter.readingDate = readingDate;
    meter.consumedUnits = latestReading - meter.billingReading;
    meter.synced = false;
    await meterBox.put(meter.id, meter);

    // Add reading locally
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
    await readingBox.put(readingId, newReading);
    notifyListeners();
    // Refresh UI from Hive only
    await fetchMeters();
    await fetchReadings(id);

    // Push
    await _syncToFirebase();
  }

  Future<void> editReading({
    required String meterId,
    required String docId,
    required double latestReading,
    required String readingDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1) Update in Hive first
      final localReading = readingBox.get(docId);
      if (localReading != null) {
        final oldConsumedUnits = localReading.consumedUnits;

        final meter = meterBox.get(meterId);
        if (meter != null) {
          final newConsumedUnits = latestReading - meter.billingReading;

          final updatedReading = localReading.copyWith(
            latestReading: latestReading,
            readingDate: readingDate,
            consumedUnits: newConsumedUnits,
            synced: false,
          );
          await readingBox.put(docId, updatedReading);

          final adjustedTotalUnits =
              (meter.consumedUnits - oldConsumedUnits + newConsumedUnits)
                  .clamp(0.0, double.infinity);
          meter.latestReading = latestReading;
          meter.readingDate = readingDate;
          meter.consumedUnits = adjustedTotalUnits;
          meter.synced = false;
          await meterBox.put(meterId, meter);
        }
      }

      await fetchReadings(meterId);
      await fetchMeters();

      // 2) Push
      await _syncToFirebase();
      _isError = false;
    } catch (e) {
      _isError = true;
      debugPrint("Error editing reading locally: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteReading(String meterId, String readingId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1) Delete from Hive first
      final localReading = readingBox.get(readingId);
      if (localReading != null) {
        final deletedConsumedUnits = localReading.consumedUnits;
        await readingBox.delete(readingId);

        final meter = meterBox.get(meterId);
        if (meter != null) {
          final newConsumedUnits = (meter.consumedUnits - deletedConsumedUnits);
          meter.consumedUnits = newConsumedUnits < 0 ? 0.0 : newConsumedUnits;
          // If the deleted reading was the latest, you may want to recompute latestReading/readingDate here.
          meter.synced = false;
          await meterBox.put(meterId, meter);
        }
      }

      await fetchReadings(meterId);
      await fetchMeters();

      // 2) Best-effort remote delete
      if (await _isConnected() && _userId.isNotEmpty) {
        final readingDocRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('meters')
            .doc(meterId)
            .collection('latest_readings')
            .doc(readingId);

        final readingSnapshot = await readingDocRef.get();
        if (readingSnapshot.exists) {
          final deletedConsumedUnits =
              readingSnapshot.data()?['consumedUnits'] ?? 0.0;

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
            final newConsumedUnits =
                currentConsumedUnits - deletedConsumedUnits;

            await meterDocRef.update({
              'consumedUnits': newConsumedUnits < 0 ? 0.0 : newConsumedUnits,
            });
          }
        }
      }

      _isError = false;
    } catch (e) {
      _isError = true;
      debugPrint("Error deleting reading: $e");
    }

    _isLoading = false;
    notifyListeners();
  }
}
