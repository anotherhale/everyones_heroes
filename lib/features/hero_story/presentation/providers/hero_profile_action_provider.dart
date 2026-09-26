import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional seeker-facing action slot on [HeroProfileScreen] (D.11).
///
/// Hero & Story presentation defines the extension point; Discovery (or App
/// composition) may override this provider to inject private preference UI
/// such as "Inspires me" without Hero & Story importing Discovery.
typedef HeroProfileActionBuilder = Widget? Function({
  required WidgetRef ref,
  required String heroId,
});

final heroProfileActionBuilderProvider =
    Provider<HeroProfileActionBuilder?>((ref) => null);
