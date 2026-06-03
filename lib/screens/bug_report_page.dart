import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/url_launcher_service.dart';

class BugReportPage extends StatefulWidget {
  const BugReportPage({super.key});

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _deviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final view = View.of(context);
    final physicalSize = view.physicalSize;
    final orientation = mediaQuery.orientation.name;
    final brightness = mediaQuery.platformBrightness.name;
    final textScaler = mediaQuery.textScaler.scale(1).toStringAsFixed(2);

    return [
      '- Platform: ${defaultTargetPlatform.name}',
      '- Web: $kIsWeb',
      '- Screen size: ${mediaQuery.size.width.toStringAsFixed(0)} x ${mediaQuery.size.height.toStringAsFixed(0)} logical px',
      '- Physical size: ${physicalSize.width.toStringAsFixed(0)} x ${physicalSize.height.toStringAsFixed(0)} px',
      '- Device pixel ratio: ${mediaQuery.devicePixelRatio.toStringAsFixed(2)}',
      '- Orientation: $orientation',
      '- Brightness: $brightness',
      '- Text scale: $textScaler',
      '- Locale: ${Localizations.localeOf(context)}',
      '- Safe area padding: left ${mediaQuery.padding.left.toStringAsFixed(0)}, top ${mediaQuery.padding.top.toStringAsFixed(0)}, right ${mediaQuery.padding.right.toStringAsFixed(0)}, bottom ${mediaQuery.padding.bottom.toStringAsFixed(0)}',
    ].join('\n');
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await UrlLauncherService.openBugReport(
      context: context,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      deviceInfo: _deviceInfo(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = _deviceInfo(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Report a bug')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 6,
                maxLines: 10,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the bug.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Device information'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(deviceInfo),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _sendReport,
                icon: const Icon(Icons.send),
                label: const Text('Send bug report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
