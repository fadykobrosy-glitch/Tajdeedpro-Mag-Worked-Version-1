import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const OtimeSyriaApp());
}

class OtimeSyriaApp extends StatelessWidget {
  const OtimeSyriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tajdeed Pro Mag',
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
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // تم إلغاء اللون الشفاف ووضع لون معتم لمنع نترات الـ CPU وتفعيل الـ GPU بالكامل
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

            if (url.startsWith('whatsapp:') || url.startsWith('intent://')) {
              try {
                String finalUrl = url.startsWith('intent://') 
                    ? url.replaceFirst('intent://', 'https://').split('#Intent')[0]
                    : url;
                await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              } catch (e) {
                debugPrint('External launch error: $e');
              }
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            // تحسين السكرول بار من خلال display: none الخفيفة على معالج الرسوميات
            _controller.runJavaScript('''
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
                  NativeShareChannel.postMessage(link);
                }
              }, true);
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://tpm-offers.blogspot.com/'));
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
            SafeArea(
              child: WebViewWidget(
                controller: _controller,
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
