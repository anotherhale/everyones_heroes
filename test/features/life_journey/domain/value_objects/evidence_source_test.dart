import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/ids/reflection_id.dart';
import 'package:everyonesheroes/features/life_journey/domain/value_objects/evidence_source.dart';

void main() {
  group('ReflectionEvidenceSource', () {
    test('stores reflection id', () {
      final source = ReflectionEvidenceSource(
        reflectionId: ReflectionId('reflection-1'),
      );

      expect(source.reflectionId, ReflectionId('reflection-1'));
    });
    test('sources with same reflection id are equal', () {
      expect(
        ReflectionEvidenceSource(reflectionId: ReflectionId('r1')),
        equals(ReflectionEvidenceSource(reflectionId: ReflectionId('r1'))),
      );
    });
  });

  group('MissionEvidenceSource', () {
    test('stores mission id', () {
      final source = MissionEvidenceSource(missionId: MissionId('mission-1'));

      expect(source.missionId, MissionId('mission-1'));
    });
    test('sources with same mission id are equal', () {
      expect(
        MissionEvidenceSource(missionId: MissionId('m1')),
        equals(MissionEvidenceSource(missionId: MissionId('m1'))),
      );
    });
  });
}
