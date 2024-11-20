import 'package:on_hand/chrome_bridge/common/chrome_enum.dart';

/// An event that caused a muted state change.
class ChromeTabMutedInfoReason extends ChromeEnum {
  const ChromeTabMutedInfoReason(super.value);

  /// A user input action has set/overridden the muted state.
  static const ChromeTabMutedInfoReason user = ChromeTabMutedInfoReason('user');

  /// Tab capture started, forcing a muted state change.
  static const ChromeTabMutedInfoReason capture =
      ChromeTabMutedInfoReason('capture');

  /// An extension, identified by the extensionId field, set the muted state.
  static const ChromeTabMutedInfoReason extension =
      ChromeTabMutedInfoReason('extension');

  static const List<ChromeTabMutedInfoReason> values = [
    user,
    capture,
    extension,
  ];

  static ChromeTabMutedInfoReason? from(String? value) {
    return value != null
        ? ChromeTabMutedInfoReason.values.singleWhere(
            (ChromeTabMutedInfoReason e) => e.value == value,
          )
        : null;
  }
}
