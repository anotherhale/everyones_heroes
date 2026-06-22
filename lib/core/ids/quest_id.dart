import 'package:everyonesheroes/core/ids/strongly_typed_id.dart';

final class QuestId extends StronglyTypedId {
  const QuestId(super.value);

  factory QuestId.generate() {
    return QuestId(StronglyTypedId.uuid.v4());
  }
}
