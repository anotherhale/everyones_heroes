import 'package:flutter/material.dart';

class UnderstandingScreen extends StatelessWidget {
  const UnderstandingScreen({super.key});

  static const _observations = <_UnderstandingObservation>[
    _UnderstandingObservation(
      emoji: '💪',
      title: 'You keep showing up.',
      description: 'Even when something is difficult, you have demonstrated a tendency to keep moving forward.',
    ),
    _UnderstandingObservation(
      emoji: '🔥',
      title: 'You move forward when things get difficult.',
      description: 'Your experiences suggest that challenges do not always stop you from taking the next step.',
    ),
    _UnderstandingObservation(
      emoji: '❤️',
      title: 'Helping others matters to you.',
      description: 'The things you value suggest that making a difference for other people is important to you.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Understanding',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We're starting to notice a few things about you.",
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                ..._observations.map(
                  (observation) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _UnderstandingCard(
                      observation: observation,
                      theme: theme,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'This understanding grows over time.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Every experience and reflection gives you another opportunity to discover something about yourself.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderstandingObservation {
  const _UnderstandingObservation({
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String emoji;
  final String title;
  final String description;
}

class _UnderstandingCard extends StatelessWidget {
  const _UnderstandingCard({required this.observation, required this.theme});

  final _UnderstandingObservation observation;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(observation.emoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    observation.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    observation.description,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
