
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  final bool isDialog;
  final VoidCallback? onSwitchToLogin;
  final VoidCallback? onSuccess;

  const RegisterScreen({
    super.key,
    this.isDialog = false,
    this.onSwitchToLogin,
    this.onSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  static const purple = Color(0xFF756FB8);
  static const darkText = Color(0xFF303342);
  static const mutedText = Color(0xFF777887);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;

    final state = AppScope.of(context);
    final current = state.profile;

    state.updateProfile(
      Profile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: current.phone,
        organization: current.organization,
      ),
    );

    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/dashboard',
        (route) => false,
      );
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 11,
        color: Color(0xFFB0B0BA),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE7E7EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE7E7EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: purple),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Start planning your first event in minutes.',
            style: TextStyle(fontSize: 11, color: mutedText),
          ),
          const SizedBox(height: 20),

          _label('Full name'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 12),
            decoration: _inputDecoration('Enter your full name'),
            validator: (value) =>
                requiredField(value) == null
                    ? null
                    : 'Please enter your full name.',
          ),
          const SizedBox(height: 15),

          _label('Email address'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 12),
            decoration: _inputDecoration('Enter your email address'),
            validator: emailField,
          ),
          const SizedBox(height: 15),

          _label('Password'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            style: const TextStyle(fontSize: 12),
            decoration: _inputDecoration('At least 6 characters').copyWith(
              suffixIcon: IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                onPressed: () {
                  setState(() => _hidePassword = !_hidePassword);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password.';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          SizedBox(
            height: 43,
            child: ElevatedButton(
              onPressed: _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3142),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Create account',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),

          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
                style: TextStyle(fontSize: 11, color: mutedText),
              ),
              TextButton(
                onPressed: () {
                  if (widget.onSwitchToLogin != null) {
                    widget.onSwitchToLogin!();
                  } else {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign in',
                  style: TextStyle(fontSize: 11, color: purple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isDialog) return _buildForm();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }
}
