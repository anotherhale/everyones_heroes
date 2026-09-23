import 'dart:convert';
import 'dart:io';

import 'package:eh_platform/eh_platform.dart';
import 'package:test/test.dart';

import '../support/platform_paths.dart';

void main() {
  late PlatformComposition composition;
  late PlatformServer server;
  late HttpClient client;
  late Uri baseUri;

  setUpAll(() async {
    final root = ehPlatformRoot();
    final config = PlatformConfig.testing(
      databaseUrl: Platform.environment['EH_DATABASE_URL'] ??
          'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform',
      port: 0,
      environment: 'test',
      devAuthToken: 'test-token',
      devUserId: '00000000-0000-4000-8000-000000000099',
      devUserDisplayName: 'Test User',
    );

    composition = await PlatformComposition.bootstrap(
      config: config,
      migrationsDirectory: '$root/migrations',
      openApiDocumentPath: '$root/openapi/openapi.v1.json',
      clock: FixedClock(DateTime.utc(2026, 9, 23, 12)),
      logger: PlatformLogger(minLevel: LogLevel.error),
    );
    server = PlatformServer(composition: composition);
    final httpServer = await server.start();
    baseUri = Uri.parse('http://127.0.0.1:${httpServer.port}');
    client = HttpClient();
  });

  tearDownAll(() async {
    client.close(force: true);
    await server.stop();
  });

  Future<HttpClientResponse> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final request = await client.getUrl(baseUri.replace(path: path));
    headers?.forEach(request.headers.set);
    return request.close();
  }

  Future<Map<String, dynamic>> readJson(HttpClientResponse response) async {
    final body = await response.transform(utf8.decoder).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  group('API health/readiness', () {
    test('GET /health returns ok', () async {
      final response = await get('/health');
      expect(response.statusCode, 200);
      final json = await readJson(response);
      expect(json['status'], 'ok');
      expect(json['service'], 'eh_platform');
      expect(response.headers.value('x-correlation-id'), isNotNull);
    });

    test('GET /ready returns ready when database is up', () async {
      final response = await get('/ready');
      expect(response.statusCode, 200);
      final json = await readJson(response);
      expect(json['status'], 'ready');
      expect((json['checks'] as Map)['database'], 'ok');
    });

    test('GET /v1/openapi.json returns OpenAPI document', () async {
      final response = await get('/v1/openapi.json');
      expect(response.statusCode, 200);
      final json = await readJson(response);
      expect(json['openapi'], startsWith('3.'));
    });
  });

  group('Identity authenticated hello', () {
    test('GET /v1/me requires auth', () async {
      final response = await get('/v1/me');
      expect(response.statusCode, 401);
      final json = await readJson(response);
      expect(json['error']['code'], 'unauthenticated');
    });

    test('GET /v1/me returns principal with bearer token', () async {
      final response = await get(
        '/v1/me',
        headers: {'Authorization': 'Bearer test-token'},
      );
      expect(response.statusCode, 200);
      final json = await readJson(response);
      expect(json['userId'], '00000000-0000-4000-8000-000000000099');
      expect(json['displayName'], 'Test User');
    });

    test('echoes incoming correlation id', () async {
      final response = await get(
        '/health',
        headers: {'X-Correlation-Id': 'fixed-correlation'},
      );
      expect(response.headers.value('x-correlation-id'), 'fixed-correlation');
    });
  });
}
