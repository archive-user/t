class Json {
  static dynamic getValueFromJson<T>(dynamic json, String path,
      {T? defaultValue}) {
    if (json == null || path.isEmpty) return defaultValue;

    // 将各种格式统一转换为点表示法
    final normalizedPath = path
        // 处理双引号方括号 ["key"] 转成 .key
        .replaceAllMapped(
            RegExp(r'\[\s*"([^"]+)"\s*\]'), (match) => '.${match.group(1)}')
        // 处理单引号方括号 ['key'] 转成 .key
        .replaceAllMapped(
            RegExp(r"\[\s*'([^']+)'\s*\]"), (match) => '.${match.group(1)}')
        // 处理数字方括号 [0] 转成 .0
        .replaceAllMapped(
            RegExp(r'\[\s*(\d+)\s*\]'), (match) => '.${match.group(1)}')
        // 处理通配符 [*] 转成 .*
        .replaceAllMapped(RegExp(r'\[\s*\*\s*\]'), (match) => '.*')
        // 移除可能产生的多余点
        .replaceAll(RegExp(r'\.{2,}'), '.');

    final keys = normalizedPath.split('.')..removeWhere((key) => key.isEmpty);
    return _getValueRecursive(json, keys, defaultValue);
  }

  static dynamic _getValueRecursive(
      dynamic current, List<String> keys, defaultValue) {
    if (current == null || keys.isEmpty) return current ?? defaultValue;

    final key = keys.first;
    final remainingKeys = keys.sublist(1);

    if (key == '*') {
      // 通配符处理
      if (current is List) {
        // 对列表中的每个元素递归处理
        return current
            .map(
                (item) => _getValueRecursive(item, remainingKeys, defaultValue))
            .toList();
      } else if (current is Map) {
        // 对Map中的每个值递归处理
        return current.values
            .map((value) =>
                _getValueRecursive(value, remainingKeys, defaultValue))
            .toList();
      } else {
        return defaultValue;
      }
    } else if (current is List) {
      final index = int.tryParse(key);
      if (index == null || index < 0 || index >= current.length) {
        return defaultValue;
      }
      return _getValueRecursive(current[index], remainingKeys, defaultValue);
    } else if (current is Map) {
      return _getValueRecursive(current[key], remainingKeys, defaultValue);
    } else {
      return defaultValue;
    }
  }

  // 强制类型转换: getValueAsType<bool>(jsonData, 'settings.darkMode', defaultValue: false)
  static T getValueAsType<T>(dynamic json, String path, {T? defaultValue}) {
    final value = getValueFromJson(json, path);

    if (value is T) {
      return value;
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    throw Exception('Value at path \'$path\' is not of type $T or is null');
  }
}
