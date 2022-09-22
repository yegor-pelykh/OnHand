import 'dart:js';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

class ChromeTabsCreateParams extends ChromeObject {
  ChromeTabsCreateParams({
    bool? active,
    int? index,
    int? openerTabId,
    bool? pinned,
    bool? selected,
    String? url,
    int? windowId,
  }) {
    if (active != null) this.active = active;
    if (index != null) this.index = index;
    if (openerTabId != null) this.openerTabId = openerTabId;
    if (pinned != null) this.pinned = pinned;
    if (selected != null) this.selected = selected;
    if (url != null) this.url = url;
    if (windowId != null) this.windowId = windowId;
  }

  ChromeTabsCreateParams.fromProxy(JsObject jsProxy) : super.fromProxy(jsProxy);

  /// Whether the tab should become the active tab in the window. Does not affect
  /// whether the window is focused (see [windows.update]). Defaults to [true].
  bool? get active => jsProxy['active'];
  set active(bool? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'active', value);

  /// The position the tab should take in the window. The provided value will be
  /// clamped to between zero and the number of tabs in the window.
  int? get index => jsProxy['index'];
  set index(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'index', value);

  /// The ID of the tab that opened this tab. If specified, the opener tab must
  /// be in the same window as the newly created tab.
  int? get openerTabId => jsProxy['openerTabId'];
  set openerTabId(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'openerTabId', value);

  /// Whether the tab should be pinned. Defaults to [false]
  bool? get pinned => jsProxy['pinned'];
  set pinned(bool? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'pinned', value);

  /// Whether the tab should become the selected tab in the window. Defaults to
  /// [true]
  bool? get selected => jsProxy['selected'];
  set selected(bool? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'selected', value);

  /// The URL to navigate the tab to initially. Fully-qualified URLs must include
  /// a scheme (i.e. 'http://www.google.com', not 'www.google.com'). Relative
  /// URLs will be relative to the current page within the extension. Defaults to
  /// the New Tab Page.
  String? get url => jsProxy['url'];
  set url(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'url', value);

  /// The window to create the new tab in. Defaults to the [current window](windows#current-window).
  int? get windowId => jsProxy['windowId'];
  set windowId(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'windowId', value);
}
