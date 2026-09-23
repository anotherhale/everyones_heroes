import 'package:test/test.dart';
import 'dart:io';

/// Architecture dependency direction tests for EH Platform H.2.
void main() {
  final libRoot = Directory('lib/src');

  List<File> dartFilesUnder(String relative) {
    final dir = Directory('${libRoot.path}/$relative');
    if (!dir.existsSync()) {
      return const [];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();
  }

  bool imports(File file, String needle) {
    return file.readAsStringSync().contains(needle);
  }

  test('domain layer does not import HTTP (shelf)', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(imports(file, 'package:shelf/'), isFalse, reason: file.path);
      expect(imports(file, 'package:http/'), isFalse, reason: file.path);
    }
  });

  test('domain layer does not import PostgreSQL', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(imports(file, 'package:postgres/'), isFalse, reason: file.path);
    }
  });

  test('domain layer does not import AI provider SDKs', () {
    for (final file in dartFilesUnder('life_journey/domain')) {
      expect(imports(file, 'package:openai'), isFalse, reason: file.path);
      expect(imports(file, 'anthropic'), isFalse, reason: file.path);
    }
  });

  test('API layer does not import postgres directly', () {
    for (final file in dartFilesUnder('api')) {
      expect(imports(file, 'package:postgres/'), isFalse, reason: file.path);
    }
  });
}
