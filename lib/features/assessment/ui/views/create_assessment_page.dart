import 'package:f_clean_template/core/app_colors.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/assessment.dart';
import '../../domain/models/criteria.dart';
import '../viewmodels/assessment_controller.dart';

class CreateAssessmentPage extends StatefulWidget {
  final String courseId;

  const CreateAssessmentPage({super.key, required this.courseId});

  @override
  State<CreateAssessmentPage> createState() => _CreateAssessmentPageState();
}

class _CreateAssessmentPageState extends State<CreateAssessmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _timeController = TextEditingController();
  bool _isPublic = true;
  String? _selectedCategoryId;

  final AssessmentController controller = Get.find();
  final GroupController groupController = Get.find();

  static const _standardCriteria = [
    'Puntualidad',
    'Contribuciones',
    'Compromiso',
    'Actitud',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      groupController.loadCategories(widget.courseId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría de grupo')),
      );
      return;
    }

    final assessment = Assessment(
      categoryId: _selectedCategoryId!,
      title: _titleController.text.trim(),
      visibility: _isPublic ? 'public' : 'private',
      timeWindowMinutes: int.parse(_timeController.text.trim()),
    );

    final criteria = _standardCriteria
        .map((name) => Criteria(name: name, weight: 1.0))
        .toList();

    final success =
        await controller.createAssessment(assessment, criteria, widget.courseId);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación creada correctamente')),
      );
      Get.back();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo crear la evaluación')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Evaluación'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Nombre de la evaluación'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _titleController,
                  hint: 'Sprint 3 Evaluación',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingresa un nombre' : null,
                ),
                const SizedBox(height: 24),
                const _SectionLabel('Categoría de grupo'),
                const SizedBox(height: 8),
                _buildCategoryDropdown(),
                const SizedBox(height: 24),
                const _SectionLabel('Ventana de tiempo'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _timeController,
                  hint: '60',
                  suffix: 'minutos',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa la duración';
                    if (int.tryParse(v.trim()) == null) return 'Debe ser un número';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const _SectionLabel('Visibilidad de resultados'),
                const SizedBox(height: 12),
                _buildVisibilityCards(),
                const SizedBox(height: 24),
                const _SectionLabel('Criterios de evaluación'),
                const SizedBox(height: 12),
                _buildCriteriaChecklist(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? suffix,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      final categories = groupController.categories;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedCategoryId,
            isExpanded: true,
            hint: const Text('Seleccionar categoría',
                style: TextStyle(color: AppColors.textMuted)),
            items: categories
                .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategoryId = v),
          ),
        ),
      );
    });
  }

  Widget _buildVisibilityCards() {
    return Row(
      children: [
        Expanded(
          child: _VisibilityCard(
            icon: Icons.visibility,
            label: 'Pública',
            description: 'Estudiantes ven resultados',
            isSelected: _isPublic,
            onTap: () => setState(() => _isPublic = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _VisibilityCard(
            icon: Icons.lock,
            label: 'Privada',
            description: 'Solo profesor ve resultados',
            isSelected: !_isPublic,
            onTap: () => setState(() => _isPublic = false),
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaChecklist() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _standardCriteria.asMap().entries.map((entry) {
          final isLast = entry.key == _standardCriteria.length - 1;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const Icon(Icons.check, color: AppColors.olive, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(() => FilledButton(
            onPressed: controller.isLoading.value ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.olive,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Crear', style: TextStyle(fontSize: 16)),
          )),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _VisibilityCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.olive.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.olive : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.olive : AppColors.textMuted,
                size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.olive : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
