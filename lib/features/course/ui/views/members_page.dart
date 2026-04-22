import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../group/domain/models/group_member.dart';
import '../../../group/ui/viewmodels/group_controller.dart';

class MembersPage extends StatefulWidget {
  final String courseId;

  const MembersPage({super.key, required this.courseId});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<GroupController>().loadCategories(widget.courseId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupController = Get.find<GroupController>();

    return Obx(() {
      if (groupController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 🔥 FIX: evitar duplicados
      final Map<String, GroupMember> uniqueMembers = {};

      for (final category in groupController.categories) {
        for (final group in category.groups) {
          for (final member in group.members) {
            if (member.email.isEmpty) continue;

            final email = member.email.trim().toLowerCase();
            uniqueMembers[email] = member;
          }
        }
      }

      final allMembers = uniqueMembers.values.toList();

      if (allMembers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline,
                  size: 64,
                  color: AppColors.textMuted.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'No hay miembros aún',
                style: TextStyle(fontSize: 16, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              const Text(
                'Los miembros aparecerán al importar un CSV',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_rounded,
                    size: 18, color: AppColors.olive),
                const SizedBox(width: 8),
                Text(
                  '${allMembers.length} miembros en total',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.olive,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: allMembers.length,
              itemBuilder: (context, index) {
                final member = allMembers[index];
                return _buildMemberTile(member, index);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMemberTile(GroupMember member, int index) {
    final colors = [
      AppColors.olive,
      AppColors.salmon,
      AppColors.rose,
      AppColors.wheat,
    ];
    final avatarColor = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColor,
            child: Text(
              member.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  member.email,
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
}