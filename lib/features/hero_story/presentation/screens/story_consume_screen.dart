import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/begin_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/consume_story_experience_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/load_story_media_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/start_story_reflection_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_consumption_session.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/story_media_bytes.dart';
import 'package:everyonesheroes/features/hero_story/application/providers/use_cases/experience_use_case_providers.dart';
import 'package:everyonesheroes/features/life_journey/application/providers/context/current_journey_context_provider.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/reflection.dart';
import 'package:everyonesheroes/features/life_journey/presentation/screens/reflect_screen.dart';

/// Story consumption UI — text/script first; media via existing storage port.
///
/// Does not use [BeginExperienceUseCase] (which creates Reflections).
/// Optional reflection is explicit via "Reflect on this story".
class StoryConsumeScreen extends ConsumerStatefulWidget {
  const StoryConsumeScreen({
    required this.storyId,
    required this.representationId,
    super.key,
  });

  final String storyId;
  final String representationId;

  @override
  ConsumerState<StoryConsumeScreen> createState() => _StoryConsumeScreenState();
}

class _StoryConsumeScreenState extends ConsumerState<StoryConsumeScreen> {
  StoryConsumptionSession? _session;
  String? _error;
  bool _loading = true;
  bool _completing = false;
  bool _completed = false;
  bool _startingReflection = false;
  int? _mediaByteLength;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    final result = await ref
        .read(beginStoryExperienceUseCaseProvider)
        .execute(
          BeginStoryExperienceRequest(
            storyId: StoryId(widget.storyId),
            representationId: StoryRepresentationId(widget.representationId),
            startedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );

    if (!mounted) {
      return;
    }

    if (result is Failure<StoryConsumptionSession>) {
      setState(() {
        _loading = false;
        _error = result.error;
      });
      return;
    }

    final session = (result as Success<StoryConsumptionSession>).value;
    setState(() {
      _session = session;
      _loading = false;
    });

    if (session.selectedRepresentation.hasMedia) {
      final mediaResult = await ref
          .read(loadStoryMediaUseCaseProvider)
          .execute(
            LoadStoryMediaRequest(
              storyId: StoryId(widget.storyId),
              representationId: StoryRepresentationId(widget.representationId),
            ),
          );
      if (!mounted) {
        return;
      }
      if (mediaResult is Success<StoryMediaBytes>) {
        setState(() {
          _mediaByteLength = mediaResult.value.bytes.length;
        });
      }
    }
  }

  Future<void> _complete() async {
    if (_completing || _completed) {
      return;
    }
    setState(() => _completing = true);

    final result = await ref
        .read(consumeStoryExperienceUseCaseProvider)
        .execute(
          ConsumeStoryExperienceRequest(
            storyId: StoryId(widget.storyId),
            representationId: StoryRepresentationId(widget.representationId),
          ),
        );

    if (!mounted) {
      return;
    }

    if (result is Failure<StoryConsumptionSession>) {
      setState(() {
        _completing = false;
        _error = result.error;
      });
      return;
    }

    setState(() {
      _completing = false;
      _completed = true;
      _session = (result as Success<StoryConsumptionSession>).value;
    });
  }

  Future<void> _reflect() async {
    if (_startingReflection) {
      return;
    }

    final journeyId = ref.read(currentJourneyContextProvider).currentJourneyId;
    if (journeyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A journey is required before reflecting.'),
        ),
      );
      return;
    }

    setState(() => _startingReflection = true);

    final result = await ref
        .read(startStoryReflectionUseCaseProvider)
        .execute(
          StartStoryReflectionRequest(
            storyId: StoryId(widget.storyId),
            journeyId: journeyId,
          ),
        );

    if (!mounted) {
      return;
    }

    result.fold(
      onSuccess: (Reflection reflection) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReflectScreen(reflectionId: reflection.id),
          ),
        );
      },
      onFailure: (error) {
        setState(() => _startingReflection = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Consume')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _session == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    key: const ValueKey('consume-error'),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                children: [
                  Text(
                    _session!.experience.title,
                    key: const ValueKey('consume-title'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _session!.selectedRepresentation.format.name,
                    key: const ValueKey('consume-format'),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 20),
                  if (_session!.selectedRepresentation.textContent != null)
                    Text(
                      _session!.selectedRepresentation.textContent!,
                      key: const ValueKey('consume-text'),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    )
                  else
                    Text(
                      _session!.experience.narrativeBody,
                      key: const ValueKey('consume-narrative-fallback'),
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
                    ),
                  if (_mediaByteLength != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Media available ($_mediaByteLength bytes)',
                      key: const ValueKey('consume-media-meta'),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    key: const ValueKey('complete-story-consume'),
                    onPressed: _completed || _completing ? null : _complete,
                    child: Text(_completed ? 'Completed' : 'Mark complete'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const ValueKey('reflect-on-story'),
                    onPressed: _startingReflection ? null : _reflect,
                    child: const Text('Reflect on this story'),
                  ),
                ],
              ),
      ),
    );
  }
}
