/// Top-level aggregate for a single assessment (activity), used on the
/// teacher analytics page.
///
/// Holds the overall activity average/std-dev, per-group averages (for the
/// bar chart), and a list of detected anomalies. Everything here is *derived*
/// from rows in Evaluations + CriteriaScores + GroupMembers — this model is
/// never persisted.
class ActivityOverview {
  ActivityOverview({
    required this.assessmentId,
    required this.assessmentTitle,
    required this.activityAverage,
    required this.stdDev,
    required this.totalEvaluations,
    required this.groupAverages,
    required this.anomalies,
  });

  final String assessmentId;
  final String assessmentTitle;

  /// Mean of every submitted evaluation's totalScore for this assessment.
  /// 0.0 when no evaluations have been submitted yet.
  final double activityAverage;

  /// Population standard deviation of evaluation totalScores.
  final double stdDev;

  /// Count of submitted evaluations across every group in the activity.
  final int totalEvaluations;

  /// One entry per group in the activity's category, ordered by group name.
  final List<GroupAverage> groupAverages;

  /// Detected outliers and uniform-score evaluators.
  final List<AnomalyEvent> anomalies;

  /// The first group flagged with an equity alert, or null when none.
  GroupAverage? get firstEquityAlert =>
      groupAverages.where((g) => g.hasEquityAlert).cast<GroupAverage?>().firstWhere(
            (_) => true,
            orElse: () => null,
          );
}

/// Average score for a single group plus the per-member breakdown that lets
/// us compute the equity alert (range of member averages).
class GroupAverage {
  GroupAverage({
    required this.groupId,
    required this.groupName,
    required this.average,
    required this.evaluationCount,
    required this.members,
  });

  final String groupId;
  final String groupName;
  final double average;
  final int evaluationCount;
  final List<MemberAverage> members;

  /// Threshold: a group is "equity alerted" when the range between its
  /// highest- and lowest-scored member is at least 1.2 points.
  static const double equityRangeThreshold = 1.2;

  /// Range = max(memberAverage) - min(memberAverage), considering only
  /// members that actually received evaluations.
  double get range {
    final scores = members
        .where((m) => m.evaluationCount > 0)
        .map((m) => m.average)
        .toList();
    if (scores.length < 2) return 0.0;
    final max = scores.reduce((a, b) => a > b ? a : b);
    final min = scores.reduce((a, b) => a < b ? a : b);
    return max - min;
  }

  bool get hasEquityAlert => range >= equityRangeThreshold;
}

/// Lightweight per-member summary used inside [GroupAverage] (just enough to
/// compute equity + render the alert card — not the full MemberResult).
class MemberAverage {
  MemberAverage({
    required this.studentId,
    required this.studentName,
    required this.average,
    required this.evaluationCount,
  });

  final String studentId;
  final String studentName;
  final double average;
  final int evaluationCount;
}

/// Kinds of anomalies we detect in peer evaluations.
///
/// * [outlierScore] — a single evaluation's totalScore is more than 2σ away
///   from the activity mean.
/// * [uniformScores] — one evaluator gave identical scores to every peer
///   across every criterion (low-effort / suspicious evaluation).
enum AnomalyKind { outlierScore, uniformScores }

/// A single anomaly detected during aggregation.
class AnomalyEvent {
  AnomalyEvent({
    required this.kind,
    required this.evaluatorId,
    required this.evaluatorName,
    required this.details,
  });

  final AnomalyKind kind;
  final String evaluatorId;
  final String evaluatorName;

  /// Human-readable one-liner for the UI card (already localized in Spanish).
  final String details;
}
