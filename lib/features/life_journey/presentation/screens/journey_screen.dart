import 'package:flutter/material.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

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
                  'Your Journey',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your story is built one step at a time.',
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                _JourneyPath(theme: theme),
                const SizedBox(height: 32),
                _SectionLabel(label: 'CURRENT CHAPTER', theme: theme),
                const SizedBox(height: 12),
                _ChapterCard(theme: theme),
                const SizedBox(height: 32),
                _SectionLabel(label: 'NEXT STEP', theme: theme),
                const SizedBox(height: 12),
                _NextStepCard(theme: theme),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPath extends StatelessWidget {
  const _JourneyPath({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

    return Column(
      children: [
        _JourneyNode(
          title: 'Beginning',
          subtitle: 'Your journey started here.',
          state: _JourneyNodeState.completed,
          primary: primary,
          surfaceVariant: surfaceVariant,
        ),
        _JourneyConnector(color: primary),
        _JourneyNode(
          title: 'Finding Your Strength',
          subtitle: 'Discovering what helps you keep moving forward.',
          state: _JourneyNodeState.completed,
          primary: primary,
          surfaceVariant: surfaceVariant,
        ),
        _JourneyConnector(color: primary),
        _JourneyNode(
          title: 'You Are Here',
          subtitle: "Building on what you've discovered.",
          state: _JourneyNodeState.current,
          primary: primary,
          surfaceVariant: surfaceVariant,
        ),
        _JourneyConnector(color: surfaceVariant),
        _JourneyNode(
          title: "What's Next?",
          subtitle: 'The next chapter is waiting.',
          state: _JourneyNodeState.future,
          primary: primary,
          surfaceVariant: surfaceVariant,
        ),
        _JourneyConnector(color: surfaceVariant),
        _JourneyNode(
          title: 'The Road Ahead',
          subtitle: 'There is always another step.',
          state: _JourneyNodeState.future,
          primary: primary,
          surfaceVariant: surfaceVariant,
        ),
      ],
    );
  }
}

enum _JourneyNodeState { completed, current, future }

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.primary,
    required this.surfaceVariant,
  });

  final String title;
  final String subtitle;
  final _JourneyNodeState state;
  final Color primary;
  final Color surfaceVariant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrent = state == _JourneyNodeState.current;
    final isCompleted = state == _JourneyNodeState.completed;

    final nodeColor = isCurrent || isCompleted ? primary : surfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent ? theme.colorScheme.surface : nodeColor,
            border: isCurrent ? Border.all(color: primary, width: 3) : null,
          ),
          child: isCompleted
              ? Icon(Icons.check, size: 15, color: theme.colorScheme.onPrimary)
              : isCurrent
              ? Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyConnector extends StatelessWidget {
  const _JourneyConnector({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 2,
        height: 36,
        margin: const EdgeInsets.only(left: 11),
        color: color,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'Finding Your Strength',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You've been discovering what helps you keep moving forward.",
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(
                  avatar: Icon(Icons.check, size: 16),
                  label: Text('4 quests completed'),
                ),
                Chip(
                  avatar: Icon(Icons.edit_note, size: 16),
                  label: Text('3 reflections'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue today\'s journey',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Take the next meaningful step.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
