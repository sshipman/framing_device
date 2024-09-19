import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framing_device/theme.dart';
import 'package:frame_sdk/bluetooth.dart';
import 'framing_device_home.dart';

void main() {
  // Start logging
  final container = ProviderContainer();

  // Request bluetooth permission
  BrilliantBluetooth.requestPermission();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const FramingDeviceApp()
  ));
}

class FramingDeviceApp extends ConsumerWidget {
  const FramingDeviceApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {

      return MaterialApp(
      title: 'Framing Device',
      theme:  CustomTheme.lightThemeData(context),
      darkTheme: CustomTheme.darkThemeData(),
      home: const FramingDeviceHome(),
    );
  }
}

