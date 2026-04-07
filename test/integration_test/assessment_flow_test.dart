import 'dart:convert';
import 'dart:io';

import 'package:f_clean_template/core/network/roble_db_client.dart';
import 'package:f_clean_template/features/assessment/data/datasources/remote/remote_assessment_source.dart';
import 'package:f_clean_template/features/assessment/data/repositories/assessment_repository.dart';
import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

import '../helpers/test_helpers.dart';

void main() {
  late MockHttpClient mockHttp;
  late RobleDbClient robleDb;
  late RemoteAssessmentSource source;
  late AssessmentRepository repository;

  /// Fixed server time — all deadline math is relative to this.
  final serverTime = DateTime.utc(2026, 4, 7, 12, 0, 0);

  setUp(() {
    mockHttp = MockHttpClient();
    robleDb = RobleDbClient(mockHttp);
    source = RemoteAssessmentSource(robleDb);
    repository = AssessmentRepository(source);
  });

  // ═════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════════════

  /// Stubs HEAD → server Date header.
  void stubServerTime([DateTime? time]) {
    when(mockHttp.head(argThat(isAUri), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 200, headers: {
              'date': HttpDate.format(time ?? serverTime),
            }));
  }

  /// Stubs all POST (insert) calls → 201 success.
  void stubInserts() {
    when(mockHttp.post(argThat(isAUri),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding')))
        .thenAnswer((_) async => http.Response(
            jsonEncode({'inserted': [], 'skipped': []}), 201));
  }

  /// Stubs GET (read) calls dispatching by `tableName` query-param.
  /// Applies remaining query-params as row filters (simulates Roble).
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

  /// Stubs PUT (update) calls → 200 success.
  void stubUpdates() {
    when(mockHttp.put(argThat(isAUri),
            headers: anyNamed('headers'),
            body: anyNamed('body'),
            encoding: anyNamed('encoding')))
        .thenAnswer((_) async =>
            http.Response(jsonEncode({'updated': true}), 200));
  }

  // ── Reusable test data ───────────────────────────────────────────

  final activeAssessmentRow = {
    '_id': 'assess-001',
    'categoryID': 'cat-001',
    'title': 'Sprint 1 Review',
    'visibility': 'public',
    'timeWindow': 120,
    'status': 'active',
    'deadline':
        serverTime.add(const Duration(minutes: 120)).toIso8601String(),
    'createdAt': serverTime.toIso8601String(),
  };

  final cancelledAssessmentRow = {
    '_id': 'assess-002',
    'categoryID': 'cat-001',
    'title': 'Cancelled One',
    'visibility': 'private',
    'timeWindow': 60,
    'status': 'cancelled',
    'deadline':
        serverTime.add(const Duration(minutes: 60)).toIso8601String(),
    'createdAt': serverTime.toIso8601String(),
  };

  // ═════════════════════════════════════════════════════════════════
  //  CREATE ASSESSMENT
  // ═════════════════════════════════════════════════════════════════

  group('createAssessment', () {
    test('happy path — 2 POSTs, status=active, deadline from server UTC',
        () async {
      stubServerTime();
      stubInserts();

      final assessment = Assessment(
        categoryId: 'cat-001',
        title: 'Sprint 1 Review',
        visibility: 'public',
        timeWindowMinutes: 120,
      );
      final criteria = [
        Criteria(name: 'Puntualidad', weight: 1.0),
        Criteria(name: 'Contribuciones', weight: 1.0),
      ];

      final result = await repository.createAssessment(assessment, criteria);
      expect(result, isTrue);

      // Capture POST bodies
      final bodies = verify(mockHttp.post(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
        encoding: anyNamed('encoding'),
      )).captured;

      expect(bodies.length, 2);

      // ── First POST → assessments table ──
      final aBody = jsonDecode(bodies[0] as String);
      expect(aBody['tableName'], 'Assessments');
      final rec = aBody['records'][0] as Map<String, dynamic>;
      expect(rec['status'], 'active');
      expect(rec['categoryID'], 'cat-001');
      expect(rec['title'], 'Sprint 1 Review');
      expect(rec['visibility'], 'public');
      expect(rec['timeWindow'], 120);

      // Deadline = server time + 120 min, stored as UTC ISO-8601
      final deadline = DateTime.parse(rec['deadline'] as String);
      expect(deadline.isUtc, isTrue);
      expect(deadline, serverTime.add(const Duration(minutes: 120)));

      // ── Second POST → criteria table ──
      final cBody = jsonDecode(bodies[1] as String);
      expect(cBody['tableName'], 'Criteria');
      final cRecs = cBody['records'] as List;
      expect(cRecs.length, 2);
      expect(cRecs[0]['name'], 'Puntualidad');
      expect(cRecs[1]['name'], 'Contribuciones');
    });

    test('rejects duplicate criteria names — no HTTP calls', () async {
      stubServerTime();

      final result = await repository.createAssessment(
        Assessment(
          categoryId: 'cat-001',
          title: 'Sprint 1 Review',
          visibility: 'public',
          timeWindowMinutes: 120,
        ),
        [
          Criteria(name: 'Puntualidad', weight: 1.0),
          Criteria(name: 'Puntualidad', weight: 1.0),
        ],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects empty criteria list — no HTTP calls', () async {
      stubServerTime();

      final result = await repository.createAssessment(
        Assessment(
          categoryId: 'cat-001',
          title: 'Sprint 1 Review',
          visibility: 'public',
          timeWindowMinutes: 120,
        ),
        [],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects empty title — no HTTP calls', () async {
      stubServerTime();

      final result = await repository.createAssessment(
        Assessment(
          categoryId: 'cat-001',
          title: '',
          visibility: 'public',
          timeWindowMinutes: 120,
        ),
        [Criteria(name: 'Puntualidad', weight: 1.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });

    test('rejects non-positive time window — no HTTP calls', () async {
      stubServerTime();

      final result = await repository.createAssessment(
        Assessment(
          categoryId: 'cat-001',
          title: 'Sprint 1 Review',
          visibility: 'public',
          timeWindowMinutes: 0,
        ),
        [Criteria(name: 'Puntualidad', weight: 1.0)],
      );

      expect(result, isFalse);
      verifyNever(mockHttp.post(any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding')));
    });
  });

  // ═════════════════════════════════════════════════════════════════
  //  GET ASSESSMENTS BY COURSE
  // ═════════════════════════════════════════════════════════════════

  group('getAssessmentsByCourse', () {
    test('returns only active assessments for the course', () async {
      stubReads({
        'GroupCategories': [
          {'_id': 'cat-001', 'courseID': 'course-001', 'name': 'Sprint 1'},
        ],
        'Assessments': [activeAssessmentRow, cancelledAssessmentRow],
      });

      final list = await repository.getAssessmentsByCourse('course-001');

      expect(list.length, 1);
      expect(list.first.id, 'assess-001');
      expect(list.first.title, 'Sprint 1 Review');
      expect(list.first.status, 'active');
    });

    test('excludes cancelled assessments', () async {
      stubReads({
        'GroupCategories': [
          {'_id': 'cat-001', 'courseID': 'course-001', 'name': 'Sprint 1'},
        ],
        'Assessments': [cancelledAssessmentRow],
      });

      final list = await repository.getAssessmentsByCourse('course-001');
      expect(list, isEmpty);
    });
  });

  // ═════════════════════════════════════════════════════════════════
  //  CANCEL ASSESSMENT
  // ═════════════════════════════════════════════════════════════════

  group('cancelAssessment', () {
    test('sends UPDATE setting status to cancelled', () async {
      stubUpdates();

      final result = await repository.cancelAssessment('assess-001');
      expect(result, isTrue);

      final body = jsonDecode(verify(mockHttp.put(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: captureAnyNamed('body'),
        encoding: anyNamed('encoding'),
      )).captured.first as String);

      expect(body['tableName'], 'Assessments');
      expect(body['idColumn'], '_id');
      expect(body['idValue'], 'assess-001');
      expect(body['updates']['status'], 'cancelled');
    });

    test('idempotent — fires UPDATE regardless, no error', () async {
      stubUpdates();

      final r1 = await repository.cancelAssessment('assess-001');
      final r2 = await repository.cancelAssessment('assess-001');

      expect(r1, isTrue);
      expect(r2, isTrue);

      verify(mockHttp.put(
        argThat(isAUri),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
        encoding: anyNamed('encoding'),
      )).called(2);
    });
  });
}
