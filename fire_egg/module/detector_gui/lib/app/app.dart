import 'package:fire_egg_detector_gui/app/home.dart';
import 'package:fire_egg_widgets/theme/theme.dart';
import 'package:flutter/material.dart';

class FireEggDetectorGuiApp extends StatelessWidget {
  const FireEggDetectorGuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: FireEggCommonTheme.create(),
      debugShowCheckedModeBanner: false,
      home: const FireEggDetectorGuiHome(),
    );
  }
}
