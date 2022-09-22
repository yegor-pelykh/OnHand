import 'package:on_hand/chrome_bridge/chrome_tab.dart';
import 'package:on_hand/chrome_bridge/chrome_tabs_create_params.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_completer.dart';

abstract class ChromeTabs {
  static Future<ChromeTab> create(ChromeTabsCreateParams properties) async {
    final completer = ChromeCompleter<ChromeTab>.oneArg(ChromeTab.fromProxy);
    ChromeCommon.tabs.callMethod('create', [
      ChromeCommon.jsify(properties),
      completer.callback,
    ]);
    return completer.future;
  }
}
