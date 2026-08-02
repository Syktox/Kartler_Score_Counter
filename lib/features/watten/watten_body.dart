import 'package:flutter/material.dart';

import '../../models/watten_game.dart';
import '../../models/watten_side.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/score_button.dart';
import '../../widgets/score_card.dart';
import '../../widgets/winner_banner.dart';

class WattenBody extends StatelessWidget {
  final bool isLoading;
  final WattenGame currentGame;
  final WattenSide selectedSide;
  final String? winner;
  final ValueChanged<WattenSide> onSelectedSideChanged;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onResetSelectedSide;

  const WattenBody({
    super.key,
    required this.isLoading,
    required this.currentGame,
    required this.selectedSide,
    required this.winner,
    required this.onSelectedSideChanged,
    required this.onScoreChanged,
    required this.onResetSelectedSide,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLandscape = ResponsiveUtils.isHandsetLandscape(
      MediaQuery.of(context).size,
    );
    final scoreCards = Row(
      crossAxisAlignment: isLandscape
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.center,
      children: [
        _WattenSideCard(
          title: 'Me',
          score: currentGame.me,
          isSelected: selectedSide == WattenSide.me,
          fillHeight: isLandscape,
          onTap: () => onSelectedSideChanged(WattenSide.me),
        ),
        _WattenSideCard(
          title: 'You',
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
