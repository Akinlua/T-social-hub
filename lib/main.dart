import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:letsgo/platform_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letsgo/splash_screen.dart';

void main() {
  runApp(const SocialHubApp());
}

class SocialHubApp extends StatelessWidget {
  const SocialHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Hub',
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
  int _currentIndex = 0;
  bool _showBars = true;
  
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
      color: Color(0xFFE1306C), // Updated Instagram brand color
    ),
    SocialPlatform(
      name: 'LinkedIn',
      icon: Icons.work,
      color: Colors.blue.shade900,
    ),
    // SocialPlatform(
    //   name: 'WhatsApp',
    //   icon: Icons.chat,
    //   color: Color(0xFF25D366), // WhatsApp green
    // ),
    SocialPlatform(
      name: 'TikTok',
      icon: Icons.music_note,
      color: Colors.black,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLastIndex();
  }

  Future<void> _loadLastIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIndex = prefs.getInt(LAST_INDEX_KEY) ?? 0;
    });
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
    // Set status bar style based on platform
    Color statusBarColor;
    Brightness iconBrightness;
    
    switch (_platforms[_currentIndex].name.toLowerCase()) {
      case 'facebook':
      case 'linkedin':
        statusBarColor = Colors.white;
        iconBrightness = Brightness.dark;
        break;
      case 'twitter/x':
      case 'instagram':
      case 'tiktok':
        statusBarColor = Colors.black;
        iconBrightness = Brightness.light;
        break;
      default:
        statusBarColor = Colors.white;
        iconBrightness = Brightness.dark;
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: statusBarColor,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: iconBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      appBar: _showBars ? AppBar(
        title: Text(_platforms[_currentIndex].name),
        backgroundColor: _platforms[_currentIndex].color,
        foregroundColor: Colors.white,
      ) : null,
      body: PlatformView(
        platformName: _platforms[_currentIndex].name,
      ),
      bottomNavigationBar: _showBars ? BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _platforms[_currentIndex].color,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _saveLastIndex(index);
        },
        items: _platforms.map((platform) => BottomNavigationBarItem(
          icon: Icon(platform.icon),
          label: platform.name,
        )).toList(),
      ) : null,
    );
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
