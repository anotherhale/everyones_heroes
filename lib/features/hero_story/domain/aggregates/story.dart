import 'dart:collection';

import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/story_id.dart';
import 'package:everyonesheroes/core/ids/story_representation_id.dart';
import 'package:everyonesheroes/core/shared_kernel/aggregate_root.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/entities/story_representation.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/representation_origin.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_transformation_type.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/story_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_approved.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_archived.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_classified.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_created.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_published.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_representation_added.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_representation_approved.dart';
import 'package:everyonesheroes/features/hero_story/domain/events/story_submitted.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/content_suitability.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_consent.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/provenance_step.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/spirituality_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_classification.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_provenance.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_title.dart';

/// Canonical lived narrative belonging to a Hero.
///
/// Media, transcripts, translations, and scripts are representations of this
/// Story — they do not replace it.
final class Story extends AggregateRoot<StoryId> {
  Story({
    required StoryId id,
    required this.heroId,
    required this._title,
    required this._narrative,
    required this._originalLanguage,
    this._lifecycleStatus = StoryLifecycleStatus.draft,
    this._visibility = StoryVisibility.draft,
    StoryClassification? classification,
    ContentSuitability? contentSuitability,
    SpiritualityClassification? spirituality,
    StoryProvenance? provenance,
    StoryConsent? consent,
    Iterable<StoryRepresentation>? representations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : _classification = classification ?? StoryClassification.empty,
       _contentSuitability = contentSuitability ?? ContentSuitability.unmarked,
       _spirituality =
           spirituality ?? SpiritualityClassification.nonSpiritual,
       _provenance = provenance ?? StoryProvenance.empty,
       _consent = consent ?? StoryConsent.none,
       _representations = [...?representations],
       _createdAt = createdAt ?? DateTime.now(),
       _updatedAt = updatedAt ?? createdAt ?? DateTime.now(),
       super(id);

  factory Story.create({
    required StoryId id,
    required HeroId heroId,
    required StoryTitle title,
    required StoryNarrative narrative,
    required LanguageCode originalLanguage,
    StoryVisibility visibility = StoryVisibility.draft,
    String? originalSourceDescription,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    final story = Story(
      id: id,
      heroId: heroId,
      title: title,
      narrative: narrative,
      originalLanguage: originalLanguage,
      visibility: visibility,
      provenance: StoryProvenance(
        originalSourceDescription: originalSourceDescription,
      ),
      createdAt: now,
      updatedAt: now,
    );

    story.raise(StoryCreated(storyId: id, heroId: heroId));
    return story;
  }

  /// Capture-first draft with provisional narrative and private visibility.
  ///
  /// Audio is attached separately as an original [StoryRepresentation].
  factory Story.createFromCapture({
    required StoryId id,
    required HeroId heroId,
    required LanguageCode originalLanguage,
    StoryTitle? title,
    String? originalSourceDescription,
    DateTime? createdAt,
  }) {
    return Story.create(
      id: id,
      heroId: heroId,
      title: title ?? StoryTitle('Untitled Story'),
      narrative: StoryNarrative.provisional(),
      originalLanguage: originalLanguage,
      visibility: StoryVisibility.private,
      originalSourceDescription:
          originalSourceDescription ?? 'Hero original audio capture',
      createdAt: createdAt,
    );
  }

  final HeroId heroId;

  StoryTitle _title;
  StoryNarrative _narrative;
  LanguageCode _originalLanguage;
  StoryLifecycleStatus _lifecycleStatus;
  StoryVisibility _visibility;
  StoryClassification _classification;
  ContentSuitability _contentSuitability;
  SpiritualityClassification _spirituality;
  StoryProvenance _provenance;
  StoryConsent _consent;
  final List<StoryRepresentation> _representations;
  final DateTime _createdAt;
  DateTime _updatedAt;

  StoryTitle get title => _title;
  StoryNarrative get narrative => _narrative;
  LanguageCode get originalLanguage => _originalLanguage;
  StoryLifecycleStatus get lifecycleStatus => _lifecycleStatus;
  StoryVisibility get visibility => _visibility;
  StoryClassification get classification => _classification;
  ContentSuitability get contentSuitability => _contentSuitability;
  SpiritualityClassification get spirituality => _spirituality;
  StoryProvenance get provenance => _provenance;
  StoryConsent get consent => _consent;
  bool get hasProvisionalNarrative => _narrative.isProvisional;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;

  UnmodifiableListView<StoryRepresentation> get representations =>
      UnmodifiableListView(_representations);

  List<LanguageCode> get availableLanguages => List.unmodifiable(
    _representations.map((r) => r.language).toSet().toList(),
  );

  bool get isPublished => _lifecycleStatus == StoryLifecycleStatus.published;

  void updateNarrative({
    StoryTitle? title,
    StoryNarrative? narrative,
  }) {
    _ensureEditable();

    if (title != null) {
      _title = title;
    }
    if (narrative != null) {
      if (narrative.isProvisional && !_narrative.isProvisional) {
        throw StateError(
          'Cannot replace an authored narrative with a provisional narrative.',
        );
      }
      _narrative = narrative;
    }
    _touch();
  }

  void updateConsent(StoryConsent consent, {DateTime? at}) {
    _consent = consent;
    _touch(at);
  }

  void markCaptureRecorded({DateTime? at}) {
    final when = at ?? DateTime.now();
    _consent = _consent.markRecorded(when);
    _touch(when);
  }

  void submit({DateTime? at}) {
    if (!_consent.isProcessingApproved) {
      throw StateError(
        'Cannot submit story without processing consent.',
      );
    }

    _transitionTo(StoryLifecycleStatus.processing);
    _touch(at);
    raise(StorySubmitted(storyId: id, heroId: heroId));
  }

  void markReadyForReview({DateTime? at}) {
    _transitionTo(StoryLifecycleStatus.review);
    _touch(at);
  }

  void approve({DateTime? at}) {
    if (_narrative.isProvisional) {
      throw StateError(
        'Cannot approve a story with provisional capture narrative.',
      );
    }

    _transitionTo(StoryLifecycleStatus.approved);
    _touch(at);
    raise(StoryApproved(storyId: id));
  }

  void reject({DateTime? at}) {
    _transitionTo(StoryLifecycleStatus.rejected);
    _touch(at);
  }

  void publish({DateTime? at}) {
    if (_visibility == StoryVisibility.private ||
        _visibility == StoryVisibility.draft) {
      throw StateError(
        'Cannot publish a story with ${_visibility.name} visibility.',
      );
    }

    if (!_consent.isPublicationApproved) {
      throw StateError(
        'Cannot publish story without publication consent.',
      );
    }

    if (_narrative.isProvisional) {
      throw StateError(
        'Cannot publish a story with provisional capture narrative.',
      );
    }

    _transitionTo(StoryLifecycleStatus.published);
    _touch(at);
    raise(StoryPublished(storyId: id, heroId: heroId));
  }

  void archive({DateTime? at}) {
    _transitionTo(StoryLifecycleStatus.archived);
    _touch(at);
    raise(StoryArchived(storyId: id));
  }

  void changeVisibility(StoryVisibility visibility) {
    if (_lifecycleStatus == StoryLifecycleStatus.published &&
        (visibility == StoryVisibility.private ||
            visibility == StoryVisibility.draft)) {
      throw StateError(
        'Published stories cannot become ${visibility.name}; archive first.',
      );
    }

    _visibility = visibility;
    _touch();
  }

  void classify(StoryClassification classification, {DateTime? at}) {
    _classification = classification;
    _touch(at);
    raise(StoryClassified(storyId: id));
  }

  void updateContentSuitability(ContentSuitability suitability) {
    _contentSuitability = suitability;
    _touch();
  }

  void updateSpirituality(SpiritualityClassification spirituality) {
    _spirituality = spirituality;
    _touch();
  }

  void addRepresentation(
    StoryRepresentation representation, {
    StoryTransformationType transformationType =
        StoryTransformationType.other,
    DateTime? at,
  }) {
    if (_representations.any((r) => r.id == representation.id)) {
      throw StateError(
        'Representation ${representation.id.value} already exists on story.',
      );
    }

    if (representation.origin == RepresentationOrigin.translated ||
        representation.origin == RepresentationOrigin.derived) {
      final sourceId = representation.sourceRepresentationId;
      if (sourceId == null || !_hasRepresentation(sourceId)) {
        throw StateError(
          'Source representation for derived content must exist on the story.',
        );
      }
    }

    if (representation.origin == RepresentationOrigin.original &&
        representation.language != _originalLanguage) {
      throw StateError(
        'Original representation language must match story original language.',
      );
    }

    _representations.add(representation);
    _provenance = _provenance.append(
      ProvenanceStep(
        transformationType: transformationType,
        producedRepresentationId: representation.id,
        sourceRepresentationId: representation.sourceRepresentationId,
        occurredAt: at ?? DateTime.now(),
        isAiAssisted: representation.isAiGenerated,
      ),
    );

    _touch(at);
    raise(
      StoryRepresentationAdded(
        storyId: id,
        representationId: representation.id,
      ),
    );
  }

  void approveRepresentation(StoryRepresentationId representationId) {
    final index = _representations.indexWhere((r) => r.id == representationId);
    if (index < 0) {
      throw StateError(
        'Representation ${representationId.value} not found on story.',
      );
    }

    final current = _representations[index];
    if (!current.isAiGenerated) {
      return;
    }

    if (current.isApproved) {
      return;
    }

    _representations[index] = current.approve();
    _touch();
    raise(
      StoryRepresentationApproved(
        storyId: id,
        representationId: representationId,
      ),
    );
  }

  /// Human edit of an unapproved representation (HS.5 / D5).
  ///
  /// Does not mutate canonical narrative. Approved representations cannot be
  /// edited in place — regenerate a new derived representation instead.
  void replaceUnapprovedRepresentationText({
    required StoryRepresentationId representationId,
    required String textContent,
    DateTime? at,
  }) {
    final index = _representations.indexWhere((r) => r.id == representationId);
    if (index < 0) {
      throw StateError(
        'Representation ${representationId.value} not found on story.',
      );
    }

    final current = _representations[index];
    if (current.isApproved) {
      throw StateError(
        'Cannot edit an approved representation in place; regenerate instead.',
      );
    }

    final trimmed = textContent.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Replacement text content cannot be empty.');
    }

    final when = at ?? DateTime.now();
    final updated = current.withTextContent(trimmed);
    _representations[index] = updated;
    _provenance = _provenance.append(
      ProvenanceStep(
        transformationType: StoryTransformationType.editing,
        producedRepresentationId: updated.id,
        sourceRepresentationId: updated.sourceRepresentationId ?? updated.id,
        occurredAt: when,
        isAiAssisted: false,
        note: 'Human edit of unapproved representation',
      ),
    );
    _touch(when);
  }

  StoryRepresentation? findRepresentation(StoryRepresentationId id) {
    for (final representation in _representations) {
      if (representation.id == id) {
        return representation;
      }
    }
    return null;
  }

  bool _hasRepresentation(StoryRepresentationId id) =>
      _representations.any((r) => r.id == id);

  void _transitionTo(StoryLifecycleStatus next) {
    if (!_lifecycleStatus.canTransitionTo(next)) {
      throw StateError(
        'Invalid story lifecycle transition: '
        '${_lifecycleStatus.name} -> ${next.name}',
      );
    }
    _lifecycleStatus = next;
  }

  void _ensureEditable() {
    if (_lifecycleStatus == StoryLifecycleStatus.published ||
        _lifecycleStatus == StoryLifecycleStatus.archived ||
        _lifecycleStatus == StoryLifecycleStatus.removed ||
        _lifecycleStatus == StoryLifecycleStatus.suspended) {
      throw StateError(
        'Cannot edit narrative while story is ${_lifecycleStatus.name}.',
      );
    }
  }

  void _touch([DateTime? at]) {
    _updatedAt = at ?? DateTime.now();
  }
}
