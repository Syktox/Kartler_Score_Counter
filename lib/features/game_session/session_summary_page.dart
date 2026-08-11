import 'package:flutter/material.dart';

import '../../models/completed_match.dart';
import '../../models/game_session.dart';
import '../players/players_controller.dart';
import '../../widgets/match_tile.dart';

/// Zusammenfassung eines Spielabends nach dem Beenden.
class SessionSummaryPage extends StatelessWidget {
  final GameSession session;
  final List<CompletedMatch> matches;
  final PlayersController players;

  const SessionSummaryPage({
    super.key,
    required this.session,
    required this.matches,
    required this.players,
  });

  String _formatDuration() {
    final end = session.endTime ?? DateTime.now();
    final duration = end.difference(session.startTime);
    final minutes = duration.inMinutes;
    if (minutes < 1) {
      return 'unter einer Minute';
    }
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) {
      return '$minutes Min.';
    }
    return '$hours Std. $rest Min.';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Spielabend beendet')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.nights_stay),
                      const SizedBox(width: 8),
                      Text(
                        'Geschafft!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Dauer: ${_formatDuration()}',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  Text(
                    'Partien: ${matches.length}',
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                  if (session.participantIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Teilnehmer: ${session.participantIds.map(players.displayName).join(', ')}',
                      style: TextStyle(color: colorScheme.onPrimaryContainer),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Partien',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (matches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Keine Partien aufgezeichnet.')),
              )
            else
              for (final match in matches)
                MatchTile(match: match, players: players),
          ],
        ),
      ),
    );
  }
}
