import '../../../domain/models/course.dart';
import '../i_course_source.dart';

class LocalCourseSource implements ICourseSource {
  final List<Course> _courses = [
    // Teacher courses (teacherId: '1' = Prof. Ospina)
    Course(
      id: '101',
      name: 'Desarrollo Móvil',
      semester: '2026-10',
      studentCount: 28,
      status: CourseStatus.active,
      categoryCount: 3,
      evaluationCount: 2,
      teacherName: 'Prof. Ospina',
    ),
    Course(
      id: '102',
      name: 'Compiladores',
      semester: '2026-10',
      studentCount: 32,
      status: CourseStatus.active,
      categoryCount: 2,
      evaluationCount: 5,
      teacherName: 'Prof. Ospina',
    ),
    Course(
      id: '103',
      name: 'Inteligencia Artificial',
      semester: '2026-10',
      studentCount: 27,
      status: CourseStatus.pending,
      categoryCount: 0,
      evaluationCount: 0,
      teacherName: 'Prof. Ospina',
    ),
    // Student courses (studentId: '2' = María García)
    Course(
      id: '201',
      name: 'Desarrollo Móvil',
      semester: '2026-10',
      studentCount: 28,
      status: CourseStatus.active,
      categoryCount: 3,
      evaluationCount: 2,
      teacherName: 'Prof. Ospina',
      groupName: 'Grupo 3',
      pendingEvaluations: 1,
    ),
    Course(
      id: '202',
      name: 'Ingeniería de Software',
      semester: '2026-10',
      studentCount: 30,
      status: CourseStatus.active,
      categoryCount: 2,
      evaluationCount: 3,
      teacherName: 'Prof. Barreto',
      groupName: 'Grupo 1',
      pendingEvaluations: 0,
    ),
  ];

  // Maps courseIds to teacherIds/studentIds for filtering
  final Map<String, String> _teacherCourses = {
    '101': '1',
    '102': '1',
    '103': '1',
  };

  final Map<String, String> _studentCourses = {
    '201': '2',
    '202': '2',
  };

  LocalCourseSource();

  @override
  Future<List<Course>> getCourses() {
    return Future.value(List.unmodifiable(_courses));
  }

  @override
  Future<List<Course>> getCoursesByTeacher(String teacherId) {
    final courseIds = _teacherCourses.entries
        .where((e) => e.value == teacherId)
        .map((e) => e.key)
        .toSet();
    final filtered = _courses.where((c) => courseIds.contains(c.id)).toList();
    return Future.value(filtered);
  }

  @override
  Future<List<Course>> getCoursesByStudent(String studentId) {
    final courseIds = _studentCourses.entries
        .where((e) => e.value == studentId)
        .map((e) => e.key)
        .toSet();
    final filtered = _courses.where((c) => courseIds.contains(c.id)).toList();
    return Future.value(filtered);
  }

  @override
  Future<bool> addCourse(Course course) {
    course.id = DateTime.now().millisecondsSinceEpoch.toString();
    _courses.add(course);
    return Future.value(true);
  }

  @override
  Future<bool> updateCourse(Course course) {
    var index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
      return Future.value(true);
    }
    return Future.value(false);
  }

  @override
  Future<bool> deleteCourse(Course course) {
    _courses.remove(course);
    return Future.value(true);
  }
}
