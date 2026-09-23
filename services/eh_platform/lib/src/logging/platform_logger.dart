import 'dart:convert';
import 'dart:io';

/// Minimal structured logger with correlation support.
final class PlatformLogger {
  PlatformLogger({
    this.minLevel = LogLevel.info,
    IOSink? sink,
  }) : _sink = sink ?? stderr;

  final LogLevel minLevel;
  final IOSink _sink;

  void debug(String message, {Map<String, Object?>? fields}) =>
      _log(LogLevel.debug, message, fields);

  void info(String message, {Map<String, Object?>? fields}) =>
      _log(LogLevel.info, message, fields);

  void warning(String message, {Map<String, Object?>? fields}) =>
      _log(LogLevel.warning, message, fields);

  void error(String message, {Map<String, Object?>? fields, Object? error}) {
    final merged = <String, Object?>{
      ...?fields,
      if (error != null) 'error': error.toString(),
    };
    _log(LogLevel.error, message, merged);
  }

  void _log(LogLevel level, String message, Map<String, Object?>? fields) {
    if (level.index < minLevel.index) return;
    final record = <String, Object?>{
      'ts': DateTime.now().toUtc().toIso8601String(),
      'level': level.name,
      'msg': message,
      if (fields != null && fields.isNotEmpty) ...fields,
    };
    _sink.writeln(jsonEncode(record));
  }

  static LogLevel parseLevel(String value) {
    return switch (value.toLowerCase()) {
      'debug' => LogLevel.debug,
      'info' => LogLevel.info,
      'warning' || 'warn' => LogLevel.warning,
      'error' => LogLevel.error,
      _ => LogLevel.info,
    };
  }
}

enum LogLevel { debug, info, warning, error }
