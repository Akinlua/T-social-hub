import 'package:flutter/material.dart';
import 'package:letsgo/platform_view.dart';

void main() {
  runApp(const SocialHubApp());
}

class SocialHubApp extends StatelessWidget {
  const SocialHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SocialHubHome(),
    );
  }
}

class SocialHubHome extends StatefulWidget {
  const SocialHubHome({super.key});

  @override
  State<SocialHubHome> createState() => _SocialHubHomeState();
}

class _SocialHubHomeState extends State<SocialHubHome> {
  int _currentIndex = 0;
  
  final List<SocialPlatform> _platforms = [
    SocialPlatform(
      name: 'Facebook',
      icon: Icons.facebook,
      color: Colors.blue,
    ),
    SocialPlatform(
      name: 'Twitter/X',
      icon: Icons.message,
      color: Colors.black87,
    ),
    SocialPlatform(
      name: 'Instagram',
      icon: Icons.camera_alt,
      color: Colors.purple,
    ),
    SocialPlatform(
      name: 'LinkedIn',
      icon: Icons.work,
      color: Colors.blue.shade900,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_platforms[_currentIndex].name),
        backgroundColor: _platforms[_currentIndex].color,
        foregroundColor: Colors.white,
      ),
      body: PlatformView(
        platformName: _platforms[_currentIndex].name,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _platforms[_currentIndex].color,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _platforms.map((platform) => BottomNavigationBarItem(
          icon: Icon(platform.icon),
          label: platform.name,
        )).toList(),
      ),
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
