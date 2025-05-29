// import 'dart:convert';
// import 'dart:io';
// import 'package:html/parser.dart' show parse;
// import 'package:html/dom.dart' show Document;

import 'package:flutter/material.dart';
import 'package:livech/webview/apple.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  String text = 'girigiri';
  String text2 = 'xifan';
  String text3 = 'dmmiku';
  String text4 = 'jzacg';
  @override
  void initState() {
    super.initState();

    void a() async {
      // aim('https://anime.girigirilove.com/playGV26394-1-1/').then((t) {
      //   setState(() {
      //     if (t.isNotEmpty) {
      //       text = t;
      //       debugPrint('请求结果：：：：$t');
      //     }
      //   });
      // });
      aim('https://dm.xifanacg.com/watch/3158/1/1.html').then((t) {
        setState(() {
          if (t.isNotEmpty) {
            text2 = t;
            debugPrint('请求结果：：：：$t');
          }
        });
      });
      // aim('https://dm.xifanacg.com/watch/3158/1/2.html').then((t) {
      //   setState(() {
      //     if (t.isNotEmpty) {
      //       text2 = t;
      //       debugPrint('请求结果：：：：$t');
      //     }
      //   });
      // });
      aim('https://dmmiku.com/index.php/vod/play/id/3125/sid/1/nid/1.html')
          .then((t) {
        setState(() {
          if (t.isNotEmpty) {
            text3 = t;
            debugPrint('请求结果：：：：$t');
          }
        });
      });
      // aim('https://www.jzacg.com/bangumi/1421-2-1/').then((t) {
      //   setState(() {
      //     if (t.isNotEmpty) {
      //       text4 = t;
      //       debugPrint('请求结果：：：：$t');
      //     }
      //   });
      // });
    }

    a();
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
          ),
          SliverToBoxAdapter(
            child: Text(text3),
          ),
          SliverToBoxAdapter(
            child: Text(text4),
          )
        ],
      ),
    );
  }
}
