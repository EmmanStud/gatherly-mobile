import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/assets.dart';
import '../core/format.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'analytics_screen.dart';
import 'attendees_screen.dart';
import 'create_event_screen.dart';
import 'event_details_screen.dart';
import 'events_screen.dart';
import 'help_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Organizer workspace: sidebar (drawer on phones), top bar and the
/// Overview / Events / Orders / Attendees / Analytics / Profile / Settings /
/// Help Center pages from the design.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _wideBreakpoint = 900;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _active = 'Overview';

  void _select(String page) {
    setState(() => _active = page);
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) scaffold.closeDrawer();
  }

  Future<void> _signOut() async {
    final messenger = ScaffoldMessenger.of(context);
    String? signOutError;
    try {
      await AppScope.of(context).signOut();
    } catch (error) {
      signOutError = error.toString();
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    if (signOutError != null) {
      showToastOn(messenger, 'Signed out on this device. $signOutError');
    }
  }

  Future<void> _createEvent() async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CreateEventScreen()),
    );
    if (message != null && mounted) showToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final sidebar = DashboardSidebar(
      active: _active,
      onSelect: _select,
      onSignOut: _signOut,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.canvas,
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: AppColors.ink,
              shape: const RoundedRectangleBorder(),
              child: SafeArea(child: sidebar),
            ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 256,
              child: ColoredBox(
                color: AppColors.ink,
                child: SafeArea(child: sidebar),
              ),
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _TopBar(
                    wide: wide,
                    onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                    onProfile: () => _select('Profile'),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: wide ? 40 : 16,
                        vertical: wide ? 36 : 24,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _PageHeading(
                                active: _active,
                                onCreate: _createEvent,
                              ),
                              const SizedBox(height: 28),
                              _buildPage(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_active) {
      case 'Events':
        return const EventsPanel();
      case 'Orders':
        return const OrdersPanel();
      case 'Attendees':
        return const AttendeesPanel();
      case 'Analytics':
        return const AnalyticsPanel();
      case 'Profile':
        return const ProfilePanel();
      case 'Settings':
        return const SettingsPanel();
      case 'Help Center':
        return const HelpCenterPanel();
      case 'Overview':
      default:
        return const OverviewPanel();
    }
  }
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.active,
    required this.onSelect,
    required this.onSignOut,
  });

  final String active;
  final ValueChanged<String> onSelect;
  final VoidCallback onSignOut;

  static const _items = [
    (Icons.grid_view_rounded, 'Overview'),
    (Icons.calendar_month_outlined, 'Events'),
    (Icons.confirmation_number_outlined, 'Orders'),
    (Icons.people_outline, 'Attendees'),
    (Icons.bar_chart_rounded, 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: _SidebarLogo(),
                ),
                const SizedBox(height: 32),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      color: Color(0x59FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
                for (final item in _items)
                  _NavItem(
                    icon: item.$1,
                    label: item.$2,
                    selected: active == item.$2,
                    badge: item.$2 == 'Orders'
                        ? '${state.paidOrderCount}'
                        : null,
                    onTap: () => onSelect(item.$2),
                  ),
                const Spacer(),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: AppColors.ink,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Need a hand?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Our event experts are here to help.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => onSelect('Help Center'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Visit help center →',
                            style: TextStyle(
                              color: AppColors.lilacText,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _NavItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: active == 'Settings',
                  onTap: () => onSelect('Settings'),
                ),
                _NavItem(
                  icon: Icons.logout_rounded,
                  label: 'Sign out',
                  selected: false,
                  onTap: onSignOut,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59756FB8),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Gatherly',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -.5,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : const Color(0x8CFFFFFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 19, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar and page heading
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.wide,
    required this.onMenu,
    required this.onProfile,
  });

  final bool wide;
  final VoidCallback onMenu;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile;
    final showName = MediaQuery.sizeOf(context).width >= 600;
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!wide) ...[
            _SquareButton(
              icon: Icons.menu_rounded,
              tooltip: 'Open menu',
              onTap: onMenu,
            ),
            const SizedBox(width: 12),
          ],
          const Spacer(),
          Stack(
            children: [
              _SquareButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifications',
                onTap: () => showToast(
                  context,
                  'You’re all caught up—no new notifications.',
                ),
              ),
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onProfile,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  InitialsAvatar(
                    initials(profile.name),
                    radius: 18,
                    square: true,
                    foreground: const Color(0xFF7067AD),
                    background: const Color(0xFFE6E2F2),
                  ),
                  if (showName) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Event organizer',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x12000000)),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: AppColors.mutedStrong),
          ),
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.active, required this.onCreate});

  final String active;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final overview = active == 'Overview';

    final eyebrow = overview
        ? formatLongDate(now).toUpperCase()
        : active == 'Help Center'
        ? 'SUPPORT'
        : 'ORGANIZER WORKSPACE';
    final title = overview
        ? '${greeting(now)}, ${state.profile.firstName}.'
        : active;
    final subtitle = switch (active) {
      'Overview' => 'Here’s what’s happening across your events.',
      'Help Center' => 'Find answers or get in touch with the Gatherly team.',
      'Profile' => 'Keep your organizer details accurate and up to date.',
      'Settings' => 'Choose how Gatherly works for you.',
      _ => 'Manage your ${active.toLowerCase()} in one place.',
    };

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0x73000000)),
            ),
          ],
        ),
        if (overview || active == 'Events')
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create event'),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Overview
// ---------------------------------------------------------------------------

