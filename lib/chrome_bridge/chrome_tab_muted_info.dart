import 'dart:js';
import 'package:on_hand/chrome_bridge/chrome_tab_muted_info_reason.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';

/// Tab muted state and the reason for the last state change.
class ChromeTabMutedInfo extends ChromeObject {
  ChromeTabMutedInfo({
    String? extensionId,
    bool? muted,
    ChromeTabMutedInfoReason? reason,
  }) {
    if (extensionId != null) this.extensionId = extensionId;
    if (muted != null) this.muted = muted;
    if (reason != null) this.reason = reason;
  }

  ChromeTabMutedInfo.fromProxy(JsObject jsProxy) : super.fromProxy(jsProxy);

  /// The ID of the extension that changed the muted state. Not set if an
  /// extension was not the reason the muted state last changed.
  String? get extensionId => jsProxy['extensionId'];
  set extensionId(String? value) =>
      ChromeCommon.setNullableProperty(jsProxy, 'extensionId', value);

  /// Whether the tab is prevented from playing sound (but hasn't necessarily
  /// recently produced sound). Equivalent to whether the muted audio indicator
  /// is showing.
  bool get muted => jsProxy['muted'];
  set muted(bool value) => jsProxy['muted'] = value;

  /// The reason the tab was muted or unmuted. Not set if the tab's mute state
  /// has never been changed.
  ChromeTabMutedInfoReason? get reason =>
      ChromeTabMutedInfoReason.from(jsProxy['reason']);
  set reason(ChromeTabMutedInfoReason? value) =>
      ChromeCommon.setNullableProperty(
          jsProxy, 'reason', ChromeCommon.jsify(value));
}
