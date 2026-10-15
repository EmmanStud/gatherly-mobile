import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/models.dart';
import '../services/gatherly_api.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  Widget _setting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final prefs = state.preferences;

    void change(Preferences next, String message) {
      state.updatePreferences(next);
      showToast(context, message);
    }

    final notifications = Panel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelTitle('Notifications', 'Control the updates sent to your account.'),
          const SizedBox(height: 16),
          _setting(
            'Order confirmations',
            'Email me whenever a guest completes an order.',
            prefs.orderEmails,
            (v) => change(prefs.copyWith(orderEmails: v), 'Notification preference updated.'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _setting(
            'Event reminders',
            'Remind me before ticket sales and events begin.',
            prefs.eventReminders,
            (v) => change(prefs.copyWith(eventReminders: v), 'Notification preference updated.'),
          ),
          const Divider(height: 1, color: AppColors.border),
          _setting(
            'Weekly performance summary',
            'Send a Monday recap of ticket sales and attendance.',
            prefs.weeklySummary,
            (v) => change(prefs.copyWith(weeklySummary: v), 'Notification preference updated.'),
          ),
        ],
      ),
    );

    final security = Panel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PanelTitle('Security', 'Extra protection for your organizer workspace.'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.soft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lilac,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-factor authentication',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Require a verification code when signing in.',
                        style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: prefs.twoFactor,
                  onChanged: (v) => change(
                    prefs.copyWith(twoFactor: v),
                    v ? 'Two-factor authentication enabled.' : 'Two-factor authentication disabled.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showPasswordChange(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size(0, 48),
              side: const BorderSide(color: Color(0x1A000000)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            icon: const Icon(Icons.lock_reset),
            label: const Text('Change password'),
          ),
        ],
      ),
    );

    return TwoColumn(left: notifications, right: security, breakpoint: 900);
  }
}

Future<void> _showPasswordChange(BuildContext context) async {
  final message = await showDialog<String>(
    context: context,
    builder: (_) => _ChangePasswordDialog(api: AppScope.of(context).api),
  );
  if (message != null && context.mounted) showToast(context, message);
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.api});

  final GatherlyApi api;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final message = await widget.api.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
        confirmNewPassword: _confirmPassword.text,
      );
      if (mounted) Navigator.pop(context, message);
    } on GatherlyApiException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to change your password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your current password.'
                      : null,
                ),
                const SizedBox(height: 12),
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
                    final passwordError = passwordField(value);
                    if (passwordError != null) return passwordError;
                    if (value != _newPassword.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
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
                          size: 18,
                          color: Color(0xFFB3261E),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFB3261E),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change password'),
        ),
      ],
    );
  }
}