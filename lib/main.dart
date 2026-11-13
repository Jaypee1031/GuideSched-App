import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'screens/auth/login_screen.dart';
import 'screens/counselor/counselor_appointments_screen.dart';
import 'screens/counselor/counselor_dashboard_screen.dart';
import 'screens/counselor/counselor_feedback_screen.dart';
import 'screens/counselor/counselor_principals_screen.dart';
import 'screens/counselor/counselor_schedule_screen.dart';
import 'screens/counselor/counselor_sections_screen.dart';
import 'screens/counselor/counselor_staff_screen.dart';
import 'screens/counselor/counselor_students_screen.dart';
import 'screens/principal/principal_appointments_screen.dart';
import 'screens/principal/principal_dashboard_screen.dart';
import 'screens/principal/principal_students_screen.dart';
import 'screens/shared/analytics_screen.dart';
import 'screens/shared/notifications_screen.dart';
import 'screens/shared/profile_screen.dart';
import 'screens/shared/reports_screen.dart';
import 'screens/student/student_appointments_screen.dart';
import 'screens/student/student_feedback_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/student/student_insights_screen.dart';
import 'state/session_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  final session = SessionState();
  await session.restore();
  runApp(
    ChangeNotifierProvider<SessionState>.value(
      value: session,
      child: const GuideSchedApp(),
    ),
  );
}

class GuideSchedApp extends StatelessWidget {
  const GuideSchedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuideSched',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionState>();
    if (!session.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!session.isLoggedIn) {
      return const LoginScreen();
    }
    switch (session.role) {
      case 'student':
        return _buildStudentShell();
      case 'counselor':
        return _buildCounselorShell();
      case 'principal':
        return _buildPrincipalShell();
      default:
        return const LoginScreen();
    }
  }

  Widget _buildStudentShell() {
    final destinations = <NavDestination>[
      NavDestination(
        title: 'Home',
        section: 'Student Portal',
        icon: Icons.home_outlined,
        showInBottomBar: true,
        builder: (_) => const StudentHomeScreen(),
      ),
      NavDestination(
        title: 'Appointments',
        section: 'Student Portal',
        icon: Icons.calendar_month_outlined,
        showInBottomBar: true,
        builder: (_) => const StudentAppointmentsScreen(),
      ),
      NavDestination(
        title: 'My Insights',
        section: 'Student Portal',
        icon: Icons.insights_outlined,
        showInBottomBar: true,
        builder: (_) => const StudentInsightsScreen(),
      ),
      NavDestination(
        title: 'Feedback',
        section: 'Student Portal',
        icon: Icons.rate_review_outlined,
        showInBottomBar: true,
        builder: (_) => const StudentFeedbackScreen(),
      ),
      NavDestination(
        title: 'Notifications',
        section: 'Account',
        icon: Icons.notifications_outlined,
        builder: (_) => const NotificationsScreen(),
      ),
      NavDestination(
        title: 'My Profile',
        section: 'Account',
        icon: Icons.person_outline,
        showInBottomBar: true,
        builder: (_) => const ProfileScreen(),
      ),
    ];
    return RoleShell(
      portalLabel: 'Student Portal',
      destinations: destinations,
      notificationsIndex: 4,
      profileIndex: 5,
    );
  }

  Widget _buildCounselorShell() {
    final destinations = <NavDestination>[
      NavDestination(
        title: 'Dashboard',
        section: 'Overview',
        icon: Icons.dashboard_outlined,
        showInBottomBar: true,
        builder: (_) => const CounselorDashboardScreen(),
      ),
      NavDestination(
        title: 'Appointments',
        section: 'Guidance Operations',
        icon: Icons.event_note_outlined,
        showInBottomBar: true,
        builder: (_) => const CounselorAppointmentsScreen(),
      ),
      NavDestination(
        title: 'My Schedule',
        section: 'Guidance Operations',
        icon: Icons.schedule_outlined,
        showInBottomBar: true,
        builder: (_) => const CounselorScheduleScreen(),
      ),
      NavDestination(
        title: 'Students',
        section: 'Records & Directory',
        icon: Icons.people_outline,
        showInBottomBar: true,
        builder: (_) => const CounselorStudentsScreen(),
      ),
      NavDestination(
        title: 'Sections & Tracks',
        section: 'Records & Directory',
        icon: Icons.class_outlined,
        builder: (_) => const CounselorSectionsScreen(),
      ),
      NavDestination(
        title: 'Analytics',
        section: 'Insights & Reports',
        icon: Icons.bar_chart_outlined,
        showInBottomBar: true,
        builder: (_) => const AnalyticsScreen(),
      ),
      NavDestination(
        title: 'Reports',
        section: 'Insights & Reports',
        icon: Icons.summarize_outlined,
        builder: (_) => const ReportsScreen(),
      ),
      NavDestination(
        title: 'Student Feedback',
        section: 'Insights & Reports',
        icon: Icons.reviews_outlined,
        builder: (_) => const CounselorFeedbackScreen(),
      ),
      NavDestination(
        title: 'Counselors & Handover',
        section: 'Administration',
        icon: Icons.supervisor_account_outlined,
        builder: (_) => const CounselorStaffScreen(),
      ),
      NavDestination(
        title: 'Principals',
        section: 'Administration',
        icon: Icons.account_balance_outlined,
        builder: (_) => const CounselorPrincipalsScreen(),
      ),
      NavDestination(
        title: 'Notifications',
        section: 'Account',
        icon: Icons.notifications_outlined,
        builder: (_) => const NotificationsScreen(),
      ),
      NavDestination(
        title: 'My Profile',
        section: 'Account',
        icon: Icons.person_outline,
        builder: (_) => const ProfileScreen(),
      ),
    ];
    return RoleShell(
      portalLabel: 'Counselor Portal',
      destinations: destinations,
      notificationsIndex: 10,
      profileIndex: 11,
    );
  }

  Widget _buildPrincipalShell() {
    final destinations = <NavDestination>[
      NavDestination(
        title: 'Dashboard',
        section: 'Principal Portal',
        icon: Icons.dashboard_outlined,
        showInBottomBar: true,
        builder: (_) => const PrincipalDashboardScreen(),
      ),
      NavDestination(
        title: 'Appointments',
        section: 'Principal Portal',
        icon: Icons.event_note_outlined,
        showInBottomBar: true,
        builder: (_) => const PrincipalAppointmentsScreen(),
      ),
      NavDestination(
        title: 'Student Directory',
        section: 'Principal Portal',
        icon: Icons.people_outline,
        showInBottomBar: true,
        builder: (_) => const PrincipalStudentsScreen(),
      ),
      NavDestination(
        title: 'Analytics',
        section: 'Insights & Reports',
        icon: Icons.bar_chart_outlined,
        showInBottomBar: true,
        builder: (_) => const AnalyticsScreen(),
      ),
      NavDestination(
        title: 'Reports',
        section: 'Insights & Reports',
        icon: Icons.summarize_outlined,
        showInBottomBar: true,
        builder: (_) => const ReportsScreen(),
      ),
      NavDestination(
        title: 'Notifications',
        section: 'Account',
        icon: Icons.notifications_outlined,
        builder: (_) => const NotificationsScreen(),
      ),
      NavDestination(
        title: 'My Profile',
        section: 'Account',
        icon: Icons.person_outline,
        builder: (_) => const ProfileScreen(),
      ),
    ];
    return RoleShell(
      portalLabel: 'Principal Portal',
      destinations: destinations,
      notificationsIndex: 5,
      profileIndex: 6,
    );
  }
}
