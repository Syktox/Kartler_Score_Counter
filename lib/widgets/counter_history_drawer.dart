import 'package:flutter/material.dart';

class CounterHistoryDrawer extends StatelessWidget {
  final String currentCounter;
  final List<String> currentHistory;

  const CounterHistoryDrawer({
    super.key,
    required this.currentCounter,
    required this.currentHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Zähler-Verlauf'),
              subtitle: Text(currentCounter),
            ),
            const Divider(),
            Expanded(
              child: currentHistory.isEmpty
                  ? const Center(child: Text('Noch keine Änderungen.'))
                  : ListView.separated(
                      itemCount: currentHistory.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        return ListTile(title: Text(currentHistory[index]));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
