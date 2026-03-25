import 'dart:math';

import 'package:loggy/loggy.dart';

import '../../../../../core/network/roble_db_client.dart';
import '../../../../../core/services/session_service.dart';
import '../../../domain/models/course.dart';
import '../i_course_source.dart';

/// Remote course source backed by Roble database.
///
/// Roble table schemas:
///   Courses:           _id, nrc, name, semester, teacherID, accessCode
///   CourseEnrollments:  _id, courseID, studentID, joinedAt
class RemoteCourseSource with UiLoggy implements ICourseSource {
  final RobleDbClient _db;
  final SessionService _session;

  RemoteCourseSource(this._db, this._session);

  String _generateId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateAccessCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Maps a Roble Courses row to a Course domain model.
  Course _rowToCourse(Map<String, dynamic> r) {
    return Course(
      id: r['_id']?.toString(),
      name: r['name']?.toString() ?? '---',
      semester: r['semester']?.toString() ?? '---',
      studentCount: 0, // computed separately if needed
      status: CourseStatus.active,
      categoryCount: 0,
      evaluationCount: 0,
      teacherName: null,
      enrollmentCode: r['accessCode']?.toString(),
    );
  }

  @override
  Future<List<Course>> getCourses() async {
    final records = await _db.read('Courses');
    return records.map(_rowToCourse).toList();
  }

  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) async {
    final records = await _db.read('Courses', {'teacherID': teacherId});
    return records.map(_rowToCourse).toList();
  }

  @override
  Future<List<Course>> getCoursesByStudent(String studentId) async {
    final enrollments =
        await _db.read('CourseEnrollments', {'studentID': studentId});
    final courses = <Course>[];
    for (final enrollment in enrollments) {
      final courseId = enrollment['courseID']?.toString();
      if (courseId == null) continue;
      final course = await getCourseById(courseId);
      if (course != null) courses.add(course);
    }
    return courses;
  }

  @override
  Future<Course?> getCourseById(String courseId) async {
    final records = await _db.read('Courses', {'_id': courseId});
    if (records.isEmpty) return null;
    return _rowToCourse(records.first);
  }

  @override
  Future<bool> addCourse(Course course) async {
    try {
      final user = _session.cachedUser;
      final accessCode = course.enrollmentCode ?? _generateAccessCode();

      await _db.insert('Courses', [
        {
          '_id': _generateId(),
          'name': course.name,
          'semester': course.semester,
          'nrc': _generateId(),
          'teacherID': user?.id ?? '',
          'accessCode': accessCode,
        }
      ]);
      return true;
    } catch (e) {
      loggy.warning('RemoteCourseSource: addCourse failed — $e');
      return false;
    }
  }

  @override
  Future<bool> updateCourse(Course course) async {
    try {
      if (course.id == null) return false;
      await _db.update('Courses', '_id', course.id!, {
        'name': course.name,
        'semester': course.semester,
        'accessCode': course.enrollmentCode ?? '',
      });
      return true;
    } catch (e) {
      loggy.warning('RemoteCourseSource: updateCourse failed — $e');
      return false;
    }
  }

  @override
  Future<bool> deleteCourse(Course course) async {
    try {
      if (course.id == null) return false;
      await _db.delete('Courses', '_id', course.id!);
      return true;
    } catch (e) {
      loggy.warning('RemoteCourseSource: deleteCourse failed — $e');
      return false;
    }
  }

  @override
  Future<Course?> joinCourse(String enrollmentCode) async {
    // Find course by accessCode
    final records =
        await _db.read('Courses', {'accessCode': enrollmentCode});
    if (records.isEmpty) return null;

    final course = _rowToCourse(records.first);
    final user = _session.cachedUser;
    if (user == null || course.id == null) return null;

    // Check if already enrolled
    final existing = await _db.read('CourseEnrollments', {
      'courseID': course.id!,
      'studentID': user.id ?? '',
    });
    if (existing.isNotEmpty) return course;

    // Create enrollment
    await _db.insert('CourseEnrollments', [
      {
        '_id': _generateId(),
        'courseID': course.id!,
        'studentID': user.id!,
        'joinedAt': DateTime.now().toIso8601String(),
      }
    ]);

    return course;
  }
}
