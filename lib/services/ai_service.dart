import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/scan_result.dart';
import 'app_settings.dart';

/// Thrown when a real backend is configured but the request fails.
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);
  @override
  String toString() => 'AiServiceException: $message';
}

/// Analyses rock photos and returns a [ScanResult].
///
/// Two modes, chosen by [AppSettings.useRealBackend]:
///  * **Mock** (default) — generates a plausible, deterministic-ish result so
///    the whole app works with no server. Great for demos and offline dev.
///  * **Backend** — POSTs the images to `{backendUrl}/analyze` and expects a
///    JSON body matching [ScanResult.fromJson]. Swap in your FastAPI + YOLO /
///    ViT service here without touching any UI code.
class AiService {
  final AppSettings settings;
  final _rng = Random();

  AiService(this.settings);

  Future<ScanResult> analyze({
    required List<String> imagePaths,
    double? latitude,
    double? longitude,
  }) async {
    if (settings.useRealBackend) {
      return _analyzeWithBackend(
        imagePaths: imagePaths,
        latitude: latitude,
        longitude: longitude,
      );
    }
    return _analyzeMock(
      imagePaths: imagePaths,
      latitude: latitude,
      longitude: longitude,
    );
  }

  // ---------------------------------------------------------------------------
  // Real backend
  // ---------------------------------------------------------------------------

  Future<ScanResult> _analyzeWithBackend({
    required List<String> imagePaths,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse('${settings.backendUrl}/analyze');
    try {
      final request = http.MultipartRequest('POST', uri);
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }
      for (final path in imagePaths) {
        final file = File(path);
        if (await file.exists()) {
          request.files
              .add(await http.MultipartFile.fromPath('images', path));
        }
      }

      final streamed = await request.send().timeout(
            const Duration(seconds: 30),
          );
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        throw AiServiceException(
          'Backend returned ${response.statusCode}: ${response.body}',
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      // Preserve local image paths + location; trust the model for the science.
      final parsed = ScanResult.fromJson(json);
      return ScanResult(
        imagePaths: imagePaths,
        rockType: parsed.rockType,
        rockConfidence: parsed.rockConfidence,
        detectedMinerals: parsed.detectedMinerals,
        potentials: parsed.potentials,
        recommendations: parsed.recommendations,
        latitude: latitude ?? parsed.latitude,
        longitude: longitude ?? parsed.longitude,
        source: 'backend',
      );
    } on SocketException {
      throw AiServiceException(
        'Could not reach the backend. Check the URL or your connection.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Mock analysis
  // ---------------------------------------------------------------------------

  static const _rockProfiles = <_RockProfile>[
    _RockProfile(
      'Quartz Vein',
      minerals: {'Quartz': 98, 'Iron Oxides': 87, 'Pyrite': 43},
      potentials: {
        'Gold': 71,
        'Copper': 24,
        'Silver': 16,
        'Lithium': 8,
        'Rare Earth Elements': 6,
        'Gemstones': 12,
      },
      recommendations: [
        'High-priority sample — collect fresh rock chips.',
        'Confirm with XRF or a laboratory assay before excavation.',
        'Pan stream sediments nearby to trace the source.',
      ],
    ),
    _RockProfile(
      'Pegmatite',
      minerals: {'Feldspar': 92, 'Quartz': 80, 'Mica': 64, 'Tourmaline': 38},
      potentials: {
        'Lithium': 74,
        'Rare Earth Elements': 52,
        'Gemstones': 46,
        'Gold': 9,
        'Copper': 12,
        'Silver': 7,
      },
      recommendations: [
        'Pegmatites are prime lithium / REE targets — sample the coarse zones.',
        'Look for spodumene and lepidolite; test with a handheld XRF.',
        'Photograph any gem-quality tourmaline separately.',
      ],
    ),
    _RockProfile(
      'Malachite-stained Basalt',
      minerals: {'Basalt matrix': 90, 'Malachite': 71, 'Chalcopyrite': 33},
      potentials: {
        'Copper': 78,
        'Silver': 21,
        'Gold': 14,
        'Lithium': 4,
        'Rare Earth Elements': 5,
        'Gemstones': 3,
      },
      recommendations: [
        'Green copper staining suggests a copper-bearing system nearby.',
        'Collect a fresh, unweathered break for assay.',
        'Map the extent of the staining along strike.',
      ],
    ),
    _RockProfile(
      'Granite',
      minerals: {'Quartz': 76, 'Feldspar': 88, 'Biotite Mica': 52},
      potentials: {
        'Rare Earth Elements': 28,
        'Lithium': 18,
        'Gold': 8,
        'Copper': 10,
        'Silver': 6,
        'Gemstones': 9,
      },
      recommendations: [
        'Fresh granite is generally low priority on its own.',
        'Check contacts and any quartz veins cutting the granite.',
        'Note the location and move to more promising outcrops.',
      ],
    ),
    _RockProfile(
      'Garnet Schist',
      minerals: {'Mica': 84, 'Quartz': 70, 'Garnet': 61},
      potentials: {
        'Gemstones': 58,
        'Rare Earth Elements': 22,
        'Gold': 12,
        'Copper': 9,
        'Lithium': 11,
        'Silver': 7,
      },
      recommendations: [
        'Garnet porphyroblasts may include gem-grade crystals.',
        'Screen soil downslope for loose garnets.',
        'Record foliation direction for structural context.',
      ],
    ),
  ];

  Future<ScanResult> _analyzeMock({
    required List<String> imagePaths,
    double? latitude,
    double? longitude,
  }) async {
    // Simulate model latency so the loading UI is exercised.
    await Future.delayed(Duration(milliseconds: 900 + _rng.nextInt(900)));

    final profile = _rockProfiles[_rng.nextInt(_rockProfiles.length)];

    double jitter(num base) {
      final v = base + _rng.nextInt(9) - 4; // ±4
      return v.clamp(0, 100).toDouble();
    }

    final detections = profile.minerals.entries
        .map((e) => Detection(name: e.key, confidence: jitter(e.value)))
        .toList()
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final potentials = profile.potentials.entries
        .map((e) =>
            MineralPotential(mineral: e.key, probability: jitter(e.value)))
        .toList()
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return ScanResult(
      imagePaths: imagePaths,
      rockType: profile.name,
      rockConfidence: jitter(94),
      detectedMinerals: detections,
      potentials: potentials,
      recommendations: profile.recommendations,
      latitude: latitude,
      longitude: longitude,
      source: 'mock',
    );
  }
}

class _RockProfile {
  final String name;
  final Map<String, int> minerals;
  final Map<String, int> potentials;
  final List<String> recommendations;

  const _RockProfile(
    this.name, {
    required this.minerals,
    required this.potentials,
    required this.recommendations,
  });
}
