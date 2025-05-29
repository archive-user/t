import 'dart:io';

import 'package:flutter/material.dart';
import 'package:livech/webview/aim.dart';
import 'package:livech/webview/apple.dart';
import 'package:livech/webview/linux.dart';
import 'package:livech/webview/windows.dart';

class Webview {
  static Future<String> getVod(
    String url, {
    void Function(Map)? onResourceLoaded,
    bool fetch = true,
    String? regexp,
  }) async {
    try {
      if (Platform.isLinux) {
        return WebviewLinux.getVod(url,
            onResourceLoaded: onResourceLoaded, fetch: fetch, regexp: regexp);
      } else if (Platform.isWindows) {
        return WebviewWindows.getVod(url,
            onResourceLoaded: onResourceLoaded, fetch: fetch, regexp: regexp);
      } else if (Platform.isAndroid) {
        return WebviewAIM.getVod(url,
            onResourceLoaded: onResourceLoaded, fetch: fetch, regexp: regexp);
      } else {
        return WebviewApple.getVod(url,
            onResourceLoaded: onResourceLoaded, fetch: fetch, regexp: regexp);
      }
    } catch (e) {
      debugPrint(e.toString());
      return await Future.value('');
    }
  }
}
