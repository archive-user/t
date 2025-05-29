import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
          await controller.runJavaScript('''
              webkit.messageHandlers.Interceptor.postMessage('webkit.messageHandlers.Interceptor.postMessage 监听所有资源加载 onPageStarted');
              (function () {
                var observer = new PerformanceObserver(function (list) {
                  list.getEntries().forEach(function (entry) {
                    Interceptor.postMessage('资源加载: ' + entry.name + ' (' + entry.initiatorType + ')');
                    if (/video/gim.test(entry.initiatorType) && /^http/gim.test(entry.name) || /xmlhttprequest/gim.test(entry.initiatorType) && /.m3u8\$/gim.test(entry.name)) {
                      Video.postMessage(entry.name);
                    }
                  });
                });
                observer.observe({ entryTypes: ['resource'] });
              })();
            ''');
          await controller.runJavaScript('''
webkit.messageHandlers.Interceptor.postMessage('webkit.messageHandlers.Interceptor.postMessage 拦截动态创建的脚本和iframe onPageStarted');
              (function () {
                var originalCreateElement = document.createElement;
                document.createElement = function (tagName) {
                  if (tagName.toLowerCase() === 'script') {
                    window.webkit.messageHandlers.Interceptor.postMessage('动态创建脚本元素');
                  } else if (tagName.toLowerCase() === 'iframe') {
                    Interceptor.postMessage('动态创建iframe元素');
                  }
                  return originalCreateElement.apply(this, arguments);
                };
              })();
            ''');
          await controller.runJavaScript('''
              window.webkit.messageHandlers.Interceptor.postMessage('window.webkit.messageHandlers.Interceptor.postMessage FETCH请求 onPageStarted');
              (function () {
                var originalFetch = window.fetch;
                window.fetch = function () {
                  Interceptor.postMessage('Fetch请求: ' + arguments[0]);
                  return originalFetch.apply(this, arguments);
                };
              })();
            ''');
          await controller.runJavaScript('''
              Interceptor.postMessage('Interceptor.postMessage XHR');
(function () {
  var originalXHROpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
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
            ''');
        },
        onPageFinished: (String url) async {
          try {
            await controller.runJavaScript('''
              webkit.messageHandlers.Interceptor.postMessage('webkit.messageHandlers.Interceptor.postMessage 监听所有资源加载 onPageFinished');
              (function () {
                var observer = new PerformanceObserver(function (list) {
                  list.getEntries().forEach(function (entry) {
                    Interceptor.postMessage('资源加载: ' + entry.name + ' (' + entry.initiatorType + ')');
                    if (/video/gim.test(entry.initiatorType) && /^http/gim.test(entry.name) || /xmlhttprequest/gim.test(entry.initiatorType) && /.m3u8\$/gim.test(entry.name)) {
                      Video.postMessage(entry.name);
                    }
                  });
                });
                observer.observe({ entryTypes: ['resource'] });
              })();
            ''');
            await controller.runJavaScript('''
webkit.messageHandlers.Interceptor.postMessage('webkit.messageHandlers.Interceptor.postMessage 拦截动态创建的脚本和iframe onPageFinished');
              (function () {
                var originalCreateElement = document.createElement;
                document.createElement = function (tagName) {
                  if (tagName.toLowerCase() === 'script') {
                    window.webkit.messageHandlers.Interceptor.postMessage('动态创建脚本元素');
                  } else if (tagName.toLowerCase() === 'iframe') {
                    Interceptor.postMessage('动态创建iframe元素');
                  }
                  return originalCreateElement.apply(this, arguments);
                };
              })();
            ''');
            await controller.runJavaScript('''
              window.webkit.messageHandlers.Interceptor.postMessage('window.webkit.messageHandlers.Interceptor.postMessage FETCH请求 onPageFinished');
              (function () {
                var originalFetch = window.fetch;
                window.fetch = function () {
                  Interceptor.postMessage('Fetch请求: ' + arguments[0]);
                  return originalFetch.apply(this, arguments);
                };
              })();
            ''');
            await controller.runJavaScript('''
              Interceptor.postMessage('Interceptor.postMessage');
(function () {
  var originalXHROpen = XMLHttpRequest.prototype.open;
  XMLHttpRequest.prototype.open = function (method, url) {
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
            ''');
            final result = await controller.runJavaScriptReturningResult('''
            document.querySelector('#playleft > iframe')?.src || '';
          ''') as String?;

            if (result != null && result != '' && result.isNotEmpty) {
              final decoded = Platform.isAndroid ? json.decode(result) : result;
              final match = RegExp('(?<=url=)http.*?(.mp4\$|.m3u8\$)')
                  .firstMatch(decoded);
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

    return await Future.value(completer.future);
  } catch (e) {
    debugPrint(e.toString());
    return await Future.value('');
  }
}
