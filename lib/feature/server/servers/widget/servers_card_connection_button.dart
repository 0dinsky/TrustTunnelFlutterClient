import 'package:flutter/material.dart';
import 'package:trusttunnel/common/assets/asset_icons.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/extensions/theme_extensions.dart';
import 'package:trusttunnel/data/model/vpn_state.dart';
import 'package:trusttunnel/widgets/buttons/custom_icon_button.dart';
import 'package:trusttunnel/widgets/rotating_wrapper.dart';

class ServersCardConnectionButton extends StatelessWidget {
  final VpnState vpnManagerState;
  final VoidCallback onPressed;
  final String serverId;

  const ServersCardConnectionButton({
    super.key,
    required this.serverId,
    required this.vpnManagerState,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool pending = isPendingResult(vpnManagerState);
    final bool connected = vpnManagerState == VpnState.connected;

    final ext = context.theme.extension<CustomFilledIconButtonTheme>()!;
    final themeStyle = (pending ? ext.iconButtonInProgress : ext.iconButton).style;

    // Явно резолвим цвет иконки — не полагаемся на IconTheme cascade от IconButton,
    // который ломается когда CustomIcon строится до оборачивания виджета темой.
    final Set<WidgetState> states = {
      if (pending || connected) WidgetState.selected,
    };
    final Color iconColor =
        themeStyle?.foregroundColor?.resolve(states) ??
        context.theme.iconTheme.color ??
        Colors.white;

    return Theme(
      data: context.theme.copyWith(iconButtonTheme: pending ? ext.iconButtonInProgress : ext.iconButton),
      child: pending
          ? RotatingWidget(
              duration: const Duration(seconds: 1),
              child: CustomIconButton.square(
                icon: AssetIcons.update,
                color: iconColor,
                onPressed: onPressed,
                size: 24,
                selected: true,
              ),
            )
          : CustomIconButton.square(
              icon: AssetIcons.powerSettingsNew,
              color: iconColor,
              onPressed: onPressed,
              size: 24,
              selected: connected,
            ),
    );
  }

  bool isPendingResult(VpnState state) => state != VpnState.connected && state != VpnState.disconnected;
}
