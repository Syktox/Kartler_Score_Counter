import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../models/watten_side.dart';

/// Maximal erlaubte Spieler pro Watten-Team.
const int wattenTeamSizeLimit = 2;

/// Gewählte Watten-Teams (Spieler-IDs).
typedef WattenTeams = ({List<String> me, List<String> you});

/// Bottom-Sheet für die Watten-Teamwahl: Wer spielt und gegen wen?
class WattenTeamSheet extends StatefulWidget {
  final List<Player> players;
  final List<String> meTeam;
  final List<String> youTeam;

  const WattenTeamSheet({
    super.key,
    required this.players,
    required this.meTeam,
    required this.youTeam,
  });

  @override
  State<WattenTeamSheet> createState() => _WattenTeamSheetState();
}

class _WattenTeamSheetState extends State<WattenTeamSheet> {
  late final Set<String> _me = Set<String>.from(widget.meTeam);
  late final Set<String> _you = Set<String>.from(widget.youTeam);

  List<Player> get _unassigned {
    return widget.players
        .where(
          (player) => !_me.contains(player.id) && !_you.contains(player.id),
        )
        .toList(growable: false);
  }

  void _toggle(String playerId, WattenSide side) {
    setState(() {
      final target = side == WattenSide.me ? _me : _you;
      final other = side == WattenSide.me ? _you : _me;
      if (!target.add(playerId)) {
        target.remove(playerId);
      }
      other.remove(playerId);
    });
  }

  void _assign(String playerId, WattenSide side) {
    setState(() {
      final target = side == WattenSide.me ? _me : _you;
      final other = side == WattenSide.me ? _you : _me;
      if (target.length >= wattenTeamSizeLimit) {
        return;
      }
      other.remove(playerId);
      target.add(playerId);
    });
  }

  bool _canAssign(String playerId, WattenSide side) {
    final target = side == WattenSide.me ? _me : _you;
    return target.contains(playerId) || target.length < wattenTeamSizeLimit;
  }

  String _nameOf(String id) {
    for (final player in widget.players) {
      if (player.id == id) {
        return player.displayName;
      }
    }
    return id;
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
              'Wer spielt?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Maximal ${wattenTeamSizeLimit * 2} Spieler, je Team maximal $wattenTeamSizeLimit.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TeamCard(
                    side: WattenSide.me,
                    memberIds: _me.toList(),
                    nameOf: _nameOf,
                    canAccept: (id) => _canAssign(id, WattenSide.me),
                    onAssign: (id) => _assign(id, WattenSide.me),
                    onRemove: (id) => _toggle(id, WattenSide.me),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TeamCard(
                    side: WattenSide.you,
                    memberIds: _you.toList(),
                    nameOf: _nameOf,
                    canAccept: (id) => _canAssign(id, WattenSide.you),
                    onAssign: (id) => _assign(id, WattenSide.you),
                    onRemove: (id) => _toggle(id, WattenSide.you),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Verfügbare Spieler',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final player in _unassigned)
                    LongPressDraggable<String>(
                      data: player.id,
                      feedback: _PlayerDragFeedback(name: player.displayName),
                      childWhenDragging: Opacity(
                        opacity: 0.35,
                        child: _AvailablePlayerTile(
                          player: player,
                          meEnabled: _me.length < wattenTeamSizeLimit,
                          youEnabled: _you.length < wattenTeamSizeLimit,
                          onAssignMe: () => _assign(player.id, WattenSide.me),
                          onAssignYou: () => _assign(player.id, WattenSide.you),
                        ),
                      ),
                      child: _AvailablePlayerTile(
                        player: player,
                        meEnabled: _me.length < wattenTeamSizeLimit,
                        youEnabled: _you.length < wattenTeamSizeLimit,
                        onAssignMe: () => _assign(player.id, WattenSide.me),
                        onAssignYou: () => _assign(player.id, WattenSide.you),
                      ),
                    ),
                  if (_unassigned.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Alle Spieler sind eingeteilt.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                Navigator.of(context).pop((
                  me: _me.toList(growable: false),
                  you: _you.toList(growable: false),
                ));
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

class _AvailablePlayerTile extends StatelessWidget {
  final Player player;
  final bool meEnabled;
  final bool youEnabled;
  final VoidCallback onAssignMe;
  final VoidCallback onAssignYou;

  const _AvailablePlayerTile({
    required this.player,
    required this.meEnabled,
    required this.youEnabled,
    required this.onAssignMe,
    required this.onAssignYou,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        child: Text(
          player.displayName.characters.first.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(player.displayName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SidePill(
            label: WattenSide.me.label,
            enabled: meEnabled,
            onPressed: onAssignMe,
          ),
          const SizedBox(width: 8),
          _SidePill(
            label: WattenSide.you.label,
            enabled: youEnabled,
            onPressed: onAssignYou,
          ),
        ],
      ),
    );
  }
}

class _PlayerDragFeedback extends StatelessWidget {
  final String name;

  const _PlayerDragFeedback({required this.name});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1, color: colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Karte einer Watten-Seite mit den bereits eingeteilten Spielern.
class _TeamCard extends StatelessWidget {
  final WattenSide side;
  final List<String> memberIds;
  final String Function(String id) nameOf;
  final bool Function(String id) canAccept;
  final ValueChanged<String> onAssign;
  final ValueChanged<String> onRemove;

  const _TeamCard({
    required this.side,
    required this.memberIds,
    required this.nameOf,
    required this.canAccept,
    required this.onAssign,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => canAccept(details.data),
      onAcceptWithDetails: (details) => onAssign(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          key: ValueKey('watten-team-${side.name}'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovering
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isHovering ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                side.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              for (final id in memberIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InputChip(
                    avatar: const Icon(Icons.person, size: 18),
                    label: Text(nameOf(id), overflow: TextOverflow.ellipsis),
                    onDeleted: () => onRemove(id),
                    deleteButtonTooltipMessage: 'Entfernen',
                  ),
                ),
              for (var i = memberIds.length; i < wattenTeamSizeLimit; i++)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    '+',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SidePill extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _SidePill({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Text(label),
    );
  }
}
