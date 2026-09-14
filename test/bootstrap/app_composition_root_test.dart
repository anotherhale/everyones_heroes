import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:everyonesheroes/app/app_composition_root.dart';

void main() {
  test('composition root initializes', () async {
    final root = Directory.systemTemp.createTempSync('eh-composition-');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    final container = await AppCompositionRoot.initialize(
      storageRoot: root,
      recordingTemp: Directory('${root.path}/temp')..createSync(),
      useRealDeviceRecording: false,
    );
    addTearDown(container.dispose);
  });
}
