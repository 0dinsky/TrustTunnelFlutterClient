import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/locale_type.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/common/utils/url_utils.dart';
import 'package:trusttunnel/feature/locale/locale_scope.dart';
import 'package:trusttunnel/feature/settings/excluded_routes/widgets/excluded_routes_screen.dart';
import 'package:trusttunnel/feature/settings/query_log/widgets/query_log_screen.dart';
import 'package:trusttunnel/feature/settings/settings_about/about_screen.dart';
import 'package:trusttunnel/feature/theme/theme_scope.dart';
import 'package:trusttunnel/widgets/common/custom_arrow_list_tile.dart';
import 'package:trusttunnel/widgets/custom_app_bar.dart';
import 'package:trusttunnel/widgets/scaffold_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => ScaffoldWrapper(
    child: Scaffold(
      appBar: CustomAppBar(title: context.ln.settings),
      body: ListView(
        children: [
          CustomArrowListTile(
            title: context.ln.queryLog,
            onTap: () => context.push(const QueryLogScreen()),
          ),
          const Divider(),
          CustomArrowListTile(
            title: context.ln.excludedRoutes,
            onTap: () => context.push(const ExcludedRoutesScreen()),
          ),
          const Divider(),
          const _AppearanceSection(),
          const _LanguageTile(),
          const Divider(),
          CustomArrowListTile(
            title: context.ln.followUsOnGithub,
            onTap: () => UrlUtils.openWebPage(UrlUtils.githubTrustTunnelTeam),
          ),
          const Divider(),
          CustomArrowListTile(
            title: context.ln.about,
            onTap: () => context.push(const AboutScreen()),
          ),
        ],
      ),
    ),
  );
}

// ─── Блок внешнего вида ───────────────────────────────────────────────────────
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final scope = ThemeScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'Внешний вид',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        // ── Светлая / Тёмная ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.brightness_6, size: 20),
              const SizedBox(width: 12),
              const Text('Тема'),
              const Spacer(),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Светлая'), icon: Icon(Icons.light_mode, size: 16)),
                  ButtonSegment(value: true,  label: Text('Тёмная'),  icon: Icon(Icons.dark_mode,  size: 16)),
                ],
                selected: {scope.isDark},
                onSelectionChanged: (v) => scope.setDark(v.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        // ── AMOLED ────────────────────────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: scope.isDark
              ? SwitchListTile(
                  secondary: const Icon(Icons.nights_stay),
                  title: const Text('AMOLED'),
                  subtitle: const Text('Чисто чёрный фон'),
                  value: scope.isAmoled,
                  onChanged: scope.setAmoled,
                  dense: true,
                )
              : const SizedBox.shrink(),
        ),
        // ── Цвет акцента ──────────────────────────────────────────────────
        const _AccentColorPicker(),
        const Divider(),
      ],
    );
  }
}

// ─── Палитра + произвольный цвет ─────────────────────────────────────────────
class _AccentColorPicker extends StatelessWidget {
  const _AccentColorPicker();

  static const _presets = <Color>[
    Color(0xFF4F8AC4), // оригинальный синий
    Color(0xFF6750A4), // Material 3 purple
    Color(0xFF006971), // teal
    Color(0xFF006E1C), // green
    Color(0xFFBF360C), // deep orange
    Color(0xFFC62828), // red
    Color(0xFF0D47A1), // blue
    Color(0xFFF57F17), // amber
    Color(0xFFFFFFFF), // белый
    Color(0xFF000000), // чёрный
  ];

