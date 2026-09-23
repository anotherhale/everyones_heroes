import 'package:eh_platform/eh_platform.dart';

/// EH Platform entrypoint (PF.3 / Phase 2 foundation).
///
/// Environment variables are documented in `.env.example`.
Future<void> main(List<String> args) async {
  await runPlatformServer();
}
