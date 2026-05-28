import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  // تحسين الأداء: تعطيل نقاط الربط الرسومية غير الضرورية
  SchedulerBinding.instance.rasterizerShouldReassemble = () => false;

  WidgetsFlutterBinding.ensureInitialized();

  // تمكين طبقات GPU للأداء الأمثل
  WebView.platform = AndroidWebViewPlatform(
    androidWebViewWidgetFactory: AndroidWebViewWidgetFactory(
      findInteractionEnabled: false, // تحسين البحث
    ),
  );

  runApp(const OtimeSyriaApp());
}

class OtimeSyriaApp extends StatelessWidget {
  const OtimeSyriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTime Syria',
      debugShowCheckedModeBanner: false,
      // استخدام ThemeData بسيطة لتقليل التعقيد
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF2c2c2c),
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {

  InAppWebViewController? _webViewController;

  // ══════════════════════════════════════════════════════════════
  // 📊 حالة التحميل - محسّنة لتقليل setState
  // ══════════════════════════════════════════════════════════════
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _isJSStylesInjected = false; // تتبع ما إذا تم حقن الأنماط مسبقاً

  // ═══════════════════════════════════════════════════════════════════
  // ⚙️ إعدادات WebView مُحسّنة للأداء الفائق والسلسة
  // ═══════════════════════════════════════════════════════════════════
  late final InAppWebViewSettings _optimizedSettings;

  WebViewScreen() {
    _optimizedSettings = InAppWebViewSettings(
      // ── JavaScript ──
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,

      // ── العرض ──
      transparentBackground: false,
      preferredContentMode: UserPreferredContentMode.MOBILE,

      // ── التمرير - مُحسّنة لمنع التدقير ──
      disableVerticalScroll: false,
      disableHorizontalScroll: false,
      overScrollMode: OverScrollMode.NEVER,
      verticalScrollbarThumbColor: const Color(0x00000000),
      horizontalScrollbarThumbColor: const Color(0x00000000),

      // ── الفيديو والأوتوبلاي ──
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,

      // ── التخزين والتحميل ──
      domStorageEnabled: true,
      databaseEnabled: true,
      cacheEnabled: true,
      pageCacheDuration: const Duration(days: 7), // تخزين مؤقت لمدة أسبوع

      // ── تحسينات جديدة للأداء ──
      useShouldOverrideUrlLoading: true,
      shouldInterceptAjaxRequest: false, // تقليل الحمل
      shouldInterceptFetchRequest: false, // تقليل الحمل

      // ── منع re-renders غير ضرورية ──
      supportMultipleWindows: false,

      // ── إعدادات الويب ──
      allowFileAccessFromFileURLs: false,
      allowUniversalAccessFromFileURLs: false,
      allowContentAccessFromFileURLs: false,

      // ── تحسين الذاكرة ──
      enableSmoothTransition: true,
      forceDark: ForceDarkPolicy.FORCE_DARK_OFF,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyStableSystemUI();
  }

  @override
  bool get wantKeepAlive => true; // الحفاظ على حالة WebView

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
    _webViewController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _applyStableSystemUI();
      _syncFirebaseInteractions();
    } else if (state == AppLifecycleState.paused) {
      // حفظ حالة WebView عند الإيقاف
      _webViewController?.evaluateJavascript(
        source: 'window.dispatchEvent(new Event("pause"));'
      );
    }
  }

  void _syncFirebaseInteractions() {
    if (_webViewController != null) {
      _webViewController!.evaluateJavascript(source: '''
        try {
          if (typeof syncGuestInteractionsWithFirebase === 'function') {
            syncGuestInteractionsWithFirebase();
          }
          if (typeof syncInteractionsWithFirebase === 'function') {
            syncInteractionsWithFirebase();
          }
        } catch (e) {
          console.log('Firebase sync error:', e);
        }
      ''');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 📝 JavaScript مُحسّن - يُنفّذ مرة واحدة فقط
  // ═══════════════════════════════════════════════════════════
  String get _injectionScript => '''
    (function() {
      // ── الأنماط المخصصة ──
      if (!document.getElementById('otime-custom-styles')) {
        var style = document.createElement('style');
        style.id = 'otime-custom-styles';
        style.innerHTML = `
          ::-webkit-scrollbar {
            display: none !important;
            -ms-overflow-style: none;
            scrollbar-width: none;
          }
          * { scrollbar-width: none; }
          .header-widget, .footer-widget { display: none !important; }
          body, html {
            background-color: #2c2c2c !important;
            overflow-x: hidden !important;
          }
          iframe { pointer-events: auto !important; }
          img {
            max-width: 100% !important;
            height: auto !important;
          }
        `;
        document.head.appendChild(style);
      }

      // ── دالة الحصول على الرابط ──
      if (typeof window.getLink !== 'function') {
        window.getLink = function(element) {
          var parentCard = element.closest('.article-card');
          if (parentCard) {
            var dataUrl = parentCard.getAttribute('data-post-url');
            if (dataUrl) return dataUrl;
          }

          if (parentCard && parentCard.classList.contains('no-image')) {
            var textLink = parentCard.querySelector('h2 a, h3 a, a[href*=".html"]');
            if (textLink) return textLink.href;
          }

          var modal = document.getElementById('articleModal');
          if (modal && modal.style.display !== 'none') {
            var modalLink = modal.getAttribute('data-current-url') ||
                            modal.querySelector('a[href*=".html"], a.read-more')?.href;
            if (modalLink) return modalLink;
          }

          return window.location.href;
        };
      }

      // ── مستمع المشاركة (يُضاف مرة واحدة فقط) ──
      if (!window.otimeShareListenerAdded) {
        window.otimeShareListenerAdded = true;
        document.addEventListener('click', function(e) {
          var btn = e.target.closest('.footer-btn.share-btn');
          if (btn) {
            e.preventDefault();
            e.stopPropagation();
            var link = window.getLink(btn);
            window.flutter_inappwebview.callHandler('NativeShareChannel', link);
          }
        }, true);
      }

      // ── تحسين أداء الصور ──
      if (!window.otimeLazyLoadSetup) {
        window.otimeLazyLoadSetup = true;
        if ('IntersectionObserver' in window) {
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
          }, { rootMargin: '50px 0px' });

          document.querySelectorAll('img[data-src]').forEach(function(img) {
            observer.observe(img);
          });
        }
      }
    })();
  ''';

  // ═══════════════════════════════════════════════════════════
  // 🚀 مدير التحميل - يحسن أداء setState
  // ═══════════════════════════════════════════════════════════
  void _updateLoadingProgress(double progress) {
    // استخدام addPostFrameCallback لتجميع التحديثات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _loadingProgress = progress / 100;
          _isLoading = progress < 100;
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  // 🎯 معاودة URL - مع الأخطاء
  // ═══════════════════════════════════════════════════════════
  Future<NavigationActionPolicy> _handleUrlLoading(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final url = navigationAction.request.url?.toString();

    if (url == null) return NavigationActionPolicy.ALLOW;

    // معالجة الروابط الخارجية
    if (url.startsWith('whatsapp:') ||
        url.startsWith('tel:') ||
        url.startsWith('intent://')) {
      try {
        // تأخير قصير للسماح بالتحميل
        await Future.delayed(const Duration(milliseconds: 200));
        String finalUrl = url.startsWith('intent://')
            ? url.replaceFirst('intent://', 'https://').split('#Intent').first
            : url;
        await launchUrl(
          Uri.parse(finalUrl),
          mode: LaunchMode.externalApplication,
        );
        return NavigationActionPolicy.CANCEL;
      } catch (e) {
        debugPrint('External launch error: $e');
      }
    }

    return NavigationActionPolicy.ALLOW;
  }

  // ═══════════════════════════════════════════════════════════
  // ✅ عند اكتمال التحميل
  // ═══════════════════════════════════════════════════════════
  Future<void> _onLoadStop(
    InAppWebViewController controller,
    WebUri? url,
  ) async {
    // حقن JavaScript مرة واحدة فقط
    if (!_isJSStylesInjected) {
      await controller.evaluateJavascript(source: _injectionScript);
      _isJSStylesInjected = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // مطلوب لـ AutomaticKeepAliveClientMixin

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
        } else {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2c2c2c),
        body: Stack(
          children: [
            // WebView في SafeArea مع عزل الرسم
            SafeArea(
              bottom: false,
              top: false,
              child: RepaintBoundary(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://tpm-offers.blogspot.com/'),
                    headers: {
                      'Cache-Control': 'max-age=300',
                    },
                  ),
                  initialSettings: _optimizedSettings,
                  initialChildScrollViewPadding: EdgeInsets.zero,
                  pullToRefreshControl: PullToRefreshControl(
                    enabled: true,
                    backgroundColor: const Color(0xFF2c2c2c),
                    color: const Color(0xFFfb6d0e),
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _setupJavaScriptHandler();
                  },
                  onProgressChanged: (controller, progress) {
                    // تحديث متزامن للتقدم
                    this._updateLoadingProgress(progress.toDouble());
                  },
                  shouldOverrideUrlLoading: _handleUrlLoading,
                  onLoadStop: _onLoadStop,
                  onReceivedError: (controller, request, error) {
                    debugPrint('WebView Error: ${error.description}');
                  },
                  onReceivedHttpError: (controller, request, error) {
                    // تجاهل أخطاء HTTP غير الحرجة
                  },
                  androidWebViewChromeClient: AndroidWebViewChromeClient(
                    onProgressChanged: (controller, progress) {
                      this._updateLoadingProgress(progress.toDouble());
                    },
                  ),
                  androidWebViewChromeClientFactory: (AndroidWebViewChromeClient androidWebViewChromeClient) {
                    return AndroidWebViewChromeClient.withCustomSettings(
                      chromeClient: androidWebViewChromeClient,
                      settings: AndroidWebViewChromeClientSettings(
                        allowFileAccess: false,
                        allowContentAccess: false,
                      ),
                    );
                  },
                ),
              ),
            ),

            // ══════════════════════════════════════════════
            // 📊 مؤشر التحميل - مع عزل الرسم لإزالة lag
            // ══════════════════════════════════════════════
            RepaintBoundary(
              child: AnimatedOpacity(
                opacity: _isLoading ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: IgnorePointer(
                  ignoring: !_isLoading,
                  child: SizedBox(
                    height: 3,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: _loadingProgress,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFfb6d0e),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setupJavaScriptHandler() {
    _webViewController?.addJavaScriptHandler(
      handlerName: 'NativeShareChannel',
      callback: (args) {
        if (args.isNotEmpty && args[0] != null) {
          Share.share(args[0].toString());
        }
      },
    );
  }
}
