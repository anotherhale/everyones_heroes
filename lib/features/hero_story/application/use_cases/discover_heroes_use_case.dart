import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/features/hero_story/application/discovery/hero_discovery_summary_mapper.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_heroes_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_heroes_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/repositories/hero_repository.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_discoverability_policy.dart';
import 'package:everyonesheroes/features/hero_story/domain/services/hero_search_port.dart';

/// Seeker-facing Hero discovery: eligibility + search + safe summaries.
///
/// Does not mutate aggregates or publish domain events.
final class DiscoverHeroesUseCase
    implements UseCase<DiscoverHeroesRequest, DiscoverHeroesResponse> {
  const DiscoverHeroesUseCase({
    required this._heroSearchPort,
    required this._heroRepository,
  });

  final HeroSearchPort _heroSearchPort;
  final HeroRepository _heroRepository;

  @override
  Future<Result<DiscoverHeroesResponse>> execute(
    DiscoverHeroesRequest request,
  ) async {
    try {
      HeroDiscoverySummaryMapper.validatePagination(
        limit: request.limit,
        offset: request.offset,
      );

      final query = HeroSearchQuery(
        text: request.text,
        experienceArea: request.experienceArea,
        language: request.language,
        activeOnly: true,
        visibilities: HeroDiscoverabilityPolicy.discoverableVisibilityList,
      );

      final ids = await _heroSearchPort.search(query);
      final matchReasons = HeroDiscoverySummaryMapper.matchReasonsFor(request);

      final eligible = <Hero>[];
      final seen = <String>{};

      for (final id in ids) {
        if (!seen.add(id.value)) {
          continue;
        }

        final hero = await _heroRepository.findById(id);
        if (hero == null) {
          continue;
        }
        if (!HeroDiscoverabilityPolicy.isDiscoverable(hero)) {
          continue;
        }

        eligible.add(hero);
      }

      eligible.sort(HeroDiscoverySummaryMapper.compareHeroes);

      final totalCount = eligible.length;
      final page = eligible.skip(request.offset).take(request.limit).toList();

      final items = page
          .map(
            (hero) => HeroDiscoverySummaryMapper.fromHero(
              hero: hero,
              matchReasons: matchReasons,
            ),
          )
          .toList(growable: false);

      final nextOffset = request.offset + items.length < totalCount
          ? request.offset + items.length
          : null;

      return Success(
        DiscoverHeroesResponse(
          items: items,
          totalCount: totalCount,
          nextOffset: nextOffset,
        ),
      );
    } on ArgumentError catch (e) {
      return Failure('${e.message ?? e}');
    } catch (e) {
      return Failure('Failed to discover heroes: $e');
    }
  }
}
