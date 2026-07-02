import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import 'bug_report_page.dart';

class SettingsPage extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final AppMode currentAppMode;
  final ValueChanged<AppMode> onAppModeChanged;
  final bool muleqackEnabled;
  final int muleqackTriggerPoints;
  final int muleqackResetPoints;
  final bool counterHistoryEnabled;
  final bool counterNegativeEnabled;
  final bool mulatschakHistoryEnabled;
  final ValueChanged<bool> onMuleqackEnabledChanged;
  final ValueChanged<int> onMuleqackTriggerPointsChanged;
  final ValueChanged<int> onMuleqackResetPointsChanged;
  final ValueChanged<bool> onCounterHistoryEnabledChanged;
  final ValueChanged<bool> onCounterNegativeEnabledChanged;
  final ValueChanged<bool> onMulatschakHistoryEnabledChanged;

  const SettingsPage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeModeChanged,
    required this.currentAppMode,
    required this.onAppModeChanged,
    required this.muleqackEnabled,
    required this.muleqackTriggerPoints,
    required this.muleqackResetPoints,
    required this.counterHistoryEnabled,
    required this.counterNegativeEnabled,
    required this.mulatschakHistoryEnabled,
    required this.onMuleqackEnabledChanged,
    required this.onMuleqackTriggerPointsChanged,
    required this.onMuleqackResetPointsChanged,
    required this.onCounterHistoryEnabledChanged,
    required this.onCounterNegativeEnabledChanged,
    required this.onMulatschakHistoryEnabledChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _triggerController;
  late final TextEditingController _resetController;
  late bool _muleqackEnabled;
  late int _muleqackTriggerPoints;
  late int _muleqackResetPoints;
  late bool _counterHistoryEnabled;
  late bool _counterNegativeEnabled;
  late bool _mulatschakHistoryEnabled;

  @override
  void initState() {
    super.initState();
    _muleqackEnabled = widget.muleqackEnabled;
    _muleqackTriggerPoints = widget.muleqackTriggerPoints;
    _muleqackResetPoints = widget.muleqackResetPoints;
    _counterHistoryEnabled = widget.counterHistoryEnabled;
    _counterNegativeEnabled = widget.counterNegativeEnabled;
    _mulatschakHistoryEnabled = widget.mulatschakHistoryEnabled;
    _triggerController = TextEditingController(
      text: _muleqackTriggerPoints.toString(),
    );
    _resetController = TextEditingController(
      text: _muleqackResetPoints.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.muleqackEnabled != widget.muleqackEnabled) {
      _muleqackEnabled = widget.muleqackEnabled;
    }

    if (oldWidget.muleqackTriggerPoints != widget.muleqackTriggerPoints) {
      _muleqackTriggerPoints = widget.muleqackTriggerPoints;
      if (_triggerController.text != _muleqackTriggerPoints.toString()) {
        _triggerController.text = _muleqackTriggerPoints.toString();
      }
    }

    if (oldWidget.muleqackResetPoints != widget.muleqackResetPoints) {
      _muleqackResetPoints = widget.muleqackResetPoints;
      if (_resetController.text != _muleqackResetPoints.toString()) {
        _resetController.text = _muleqackResetPoints.toString();
      }
    }

    if (oldWidget.counterHistoryEnabled != widget.counterHistoryEnabled) {
      _counterHistoryEnabled = widget.counterHistoryEnabled;
    }

    if (oldWidget.counterNegativeEnabled != widget.counterNegativeEnabled) {
      _counterNegativeEnabled = widget.counterNegativeEnabled;
    }

    if (oldWidget.mulatschakHistoryEnabled != widget.mulatschakHistoryEnabled) {
      _mulatschakHistoryEnabled = widget.mulatschakHistoryEnabled;
    }
  }

  @override
  void dispose() {
    _triggerController.dispose();
    _resetController.dispose();
    super.dispose();
  }

  void _updateTriggerPoints(int points) {
    setState(() {
      _muleqackTriggerPoints = points;
    });

    widget.onMuleqackTriggerPointsChanged(points);
  }

  void _updateResetPoints(int points) {
    setState(() {
      _muleqackResetPoints = points;
    });

    widget.onMuleqackResetPointsChanged(points);
  }

  void _submitTriggerPoints() {
    final parsedValue = int.tryParse(_triggerController.text);
    if (parsedValue != null && parsedValue > 0) {
      _updateTriggerPoints(parsedValue);
      return;
    }

    _triggerController.text = _muleqackTriggerPoints.toString();
  }

  void _submitResetPoints() {
    final parsedValue = int.tryParse(_resetController.text);
    if (parsedValue != null && parsedValue >= 0) {
      _updateResetPoints(parsedValue);
      return;
    }

    _resetController.text = _muleqackResetPoints.toString();
  }

  @override
  Widget build(BuildContext context) {
    final showMuleqackSettings = widget.currentAppMode == AppMode.mulatschak;
    final showCounterSettings = widget.currentAppMode == AppMode.counter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          children: [
            const ListTile(title: Text('Modus')),
            RadioGroup<AppMode>(
              groupValue: widget.currentAppMode,
              onChanged: (value) {
                if (value != null) {
                  widget.onAppModeChanged(value);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<AppMode>(
                    title: Text('Counter'),
                    value: AppMode.counter,
                  ),
                  RadioListTile<AppMode>(
                    title: Text('Watten'),
                    value: AppMode.watten,
                  ),
                  RadioListTile<AppMode>(
                    title: Text('Mulatschak'),
                    value: AppMode.mulatschak,
                  ),
                  RadioListTile<AppMode>(
                    title: Text('Hosn Obe'),
                    value: AppMode.hosnObe,
                  ),
                ],
              ),
            ),
            if (showCounterSettings) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Allow negative counters'),
                subtitle: const Text('Let counters go below zero.'),
                value: _counterNegativeEnabled,
                onChanged: (value) {
                  setState(() {
                    _counterNegativeEnabled = value;
                  });
                  widget.onCounterNegativeEnabledChanged(value);
                },
              ),
              SwitchListTile(
                title: const Text('Counter history'),
                subtitle: const Text(
                  'Shows a history button with the latest counter changes.',
                ),
                value: _counterHistoryEnabled,
                onChanged: (value) {
                  setState(() {
                    _counterHistoryEnabled = value;
                  });
                  widget.onCounterHistoryEnabledChanged(value);
                },
              ),
            ],
            if (showMuleqackSettings) ...[
              const Divider(),
              SwitchListTile(
                title: const Text('Mulatschak history'),
                subtitle: const Text(
                  'Shows a history button with the latest player changes.',
                ),
                value: _mulatschakHistoryEnabled,
                onChanged: (value) {
                  setState(() {
                    _mulatschakHistoryEnabled = value;
                  });
                  widget.onMulatschakHistoryEnabledChanged(value);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Mulatschak reset'),
                subtitle: const Text(
                  'Automatically resets a player when the configured score is reached.',
                ),
                value: _muleqackEnabled,
                onChanged: (value) {
                  setState(() {
                    _muleqackEnabled = value;
                  });
                  widget.onMuleqackEnabledChanged(value);
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _triggerController,
                  enabled: _muleqackEnabled,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reset when score reaches',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitTriggerPoints(),
                  onTapOutside: (_) => _submitTriggerPoints(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _resetController,
                  enabled: _muleqackEnabled,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reset score to',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitResetPoints(),
                  onTapOutside: (_) => _submitResetPoints(),
                ),
              ),
            ],
            const Divider(),
            RadioGroup<ThemeMode>(
              groupValue: widget.currentThemeMode,
              onChanged: (value) {
                if (value != null) {
                  widget.onThemeModeChanged(value);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text('Light Mode'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Dark Mode'),
                    value: ThemeMode.dark,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('System Mode'),
                    value: ThemeMode.system,
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BugReportPage()),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('Report a bug'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
