import 'package:flutter/material.dart';

import 'score_button.dart';

class CounterControls extends StatelessWidget {
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  const CounterControls({
    super.key,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreButton(
          label: '-',
          onPressed: onDecrement,
          minimumSize: const Size(80, 80),
          fontSize: 32,
        ),
        const SizedBox(width: 20),
        ScoreButton(
          label: 'Reset',
          onPressed: onReset,
        ),
        const SizedBox(width: 20),
        ScoreButton(
          label: '+',
          onPressed: onIncrement,
          minimumSize: const Size(80, 80),
          fontSize: 32,
        ),
      ],
    );
  }
}
