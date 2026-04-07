import 'package:loggy/loggy.dart';

import '../../../../../core/models/user.dart';
import '../../../../../core/network/roble_db_client.dart';
import '../../../../../core/services/session_service.dart';
import '../../../domain/models/assessment.dart';
import '../../../domain/models/criteria_score.dart';
import '../../../domain/models/evaluation.dart';
import '../../../domain/models/student_result.dart';
import '../i_evaluation_source.dart';

class RemoteEvaluationSource with UiLoggy implements IEvaluationSource {
  final RobleDbClient _robleDb;
  final SessionService _session;

  RemoteEvaluationSource(this._robleDb, this._session);

  @override
  Future<List<Assessment>> getPendingAssessments(String studentId) async {
    final serverTime = await _robleDb.getServerTime();

    // 1. Find student's groups via GroupMembers
    final memberRows =
        await _robleDb.read('GroupMembers', {'studentID': studentId});
    if (memberRows.isEmpty) return [];

    // 2. For each group, resolve its category and peer list
    final Map<String, String> groupToCategory = {};
    final Map<String, List<String>> groupPeers = {};

    for (final row in memberRows) {
      final groupId = row['groupID'].toString();

      final groupRows = await _robleDb.read('Groups', {'_id': groupId});
      if (groupRows.isNotEmpty) {
        groupToCategory[groupId] =
            groupRows.first['categoryID'].toString();
      }

      final allMembers =
          await _robleDb.read('GroupMembers', {'groupID': groupId});
      groupPeers[groupId] = allMembers
          .map((m) => m['studentID'].toString())
          .where((id) => id != studentId)
          .toList();
    }

    // 3. Invert to category → groupId for lookup
    final Map<String, String> categoryToGroup = {};
    groupToCategory.forEach((gId, cId) => categoryToGroup[cId] = gId);

    // 4. Fetch assessments for enrolled categories, keep active + not expired
    final categoryIds = groupToCategory.values.toSet();
    final List<Assessment> active = [];
    for (final catId in categoryIds) {
      final rows =
          await _robleDb.read('Assessments', {'categoryID': catId});
      for (final row in rows) {
        final a = Assessment.fromJson(row);
        if (a.status == 'active' &&
            a.deadline != null &&
            a.deadline!.isAfter(serverTime)) {
          active.add(a);
        }
      }
    }

    if (active.isEmpty) return [];

    // 5. Fetch student's existing evaluations
    final evalRows =
        await _robleDb.read('Evaluations', {'evaluatorID': studentId});

    // 6. Keep only assessments where at least one peer is still unevaluated
    final List<Assessment> pending = [];
    for (final assessment in active) {
      final groupId = categoryToGroup[assessment.categoryId];
      if (groupId == null) continue;

      final peers = groupPeers[groupId] ?? [];
      final evaluatedPeers = evalRows
          .where((e) => e['assessmentID'] == assessment.id)
          .map((e) => e['evaluatedID'].toString())
          .toSet();

      if (!peers.every((p) => evaluatedPeers.contains(p))) {
        pending.add(assessment);
      }
    }

    loggy.info(
        'RemoteEvaluationSource: ${pending.length} pending for $studentId');
    return pending;
  }

