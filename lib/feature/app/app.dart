import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/common/theme/amoled_theme.dart';
import 'package:trusttunnel/common/theme/dark_theme.dart';
import 'package:trusttunnel/common/theme/light_theme.dart';
import 'package:trusttunnel/feature/locale/locale_scope.dart';
import 'package:trusttunnel/feature/navigation/navigation_screen.dart';
import 'package:trusttunnel/feature/theme/theme_scope.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeScope  = ThemeScope.of(context);
    final localeScope = LocaleScope.of(context);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // ── Определяем seed цвет ──────────────────────────────────────────
        // Если пользователь выбрал цвет — используем его.
        // Иначе берём dominant цвет из обоев через dynamic_color.
        // Fallback — оригинальный синий AdGuard.
        final Color seed;
        if (themeScope.accentColor != null) {
          seed = themeScope.accentColor!;
        } else if (lightDynamic != null) {
          // harmonized() убирает артефакты насыщенности
          seed = lightDynamic.harmonized().primary;
        } else {
          seed = const Color(0xFF4F8AC4);
        }

        // ── Темы ──────────────────────────────────────────────────────────
        final lightTheme = context.dependencyFactory.lightThemeData.copyWith(
          primaryColor: seed,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.light,
          ),
        );

        final ThemeData darkTheme = themeScope.isAmoled
            ? AmoledTheme(accent: seed).data
            : DarkTheme(accent: seed).data;

        return MaterialApp(
          theme:                  lightTheme,
          darkTheme:              darkTheme,
          themeMode:              themeScope.themeMode,
          locale:                 localeScope.locale ?? Localization.defaultLocale,
          localizationsDelegates: Localization.localizationDelegates,
          supportedLocales:       Localization.supportedLocales,
          title:                  'TrustTunnel',
          home: const _Root(),
        );
      },
    );
  }
}

// ── Корневой виджет с правильной строкой состояния ────────────────────────────
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final isAmoled = ThemeScope.of(context).isAmoled;
    final bg       = Theme.of(context).scaffoldBackgroundColor;

    // AMOLED: делаем строку состояния слегка отличимой от чёрного фона
    // через полупрозрачный белый оверлей, либо edge-to-edge transparent
    final statusColor = isAmoled
        ? Colors.white.withValues(alpha: 0.05)  // едва заметная граница
        : Colors.transparent;                    // остальные темы — прозрачная

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor:           statusColor,
        statusBarBrightness:      isDark ? Brightness.dark  : Brightness.light,
        statusBarIconBrightness:  isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: bg,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: const NavigationScreen(),
    );
  }
}
