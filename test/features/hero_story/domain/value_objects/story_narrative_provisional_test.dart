import 'package:everyonesheroes/features/hero_story/domain/value_objects/story_narrative.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provisional narrative is flagged and non-empty', () {
    final narrative = StoryNarrative.provisional();
    expect(narrative.isProvisional, isTrue);
    expect(narrative.value.isNotEmpty, isTrue);
  });

  test('authored narrative is not provisional', () {
    final narrative = StoryNarrative('I rebuilt meaning after loss.');
    expect(narrative.isProvisional, isFalse);
  });
}
