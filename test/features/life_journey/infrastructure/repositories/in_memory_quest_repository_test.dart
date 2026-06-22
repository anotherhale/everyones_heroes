import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/quest.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/quest_title.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/quest_status.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/repositories/in_memory_quest_repository.dart';
import 'package:flutter_test/flutter_test.dart';

JourneyId createJourneyId() {
  return JourneyId.generate();
}

Quest createQuest({
  QuestId? id,
  JourneyId? journeyId,
  String title = '90 Day Health Quest',
}) {
  return Quest.create(
    id: id ?? QuestId.generate(),
    journeyId: journeyId ?? createJourneyId(),
    title: QuestTitle(title),
  );
}

Quest createCompletedQuest({
  required QuestId id,
  required JourneyId journeyId,
}) {
  return Quest(
    id: id,
    journeyId: journeyId,
    title: QuestTitle('Completed Quest'),
    status: QuestStatus.completed,
  );
}

void main() {
  late InMemoryQuestRepository repository;
  group('InMemoryQuestRepository', () {
    setUp(() {
      repository = InMemoryQuestRepository();
    });

    group('save()', () {
      test('saves a quest', () async {
        final quest = createQuest();

        await repository.save(quest);

        final result = await repository.findById(quest.id);

        expect(result, isNotNull);
        expect(result!.id, equals(quest.id));
      });

      test('saves multiple quests', () async {
        final quest1 = createQuest();
        final quest2 = createQuest();

        await repository.save(quest1);
        await repository.save(quest2);

        expect(await repository.findById(quest1.id), isNotNull);
        expect(await repository.findById(quest2.id), isNotNull);
      });

      test('overwrites existing quest with same id', () async {
        final id = QuestId.generate();
        final journeyId = JourneyId.generate();

        final original = createQuest(id: id, journeyId: journeyId);

        final updated = createCompletedQuest(id: id, journeyId: journeyId);

        await repository.save(original);
        await repository.save(updated);

        final result = await repository.findById(id);

        expect(result, isNotNull);
        expect(result!.status, QuestStatus.completed);
      });
    });
  });

  group('findById()', () {
    test('returns saved quest', () async {
      final quest = createQuest();

      await repository.save(quest);

      final result = await repository.findById(quest.id);

      expect(result, isNotNull);
      expect(result!.id, equals(quest.id));
    });

    test('returns overwritten quest', () async {
      final id = QuestId.generate();
      final journeyId = JourneyId.generate();

      await repository.save(createQuest(id: id, journeyId: journeyId));

      await repository.save(createCompletedQuest(id: id, journeyId: journeyId));

      final result = await repository.findById(id);

      expect(result, isNotNull);
      expect(result!.status, QuestStatus.completed);
    });

    test('returns null when quest does not exist', () async {
      final result = await repository.findById(QuestId.generate());

      expect(result, isNull);
    });
  });

  group('exists()', () {
    test('returns true when quest exists', () async {
      final quest = createQuest();

      await repository.save(quest);

      expect(await repository.exists(quest.id), isTrue);
    });

    test('returns false when quest does not exist', () async {
      expect(await repository.exists(QuestId.generate()), isFalse);
    });

    test('returns false after deletion', () async {
      final quest = createQuest();

      await repository.save(quest);

      await repository.delete(quest.id);

      expect(await repository.exists(quest.id), isFalse);
    });
  });

  group('delete()', () {
    test('deletes existing quest', () async {
      final quest = createQuest();

      await repository.save(quest);

      await repository.delete(quest.id);

      expect(await repository.findById(quest.id), isNull);
    });

    test('deleting missing quest does not throw', () {
      expect(repository.delete(QuestId.generate()), completes);
    });

    test('only removes specified quest', () async {
      final quest1 = createQuest();
      final quest2 = createQuest();

      await repository.save(quest1);
      await repository.save(quest2);

      await repository.delete(quest1.id);

      expect(await repository.findById(quest1.id), isNull);

      expect(await repository.findById(quest2.id), isNotNull);
    });
  });

  test('returns empty list when no quests exist', () async {
    final results = await repository.findByJourneyId(JourneyId.generate());

    expect(results, isEmpty);
  });

  test('returns empty list when journey has no quests', () async {
    final journeyA = JourneyId.generate();
    final journeyB = JourneyId.generate();

    await repository.save(createQuest(journeyId: journeyA));

    final results = await repository.findByJourneyId(journeyB);

    expect(results, isEmpty);
  });

  test('returns single matching quest', () async {
    final journeyId = JourneyId.generate();

    final quest = createQuest(journeyId: journeyId);

    await repository.save(quest);

    final results = await repository.findByJourneyId(journeyId);

    expect(results, hasLength(1));
    expect(results.first.id, quest.id);
  });

  test('returns multiple matching quests', () async {
    final journeyId = JourneyId.generate();

    await repository.save(createQuest(journeyId: journeyId));

    await repository.save(createQuest(journeyId: journeyId));

    final results = await repository.findByJourneyId(journeyId);

    expect(results, hasLength(2));
  });

  test('excludes quests from other journeys', () async {
    final journeyA = JourneyId.generate();
    final journeyB = JourneyId.generate();

    await repository.save(createQuest(journeyId: journeyA));

    await repository.save(createQuest(journeyId: journeyB));

    final results = await repository.findByJourneyId(journeyA);

    expect(results, hasLength(1));
    expect(results.first.journeyId, journeyA);
  });

  test('returns all quests for matching journey', () async {
    final journeyA = JourneyId.generate();
    final journeyB = JourneyId.generate();

    await repository.save(createQuest(journeyId: journeyA));

    await repository.save(createQuest(journeyId: journeyA));

    await repository.save(createQuest(journeyId: journeyB));

    final results = await repository.findByJourneyId(journeyA);

    expect(results, hasLength(2));
  });

  test('returns empty list after deletion', () async {
    final journeyId = JourneyId.generate();

    final quest = createQuest(journeyId: journeyId);

    await repository.save(quest);

    await repository.delete(quest.id);

    final results = await repository.findByJourneyId(journeyId);

    expect(results, isEmpty);
  });

  group('repository lifecycle', () {
    test('save then findByJourneyId', () async {
      final journeyId = JourneyId.generate();

      await repository.save(createQuest(journeyId: journeyId));

      final results = await repository.findByJourneyId(journeyId);

      expect(results, hasLength(1));
    });

    test('save multiple journeys isolates quests', () async {
      final journeyA = JourneyId.generate();
      final journeyB = JourneyId.generate();

      await repository.save(createQuest(journeyId: journeyA));

      await repository.save(createQuest(journeyId: journeyB));

      expect(await repository.findByJourneyId(journeyA), hasLength(1));

      expect(await repository.findByJourneyId(journeyB), hasLength(1));
    });

    test('delete one quest preserves others', () async {
      final journeyId = JourneyId.generate();

      final quest1 = createQuest(journeyId: journeyId);

      final quest2 = createQuest(journeyId: journeyId);

      await repository.save(quest1);
      await repository.save(quest2);

      await repository.delete(quest1.id);

      final results = await repository.findByJourneyId(journeyId);

      expect(results, hasLength(1));
      expect(results.first.id, quest2.id);
    });

    test('overwrite quest preserves journey association', () async {
      final id = QuestId.generate();
      final journeyId = JourneyId.generate();

      await repository.save(createQuest(id: id, journeyId: journeyId));

      await repository.save(createCompletedQuest(id: id, journeyId: journeyId));

      final results = await repository.findByJourneyId(journeyId);

      expect(results, hasLength(1));
      expect(results.first.status, QuestStatus.completed);
    });
  });
}
