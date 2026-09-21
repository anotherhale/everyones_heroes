import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_builder_session_completed.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_builder_session_created.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';

/// Durable, AI-agnostic Story Builder session (SB.1).
///
/// Holds Hero-authored prompts/responses and progress. Does not depend on
/// recording ([CaptureSession] is application-only) or AI providers.
///
/// Story creation timing follows SB.0: optional [storyId] link only; draft
/// Story materialization is deferred until Complete/Save in later slices.
final class StoryBuilderSession extends AggregateRoot<StoryBuilderSessionId> {
  StoryBuilderSession({
    required StoryBuilderSessionId id,
    required this.heroId,
    required StoryBuilderSessionStatus status,
    required StoryBuilderMode mode,
    required StoryBuilderIntent intent,
    required DateTime createdAt,
    required DateTime updatedAt,
    StoryId? storyId,
    Iterable<StoryBuilderPrompt>? prompts,
    Iterable<StoryBuilderResponse>? responses,
  }) : _status = status,
       _mode = mode,
       _intent = intent,
       _storyId = storyId,
       _createdAt = createdAt,
       _updatedAt = updatedAt,
       _prompts = List<StoryBuilderPrompt>.of(prompts ?? const []),
       _responses = List<StoryBuilderResponse>.of(responses ?? const []),
       super(id);

