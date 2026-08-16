import 'package:flutter/material.dart';

class ScoreButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Size minimumSize;
  final double fontSize;
  final double? width;

  const ScoreButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.minimumSize = const Size(100, 80),
    this.fontSize = 24,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: minimumSize,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          disabledBackgroundColor: colorScheme.surface.withValues(
            alpha: 0.4,
          ),
          disabledForegroundColor: colorScheme.onSurface.withValues(
            alpha: 0.5,
          ),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.45),
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
}
