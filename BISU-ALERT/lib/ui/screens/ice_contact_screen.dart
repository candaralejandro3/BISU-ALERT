import 'package:flutter/material.dart';

import '../../data/services/profile_data_service.dart';
import '../theme/app_colors.dart';

class IceContactScreen extends StatefulWidget {
  const IceContactScreen({super.key});

  @override
  State<IceContactScreen> createState() => _IceContactScreenState();
}

class _IceContactScreenState extends State<IceContactScreen> {
  final ProfileDataService _service = ProfileDataService();

  @override
  void initState() {
    super.initState();
    _service.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showEditDialog() {
    final nameCtrl = TextEditingController(text: _service.iceName);
    final relCtrl = TextEditingController(text: _service.iceRelationship);
    final phoneCtrl = TextEditingController(text: _service.icePhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Edit ICE Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relCtrl,
                decoration: const InputDecoration(
                  labelText: 'Relationship (e.g. Mother / Guardian)',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
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
              await _service.saveIceContact(
                name: nameCtrl.text.trim(),
                relationship: relCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
              );
              if (mounted) setState(() {});
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ICE Contact updated successfully.'),
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
        title: const Text('ICE Contact'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Contact Details',
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
                  _DetailRow(
                    icon: Icons.person_outline,
                    iconColor: AppColors.primary,
                    label: 'Contact Name',
                    value: _service.iceName.isNotEmpty
                        ? _service.iceName
                        : 'Not specified',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.family_restroom_outlined,
                    iconColor: AppColors.primary,
                    label: 'Relationship',
                    value: _service.iceRelationship.isNotEmpty
                        ? _service.iceRelationship
                        : 'Not specified',
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.phone_in_talk_outlined,
                    iconColor: AppColors.primary,
                    label: 'Phone Number',
                    value: _service.icePhone.isNotEmpty
                        ? _service.icePhone
                        : 'Not specified',
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
