import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:letsgo/main.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:letsgo/services/native_app_launcher.dart';

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
  late WebViewController _currentController;
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
                _currentController.runJavaScript(
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
            
            if (platformName.toLowerCase() == 'facebook') {
              _handleFacebookPage(_controllers[platformName.toLowerCase()]!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation requests including OAuth
            return NavigationDecision.navigate;
          },
        ))
        ..setOnConsoleMessage((JavaScriptConsoleMessage message) {
          print('WebView Console: ${message.message}');
        });

      // Update user agent to include more browser-like capabilities
      final userAgent = platformName.toLowerCase() == 'facebook' 
        ? 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1'
        : 'Mozilla/5.0 (Linux; Android 12; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36 SocialHub/1.0';

      controller
        ..setUserAgent(userAgent)
        ..loadRequest(Uri.parse(_getUrl(platformName)));

      _controllers[platformName.toLowerCase()] = controller;
    }
    
    _currentController = _controllers[platformName.toLowerCase()]!;
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
                        _currentController.reload();
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
    
    final appConfig = {
      'instagram': 'com.instagram.android',
      'facebook': 'com.facebook.katana',
      'twitter/x': 'com.twitter.android',
      'linkedin': 'com.linkedin.android',
      'tiktok': 'com.zhiliaoapp.musically',
      'whatsapp': 'com.whatsapp',
    };

    final packageName = appConfig[widget.platformName.toLowerCase()];
    
    if (packageName != null) {
      NativeAppLauncher.launchNativeApp(packageName).then((success) {
        if (!success) {
          // Fallback to web view if app launch fails
          setState(() {
            _isLoading = true;
            _showWebView = true;
          });
          _initializeController(widget.platformName);
        }
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showWebView = true;
    });
    _initializeController(widget.platformName);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Show loading indicator immediately
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
        
        // Content below loading indicator
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    // Show loading state immediately when platform changes
    if (widget.platformName != _lastPlatform) {
      _isLoading = true;
      _lastPlatform = widget.platformName;
    }

    return WillPopScope(
      onWillPop: () async {
        if (await _currentController.canGoBack()) {
          _currentController.goBack();
          return false;
        }
        return true;
      },
      child: Stack(
        children: [
          if (_showWebView)
            SafeArea(
              child: WebViewWidget(controller: _currentController),
            ),
          Positioned(
            left: _buttonPosition.dx,
            top: _buttonPosition.dy,
            child: Draggable(
              feedback: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Icon(
                  _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: null,
              ),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                setState(() {
                  _buttonPosition = Offset(
                    details.offset.dx
                        .clamp(0, MediaQuery.of(context).size.width - 40),
                    details.offset.dy
                        .clamp(0, MediaQuery.of(context).size.height - 40),
                  );
                });
              },
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Icon(
                  _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _fullscreen = !_fullscreen;
                  });
                  if (mounted) {
                    context
                        .findAncestorStateOfType<SocialHubHomeState>()
                        ?.toggleBars(_fullscreen);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
