import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kDarkKey   = 'theme_is_dark';
const _kAmoledKey = 'theme_is_amoled';
const _kColorKey  = 'theme_accent_color';

// ─── InheritedWidget ──────────────────────────────────────────────────────────
class _ThemeInherited extends InheritedWidget {
  final ThemeScopeState state;
  // Копируем значения чтобы updateShouldNotify корректно сравнивал
  final bool isDark;
  final bool isAmoled;
  final Color? accentColor;

  const _ThemeInherited({
    required this.state,
    required this.isDark,
    required this.isAmoled,
    required this.accentColor,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ThemeInherited old) =>
      isDark != old.isDark ||
      isAmoled != old.isAmoled ||
      accentColor != old.accentColor;
}

// ─── Scope ────────────────────────────────────────────────────────────────────
class ThemeScope extends StatefulWidget {
  final Widget child;
  const ThemeScope({super.key, required this.child});

  static ThemeScopeState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ThemeInherited>()!.state;

  @override
  State<ThemeScope> createState() => ThemeScopeState();
}

class ThemeScopeState extends State<ThemeScope> {
  bool   _isDark      = false;
  bool   _isAmoled    = false;
  Color? _accentColor;          // null = Material You (системный цвет)

  bool   get isDark       => _isDark;
  bool   get isAmoled     => _isAmoled;
  Color? get accentColor  => _accentColor;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final colorVal = prefs.getInt(_kColorKey);
    setState(() {
      _isDark      = prefs.getBool(_kDarkKey)   ?? false;
      _isAmoled    = prefs.getBool(_kAmoledKey) ?? false;
      _accentColor = colorVal != null ? Color(colorVal) : null;
    });
  }

  Future<void> setDark(bool value) async {
    setState(() => _isDark = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkKey, value);
  }

  Future<void> setAmoled(bool value) async {
    setState(() => _isAmoled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAmoledKey, value);
  }

  /// null = Material You (системный цвет обоев)
  Future<void> setAccentColor(Color? color) async {
    setState(() => _accentColor = color);
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(_kColorKey);
    } else {
      await prefs.setInt(_kColorKey, color.toARGB32());
    }
  }

  @override
  Widget build(BuildContext context) => _ThemeInherited(
    state:       this,
    isDark:      _isDark,
    isAmoled:    _isAmoled,
    accentColor: _accentColor,
    child:       widget.child,
  );
}
