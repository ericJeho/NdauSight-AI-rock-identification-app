import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A labelled horizontal bar showing a 0–100 value, coloured either by the
/// mineral it represents or by a traffic-light score.
class ProbabilityBar extends StatelessWidget {
  final String label;
  final double value; // 0–100
  final Color? color;
  final bool colorByScore;

  const ProbabilityBar({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.colorByScore = false,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = color ??
        (colorByScore
            ? AppColors.forScore(value)
            : AppColors.forMineral(label));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${value.round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: barColor)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFFE4E1DA),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
