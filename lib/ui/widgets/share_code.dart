import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';

/// Muestra un código para compartir: QR para escanear con la app y botón para
/// copiarlo y mandarlo por WhatsApp, correo, etc.
Future<void> showShareCodeSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String code,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final loc = AppLocalizations.of(ctx);
      final theme = Theme.of(ctx);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: code,
                  size: 260,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.L,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.copy),
                label: Text(loc.shareCopyCode),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text(loc.shareCopied)));
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                loc.shareHowTo,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Pide un código: pegarlo o escanear el QR. Devuelve el texto o null.
Future<String?> askForCode(BuildContext context, {required String title}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _CodeInput(title: title),
  );
}

class _CodeInput extends StatefulWidget {
  const _CodeInput({required this.title});

  final String title;

  @override
  State<_CodeInput> createState() => _CodeInputState();
}

class _CodeInputState extends State<_CodeInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _ctrl.text = data!.text!;
  }

  Future<void> _scan() async {
    final code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScanScreen()));
    if (code != null && mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(loc.shareScanQr),
              onPressed: _scan,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: loc.sharePasteLabel,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: loc.sharePaste,
                  icon: const Icon(Icons.content_paste),
                  onPressed: _paste,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(_ctrl.text),
              child: Text(loc.shareImport),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cámara para leer un QR de Plate Calc.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.shareScanQr)),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_done) return;
              for (final b in capture.barcodes) {
                final v = b.rawValue;
                if (v != null && v.startsWith('PC')) {
                  _done = true;
                  Navigator.of(context).pop(v);
                  return;
                }
              }
            },
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(loc.shareCameraError, textAlign: TextAlign.center),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
