import 'package:eh_platform/src/shared_kernel/result.dart';

abstract interface class UseCase<Request, Response> {
  Future<Result<Response>> execute(Request request);
}
