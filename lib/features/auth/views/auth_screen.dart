import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cardx/core/theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        TextInput.finishAutofillContext();
        return;
      }

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (response.session == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Account created. Check your email to confirm it.'),
          ),
        );
      } else {
        TextInput.finishAutofillContext();
      }
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Authentication failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleMode() {
    TextInput.finishAutofillContext(shouldSave: false);
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;
    final title = _isLoginMode ? 'Welcome back' : 'Create your account';
    final subtitle = _isLoginMode
        ? 'Sign in with your email and password to continue.'
        : 'Create an email password account to start collecting.';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: brand.pageGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: brand.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: brand.surfaceShadow,
                        blurRadius: 32,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: brand.heroGradient,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.sports_soccer,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ToggleButtons(
                            isSelected: [_isLoginMode, !_isLoginMode],
                            onPressed: (index) {
                              if ((_isLoginMode && index == 0) ||
                                  (!_isLoginMode && index == 1)) {
                                return;
                              }
                              _toggleMode();
                            },
                            borderRadius: BorderRadius.circular(16),
                            selectedColor: theme.colorScheme.onPrimary,
                            fillColor: theme.colorScheme.primary,
                            color: theme.colorScheme.onSurface,
                            constraints: const BoxConstraints(minHeight: 48),
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18),
                                child: Text('Sign in'),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18),
                                child: Text('Register'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _AuthCredentialFields(
                            isLoginMode: _isLoginMode,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            onSubmit: _submit,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    _isLoginMode ? 'Sign in' : 'Create account',
                                  ),
                          ),
                          const SizedBox(height: 14),
                          TextButton(
                            onPressed: _isLoading ? null : _toggleMode,
                            child: Text(
                              _isLoginMode
                                  ? 'Need an account? Register'
                                  : 'Already have an account? Sign in',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCredentialFields extends StatelessWidget {
  const _AuthCredentialFields({
    required this.isLoginMode,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
  });

  final bool isLoginMode;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Email is required.';
    }
    if (!trimmed.contains('@')) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Password is required.';
    }
    if ((value ?? '').length < 6) {
      return 'Use at least 6 characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoginMode) {
      return Column(
        children: [
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: _validatePassword,
            onFieldSubmitted: (_) => onSubmit(),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'name@example.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: _validateEmail,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          textInputAction: TextInputAction.next,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: _validatePassword,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.newPassword],
          decoration: const InputDecoration(
            labelText: 'Confirm password',
            prefixIcon: Icon(Icons.lock_reset_outlined),
          ),
          validator: (value) {
            if ((value ?? '').isEmpty) {
              return 'Please confirm your password.';
            }
            if (value != passwordController.text) {
              return 'Passwords do not match.';
            }
            return null;
          },
          onFieldSubmitted: (_) => onSubmit(),
        ),
      ],
    );
  }
}
