import '../models/course.dart';

abstract class ICourseRepository {
  Future<List<Course>> getCourses();

  Future<List<Course>> getCoursesByTeacher(String teacherId);

  Future<List<Course>> getCoursesByStudent(String studentId);

  Future<bool> addCourse(Course course);

  Future<bool> updateCourse(Course course);

  Future<bool> deleteCourse(Course course);
}
