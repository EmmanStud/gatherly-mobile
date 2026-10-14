
import 'dart:async';

import 'package:flutter/material.dart';

import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  final bool isDialog;
  final VoidCallback? onSwitchToRegister;

  const LoginScreen({
    super.key,
    this.isDialog = false,
    this.onSwitchToRegister,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
  bool _isLoading = false;

  static const purple = Color(0xFF756FB8);
  static const darkText = Color(0xFF303342);
  static const mutedText = Color(0xFF777887);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final state = AppScope.of(context);
      final result = await state.api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      state.signIn(result.user);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (error) {
      if (mounted) showToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await showDialog<String>(
      context: context,
      builder: (_) => _PasswordResetDialog(
        api: AppScope.of(context).api,
        initialEmail: _emailController.text.trim(),
      ),
    );
    if (message != null && mounted) showToastOn(messenger, message);
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: darkText,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Sign in to continue to your organizer workspace.',
            style: TextStyle(fontSize: 11, color: mutedText),
          ),
          const SizedBox(height: 22),
          const Text(
            'Email address',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 12),
            decoration: _inputDecoration('Enter your email address'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email address.';
              }
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 17),
          const Text(
            'Password',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            style: const TextStyle(fontSize: 12),
            decoration: _inputDecoration('Enter your password').copyWith(
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
                return 'Please enter your password.';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isLoading ? null : _forgotPassword,
              child: const Text(
                'Forgot password?',
                style: TextStyle(fontSize: 11, color: purple),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 43,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D3142),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Sign in securely',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'New to Gatherly? ',
                style: TextStyle(fontSize: 11, color: mutedText),
              ),
              TextButton(
                onPressed: () {
                  if (widget.onSwitchToRegister != null) {
                    widget.onSwitchToRegister!();
                  } else {
                    Navigator.pushNamed(context, '/register');
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Create an account',
                  style: TextStyle(fontSize: 11, color: purple),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFB0B0BA)),
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

enum _PasswordResetStep { email, code, password }

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({
    required this.api,
    required this.initialEmail,
  });

  final GatherlyApi api;
  final String initialEmail;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  _PasswordResetStep _step = _PasswordResetStep.email;
  String? _resetToken;
  String? _message;
  String? _error;
  bool _busy = false;
  int _resendSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _resendSeconds = seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.api.sendPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _step = _PasswordResetStep.code;
        _message = message;
      });
      _startResendCountdown(60);
    } catch (error) {
      if (!mounted) return;
      if (error is GatherlyApiException && error.statusCode == 429) {
        setState(() {
          _step = _PasswordResetStep.code;
          _message = null;
          _error = error.message;
        });
        _startResendCountdown(error.retryAfterSeconds ?? 60);
      } else {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.api.sendPasswordReset(_email.text.trim());
      if (!mounted) return;
      setState(() => _message = message);
      _startResendCountdown(60);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      if (error is GatherlyApiException && error.statusCode == 429) {
        _startResendCountdown(error.retryAfterSeconds ?? 60);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await widget.api.verifyPasswordReset(
        email: _email.text.trim(),
        code: _code.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _step = _PasswordResetStep.password;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.api.completePasswordReset(
        email: _email.text.trim(),
        resetToken: _resetToken!,
        newPassword: _newPassword.text,
        confirmNewPassword: _confirmPassword.text,
      );
      if (mounted) Navigator.of(context).pop(message);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _PasswordResetStep.email => 'Reset your password',
      _PasswordResetStep.code => 'Verify your email',
      _PasswordResetStep.password => 'Choose a new password',
    };

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_step == _PasswordResetStep.email) ...[
                  const Text('Enter your account email to receive a recovery code.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email address'),
                    validator: emailField,
                  ),
                ],
                if (_step == _PasswordResetStep.code) ...[
                  Text('Enter the recovery code sent to ${_email.text.trim()}.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'Six-digit recovery code'),
                    validator: (value) => value == null || !RegExp(r'^\d{6}$').hasMatch(value)
                        ? 'Enter the six-digit recovery code.'
                        : null,
                  ),
                ],
                if (_step == _PasswordResetStep.password) ...[
                  Text('Set a new password for ${_email.text.trim()}.'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New password'),
                    validator: passwordField,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm new password'),
                    validator: (value) {
                      final error = passwordField(value);
                      if (error != null) return error;
                      return value != _newPassword.text ? 'Passwords do not match.' : null;
                    },
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: const TextStyle(color: Colors.green)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_step == _PasswordResetStep.code)
          TextButton(
            onPressed: _busy || _resendSeconds > 0 ? null : _resendCode,
            child: Text(_resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend code'),
          ),
        FilledButton(
          onPressed: _busy
              ? null
              : switch (_step) {
                  _PasswordResetStep.email => _sendCode,
                  _PasswordResetStep.code => _verifyCode,
                  _PasswordResetStep.password => _completeReset,
                },
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(switch (_step) {
                  _PasswordResetStep.email => 'Send code',
                  _PasswordResetStep.code => 'Verify code',
                  _PasswordResetStep.password => 'Reset password',
                }),
        ),
      ],
    );
  }
}
