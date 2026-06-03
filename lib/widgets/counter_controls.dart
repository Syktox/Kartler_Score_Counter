import 'package:flutter/material.dart';

import 'score_button.dart';

class CounterControls extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;
  final bool compact;

  const CounterControls({
    super.key,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = compact ? const Size(64, 56) : const Size(80, 80);
    final resetSize = compact ? const Size(88, 56) : const Size(100, 80);
    final gap = compact ? 8.0 : 20.0;
    final symbolSize = compact ? 24.0 : 32.0;
    final resetFontSize = compact ? 18.0 : 24.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreButton(
          label: '-',
          onPressed: onDecrement,
          minimumSize: buttonSize,
          fontSize: symbolSize,
        ),
        SizedBox(width: gap),
        ScoreButton(
          label: 'Reset',
          onPressed: onReset,
          minimumSize: resetSize,
          fontSize: resetFontSize,
        ),
        SizedBox(width: gap),
        ScoreButton(
          label: '+',
          onPressed: onIncrement,
          minimumSize: buttonSize,
          fontSize: symbolSize,
        ),
      ],
    );
  }
}
