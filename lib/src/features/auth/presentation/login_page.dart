import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/components/shadcn_button.dart';
import '../../../shared/components/shadcn_input.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../data/auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (_isRegistering) {
        ref.read(authNotifierProvider.notifier).register(email, password);
      } else {
        ref.read(authNotifierProvider.notifier).login(email, password);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next is AuthAuthenticated) {
        context.go('/');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const Icon(LucideIcons.chefHat, size: 48, color: AppTheme.primary)
                      .animate().scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  Text(
                    'Cookest',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms),

                  const SizedBox(height: 8),

                  Text(
                    _isRegistering
                        ? 'Create an account to get started'
                        : 'Sign in to your account',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  ShadcnInput(
                    label: 'Email',
                    placeholder: 'm@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!val.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),

                  const SizedBox(height: 16),

                  ShadcnInput(
                    label: 'Password',
                    placeholder: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 8) return 'At least 8 characters';
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.05),

                  const SizedBox(height: 24),

                  ShadcnButton(
                    text: _isRegistering ? 'Create Account' : 'Sign In',
                    fullWidth: true,
                    isLoading: authState is AuthLoading,
                    onPressed: _submit,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppTheme.inputBorder)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(fontSize: 10, color: AppTheme.mutedForeground, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(child: Divider(color: AppTheme.inputBorder)),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: () => setState(() {
                      _isRegistering = !_isRegistering;
                      _formKey.currentState?.reset();
                    }),
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Sign In'
                          : "Don't have an account? Sign Up",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ).animate().fadeIn(delay: 700.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
