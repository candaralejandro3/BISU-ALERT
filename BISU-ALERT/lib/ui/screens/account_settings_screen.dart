import 'package:flutter/material.dart';

import '../../data/auth/auth_controller.dart';
import '../../data/auth/auth_scope.dart';
import '../theme/app_colors.dart';
import '../widgets/logout_dialog.dart';
import 'onboarding_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  void _showChangePasswordDialog(BuildContext context, AuthController auth) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password (min 6 chars)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: isSaving
                  ? null
                  : () async {
                      final current = currentPasswordController.text;
                      final newPass = newPasswordController.text;
                      final confirm = confirmPasswordController.text;

                      if (newPass != confirm) {
                        setDialogState(() => errorMessage = 'New passwords do not match.');
                        return;
                      }
                      if (newPass.length < 6) {
                        setDialogState(
                          () => errorMessage = 'Password must be at least 6 characters.',
                        );
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                        errorMessage = null;
                      });

                      try {
                        await auth.changePassword(
                          currentPassword: current,
                          newPassword: newPass,
                        );
                        if (context.mounted) {
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password updated successfully.'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          errorMessage = e.toString().replaceFirst('Exception: ', '');
                        });
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.sos),
            SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your BISU-Alert account? '
          'This will permanently deactivate your campus mobile profile, revoke active sessions, '
          'and remove your emergency ICE contact records.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.sos),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await auth.deleteAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deactivated and signed out.'),
                    backgroundColor: AppColors.sos,
                  ),
                );
              }
            },
            child: const Text('Yes, Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = AuthScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    ),
                    title: const Text(
                      'Change Password',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Update your account sign-in password.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () => _showChangePasswordDialog(context, auth),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Color(0xFF0D9488)),
                    ),
                    title: const Text(
                      'View App Tutorial',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Replay the BISU-Alert welcome guide.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => OnboardingScreen(
                            onGetStarted: () => Navigator.of(ctx).pop(),
                            isReplay: true,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Color(0xFFEA580C)),
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Log out of this device.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () => confirmSignOut(context, auth),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sos.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.sos),
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: AppColors.sos,
                      ),
                    ),
                    subtitle: const Text(
                      'Revoke campus registration and purge local data.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.sos,
                    ),
                    onTap: () => _showDeleteAccountDialog(context, auth),
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
