import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/scan_result.dart';
import '../services/scan_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/probability_bar.dart';

/// Detailed read-out for a single scan.
class ResultsScreen extends StatelessWidget {
  final ScanResult scan;
  const ResultsScreen({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ScanRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan result'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'delete') {
                await repo.deleteScan(scan.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Delete scan')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (scan.imagePaths.isNotEmpty) _Photos(paths: scan.imagePaths),
          const SizedBox(height: 12),
          _Header(scan: scan),
          if (scan.source == 'mock')
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: _MockNotice(),
            ),
          const SectionHeader('Detected minerals'),
          ...scan.detectedMinerals.map(
            (d) => ProbabilityBar(
                label: d.name, value: d.confidence, colorByScore: true),
          ),
          const SectionHeader('Estimated precious-mineral potential'),
          ...scan.potentials.map(
            (p) => ProbabilityBar(label: p.mineral, value: p.probability),
          ),
          const SectionHeader('AI recommendations'),
          ...scan.recommendations.map((r) => _RecTile(text: r)),
          const SizedBox(height: 8),
          if (scan.hasLocation) _LocationCard(scan: scan),
          const SizedBox(height: 18),
          _Actions(scan: scan),
        ],
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  final List<String> paths;
  const _Photos({required this.paths});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = File(paths[i]);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: f.existsSync()
                ? Image.file(f, width: 260, fit: BoxFit.cover)
                : Container(
                    width: 260,
                    color: const Color(0xFFE4E1DA),
                    child: const Icon(Icons.landscape,
                        size: 48, color: AppColors.textMuted),
                  ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ScanResult scan;
  const _Header({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scan.rockType,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  PriorityBadge(scan.priority),
                ],
              ),
            ),
            ConfidenceRing(
                value: scan.rockConfidence, caption: 'ID confidence'),
          ],
        ),
      ),
    );
  }
}

class _RecTile extends StatelessWidget {
  final String text;
  const _RecTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chevron_right, color: AppColors.gold),
          const SizedBox(width: 4),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final ScanResult scan;
  const _LocationCard({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.place, color: AppColors.danger),
        title: const Text('Recorded location'),
        subtitle: Text(
          '${scan.latitude!.toStringAsFixed(5)}, '
          '${scan.longitude!.toStringAsFixed(5)}',
        ),
      ),
    );
  }
}

class _MockNotice extends StatelessWidget {
  const _MockNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sample result (demo mode). Connect a real vision backend in '
              'Settings for live analysis.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final ScanResult scan;
  const _Actions({required this.scan});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ScanRepository>();
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: scan.hasLocation
                ? () async {
                    await repo.shareScan(scan);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Shared to community discoveries.')),
                      );
                    }
                  }
                : null,
            icon: const Icon(Icons.ios_share),
            label: const Text('Share'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final n = await repo.syncNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(n > 0
                          ? 'Synced $n scan(s) to the cloud.'
                          : 'Offline — will sync when connected.')),
                );
              }
            },
            icon: const Icon(Icons.cloud_upload_outlined),
            label: const Text('Sync'),
          ),
        ),
      ],
    );
  }
}
