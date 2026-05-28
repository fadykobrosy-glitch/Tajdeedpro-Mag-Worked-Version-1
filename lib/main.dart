import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // مكتبة التحكم المستقر بألوان أشرطة النظام
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

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
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
    
    // الحل المعتمد لمنع ضياع الـ LocalStorage والفايربيس
    domStorageEnabled: true, // تفعيل التخزين المحلي لضمان ثبات اللوكال ستوريج
    databaseEnabled: true,   // تفعيل قواعد بيانات المتصفح لعمل الفايربيس بسلاسة
    cacheEnabled: true,      // تفعيل الكاش لحفظ الجلسات عند تصغير التطبيق
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // تثبيت أشرطة الهاتف باللون الأسود المستقر والكلاسيكي
    _applyStableSystemUI();
  }

  void _applyStableSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // شريط الساعة العلوي أسود
      statusBarIconBrightness: Brightness.light, // أيقونات الساعة بيضاء
      systemNavigationBarColor: Colors.black, // شريط الأدوات السفلي أسود
      systemNavigationBarIconBrightness: Brightness.light, // أزرار التحكم السفلية بيضاء
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
    
    // إذا استيقظ التطبيق وعاد للواجهة (من المينيمايز أو القفل)
    if (state == AppLifecycleState.resumed) {
      // التأكيد على ثبات ألوان الأشرطة السوداء عند العودة للتطبيق
      _applyStableSystemUI();

      if (_webViewController != null) {
        debugPrint('📱 [Otime Wakeup] تم رصد عودة التطبيق للواجهة، يتم نغز المزامنة فوراً...');
        
        _webViewController!.evaluateJavascript(source: '''
          console.log('🔄 [Native Bridge] نغزة ذكية من فلاتر لإفراغ طابور العمليات فوراً');
          if (typeof syncGuestInteractionsWithFirebase === 'function') {
            syncGuestInteractionsWithFirebase();
          }
          if (typeof syncInteractionsWithFirebase === 'function') {
            syncInteractionsWithFirebase();
          }
        ''');
      }
    }
  }

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
            // إرجاع الـ SafeArea لضمان ثبات الأبعاد وحل مشاكل اليوتيوب والتدقير تماماً
            SafeArea(
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
                  // حقن كود الـ CSS والـ JS المحمّي ضد التكرار لمنع الـ Flicker والبطء
                  await controller.evaluateJavascript(source: '''
                    // 1. منع تكرار حقن الـ CSS (حقن لمرة واحدة بالـ ID)
                    if (!document.getElementById('otime-custom-styles')) {
                      var style = document.createElement('style');
                      style.id = 'otime-custom-styles';
                      style.innerHTML = `
                        ::-webkit-scrollbar { display: none !important; }
                        .header-widget, .footer-widget { display: none !important; }
                        body, html { background-color: #2c2c2c !important; }
                      `;
                      document.head.appendChild(style);
                    }

                    // حماية الدالة المساعدة من التكرار
                    if (typeof window.getLink !== 'function') {
                      window.getLink = function(element) {
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
                      };
                    }

                    // 2. منع تكرار مستمعي النقرات (استخدام الـ window flag كـ قفل أمان)
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
