import 'package:flutter/material.dart';

import '../../../data/auth/auth_controller.dart';
import '../../../data/auth/auth_scope.dart';
import '../../widgets/auth_scaffold.dart';
import 'auth_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onCreateAccount});

  final VoidCallback onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _errorMessage = null);

    try {
      await AuthScope.read(context).signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    }
  }

  void _useDemoAccount() {
    _emailController.text = AuthController.demoEmail;
    _passwordController.text = AuthController.demoPassword;
    setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = AuthScope.of(context).isBusy;

    return AuthScaffold(
      title: 'Sign in',
      subtitle: 'See where emergencies are located on the BISU-Bilar campus, '
          'and let responders know where you are.',
      children: [
        Card(
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    AuthErrorBanner(message: _errorMessage!),
                  TextFormField(
                    controller: _emailController,
                    enabled: !isBusy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Campus email',
                      hintText: 'student@bisu.edu.ph',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isBusy,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (String? value) => AuthValidators.notEmpty(
                      value,
                      'Enter your password.',
                    ),
                    onFieldSubmitted: (_) {
                      if (!isBusy) {
                        _submit();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: isBusy
                            ? null
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password reset link sent to your campus '
                                      'email (placeholder).',
                                    ),
                                  ),
                                );
                              },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AuthSubmitButton(
                    label: 'Sign In',
                    isBusy: isBusy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'New to BISU-Alert?',
              style: TextStyle(fontSize: 14),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F5222),
              ),
              onPressed: isBusy ? null : widget.onCreateAccount,
              child: const Text(
                'Create an account',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueGrey.shade700,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User Guide will be available soon.'),
                ),
              );
            },
            icon: const Icon(Icons.menu_book_outlined, size: 20),
            label: const Text(
              'User Guide',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _DemoHint(onUseDemoAccount: isBusy ? null : _useDemoAccount),
      ],
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onUseDemoAccount});

  final VoidCallback? onUseDemoAccount;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo account',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AuthController.demoEmail} / ${AuthController.demoPassword}',
                  style: textTheme.bodySmall?.copyWith(
                    color: textTheme.bodySmall?.color?.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onUseDemoAccount,
            child: const Text('Fill'),
          ),
        ],
      ),
    );
  }
}
