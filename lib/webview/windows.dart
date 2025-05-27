import 'dart:async';
import 'dart:convert'; // 用于 JSON 解析
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

class WebviewWindows {
  static Future<String> getVod(
    String url, {
    void Function(String)? onResourceLoaded, // 回调：每当资源加载时触发
    bool fetch = true,
  }) async {
    try {
      final completer = Completer<String>();
      final controller = WebviewController();

      await controller.initialize();

      // 设置超时（100秒）
      Future.delayed(const Duration(seconds: 60), () {
        if (!completer.isCompleted) {
          debugPrint('超时：$url');
          controller.executeScript('''
            window.location.href = 'about:blank';
          ''');
          completer.complete('');
        }
      });

      final proxyScript = '''
        window.addEventListener('DOMContentLoaded', async function () {
          if (!/404\$|favicon.ico\$/.test(window.location.href)) return;
          for (let i = 1; i < 100; i++) { clearTimeout(i); }
          window.chrome.webview.postMessage(JSON.stringify({
            type: 'resource',
            url: 'DOMContentLoaded'
          }));
          try {
            // 使用fetch获取页面内容
            const response = await fetch('$url', {
              method: 'GET',
              headers: {
                'Accept': 'text/html',
                'Content-Type': 'text/html'
              },
              credentials: 'include'
            });
            if (!response.ok) {
              throw new Error('Network response was not ok');
            }
            // 获取HTML文本
            const html = await response.text();
            // 创建临时DOM解析HTML
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');
            const vod = doc?.querySelector('video')?.src;
            if (vod && /^bolb/.test(vod)) {
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'video',
                url: vod,
              }));
            }
            const vodIframe = doc?.querySelector('iframe')?.src;
            if (vodIframe && /url=|player|.php|addons/.test(vodIframe)) {
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'iframe',
                url: vodIframe,
              }));
            }
            // 移除标签
            const els = doc?.querySelectorAll('img, style, link, form, .ds-comment, iframe[src*="prestrain"], script[src*="swiper"], script[src*="assembly"], script[src*="zh.js"], script[src*="ecscript"]');
            els.forEach(el => el.remove());
            // 也可以选择性地移除其他元素
            const ads = doc?.querySelectorAll('.ad-class, [id*="ad"], script[src*="google"]');
            ads.forEach(ad => ad.remove());
            // 替换当前document的HTML
            document.open();
            document.write(doc.documentElement.outerHTML);
            document.close();
          } catch (error) {
            window.chrome.webview.postMessage(JSON.stringify({
              type: 'pageProcessed',
              url: '$url',
              error: error.message
            }));
          }
        });
      ''';

      const interceptScript = '''
        // 拦截所有动态加载的资源
        (function () {
          // 拦截 XMLHttpRequest
          const originalXHR = window.XMLHttpRequest;
          window.XMLHttpRequest = function () {
            const xhr = new originalXHR();
            xhr.addEventListener('load', function () {
              if (/.ts\$|.google|playOnline/gim.test(this.responseURL || this._url)) return;
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'xhr',
                url: this.responseURL || this._url
              }));
            });
            return xhr;
          };
          // 拦截 fetch API
          (function () {
            var originalFetch = window.fetch;
            window.fetch = function () {
              if (/.ts\$|.google|playOnline/gim.test(arguments[0])) return;
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'fetch',
                url: arguments[0]
              }));
              return originalFetch.apply(this, arguments);
            };
          })();
          // 使用 PerformanceObserver 监听静态资源
          const observer = new PerformanceObserver(list => {
            list.getEntries().forEach(entry => {
              if (entry.initiatorType == 'video' && entry.responseStatus == '200') {
                window.chrome.webview.postMessage(JSON.stringify({
                  type: 'poster',
                  url: entry.name
                }));
                return;
              }
              window.chrome.webview.postMessage(JSON.stringify({
                type: entry.initiatorType,
                url: entry.name
              }));
            });
          });
          observer.observe({ entryTypes: ['resource'] });
          // 监听 iframe 加载
          document.addEventListener('DOMNodeInserted', e => {
            if (e.target.tagName === 'IFRAME' && e.target.src) {
              window.chrome.webview.postMessage(JSON.stringify({
                type: 'iframe',
                url: e.target.src
              }));
            }
          });
        })();
      ''';

      // 注入脚本（在页面初始化时执行）
      await controller.addScriptToExecuteOnDocumentCreated(proxyScript);
      await controller.addScriptToExecuteOnDocumentCreated(interceptScript);

      // 监听来自网页的消息（资源加载事件）
      controller.webMessage.listen((message) {
        try {
          final data = json.decode(message);
          debugPrint(data.toString());
          if (data['type'] == 'resource' && onResourceLoaded != null) {
            onResourceLoaded(data['url']); // 回调返回资源 URL
          }
          if (data['type'] == 'video' ||
              !RegExp('url=').hasMatch(data['url']) &&
                  RegExp(r'.m3u8$|.mp4$|m3u8\?|mp4\?').hasMatch(data['url'])) {
            if (!completer.isCompleted) {
              completer.complete(data['url']);
            }
          }
          if (data['type'] == 'iframe' &&
              RegExp(r'url=|player|.php|addons').hasMatch(data['url']) &&
              !RegExp(r'googleads|doubleclick|pagead').hasMatch(data['url'])) {
            debugPrint('{type: load, url: ${data['url']}}');
            controller.loadUrl(data['url']);
          }
        } catch (e) {
          debugPrint('解析资源消息失败: $e');
        }
      });

      // 加载目标 URL
      final loadUrl = fetch
          ? '${RegExp(r'http(s?):\/\/.*?(?=\/|$)').allMatches(url).first.group(0).toString()}/favicon.ico'
          : url;
      debugPrint('{type: load, url: $loadUrl}');
      await controller.loadUrl(loadUrl);

      // 等待页面加载完成（可选）
      final result = await completer.future;
      controller.executeScript('''
        window.location.href = 'about:blank';
      ''');
      // await controller.clearCache();
      // await controller.dispose();
      return result;
    } catch (e) {
      debugPrint('WebViewWindows 错误: $e');
      return '';
    }
  }
}
