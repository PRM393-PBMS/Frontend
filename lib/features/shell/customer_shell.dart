import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale_controller.dart';
import 'adaptive_shell.dart';

class CustomerShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const CustomerShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return AdaptiveShell(navigationShell: navigationShell, destinations: [
      ShellDestination(Icons.home_outlined, Icons.home_rounded, t.navHome),
      ShellDestination(Icons.receipt_long_outlined, Icons.receipt_long_rounded,
          t.navHistory),
      ShellDestination(Icons.directions_car_outlined,
          Icons.directions_car_rounded, t.navPasses),
      ShellDestination(
          Icons.person_outline_rounded, Icons.person_rounded, t.navAccount),
    ]);
  }
}
