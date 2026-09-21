import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_builder_session_request.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/hero/active_local_hero_provider.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/story_builder_use_case_providers.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/presentation/models/story_builder_intent_labels.dart';
import 'package:everyonesheroes/features/hero_story/presentation/providers/resumable_story_builder_sessions_provider.dart';
import 'package:everyonesheroes/features/hero_story/presentation/screens/story_builder_screen.dart';

/// Collects purpose (one) and themes (zero or more) before creating a session.
class StoryBuilderIntentScreen extends ConsumerStatefulWidget {
  const StoryBuilderIntentScreen({super.key, required this.mode});

  final StoryBuilderMode mode;

  @override
  ConsumerState<StoryBuilderIntentScreen> createState() =>
      _StoryBuilderIntentScreenState();
}

class _StoryBuilderIntentScreenState
    extends ConsumerState<StoryBuilderIntentScreen> {
  StoryBuilderPurpose? _purpose;
  final Set<StoryBuilderTheme> _themes = {};
  var _themesUnsure = false;
  var _isCreating = false;
  String? _error;

  bool get _canContinue => _purpose != null && !_isCreating;

  Future<void> _continue() async {
    final purpose = _purpose;
    if (purpose == null || _isCreating) {
      return;
    }
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final hero = await ref.read(ensureActiveLocalHeroProvider.future);
      final sessionId = StoryBuilderSessionId.generate();
      final intent = StoryBuilderIntent(
        purpose: purpose,
        themes: _themesUnsure ? const [] : _themes,
        themesUnsure: _themesUnsure,
      );
      final started = await ref
          .read(startStoryBuilderSessionUseCaseProvider)
          .execute(
            StartStoryBuilderSessionRequest(
              sessionId: sessionId,
              heroId: hero.id,
              mode: widget.mode,
              intent: intent,
            ),
          );
      if (started is Failure) {
        setState(() {
          _isCreating = false;
          _error = (started as Failure).error;
        });
        return;
      }
      final session = (started as Success<StoryBuilderSession>).value;
      if (!mounted) {
        return;
      }
      ref.invalidate(resumableStoryBuilderSessionsProvider);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => StoryBuilderScreen(
            resumeSessionId: session.id.value,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCreating = false;
        _error = 'Unable to start Story Builder.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your story intent'),
        key: const ValueKey('story-builder-intent-app-bar'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Text(
                    'What do you want this story to do?',
                    key: const ValueKey('story-builder-purpose-title'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose one purpose.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final purpose in StoryBuilderPurpose.values)
                    ListTile(
                      key: ValueKey('story-builder-purpose-${purpose.name}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(StoryBuilderIntentLabels.purpose(purpose)),
                      leading: Icon(
                        _purpose == purpose
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      selected: _purpose == purpose,
                      onTap: _isCreating
                          ? null
                          : () => setState(() => _purpose = purpose),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'What is your story about?',
                    key: const ValueKey('story-builder-themes-title'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose any themes that fit — or say you are not sure yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    key: const ValueKey('story-builder-themes-unsure'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Not sure yet'),
                    value: _themesUnsure,
                    onChanged: _isCreating
                        ? null
                        : (value) {
                            setState(() {
                              _themesUnsure = value ?? false;
                              if (_themesUnsure) {
                                _themes.clear();
                              }
                            });
                          },
                  ),
                  for (final storyTheme in StoryBuilderTheme.values)
                    CheckboxListTile(
                      key: ValueKey(
                        'story-builder-theme-${storyTheme.name}',
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: Text(StoryBuilderIntentLabels.theme(storyTheme)),
                      value: _themes.contains(storyTheme),
                      onChanged: _isCreating || _themesUnsure
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected ?? false) {
                                  _themes.add(storyTheme);
                                } else {
                                  _themes.remove(storyTheme);
                                }
                              });
                            },
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      key: const ValueKey('story-builder-intent-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: FilledButton(
                key: const ValueKey('story-builder-intent-continue'),
                onPressed: _canContinue ? _continue : null,
                child: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start building'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
