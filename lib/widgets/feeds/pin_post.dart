import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/go_to_feed.dart';
import 'package:publicos_desktop/widgets/profile/create_record_page.dart';
import 'package:publicos_desktop/widgets/profile/profile_post_card.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/fullscreen_overlay.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// Whether [post] can be pinned by the signed-in account: it must carry a
/// post permalink (PublicOS posts only; an external RSS item's `url` is the
/// article, not something that returns the post), and the viewer must be an
/// individual account. Org profiles pin through a vote, not built yet.
bool canPinPost(Post post) {
  final url = post.url;
  if (url == null || postRefOf(url) == null) return false;
  if (PublicOS.myPublicosAddress == null) return false;
  return AppStateNotifier.currentMyContact?.isOrgAccount != true;
}

/// "Pin to profile". Opens the card editor
/// in pin mode on a draft `cardKind:'post'` card (default 4x2) whose value is
/// the post's URL, then writes it to the viewer's own profile, first or last.
Future<void> pinPostToProfile(BuildContext context, Post post) async {
  final url = post.url;
  if (url == null || postRefOf(url) == null) return;
  final draft = Record.asProfile(
    key: 'card.post_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
    // Verbatim: the SSP matches the owner segment case-sensitively.
    value: url,
    expiration: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    width: 4,
    height: 2,
    noTitle: true,
    customMetadataAttributes: {
      'cardKind': PostCardMeta.kind,
      // Where the pinner found it, so the card's "Go to feed" lands there.
      if (feedLinkOf(post) case final link?) PostCardMeta.feedLink: link,
    },
  );
  await showCreateRecordSheet(
    context,
    record: draft,
    onSave: (_) {},
    onPin: (record, toTop) async {
      Navigator.of(context).pop();
      await _writePin(context, record, toTop);
    },
  );
}

Future<void> _writePin(BuildContext context, Record record, bool toTop) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final overlay = FullscreenOverlay.showTransaction(context, l10n.postCardPinSaving);
  var ok = false;
  try {
    final addr = PublicOS.myPublicosAddress;
    if (addr == null) return;
    // Ranks come from the chain, not the local copy: a stale snapshot could
    // hand out a rank another card already holds.
    final me = await PublicOSContacts.fetchContact(EthereumAddress.fromHex(addr));
    final ranked = me.records
        .where((r) =>
            r.type == RecordType.profile &&
            (r.profileSubtype == ProfileSubtype.card ||
                r.profileSubtype == ProfileSubtype.social) &&
            r.rank != null)
        .map((r) => r.rank!)
        .toList()
      ..sort();
    final rank = toTop
        ? keyBetween(null, ranked.isEmpty ? null : ranked.first)
        : keyBetween(ranked.isEmpty ? null : ranked.last, null);
    ok = await PublicOSContacts.setRecord(record.copyWith(rank: rank));
    if (ok) await AppStateNotifier.loadMyContact();
  } catch (_) {
    ok = false;
  } finally {
    overlay.dismiss();
  }
  messenger.showSnackBar(SnackBar(
    content: Text(ok ? l10n.postCardPinDone : l10n.postCardPinFailed),
    behavior: SnackBarBehavior.floating,
  ));
}
