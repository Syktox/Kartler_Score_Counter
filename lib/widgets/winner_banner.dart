import 'package:flutter/material.dart';

import '../utils/winner_text.dart';

class WinnerBanner extends StatelessWidget {
  final String winner;
  final bool compact;

  const WinnerBanner({super.key, required this.winner, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 0 : 20),
      padding: compact
          ? const EdgeInsets.symmetric(vertical: 10, horizontal: 8)
          : const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Text(
        WinnerText.sentence(winner),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 16 : 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
