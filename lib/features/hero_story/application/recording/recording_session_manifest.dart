import 'dart:convert';

import 'package:everyonesheroes/features/hero_story/application/recording/recording_session_state.dart';

/// Optional on-disk recovery snapshot for a device recording session (HS.9).
///
/// Application-only; never a domain aggregate field.
final class RecordingSessionManifest {
  const RecordingSessionManifest({
    required this.sessionId,
    required this.heroId,
    required this.storyId,
    required this.representationId,
    required this.phase,
    required this.updatedAt,
    this.tempPath,
    this.createdAt,
    this.originalLanguage,
    this.contentType,
    this.lastError,
  });

  final String sessionId;
  final String heroId;
  final String storyId;
  final String representationId;
  final RecordingSessionPhase phase;
  final DateTime updatedAt;
  final String? tempPath;
  final DateTime? createdAt;
  final String? originalLanguage;
  final String? contentType;
  final String? lastError;

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'heroId': heroId,
        'storyId': storyId,
        'representationId': representationId,
        'phase': phase.name,
        'updatedAt': updatedAt.toIso8601String(),
        if (tempPath != null) 'tempPath': tempPath,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (originalLanguage != null) 'originalLanguage': originalLanguage,
        if (contentType != null) 'contentType': contentType,
        if (lastError != null) 'lastError': lastError,
      };

  String encode() => jsonEncode(toJson());

  factory RecordingSessionManifest.fromJson(Map<String, Object?> json) {
    final phaseName = json['phase'] as String? ?? RecordingSessionPhase.idle.name;
    final phase = RecordingSessionPhase.values.firstWhere(
      (value) => value.name == phaseName,
      orElse: () => RecordingSessionPhase.idle,
    );

    return RecordingSessionManifest(
      sessionId: json['sessionId'] as String? ?? '',
      heroId: json['heroId'] as String? ?? '',
      storyId: json['storyId'] as String? ?? '',
      representationId: json['representationId'] as String? ?? '',
      phase: phase,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      tempPath: json['tempPath'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      originalLanguage: json['originalLanguage'] as String?,
      contentType: json['contentType'] as String?,
      lastError: json['lastError'] as String?,
    );
  }

  factory RecordingSessionManifest.decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Recording session manifest must be a JSON object.');
    }
    return RecordingSessionManifest.fromJson(
      Map<String, Object?>.from(decoded),
    );
  }

  RecordingSessionManifest copyWith({
    String? sessionId,
    String? heroId,
    String? storyId,
    String? representationId,
    RecordingSessionPhase? phase,
    DateTime? updatedAt,
    String? tempPath,
    bool clearTempPath = false,
    DateTime? createdAt,
    String? originalLanguage,
    String? contentType,
    String? lastError,
    bool clearLastError = false,
  }) {
    return RecordingSessionManifest(
      sessionId: sessionId ?? this.sessionId,
      heroId: heroId ?? this.heroId,
      storyId: storyId ?? this.storyId,
      representationId: representationId ?? this.representationId,
      phase: phase ?? this.phase,
      updatedAt: updatedAt ?? this.updatedAt,
      tempPath: clearTempPath ? null : (tempPath ?? this.tempPath),
      createdAt: createdAt ?? this.createdAt,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      contentType: contentType ?? this.contentType,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }
}
