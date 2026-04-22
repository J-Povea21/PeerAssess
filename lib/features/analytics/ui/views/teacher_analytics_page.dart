import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/ui/viewmodels/auth_controller.dart';
import '../../../reflection/ui/views/reflections_review_page.dart';
import '../../domain/models/activity_overview.dart';
import '../viewmodels/analytics_controller.dart';
import 'group_results_page.dart';
import 'student_evolution_page.dart';

/// Main teacher analytics screen. Shows one selected activity's overview:
/// headline stats, per-group comparison, equity alerts and anomaly alerts.
class TeacherAnalyticsPage extends StatefulWidget {
  const TeacherAnalyticsPage({super.key});

  @override
  State<TeacherAnalyticsPage> createState() => _TeacherAnalyticsPageState();
}

class _TeacherAnalyticsPageState extends State<TeacherAnalyticsPage> {
  AnalyticsController get controller => Get.find<AnalyticsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teacherId = Get.find<AuthController>().currentUser?.id;
      if (teacherId != null && controller.teacherAssessments.isEmpty) {
        controller.loadTeacherAssessments(teacherId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: RefreshIndicator(
          onRefresh: () async {
            final teacherId = Get.find<AuthController>().currentUser?.id;
            if (teacherId != null) {
              await controller.loadTeacherAssessments(teacherId);
            }
          },
          child: Obx(() {
            if (controller.isLoadingAssessments.value &&
                controller.teacherAssessments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.teacherAssessments.isEmpty) {
              return _buildEmpty();
            }

            final overview = controller.activityOverview.value;

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
                        _buildActivityDropdown(),
                        const SizedBox(height: 16),
                        if (controller.isLoadingOverview.value)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                                child: CircularProgressIndicator()),
                          )
                        else if (overview == null)
                          const SizedBox.shrink()
                        else ...[
                          _buildStatsRow(overview),
                          const SizedBox(height: 24),
                          _sectionTitle('COMPARACIÓN POR GRUPO'),
                          const SizedBox(height: 12),
                          _buildGroupComparisonCard(overview),
                          if (overview.firstEquityAlert != null) ...[
                            const SizedBox(height: 24),
                            _sectionTitle('ÍNDICE DE EQUIDAD'),
                            const SizedBox(height: 12),
                            _buildEquityAlertCard(
                                overview.firstEquityAlert!),
                          ],
                          if (overview.anomalies.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _sectionTitle('DETECCIÓN DE ANOMALÍAS'),
                            const SizedBox(height: 12),
                            ...overview.anomalies.map((a) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _buildAnomalyCard(a),
                                )),
                          ],
                          const SizedBox(height: 24),
                          _sectionTitle('EVOLUCIÓN POR ESTUDIANTE'),
                          const SizedBox(height: 12),
                          _buildEvolutionLink(overview),
                          const SizedBox(height: 12),
                          _buildReflectionsLink(),
                          const SizedBox(height: 28),
                        ],
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

  // ─── Sub-widgets ──────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.analytics_outlined,
            size: 64, color: AppColors.textMuted),
        const SizedBox(height: 16),
        const Center(
          child: Text('Analíticas',
              style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Aún no hay evaluaciones creadas en tus cursos',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Analíticas',
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildActivityDropdown() {
    return GestureDetector(
      onTap: _showActivityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedLabel(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  String _selectedLabel() {
    final id = controller.selectedAssessmentId.value;
    if (id == null) return 'Selecciona una evaluación';
    final a = controller.teacherAssessments
        .firstWhereOrNull((x) => x.id == id);
    if (a == null) return 'Selecciona una evaluación';
    final courseName = controller.courseNameByAssessment[id] ?? '';
    return courseName.isEmpty ? a.title : '$courseName - ${a.title}';
  }

  void _showActivityPicker() {
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
                  'Selecciona una evaluación',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ...controller.teacherAssessments.map((a) {
                final courseName =
                    controller.courseNameByAssessment[a.id] ?? '';
                final label =
                    courseName.isEmpty ? a.title : '$courseName - ${a.title}';
                return ListTile(
                  title: Text(label),
                  trailing: controller.selectedAssessmentId.value == a.id
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.olive)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (a.id != null) controller.selectAssessment(a.id!);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(ActivityOverview o) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
              o.activityAverage.toStringAsFixed(1),
              'Promedio\nActividad',
              AppColors.olive),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
              o.stdDev.toStringAsFixed(2),
              'Desv.\nEstándar',
              AppColors.salmon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
              o.anomalies.length.toString(), 'Anomalías', AppColors.rose),
        ),
      ],
    );
  }

  Widget _buildStatTile(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.2)),
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

  Widget _buildGroupComparisonCard(ActivityOverview o) {
    if (o.groupAverages.isEmpty) {
      return _emptyCard('Aún no hay grupos para esta evaluación');
    }

    final palette = [
      AppColors.salmon,
      AppColors.wheat,
      AppColors.olive,
      AppColors.rose,
    ];
    const maxScore = 5.0;

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
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < o.groupAverages.length; i++)
              Expanded(
                child: _buildGroupBar(
                  o.groupAverages[i],
                  palette[i % palette.length],
                  maxScore,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupBar(GroupAverage g, Color color, double maxScore) {
    final heightFactor =
        g.evaluationCount == 0 ? 0.0 : (g.average / maxScore).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () {
        final assessmentId = controller.selectedAssessmentId.value;
        if (assessmentId == null) return;
        Get.to(() => GroupResultsPage(
              assessmentId: assessmentId,
              groupId: g.groupId,
              fallbackGroupName: g.groupName,
            ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              g.groupName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              g.evaluationCount == 0
                  ? '—'
                  : g.average.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquityAlertCard(GroupAverage g) {
    final membersWithScores =
        g.members.where((m) => m.evaluationCount > 0).toList()
          ..sort((a, b) => b.average.compareTo(a.average));

    return GestureDetector(
      onTap: () {
        final assessmentId = controller.selectedAssessmentId.value;
        if (assessmentId == null) return;
        Get.to(() => GroupResultsPage(
              assessmentId: assessmentId,
              groupId: g.groupId,
              fallbackGroupName: g.groupName,
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.rose.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.rose.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.rose.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.rose,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${g.groupName} - Alerta',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.rose,
                        ),
                      ),
                      Text(
                        'Alta desviación: ${g.range.toStringAsFixed(1)} entre miembros',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (membersWithScores.isNotEmpty)
              Row(
                children: [
                  for (int i = 0;
                      i < membersWithScores.length.clamp(0, 4);
                      i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _memberBadge(
                        membersWithScores[i].studentName,
                        membersWithScores[i].average,
                        _memberColor(i),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _memberColor(int index) {
    const palette = [
      AppColors.olive,
      AppColors.wheat,
      AppColors.rose,
      AppColors.salmon,
    ];
    return palette[index % palette.length];
  }

  Widget _memberBadge(String name, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _shortName(name),
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  String _shortName(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length <= 1) return fullName;
    return '${parts.first} ${parts.last[0]}.';
  }

  Widget _buildAnomalyCard(AnomalyEvent a) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.salmon.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.salmon.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.error_outline_rounded,
                color: AppColors.salmon, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.kind == AnomalyKind.outlierScore
                      ? 'Puntuación atípica'
                      : 'Evaluación uniforme',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${a.evaluatorName}: ${a.details}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionLink(ActivityOverview o) {
    final assessmentId = controller.selectedAssessmentId.value;
    final courseId = assessmentId == null
        ? null
        : controller.courseIdByAssessment[assessmentId];

    return GestureDetector(
      onTap: () {
        if (courseId == null) {
          Get.snackbar('Sin datos',
              'Selecciona una evaluación primero',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        Get.to(() => StudentEvolutionPage(
              courseId: courseId,
              assessmentId: assessmentId,
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.olive.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: AppColors.olive),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ver evolución del semestre',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionsLink() {
    return GestureDetector(
      onTap: () {
        final assessmentId = controller.selectedAssessmentId.value;
        if (assessmentId == null) {
          Get.snackbar('Sin datos',
              'Selecciona una evaluación primero',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        final title = _selectedLabel();
        Get.to(() => ReflectionsReviewPage(
              assessmentId: assessmentId,
              title: 'Reflexiones · $title',
            ));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.salmon.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.forum_rounded, color: AppColors.salmon),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ver reflexiones de estudiantes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted),
          ],
        ),
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
        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      ),
    );
  }
}

