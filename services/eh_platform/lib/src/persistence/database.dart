import 'package:postgres/postgres.dart';

/// PostgreSQL connectivity for the EH Platform (PF-ADR-007).
final class PlatformDatabase {
  PlatformDatabase(this._connection);

  final Connection _connection;

  Connection get connection => _connection;

  static Future<PlatformDatabase> connect(String databaseUrl) async {
    final uri = Uri.parse(databaseUrl);
    final connection = await Connection.open(
      Endpoint(
        host: uri.host.isEmpty ? '127.0.0.1' : uri.host,
        port: uri.hasPort ? uri.port : 5432,
        database: uri.pathSegments.isEmpty ? 'eh_platform' : uri.pathSegments.first,
        username: uri.userInfo.isEmpty
            ? null
            : Uri.decodeComponent(uri.userInfo.split(':').first),
        password: uri.userInfo.contains(':')
            ? Uri.decodeComponent(uri.userInfo.split(':').sublist(1).join(':'))
            : null,
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    return PlatformDatabase(connection);
  }

  Future<bool> isReady() async {
    final result = await _connection.execute('SELECT 1');
    return result.isNotEmpty;
  }

  Future<T> runInTransaction<T>(
    Future<T> Function(TxSession session) action,
  ) {
    return _connection.runTx(action);
  }

  Future<void> close() => _connection.close();
}
