import 'package:flutter/material.dart';

import '../../data/auth/auth_controller.dart';

/// Asks for confirmation, then clears the session. The auth gate reacts to the
/// state change and swaps the app back to the sign-in screen.
Future<void> confirmSignOut(BuildContext context, AuthController auth) async {
  final bool? shouldSignOut = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Log out of BISU-Alert?'),
        content: const Text(
          'You will stop receiving alerts about where emergencies are located '
          'on campus until you sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      );
    },
  );

  if (shouldSignOut == true) {
    auth.signOut();
  }
}
