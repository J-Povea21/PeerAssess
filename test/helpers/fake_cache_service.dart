import 'package:f_clean_template/core/cache/i_cache_service.dart';

/// Fake [ICacheService] for unit tests.
///
/// Avoids Mockito's generic-method limitations by tracking interactions
/// with plain lists/maps instead of stubs.
///
/// Usage:
/// ```dart
/// fakeCache.primeCacheForList(key, [item.toJson()]);  // simulate hit
/// // don't prime → returns null                        // simulate miss
/// expect(fakeCache.wasSetListCalledFor(key), isTrue);  // verify stored
/// expect(fakeCache.wasInvalidated(key), isTrue);       // verify evicted
/// ```
class FakeCacheService implements ICacheService {
  final Map<String, List<Map<String, dynamic>>?> _getListData = {};
  final List<String> invalidatedKeys = [];
  final List<String> setListKeys = [];
  bool clearCalled = false;

  void primeCacheForList(String key, List<Map<String, dynamic>> data) =>
      _getListData[key] = data;

  bool wasSetListCalledFor(String key) => setListKeys.contains(key);
  bool wasInvalidated(String key) => invalidatedKeys.contains(key);

  @override
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async =>
      null;

  @override
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson, {
    Duration ttl = const Duration(minutes: 10),
  }) async {}

  @override
  Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final data = _getListData[key];
    if (data == null) return null;
    return data.map((e) => fromJson(e)).toList();
  }

  @override
  Future<void> setList<T>(
    String key,
    List<T> values,
    Map<String, dynamic> Function(T) toJson, {
    Duration ttl = const Duration(minutes: 10),
  }) async {
    setListKeys.add(key);
  }

  @override
  Future<void> invalidate(String key) async => invalidatedKeys.add(key);

  @override
  Future<void> clear() async => clearCalled = true;
}
