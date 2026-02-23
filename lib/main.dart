import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const TajdeedProMagApp());
}

class TajdeedProMagApp extends StatelessWidget {
  const TajdeedProMagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tajdeed Pro Mag',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // متغيرات مشتركة لتقليل التكرار
  static const _logoShape = ContinuousRectangleBorder(
    side: BorderSide(color: Colors.orange, width: 2.0),
    borderRadius: BorderRadius.circular(60),
  );
  
  static const _logoDecoration = ShapeDecoration(
    color: Color(0xFFfb6d0e),
    shape: _logoShape,
  );

  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WebViewScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2c2c2c),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: _logoDecoration,
                      child: Center(
                        child: ClipPath(
                          clipper: ShapeBorderClipper(
                            shape: _logoShape,
                          ),
                          child: Image.asset(
                            'assets/icon/icon.png',
                            width: 120,
                            height: 120,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: _logoDecoration,
                                child: const Icon(
                                  Icons.article,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'تجديد',
                      style: GoogleFonts.tajawal(
                        color: const Color(0xFFefefef),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'أول مجلة إلكترونية تقدم الابتكار والتطوير في عالم التصميم الواسع والإعلان',
                        style: GoogleFonts.tajawal(
                          color: const Color(0xFFefefef),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFFfb6d0e),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'All Rights Reserved - Tajdeedpro Mag - 2026',
                    style: GoogleFonts.tajawal(
                      color: const Color(0xFFefefef),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF2c2c2c))
      ..addJavaScriptChannel(
        'NativeShareChannel',
        onMessageReceived: (JavaScriptMessage message) {
          Share.share(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onNavigationRequest: (NavigationRequest request) async {
            final url = request.url;

            // إصلاح الواتساب والروابط الخارجية - الفتح الخارجي فوراً
            if (url.contains("whatsapp.com") || url.startsWith("whatsapp:") || 
                url.startsWith("intent://") || (!url.startsWith('http') && !url.startsWith('https'))) {
              try {
                String finalUrl = url;
                if (url.startsWith('intent://')) {
                  finalUrl = url.replaceFirst('intent://', 'https://').split('#Intent')[0];
                }
                await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              } catch (e) {
                debugPrint('External launch error: $e');
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            _controller.runJavaScript('''
              // 1. تنظيف الواجهة (بضل متل ما هو)
              var style = document.createElement('style');
              style.innerHTML = `
                ::-webkit-scrollbar { opacity: 0 !important; width: 0px !important; background: transparent !important; }
                ::-webkit-scrollbar-track { background: transparent !important; }
                ::-webkit-scrollbar-thumb { background: transparent !important; }
                html, body { -ms-overflow-style: none !important; scrollbar-width: none !important; }
                .header-widget, .footer-widget { display: none !important; }
              `;
              document.head.appendChild(style);

              // 2. وظيفة استخراج الرابط "الجراحية" (للمقالات النصية والمودال حصراً)
              function getLink(element) {
                // أ- محاولة جلب الرابط الأساسي (للمقالات العادية الشغالة)
                var parentCard = element.closest('.article-card');
                var dataUrl = parentCard ? parentCard.getAttribute('data-post-url') : null;
                if (dataUrl) return dataUrl;

                // ب- إذا فشل وكان المقال نصي (.no-image)
                if (parentCard && parentCard.classList.contains('no-image')) {
                  var textLink = parentCard.querySelector('h2 a, h3 a, a[href*=".html"]');
                  if (textLink) return textLink.href;
                }

                // ج- إذا كنا جوا مودال (نصي أو عادي)
                var modal = document.getElementById('articleModal');
                if (modal && modal.style.display !== 'none') {
                  // البحث عن رابط المقال الكامل داخل المودال
                  var modalLink = modal.getAttribute('data-current-url') || 
                                  modal.querySelector('a[href*=".html"], a.read-more')?.href;
                  if (modalLink) return modalLink;
                }

                // د- الملاذ الأخير
                return window.location.href;
              }

              // 3. التنصت على أي نقرة مشاركة
              document.addEventListener('click', function(e) {
                var btn = e.target.closest('.footer-btn.share-btn');
                if (btn) {
                  e.preventDefault();
                  e.stopPropagation();
                  var link = getLink(btn);
                  NativeShareChannel.postMessage(link);
                }
              }, true);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://tajdeedpro.blogspot.com/'));
  }

  Future<void> _refreshWebView() async {
    await _controller.reload();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF2c2c2c),
        body: Stack(
          children: [
            // Full-screen WebView with RefreshIndicator
            SafeArea(
              child: RefreshIndicator(
                key: _refreshIndicatorKey,
                onRefresh: _refreshWebView,
                color: const Color(0xFFfb6d0e),
                backgroundColor: const Color(0xFF2c2c2c),
                displacement: 80,
                strokeWidth: 3,
                child: WebViewWidget(
                  controller: _controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                ),
              ),
            ),
            // Loading indicator overlay
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
