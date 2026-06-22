enum QuestStatus {
  active,
  completed,
  abandoned,
}

extension QuestStatusX on QuestStatus {
  bool get isActive => this == QuestStatus.active;

  bool get isCompleted => this == QuestStatus.completed;

  bool get isAbandoned => this == QuestStatus.abandoned;
}