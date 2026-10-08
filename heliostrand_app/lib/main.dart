import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'ui/screens/dashboard_screen.dart';
import 'ui/screens/version_gate.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  if (sentryDsn.isEmpty) {
    // Los reportes remotos se activan al configurar un DSN valido.
    runApp(const HeliostrandApp());
    return;
  }

  await SentryFlutter.init((options) {
    options.dsn = sentryDsn;
    options.environment = const String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'production',
    );
    options.sendDefaultPii = false;
    options.attachStacktrace = true;
    options.tracesSampleRate = 0.0;
  }, appRunner: () => runApp(const HeliostrandApp()));
}

class HeliostrandApp extends StatelessWidget {
  const HeliostrandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theo Jansen Solar Tracker',
      debugShowCheckedModeBanner: false,
      theme: SolarTrackerTheme.darkTheme,
      home: const VersionGate(child: DashboardScreen()),
    );
  }
}
