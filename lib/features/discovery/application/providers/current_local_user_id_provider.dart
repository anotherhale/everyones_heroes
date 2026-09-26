import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/core/identity/local_user_identity.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';

/// Current local [UserId] for DiscoveryProfile resolution (D.1).
///
/// Temporary until Identity BC. Override in tests via ProviderScope.
final currentLocalUserIdProvider = Provider<UserId>((ref) {
  return LocalUserIdentity.current;
});
