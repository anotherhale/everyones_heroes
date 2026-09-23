import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/life_journey/application/models/adaptive_experience.dart';
import 'package:everyonesheroes/features/life_journey/application/use_cases/platform_get_today_experience_use_case.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/eh_platform_client.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/today_experience_cache.dart';
import 'package:everyonesheroes/features/life_journey/infrastructure/platform/today_experience_dto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('TodayExperienceDto', () {
    test('maps platform JSON to AdaptiveExperience', () {
      final dto = TodayExperienceDto.fromJson({
        'experienceId': 'consistency-next-step',
        'experienceType': 'reflection',
        'title': 'Keep Showing Up',
        'description': 'Take one small step today.',
        'action': 'begin',
        'rationale': 'You have been building consistency.',
        'journeyId': 'j1',
        'explanation': {
          'sources': [
            {'kind': 'behavior_pattern', 'value': 'consistency'},
          ],
        },
        'target': null,
      });

      final experience = dto.toAdaptiveExperience();
      expect(experience.id, 'consistency-next-step');
      expect(experience.type, ExperienceType.reflection);
      expect(experience.rationale, 'You have been building consistency.');
      expect(dto.explanationSources.first.value, 'consistency');
    });

    test('maps story target', () {
      final dto = TodayExperienceDto.fromJson({
        'experienceId': 'adaptive-story-s1',
        'experienceType': 'story',
        'title': 'Rising Again',
        'description': 'A story that connects.',
        'action': 'begin',
        'journeyId': 'j1',
        'explanation': {'sources': []},
        'target': {'kind': 'story', 'storyId': 's1'},
      });

      expect(dto.storyTargetId, 's1');
      expect(dto.toAdaptiveExperience().type, ExperienceType.story);
    });
  });

  group('PlatformGetTodayExperienceUseCase', () {
    test('returns platform DTO without local selection', () async {
      final client = EhPlatformClient(
        baseUrl: Uri.parse('http://platform.test'),
        authToken: 'token',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/v1/experiences/today');
          expect(request.headers['authorization'], 'Bearer token');
          return http.Response(
            '{"experienceId":"default-reflection","experienceType":"reflection",'
            '"title":"Take the Next Step","description":"Reflect.",'
            '"action":"begin","journeyId":"j1","explanation":{"sources":[]},'
            '"target":null}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final useCase = PlatformGetTodayExperienceUseCase(client: client);
      final result = await useCase.execute();
      expect(result, isA<Success<AdaptiveExperience>>());
      final experience = (result as Success<AdaptiveExperience>).value;
      expect(experience.id, 'default-reflection');
    });

    test('404 maps to unavailable journey failure', () async {
      final client = EhPlatformClient(
        baseUrl: Uri.parse('http://platform.test'),
        authToken: 'token',
        httpClient: MockClient((request) async {
          return http.Response(
            '{"error":{"code":"not_found","message":"No current journey"}}',
            404,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final useCase = PlatformGetTodayExperienceUseCase(client: client);
      final result = await useCase.execute();
      expect(result, isA<Failure>());
    });

    test('uses cache on network failure without local invent', () async {
      var calls = 0;
      final cache = TodayExperienceCache();
      final client = EhPlatformClient(
        baseUrl: Uri.parse('http://platform.test'),
        authToken: 'token',
        httpClient: MockClient((request) async {
          calls++;
          if (calls == 1) {
            return http.Response(
              '{"experienceId":"consistency-next-step","experienceType":"reflection",'
              '"title":"Keep Showing Up","description":"Step.",'
              '"action":"begin","journeyId":"j1","explanation":{"sources":[]},'
              '"target":null}',
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          throw const SocketException('offline');
        }),
      );

      final useCase = PlatformGetTodayExperienceUseCase(
        client: client,
        cache: cache,
      );

      final first = await useCase.execute();
      expect((first as Success<AdaptiveExperience>).value.id,
          'consistency-next-step');
      expect(cache.lastReadWasStale, isFalse);

      final second = await useCase.execute();
      expect((second as Success<AdaptiveExperience>).value.id,
          'consistency-next-step');
      expect(cache.lastReadWasStale, isTrue);
    });

    test('unavailable when offline and no cache', () async {
      final client = EhPlatformClient(
        baseUrl: Uri.parse('http://platform.test'),
        authToken: 'token',
        httpClient: MockClient((request) async {
          throw const SocketException('offline');
        }),
      );

      final useCase = PlatformGetTodayExperienceUseCase(client: client);
      final result = await useCase.execute();
      expect(result, isA<Failure>());
    });
  });
}
