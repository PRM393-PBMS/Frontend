import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'core/l10n/locale_controller.dart';
import 'core/routes/app_router.dart';
import 'core/security/app_lock_gate.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'l10n/app_localizations.dart';

class ParkingApp extends StatefulWidget {
  final bool showOnboarding;

  const ParkingApp({super.key, required this.showOnboarding});

  @override
  State<ParkingApp> createState() => _ParkingAppState();
}

class _ParkingAppState extends State<ParkingApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router =
        AppRouter.createRouter(context.read<AuthBloc>(), widget.showOnboarding);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance.localeNotifier,
      builder: (context, locale, _) {
        Intl.defaultLocale = locale.languageCode;
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance.themeModeNotifier,
          builder: (context, mode, _) => MaterialApp.router(
            onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,
            routerConfig: _router,
            builder: (context, child) =>
                AppLockGate(child: child ?? const SizedBox.shrink()),
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
          ),
        );
      },
    );
  }
}