  @override
  Widget build(BuildContext context) {
    final scope = ThemeScope.of(context);
    // Цвет считается кастомным если не совпадает ни с одним пресетом
    final isCustom = scope.accentColor != null &&
        !_presets.contains(scope.accentColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.palette, size: 20),
            SizedBox(width: 12),
            Text('Цвет акцента'),
          ]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Material You
                _ColorCircle(
                  color: Theme.of(context).colorScheme.primary,
                  isSelected: scope.accentColor == null,
                  onTap: () => scope.setAccentColor(null),
                  child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                // Пресеты
                ..._presets.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ColorCircle(
                    color: c,
                    isSelected: scope.accentColor == c,
                    onTap: () => scope.setAccentColor(c),
                    hasBorder: c == Colors.white || c == Colors.black,
                  ),
                )),
                // Кнопка произвольного цвета
                _ColorCircle(
                  color: isCustom ? scope.accentColor! : Colors.grey.shade400,
                  isSelected: isCustom,
                  onTap: () => _showColorPicker(context, scope),
                  child: Icon(
                    Icons.colorize,
                    size: 16,
                    color: isCustom
                        ? (ThemeData.estimateBrightnessForColor(scope.accentColor!) == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            scope.accentColor == null
                ? 'Цвет обоев (Material You)'
                : isCustom
                    ? 'Свой цвет: #${scope.accentColor!.toARGB32().toRadixString(16).substring(2).toUpperCase()}'
                    : '#${scope.accentColor!.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, ThemeScopeState scope) {
    // Начальное состояние пикера
    final initial = scope.accentColor ?? const Color(0xFF4F8AC4);
    int r = initial.r.toInt();
    int g = initial.g.toInt();
    int b = initial.b.toInt();

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final preview = Color.fromRGBO(r, g, b, 1);
          final hexStr = preview.toARGB32().toRadixString(16).substring(2).toUpperCase();
          final isDarkColor = ThemeData.estimateBrightnessForColor(preview) == Brightness.dark;

          return AlertDialog(
            title: const Text('Свой цвет'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Превью
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '#$hexStr',
                      style: TextStyle(
                        color: isDarkColor ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // R
                _SliderRow(label: 'R', value: r, color: Colors.red,
                  onChanged: (v) => setState(() => r = v)),
                // G
                _SliderRow(label: 'G', value: g, color: Colors.green,
                  onChanged: (v) => setState(() => g = v)),
                // B
                _SliderRow(label: 'B', value: b, color: Colors.blue,
                  onChanged: (v) => setState(() => b = v)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () {
                  scope.setAccentColor(Color.fromRGBO(r, g, b, 1));
                  Navigator.of(ctx).pop();
                },
                child: const Text('Применить'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 16,
        child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: 0,
          max: 255,
          divisions: 255,
          activeColor: color,
          onChanged: (v) => onChanged(v.round()),
        ),
      ),
      SizedBox(
        width: 32,
        child: Text('$value',
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          textAlign: TextAlign.right),
      ),
    ],
  );
}

// ─── Кружок цвета ─────────────────────────────────────────────────────────────
class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;
  final bool hasBorder;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.child,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
            : hasBorder
                ? Border.all(color: Theme.of(context).colorScheme.outline, width: 1)
                : null,
        boxShadow: [BoxShadow(
          color: color == Colors.black
              ? Colors.white.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.4),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )],
      ),
      child: isSelected
          ? Center(child: child ?? Icon(Icons.check, size: 18,
              color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                  ? Colors.white : Colors.black))
          : child != null ? Center(child: child) : null,
    ),
  );
}

// ─── Выбор языка ──────────────────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  const _LanguageTile();

  static const _supported = [
    (LocaleType.system, '🌐', 'Системный'),
    (LocaleType.ru,     '🇷🇺', 'Русский'),
    (LocaleType.en,     '🇬🇧', 'English'),
  ];

  String _currentLabel(Locale? locale) {
    if (locale == null) return '🌐 Системный';
    for (final entry in _supported) {
      if (entry.$1.value?.languageCode == locale.languageCode) {
        return '${entry.$2} ${entry.$3}';
      }
    }
    return '🌐 Системный';
  }

  @override
  Widget build(BuildContext context) {
    final scope = LocaleScope.of(context);
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Язык'),
      subtitle: Text(_currentLabel(scope.locale)),
      onTap: () => _showDialog(context, scope),
    );
  }

  void _showDialog(BuildContext context, LocaleScopeState scope) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Выбрать язык'),
        children: _supported.map((entry) {
          final locType    = entry.$1;
          final flag       = entry.$2;
          final name       = entry.$3;
          final isSelected = locType == LocaleType.system
              ? scope.locale == null
              : scope.locale?.languageCode == locType.value?.languageCode;
          return SimpleDialogOption(
            onPressed: () {
              scope.setLocale(locType.value);
              Navigator.of(ctx).pop();
            },
            child: Row(
              children: [
                Text(flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(name, style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                )),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary, size: 18),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
