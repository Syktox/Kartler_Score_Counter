import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_mode.dart';
import '../../models/rule_profile.dart';
import '../../screens/bug_report_page.dart';
import '../../screens/donation_page.dart';
import '../../screens/privacy_policy_page.dart';
import 'settings_controller.dart';

/// Einstellungen: Modus, Theme, Haptik, Verlauf und Regelprofil.
class SettingsPage extends StatefulWidget {
  final SettingsController settings;

  const SettingsPage({super.key, required this.settings});

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
        title: const Text('Zähler-Verlauf'),
        subtitle: const Text('Zeigt die letzten Änderungen des Zählers.'),
        value: settings.counterHistoryEnabled,
        onChanged: settings.setCounterHistoryEnabled,
      ),
      SwitchListTile(
        title: const Text('Negative Zähler erlauben'),
        subtitle: const Text('Zähler dürfen unter null fallen.'),
        value: settings.counterNegativeEnabled,
        onChanged: settings.setCounterNegativeEnabled,
      ),
      SwitchListTile(
        title: const Text('Mulatschak-Verlauf'),
        subtitle: const Text('Zeigt die letzten Punkteänderungen der Spieler.'),
        value: settings.mulatschakHistoryEnabled,
        onChanged: settings.setMulatschakHistoryEnabled,
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

    final utilitySection = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: OutlinedButton.icon(
          onPressed: () {
            widget.settings.setHasCompletedOnboarding(false);
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.style_outlined),
          label: const Text('Einführung erneut anzeigen'),
        ),
      ),
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
                      ...rulesSection,
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
              ...rulesSection,
              const Divider(),
              ...utilitySection,
            ],
          );

    return content;
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
