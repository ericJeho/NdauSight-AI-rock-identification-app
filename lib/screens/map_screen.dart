import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/discovery.dart';
import '../models/scan_result.dart';
import '../services/scan_repository.dart';
import '../theme/app_theme.dart';

/// Map of the user's located scans and shared community discoveries, with a
/// simple geological-belt overlay. Uses OpenStreetMap tiles (no API key).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _controller = MapController();
  bool _showBelts = true;
  bool _showCommunity = true;

  /// Illustrative "known mineral belt" corridors (e.g. Great Dyke-style
  /// trends). In production these would come from a geological map service.
  static final List<List<LatLng>> _belts = [
    [
      const LatLng(-17.3, 30.2),
      const LatLng(-18.5, 30.0),
      const LatLng(-19.9, 29.8),
      const LatLng(-20.9, 29.6),
    ],
    [
      const LatLng(-18.8, 31.2),
      const LatLng(-19.6, 31.0),
      const LatLng(-20.4, 30.7),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ScanRepository>();
    final scans = repo.locatedScans;
    final discoveries = repo.discoveries;

    final center = scans.isNotEmpty
        ? LatLng(scans.first.latitude!, scans.first.longitude!)
        : (discoveries.isNotEmpty
            ? LatLng(discoveries.first.latitude, discoveries.first.longitude)
            : const LatLng(-19.0, 29.9));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geological map'),
        actions: [
          IconButton(
            tooltip: 'Toggle mineral belts',
            icon: Icon(_showBelts ? Icons.layers : Icons.layers_outlined),
            onPressed: () => setState(() => _showBelts = !_showBelts),
          ),
          IconButton(
            tooltip: 'Toggle community pins',
            icon: Icon(_showCommunity ? Icons.groups : Icons.groups_outlined),
            onPressed: () =>
                setState(() => _showCommunity = !_showCommunity),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 7,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ndausight.app',
          ),
          if (_showBelts)
            PolylineLayer(
              polylines: _belts
                  .map((pts) => Polyline(
                        points: pts,
                        strokeWidth: 14,
                        color: AppColors.gold.withValues(alpha: 0.35),
                      ))
                  .toList(),
            ),
          MarkerLayer(
            markers: [
              ...scans.map(_scanMarker),
              if (_showCommunity) ...discoveries.map(_discoveryMarker),
            ],
          ),
        ],
      ),
    );
  }

  Marker _scanMarker(ScanResult s) {
    return Marker(
      point: LatLng(s.latitude!, s.longitude!),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _showScanSheet(s),
        child: const Icon(Icons.location_on,
            color: AppColors.slate, size: 40),
      ),
    );
  }

  Marker _discoveryMarker(Discovery d) {
    return Marker(
      point: LatLng(d.latitude, d.longitude),
      width: 44,
      height: 44,
      child: GestureDetector(
        onTap: () => _showDiscoverySheet(d),
        child: Icon(Icons.place,
            color: AppColors.forMineral(d.topMineral), size: 40),
      ),
    );
  }

  void _showScanSheet(ScanResult s) {
    final top = s.topPotential;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your scan · ${s.rockType}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (top != null)
              Text('${top.mineral} potential ${top.probability.round()}%'),
            Text('${s.latitude!.toStringAsFixed(4)}, '
                '${s.longitude!.toStringAsFixed(4)}',
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  void _showDiscoverySheet(Discovery d) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${d.rockType} · by ${d.author}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('${d.topMineral} potential ${d.topProbability.round()}%'),
            if (d.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(d.note!,
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.star, color: AppColors.gold, size: 18),
              const SizedBox(width: 4),
              Text('${d.rating.toStringAsFixed(1)} (${d.ratingCount})'),
            ]),
          ],
        ),
      ),
    );
  }
}
