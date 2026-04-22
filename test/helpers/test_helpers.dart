import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:f_clean_template/features/group/domain/models/group.dart';
import 'package:f_clean_template/features/group/domain/models/group_category.dart';
import 'package:f_clean_template/features/group/domain/models/group_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// ---------------------------------------------------------------------------
// Barrel export — import this single file in every test
// ---------------------------------------------------------------------------

export 'fake_cache_service.dart';
export 'mock_analytics_controller.dart';
export 'mock_assessment_controller.dart';
export 'mock_auth_controller.dart';
export 'mock_course_controller.dart';
export 'mock_evaluation_controller.dart';
export 'mock_group_controller.dart';
export 'mock_http_client.dart';
export 'mock_reflection_controller.dart';


/// Matches any [Uri] instance — useful with `argThat(isAUri)` in mockito stubs.
const Matcher isAUri = _IsAUri();

class _IsAUri extends Matcher {
  const _IsAUri();

  @override
  bool matches(dynamic item, Map matchState) => item is Uri;

  @override
  Description describe(Description description) =>
      description.add('is a Uri');
}


/// A teacher user for test scenarios.
final User mockTeacher = User(
  id: 'teacher-001',
  name: 'Prof. García',
  email: 'garcia@uninorte.edu.co',
  role: UserRole.teacher,
);

/// A student user for test scenarios.
final User mockStudent = User(
  id: 'student-001',
  name: 'María López',
  email: 'mlopez@uninorte.edu.co',
  role: UserRole.student,
);


/// Sample course list for test scenarios.
List<Course> mockCourses() => [
      Course(
        id: 'course-001',
        name: 'Desarrollo Móvil',
        semester: '2026-1',
        studentCount: 25,
        status: CourseStatus.active,
        categoryCount: 2,
        evaluationCount: 1,
        teacherName: 'Prof. García',
        enrollmentCode: 'ABC123',
      ),
      Course(
        id: 'course-002',
        name: 'Ingeniería de Software',
        semester: '2026-1',
        studentCount: 30,
        status: CourseStatus.active,
        categoryCount: 1,
        evaluationCount: 0,
        teacherName: 'Prof. Salazar',
        enrollmentCode: 'XYZ789',
      ),
    ];

/// A single course with pending evaluations (student view).
Course mockCourseWithPending() => Course(
      id: 'course-001',
      name: 'Desarrollo Móvil',
      semester: '2026-1',
      studentCount: 25,
      status: CourseStatus.active,
      categoryCount: 2,
      evaluationCount: 1,
      teacherName: 'Prof. García',
      pendingEvaluations: 3,
      enrollmentCode: 'ABC123',
    );

/// Sample group category for test scenarios.
GroupCategory mockCategory() => GroupCategory(
      id: 'cat-001',
      name: 'Sprint 1',
      courseId: 'course-001',
      groups: [
        Group(
          id: 'grp-001',
          name: 'Group 1',
          categoryId: 'cat-001',
          members: [
            GroupMember(id: 'gm-001', firstName: 'María', lastName: 'López', email: 'mlopez@uninorte.edu.co'),
            GroupMember(id: 'gm-002', firstName: 'Carlos', lastName: 'Ruiz', email: 'cruiz@uninorte.edu.co'),
          ],
        ),
        Group(
          id: 'grp-002',
          name: 'Group 2',
          categoryId: 'cat-001',
          members: [
            GroupMember(id: 'gm-003', firstName: 'Ana', lastName: 'Torres', email: 'atorres@uninorte.edu.co'),
          ],
        ),
      ],
    );

/// Wraps [child] in a [GetMaterialApp] so GetX routing, DI, and Obx work
/// correctly in widget tests.
///
/// Usage:
/// ```dart
/// await tester.pumpWidget(pumpApp(const MyPage()));
/// ```
Widget pumpApp(Widget child) {
  return GetMaterialApp(
    home: child,
  );
}
