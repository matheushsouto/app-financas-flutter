import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guia_financeiro/core/routes/app_routes.dart';
import 'package:guia_financeiro/core/utils/validators.dart';
import 'package:guia_financeiro/services/auth_service.dart';

import '../../core/constants/app_strings.dart';
import '../../widgets/screen_placeholder.dart';

/// Tela de login (wireframe 1).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(
        email: _emailController.text, 
        password: _passwordController.text,
      );
      if (mounted) context.goNamed(AppRoutes.home);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleForgotPassword() async {
    final String email = _emailController.text.trim();

    if (Validators.email(email) != null) {
      _showMessage('Informe seu e-mail no campo acima para recuperar');
      return;
    }

    try {
      await _authService.sendPasswordResetEmail(email);
      _showMessage('Enviamos um e-mail com as instruções de recuperação');
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch(_) {
      _showMessage(AppStrings.genericError);
    }
  }
}