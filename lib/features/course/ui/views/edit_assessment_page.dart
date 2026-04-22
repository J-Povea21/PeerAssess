import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EditAssessmentPage extends StatefulWidget {
  final Map<String, dynamic> assessment;

  const EditAssessmentPage({super.key, required this.assessment});

  @override
  State<EditAssessmentPage> createState() => _EditAssessmentPageState();
}

class _EditAssessmentPageState extends State<EditAssessmentPage> {
  late TextEditingController nameController;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.assessment['name']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar evaluación'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la evaluación',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
               
                widget.assessment['name'] = nameController.text;

                Get.back();
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        ),
      ),
    );
  }
}