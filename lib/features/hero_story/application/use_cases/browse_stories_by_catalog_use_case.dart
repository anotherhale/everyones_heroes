import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/browse_stories_by_catalog_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/requests/discover_stories_request.dart';
import 'package:everyonesheroes/features/hero_story/application/dto/responses/discover_stories_response.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/discover_stories_use_case.dart';
import 'package:everyonesheroes/features/hero_story/application/use_cases/use_case.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/catalog_browse_dimension.dart';

/// Catalog browse by one primary dimension with discovery eligibility defaults.
final class BrowseStoriesByCatalogUseCase
    implements
        UseCase<BrowseStoriesByCatalogRequest, DiscoverStoriesResponse> {
  const BrowseStoriesByCatalogUseCase({
    required this._discoverStoriesUseCase,
  });

  final DiscoverStoriesUseCase _discoverStoriesUseCase;

  @override
  Future<Result<DiscoverStoriesResponse>> execute(
    BrowseStoriesByCatalogRequest request,
  ) async {
    try {
      final discoverRequest = _toDiscoverRequest(request);
      return _discoverStoriesUseCase.execute(discoverRequest);
    } on ArgumentError catch (e) {
      return Failure('${e.message ?? e}');
    } catch (e) {
      return Failure('Failed to browse stories: $e');
    }
  }

  DiscoverStoriesRequest _toDiscoverRequest(
    BrowseStoriesByCatalogRequest request,
  ) {
    switch (request.dimension) {
      case CatalogBrowseDimension.subject:
        final subject = request.subject;
        if (subject == null) {
          throw ArgumentError('subject is required for subject browse');
        }
        return DiscoverStoriesRequest(
          subjects: [subject],
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.challenge:
        final challenge = request.challenge;
        if (challenge == null) {
          throw ArgumentError('challenge is required for challenge browse');
        }
        return DiscoverStoriesRequest(
          challenges: [challenge],
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.narrativeTheme:
        final themeId = request.narrativeThemeId;
        if (themeId == null) {
          throw ArgumentError(
            'narrativeThemeId is required for narrativeTheme browse',
          );
        }
        return DiscoverStoriesRequest(
          narrativeThemeIds: [themeId],
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.format:
        final format = request.format;
        if (format == null) {
          throw ArgumentError('format is required for format browse');
        }
        return DiscoverStoriesRequest(
          formats: [format],
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.availableLanguage:
        final language = request.language;
        if (language == null) {
          throw ArgumentError(
            'language is required for availableLanguage browse',
          );
        }
        return DiscoverStoriesRequest(
          availableLanguage: language,
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.originalLanguage:
        final language = request.language;
        if (language == null) {
          throw ArgumentError(
            'language is required for originalLanguage browse',
          );
        }
        return DiscoverStoriesRequest(
          originalLanguage: language,
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.outcome:
        final outcome = request.outcome;
        if (outcome == null) {
          throw ArgumentError('outcome is required for outcome browse');
        }
        return DiscoverStoriesRequest(
          outcomes: [outcome],
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.emotionalCharacter:
        final character = request.emotionalCharacter;
        if (character == null) {
          throw ArgumentError(
            'emotionalCharacter is required for emotionalCharacter browse',
          );
        }
        return DiscoverStoriesRequest(
          emotionalCharacters: [character],
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
      case CatalogBrowseDimension.audience:
        final audience = request.audience;
        if (audience == null) {
          throw ArgumentError('audience is required for audience browse');
        }
        return DiscoverStoriesRequest(
          audience: audience,
          maxProfanity: request.maxProfanity,
          maxViolence: request.maxViolence,
          maxSexualContent: request.maxSexualContent,
          maxSubstanceUse: request.maxSubstanceUse,
          maxDisturbingContent: request.maxDisturbingContent,
          limit: request.limit,
          offset: request.offset,
        );
    }
  }
}
