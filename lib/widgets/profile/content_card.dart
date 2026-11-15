import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

// The content card: the one card a person makes by hand. It merges two legacy
// kinds, the text card and the image card. A background colour or gradient, an
// optional image, a title, a body text and a link, all on one record.
//
// SHARED VERBATIM between publicos_client (lib/components/profile/) and
// publicos_desktop (lib/widgets/profile/). It imports packages only, so the
// file is byte-identical in both apps: change it in one, copy it to the other.
//
// Core hands out `Record`; how a card reads and looks is the client's business,
// so this parser lives here and not in PublicOS_Core.

/// A two-stop linear gradient, stored as
/// `metadata.gradient = {colors: [argb, argb], angle}`.
///
/// `angle` follows the CSS convention (the website paints the same record in
/// a browser): 90 runs left to right, 180 top to bottom. The record's plain
/// `color` is written as the first stop, so a reader that knows no gradient
/// still paints a sensible plate.
class CardGradient {
  final Color from;
  final Color to;
  final double angle;

  const CardGradient({required this.from, required this.to, this.angle = 135});

  static CardGradient? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final colors = raw['colors'];
    if (colors is! List || colors.length < 2) return null;
    final a = colors[0];
    final b = colors[1];
    if (a is! num || b is! num) return null;
    final angle = raw['angle'];
    return CardGradient(
      from: Color(a.toInt()),
      to: Color(b.toInt()),
      angle: angle is num ? angle.toDouble() : 135,
    );
  }

  Map<String, dynamic> toMetadata() => {
        'colors': [from.toARGB32(), to.toARGB32()],
        'angle': angle,
      };

  /// [opacity] replaces each stop's alpha, the way the plain plate applies the
  /// record's opacity. A fully transparent stop stays transparent: raising its
  /// alpha would turn `0x00000000` into opaque black.
  LinearGradient toLinearGradient({double opacity = 1}) {
    final r = angle * math.pi / 180;
    final dx = math.sin(r);
    final dy = -math.cos(r);
    Color apply(Color c) => c.a == 0 ? c : c.withValues(alpha: opacity);
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: [apply(from), apply(to)],
    );
  }
}

/// The card's tip action, stored as `metadata.tip = {to, chainId, token}`.
/// Tapping the card opens the send sheet locked to exactly this wallet, chain
/// and token, at amount 0. There is deliberately no amount.
///
/// `token` is `"OX"` on chain 4489 (OX's contract address changes with the
/// chain, so it is never stored), `"native"` for another chain's own coin, or
/// an ERC-20 contract address.
class CardTip {
  final String to;
  final int chainId;
  final String token;

  const CardTip({required this.to, required this.chainId, required this.token});

  static const ox = 'OX';
  static const native = 'native';

  static final _address = RegExp(r'^0x[0-9a-fA-F]{40}$');

  static bool isAddress(String s) => _address.hasMatch(s);

  bool get isOx => token == ox;
  bool get isNative => token == native;

  static CardTip? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final to = raw['to'];
    final chainId = raw['chainId'];
    final token = raw['token'];
    if (to is! String || !isAddress(to.trim())) return null;
    if (chainId is! num) return null;
    if (token is! String) return null;
    final t = token.trim();
    if (t != ox && t != native && !isAddress(t)) return null;
    return CardTip(to: to.trim(), chainId: chainId.toInt(), token: t);
  }

  Map<String, dynamic> toMetadata() => {
        'to': to,
        'chainId': chainId,
        'token': token,
      };
}

class ContentCard {
  final String title;
  final String body;

  /// Background image URL. When present the card paints no colour or gradient
  /// under it (two layers clipped at one radius leave a coloured fringe).
  final String? image;
  final String? link;

  /// The tip action. A card has a link or a tip, never both.
  final CardTip? tip;
  final Color? color;
  final CardGradient? gradient;
  final double opacity;
  final int width;
  final int height;

  const ContentCard({
    this.title = '',
    this.body = '',
    this.image,
    this.link,
    this.tip,
    this.color,
    this.gradient,
    this.opacity = 1.0,
    this.width = 2,
    this.height = 1,
  });

  bool get hasTitle => title.trim().isNotEmpty;
  bool get hasBody => body.trim().isNotEmpty;
  bool get hasImage => image != null && image!.trim().isNotEmpty;
  bool get hasLink => !hasTip && link != null && link!.trim().isNotEmpty;
  bool get hasTip => tip != null;

  /// A card that paints nothing and says nothing: the transparent spacer a
  /// user drops in to organise the grid.
  bool get isSpacer =>
      !hasTip && // a tip card is never invisible: it takes money
      !hasTitle &&
      !hasBody &&
      !hasImage &&
      gradient == null &&
      color != null &&
      color!.a == 0;

  /// The card kind as the renderer dispatches it. Only NFT and app cards carry
  /// an explicit `cardKind`; the rest are told apart by `isImageRecord`.
  static String kindOf(Record r) {
    final kind = r.metadata['cardKind'];
    if (kind is String) return kind;
    return r.metadata['isImageRecord'] == true ? 'image' : 'text';
  }

  /// True for the records this class reads: the untagged `card.*` kinds.
  static bool isContent(Record r) {
    if (r.profileSubtype != ProfileSubtype.card) return false;
    final kind = kindOf(r);
    return kind == 'text' || kind == 'image';
  }

  /// A fresh base36 millisecond id, the convention for `card.<id>` keys.
  static String newId() =>
      DateTime.now().millisecondsSinceEpoch.toRadixString(36);

  /// Reads all three shapes on chain:
  /// - legacy **text** card: `value` = body;
  /// - legacy **image** card: `isImageRecord: true`, `value` = image URL;
  /// - the merged shape: `value` = body, `metadata.image` = image URL.
  factory ContentCard.fromRecord(Record r) {
    final m = r.metadata;
    final legacyImage = m['cardKind'] == null && m['isImageRecord'] == true;
    final name = m['name'];
    final untitled = r.noTitle || m['noTitle'] == true;
    final image = legacyImage ? r.value : m['image'];
    final link = r.link;
    // A record carrying both keeps the tip: a leftover link is plausible, a
    // tip key only exists because someone added it. The next save drops the
    // link.
    final tip = CardTip.tryParse(m['tip']);
    return ContentCard(
      title: untitled || name is! String ? '' : name,
      body: legacyImage ? '' : r.value,
      image: image is String && image.trim().isNotEmpty ? image.trim() : null,
      link: tip == null && link != null && link.trim().isNotEmpty
          ? link.trim()
          : null,
      tip: tip,
      color: r.color,
      gradient: CardGradient.tryParse(m['gradient']),
      opacity: (m['opacity'] as num?)?.toDouble() ?? 1.0,
      width: r.width,
      height: r.height,
    );
  }

  /// Always writes the merged shape. A legacy image card edited through here is
  /// rewritten into it (value -> `metadata.image`); no migration otherwise.
  ///
  /// Expiration 0 = never: the contract skips its check for 0
  /// (AccountBlueprint `_setRecord`). A card is the owner's for as long as
  /// the account lives.
  Record toRecord({required String id}) {
    return Record.asProfile(
      key: 'card.$id',
      value: body.trim(),
      expiration: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      link: hasLink ? link!.trim() : null,
      color: gradient?.from ?? color,
      width: width,
      height: height,
      noTitle: !hasTitle,
      opacity: opacity,
      customMetadataAttributes: {
        'name': title.trim(),
        if (hasImage) 'image': image!.trim(),
        if (gradient != null) 'gradient': gradient!.toMetadata(),
        if (tip != null) 'tip': tip!.toMetadata(),
      },
    );
  }
}
