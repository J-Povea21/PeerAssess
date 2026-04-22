import 'package:loggy/loggy.dart';

import '../../../../../core/cache/cache_keys.dart';
import '../../../../../core/cache/i_cache_service.dart';
import '../../../../../core/services/session_service.dart';
import '../../../domain/models/course.dart';
import '../i_course_source.dart';

class CacheCourseSource implements ICourseSource {
  final ICourseSource _remote;
  final ICacheService _cache;
  final SessionService _session;

  CacheCourseSource(this._remote, this._cache, this._session);

  // — Cached reads —

  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) async {
    final key = CacheKeys.coursesTeacher(teacherId);
    final cached = await _cache.getList(key, Course.fromJson);
    if (cached != null) {
      logInfo('CacheCourseSource: hit — $key');
      return cached;
    }
    logInfo('CacheCourseSource: miss — $key, fetching remote');
    final courses = await _remote.getCoursesByTeacher(teacherId);
    await _cache.setList(key, courses, (c) => c.toJson());
    return courses;
  }

  @override
  Future<List<Course>> getCoursesByStudent(String studentId) async {
    final key = CacheKeys.coursesStudent(studentId);
    final cached = await _cache.getList(key, Course.fromJson);
    if (cached != null) {
      logInfo('CacheCourseSource: hit — $key');
      return cached;
    }
    logInfo('CacheCourseSource: miss — $key, fetching remote');
    final courses = await _remote.getCoursesByStudent(studentId);
    await _cache.setList(key, courses, (c) => c.toJson());
    return courses;
  }

  // — Pass-through reads —

  @override
  Future<List<Course>> getCourses() => _remote.getCourses();

  @override
  Future<Course?> getCourseById(String courseId) =>
      _remote.getCourseById(courseId);

  // — Writes (remote + invalidate) —

  @override
  Future<bool> addCourse(Course course) async {
    final result = await _remote.addCourse(course);
    if (result) await _invalidateTeacherCache();
    return result;
  }

  @override
  Future<bool> updateCourse(Course course) async {
    final result = await _remote.updateCourse(course);
    if (result) await _invalidateTeacherCache();
    return result;
  }

  @override
  Future<bool> deleteCourse(Course course) async {
    final result = await _remote.deleteCourse(course);
    if (result) await _invalidateTeacherCache();
    return result;
  }

  @override
  Future<Course?> joinCourse(String enrollmentCode) async {
    final result = await _remote.joinCourse(enrollmentCode);
    if (result != null) await _invalidateStudentCache();
    return result;
  }

  // — Helpers —

  Future<void> _invalidateTeacherCache() async {
    final userId = _session.cachedUser?.id;
    if (userId == null) return;
    await _cache.invalidate(CacheKeys.coursesTeacher(userId));
    logInfo('CacheCourseSource: invalidated teacher cache for user $userId');
  }

  Future<void> _invalidateStudentCache() async {
    final userId = _session.cachedUser?.id;
    if (userId == null) return;
    await _cache.invalidate(CacheKeys.coursesStudent(userId));
    logInfo('CacheCourseSource: invalidated student cache for user $userId');
  }
}
