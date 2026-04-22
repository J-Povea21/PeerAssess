import 'dart:convert';
import 'dart:io';

import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/core/network/roble_db_client.dart';
import 'package:f_clean_template/core/services/session_service.dart';
import 'package:f_clean_template/features/assessment/data/datasources/remote/remote_evaluation_source.dart';
import 'package:f_clean_template/features/assessment/data/repositories/evaluation_repository.dart';
import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria_score.dart';
import 'package:f_clean_template/features/assessment/domain/models/evaluation.dart';
// hide Evaluation to avoid name collision with flutter_test/accessibility.dart
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockHttpClient mockHttp;
  late RobleDbClient robleDb;
  late SessionService session;
  late RemoteEvaluationSource source;
  late EvaluationRepository repository;

  /// Fixed server time — assessment deadline is relative to this.
  final serverTime = DateTime.utc(2026, 4, 7, 12, 0, 0);

  /// A deadline 2 hours in the future (still open).
  final futureDeadline =
      serverTime.add(const Duration(hours: 2)).toIso8601String();

  /// A deadline 1 hour in the past (expired).
  final pastDeadline =
      serverTime.subtract(const Duration(hours: 1)).toIso8601String();

  setUp(() {
    mockHttp = MockHttpClient();
    robleDb = RobleDbClient(mockHttp);
    session = SessionService();
    source = RemoteEvaluationSource(robleDb, session);
    repository = EvaluationRepository(source);
  });

  // ═════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════════════

  /// Inject a user into SessionService for the test.
  void setCurrentUser(User user) {
    session.setTestUser(user);
  }

  /// Stubs HEAD → server Date header.
  void stubServerTime([DateTime? time]) {
    when(mockHttp.head(argThat(isAUri), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 200, headers: {
              'date': HttpDate.format(time ?? serverTime),
            }));
  }

  /// Stubs all POST (insert) calls → 201 with a generated _id so callers
  /// that need the server-assigned id (e.g. submitEvaluation) can proceed.
  void stubInserts() {
    when(mockHttp.post(argThat(isAUri),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding')))
        .thenAnswer((_) async => http.Response(
            jsonEncode({'inserted': [{'_id': 'generated-001'}], 'skipped': []}), 201));
  }

  /// Stubs GET (read) calls dispatching by `tableName` query-param.
  void stubReads(Map<String, List<Map<String, dynamic>>> data) {
    when(mockHttp.get(argThat(isAUri), headers: anyNamed('headers')))
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

  // ── Reusable test data ───────────────────────────────────────────

  final studentUser = User(
    id: 'student-001',
    name: 'María López',
    email: 'mlopez@uninorte.edu.co',
    role: UserRole.student,
  );

  final teacherUser = User(
    id: 'teacher-001',
    name: 'Prof. García',
    email: 'garcia@uninorte.edu.co',
    role: UserRole.teacher,
  );

  final activeAssessment = {
    '_id': 'assess-001',
    'categoryID': 'cat-001',
    'title': 'Sprint 1 Review',
    'visibility': 'public',
    'timeWindow': 120,
    'status': 'active',
    'deadline': futureDeadline,
    'createdAt': serverTime.toIso8601String(),
  };

  final expiredAssessment = {
    '_id': 'assess-expired',
    'categoryID': 'cat-001',
    'title': 'Expired Review',
    'visibility': 'public',
    'timeWindow': 60,
    'status': 'active',
    'deadline': pastDeadline,
    'createdAt':
        serverTime.subtract(const Duration(hours: 2)).toIso8601String(),
  };

  final cancelledAssessment = {
    '_id': 'assess-cancelled',
    'categoryID': 'cat-001',
    'title': 'Cancelled Review',
    'visibility': 'public',
    'timeWindow': 120,
    'status': 'cancelled',
    'deadline': futureDeadline,
    'createdAt': serverTime.toIso8601String(),
  };

  /// DB rows for a scenario where student-001 is in group grp-001.
  Map<String, List<Map<String, dynamic>>> standardDbState({
    List<Map<String, dynamic>>? evaluations,
  }) =>
      {
        'user_groups': [
          {'_id': 'ug-001', 'user_id': 'student-001', 'group_id': 'grp-001'},
        ],
        'Groups': [
          {'_id': 'grp-001', 'categoryID': 'cat-001', 'name': 'Group 1'},
        ],
        'GroupMembers': [
          {'_id': 'gm-001', 'groupID': 'grp-001', 'studentID': 'student-001'},
          {'_id': 'gm-002', 'groupID': 'grp-001', 'studentID': 'student-002'},
          {'_id': 'gm-003', 'groupID': 'grp-001', 'studentID': 'student-003'},
        ],
        'Assessments': [activeAssessment],
        'Evaluations': evaluations ?? [],
        'Criteria': [
          {
            '_id': 'crit-001',
            'assessmentID': 'assess-001',
            'name': 'Puntualidad',
            'weight': 1.0,
          },
          {
            '_id': 'crit-002',
            'assessmentID': 'assess-001',
            'name': 'Contribuciones',
            'weight': 1.0,
          },
        ],
      };

  // ═════════════════════════════════════════════════════════════════
  //  GET PENDING ASSESSMENTS
  // ═════════════════════════════════════════════════════════════════

  group('getPendingAssessments', () {
    test('returns active, non-expired, not-yet-submitted assessments',
        () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState());

      final pending = await repository.getPendingAssessments('student-001');

      expect(pending.length, 1);
      expect(pending.first.id, 'assess-001');
    });

    test('excludes expired assessments', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads({
        ...standardDbState(),
        'Assessments': [expiredAssessment],
      });

      final pending = await repository.getPendingAssessments('student-001');
      expect(pending, isEmpty);
    });

    test('excludes cancelled assessments', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads({
        ...standardDbState(),
        'Assessments': [cancelledAssessment],
      });

      final pending = await repository.getPendingAssessments('student-001');
      expect(pending, isEmpty);
    });

    test('excludes assessments already submitted by this student', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState(evaluations: [
        {
          '_id': 'eval-001',
          'assessmentID': 'assess-001',
          'evaluatorID': 'student-001',
          'evaluatedID': 'student-002',
          'totalScore': 4.0,
          'submittedAt': serverTime.toIso8601String(),
        },
        {
          '_id': 'eval-002',
          'assessmentID': 'assess-001',
          'evaluatorID': 'student-001',
          'evaluatedID': 'student-003',
          'totalScore': 3.5,
          'submittedAt': serverTime.toIso8601String(),
        },
      ]));

      // Student already submitted for all peers in the group → nothing pending
      final pending = await repository.getPendingAssessments('student-001');
      expect(pending, isEmpty);
    });

    test('only returns assessments from courses student is enrolled in',
        () async {
      setCurrentUser(studentUser);
      stubServerTime();

      final otherCourseAssessment = {
        '_id': 'assess-other',
        'categoryID': 'cat-999', // different category, different course
        'title': 'Other Course Review',
        'visibility': 'public',
        'timeWindow': 120,
        'status': 'active',
        'deadline': futureDeadline,
        'createdAt': serverTime.toIso8601String(),
      };

      stubReads({
        ...standardDbState(),
        'Assessments': [activeAssessment, otherCourseAssessment],
      });

      final pending = await repository.getPendingAssessments('student-001');

      // Only the assessment from the student's enrolled category
      expect(pending.length, 1);
      expect(pending.first.id, 'assess-001');
    });
  });

  // ═════════════════════════════════════════════════════════════════
  //  SUBMIT EVALUATION
  // ═════════════════════════════════════════════════════════════════

  group('submitEvaluation', () {
    test('happy path — 2 POSTs, submittedAt from server UTC', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubInserts();
      stubReads(standardDbState());

      final evaluation = Evaluation(
        assessmentId: 'assess-001',
        evaluatorId: 'student-001',
        evaluatedId: 'student-002',
      );
      final scores = [
        CriteriaScore(criteriaId: 'crit-001', score: 5.0),
        CriteriaScore(criteriaId: 'crit-002', score: 4.0),
      ];

      final result = await repository.submitEvaluation(evaluation, scores);
      expect(result, isTrue);

      final bodies = verify(mockHttp.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
        encoding: anyNamed('encoding'),
      )).captured;

      expect(bodies.length, 2);

      // ── First POST → evaluations table ──
      final eBody = jsonDecode(bodies[0] as String);
      expect(eBody['tableName'], 'Evaluations');
      final eRec = eBody['records'][0] as Map<String, dynamic>;
      expect(eRec['assessmentID'], 'assess-001');
      expect(eRec['evaluatorID'], 'student-001');
      expect(eRec['evaluatedID'], 'student-002');
      final submittedAt = DateTime.parse(eRec['submittedAt'] as String);
      expect(submittedAt.isUtc, isTrue);

      // ── Second POST → criteria_scores table ──
      final sBody = jsonDecode(bodies[1] as String);
      expect(sBody['tableName'], 'CriteriaScores');
      final sRecs = sBody['records'] as List;
      expect(sRecs.length, 2);
      expect(sRecs[0]['score'], 5.0);
      expect(sRecs[1]['score'], 4.0);
    });

    test('rejects submission after deadline', () async {
      setCurrentUser(studentUser);
      stubServerTime(); // server time is 12:00
      stubReads({
        ...standardDbState(),
        'Assessments': [expiredAssessment], // deadline already passed
      });

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-expired',
          evaluatorId: 'student-001',
          evaluatedId: 'student-002',
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 4.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects duplicate evaluation for same peer', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState(evaluations: [
        {
          '_id': 'eval-existing',
          'assessmentID': 'assess-001',
          'evaluatorID': 'student-001',
          'evaluatedID': 'student-002',
          'totalScore': 4.0,
          'submittedAt': serverTime.toIso8601String(),
        },
      ]));

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-002', // same peer, already evaluated
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 4.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects self-evaluation', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState());

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-001', // self!
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 4.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects evaluation from a teacher', () async {
      setCurrentUser(teacherUser); // teacher role!
      stubServerTime();
      stubReads(standardDbState());

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'teacher-001',
          evaluatedId: 'student-002',
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 4.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects evaluation of peer not in same group', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState());

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-999', // not in grp-001!
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 4.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects negative score', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState());

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-002',
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: -1.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects score above 5.0', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState());

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-002',
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 6.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects score outside valid set (e.g. 3.5)', () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubReads(standardDbState());

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-002',
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 3.5)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects when missing scores for criteria in the assessment',
        () async {
      setCurrentUser(studentUser);
      stubServerTime();
      stubInserts();
      stubReads(standardDbState()); // assessment has 2 criteria

      final result = await repository.submitEvaluation(
        Evaluation(
          assessmentId: 'assess-001',
          evaluatorId: 'student-001',
          evaluatedId: 'student-002',
        ),
        [CriteriaScore(criteriaId: 'crit-001', score: 4.0)], // only 1 of 2!
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });
  });

  // ═════════════════════════════════════════════════════════════════
  //  GET GROUP RESULTS
  // ═════════════════════════════════════════════════════════════════

  group('getGroupResults', () {
    test('computes averages using actual evaluation count as denominator',
        () async {
      setCurrentUser(studentUser);
      stubReads({
        'GroupMembers': [
          {'_id': 'gm-001', 'groupID': 'grp-001', 'studentID': 'student-001'},
          {'_id': 'gm-002', 'groupID': 'grp-001', 'studentID': 'student-002'},
          {'_id': 'gm-003', 'groupID': 'grp-001', 'studentID': 'student-003'},
        ],
        'Evaluations': [
          // student-002 evaluated student-001
          {
            '_id': 'eval-001',
            'assessmentID': 'assess-001',
            'evaluatorID': 'student-002',
            'evaluatedID': 'student-001',
            'totalScore': 4.0,
            'submittedAt': serverTime.toIso8601String(),
          },
          // student-003 did NOT submit (missed deadline) → denominator = 1 for student-001
        ],
        'CriteriaScores': [
          {
            '_id': 'cs-001',
            'evaluationID': 'eval-001',
            'criteriaID': 'crit-001',
            'score': 5.0,
          },
          {
            '_id': 'cs-002',
            'evaluationID': 'eval-001',
            'criteriaID': 'crit-002',
            'score': 3.0,
          },
        ],
      });

      final results = await repository.getGroupResults(
        'assess-001',
        'grp-001',
      );

      // student-001 received 1 evaluation: total avg = (5.0 + 3.0) / 2 = 4.0
      final student001 = results.firstWhere(
        (r) => r.evaluatedId == 'student-001',
      );
      expect(student001.averageScore, 4.0);
      expect(student001.evaluationCount, 1);
    });
  });
}
