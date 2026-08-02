import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import '../../widgets/counter_controls.dart';

class CounterBody extends StatelessWidget {
  final bool isLoading;
  final String counterName;
  final int score;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  const CounterBody({
    super.key,
    required this.isLoading,
    required this.counterName,
    required this.score,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLandscape = ResponsiveUtils.isHandsetLandscape(
      MediaQuery.of(context).size,
    );
    final title = Text(
      counterName,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isLandscape ? 40 : 56,
        fontWeight: FontWeight.bold,
      ),
    );
    final scoreText = Text(
      '$score',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: isLandscape ? 104 : 136,
        fontWeight: FontWeight.w900,
      ),
    );

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [title, const SizedBox(height: 8), scoreText],
              ),
            ),
            const SizedBox(width: 16),
            CounterControls(
              compact: true,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
              onReset: onReset,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          title,
          Expanded(child: Center(child: scoreText)),
          CounterControls(
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onReset: onReset,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
