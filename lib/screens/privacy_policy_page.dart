import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        top: false,
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Last updated: August 6, 2026'),
            SizedBox(height: 24),
            _PrivacySection(
              title: 'Data stored by the app',
              body:
                  'Kartler stores game state locally on your device with '
                  'shared_preferences. This can include counter names and '
                  'values, Watten game scores, Mulatschak player scores and '
                  'history, and app settings such as mode and theme.',
            ),
            _PrivacySection(
              title: 'Local storage',
              body:
                  'This data stays on your device. Kartler does not send '
                  'saved scores, names, settings, or history entries to the '
                  'developer or to an external server.',
            ),
            _PrivacySection(
              title: 'Store donations',
              body:
                  'Optional donations are handled by the store billing '
                  'system. The store processes the payment and may provide '
                  'purchase status updates to the app so the transaction can '
                  'be completed.',
            ),
            _PrivacySection(
              title: 'External links',
              body:
                  'Kartler may open external links, such as bug report '
                  'links, with url_launcher. When you open an external link, '
                  'your browser or the target app handles that website or '
                  'service.',
            ),
            _PrivacySection(
              title: 'Analytics and tracking',
              body:
                  'Kartler does not include analytics, advertising SDKs, '
                  'or third-party tracking SDKs.',
            ),
            _PrivacySection(
              title: 'Data deletion',
              body:
                  'You can delete stored game data by using the app '
                  'controls where available. You can also clear all app data '
                  'through your device settings or uninstall the app.',
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;

  const _PrivacySection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}
