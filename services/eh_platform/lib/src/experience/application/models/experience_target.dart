/// Optional target for non-reflection experiences (HS.8 Story seam).
sealed class ExperienceTarget {
  const ExperienceTarget();

  Map<String, Object?> toJson();
}

final class StoryExperienceTarget extends ExperienceTarget {
  const StoryExperienceTarget({required this.storyId});

  final String storyId;

  @override
  Map<String, Object?> toJson() => {
        'kind': 'story',
        'storyId': storyId,
      };
}
