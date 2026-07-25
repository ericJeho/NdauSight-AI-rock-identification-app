import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-configurable settings, persisted with SharedPreferences.
///
/// The most important toggle here is [useRealBackend]: off by default so the
/// app runs standalone with realistic mock scans, on when the user has a real
/// vision backend to point at via [backendUrl].
class AppSettings extends ChangeNotifier {
  static const _kUseBackend = 'use_real_backend';
  static const _kBackendUrl = 'backend_url';
  static const _kAuthor = 'author_name';
  static const _kAutoSync = 'auto_sync';

  late SharedPreferences _prefs;

  bool _useRealBackend = false;
  String _backendUrl = 'https://api.ndausight.example.com';
  String _author = 'Field Geologist';
  bool _autoSync = true;

  bool get useRealBackend => _useRealBackend;
  String get backendUrl => _backendUrl;
  String get author => _author;
  bool get autoSync => _autoSync;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _useRealBackend = _prefs.getBool(_kUseBackend) ?? false;
    _backendUrl = _prefs.getString(_kBackendUrl) ?? _backendUrl;
    _author = _prefs.getString(_kAuthor) ?? _author;
    _autoSync = _prefs.getBool(_kAutoSync) ?? true;
    notifyListeners();
  }

  Future<void> setUseRealBackend(bool value) async {
    _useRealBackend = value;
    await _prefs.setBool(_kUseBackend, value);
    notifyListeners();
  }

  Future<void> setBackendUrl(String value) async {
    _backendUrl = value.trim();
    await _prefs.setString(_kBackendUrl, _backendUrl);
    notifyListeners();
  }

  Future<void> setAuthor(String value) async {
    _author = value.trim().isEmpty ? 'Field Geologist' : value.trim();
    await _prefs.setString(_kAuthor, _author);
    notifyListeners();
  }

  Future<void> setAutoSync(bool value) async {
    _autoSync = value;
    await _prefs.setBool(_kAutoSync, value);
    notifyListeners();
  }
}
