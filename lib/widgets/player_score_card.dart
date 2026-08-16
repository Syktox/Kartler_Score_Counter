import 'package:flutter/material.dart';

import 'score_card.dart';

/// Einheitliche Karten-Optik für die Kärtchen aller Spielmodi
/// (Watten, Mulatschak, Hosn Obe).
class PlayerScoreCard extends StatelessWidget {
  static const double width = 176;
  static const double compactWidth = 148;
  static const double minHeight = 204;
  static const double compactMinHeight = 172;

  final String title;
  final int score;
  final bool isSelected;
  final bool compact;
  final bool stretch;
  final Widget? badge;
  final VoidCallback onTap;

  const PlayerScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.stretch = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: stretch ? StackFit.expand : StackFit.loose,
      children: [
        ScoreCard(
          title: title,
          score: score,
          isSelected: isSelected,
          compact: compact,
          stretch: stretch,
          width: compact ? compactWidth : width,
          constraints: BoxConstraints(
            minHeight: compact ? compactMinHeight : minHeight,
          ),
          padding: stretch
              ? const EdgeInsets.fromLTRB(16, 56, 16, 0)
              : (compact
                    ? const EdgeInsets.fromLTRB(8, 44, 8, 12)
                    : const EdgeInsets.fromLTRB(16, 56, 16, 14)),
          onTap: onTap,
        ),
        if (badge != null)
          Positioned(right: 12, top: 8, child: badge!),
      ],
    );
  }
}