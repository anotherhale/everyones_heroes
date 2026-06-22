enum MissionStatus {
  pending,
  completed,
}

extension MissionStatusX on MissionStatus {
  bool get isPending => this == MissionStatus.pending;

  bool get isCompleted => this == MissionStatus.completed;
}