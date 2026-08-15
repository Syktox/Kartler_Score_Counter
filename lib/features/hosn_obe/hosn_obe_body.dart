import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';
import '../../widgets/winner_banner.dart';

class HosnObeBody extends StatelessWidget {
  final bool isLoading;
  final Map<String, int> scores;
  final String currentPlayerId;
  final String Function(String playerId) nameOf;
  final String? winner;
  final ValueChanged<String> onPlayerSelected;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetPlayers;
  final bool hasAvailablePlayers;
  final VoidCallback onPickLineup;
  final VoidCallback onAddPlayer;

  const HosnObeBody({
    super.key,
    required this.isLoading,
    required this.scores,
    required this.currentPlayerId,
    required this.nameOf,
    required this.winner,
    required this.onPlayerSelected,
    required this.onScoreChanged,
    required this.onResetPlayers,
    required this.hasAvailablePlayers,
    required this.onPickLineup,
    required this.onAddPlayer,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_outlined, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Noch keine Spieler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Verwalte Spieler über die Startseite, um Leben zu zählen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (hasAvailablePlayers) ...[
                FilledButton.icon(
                  onPressed: onPickLineup,
                  icon: const Icon(Icons.groups_2_outlined),
                  label: const Text('Wer spielt mit?'),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                onPressed: onAddPlayer,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Spieler verwalten'),
              ),
            ],
          ),
        ),
      );
    }

    final isLandscape = ResponsiveUtils.isHandsetLandscape(
      MediaQuery.of(context).size,
    );
    final playerWrap = SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: scores.entries
            .map(
              (entry) => _PlayerCard(
                playerId: entry.key,
                name: nameOf(entry.key),
                score: entry.value,
                isSelected: entry.key == currentPlayerId,
                compact: isLandscape,
                onSelected: onPlayerSelected,
              ),
            )
            .toList(),
      ),
    );

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 18, 12),
        child: Row(
          children: [
            Expanded(child: playerWrap),
            const SizedBox(width: 12),
            SizedBox(
              width: 132,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (winner != null) ...[
                    WinnerBanner(winner: winner!, compact: true),
                    const SizedBox(height: 8),
                  ],
                  HosnObeControls(
                    compact: true,
                    onScoreChanged: onScoreChanged,
                    onResetPlayers: onResetPlayers,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        children: [
          if (winner != null) WinnerBanner(winner: winner!),
          Expanded(child: playerWrap),
          const SizedBox(height: 20),
          HosnObeControls(
            onScoreChanged: onScoreChanged,
            onResetPlayers: onResetPlayers,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class HosnObeControls extends StatelessWidget {
  final bool compact;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetPlayers;

  const HosnObeControls({
    super.key,
    this.compact = false,
    required this.onScoreChanged,
    required this.onResetPlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScoreButton(
            label: '-1',
            onPressed: () => onScoreChanged(-1),
            minimumSize: const Size(120, 56),
            fontSize: 22,
            width: 120,
          ),
          const SizedBox(height: 8),
          ScoreButton(
            label: 'Reset',
            onPressed: onResetPlayers,
            minimumSize: const Size(120, 56),
            fontSize: 18,
            width: 120,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreButton(label: '-1', onPressed: () => onScoreChanged(-1)),
        const SizedBox(width: 20),
        ScoreButton(
          label: 'Reset',
          onPressed: onResetPlayers,
          minimumSize: const Size(120, 80),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String playerId;
  final String name;
  final int score;
  final bool isSelected;
  final bool compact;
  final ValueChanged<String> onSelected;

  const _PlayerCard({
    required this.playerId,
    required this.name,
    required this.score,
    required this.isSelected,
    required this.onSelected,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScoreCard(
      title: name,
      score: score,
      isSelected: isSelected,
      compact: compact,
      width: compact ? 132 : 180,
      onTap: () => onSelected(playerId),
    );
  }
}
