import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;

  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.width,
    this.margin,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(compact ? 16 : 20);
    final titleSize = compact ? 18.0 : 24.0;
    final scoreSize = compact ? 42.0 : 64.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        margin: margin,
        constraints: constraints,
        padding: compact
            ? const EdgeInsets.symmetric(vertical: 12, horizontal: 8)
            : const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.65)
              : Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: isSelected ? 2 : 1.25,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 10 : 18),
            Text(
              '$score',
              style: TextStyle(
                fontSize: scoreSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
