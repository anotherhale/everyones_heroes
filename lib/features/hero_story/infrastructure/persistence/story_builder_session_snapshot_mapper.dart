import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_prompt_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_response_id.dart';
import 'package:everyonesheroes/core/ids/story_builder_session_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/story_builder_session.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_mode.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_narrative_role.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_purpose.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_session_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_builder_theme.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_intent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_prompt.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_builder_response.dart';

/// JSON snapshot mapper for durable local [StoryBuilderSession] persistence (SB.5).
///
/// Uses the public [StoryBuilderSession] constructor for reconstitution
/// (no domain events on load). Does **not** persist derived
/// [DeterministicStoryStructure].
///
/// Follows HS.9 Hero/Story mapper conventions: enum `.name`, ISO-8601 dates,
/// ID `.value` strings. No schemaVersion field (matches existing HS file
/// persistence; see SB-5 report).
final class StoryBuilderSessionSnapshotMapper {
  const StoryBuilderSessionSnapshotMapper._();

  static Map<String, dynamic> toJson(StoryBuilderSession session) {
    return {
      'id': session.id.value,
      'heroId': session.heroId.value,
      'status': session.status.name,
      'mode': session.mode.name,
      'intent': _intentToJson(session.intent),
      'storyId': session.storyId?.value,
      'prompts': [
        for (final prompt in session.prompts) _promptToJson(prompt),
      ],
      'responses': [
        for (final response in session.responses) _responseToJson(response),
      ],
      'createdAt': session.createdAt.toIso8601String(),
      'updatedAt': session.updatedAt.toIso8601String(),
    };
  }

  static StoryBuilderSession fromJson(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      final heroId = json['heroId'];
      final status = json['status'];
      final mode = json['mode'];
      final createdAt = json['createdAt'];
      final updatedAt = json['updatedAt'];

      if (id is! String || id.isEmpty) {
        throw const FormatException('Missing or invalid session id.');
      }
      if (heroId is! String || heroId.isEmpty) {
        throw const FormatException('Missing or invalid heroId.');
      }
      if (status is! String) {
        throw const FormatException('Missing or invalid status.');
      }
      if (mode is! String) {
        throw const FormatException('Missing or invalid mode.');
      }
      if (createdAt is! String) {
        throw const FormatException('Missing or invalid createdAt.');
      }
      if (updatedAt is! String) {
        throw const FormatException('Missing or invalid updatedAt.');
      }

      final intentRaw = json['intent'];
      if (intentRaw != null && intentRaw is! Map) {
        throw const FormatException('Invalid intent object.');
      }

      final promptsRaw = json['prompts'];
      if (promptsRaw != null && promptsRaw is! List) {
        throw const FormatException('Invalid prompts list.');
      }

      final responsesRaw = json['responses'];
      if (responsesRaw != null && responsesRaw is! List) {
        throw const FormatException('Invalid responses list.');
      }

      final storyIdRaw = json['storyId'];
      if (storyIdRaw != null && storyIdRaw is! String) {
        throw const FormatException('Invalid storyId.');
      }

      return StoryBuilderSession(
        id: StoryBuilderSessionId(id),
        heroId: HeroId(heroId),
        status: StoryBuilderSessionStatus.values.byName(status),
        mode: StoryBuilderMode.values.byName(mode),
        intent: _intentFromJson(
          intentRaw == null
              ? const <String, dynamic>{}
              : Map<String, dynamic>.from(intentRaw as Map),
        ),
        storyId: storyIdRaw == null || storyIdRaw.isEmpty
            ? null
            : StoryId(storyIdRaw),
        prompts: [
          for (final item in (promptsRaw as List? ?? const []))
            _promptFromJson(Map<String, dynamic>.from(item as Map)),
        ],
        responses: [
          for (final item in (responsesRaw as List? ?? const []))
            _responseFromJson(Map<String, dynamic>.from(item as Map)),
        ],
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
    } on FormatException {
      rethrow;
    } on ArgumentError catch (e) {
      throw FormatException('Invalid StoryBuilderSession snapshot: $e');
    } on TypeError catch (e) {
      throw FormatException('Malformed StoryBuilderSession snapshot: $e');
    } catch (e) {
      throw FormatException('Failed to deserialize StoryBuilderSession: $e');
    }
  }

