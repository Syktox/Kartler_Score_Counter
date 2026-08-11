import 'package:flutter/material.dart';

import '../../models/app_mode.dart';
import '../../models/completed_match.dart';
import '../../models/game_session.dart';
import '../players/players_controller.dart';
import 'statistics_calculator.dart';

/// Statistik-Seite: aggregiert ausschließlich aus der Match-History
/// und den Spielabenden.
class StatisticsPage extends StatelessWidget {
  final StatisticsResult result;
  final PlayersController players;
  final List<GameSession> sessions;

  const StatisticsPage({
    super.key,
    required this.result,
    required this.players,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiken')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (result.totalMatches == 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Noch keine Statistiken.\nSchließe Partien ab, um deine Auswertung zu sehen.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              _SummaryCard(result: result),
              const SizedBox(height: 20),
              _SectionTitle(title: 'Bestenliste'),
              const SizedBox(height: 8),
              for (var i = 0; i < result.leaderboard.length; i++)
                _LeaderboardTile(
                  rank: i + 1,
                  entry: result.leaderboard[i],
                  players: players,
                ),
              const SizedBox(height: 20),
              _SectionTitle(title: 'Beliebteste Modi'),
              const SizedBox(height: 8),
              _ModeBreakdown(result: result),
              if (result.recentMatches.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionTitle(title: 'Letzte Partien'),
                const SizedBox(height: 8),
                for (final match in result.recentMatches)
                  _RecentMatchTile(match: match, players: players),
              ],
            ],
            const SizedBox(height: 20),
            _SectionTitle(title: 'Spielabende'),
            const SizedBox(height: 8),
            _SessionsSummary(result: result),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final StatisticsResult result;

  const _SummaryCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mostPlayed = result.mostPlayedMode;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatPill(label: 'Partien', value: '${result.totalMatches}'),
              _StatPill(label: 'Spielabende', value: '${result.totalSessions}'),
              _StatPill(
                label: 'Größter Sieg',
                value: '${result.biggestWinMargin}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (mostPlayed != null)
            Text(
              'Lieblingsmodus: ${mostPlayed.label}',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final PlayerStatEntry entry;
  final PlayersController players;

  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final player = players.playerById(entry.playerId);
    final name = player?.displayName ?? entry.playerId;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: rank == 1 ? colorScheme.primaryContainer : null,
          child: Text(
            '$rank',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${entry.matches} Partien · ${entry.wins} Siege · ${entry.losses} Niederlagen',
        ),
        trailing: Text(
          '${(entry.winRate * 100).round()} %',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ModeBreakdown extends StatelessWidget {
  final StatisticsResult result;

  const _ModeBreakdown({required this.result});

  @override
  Widget build(BuildContext context) {
    final total = result.totalMatches == 0 ? 1 : result.totalMatches;

    return Column(
      children: [
        for (final mode in AppMode.values)
          if (result.matchesPerMode[mode] != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      mode.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: result.matchesPerMode[mode]! / total,
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${result.matchesPerMode[mode]}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _RecentMatchTile extends StatelessWidget {
  final CompletedMatch match;
  final PlayersController players;

  const _RecentMatchTile({required this.match, required this.players});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final local = match.endedAt.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';

    final standings = match.finalStandings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(
            _modeIcon(match.gameType),
            color: colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          '${match.gameType.label} · ${match.winnerName} gewinnt',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          standings.map((entry) => '${entry.key}: ${entry.value}').join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(date, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }

  static IconData _modeIcon(AppMode mode) {
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

class _SessionsSummary extends StatelessWidget {
  final StatisticsResult result;

  const _SessionsSummary({required this.result});

  @override
  Widget build(BuildContext context) {
    final lastSession = result.lastSession;

    if (lastSession == null) {
      return const Text('Noch keine abgeschlossenen Spielabende.');
    }
    final local = lastSession.startTime.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.${local.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Letzter Spielabend: $date'),
        const SizedBox(height: 4),
        Text(
          '${lastSession.matchIds.length} Partien aufgezeichnet',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
