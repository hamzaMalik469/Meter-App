import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MepcoBillWebView extends StatefulWidget {
  final String referenceNumber;
  const MepcoBillWebView({super.key, required this.referenceNumber});

  @override
  State<MepcoBillWebView> createState() => _MepcoBillWebViewState();
}

class _MepcoBillWebViewState extends State<MepcoBillWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
          "AppleWebKit/537.36 (KHTML, like Gecko) "
          "Chrome/114.0.0.0 Safari/537.36") // Pretend to be desktop Chrome
      ..loadRequest(Uri.parse("https://mepcobill.pk/"))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            if (url == "https://mepcobill.pk/") {
              await _controller.runJavaScript('''
                document.getElementById('reference').value = '${widget.referenceNumber}';
                document.getElementById('checkBill').click();
              ''');
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MEPCO Bill Viewer")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
