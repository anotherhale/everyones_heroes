import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/features/discovery/domain/aggregates/discovery_profile.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/discovery_profile_repository.dart';

/// Ensures a DiscoveryProfile exists for the current local user.
///
/// ## D.1 lifecycle
///
/// Attaches DiscoveryProfile to the application session without requiring a
/// full Identity BC. Creates an empty profile on first use; does not invent
/// influences or themes.
final class EnsureCurrentDiscoveryProfileUseCase {
  EnsureCurrentDiscoveryProfileUseCase({
    required DiscoveryProfileRepository repository,
    required UserId currentUserId,
  }) : _repository = repository,
       _currentUserId = currentUserId;

  final DiscoveryProfileRepository _repository;
  final UserId _currentUserId;

  Future<DiscoveryProfile> execute({UserId? userId}) async {
    final resolvedUserId = userId ?? _currentUserId;
    final existing = await _repository.findByUserId(resolvedUserId);
    if (existing != null) {
      return existing;
    }

    final profile = DiscoveryProfile(
      id: DiscoveryProfileId.generate(),
      userId: resolvedUserId,
    );
    await _repository.save(profile);
    return profile;
  }
}
