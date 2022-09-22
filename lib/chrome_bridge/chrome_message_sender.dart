import 'dart:js';
import 'package:on_hand/chrome_bridge/chrome_tab.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

/// An object containing information about the script context that sent a message
/// or request.
class ChromeMessageSender extends ChromeObject {
  ChromeMessageSender({
    String? documentId,
    String? documentLifecycle,
    int? frameId,
    String? id,
    String? nativeApplication,
    String? origin,
    ChromeTab? tab,
    String? tlsChannelId,
    String? url,
  }) {
    if (documentId != null) this.documentId = documentId;
    if (documentLifecycle != null) this.documentLifecycle = documentLifecycle;
    if (frameId != null) this.frameId = frameId;
    if (id != null) this.id = id;
    if (nativeApplication != null) this.nativeApplication = nativeApplication;
    if (origin != null) this.origin = origin;
    if (tab != null) this.tab = tab;
    if (tlsChannelId != null) this.tlsChannelId = tlsChannelId;
    if (url != null) this.url = url;
  }

  ChromeMessageSender.fromProxy(JsObject jsProxy) : super.fromProxy(jsProxy);

  static ChromeMessageSender? fromProxyN(JsObject? jsProxy) =>
      jsProxy != null ? ChromeMessageSender.fromProxy(jsProxy) : null;

  /// A UUID of the document that opened the connection.
  String? get documentId => jsProxy['documentId'];
  set documentId(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'documentId', value);

  /// The lifecycle the document that opened the connection is in at the time the port was created.
  /// Note that the lifecycle state of the document may have changed since port creation.
  String? get documentLifecycle => jsProxy['documentLifecycle'];
  set documentLifecycle(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'documentLifecycle', value);

  /// The [frame](webNavigation#frame_ids) that opened the connection. 0 for
  /// top-level frames, positive for child frames. This will only be set when
  /// `tab` is set.
  int? get frameId => jsProxy['frameId'];
  set frameId(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'frameId', value);

  /// The ID of the extension or app that opened the connection, if any.
  String? get id => jsProxy['id'];
  set id(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'id', value);

  /// The name of the native application that opened the connection, if any.
  String? get nativeApplication => jsProxy['nativeApplication'];
  set nativeApplication(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'nativeApplication', value);

  /// The origin of the page or frame that opened the connection. It can vary from the url
  /// property (e.g., about:blank) or can be opaque (e.g., sandboxed iframes).
  /// This is useful for identifying if the origin can be trusted if we can't immediately
  /// tell from the URL.
  String? get origin => jsProxy['origin'];
  set origin(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'origin', value);

  /// The [tabs.Tab] which opened the connection, if any. This property will
  /// *only* be present when the connection was opened from a tab (including
  /// content scripts), and *only* if the receiver is an extension, not an app.
  ChromeTab? get tab => ChromeTab.fromProxyN(jsProxy['tab']);
  set tab(ChromeTab? value) => ChromeCommon.setNullableProperty(
      jsProxy, 'tab', ChromeCommon.jsify(value));

  /// The TLS channel ID of the page or frame that opened the connection, if
  /// requested by the extension or app, and if available.
  String? get tlsChannelId => jsProxy['tlsChannelId'];
  set tlsChannelId(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'tlsChannelId', value);

  /// The URL of the page or frame that opened the connection. If the sender is
  /// in an iframe, it will be iframe's URL not the URL of the page which hosts
  /// it.
  String? get url => jsProxy['url'];
  set url(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'url', value);
}
