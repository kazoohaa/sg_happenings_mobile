import 'package:flutter/material.dart';

import '../../api/app_api.dart';
import '../../api/auth_repository.dart';
import '../login/login_page.dart';
import '../main_navigation/main_navigation.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final signedIn = await authRepository.register(
        username: _username.text,
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      if (signedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (context) => const MainNavigation()),
          (route) => false,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Please sign in with your username and password.'),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const LoginPage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 16),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _fieldBox({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E0D5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8ED),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF8),
              Color(0xFFF7EEDC),
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF3E2723)),
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to discover events and manage your profile.',
                    style: TextStyle(fontSize: 15, height: 1.35, color: Colors.brown.shade800),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          _fieldBox(
                            child: TextFormField(
                              controller: _username,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: _fieldDecoration('Username'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter a username';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _fieldBox(
                            child: TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration('Full name'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your name';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _fieldBox(
                            child: TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: _fieldDecoration('Email'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Enter your email';
                                if (!AuthRepository.isValidEmailForUi(v.trim())) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _fieldBox(
                            child: TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: _fieldDecoration('Password').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF666666),
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter a password';
                                if (v.length < 6) return 'At least 6 characters';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _fieldBox(
                            child: TextFormField(
                              controller: _confirm,
                              obscureText: _obscureConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _fieldDecoration('Confirm password').copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                                    color: const Color(0xFF666666),
                                  ),
                                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v != _password.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox(
                      width: 320,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          disabledBackgroundColor:
                              const Color(0xFFFF6B35).withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute<void>(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                      child: const Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          color: Color(0xFFD84315),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
