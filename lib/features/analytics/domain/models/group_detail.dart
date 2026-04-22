import 'member_result.dart';

/// Detailed breakdown for one group in the context of one assessment.
/// Drives the "Grupo X - Resultados" screen.
class GroupDetail {
  GroupDetail({
    required this.assessmentId,
    required this.assessmentTitle,
    required this.groupId,
    required this.groupName,
    required this.groupAverage,
    required this.members,
    required this.criteriaNames,
  });

  final String assessmentId;
  final String assessmentTitle;
  final String groupId;
  final String groupName;

  /// Mean of member averages (weighted equally, not by evaluation count).
  final double groupAverage;

  /// One entry per group member, including members who received no
  /// evaluations (average = 0, evaluationCount = 0).
  final List<MemberResult> members;

  /// Ordered list of criterion names for this assessment. The UI iterates
  /// this list to render per-criterion chips on every member card in the
  /// same order.
  final List<String> criteriaNames;

  /// Range of member averages — mirrors [GroupAverage.range] but for this
  /// single group's view.
  double get memberRange {
    final scores = members
        .where((m) => m.evaluationCount > 0)
        .map((m) => m.average)
        .toList();
    if (scores.length < 2) return 0.0;
    final max = scores.reduce((a, b) => a > b ? a : b);
    final min = scores.reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  /// Human-readable equity label derived from [memberRange]:
  /// < 0.6 → "Alta", < 1.2 → "Media", ≥ 1.2 → "Baja".
  String get equityLabel {
    final r = memberRange;
    if (r < 0.6) return 'Alta';
    if (r < 1.2) return 'Media';
    return 'Baja';
  }
}
