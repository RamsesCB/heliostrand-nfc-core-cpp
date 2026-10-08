import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/update_policy_service.dart';

/// Puerta de entrada: impide navegar con versionCode inferior al minimo remoto.
class VersionGate extends StatefulWidget {
  const VersionGate({super.key, required this.child});

  final Widget child;

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {
  late Future<bool> _requiresUpdate = const UpdatePolicyService()
      .requiresUpdate();

  void _retry() {
    setState(() {
      _requiresUpdate = const UpdatePolicyService().requiresUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sin endpoint configurado, no se publica una promesa falsa de force-update.
    if (versionPolicyUrl.isEmpty) return widget.child;

    return PopScope(
      canPop: false,
      child: FutureBuilder<bool>(
        future: _requiresUpdate,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48),
                      const SizedBox(height: 16),
                      const Text('No se pudo verificar la version de la app.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _retry,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (snapshot.data != true) return widget.child;
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.system_update, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Actualizacion obligatoria',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Debes instalar la version mas reciente para continuar.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => launchUrl(
                        Uri.https('play.google.com', '/store/apps/details', {
                          'id': 'com.theojansen.heliostrand_app',
                        }),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Actualizar desde Google Play'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _retry,
                      child: const Text('Volver a comprobar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
