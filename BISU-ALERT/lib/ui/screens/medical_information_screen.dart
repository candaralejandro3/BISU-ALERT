import 'package:flutter/material.dart';

import '../../data/services/profile_data_service.dart';
import '../theme/app_colors.dart';

class MedicalInformationScreen extends StatefulWidget {
  const MedicalInformationScreen({super.key});

  @override
  State<MedicalInformationScreen> createState() => _MedicalInformationScreenState();
}

class _MedicalInformationScreenState extends State<MedicalInformationScreen> {
  final ProfileDataService _service = ProfileDataService();

  @override
  void initState() {
    super.initState();
    _service.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showEditDialog() {
    final bloodCtrl = TextEditingController(text: _service.bloodType);
    final allergyCtrl = TextEditingController(text: _service.allergies);
    final condCtrl = TextEditingController(text: _service.conditions);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Edit Medical Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bloodCtrl,
                decoration: const InputDecoration(
                  labelText: 'Blood Type (e.g. O+, A+, B+, AB-)',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: allergyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Known Drug / Food Allergies',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: condCtrl,
                decoration: const InputDecoration(
                  labelText: 'Medical Conditions (e.g. Asthma, Diabetes)',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            onPressed: () async {
              await _service.saveMedicalInfo(
                blood: bloodCtrl.text.trim(),
                allergy: allergyCtrl.text.trim(),
                condition: condCtrl.text.trim(),
              );
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Medical Information updated successfully.'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Information'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Medical Info',
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MedicalDetailRow(
                    icon: Icons.water_drop_outlined,
                    iconColor: const Color(0xFF0D9488),
                    label: 'Blood Type',
                    value: _service.bloodType.isNotEmpty
                        ? _service.bloodType
                        : 'Not specified',
                  ),
                  const Divider(height: 24),
                  _MedicalDetailRow(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFEAB308),
                    label: 'Known Drug / Environmental Allergies',
                    value: _service.allergies.isNotEmpty
                        ? _service.allergies
                        : 'None reported',
                  ),
                  const Divider(height: 24),
                  _MedicalDetailRow(
                    icon: Icons.medical_services_outlined,
                    iconColor: const Color(0xFF16A34A),
                    label: 'Medical Conditions',
                    value: _service.conditions.isNotEmpty
                        ? _service.conditions
                        : 'None reported',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MedicalDetailRow extends StatelessWidget {
  const _MedicalDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
