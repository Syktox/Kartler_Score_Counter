import 'package:flutter/material.dart';

import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';
import '../../widgets/winner_banner.dart';

class WattenBody extends StatelessWidget {
  final bool isLoading;
  final String gameName;
  final WattenGame currentGame;
  final WattenSide selectedSide;
  final String? winner;
  final bool tableMode;
  final ValueChanged<WattenSide> onSelectedSideChanged;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetSelectedSide;
  final ValueChanged<bool> onTableModeChanged;

  const WattenBody({
    super.key,
    required this.isLoading,
    required this.gameName,
    required this.currentGame,
    required this.selectedSide,
    required this.winner,
    required this.tableMode,
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

    final scoreCards = Row(
      crossAxisAlignment: isLandscape
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        _WattenSideCard(
          title: WattenSide.me.label,
          score: currentGame.me,
          isSelected: selectedSide == WattenSide.me,
          fillHeight: isLandscape,
          onTap: () => onSelectedSideChanged(WattenSide.me),
        ),
        _WattenSideCard(
          title: WattenSide.you.label,
          score: currentGame.you,
          isSelected: selectedSide == WattenSide.you,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.compare_arrows),
                        tooltip: 'Tischmodus',
                        onPressed: () => onTableModeChanged(!tableMode),
                      ),
                    ],
                  ),
                  if (winner != null) ...[
                    WinnerBanner(winner: winner!, compact: true),
                    const SizedBox(height: 6),
                  ],
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
          Text(
            gameName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (winner != null) WinnerBanner(winner: winner!),
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
              score: currentGame.you,
              rotated: true,
              isSelected: selectedSide == WattenSide.you,
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
              score: currentGame.me,
              rotated: false,
              isSelected: selectedSide == WattenSide.me,
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
}

class _TableSide extends StatelessWidget {
  final WattenSide side;
  final int score;
  final bool rotated;
  final bool isSelected;
  final String? winner;
  final VoidCallback onSelect;
  final ValueChanged<int> onScore;
  final VoidCallback onReset;

  const _TableSide({
    required this.side,
    required this.score,
    required this.rotated,
    required this.isSelected,
    required this.winner,
    required this.onSelect,
    required this.onScore,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final winnerOfSide = winner == side.label;
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ScoreCard(
            title: side.label,
            score: score,
            isSelected: isSelected,
            onTap: onSelect,
            compact: true,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(minHeight: 120),
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
                  label: 'Reset',
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

    final decorated = Stack(
      children: [
        Positioned.fill(child: content),
        if (winnerOfSide)
          Positioned(
            left: 8,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
              ),
              child: const Text(
                'Gewinnt!',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: rotated ? RotatedBox(quarterTurns: 2, child: decorated) : decorated,
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
          label: 'Reset',
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
          label: 'Reset',
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
  final VoidCallback onTap;
  final bool fillHeight;

  const _WattenSideCard({
    required this.title,
    required this.score,
    required this.isSelected,
    required this.onTap,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ScoreCard(
        title: title,
        score: score,
        isSelected: isSelected,
        onTap: onTap,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        constraints: fillHeight
            ? null
            : BoxConstraints(
                minHeight: ResponsiveUtils.isDesktopCardPlatform ? 260 : 220,
                maxHeight: ResponsiveUtils.isDesktopCardPlatform ? 300 : 260,
              ),
      ),
    );
  }
}
