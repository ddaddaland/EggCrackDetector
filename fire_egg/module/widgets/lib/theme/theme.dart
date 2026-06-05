import 'package:fire_egg_widgets/text/fonts.dart';
import 'package:flutter/material.dart';

class FireEggCommonTheme {
  const FireEggCommonTheme._();

  static ThemeData create({
    MaterialColor primaryColor = Colors.amber,
  }) {
    return ThemeData(
      fontFamily: Fonts.pretendard,
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
          iconSize: 20,
          padding: EdgeInsets.zero,
          minimumSize: Size.square(35),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryColor,
      ),
    );
  }
}
