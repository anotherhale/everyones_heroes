import 'package:eh_platform/src/hero_story/domain/models/story_candidate_eligibility_facts.dart';
import 'package:eh_platform/src/hero_story/domain/services/adaptive_story_candidate_eligibility_policy.dart';
import 'package:test/test.dart';

StoryCandidateEligibilityFacts _facts({
  String lifecycleStatus = 'published',
  String storyVisibility = 'public',
  bool hasProvisionalNarrative = false,
  bool hasAuthoritativeRepresentation = true,
  String heroStatus = 'active',
  String heroVisibility = 'public',
  List<String> themeIds = const ['courage'],
}) {
  return StoryCandidateEligibilityFacts(
    storyId: 'story-1',
    heroId: 'hero-1',
    title: 'A Story',
    themeIds: themeIds,
    updatedAt: DateTime.utc(2026, 6, 1),
    lifecycleStatus: lifecycleStatus,
    storyVisibility: storyVisibility,
    hasProvisionalNarrative: hasProvisionalNarrative,
    hasAuthoritativeRepresentation: hasAuthoritativeRepresentation,
    heroStatus: heroStatus,
    heroVisibility: heroVisibility,
  );
}

void main() {
  group('AdaptiveStoryCandidateEligibilityPolicy', () {
    test('eligible published/public Story with discoverable Hero', () {
      final result =
          AdaptiveStoryCandidateEligibilityPolicy.evaluate(_facts());
      expect(result.isEligible, isTrue);
      expect(result.catalogThemeIds, ['courage']);
    });

    test('eligible published/community Story with community Hero', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(
          storyVisibility: 'community',
          heroVisibility: 'community',
        ),
      );
      expect(result.isEligible, isTrue);
    });

    test('unpublished Story is ineligible', () {
      for (final status in [
        'draft',
        'processing',
        'review',
        'approved',
        'archived',
        'rejected',
        'suspended',
        'removed',
      ]) {
        final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
          _facts(lifecycleStatus: status),
        );
        expect(result.isEligible, isFalse, reason: status);
        expect(result.reason, 'story_not_published');
      }
    });

    test('private Story is ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(storyVisibility: 'private'),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'story_visibility_not_discoverable');
    });

    test('unlisted Story is ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(storyVisibility: 'unlisted'),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'story_visibility_not_discoverable');
    });

    test('provisional narrative is ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(hasProvisionalNarrative: true),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'provisional_narrative');
    });

    test('missing Discovery theme is ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(themeIds: const []),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'missing_catalog_theme');
    });

    test('invalid/unknown theme IDs only → ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(themeIds: const ['not-a-real-theme', 'invented']),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'missing_catalog_theme');
    });

    test('mix of valid + invalid themes keeps only catalog IDs', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(themeIds: const ['courage', 'not-a-real-theme', 'purpose']),
      );
      expect(result.isEligible, isTrue);
      expect(result.catalogThemeIds, ['courage', 'purpose']);
    });

    test('inactive Hero is ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(heroStatus: 'archived'),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'hero_not_active');
    });

    test('private Hero is ineligible', () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(heroVisibility: 'private'),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'hero_visibility_not_discoverable');
    });

    test('authoritativeRepresentationsOnly: missing authoritative → ineligible',
        () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(hasAuthoritativeRepresentation: false),
      );
      expect(result.isEligible, isFalse);
      expect(result.reason, 'missing_authoritative_representation');
    });

    test('authoritativeRepresentationsOnly: present authoritative → eligible',
        () {
      final result = AdaptiveStoryCandidateEligibilityPolicy.evaluate(
        _facts(hasAuthoritativeRepresentation: true),
      );
      expect(result.isEligible, isTrue);
    });
  });
}
