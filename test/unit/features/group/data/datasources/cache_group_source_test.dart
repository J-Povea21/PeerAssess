import 'package:f_clean_template/core/cache/cache_keys.dart';
import 'package:f_clean_template/features/group/data/datasources/cache/cache_group_source.dart';
import 'package:f_clean_template/features/group/data/datasources/i_group_source.dart';
import 'package:f_clean_template/features/group/domain/models/group.dart';
import 'package:f_clean_template/features/group/domain/models/group_category.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../../helpers/test_helpers.dart';

/// Uses `noSuchMethod` overrides (same pattern as MockHttpClient) so that
/// `when()` and `verify()` work correctly with non-nullable String params.
class MockIGroupSource extends Mock implements IGroupSource {
  @override
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId) =>
      super.noSuchMethod(
          Invocation.method(#getCategoriesByCourse, [courseId]),
          returnValue: Future.value(<GroupCategory>[]),
          returnValueForMissingStub: Future.value(<GroupCategory>[]));

  @override
  Future<List<Group>> getGroupsByCategory(String categoryId) =>
      super.noSuchMethod(
          Invocation.method(#getGroupsByCategory, [categoryId]),
          returnValue: Future.value(<Group>[]),
          returnValueForMissingStub: Future.value(<Group>[]));

  @override
  Future<GroupCategory> importCategoryFromCsv(
          String courseId, String csvContent) =>
      super.noSuchMethod(
          Invocation.method(#importCategoryFromCsv, [courseId, csvContent]),
          returnValue: Future.value(GroupCategory(
              id: '', name: '', courseId: '', groups: [])),
          returnValueForMissingStub: Future.value(GroupCategory(
              id: '', name: '', courseId: '', groups: [])));
}

void main() {
  late MockIGroupSource mockRemote;
  late FakeCacheService fakeCache;
  late CacheGroupSource sut;

  final category = mockCategory();
  final categoriesKey = CacheKeys.groupCategories('course-001');
  final groupsKey = CacheKeys.groups(category.id);

  setUp(() {
    mockRemote = MockIGroupSource();
    fakeCache = FakeCacheService();
    sut = CacheGroupSource(mockRemote, fakeCache);

    when(mockRemote.getCategoriesByCourse('course-001'))
        .thenAnswer((_) async => [category]);
    when(mockRemote.getGroupsByCategory(category.id))
        .thenAnswer((_) async => category.groups);
    when(mockRemote.importCategoryFromCsv('course-001', 'csv,data'))
        .thenAnswer((_) async => category);
  });

  // ── getCategoriesByCourse ──────────────────────────────────────────────────

  group('getCategoriesByCourse', () {
    test('returns cached list and does NOT call remote on cache hit', () async {
      fakeCache.primeCacheForList(categoriesKey, [category.toJson()]);

      final result = await sut.getCategoriesByCourse('course-001');

      expect(result, hasLength(1));
      verifyNever(mockRemote.getCategoriesByCourse('course-001'));
    });

    test('calls remote on cache miss and stores result', () async {
      await sut.getCategoriesByCourse('course-001');

      verify(mockRemote.getCategoriesByCourse('course-001')).called(1);
      expect(fakeCache.wasSetListCalledFor(categoriesKey), isTrue);
    });
  });

  // ── getGroupsByCategory ────────────────────────────────────────────────────

  group('getGroupsByCategory', () {
    test('returns cached list and does NOT call remote on cache hit', () async {
      fakeCache.primeCacheForList(
          groupsKey, category.groups.map((g) => g.toJson()).toList());

      final result = await sut.getGroupsByCategory(category.id);

      expect(result, hasLength(category.groups.length));
      verifyNever(mockRemote.getGroupsByCategory(category.id));
    });

    test('calls remote on cache miss and stores result', () async {
      await sut.getGroupsByCategory(category.id);

      verify(mockRemote.getGroupsByCategory(category.id)).called(1);
      expect(fakeCache.wasSetListCalledFor(groupsKey), isTrue);
    });
  });

  // ── remote throws ─────────────────────────────────────────────────────────

  group('remote throws', () {
    test('getCategoriesByCourse propagates exception and does not write cache',
        () async {
      when(mockRemote.getCategoriesByCourse('course-001'))
          .thenThrow(Exception('network error'));

      expect(
        () => sut.getCategoriesByCourse('course-001'),
        throwsA(isA<Exception>()),
      );
      expect(fakeCache.setListKeys, isEmpty);
    });

    test('getGroupsByCategory propagates exception and does not write cache',
        () async {
      when(mockRemote.getGroupsByCategory(category.id))
          .thenThrow(Exception('network error'));

      expect(
        () => sut.getGroupsByCategory(category.id),
        throwsA(isA<Exception>()),
      );
      expect(fakeCache.setListKeys, isEmpty);
    });
  });

  // ── importCategoryFromCsv ──────────────────────────────────────────────────

  group('importCategoryFromCsv', () {
    test('calls remote with correct arguments', () async {
      await sut.importCategoryFromCsv('course-001', 'csv,data');
      verify(mockRemote.importCategoryFromCsv('course-001', 'csv,data'))
          .called(1);
    });

    test('invalidates group categories cache for the course', () async {
      await sut.importCategoryFromCsv('course-001', 'csv,data');
      expect(fakeCache.wasInvalidated(categoriesKey), isTrue);
    });

    test('invalidates groups cache for the imported category id', () async {
      await sut.importCategoryFromCsv('course-001', 'csv,data');
      // category.id = 'cat-001'
      expect(fakeCache.wasInvalidated(groupsKey), isTrue);
    });

    test('returns the category returned by remote', () async {
      final result =
          await sut.importCategoryFromCsv('course-001', 'csv,data');
      expect(result.id, category.id);
      expect(result.name, category.name);
    });
  });
}
