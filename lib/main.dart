import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:letsgo/platform_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letsgo/splash_screen.dart';
import 'package:letsgo/services/native_app_launcher.dart';
import 'dart:io';

void main() {
  runApp(const SocialHubApp());
}

class SocialHubApp extends StatelessWidget {
  const SocialHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SYNEX',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
    );
  }
}

class SocialHubHome extends StatefulWidget {
  const SocialHubHome({super.key});

  @override
  State<SocialHubHome> createState() => SocialHubHomeState();
}

class SocialHubHomeState extends State<SocialHubHome> {
  static const String LAST_INDEX_KEY = 'last_platform_index';
  static const String LAST_APP_STATE_KEY = 'last_app_state';
  int _currentIndex = 0;
  bool _showBars = true;
  String? _lastOpenedApp;
  
  // Define appConfig at class level
  final Map<String, String> appConfig = {
    'Twitter/X': 'com.twitter.android',
    'Facebook': 'com.facebook.katana',
    'Instagram': 'com.instagram.android',
    'LinkedIn': 'com.linkedin.android',
    'WhatsApp': 'com.whatsapp',
    'Telegram': 'org.telegram.messenger',
    'TikTok': 'com.zhiliaoapp.musically',
  };
  
  final List<SocialPlatform> _platforms = [
    SocialPlatform(
      name: 'Twitter/X',
      icon: Icons.message,
      color: Colors.black87,
    ),
    SocialPlatform(
      name: 'Facebook',
      icon: Icons.facebook,
      color: Colors.blue,
    ),
    SocialPlatform(
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE1306C),
    ),
    SocialPlatform(
      name: 'LinkedIn',
      icon: Icons.work,
      color: Colors.blue.shade900,
    ),
    SocialPlatform(
      name: 'WhatsApp',
      icon: Icons.chat,
      color: Color(0xFF25D366),
    ),
    SocialPlatform(
      name: 'Telegram',
      icon: Icons.send,
      color: Color(0xFF0088cc),
    ),
    SocialPlatform(
      name: 'TikTok',
      icon: Icons.music_note,
      color: Colors.black,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLastState();
  }

  Future<void> _loadLastState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt(LAST_INDEX_KEY) ?? 0;
      _lastOpenedApp = prefs.getString(LAST_APP_STATE_KEY);
    });
  }

  Future<void> _saveLastState(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAST_APP_STATE_KEY, packageName);
  }

  Future<void> _saveLastIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(LAST_INDEX_KEY, index);
  }

  void toggleBars(bool fullscreen) {
    setState(() {
      _showBars = !fullscreen;
    });
    
    Color statusBarColor;
    Brightness iconBrightness;
    
    // Set specific colors for each platform
    switch (_platforms[_currentIndex].name.toLowerCase()) {
      case 'facebook':
      case 'linkedin':
        statusBarColor = Colors.white;
        iconBrightness = Brightness.dark; // Black icons for white background
        break;
      case 'twitter/x':
      case 'instagram':
      case 'tiktok':
        statusBarColor = Colors.black;
        iconBrightness = Brightness.light; // White icons for black background
        break;
      default:
        statusBarColor = Colors.white;
        iconBrightness = Brightness.dark;
    }

    if (fullscreen) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [SystemUiOverlay.top],
      );
      // Update status bar color for fullscreen mode
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: statusBarColor.withOpacity(0.8),
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: iconBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ));
    } else {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      // Restore solid color for normal mode
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: statusBarColor,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: iconBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SYNEX',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _platforms.length,
        itemBuilder: (context, index) {
          final platform = _platforms[index];
          final packageName = appConfig[platform.name];
          
          return FutureBuilder<ImageProvider>(
            future: getNativeAppIcon(packageName ?? ''),
            builder: (context, snapshot) {
              return GestureDetector(
                onTap: () => _launchApp(platform.name),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          platform.color,
                          platform.color.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        snapshot.hasData
                            ? Image(
                                image: snapshot.data!,
                                width: 48,
                                height: 48,
                              )
                            : Icon(
                                platform.icon,
                                size: 48,
                                color: Colors.white,
                              ),
                        const SizedBox(height: 8),
                        Text(
                          platform.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _launchApp(String platformName) async {
    final packageName = appConfig[platformName];
    if (packageName != null) {
      try {
        const platform = MethodChannel('com.example.letsgo/app_launcher');
        final bool result = await platform.invokeMethod('launchApp', {
          'packageName': packageName,
        });
        if (result) {
          _saveLastState(packageName);
          _saveLastIndex(_platforms.indexWhere((p) => p.name == platformName));
        }
      } catch (e) {
        print('Failed to launch app: $e');
      }
    }
  }

  Future<ImageProvider> getNativeAppIcon(String packageName) async {
    try {
      const platform = MethodChannel('com.example.letsgo/app_icons');
      final String? iconPath = await platform.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      if (iconPath != null) {
        return FileImage(File(iconPath));
      }
    } catch (e) {
      print('Failed to load native icon: $e');
    }
    return _getDefaultIcon(packageName);
  }

  AssetImage _getDefaultIcon(String packageName) {
    final iconMap = {
      'com.twitter.android': 'assets/icons/twitter.png',
      'com.facebook.katana': 'assets/icons/facebook.png',
      // Add other default icons
    };
    return AssetImage(iconMap[packageName] ?? 'assets/icons/default.png');
  }
}

class SocialPlatform {
  final String name;
  final IconData icon;
  final Color color;

  SocialPlatform({
    required this.name,
    required this.icon,
    required this.color,
  });
}
