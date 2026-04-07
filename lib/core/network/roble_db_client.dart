import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

import '../config/app_config.dart';

/// Reusable helper for Roble database CRUD operations.
///
/// Endpoints:
///   POST /database/{dbName}/insert   — { tableName, records }
///   GET  /database/{dbName}/read     — ?tableName=X&col=val
///   PUT  /database/{dbName}/update   — { tableName, idColumn, idValue, updates }
///   DELETE /database/{dbName}/delete — { tableName, idColumn, idValue }
class RobleDbClient with UiLoggy {
  final http.Client httpClient;

  RobleDbClient(this.httpClient);

  String get _base =>
      '${AppConfig.robleBaseUrl}/database/${AppConfig.robleToken}';

  /// Returns the current server time (UTC) from the Roble HTTP `Date` header.
  /// Used instead of device clock for deadline enforcement.
  Future<DateTime> getServerTime() async {
    final response = await httpClient.head(Uri.parse(_base));
    return HttpDate.parse(response.headers['date']!).toUtc();
  }

  /// Insert one or more records into [tableName].
  /// Returns `{ inserted: [...], skipped: [...] }`.
  Future<Map<String, dynamic>> insert(
    String tableName,
    List<Map<String, dynamic>> records,
  ) async {
    final payload = jsonEncode({'tableName': tableName, 'records': records});
    loggy.info('RobleDb: INSERT into $tableName (${records.length} records) body=$payload');

    final response = await httpClient.post(
      Uri.parse('$_base/insert'),
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    loggy.info('RobleDb: INSERT response status=${response.statusCode}');
    loggy.info('RobleDb: INSERT response body=${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    loggy.warning('RobleDb: INSERT failed ${response.statusCode} — ${response.body}');
    throw Exception('Insert failed: ${response.statusCode}');
  }

  /// Read records from [tableName] with optional [filters].
  /// Returns a list of record maps.
  Future<List<Map<String, dynamic>>> read(
    String tableName, [
    Map<String, String>? filters,
  ]) async {
    loggy.info('RobleDb: READ from $tableName filters=$filters');

    final queryParams = {'tableName': tableName, ...?filters};
    final uri = Uri.parse('$_base/read').replace(queryParameters: queryParams);

    loggy.info('RobleDb: READ url=$uri');
    final response = await httpClient.get(uri);
    loggy.info('RobleDb: READ response status=${response.statusCode}');
    loggy.info('RobleDb: READ response body=${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Roble may return a bare array or an object with a data/records key
      List<dynamic> rows;
      if (decoded is List) {
        rows = decoded;
      } else if (decoded is Map) {
        rows = (decoded['data'] ?? decoded['records'] ?? []) as List<dynamic>;
      } else {
        loggy.warning('RobleDb: READ unexpected type: ${decoded.runtimeType}');
        return [];
      }

      loggy.info('RobleDb: READ parsed ${rows.length} rows');
      return rows
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }

    loggy.warning('RobleDb: READ failed ${response.statusCode} — ${response.body}');
    throw Exception('Read failed: ${response.statusCode}');
  }

  /// Update a single record in [tableName] identified by [idColumn]=[idValue].
  Future<Map<String, dynamic>> update(
    String tableName,
    String idColumn,
    String idValue,
    Map<String, dynamic> updates,
  ) async {
    loggy.info('RobleDb: UPDATE $tableName where $idColumn=$idValue');

    final response = await httpClient.put(
      Uri.parse('$_base/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tableName': tableName,
        'idColumn': idColumn,
        'idValue': idValue,
        'updates': updates,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    loggy.warning('RobleDb: UPDATE failed ${response.statusCode} — ${response.body}');
    throw Exception('Update failed: ${response.statusCode}');
  }

  /// Delete a single record from [tableName] identified by [idColumn]=[idValue].
  Future<Map<String, dynamic>> delete(
    String tableName,
    String idColumn,
    String idValue,
  ) async {
    loggy.info('RobleDb: DELETE from $tableName where $idColumn=$idValue');

    final request = http.Request('DELETE', Uri.parse('$_base/delete'));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'tableName': tableName,
      'idColumn': idColumn,
      'idValue': idValue,
    });

    final streamed = await httpClient.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    loggy.warning('RobleDb: DELETE failed ${response.statusCode} — ${response.body}');
    throw Exception('Delete failed: ${response.statusCode}');
  }
}
