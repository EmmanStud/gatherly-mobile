import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../models/models.dart';
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
            onPressed: () => showToast(context, 'Password reset instructions sent to your email.'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size(0, 48),
              side: const BorderSide(color: Color(0x1A000000)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            icon: const Icon(Icons.lock_reset),
            label: const Text('Send password reset email'),
          ),
        ],
      ),
    );

    return TwoColumn(left: notifications, right: security, breakpoint: 900);
  }
}