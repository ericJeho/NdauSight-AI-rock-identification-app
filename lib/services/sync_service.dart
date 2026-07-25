import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/scan_result.dart';
import 'app_settings.dart';
import 'storage_service.dart';

/// Pushes locally-stored scans to the cloud when a connection is available.
///
/// In mock mode (no real backend) this simply marks scans as synced after a
/// short delay, so the offline → online flow can be demonstrated end-to-end.
class SyncService {
  final StorageService storage;
  final AppSettings settings;

  SyncService({required this.storage, required this.settings});

  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Attempts to sync every unsynced scan. Returns the number synced.
  Future<int> syncPending() async {
    if (!await isOnline()) return 0;

    final pending = storage.unsyncedScans();
    var count = 0;

    for (final scan in pending) {
      final ok = settings.useRealBackend
          ? await _pushToBackend(scan)
          : await _pushMock(scan);
      if (ok) {
        await storage.saveScan(scan.copyWith(synced: true));
        count++;
      }
    }
    return count;
  }

  Future<bool> _pushMock(ScanResult scan) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return true;
  }

  Future<bool> _pushToBackend(ScanResult scan) async {
    try {
      final uri = Uri.parse('${settings.backendUrl}/scans');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(scan.toJson()),
          )
          .timeout(const Duration(seconds: 20));
      return resp.statusCode >= 200 && resp.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
