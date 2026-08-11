import 'package:flutter/material.dart';

/// Schwebende Bestätigung (z. B. „Partie aufgezeichnet!“), die kurz nach der
/// AppBar erscheint und sich von selbst wieder ausblendet.
class RecordedBubble extends StatelessWidget {
  final String message;

  const RecordedBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: Material(
        color: colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(28),
        elevation: 6,
        shadowColor: Colors.black45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: colorScheme.inversePrimary),
              const SizedBox(width: 10),
              Text(
                message,
                style: TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
