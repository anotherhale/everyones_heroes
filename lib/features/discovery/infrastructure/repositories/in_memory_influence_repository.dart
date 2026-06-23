import 'package:everyonesheroes/core/ids/influence_id.dart';

import '../../domain/entities/influence.dart';
import '../../domain/repositories/influence_repository.dart';

final class InMemoryInfluenceRepository implements InfluenceRepository {
  InMemoryInfluenceRepository({Iterable<Influence>? influences}) {
    for (final influence in influences ?? const <Influence>[]) {
      _influences[influence.id.value] = influence;
    }
  }

  final Map<String, Influence> _influences = {};

  @override
  Future<Influence?> findById(InfluenceId id) async {
    return _influences[id.value];
  }

  @override
  Future<List<Influence>> findAll() async {
    return _influences.values.toList(growable: false);
  }
}
