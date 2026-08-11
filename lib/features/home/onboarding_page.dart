import 'package:flutter/material.dart';

import '../../core/app_constants.dart';
import '../../models/app_mode.dart';

/// App-Start: kurze Auswahl „Was möchtest du spielen?“ bei jedem Start.
class OnboardingPage extends StatelessWidget {
  final ValueChanged<AppMode> onModeSelected;
  final VoidCallback onSkip;

  const OnboardingPage({
    super.key,
    required this.onModeSelected,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.casino, size: 72, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                AppConstants.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Deine Kartenrunde. Deine Punkte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Was möchtest du spielen?',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _OnboardingOption(
                icon: Icons.style_outlined,
                title: AppMode.watten.label,
                subtitle: 'Zwei Parteien zählen bis zur Zielpunktzahl.',
                onTap: () => onModeSelected(AppMode.watten),
              ),
              const SizedBox(height: 12),
              _OnboardingOption(
                icon: Icons.casino_outlined,
                title: AppMode.mulatschak.label,
                subtitle: 'Rundenweise Punkte mit Multiplikator.',
                onTap: () => onModeSelected(AppMode.mulatschak),
              ),
              const SizedBox(height: 12),
              _OnboardingOption(
                icon: Icons.emoji_events_outlined,
                title: AppMode.hosnObe.label,
                subtitle: 'Wer seine Leben verliert, verliert.',
                onTap: () => onModeSelected(AppMode.hosnObe),
              ),
              const SizedBox(height: 12),
              _OnboardingOption(
                icon: Icons.numbers,
                title: AppMode.counter.label,
                subtitle: 'Ein freier Zähler für alles andere.',
                onTap: () => onModeSelected(AppMode.counter),
              ),
              const SizedBox(height: 28),
              TextButton(onPressed: onSkip, child: const Text('Überspringen')),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OnboardingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
