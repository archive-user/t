import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewAIM {
  static Future<String> getVod(
    String url, {
    void Function(Map)? onResourceLoaded, // 回调：每当资源加载时触发
    bool fetch = true,
    String? regexp,
  }) async {
    try {
      final completer = Completer<String>();
      final controller = WebViewController();

      // 设置超时
      Future.delayed(const Duration(seconds: 100), () {
        if (!completer.isCompleted) {
          debugPrint('{type: timeout, message: $url}');
          if (onResourceLoaded != null) {
            onResourceLoaded({'type': 'timeout', 'message': url});
          }
          completer.complete('');
        }
      });

      final proxyScript = '''
        (async function () {
          Interceptor.postMessage(JSON.stringify({
            type: 'regexp',
            message: String(document?.documentElement?.outerHTML)?.match(/$regexp/gim)?.at(0) || ''
          }));
          if (/404\$|favicon.gif\$/.test(window.location.href)) {
            try {
              const response = await fetch('$url', {
                method: 'GET',
                headers: {
                  'Accept': 'text/html',
                  'Content-Type': 'text/html'
                },
                credentials: 'include'
              });
              const html = await response.text();
              const parser = new DOMParser();
              const doc = parser.parseFromString(html, 'text/html');
              document.open();
              document.close();
              const els = doc?.querySelectorAll('img, style, link, form, .ds-comment, iframe[src*="prestrain"], script[src*="swiper"], script[src*="assembly"], script[src*="zh.js"], script[src*="ecscript"]');
              els.forEach(el => el.remove());
              const ads = doc?.querySelectorAll('.ad-class, [id*="ad"], script[src*="google"]');
              ads.forEach(ad => ad.remove());
              document.write(doc.documentElement.outerHTML);
            } catch (e) {
              return Interceptor.postMessage(JSON.stringify({
                type: 'fetchError',
                message: 'fetch请求失败'
              }));
            }
          };
          Interceptor.postMessage(JSON.stringify({
            type: 'regexp',
            message: String(document?.documentElement?.outerHTML)?.match(/$regexp/gim)?.at(0) || ''
          }));
          const vod = document?.querySelector('video')?.src;
          if (vod && /^bolb/.test(vod)) {
            Interceptor.postMessage(JSON.stringify({
              type: 'video',
              message: vod,
            }));
          }
          const vodIframe = document?.querySelector('iframe')?.src;
          if (vodIframe && /url=|player|.php|addons/.test(vodIframe)) {
            Interceptor.postMessage(JSON.stringify({
              type: 'iframe',
              message: vodIframe,
            }));
          };
        })();
      ''';

      const interceptScript = '''
        (function () {
          // 拦截 XMLHttpRequest
          const originalXHR = window.XMLHttpRequest;
          window.XMLHttpRequest = function () {
            const xhr = new originalXHR();
            xhr.addEventListener('load', function () {
              Interceptor.postMessage(JSON.stringify({
                type: 'xhr',
                message: this.responseURL || this._url
              }));
            });
            return xhr;
          };
          // 拦截 fetch API
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
          // 使用 PerformanceObserver 监听静态资源
          const observer = new PerformanceObserver(list => {
            list.getEntries().forEach(entry => {
              if (entry.initiatorType == 'video' && entry.responseStatus == '200') {
                Interceptor.postMessage(JSON.stringify({
                  type: 'poster',
                  message: entry.name
                }));
                return;
              }
              Interceptor.postMessage(JSON.stringify({
                type: entry.initiatorType,
                message: entry.name
              }));
            });
          });
          observer.observe({ entryTypes: ['resource'] });
          const mutationObserver = new MutationObserver((mutations) => {
            mutations.forEach((mutation) => {
              mutation.addedNodes.forEach((node) => {
                if (node.tagName == 'IFRAME' && node.src) {
                  Interceptor.postMessage(JSON.stringify({
                    type: node.tagName.toLocaleLowerCase(),
                    message: node.src
                  }));
                }
              });
            });
          });
          mutationObserver.observe(document, {
            childList: true,    // 观察子节点的添加/移除
            subtree: true,      // 观察所有后代节点
            attributes: false,  // 不观察属性变化
            characterData: false // 不观察文本内容变化
          });
        })();
      ''';

      controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      // JavaScript通道
      controller.addJavaScriptChannel(
        'Interceptor',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            final data = json.decode(message.message);
            debugPrint(data.toString());
            if (onResourceLoaded != null) {
              onResourceLoaded(data);
            }
            if (data['type'] == 'fetchError') {
              await controller.loadRequest(Uri.parse(url));
            }
            if (data['type'] == 'video' &&
                    RegExp('^http').hasMatch(data['message']) ||
                !RegExp('url=').hasMatch(data['message']) &&
                    RegExp(r'.m3u8$|.mp4$|m3u8\?|mp4\?')
                        .hasMatch(data['message'])) {
              if (!completer.isCompleted) {
                completer.complete(data['message']);
              }
            }
            final regexpMatch = regexp != null
                ? RegExp(regexp).allMatches(data['message'])
                : [] as Iterable;
            if (regexpMatch.isNotEmpty) {
              debugPrint(
                  '{type: regexp, message: ${regexpMatch.first.group(0)}}');
              if (!completer.isCompleted) {
                completer.complete(regexpMatch.first.group(0));
              }
            }
            if (data['type'] == 'iframe' &&
                RegExp(r'url=|player|.php|addons').hasMatch(data['message']) &&
                !RegExp(r'googleads|doubleclick|pagead')
                    .hasMatch(data['message'])) {
              if (data['message'] != url) {
                debugPrint('{type: load, message: ${data['message']}}');
                controller.loadRequest(Uri.parse(data['message']));
              }
            }
          } catch (e) {
            debugPrint('解析资源消息失败: $e');
          }
        },
      );

      controller.setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36');

      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            if (Platform.isIOS || Platform.isMacOS) {
              await Future.delayed(const Duration(seconds: 1));
            }
            try {
              await controller.runJavaScript(proxyScript);
            } catch (e) {
              debugPrint(e.toString());
            }
            try {
              await controller.runJavaScript(interceptScript);
            } catch (e) {
              debugPrint(e.toString());
            }
          },
        ),
      );

      await controller.runJavaScript('''
        if (window.performance && performance.memory) {
          performance.memory.jsHeapSizeLimit = 0;
        }
      ''');

      // 加载目标 URL
      final loadUrl = fetch
          ? '${RegExp(r'http(s?):\/\/.*?(?=\/|$)').allMatches(url).first.group(0).toString()}/favicon.gif'
          : url;
      debugPrint('{type: load, message: $loadUrl}');
      await controller.loadRequest(Uri.parse(loadUrl));

      // 等待页面加载完成
      final result = await completer.future;
      await controller.runJavaScript('localStorage.clear()');
      await controller.runJavaScript('sessionStorage.clear()');
      await controller.clearCache();
      await controller.loadRequest(Uri.parse('about:blank'));
      return result;
    } catch (e) {
      debugPrint(e.toString());
      return await Future.value('');
    }
  }
}
