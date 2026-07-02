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
    final buttonSize = compact ? const Size(112, 58) : const Size(160, 76);
    final resetSize = compact ? const Size(112, 58) : const Size(160, 76);
    final buttonWidth = compact ? 112.0 : 160.0;
    final gap = compact ? 8.0 : 14.0;
    final symbolSize = compact ? 28.0 : 36.0;
    final resetFontSize = compact ? 18.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreButton(
          label: '+',
          onPressed: onIncrement,
          minimumSize: buttonSize,
          fontSize: symbolSize,
          width: buttonWidth,
        ),
        SizedBox(height: gap),
        ScoreButton(
          label: 'Reset',
          onPressed: onReset,
          minimumSize: resetSize,
          fontSize: resetFontSize,
          width: buttonWidth,
        ),
        SizedBox(height: gap),
        ScoreButton(
          label: '-',
          onPressed: onDecrement,
          minimumSize: buttonSize,
          fontSize: symbolSize,
          width: buttonWidth,
        ),
      ],
    );
  }
}
