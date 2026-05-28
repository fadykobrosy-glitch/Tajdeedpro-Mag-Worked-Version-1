import 'package:flutter/material.dart';
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
      theme: ThemeData(
        useMaterial3: false,
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

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  // إعدادات خارقة لتسريع المتصفح والـ GPU وأرشفة الذاكرة المحلية
  final InAppWebViewSettings _settings = InAppWebViewSettings(
    javaScriptEnabled: true,
    transparentBackground: false,
    preferredContentMode: UserPreferredContentMode.MOBILE,
    hardwareAcceleration: true, // تفعيل التسريع العتادي وتخفيف معالجة الطبقات
    disableVerticalScroll: false, // تحسين أداء الرندرة والتمرير
    disableHorizontalScroll: false,
    overScrollMode: OverScrollMode.NEVER,
    verticalScrollbarThumbColor: const Color(0x00000000), // إخفاء السكرول بار برمجياً
    
    // الأسطر الثلاثة القادمة هي الحل لمنع ضياع الـ LocalStorage والفايربيس
    domStorageEnabled: true, // تفعيل التخزين المحلي لضمان ثبات اللوكال ستوريج
    databaseEnabled: true,   // تفعيل قواعد بيانات المتصفح لعمل الفايربيس بسلاسة
    cacheEnabled: true,      // تفعيل الكاش لحفظ الجلسات عند تصغير التطبيق
  );

  @override
  Widget build(BuildContext context) {
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
            SafeArea(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri('https://tpm-offers.blogspot.com/')),
                initialSettings: _settings,
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                  
                  // كود دمج ميزة المشاركة الأصلية (Share) مع جافاسكربت
                  _webViewController!.addJavaScriptChannel(
                    'NativeShareChannel',
                    onMessageReceived: (message) {
                      if (message.message.isNotEmpty) {
                        Share.share(message.message);
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
                      // فرملة أمان: نمنح المتصفح 300 مللي ثانية ليكمل حفظ الطابور في الـ LocalStorage قبل فتح التطبيق الخارجي
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
                  // حقن كود الـ CSS والـ JS الذكي الخاص بموقعك لإخفاء الهيدر والفوتر وتفعيل المشاركة
                  await controller.evaluateJavascript(source: '''
                    var style = document.createElement('style');
                    style.innerHTML = `
                      ::-webkit-scrollbar { display: none !important; }
                      .header-widget, .footer-widget { display: none !important; }
                      body, html { background-color: #2c2c2c !important; }
                    `;
                    document.head.appendChild(style);

                    function getLink(element) {
                      var parentCard = element.closest('.article-card');
                      var dataUrl = parentCard ? parentCard.getAttribute('data-post-url') : null;
                      if (dataUrl) return dataUrl;

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
                    }

                    document.addEventListener('click', function(e) {
                      var btn = e.target.closest('.footer-btn.share-btn');
                      if (btn) {
                        e.preventDefault();
                        e.stopPropagation();
                        var link = getLink(btn);
                        window.NativeShareChannel.postMessage(link);
                      }
                    }, true);
                  ''');
                },
              ),
            ),
            if (_isLoading)
              Positioned(
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
          ],
        ),
      ),
    );
  }
}
