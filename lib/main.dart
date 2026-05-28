import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OtimeSyriaApp());
}

class OtimeSyriaApp extends StatelessWidget {
  const OtimeSyriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTime Syria',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

// 1 & 3. تم إضافة AutomaticKeepAliveClientMixin و wantKeepAlive للحفاظ على الحالة
class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  bool get wantKeepAlive => true; // منع تدمير الـ WebView عند التنقل

  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    transparentBackground: false,
    preferredContentMode: UserPreferredContentMode.MOBILE,
    hardwareAcceleration: true,
    allowsInlineMediaPlayback: true,
    mediaPlaybackRequiresUserGesture: false,
    javaScriptCanOpenWindowsAutomatically: true,
    useShouldOverrideUrlLoading: true,
    disableVerticalScroll: false,
    disableHorizontalScroll: false,
    overScrollMode: OverScrollMode.NEVER,
    verticalScrollbarThumbColor: const Color(0x00000000),
    domStorageEnabled: true,
    databaseEnabled: true,
    cacheEnabled: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyStableSystemUI();
  }

  void _applyStableSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _applyStableSystemUI();
      if (_webViewController != null) {
        _webViewController!.evaluateJavascript(source: '''
          if (typeof syncGuestInteractionsWithFirebase === 'function') syncGuestInteractionsWithFirebase();
          if (typeof syncInteractionsWithFirebase === 'function') syncInteractionsWithFirebase();
        ''');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ضروري لـ AutomaticKeepAliveClientMixin
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2c2c2c),
        body: Stack(
          children: [
            // 2. RepaintBoundary لعزل الرسم ومنع الـ lag
            RepaintBoundary(
              child: SafeArea(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri('https://tpm-offers.blogspot.com/')),
                  initialSettings: _settings,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _webViewController!.addJavaScriptHandler(
                      handlerName: 'NativeShareChannel',
                      callback: (args) {
                        if (args.isNotEmpty && args[0] != null) {
                          Share.share(args[0].toString());
                        }
                      },
                    );
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _loadingProgress = progress / 100;
                      _isLoading = progress < 100;
                    });
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    final url = navigationAction.request.url?.toString() ?? '';
                    if (url.startsWith('whatsapp:') || url.startsWith('tel:') || url.startsWith('intent://')) {
                      try {
                        await Future.delayed(const Duration(milliseconds: 300));
                        String finalUrl = url.startsWith('intent://') 
                            ? url.replaceFirst('intent://', 'https://').split('#Intent')[0] 
                            : url;
                        await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
                        return NavigationActionPolicy.CANCEL;
                      } catch (e) {
                        debugPrint('External launch error: $e');
                      }
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStop: (controller, url) async {
                    // 5 & 6. حقن JS والـ IntersectionObserver للتحميل الكسول
                    await controller.evaluateJavascript(source: '''
                      (function() {
                        if (!document.getElementById('otime-custom-styles')) {
                          var style = document.createElement('style');
                          style.id = 'otime-custom-styles';
                          style.innerHTML = `
                            ::-webkit-scrollbar { display: none !important; }
                            .header-widget, .footer-widget { display: none !important; }
                            body, html { background-color: #2c2c2c !important; }
                            iframe { pointer-events: auto !important; }
                          `;
                          document.head.appendChild(style);
                        }

                        if (!window.otimeLazyLoadSetup) {
                          window.otimeLazyLoadSetup = true;
                          var observer = new IntersectionObserver(function(entries) {
                            entries.forEach(function(entry) {
                              if (entry.isIntersecting) {
                                var img = entry.target;
                                if (img.dataset.src) {
                                  img.src = img.dataset.src;
                                  img.removeAttribute('data-src');
                                }
                                observer.unobserve(img);
                              }
                            });
                          });
                          document.querySelectorAll('img[data-src]').forEach(function(img) { observer.observe(img); });
                        }

                        if (typeof window.getLink !== 'function') {
                          window.getLink = function(element) {
                            var parentCard = element.closest('.article-card');
                            var dataUrl = parentCard ? parentCard.getAttribute('data-post-url') : null;
                            if (dataUrl) return dataUrl;
                            return window.location.href;
                          };
                        }

                        if (!window.otimeShareListenerAdded) {
                          window.otimeShareListenerAdded = true;
                          document.addEventListener('click', function(e) {
                            var btn = e.target.closest('.footer-btn.share-btn');
                            if (btn) {
                              e.preventDefault();
                              window.flutter_inappwebview.callHandler('NativeShareChannel', window.getLink(btn));
                            }
                          }, true);
                        }
                      })();
                    ''');
                  },
                ),
              ),
            ),
            // 4. AnimatedOpacity لانتقال سلس لمؤشر التحميل
            AnimatedOpacity(
              opacity: _isLoading ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFfb6d0e)),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
