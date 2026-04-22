import 'dart:convert';

import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/core/network/roble_db_client.dart';
import 'package:f_clean_template/core/services/session_service.dart';
import 'package:f_clean_template/features/auth/data/datasources/i_auth_source.dart';
import 'package:f_clean_template/features/auth/data/datasources/remote/remote_auth_source.dart';
import 'package:f_clean_template/features/auth/data/repositories/auth_repository.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/data/datasources/i_course_source.dart';
import 'package:f_clean_template/features/course/data/datasources/remote/remote_course_source.dart';
import 'package:f_clean_template/features/course/data/repositories/course_repository.dart';
import 'package:f_clean_template/features/course/domain/repositories/i_course_repository.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/course_list_page.dart';
import 'package:f_clean_template/features/group/data/datasources/i_group_source.dart';
import 'package:f_clean_template/features/group/data/datasources/remote/remote_group_source.dart';
import 'package:f_clean_template/features/group/data/repositories/group_repository.dart';
import 'package:f_clean_template/features/group/domain/repositories/i_group_repository.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockHttpClient mockHttp;

  // ═══════════════════════════════════════════════════════════════════
  //  SHARED HELPERS (same pattern as assessment_flow_test)
  // ═══════════════════════════════════════════════════════════════════

  /// Stubs GET (read) calls dispatching by `tableName` query-param.
  /// Applies remaining query-params as row filters (simulates Roble).
  void stubReads(
      MockHttpClient client, Map<String, List<Map<String, dynamic>>> data) {
    when(client.get(argThat(isAUri), headers: anyNamed('headers')))
        .thenAnswer((inv) async {
      final uri = inv.positionalArguments[0] as Uri;
      final table = uri.queryParameters['tableName'] ?? '';
      final filters = Map<String, String>.from(uri.queryParameters)
        ..remove('tableName');
      final rows = (data[table] ?? []).where((row) {
        return filters.entries
            .every((f) => row[f.key]?.toString() == f.value);
      }).toList();
      return http.Response(jsonEncode(rows), 200);
    });
  }

  /// Stubs all POST (insert) calls -> 201 success.
  void stubInserts(MockHttpClient client) {
    when(client.post(argThat(isAUri),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding')))
        .thenAnswer((_) async => http.Response(
            jsonEncode({'inserted': [], 'skipped': []}), 201));
  }

  // ═══════════════════════════════════════════════════════════════════
  //  1. COURSE LIST FLOW — full-stack with UI
  // ═══════════════════════════════════════════════════════════════════

  group('Level 3 — Course list flow (teacher)', () {
    late SessionService session;
    late RobleDbClient robleDb;
    late CourseController courseController;

    setUp(() {
      Get.reset();
      mockHttp = MockHttpClient();

      // ── Register REAL layers (mirrors main.dart) ──
      session = SessionService();
      session.setTestUser(mockTeacher);

      robleDb = RobleDbClient(mockHttp);

      final courseSource = RemoteCourseSource(robleDb, session);
      final courseRepo = CourseRepository(courseSource);
      courseController = CourseController(courseRepo);

      // Register with GetX so UI pages can find them
      Get.put<http.Client>(mockHttp);
      Get.put(session);
      Get.put(robleDb);
      Get.put<ICourseSource>(courseSource);
      Get.put<ICourseRepository>(courseRepo);
      Get.put(courseController);

      // AuthController is needed by CourseListPage — use mock for simplicity
      final mockAuth = MockAuthController();
      mockAuth.setUser(mockTeacher);
      Get.put<AuthController>(mockAuth);
    });

    tearDown(() => Get.reset());

    // ── Reusable Roble data ──

    final courseRows = [
      {
        '_id': 'course-001',
        'name': 'Desarrollo Movil',
        'semester': '2026-1',
        'nrc': 'NRC001',
        'teacherID': 'teacher-001',
        'accessCode': 'ABC123',
      },
      {
        '_id': 'course-002',
        'name': 'Ingenieria de Software',
        'semester': '2026-1',
        'nrc': 'NRC002',
        'teacherID': 'teacher-001',
        'accessCode': 'XYZ789',
      },
    ];

    final enrichmentData = <String, List<Map<String, dynamic>>>{
      'Courses': courseRows,
      'CourseEnrollments': [
        {'_id': 'enr-1', 'courseID': 'course-001', 'studentID': 'student-001'},
        {'_id': 'enr-2', 'courseID': 'course-001', 'studentID': 'student-002'},
        {'_id': 'enr-3', 'courseID': 'course-002', 'studentID': 'student-001'},
      ],
      'GroupCategories': [
        {'_id': 'cat-001', 'courseID': 'course-001', 'name': 'Sprint 1'},
      ],
      'assessments': [],
    };

    testWidgets(
        'getCoursesByTeacher loads courses through full stack '
        'and renders them in CourseListPage', (tester) async {
      stubReads(mockHttp, enrichmentData);

      // Load courses through real controller -> repo -> source -> RobleDbClient
      await courseController.getCoursesByTeacher('teacher-001');

      // Verify controller state
      expect(courseController.courses.length, 2);
      expect(courseController.courses[0].name, 'Desarrollo Movil');
      expect(courseController.courses[1].name, 'Ingenieria de Software');

      // Verify enrichment counts
      expect(courseController.courses[0].studentCount, 2);
      expect(courseController.courses[0].categoryCount, 1);
      expect(courseController.courses[1].studentCount, 1);
      expect(courseController.courses[1].categoryCount, 0);

      // ── Render UI ──
      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      // Assert: course names appear in UI
      expect(find.text('Desarrollo Movil'), findsOneWidget);
      expect(find.text('Ingenieria de Software'), findsOneWidget);

      // Assert: combined stats label (semester | students | categories | evaluations)
      expect(find.text('2026-1 | 2 estudiantes | 1 categorías | 0 evaluaciones'),
          findsOneWidget);
      expect(find.text('2026-1 | 1 estudiantes | 0 categorías | 0 evaluaciones'),
          findsOneWidget);

      // ── Verify HTTP calls ──
      // getCoursesByTeacher reads Courses table, then enriches each course
      // with CourseEnrollments, GroupCategories, assessments counts.
      // That's 1 + 3*2 = 7 GET calls total.
      verify(mockHttp.get(argThat(isAUri), headers: anyNamed('headers')))
          .called(7);
    });

    testWidgets('empty course list shows empty state message', (tester) async {
      stubReads(mockHttp, {
        'Courses': <Map<String, dynamic>>[],
      });

      await courseController.getCoursesByTeacher('teacher-001');

      expect(courseController.courses, isEmpty);

      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(find.text('No tienes cursos creados'), findsOneWidget);

      verify(mockHttp.get(argThat(isAUri), headers: anyNamed('headers')))
          .called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  2. AUTH LOGIN FLOW — full-stack at controller level
  // ═══════════════════════════════════════════════════════════════════

  group('Level 3 — Auth login flow', () {
    late SessionService session;
    late RemoteAuthSource authSource;
    late AuthRepository authRepo;
    late AuthController authController;

    setUp(() async {
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      mockHttp = MockHttpClient();

      // ── Register REAL layers (mirrors main.dart) ──
      session = SessionService();
      await session.load();

      authSource = RemoteAuthSource(mockHttp, session);
      authRepo = AuthRepository(authSource);

      Get.put<http.Client>(mockHttp);
      Get.put(session);
      Get.put<IAuthSource>(authSource);
      Get.put<IAuthRepository>(authRepo);

      // AuthController.onInit calls _restoreSession.
      // Since session.hasSession is false, getCurrentUser returns null
      // immediately (no HTTP call).
      Get.put(authController = AuthController(authRepo));
    });

    tearDown(() => Get.reset());

    test('login — POST returns user + tokens, controller state updated',
        () async {
      // Stub HTTP POST → 201 with user + tokens
      when(mockHttp.post(argThat(isAUri),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding')))
          .thenAnswer((_) async => http.Response(
              jsonEncode({
                'user': {
                  '_id': 'teacher-001',
                  'name': 'Prof. Garcia',
                  'email': 'garcia@uninorte.edu.co',
                  'role': 'TEACHER',
                },
                'accessToken': 'fake-access-token',
                'refreshToken': 'fake-refresh-token',
              }),
              201));

      // Pre-conditions
      expect(authController.isLogged, isFalse);
      expect(authController.currentUser, isNull);

      // Act — full chain: AuthController -> AuthRepository -> RemoteAuthSource -> http.Client
      final success =
          await authController.login('garcia@uninorte.edu.co', 'password123');

      // Assert controller state
      expect(success, isTrue);
      expect(authController.isLogged, isTrue);
      expect(authController.currentUser, isNotNull);
      expect(authController.currentUser!.name, 'Prof. Garcia');
      expect(authController.currentUser!.email, 'garcia@uninorte.edu.co');
      expect(authController.currentUser!.role, UserRole.teacher);
      expect(authController.isLoading.value, isFalse);

      // Assert session was saved
      expect(session.accessToken, 'fake-access-token');
      expect(session.refreshToken, 'fake-refresh-token');
      expect(session.cachedUser?.id, 'teacher-001');

      // Verify HTTP POST was called exactly once
      final captured = verify(mockHttp.post(
        argThat(isAUri),
        headers: captureAnyNamed('headers'),
        body: captureAnyNamed('body'),
        encoding: anyNamed('encoding'),
      )).captured;

      // Headers should include Content-Type
      final headers = captured[0] as Map<String, String>;
      expect(headers['Content-Type'], 'application/json');

      // Body should contain email + password
      final body = jsonDecode(captured[1] as String);
      expect(body['email'], 'garcia@uninorte.edu.co');
      expect(body['password'], 'password123');
    });

    test('login — failed credentials return false, user stays null', () async {
      when(mockHttp.post(argThat(isAUri),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding')))
          .thenAnswer((_) async => http.Response(
              jsonEncode({'message': 'Invalid credentials'}), 401));

      final success =
          await authController.login('wrong@uninorte.edu.co', 'badpass');

      expect(success, isFalse);
      expect(authController.isLogged, isFalse);
      expect(authController.currentUser, isNull);
      expect(authController.isLoading.value, isFalse);

      verify(mockHttp.post(argThat(isAUri),
              headers: anyNamed('headers'),
              body: anyNamed('body'),
              encoding: anyNamed('encoding')))
          .called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  //  3. GROUP CATEGORIES FLOW — full-stack at controller level
  // ═══════════════════════════════════════════════════════════════════

  group('Level 3 — Group categories flow', () {
    late RobleDbClient robleDb;
    late GroupController groupController;

    setUp(() {
      Get.reset();
      mockHttp = MockHttpClient();

      // ── Register REAL layers (mirrors main.dart) ──
      robleDb = RobleDbClient(mockHttp);

      final groupSource = RemoteGroupSource(robleDb);
      final groupRepo = GroupRepository(groupSource);
      groupController = GroupController(groupRepo);

      Get.put<http.Client>(mockHttp);
      Get.put(robleDb);
      Get.put<IGroupSource>(groupSource);
      Get.put<IGroupRepository>(groupRepo);
      Get.put(groupController);
    });

    tearDown(() => Get.reset());

    test(
        'loadCategories — reads categories, groups, members, users '
        'through full stack', () async {
      stubReads(mockHttp, {
        'GroupCategories': [
          {'_id': 'cat-001', 'courseID': 'course-001', 'name': 'Sprint 1'},
        ],
        'Groups': [
          {'_id': 'grp-001', 'categoryID': 'cat-001', 'name': 'Group 1'},
          {'_id': 'grp-002', 'categoryID': 'cat-001', 'name': 'Group 2'},
        ],
        'GroupMembers': [
          {'_id': 'gm-001', 'groupID': 'grp-001', 'studentID': 'stu-001'},
          {'_id': 'gm-002', 'groupID': 'grp-001', 'studentID': 'stu-002'},
          {'_id': 'gm-003', 'groupID': 'grp-002', 'studentID': 'stu-003'},
        ],
        'Users': [
          {
            '_id': 'stu-001',
            'name': 'Maria Lopez',
            'mail': 'mlopez@uninorte.edu.co',
            'role': 'STUDENT'
          },
          {
            '_id': 'stu-002',
            'name': 'Carlos Ruiz',
            'mail': 'cruiz@uninorte.edu.co',
            'role': 'STUDENT'
          },
          {
            '_id': 'stu-003',
            'name': 'Ana Torres',
            'mail': 'atorres@uninorte.edu.co',
            'role': 'STUDENT'
          },
        ],
      });

      // Act — full chain: GroupController -> GroupRepository -> RemoteGroupSource -> RobleDbClient
      await groupController.loadCategories('course-001');

      // Assert controller state
      expect(groupController.categories.length, 1);
      final cat = groupController.categories.first;
      expect(cat.name, 'Sprint 1');
      expect(cat.courseId, 'course-001');
      expect(cat.groupCount, 2);

      // Verify groups and members resolved
      expect(cat.groups[0].name, 'Group 1');
      expect(cat.groups[0].members.length, 2);
      expect(cat.groups[0].members[0].firstName, 'Maria');
      expect(cat.groups[0].members[0].lastName, 'Lopez');
      expect(cat.groups[0].members[0].email, 'mlopez@uninorte.edu.co');

      expect(cat.groups[1].name, 'Group 2');
      expect(cat.groups[1].members.length, 1);
      expect(cat.groups[1].members[0].firstName, 'Ana');
      expect(cat.groups[1].members[0].lastName, 'Torres');

      // Verify total member count
      expect(cat.memberCount, 3);

      // Verify HTTP GETs happened
      // Flow: GroupCategories(1) + Groups(1) + GroupMembers(2) + Users(1) = 5 GETs
      verify(mockHttp.get(argThat(isAUri), headers: anyNamed('headers')))
          .called(5);
    });

    test('empty categories — no groups or members fetched', () async {
      stubReads(mockHttp, {
        'GroupCategories': <Map<String, dynamic>>[],
      });

      await groupController.loadCategories('course-001');

      expect(groupController.categories, isEmpty);
      expect(groupController.isLoading.value, isFalse);

      // Only 1 GET for GroupCategories
      verify(mockHttp.get(argThat(isAUri), headers: anyNamed('headers')))
          .called(1);
    });

    test('loadGroups — loads groups for a specific category', () async {
      stubReads(mockHttp, {
        'Groups': [
          {'_id': 'grp-001', 'categoryID': 'cat-001', 'name': 'Group 1'},
          {'_id': 'grp-002', 'categoryID': 'cat-001', 'name': 'Group 2'},
        ],
        'GroupMembers': [
          {'_id': 'gm-001', 'groupID': 'grp-001', 'studentID': 'stu-001'},
        ],
        'Users': [
          {
            '_id': 'stu-001',
            'name': 'Maria Lopez',
            'mail': 'mlopez@uninorte.edu.co',
            'role': 'STUDENT'
          },
        ],
      });

      await groupController.loadGroups('cat-001');

      expect(groupController.selectedGroups.length, 2);
      expect(groupController.selectedGroups[0].name, 'Group 1');
      expect(groupController.selectedGroups[0].members.length, 1);
      expect(groupController.selectedGroups[1].name, 'Group 2');
      expect(groupController.selectedGroups[1].members.length, 0);
      expect(groupController.isLoading.value, isFalse);

      verify(mockHttp.get(argThat(isAUri), headers: anyNamed('headers')))
          .called(4); // Groups(1) + GroupMembers(2) + Users(1, cached after first) = 4
    });
  });
}
