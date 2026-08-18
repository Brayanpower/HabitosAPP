import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/presentation/providers/auth_provider.dart';
import 'package:habitos_app/presentation/widgets/qr_pairing_scanner.dart';

class TvPairingDialog extends StatefulWidget {
  const TvPairingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const TvPairingDialog(),
    );
  }

  @override
  State<TvPairingDialog> createState() => _TvPairingDialogState();
}

class _TvPairingDialogState extends State<TvPairingDialog> {
  bool _isSuccess = false;
  String? _errorMessage;

  Future<void> _scanQr(AuthProvider authProvider) async {
    final result = await Navigator.of(context).push<DeviceLoginResult>(
      MaterialPageRoute(
        builder: (_) => const QrPairingScanner(
          expectedPrefix: 'VITALHABIT:TV:',
          title: 'Escanear QR de la TV',
          subtitle: 'Apunta la cámara al código QR que muestra tu Smart TV',
        ),
      ),
    );
    if (result == null || !mounted) return;

    final user = authProvider.user;
    if (user == null) {
      setState(() {
        _errorMessage = 'Inicia sesión en la app para vincular tu TV';
      });
      return;
    }

    try {
      // Escribir la sesión de login de la TV en Firestore
      await FirebaseFirestore.instance
          .collection('tv_sessions')
          .doc(result.deviceId)
          .set({
        'userId': user.id,
        'userName': user.name,
        'deviceName': 'Smart TV',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _errorMessage = null;
        _isSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡TV vinculada con éxito!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'No se pudo vincular la TV: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con Icono de TV
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.tv_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vincular Smart TV',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Televisor / Pantalla Inteligente',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Instrucción
            Text(
              'En la TV se muestra un código QR. Escanéalo para autorizarla y ver tus estadísticas en pantalla grande.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],

            // Escanear QR de la TV
            FilledButton.icon(
              onPressed: _isSuccess
                  ? null
                  : () => _scanQr(authProvider),
              icon: _isSuccess
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
              label: Text(_isSuccess ? 'Vinculando...' : 'Escanear QR de la TV'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
