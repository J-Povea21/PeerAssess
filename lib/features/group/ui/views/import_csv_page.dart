import 'dart:convert';

import 'package:f_clean_template/core/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../viewmodels/group_controller.dart';

class ImportCsvPage extends StatefulWidget {
  final String courseId;

  const ImportCsvPage({super.key, required this.courseId});

  @override
  State<ImportCsvPage> createState() => _ImportCsvPageState();
}

class _ImportCsvPageState extends State<ImportCsvPage> {
  String? _fileName;
  String? _csvContent;
  List<_PreviewRow> _previewRows = [];
  String? _categoryName;
  int _totalGroups = 0;
  int _totalMembers = 0;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes);
      _parseCsvPreview(content);

      setState(() {
        _fileName = file.name;
        _csvContent = content;
      });
    }
  }

  void _parseCsvPreview(String content) {
    final lines = content
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) return;

    final dataLines = lines.sublist(1);
    final Map<String, List<String>> groups = {};

    for (final line in dataLines) {
      final cols = line.split(',').map((s) => s.trim()).toList();
      if (cols.length < 8) continue;

      _categoryName ??= cols[0];
      final groupName = cols[1];
      final firstName = cols[5];
      final lastName = cols[6];

      groups.putIfAbsent(groupName, () => []);
      groups[groupName]!.add('$firstName $lastName');
    }

    _totalGroups = groups.length;
    _totalMembers = groups.values.fold<int>(0, (s, l) => s + l.length);
    _previewRows = groups.entries
        .map((e) => _PreviewRow(groupName: e.key, members: e.value))
        .toList();
  }

  Future<void> _import() async {
    if (_csvContent == null) return;

    final controller = Get.find<GroupController>();
    final category =
        await controller.importCsv(widget.courseId, _csvContent!);

    if (category != null && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar CSV'),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFileSelector(),
                    if (_csvContent != null) ...[
                      const SizedBox(height: 20),
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                      _buildPreview(),
                    ],
                  ],
                ),
              ),
            ),
            if (_csvContent != null) _buildImportButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.olive.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _fileName != null ? Icons.check_circle : Icons.upload_file,
              size: 48,
              color:
                  _fileName != null ? AppColors.olive : AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              _fileName ?? 'Seleccionar archivo CSV',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _fileName != null
                    ? AppColors.textDark
                    : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Formato: Brightspace Group Export (.csv)',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.olive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryStat(
              _categoryName ?? '-',
              'Categoría',
              Icons.category_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.olive.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildSummaryStat(
              _totalGroups.toString(),
              'Grupos',
              Icons.group_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.olive.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _buildSummaryStat(
              _totalMembers.toString(),
              'Miembros',
              Icons.people_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.olive),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VISTA PREVIA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        ..._previewRows.map((row) => _buildPreviewGroupCard(row)),
      ],
    );
  }

  Widget _buildPreviewGroupCard(_PreviewRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_rounded,
                  size: 18, color: AppColors.olive),
              const SizedBox(width: 8),
              Text(
                row.groupName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${row.members.length} miembros',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: row.members
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.beige.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(m,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textDark)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return Obx(() {
      final controller = Get.find<GroupController>();
      return Container(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: controller.isImporting.value ? null : _import,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.olive,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.olive.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: controller.isImporting.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Importar categoría',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      );
    });
  }
}

class _PreviewRow {
  final String groupName;
  final List<String> members;

  _PreviewRow({required this.groupName, required this.members});
}
