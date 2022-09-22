import 'dart:js';
import 'dart:convert';
import 'package:on_hand/chrome_bridge/common/chrome_enum.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

abstract class ChromeCommon {
  static final JsObject json = context['JSON'];
  static final JsObject chrome = context['chrome'];
  static final JsObject runtime = chrome['runtime'];
  static final JsObject tabs = chrome['tabs'];

  static String? get lastError {
    final error = runtime['lastError'];
    if (error == null) return null;
    return error['message'] as String;
  }

  static bool get isWebExtension {
    return context['chrome'] != null;
  }

  static setNullableProperty<T>(JsObject obj, String propName, T? value) {
    if (value != null) {
      obj[propName] = value;
    } else {
      obj.deleteProperty(propName);
    }
  }

  static List? listify(JsObject? obj, [Function? transformer]) {
    if (obj == null) {
      return null;
    } else {
      List l = List.filled(obj['length'], null);
      for (int i = 0; i < l.length; i++) {
        if (transformer != null) {
          l[i] = transformer(obj[i]);
        } else {
          l[i] = obj[i];
        }
      }
      return l;
    }
  }

  static Map? mapify(JsObject? obj) {
    if (obj == null) return null;
    return jsonDecode(json.callMethod('stringify', [obj]));
  }

  static dynamic jsify(dynamic obj) {
    if (obj == null || obj is num || obj is String) {
      return obj;
    } else if (obj is ChromeObject) {
      return obj.jsProxy;
    } else if (obj is ChromeEnum) {
      return obj.value;
    } else if (obj is Map) {
      // Do a deep convert
      Map m = {};
      for (var key in obj.keys) {
        m[key] = jsify(obj[key]);
      }
      return JsObject.jsify(m);
    } else if (obj is Iterable) {
      // Do a deep convert
      return JsArray.from(obj).map(jsify);
    } else {
      return obj;
    }
  }
}
