import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:everyonesheroes/features/hero_story/application/playback/original_recording_player.dart';
import 'package:everyonesheroes/features/hero_story/infrastructure/playback/just_audio_original_recording_player.dart';

/// Production original-recording player. Tests override this with a fake.
final originalRecordingPlayerFactoryProvider =
    Provider<OriginalRecordingPlayerFactory>((ref) {
      return const JustAudioOriginalRecordingPlayerFactory();
    });
