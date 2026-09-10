import 'dart:collection';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/hero_created.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/hero_profile_updated.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';

/// A person whose lived experience may inspire others.
///
/// Hero identity is distinct from authentication identity ([identityUserId]).
final class Hero extends AggregateRoot<HeroId> {
  Hero({
    required HeroId id,
    required HeroProfile profile,
    this.identityUserId,
    HeroVisibility visibility = HeroVisibility.private,
    HeroStatus status = HeroStatus.active,
    Iterable<StoryId>? publishedStoryIds,
    DateTime? createdAt,
  }) : _profile = profile,
       _visibility = visibility,
       _status = status,
       _publishedStoryIds = [...?publishedStoryIds],
       _createdAt = createdAt ?? DateTime.now(),
       super(id);

  factory Hero.create({
    required HeroId id,
    required HeroProfile profile,
    UserId? identityUserId,
    HeroVisibility visibility = HeroVisibility.private,
    DateTime? createdAt,
  }) {
    final hero = Hero(
      id: id,
      profile: profile,
      identityUserId: identityUserId,
      visibility: visibility,
      createdAt: createdAt,
    );

    hero.raise(HeroCreated(heroId: id));
    return hero;
  }

  final UserId? identityUserId;

  HeroProfile _profile;
  HeroVisibility _visibility;
  HeroStatus _status;
  final List<StoryId> _publishedStoryIds;
  final DateTime _createdAt;

  HeroProfile get profile => _profile;
  HeroVisibility get visibility => _visibility;
  HeroStatus get status => _status;
  DateTime get createdAt => _createdAt;

  UnmodifiableListView<StoryId> get publishedStoryIds =>
      UnmodifiableListView(_publishedStoryIds);

  bool get isActive => _status == HeroStatus.active;

  void updateProfile(HeroProfile profile) {
    _ensureActive();

    if (_profile == profile) {
      return;
    }

    _profile = profile;
    raise(HeroProfileUpdated(heroId: id));
  }

  void changeVisibility(HeroVisibility visibility) {
    _ensureActive();
    _visibility = visibility;
  }

  void archive() {
    if (_status == HeroStatus.archived) {
      return;
    }
    _status = HeroStatus.archived;
  }

  void reactivate() {
    _status = HeroStatus.active;
  }

  /// Records a published Story reference owned by this Hero.
  void attachPublishedStory(StoryId storyId) {
    _ensureActive();

    if (_publishedStoryIds.contains(storyId)) {
      return;
    }

    _publishedStoryIds.add(storyId);
  }

  void detachPublishedStory(StoryId storyId) {
    _publishedStoryIds.remove(storyId);
  }

  void _ensureActive() {
    if (_status != HeroStatus.active) {
      throw StateError('Cannot modify an archived hero.');
    }
  }
}
