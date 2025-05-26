import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<String> aim(String url) async {
  final completer = Completer<String>();
  final controller = WebViewController();

  // 设置超时（100秒）
  Future.delayed(const Duration(seconds: 100), () {
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('Loading timed out'));
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
      if (!completer.isCompleted) {
        completer.complete(message.message);
      }
    },
  );

  controller.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36');

  controller.setNavigationDelegate(
    NavigationDelegate(
      onUrlChange: (change) async {
        await controller.runJavaScript('''
              // 移除元素
              function removeEl() {
                // 按class名移除
                document.querySelectorAll('img, link, style').forEach(el => el.remove());

                // 按iframe源移除
                document.querySelectorAll('iframe').forEach(iframe => {
                  if (iframe.src.includes('adservice') ||
                    iframe.src.includes('doubleclick')) {
                    iframe.remove();
                  }
                });
              }

              // 初始清理
              removeEl();

              // 监控DOM变化持续清理
              const observer = new MutationObserver(removeEl);
              observer.observe(document.documentElement, {
                childList: true,
                subtree: true
              });

              // 1. 拦截所有 XMLHttpRequest
              (function () {
                var originalXHROpen = XMLHttpRequest.prototype.open;
                XMLHttpRequest.prototype.open = function (method, url) {
                  if (/.ts\$|.google/gim.test(url)) return;
                  Interceptor.postMessage('XHR请求: ' + method + ' ' + url);
                  if (/^http/gim.test(url) && /.m3u8\$/gim.test(url)) {
                      Video.postMessage(url);
                    }
                  originalXHROpen.apply(this, arguments);
                };

                var originalXHRSend = XMLHttpRequest.prototype.send;
                XMLHttpRequest.prototype.send = function (body) {
                  if (body) {
                    Interceptor.postMessage('XHR请求体: ' + body);
                  }
                  originalXHRSend.apply(this, arguments);
                };
              })();

              // 2. 拦截所有 Fetch API 请求
              (function () {
                var originalFetch = window.fetch;
                window.fetch = function () {
                  if (/.ts\$|.google/gim.test(url)) return;
                  Interceptor.postMessage('Fetch请求: ' + arguments[0]);
                  return originalFetch.apply(this, arguments);
                };
              })();

              // 3. 监听所有资源加载
              (function () {
                var observer = new PerformanceObserver(function (list) {
                  list.getEntries().forEach(function (entry) {
                    if (/video/gim.test(entry.initiatorType) && /^http/gim.test(entry.name) || /xmlhttprequest/gim.test(entry.initiatorType) && /.m3u8\$/gim.test(entry.name)) {
                      // Interceptor.postMessage('资源加载: ' + entry.name + ' (' + entry.initiatorType + ')');
                      Video.postMessage(entry.name);
                    }
                  });
                });
                observer.observe({ entryTypes: ['resource'] });
              })();

              // 4. 拦截动态创建的脚本和iframe
              (function () {
                var originalCreateElement = document.createElement;
                document.createElement = function (tagName) {
                  if (tagName.toLowerCase() === 'script') {
                    Interceptor.postMessage('动态创建脚本元素');
                  } else if (tagName.toLowerCase() === 'iframe') {
                    Interceptor.postMessage('动态创建iframe元素');
                  }
                  return originalCreateElement.apply(this, arguments);
                };
              })();
  ''');
      },
      onPageFinished: (String url) async {
        try {
          final result = await controller.runJavaScriptReturningResult('''
            document.querySelector('#playleft > iframe')?.src || '';
          ''') as String?;

          if (result != null && result != '' && result.isNotEmpty) {
            final decoded = json.decode(result);
            final match =
                RegExp('(?<=url=)http.*?(.mp4\$|.m3u8\$)').firstMatch(decoded);
            if (match != null && !completer.isCompleted) {
              completer.complete(match.group(0));
            } else {
              await controller.loadRequest(Uri.parse(decoded));
            }
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      },
    ),
  );

  await controller.loadRequest(Uri.parse(url));

  return await Future.any([completer.future]);
}
