abstract class ICacheService {
  /// Returns the cached value, or null if missing or expired.
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  );

  /// Stores a value with a TTL (default 10 minutes).
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson, {
    Duration ttl = const Duration(minutes: 10),
  });

  /// Returns a cached list, or null if missing or expired.
  Future<List<T>?> getList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  );

  /// Stores a list with a TTL (default 10 minutes).
  Future<void> setList<T>(
    String key,
    List<T> values,
    Map<String, dynamic> Function(T) toJson, {
    Duration ttl = const Duration(minutes: 10),
  });

  /// Removes a single key.
  Future<void> invalidate(String key);

  /// Wipes all cached data.
  Future<void> clear();
}
