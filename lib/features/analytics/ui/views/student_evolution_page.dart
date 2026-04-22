import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/student_evolution.dart';
import '../viewmodels/analytics_controller.dart';

/// "Evolución del semestre" screen. Plots the student's average across every
/// assessment in a course and ranks per-criterion improvement.
///
/// Two entry points:
///
/// * From the group results screen: [studentId] is provided → we load
///   that student's evolution immediately.
/// * From the teacher analytics overview: [studentId] is null → we show a
///   picker listing every evaluated student in the current activity so the
///   teacher can drill in without going through a specific group first.
class StudentEvolutionPage extends StatefulWidget {
  const StudentEvolutionPage({
    super.key,
    required this.courseId,
    this.studentId,
    this.assessmentId,
  });

  final String courseId;

  /// When null, the page opens with an empty state and a "Seleccionar
  /// estudiante" prompt. When non-null, the evolution is loaded in initState.
  final String? studentId;

  /// Optional context so the student picker can show candidates from the
  /// activity the teacher was looking at before navigating here.
  final String? assessmentId;

  @override
  State<StudentEvolutionPage> createState() => _StudentEvolutionPageState();
}

class _StudentEvolutionPageState extends State<StudentEvolutionPage> {
  AnalyticsController get controller => Get.find<AnalyticsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sid = widget.studentId;
      if (sid != null) {
        controller.loadStudentEvolution(widget.courseId, sid);
      } else {
        // No student pre-selected — clear any stale evolution so the page
        // shows the picker prompt instead of a previous student's data.
        controller.studentEvolution.value = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.beige,
              Colors.white,
              AppColors.rose.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            final evolution = controller.studentEvolution.value;
            final loading = controller.isLoadingEvolution.value;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildStudentSelector(evolution),
                        const SizedBox(height: 20),
                        if (loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child:
                                Center(child: CircularProgressIndicator()),
                          )
                        else if (evolution == null)
                          _emptyCard(
                              'Selecciona un estudiante para ver su evolución')
                        else if (evolution.points.isEmpty)
                          _emptyCard(
                              'Este estudiante aún no tiene evaluaciones '
                              'registradas en el curso')
                        else ...[
                          _buildPerformanceCard(evolution),
                          const SizedBox(height: 24),
                          _sectionTitle('CRITERIOS - ÚLTIMA EVALUACIÓN'),
                          const SizedBox(height: 12),
                          _buildCriteriaCard(evolution),
                          const SizedBox(height: 24),
                          _sectionTitle('RANKING DE MEJORA'),
                          const SizedBox(height: 12),
                          _buildRankingCard(evolution),
                        ],
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── Sub-widgets ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textDark),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: 'Volver',
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Evolución del Semestre',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSelector(StudentEvolution? evolution) {
    final name = evolution?.studentName ?? 'Seleccionar estudiante';
    final courseName = evolution?.courseName ?? '—';

