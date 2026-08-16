import 'package:flutter/material.dart';

import '../../models/player.dart';
import '../../utils/name_utils.dart';
import '../../widgets/app_dialogs.dart';
import '../hosn_obe/hosn_obe_controller.dart';
import '../mulatschak/mulatschak_controller.dart';
import '../players/players_controller.dart';
import '../watten/watten_controller.dart';

/// Spielerverwaltung: globale Spieler anlegen, umbenennen und löschen.
class PlayerManagementPage extends StatefulWidget {
  final PlayersController players;
  final MulatschakController mulatschak;
  final HosnObeController hosnObe;
  final WattenController watten;
  final bool confirmDelete;

  const PlayerManagementPage({
    super.key,
    required this.players,
    required this.mulatschak,
    required this.hosnObe,
    required this.watten,
    required this.confirmDelete,
  });

  @override
  State<PlayerManagementPage> createState() => _PlayerManagementPageState();
}

class _PlayerManagementPageState extends State<PlayerManagementPage> {
  List<String> _usageOf(Player player) {
    final usage = <String>[];
    if (widget.mulatschak.lineup.containsKey(player.id)) {
      usage.add('Mulatschak');
    }
    if (widget.hosnObe.lineup.containsKey(player.id)) {
      usage.add('Hosn Obe');
    }
    if (widget.watten.meTeam.contains(player.id) ||
        widget.watten.youTeam.contains(player.id)) {
      usage.add('Watten');
    }
    return usage;
  }

  Future<void> _showAddDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PlayerEditDialog(
        title: 'Spieler hinzufügen',
        initialName: '',
        isValid: (name) => widget.players.isNameValid(name),
        onSubmit: (name) async {
          final player = await widget.players.addPlayer(name);
          if (player == null) {
            return;
          }
          await widget.mulatschak.addPlayerToLineup(player.id);
          await widget.hosnObe.addPlayerToLineup(player.id);
        },
      ),
    );
  }

  Future<void> _showEditDialog(Player player) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _PlayerEditDialog(
        title: 'Spieler umbenennen',
        initialName: player.name,
        isValid: (name) => widget.players.isNameValid(name, player.id),
        onSubmit: (name) async {
          await widget.players.renamePlayer(player.id, name);
        },
      ),
    );
  }

  void _deletePlayer(Player player) {
    widget.mulatschak.removePlayerFromLineup(player.id);
    widget.hosnObe.removePlayerFromLineup(player.id);
    widget.watten.removePlayerFromTeams(player.id);
    widget.players.deletePlayer(player.id);
  }

  void _deleteOrConfirm(Player player) {
    if (widget.confirmDelete) {
      _showDeleteDialog(player);
      return;
    }
    _deletePlayer(player);
  }

  Future<void> _showDeleteDialog(Player player) async {
    final usage = _usageOf(player);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final message = usage.isEmpty
            ? 'Möchtest du "${player.name}" wirklich löschen?'
            : 'Möchtest du "${player.name}" wirklich löschen?\n'
                  'Der Spieler wird aus ${usage.join(' und ')} entfernt. '
                  'Gespielte Partien bleiben in der History erhalten.';
        return AlertDialog(
          title: const Text('Spieler löschen'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () {
                _deletePlayer(player);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spieler')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            widget.players,
            widget.mulatschak,
            widget.hosnObe,
            widget.watten,
          ]),
          builder: (context, _) {
            final players = widget.players.players;
            return Column(
              children: [
                Expanded(
                  child: players.isEmpty
                      ? const Center(
                          child: Text(
                            'Noch keine Spieler.\nLege deinen ersten Spieler an!',
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: players.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final player = players[index];

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  child: Text(
                                    _initialOf(player),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  player.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      tooltip: 'Umbenennen',
                                      onPressed: () => _showEditDialog(player),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip: 'Löschen',
                                      onPressed: () => _deleteOrConfirm(player),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Spieler hinzufügen'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _initialOf(Player player) {
    return player.name.isEmpty
        ? '?'
        : player.name.characters.first.toUpperCase();
  }
}

class _PlayerEditDialog extends StatefulWidget {
  final String title;
  final String initialName;
  final bool Function(String name) isValid;
  final Future<void> Function(String name) onSubmit;

  const _PlayerEditDialog({
    required this.title,
    required this.initialName,
    required this.isValid,
    required this.onSubmit,
  });

  @override
  State<_PlayerEditDialog> createState() => _PlayerEditDialogState();
}

class _PlayerEditDialogState extends State<_PlayerEditDialog> {
  late final TextEditingController _nameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = NameUtils.clean(_nameController.text);
    if (!widget.isValid(name)) {
      AppDialogs.showErrorBubble(
        context,
        'Dieser Spielername ist bereits vergeben.',
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    await widget.onSubmit(name);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'z. B. Max',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.initialName.isEmpty ? 'Hinzufügen' : 'Speichern'),
        ),
      ],
    );
  }
}
