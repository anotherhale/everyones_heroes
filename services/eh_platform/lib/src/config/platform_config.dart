import 'dart:io';

/// Server configuration for the EH Platform modular monolith.
///
/// Secrets must come from the environment — never committed.
final class PlatformConfig {
  const PlatformConfig({
    required this.environment,
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.logLevel,
    required this.devAuthToken,
    required this.devUserId,
    required this.devUserDisplayName,
    required this.aiMode,
    this.openAiApiKey,
  });

  factory PlatformConfig.fromEnvironment({Map<String, String>? environment}) {
    final env = environment ?? Platform.environment;
    final databaseUrl = env['EH_DATABASE_URL']?.trim();
    if (databaseUrl == null || databaseUrl.isEmpty) {
      throw StateError(
        'EH_DATABASE_URL is required (postgres://user:pass@host:port/db).',
      );
    }

    return PlatformConfig(
      environment: _nonEmpty(env['EH_ENV'], 'development'),
      host: _nonEmpty(env['EH_HTTP_HOST'], '0.0.0.0'),
      port: int.tryParse(env['EH_HTTP_PORT'] ?? '') ?? 8080,
      databaseUrl: databaseUrl,
      logLevel: _nonEmpty(env['EH_LOG_LEVEL'], 'info'),
      devAuthToken: _nonEmpty(
        env['EH_DEV_AUTH_TOKEN'],
        'dev-platform-token',
      ),
      devUserId: _nonEmpty(
        env['EH_DEV_USER_ID'],
        '00000000-0000-4000-8000-000000000001',
      ),
      devUserDisplayName: _nonEmpty(
        env['EH_DEV_USER_DISPLAY_NAME'],
        'Dev User',
      ),
      aiMode: _nonEmpty(env['EH_AI_MODE'], 'stub'),
      openAiApiKey: env['OPENAI_API_KEY']?.trim().isNotEmpty == true
          ? env['OPENAI_API_KEY']!.trim()
          : null,
    );
  }

  /// Safe defaults for unit tests that do not touch a live database.
  factory PlatformConfig.testing({
    String databaseUrl = 'postgres://eh:eh_dev@127.0.0.1:5432/eh_platform',
    String environment = 'test',
    int port = 0,
    String devAuthToken = 'test-token',
    String devUserId = '00000000-0000-4000-8000-000000000099',
    String devUserDisplayName = 'Test User',
    String aiMode = 'stub',
  }) {
    return PlatformConfig(
      environment: environment,
      host: '127.0.0.1',
      port: port,
      databaseUrl: databaseUrl,
      logLevel: 'warning',
      devAuthToken: devAuthToken,
      devUserId: devUserId,
      devUserDisplayName: devUserDisplayName,
      aiMode: aiMode,
    );
  }

  final String environment;
  final String host;
  final int port;
  final String databaseUrl;
  final String logLevel;
  final String devAuthToken;
  final String devUserId;
  final String devUserDisplayName;

  /// `stub` (default) or `openai` — provider SDKs stay behind adapters.
  final String aiMode;
  final String? openAiApiKey;

  bool get isDevelopment =>
      environment == 'development' || environment == 'test';

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }
}
