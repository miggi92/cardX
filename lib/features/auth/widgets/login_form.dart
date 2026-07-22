import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cardx/core/theme/app_theme.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onToggleMode;

  const LoginForm({super.key, required this.onToggleMode});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      TextInput.finishAutofillContext();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        // Optional: redirectTo: 'io.supabase.flutter://callback',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

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
            Text('Sign in with your email or Google.', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
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
              onPressed: _isLoading ? null : _signInWithEmail,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Sign in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.login), // Hier idealerweise ein Google SVG Asset einfügen
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: _isLoading ? null : widget.onToggleMode,
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