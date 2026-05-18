import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusttunnel/common/localization/locale_type.dart';

const _kLocaleKey = 'app_locale';

class _LocaleInherited extends InheritedWidget {
  final LocaleScopeState state;
  final Locale? locale;

  const _LocaleInherited({
    required this.state,
    required this.locale,
    required super.child,
  });

  @override
  bool updateShouldNotify(_LocaleInherited old) => locale != old.locale;
}

class LocaleScope extends StatefulWidget {
  final Widget child;
  const LocaleScope({super.key, required this.child});

  static LocaleScopeState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LocaleInherited>()!.state;

  @override
  State<LocaleScope> createState() => LocaleScopeState();
}

class LocaleScopeState extends State<LocaleScope> {
  Locale? _locale; // null = системный язык

  Locale? get locale => _locale;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null) {
      try {
        final type = LocaleType.fromString(saved);
        if (mounted) setState(() => _locale = type.value);
      } catch (_) {}
    }
  }

  Future<void> setLocale(Locale? locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_kLocaleKey);
    } else {
      final type = LocaleType.values.firstWhere(
        (e) => e.value?.languageCode == locale.languageCode,
        orElse: () => LocaleType.system,
      );
      if (type == LocaleType.system) {
        await prefs.remove(_kLocaleKey);
      } else {
        await prefs.setString(_kLocaleKey, type.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) => _LocaleInherited(
    state:  this,
    locale: _locale,
    child:  widget.child,
  );
}
