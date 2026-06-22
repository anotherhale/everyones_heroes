import 'package:everyonesheroes/contexts/life_journey/application/create_journey_request.dart';
import 'package:everyonesheroes/contexts/life_journey/application/use_case.dart';
import 'package:everyonesheroes/core/eventing/event_bus.dart';
import 'package:everyonesheroes/core/results/result.dart';
import 'package:everyonesheroes/core/results/success.dart';
import 'package:everyonesheroes/core/results/failure.dart';
import 'package:everyonesheroes/features/life_journey/domain/aggregates/journey.dart';
import 'package:everyonesheroes/features/life_journey/domain/repositories/journey_repository.dart';

final class CreateJourneyUseCase
    implements UseCase<CreateJourneyRequest, Journey> {
  const CreateJourneyUseCase({
    required JourneyRepository journeyRepository,
    required EventBus eventBus,
  }) : _journeyRepository = journeyRepository,
       _eventBus = eventBus;

  final JourneyRepository _journeyRepository;
  final EventBus _eventBus;

  @override
  Future<Result<Journey>> execute(CreateJourneyRequest request) async {
    try {
      final journey = Journey.create(
        id: request.journeyId,
        vision: request.vision,
      );

      await _journeyRepository.save(journey);

      for (final event in journey.domainEvents) {
        await _eventBus.publish(event);
      }

      journey.clearDomainEvents();

      return Success(journey);
    } catch (e) {
      return Failure('Failed to create journey: $e');
    }
  }
}
