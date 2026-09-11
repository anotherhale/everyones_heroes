import 'package:everyonesheroes/features/hero_story/domain/enums/story_lifecycle_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('draft can move to processing', () {
    expect(
      StoryLifecycleStatus.draft.canTransitionTo(
        StoryLifecycleStatus.processing,
      ),
      isTrue,
    );
  });

  test('published cannot move directly to approved', () {
    expect(
      StoryLifecycleStatus.published.canTransitionTo(
        StoryLifecycleStatus.approved,
      ),
      isFalse,
    );
  });
}
