import 'package:everyonesheroes/core/ids/hero_id.dart';
import 'package:everyonesheroes/core/ids/user_id.dart';
import 'package:everyonesheroes/core/shared_kernel/language_code.dart';
import 'package:everyonesheroes/features/hero_story/domain/aggregates/hero.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_status.dart';
import 'package:everyonesheroes/features/hero_story/domain/enums/hero_visibility.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/hero_profile.dart';

/// JSON snapshot mapper for durable local [Hero] persistence (HS.9).
final class HeroSnapshotMapper {
  const HeroSnapshotMapper._();

  static Map<String, dynamic> toJson(Hero hero) {
    return {
      'id': hero.id.value,
      'identityUserId': hero.identityUserId?.value,
      'profile': {
        'displayName': hero.profile.displayName,
        'biography': hero.profile.biography,
        'experienceAreas': hero.profile.experienceAreas,
        'languages': [
          for (final language in hero.profile.languages) language.value,
        ],
        'geographicContext': hero.profile.geographicContext,
      },
      'visibility': hero.visibility.name,
      'status': hero.status.name,
      'createdAt': hero.createdAt.toIso8601String(),
    };
  }

  static Hero fromJson(Map<String, dynamic> json) {
    final profileJson = Map<String, dynamic>.from(json['profile'] as Map);
    final languagesRaw = profileJson['languages'] as List? ?? const [];
    final experienceAreasRaw =
        profileJson['experienceAreas'] as List? ?? const [];

    return Hero(
      id: HeroId(json['id'] as String),
      identityUserId: json['identityUserId'] == null
          ? null
          : UserId(json['identityUserId'] as String),
      profile: HeroProfile(
        displayName: profileJson['displayName'] as String,
        biography: profileJson['biography'] as String?,
        experienceAreas: [
          for (final area in experienceAreasRaw) area as String,
        ],
        languages: [
          for (final language in languagesRaw) LanguageCode(language as String),
        ],
        geographicContext: profileJson['geographicContext'] as String?,
      ),
      visibility: HeroVisibility.values.byName(json['visibility'] as String),
      status: HeroStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
