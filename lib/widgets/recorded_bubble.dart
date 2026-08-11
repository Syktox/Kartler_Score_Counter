import 'dart:async';

import 'package:flutter/material.dart';

/// Verwaltet die schwebende Bestätigungs-Blase: ein Overlay-Eintrag, der kurz
/// nach der AppBar erscheint und sich nach [show] von selbst entfernt.
class RecordedBubbleHost {
  OverlayEntry? _entry;
  Timer? _timer;

  /// Zeigt [message] als kurze Bestätigung. Eine bereits sichtbare Blase wird
  /// dabei ersetzt.
  void show(BuildContext context, String message) {
    _timer?.cancel();
    _entry?.remove();

    final mediaQuery = MediaQuery.of(context);
    final top = mediaQuery.padding.top + kToolbarHeight + 14;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: top,
        left: 0,
        right: 0,
        child: Center(child: RecordedBubble(message: message)),
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (entry.mounted) {
        entry.remove();
      }
      if (_entry == entry) {
        _entry = null;
      }
    });
  }

  void dispose() {
    _timer?.cancel();
    _entry?.remove();
    _entry = null;
  }
}

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
