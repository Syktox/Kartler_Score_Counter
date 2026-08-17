import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import '../../widgets/player_score_card.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card_badge.dart';

class MulatschakBody extends StatelessWidget {
  final bool isLoading;
  final Map<String, int> scores;
  final String currentPlayerId;
  final String Function(String playerId) nameOf;
  final int multiplier;
  final String? winnerPlayerId;
  final ValueChanged<String> onPlayerSelected;
  final void Function(int oldIndex, int newIndex) onPlayersReordered;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<int> onMultiplierChanged;
  final bool hasAvailablePlayers;
  final VoidCallback onPickLineup;
  final VoidCallback onAddPlayer;

  const MulatschakBody({
    super.key,
    required this.isLoading,
    required this.scores,
    required this.currentPlayerId,
    required this.nameOf,
    required this.multiplier,
    required this.winnerPlayerId,
    required this.onPlayerSelected,
    required this.onPlayersReordered,
    required this.onScoreChanged,
    required this.onMultiplierChanged,
    required this.hasAvailablePlayers,
    required this.onPickLineup,
    required this.onAddPlayer,
  });

  bool get _hasWinner => winnerPlayerId != null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scores.isEmpty) {
      return _EmptyLineup(
        hasAvailablePlayers: hasAvailablePlayers,
        onPickLineup: onPickLineup,
        onAddPlayer: onAddPlayer,
      );
    }

    final entries = scores.entries.toList();
    final isLandscape = ResponsiveUtils.isHandsetLandscape(
      MediaQuery.of(context).size,
    );

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 18, 6),
        child: Row(
          children: [
            Expanded(child: _buildCompactPlayerWrap(entries)),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: MulatschakControls(
                compact: true,
                multiplier: multiplier,
                onScoreChanged: onScoreChanged,
                onMultiplierChanged: onMultiplierChanged,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (ResponsiveUtils.isHandsetWidth(constraints.maxWidth) &&
                    entries.length >= 3) {
                  return _buildPlayersGrid(entries);
                }

                return _buildPlayersWrap(entries);
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: MulatschakControls(
              multiplier: multiplier,
              onScoreChanged: onScoreChanged,
              onMultiplierChanged: onMultiplierChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersWrap(List<MapEntry<String, int>> entries) {
    const spacing = 12.0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Bei zwei Spielern passen die Karten nebeneinander in eine
            // Zeile, damit die Punkte auf einer Linie liegen.
            final cardWidth = entries.length == 2
                ? math.min(
                    PlayerScoreCard.width,
                    (constraints.maxWidth - spacing) / 2,
                  )
                : PlayerScoreCard.width;

            return Wrap(
              alignment: WrapAlignment.center,
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(entries.length, (index) {
                final entry = entries[index];

                return SizedBox(
                  width: cardWidth,
                  child: _PlayerCard(
                    key: ValueKey('mulatschak-score-player-${entry.key}'),
                    index: index,
                    playerId: entry.key,
                    name: nameOf(entry.key),
                    score: entry.value,
                    isSelected: entry.key == currentPlayerId,
                    isWinner: entry.key == winnerPlayerId,
                    isLoser: _hasWinner && entry.key != winnerPlayerId,
                    onSelected: onPlayerSelected,
                    onReordered: onPlayersReordered,
                    onDroppedOutside: () =>
                        onPlayersReordered(index, entries.length),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactPlayerWrap(List<MapEntry<String, int>> entries) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: List.generate(entries.length, (index) {
            final entry = entries[index];

            return SizedBox(
              width: 148,
              child: _PlayerCard(
                key: ValueKey('mulatschak-score-player-${entry.key}'),
                index: index,
                playerId: entry.key,
                name: nameOf(entry.key),
                score: entry.value,
                isSelected: entry.key == currentPlayerId,
                isWinner: entry.key == winnerPlayerId,
                isLoser: _hasWinner && entry.key != winnerPlayerId,
                compact: true,
                onSelected: onPlayerSelected,
                onReordered: onPlayersReordered,
                onDroppedOutside: () =>
                    onPlayersReordered(index, entries.length),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPlayersGrid(List<MapEntry<String, int>> entries) {
    const columnCount = 3;
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        final cellHeight = math.max(204.0, cellWidth / 0.68);

        return GridView.count(
          crossAxisCount: columnCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: cellWidth / cellHeight,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 190),
          children: List.generate(entries.length, (index) {
            final entry = entries[index];

            return _PlayerCard(
              key: ValueKey('mulatschak-score-player-${entry.key}'),
              index: index,
              playerId: entry.key,
              name: nameOf(entry.key),
              score: entry.value,
              isSelected: entry.key == currentPlayerId,
              isWinner: entry.key == winnerPlayerId,
              isLoser: _hasWinner && entry.key != winnerPlayerId,
              onSelected: onPlayerSelected,
              onReordered: onPlayersReordered,
              onDroppedOutside: () => onPlayersReordered(index, entries.length),
            );
          }),
        );
      },
    );
  }
}

class _EmptyLineup extends StatelessWidget {
  final bool hasAvailablePlayers;
  final VoidCallback onPickLineup;
  final VoidCallback onAddPlayer;

  const _EmptyLineup({
    required this.hasAvailablePlayers,
    required this.onPickLineup,
    required this.onAddPlayer,
  });

  @override
  Widget build(BuildContext context) {
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
              'Verwalte Spieler über die Startseite, um Punkte zu zählen.',
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
}

class MulatschakControls extends StatelessWidget {
  final int multiplier;
  final bool compact;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<int> onMultiplierChanged;

  const MulatschakControls({
    super.key,
    required this.multiplier,
    this.compact = false,
    required this.onScoreChanged,
    required this.onMultiplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _MultiplierButton(
              compact: true,
              multiplier: multiplier,
              onChanged: onMultiplierChanged,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Expanded(
                child: ScoreButton(
                  label: '-5',
                  onPressed: () => onScoreChanged(-5),
                  minimumSize: const Size(96, 48),
                  fontSize: 20,
                  width: 96,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ScoreButton(
                  label: '-1',
                  onPressed: () => onScoreChanged(-1),
                  minimumSize: const Size(96, 48),
                  fontSize: 20,
                  width: 96,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ScoreButton(
                  label: '+1',
                  onPressed: () => onScoreChanged(1),
                  minimumSize: const Size(96, 48),
                  fontSize: 20,
                  width: 96,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ScoreButton(
                  label: '+5',
                  onPressed: () => onScoreChanged(5),
                  minimumSize: const Size(96, 48),
                  fontSize: 20,
                  width: 96,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MultiplierButton(
          multiplier: multiplier,
          onChanged: onMultiplierChanged,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final buttonWidth = ((constraints.maxWidth - gap * 3) / 4).clamp(
              0.0,
              116.0,
            );

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScoreButton(
                  label: '-5',
                  onPressed: () => onScoreChanged(-5),
                  minimumSize: const Size(0, 80),
                  width: buttonWidth,
                ),
                const SizedBox(width: gap),
                ScoreButton(
                  label: '-1',
                  onPressed: () => onScoreChanged(-1),
                  minimumSize: const Size(0, 80),
                  width: buttonWidth,
                ),
                const SizedBox(width: gap),
                ScoreButton(
                  label: '+1',
                  onPressed: () => onScoreChanged(1),
                  minimumSize: const Size(0, 80),
                  width: buttonWidth,
                ),
                const SizedBox(width: gap),
                ScoreButton(
                  label: '+5',
                  onPressed: () => onScoreChanged(5),
                  minimumSize: const Size(0, 80),
                  width: buttonWidth,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MultiplierButton extends StatelessWidget {
  static const multipliers = [1, 2, 4, 8, 16, 32, 64, 128];

  final int multiplier;
  final ValueChanged<int> onChanged;
  final bool compact;

  const _MultiplierButton({
    required this.multiplier,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<int>(
      key: const Key('mulatschakMultiplierButton'),
      tooltip: 'Multiplikator',
      initialValue: multipliers.contains(multiplier) ? multiplier : null,
      constraints: const BoxConstraints(),
      position: PopupMenuPosition.over,
      onSelected: onChanged,
      itemBuilder: (context) => multipliers
          .map(
            (value) => PopupMenuItem<int>(
              value: value,
              height: 44,
              child: Center(child: Text('${value}x')),
            ),
          )
          .toList(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 22,
          vertical: compact ? 4 : 10,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${multiplier}x',
              style: TextStyle(
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down,
              size: compact ? 20 : 24,
              color: colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final int index;
  final String playerId;
  final String name;
  final int score;
  final bool isSelected;
  final bool isWinner;
  final bool isLoser;
  final bool compact;
  final ValueChanged<String> onSelected;
  final void Function(int oldIndex, int newIndex) onReordered;
  final VoidCallback onDroppedOutside;

  const _PlayerCard({
    super.key,
    required this.index,
    required this.playerId,
    required this.name,
    required this.score,
    required this.isSelected,
    required this.isWinner,
    required this.isLoser,
    required this.onSelected,
    required this.onReordered,
    required this.onDroppedOutside,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stretch = constraints.hasBoundedHeight;
        final card = _scoreCard(context, stretch: stretch);
        final feedbackWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : (compact ? 148.0 : 176.0);
        final feedbackHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;

        return DragTarget<int>(
          onWillAcceptWithDetails: (details) => details.data != index,
          onAcceptWithDetails: (details) {
            final oldIndex = details.data;
            final newIndex = index > oldIndex ? index + 1 : index;
            onReordered(oldIndex, newIndex);
          },
          builder: (context, candidateData, rejectedData) {
            final isDropTarget = candidateData.isNotEmpty;

            return LongPressDraggable<int>(
              data: index,
              onDragEnd: (details) {
                if (!details.wasAccepted) {
                  onDroppedOutside();
                }
              },
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: feedbackWidth,
                  height: feedbackHeight,
                  child: Opacity(opacity: 0.92, child: _scoreCard(context)),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card),
              child: AnimatedScale(
                scale: isDropTarget ? 1.04 : 1,
                duration: const Duration(milliseconds: 120),
                child: card,
              ),
            );
          },
        );
      },
    );
  }

  Widget _scoreCard(BuildContext context, {bool stretch = false}) {
    return PlayerScoreCard(
      title: name,
      score: score,
      isSelected: isSelected,
      compact: compact,
      stretch: stretch,
      onTap: () {
        FocusScope.of(context).unfocus();
        onSelected(playerId);
      },
      badge: isWinner
          ? const ScoreCardBadge(label: 'Gewinner', color: Colors.green)
          : isLoser
          ? const ScoreCardBadge(
              label: 'X',
              color: Colors.red,
              fontSize: 16,
            )
          : null,
    );
  }
}
