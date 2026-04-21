import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'group_results_page.dart';
import 'student_evolution_page.dart';

class TeacherAnalyticsPage extends StatefulWidget {
  const TeacherAnalyticsPage({super.key});

  @override
  State<TeacherAnalyticsPage> createState() => _TeacherAnalyticsPageState();
}

class _TeacherAnalyticsPageState extends State<TeacherAnalyticsPage> {
  final String _selectedActivity = 'Desarrollo Móvil - Sprint 2';

  final List<_GroupComparison> _groups = const [
    _GroupComparison('G1', 4.3, AppColors.salmon),
    _GroupComparison('G2', 3.9, AppColors.wheat),
    _GroupComparison('G3', 4.5, AppColors.olive),
    _GroupComparison('G4', 3.3, AppColors.rose),
    _GroupComparison('G5', 4.1, AppColors.wheat),
    _GroupComparison('G6', 3.6, AppColors.salmon),
    _GroupComparison('G7', 4.4, AppColors.olive),
  ];

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
        child: CustomScrollView(
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
                    _buildStatsRow(),
                    const SizedBox(height: 24),
                    _sectionTitle('COMPARACIÓN POR GRUPO'),
                    const SizedBox(height: 12),
                    _buildGroupComparisonCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('ÍNDICE DE EQUIDAD'),
                    const SizedBox(height: 12),
                    _buildEquityAlertCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('DETECCIÓN DE ANOMALÍAS'),
                    const SizedBox(height: 12),
                    _buildAnomaliesCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('EVOLUCIÓN POR ESTUDIANTE'),
                    const SizedBox(height: 12),
                    _buildEvolutionLink(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: const [
        Icon(Icons.arrow_back_rounded, color: AppColors.textDark),
        SizedBox(width: 12),
        Text(
          'Analíticas',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _selectedActivity,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile('4.1', 'Promedio\nActividad', AppColors.olive),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile('0.32', 'Desv.\nEstándar', AppColors.salmon),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile('1', 'Anomalías', AppColors.rose),
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
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.2,
            ),
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

  Widget _buildGroupComparisonCard() {
    final maxScore = 5.0;
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
        height: 160,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _groups.map((g) {
            final heightFactor = (g.score / maxScore).clamp(0.0, 1.0);
            return Expanded(
              child: GestureDetector(
                onTap: () => Get.to(() => GroupResultsPage(
                      groupName: g.label,
                      groupAverage: g.score,
                    )),
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
                              color: g.color,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        g.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        g.score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEquityAlertCard() {
    return Container(
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Grupo 4 - Alerta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.rose,
                      ),
                    ),
                    Text(
                      'Alta desviación: 1.4 entre miembros',
                      style: TextStyle(
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
          Row(
            children: [
              Expanded(child: _memberScore('Ana M.', 4.8, AppColors.olive)),
              const SizedBox(width: 8),
              Expanded(child: _memberScore('Luis N.', 4.2, AppColors.wheat)),
              const SizedBox(width: 8),
              Expanded(child: _memberScore('Carlos P.', 2.3, AppColors.rose)),
              const SizedBox(width: 8),
              Expanded(child: _memberScore('Sofía L.', 3.7, AppColors.salmon)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _memberScore(String name, double score, Color color) {
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
            name,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnomaliesCard() {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluación inconsistente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Un evaluador dio 1.0 a toda la actividad',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionLink() {
    return GestureDetector(
      onTap: () => Get.to(() => const StudentEvolutionPage()),
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
}

class _GroupComparison {
  final String label;
  final double score;
  final Color color;
  const _GroupComparison(this.label, this.score, this.color);
}
