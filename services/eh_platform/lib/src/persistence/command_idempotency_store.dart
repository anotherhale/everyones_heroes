import 'dart:convert';

import 'package:eh_platform/src/persistence/database.dart';
import 'package:eh_platform/src/shared_kernel/user_id.dart';
import 'package:postgres/postgres.dart';

/// Stores command idempotency keys → prior HTTP responses (PF.3 table).
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

  /// Fingerprint stored in PF.3 `request_fingerprint` column.
  String get requestFingerprint => '$commandName:$requestHash';
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

/// Persists idempotency records using the PF.3 `command_idempotency` schema.
///
/// Uses the platform connection directly so lookups work outside a domain
/// UnitOfWork transaction (API idempotency check before command execution).
final class PostgresCommandIdempotencyStore implements CommandIdempotencyStore {
  PostgresCommandIdempotencyStore(this._database);

  final PlatformDatabase _database;

  @override
  Future<IdempotencyRecord?> find({
    required String idempotencyKey,
    required UserId userId,
  }) async {
    final rows = await _database.connection.execute(
      Sql.named('''
        SELECT idempotency_key, user_id::text, request_fingerprint,
               response_status, response_body
        FROM command_idempotency
        WHERE idempotency_key = @key
          AND (user_id IS NULL OR user_id = @userId::uuid)
        '''),
      parameters: {'key': idempotencyKey, 'userId': userId.value},
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final body = row[4];
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

    final fingerprint = row[2] as String;
    final parts = fingerprint.split(':');
    final commandName = parts.isNotEmpty ? parts.first : 'unknown';
    final requestHash =
        parts.length > 1 ? parts.sublist(1).join(':') : fingerprint;

    return IdempotencyRecord(
      idempotencyKey: row[0] as String,
      userId: UserId(row[1] as String? ?? userId.value),
      commandName: commandName,
      requestHash: requestHash,
      responseStatus: row[3] as int,
      responseBody: bodyMap,
    );
  }

  @override
  Future<void> save(IdempotencyRecord record) async {
    await _database.connection.execute(
      Sql.named('''
        INSERT INTO command_idempotency (
          idempotency_key, user_id, request_fingerprint,
          response_status, response_body
        ) VALUES (
          @key, @userId::uuid, @fingerprint,
          @status, @body::jsonb
        )
        ON CONFLICT (idempotency_key) DO NOTHING
        '''),
      parameters: {
        'key': record.idempotencyKey,
        'userId': record.userId.value,
        'fingerprint': record.requestFingerprint,
        'status': record.responseStatus,
        'body': jsonEncode(record.responseBody),
      },
    );
  }
}
