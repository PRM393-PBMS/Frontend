import '../../core/l10n/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/routes/route_names.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/state_views.dart';
import '../auth/presentation/blocs/auth_bloc.dart';
import '../auth/presentation/blocs/auth_event.dart';

/// Tài khoản có vai trò ứng dụng di động chưa hỗ trợ (vd. Admin).
class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyState(
                  icon: Icons.admin_panel_settings_outlined,
                  title: context.l10n.unsupportedTitle,
                  message: context.l10n.unsupportedMessage(
                      user?.email ?? '', user?.roleName ?? ''),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: AppButton.secondary(
                    label: context.l10n.commonLogout,
                    icon: Icons.logout_rounded,
                    onPressed: () =>
                        context.read<AuthBloc>().add(AuthLogoutRequested()),
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

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: EmptyState(
          icon: Icons.explore_off_outlined,
          title: context.l10n.notFoundTitle,
          message: context.l10n.notFoundMessage,
          actionLabel: context.l10n.notFoundAction,
          onAction: () => context.go(RouteNames.splash),
        ),
      ),
    );
  }
}
