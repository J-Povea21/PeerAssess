import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/course.dart';
import '../../domain/repositories/i_course_repository.dart';

class CourseController extends GetxController {
  final RxList<Course> _courses = <Course>[].obs;
  late ICourseRepository repository;
  final RxBool isLoading = false.obs;

  List<Course> get courses => _courses;

  CourseController(this.repository);

  Future<void> getCoursesByTeacher(String teacherId) async {
    logInfo("CourseController: Getting courses for teacher $teacherId");
    isLoading.value = true;
    _courses.value = await repository.getCoursesByTeacher(teacherId);
    isLoading.value = false;
  }

  Future<void> getCoursesByStudent(String studentId) async {
    logInfo("CourseController: Getting courses for student $studentId");
    isLoading.value = true;
    _courses.value = await repository.getCoursesByStudent(studentId);
    isLoading.value = false;
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
