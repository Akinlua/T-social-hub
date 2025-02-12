import 'package:flutter/services.dart';

class NativeAppLauncher {
  static const platform = MethodChannel('com.example.letsgo/app_launcher');

  static Future<bool> launchNativeApp(String packageName) async {
    try {
      final bool result = await platform.invokeMethod('launchApp', {
        'packageName': packageName,
      });
      return result;
    } on PlatformException catch (e) {
      print('Error launching app: ${e.message}');
      return false;
    }
  }
} 