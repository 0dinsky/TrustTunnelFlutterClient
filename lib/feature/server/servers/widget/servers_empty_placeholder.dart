import 'package:flutter/material.dart';
import 'package:trusttunnel/common/assets/assets_images.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/feature/server/server_details/widgets/server_details_popup.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope.dart';
import 'package:trusttunnel/feature/server/servers/widget/tt_import_dialog.dart';
import 'package:trusttunnel/widgets/default_page.dart';

class ServersEmptyPlaceholder extends StatelessWidget {
  const ServersEmptyPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: DefaultPage(
          title: context.ln.serversEmptyTitle,
          descriptionText: context.ln.serversEmptyDescription,
          imagePath: AssetImages.server,
          imageSize: const Size.square(248),
          buttonText: context.ln.create,
          onButtonPressed: () => _pushServerDetailsScreen(context),
          alignment: Alignment.center,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: OutlinedButton.icon(
          onPressed: () => _showTtImportDialog(context),
          icon: const Icon(Icons.link, size: 18),
          label: const Text('Импортировать по ссылке tt://'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
    ],
  );

  void _showTtImportDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => TtImportDialog(
        onImport: (link) async {
          final uri = Uri.tryParse(link.trim());
          if (uri == null) return;
          try {
            final parsed = await context.repositoryFactory.deepLinkRepository.parseDataFromLink(
              deepLink: uri.toString(),
            );
            if (context.mounted) {
              final controller = ServersScope.controllerOf(context, listen: false);
              await context.push(ServerDetailsPopUp.preloaded(preloadedData: parsed));
              controller.fetchServers();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ошибка: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _pushServerDetailsScreen(BuildContext context) async {
    final controller = ServersScope.controllerOf(context, listen: false);
    await context.push(const ServerDetailsPopUp());
    controller.fetchServers();
  }
}