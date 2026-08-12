import 'package:flutter/material.dart';

import '../../models/app_mode.dart';
import '../../models/game_session.dart';

class HubPage extends StatelessWidget {
  final GameSession? activeSession;
  final List<String> sessionParticipantNames;
  final VoidCallback onStartSession;
  final VoidCallback onEndSession;
  final ValueChanged<AppMode> onModeSelected;
  final VoidCallback onOpenStatistics;
  final VoidCallback onOpenPlayers;
  final int pastSessionCount;

  const HubPage({
    super.key,
    required this.activeSession,
    required this.sessionParticipantNames,
    required this.onStartSession,
    required this.onEndSession,
    required this.onModeSelected,
    required this.onOpenStatistics,
    required this.onOpenPlayers,
    required this.pastSessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Servus! Was möchtest du spielen?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Wähle einen Spielmodus oder starte einen Spielabend.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Spielmodus'),
          const SizedBox(height: 8),
          _ModeCard(
            icon: Icons.style_outlined,
            title: AppMode.watten.label,
            subtitle:
                'Zwei Parteien, schnell gezählt – perfekt für zwischendurch.',
            onTap: () => onModeSelected(AppMode.watten),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.casino_outlined,
            title: AppMode.mulatschak.label,
            subtitle: 'Rundenweise Punkte mit Multiplikator und Muleqack.',
            onTap: () => onModeSelected(AppMode.mulatschak),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: Icons.emoji_events_outlined,
            title: AppMode.hosnObe.label,
            subtitle: 'Wer die letzten Leben verliert, verliert die Partie.',
            onTap: () => onModeSelected(AppMode.hosnObe),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Freier Zähler'),
          const SizedBox(height: 8),
          _ModeCard(
            icon: Icons.numbers,
            title: AppMode.counter.label,
            subtitle: 'Freier Zähler für alles andere.',
            onTap: () => onModeSelected(AppMode.counter),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Spielabend'),
          const SizedBox(height: 8),
          if (activeSession != null)
            _SessionCard(
              participants: sessionParticipantNames,
              onEnd: onEndSession,
            )
          else
            _ActionCard(
              icon: Icons.nights_stay_outlined,
              title: 'Spielabend starten',
              subtitle: pastSessionCount == 0
                  ? 'Sammle Partien und sehe danach die Zusammenfassung.'
                  : 'Bereits $pastSessionCount Spielabende abgeschlossen.',
              onTap: onStartSession,
            ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Mehr'),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.bar_chart_outlined,
            title: 'Statistiken',
            subtitle: 'Siege, Winrate und mehr aus deiner Match-History.',
            onTap: onOpenStatistics,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.groups_outlined,
            title: 'Spieler verwalten',
            subtitle: 'Globale Spieler für alle Spielmodi.',
            onTap: onOpenPlayers,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
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
          radius: 26,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(icon, size: 28, color: colorScheme.onPrimaryContainer),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
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
          radius: 26,
          backgroundColor: colorScheme.secondaryContainer,
          child: Icon(icon, size: 26, color: colorScheme.onSecondaryContainer),
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

class _SessionCard extends StatelessWidget {
  final List<String> participants;
  final VoidCallback onEnd;

  const _SessionCard({required this.participants, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final participantText = participants.isEmpty
        ? 'Keine Teilnehmer gewählt'
        : participants.join(', ');

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.nights_stay, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Spielabend läuft',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Teilnehmer: $participantText',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              'Spiele eine Partie und schließe sie über das Trophäen-Symbol ab. Danach kannst du den Spielabend hier beenden.',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onEnd,
              icon: const Icon(Icons.flag),
              label: const Text('Spielabend beenden'),
            ),
          ],
        ),
      ),
    );
  }
}
