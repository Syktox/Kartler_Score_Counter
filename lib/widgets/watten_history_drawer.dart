import 'package:flutter/material.dart';

import '../models/watten_history_entry.dart';
import '../models/watten_side.dart';
import '../utils/history_utils.dart';

class WattenHistoryDrawer extends StatelessWidget {
  final List<String> history;
  final String meLabel;
  final String youLabel;

  const WattenHistoryDrawer({
    super.key,
    required this.history,
    required this.meLabel,
    required this.youLabel,
  });

  String _labelFor(WattenSide side) {
    return side == WattenSide.me ? meLabel : youLabel;
  }

  @override
  Widget build(BuildContext context) {
    final entries = history
        .map(WattenHistoryEntry.decode)
        .whereType<WattenHistoryEntry>()
        .toList()
        .reversed
        .toList(growable: false);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              leading: Icon(Icons.history),
              title: Text('Watten-Verlauf'),
              subtitle: Text('Punkteänderungen der beiden Seiten'),
            ),
            const Divider(),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('Noch keine Änderungen.'))
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return ListTile(
                          title: Text(_labelFor(entry.side)),
                          subtitle: Text(entry.time),
                          trailing: Text(
                            '${HistoryUtils.formatSignedPoints(entry.points)} Punkte',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
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
