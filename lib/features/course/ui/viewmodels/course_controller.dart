import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/course.dart';
import '../../domain/repositories/i_course_repository.dart';

class CourseController extends GetxController {
  final RxList<Course> _courses = <Course>[].obs;
  late ICourseRepository repository;
  final RxBool isLoading = false.obs;
  final Rx<Course?> selectedCourse = Rx<Course?>(null);

  /// Tracks who is currently loading courses (for refresh after create)
  String? _activeUserId;
  bool _isTeacher = false;

  List<Course> get courses => _courses;

  CourseController(this.repository);

  Future<void> getCoursesByTeacher(String teacherId) async {
    logInfo("CourseController: Getting courses for teacher $teacherId");
    _activeUserId = teacherId;
    _isTeacher = true;
    isLoading.value = true;
    try {
      _courses.value = await repository.getCoursesByTeacher(teacherId);
    } catch (e) {
      logWarning("CourseController: Failed to get teacher courses — $e");
      _courses.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getCoursesByStudent(String studentId) async {
    logInfo("CourseController: Getting courses for student $studentId");
    _activeUserId = studentId;
    _isTeacher = false;
    isLoading.value = true;
    try {
      _courses.value = await repository.getCoursesByStudent(studentId);
    } catch (e) {
      logWarning("CourseController: Failed to get student courses — $e");
      _courses.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCourses() async {
    if (_activeUserId == null) return;
    if (_isTeacher) {
      await getCoursesByTeacher(_activeUserId!);
    } else {
      await getCoursesByStudent(_activeUserId!);
    }
  }

  Future<bool> createCourse({
    required String name,
    required String semester,
    required String teacherName,
  }) async {
    logInfo("CourseController: Creating course '$name'");
    final course = Course(
      name: name,
      semester: semester,
      studentCount: 0,
      status: CourseStatus.active,
      categoryCount: 0,
      evaluationCount: 0,
      teacherName: teacherName,
    );
    final success = await repository.addCourse(course);
    if (success) {
      await refreshCourses();
    }
    return success;
  }

  Future<Course?> joinCourse(String enrollmentCode) async {
    logInfo("CourseController: Joining course with code $enrollmentCode");
    final course = await repository.joinCourse(enrollmentCode);
    if (course != null) {
      await refreshCourses();
    }
    return course;
  }

  Future<void> addCourse(Course course) async {
    logInfo("CourseController: Add course");
    await repository.addCourse(course);
  }

  Future<void> updateCourse(Course course) async {
    logInfo("CourseController: Update course");
    await repository.updateCourse(course);
  }

  Future<void> deleteCourse(Course course) async {
    logInfo("CourseController: Delete course");
    await repository.deleteCourse(course);
  }
}
