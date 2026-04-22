import 'dart:math' as math;

import 'package:loggy/loggy.dart';

import '../../../../../core/network/roble_db_client.dart';
import '../../../../../core/services/session_service.dart';
import '../../../../assessment/domain/models/assessment.dart';
import '../../../domain/models/activity_overview.dart';
import '../../../domain/models/group_detail.dart';
import '../../../domain/models/member_result.dart';
import '../../../domain/models/student_evolution.dart';
import '../i_analytics_source.dart';

/// Roble-backed analytics source.
///
/// Every read here is *derived* — we fetch rows from the persisted tables
/// (Assessments, Evaluations, CriteriaScores, Groups, GroupMembers, Criteria,
/// GroupCategories, Users) and compute aggregates in Dart.
///
/// An in-memory user cache is held for the lifetime of the instance so we
/// don't re-download the Users table for every student-name resolution.
class RemoteAnalyticsSource with UiLoggy implements IAnalyticsSource {
  final RobleDbClient _db;
  final SessionService _session;

  RemoteAnalyticsSource(this._db, this._session);

  /// Resolves the caller-supplied student id into the canonical `Users._id`
  /// used everywhere in Roble. The auth layer and the CSV importer can
  /// assign different ids, but the email is the stable identifier — so we
  /// check whether [fallback] already matches a Users row, and if not we
  /// look up the signed-in user's email and swap in the row id we find.
  ///
  /// If nothing resolves, we hand the original id back unchanged so calling
  /// code behaves identically to before (empty results rather than a crash).
  Future<String> _resolveStudentId(String fallback) async {
    final users = await _getAllUsers();
    if (users.containsKey(fallback)) return fallback;

    final email = _session.cachedUser?.email;
    if (email == null || email.isEmpty) return fallback;

    for (final u in users.values) {
      if (u['mail']?.toString() == email) {
        final id = u['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          loggy.info(
              'RemoteAnalyticsSource: resolved auth id "$fallback" → Roble id "$id" via email');
          return id;
        }
      }
    }
    return fallback;
  }

  /// Threshold in standard deviations above which an evaluation total-score
  /// is flagged as an outlier.
  static const double _outlierSigmaThreshold = 2.0;

  /// Per-instance users cache: userId → row. Populated lazily on first use.
  Map<String, Map<String, dynamic>>? _usersCache;

  Future<Map<String, Map<String, dynamic>>> _getAllUsers() async {
    if (_usersCache != null) return _usersCache!;
    final rows = await _db.read('Users');
    _usersCache = {
      for (final u in rows)
        if (u['_id'] != null) u['_id'].toString(): u,
    };
    return _usersCache!;
  }

  String _userName(Map<String, Map<String, dynamic>> users, String id) {
    final u = users[id];
    if (u == null) return 'Estudiante $id';
    final name = u['name']?.toString().trim();
    if (name == null || name.isEmpty) return 'Estudiante $id';
    return name;
  }

  /// Sort assessments chronologically (oldest first) when createdAt is set;
  /// fall back to title comparison otherwise.
  int _byCreatedAt(Assessment a, Assessment b) {
    final ac = a.createdAt;
    final bc = b.createdAt;
    if (ac != null && bc != null) return ac.compareTo(bc);
    if (ac != null) return -1;
    if (bc != null) return 1;
    return a.title.compareTo(b.title);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher: course-level assessment list
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<Assessment>> getCourseAssessments(String courseId) async {
    loggy.info('RemoteAnalyticsSource: getCourseAssessments course=$courseId');

    final cats =
        await _db.read('GroupCategories', {'courseID': courseId});
    final catIds = cats.map((r) => r['_id'].toString()).toSet();

    final assessments = <Assessment>[];
    for (final catId in catIds) {
      final rows = await _db.read('Assessments', {'categoryID': catId});
      assessments.addAll(rows.map(Assessment.fromJson));
    }

    assessments.sort(_byCreatedAt);
    loggy.info(
        'RemoteAnalyticsSource: course=$courseId → ${assessments.length} assessments');
    return assessments;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher: activity overview (main analytics screen)
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<ActivityOverview> getActivityOverview(String assessmentId) async {
    loggy.info(
        'RemoteAnalyticsSource: getActivityOverview assessment=$assessmentId');

    // 1. Assessment row (for title + category).
    final aRows = await _db.read('Assessments', {'_id': assessmentId});
    if (aRows.isEmpty) {
      return ActivityOverview(
        assessmentId: assessmentId,
        assessmentTitle: '---',
        activityAverage: 0,
        stdDev: 0,
        totalEvaluations: 0,
        groupAverages: const [],
        anomalies: const [],
      );
    }
    final assessment = Assessment.fromJson(aRows.first);

    // 2. All evaluations + all criteria scores for this assessment.
    final evalRows =
        await _db.read('Evaluations', {'assessmentID': assessmentId});
    final evalIds = evalRows.map((e) => e['_id'].toString()).toSet();

    final allScoreRows = await _db.read('CriteriaScores');
    final scoreRows = allScoreRows
        .where((s) => evalIds.contains(s['evaluationID'].toString()))
        .toList();

    // 3. Activity mean and population std-dev.
    final totalScores = evalRows
        .map((e) => (e['totalScore'] as num?)?.toDouble() ?? 0.0)
        .toList();
    final activityAverage = _mean(totalScores);
    final stdDev = _populationStdDev(totalScores, activityAverage);

    // 4. Groups for the activity's category + per-group aggregates.
    final groupRows =
        await _db.read('Groups', {'categoryID': assessment.categoryId});
    final users = await _getAllUsers();

    final groupAverages = <GroupAverage>[];
    for (final g in groupRows) {
      final groupId = g['_id'].toString();
      final groupName = g['name']?.toString() ?? groupId;

      final memberRows =
          await _db.read('GroupMembers', {'groupID': groupId});
      final memberIds =
          memberRows.map((m) => m['studentID'].toString()).toList();

      // Member averages are computed only from evaluations pointed at them.
      final memberAverages = <MemberAverage>[];
      final groupMemberTotals = <double>[];
      for (final mid in memberIds) {
        final received = evalRows
            .where((e) => e['evaluatedID'].toString() == mid)
            .map((e) => (e['totalScore'] as num?)?.toDouble() ?? 0.0)
            .toList();
        final avg = _mean(received);
        if (received.isNotEmpty) groupMemberTotals.addAll(received);
        memberAverages.add(MemberAverage(
          studentId: mid,
          studentName: _userName(users, mid),
          average: avg,
          evaluationCount: received.length,
        ));
      }

      groupAverages.add(GroupAverage(
        groupId: groupId,
        groupName: groupName,
        average: _mean(groupMemberTotals),
        evaluationCount: groupMemberTotals.length,
        members: memberAverages,
      ));
    }

    groupAverages.sort((a, b) => a.groupName.compareTo(b.groupName));

    // 5. Anomalies.
    final anomalies = _detectAnomalies(
      evalRows: evalRows,
      scoreRows: scoreRows,
      activityAverage: activityAverage,
      stdDev: stdDev,
      users: users,
    );

    return ActivityOverview(
      assessmentId: assessmentId,
      assessmentTitle: assessment.title,
      activityAverage: activityAverage,
      stdDev: stdDev,
      totalEvaluations: evalRows.length,
      groupAverages: groupAverages,
      anomalies: anomalies,
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher: per-group drill-down
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<GroupDetail> getGroupDetail(
      String assessmentId, String groupId) async {
    loggy.info(
        'RemoteAnalyticsSource: getGroupDetail assessment=$assessmentId group=$groupId');

    final aRows = await _db.read('Assessments', {'_id': assessmentId});
    final gRows = await _db.read('Groups', {'_id': groupId});

    final assessment = aRows.isNotEmpty
        ? Assessment.fromJson(aRows.first)
        : Assessment(categoryId: '', title: '---', visibility: 'private', timeWindowMinutes: 0);
    final groupName = gRows.isNotEmpty
        ? (gRows.first['name']?.toString() ?? groupId)
        : groupId;

    // Criteria (id → name) + ordered name list for consistent UI order.
    final criteriaRows =
        await _db.read('Criteria', {'assessmentID': assessmentId});
    final criteriaIdToName = <String, String>{
      for (final c in criteriaRows)
        c['_id'].toString(): c['name']?.toString() ?? '---',
    };
    final criteriaNames = _orderedCriteriaNames(
        criteriaRows.map((c) => c['name']?.toString() ?? '---').toList());

    // Members + their received evaluations.
    final memberRows =
        await _db.read('GroupMembers', {'groupID': groupId});
    final memberIds =
        memberRows.map((m) => m['studentID'].toString()).toList();

    final evalRows =
        await _db.read('Evaluations', {'assessmentID': assessmentId});
    final allScoreRows = await _db.read('CriteriaScores');

    final users = await _getAllUsers();

    final members = <MemberResult>[];
    for (final mid in memberIds) {
      final receivedEvals = evalRows
          .where((e) => e['evaluatedID'].toString() == mid)
          .toList();

      if (receivedEvals.isEmpty) {
        members.add(MemberResult(
          studentId: mid,
          studentName: _userName(users, mid),
          average: 0.0,
          evaluationCount: 0,
        ));
        continue;
      }

      final receivedEvalIds =
          receivedEvals.map((e) => e['_id'].toString()).toSet();
      final scores = allScoreRows
          .where((s) => receivedEvalIds.contains(s['evaluationID'].toString()))
          .toList();

      // Per-criteria-name average.
      final byCriteriaName = <String, List<double>>{};
      for (final s in scores) {
        final cId = s['criteriaID'].toString();
        final cName = criteriaIdToName[cId] ?? cId;
        final val = (s['score'] as num?)?.toDouble() ?? 0.0;
        byCriteriaName.putIfAbsent(cName, () => []).add(val);
      }
      final criteriaScores = <String, double>{
        for (final e in byCriteriaName.entries) e.key: _mean(e.value),
      };

      final overall = receivedEvals
          .map((e) => (e['totalScore'] as num?)?.toDouble() ?? 0.0)
          .toList();

      members.add(MemberResult(
        studentId: mid,
        studentName: _userName(users, mid),
        average: _mean(overall),
        evaluationCount: receivedEvals.length,
        criteriaScores: criteriaScores,
      ));
    }

    members.sort((a, b) => b.average.compareTo(a.average));

    final memberAverages = members
        .where((m) => m.evaluationCount > 0)
        .map((m) => m.average)
        .toList();

    return GroupDetail(
      assessmentId: assessmentId,
      assessmentTitle: assessment.title,
      groupId: groupId,
      groupName: groupName,
      groupAverage: _mean(memberAverages),
      members: members,
      criteriaNames: criteriaNames,
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher: per-student evolution across a course's assessments
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<StudentEvolution> getStudentEvolution(
      String courseId, String studentId) async {
    loggy.info(
        'RemoteAnalyticsSource: getStudentEvolution course=$courseId student=$studentId');

    final users = await _getAllUsers();
    studentId = await _resolveStudentId(studentId);
    final studentName = _userName(users, studentId);

    final courseRows = await _db.read('Courses', {'_id': courseId});
    final courseName = courseRows.isNotEmpty
        ? (courseRows.first['name']?.toString() ?? '---')
        : '---';

    final assessments = await getCourseAssessments(courseId);

    final points = <EvolutionPoint>[];
    for (final a in assessments) {
      if (a.id == null) continue;
      final r = await getMyResultForAssessment(studentId, a.id!);
      if (r == null || r.evaluationCount == 0) continue;
      points.add(EvolutionPoint(
        assessmentId: a.id!,
        assessmentTitle: a.title,
        average: r.average,
        criteriaAverages: r.criteriaScores,
        submittedAt: a.createdAt,
      ));
    }

    // Points come out in assessment-order already (getCourseAssessments sorts
    // by createdAt) — but belt & braces in case some rows had null timestamps.
    points.sort((x, y) {
      final xd = x.submittedAt;
      final yd = y.submittedAt;
      if (xd != null && yd != null) return xd.compareTo(yd);
      return 0;
    });

    final criteriaDeltas = _criteriaDeltas(points);

    return StudentEvolution(
      studentId: studentId,
      studentName: studentName,
      courseId: courseId,
      courseName: courseName,
      points: points,
      criteriaDeltas: criteriaDeltas,
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Student: assessments that already have a result + per-assessment result
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<Assessment>> getMyAssessmentsWithResults(
      String studentId) async {
    loggy.info(
        'RemoteAnalyticsSource: getMyAssessmentsWithResults student=$studentId');

    studentId = await _resolveStudentId(studentId);

    // 1. Student's groups → their categories.
    final memberRows =
        await _db.read('GroupMembers', {'studentID': studentId});
    if (memberRows.isEmpty) return const [];

    final groupIds =
        memberRows.map((r) => r['groupID'].toString()).toSet();
    final categoryIds = <String>{};
    for (final gId in groupIds) {
      final gRows = await _db.read('Groups', {'_id': gId});
      if (gRows.isEmpty) continue;
      categoryIds.add(gRows.first['categoryID'].toString());
    }

    // 2. All assessments for those categories.
    final candidates = <Assessment>[];
    for (final cId in categoryIds) {
      final rows = await _db.read('Assessments', {'categoryID': cId});
      candidates.addAll(rows.map(Assessment.fromJson));
    }

    // 3. Keep only those where the student has received at least one eval.
    final myEvalRows =
        await _db.read('Evaluations', {'evaluatedID': studentId});
    final assessmentsWithResults = myEvalRows
        .map((e) => e['assessmentID'].toString())
        .toSet();

    final result = candidates
        .where((a) => a.id != null && assessmentsWithResults.contains(a.id))
        .toList()
      ..sort(_byCreatedAt);

    // Most recent first — dropdown should show the latest at the top.
    return result.reversed.toList();
  }

  @override
  Future<MemberResult?> getMyResultForAssessment(
      String studentId, String assessmentId) async {
    loggy.info(
        'RemoteAnalyticsSource: getMyResultForAssessment '
        'student=$studentId assessment=$assessmentId');

    final users = await _getAllUsers();
    studentId = await _resolveStudentId(studentId);
    final studentName = _userName(users, studentId);

    final evalRows = await _db.read(
        'Evaluations', {'assessmentID': assessmentId});
    final received = evalRows
        .where((e) => e['evaluatedID'].toString() == studentId)
        .toList();

    if (received.isEmpty) {
      return MemberResult(
        studentId: studentId,
        studentName: studentName,
        average: 0.0,
        evaluationCount: 0,
      );
    }

    final receivedEvalIds =
        received.map((e) => e['_id'].toString()).toSet();

    final criteriaRows =
        await _db.read('Criteria', {'assessmentID': assessmentId});
    final criteriaIdToName = <String, String>{
      for (final c in criteriaRows)
        c['_id'].toString(): c['name']?.toString() ?? '---',
    };

    final allScoreRows = await _db.read('CriteriaScores');
    final scoreRows = allScoreRows
        .where((s) => receivedEvalIds.contains(s['evaluationID'].toString()))
        .toList();

    final byCriteriaName = <String, List<double>>{};
    for (final s in scoreRows) {
      final cId = s['criteriaID'].toString();
      final cName = criteriaIdToName[cId] ?? cId;
      final val = (s['score'] as num?)?.toDouble() ?? 0.0;
      byCriteriaName.putIfAbsent(cName, () => []).add(val);
    }
    final criteriaScores = <String, double>{
      for (final e in byCriteriaName.entries) e.key: _mean(e.value),
    };

    final totals = received
        .map((e) => (e['totalScore'] as num?)?.toDouble() ?? 0.0)
        .toList();

    return MemberResult(
      studentId: studentId,
      studentName: studentName,
      average: _mean(totals),
      evaluationCount: received.length,
      criteriaScores: criteriaScores,
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────

  double _mean(List<double> xs) {
    if (xs.isEmpty) return 0.0;
    final sum = xs.fold<double>(0, (a, b) => a + b);
    return sum / xs.length;
  }

  double _populationStdDev(List<double> xs, double mean) {
    if (xs.length < 2) return 0.0;
    final sumSq =
        xs.fold<double>(0, (a, x) => a + (x - mean) * (x - mean));
    return math.sqrt(sumSq / xs.length);
  }

  /// Sort criterion names by the canonical rubric order
  /// (Puntualidad → Contribuciones → Compromiso → Actitud), with any unknown
  /// criteria appended alphabetically afterwards.
  List<String> _orderedCriteriaNames(List<String> names) {
    const canonical = [
      'Puntualidad',
      'Contribuciones',
      'Compromiso',
      'Actitud',
    ];
    final unique = names.toSet().toList();
    final ordered = <String>[];
    for (final c in canonical) {
      final match = unique.firstWhere(
        (n) => n.toLowerCase() == c.toLowerCase(),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        ordered.add(match);
        unique.remove(match);
      }
    }
    unique.sort();
    ordered.addAll(unique);
    return ordered;
  }

  /// For each criterion seen across [points], compute (first, last) averages
  /// and the delta. Sorted by delta descending.
  List<CriterionDelta> _criteriaDeltas(List<EvolutionPoint> points) {
    if (points.length < 2) return const [];

    final allCriteria = <String>{};
    for (final p in points) {
      allCriteria.addAll(p.criteriaAverages.keys);
    }

    final deltas = <CriterionDelta>[];
    for (final name in allCriteria) {
      double? first;
      double? last;
      for (final p in points) {
        final v = p.criteriaAverages[name];
        if (v == null) continue;
        first ??= v;
        last = v;
      }
      if (first != null && last != null) {
        deltas.add(CriterionDelta(
            name: name, current: last, previous: first));
      }
    }

    deltas.sort((a, b) => b.delta.compareTo(a.delta));
    return deltas;
  }

  /// Detects outlier evaluations (>[_outlierSigmaThreshold]σ from mean) and
  /// "uniform score" evaluators (≥2 evaluations, identical total score and
  /// identical criterion scores across every peer).
  List<AnomalyEvent> _detectAnomalies({
    required List<Map<String, dynamic>> evalRows,
    required List<Map<String, dynamic>> scoreRows,
    required double activityAverage,
    required double stdDev,
    required Map<String, Map<String, dynamic>> users,
  }) {
    final anomalies = <AnomalyEvent>[];

    // Outlier scores.
    if (stdDev > 0) {
      for (final e in evalRows) {
        final total = (e['totalScore'] as num?)?.toDouble() ?? 0.0;
        final diff = (total - activityAverage).abs();
        if (diff / stdDev >= _outlierSigmaThreshold) {
          final evaluatorId = e['evaluatorID'].toString();
          anomalies.add(AnomalyEvent(
            kind: AnomalyKind.outlierScore,
            evaluatorId: evaluatorId,
            evaluatorName: _userName(users, evaluatorId),
            details:
                'Evaluación desviada en ${(diff / stdDev).toStringAsFixed(1)}σ '
                '(puntuó ${total.toStringAsFixed(1)})',
          ));
        }
      }
    }

    // Uniform-score evaluators.
    final byEvaluator = <String, List<Map<String, dynamic>>>{};
    for (final e in evalRows) {
      byEvaluator
          .putIfAbsent(e['evaluatorID'].toString(), () => [])
          .add(e);
    }

    for (final entry in byEvaluator.entries) {
      final evaluatorId = entry.key;
      final evals = entry.value;
      if (evals.length < 2) continue;

      final totals = evals
          .map((e) => (e['totalScore'] as num?)?.toDouble() ?? 0.0)
          .toSet();
      if (totals.length != 1) continue;

      // Also require identical criterion scores across all evaluations.
      final evalIdToScores = <String, Map<String, double>>{};
      for (final e in evals) {
        final eid = e['_id'].toString();
        final scores = scoreRows
            .where((s) => s['evaluationID'].toString() == eid)
            .toList();
        final map = <String, double>{};
        for (final s in scores) {
          map[s['criteriaID'].toString()] =
              (s['score'] as num?)?.toDouble() ?? 0.0;
        }
        evalIdToScores[eid] = map;
      }
      final distinctScoreMaps =
          evalIdToScores.values.map((m) => m.toString()).toSet();
      if (distinctScoreMaps.length != 1) continue;

      anomalies.add(AnomalyEvent(
        kind: AnomalyKind.uniformScores,
        evaluatorId: evaluatorId,
        evaluatorName: _userName(users, evaluatorId),
        details:
            'Puntuó ${totals.first.toStringAsFixed(1)} a todos los compañeros con criterios idénticos',
      ));
    }

    return anomalies;
  }
}
