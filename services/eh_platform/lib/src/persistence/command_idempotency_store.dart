import 'dart:convert';

import 'package:eh_platform/src/shared_kernel/ids/user_id.dart';
import 'package:postgres/postgres.dart';

/// Stores command idempotency keys → prior HTTP responses.
abstract interface class CommandIdempotencyStore {
  Future<IdempotencyRecord?> find({
    required String idempotencyKey,
    required UserId userId,
  });

  Future<void> save(IdempotencyRecord record);
}

final class IdempotencyRecord {
  const IdempotencyRecord({
    required this.idempotencyKey,
    required this.userId,
    required this.commandName,
    required this.requestHash,
    required this.responseStatus,
    required this.responseBody,
  });

  final String idempotencyKey;
  final UserId userId;
  final String commandName;
  final String requestHash;
  final int responseStatus;
  final Map<String, Object?> responseBody;
}

final class InMemoryCommandIdempotencyStore implements CommandIdempotencyStore {
  final Map<String, IdempotencyRecord> _records = {};

  String _key(String idempotencyKey, UserId userId) =>
      '$idempotencyKey::${userId.value}';

  @override
  Future<IdempotencyRecord?> find({
    required String idempotencyKey,
    required UserId userId,
  }) async {
    return _records[_key(idempotencyKey, userId)];
  }

  @override
  Future<void> save(IdempotencyRecord record) async {
    _records[_key(record.idempotencyKey, record.userId)] = record;
  }
}

final class PostgresCommandIdempotencyStore implements CommandIdempotencyStore {
  PostgresCommandIdempotencyStore(this._sessionProvider);

  final Session Function() _sessionProvider;

  @override
  Future<IdempotencyRecord?> find({
    required String idempotencyKey,
    required UserId userId,
  }) async {
    final rows = await _sessionProvider().execute(
      Sql.named('''
        SELECT idempotency_key, user_id, command_name, request_hash,
               response_status, response_body
        FROM command_idempotency
        WHERE idempotency_key = @key AND user_id = @userId
        '''),
      parameters: {'key': idempotencyKey, 'userId': userId.value},
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final body = row[5];
    final Map<String, Object?> bodyMap;
    if (body is Map) {
      bodyMap = Map<String, Object?>.from(body);
    } else if (body is String) {
      bodyMap = Map<String, Object?>.from(jsonDecode(body) as Map);
    } else {
      throw FormatException(
        'Unexpected idempotency body type: ${body.runtimeType}',
      );
    }
    return IdempotencyRecord(
      idempotencyKey: row[0] as String,
      userId: UserId(row[1] as String),
      commandName: row[2] as String,
      requestHash: row[3] as String,
      responseStatus: row[4] as int,
      responseBody: bodyMap,
    );
  }

  @override
  Future<void> save(IdempotencyRecord record) async {
    await _sessionProvider().execute(
      Sql.named('''
        INSERT INTO command_idempotency (
          idempotency_key, user_id, command_name, request_hash,
          response_status, response_body
        ) VALUES (
          @key, @userId, @commandName, @requestHash,
          @status, @body
        )
        ON CONFLICT (idempotency_key, user_id) DO NOTHING
        '''),
      parameters: {
        'key': record.idempotencyKey,
        'userId': record.userId.value,
        'commandName': record.commandName,
        'requestHash': record.requestHash,
        'status': record.responseStatus,
        'body': jsonEncode(record.responseBody),
      },
    );
  }
}
