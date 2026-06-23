import 'package:everyonesheroes/core/ids/influence_id.dart';

import '../entities/influence.dart';

abstract interface class InfluenceRepository {
  Future<Influence?> findById(InfluenceId id);

  Future<List<Influence>> findAll();
}
