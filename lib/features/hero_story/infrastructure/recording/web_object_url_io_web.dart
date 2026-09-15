import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Reads bytes from a browser object URL / blob URL via `fetch`.
///
/// Kept in infrastructure so application/domain never see `Blob` or `package:web`.
Future<Uint8List> readBytesFromObjectUrl(String url) async {
  final response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError(
      'Failed to read recording object URL (HTTP ${response.status}).',
    );
  }
  final buffer = await response.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

void revokeObjectUrl(String url) {
  web.URL.revokeObjectURL(url);
}
