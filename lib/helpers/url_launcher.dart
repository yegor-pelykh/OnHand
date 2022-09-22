import 'dart:html';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:on_hand/chrome_bridge/chrome_tabs.dart';
import 'package:on_hand/chrome_bridge/chrome_tabs_create_params.dart';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/helpers/device_info.dart';

abstract class UrlLauncher {
  static Future<void> _launchInsideBrowser(Uri uri, bool newTab) async {
    final a = AnchorElement(href: uri.toString());
    if (newTab) {
      a.target = '_blank';
      final browserName = await DeviceInfo.getBrowserName();
      final evt = MouseEvent(
        'click',
        ctrlKey: browserName == BrowserName.firefox,
      );
      a.dispatchEvent(evt);
    } else {
      a.target = '_self';
      final evt = MouseEvent('click');
      a.dispatchEvent(evt);
    }
  }

  static Future<void> _launchInNewTabInsideExtension(Uri uri) async {
    await ChromeTabs.create(
      ChromeTabsCreateParams(
        url: uri.toString(),
        active: false,
      ),
    );
  }

  static Future<void> launch(Uri uri, bool newTab) async {
    if (newTab && ChromeCommon.isWebExtension) {
      await _launchInNewTabInsideExtension(uri);
    } else {
      await _launchInsideBrowser(uri, newTab);
    }
  }
}
