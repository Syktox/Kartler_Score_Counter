import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_constants.dart';
import '../features/home/home_page.dart';
import '../models/app_mode.dart';
import 'theme/app_theme.dart';

/// Wurzel-Widget der App.
///
/// Verwaltet nur noch Theme-Modus und System-UI; die gesamte Fachlogik
/// liegt in den Feature-Controllern der [HomePage].
class KartlerApp extends StatefulWidget {
  const KartlerApp({super.key});

  @override
  State<KartlerApp> createState() => _KartlerAppState();
}

class _KartlerAppState extends State<KartlerApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  AppMode _appMode = AppMode.watten;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncKeyboardState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncKeyboardState();
    }
  }

  void _syncKeyboardState() {
    unawaited(HardwareKeyboard.instance.syncKeyboardState());
  }

  void _updateThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    setState(() {
      _themeMode = mode;
    });
  }

  void _updateAppMode(AppMode mode) {
    if (_appMode == mode) {
      return;
    }
    setState(() {
      _appMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.name,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarDividerColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: HomePage(
        themeMode: _themeMode,
        onThemeModeChanged: _updateThemeMode,
        appMode: _appMode,
        onAppModeChanged: _updateAppMode,
      ),
    );
  }
}
