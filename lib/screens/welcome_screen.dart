
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

const Color gatherlyBlue = Color(0xFF6670B8);
const Color gatherlyInk = Color(0xFF2D3142);
const Color gatherlyYellow = Color(0xFFF4DFA6);

class WelcomeScreen extends StatelessWidget {
  WelcomeScreen({super.key});

  void _showAuthDialog(
    BuildContext context, {
    required bool isRegister,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x990D1020),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight:
                    MediaQuery.of(dialogContext).size.height * 0.85,
              ),
              child: Material(
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 12, 8),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 13,
                            backgroundColor: gatherlyInk,
                            child: Icon(
                              Icons.event_available_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Gatherly',
                            style: TextStyle(
                              color: gatherlyInk,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Close',
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, size: 19),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          22, 20, 22, 18,
                        ),
                        child: isRegister
                            ? RegisterScreen(
                                isDialog: true,
                                onSwitchToLogin: () {
                                  Navigator.of(dialogContext).pop();
                                  _showAuthDialog(
                                    context,
                                    isRegister: false,
                                  );
                                },
                                onSuccess: () {
                                  Navigator.of(dialogContext).pop();
                                  Navigator.of(context)
                                      .pushNamedAndRemoveUntil(
                                    '/dashboard',
                                    (route) => false,
                                  );
                                },
                              )
                            : LoginScreen(
                                isDialog: true,
                                onSwitchToRegister: () {
                                  Navigator.of(dialogContext).pop();
                                  _showAuthDialog(
                                    context,
                                    isRegister: true,
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 700;
            final horizontalPadding =
                isWide ? 48.0 : (width < 360 ? 16.0 : 24.0);

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top navigation
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding, 12,
                          horizontalPadding, 20,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              color: gatherlyBlue,
                              size: 27,
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Gatherly',
                              style: TextStyle(
                                color: gatherlyInk,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _showAuthDialog(
                                context,
                                isRegister: false,
                              ),
                              child: const Text('Sign In'),
                            ),
                            const SizedBox(width: 5),
                            FilledButton(
                              onPressed: () => _showAuthDialog(
                                context,
                                isRegister: true,
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: gatherlyBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ],
                        ),
                      ),

                      // Dashboard preview
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: horizontalPadding * 0.65,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF292A38),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Color(0xFFEAEAF8),
                                    child: Icon(
                                      Icons.confirmation_num_outlined,
                                      color: gatherlyBlue,
                                      size: 17,
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'UPCOMING EVENT',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.black54,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Manila Creatives Summit 2025',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: gatherlyInk,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.notifications_none_rounded,
                                    size: 18,
                                    color: gatherlyBlue,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Container(
                              width: double.infinity,
                              height: 155,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF5440A0),
                                    Color(0xFF24263D),
                                    Color(0xFF171A2B),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Expanded(
                                    child: Center(
                                      child: Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFFBCA4FF),
                                        size: 34,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gatherlyYellow,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'ON SALE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: gatherlyInk,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    '342 tickets sold',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    '68% of ticket capacity reached',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Expanded(
                                  child: _statCard(
                                    icon: Icons.payments_outlined,
                                    title: '₱2.8M',
                                    subtitle: 'Revenue earned',
                                    color: const Color(0xFFF3DDD6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _statCard(
                                    icon: Icons.groups_outlined,
                                    title: '1,546',
                                    subtitle: 'Happy attendees',
                                    color: const Color(0xFFDCEBE4),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // City names
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: isWide ? 32 : 20,
                          runSpacing: 12,
                          children: [
                            _city('MANILA'),
                            _city('CEBU'),
                            _city('DAVAO'),
                            _city('ILOILO'),
                            _city('BAGUIO'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 42),

                      // Introduction
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'ONE PLATFORM. EVERY DETAIL.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: gatherlyBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Smart tools that power\nevery event',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: gatherlyInk,
                                fontSize: isWide ? 34 : 27,
                                height: 1.12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'From the first invitation to the final report, '
                              'Gatherly keeps your team focused and your '
                              'guests delighted.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                height: 1.65,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Feature cards
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding * 0.65,
                        ),
                        child: isWide
                            ? Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _featureCard(
                                      number: '01',
                                      title: 'Plan without the chaos',
                                      description:
                                          'Build schedules, manage venues, '
                                          'and organize every detail in '
                                          'one place.',
                                      color: const Color(0xFFE0EBDD),
                                      icon: Icons.event_note_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _featureCard(
                                      number: '02',
                                      title: 'Sell with confidence',
                                      description:
                                          'Manage ticket types, monitor '
                                          'sales, and keep every transaction '
                                          'organized.',
                                      color: const Color(0xFFE0E7F3),
                                      icon:
                                          Icons.confirmation_num_rounded,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _featureCard(
                                      number: '03',
                                      title: 'Learn from every moment',
                                      description:
                                          'Track event performance and use '
                                          'meaningful insights to plan '
                                          'what comes next.',
                                      color: const Color(0xFFF5E0D9),
                                      icon: Icons.insights_rounded,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _featureCard(
                                    number: '01',
                                    title: 'Plan without the chaos',
                                    description:
                                        'Build schedules, manage venues, '
                                        'and organize every detail in '
                                        'one place.',
                                    color: const Color(0xFFE0EBDD),
                                    icon: Icons.event_note_rounded,
                                  ),
                                  const SizedBox(height: 14),
                                  _featureCard(
                                    number: '02',
                                    title: 'Sell with confidence',
                                    description:
                                        'Manage ticket types, monitor '
                                        'sales, and keep every transaction '
                                        'organized.',
                                    color: const Color(0xFFE0E7F3),
                                    icon: Icons.confirmation_num_rounded,
                                  ),
                                  const SizedBox(height: 14),
                                  _featureCard(
                                    number: '03',
                                    title: 'Learn from every moment',
                                    description:
                                        'Track event performance and use '
                                        'meaningful insights to plan '
                                        'what comes next.',
                                    color: const Color(0xFFF5E0D9),
                                    icon: Icons.insights_rounded,
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 32),

                      // Dark footer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(
                          22, 38, 22, 28,
                        ),
                        color: gatherlyInk,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BUILT FOR REAL TEAMS',
                              style: TextStyle(
                                color: Color(0xFFCDD0E1),
                                fontSize: 9,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your entire event\noperation, in your pocket.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'React on the web and Flutter on mobile share '
                              'the same intuitive flow—so organizers can '
                              'create, update, search, and monitor events '
                              'anywhere.',
                              style: TextStyle(
                                color: Color(0xFFB6B9C8),
                                fontSize: 11,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _footerInfoCard(
                              title: 'Protected access',
                              description:
                                  'JWT-ready routes and secure API patterns.',
                            ),
                            const SizedBox(height: 12),
                            _footerInfoCard(
                              title: 'Reliable data',
                              description:
                                  'Validated forms and MongoDB-ready models.',
                            ),
                            const SizedBox(height: 28),

                            // Mobile dashboard preview
                            Center(
                              child: Container(
                                width: 270,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: gatherlyBlue,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(0xFF858CD0),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 4,
                                      margin: const EdgeInsets.only(
                                        top: 2,
                                        bottom: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF969DDC),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F7F2),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Good morning',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ),
                                              CircleAvatar(
                                                radius: 10,
                                                backgroundColor:
                                                    gatherlyYellow,
                                                child: Text(
                                                  'CS',
                                                  style: TextStyle(
                                                    fontSize: 7,
                                                    color: gatherlyInk,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Text(
                                            'Your events',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: gatherlyInk,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding:
                                                const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: gatherlyInk,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'NEXT EVENT',
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 7,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Text(
                                                  'Manila Creatives Summit 2025',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '342',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 19,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.only(
                                                        bottom: 3,
                                                      ),
                                                      child: Text(
                                                        'tickets sold',
                                                        style: TextStyle(
                                                          color:
                                                              Colors.white60,
                                                          fontSize: 8,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 34,
                                            child: FilledButton(
                                              onPressed: null,
                                              style:
                                                  FilledButton.styleFrom(
                                                backgroundColor:
                                                    gatherlyBlue,
                                                foregroundColor:
                                                    Colors.white,
                                                disabledBackgroundColor:
                                                    gatherlyBlue,
                                                disabledForegroundColor:
                                                    Colors.white,
                                                shape:
                                                    RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    8,
                                                  ),
                                                ),
                                              ),
                                              child: const Text(
                                                'Open dashboard',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 38),
                            const Divider(
                              color: Color(0xFF45495A),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.event_available_rounded,
                                          color: gatherlyBlue,
                                          size: 15,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Gatherly',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Made in the Philippines by the Gatherly team.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF9296A8),
                                      fontSize: 8,
                                      height: 1.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: gatherlyInk),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: gatherlyInk,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: gatherlyInk,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _city(String name) {
    return Text(
      name,
      style: const TextStyle(
        color: Color(0xFF777887),
        fontSize: 10,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _featureCard({
    required String number,
    required String title,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: gatherlyInk, size: 21),
              ),
              const Spacer(),
              Text(
                number,
                style: const TextStyle(
                  color: gatherlyInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: gatherlyInk,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF555766),
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerInfoCard({
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF383D50),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF484D60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFFB6B9C8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}