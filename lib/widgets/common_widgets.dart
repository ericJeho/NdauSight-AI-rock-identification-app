import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A pill showing a scan's priority (High / Medium / Low).
class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge(this.priority, {super.key});

  Color get _color {
    switch (priority) {
      case 'High':
        return AppColors.success;
      case 'Medium':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$priority priority',
        style: TextStyle(
            color: _color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// A small circular confidence indicator (used on the results header).
class ConfidenceRing extends StatelessWidget {
  final double value; // 0–100
  final String caption;
  const ConfidenceRing({super.key, required this.value, this.caption = ''});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forScore(value);
    return Column(
      children: [
        SizedBox(
          height: 64,
          width: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 64,
                width: 64,
                child: CircularProgressIndicator(
                  value: (value / 100).clamp(0.0, 1.0),
                  strokeWidth: 6,
                  backgroundColor: const Color(0xFFE4E1DA),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text('${value.round()}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(caption,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ),
      ],
    );
  }
}

/// Section title with an optional trailing widget.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Friendly empty-state placeholder.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
