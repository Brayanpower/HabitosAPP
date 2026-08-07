import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:habitos_app/config/config.dart';
import 'package:habitos_app/config/helpers/wear_sync_service.dart';

class WearPairingDialog extends StatefulWidget {
  const WearPairingDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const WearPairingDialog(),
    );
  }

  @override
  State<WearPairingDialog> createState() => _WearPairingDialogState();
}

class _WearPairingDialogState extends State<WearPairingDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _submitPin(WearSyncService syncService) {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      setState(() {
        _errorMessage = 'Ingresa el código PIN de 4 dígitos';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSuccess = true;
    });

    syncService.confirmPairing(pin);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡PIN $pin confirmado! Sincronizando con el reloj...'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final syncService = context.watch<WearSyncService>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con Icono de Smartwatch
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.watch_rounded,
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
                        'Vincular Wearable',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reloj inteligente Wear OS',
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

            // Estado de Conexión del Servidor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: syncService.isConnected
                    ? AppTheme.success.withValues(alpha: 0.12)
                    : (isDark ? AppTheme.borderDark : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: syncService.isConnected
                      ? AppTheme.success.withValues(alpha: 0.3)
                      : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    syncService.isConnected ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                    color: syncService.isConnected ? AppTheme.success : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncService.isConnected
                              ? 'Reloj Conectado (${syncService.clientCount})'
                              : 'Esperando conexión del reloj',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: syncService.isConnected ? AppTheme.success : null,
                          ),
                        ),
                        Text(
                          'Servidor: ${syncService.localIp}:${syncService.port}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (syncService.isConnected)
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, size: 20, color: AppTheme.primary),
                      tooltip: 'Sincronizar ahora',
                      onPressed: () {
                        syncService.broadcastHabits();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Hábitos sincronizados con el reloj'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Instrucción y Campo de PIN
            Text(
              'Ingresa el código PIN de 4 dígitos que aparece en la pantalla de tu reloj:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: TextStyle(
                  color: Colors.grey.withValues(alpha: 0.4),
                  letterSpacing: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.error, fontSize: 12),
              ),
            ],

            const SizedBox(height: 22),

            // Botón de Confirmación
            FilledButton.icon(
              onPressed: _isSuccess ? null : () => _submitPin(syncService),
              icon: _isSuccess
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.link_rounded),
              label: Text(_isSuccess ? 'Vinculando...' : 'Vincular Reloj'),
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
