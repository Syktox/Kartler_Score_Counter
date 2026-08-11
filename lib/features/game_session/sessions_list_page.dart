import 'package:flutter/material.dart';

import '../../models/game_session.dart';
import '../players/players_controller.dart';

/// Liste aller vergangenen Spielabende.
class SessionsListPage extends StatelessWidget {
  final List<GameSession> sessions;
  final PlayersController players;

  const SessionsListPage({
    super.key,
    required this.sessions,
    required this.players,
  });

  String _formatDate(DateTime time) {
    final local = time.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = sessions
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Spielabende')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: sorted.isEmpty
            ? const Center(
                child: Text('Noch keine abgeschlossenen Spielabende.'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sorted.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final session = sorted[index];
                  final matchCount = session.matchIds.length;
                  final participants = session.participantIds.isEmpty
                      ? 'Keine Teilnehmer'
                      : session.participantIds.map(players.displayName).join(', ');

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.nights_stay_outlined),
                      title: Text(_formatDate(session.startTime)),
                      subtitle: Text(
                        '$matchCount Partien · $participants',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _SessionDetail(
                              session: session,
                              players: players,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _SessionDetail extends StatelessWidget {
  final GameSession session;
  final PlayersController players;

  const _SessionDetail({required this.session, required this.players});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spielabend')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Teilnehmer: ${session.participantIds.isEmpty ? '—' : session.participantIds.map(players.displayName).join(', ')}',
            ),
            const SizedBox(height: 4),
            Text('Partien: ${session.matchIds.length}'),
            const SizedBox(height: 16),
            Text(
              'Aufgezeichnete Partie-IDs:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (session.matchIds.isEmpty)
              const Text('Keine Partien aufgezeichnet.')
            else
              for (final matchId in session.matchIds)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(matchId, style: const TextStyle(fontSize: 12)),
                ),
          ],
        ),
      ),
    );
  }
}
