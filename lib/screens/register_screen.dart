import 'dart:async';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../services/gatherly_api.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final state = AppScope.of(context);
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final status = await state.api.emailStatus(email);
      if (status.registered) {
        throw const GatherlyApiException(
          'Email is already registered, please log in to continue.',
        );
      }

      if (!status.verified) {
        var retryAfterSeconds = 60;
        String? initialError;
        try {
          await state.api.sendVerification(name: name, email: email);
        } on GatherlyApiException catch (error) {
          if (error.statusCode != 429) rethrow;
          retryAfterSeconds = error.retryAfterSeconds ?? 60;
          initialError = error.message;
        }
        if (!mounted) return;
        final verified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _EmailVerificationDialog(
            api: state.api,
            name: name,
            email: email,
            initialRetryAfterSeconds: retryAfterSeconds,
            initialError: initialError,
          ),
        );
        if (verified != true || !mounted) return;
      }

      final result = await state.api.register(
        name: name,
        email: email,
        password: _passwordController.text,
      );
      state.signIn(result.user);
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } on GatherlyApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFB0B0BA)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            validator: (value) => requiredField(value) == null
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
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            validator: emailField,
          ),
          const SizedBox(height: 15),

          _label('Password'),
          const SizedBox(height: 7),
          TextFormField(
            controller: _passwordController,
            obscureText: _hidePassword,
            style: const TextStyle(fontSize: 12),
            decoration:
                _inputDecoration(
                  '8–128 characters, with a number and symbol',
                ).copyWith(
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
            onChanged: (_) {
              if (_errorMessage != null) setState(() => _errorMessage = null);
            },
            validator: passwordField,
          ),
          const SizedBox(height: 22),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Color(0xFFB3261E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB3261E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 43,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
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

class _EmailVerificationDialog extends StatefulWidget {
  const _EmailVerificationDialog({
    required this.api,
    required this.name,
    required this.email,
    required this.initialRetryAfterSeconds,
    this.initialError,
  });

  final GatherlyApi api;
  final String name;
  final String email;
  final int initialRetryAfterSeconds;
  final String? initialError;

  @override
  State<_EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<_EmailVerificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  Timer? _timer;
  late int _resendSeconds;
  String? _message;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _error = widget.initialError;
    _startResendCountdown(widget.initialRetryAfterSeconds);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startResendCountdown(int seconds) {
    _timer?.cancel();
    _resendSeconds = seconds;
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

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.verifyEmail(
        email: widget.email,
        code: _code.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.api.sendVerification(name: widget.name, email: widget.email);
      if (!mounted) return;
      setState(() => _message = 'A new verification code was sent.');
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verify your email'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Enter the six-digit code sent to ${widget.email}.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                ),
                validator: (value) =>
                    value == null || !RegExp(r'^\d{6}$').hasMatch(value)
                    ? 'Enter the six-digit verification code.'
                    : null,
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(_message!, style: const TextStyle(color: Colors.green)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _busy || _resendSeconds > 0 ? null : _resend,
          child: Text(
            _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend',
          ),
        ),
        FilledButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
