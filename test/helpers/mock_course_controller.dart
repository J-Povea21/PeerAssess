import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

/// Mock [CourseController] for Level 1 widget tests.
class MockCourseController extends GetxService
    with Mock
    implements CourseController {
  @override
  final RxList<Course> courses = <Course>[].obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  final Rx<Course?> selectedCourse = Rx<Course?>(null);

  @override
  Future<void> getCoursesByTeacher(String teacherId) async {}

  @override
  Future<void> getCoursesByStudent(String studentId) async {}

  @override
  Future<void> refreshCourses() async {}

  @override
  Future<bool> createCourse({
    required String name,
    required String semester,
    required String teacherName,
  }) async {
    return true;
  }

  @override
  Future<Course?> joinCourse(String enrollmentCode) async {
    return null;
  }

  @override
  Future<void> addCourse(Course course) async {}

  @override
  Future<void> updateCourse(Course course) async {}

  @override
  Future<void> deleteCourse(Course course) async {}

  @override
  void onInit() {}
}
