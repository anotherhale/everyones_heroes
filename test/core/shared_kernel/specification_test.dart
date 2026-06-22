import 'package:everyonesheroes/core/shared_kernel/specification/specification.dart';
import 'package:everyonesheroes/core/shared_kernel/specification/specification_extensions.dart';

import 'package:flutter_test/flutter_test.dart';

final class EvenNumberSpecification implements Specification<int> {
  @override
  bool isSatisfiedBy(int candidate) {
    return candidate.isEven;
  }
}

final class PositiveNumberSpecification implements Specification<int> {
  @override
  bool isSatisfiedBy(int candidate) {
    return candidate > 0;
  }
}

final class GreaterThanTenSpecification implements Specification<int> {
  @override
  bool isSatisfiedBy(int candidate) {
    return candidate > 10;
  }
}

void main() {
  group('Specification', () {
    group('base specifications', () {
      test('even specification accepts even number', () {
        final spec = EvenNumberSpecification();

        expect(spec.isSatisfiedBy(4), isTrue);
      });

      test('even specification rejects odd number', () {
        final spec = EvenNumberSpecification();

        expect(spec.isSatisfiedBy(5), isFalse);
      });

      test('positive specification accepts positive number', () {
        final spec = PositiveNumberSpecification();

        expect(spec.isSatisfiedBy(1), isTrue);
      });

      test('positive specification rejects negative number', () {
        final spec = PositiveNumberSpecification();

        expect(spec.isSatisfiedBy(-1), isFalse);
      });
    });

    group('and()', () {
      test('returns true when both specifications are satisfied', () {
        final spec = EvenNumberSpecification().and(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(10), isTrue);
      });

      test('returns false when left specification fails', () {
        final spec = EvenNumberSpecification().and(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(9), isFalse);
      });

      test('returns false when right specification fails', () {
        final spec = EvenNumberSpecification().and(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(-10), isFalse);
      });

      test('returns false when both specifications fail', () {
        final spec = EvenNumberSpecification().and(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(-9), isFalse);
      });
    });

    group('or()', () {
      test('returns true when both specifications pass', () {
        final spec = EvenNumberSpecification().or(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(8), isTrue);
      });

      test('returns true when left specification passes', () {
        final spec = EvenNumberSpecification().or(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(-8), isTrue);
      });

      test('returns true when right specification passes', () {
        final spec = EvenNumberSpecification().or(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(9), isTrue);
      });

      test('returns false when neither specification passes', () {
        final spec = EvenNumberSpecification().or(
          PositiveNumberSpecification(),
        );

        expect(spec.isSatisfiedBy(-9), isFalse);
      });
    });

    group('not()', () {
      test('inverts a satisfied specification', () {
        final spec = EvenNumberSpecification().not();

        expect(spec.isSatisfiedBy(4), isFalse);
      });

      test('inverts an unsatisfied specification', () {
        final spec = EvenNumberSpecification().not();

        expect(spec.isSatisfiedBy(5), isTrue);
      });
    });

    group('complex composition', () {
      test('supports chained specifications', () {
        final spec = EvenNumberSpecification()
            .and(PositiveNumberSpecification())
            .and(GreaterThanTenSpecification());

        expect(spec.isSatisfiedBy(12), isTrue);

        expect(spec.isSatisfiedBy(8), isFalse);

        expect(spec.isSatisfiedBy(-12), isFalse);
      });

      test('supports mixed and/or composition', () {
        final spec = EvenNumberSpecification()
            .and(PositiveNumberSpecification())
            .or(GreaterThanTenSpecification());

        expect(spec.isSatisfiedBy(12), isTrue);

        expect(spec.isSatisfiedBy(8), isTrue);

        expect(spec.isSatisfiedBy(11), isTrue);

        expect(spec.isSatisfiedBy(-3), isFalse);
      });
    });
  });
}
