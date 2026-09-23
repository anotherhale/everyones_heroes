import 'package:everyonesheroes/features/life_journey/infrastructure/platform/today_experience_dto.dart';

/// Non-authoritative short-lived UI cache of last successful Today DTO (J.1).
///
/// Used only when platform fetch fails (offline / network). Never drives
/// selection when a fresh platform result is available.
final class TodayExperienceCache {
  TodayExperienceDto? _last;
  bool _lastReadWasStale = false;

  void store(TodayExperienceDto dto) {
    _last = dto;
    _lastReadWasStale = false;
  }

  TodayExperienceDto? read() => _last;

  /// Returns cached DTO and marks the next presentation as stale/offline.
  TodayExperienceDto? readStale() {
    final value = _last;
    if (value != null) {
      _lastReadWasStale = true;
    }
    return value;
  }

  bool get lastReadWasStale => _lastReadWasStale;

  void clearStaleFlag() {
    _lastReadWasStale = false;
  }

  void clear() {
    _last = null;
    _lastReadWasStale = false;
  }

  bool get hasValue => _last != null;
}
