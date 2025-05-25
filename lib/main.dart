import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('is OK!!');
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
  late final WebViewController _controller;

  @override
  void initState() async {
    super.initState();

    if (Platform.isLinux) {
      final webview = await WebviewWindow.create();
      webview
        ..registerJavaScriptMessageHandler("test", (name, body) {
          debugPrint('on javaScipt message: $name $body');
        })
        ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
        ..setPromptHandler((prompt, defaultText) {
          if (prompt == "test") {
            return "Hello World!";
          } else if (prompt == "init") {
            return "initial prompt";
          }
          return "";
        })
        ..addScriptToExecuteOnDocumentCreated("""
  const mixinContext = {
    platform: 'Desktop',
    conversation_id: 'conversationId',
    immersive: false,
    app_version: '1.0.0',
    appearance: 'dark',
  }
  window.MixinContext = {
    getContext: function() {
      return JSON.stringify(mixinContext)
    }
  }
""")
        ..launch("https://flutter.dev/");
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) async {
              // 页面加载完成后获取网页内容
              try {
                final String? pageContent =
                    await _controller.runJavaScriptReturningResult(
                        'document.documentElement.outerHTML;') as String?;

                if (pageContent != null) {
                  print('网页内容: $pageContent');
                } else {
                  print('未能获取网页内容');
                }
              } catch (e) {
                print('获取网页内容时出错: $e');
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
      body: WebViewWidget(controller: _controller),
    );
  }
}
