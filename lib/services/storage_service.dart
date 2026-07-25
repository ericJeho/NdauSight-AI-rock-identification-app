import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/discovery.dart';
import '../models/scan_result.dart';

/// Offline-first persistence layer built on Hive.
///
/// Scans and discoveries are stored as JSON strings, so no generated Hive
/// adapters are required — the app runs straight after `flutter pub get`.
class StorageService {
  static const _scansBox = 'scans';
  static const _discoveriesBox = 'discoveries';

  late Box<String> _scans;
  late Box<String> _discoveries;

  Future<void> init() async {
    await Hive.initFlutter();
    _scans = await Hive.openBox<String>(_scansBox);
    _discoveries = await Hive.openBox<String>(_discoveriesBox);

    if (_discoveries.isEmpty) {
      await _seedDiscoveries();
    }
  }

  // --- Scans -----------------------------------------------------------------

  List<ScanResult> allScans() {
    final list = _scans.values
        .map((s) => ScanResult.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> saveScan(ScanResult scan) async {
    await _scans.put(scan.id, jsonEncode(scan.toJson()));
  }

  Future<void> deleteScan(String id) async {
    await _scans.delete(id);
  }

  List<ScanResult> unsyncedScans() =>
      allScans().where((s) => !s.synced).toList();

  // --- Discoveries -----------------------------------------------------------

  List<Discovery> allDiscoveries() {
    final list = _discoveries.values
        .map((s) =>
            Discovery.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> saveDiscovery(Discovery d) async {
    await _discoveries.put(d.id, jsonEncode(d.toJson()));
  }

  Future<void> _seedDiscoveries() async {
    // A few example community pins so the map isn't empty on first launch.
    // Coordinates sit around the Great Dyke / Zimbabwe mineral belts.
    final seeds = [
      Discovery(
        author: 'T. Moyo',
        rockType: 'Quartz Vein',
        topMineral: 'Gold',
        topProbability: 68,
        latitude: -18.9219,
        longitude: 29.9219,
        note: 'Visible quartz reef along the ridge.',
        rating: 4.4,
        ratingCount: 12,
      ),
      Discovery(
        author: 'A. Ncube',
        rockType: 'Pegmatite',
        topMineral: 'Lithium',
        topProbability: 74,
        latitude: -20.1500,
        longitude: 30.8300,
        note: 'Coarse spodumene-looking crystals.',
        rating: 4.8,
        ratingCount: 21,
      ),
      Discovery(
        author: 'R. Dube',
        rockType: 'Malachite-stained Basalt',
        topMineral: 'Copper',
        topProbability: 61,
        latitude: -19.4500,
        longitude: 29.8100,
        note: 'Strong green staining on outcrop.',
        rating: 4.0,
        ratingCount: 8,
      ),
    ];
    for (final d in seeds) {
      await saveDiscovery(d);
    }
  }
}
