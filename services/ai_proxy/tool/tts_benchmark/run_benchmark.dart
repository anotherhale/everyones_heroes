#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// Reproducible HS.12.7 TTS provider benchmark.
///
/// Measures complete-file synthesis against:
///   - OpenAI (via OpenAiSpeechClient / OPENAI_API_KEY)
///   - Local sidecar (EH_LOCAL_TTS_URL) for qwen3 / cosyvoice / fake
///
/// Does not require Flutter. Does not download ML models itself.
///
/// Usage:
///   cd services/ai_proxy
///   dart run tool/tts_benchmark/run_benchmark.dart \
///     --provider openai \
///     --out ../../docs/architecture/hs12_7_benchmark_artifacts
///
///   dart run tool/tts_benchmark/run_benchmark.dart \
///     --provider qwen3 \
///     --sidecar http://127.0.0.1:8791 \
///     --out ../../docs/architecture/hs12_7_benchmark_artifacts
library;

import 'dart:convert';
import 'dart:io';

import 'package:ai_proxy/src/openai_speech_client.dart';
import 'package:ai_proxy/src/tts/local_http_tts_provider.dart';
import 'package:ai_proxy/src/tts/openai_tts_provider.dart';
import 'package:ai_proxy/src/tts/tts_provider.dart';

Future<void> main(List<String> args) async {
  final options = _Options.parse(args);
  final corpusFile = File(options.corpusPath);
  if (!corpusFile.existsSync()) {
    stderr.writeln('Corpus not found: ${options.corpusPath}');
    exitCode = 1;
    return;
  }
  final corpus =
      jsonDecode(await corpusFile.readAsString()) as Map<String, dynamic>;
  final items = (corpus['items'] as List).cast<Map<String, dynamic>>();

  final outDir = Directory(options.outDir);
  await outDir.create(recursive: true);
  final audioDir =
      Directory('${outDir.path}/${options.provider}/audio');
  await audioDir.create(recursive: true);

  final provider = await _buildProvider(options);
  final rows = <Map<String, dynamic>>[];

  print('HS.12.7 TTS benchmark');
  print('  provider: ${options.provider}');
  print('  corpus:   ${options.corpusPath}');
  print('  out:      ${outDir.path}');
  print('');

  // Warm / startup probe for local sidecar.
  double? startupSeconds;
  if (options.sidecarBase != null) {
    final sw = Stopwatch()..start();
    try {
      final client = HttpClient();
      final req = await client.getUrl(
        options.sidecarBase!.resolve('/health'),
      );
      final res = await req.close().timeout(const Duration(seconds: 30));
      await res.drain<void>();
      startupSeconds = sw.elapsedMilliseconds / 1000.0;
      client.close(force: true);
    } catch (e) {
      startupSeconds = sw.elapsedMilliseconds / 1000.0;
      print('WARN: sidecar health probe failed: $e');
    }
  }

  var first = true;
  for (final item in items) {
    if (options.only != null && item['id'] != options.only) {
      continue;
    }
    final id = item['id'] as String;
    final language = (item['language'] as String).toLowerCase();
    final text = item['text'] as String;
    print('→ $id ($language, ${text.length} chars)');

    final sw = Stopwatch()..start();
    String? error;
    TtsSynthesisResult? result;
    try {
      result = await provider.synthesize(
        TtsSynthesisRequest(
          text: text,
          language: language,
          modelHint: options.modelHint,
        ),
      );
    } catch (e) {
      error = e.toString();
    }
    final synthesisSeconds = sw.elapsedMilliseconds / 1000.0;

    double? audioDuration;
    int? sampleRate;
    String? contentType;
    int? fileSize;
    String? audioPath;
    if (result != null) {
      contentType = result.contentType;
      fileSize = result.audioBytes.length;
      final ext = _extensionFor(result.contentType);
      audioPath = '${audioDir.path}/$id$ext';
      await File(audioPath).writeAsBytes(result.audioBytes, flush: true);
      final probe = await _ffprobe(audioPath);
      audioDuration = probe.durationSeconds;
      sampleRate = probe.sampleRate;
    }

    final row = <String, dynamic>{
      'provider': options.provider,
      'itemId': id,
      'language': language,
      'textChars': text.length,
      'startupSeconds': first ? startupSeconds : null,
      'firstSynthesis': first,
      'synthesisSeconds': synthesisSeconds,
      'audioDurationSeconds': audioDuration,
      'realTimeFactor': (audioDuration != null && audioDuration > 0)
          ? synthesisSeconds / audioDuration
          : null,
      'outputFormat': contentType,
      'sampleRateHz': sampleRate,
      'fileSizeBytes': fileSize,
      'modelLabel': result?.modelLabel,
      'audioPath': audioPath,
      'error': error,
    };
    rows.add(row);
    print(
      error == null
          ? '  ok  synth=${synthesisSeconds.toStringAsFixed(2)}s '
              'audio=${audioDuration?.toStringAsFixed(2) ?? "?"}s '
              'rtf=${row['realTimeFactor']?.toStringAsFixed(2) ?? "?"}'
          : '  FAIL $error',
    );
    first = false;
  }

  final resultsPath = '${outDir.path}/${options.provider}/results.json';
  await File(resultsPath).writeAsString(
    const JsonEncoder.withIndent('  ').convert({
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'provider': options.provider,
      'host': Platform.localHostname,
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'numberOfProcessors': Platform.numberOfProcessors,
      'rows': rows,
    }),
  );
  print('\nWrote $resultsPath');
}

