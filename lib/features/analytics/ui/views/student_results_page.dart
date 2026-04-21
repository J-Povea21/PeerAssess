import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';

class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  final TextEditingController _learnedCtrl = TextEditingController();
  final TextEditingController _improveCtrl = TextEditingController();

  final double _score = 4.3;
  final String _sprintLabel = 'Tu Resultado - Sprint 2';

  @override
  void dispose() {
    _learnedCtrl.dispose();
    _improveCtrl.dispose();
    super.dispose();
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    Center(child: _buildScoreBadge()),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _sprintLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Tus compañeros te evaluaron',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAutoFeedbackCard(),
                    const SizedBox(height: 24),
                    _sectionTitle('TU AUTO-REFLEXIÓN (VOLUNTARIA)'),
                    const SizedBox(height: 14),
                    _buildReflectionField(
                      label: '¿Qué aprendiste de esta evaluación?',
                      hint: 'Escribe tu reflexión aquí...',
                      controller: _learnedCtrl,
                    ),
                    const SizedBox(height: 14),
                    _buildReflectionField(
                      label: '¿Qué mejorarás para la próxima evaluación?',
                      hint: 'Escribe tu reflexión aquí...',
                      controller: _improveCtrl,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReflection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.olive,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Guardar reflexión',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
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
          'Reflexión Post-Evaluación',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.wheat.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.olive, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        _score.toStringAsFixed(1),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildAutoFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wheat.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.wheat),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'RETROALIMENTACIÓN AUTOMÁTICA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.olive,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
              children: [
                TextSpan(text: 'Demuestras un '),
                TextSpan(
                  text: 'alto compromiso',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' y tus '),
                TextSpan(
                  text: 'contribuciones enriquecen',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                    text:
                        ' el trabajo del equipo. Se recomienda mejorar la '),
                TextSpan(
                  text: 'puntualidad',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: ' para maximizar la colaboración.'),
              ],
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

  Widget _buildReflectionField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.olive, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _submitReflection() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reflexión guardada'),
      ),
    );
    _learnedCtrl.clear();
    _improveCtrl.clear();
  }
}
