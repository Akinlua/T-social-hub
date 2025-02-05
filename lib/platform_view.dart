import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformView extends StatefulWidget {
  final String platformName;
  
  const PlatformView({
    super.key,
    required this.platformName,
  });

  @override
  State<PlatformView> createState() => _PlatformViewState();
}

class _PlatformViewState extends State<PlatformView> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _showWebView = false;
  String _currentPlatform = '';

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (String url) {
          setState(() {
            _isLoading = false;
          });
        },
      ));
    _loadPlatform();
  }

  @override
  void didUpdateWidget(PlatformView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.platformName != widget.platformName) {
      _loadPlatform();
    }
  }

  void _loadPlatform() {
    if (_currentPlatform == widget.platformName) return;
    
    _currentPlatform = widget.platformName;
    String url;
    setState(() {
      _isLoading = true;
    });

    switch (widget.platformName.toLowerCase()) {
      case 'facebook':
        url = 'https://m.facebook.com';
        break;
      case 'twitter/x':
        url = 'https://mobile.twitter.com';
        break;
      case 'instagram':
        url = 'https://instagram.com';
        break;
      case 'linkedin':
        url = 'https://www.linkedin.com';
        break;
      default:
        url = 'https://google.com';
    }
    
    setState(() {
      _showWebView = true;
    });
    _controller.loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Stack(
        children: [
          if (_showWebView) 
            WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 