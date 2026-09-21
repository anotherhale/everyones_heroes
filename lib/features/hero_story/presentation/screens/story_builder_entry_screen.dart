import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/resumable_story_builder_sessions_provider.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_intent_screen.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';

/// SB.6/SB.7 entry: mode selection + resume of incomplete Builder sessions.
///
/// Guided is a complete, no-AI product path. AI uses the adaptive Story Coach.
class StoryBuilderEntryScreen extends ConsumerWidget {
  const StoryBuilderEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumableAsync = ref.watch(resumableStoryBuilderSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Build My Story'),
        key: const ValueKey('story-builder-entry-app-bar'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'How would you like to build your story?',
              key: const ValueKey('story-builder-mode-title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Everyone gets a complete Story Builder. AI makes the experience '
              'more adaptive — not more legitimate.',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            _ModeOption(
              key: const ValueKey('story-builder-mode-guided'),
              title: 'Guided Story Builder',
              subtitle:
                  'Tell your story one step at a time with thoughtful questions '
                  'that help you discover the beginning, challenge, turning '
                  'point, outcome, and meaning.',
              details: const [
                'Complete guided experience',
                'No AI required',
                'Works offline — no network or AI credits',
              ],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StoryBuilderIntentScreen(
                      mode: StoryBuilderMode.guided,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ModeOption(
              key: const ValueKey('story-builder-mode-ai'),
              title: 'AI Story Coach',
              subtitle:
                  'Have an adaptive conversation that responds to your story '
                  'and helps you explore what matters most. You remain the author.',
              details: const [
                'Adaptive questions from the AI Story Coach',
                'Your words stay exactly as you write them',
                'Requires network access to the EH AI proxy',
              ],
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StoryBuilderIntentScreen(
                      mode: StoryBuilderMode.ai,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'CONTINUE A DRAFT',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.1,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            resumableAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    key: ValueKey('story-builder-resume-loading'),
                  ),
                ),
              ),
              error: (_, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unable to load saved drafts.',
                    key: const ValueKey('story-builder-resume-error'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    key: const ValueKey('story-builder-resume-retry'),
                    onPressed: () => ref.invalidate(
                      resumableStoryBuilderSessionsProvider,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return Text(
                    'No incomplete Story Builder sessions yet.',
                    key: const ValueKey('story-builder-resume-empty'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final session in sessions)
                      _ResumeTile(
                        session: session,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => StoryBuilderScreen(
                                resumeSessionId: session.id.value,
                              ),
                            ),
                          ).then((_) {
                            ref.invalidate(
                              resumableStoryBuilderSessionsProvider,
                            );
                          });
                        },
                      ),
                  ],
                );
              },
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 10),
              for (final detail in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '· $detail',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({required this.session, required this.onTap});

  final StoryBuilderSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = session.progress.answeredCount;
    final statusLabel = session.status == StoryBuilderSessionStatus.paused
        ? 'Paused'
        : 'In progress';
    final modeLabel = session.mode == StoryBuilderMode.guided
        ? 'Guided'
        : 'AI Coach';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: ValueKey('story-builder-resume-${session.id.value}'),
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Resume draft · $modeLabel',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '$statusLabel · $answered response${answered == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// Navigates into Builder for a known session id (used by tests / deep links).
void openStoryBuilderSession(
  BuildContext context,
  StoryBuilderSessionId sessionId,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StoryBuilderScreen(resumeSessionId: sessionId.value),
    ),
  );
}
