import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

Future<void> runUiAction(
  BuildContext context,
  Future<void> Function() action,
  String message,
) async {
  try {
    await action();
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SolarTrackerTheme.badgeRedText,
      ),
    );
  }
}

Future<void> openExternalLink(BuildContext context, Uri uri) =>
    runUiAction(context, () async {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No se pudo abrir el enlace');
      }
    }, 'No se pudo abrir el enlace. Inténtalo nuevamente.');
