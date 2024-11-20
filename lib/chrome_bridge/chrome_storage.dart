import 'dart:js';
import 'package:on_hand/chrome_bridge/common/chrome_common.dart';
import 'package:on_hand/chrome_bridge/common/chrome_completer.dart';
import 'package:on_hand/chrome_bridge/common/chrome_object.dart';
import 'package:on_hand/chrome_bridge/common/chrome_stream_controller.dart';

class StorageArea extends ChromeObject {
  StorageArea();
  StorageArea.fromProxy(super.jsProxy) : super.fromProxy();

  /// Gets one or more items from storage.
  ///
  /// [keys] A single key to get, list of keys to get, or a dictionary specifying
  /// default values (see description of the object).  An empty list or object
  /// will return an empty result object.  Pass in `null` to get the entire
  /// contents of storage.
  ///
  /// Returns:
  /// Object with items in their key-value mappings.
  Future<Map<String, dynamic>> get([dynamic keys]) {
    final completer =
        ChromeCompleter<Map<String, dynamic>>.oneArg(ChromeCommon.mapify);
    jsProxy.callMethod('get', [ChromeCommon.jsify(keys), completer.callback]);
    return completer.future;
  }

  /// Gets the amount of space (in bytes) being used by one or more items.
  ///
  /// [keys] A single key or list of keys to get the total usage for. An empty
  /// list will return 0. Pass in `null` to get the total usage of all of
  /// storage.
  ///
  /// Returns:
  /// Amount of space being used in storage, in bytes.
  Future<int> getBytesInUse([dynamic keys]) {
    var completer = ChromeCompleter<int>.oneArg();
    jsProxy.callMethod(
        'getBytesInUse', [ChromeCommon.jsify(keys), completer.callback]);
    return completer.future;
  }

  /// Sets multiple items.
  ///
  /// [items] An object which gives each key/value pair to update storage with.
  /// Any other key/value pairs in storage will not be affected.
  ///
  /// Primitive values such as numbers will serialize as expected. Values with a
  /// `typeof` `"object"` and `"function"` will typically serialize to `{}`, with
  /// the exception of `Array` (serializes as expected), `Date`, and `Regex`
  /// (serialize using their `String` representation).
  Future set(Map<String, dynamic> items) {
    var completer = ChromeCompleter.noArgs();
    jsProxy.callMethod('set', [ChromeCommon.jsify(items), completer.callback]);
    return completer.future;
  }

  /// Removes one or more items from storage.
  ///
  /// [keys] A single key or a list of keys for items to remove.
  Future remove(dynamic keys) {
    var completer = ChromeCompleter.noArgs();
    jsProxy
        .callMethod('remove', [ChromeCommon.jsify(keys), completer.callback]);
    return completer.future;
  }

  /// Removes all items from storage.
  Future clear() {
    var completer = ChromeCompleter.noArgs();
    jsProxy.callMethod('clear', [completer.callback]);
    return completer.future;
  }
}

class LocalStorageArea extends StorageArea {
  LocalStorageArea();

  LocalStorageArea.fromProxy(super.jsProxy) : super.fromProxy();

  /// The maximum amount (in bytes) of data that can be stored in local storage,
  /// as measured by the JSON stringification of every value plus every key's
  /// length. This value will be ignored if the extension has the
  /// `unlimitedStorage` permission. Updates that would cause this limit to be
  /// exceeded fail immediately and set [runtime.lastError].
  int get quotaBytes => jsProxy['QUOTA_BYTES'];
}

/// StorageChange info
class StorageChange {
  /// The new value of the item, if there is a new value.
  final dynamic newValue;

  /// The old value of the item, if there was an old value.
  final dynamic oldValue;

  StorageChange(this.newValue, this.oldValue);

  StorageChange.fromMap(Map<dynamic, dynamic> map)
      : newValue = map['newValue'],
        oldValue = map['oldValue'];
}

/// Fired when one or more items change.
class StorageOnChangedEvent {
  /// Object mapping each key that changed to its corresponding
  /// [storage.StorageChange] for that item.
  final Map<String, StorageChange> changes;

  /// The name of the storage area (`"sync"`, `"local"` or `"managed"`) the
  /// changes are for.
  final String areaName;

  StorageOnChangedEvent(this.changes, this.areaName);

  static StorageOnChangedEvent from(JsObject changes, String areaName) {
    final convertedChanges =
        ChromeCommon.mapify(changes).map<String, StorageChange>((key, value) {
      return MapEntry(key.toString(), StorageChange.fromMap(value));
    });
    return StorageOnChangedEvent(convertedChanges, areaName);
  }
}

abstract class ChromeStorage {
  /// Fired when one or more items change.
  static ChromeStreamController<StorageOnChangedEvent>? _onChanged;
  static Stream<StorageOnChangedEvent> get onChanged {
    if (_onChanged == null) {
      getApi() => ChromeCommon.storage;
      _onChanged = ChromeStreamController<StorageOnChangedEvent>.twoArgs(
        getApi,
        'onChanged',
        StorageOnChangedEvent.from,
      );
    }
    return _onChanged!.stream;
  }

  /// Items in the `local` storage area are local to each machine.
  static LocalStorageArea get local =>
      LocalStorageArea.fromProxy(ChromeCommon.storage['local']);
}
