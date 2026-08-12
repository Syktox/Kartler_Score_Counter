import 'package:flutter/material.dart';

import '../../models/player.dart';

/// Bottom-Sheet für die Mitspieler-Auswahl bei Mulatschak und Hosn Obe:
/// Wer spielt mit? bestimmt das Lineup des Modus.
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
  late final Set<String> _lineup = Set<String>.from(widget.lineup);

  void _toggle(String playerId) {
    setState(() {
      if (!_lineup.add(playerId)) {
        _lineup.remove(playerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wer spielt mit?',
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
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final player in widget.players)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 18,
                        child: Text(
                          player.displayName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(player.displayName),
                      trailing: OutlinedButton(
                        onPressed: () => _toggle(player.id),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          _lineup.contains(player.id)
                              ? 'Mitspielen'
                              : 'Zuschauen',
                        ),
                      ),
                    ),
                  if (widget.players.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Noch keine Spieler vorhanden. Lege Spieler unter '
                        '„Spieler verwalten“ an.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(_lineup.toList(growable: false));
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
