import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  if (runWebViewTitleBarWidget([])) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('is OK!!');
    return MaterialApp(
      title: 'WebView Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebViewExample(),
    );
  }
}

class WebViewExample extends StatefulWidget {
  const WebViewExample({super.key});

  @override
  State<WebViewExample> createState() => _WebViewExampleState();
}

class _WebViewExampleState extends State<WebViewExample> {
  @override
  void initState() {
    super.initState();

    if (Platform.isLinux) {
      WebviewWindow.isWebviewAvailable().then((value) async {
        final webview = await WebviewWindow.create(
          configuration: CreateConfiguration(
            titleBarTopPadding: Platform.isMacOS ? 20 : 0,
          ),
        );
        webview
          ..setBrightness(Brightness.dark)
          ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
          ..launch('https://flutter.dev/')
          ..onClose.whenComplete(() {
            debugPrint("on close");
          });
        await Future.delayed(const Duration(seconds: 2));
        const javaScriptToEval = [
          'eval({"name": "test", "user_agent": navigator.userAgent, "body": document.body.outerHTML})'
        ];
        for (final javaScript in javaScriptToEval) {
          try {
            final ret = await webview.evaluateJavaScript(javaScript);
            debugPrint('evaluateJavaScript: $ret');
          } catch (e) {
            debugPrint('evaluateJavaScript error: $e \n $javaScript');
          }
        }
      });
    } else {
      late final WebViewController controller;
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) async {
              // 页面加载完成后获取网页内容
              try {
                final String? pageContent =
                    await controller.runJavaScriptReturningResult(
                        'document.documentElement.outerHTML;') as String?;

                if (pageContent != null) {
                  debugPrint('网页内容: $pageContent');
                } else {
                  debugPrint('未能获取网页内容');
                }
              } catch (e) {
                debugPrint('获取网页内容时出错: $e');
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('https://flutter.dev/'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter WebView Example')),
      body: const Text('test'),
    );
  }
}
