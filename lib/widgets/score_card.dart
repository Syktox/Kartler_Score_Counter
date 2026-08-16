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
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(compact ? 16 : 20);
    final titleSize = compact ? 18.0 : 22.0;
    final scoreSize = compact ? 32.0 : 28.0;

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
    Widget content() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final innerWidth = constraints.maxWidth;
          final isTight =
              constraints.hasBoundedHeight &&
              constraints.minHeight == constraints.maxHeight;

          final effectiveNameStyle =
              DefaultTextStyle.of(context).style.merge(nameStyle);

          final namePainter = TextPainter(
            text: TextSpan(text: title, style: effectiveNameStyle),
            maxLines: 2,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: innerWidth);
          final nameHeight = namePainter.height;

          final oneLinePainter = TextPainter(
            text: TextSpan(text: 'Ag', style: effectiveNameStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          final lineHeight = oneLinePainter.height;

          final scorePainter = TextPainter(
            text: TextSpan(text: '$score', style: scoreStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          final scoreHeight = scorePainter.height;
          final scoreBox = SizedBox(
            height: scoreHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('$score', style: scoreStyle),
            ),
          );

          // Es wird immer Platz für einen zweizeiligen Namen reserviert,
          // damit die Score-Position nie von der Zeilenanzahl abhängt.
          const minNameScoreGap = 12.0;
          final reservedContent = lineHeight * 2 + minNameScoreGap + scoreHeight;
          final availableHeight = isTight
              ? constraints.maxHeight
              : (constraints.minHeight.isFinite &&
                      constraints.minHeight > 0)
                  ? math.max(
                      constraints.minHeight - (padding?.vertical ?? 0),
                      reservedContent,
                    )
                  : reservedContent;

          // Fester Anker: Der Score sitzt immer an derselben Stelle und wird
          // nur nach unten ausweichen, wenn der Name den Abstand einnimmt.
          final anchorScoreTop = availableHeight * 0.70 - scoreHeight / 2;
          final scoreTop = math.min(
            math.max(anchorScoreTop, nameHeight + minNameScoreGap),
            math.max(nameHeight + minNameScoreGap, availableHeight - scoreHeight),
          );
          final gap = scoreTop - nameHeight;

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