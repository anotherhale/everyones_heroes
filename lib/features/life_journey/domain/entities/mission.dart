

import 'package:everyonesheroes/core/ids/mission_id.dart';
import 'package:everyonesheroes/core/shared_kernel/entity.dart';

import '../enums/mission_status.dart';
import '../value_objects/mission_title.dart';

final class Mission extends Entity<MissionId> {
  Mission({
    required MissionId id,
    required MissionTitle title,
    MissionStatus status = MissionStatus.pending,
    DateTime? completedAt,
  })  : _title = title,
        _status = status,
        _completedAt = completedAt,
        super(id);

  final MissionTitle _title;

  MissionStatus _status;

  DateTime? _completedAt;

  factory Mission.create({
    required MissionId id,
    required MissionTitle title,
  }) {
    return Mission(
      id: id,
      title: title,
    );
  }

  MissionTitle get title => _title;

  MissionStatus get status => _status;

  DateTime? get completedAt => _completedAt;

  bool get isCompleted =>
      _status == MissionStatus.completed;

  void complete() {
    if (isCompleted) {
      throw StateError(
        'Mission already completed',
      );
    }

    _status = MissionStatus.completed;
    _completedAt = DateTime.now();
  }
}