import 'dart:io';

/// Resolves paths relative to `services/eh_platform` regardless of CWD.
String ehPlatformRoot() {
  final scriptDir = Directory.current.path;
  if (File('$scriptDir/pubspec.yaml').existsSync() &&
      File('$scriptDir/migrations/001_platform_foundation.sql').existsSync()) {
    return scriptDir;
  }
  final nested = Directory('$scriptDir/services/eh_platform');
  if (nested.existsSync()) {
    return nested.path;
  }
  // Walk up from test execution CWD.
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    final candidate = Directory('${dir.path}/services/eh_platform');
    if (candidate.existsSync()) return candidate.path;
    final pubspec = File('${dir.path}/pubspec.yaml');
    final migrations =
        File('${dir.path}/migrations/001_platform_foundation.sql');
    if (pubspec.existsSync() && migrations.existsSync()) {
      return dir.path;
    }
    dir = dir.parent;
  }
  throw StateError('Could not locate services/eh_platform root from $scriptDir');
}
