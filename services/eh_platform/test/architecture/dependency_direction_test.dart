import 'dart:io';

import 'package:test/test.dart';

import '../support/platform_paths.dart';

void main() {
  group('Dependency direction', () {
    test('domain identity types do not import HTTP or postgres', () {
      final root = ehPlatformRoot();
      final domainFiles = [
        '$root/lib/src/identity/domain/user.dart',
        '$root/lib/src/identity/domain/authenticated_principal.dart',
        '$root/lib/src/shared_kernel/user_id.dart',
        '$root/lib/src/shared_kernel/result.dart',
        '$root/lib/src/events/domain_event.dart',
        '$root/lib/src/ai/ai_orchestration_port.dart',
      ];

      for (final path in domainFiles) {
        final source = File(path).readAsStringSync();
        expect(source.contains("package:shelf/"), isFalse, reason: path);
        expect(source.contains("package:postgres/"), isFalse, reason: path);
        expect(source.contains("package:http/"), isFalse, reason: path);
        expect(source.contains('dart:io'), isFalse, reason: path);
        expect(source.toLowerCase().contains('openai'), isFalse, reason: path);
      }
    });

    test('application handlers do not import shelf', () {
      final root = ehPlatformRoot();
      final appFiles = Directory('$root/lib/src/identity/application')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in appFiles) {
        final source = file.readAsStringSync();
        expect(source.contains("package:shelf/"), isFalse, reason: file.path);
        expect(source.contains("package:postgres/"), isFalse, reason: file.path);
      }
    });

    test('module map matches PF-ADR-002', () {
      final root = ehPlatformRoot();
      for (final module in [
        'identity',
        'life_journey',
        'discovery',
        'hero_story',
        'experience',
        'ai',
      ]) {
        expect(
          Directory('$root/lib/src/modules/$module').existsSync(),
          isTrue,
          reason: module,
        );
      }
      expect(
        Directory('$root/lib/src/modules/behavioral_understanding').existsSync(),
        isFalse,
        reason: 'Behavioral Understanding stays under life_journey (PF-ADR-002)',
      );
    });
  });
}
