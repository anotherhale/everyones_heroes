import 'dart:io';

import 'package:everyonesheroes/core/ids/story_experience_plan_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_arc.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_intention.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_experience_step_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/source_span_reference.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_moment.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_music_direction.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_plan.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_experience_step.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/persistence/story_experience_plan_snapshot_mapper.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/file_story_experience_plan_repository.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/repositories/in_memory_story_experience_plan_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final transcriptId = StoryRepresentationId('rep-t');
  final storyId = StoryId('story-1');

  StoryExperiencePlan buildPlan({
    required StoryExperiencePlanId id,
    DateTime? createdAt,
    String coreMessage = 'Core message',
  }) {
    return StoryExperiencePlan(
      id: id,
      storyId: storyId,
      transcriptRepresentationId: transcriptId,
      intention: StoryExperienceIntention.encourage,
      coreMessage: coreMessage,
      emotionalArc: StoryExperienceArc.connection,
      keyMoments: [
        StoryExperienceMoment(
          id: 'km-1',
          description: 'A key moment',
          sourceSpan: SourceSpanReference(
            representationId: transcriptId,
            startOffset: 0,
            endOffset: 12,
          ),
        ),
      ],
      musicDirection: StoryExperienceMusicDirection(
        mood: 'warm',
        energy: 'low',
        style: 'piano',
        rationale: 'Supports the reflective close of the story.',
      ),
      reflectionPrompt: 'What would you tell your past self?',
      sequence: const [
        StoryExperienceStep(type: StoryExperienceStepType.story),
        StoryExperienceStep(
          type: StoryExperienceStepType.keyMoment,
          referenceId: 'km-1',
        ),
      ],
      createdAt: createdAt ?? DateTime.utc(2026, 9, 24),
      providerLabel: 'test',
    );
  }

  group('InMemoryStoryExperiencePlanRepository', () {
    test('save/load and missing plan', () async {
      final repo = InMemoryStoryExperiencePlanRepository();
      expect(await repo.findByStoryId(storyId), isNull);
      expect(await repo.getByStoryId(storyId), isNull);

      final plan = buildPlan(id: StoryExperiencePlanId('plan-1'));
      await repo.save(plan);
      expect(await repo.findByStoryId(storyId), plan);
      expect(await repo.findById(plan.id), plan);
    });

    test('replacement/regeneration updates latest by story', () async {
      final repo = InMemoryStoryExperiencePlanRepository();
      final first = buildPlan(id: StoryExperiencePlanId('plan-1'));
      final second = buildPlan(
        id: StoryExperiencePlanId('plan-2'),
        createdAt: DateTime.utc(2026, 9, 25),
        coreMessage: 'Updated core message',
      );
      await repo.save(first);
      await repo.save(second);
      expect(await repo.findByStoryId(storyId), second);
    });
  });

  group('StoryExperiencePlanSnapshotMapper', () {
    test('round-trip serialization', () {
      final plan = buildPlan(id: StoryExperiencePlanId('plan-rt'));
      final json = StoryExperiencePlanSnapshotMapper.toJson(plan);
      final restored = StoryExperiencePlanSnapshotMapper.fromJson(json);
      expect(restored, plan);
    });
  });

  group('FileStoryExperiencePlanRepository', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('hs12-4-plan-');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('save/load/replace/missing across instances', () async {
      final repo = FileStoryExperiencePlanRepository(rootDirectory: tempDir);
      expect(await repo.findByStoryId(storyId), isNull);

      final first = buildPlan(id: StoryExperiencePlanId('plan-1'));
      await repo.save(first);

      final reloaded = FileStoryExperiencePlanRepository(rootDirectory: tempDir);
      expect(await reloaded.findByStoryId(storyId), first);

      final second = buildPlan(
        id: StoryExperiencePlanId('plan-2'),
        createdAt: DateTime.utc(2026, 9, 26),
        coreMessage: 'Regenerated',
      );
      await reloaded.save(second);
      expect(await reloaded.findByStoryId(storyId), second);

      // Prior plan file removed on regeneration.
      final priorFile = File(
        '${tempDir.path}/story_experience_plans/plan-1.json',
      );
      expect(priorFile.existsSync(), isFalse);
    });
  });
}
