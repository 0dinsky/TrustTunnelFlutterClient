import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';

const _kSpeedNotifKey = 'speed_notification_enabled';

class NotificationTile extends StatefulWidget {
  const NotificationTile({super.key});

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(_kSpeedNotifKey) ?? false;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSpeedNotifKey, value);
    if (mounted) {
      try {
        await context.repositoryFactory.vpnRepository
            .setSpeedNotificationEnabled(enabled: value);
      } catch (_) {
        // VPN может быть не запущен — настройка применится при следующем старте
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: const Icon(Icons.speed),
      title: Text(context.ln.speedNotificationTitle),
      subtitle: Text(context.ln.speedNotificationSubtitle),
      value: _enabled,
      onChanged: _toggle,
    );
  }
}
