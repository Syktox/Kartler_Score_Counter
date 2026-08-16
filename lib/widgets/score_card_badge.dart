import 'package:flutter/material.dart';

/// Status-Badge (z. B. „Gewinner", „X", „Gespannt"), das einheitlich auf den
/// Score-Cards aller Spielmodi oben rechts angezeigt wird.
class ScoreCardBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const ScoreCardBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}