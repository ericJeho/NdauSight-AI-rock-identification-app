import 'package:flutter_test/flutter_test.dart';
import 'package:ndausight/models/scan_result.dart';

void main() {
  group('ScanResult', () {
    ScanResult sample({double topProb = 71}) => ScanResult(
          imagePaths: const ['/tmp/a.jpg'],
          rockType: 'Quartz Vein',
          rockConfidence: 96,
          detectedMinerals: const [
            Detection(name: 'Quartz', confidence: 98),
          ],
          potentials: [
            MineralPotential(mineral: 'Gold', probability: topProb),
            const MineralPotential(mineral: 'Copper', probability: 24),
          ],
          recommendations: const ['Collect a fresh sample.'],
          latitude: -19.0,
          longitude: 29.9,
        );

    test('topPotential returns the highest probability mineral', () {
      expect(sample().topPotential?.mineral, 'Gold');
    });

    test('priority reflects the top potential', () {
      expect(sample(topProb: 71).priority, 'High');
      expect(sample(topProb: 40).priority, 'Medium');
      expect(sample(topProb: 10).priority, 'Low');
    });

    test('round-trips through JSON', () {
      final original = sample();
      final restored = ScanResult.fromJson(original.toJson());
      expect(restored.rockType, original.rockType);
      expect(restored.potentials.length, original.potentials.length);
      expect(restored.topPotential?.mineral, 'Gold');
      expect(restored.latitude, -19.0);
    });

    test('hasLocation is false without coordinates', () {
      final noLoc = ScanResult(
        imagePaths: const [],
        rockType: 'Granite',
        rockConfidence: 80,
        detectedMinerals: const [],
        potentials: const [],
        recommendations: const [],
      );
      expect(noLoc.hasLocation, false);
      expect(noLoc.priority, 'Low');
    });
  });
}
