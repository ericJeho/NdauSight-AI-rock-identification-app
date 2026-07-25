import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/discovery.dart';
import '../services/scan_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Feed of shared community discoveries, sortable and rateable.
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<ScanRepository>();
    final discoveries = repo.discoveries;

    return Scaffold(
      appBar: AppBar(title: const Text('Community discoveries')),
      body: discoveries.isEmpty
          ? const EmptyState(
              icon: Icons.groups,
              title: 'No discoveries yet',
              message:
                  'Share a scan with a location to put it on the community map.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: discoveries.length,
              itemBuilder: (_, i) =>
                  _DiscoveryCard(discovery: discoveries[i]),
            ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final Discovery discovery;
  const _DiscoveryCard({required this.discovery});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ScanRepository>();
    final color = AppColors.forMineral(discovery.topMineral);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Icon(Icons.diamond_outlined, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discovery.rockType,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('by ${discovery.author} · '
                          '${DateFormat('d MMM').format(discovery.timestamp)}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${discovery.topMineral} ${discovery.topProbability.round()}%',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (discovery.note != null) ...[
              const SizedBox(height: 10),
              Text(discovery.note!),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${discovery.latitude.toStringAsFixed(3)}, '
                    '${discovery.longitude.toStringAsFixed(3)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const Spacer(),
                _RatingRow(
                  rating: discovery.rating,
                  count: discovery.ratingCount,
                  onRate: (stars) => repo.rateDiscovery(discovery, stars),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final double rating;
  final int count;
  final void Function(double) onRate;
  const _RatingRow(
      {required this.rating, required this.count, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () => onRate(i.toDouble()),
            child: Icon(
              i <= rating.round() ? Icons.star : Icons.star_border,
              size: 20,
              color: AppColors.gold,
            ),
          ),
        const SizedBox(width: 4),
        Text('($count)',
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
