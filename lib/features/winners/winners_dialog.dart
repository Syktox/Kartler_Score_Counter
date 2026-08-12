import 'package:flutter/material.dart';

import '../../models/app_mode.dart';
import '../../models/completed_match.dart';

enum _WinnersScope { overall, today }

/// Schwebendes Fenster mit den Gewinnern der aufgezeichneten Partien.
///
/// Zwei Ansichten – „Gesamt“ und „Heute“ (der laufende Spielabend) – zeigen
/// pro Spielmodus die Spieler mit ihren gewonnenen Spielen als Balken.
class WinnersDialog extends StatefulWidget {
  final List<CompletedMatch> matches;
  final String Function(String? playerId) displayName;

  const WinnersDialog({
    super.key,
    required this.matches,
    required this.displayName,
  });

  @override
  State<WinnersDialog> createState() => _WinnersDialogState();
}

class _WinnersDialogState extends State<WinnersDialog> {
  _WinnersScope _scope = _WinnersScope.overall;

  bool _isToday(CompletedMatch match) {
    final now = DateTime.now();
    return match.endedAt.year == now.year &&
        match.endedAt.month == now.month &&
        match.endedAt.day == now.day;
  }

  List<CompletedMatch> get _filtered {
    return widget.matches
        .where((match) => match.gameType != AppMode.counter)
        .where((match) => _scope == _WinnersScope.overall || _isToday(match))
        .toList(growable: false);
  }

  /// Anzahl gewonnener Spiele je Sieger, aufgeschlüsselt nach Spielmodus.
  Map<AppMode, Map<String, int>> _winsByMode() {
    final result = <AppMode, Map<String, int>>{};
    for (final match in _filtered) {
      final winnerKey = match.winnerId ?? match.winnerLabel;
      if (winnerKey == null || winnerKey.isEmpty) {
        continue;
      }
      final name = match.winnerId != null
          ? widget.displayName(match.winnerId)
          : winnerKey;
      final counts = result.putIfAbsent(match.gameType, () => {});
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final winsByMode = _winsByMode();
    final hasMatches = winsByMode.values.any((counts) => counts.isNotEmpty);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Gewinner bisher',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<_WinnersScope>(
                segments: const [
                  ButtonSegment(
                    value: _WinnersScope.overall,
                    label: Text('Gesamt'),
                  ),
                  ButtonSegment(
                    value: _WinnersScope.today,
                    label: Text('Heute'),
                  ),
                ],
                selected: {_scope},
                onSelectionChanged: (selection) {
                  setState(() {
                    _scope = selection.single;
                  });
                },
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: hasMatches
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final entry in winsByMode.entries) ...[
                              _ModeWinnersCard(
                                mode: entry.key,
                                counts: entry.value,
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Noch keine Partien aufgezeichnet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Schließen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeWinnersCard extends StatelessWidget {
  final AppMode mode;
  final Map<String, int> counts;

  const _ModeWinnersCard({required this.mode, required this.counts});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxWins = ranked.first.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mode.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          for (final (index, entry) in ranked.indexed) ...[
            _WinnerRow(
              name: entry.key,
              wins: entry.value,
              maxWins: maxWins,
              isWinner: entry.value == maxWins,
            ),
            if (index < ranked.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _WinnerRow extends StatelessWidget {
  final String name;
  final int wins;
  final int maxWins;
  final bool isWinner;

  const _WinnerRow({
    required this.name,
    required this.wins,
    required this.maxWins,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fraction = maxWins <= 0 ? 0.0 : wins / maxWins;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w500,
              color: isWinner ? colorScheme.primary : null,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(height: 16, color: colorScheme.surface),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    height: 16,
                    color: isWinner
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            '$wins',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (isWinner) ...[
          const SizedBox(width: 4),
          const Icon(Icons.emoji_events, size: 18, color: Colors.amber),
        ],
      ],
    );
  }
}
