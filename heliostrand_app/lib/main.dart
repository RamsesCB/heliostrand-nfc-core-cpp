import 'package:flutter/material.dart';

import 'ui/screens/dashboard_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HeliostrandApp());
}

class HeliostrandApp extends StatelessWidget {
  const HeliostrandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theo Jansen Solar Tracker',
      debugShowCheckedModeBanner: false,
      theme: SolarTrackerTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
