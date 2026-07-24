import 'package:everyonesheroes/core/ids/aggregate_id.dart';
import 'package:everyonesheroes/core/ids/journey_id.dart';
import 'package:everyonesheroes/core/ids/quest_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';

import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

import 'package:everyonesheroes/features/life_journey/domain/events/chapter_advanced.dart';
import 'package:everyonesheroes/features/life_journey/domain/events/journey_created.dart';

import 'package:everyonesheroes/features/life_journey/domain/value_objects/journey_vision.dart';

final class Journey extends AggregateRoot<JourneyId> {
  Journey({
    required JourneyId id,
    required this._vision,
    this._currentChapter = JourneyChapter.awakening,
    List<QuestId>? activeQuestIds,
  }) : _activeQuestIds = activeQuestIds ?? [],
       super(id);

  final JourneyVision _vision;

  JourneyChapter _currentChapter;

  final List<QuestId> _activeQuestIds;

  factory Journey.create({
    required JourneyId id,
    required JourneyVision vision,
  }) {
    final journey = Journey(id: id, vision: vision);

    journey.raise(JourneyCreated(aggregateId: id));

    return journey;
  }

  JourneyVision get vision => _vision;

  JourneyChapter get currentChapter => _currentChapter;

  List<QuestId> get activeQuestIds => List.unmodifiable(_activeQuestIds);

  bool get isComplete => currentChapter == JourneyChapter.contribution;

  void attachQuest(QuestId questId) {
    final alreadyAttached = _activeQuestIds.contains(questId);

    if (alreadyAttached) {
      throw StateError(
        'Quest ${questId.value} is already attached to this journey.',
      );
    }

    _activeQuestIds.add(questId);
  }

  bool hasQuest(QuestId questId) {
    return _activeQuestIds.contains(questId);
  }

  void advanceChapter(JourneyChapter nextChapter) {
    if (!_currentChapter.canAdvanceTo(nextChapter)) {
      throw StateError(
        'Invalid chapter progression: '
        '${_currentChapter.name} -> ${nextChapter.name}',
      );
    }

    final previousChapter = _currentChapter;

    _currentChapter = nextChapter;

    raise(
      ChapterAdvanced(
        aggregateId: id,
        previousChapter: previousChapter,
        newChapter: nextChapter,
      ),
    );
  }
}
