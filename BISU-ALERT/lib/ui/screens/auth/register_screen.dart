import 'package:flutter/material.dart';

import '../../../data/auth/auth_controller.dart';
import '../../../data/auth/auth_scope.dart';
import '../../../data/model/app_user.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_scaffold.dart';
import 'auth_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onBackToLogin,
    required this.onRegistered,
  });

  final VoidCallback onBackToLogin;
  final VoidCallback onRegistered;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _campusIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  CampusRole _role = CampusRole.student;
  bool _obscurePassword = true;
  bool _wantsEmergencyLocationAlerts = true;
  bool _acceptedTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _campusIdController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage =
            'Please accept the campus data privacy terms to continue.';
      });
      return;
    }

    setState(() => _errorMessage = null);

    final AuthController auth = AuthScope.read(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final VoidCallback onRegistered = widget.onRegistered;

    try {
      await auth.register(
        fullName: _nameController.text,
        email: _emailController.text,
        campusId: _campusIdController.text,
        role: _role,
        department: _departmentController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
        wantsEmergencyLocationAlerts: _wantsEmergencyLocationAlerts,
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
      return;
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Account created. You can now see where emergencies are located on '
          'campus.',
        ),
      ),
    );
    onRegistered();
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = AuthScope.of(context).isBusy;

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Register to get incident locations, evacuation zones, and '
          'live alerts for the BISU-Bilar campus.',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    AuthErrorBanner(message: _errorMessage!),
                  TextFormField(
                    controller: _nameController,
                    enabled: !isBusy,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (String? value) => AuthValidators.notEmpty(
                      value,
                      'Enter your full name.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CampusRole>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Campus role',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    items: CampusRole.values
                        .map(
                          (CampusRole role) => DropdownMenuItem<CampusRole>(
                            value: role,
                            child: Text(role.label),
                          ),
                        )
                        .toList(),
                    onChanged: isBusy
                        ? null
                        : (CampusRole? value) {
                            if (value != null) {
                              setState(() => _role = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _campusIdController,
                    enabled: !isBusy,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Campus ID',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: (String? value) => AuthValidators.notEmpty(
                      value,
                      'Enter your campus ID number.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _departmentController,
                    enabled: !isBusy,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'College / Department',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: (String? value) => AuthValidators.notEmpty(
                      value,
                      'Enter your college or department.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    enabled: !isBusy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Campus email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !isBusy,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: AuthValidators.phoneNumber,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isBusy,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: 'At least 8 characters.',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                    validator: AuthValidators.password,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmController,
                    enabled: !isBusy,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                    validator: (String? value) {
                      if ((value ?? '').isEmpty) {
                        return 'Re-enter your password.';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!isBusy) {
                        _submit();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: _wantsEmergencyLocationAlerts,
                  onChanged: isBusy
                      ? null
                      : (bool value) => setState(
                          () => _wantsEmergencyLocationAlerts = value,
                        ),
                  title: const Text('Emergency location alerts'),
                  subtitle: const Text(
                    'Notify me where an incident is happening and the nearest '
                    'safe zone.',
                  ),
                  secondary: const Icon(
                    Icons.share_location,
                    color: AppColors.primary,
                  ),
                ),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: isBusy
                      ? null
                      : (bool? value) => setState(
                          () => _acceptedTerms = value ?? false,
                        ),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I agree to the campus data privacy terms',
                  ),
                  subtitle: const Text(
                    'My location and profile may be shared with BISU response '
                    'teams during an emergency.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AuthSubmitButton(
          label: 'Create Account',
          isBusy: isBusy,
          onPressed: _submit,
        ),
        const SizedBox(height: 2),
        // Wrap (not Row) so the prompt and button move onto separate lines on
        // narrow screens or at large system font scales instead of overflowing.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Already registered?'),
            TextButton(
              onPressed: isBusy ? null : widget.onBackToLogin,
              child: const Text('Sign in'),
            ),
          ],
        ),
      ],
    );
  }
}