    return GestureDetector(
      onTap: _showStudentPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.olive,
              child: Text(
                _initialsFrom(evolution?.studentName),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    courseName,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(StudentEvolution evolution) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Desempeño por Evaluación',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                'Último: ${evolution.latestAverage.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _LineChartPainter(points: evolution.points),
              child: Container(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: evolution.points
                .map((p) => Expanded(
                      child: Text(
                        _shortenTitle(p.assessmentTitle),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCriteriaCard(StudentEvolution evolution) {
    final lastPoint = evolution.points.last;
    final criteriaAverages = lastPoint.criteriaAverages;

    if (criteriaAverages.isEmpty) {
      return _emptyCard('No hay criterios disponibles');
    }

    // Use the deltas list for order (so criteria appear consistently with the
    // ranking card below). Fallback to whatever order the map exposes.
    final order = evolution.criteriaDeltas.isNotEmpty
        ? evolution.criteriaDeltas.map((d) => d.name).toList()
        : criteriaAverages.keys.toList();

    // Look up delta direction per name for the trend icon.
    final deltaByName = {
      for (final d in evolution.criteriaDeltas) d.name: d.delta,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: order
            .where(criteriaAverages.containsKey)
            .map((name) => _buildCriterionRow(
                  name,
                  criteriaAverages[name]!,
                  deltaByName[name] ?? 0.0,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCriterionRow(String name, double score, double delta) {
    final IconData icon;
    final Color color;
    if (delta > 0.05) {
      icon = Icons.arrow_upward_rounded;
      color = AppColors.olive;
    } else if (delta < -0.05) {
      icon = Icons.arrow_downward_rounded;
      color = AppColors.rose;
    } else {
      icon = Icons.remove_rounded;
      color = AppColors.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark),
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 5.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.beige,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(StudentEvolution evolution) {
    if (evolution.criteriaDeltas.isEmpty) {
      return _emptyCard(
          'Aún no hay suficientes evaluaciones para calcular la mejora');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.olive.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: evolution.criteriaDeltas.map((d) {
          final Color color;
          final String label;
          if (d.delta > 0.05) {
            color = AppColors.olive;
            label = '+${d.delta.toStringAsFixed(1)}';
          } else if (d.delta < -0.05) {
            color = AppColors.rose;
            label = d.delta.toStringAsFixed(1);
          } else {
            color = AppColors.textMuted;
            label = '0.0';
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }

  // ─── Student picker ────────────────────────────────────────────────────

  void _showStudentPicker() {
    // Build the candidate list from the controller's currently loaded
    // activity overview. If the overview is for the same assessment the
    // teacher came from, we get every evaluated student; otherwise we fall
    // back to just whichever student is currently showing (or nothing).
    final overview = controller.activityOverview.value;
    final candidates = <_Candidate>[];

    if (overview != null) {
      final seen = <String>{};
      for (final g in overview.groupAverages) {
        for (final m in g.members) {
          if (m.evaluationCount > 0 && seen.add(m.studentId)) {
            candidates.add(_Candidate(
              studentId: m.studentId,
              studentName: m.studentName,
              groupName: g.groupName,
              average: m.average,
            ));
          }
        }
      }
      candidates.sort((a, b) => a.studentName.compareTo(b.studentName));
    }

    if (candidates.isEmpty) {
      Get.snackbar(
        'Sin estudiantes',
        'No hay evaluaciones recibidas todavía para poder listar estudiantes',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Selecciona un estudiante',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ...candidates.map((c) {
                final currentId =
                    controller.studentEvolution.value?.studentId;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        AppColors.olive.withValues(alpha: 0.2),
                    child: Text(
                      _initialsFrom(c.studentName),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.olive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(c.studentName),
                  subtitle: Text(
                    '${c.groupName} · ${c.average.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  trailing: currentId == c.studentId
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.olive)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.loadStudentEvolution(
                        widget.courseId, c.studentId);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _initialsFrom(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }

  String _shortenTitle(String title) {
    if (title.length <= 10) return title;
    return '${title.substring(0, 9)}…';
  }
}

/// Internal record for the student picker.
class _Candidate {
  _Candidate({
    required this.studentId,
    required this.studentName,
    required this.groupName,
    required this.average,
  });

  final String studentId;
  final String studentName;
  final String groupName;
  final double average;
}

/// Draws a simple line chart of [EvolutionPoint.average] values in [2.0, 5.0]
/// (PeerAssess rubric scale). Positions are spaced evenly by index — we ignore
/// submittedAt gaps since the visual emphasis is on ordering, not timing.
class _LineChartPainter extends CustomPainter {
  final List<EvolutionPoint> points;
  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const minY = 2.0;
    const maxY = 5.0;
    const yStep = 1.0;

    final gridPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const labelStyle = TextStyle(
      fontSize: 10,
      color: AppColors.textMuted,
    );

    const leftPadding = 28.0;
    final chartWidth = size.width - leftPadding;

    // Y-axis grid + labels.
    for (double v = minY; v <= maxY; v += yStep) {
      final y =
          size.height - ((v - minY) / (maxY - minY)) * size.height;
      canvas.drawLine(
          Offset(leftPadding, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: v.toStringAsFixed(1), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Line + dots.
    final linePaint = Paint()
      ..color = AppColors.olive
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = AppColors.olive;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = leftPadding +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final normalized =
          ((points[i].average - minY) / (maxY - minY)).clamp(0.0, 1.0);
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
