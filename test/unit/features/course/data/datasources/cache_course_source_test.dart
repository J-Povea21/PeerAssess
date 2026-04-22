import 'package:f_clean_template/core/cache/cache_keys.dart';
import 'package:f_clean_template/core/services/session_service.dart';
import 'package:f_clean_template/features/course/data/datasources/cache/cache_course_source.dart';
import 'package:f_clean_template/features/course/data/datasources/i_course_source.dart';
import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../../helpers/test_helpers.dart';

/// Uses `noSuchMethod` overrides (same pattern as MockHttpClient) so that
/// `when()` and `verify()` work correctly with non-nullable String params.
class MockICourseSource extends Mock implements ICourseSource {
  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) =>
      super.noSuchMethod(
          Invocation.method(#getCoursesByTeacher, [teacherId]),
          returnValue: Future.value(<Course>[]),
          returnValueForMissingStub: Future.value(<Course>[]));

  @override
  Future<List<Course>> getCoursesByStudent(String studentId) =>
      super.noSuchMethod(
          Invocation.method(#getCoursesByStudent, [studentId]),
          returnValue: Future.value(<Course>[]),
          returnValueForMissingStub: Future.value(<Course>[]));

  @override
  Future<List<Course>> getCourses() =>
      super.noSuchMethod(Invocation.method(#getCourses, []),
          returnValue: Future.value(<Course>[]),
          returnValueForMissingStub: Future.value(<Course>[]));

  @override
  Future<Course?> getCourseById(String courseId) =>
      super.noSuchMethod(Invocation.method(#getCourseById, [courseId]),
          returnValue: Future<Course?>.value(null),
          returnValueForMissingStub: Future<Course?>.value(null));

  @override
  Future<bool> addCourse(Course course) =>
      super.noSuchMethod(Invocation.method(#addCourse, [course]),
          returnValue: Future.value(true),
          returnValueForMissingStub: Future.value(true));

  @override
  Future<bool> updateCourse(Course course) =>
      super.noSuchMethod(Invocation.method(#updateCourse, [course]),
          returnValue: Future.value(true),
          returnValueForMissingStub: Future.value(true));

  @override
  Future<bool> deleteCourse(Course course) =>
      super.noSuchMethod(Invocation.method(#deleteCourse, [course]),
          returnValue: Future.value(true),
          returnValueForMissingStub: Future.value(true));

  @override
  Future<Course?> joinCourse(String enrollmentCode) =>
      super.noSuchMethod(Invocation.method(#joinCourse, [enrollmentCode]),
          returnValue: Future<Course?>.value(null),
          returnValueForMissingStub: Future<Course?>.value(null));
}

void main() {
  late MockICourseSource mockRemote;
  late FakeCacheService fakeCache;
  late SessionService session;
  late CacheCourseSource sut;

  final courses = mockCourses();
  final teacherKey = CacheKeys.coursesTeacher(mockTeacher.id!);
  final studentKey = CacheKeys.coursesStudent(mockStudent.id!);

  setUp(() {
    mockRemote = MockICourseSource();
    fakeCache = FakeCacheService();
    session = SessionService()..setTestUser(mockTeacher);
    sut = CacheCourseSource(mockRemote, fakeCache, session);

    when(mockRemote.getCoursesByTeacher(mockTeacher.id!))
        .thenAnswer((_) async => courses);
    when(mockRemote.getCoursesByStudent(mockStudent.id!))
        .thenAnswer((_) async => courses);
    when(mockRemote.getCourses()).thenAnswer((_) async => courses);
    when(mockRemote.getCourseById('course-001'))
        .thenAnswer((_) async => courses.first);
    when(mockRemote.addCourse(courses.first)).thenAnswer((_) async => true);
    when(mockRemote.updateCourse(courses.first)).thenAnswer((_) async => true);
    when(mockRemote.deleteCourse(courses.first)).thenAnswer((_) async => true);
    when(mockRemote.joinCourse('ABC123'))
        .thenAnswer((_) async => courses.first);
    when(mockRemote.joinCourse('INVALID')).thenAnswer((_) async => null);
  });

  // ── getCoursesByTeacher ────────────────────────────────────────────────────

  group('getCoursesByTeacher', () {
    test('returns cached list and does NOT call remote on cache hit', () async {
      fakeCache.primeCacheForList(
          teacherKey, courses.map((c) => c.toJson()).toList());

      final result = await sut.getCoursesByTeacher(mockTeacher.id!);

      expect(result, hasLength(courses.length));
      verifyNever(mockRemote.getCoursesByTeacher(mockTeacher.id!));
    });

    test('calls remote on cache miss', () async {
      await sut.getCoursesByTeacher(mockTeacher.id!);
      verify(mockRemote.getCoursesByTeacher(mockTeacher.id!)).called(1);
    });

    test('stores remote result in cache on miss', () async {
      await sut.getCoursesByTeacher(mockTeacher.id!);
      expect(fakeCache.wasSetListCalledFor(teacherKey), isTrue);
    });

    test('returns remote result on cache miss', () async {
      final result = await sut.getCoursesByTeacher(mockTeacher.id!);
      expect(result, equals(courses));
    });
  });

  // ── getCoursesByStudent ────────────────────────────────────────────────────

  group('getCoursesByStudent', () {
    test('returns cached list and does NOT call remote on cache hit', () async {
      fakeCache.primeCacheForList(
          studentKey, courses.map((c) => c.toJson()).toList());

      final result = await sut.getCoursesByStudent(mockStudent.id!);

      expect(result, hasLength(courses.length));
      verifyNever(mockRemote.getCoursesByStudent(mockStudent.id!));
    });

    test('calls remote on cache miss and stores result', () async {
      await sut.getCoursesByStudent(mockStudent.id!);

      verify(mockRemote.getCoursesByStudent(mockStudent.id!)).called(1);
      expect(fakeCache.wasSetListCalledFor(studentKey), isTrue);
    });
  });

  // ── addCourse ──────────────────────────────────────────────────────────────

  group('addCourse', () {
    test('calls remote and invalidates teacher cache key on success', () async {
      await sut.addCourse(courses.first);

      verify(mockRemote.addCourse(courses.first)).called(1);
      expect(fakeCache.wasInvalidated(teacherKey), isTrue);
    });

    test('does NOT invalidate cache when remote returns false', () async {
      when(mockRemote.addCourse(courses.first)).thenAnswer((_) async => false);

      await sut.addCourse(courses.first);

      expect(fakeCache.invalidatedKeys, isEmpty);
    });
  });

  // ── updateCourse ───────────────────────────────────────────────────────────

  group('updateCourse', () {
    test('calls remote and invalidates teacher cache key on success', () async {
      await sut.updateCourse(courses.first);

      verify(mockRemote.updateCourse(courses.first)).called(1);
      expect(fakeCache.wasInvalidated(teacherKey), isTrue);
    });

    test(
        'does NOT invalidate student cache — '
        'student devices manage their own cache via TTL', () async {
      await sut.updateCourse(courses.first);

      expect(
        fakeCache.invalidatedKeys.where((k) => k.startsWith('courses:student:')),
        isEmpty,
      );
    });
  });

  // ── deleteCourse ───────────────────────────────────────────────────────────

  group('deleteCourse', () {
    test('calls remote and invalidates teacher cache key on success', () async {
      await sut.deleteCourse(courses.first);

      verify(mockRemote.deleteCourse(courses.first)).called(1);
      expect(fakeCache.wasInvalidated(teacherKey), isTrue);
    });
  });

  // ── joinCourse ─────────────────────────────────────────────────────────────

  group('joinCourse', () {
    setUp(() {
      session.setTestUser(mockStudent);
      sut = CacheCourseSource(mockRemote, fakeCache, session);
    });

    test('calls remote and invalidates student cache key on success', () async {
      await sut.joinCourse('ABC123');

      verify(mockRemote.joinCourse('ABC123')).called(1);
      expect(fakeCache.wasInvalidated(studentKey), isTrue);
    });

    test('does NOT invalidate cache when remote returns null', () async {
      await sut.joinCourse('INVALID');

      expect(fakeCache.invalidatedKeys, isEmpty);
    });
  });

  // ── remote throws ─────────────────────────────────────────────────────────

  group('remote throws', () {
    test('getCoursesByTeacher propagates exception and does not write cache',
        () async {
      when(mockRemote.getCoursesByTeacher(mockTeacher.id!))
          .thenThrow(Exception('network error'));

      expect(
        () => sut.getCoursesByTeacher(mockTeacher.id!),
        throwsA(isA<Exception>()),
      );
      expect(fakeCache.setListKeys, isEmpty);
    });

    test('getCoursesByStudent propagates exception and does not write cache',
        () async {
      when(mockRemote.getCoursesByStudent(mockStudent.id!))
          .thenThrow(Exception('network error'));

      expect(
        () => sut.getCoursesByStudent(mockStudent.id!),
        throwsA(isA<Exception>()),
      );
      expect(fakeCache.setListKeys, isEmpty);
    });
  });

  // ── pass-throughs ──────────────────────────────────────────────────────────

  group('pass-throughs', () {
    test('getCourses delegates directly to remote with no cache interaction',
        () async {
      final result = await sut.getCourses();

      verify(mockRemote.getCourses()).called(1);
      expect(fakeCache.setListKeys, isEmpty);
      expect(result, equals(courses));
    });

    test('getCourseById delegates directly to remote with no cache interaction',
        () async {
      final result = await sut.getCourseById('course-001');

      verify(mockRemote.getCourseById('course-001')).called(1);
      expect(fakeCache.setListKeys, isEmpty);
      expect(result, equals(courses.first));
    });
  });
}