  @override
  Future<bool> submitEvaluation(
      Evaluation evaluation, List<CriteriaScore> scores) async {
    if (evaluation.evaluatorId == evaluation.evaluatedId) return false;

    final user = _session.cachedUser;
    if (user == null || user.role != UserRole.student) return false;

    if (scores.any((s) => !s.isValidScore)) return false;

    // ── Server time + assessment lookup ──
    final serverTime = await _robleDb.getServerTime();

    final assessmentRows = await _robleDb
        .read('Assessments', {'_id': evaluation.assessmentId});
    if (assessmentRows.isEmpty) return false;
    final assessment = Assessment.fromJson(assessmentRows.first);

    // ── Deadline ──
    if (assessment.deadline == null ||
        !assessment.deadline!.isAfter(serverTime)) {
      return false;
    }

    // ── Duplicate check ──
    final existingEvals = await _robleDb.read('Evaluations', {
      'assessmentID': evaluation.assessmentId,
      'evaluatorID': evaluation.evaluatorId,
      'evaluatedID': evaluation.evaluatedId,
    });
    if (existingEvals.isNotEmpty) return false;

    // ── Group membership check ──
    final evaluatorGroups = await _robleDb
        .read('GroupMembers', {'studentID': evaluation.evaluatorId});

    String? sharedGroupId;
    for (final row in evaluatorGroups) {
      final gId = row['groupID'].toString();
      final groupRows = await _robleDb.read('Groups', {'_id': gId});
      if (groupRows.isNotEmpty &&
          groupRows.first['categoryID'].toString() == assessment.categoryId) {
        sharedGroupId = gId;
        break;
      }
    }
    if (sharedGroupId == null) return false;

    final groupMemberRows =
        await _robleDb.read('GroupMembers', {'groupID': sharedGroupId});
    final memberIds =
        groupMemberRows.map((r) => r['studentID'].toString()).toSet();
    if (!memberIds.contains(evaluation.evaluatedId)) return false;

    // ── Criteria completeness check ──
    final criteriaRows = await _robleDb
        .read('Criteria', {'assessmentID': evaluation.assessmentId});
    if (scores.length != criteriaRows.length) return false;

    // ── Compute total score and timestamp ──
    final totalScore =
        scores.fold<double>(0, (sum, s) => sum + s.score) / scores.length;
    evaluation.totalScore = totalScore;
    evaluation.submittedAt = serverTime;

    loggy.info(
        'RemoteEvaluationSource: submitting eval '
        '${evaluation.evaluatorId} → ${evaluation.evaluatedId}');

    // ── POST evaluation ──
    await _robleDb.insert('Evaluations', [evaluation.toJsonNoId()]);

    // ── POST criteria scores ──
    await _robleDb.insert(
        'CriteriaScores', scores.map((s) => s.toJsonNoId()).toList());

    return true;
  }
  
  @override
  Future<List<StudentResult>> getGroupResults(
      String assessmentId, String groupId) async {
    loggy.info(
        'RemoteEvaluationSource: getGroupResults '
        'assessment=$assessmentId group=$groupId');

    // 1. Group members
    final memberRows =
        await _robleDb.read('GroupMembers', {'groupID': groupId});
    final memberIds =
        memberRows.map((r) => r['studentID'].toString()).toList();

    // 2. Evaluations for this assessment
    final evalRows =
        await _robleDb.read('Evaluations', {'assessmentID': assessmentId});

    // 3. Criteria scores for those evaluations
    final evalIds = evalRows.map((r) => r['_id'].toString()).toSet();
    final allScoreRows = await _robleDb.read('CriteriaScores');
    final scoreRows = allScoreRows
        .where((r) => evalIds.contains(r['evaluationID'].toString()))
        .toList();

    // 4. Compute per-student results
    final List<StudentResult> results = [];
    for (final memberId in memberIds) {
      final memberEvals = evalRows
          .where((e) => e['evaluatedID'].toString() == memberId)
          .toList();

      if (memberEvals.isEmpty) {
        results.add(StudentResult(
          evaluatedId: memberId,
          averageScore: 0.0,
          evaluationCount: 0,
        ));
        continue;
      }

      // Per-criteria averages across all evaluations received
      final memberEvalIds =
          memberEvals.map((e) => e['_id'].toString()).toSet();
      final memberScores = scoreRows
          .where((s) => memberEvalIds.contains(s['evaluationID'].toString()))
          .toList();

      final Map<String, List<double>> byCriteria = {};
      for (final s in memberScores) {
        final cId = s['criteriaID'].toString();
        final val = (s['score'] as num).toDouble();
        byCriteria.putIfAbsent(cId, () => []).add(val);
      }

      final Map<String, double> criteriaAverages = {};
      byCriteria.forEach((cId, vals) {
        criteriaAverages[cId] =
            vals.reduce((a, b) => a + b) / vals.length;
      });

      // Overall average = mean of evaluation total_scores
      final totalSum = memberEvals.fold<double>(
          0, (sum, e) => sum + (e['totalScore'] as num).toDouble());

      results.add(StudentResult(
        evaluatedId: memberId,
        averageScore: totalSum / memberEvals.length,
        evaluationCount: memberEvals.length,
        criteriaAverages: criteriaAverages,
      ));
    }

    return results;
  }
}
