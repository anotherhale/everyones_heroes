import 'dart:typed_data';

/// Stub for non-web platforms — object URLs are a browser concept.
Future<Uint8List> readBytesFromObjectUrl(String url) {
  throw UnsupportedError(
    'Reading object-URL bytes is only supported on Flutter Web.',
  );
}

void revokeObjectUrl(String url) {
  // No-op outside the browser.
}
