import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/components/shadcn_button.dart';
import '../../../shared/components/shadcn_input.dart';
import '../../../shared/theme/shadcn_theme.dart';
import 'auth_state.dart';

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
        ref.read(authControllerProvider.notifier).register(email, password);
      } else {
        ref.read(authControllerProvider.notifier).login(email, password);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Listen for errors or success
    ref.listen(authControllerProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.destructive,
          ),
        );
      } else if (next is AuthSuccess) {
        // Navigate to home or show success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isRegistering ? 'Account created!' : 'Welcome back!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Header
                  Text(
                    'Cookest',
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms).moveY(begin: 20, end: 0),
                  
                  const SizedBox(height: 8),
                  Text(
                    _isRegistering 
                      ? 'Create an account to get started' 
                      : 'Enter your email below to login to your account',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  // Fields
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
                  ).animate().fadeIn(delay: 300.ms).moveX(begin: -20, end: 0),

                  const SizedBox(height: 16),

                  ShadcnInput(
                    label: 'Password',
                    placeholder: '••••••••',
                    controller: _passwordController,
                    obscureText: true,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 8) return 'Password must be at least 8 characters';
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms).moveX(begin: -20, end: 0),

                  const SizedBox(height: 24),

                  // Actions
                  ShadcnButton(
                    text: _isRegistering ? 'Sign Up with Email' : 'Sign In with Email',
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
                        child: Text(
                          'OR CONTINUE WITH',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.mutedForeground,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppTheme.inputBorder)),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 16),

                  ShadcnButton(
                    text: 'Github',
                    variant: ShadcnButtonVariant.outline,
                    fullWidth: true,
                    icon: const Icon(LucideIcons.github, size: 16),
                    onPressed: () {}, // Stub
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 24),

                  // Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isRegistering 
                        ? 'Already have an account? Sign In' 
                        : 'Don\'t have an account? Sign Up',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
