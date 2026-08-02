import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';
import '../../widgets/winner_banner.dart';

class HosnObeBody extends StatelessWidget {
  final bool isLoading;
  final Map<String, int> players;
  final String currentPlayer;
  final String? winner;
  final ValueChanged<String> onPlayerSelected;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetPlayers;

  const HosnObeBody({
    super.key,
    required this.isLoading,
    required this.players,
    required this.currentPlayer,
    required this.winner,
    required this.onPlayerSelected,
    required this.onScoreChanged,
    required this.onResetPlayers,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLandscape = ResponsiveUtils.isHandsetLandscape(
      MediaQuery.of(context).size,
    );
    final playerWrap = SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: players.entries
            .map(
              (entry) => _PlayerCard(
                name: entry.key,
                score: entry.value,
                isSelected: entry.key == currentPlayer,
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
  final String name;
  final int score;
  final bool isSelected;
  final bool compact;
  final ValueChanged<String> onSelected;

  const _PlayerCard({
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
      onTap: () => onSelected(name),
    );
  }
}
