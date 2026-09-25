import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/presentation/models/captured_story_reading_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/hero_story_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/story_experience_plan_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/story_voice_rendering_view_data.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_lab_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_plan_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_experience_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_playback_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_provider.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_understanding_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/hero_story_voice_rendering_controller.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/owned_story_detail_screen.dart';

/// Hero-owned presentation of a saved Story.
///
/// The canonical Story is unchanged. This screen plays the original recording
/// and optionally surfaces a grounded captured-story reading (HS.12.3), a
/// derived Story Experience Plan (HS.12.4), playable experience presentation
/// (HS.12.5), an explicitly authorized derived voice rendering (HS.12.6), and
/// an experimental AI Experience Laboratory action (Experiment A).
class HeroStoryScreen extends ConsumerWidget {
  const HeroStoryScreen({required this.storyId, super.key});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final storyAsync = ref.watch(heroStoryProvider(storyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero Story'),
        key: const ValueKey('hero-story-app-bar'),
      ),
      body: SafeArea(
        child: storyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              key: ValueKey('hero-story-loading'),
            ),
          ),
          error: (error, _) => _HeroStoryMessage(
            message: 'Unable to open this story.',
            messageKey: const ValueKey('hero-story-load-error'),
            onRetry: () => ref.invalidate(heroStoryProvider(storyId)),
          ),
          data: (story) =>
              _HeroStoryBody(storyId: storyId, story: story, theme: theme),
        ),
      ),
    );
  }
}

class _HeroStoryBody extends ConsumerWidget {
  const _HeroStoryBody({
    required this.storyId,
    required this.story,
    required this.theme,
  });

  final String storyId;
  final HeroStoryViewData story;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(heroStoryPlaybackProvider(storyId));
    final playbackController = ref.read(
      heroStoryPlaybackProvider(storyId).notifier,
    );
    final understanding = ref.watch(heroStoryUnderstandingProvider(storyId));
    final understandingController = ref.read(
      heroStoryUnderstandingProvider(storyId).notifier,
    );
    final experiencePlan = ref.watch(heroStoryExperiencePlanProvider(storyId));
    final experiencePlanController = ref.read(
      heroStoryExperiencePlanProvider(storyId).notifier,
    );
    // Only bind the experience player when a plan exists so earlier Hero Story
    // surfaces (HS.12.2 / HS.12.3) do not construct just_audio experience players.
    final hasExperiencePlan = experiencePlan.plan != null;
    final experiencePlayback = hasExperiencePlan
        ? ref.watch(heroStoryExperiencePlaybackProvider(storyId))
        : const HeroStoryExperiencePlaybackState();
    final voiceRendering = hasExperiencePlan
        ? ref.watch(heroStoryVoiceRenderingProvider(storyId))
        : const HeroStoryVoiceRenderingState();
    final experienceLab = hasExperiencePlan
        ? ref.watch(heroStoryExperienceLabProvider(storyId))
        : const HeroStoryExperienceLabState();
    final recordingId = story.originalRecordingId;

    Future<void> stopExperienceIfBound() async {
      if (!hasExperiencePlan) {
        return;
      }
      await ref
          .read(heroStoryExperiencePlaybackProvider(storyId).notifier)
          .stop();
    }

    Future<void> stopNarratedIfBound() async {
      if (!hasExperiencePlan) {
        return;
      }
      await ref.read(heroStoryVoiceRenderingProvider(storyId).notifier).stop();
    }

    Future<void> stopLabIfBound() async {
      if (!hasExperiencePlan) {
        return;
      }
      await ref.read(heroStoryExperienceLabProvider(storyId).notifier).stop();
    }

