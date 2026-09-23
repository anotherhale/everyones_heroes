import 'package:eh_platform/src/events/event_bus.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_journey_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/create_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/requests/submit_reflection_request.dart';
import 'package:eh_platform/src/life_journey/application/dto/view_models.dart';
import 'package:eh_platform/src/life_journey/application/use_cases/submit_reflection_use_case.dart';
import 'package:eh_platform/src/life_journey/domain/domain.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/postgres_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/persistence/postgres_reflection_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_journey_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/repositories/owned_in_memory_reflection_repository.dart';
import 'package:eh_platform/src/life_journey/infrastructure/transactions/transaction_boundary.dart';
import 'package:eh_platform/src/shared_kernel/ids/journey_id.dart';
import 'package:eh_platform/src/shared_kernel/ids/reflection_id.dart';
import 'package:eh_platform/src/shared_kernel/result.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';

/// Application facade for H.2 commands/queries with ownership + transactions.
final class LifeJourneyApplicationService {
  LifeJourneyApplicationService({
    required this.transactions,
    required this.journeyRepository,
    required this.reflectionRepository,
    required this.eventBus,
    required this.submitReflectionUseCase,
  });

  final TransactionBoundary transactions;
  final JourneyRepository journeyRepository;
  final ReflectionRepository reflectionRepository;
  final EventBus eventBus;
  final SubmitReflectionUseCase submitReflectionUseCase;

  Future<Result<JourneySummaryDto>> createJourney({
    required UserId userId,
    required CreateJourneyRequest request,
  }) async {
    try {
      return await transactions.run(() async {
        final journey = Journey.create(
          id: request.journeyId,
          vision: request.vision,
        );
        await _saveJourneyForUser(journey, userId);
        for (final event in journey.pullDomainEvents()) {
          await eventBus.publish(event);
        }
        return Success(JourneySummaryDto.fromJourney(journey));
      });
    } catch (e) {
      return Failure(
        code: 'create_journey_failed',
        message: 'Failed to create journey: $e',
      );
    }
  }

  Future<Result<ReflectionDto>> createReflection({
    required UserId userId,
    required CreateReflectionRequest request,
  }) async {
    try {
      return await transactions.run(() async {
        final journey = await journeyRepository.findById(request.journeyId);
        if (journey == null) {
          return Failure(
            code: 'not_found',
            message: 'Journey not found: ${request.journeyId.value}',
          );
        }
        final owner = await _journeyOwner(request.journeyId);
        if (owner != userId) {
          return const Failure(
            code: 'forbidden',
            message: 'Not authorized to create reflection',
          );
        }

        final reflection = Reflection.create(
          id: request.reflectionId,
          journeyId: request.journeyId,
          questId: request.questId,
          missionId: request.missionId,
        );
        await _saveReflectionForUser(reflection, userId);
        return Success(ReflectionDto.fromDomain(reflection));
      });
    } catch (e) {
      return Failure(
        code: 'create_reflection_failed',
        message: 'Failed to create reflection: $e',
      );
    }
  }

  Future<Result<ReflectionDto>> addReflectionResponse({
    required UserId userId,
    required ReflectionId reflectionId,
    required ReflectionResponse response,
  }) async {
    try {
      return await transactions.run(() async {
        final owner = await _reflectionOwner(reflectionId);
        if (owner == null) {
          return Failure(
            code: 'not_found',
            message: 'Reflection not found: ${reflectionId.value}',
          );
        }
        if (owner != userId) {
          return const Failure(code: 'forbidden', message: 'Not authorized');
        }

        final reflection = await reflectionRepository.findById(reflectionId);
        if (reflection == null) {
          return Failure(
            code: 'not_found',
            message: 'Reflection not found: ${reflectionId.value}',
          );
        }

        reflection.addResponse(response);
        await reflectionRepository.save(reflection);
        return Success(ReflectionDto.fromDomain(reflection));
      });
    } catch (e) {
      return Failure(
        code: 'add_response_failed',
        message: 'Failed to add reflection response: $e',
      );
    }
  }

