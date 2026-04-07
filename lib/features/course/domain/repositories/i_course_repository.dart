import '../models/course.dart';

abstract class ICourseRepository {
  Future<List<Course>> getCourses();

  Future<List<Course>> getCoursesByTeacher(String teacherId);

  Future<List<Course>> getCoursesByStudent(String studentId);

  Future<Course?> getCourseById(String courseId);

  Future<bool> addCourse(Course course);

  Future<bool> updateCourse(Course course);

  Future<bool> deleteCourse(Course course);

  Future<Course?> joinCourse(String enrollmentCode);
}