    return ListView(
      key: const ValueKey('hero-story-screen'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      children: [
        Text(
          'HERO STORY',
          key: const ValueKey('hero-story-kicker'),
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.4,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: CircleAvatar(
            key: const ValueKey('hero-story-monogram'),
            radius: 48,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text(
              story.monogram,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          story.heroName,
          key: const ValueKey('hero-story-name'),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        Text(
          story.title,
          key: const ValueKey('hero-story-title'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Original recording',
          key: const ValueKey('hero-story-original-label'),
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (recordingId == null)
          Text(
            'No original recording is available.',
            key: const ValueKey('hero-story-no-recording'),
            style: theme.textTheme.bodyLarge,
          )
        else ...[
          if (playback.errorMessage != null) ...[
            Text(
              playback.errorMessage!,
              key: const ValueKey('hero-story-playback-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const ValueKey('hero-story-play-button'),
            onPressed: playback.isBusy
                ? null
                : () async {
                    await stopExperienceIfBound();
                    await stopNarratedIfBound();
                    await stopLabIfBound();
                    if (playback.phase == HeroStoryPlaybackPhase.playing) {
                      await playbackController.pause();
                    } else {
                      await playbackController.playOriginal(
                        representationId: recordingId,
                      );
                    }
                  },
            icon: Icon(
              playback.phase == HeroStoryPlaybackPhase.playing
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
            label: Text(_playLabel(playback.phase)),
          ),
          if (playback.phase == HeroStoryPlaybackPhase.playing ||
              playback.phase == HeroStoryPlaybackPhase.paused) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('hero-story-stop-button'),
              onPressed: playback.isBusy ? null : playbackController.stop,
              child: const Text('Stop'),
            ),
          ],
        ],
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const ValueKey('hero-story-understand-button'),
          onPressed: understanding.isProcessing
              ? null
              : () => understandingController.understand(
                    isRetry: understanding.phase ==
                        HeroStoryUnderstandingPhase.failed,
                  ),
          icon: understanding.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(
            understanding.phase == HeroStoryUnderstandingPhase.failed
                ? 'Retry understanding'
                : understanding.phase == HeroStoryUnderstandingPhase.ready
                    ? 'Refresh understanding'
                    : 'Understand my story',
          ),
        ),
        if (understanding.isProcessing) ...[
          const SizedBox(height: 16),
          Text(
            HeroStoryUnderstandingController.processingMessage,
            key: const ValueKey('hero-story-understanding-processing'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (understanding.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            understanding.errorMessage!,
            key: const ValueKey('hero-story-understanding-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your original recording is still available.',
            key: const ValueKey('hero-story-understanding-error-recording'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (understanding.reading != null) ...[
          const SizedBox(height: 28),
          _CapturedStoryReadingSection(
            reading: understanding.reading!,
            theme: theme,
          ),
        ],
        if (understanding.reading != null) ...[
          const SizedBox(height: 20),
          if (experiencePlan.plan == null)
            OutlinedButton.icon(
              key: const ValueKey('hero-story-create-experience-button'),
              onPressed: experiencePlan.canCreate
                  ? () => experiencePlanController.create(
                        isRetry: experiencePlan.phase ==
                            HeroStoryExperiencePlanPhase.failed,
                      )
                  : null,
              icon: experiencePlan.isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                experiencePlan.phase == HeroStoryExperiencePlanPhase.failed
                    ? 'Retry experience plan'
                    : 'Create my experience',
              ),
            )
          else ...[
            OutlinedButton.icon(
              key: const ValueKey('hero-story-create-experience-button'),
              onPressed: experiencePlan.canCreate
                  ? () => experiencePlanController.create(isRetry: false)
                  : null,
              icon: experiencePlan.isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                experiencePlan.isGenerating
                    ? 'Refreshing experience plan'
                    : 'Refresh experience plan',
              ),
            ),
            if (recordingId != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const ValueKey('hero-story-play-experience-button'),
                onPressed: experiencePlayback.isBusy ||
                        experiencePlan.isGenerating
                    ? null
                    : () async {
                        final controller = ref.read(
                          heroStoryExperiencePlaybackProvider(storyId).notifier,
                        );
                        await stopNarratedIfBound();
                        await stopLabIfBound();
                        if (experiencePlayback.phase ==
                            HeroStoryExperiencePlaybackPhase.playing) {
                          await controller.pause();
                        } else if (experiencePlayback.phase ==
                            HeroStoryExperiencePlaybackPhase.paused) {
                          await controller.resume(
                            originalRecordingId: recordingId,
                          );
                        } else {
                          await controller.playExperience(
                            originalRecordingId: recordingId,
                          );
                        }
                      },
                icon: Icon(
                  experiencePlayback.phase ==
                          HeroStoryExperiencePlaybackPhase.playing
                      ? Icons.pause
                      : Icons.headphones,
                ),
                label: Text(_experiencePlayLabel(experiencePlayback.phase)),
              ),
              if (experiencePlayback.isActive) ...[
                const SizedBox(height: 8),
                TextButton(
                  key: const ValueKey('hero-story-experience-stop-button'),
                  onPressed: experiencePlayback.isBusy
                      ? null
                      : () => ref
                          .read(
                            heroStoryExperiencePlaybackProvider(storyId)
                                .notifier,
                          )
                          .stop(),
                  child: const Text('Stop experience'),
                ),
              ],
              if (experiencePlayback.purposeLabel != null &&
                  experiencePlayback.isActive) ...[
                const SizedBox(height: 8),
                Text(
                  experiencePlayback.purposeLabel!,
                  key: const ValueKey('hero-story-experience-playback-purpose'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ],
          if (experiencePlan.isGenerating) ...[
            const SizedBox(height: 16),
            Text(
              HeroStoryExperiencePlanController.generatingMessage,
              key: const ValueKey('hero-story-experience-generating'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (experiencePlan.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              experiencePlan.errorMessage!,
              key: const ValueKey('hero-story-experience-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your original recording is still available.',
              key: const ValueKey('hero-story-experience-error-recording'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (experiencePlayback.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              experiencePlayback.errorMessage!,
              key: const ValueKey('hero-story-experience-playback-error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your original recording is still available.',
              key: const ValueKey(
                'hero-story-experience-playback-error-recording',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (experiencePlan.plan != null) ...[
            const SizedBox(height: 28),
            _StoryExperiencePlanSection(
              plan: experiencePlan.plan!,
              theme: theme,
            ),
            const SizedBox(height: 28),
            _StoryVoiceRenderingSection(
              storyId: storyId,
              state: voiceRendering,
              theme: theme,
            ),
            const SizedBox(height: 28),
            _StoryExperienceLabSection(
              storyId: storyId,
              recordingId: recordingId?.value,
              state: experienceLab,
              theme: theme,
            ),
          ],
        ],
        const SizedBox(height: 28),
        Text(
          'A real story from a real person',
          key: const ValueKey('hero-story-tagline'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const ValueKey('hero-story-details-button'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OwnedStoryDetailScreen(storyId: storyId),
                ),
              );
            },
            child: const Text('Story details'),
          ),
        ),
      ],
    );
  }

  static String _playLabel(HeroStoryPlaybackPhase phase) {
    return switch (phase) {
      HeroStoryPlaybackPhase.playing => 'Pause',
      HeroStoryPlaybackPhase.paused => 'Resume',
      HeroStoryPlaybackPhase.idle ||
      HeroStoryPlaybackPhase.loading ||
      HeroStoryPlaybackPhase.completed ||
      HeroStoryPlaybackPhase.failed =>
        'Play my recording',
    };
  }

  static String _experiencePlayLabel(HeroStoryExperiencePlaybackPhase phase) {
    return switch (phase) {
      HeroStoryExperiencePlaybackPhase.playing => 'Pause experience',
      HeroStoryExperiencePlaybackPhase.paused => 'Resume experience',
      HeroStoryExperiencePlaybackPhase.silenced => 'Pause experience',
      HeroStoryExperiencePlaybackPhase.loading => 'Loading experience…',
      HeroStoryExperiencePlaybackPhase.idle ||
      HeroStoryExperiencePlaybackPhase.completed ||
      HeroStoryExperiencePlaybackPhase.failed =>
        'Play my experience',
    };
  }
}

class _CapturedStoryReadingSection extends StatelessWidget {
  const _CapturedStoryReadingSection({
    required this.reading,
    required this.theme,
  });

  final CapturedStoryReadingViewData reading;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hero-story-reading-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Story Understanding',
          key: const ValueKey('hero-story-reading-title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Grounded in your transcript — not a rewrite of your story.',
          key: const ValueKey('hero-story-reading-subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-movement'),
          label: 'Movement',
          element: reading.movement,
          theme: theme,
        ),
        _ReadingThemesTile(
          key: const ValueKey('hero-story-reading-themes'),
          themes: reading.themes,
          theme: theme,
        ),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-challenge'),
          label: 'Challenge',
          element: reading.challenge,
          theme: theme,
        ),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-turning-point'),
          label: 'Turning point',
          element: reading.turningPoint,
          theme: theme,
        ),
        _ReadingElementTile(
          key: const ValueKey('hero-story-reading-outcome'),
          label: 'Outcome',
          element: reading.outcome,
          theme: theme,
        ),
      ],
    );
  }
}

class _ReadingElementTile extends StatelessWidget {
  const _ReadingElementTile({
    required this.label,
    required this.element,
    required this.theme,
    super.key,
  });

  final String label;
  final GroundedElementViewData element;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(element.text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 2),
          Text(
            'Source ${element.spanLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingThemesTile extends StatelessWidget {
  const _ReadingThemesTile({
    required this.themes,
    required this.theme,
    super.key,
  });

  final List<GroundedThemeViewData> themes;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Themes',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in themes) ...[
            Text(item.label, style: theme.textTheme.bodyLarge),
            Text(
              'Source ${item.spanLabel}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _StoryExperiencePlanSection extends StatelessWidget {
  const _StoryExperiencePlanSection({
    required this.plan,
    required this.theme,
  });

  final StoryExperiencePlanViewData plan;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hero-story-experience-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience Plan',
          key: const ValueKey('hero-story-experience-title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Derived presentation guidance — Play my experience renders this '
          'plan over your original recording. Your story is not rewritten.',
          key: const ValueKey('hero-story-experience-subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _PlanLabeledText(
          key: const ValueKey('hero-story-experience-intention'),
          label: 'Intention',
          value: plan.intentionLabel,
          theme: theme,
        ),
        _PlanLabeledText(
          key: const ValueKey('hero-story-experience-arc'),
          label: 'Arc',
          value: plan.arcLabel,
          theme: theme,
        ),
        _PlanLabeledText(
          key: const ValueKey('hero-story-experience-core-message'),
          label: 'Core message',
          value: plan.coreMessage,
          theme: theme,
        ),
        Text(
          'Key moments',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        for (var i = 0; i < plan.keyMoments.length; i++) ...[
          Text(
            plan.keyMoments[i].description,
            key: ValueKey('hero-story-experience-moment-$i'),
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            'Source ${plan.keyMoments[i].spanLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _PlanLabeledText(
          key: const ValueKey('hero-story-experience-reflection'),
          label: 'Reflection prompt',
          value: plan.reflectionPrompt,
          theme: theme,
        ),
        _PlanLabeledText(
          key: const ValueKey('hero-story-experience-music'),
          label: 'Music direction',
          value:
              '${plan.musicMood} · ${plan.musicEnergy} · ${plan.musicStyle}\n'
              '${plan.musicRationale}',
          theme: theme,
        ),
      ],
    );
  }
}

class _StoryVoiceRenderingSection extends ConsumerWidget {
  const _StoryVoiceRenderingSection({
    required this.storyId,
    required this.state,
    required this.theme,
  });

  final String storyId;
  final HeroStoryVoiceRenderingState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(heroStoryVoiceRenderingProvider(storyId).notifier);

    return Column(
      key: const ValueKey('hero-story-voice-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Narrated version',
          key: const ValueKey('hero-story-voice-title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A derived synthetic narration of your experience — not your '
          'original recording, and not a rewrite of your story.',
          key: const ValueKey('hero-story-voice-subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (!state.hasVoiceRenderingConsent) ...[
          Text(
            HeroStoryVoiceRenderingController.consentRequiredMessage,
            key: const ValueKey('hero-story-voice-consent-needed'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('hero-story-voice-grant-consent-button'),
            onPressed: state.isRendering
                ? null
                : () => controller.grantVoiceRenderingConsent(),
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Authorize AI voice narration'),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const ValueKey('hero-story-create-narrated-button'),
          onPressed: !state.canCreate || !state.hasVoiceRenderingConsent
              ? null
              : () => controller.createNarratedVersion(
                    isRetry: state.phase == HeroStoryVoiceRenderingPhase.failed,
                  ),
          icon: state.isRendering
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.record_voice_over_outlined),
          label: Text(
            state.phase == HeroStoryVoiceRenderingPhase.failed
                ? 'Retry narrated version'
                : state.hasArtifact
                    ? 'Recreate narrated version'
                    : 'Create narrated version',
          ),
        ),
        if (state.isRendering) ...[
          const SizedBox(height: 16),
          Text(
            HeroStoryVoiceRenderingController.renderingMessage,
            key: const ValueKey('hero-story-voice-rendering'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage!,
            key: const ValueKey('hero-story-voice-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your original recording is still available.',
            key: const ValueKey('hero-story-voice-error-recording'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (state.rendering != null) ...[
          const SizedBox(height: 16),
          _NarratedArtifactSummary(
            rendering: state.rendering!,
            theme: theme,
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: const ValueKey('hero-story-play-narrated-button'),
            onPressed: state.isRendering
                ? null
                : () async {
                    if (state.phase == HeroStoryVoiceRenderingPhase.playing) {
                      await controller.pause();
                    } else if (state.phase ==
                        HeroStoryVoiceRenderingPhase.paused) {
                      await controller.resume();
                    } else {
                      await controller.playNarratedVersion();
                    }
                  },
            icon: Icon(
              state.phase == HeroStoryVoiceRenderingPhase.playing
                  ? Icons.pause
                  : Icons.play_circle_outline,
            ),
            label: Text(_narratedPlayLabel(state.phase)),
          ),
          if (state.phase == HeroStoryVoiceRenderingPhase.playing ||
              state.phase == HeroStoryVoiceRenderingPhase.paused) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('hero-story-narrated-stop-button'),
              onPressed: state.isRendering ? null : controller.stop,
              child: const Text('Stop narrated version'),
            ),
          ],
        ],
      ],
    );
  }

  static String _narratedPlayLabel(HeroStoryVoiceRenderingPhase phase) {
    return switch (phase) {
      HeroStoryVoiceRenderingPhase.playing => 'Pause narrated version',
      HeroStoryVoiceRenderingPhase.paused => 'Resume narrated version',
      HeroStoryVoiceRenderingPhase.rendering => 'Creating…',
      HeroStoryVoiceRenderingPhase.idle ||
      HeroStoryVoiceRenderingPhase.consentNeeded ||
      HeroStoryVoiceRenderingPhase.ready ||
      HeroStoryVoiceRenderingPhase.failed =>
        'Play narrated version',
    };
  }
}

class _NarratedArtifactSummary extends StatelessWidget {
  const _NarratedArtifactSummary({
    required this.rendering,
    required this.theme,
  });

  final StoryVoiceRenderingViewData rendering;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('hero-story-voice-artifact'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rendering.modeLabel,
          key: const ValueKey('hero-story-voice-mode'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Derived from experience plan ${rendering.experiencePlanId} '
          '(${rendering.experiencePlanProcessingVersion}). '
          'Generated audio — not the original recording.',
          key: const ValueKey('hero-story-voice-provenance'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StoryExperienceLabSection extends ConsumerWidget {
  const _StoryExperienceLabSection({
    required this.storyId,
    required this.recordingId,
    required this.state,
    required this.theme,
  });

  final String storyId;
  final String? recordingId;
  final HeroStoryExperienceLabState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(heroStoryExperienceLabProvider(storyId).notifier);

    return Column(
      key: const ValueKey('hero-story-lab-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Experience Laboratory (Experiment A)',
          key: const ValueKey('hero-story-lab-title'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Experimental: OpenAI creative direction + OpenAI TTS + Stable Audio '
          'instrumental bed. Presentation only — does not change your Story, '
          'reading, or experience plan.',
          key: const ValueKey('hero-story-lab-subtitle'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (!state.hasRequiredConsent) ...[
          Text(
            HeroStoryExperienceLabController.consentRequiredMessage,
            key: const ValueKey('hero-story-lab-consent-needed'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('hero-story-lab-grant-consent-button'),
            onPressed:
                state.isGenerating ? null : () => controller.grantLabConsents(),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Authorize experimental AI experience'),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          key: const ValueKey('hero-story-lab-generate-button'),
          onPressed: !state.canGenerate || !state.hasRequiredConsent
              ? null
              : () => controller.generate(
                    isRetry: state.phase == HeroStoryExperienceLabPhase.failed,
                  ),
          icon: state.isGenerating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high_outlined),
          label: Text(
            state.phase == HeroStoryExperienceLabPhase.failed
                ? 'Retry AI experience'
                : state.hasPlayableArtifact
                    ? 'Regenerate AI experience'
                    : 'Create AI experience',
          ),
        ),
        if (state.progressMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.progressMessage!,
            key: const ValueKey('hero-story-lab-progress'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (state.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            state.errorMessage!,
            key: const ValueKey('hero-story-lab-error'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        if (state.hasPlayableArtifact) ...[
          const SizedBox(height: 16),
          if (state.providerSummary != null)
            Text(
              state.providerSummary!,
              key: const ValueKey('hero-story-lab-providers'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: const ValueKey('hero-story-lab-play-button'),
            onPressed: state.isGenerating || recordingId == null
                ? null
                : () async {
                    if (state.phase == HeroStoryExperienceLabPhase.playing) {
                      await controller.pause();
                    } else if (state.phase ==
                        HeroStoryExperienceLabPhase.paused) {
                      await controller.resume(
                        originalRecordingId: recordingId!,
                      );
                    } else {
                      await controller.playLabExperience(
                        originalRecordingId: recordingId!,
                      );
                    }
                  },
            icon: Icon(
              state.phase == HeroStoryExperienceLabPhase.playing
                  ? Icons.pause
                  : Icons.play_circle_outline,
            ),
            label: Text(_labPlayLabel(state.phase)),
          ),
          if (state.phase == HeroStoryExperienceLabPhase.playing ||
              state.phase == HeroStoryExperienceLabPhase.paused ||
              state.phase == HeroStoryExperienceLabPhase.silenced) ...[
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('hero-story-lab-stop-button'),
              onPressed: state.isGenerating ? null : controller.stop,
              child: const Text('Stop AI experience'),
            ),
          ],
        ],
      ],
    );
  }

  static String _labPlayLabel(HeroStoryExperienceLabPhase phase) {
    return switch (phase) {
      HeroStoryExperienceLabPhase.playing => 'Pause AI experience',
      HeroStoryExperienceLabPhase.paused => 'Resume AI experience',
      HeroStoryExperienceLabPhase.silenced => 'Pause AI experience',
      HeroStoryExperienceLabPhase.generating => 'Loading…',
      HeroStoryExperienceLabPhase.idle ||
      HeroStoryExperienceLabPhase.consentNeeded ||
      HeroStoryExperienceLabPhase.ready ||
      HeroStoryExperienceLabPhase.failed =>
        'Play AI experience',
    };
  }
}

class _PlanLabeledText extends StatelessWidget {
  const _PlanLabeledText({
    required this.label,
    required this.value,
    required this.theme,
    super.key,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _HeroStoryMessage extends StatelessWidget {
  const _HeroStoryMessage({
    required this.message,
    required this.messageKey,
    this.onRetry,
  });

  final String message;
  final Key messageKey;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, key: messageKey, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
