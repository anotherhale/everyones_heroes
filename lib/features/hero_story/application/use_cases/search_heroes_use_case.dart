import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_search_port.dart';

final class SearchHeroesUseCase
    implements UseCase<HeroSearchQuery, List<HeroId>> {
  const SearchHeroesUseCase({required HeroSearchPort heroSearchPort})
    : _heroSearchPort = heroSearchPort;

  final HeroSearchPort _heroSearchPort;

  @override
  Future<Result<List<HeroId>>> execute(HeroSearchQuery request) async {
    try {
      final ids = await _heroSearchPort.search(request);
      return Success(ids);
    } catch (e) {
      return Failure('Failed to search heroes: $e');
    }
  }
}
