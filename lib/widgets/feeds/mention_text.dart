import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_mentions/zero_mentions.dart';

import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Resolves mention addresses to current display names — local-first, chain
/// on miss, **never persisted** (the mention_system hard rule: no ghost
/// contact rows; `fetchContact` is display-only and only self-persists).
///
/// One instance per view (page/list) so every unique address resolves once
/// and the cache dies with the view — names re-read fresh on next open, no
/// TTL bookkeeping. Widgets listen and restyle when names land.
class MentionResolver extends ChangeNotifier {
  MentionResolver({Map<String, Contact> seed = const {}}) {
    for (final e in seed.entries) {
      if (e.value.displayName.isNotEmpty) {
        _names[e.key.toLowerCase()] = e.value.displayName;
      }
    }
  }

  final Map<String, String> _names = {}; // lower 0x… → display name
  final Set<String> _inFlight = {};
  final Set<String> _failed = {}; // don't re-hammer the chain this view
  bool _storedLoaded = false;
  bool _disposed = false;

  /// Resolved name, or null (unknown / still resolving / failed → caller
  /// falls back to a truncated address).
  String? nameOf(String address) => _names[address.toLowerCase()];

  /// Kick off resolution for any of [addresses] not yet known. Fire-and-
  /// forget: listeners are notified as names land, render never blocks.
  void ensure(Iterable<String> addresses) {
    final missing = <String>[];
    for (final a in addresses) {
      final k = a.toLowerCase();
      if (_names.containsKey(k) || _inFlight.contains(k) || _failed.contains(k)) {
        continue;
      }
      _inFlight.add(k);
      missing.add(a);
    }
    if (missing.isNotEmpty) _resolve(missing);
  }

  Future<void> _resolve(List<String> addresses) async {
    // L1 — one local-DB read per view, shared by every request.
    if (!_storedLoaded) {
      _storedLoaded = true;
      try {
        final stored = await PublicOSContacts.getStoredContacts();
        for (final c in stored) {
          final addr = c.publicosAddress?.eip55With0x;
          if (addr != null && c.displayName.isNotEmpty) {
            _names.putIfAbsent(addr.toLowerCase(), () => c.displayName);
          }
        }
      } catch (_) {}
    }
    var landed = false;
    for (final address in addresses) {
      final k = address.toLowerCase();
      if (_names.containsKey(k)) {
        _inFlight.remove(k);
        landed = true;
        continue;
      }
      // L2 — chain read, display-only. Deliberately NOT saved: mention
      // resolution must never create a contact row.
      try {
        final contact =
            await PublicOSContacts.fetchContact(EthereumAddress.fromHex(address));
        if (contact.displayName.isNotEmpty) {
          _names[k] = contact.displayName;
          landed = true;
        } else {
          _failed.add(k);
        }
      } catch (_) {
        _failed.add(k);
      }
      _inFlight.remove(k);
    }
    if (landed && !_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Drop-in replacement for a plain `Text` over wire content that may carry
/// `@[0xAddr]` tokens: parses, resolves via [resolver], renders mentions as
/// styled tappable `@displayname` spans (truncated address while unresolved),
/// tap → profile. Plain text renders unchanged — including the token-free
/// common case.
class MentionText extends StatefulWidget {
  const MentionText(
    this.text, {
    super.key,
    this.resolver,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  /// Wire-form text (raw `@[0xAddr]` tokens allowed).
  final String text;

  /// Shared per-view resolver; when null the widget owns a private one
  /// (fine for isolated sites — feed cards resolve lazily per card).
  final MentionResolver? resolver;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Bio and text cards align their text; posts leave it null.
  final TextAlign? textAlign;

  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  MentionResolver? _ownResolver;
  final List<TapGestureRecognizer> _recognizers = [];

  MentionResolver get _resolver =>
      widget.resolver ?? (_ownResolver ??= MentionResolver());

  @override
  void initState() {
    super.initState();
    _resolver.addListener(_onResolved);
  }

  @override
  void didUpdateWidget(MentionText old) {
    super.didUpdateWidget(old);
    if (old.resolver != widget.resolver) {
      (old.resolver ?? _ownResolver)?.removeListener(_onResolved);
      _resolver.addListener(_onResolved);
    }
  }

  void _onResolved() {
    if (mounted) setState(() {});
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    (widget.resolver ?? _ownResolver)?.removeListener(_onResolved);
    _ownResolver?.dispose();
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = parseMentions(widget.text);
    // Fast path: no tokens → plain Text, zero overhead.
    if (segments.length == 1 && segments.single is TextSegment) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
        textAlign: widget.textAlign,
      );
    }

    final tokens = GlassTokens.of(context);
    final mentionStyle = (widget.style ?? const TextStyle()).copyWith(
      color: tokens.connectedAccent,
      fontWeight: FontWeight.w600,
    );

    _resolver.ensure(
        segments.whereType<MentionRef>().map((segment) => segment.address));

    _disposeRecognizers();
    final spans = <InlineSpan>[
      for (final seg in segments)
        switch (seg) {
          TextSegment(:final text) => TextSpan(text: text),
          MentionRef(:final address) => TextSpan(
              text:
                  '@${_resolver.nameOf(address) ?? truncatedAddress(address)}',
              style: mentionStyle,
              recognizer: _recognizer(address),
            ),
        },
    ];
    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
    );
  }

  TapGestureRecognizer _recognizer(String address) {
    final r = TapGestureRecognizer()
      ..onTap = () => AppNav.toProfile(context, address);
    _recognizers.add(r);
    return r;
  }
}
