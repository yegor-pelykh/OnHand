import 'dart:js';
import 'package:on_hand/chrome_bridge/chrome_message_sender.dart';

/// Fired when a message is sent from either an extension process (by
/// [runtime.sendMessage]) or a content script (by [tabs.sendMessage]).
class ChromeMessageEvent {
  /// `optional`
  /// The message sent by the calling script.
  final dynamic message;

  /// Message sender.
  final ChromeMessageSender sender;

  /// Function to call (at most once) when you have a response. The argument
  /// should be any JSON-ifiable object. If you have more than one `onMessage`
  /// listener in the same document, then only one may send a response. This
  /// function becomes invalid when the event listener returns, *unless you
  /// return true* from the event listener to indicate you wish to send a
  /// response asynchronously (this will keep the message channel open to the
  /// other end until `sendResponse` is called).
  final JsFunction sendResponse;

  ChromeMessageEvent(this.message, this.sender, this.sendResponse);

  static ChromeMessageEvent from(
      JsObject message, JsObject sender, JsFunction sendResponse) {
    return ChromeMessageEvent(
      message,
      ChromeMessageSender.fromProxy(sender),
      sendResponse,
    );
  }
}
