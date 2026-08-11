import 'package:flutter/material.dart';

import '../../models/app_mode.dart';

class MatchPreview {
  final String? winnerId;
  final String? winnerLabel;
  final List<({String name, int score})> standings;

  const MatchPreview({
    this.winnerId,
    this.winnerLabel,
    required this.standings,
  });

  String get winnerName => winnerId ?? winnerLabel ?? 'Unentschieden';
}

/// Bottom Sheet zum Abschließen einer Partie.
///
/// Zeigt den aktuellen Spielstand des gewählten Modus und erlaubt,
/// die Partie (optional mit Board-Reset) aufzuzeichnen.
class FinishMatchSheet extends StatefulWidget {
  final AppMode initialMode;
  final MatchPreview Function(AppMode mode) previewFor;
  final void Function(AppMode mode, {required bool resetBoard}) onRecord;

  const FinishMatchSheet({
    super.key,
    required this.initialMode,
    required this.previewFor,
    required this.onRecord,
  });

  @override
  State<FinishMatchSheet> createState() => _FinishMatchSheetState();
}

class _FinishMatchSheetState extends State<FinishMatchSheet> {
  late AppMode _selectedMode;
  bool _resetBoard = true;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final preview = widget.previewFor(_selectedMode);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined),
                const SizedBox(width: 8),
                Text(
                  'Partie abschließen',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<AppMode>(
              segments: [
                for (final mode in AppMode.values)
                  ButtonSegment(
                    value: mode,
                    label: Text(mode.label),
                    icon: Icon(_iconFor(mode)),
                  ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedMode = selection.first;
                });
              },
              showSelectedIcon: false,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Gewinner: ${preview.winnerName}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in preview.standings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(entry.name)),
                          Text(
                            '${entry.score}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Board für die nächste Partie zurücksetzen'),
              value: _resetBoard,
              onChanged: (value) {
                setState(() {
                  _resetBoard = value ?? true;
                });
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                widget.onRecord(_selectedMode, resetBoard: _resetBoard);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Partie aufzeichnen'),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(AppMode mode) {
    switch (mode) {
      case AppMode.watten:
        return Icons.style_outlined;
      case AppMode.mulatschak:
        return Icons.casino_outlined;
      case AppMode.hosnObe:
        return Icons.emoji_events_outlined;
      case AppMode.counter:
        return Icons.numbers;
    }
  }
}
