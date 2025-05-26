// import 'dart:convert';
import 'dart:io';
// import 'package:html/parser.dart' show parse;
// import 'package:html/dom.dart' show Document;

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:livech/webview/aim.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('is OK!!');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  late final WebViewController? controller;
  String text = 'test';
  String text2 = 'test';
  @override
  void initState() {
    super.initState();

    if (Platform.isLinux) {
      if (runWebViewTitleBarWidget([])) {
        return;
      }
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
    } else if (Platform.isWindows) {
      final controller = WebviewController();
      controller.initialize().then((value) async {
        await controller.setBackgroundColor(Colors.transparent);
        await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
        controller.webMessage.listen((message) {
          debugPrint('收到消息: $message');
          setState(() {
            text = message;
          });
        });
        await controller.loadUrl('https://flutter.dev/');
        await Future.delayed(const Duration(seconds: 2));
        await controller.executeScript('''
          window.chrome.webview.postMessage('videoMessage:' + document.body.outerHTML);
          window.location.href = 'about:blank';
        ''');
      });
    } else {
      void a() async {
        aim('https://anime.girigirilove.com/playGV26394-1-1/').then((t) {
          setState(() {
            text = t;
          });
          debugPrint('请求结果：：：：$t');
        });

        aim('https://dm.xifanacg.com/watch/3158/1/1.html').then((t) {
          setState(() {
            text2 = t;
          });
          debugPrint('请求结果：：：：$t');
        });
      }

      a();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter WebView Example')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Text(text),
          ),
          SliverToBoxAdapter(
            child: Text(text2),
          )
        ],
      ),
    );
  }
}
