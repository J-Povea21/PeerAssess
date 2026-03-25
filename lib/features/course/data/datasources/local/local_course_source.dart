import 'dart:math';

import '../../../domain/models/course.dart';
import '../i_course_source.dart';

class LocalCourseSource implements ICourseSource {
  final List<Course> _courses = [];

  /// Maps courseId → teacherId (who created the course)
  final Map<String, String> _teacherCourses = {};

  /// Maps courseId → Set<studentId> (enrolled students)
  final Map<String, Set<String>> _studentEnrollments = {};

  /// Tracks the current teacher for course creation
  String? _activeTeacherId;

  LocalCourseSource();

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  String _generateEnrollmentCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<List<Course>> getCourses() {
    return Future.value(List.unmodifiable(_courses));
  }

  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) {
    _activeTeacherId = teacherId;
    final courseIds = _teacherCourses.entries
        .where((e) => e.value == teacherId)
        .map((e) => e.key)
        .toSet();
    final filtered = _courses.where((c) => courseIds.contains(c.id)).toList();
    return Future.value(filtered);
  }

  @override
  Future<List<Course>> getCoursesByStudent(String studentId) {
    final courseIds = _studentEnrollments.entries
        .where((e) => e.value.contains(studentId))
        .map((e) => e.key)
        .toSet();
    final filtered = _courses.where((c) => courseIds.contains(c.id)).toList();
    return Future.value(filtered);
  }

  @override
  Future<Course?> getCourseById(String courseId) {
    final course = _courses.cast<Course?>().firstWhere(
          (c) => c!.id == courseId,
          orElse: () => null,
        );
    return Future.value(course);
  }

  @override
  Future<bool> addCourse(Course course) {
    course.id = _generateId();
    course.enrollmentCode = _generateEnrollmentCode();
    _courses.add(course);
    // Associate with the active teacher
    if (_activeTeacherId != null) {
      _teacherCourses[course.id!] = _activeTeacherId!;
    }
    return Future.value(true);
  }

  @override
  Future<bool> updateCourse(Course course) {
    final index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
      return Future.value(true);
    }
    return Future.value(false);
  }

  @override
  Future<bool> deleteCourse(Course course) {
    _courses.removeWhere((c) => c.id == course.id);
    _teacherCourses.remove(course.id);
    _studentEnrollments.remove(course.id);
    return Future.value(true);
  }

  @override
  Future<Course?> joinCourse(String enrollmentCode) {
    final course = _courses.cast<Course?>().firstWhere(
          (c) => c!.enrollmentCode == enrollmentCode,
          orElse: () => null,
        );
    if (course != null) {
      course.studentCount++;
    }
    return Future.value(course);
  }

  /// Enroll a student in a course (for tracking).
  void enrollStudent(String courseId, String studentId) {
    _studentEnrollments.putIfAbsent(courseId, () => {});
    _studentEnrollments[courseId]!.add(studentId);
  }
}
