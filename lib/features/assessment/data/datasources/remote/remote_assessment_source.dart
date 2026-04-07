import 'package:loggy/loggy.dart';

import '../../../../../core/network/roble_db_client.dart';
import '../../../domain/models/assessment.dart';
import '../../../domain/models/criteria.dart';
import '../i_assessment_source.dart';

class RemoteAssessmentSource with UiLoggy implements IAssessmentSource {
  final RobleDbClient _robleDb;

  RemoteAssessmentSource(this._robleDb);

  @override
  Future<bool> createAssessment(
      Assessment assessment, List<Criteria> criteria) async {
    if (assessment.title.trim().isEmpty) return false;
    if (assessment.timeWindowMinutes <= 0) return false;
    if (criteria.isEmpty) return false;

    final names = criteria.map((c) => c.name).toSet();
    if (names.length != criteria.length) return false; // duplicates

    // ── Server time → deadline ──
    final serverTime = await _robleDb.getServerTime();
    assessment.status = 'active';
    assessment.deadline =
        serverTime.add(Duration(minutes: assessment.timeWindowMinutes));
    assessment.createdAt = serverTime;

    loggy.info('RemoteAssessmentSource: creating "${assessment.title}"');

    await _robleDb.insert('Assessments', [assessment.toJsonNoId()]);

    await _robleDb
        .insert('Criteria', criteria.map((c) => c.toJsonNoId()).toList());

    return true;
  }

  @override
  Future<List<Assessment>> getAssessmentsByCourse(String courseId) async {
    loggy.info(
        'RemoteAssessmentSource: getAssessmentsByCourse courseId=$courseId');

    // 1. Get categories (activities) for this course
    final catRows =
        await _robleDb.read('GroupCategories', {'courseID': courseId});
    final catIds = catRows.map((r) => r['_id'].toString()).toSet();

    // 2. For each category, fetch assessments and keep only active ones
    final List<Assessment> result = [];
    for (final catId in catIds) {
      final rows = await _robleDb.read('Assessments', {'categoryID': catId});
      for (final row in rows) {
        final assessment = Assessment.fromJson(row);
        if (assessment.status == 'active') {
          result.add(assessment);
        }
      }
    }

    loggy.info(
        'RemoteAssessmentSource: found ${result.length} active assessments');
    return result;
  }

  @override
  Future<bool> cancelAssessment(String assessmentId) async {
    loggy.info('RemoteAssessmentSource: cancelAssessment id=$assessmentId');

    await _robleDb
        .update('Assessments', '_id', assessmentId, {'status': 'cancelled'});
    return true;
  }
}
