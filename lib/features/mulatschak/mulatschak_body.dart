import 'package:flutter/material.dart';

import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';

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
        padding: const EdgeInsets.fromLTRB(14, 10, 18, 12),
        child: Row(
          children: [
            Expanded(child: _buildCompactPlayerWrap(entries)),
            const SizedBox(width: 12),
            SizedBox(
              width: 216,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MulatschakControls(
                      compact: true,
                      multiplier: multiplier,
                      onScoreChanged: onScoreChanged,
                      onMultiplierChanged: onMultiplierChanged,
                    ),
                  ],
                ),
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

                return _buildPlayersWrap(entries);
              },
            ),
          ),
          MulatschakControls(
            multiplier: multiplier,
            onScoreChanged: onScoreChanged,
            onMultiplierChanged: onMultiplierChanged,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlayersWrap(List<MapEntry<String, int>> entries) {
    return SingleChildScrollView(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: List.generate(entries.length, (index) {
          final entry = entries[index];

          return SizedBox(
            width: 176,
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
              onDroppedOutside: () => onPlayersReordered(index, entries.length),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompactPlayerWrap(List<MapEntry<String, int>> entries) {
    return SingleChildScrollView(
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
              onDroppedOutside: () => onPlayersReordered(index, entries.length),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPlayersGrid(List<MapEntry<String, int>> entries) {
    final columnCount = entries.length >= 3 ? 3 : entries.length;

    return GridView.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.65,
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
  final bool compact;
  final int multiplier;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<int> onMultiplierChanged;

  const MulatschakControls({
    super.key,
    this.compact = false,
    required this.multiplier,
    required this.onScoreChanged,
    required this.onMultiplierChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final buttons = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScoreButton(
            label: '-5',
            onPressed: () => onScoreChanged(-5),
            minimumSize: const Size(128, 48),
            fontSize: 20,
            width: 128,
          ),
          const SizedBox(height: 8),
          ScoreButton(
            label: '-1',
            onPressed: () => onScoreChanged(-1),
            minimumSize: const Size(128, 48),
            fontSize: 20,
            width: 128,
          ),
          const SizedBox(height: 8),
          ScoreButton(
            label: '+1',
            onPressed: () => onScoreChanged(1),
            minimumSize: const Size(128, 48),
            fontSize: 20,
            width: 128,
          ),
          const SizedBox(height: 8),
          ScoreButton(
            label: '+5',
            onPressed: () => onScoreChanged(5),
            minimumSize: const Size(128, 48),
            fontSize: 20,
            width: 128,
          ),
        ],
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MulatschakMultiplierSelector(
            multiplier: multiplier,
            onChanged: onMultiplierChanged,
          ),
          const SizedBox(width: 8),
          buttons,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final buttonWidth = ((constraints.maxWidth - gap * 3) / 4).clamp(
          0.0,
          116.0,
        );

        return Column(
          children: [
            _MultiplierRow(
              multiplier: multiplier,
              onChanged: onMultiplierChanged,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScoreButton(
                  label: '-5',
                  onPressed: () => onScoreChanged(-5),
                  minimumSize: const Size(0, 84),
                  width: buttonWidth,
                ),
                const SizedBox(width: gap),
                ScoreButton(
                  label: '-1',
                  onPressed: () => onScoreChanged(-1),
                  minimumSize: const Size(0, 84),
                  width: buttonWidth,
                ),
                const SizedBox(width: gap),
                ScoreButton(
                  label: '+1',
                  onPressed: () => onScoreChanged(1),
                  minimumSize: const Size(0, 84),
                  width: buttonWidth,
                ),
                const SizedBox(width: gap),
                ScoreButton(
                  label: '+5',
                  onPressed: () => onScoreChanged(5),
                  minimumSize: const Size(0, 84),
                  width: buttonWidth,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class MulatschakMultiplierSelector extends StatelessWidget {
  static const multipliers = [1, 2, 4, 8, 16, 32, 64, 128];

  final int multiplier;
  final ValueChanged<int> onChanged;

  const MulatschakMultiplierSelector({
    super.key,
    required this.multiplier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 76,
      child: PopupMenuButton<int>(
        key: const Key('mulatschakMultiplierButton'),
        tooltip: 'Multiplikator',
        initialValue: multipliers.contains(multiplier) ? multiplier : null,
        constraints: const BoxConstraints.tightFor(width: 76),
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
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${multiplier}x',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiplierRow extends StatelessWidget {
  final int multiplier;
  final ValueChanged<int> onChanged;

  const _MultiplierRow({required this.multiplier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const label = Text(
      'Multiplikator',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final selector = MulatschakMultiplierSelector(
          multiplier: multiplier,
          onChanged: onChanged,
        );

        if (ResponsiveUtils.isHandsetWidth(constraints.maxWidth)) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [label, selector],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [label, const SizedBox(width: 16), selector],
        );
      },
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
    return Stack(
      fit: stretch ? StackFit.expand : StackFit.loose,
      children: [
        ScoreCard(
          title: name,
          score: score,
          isSelected: isSelected,
          compact: compact,
          stretch: stretch,
          width: compact ? 148 : 176,
          constraints: BoxConstraints(minHeight: compact ? 156 : 204),
          padding: stretch
              ? const EdgeInsets.fromLTRB(16, 54, 16, 0)
              : (compact
                    ? const EdgeInsets.fromLTRB(8, 36, 8, 12)
                    : const EdgeInsets.fromLTRB(16, 48, 16, 14)),
          titleScoreGap: stretch ? 14 : (compact ? 12 : 14),
          onTap: () {
            FocusScope.of(context).unfocus();
            onSelected(playerId);
          },
        ),
        if (isWinner)
          const Positioned(right: 12, top: 8, child: _MulatschakWinnerBadge())
        else if (isLoser)
          const Positioned(right: 12, top: 8, child: _MulatschakLoserBadge()),
      ],
    );
  }
}

class _MulatschakWinnerBadge extends StatelessWidget {
  const _MulatschakWinnerBadge();

  @override
  Widget build(BuildContext context) {
    return const _MulatschakStatusBadge(label: 'Gewinner', color: Colors.green);
  }
}

class _MulatschakLoserBadge extends StatelessWidget {
  const _MulatschakLoserBadge();

  @override
  Widget build(BuildContext context) {
    return const _MulatschakStatusBadge(
      label: 'X',
      color: Colors.red,
      fontSize: 16,
    );
  }
}

class _MulatschakStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const _MulatschakStatusBadge({
    required this.label,
    required this.color,
    this.fontSize = 13,
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
