import 'dart:io';

import 'package:flutter/material.dart';
import 'package:livech/webview/aim.dart';
import 'package:livech/webview/linux.dart';
import 'package:livech/webview/windows.dart';

class Webview {
  static Future<String> getVod(String url) async {
    try {
      if (Platform.isLinux) {
        return WebviewLinux.getVod(url);
      } else if (Platform.isWindows) {
        return WebviewWindows.getVod(url);
      } else {
        return WebviewAIM.getVod(url);
      }
    } catch (e) {
      debugPrint(e.toString());
      return await Future.value('');
    }
  }
}
