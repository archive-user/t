import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<String> aim(String url) async {
  try {
    final completer = Completer<String>();
    final controller = WebViewController();

    // 设置超时（100秒）
    Future.delayed(const Duration(seconds: 100), () {
      if (!completer.isCompleted) {
        completer.complete('');
      }
    });

    // 清理缓存和设置
    // await controller.clearCache();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    // JavaScript通道
    controller.addJavaScriptChannel(
      'Interceptor',
      onMessageReceived: (JavaScriptMessage message) {
        debugPrint('Resource: ${message.message}');
      },
    );
    controller.addJavaScriptChannel(
      'Video',
      onMessageReceived: (JavaScriptMessage message) {
        // controller.runJavaScript('''
        //   window.location.href = 'about:blank';
        // ''').then((onValue) {
        //   if (!completer.isCompleted) {
        //     completer.complete(message.message);
        //     controller.removeJavaScriptChannel('Interceptor');
        //     controller.removeJavaScriptChannel('Video');
        //   }
        // });
      },
    );

    controller.setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36');

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) async {
          await Future.delayed(const Duration(seconds: 1));
          try {
            await controller.runJavaScript('''
              Interceptor.postMessage('Interceptor.postMessage 监听所有资源加载 onPageStarted');
              (function () {
                var observer = new PerformanceObserver(function (list) {
                  list.getEntries().forEach(function (entry) {
                    Interceptor.postMessage(JSON.stringify({
                      type: entry.initiatorType,
                      message: entry.name
                    }));
                  });
                });
                observer.observe({ entryTypes: ['resource'] });
              })();
            ''');
          } catch (e) {
            print(e);
          }
          try {
            await controller.runJavaScript('''
              Interceptor.postMessage('Interceptor.postMessage FETCH请求 onPageStarted');
              (function () {
                var originalFetch = window.fetch;
                window.fetch = function () {
                  Interceptor.postMessage(JSON.stringify({
                    type: 'fetch',
                    message: arguments[0]
                  }));
                  return originalFetch.apply(this, arguments);
                };
              })();
            ''');
          } catch (e) {
            print(e);
          }

          try {
            await controller.runJavaScript('''
              Interceptor.postMessage('Interceptor.postMessage XHR');
              (function () {
                var originalXHROpen = XMLHttpRequest.prototype.open;
                XMLHttpRequest.prototype.open = function (method, url) {
                  Interceptor.postMessage(JSON.stringify({
                    type: method,
                    message: url
                  }));
                  originalXHROpen.apply(this, arguments);
                };

                var originalXHRSend = XMLHttpRequest.prototype.send;
                XMLHttpRequest.prototype.send = function (body) {
                  if (body) {
                    Interceptor.postMessage('XHR请求体: ' + body);
                    Interceptor.postMessage(JSON.stringify({
                      type: 'POST',
                      message: body
                    }));
                  }
                  originalXHRSend.apply(this, arguments);
                };
              })();
            ''');
          } catch (e) {
            print(e);
          }
        },
        onPageFinished: (String url) async {},
      ),
    );

    await controller.loadRequest(Uri.parse(url));

    return await Future.value(completer.future);
  } catch (e) {
    debugPrint(e.toString());
    return await Future.value('');
  }
}
