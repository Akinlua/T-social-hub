import 'package:flutter/material.dart';
import 'package:letsgo/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _navigateToHome();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SocialHubHome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.3; // Reduced to 30% of screen width

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: RotationTransition(
              turns: _controller,
              child: Image.asset(
                'assets/splash.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            bottom: 50, // Distance from bottom
            left: 0,
            right: 0,
            child: const Text(
              'SYNEX',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28, // Increased font size
                fontWeight: FontWeight.w500,
                color: Color(0xFF0066CC), // Changed to blue
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 