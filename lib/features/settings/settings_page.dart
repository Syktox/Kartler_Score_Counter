import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_mode.dart';
import '../../models/rule_profile.dart';
import '../../persistence/backup_service.dart';
import '../../screens/bug_report_page.dart';
import '../../screens/donation_page.dart';
import '../../screens/privacy_policy_page.dart';
import 'settings_controller.dart';

/// Einstellungen: Modus, Theme, Haptik, Verlauf, Regelprofil und Backup.
class SettingsPage extends StatefulWidget {
  final SettingsController settings;
  final Future<void> Function()? onDataImported;

  const SettingsPage({super.key, required this.settings, this.onDataImported});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _wattenScoreController;
  late final TextEditingController _mulatschakStartController;
  late final TextEditingController _hosnObeLivesController;
  late final TextEditingController _muleqackTriggerController;
  late final TextEditingController _muleqackResetController;

  @override
  void initState() {
    super.initState();
    final profile = widget.settings.ruleProfile;
    _wattenScoreController = TextEditingController(
      text: profile.wattenWinningScore.toString(),
    );
    _mulatschakStartController = TextEditingController(
      text: profile.mulatschakStartingScore.toString(),
    );
    _hosnObeLivesController = TextEditingController(
      text: profile.hosnObeStartingLives.toString(),
    );
    _muleqackTriggerController = TextEditingController(
      text: profile.muleqackTriggerPoints.toString(),
    );
    _muleqackResetController = TextEditingController(
      text: profile.muleqackResetPoints.toString(),
    );
  }

  @override
  void dispose() {
    _wattenScoreController.dispose();
    _mulatschakStartController.dispose();
    _hosnObeLivesController.dispose();
    _muleqackTriggerController.dispose();
    _muleqackResetController.dispose();
    super.dispose();
  }

  RuleProfile get _profile => widget.settings.ruleProfile;

  void _commitProfile(RuleProfile profile) {
    widget.settings.setRuleProfile(profile);
  }

  int? _parsePositive(TextEditingController controller, int fallback) {
    final value = int.tryParse(controller.text);
    if (value == null || value <= 0) {
      controller.text = fallback.toString();
      return null;
    }
    return value;
  }

  void _commitWattenScore() {
    final value = _parsePositive(
      _wattenScoreController,
      _profile.wattenWinningScore,
    );
    if (value != null) {
      _commitProfile(_profile.copyWith(wattenWinningScore: value));
    }
  }

  void _commitMulatschakStart() {
    final value = _parsePositive(
      _mulatschakStartController,
      _profile.mulatschakStartingScore,
    );
    if (value != null) {
      _commitProfile(_profile.copyWith(mulatschakStartingScore: value));
    }
  }

  void _commitHosnObeLives() {
    final value = _parsePositive(
      _hosnObeLivesController,
      _profile.hosnObeStartingLives,
    );
    if (value != null) {
      _commitProfile(_profile.copyWith(hosnObeStartingLives: value));
    }
  }

  void _commitMuleqackTrigger() {
    final value = _parsePositive(
      _muleqackTriggerController,
      _profile.muleqackTriggerPoints,
    );
    if (value != null) {
      _commitProfile(_profile.copyWith(muleqackTriggerPoints: value));
    }
  }

  void _commitMuleqackReset() {
    final value = int.tryParse(_muleqackResetController.text);
    if (value == null || value < 0) {
      _muleqackResetController.text = _profile.muleqackResetPoints.toString();
      return;
    }
    _commitProfile(_profile.copyWith(muleqackResetPoints: value));
  }

  // MARK: - Backup