class OverviewPanel extends StatelessWidget {
  const OverviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final next = state.nextEvent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Metrics(state: state),
        const SizedBox(height: 24),
        if (next != null) ...[
          _NextUpCard(event: next),
          const SizedBox(height: 24),
        ],
        const EventsPanel(),
      ],
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Kpi(
        'Total revenue',
        formatPeso(state.demoRevenueCentavos),
        '+12.4%',
        Icons.bar_chart_rounded,
        AppColors.kpiPurpleBg,
        AppColors.primary,
      ),
      _Kpi(
        'Tickets sold',
        groupThousands(state.ticketsSold),
        '+8.2%',
        Icons.confirmation_number_outlined,
        AppColors.kpiBlueBg,
        AppColors.kpiBlue,
      ),
      _Kpi(
        'Total attendees',
        groupThousands(state.demoAttendeeCount),
        '+16.8%',
        Icons.people_outline,
        AppColors.kpiGreenBg,
        AppColors.kpiGreen,
      ),
      _Kpi(
        'Active events',
        '${state.activeEvents}',
        '${state.draftEvents} drafts',
        Icons.calendar_month_outlined,
        AppColors.kpiSandBg,
        AppColors.kpiSand,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 1100
            ? 4
            : (box.maxWidth >= 600 ? 2 : 1);
        final width = (box.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final tile in tiles)
              SizedBox(width: width, child: _KpiCard(tile)),
          ],
        );
      },
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value, this.change, this.icon, this.bg, this.fg);

  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color bg;
  final Color fg;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.kpi);

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) {
    final positive = kpi.change.startsWith('+');
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kpi.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(kpi.icon, size: 19, color: kpi.fg),
              ),
              const Icon(Icons.more_horiz, color: Color(0x40000000)),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            kpi.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kpi.value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  kpi.change,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: positive
                        ? const Color(0xFF059669)
                        : const Color(0x59000000),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final info = Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.yellow,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NEXT UP · ${daysUntilLabel(DateTime.now(), event.startAt).toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            event.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _InfoChip(
                Icons.calendar_today_outlined,
                formatDate(event.startAt),
              ),
              _InfoChip(Icons.location_on_outlined, event.venue),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(0, 44),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventDetailsScreen(eventId: event.id),
                  ),
                ),
                label: const Text('Manage event'),
                icon: const Icon(Icons.chevron_right, size: 18),
                iconAlignment: IconAlignment.end,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: '${event.sold} ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: '/ ${event.capacity}',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'tickets sold',
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final photo = Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: .8,
          child: Image.network(
            kEventImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                const ColoredBox(color: AppColors.panel),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.panel, Color(0x33333746), Color(0x00333746)],
              stops: [0, .5, 1],
            ),
          ),
        ),
        const Positioned(
          right: 16,
          bottom: 10,
          child: Text(
            'Photo by Andrii Leonov · Unsplash',
            style: TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ),
      ],
    );

    return Panel(
      color: AppColors.panel,
      padding: EdgeInsets.zero,
      clip: true,
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 150, child: photo),
                info,
              ],
            );
          }
          // The text column decides the height; the photo fills the right side.
          final photoWidth = box.maxWidth * .45;
          return Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: photoWidth,
                child: photo,
              ),
              Padding(
                padding: EdgeInsets.only(right: photoWidth),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 260),
                  child: info,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.lilacText),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
