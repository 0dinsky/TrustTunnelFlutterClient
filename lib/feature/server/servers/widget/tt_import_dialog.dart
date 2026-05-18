import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TtImportDialog extends StatefulWidget {
  final void Function(String link) onImport;

  const TtImportDialog({super.key, required this.onImport});

  @override
  State<TtImportDialog> createState() => _TtImportDialogState();
}

class _TtImportDialogState extends State<TtImportDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _tryPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _controller.text = data!.text!;
      setState(() => _error = null);
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Вставьте ссылку');
      return;
    }
    if (!text.startsWith('tt://')) {
      setState(() => _error = 'Ссылка должна начинаться с tt://');
      return;
    }
    Navigator.of(context).pop();
    widget.onImport(text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Импорт сервера'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Вставьте ссылку формата tt://?...',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'tt://?AAEB...',
            errorText: _error,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.content_paste),
              tooltip: 'Вставить из буфера',
              onPressed: _tryPaste,
            ),
          ),
          onChanged: (_) => setState(() => _error = null),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
      FilledButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.download, size: 18),
        label: const Text('Импортировать'),
      ),
    ],
  );
}
