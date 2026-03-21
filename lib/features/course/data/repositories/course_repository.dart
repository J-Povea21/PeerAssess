import '../../domain/models/course.dart';
import '../../domain/repositories/i_course_repository.dart';
import '../datasources/i_course_source.dart';

class CourseRepository implements ICourseRepository {
  late ICourseSource courseSource;

  CourseRepository(this.courseSource);

  @override
  Future<List<Course>> getCourses() async =>
      await courseSource.getCourses();

  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) async =>
      await courseSource.getCoursesByTeacher(teacherId);

  @override
  Future<List<Course>> getCoursesByStudent(String studentId) async =>
      await courseSource.getCoursesByStudent(studentId);

  @override
  Future<bool> addCourse(Course course) async =>
      await courseSource.addCourse(course);

  @override
  Future<bool> updateCourse(Course course) async =>
      await courseSource.updateCourse(course);

  @override
  Future<bool> deleteCourse(Course course) async =>
      await courseSource.deleteCourse(course);
}
