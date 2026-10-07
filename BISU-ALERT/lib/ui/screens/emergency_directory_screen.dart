import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock/mock_data.dart';
import '../../data/model/emergency_contact.dart';

class EmergencyDirectoryScreen extends StatelessWidget {
  const EmergencyDirectoryScreen({super.key});

  Future<void> _callContact(BuildContext context, EmergencyContact contact) async {
    final Uri uri = Uri(scheme: 'tel', path: contact.phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot place call to ${contact.phoneNumber}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Directory',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: MockData.emergencyContacts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final EmergencyContact contact = MockData.emergencyContacts[index];
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.phone_in_talk_outlined),
                      ),
                      title: Text(contact.name),
                      subtitle: Text('${contact.role} • ${contact.phoneNumber}'),
                      trailing: FilledButton(
                        onPressed: () => _callContact(context, contact),
                        child: const Text('Call'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
