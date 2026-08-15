import 'package:flutter/material.dart';

import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';

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
    final scoreCards = Row(
      crossAxisAlignment: isLandscape
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        _WattenSideCard(
          title: meLabel,
          score: currentGame.me,
          isSelected: selectedSide == WattenSide.me,
          isWinner: meIsWinner,
          isLoser: hasWinner && !meIsWinner,
          isTense: !hasWinner && _isTense(currentGame.me),
          fillHeight: isLandscape,
          onTap: () => onSelectedSideChanged(WattenSide.me),
        ),
        _WattenSideCard(
          title: youLabel,
          score: currentGame.you,
          isSelected: selectedSide == WattenSide.you,
          isWinner: youIsWinner,
          isLoser: hasWinner && !youIsWinner,
          isTense: !hasWinner && _isTense(currentGame.you),
          fillHeight: isLandscape,
          onTap: () => onSelectedSideChanged(WattenSide.you),
        ),
      ],
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
              child: Column(
                children: [
                  Expanded(
                    child: WattenControls(
                      compact: true,
                      fillHeight: true,
                      onScoreChanged: onScoreChanged,
                      onResetSelectedSide: onResetSelectedSide,
                    ),
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
          child: Stack(
            children: [
              Positioned.fill(
                child: ScoreCard(
                  title: title,
                  score: score,
                  isSelected: isSelected,
                  onTap: onSelect,
                  compact: true,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: const BoxConstraints(minHeight: 120),
                ),
              ),
              if (winnerOfSide)
                const Positioned(right: 12, top: 6, child: _WinnerBadge())
              else if (loserOfSide)
                const Positioned(right: 12, top: 6, child: _LoserBadge())
              else if (isTense)
                const Positioned(right: 12, top: 6, child: _TenseBadge()),
            ],
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
  final bool fillHeight;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetSelectedSide;

  const WattenControls({
    super.key,
    this.compact = false,
    this.fillHeight = false,
    required this.onScoreChanged,
    required this.onResetSelectedSide,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      final buttons = [
        ScoreButton(
          label: '+2',
          onPressed: () => onScoreChanged(2),
          minimumSize: const Size(120, 54),
          fontSize: 22,
          width: 120,
        ),
        ScoreButton(
          label: '+3',
          onPressed: () => onScoreChanged(3),
          minimumSize: const Size(120, 54),
          fontSize: 22,
          width: 120,
        ),
        ScoreButton(
          label: 'Streichen',
          onPressed: onResetSelectedSide,
          minimumSize: const Size(120, 54),
          fontSize: 18,
          width: 120,
        ),
      ];

      if (fillHeight) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final button in buttons) ...[
              Expanded(child: button),
              if (button != buttons.last) const SizedBox(height: 8),
            ],
          ],
        );
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buttons[0],
          const SizedBox(height: 8),
          buttons[1],
          const SizedBox(height: 8),
          buttons[2],
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
  final bool fillHeight;

  const _WattenSideCard({
    required this.title,
    required this.score,
    required this.isSelected,
    required this.isWinner,
    required this.isLoser,
    required this.isTense,
    required this.onTap,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: fillHeight && constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : null,
                child: ScoreCard(
                  title: title,
                  score: score,
                  isSelected: isSelected,
                  onTap: onTap,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  constraints: fillHeight
                      ? null
                      : BoxConstraints(
                          minHeight: ResponsiveUtils.isDesktopCardPlatform
                              ? 270
                              : 230,
                          maxHeight: ResponsiveUtils.isDesktopCardPlatform
                              ? 310
                              : 270,
                        ),
                ),
              ),
              if (isWinner)
                const Positioned(right: 14, top: 10, child: _WinnerBadge())
              else if (isLoser)
                const Positioned(right: 14, top: 10, child: _LoserBadge())
              else if (isTense)
                const Positioned(right: 14, top: 10, child: _TenseBadge()),
            ],
          );
        },
      ),
    );
  }
}

class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge();

  @override
  Widget build(BuildContext context) {
    return const _WattenStatusBadge(label: 'Gewinner', color: Colors.green);
  }
}

class _TenseBadge extends StatelessWidget {
  const _TenseBadge();

  @override
  Widget build(BuildContext context) {
    return const _WattenStatusBadge(label: 'Gespannt', color: Colors.amber);
  }
}

class _LoserBadge extends StatelessWidget {
  const _LoserBadge();

  @override
  Widget build(BuildContext context) {
    return const _WattenStatusBadge(
      label: 'X',
      color: Colors.red,
      fontSize: 16,
    );
  }
}

class _WattenStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const _WattenStatusBadge({
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
