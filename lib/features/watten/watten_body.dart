import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/player_score_card.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card_badge.dart';

class WattenBody extends StatelessWidget {
  final bool isLoading;
  final WattenGame currentGame;
  final WattenSide selectedSide;
  final String? winner;
  final bool tableMode;
  final int winningScore;
  final String meLabel;
  final String youLabel;
  final ValueChanged<WattenSide> onSelectedSideChanged;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetSelectedSide;
  final ValueChanged<bool> onTableModeChanged;

  const WattenBody({
    super.key,
    required this.isLoading,
    required this.currentGame,
    required this.selectedSide,
    required this.winner,
    required this.tableMode,
    required this.winningScore,
    required this.meLabel,
    required this.youLabel,
    required this.onSelectedSideChanged,
    required this.onScoreChanged,
    required this.onResetSelectedSide,
    required this.onTableModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLandscape = ResponsiveUtils.isHandsetLandscape(
      MediaQuery.of(context).size,
    );

    if (isLandscape && tableMode) {
      return _buildTableMode(context);
    }

    final meIsWinner = winner == WattenSide.me.label;
    final youIsWinner = winner == WattenSide.you.label;
    final hasWinner = winner != null;
    final scoreCards = _buildScoreCards(
      context,
      compact: isLandscape,
      meLabel: meLabel,
      meScore: currentGame.me,
      meSelected: selectedSide == WattenSide.me,
      meWinner: meIsWinner,
      meLoser: hasWinner && !meIsWinner,
      meTense: !hasWinner && _isTense(currentGame.me),
      youLabel: youLabel,
      youScore: currentGame.you,
      youSelected: selectedSide == WattenSide.you,
      youWinner: youIsWinner,
      youLoser: hasWinner && !youIsWinner,
      youTense: !hasWinner && _isTense(currentGame.you),
      onSelectMe: () => onSelectedSideChanged(WattenSide.me),
      onSelectYou: () => onSelectedSideChanged(WattenSide.you),
    );

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 18, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: scoreCards,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 132,
              child: Center(
                child: WattenControls(
                  compact: true,
                  onScoreChanged: onScoreChanged,
                  onResetSelectedSide: onResetSelectedSide,
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: scoreCards),
          const SizedBox(height: 24),
          WattenControls(
            onScoreChanged: onScoreChanged,
            onResetSelectedSide: onResetSelectedSide,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildScoreCards(
    BuildContext context, {
    required bool compact,
    required String meLabel,
    required int meScore,
    required bool meSelected,
    required bool meWinner,
    required bool meLoser,
    required bool meTense,
    required String youLabel,
    required int youScore,
    required bool youSelected,
    required bool youWinner,
    required bool youLoser,
    required bool youTense,
    required VoidCallback onSelectMe,
    required VoidCallback onSelectYou,
  }) {
    const spacing = 12.0;
    final baseWidth = compact
        ? PlayerScoreCard.compactWidth
        : PlayerScoreCard.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = math.min(
          baseWidth,
          (constraints.maxWidth - spacing) / 2,
        );

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: cardWidth,
              child: _WattenSideCard(
                title: meLabel,
                score: meScore,
                isSelected: meSelected,
                isWinner: meWinner,
                isLoser: meLoser,
                isTense: meTense,
                compact: compact,
                onTap: onSelectMe,
              ),
            ),
            const SizedBox(width: spacing),
            SizedBox(
              width: cardWidth,
              child: _WattenSideCard(
                title: youLabel,
                score: youScore,
                isSelected: youSelected,
                isWinner: youWinner,
                isLoser: youLoser,
                isTense: youTense,
                compact: compact,
                onTap: onSelectYou,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tischmodus: beide Seiten liegen sich gegenüber, jede Seite hat eigene
  /// große Bedienelemente – ideal, wenn das Handy auf dem Tisch liegt.
  Widget _buildTableMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 18, 12),
      child: Column(
        children: [
          Expanded(
            child: _TableSide(
              side: WattenSide.you,
              title: youLabel,
              score: currentGame.you,
              rotated: true,
              isSelected: selectedSide == WattenSide.you,
              isTense:
                  winner != WattenSide.you.label && _isTense(currentGame.you),
              winner: winner,
              onSelect: () {
                onSelectedSideChanged(WattenSide.you);
                onTableModeChanged(true);
              },
              onScore: (delta) {
                onSelectedSideChanged(WattenSide.you);
                onScoreChanged(delta);
              },
              onReset: () {
                onSelectedSideChanged(WattenSide.you);
                onResetSelectedSide();
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _TableSide(
              side: WattenSide.me,
              title: meLabel,
              score: currentGame.me,
              rotated: false,
              isSelected: selectedSide == WattenSide.me,
              isTense:
                  winner != WattenSide.me.label && _isTense(currentGame.me),
              winner: winner,
              onSelect: () {
                onSelectedSideChanged(WattenSide.me);
                onTableModeChanged(true);
              },
              onScore: (delta) {
                onSelectedSideChanged(WattenSide.me);
                onScoreChanged(delta);
              },
              onReset: () {
                onSelectedSideChanged(WattenSide.me);
                onResetSelectedSide();
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isTense(int score) {
    final pointsUntilWin = winningScore - score;
    return pointsUntilWin == 1 || pointsUntilWin == 2;
  }
}

class _TableSide extends StatelessWidget {
  final WattenSide side;
  final String title;
  final int score;
  final bool rotated;
  final bool isSelected;
  final bool isTense;
  final String? winner;
  final VoidCallback onSelect;
  final ValueChanged<int> onScore;
  final VoidCallback onReset;

  const _TableSide({
    required this.side,
    required this.title,
    required this.score,
    required this.rotated,
    required this.isSelected,
    required this.isTense,
    required this.winner,
    required this.onSelect,
    required this.onScore,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final winnerOfSide = winner == side.label;
    final loserOfSide = winner != null && !winnerOfSide;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: PlayerScoreCard.compactWidth,
              ),
              child: _WattenSideCard(
                title: title,
                score: score,
                isSelected: isSelected,
                compact: true,
                isWinner: winnerOfSide,
                isLoser: loserOfSide,
                isTense: isTense,
                onTap: onSelect,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 220,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScoreButton(
                      label: '+2',
                      onPressed: () => onScore(2),
                      minimumSize: const Size(100, 56),
                      fontSize: 20,
                      width: 100,
                    ),
                    const SizedBox(width: 8),
                    ScoreButton(
                      label: '+3',
                      onPressed: () => onScore(3),
                      minimumSize: const Size(100, 56),
                      fontSize: 20,
                      width: 100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ScoreButton(
                  label: 'Streichen',
                  onPressed: onReset,
                  minimumSize: const Size(100, 44),
                  fontSize: 16,
                  width: 100,
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: rotated ? RotatedBox(quarterTurns: 2, child: content) : content,
    );
  }
}

class WattenControls extends StatelessWidget {
  final bool compact;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetSelectedSide;

  const WattenControls({
    super.key,
    this.compact = false,
    required this.onScoreChanged,
    required this.onResetSelectedSide,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScoreButton(
            label: '+2',
            onPressed: () => onScoreChanged(2),
            minimumSize: const Size(120, 54),
            fontSize: 22,
            width: 120,
          ),
          const SizedBox(height: 8),
          ScoreButton(
            label: '+3',
            onPressed: () => onScoreChanged(3),
            minimumSize: const Size(120, 54),
            fontSize: 22,
            width: 120,
          ),
          const SizedBox(height: 8),
          ScoreButton(
            label: 'Streichen',
            onPressed: onResetSelectedSide,
            minimumSize: const Size(120, 54),
            fontSize: 18,
            width: 120,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScoreButton(
              label: '+2',
              onPressed: () => onScoreChanged(2),
              fontSize: 28,
            ),
            const SizedBox(width: 20),
            ScoreButton(
              label: '+3',
              onPressed: () => onScoreChanged(3),
              fontSize: 28,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ScoreButton(
          label: 'Streichen',
          onPressed: onResetSelectedSide,
          minimumSize: const Size(120, 80),
        ),
      ],
    );
  }
}

class _WattenSideCard extends StatelessWidget {
  final String title;
  final int score;
  final bool isSelected;
  final bool isWinner;
  final bool isLoser;
  final bool isTense;
  final VoidCallback onTap;
  final bool compact;

  const _WattenSideCard({
    required this.title,
    required this.score,
    required this.isSelected,
    required this.isWinner,
    required this.isLoser,
    required this.isTense,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return PlayerScoreCard(
      title: title,
      score: score,
      isSelected: isSelected,
      compact: compact,
      onTap: onTap,
      badge: isWinner
          ? const ScoreCardBadge(label: 'Gewinner', color: Colors.green)
          : isLoser
          ? const ScoreCardBadge(
              label: 'X',
              color: Colors.red,
              fontSize: 16,
            )
          : isTense
          ? const ScoreCardBadge(label: 'Gespannt', color: Colors.amber)
          : null,
    );
  }
}
