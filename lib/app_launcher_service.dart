// lib/services/app_launcher_service.dart
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class AppLauncherService {
  static Future<bool> launchApp(String packageName, {String? fallbackUrl}) async {
    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: packageName,
          flags: [
            0x10000000, // FLAG_ACTIVITY_NEW_TASK
            0x00080000, // FLAG_ACTIVITY_NEW_DOCUMENT
          ],
        );
        await intent.launch();
        return true;
      } catch (e) {
        if (fallbackUrl != null) {
          return _launchStore(fallbackUrl);
        }
        return false;
      }
    } else if (Platform.isIOS) {
      // iOS uses URL schemes
      final schemes = {
        'com.facebook.katana': 'fb://',
        'com.instagram.android': 'instagram://',
        'com.twitter.android': 'twitter://',
        'com.linkedin.android': 'linkedin://',
        'com.zhiliaoapp.musically': 'tiktok://',
      };
      
      final scheme = schemes[packageName] ?? fallbackUrl;
      if (scheme != null) {
        final url = Uri.parse(scheme);
        if (await canLaunchUrl(url)) {
          return launchUrl(url);
        } else if (fallbackUrl != null) {
          return _launchStore(fallbackUrl);
        }
      }
    }
    return false;
  }

  static Future<bool> _launchStore(String url) async {
    final uri = Uri.parse(url);
    return await canLaunchUrl(uri) ? await launchUrl(uri) : false;
  }
}