import 'package:everyonesheroes/core/results/result.dart';

abstract interface class UseCase<Request, Response> {
  Future<Result<Response>> execute(Request request);
}
