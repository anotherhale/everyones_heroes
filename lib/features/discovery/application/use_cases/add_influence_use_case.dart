import 'package:everyonesheroes/core/ids/discovery_profile_id.dart';
import 'package:everyonesheroes/core/ids/influence_id.dart';

import '../../domain/repositories/discovery_profile_repository.dart';

final class AddInfluenceUseCase {
  AddInfluenceUseCase({required this._repository});

  final DiscoveryProfileRepository _repository;

  Future<void> execute({
    required DiscoveryProfileId profileId,
    required InfluenceId influenceId,
  }) async {
    final profile = await _repository.findById(profileId);

    if (profile == null) {
      throw StateError('DiscoveryProfile not found.');
    }

    profile.addInfluence(influenceId);

    await _repository.save(profile);
  }
}
