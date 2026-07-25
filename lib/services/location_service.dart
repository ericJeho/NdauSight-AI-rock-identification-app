import 'package:geolocator/geolocator.dart';

/// Thin wrapper over Geolocator that handles permission flow gracefully.
class LocationService {
  /// Returns the current position, or `null` if location is unavailable or
  /// permission was denied. Never throws for the common denial cases so the
  /// scan flow can continue without a fix.
  Future<Position?> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      // Fall back to the last known position if a live fix times out.
      return Geolocator.getLastKnownPosition();
    }
  }
}
