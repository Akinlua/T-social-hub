import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:letsgo/main.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

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
  final Map<String, WebViewController> _controllers = {};
  bool _isLoading = true;
  bool _showWebView = true;
  String _currentPlatform = '';
  bool _fullscreen = false;
  Offset _buttonPosition = const Offset(16, 16); // Default position top-right
  WebViewController? _currentController;
  bool _isShowingError = false;
  String _lastPlatform = '';
  static const String SCROLL_POSITION_KEY = 'scroll_position';
  static const String CURRENT_URL_KEY = 'current_url';

  @override
  void initState() {
    super.initState();
    _restoreState();
    // Add a small delay for the initial load
    Future.delayed(Duration(milliseconds: 500), () {
      _initializeController(widget.platformName);
    });
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('${widget.platformName}_$CURRENT_URL_KEY');
    final scrollPosition = prefs.getDouble('${widget.platformName}_$SCROLL_POSITION_KEY');

    if (savedUrl != null) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(savedUrl))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (scrollPosition != null) {
                _currentController?.runJavaScript(
                  'window.scrollTo(0, $scrollPosition);'
                );
              }
              setState(() {
                _isLoading = false;
              });
            },
          ),
        );
      _controllers[widget.platformName] = controller;
    }
  }

  Future<void> _saveState() async {
    final controller = _controllers[widget.platformName];
    if (controller != null) {
      final prefs = await SharedPreferences.getInstance();
      final url = await controller.currentUrl();
      final scrollPosition = await controller.runJavaScriptReturningResult(
        'window.pageYOffset'
      );
      
      await prefs.setString('${widget.platformName}_$CURRENT_URL_KEY', url ?? '');
      await prefs.setDouble('${widget.platformName}_$SCROLL_POSITION_KEY', 
        double.parse(scrollPosition.toString()));
    }
  }

  @override
  void dispose() {
    _saveState();
    super.dispose();
  }

  void _initializeController(String platformName) {
    if (!_controllers.containsKey(platformName.toLowerCase())) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..enableZoom(true)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _showWebView = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _enableCaching(_controllers[platformName.toLowerCase()]!);
            
            // Special handling for Facebook
            if (platformName.toLowerCase() == 'facebook') {
              _handleFacebookPage(_controllers[platformName.toLowerCase()]!);
            }
          },
          // onWebResourceError: (WebResourceError error) {
          //   if (!_isShowingError) {
          //     setState(() {
          //       _isLoading = false;
          //     });
          //     _showErrorWidget();
          //   }
          // },
        ));

      // Platform specific initialization
      if (platformName.toLowerCase() == 'facebook') {
        controller
          ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1')
          ..loadRequest(Uri.parse('https://m.facebook.com/home.php'));
      } else {
        controller
          ..setUserAgent('Mozilla/5.0 (Linux; Android 12; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36')
          ..loadRequest(Uri.parse(_getUrl(platformName)));
      }

      _controllers[platformName.toLowerCase()] = controller;
    }
    
    setState(() {
      _currentController = _controllers[platformName.toLowerCase()];
      _lastPlatform = platformName;
    });
  }

  void _handleFacebookPage(WebViewController controller) {
    controller.runJavaScript('''
      // Suppress permission policy errors
      const originalError = console.error;
      console.error = (...args) => {
        if (!args[0]?.includes?.('Permissions-Policy')) {
          originalError.apply(console, args);
        }
      };
      
      // Handle redirect if needed
      if (document.body.innerHTML.includes('redirect')) {
        window.location.href = 'https://m.facebook.com/home.php';
      }
    ''');
  }

  void _enableCaching(WebViewController controller) {
    controller.runJavaScript('''
      if ('caches' in window) {
        caches.open('offline-cache').then(function(cache) {
          cache.add(window.location.href);
        });
      }
    ''');
  }

  String _getUrl(String platformName) {
    switch (platformName.toLowerCase()) {
      
      case 'twitter/x':
        return 'https://mobile.twitter.com';
      case 'facebook':
        return 'https://m.facebook.com';
      case 'instagram':
        return 'https://instagram.com';
      case 'linkedin':
        return 'https://www.linkedin.com';
      case 'tiktok':
        return 'https://www.tiktok.com';
      default:
        return 'https://google.com';
    }
  }

  void _showErrorWidget() {
    if (_isShowingError) return;
    _isShowingError = true;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/offline.png',
                  height: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Internet Connection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can still browse cached content.\nCheck your connection to load new content.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _isShowingError = false;
                      },
                      child: const Text('Continue Offline'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _isShowingError = false;
                        _currentController?.reload();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => _isShowingError = false); // Reset flag when dialog is dismissed
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
    
    if (widget.platformName.toLowerCase() == 'whatsapp') {
      _launchWhatsApp();
      return;
    }

    setState(() {
      _isLoading = true;
      _showWebView = true;
    });

    _initializeController(widget.platformName);
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _launchWhatsApp() async {
    setState(() {
      _showWebView = false;
      _isLoading = false;
    });

    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          package: 'com.whatsapp',
          componentName: 'com.whatsapp.HomeActivity',
          flags: [
            0x10000000, // FLAG_ACTIVITY_NEW_TASK
            0x00080000, // FLAG_ACTIVITY_NEW_DOCUMENT
            0x08000000, // FLAG_ACTIVITY_CLEAR_TASK
            0x00400000, // FLAG_ACTIVITY_RETAIN_IN_RECENTS
          ],
        );
        await intent.launch();
      } catch (e) {
        final playStoreIntent = AndroidIntent(
          action: 'action_view',
          data: 'market://details?id=com.whatsapp',
        );
        await playStoreIntent.launch();
      }
    } else if (Platform.isIOS) {
      final url = Uri.parse('whatsapp://');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // If WhatsApp is not installed, open App Store
        final appStoreUrl = Uri.parse(
            'https://apps.apple.com/app/whatsapp-messenger/id310633997');
        await launchUrl(appStoreUrl);
      }
    }
  }

  Future<bool> _handleBackPressed() async {
    if (_currentController != null) {
      try {
        // Check if we're on the main feed/home page
        final currentUrl = await _currentController!.currentUrl() ?? '';
        final isMainPage = _isMainPage(currentUrl);
        
        // If we can go back and not on main page, navigate back
        final canGoBack = await _currentController!.canGoBack();
        if (canGoBack && !isMainPage) {
          _currentController!.goBack();
          return false; // Don't close the app
        }
      } catch (e) {
        // Handle any potential errors
        print('Error handling back navigation: $e');
      }
    }
    return true; // Allow closing the app
  }

  bool _isMainPage(String url) {
    final platform = widget.platformName.toLowerCase();
    switch (platform) {
      case 'instagram':
        return url.contains('instagram.com') && !url.contains('/p/') && 
               !url.contains('/reels/') && !url.contains('/stories/');
      case 'facebook':
        return url.contains('m.facebook.com/home') || url == 'https://m.facebook.com/';
      case 'twitter/x':
        return url == 'https://mobile.twitter.com/' || url == 'https://mobile.twitter.com/home';
      case 'linkedin':
        return url == 'https://www.linkedin.com/' || url == 'https://www.linkedin.com/feed/';
      case 'tiktok':
        return url == 'https://www.tiktok.com/' || url == 'https://www.tiktok.com/foryou';
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPressed,
      child: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_currentController != null)
            WebViewWidget(
              controller: _currentController!,
            ),
        ],
      ),
    );
  }
}
