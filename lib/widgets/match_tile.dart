import 'package:flutter/material.dart';

import '../features/players/players_controller.dart';
import '../models/completed_match.dart';

/// Karte zur Anzeige einer aufgezeichneten Partie mit Endstand.
class MatchTile extends StatelessWidget {
  final CompletedMatch match;
  final PlayersController players;

  const MatchTile({super.key, required this.match, required this.players});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final standings = match.finalStandings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final winnerId = match.winnerId;
    final winnerLabel =
        winnerId != null && match.participantIds.contains(winnerId)
        ? players.displayName(winnerId)
        : match.winnerName;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.gameType.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  winnerLabel == '—' ? 'Unentschieden' : 'Sieger: $winnerLabel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            for (final entry in standings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        match.participantIds.contains(entry.key)
                            ? players.displayName(entry.key)
                            : entry.key,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
