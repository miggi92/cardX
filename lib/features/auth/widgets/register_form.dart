import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardx/core/theme/app_theme.dart';

import '../application/auth_controller.dart';

class RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onToggleMode;

  const RegisterForm({super.key, required this.onToggleMode});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      final response = await ref.read(authControllerProvider.notifier).signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. Check your email to confirm it.')),
        );
      } else {
        TextInput.finishAutofillContext();
      }
    } on AuthFlowException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final authState = ref.watch(authControllerProvider);

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeroIcon(brand),
            const SizedBox(height: 20),
            Text('Create your account', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Create an email password account to start collecting.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (val) => (val == null || val.isEmpty || !val.contains('@')) ? 'Enter a valid email.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              validator: (val) => (val != null && val.length < 6) ? 'Use at least 6 characters.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined)),
              onFieldSubmitted: (_) => _signUp(),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please confirm your password.';
                if (val != _passwordController.text) return 'Passwords do not match.';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.isAnyLoading ? null : _signUp,
              child: authState.isPasswordAuthLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: authState.isAnyLoading ? null : widget.onToggleMode,
              child: const Text('Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIcon(AppBrandTheme brand) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(gradient: brand.heroGradient, borderRadius: BorderRadius.circular(22)),
      child: const Icon(Icons.sports_soccer, color: Colors.white, size: 36),
    );
  }
}