Future<TtsProvider> _buildProvider(_Options options) async {
  switch (options.provider) {
    case 'openai':
      final key = Platform.environment['OPENAI_API_KEY']?.trim() ?? '';
      if (key.isEmpty) {
        throw StateError('OPENAI_API_KEY is required for --provider openai');
      }
      final envModel = Platform.environment['OPENAI_SPEECH_MODEL']?.trim();
      final model = (options.modelHint != null &&
              options.modelHint!.trim().isNotEmpty)
          ? options.modelHint!.trim()
          : (envModel != null && envModel.isNotEmpty ? envModel : 'tts-1');
      final envVoice = Platform.environment['OPENAI_SPEECH_VOICE']?.trim();
      final voice =
          (envVoice != null && envVoice.isNotEmpty) ? envVoice : 'alloy';
      final envBase = Platform.environment['OPENAI_BASE_URL']?.trim();
      final baseUrl = (envBase != null && envBase.isNotEmpty)
          ? envBase
          : 'https://api.openai.com/v1';
      return OpenAiTtsProvider(
        client: OpenAiSpeechClient(
          apiKey: key,
          baseUrl: baseUrl,
          model: model,
          voice: voice,
        ),
      );
    case 'qwen3':
    case 'cosyvoice':
    case 'fake':
      final base = options.sidecarBase;
      if (base == null) {
        throw StateError(
          '--sidecar URL is required for provider ${options.provider}',
        );
      }
      return LocalHttpTtsProvider(
        providerKey: options.provider,
        baseUrl: base,
      );
    default:
      throw StateError('Unsupported provider: ${options.provider}');
  }
}

String _extensionFor(String contentType) {
  final base = contentType.split(';').first.trim().toLowerCase();
  return switch (base) {
    'audio/mpeg' || 'audio/mp3' => '.mp3',
    'audio/wav' || 'audio/x-wav' => '.wav',
    'audio/ogg' => '.ogg',
    'audio/mp4' || 'audio/m4a' => '.m4a',
    _ => '.bin',
  };
}

Future<({double? durationSeconds, int? sampleRate})> _ffprobe(
  String path,
) async {
  try {
    final result = await Process.run('ffprobe', [
      '-v',
      'error',
      '-show_entries',
      'format=duration:stream=sample_rate',
      '-of',
      'json',
      path,
    ]);
    if (result.exitCode != 0) {
      return (durationSeconds: null, sampleRate: null);
    }
    final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final format = decoded['format'] as Map<String, dynamic>?;
    final streams = (decoded['streams'] as List?)?.cast<Map<String, dynamic>>();
    final duration = double.tryParse('${format?['duration']}');
    final sampleRate = int.tryParse('${streams?.firstOrNull?['sample_rate']}');
    return (durationSeconds: duration, sampleRate: sampleRate);
  } catch (_) {
    return (durationSeconds: null, sampleRate: null);
  }
}

final class _Options {
  _Options({
    required this.provider,
    required this.corpusPath,
    required this.outDir,
    this.sidecarBase,
    this.modelHint,
    this.only,
  });

  final String provider;
  final String corpusPath;
  final String outDir;
  final Uri? sidecarBase;
  final String? modelHint;
  final String? only;

  static _Options parse(List<String> args) {
    String provider = 'openai';
    String corpusPath = 'tool/tts_benchmark/corpus.json';
    String outDir = 'tool/tts_benchmark/out';
    Uri? sidecar;
    String? modelHint;
    String? only;
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      String next() {
        if (i + 1 >= args.length) {
          throw FormatException('Missing value for $arg');
        }
        return args[++i];
      }

      switch (arg) {
        case '--provider':
          provider = next();
        case '--corpus':
          corpusPath = next();
        case '--out':
          outDir = next();
        case '--sidecar':
          sidecar = Uri.parse(next());
        case '--model':
          modelHint = next();
        case '--only':
          only = next();
        case '--help':
        case '-h':
          stdout.writeln(
            'Usage: dart run tool/tts_benchmark/run_benchmark.dart '
            '--provider openai|qwen3|cosyvoice|fake [options]',
          );
          exit(0);
        default:
          throw FormatException('Unknown arg: $arg');
      }
    }
    return _Options(
      provider: provider,
      corpusPath: corpusPath,
      outDir: outDir,
      sidecarBase: sidecar ??
          (Platform.environment['EH_LOCAL_TTS_URL']?.trim().isNotEmpty == true
              ? Uri.parse(Platform.environment['EH_LOCAL_TTS_URL']!.trim())
              : null),
      modelHint: modelHint,
      only: only,
    );
  }
}
