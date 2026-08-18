import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WearLoginResult {
  final String deviceId;
  final String token;

  const WearLoginResult({required this.deviceId, required this.token});
}

class QrPairingScanner extends StatefulWidget {
  const QrPairingScanner({super.key});

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

      // Formato esperado: VITALHABIT:LOGIN:<deviceId>:<token>
      if (raw.startsWith('VITALHABIT:LOGIN:')) {
        final parts = raw.substring('VITALHABIT:LOGIN:'.length).split(':');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          _handled = true;
          Navigator.of(context).pop(WearLoginResult(
            deviceId: parts[0],
            token: parts[1],
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
        title: const Text('Escanear QR del reloj'),
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
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Apunta la cámara al código QR que muestra tu reloj',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
