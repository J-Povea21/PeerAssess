import 'dart:convert';

import 'package:f_clean_template/core/cache/cache_service.dart';
import 'package:f_clean_template/core/cache/i_local_preferences.dart';
import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spy implementation — stores writes in memory so tests can read them back
/// without needing Mockito's `captureAny` (which has null-safety issues).
class SpyLocalPreferences implements ILocalPreferences {
  final Map<String, String> stored = {};
  final List<String> removedKeys = [];
  bool clearCalled = false;

  @override Future<String?> getString(String key) async => stored[key];
  @override Future<void> setString(String key, String value) async { stored[key] = value; }
  @override Future<void> remove(String key) async { removedKeys.add(key); }
  @override Future<void> clear() async { clearCalled = true; }

  // Unused in CacheService — provided to satisfy the interface
  @override Future<int?> getInt(String key) async => null;
  @override Future<void> setInt(String key, int value) async {}
  @override Future<double?> getDouble(String key) async => null;
  @override Future<void> setDouble(String key, double value) async {}
  @override Future<bool?> getBool(String key) async => null;
  @override Future<void> setBool(String key, bool value) async {}
  @override Future<List<String>?> getStringList(String key) async => null;
  @override Future<void> setStringList(String key, List<String> value) async {}
}

void main() {
  late SpyLocalPreferences spy;
  late CacheService sut;

  final course = Course(
    id: 'c-1', name: 'Test Course', semester: '2026-1',
    studentCount: 10, status: CourseStatus.active,
    categoryCount: 0, evaluationCount: 0,
  );

  setUp(() {
    spy = SpyLocalPreferences();
    sut = CacheService(spy);
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  void storeEnvelope(String key, dynamic value, {int ttlMs = 600000}) {
    spy.stored[key] = jsonEncode({
      'value': value,
      'cachedAt': DateTime.now().toUtc().toIso8601String(),
      'ttl': ttlMs,
    });
  }

  void storeStaleEnvelope(String key, dynamic value, {int ttlMs = 60000}) {
    spy.stored[key] = jsonEncode({
      'value': value,
      'cachedAt': DateTime.now()
          .toUtc()
          .subtract(Duration(milliseconds: ttlMs + 5000))
          .toIso8601String(),
      'ttl': ttlMs,
    });
  }

  // ── get ────────────────────────────────────────────────────────────────────

  group('get', () {
    test('returns null when key is not in storage', () async {
      expect(await sut.get('k', Course.fromJson), isNull);
    });

    test('returns null when TTL has expired', () async {
      storeStaleEnvelope('k', course.toJson());
      expect(await sut.get('k', Course.fromJson), isNull);
    });

    test('removes key from storage when TTL has expired', () async {
      storeStaleEnvelope('k', course.toJson());
      await sut.get('k', Course.fromJson);
      expect(spy.removedKeys, contains('k'));
    });

    test('returns deserialized value when within TTL', () async {
      storeEnvelope('k', course.toJson());
      final result = await sut.get('k', Course.fromJson);
      expect(result?.id, 'c-1');
      expect(result?.name, 'Test Course');
    });

    test('returns null without crashing when stored JSON is malformed', () async {
      spy.stored['k'] = '{{not-valid-json';
      expect(await sut.get('k', Course.fromJson), isNull);
    });

    test('removes key when stored JSON is malformed (self-heal)', () async {
      spy.stored['k'] = '{{not-valid-json';
      await sut.get('k', Course.fromJson);
      expect(spy.removedKeys, contains('k'));
    });

    test('removes key when envelope is valid JSON but missing required fields', () async {
      spy.stored['k'] = jsonEncode({'value': course.toJson()});
      await sut.get('k', Course.fromJson);
      expect(spy.removedKeys, contains('k'));
    });

    test('fromJson errors propagate instead of silently evicting the key', () async {
      storeEnvelope('k', course.toJson());
      // fromJson that always throws simulates a model schema bug.
      expect(
        () => sut.get<Course>('k', (_) => throw FormatException('bad schema')),
        throwsA(isA<FormatException>()),
      );
      // Key must NOT be removed — the envelope is valid, the bug is in the model.
      expect(spy.removedKeys, isNot(contains('k')));
    });
  });

  // ── getList / setList ──────────────────────────────────────────────────────

  group('getList', () {
    test('returns null when key is not in storage', () async {
      expect(await sut.getList('k', Course.fromJson), isNull);
    });

    test('returns null when TTL has expired', () async {
      storeStaleEnvelope('k', [course.toJson()]);
      expect(await sut.getList('k', Course.fromJson), isNull);
    });

    test('returns correctly deserialized list when within TTL', () async {
      storeEnvelope('k', [course.toJson()]);
      final result = await sut.getList('k', Course.fromJson);
      expect(result, hasLength(1));
      expect(result!.first.id, 'c-1');
      expect(result.first.name, 'Test Course');
    });

    test('setList / getList round-trip preserves all fields', () async {
      await sut.setList('k', [course], (c) => c.toJson());
      // spy.stored['k'] was written by setList — getList reads it back directly
      final result = await sut.getList('k', Course.fromJson);
      expect(result?.first.id, course.id);
      expect(result?.first.name, course.name);
      expect(result?.first.semester, course.semester);
    });
  });

  // ── invalidate / clear ─────────────────────────────────────────────────────

  group('invalidate', () {
    test('calls remove on the given key', () async {
      await sut.invalidate('my_key');
      expect(spy.removedKeys, contains('my_key'));
    });
  });

  group('clear', () {
    test('delegates to prefs.clear()', () async {
      await sut.clear();
      expect(spy.clearCalled, isTrue);
    });
  });

  // ── default TTL ────────────────────────────────────────────────────────────

  group('default TTL', () {
    test('stored envelope uses 600000 ms (10 min) when none is specified',
        () async {
      await sut.set('k', course, (c) => c.toJson());
      final envelope = jsonDecode(spy.stored['k']!) as Map<String, dynamic>;
      expect(envelope['ttl'], equals(600000));
    });

    test('stored envelope uses custom TTL in ms when specified', () async {
      await sut.set('k', course, (c) => c.toJson(),
          ttl: const Duration(minutes: 2));
      final envelope = jsonDecode(spy.stored['k']!) as Map<String, dynamic>;
      expect(envelope['ttl'], equals(120000));
    });

    test('cachedAt is stored as UTC ISO string', () async {
      await sut.set('k', course, (c) => c.toJson());
      final envelope = jsonDecode(spy.stored['k']!) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(envelope['cachedAt'] as String);
      expect(cachedAt.isUtc, isTrue);
    });
  });
}
