import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/group_detail.dart';
import '../../domain/models/member_result.dart';
import '../viewmodels/analytics_controller.dart';
import 'student_evolution_page.dart';

/// "Grupo X - Resultados" screen. Reactive on [AnalyticsController.groupDetail]
/// and [AnalyticsController.isLoadingGroup].
///
/// Reached by tapping a bar on the teacher analytics comparison chart — which
/// hands us the [assessmentId]/[groupId] pair to load, plus a [fallbackGroupName]
/// to show immediately before the detail arrives from the backend.
class GroupResultsPage extends StatefulWidget {
  const GroupResultsPage({
    super.key,
    required this.assessmentId,
    required this.groupId,
    this.fallbackGroupName = '',
  });

  final String assessmentId;
  final String groupId;
  final String fallbackGroupName;

  @override
  State<GroupResultsPage> createState() => _GroupResultsPageState();
}

class _GroupResultsPageState extends State<GroupResultsPage> {
  AnalyticsController get controller => Get.find<AnalyticsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadGroupDetail(widget.assessmentId, widget.groupId);
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
          child: RefreshIndicator(
            onRefresh: () => controller.loadGroupDetail(
                widget.assessmentId, widget.groupId),
            child: Obx(() {
              final detail = controller.groupDetail.value;
              final loading = controller.isLoadingGroup.value;

              if (loading && detail == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(detail),
                          const SizedBox(height: 16),
                          if (detail == null)
                            _emptyCard('Sin datos para este grupo')
                          else ...[
                            _buildGroupAverageCard(detail),
                            const SizedBox(height: 24),
                            _sectionTitle('MIEMBROS DEL GRUPO'),
                            const SizedBox(height: 12),
                            if (detail.members.isEmpty)
                              _emptyCard(
                                  'Este grupo aún no tiene estudiantes asignados')
                            else
                              ...detail.members.asMap().entries.map((entry) {
                                final i = entry.key;
                                final m = entry.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildMemberCard(
                                      m, detail.criteriaNames, i),
                                );
                              }),
                            const SizedBox(height: 12),
                            _sectionTitle('RETROALIMENTACIÓN AUTOMÁTICA'),
                            const SizedBox(height: 12),
                            _buildFeedbackCard(detail),
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
      ),
    );
  }

  // ─── Sub-widgets ────────────────────────────────────────────────────────

  Widget _buildHeader(GroupDetail? detail) {
    final name = detail?.groupName ??
        (widget.fallbackGroupName.isEmpty ? 'Grupo' : widget.fallbackGroupName);
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
        Expanded(
          child: Text(
            '$name - Resultados',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupAverageCard(GroupDetail detail) {
    final equity = detail.equityLabel;
    final (equityIcon, equityColor) = switch (equity) {
      'Alta' => (Icons.check_rounded, AppColors.olive),
      'Media' => (Icons.remove_rounded, AppColors.wheat),
      _ => (Icons.warning_amber_rounded, AppColors.rose),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.wheat,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Promedio del Grupo',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.groupAverage.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Equidad',
                style: TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    equity,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(equityIcon, size: 18, color: equityColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Rango: ${detail.memberRange.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
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

  Widget _buildMemberCard(
      MemberResult m, List<String> criteriaNames, int index) {
    final color = _memberColor(index);

    return GestureDetector(
      onTap: () => _openEvolution(m.studentId),
      child: Container(
        padding: const EdgeInsets.all(14),
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
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(
                    _initials(m.studentName),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.studentName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        m.hasNoResults
                            ? 'Sin evaluaciones recibidas'
                            : 'Promedio: ${m.average.toStringAsFixed(1)} · '
                                '${m.evaluationCount} evaluación(es)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  m.hasNoResults ? '—' : m.average.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: m.hasNoResults ? AppColors.textMuted : color,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
            if (!m.hasNoResults && criteriaNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: criteriaNames
                    .map((name) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3),
                            child: _criteriaChip(
                              _shortCriterion(name),
                              m.criteriaScores[name] ?? 0.0,
                              color,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _criteriaChip(String label, double score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(GroupDetail detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.olive, size: 18),
              SizedBox(width: 8),
              Text(
                'Resumen del desempeño',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _autoFeedback(detail),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
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

  // ─── Helpers ────────────────────────────────────────────────────────────

  void _openEvolution(String studentId) {
    final courseId =
        controller.courseIdByAssessment[widget.assessmentId];
    if (courseId == null) {
      Get.snackbar(
        'Sin datos',
        'No se encontró el curso asociado a esta evaluación',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.to(() => StudentEvolutionPage(
          courseId: courseId,
          studentId: studentId,
        ));
  }

  /// Generates an auto feedback paragraph based on equity + group average.
  String _autoFeedback(GroupDetail detail) {
    final avg = detail.groupAverage;
    final equity = detail.equityLabel;

    final buffer = StringBuffer();

    if (avg == 0.0) {
      buffer.write(
          'Este grupo aún no registra evaluaciones, por lo que no se puede '
          'emitir retroalimentación automática.');
      return buffer.toString();
    }

    if (avg >= 4.3) {
      buffer.write('El grupo muestra un desempeño sólido ');
    } else if (avg >= 3.5) {
      buffer.write('El grupo muestra un desempeño moderado ');
    } else {
      buffer.write('El grupo muestra un desempeño bajo ');
    }

    if (equity == 'Alta') {
      buffer.write(
          'con alta equidad entre sus miembros. Las puntuaciones recibidas '
          'son consistentes y reflejan contribución balanceada.');
    } else if (equity == 'Media') {
      buffer.write(
          'con equidad media entre sus miembros. Algunos integrantes reciben '
          'puntuaciones por debajo del resto — vale la pena revisar la '
          'distribución de tareas.');
    } else {
      buffer.write(
          'con baja equidad entre sus miembros (rango > 1.2). Se recomienda '
          'conversar con el grupo sobre la distribución de responsabilidades.');
    }

    return buffer.toString();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// Shortens long criterion names so they fit in the compact chips.
  String _shortCriterion(String name) {
    if (name.length <= 6) return name;
    return '${name.substring(0, 5)}.';
  }

  Color _memberColor(int index) {
    const palette = [
      AppColors.olive,
      AppColors.wheat,
      AppColors.salmon,
      AppColors.rose,
    ];
    return palette[index % palette.length];
  }
}