  Future<void> _exportBackup() async {
    final json = await const BackupService().exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup in die Zwischenablage kopiert.')),
    );
  }

  Future<void> _importBackup() async {
    String? clipboardText;
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      clipboardText = clipboard?.text;
    } catch (_) {
      clipboardText = null;
    }
    if (!mounted) {
      return;
    }
    final json = await showDialog<String>(
      context: context,
      builder: (_) => _BackupImportDialog(initialText: clipboardText ?? ''),
    );
    if (json == null || json.trim().isEmpty || !mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Daten ersetzen?'),
        content: const Text(
          'Achtung: Beim Import werden alle aktuellen Spieler, Partien, '
          'Spielabende und Einstellungen durch die Daten aus dem Backup '
          'ersetzt. Dieser Vorgang kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Importieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await const BackupService().importJson(json.trim());
    } on BackupException catch (error) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Import fehlgeschlagen'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup erfolgreich wiederhergestellt.')),
    );
    Navigator.of(context).pop();
    await widget.onDataImported?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (context, _) => _buildContent(context),
        ),
      ),
    );
  }

  /// Baut den Inhalt bei jeder Controller-Änderung neu, damit Umschalter und
  /// Radio-Auswahl den aktuellen Einstellungen entsprechen.
  Widget _buildContent(BuildContext context) {
    final settings = widget.settings;
    final profile = _profile;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final modeSection = <Widget>[
      const _SectionHeader(title: 'Spielmodus'),
      RadioGroup<AppMode>(
        groupValue: settings.appMode,
        onChanged: (value) {
          if (value != null) {
            settings.setAppMode(value);
          }
        },
        child: Column(
          children: [
            for (final mode in AppMode.values)
              RadioListTile<AppMode>(title: Text(mode.label), value: mode),
          ],
        ),
      ),
    ];

    final appearanceSection = <Widget>[
      const _SectionHeader(title: 'Darstellung'),
      RadioGroup<ThemeMode>(
        groupValue: settings.themeMode,
        onChanged: (value) {
          if (value != null) {
            settings.setThemeMode(value);
          }
        },
        child: const Column(
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Hell'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Dunkel'),
              value: ThemeMode.dark,
            ),
            RadioListTile<ThemeMode>(
              title: Text('System'),
              value: ThemeMode.system,
            ),
          ],
        ),
      ),
      SwitchListTile(
        title: const Text('Haptisches Feedback'),
        subtitle: const Text('Leichtes Vibrieren bei Eingaben und Siegen.'),
        value: settings.hapticsEnabled,
        onChanged: settings.setHapticsEnabled,
      ),
      SwitchListTile(
        title: const Text('Watten-Tischmodus'),
        subtitle: const Text(
          'Im Querformat einander gegenüberliegende Seiten.',
        ),
        value: settings.wattenTableMode,
        onChanged: settings.setWattenTableMode,
      ),
    ];

    final historySection = <Widget>[
      const _SectionHeader(title: 'Verlauf'),
      SwitchListTile(
        title: const Text('Zähler-Verlauf anzeigen'),
        subtitle: const Text(
          'Der Verlauf wird immer aufgezeichnet. Diese Einstellung blendet ihn ein.',
        ),
        value: settings.counterHistoryEnabled,
        onChanged: settings.setCounterHistoryEnabled,
      ),
      SwitchListTile(
        title: const Text('Watten-Verlauf anzeigen'),
        subtitle: const Text(
          'Der Verlauf wird immer aufgezeichnet. Diese Einstellung blendet ihn ein.',
        ),
        value: settings.wattenHistoryEnabled,
        onChanged: settings.setWattenHistoryEnabled,
      ),
      SwitchListTile(
        title: const Text('Mulatschak-Verlauf anzeigen'),
        subtitle: const Text(
          'Der Verlauf wird immer aufgezeichnet. Eine neue Runde beginnt, sobald alle Spieler Punkte erhalten haben.',
        ),
        value: settings.mulatschakHistoryEnabled,
        onChanged: settings.setMulatschakHistoryEnabled,
      ),
    ];

    final counterSection = <Widget>[
      const _SectionHeader(title: 'Zähler'),
      SwitchListTile(
        title: const Text('Negative Zähler erlauben'),
        subtitle: const Text('Zähler dürfen unter null fallen.'),
        value: settings.counterNegativeEnabled,
        onChanged: settings.setCounterNegativeEnabled,
      ),
    ];

    final safetySection = <Widget>[
      const _SectionHeader(title: 'Sicherheit'),
      SwitchListTile(
        title: const Text('Spieler-Löschen bestätigen'),
        subtitle: const Text(
          'Fragt vor dem Löschen eines Spielers nach. Ausgeschaltet wird sofort gelöscht.',
        ),
        value: settings.playerDeleteConfirmationEnabled,
        onChanged: settings.setPlayerDeleteConfirmationEnabled,
      ),
    ];

    final rulesSection = <Widget>[
      const _SectionHeader(title: 'Regelprofil'),
      _NumberField(
        label: 'Watten: Siegpunktzahl',
        hint: 'z. B. 11',
        controller: _wattenScoreController,
        onCommit: _commitWattenScore,
      ),
      _NumberField(
        label: 'Mulatschak: Startpunkte',
        hint: 'z. B. 21',
        controller: _mulatschakStartController,
        onCommit: _commitMulatschakStart,
      ),
      _NumberField(
        label: 'Hosn Obe: Startleben',
        hint: 'z. B. 4',
        controller: _hosnObeLivesController,
        onCommit: _commitHosnObeLives,
      ),
      SwitchListTile(
        title: const Text('Mulatschak-Reset (Muleqack)'),
        subtitle: const Text(
          'Setzt einen Spieler automatisch zurück, wenn die gewählte Punktzahl erreicht wird.',
        ),
        value: profile.muleqackEnabled,
        onChanged: (enabled) {
          _commitProfile(profile.copyWith(muleqackEnabled: enabled));
        },
      ),
      _NumberField(
        label: 'Reset bei Punktzahl',
        hint: 'z. B. 100',
        controller: _muleqackTriggerController,
        onCommit: _commitMuleqackTrigger,
      ),
      _NumberField(
        label: 'Zurücksetzen auf',
        hint: 'z. B. 50',
        controller: _muleqackResetController,
        onCommit: _commitMuleqackReset,
      ),
      SwitchListTile(
        title: const Text('Mulatschak-Stiche automatisch erkennen'),
        subtitle: const Text(
          'Nach 5 Stichen erhalten nur offene Spieler automatisch +5. +1 bedeutet gegangen; +5 als erster Eintrag deaktiviert die Automatik bis zur nächsten Runde.',
        ),
        value: profile.mulatschakAutoCompleteRound,
        onChanged: (enabled) {
          _commitProfile(
            profile.copyWith(mulatschakAutoCompleteRound: enabled),
          );
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: OutlinedButton.icon(
          onPressed: () {
            widget.settings.resetRuleProfile();
            final reset = widget.settings.ruleProfile;
            _wattenScoreController.text = reset.wattenWinningScore.toString();
            _mulatschakStartController.text = reset.mulatschakStartingScore
                .toString();
            _hosnObeLivesController.text = reset.hosnObeStartingLives
                .toString();
            _muleqackTriggerController.text = reset.muleqackTriggerPoints
                .toString();
            _muleqackResetController.text = reset.muleqackResetPoints
                .toString();
          },
          icon: const Icon(Icons.restart_alt),
          label: const Text('Regeln zurücksetzen'),
        ),
      ),
    ];

    final backupSection = <Widget>[
      const _SectionHeader(title: 'Daten & Backup'),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: OutlinedButton.icon(
          onPressed: _exportBackup,
          icon: const Icon(Icons.file_upload_outlined),
          label: const Text('Backup exportieren'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: OutlinedButton.icon(
          onPressed: _importBackup,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Backup wiederherstellen'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Backups enthalten Spieler, Partien, Spielabende, Einstellungen '
          'und Spielstände. Ein Export wird als JSON in die Zwischenablage '
          'kopiert.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ];

    final utilitySection = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
            );
          },
          icon: const Icon(Icons.privacy_tip_outlined),
          label: const Text('Datenschutz'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => DonationPage()));
          },
          icon: const Icon(Icons.favorite_outline),
          label: const Text('Spenden'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BugReportPage()));
          },
          icon: const Icon(Icons.bug_report_outlined),
          label: const Text('Fehler melden'),
        ),
      ),
    ];

    final content = isLandscape
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...modeSection,
                      const Divider(),
                      ...appearanceSection,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...historySection,
                      const Divider(),
                      ...counterSection,
                      const Divider(),
                      ...safetySection,
                      const Divider(),
                      ...rulesSection,
                      const Divider(),
                      ...backupSection,
                      const Divider(),
                      ...utilitySection,
                    ],
                  ),
                ),
              ],
            ),
          )
        : ListView(
            children: [
              ...modeSection,
              const Divider(),
              ...appearanceSection,
              const Divider(),
              ...historySection,
              const Divider(),
              ...counterSection,
              const Divider(),
              ...safetySection,
              const Divider(),
              ...rulesSection,
              const Divider(),
              ...backupSection,
              const Divider(),
              ...utilitySection,
            ],
          );

    return content;
  }
}

/// Dialog zum Einfügen eines Backup-JSONs.
///
/// Eigener StatefulWidget, damit der TextEditingController erst entsorgt
/// wird, wenn auch die Dialog-Animation abgeschlossen ist.
class _BackupImportDialog extends StatefulWidget {
  final String initialText;

  const _BackupImportDialog({required this.initialText});

  @override
  State<_BackupImportDialog> createState() => _BackupImportDialogState();
}

class _BackupImportDialogState extends State<_BackupImportDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup wiederherstellen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Füge hier das Backup-JSON ein. Ein Backup bekommst du über '
            '„Backup exportieren“.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 8,
            minLines: 4,
            decoration: const InputDecoration(
              hintText: 'Backup-JSON einfügen …',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final VoidCallback onCommit;

  const _NumberField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => onCommit(),
        onTapOutside: (_) => onCommit(),
      ),
    );
  }
}
