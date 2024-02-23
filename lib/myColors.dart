import 'package:flutter/material.dart';

abstract class MyColors {
  static const white = Color(0xFFFFFFFF);
  static final Color btnPrimary =
      const Color.fromARGB(255, 186, 129, 255).withOpacity(.6);
  static Color btnVariant = const Color(0xff3700B3).withOpacity(.7);
  static Color btnSeconday = const Color(0xff03DAC6).withOpacity(0.2);
  static Color background = const Color(0xFF292929);
  static Color onPrimary = const Color(0xFF000000);

  static const green = Color(0xFF178262);

  static const textDisbaled = Color.fromRGBO(255, 255, 255, 0.75);

  static const LinearGradient gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color(0xFF178262),
        Color(0xFF00776B),
        Color(0xFF178262),
      ]);

  static const LinearGradient gradientDisabled = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: <Color>[
        Color.fromRGBO(23, 130, 98, 0.6),
        Color.fromRGBO(0, 119, 107, 0.6),
        Color.fromRGBO(23, 130, 98, 0.6),
      ]);
}
