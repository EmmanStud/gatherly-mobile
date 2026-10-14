import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/format.dart';
import '../models/models.dart';
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    AppScope.of(context).updateProfile(
      Profile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        organization: _organization.text.trim(),
      ),
    );
    showToast(context, 'Profile changes saved.');
  }

  Widget _field(String label, TextEditingController controller,
      {String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
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
            _field('Full name', _name),
            const SizedBox(height: 18),
            _field('Email address', _email, validator: emailField, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 18),
            _field('Mobile number', _phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 18),
            _field('Organization', _organization),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _save, child: const Text('Save profile')),
            ),
          ],
        ),
      ),
    );

    return TwoColumn(left: card, right: form, leftFlex: 7, rightFlex: 13, breakpoint: 900);
  }
}