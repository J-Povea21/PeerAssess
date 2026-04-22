import 'dart:convert';

import 'package:loggy/loggy.dart';

import 'i_cache_service.dart';
import 'i_local_preferences.dart';

class CacheService implements ICacheService {
  final ILocalPreferences _prefs;

  CacheService(this._prefs);

  @override
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;

    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (_isExpired(envelope)) {
        await _prefs.remove(key);
        logInfo('CacheService: expired — key "$key"');
        return null;
      }
    } catch (e, st) {
      logWarning('CacheService: poisoned envelope for "$key": $e', e, st);
      await _prefs.remove(key);
      return null;
    }

    // fromJson errors propagate — they indicate a real model bug, not corruption.
    return fromJson(envelope['value'] as Map<String, dynamic>);
  }

  @override
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson, {
    Duration ttl = const Duration(minutes: 10),
  }) async {
    try {
      final envelope = _buildEnvelope(toJson(value), ttl);
      await _prefs.setString(key, jsonEncode(envelope));
      logInfo('CacheService: stored key "$key" (ttl ${ttl.inMinutes}m)');
    } catch (e, st) {
      logError('CacheService: error storing key "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = await _prefs.getString(key);
    if (raw == null) return null;

    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(raw) as Map<String, dynamic>;
      if (_isExpired(envelope)) {
        await _prefs.remove(key);
        logInfo('CacheService: expired list — key "$key"');
        return null;
      }
    } catch (e, st) {
      logWarning('CacheService: poisoned envelope for list "$key": $e', e, st);
      await _prefs.remove(key);
      return null;
    }

    // fromJson errors propagate — they indicate a real model bug, not corruption.
    final list = envelope['value'] as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> setList<T>(
    String key,
    List<T> values,
    Map<String, dynamic> Function(T) toJson, {
    Duration ttl = const Duration(minutes: 10),
  }) async {
    try {
      final envelope = _buildEnvelope(
        values.map(toJson).toList(),
        ttl,
      );
      await _prefs.setString(key, jsonEncode(envelope));
      logInfo('CacheService: stored list key "$key" (${values.length} items, ttl ${ttl.inMinutes}m)');
    } catch (e, st) {
      logError('CacheService: error storing list key "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<void> invalidate(String key) async {
    logInfo('CacheService: invalidating key "$key"');
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    logInfo('CacheService: clearing all cache');
    await _prefs.clear();
  }

  // — Helpers —

  bool _isExpired(Map<String, dynamic> envelope) {
    final cachedAt = DateTime.parse(envelope['cachedAt'] as String).toUtc();
    final ttlMs = envelope['ttl'] as int;
    return DateTime.now().toUtc().difference(cachedAt) >=
        Duration(milliseconds: ttlMs);
  }

  Map<String, dynamic> _buildEnvelope(dynamic value, Duration ttl) => {
        'value': value,
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'ttl': ttl.inMilliseconds,
      };
}
