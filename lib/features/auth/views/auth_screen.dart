import 'package:flutter/material.dart';
import 'package:cardx/core/theme/app_theme.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginMode = true;

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.extension<AppBrandTheme>()!;

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
                  child: _isLoginMode
                      ? LoginForm(onToggleMode: _toggleMode)
                      : RegisterForm(onToggleMode: _toggleMode),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}