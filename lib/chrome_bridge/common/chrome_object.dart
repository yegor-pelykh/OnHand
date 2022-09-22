import 'dart:js';

/// The abstract superclass of objects that can hold [JsObject] proxies.
abstract class ChromeObject {
  final JsObject jsProxy;

  /// Create a new instance of a [ChromeObject], which creates and delegates to a [JsObject] proxy
  ChromeObject() : jsProxy = JsObject(context['Object']);

  /// Create a new instance of a [ChromeObject], which delegates to the given [JsObject] proxy.
  ChromeObject.fromProxy(this.jsProxy);

  JsObject toJs() => jsProxy;

  @override
  String toString() => jsProxy.toString();
}
