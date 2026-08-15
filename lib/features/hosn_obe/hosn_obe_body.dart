import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';

class HosnObeBody extends StatelessWidget {
  final bool isLoading;
  final Map<String, int> scores;
  final String currentPlayerId;
  final String Function(String playerId) nameOf;
  final String? winnerPlayerId;
  final ValueChanged<String> onPlayerSelected;
  final ValueChanged<int> onScoreChanged;
  final bool hasAvailablePlayers;
  final VoidCallback onPickLineup;
  final VoidCallback onAddPlayer;

  const HosnObeBody({
    super.key,
    required this.isLoading,
    required this.scores,
    required this.currentPlayerId,
    required this.nameOf,
    required this.winnerPlayerId,
    required this.onPlayerSelected,
    required this.onScoreChanged,
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
    final hasWinner = winnerPlayerId != null;
    final entries = scores.entries.toList();
    final playerWrap = SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: entries
            .map(
              (entry) => _PlayerCard(
                playerId: entry.key,
                name: nameOf(entry.key),
                score: entry.value,
                isSelected: entry.key == currentPlayerId,
                isWinner: entry.key == winnerPlayerId,
                isLoser: hasWinner && entry.key != winnerPlayerId,
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
                  HosnObeControls(
                    compact: true,
                    onScoreChanged: onScoreChanged,
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (ResponsiveUtils.isHandsetWidth(constraints.maxWidth) &&
                    entries.length >= 2) {
                  return _buildPlayersGrid(entries);
                }

                return playerWrap;
              },
            ),
          ),
          const SizedBox(height: 20),
          HosnObeControls(
            onScoreChanged: onScoreChanged,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlayersGrid(List<MapEntry<String, int>> entries) {
    final columnCount = entries.length >= 3 ? 3 : entries.length;

return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.68,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];

        return _PlayerCard(
          playerId: entry.key,
          name: nameOf(entry.key),
          score: entry.value,
          isSelected: entry.key == currentPlayerId,
          isWinner: entry.key == winnerPlayerId,
          isLoser: entry.key != winnerPlayerId && winnerPlayerId != null,
          onSelected: onPlayerSelected,
        );
      }),
    );
  }
}

class HosnObeControls extends StatelessWidget {
  final bool compact;
  final ValueChanged<int> onScoreChanged;

  const HosnObeControls({
    super.key,
    this.compact = false,
    required this.onScoreChanged,
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
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScoreButton(label: '-1', onPressed: () => onScoreChanged(-1)),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final String playerId;
  final String name;
  final int score;
  final bool isSelected;
  final bool isWinner;
  final bool isLoser;
  final bool compact;
  final ValueChanged<String> onSelected;

  const _PlayerCard({
    required this.playerId,
    required this.name,
    required this.score,
    required this.isSelected,
    required this.isWinner,
    required this.isLoser,
    required this.onSelected,
    this.compact = false,
  });

@override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stretch = constraints.hasBoundedHeight;
        return Stack(
          fit: stretch ? StackFit.expand : StackFit.loose,
          children: [
            ScoreCard(
              title: name,
              score: score,
              isSelected: isSelected,
              compact: compact,
              stretch: stretch,
              width: compact ? 148 : 204,
              constraints: BoxConstraints(minHeight: compact ? 156 : 204),
              padding: stretch
                  ? const EdgeInsets.fromLTRB(16, 48, 16, 0)
                  : (compact
                        ? const EdgeInsets.fromLTRB(8, 36, 8, 12)
                        : const EdgeInsets.fromLTRB(16, 48, 16, 14)),
              titleScoreGap: stretch ? 14 : (compact ? 12 : 14),
              onTap: () => onSelected(playerId),
            ),
            if (isWinner)
              const Positioned(
                right: 12,
                top: 8,
                child: _HosnObeStatusBadge(
                  label: 'Gewinner',
                  color: Colors.green,
                ),
              )
            else if (isLoser || score <= 0)
              const Positioned(
                right: 12,
                top: 8,
                child: _HosnObeStatusBadge(
                  label: 'X',
                  color: Colors.red,
                  fontSize: 16,
                ),
              )
            else if (score == 1)
              const Positioned(
                right: 12,
                top: 8,
                child: _HosnObeStatusBadge(
                  label: 'Schwimmt',
                  color: Colors.amber,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HosnObeStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const _HosnObeStatusBadge({
    required this.label,
    required this.color,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
