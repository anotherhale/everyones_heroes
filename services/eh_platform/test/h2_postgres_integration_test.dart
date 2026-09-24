import 'dart:convert';
import 'dart:io';

import 'package:eh_platform/eh_platform.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import 'support/platform_paths.dart';

void main() {
  final dbUrl = Platform.environment['EH_DATABASE_URL'] ??
      'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform';

  group('H.2 PostgreSQL vertical integration', () {
    late PlatformComposition composition;
    late http.Client client;
    late Uri base;
    late String root;

    setUpAll(() async {
      root = ehPlatformRoot();
      // Ensure a clean schema for this suite when possible.
      final database = await PlatformDatabase.connect(dbUrl);
      await MigrationRunner(
        database: database,
        migrationsDirectory: '$root/migrations',
      ).applyPending();
      await database.close();
    });

    setUp(() async {
      final config = PlatformConfig.testing(
        databaseUrl: dbUrl,
        environment: 'test',
        devAuthToken: 'pg-h2-token',
        devUserId: '00000000-0000-4000-8000-0000000000bb',
        devUserDisplayName: 'PG H2 User',
      );

      composition = await PlatformComposition.bootstrap(
        config: config,
        migrationsDirectory: '$root/migrations',
      );

      // Isolate test data for this user.
      await composition.database.connection.execute(
        r'DELETE FROM reflections WHERE user_id = $1::uuid',
        parameters: [config.devUserId],
      );
      await composition.database.connection.execute(
        r'DELETE FROM journeys WHERE user_id = $1::uuid',
        parameters: [config.devUserId],
      );
      await composition.database.connection.execute(
        r'DELETE FROM command_idempotency WHERE user_id = $1::uuid',
        parameters: [config.devUserId],
      );

      final server = await shelf_io.serve(composition.handler, 'localhost', 0);
      base = Uri.parse('http://localhost:${server.port}');
      client = http.Client();
      addTearDown(() async {
        client.close();
        await server.close(force: true);
        await composition.close();
      });
    });

    test('HTTP → PF.3 Identity → Domain → PostgreSQL submit reflection',
        () async {
      Future<http.Response> post(String path, Map<String, Object?> body) {
        return client.post(
          base.replace(path: path),
          headers: {
            'content-type': 'application/json',
            'authorization': 'Bearer pg-h2-token',
            'Idempotency-Key': 'pg-$path-${body.hashCode}',
          },
          body: jsonEncode(body),
        );
      }

      final journey = await post('/v1/journeys', {
        'vision': 'Persist understanding in PostgreSQL',
      });
      expect(journey.statusCode, 201, reason: journey.body);
      final journeyId =
          (jsonDecode(journey.body) as Map)['journeyId'] as String;

      final rows = await composition.database.connection.execute(
        r'SELECT id FROM journeys WHERE id = $1',
        parameters: [journeyId],
      );
      expect(rows.length, 1);

      final reflection = await post('/v1/reflections', {
        'journeyId': journeyId,
      });
      expect(reflection.statusCode, 201, reason: reflection.body);
      final reflectionId =
          (jsonDecode(reflection.body) as Map)['reflectionId'] as String;

      final response = await post('/v1/reflections/$reflectionId/responses', {
        'type': 'emoji',
        'emotion': 'calm',
      });
      expect(response.statusCode, 200, reason: response.body);

      final submit = await post('/v1/reflections/$reflectionId/submit', {});
      expect(submit.statusCode, 200, reason: submit.body);

      final reflectionRows = await composition.database.connection.execute(
        r'''
SELECT submitted_at, jsonb_array_length(behavioral_evidence)
FROM reflections WHERE id = $1
''',
        parameters: [reflectionId],
      );
      expect(reflectionRows.first[0], isNotNull);
      expect(reflectionRows.first[1] as int, greaterThan(0));

      final understanding = await client.get(
        base.replace(path: '/v1/understanding/current'),
        headers: {'authorization': 'Bearer pg-h2-token'},
      );
      expect(understanding.statusCode, 200);
      expect((jsonDecode(understanding.body) as Map)['journeyId'], journeyId);

      // PF.3 health + identity still available.
      final health = await client.get(base.replace(path: '/health'));
      expect(health.statusCode, 200);
      final me = await client.get(
        base.replace(path: '/v1/me'),
        headers: {'authorization': 'Bearer pg-h2-token'},
      );
      expect(me.statusCode, 200);
    });

    test('missing reflection submit fails without corrupting store', () async {
      final before = await composition.database.connection.execute(
        'SELECT count(*) FROM reflections',
      );
      final response = await client.post(
        base.replace(path: '/v1/reflections/missing-id/submit'),
        headers: {
          'content-type': 'application/json',
          'authorization': 'Bearer pg-h2-token',
        },
        body: '{}',
      );
      expect(response.statusCode, anyOf(400, 404));
      final after = await composition.database.connection.execute(
        'SELECT count(*) FROM reflections',
      );
      expect(after.first[0], before.first[0]);
    });

    test('clean migration sequence includes PF.3 + H.2 tables', () async {
      final tables = await composition.database.connection.execute('''
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'identity_users', 'identity_sessions', 'command_idempotency',
    'schema_migrations', 'journeys', 'reflections',
    'discoverable_story_candidates'
  )
ORDER BY table_name
''');
      final names = tables.map((row) => row[0] as String).toList();
      expect(
        names,
        containsAll([
          'command_idempotency',
          'discoverable_story_candidates',
          'identity_sessions',
          'identity_users',
          'journeys',
          'reflections',
          'schema_migrations',
        ]),
      );

      final versions = await composition.database.connection.execute(
        'SELECT version FROM schema_migrations ORDER BY version',
      );
      final versionNames = versions.map((r) => r[0] as String).toList();
      expect(versionNames, contains('001_platform_foundation.sql'));
      expect(versionNames, contains('002_h2_life_journey.sql'));
      expect(versionNames, contains('003_j2_discoverable_story_candidates.sql'));
    });
  });
}
