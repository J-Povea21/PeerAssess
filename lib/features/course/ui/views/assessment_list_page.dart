import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'edit_assessment_page.dart';

class AssessmentListPage extends StatelessWidget {
  final String courseId;

  const AssessmentListPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    
    final List<Map<String, dynamic>> assessments = [
      {'name': 'Evaluación 1'},
      {'name': 'Evaluación 2'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: assessments.length,
      itemBuilder: (context, index) {
        final assessment = assessments[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              assessment['name'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

      
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Get.to(() =>
                    EditAssessmentPage(assessment: assessment));

                
                (context as Element).markNeedsBuild();
              },
            ),
          ),
        );
      },
    );
  }
}