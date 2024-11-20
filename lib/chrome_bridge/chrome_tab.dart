import 'dart:js';
import 'package:on_hand/chrome_bridge/chrome_tab_muted_info.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

class ChromeTab extends ChromeObject {
  ChromeTab({
    bool? active,
    bool? audible,
    bool? autoDiscardable,
    bool? discarded,
    String? favIconUrl,
    int? groupId, //
    int? height,
    bool? highlighted,
    int? id,
    bool? incognito,
    int? index,
    ChromeTabMutedInfo? mutedInfo,
    int? openerTabId,
    String? pendingUrl, //
    bool? pinned,
    String? sessionId,
    String? status,
    String? title,
    String? url,
    int? width,
    int? windowId,
  }) {
    if (active != null) this.active = active;
    if (audible != null) this.audible = audible;
    if (autoDiscardable != null) this.autoDiscardable = autoDiscardable;
    if (discarded != null) this.discarded = discarded;
    if (favIconUrl != null) this.favIconUrl = favIconUrl;
    if (groupId != null) this.groupId = groupId;
    if (height != null) this.height = height;
    if (highlighted != null) this.highlighted = highlighted;
    if (id != null) this.id = id;
    if (incognito != null) this.incognito = incognito;
    if (index != null) this.index = index;
    if (mutedInfo != null) this.mutedInfo = mutedInfo;
    if (openerTabId != null) this.openerTabId = openerTabId;
    if (pendingUrl != null) this.pendingUrl = pendingUrl;
    if (pinned != null) this.pinned = pinned;
    if (sessionId != null) this.sessionId = sessionId;
    if (status != null) this.status = status;
    if (title != null) this.title = title;
    if (url != null) this.url = url;
    if (width != null) this.width = width;
    if (windowId != null) this.windowId = windowId;
  }

  ChromeTab.fromProxy(super.jsProxy) : super.fromProxy();

  static ChromeTab? fromProxyN(JsObject? jsProxy) =>
      jsProxy != null ? ChromeTab.fromProxy(jsProxy) : null;

  /// Whether the tab is active in its window. (Does not necessarily mean the
  /// window is focused.)
  bool get active => jsProxy['active'];
  set active(bool value) => jsProxy['active'] = value;

  /// Whether the tab has produced sound over the past couple of seconds (but it
  /// might not be heard if also muted). Equivalent to whether the speaker audio
  /// indicator is showing.
  bool? get audible => jsProxy['audible'];
  set audible(bool? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'audible', value);

  /// Whether the tab can be discarded automatically by the browser when
  /// resources are low.
  bool get autoDiscardable => jsProxy['autoDiscardable'];
  set autoDiscardable(bool value) => jsProxy['autoDiscardable'] = value;

  /// Whether the tab is discarded. A discarded tab is one whose content has been
  /// unloaded from memory, but is still visible in the tab strip. Its content
  /// gets reloaded the next time it's activated.
  bool get discarded => jsProxy['discarded'];
  set discarded(bool value) => jsProxy['discarded'] = value;

  /// The ID of the group that the tab belongs to.
  int get groupId => jsProxy['groupId'];
  set groupId(int value) => jsProxy['groupId'] = value;

  /// The URL of the tab's favicon. This property is only present if the
  /// extension's manifest includes the `"tabs"` permission. It may also be an
  /// empty string if the tab is loading.
  String? get favIconUrl => jsProxy['favIconUrl'];
  set favIconUrl(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'favIconUrl', value);

  /// The height of the tab in pixels.
  int? get height => jsProxy['height'];
  set height(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'height', value);

  /// Whether the tab is highlighted.
  bool get highlighted => jsProxy['highlighted'];
  set highlighted(bool value) => jsProxy['highlighted'] = value;

  /// The ID of the tab. Tab IDs are unique within a browser session. Under some
  /// circumstances a Tab may not be assigned an ID, for example when querying
  /// foreign tabs using the [sessions] API, in which case a session ID may be
  /// present. Tab ID can also be set to chrome.tabs.TAB_ID_NONE for apps and
  /// devtools windows.
  int? get id => jsProxy['id'];
  set id(int? value) => ChromeCommon.setNullableProperty(jsProxy, 'id', value);

  /// Whether the tab is in an incognito window.
  bool get incognito => jsProxy['incognito'];
  set incognito(bool value) => jsProxy['incognito'] = value;

  /// The zero-based index of the tab within its window.
  int get index => jsProxy['index'];
  set index(int value) => jsProxy['index'] = value;

  /// Current tab muted state and the reason for the last state change.
  ChromeTabMutedInfo? get mutedInfo => jsProxy['mutedInfo'];
  set mutedInfo(ChromeTabMutedInfo? value) => ChromeCommon.setNullableProperty(
      jsProxy, 'mutedInfo', ChromeCommon.jsify(value));

  /// The ID of the tab that opened this tab, if any. This property is only
  /// present if the opener tab still exists.
  int? get openerTabId => jsProxy['openerTabId'];
  set openerTabId(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'openerTabId', value);

  /// The URL the tab is navigating to, before it has committed. This property is only present
  /// if the extension's manifest includes the "tabs" permission and there is a pending navigation.
  String? get pendingUrl => jsProxy['pendingUrl'];
  set pendingUrl(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'pendingUrl', value);

  /// Whether the tab is pinned.
  bool get pinned => jsProxy['pinned'];
  set pinned(bool value) => jsProxy['pinned'] = value;

  /// The session ID used to uniquely identify a Tab obtained from the [sessions] API.
  String? get sessionId => jsProxy['sessionId'];
  set sessionId(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'sessionId', value);

  /// Either _loading_ or _complete_.
  String? get status => jsProxy['status'];
  set status(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'status', value);

  /// The title of the tab. This property is only present if the extension's
  /// manifest includes the `"tabs"` permission.
  String? get title => jsProxy['title'];
  set title(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'title', value);

  /// The URL the tab is displaying. This property is only present if the
  /// extension's manifest includes the `"tabs"` permission.
  String? get url => jsProxy['url'];
  set url(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'url', value);

  /// The width of the tab in pixels.
  int? get width => jsProxy['width'];
  set width(int? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'width', value);

  /// The ID of the window the tab is contained within.
  int get windowId => jsProxy['windowId'];
  set windowId(int value) => jsProxy['windowId'] = value;
}
