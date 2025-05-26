// import 'dart:convert';
// import 'dart:io';
// import 'package:html/parser.dart' show parse;
// import 'package:html/dom.dart' show Document;

// import 'package:desktop_webview_window/desktop_webview_window.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:webview_windows/webview_windows.dart';

// void main() {
//   if (runWebViewTitleBarWidget([])) {
//     return;
//   }
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     debugPrint('is OK!!');
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'WebView Example',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: const WebViewExample(),
//     );
//   }
// }

// class WebViewExample extends StatefulWidget {
//   const WebViewExample({super.key});

//   @override
//   State<WebViewExample> createState() => _WebViewExampleState();
// }

// class _WebViewExampleState extends State<WebViewExample> {
//   late final WebViewController? controller;
//   String text = 'test';
//   @override
//   void initState() {
//     super.initState();

//     if (Platform.isLinux) {
//       WebviewWindow.isWebviewAvailable().then((value) async {
//         final webview = await WebviewWindow.create(
//           configuration: CreateConfiguration(
//             titleBarTopPadding: Platform.isMacOS ? 20 : 0,
//           ),
//         );
//         webview
//           ..setBrightness(Brightness.dark)
//           ..setApplicationNameForUserAgent(" WebviewExample/1.0.0")
//           ..launch('https://flutter.dev/')
//           ..onClose.whenComplete(() {
//             debugPrint("on close");
//           });
//         await Future.delayed(const Duration(seconds: 2));
//         const javaScriptToEval = [
//           'eval({"name": "test", "user_agent": navigator.userAgent, "body": document.body.outerHTML})'
//         ];
//         for (final javaScript in javaScriptToEval) {
//           try {
//             final ret = await webview.evaluateJavaScript(javaScript);
//             debugPrint('evaluateJavaScript: $ret');
//           } catch (e) {
//             debugPrint('evaluateJavaScript error: $e \n $javaScript');
//           }
//         }
//       });
//     } else if (Platform.isWindows) {
//       final controller = WebviewController();
//       controller.initialize().then((value) async {
//         await controller.setBackgroundColor(Colors.transparent);
//         await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
//         controller.webMessage.listen((message) {
//           debugPrint('收到消息: $message');
//           setState(() {
//             text = message;
//           });
//         });
//         await controller.loadUrl('https://flutter.dev/');
//         await Future.delayed(const Duration(seconds: 2));
//         await controller.executeScript('''
// window.chrome.webview.postMessage('videoMessage:' + document.body.outerHTML);
// window.location.href = 'about:blank';
// ''');
//       });
//     } else {
//       controller = WebViewController();
//       controller?.loadRequest(Uri.parse('about:blank'));
//       controller?.clearCache();
//       controller?.setJavaScriptMode(JavaScriptMode.unrestricted);
//       controller?.addJavaScriptChannel(
//         'Interceptor',
//         onMessageReceived: (JavaScriptMessage message) {
//           print('Resource: ${message.message}');
//         },
//       );
//       controller?.setUserAgent(
//           'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36');
//       controller?.setNavigationDelegate(
//         NavigationDelegate(
//           onUrlChange: (url) async {
//             controller?.runJavaScript('''
//       // 移除元素
//       function removeEl() {
//         // 按class名移除
//         document.querySelectorAll('img link').forEach(el => el.remove());
        
//         // 按iframe源移除
//         document.querySelectorAll('iframe').forEach(iframe => {
//           if (iframe.src.includes('adservice') || 
//               iframe.src.includes('doubleclick')) {
//             iframe.remove();
//           }
//         });
//       }
      
//       // 初始清理
//       removeEl();
      
//       // 监控DOM变化持续清理
//       const observer = new MutationObserver(removeEl);
//       observer.observe(document.documentElement, {
//         childList: true,
//         subtree: true
//       });

//         // 1. 拦截所有 XMLHttpRequest
//         (function() {
//           var originalXHROpen = XMLHttpRequest.prototype.open;
//           XMLHttpRequest.prototype.open = function(method, url) {
//             if (/.ts\$/gim.test(url)) return;
//             Interceptor.postMessage('XHR请求: ' + method + ' ' + url);
//             originalXHROpen.apply(this, arguments);
//           };
          
//           var originalXHRSend = XMLHttpRequest.prototype.send;
//           XMLHttpRequest.prototype.send = function(body) {
//             if (body) {
//               Interceptor.postMessage('XHR请求体: ' + body);
//             }
//             originalXHRSend.apply(this, arguments);
//           };
//         })();

//         // 2. 拦截所有 Fetch API 请求
//         (function() {
//           var originalFetch = window.fetch;
//           window.fetch = function() {
//             // return;
//             Interceptor.postMessage('Fetch请求: ' + arguments[0]);
//             return originalFetch.apply(this, arguments);
//           };
//         })();

//         // 3. 监听所有资源加载
//         (function() {
//           var observer = new PerformanceObserver(function(list) {
//             list.getEntries().forEach(function(entry) {
//               Interceptor.postMessage('资源加载: ' + entry.name + ' (' + entry.initiatorType + ')');
//             });
//           });
//           observer.observe({entryTypes: ['resource']});
//         })();

//         // 4. 拦截动态创建的脚本和iframe
//         (function() {
//           var originalCreateElement = document.createElement;
//           document.createElement = function(tagName) {
//             if (tagName.toLowerCase() === 'script') {
//               Interceptor.postMessage('动态创建脚本元素');
//             } else if (tagName.toLowerCase() === 'iframe') {
//               Interceptor.postMessage('动态创建iframe元素');
//             }
//             return originalCreateElement.apply(this, arguments);
//           };
//         })();

//         // 5. 监听脚本错误
//         window.onerror = function(message, source, lineno, colno, error) {
//           Interceptor.postMessage('脚本错误: ' + message + ' at ' + source + ':' + lineno);
//           return true; // 阻止错误继续传播
//         };

//         // 6. 拦截所有console.log
//         var originalConsoleLog = console.log;
//         console.log = function() {
//           var args = Array.prototype.slice.call(arguments);
//           Interceptor.postMessage('控制台日志: ' + args.join(' '));
//           originalConsoleLog.apply(console, arguments);
//         };

//         // 7. 监听所有链接点击
//         document.addEventListener('click', function(e) {
//           if (e.target.tagName === 'A') {
//             Interceptor.postMessage('点击链接: ' + e.target.href);
//           }
//         }, true);

//         // 8. 监听所有表单提交
//         document.addEventListener('submit', function(e) {
//           Interceptor.postMessage('表单提交: ' + e.target.action);
//         }, true);
//               ''');
//           },
//           onPageFinished: (String url) async {
//             await _getIframeContent(controller);
//           },
//         ),
//       );
//       controller?.loadRequest(
//           Uri.parse('https://anime.girigirilove.com/playGV26475-1-1/'));
//     }
//   }

//   Future<void> _getIframeContent(controller) async {
//     try {
//       // 方法1: 尝试直接获取iframe内容
//       final result = await controller?.runJavaScriptReturningResult('''
// document.querySelector('#playleft > iframe').src;
//       ''') as String;

//       debugPrint('iframe内容获取结果: ${json.decode(result)}');

//       controller?.loadRequest(Uri.parse(json.decode(result)));
//       setState(() {
//         text = json.decode(result) ?? '未获取到内容';
//       });
//     } catch (e) {
//       setState(() {
//         text = '获取iframe内容出错: $e';
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Flutter WebView Example')),
//       body: CustomScrollView(
//         slivers: [
//           SliverToBoxAdapter(
//             child: Text(text),
//           )
//         ],
//       ),
//     );
//   }
// }
