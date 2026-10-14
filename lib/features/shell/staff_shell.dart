import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_controller.dart';
import 'adaptive_shell.dart';

class StaffShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const StaffShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AdaptiveShell(navigationShell: navigationShell, destinations: [
      ShellDestination(Icons.login_rounded, Icons.login_rounded, t.navCheckIn),
      ShellDestination(
          Icons.logout_rounded, Icons.logout_rounded, t.navCheckOut),
      ShellDestination(Icons.local_parking_outlined,
          Icons.local_parking_rounded, t.navSessions),
      ShellDestination(
          Icons.report_outlined, Icons.report_rounded, t.navIncidents),
      ShellDestination(
          Icons.person_outline_rounded, Icons.person_rounded, t.navAccount),
    ]);
  }
}
