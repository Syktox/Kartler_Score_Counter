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
                        final roundEntries = _mergeQuickEntries(
                          roundEntry.value,
                        ).reversed.toList();

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
                                subtitle: Text(entry.timeLabel),
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

  List<_MergedMulatschakHistoryEntry> _mergeQuickEntries(
    List<MulatschakHistoryEntry> entries,
  ) {
    final merged = <_MergedMulatschakHistoryEntry>[];

    for (final entry in entries) {
      final previous = merged.isEmpty ? null : merged.last;

      if (previous != null && previous.canMerge(entry)) {
        previous.add(entry);
      } else {
        merged.add(_MergedMulatschakHistoryEntry.fromEntry(entry));
      }
    }

    return merged;
  }
}

class _MergedMulatschakHistoryEntry {
  static const _mergeWindow = Duration(seconds: 30);

  final String playerName;
  String _startTime;
  String _endTime;
  final int _singleChangePoints;
  int points;

  _MergedMulatschakHistoryEntry({
    required this.playerName,
    required String startTime,
    required String endTime,
    required int singleChangePoints,
    required this.points,
  }) : _startTime = startTime,
       _endTime = endTime,
       _singleChangePoints = singleChangePoints;

  factory _MergedMulatschakHistoryEntry.fromEntry(
    MulatschakHistoryEntry entry,
  ) {
    return _MergedMulatschakHistoryEntry(
      playerName: entry.playerName,
      startTime: entry.time,
      endTime: entry.time,
      singleChangePoints: entry.points,
      points: entry.points,
    );
  }

  String get timeLabel => _startTime == _endTime
      ? _startTime
      : '$_startTime - $_endTime';

  bool canMerge(MulatschakHistoryEntry next) {
    if (playerName != next.playerName) {
      return false;
    }
    if (_singleChangePoints == 0 || _singleChangePoints != next.points) {
      return false;
    }

    final previousSeconds = _secondsOfDay(_endTime);
    final nextSeconds = _secondsOfDay(next.time);
    if (previousSeconds == null || nextSeconds == null) {
      return false;
    }

    final difference = Duration(seconds: nextSeconds - previousSeconds);
    return !difference.isNegative && difference < _mergeWindow;
  }

  void add(MulatschakHistoryEntry next) {
    points += next.points;
    _endTime = next.time;
  }

  static int? _secondsOfDay(String time) {
    final parts = time.split(':');
    if (parts.length < 2 || parts.length > 3) {
      return null;
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    final seconds = parts.length == 3 ? int.tryParse(parts[2]) : 0;
    if (hours == null || minutes == null || seconds == null) {
      return null;
    }
    if (hours < 0 ||
        hours > 23 ||
        minutes < 0 ||
        minutes > 59 ||
        seconds < 0 ||
        seconds > 59) {
      return null;
    }

    return hours * 3600 + minutes * 60 + seconds;
  }
}
