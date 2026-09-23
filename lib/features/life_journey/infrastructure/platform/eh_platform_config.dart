/// Configuration for EH Platform H.2 client (PF.3 / H.2 migration).
///
/// Production authority requires `--dart-define=EH_PLATFORM_URL=...`.
/// Optional: `--dart-define=EH_H2_MODE=platform|local` (default: platform when
/// URL is set, otherwise local transitional path for offline tests).
/// Optional: `--dart-define=EH_PLATFORM_AUTH_TOKEN=...` (Identity lite bearer).
final class EhPlatformConfig {
  static const String platformUrlDefine = String.fromEnvironment(
    'EH_PLATFORM_URL',
  );

  static const String h2ModeDefine = String.fromEnvironment(
    'EH_H2_MODE',
  );

  static const String authTokenDefine = String.fromEnvironment(
    'EH_PLATFORM_AUTH_TOKEN',
  );

  static const String userIdDefine = String.fromEnvironment(
    'EH_PLATFORM_USER_ID',
    defaultValue: 'dev-user',
  );

  /// True when Flutter must treat EH Platform as H.2 authority.
  static bool get usePlatformAuthority {
    if (h2ModeDefine == 'local') {
      return false;
    }
    if (h2ModeDefine == 'platform') {
      return true;
    }
    return platformUrlDefine.isNotEmpty;
  }

  static Uri? get baseUrl {
    if (platformUrlDefine.isEmpty) {
      return null;
    }
    return Uri.parse(platformUrlDefine);
  }

  static String get authToken =>
      authTokenDefine.isEmpty ? userIdDefine : authTokenDefine;

  static String get userId => userIdDefine;
}
