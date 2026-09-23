import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/use_case.dart';
import 'package:eh_platform/src/eventing/event_bus.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/success.dart';
import 'package:eh_platform/src/shared_kernel/failure.dart';
import 'package:eh_platform/src/life_journey/domain/aggregates/journey.dart';
import 'package:eh_platform/src/life_journey/domain/repositories/journey_repository.dart';

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

      final events = journey.pullDomainEvents();

      for (final event in events) {
        await _eventBus.publish(event);
      }

      return Success(journey);
    } catch (e) {
      return Failure('Failed to create journey: $e');
    }
  }
}
