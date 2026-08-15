import 'dart:math' as math;

import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;
  final bool stretch;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final double? titleScoreGap;

  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.stretch = false,
    this.width,
    this.margin,
    this.constraints,
    this.padding,
    this.titleScoreGap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(compact ? 16 : 20);
    final titleSize = compact ? 18.0 : 22.0;
    final scoreSize = compact ? 32.0 : 28.0;
    final gapSize = titleScoreGap ?? (compact ? 10 : 18);

    final nameStyle = TextStyle(
      fontSize: titleSize,
      fontWeight: FontWeight.w900,
    );
    final scoreStyle = TextStyle(
      fontSize: scoreSize,
      height: 1,
      fontWeight: FontWeight.w900,
    );

    final name = Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: nameStyle,
    );
    final scoreBox = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text('$score', style: scoreStyle),
    );

    Widget content() {
      if (!stretch) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [name, SizedBox(height: gapSize), scoreBox],
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = constraints.maxWidth;
          final innerHeight = constraints.maxHeight;

          final namePainter = TextPainter(
            text: TextSpan(text: title, style: nameStyle),
            maxLines: 2,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: innerWidth);

          final scorePainter = TextPainter(
            text: TextSpan(text: '$score', style: scoreStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          final scoreScale = scorePainter.width <= 0
              ? 1.0
              : math.min(1.0, innerWidth / scorePainter.width);
          final scoreHeight = scorePainter.height * scoreScale;

          final targetScoreCenter = innerHeight * 0.55;
          final gap = math.max(
            gapSize,
            targetScoreCenter - namePainter.height - scoreHeight / 2,
          );

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [name, SizedBox(height: gap), scoreBox],
          );
        },
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        margin: margin,
        constraints: constraints,
        padding:
            padding ??
            (compact
                ? const EdgeInsets.symmetric(vertical: 12, horizontal: 8)
                : const EdgeInsets.symmetric(vertical: 20, horizontal: 16)),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.65)
              : Colors.transparent,
          borderRadius: borderRadius,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
            width: 2,
          ),
        ),
        child: content(),
      ),
    );
  }
}