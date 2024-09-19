import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData lightThemeData(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange,
          brightness: Brightness.light,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      appBarTheme: AppBarTheme(color: Colors.deepOrange.shade400, foregroundColor: Colors.white),

      useMaterial3: true,
    );
  }

  static ThemeData darkThemeData(){
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange,
        brightness: Brightness.dark,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      appBarTheme: AppBarTheme(color: Colors.deepOrange.shade900, foregroundColor: Colors.white),

      useMaterial3: true,
    );
  }
}