  factory StoryBuilderSession.create({
    required StoryBuilderSessionId id,
    required HeroId heroId,
    StoryBuilderMode mode = StoryBuilderMode.guided,
    StoryBuilderIntent? intent,
    StoryId? storyId,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final session = StoryBuilderSession(
      id: id,
      heroId: heroId,
      status: StoryBuilderSessionStatus.inProgress,
      mode: mode,
      intent: intent ?? StoryBuilderIntent.empty(),
      storyId: storyId,
      createdAt: now,
      updatedAt: now,
    );
    session.raise(
      StoryBuilderSessionCreated(sessionId: id, heroId: heroId),
    );
    return session;
  }

  final HeroId heroId;

  StoryBuilderSessionStatus _status;
  StoryBuilderMode _mode;
  StoryBuilderIntent _intent;
  StoryId? _storyId;
  final DateTime _createdAt;
  DateTime _updatedAt;
  final List<StoryBuilderPrompt> _prompts;
  final List<StoryBuilderResponse> _responses;

  StoryBuilderSessionStatus get status => _status;
  StoryBuilderMode get mode => _mode;
  StoryBuilderIntent get intent => _intent;
  StoryId? get storyId => _storyId;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;

  List<StoryBuilderPrompt> get prompts => List.unmodifiable(_prompts);
  List<StoryBuilderResponse> get responses => List.unmodifiable(_responses);

  StoryBuilderProgress get progress {
    final answered = _responses.where((r) => !r.skipped).length;
    final skipped = _responses.where((r) => r.skipped).length;
    return StoryBuilderProgress(
      presentedPromptCount: _prompts.length,
      responseCount: _responses.length,
      answeredCount: answered,
      skippedCount: skipped,
      currentPromptOrdinal: _prompts.isEmpty ? null : _prompts.last.ordinal,
    );
  }

  bool get isComplete => _status == StoryBuilderSessionStatus.completed;

  /// Records that a prompt was presented. Does not create a response.
  void presentPrompt(StoryBuilderPrompt prompt, {DateTime? at}) {
    _ensureMutable();
    if (_prompts.any((p) => p.id == prompt.id)) {
      throw StateError('Prompt ${prompt.id} was already presented.');
    }
    if (_prompts.any((p) => p.ordinal == prompt.ordinal)) {
      throw StateError('Prompt ordinal ${prompt.ordinal} is already used.');
    }
    _prompts.add(prompt);
    _touch(at);
  }

  /// Records an answered response for a previously presented prompt.
  void answerPrompt({
    required StoryBuilderResponseId responseId,
    required StoryBuilderPromptId promptId,
    required String text,
    DateTime? at,
  }) {
    _ensureMutable();
    final prompt = _requirePresentedPrompt(promptId);
    _ensureNoResponseForPrompt(promptId);

    final now = at ?? DateTime.now();
    _responses.add(
      StoryBuilderResponse(
        id: responseId,
        promptId: promptId,
        ordinal: prompt.ordinal,
        text: text,
        skipped: false,
        createdAt: now,
      ),
    );
    _touch(now);
  }

  /// Records a skipped prompt. Preserves prompt association without inventing text.
  void skipPrompt({
    required StoryBuilderResponseId responseId,
    required StoryBuilderPromptId promptId,
    DateTime? at,
  }) {
    _ensureMutable();
    final prompt = _requirePresentedPrompt(promptId);
    _ensureNoResponseForPrompt(promptId);

    final now = at ?? DateTime.now();
    _responses.add(
      StoryBuilderResponse(
        id: responseId,
        promptId: promptId,
        ordinal: prompt.ordinal,
        text: null,
        skipped: true,
        createdAt: now,
      ),
    );
    _touch(now);
  }

  /// Edits an existing answered response. Identity is preserved.
  void editResponse({
    required StoryBuilderResponseId responseId,
    required String text,
    DateTime? at,
  }) {
    _ensureMutable();
    final index = _responses.indexWhere((r) => r.id == responseId);
    if (index < 0) {
      throw StateError('Response $responseId not found.');
    }
    final existing = _responses[index];
    if (existing.skipped) {
      throw StateError('Cannot edit a skipped response.');
    }
    final now = at ?? DateTime.now();
    _responses[index] = existing.withEditedText(text, at: now);
    _touch(now);
  }

  /// Replaces a skipped marker with an answered response (same response id).
  void answerSkippedResponse({
    required StoryBuilderResponseId responseId,
    required String text,
    DateTime? at,
  }) {
    _ensureMutable();
    final index = _responses.indexWhere((r) => r.id == responseId);
    if (index < 0) {
      throw StateError('Response $responseId not found.');
    }
    final existing = _responses[index];
    if (!existing.skipped) {
      throw StateError('Response is not skipped; use editResponse.');
    }
    final now = at ?? DateTime.now();
    _responses[index] = StoryBuilderResponse(
      id: existing.id,
      promptId: existing.promptId,
      ordinal: existing.ordinal,
      text: text,
      skipped: false,
      createdAt: existing.createdAt,
      updatedAt: now,
    );
    _touch(now);
  }

  void setIntent(StoryBuilderIntent intent, {DateTime? at}) {
    _ensureMutable();
    _intent = intent;
    _touch(at);
  }

  void setMode(StoryBuilderMode mode, {DateTime? at}) {
    _ensureMutable();
    _mode = mode;
    _touch(at);
  }

  /// Optional association to an existing Story. Does not create a Story.
  void associateStory(StoryId storyId, {DateTime? at}) {
    _ensureMutable();
    if (_storyId != null && _storyId != storyId) {
      throw StateError('Session already associated with story $_storyId.');
    }
    _storyId = storyId;
    _touch(at);
  }

  void pause({DateTime? at}) {
    _transitionTo(StoryBuilderSessionStatus.paused, at: at);
  }

  void resume({DateTime? at}) {
    if (_status == StoryBuilderSessionStatus.inProgress) {
      return;
    }
    _transitionTo(StoryBuilderSessionStatus.inProgress, at: at);
  }

  void complete({DateTime? at}) {
    _transitionTo(StoryBuilderSessionStatus.completed, at: at);
    raise(
      StoryBuilderSessionCompleted(
        sessionId: id,
        heroId: heroId,
        storyId: _storyId,
      ),
    );
  }

  void abandon({DateTime? at}) {
    _transitionTo(StoryBuilderSessionStatus.abandoned, at: at);
  }

  void _transitionTo(StoryBuilderSessionStatus next, {DateTime? at}) {
    if (!_status.canTransitionTo(next)) {
      throw StateError('Cannot transition from $_status to $next.');
    }
    if (_status == next) {
      return;
    }
    _status = next;
    _touch(at);
  }

  void _ensureMutable() {
    if (!_status.isMutable) {
      throw StateError('Cannot modify a $_status Story Builder session.');
    }
  }

  StoryBuilderPrompt _requirePresentedPrompt(StoryBuilderPromptId promptId) {
    for (final prompt in _prompts) {
      if (prompt.id == promptId) {
        return prompt;
      }
    }
    throw StateError('Prompt $promptId has not been presented.');
  }

  void _ensureNoResponseForPrompt(StoryBuilderPromptId promptId) {
    if (_responses.any((r) => r.promptId == promptId)) {
      throw StateError('Prompt $promptId already has a response.');
    }
  }

  void _touch([DateTime? at]) {
    _updatedAt = at ?? DateTime.now();
  }
}
