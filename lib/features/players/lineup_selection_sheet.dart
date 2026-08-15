import 'package:flutter/material.dart';

import '../../models/player.dart';

/// Bottom-Sheet für die Mitspieler-Auswahl bei Mulatschak und Hosn Obe:
/// Wer spielt? bestimmt das Lineup des Modus.
class LineupSelectionSheet extends StatefulWidget {
  final List<Player> players;
  final List<String> lineup;

  const LineupSelectionSheet({
    super.key,
    required this.players,
    required this.lineup,
  });

  @override
  State<LineupSelectionSheet> createState() => _LineupSelectionSheetState();
}

class _LineupSelectionSheetState extends State<LineupSelectionSheet> {
  late List<String> _orderedPlayerIds;
  late Set<String> _lineup;

  @override
  void initState() {
    super.initState();
    final knownPlayerIds = widget.players.map((player) => player.id).toSet();
    final lineupIds = [
      for (final playerId in widget.lineup)
        if (knownPlayerIds.contains(playerId)) playerId,
    ];
    _orderedPlayerIds = [
      ...lineupIds,
      for (final player in widget.players)
        if (!lineupIds.contains(player.id)) player.id,
    ];
    _lineup = Set<String>.from(lineupIds);
  }

  void _setParticipation(String playerId, bool isPlaying) {
    setState(() {
      if (isPlaying) {
        _lineup.add(playerId);
      } else {
        _lineup.remove(playerId);
      }
    });
  }

  void _reorderPlayer(int oldIndex, int newIndex) {
    setState(() {
      final playerId = _orderedPlayerIds.removeAt(oldIndex);
      _orderedPlayerIds.insert(newIndex, playerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playersById = {
      for (final player in widget.players) player.id: player,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wer spielt?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${_lineup.length} von ${widget.players.length} Spielern '
              'spielen mit.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: widget.players.isEmpty
                  ? const SizedBox.shrink()
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: _orderedPlayerIds.length,
                      onReorderItem: _reorderPlayer,
                      itemBuilder: (context, index) {
                        final player = playersById[_orderedPlayerIds[index]]!;
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('lineup-player-${player.id}'),
                          index: index,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                radius: 18,
                                child: Text(
                                  player.displayName.characters.first
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(player.displayName),
                              trailing: _ParticipationSlider(
                                key: ValueKey(
                                  'lineup-participation-${player.id}',
                                ),
                                isPlaying: _lineup.contains(player.id),
                                onChanged: (isPlaying) =>
                                    _setParticipation(player.id, isPlaying),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(
                  _orderedPlayerIds
                      .where(_lineup.contains)
                      .toList(growable: false),
                );
              },
              icon: const Icon(Icons.check),
              label: const Text('Fertig'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipationSlider extends StatelessWidget {
  final bool isPlaying;
  final ValueChanged<bool> onChanged;

  const _ParticipationSlider({
    super.key,
    required this.isPlaying,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Teilnahme',
      value: isPlaying ? 'Mitspielen' : 'Zuschauen',
      child: SizedBox(
        width: 142,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  isPlaying ? 'Mitspielen' : 'Zuschauen',
                  key: ValueKey(isPlaying),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isPlaying
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Switch(
              value: isPlaying,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
