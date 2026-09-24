import 'dart:convert';

import 'package:eh_platform/src/api/hero_story_api.dart';
import 'package:eh_platform/src/api/middleware/correlation_middleware.dart';
import 'package:eh_platform/src/hero_story/application/use_cases/project_discoverable_story_candidate_use_case.dart';
import 'package:eh_platform/src/hero_story/domain/models/story_candidate_eligibility_facts.dart';
import 'package:eh_platform/src/identity/domain/authenticated_principal.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

Map<String, Object?> _eligibleBody({
  String storyId = 'story-ingest-1',
  String lifecycleStatus = 'published',
  String storyVisibility = 'public',
  String heroVisibility = 'public',
  List<String> themeIds = const ['discovery', 'purpose'],
}) {
  return {
    'storyId': storyId,
    'heroId': 'hero-1',
    'title': 'Ingested Finding Direction',
    'themeIds': themeIds,
    'updatedAt': '2026-06-01T00:00:00.000Z',
    'lifecycleStatus': lifecycleStatus,
    'storyVisibility': storyVisibility,
    'hasProvisionalNarrative': false,
    'hasAuthoritativeRepresentation': true,
    'heroStatus': 'active',
    'heroVisibility': heroVisibility,
  };
}

Handler _handler({
  required ProjectDiscoverableStoryCandidateUseCase project,
  AuthenticatedPrincipal? principal,
}) {
  final api = HeroStoryApi(projectCandidate: project);
  return const Pipeline()
      .addMiddleware(correlationMiddleware())
      .addMiddleware((inner) {
        return (request) {
          if (principal == null) {
            return inner(request);
          }
          return inner(
            request.change(
              context: {
                ...request.context,
                principalContextKey: principal,
              },
            ),
          );
        };
      })
      .addHandler(api.router.call);
}

void main() {
  group('J.2 Slice 5 HeroStoryApi candidate ingest', () {
    late InMemoryDiscoverableStoryCandidateProjection projection;
    late ProjectDiscoverableStoryCandidateUseCase project;
    late AuthenticatedPrincipal principal;

    setUp(() {
      projection = InMemoryDiscoverableStoryCandidateProjection();
      project = ProjectDiscoverableStoryCandidateUseCase(
        projection: projection,
      );
      principal = AuthenticatedPrincipal(
        userId: UserId('user-ingest'),
        displayName: 'Ingest',
      );
    });

    test('valid request projects eligible candidate', () async {
      final server = await shelf_io.serve(
        _handler(project: project, principal: principal),
        '127.0.0.1',
        0,
      );
      addTearDown(() => server.close(force: true));

      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:${server.port}/v1/hero-story/candidates/story-ingest-1',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(_eligibleBody()),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['wasUpserted'], isTrue);
      expect(body['storyId'], 'story-ingest-1');
      expect(await projection.exists('story-ingest-1'), isTrue);
    });

    test('ineligible facts remove / omit candidate', () async {
      await project.execute(
        StoryCandidateEligibilityFacts.fromJson(_eligibleBody()),
      );
      expect(await projection.exists('story-ingest-1'), isTrue);

      final server = await shelf_io.serve(
        _handler(project: project, principal: principal),
        '127.0.0.1',
        0,
      );
      addTearDown(() => server.close(force: true));

      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:${server.port}/v1/hero-story/candidates/story-ingest-1',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(_eligibleBody(lifecycleStatus: 'archived')),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['wasUpserted'], isFalse);
      expect(body['reason'], 'story_not_published');
      expect(await projection.exists('story-ingest-1'), isFalse);
    });

    test('invalid request returns 400', () async {
      final server = await shelf_io.serve(
        _handler(project: project, principal: principal),
        '127.0.0.1',
        0,
      );
      addTearDown(() => server.close(force: true));

      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:${server.port}/v1/hero-story/candidates/story-ingest-1',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'title': 'missing required fields'}),
      );

      expect(response.statusCode, 400);
      expect(response.body, contains('validation_error'));
    });

    test('storyId path/body mismatch returns 400', () async {
      final server = await shelf_io.serve(
        _handler(project: project, principal: principal),
        '127.0.0.1',
        0,
      );
      addTearDown(() => server.close(force: true));

      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:${server.port}/v1/hero-story/candidates/path-id',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(_eligibleBody(storyId: 'body-id')),
      );

      expect(response.statusCode, 400);
      expect(response.body, contains('must match path'));
    });

    test('unauthenticated request returns 401', () async {
      final server = await shelf_io.serve(
        _handler(project: project),
        '127.0.0.1',
        0,
      );
      addTearDown(() => server.close(force: true));

      final response = await http.put(
        Uri.parse(
          'http://127.0.0.1:${server.port}/v1/hero-story/candidates/story-ingest-1',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(_eligibleBody()),
      );

      expect(response.statusCode, 401);
    });

    test('repeated ingest is idempotent', () async {
      final server = await shelf_io.serve(
        _handler(project: project, principal: principal),
        '127.0.0.1',
        0,
      );
      addTearDown(() => server.close(force: true));

      final uri = Uri.parse(
        'http://127.0.0.1:${server.port}/v1/hero-story/candidates/story-ingest-1',
      );
      final headers = {'content-type': 'application/json'};
      final body = jsonEncode(_eligibleBody(themeIds: const ['courage']));

      final first = await http.put(uri, headers: headers, body: body);
      final second = await http.put(uri, headers: headers, body: body);
      expect(first.statusCode, 200);
      expect(second.statusCode, 200);
      expect(await projection.listCandidates(), hasLength(1));
      expect((await projection.listCandidates()).single.themeIds, ['courage']);
    });
  });
}
