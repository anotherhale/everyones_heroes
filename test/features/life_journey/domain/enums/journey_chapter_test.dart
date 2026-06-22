import 'package:flutter_test/flutter_test.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/journey_chapter.dart';

void main() {
  group('JourneyChapter.next', () {
    test(
      'awakening advances to commitment',
      () {
        expect(
          JourneyChapter.awakening.next,
          JourneyChapter.commitment,
        );
      },
    );

    test(
      'commitment advances to resistance',
      () {
        expect(
          JourneyChapter.commitment.next,
          JourneyChapter.resistance,
        );
      },
    );

    test(
      'resistance advances to momentum',
      () {
        expect(
          JourneyChapter.resistance.next,
          JourneyChapter.momentum,
        );
      },
    );

    test(
      'momentum advances to transformation',
      () {
        expect(
          JourneyChapter.momentum.next,
          JourneyChapter.transformation,
        );
      },
    );

    test(
      'transformation advances to contribution',
      () {
        expect(
          JourneyChapter.transformation.next,
          JourneyChapter.contribution,
        );
      },
    );

    test(
      'contribution has no next chapter',
      () {
        expect(
          JourneyChapter.contribution.next,
          isNull,
        );
      },
    );
  });

  group('JourneyChapter.canAdvanceTo', () {
    test(
      'awakening can advance to commitment',
      () {
        expect(
          JourneyChapter.awakening.canAdvanceTo(
            JourneyChapter.commitment,
          ),
          isTrue,
        );
      },
    );

    test(
      'commitment can advance to resistance',
      () {
        expect(
          JourneyChapter.commitment.canAdvanceTo(
            JourneyChapter.resistance,
          ),
          isTrue,
        );
      },
    );

    test(
      'resistance can advance to momentum',
      () {
        expect(
          JourneyChapter.resistance.canAdvanceTo(
            JourneyChapter.momentum,
          ),
          isTrue,
        );
      },
    );

    test(
      'momentum can advance to transformation',
      () {
        expect(
          JourneyChapter.momentum.canAdvanceTo(
            JourneyChapter.transformation,
          ),
          isTrue,
        );
      },
    );

    test(
      'transformation can advance to contribution',
      () {
        expect(
          JourneyChapter.transformation.canAdvanceTo(
            JourneyChapter.contribution,
          ),
          isTrue,
        );
      },
    );
  });

  group('JourneyChapter prevents skipping', () {
    test(
      'awakening cannot advance to resistance',
      () {
        expect(
          JourneyChapter.awakening.canAdvanceTo(
            JourneyChapter.resistance,
          ),
          isFalse,
        );
      },
    );

    test(
      'awakening cannot advance to momentum',
      () {
        expect(
          JourneyChapter.awakening.canAdvanceTo(
            JourneyChapter.momentum,
          ),
          isFalse,
        );
      },
    );

    test(
      'awakening cannot advance to transformation',
      () {
        expect(
          JourneyChapter.awakening.canAdvanceTo(
            JourneyChapter.transformation,
          ),
          isFalse,
        );
      },
    );

    test(
      'awakening cannot advance to contribution',
      () {
        expect(
          JourneyChapter.awakening.canAdvanceTo(
            JourneyChapter.contribution,
          ),
          isFalse,
        );
      },
    );
  });

  group('JourneyChapter prevents regression', () {
    test(
      'commitment cannot advance to awakening',
      () {
        expect(
          JourneyChapter.commitment.canAdvanceTo(
            JourneyChapter.awakening,
          ),
          isFalse,
        );
      },
    );

    test(
      'resistance cannot advance to commitment',
      () {
        expect(
          JourneyChapter.resistance.canAdvanceTo(
            JourneyChapter.commitment,
          ),
          isFalse,
        );
      },
    );

    test(
      'momentum cannot advance to resistance',
      () {
        expect(
          JourneyChapter.momentum.canAdvanceTo(
            JourneyChapter.resistance,
          ),
          isFalse,
        );
      },
    );

    test(
      'transformation cannot advance to momentum',
      () {
        expect(
          JourneyChapter.transformation.canAdvanceTo(
            JourneyChapter.momentum,
          ),
          isFalse,
        );
      },
    );

    test(
      'contribution cannot advance to transformation',
      () {
        expect(
          JourneyChapter.contribution.canAdvanceTo(
            JourneyChapter.transformation,
          ),
          isFalse,
        );
      },
    );
  });

  group('JourneyChapter.isFinalChapter', () {
    test(
      'awakening is not final',
      () {
        expect(
          JourneyChapter.awakening.isFinalChapter,
          isFalse,
        );
      },
    );

    test(
      'commitment is not final',
      () {
        expect(
          JourneyChapter.commitment.isFinalChapter,
          isFalse,
        );
      },
    );

    test(
      'resistance is not final',
      () {
        expect(
          JourneyChapter.resistance.isFinalChapter,
          isFalse,
        );
      },
    );

    test(
      'momentum is not final',
      () {
        expect(
          JourneyChapter.momentum.isFinalChapter,
          isFalse,
        );
      },
    );

    test(
      'transformation is not final',
      () {
        expect(
          JourneyChapter.transformation.isFinalChapter,
          isFalse,
        );
      },
    );

    test(
      'contribution is final',
      () {
        expect(
          JourneyChapter.contribution.isFinalChapter,
          isTrue,
        );
      },
    );
  });
}