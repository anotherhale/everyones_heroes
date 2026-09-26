import 'package:everyonesheroes/core/ids/user_id.dart';

/// Temporary application-level local user identity until the Identity BC exists.
///
/// ## D.1 decision
///
/// DiscoveryProfile is keyed by [UserId], but Flutter has no Identity aggregate
/// yet. The adaptive experience path needs a stable "current user" to resolve
/// the active DiscoveryProfile.
///
/// This class reuses the existing dart-define already used for platform client
/// auth fallback (`EH_PLATFORM_USER_ID`, default `dev-user`) so local Discovery
/// and platform client principal agree in development.
///
/// Long-term Identity binding remains future work. Do not treat this as
/// authentication, authorization, or a multi-user account system.
abstract final class LocalUserIdentity {
  static const String userIdDefine = String.fromEnvironment(
    'EH_PLATFORM_USER_ID',
    defaultValue: 'dev-user',
  );

  static UserId get current => UserId(userIdDefine);
}
