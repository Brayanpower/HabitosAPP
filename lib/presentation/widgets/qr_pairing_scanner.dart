import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DeviceLoginResult {
  final String deviceId;
  final String? token;

  const DeviceLoginResult({required this.deviceId, this.token});
}

class QrPairingScanner extends StatefulWidget {
  final String expectedPrefix;
  final String title;
  final String subtitle;

  const QrPairingScanner({
    super.key,
    this.expectedPrefix = 'VITALHABIT:LOGIN:',
    this.title = 'Escanear QR del reloj',
    this.subtitle = 'Apunta la cámara al código QR que muestra tu reloj',
  });

  @override
  State<QrPairingScanner> createState() => _QrPairingScannerState();
}

class _QrPairingScannerState extends State<QrPairingScanner> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      if (raw.startsWith(widget.expectedPrefix)) {
        final payload = raw.substring(widget.expectedPrefix.length);
        final parts = payload.split(':');
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          _handled = true;
          Navigator.of(context).pop(DeviceLoginResult(
            deviceId: parts[0],
            token: parts.length > 1 ? parts[1] : null,
          ));
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
