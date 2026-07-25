import 'package:flutter/foundation.dart';

import '../models/discovery.dart';
import '../models/scan_result.dart';
import 'ai_service.dart';
import 'app_settings.dart';
import 'location_service.dart';
import 'storage_service.dart';
import 'sync_service.dart';

/// The app's central state holder: owns the scan history and community feed,
/// and coordinates the AI, location, storage and sync services.
class ScanRepository extends ChangeNotifier {
  final AiService ai;
  final StorageService storage;
  final LocationService location;
  final SyncService sync;
  final AppSettings settings;

  ScanRepository({
    required this.ai,
    required this.storage,
    required this.location,
    required this.sync,
    required this.settings,
  }) {
    _scans = storage.allScans();
    _discoveries = storage.allDiscoveries();
  }

  List<ScanResult> _scans = [];
  List<Discovery> _discoveries = [];
  bool _analyzing = false;

  List<ScanResult> get scans => List.unmodifiable(_scans);
  List<Discovery> get discoveries => List.unmodifiable(_discoveries);
  bool get analyzing => _analyzing;
  int get pendingSync => storage.unsyncedScans().length;

  /// All scans that carry a GPS fix — used to plot the personal map layer.
  List<ScanResult> get locatedScans =>
      _scans.where((s) => s.hasLocation).toList();

  /// Runs the full capture → analyse → persist pipeline for a set of photos.
  Future<ScanResult> analyzePhotos(List<String> imagePaths) async {
    _analyzing = true;
    notifyListeners();
    try {
      final pos = await location.currentPosition();
      final result = await ai.analyze(
        imagePaths: imagePaths,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
      await storage.saveScan(result);
      _scans = storage.allScans();
      notifyListeners();
      return result;
    } finally {
      _analyzing = false;
      notifyListeners();
    }
  }

  Future<void> deleteScan(String id) async {
    await storage.deleteScan(id);
    _scans = storage.allScans();
    notifyListeners();
  }

  /// Publish one of the user's scans to the community discovery map.
  Future<void> shareScan(ScanResult scan) async {
    final top = scan.topPotential;
    if (!scan.hasLocation || top == null) return;
    final discovery = Discovery(
      author: settings.author,
      rockType: scan.rockType,
      topMineral: top.mineral,
      topProbability: top.probability,
      latitude: scan.latitude!,
      longitude: scan.longitude!,
    );
    await storage.saveDiscovery(discovery);
    _discoveries = storage.allDiscoveries();
    notifyListeners();
  }

  Future<void> rateDiscovery(Discovery d, double stars) async {
    final updated = d.withRating(stars);
    await storage.saveDiscovery(updated);
    _discoveries = storage.allDiscoveries();
    notifyListeners();
  }

  /// Attempts to sync unsynced scans; returns how many were pushed.
  Future<int> syncNow() async {
    final n = await sync.syncPending();
    _scans = storage.allScans();
    notifyListeners();
    return n;
  }
}
