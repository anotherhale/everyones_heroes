import 'package:everyonesheroes/core/shared_kernel/value_object.dart';
import 'package:everyonesheroes/features/hero_story/domain/value_objects/understood_claim.dart';

/// Key interpretive story elements grounded in Hero material (SB.8).
///
/// These are interpretations of source material, not authored story prose.
final class UnderstoodKeyStoryElements extends ValueObject {
  const UnderstoodKeyStoryElements({
    this.challenge,
    this.struggle,
    this.stakes,
    this.turningPoint,
    this.decision,
    this.action,
    this.outcome,
    this.reflection,
    this.message,
  });

  final UnderstoodClaim? challenge;
  final UnderstoodClaim? struggle;
  final UnderstoodClaim? stakes;
  final UnderstoodClaim? turningPoint;
  final UnderstoodClaim? decision;
  final UnderstoodClaim? action;
  final UnderstoodClaim? outcome;
  final UnderstoodClaim? reflection;
  final UnderstoodClaim? message;

  bool get isEmpty =>
      challenge == null &&
      struggle == null &&
      stakes == null &&
      turningPoint == null &&
      decision == null &&
      action == null &&
      outcome == null &&
      reflection == null &&
      message == null;

  @override
  List<Object?> get equalityProps => [
    challenge,
    struggle,
    stakes,
    turningPoint,
    decision,
    action,
    outcome,
    reflection,
    message,
  ];
}
