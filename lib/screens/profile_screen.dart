import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class ProfilePanel extends StatefulWidget {
  const ProfilePanel({super.key});

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _organization;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Read once without subscribing; the form owns the text while editing.
    final profile = context.getInheritedWidgetOfExactType<AppScope>()!.notifier!.profile;
    _name = TextEditingController(text: profile.name);
    _email = TextEditingController(text: profile.email);
    _phone = TextEditingController(text: profile.phone);
    _organization = TextEditingController(text: profile.organization);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _organization.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await AppScope.of(context).updateProfile(
        Profile(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          organization: _organization.text.trim(),
        ),
      );
      if (mounted) setState(() => _successMessage = 'Profile changes saved.');
    } on GatherlyApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to save your profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field(String label, TextEditingController controller,
      {String? Function(String?)? validator,
      TextInputType? keyboardType,
      bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator ?? requiredField,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;

    final card = Panel(
      color: AppColors.panel,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              initials(profile.name),
              style: const TextStyle(color: AppColors.ink, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            profile.name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(profile.email, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACCOUNT ROLE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Primary organizer',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final form = Panel(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PanelTitle('Personal information', 'These details appear on your organizer account.'),
            const SizedBox(height: 24),
            _field(
              'Full name',
              _name,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required.';
                }
                if (value.trim().length > 100) {
                  return 'Name must be 100 characters or fewer.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _field(
              'Email address',
              _email,
              validator: emailField,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            const SizedBox(height: 18),
            _field('Mobile number', _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 18),
            _field('Organization', _organization),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              _messageBanner(_errorMessage!, isError: true),
              const SizedBox(height: 12),
            ],
            if (_successMessage != null) ...[
              _messageBanner(_successMessage!, isError: false),
              const SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save profile'),
              ),
            ),
          ],
        ),
      ),
    );

    return TwoColumn(left: card, right: form, leftFlex: 7, rightFlex: 13, breakpoint: 900);
  }

  Widget _messageBanner(String message, {required bool isError}) {
    final color = isError ? AppColors.danger : const Color(0xFF287A4B);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}