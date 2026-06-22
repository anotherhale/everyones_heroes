import 'package:everyonesheroes/features/life_journey/domain/entities/reflection/reflection_response.dart';
import 'package:everyonesheroes/features/life_journey/domain/enums/reflection_response_type.dart';

final class ScaleResponse extends ReflectionResponse {
  ScaleResponse({required this.value, this.maxValue = 10}) {
    if (value < 0 || value > maxValue) {
      throw ArgumentError('Scale value out of range.');
    }
  }

  final int value;

  final int maxValue;

  @override
  ReflectionResponseType get type => ReflectionResponseType.scale;
}
