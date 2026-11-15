// [WebViewHost] over WebView2, via the vendored `zero_webview_windows`.
//
// The desktop twin of publicos_client's `WebViewFlutterHost`. Same contract,
// different engine -- and one real capability difference that is stated rather
// than hidden: this engine CAN inject at document-start, and the mobile one
// cannot.

import 'dart:async';
import 'dart:convert';

import 'package:publicos_web3_bridge/publicos_web3_bridge.dart';
import 'package:zero_webview_windows/zero_webview_windows.dart';

class WebView2Host implements WebViewHost {
  final WebviewController controller;
  final void Function(String message)? log;

  final _events = StreamController<WebViewEvent>.broadcast();
  final _messages = StreamController<String>.broadcast();
  final _subs = <StreamSubscription<dynamic>>[];

  String _lastUrl = '';

  WebView2Host(this.controller, {this.log}) {
    // WebView2 reports these as separate streams rather than one delegate, so
    // they are folded back into the single lifecycle the bridge expects.
    _subs.add(controller.url.listen((u) {
      if (u.isEmpty) return;
      _lastUrl = u;
      _events.add(WebViewEvent(WebViewEventKind.urlChanged, u));
    }));

    _subs.add(controller.loadingState.listen((s) {
      switch (s) {
        case LoadingState.loading:
          _events.add(WebViewEvent(WebViewEventKind.pageStarted, _lastUrl));
        case LoadingState.navigationCompleted:
          _events.add(WebViewEvent(WebViewEventKind.pageFinished, _lastUrl));
        case LoadingState.none:
          break;
      }
    }));

    _subs.add(controller.onLoadError.listen((e) {
      _events.add(WebViewEvent(
        WebViewEventKind.error,
        _lastUrl,
        message: e.name,
      ));
    }));

    // The page posts on WebView2's own channel. Arrives already JSON-decoded,
    // so it is re-encoded to the raw string the bridge's dispatcher parses --
    // one wire format for both engines rather than two code paths above.
    _subs.add(controller.webMessage.listen((msg) {
      _messages.add(msg is String ? msg : jsonEncode(msg));
    }));
  }

  @override
  Stream<WebViewEvent> get events => _events.stream;

  @override
  Stream<String> get messages => _messages.stream;

  @override
  Future<void> load(Uri url) => controller.loadUrl(url.toString());

  @override
  Future<void> runJavaScript(String js) async {
    await controller.executeScript(js);
  }

  @override
  Future<Object?> evaluate(String js) => controller.executeScript(js);

  /// Real document-start injection, unlike the mobile host.
  ///
  /// Registered once and it survives every navigation, so the provider is
  /// already present when a page's own first script runs.
  @override
  Future<void> injectAtDocumentStart(String js) async {
    await controller.addScriptToExecuteOnDocumentCreated(js);
    log?.call('[webview] provider registered at document-start');
  }

  @override
  bool get supportsDocumentStartInjection => true;

  @override
  Future<void> postMessage(String json) async {
    // Answers go back by evaluating into the page, the same way the mobile host
    // does. WebView2's postWebMessage would work too, but keeping one response
    // path means one thing to get right.
    await controller.executeScript(
      'window.FlutterWeb3Bridge && '
      'window.FlutterWeb3Bridge.resolveRequest($json);',
    );
  }

  @override
  Future<void> goBack() => controller.goBack();

  /// WebView2 reports history as a pushed event rather than a query, so the
  /// last value is mirrored here.
  bool canGoBackNow = false;

  @override
  Future<bool> canGoBack() async => canGoBackNow;

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _events.close();
    await _messages.close();
  }
}
