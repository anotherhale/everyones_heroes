import 'package:everyonesheroes/features/discovery/domain/entities/influence.dart';
import 'package:everyonesheroes/features/discovery/domain/repositories/influence_repository.dart';

/// Returns the curated Influence catalog for Discovery selection (D.3).
final class ListInfluencesUseCase {
  ListInfluencesUseCase({required this._repository});

  final InfluenceRepository _repository;

  Future<List<Influence>> execute() {
    return _repository.findAll();
  }
}