  static Map<String, dynamic> _intentToJson(StoryBuilderIntent intent) {
    return {
      'purpose': intent.purpose?.name,
      'themes': [for (final theme in intent.themes) theme.name],
      'themesUnsure': intent.themesUnsure,
    };
  }

  static StoryBuilderIntent _intentFromJson(Map<String, dynamic> json) {
    final purposeRaw = json['purpose'];
    if (purposeRaw != null && purposeRaw is! String) {
      throw const FormatException('Invalid intent.purpose.');
    }

    final themesRaw = json['themes'];
    if (themesRaw != null && themesRaw is! List) {
      throw const FormatException('Invalid intent.themes.');
    }

    final themesUnsure = json['themesUnsure'];
    if (themesUnsure != null && themesUnsure is! bool) {
      throw const FormatException('Invalid intent.themesUnsure.');
    }

    return StoryBuilderIntent(
      purpose: purposeRaw == null
          ? null
          : StoryBuilderPurpose.values.byName(purposeRaw as String),
      themes: [
        for (final theme in (themesRaw as List? ?? const []))
          StoryBuilderTheme.values.byName(theme as String),
      ],
      themesUnsure: themesUnsure as bool? ?? false,
    );
  }

  static Map<String, dynamic> _promptToJson(StoryBuilderPrompt prompt) {
    return {
      'id': prompt.id.value,
      'text': prompt.text,
      'ordinal': prompt.ordinal,
      'narrativeRole': prompt.narrativeRole?.name,
      'isOptional': prompt.isOptional,
    };
  }

  static StoryBuilderPrompt _promptFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final text = json['text'];
    final ordinal = json['ordinal'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing or invalid prompt id.');
    }
    if (text is! String) {
      throw const FormatException('Missing or invalid prompt text.');
    }
    if (ordinal is! int) {
      throw const FormatException('Missing or invalid prompt ordinal.');
    }

    final roleRaw = json['narrativeRole'];
    if (roleRaw != null && roleRaw is! String) {
      throw const FormatException('Invalid prompt narrativeRole.');
    }

    final isOptional = json['isOptional'];
    if (isOptional != null && isOptional is! bool) {
      throw const FormatException('Invalid prompt isOptional.');
    }

    return StoryBuilderPrompt(
      id: StoryBuilderPromptId(id),
      text: text,
      ordinal: ordinal,
      narrativeRole: roleRaw == null
          ? null
          : StoryBuilderNarrativeRole.values.byName(roleRaw as String),
      isOptional: isOptional as bool? ?? true,
    );
  }

  static Map<String, dynamic> _responseToJson(StoryBuilderResponse response) {
    return {
      'id': response.id.value,
      'promptId': response.promptId.value,
      'ordinal': response.ordinal,
      'text': response.text,
      'skipped': response.skipped,
      'createdAt': response.createdAt.toIso8601String(),
      'updatedAt': response.updatedAt?.toIso8601String(),
    };
  }

  static StoryBuilderResponse _responseFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final promptId = json['promptId'];
    final ordinal = json['ordinal'];
    final skipped = json['skipped'];
    final createdAt = json['createdAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Missing or invalid response id.');
    }
    if (promptId is! String || promptId.isEmpty) {
      throw const FormatException('Missing or invalid response promptId.');
    }
    if (ordinal is! int) {
      throw const FormatException('Missing or invalid response ordinal.');
    }
    if (skipped is! bool) {
      throw const FormatException('Missing or invalid response skipped.');
    }
    if (createdAt is! String) {
      throw const FormatException('Missing or invalid response createdAt.');
    }

    final text = json['text'];
    if (text != null && text is! String) {
      throw const FormatException('Invalid response text.');
    }

    final updatedAt = json['updatedAt'];
    if (updatedAt != null && updatedAt is! String) {
      throw const FormatException('Invalid response updatedAt.');
    }

    return StoryBuilderResponse(
      id: StoryBuilderResponseId(id),
      promptId: StoryBuilderPromptId(promptId),
      ordinal: ordinal,
      text: text as String?,
      skipped: skipped,
      createdAt: DateTime.parse(createdAt),
      updatedAt: updatedAt == null
          ? null
          : DateTime.parse(updatedAt as String),
    );
  }
}
