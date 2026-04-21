import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupResultsPage extends StatelessWidget {
  final String groupName;
  final double groupAverage;

  const GroupResultsPage({
    super.key,
    this.groupName = 'Grupo 3',
    this.groupAverage = 4.2,
  });

  @override
  Widget build(BuildContext context) {
    final members = const [
      _Member('MG', 'María García', 4.5, AppColors.olive, {
        'Punt.': 4.5,
        'Contr.': 4.7,
        'Comp.': 4.3,
        'Actit.': 4.5,
      }),
      _Member('JP', 'Juan Pérez', 4.3, AppColors.wheat, {
        'Punt.': 4.0,
        'Contr.': 4.5,
        'Comp.': 4.5,
        'Actit.': 4.2,
      }),
      _Member('LS', 'Laura Sánchez', 3.8, AppColors.salmon, {
        'Punt.': 3.5,
        'Contr.': 4.0,
        'Comp.': 3.7,
        'Actit.': 4.0,
      }),
    ];

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
                      _buildGroupAverageCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('MIEMBROS DEL GRUPO'),
                      const SizedBox(height: 12),
                      ...members.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMemberCard(m),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionTitle('RETROALIMENTACIÓN AUTOMÁTICA'),
                      const SizedBox(height: 12),
                      _buildFeedbackCard(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Get.back(),
          child: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$groupName - Resultados',
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

  Widget _buildGroupAverageCard() {
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
                  groupAverage.toStringAsFixed(1),
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
            children: const [
              Text(
                'Equidad',
                style: TextStyle(fontSize: 12, color: AppColors.textDark),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Alta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.check_rounded,
                      size: 18, color: AppColors.textDark),
                ],
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

  Widget _buildMemberCard(_Member m) {
    return Container(
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
                backgroundColor: m.color.withValues(alpha: 0.2),
                child: Text(
                  m.initials,
                  style: TextStyle(
                    color: m.color,
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
                      m.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Promedio: ${m.average.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                m.average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: m.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: m.criteria.entries
                .map((e) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _criteriaChip(e.key, e.value, m.color),
                      ),
                    ))
                .toList(),
          ),
        ],
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

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
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
          SizedBox(height: 10),
          Text(
            'El grupo muestra un desempeño sólido con alta equidad entre sus miembros. Se destaca la contribución constante y el compromiso colectivo. Se recomienda reforzar la puntualidad en entregas parciales.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Member {
  final String initials;
  final String name;
  final double average;
  final Color color;
  final Map<String, double> criteria;

  const _Member(
      this.initials, this.name, this.average, this.color, this.criteria);
}
