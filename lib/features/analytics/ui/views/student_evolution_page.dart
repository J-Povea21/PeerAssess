import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentEvolutionPage extends StatefulWidget {
  const StudentEvolutionPage({super.key});

  @override
  State<StudentEvolutionPage> createState() => _StudentEvolutionPageState();
}

class _StudentEvolutionPageState extends State<StudentEvolutionPage> {
  final String _selectedStudent = 'María García';
  final String _selectedCourse = 'Desarrollo Móvil';

  final List<_EvalPoint> _points = const [
    _EvalPoint('Sprint 1', 3.2),
    _EvalPoint('Sprint 2', 3.8),
    _EvalPoint('Sprint 3', 4.1),
    _EvalPoint('Taller 1', 4.3),
    _EvalPoint('Taller 2', 4.6),
  ];

  final List<_CriterionTrend> _criteria = const [
    _CriterionTrend('Puntualidad', 4.8, _Trend.up),
    _CriterionTrend('Contribuciones', 4.5, _Trend.up),
    _CriterionTrend('Compromiso', 4.0, _Trend.flat),
    _CriterionTrend('Actitud', 4.7, _Trend.up),
  ];

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
                      _buildStudentSelector(),
                      const SizedBox(height: 20),
                      _buildPerformanceCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('CRITERIOS - ÚLTIMA EVALUACIÓN'),
                      const SizedBox(height: 12),
                      _buildCriteriaCard(),
                      const SizedBox(height: 24),
                      _sectionTitle('RANKING DE MEJORA'),
                      const SizedBox(height: 12),
                      _buildRankingCard(),
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

  Widget _buildStudentSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textMuted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.olive,
            child: Text(
              _initialsFrom(_selectedStudent),
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
                  _selectedStudent,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  _selectedCourse,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
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
          const Text(
            'Desempeño por Evaluación',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: _LineChartPainter(points: _points),
              child: Container(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _points
                .map((p) => Text(
                      p.label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted),
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

  Widget _buildCriteriaCard() {
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
        children: _criteria.map(_buildCriterionRow).toList(),
      ),
    );
  }

  Widget _buildCriterionRow(_CriterionTrend c) {
    final trendIcon = switch (c.trend) {
      _Trend.up => const Icon(Icons.arrow_upward_rounded,
          color: AppColors.olive, size: 14),
      _Trend.down => const Icon(Icons.arrow_downward_rounded,
          color: AppColors.rose, size: 14),
      _Trend.flat => const Icon(Icons.remove_rounded,
          color: AppColors.textMuted, size: 14),
    };

    final trendColor = switch (c.trend) {
      _Trend.up => AppColors.olive,
      _Trend.down => AppColors.rose,
      _Trend.flat => AppColors.textMuted,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.name,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark),
                ),
              ),
              Text(
                c.score.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 4),
              trendIcon,
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: c.score / 5.0,
              minHeight: 6,
              backgroundColor: AppColors.beige,
              valueColor: AlwaysStoppedAnimation<Color>(trendColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard() {
    final items = const [
      ('+1.4', 'Puntualidad', AppColors.olive),
      ('+0.9', 'Actitud', AppColors.wheat),
      ('+0.3', 'Contribuciones', AppColors.salmon),
      ('0.0', 'Compromiso', AppColors.textMuted),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.olive.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: items
            .map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: it.$3.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          it.$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: it.$3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        it.$2,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  String _initialsFrom(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}

class _EvalPoint {
  final String label;
  final double value;
  const _EvalPoint(this.label, this.value);
}

class _CriterionTrend {
  final String name;
  final double score;
  final _Trend trend;
  const _CriterionTrend(this.name, this.score, this.trend);
}

enum _Trend { up, down, flat }

class _LineChartPainter extends CustomPainter {
  final List<_EvalPoint> points;
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

    final labelStyle = const TextStyle(
      fontSize: 10,
      color: AppColors.textMuted,
    );

    // Y-axis grid + labels
    const leftPadding = 28.0;
    final chartWidth = size.width - leftPadding;
    for (double v = minY; v <= maxY; v += yStep) {
      final y = size.height -
          ((v - minY) / (maxY - minY)) * size.height;
      canvas.drawLine(
          Offset(leftPadding, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: v.toStringAsFixed(1), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Line
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
          ((points[i].value - minY) / (maxY - minY)).clamp(0.0, 1.0);
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