  /// Authoritative H.2 command: submit → analysis → evidence → patterns.
  Future<Result<SubmitReflectionResultDto>> submitReflection({
    required UserId userId,
    required SubmitReflectionRequest request,
  }) async {
    try {
      return await transactions.run(() async {
        final owner = await _reflectionOwner(request.reflectionId);
        if (owner == null) {
          return Failure(
            code: 'not_found',
            message: 'Reflection not found: ${request.reflectionId.value}',
          );
        }
        if (owner != userId) {
          return const Failure(code: 'forbidden', message: 'Not authorized');
        }

        final submitResult = await submitReflectionUseCase.execute(request);
        if (submitResult.isFailure) {
          return submitResult.fold(
            onSuccess: (_) => throw StateError('unreachable'),
            onFailure: (failure) => Failure<SubmitReflectionResultDto>(
              code: failure.code,
              message: failure.message,
              details: failure.details,
            ),
          );
        }

        final reflection = submitResult.getOrThrow();
        final freshReflection =
            await reflectionRepository.findById(reflection.id) ?? reflection;
        final journey =
            await journeyRepository.findById(freshReflection.journeyId);
        if (journey == null) {
          return Failure(
            code: 'not_found',
            message:
                'Journey not found after submit: ${freshReflection.journeyId.value}',
          );
        }

        final understanding = await _buildUnderstanding(journey);
        return Success(
          SubmitReflectionResultDto(
            reflection: ReflectionDto.fromDomain(freshReflection),
            understanding: understanding,
          ),
        );
      });
    } catch (e) {
      return Failure(
        code: 'submit_reflection_failed',
        message: 'Failed to submit reflection: $e',
      );
    }
  }

  Future<Result<JourneySummaryDto>> getCurrentJourney({
    required UserId userId,
  }) async {
    try {
      return await transactions.run(() async {
        final journey = await _currentJourney(userId);
        if (journey == null) {
          return const Failure(code: 'not_found', message: 'No current journey');
        }
        return Success(JourneySummaryDto.fromJourney(journey));
      });
    } catch (e) {
      return Failure(
        code: 'get_current_journey_failed',
        message: 'Failed to load current journey: $e',
      );
    }
  }

  Future<Result<UnderstandingDto>> getCurrentUnderstanding({
    required UserId userId,
  }) async {
    try {
      return await transactions.run(() async {
        final journey = await _currentJourney(userId);
        if (journey == null) {
          return const Failure(code: 'not_found', message: 'No current journey');
        }
        return Success(await _buildUnderstanding(journey));
      });
    } catch (e) {
      return Failure(
        code: 'get_understanding_failed',
        message: 'Failed to load understanding: $e',
      );
    }
  }

  Future<UnderstandingDto> _buildUnderstanding(Journey journey) async {
    final reflections =
        await reflectionRepository.findByJourneyId(journey.id);
    final evidence = reflections
        .expand((r) => r.behavioralEvidence)
        .toList(growable: true)
      ..sort((a, b) => b.observedAt.compareTo(a.observedAt));
    final recent = evidence.take(20).toList(growable: false);

    return UnderstandingDto(
      journeyId: journey.id.value,
      patterns: journey.behaviorPatterns
          .map(BehaviorPatternDto.fromDomain)
          .toList(growable: false),
      recentEvidence:
          recent.map(BehavioralEvidenceDto.fromDomain).toList(growable: false),
    );
  }

  Future<Journey?> _currentJourney(UserId userId) async {
    final repo = journeyRepository;
    if (repo is OwnedInMemoryJourneyRepository) {
      return repo.findCurrentByUserId(userId);
    }
    if (repo is PostgresJourneyRepository) {
      return repo.findCurrentByUserId(userId);
    }
    return null;
  }

  Future<UserId?> _journeyOwner(JourneyId id) async {
    final repo = journeyRepository;
    if (repo is OwnedInMemoryJourneyRepository) {
      return repo.ownerOf(id);
    }
    if (repo is PostgresJourneyRepository) {
      return repo.ownerOf(id);
    }
    return null;
  }

  Future<UserId?> _reflectionOwner(ReflectionId id) async {
    final repo = reflectionRepository;
    if (repo is OwnedInMemoryReflectionRepository) {
      return repo.ownerOf(id);
    }
    if (repo is PostgresReflectionRepository) {
      return repo.ownerOf(id);
    }
    return null;
  }

  Future<void> _saveJourneyForUser(Journey journey, UserId userId) async {
    final repo = journeyRepository;
    if (repo is OwnedInMemoryJourneyRepository) {
      await repo.saveForUser(journey, userId);
      return;
    }
    if (repo is PostgresJourneyRepository) {
      await repo.saveForUser(journey, userId);
      return;
    }
    await repo.save(journey);
  }

  Future<void> _saveReflectionForUser(
    Reflection reflection,
    UserId userId,
  ) async {
    final repo = reflectionRepository;
    if (repo is OwnedInMemoryReflectionRepository) {
      await repo.saveForUser(reflection, userId);
      return;
    }
    if (repo is PostgresReflectionRepository) {
      await repo.saveForUser(reflection, userId);
      return;
    }
    await repo.save(reflection);
  }
}
