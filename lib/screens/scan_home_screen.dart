import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/scan_repository.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'capture_screen.dart';
import 'results_screen.dart';

/// Landing screen: quick-scan call to action plus the user's scan history.
class ScanHomeScreen extends StatelessWidget {
  const ScanHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ScanRepository>();
    final scans = repo.scans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('NdauSight AI'),
        actions: [
          if (repo.pendingSync > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final n = await repo.syncNow();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(n > 0
                                ? 'Synced $n scan(s).'
                                : 'Nothing to sync — you may be offline.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync, color: Colors.white, size: 18),
                  label: Text('${repo.pendingSync}',
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _ScanCta(),
          Expanded(
            child: scans.isEmpty
                ? const EmptyState(
                    icon: Icons.travel_explore,
                    title: 'No scans yet',
                    message:
                        'Tap “Scan a Rock” to photograph a sample and get an AI mineral read-out.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: scans.length,
                    itemBuilder: (_, i) => _ScanTile(scan: scans[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ScanCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.slate, AppColors.slateLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Identify a rock in the field',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Photograph a sample from a few angles for the best read.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CaptureScreen()),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan a Rock'),
          ),
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  final ScanResult scan;
  const _ScanTile({required this.scan});

  @override
  Widget build(BuildContext context) {
    final top = scan.topPotential;
    final thumb = scan.imagePaths.isNotEmpty
        ? File(scan.imagePaths.first)
        : null;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: thumb != null && thumb.existsSync()
              ? Image.file(thumb,
                  width: 54, height: 54, fit: BoxFit.cover)
              : Container(
                  width: 54,
                  height: 54,
                  color: const Color(0xFFE4E1DA),
                  child: const Icon(Icons.landscape,
                      color: AppColors.textMuted),
                ),
        ),
        title: Text(scan.rockType,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              top != null
                  ? '${top.mineral} potential ${top.probability.round()}%'
                  : 'Analysed',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            Text(
              DateFormat('d MMM, HH:mm').format(scan.timestamp),
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        trailing: PriorityBadge(scan.priority),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ResultsScreen(scan: scan)),
          );
        },
      ),
    );
  }
}
