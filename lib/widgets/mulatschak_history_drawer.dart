import 'dart:collection';

import 'package:flutter/material.dart';

import '../models/mulatschak_history_entry.dart';
import '../utils/history_utils.dart';

class MulatschakHistoryDrawer extends StatelessWidget {
  final List<String> history;

  const MulatschakHistoryDrawer({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final rounds = SplayTreeMap<int, List<MulatschakHistoryEntry>>(
      (left, right) => right.compareTo(left),
    );

    for (final entry in history.map(MulatschakHistoryEntry.decode)) {
      if (entry != null) {
        rounds.putIfAbsent(entry.round, () => []).add(entry);
      }
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Mulatschak-Verlauf'),
              subtitle: Text(
                'Neue Runde, sobald alle Spieler Punkte erhalten haben',
              ),
            ),
            const Divider(),
            Expanded(
              child: rounds.isEmpty
                  ? const Center(child: Text('Noch keine Änderungen.'))
                  : ListView.separated(
                      itemCount: rounds.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final roundEntry = rounds.entries.elementAt(index);
                        final roundEntries = roundEntry.value.reversed.toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Text(
                                'Runde ${roundEntry.key}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            ...roundEntries.map(
                              (entry) => ListTile(
                                dense: true,
                                title: Text(entry.playerName),
                                subtitle: Text(entry.time),
                                trailing: Text(
                                  '${HistoryUtils.formatSignedPoints(entry.points)} Punkte',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
