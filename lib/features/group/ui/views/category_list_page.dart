import 'package:f_clean_template/core/app_colors.dart';
import 'package:f_clean_template/core/models/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/ui/viewmodels/auth_controller.dart';
import '../../domain/models/group_category.dart';
import '../viewmodels/group_controller.dart';
import 'group_list_page.dart';
import 'import_csv_page.dart';

class CategoryListPage extends StatefulWidget {
  final String courseId;

  const CategoryListPage({super.key, required this.courseId});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<GroupController>().loadCategories(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GroupController>();
    final isTeacher =
        Get.find<AuthController>().currentRole == UserRole.teacher;

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.categories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category_outlined,
                  size: 64,
                  color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'No hay categorías aún',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Text(
                isTeacher
                    ? 'Importa un archivo CSV para crear categorías'
                    : 'El profesor aún no ha creado categorías',
                style:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              if (isTeacher) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Get.to(
                        () => ImportCsvPage(courseId: widget.courseId));
                    if (result == true) {
                      controller.loadCategories(widget.courseId);
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importar CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.olive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      return Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: controller.categories.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCategoryCard(controller.categories[index]),
              );
            },
          ),
          if (isTeacher)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                heroTag: 'category_import_fab',
                onPressed: () async {
                  final result = await Get.to(
                      () => ImportCsvPage(courseId: widget.courseId));
                  if (result == true) {
                    controller.loadCategories(widget.courseId);
                  }
                },
                backgroundColor: AppColors.olive,
                icon: const Icon(Icons.upload_file, color: Colors.white),
                label: const Text('Importar CSV',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildCategoryCard(GroupCategory category) {
    return GestureDetector(
      onTap: () => Get.to(() => GroupListPage(category: category)),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.salmon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.category_rounded,
                  color: AppColors.salmon, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.groupCount} grupos | ${category.memberCount} miembros',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
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
