import 'package:eh_platform/src/life_journey/domain/enums/reflection_response_type.dart';

abstract class ReflectionResponse {
  const ReflectionResponse();

  ReflectionResponseType get type;
}
