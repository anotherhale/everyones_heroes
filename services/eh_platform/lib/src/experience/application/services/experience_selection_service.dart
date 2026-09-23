import 'package:eh_platform/src/experience/application/models/selected_experience.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';

/// UI.3 Experience Selection seam — answers "what experience next?"
///
/// Must remain separate from H.2 pattern detection.
abstract interface class ExperienceSelectionService {
  SelectedExperience selectFor(Journey journey);
}
