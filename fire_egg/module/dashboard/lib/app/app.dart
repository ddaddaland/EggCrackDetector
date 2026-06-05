import 'package:fire_egg_dashboard/app/home.dart';
import 'package:fire_egg_widgets/theme/theme.dart';
import 'package:flutter/material.dart';

class FireEggDashboardApp extends StatelessWidget {
  const FireEggDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: FireEggCommonTheme.create(
        primaryColor: Colors.cyan,
      ),
      home: FireEggDashboardHome(),
    );
  }
}
