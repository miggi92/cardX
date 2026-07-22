import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cardx/core/theme/app_theme.dart';

import '../application/auth_controller.dart';
import '../domain/auth_provider_type.dart';

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onToggleMode;

  const LoginForm({super.key, required this.onToggleMode});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await ref.read(authControllerProvider.notifier).signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      TextInput.finishAutofillContext();
    } on AuthFlowException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _signInWithProvider(AuthProviderType provider) async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithProvider(provider);
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
            Text('Welcome back', style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text('Sign in with your email or a social provider.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
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
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
              onFieldSubmitted: (_) => _signInWithEmail(),
              validator: (val) => (val == null || val.isEmpty) ? 'Password is required.' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.isAnyLoading ? null : _signInWithEmail,
              child: authState.isPasswordAuthLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            ...supportedSocialAuthProviders.map(
              (provider) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  onPressed: authState.isAnyLoading ? null : () => _signInWithProvider(provider),
                  icon: authState.loadingProvider == provider
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : Icon(provider.icon),
                  label: Text(provider.label),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: authState.isAnyLoading ? null : widget.onToggleMode,
              child: const Text('Need an account? Register'),
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