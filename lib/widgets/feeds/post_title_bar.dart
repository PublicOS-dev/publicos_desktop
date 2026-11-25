import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/post_signature_mark.dart'
    show postIsOutside, ChannelHostMark, SignedCopyBadge;

/// The title in the bar of an opened post: the channel's own title, then
/// "hosted by <owner>" when the owner's claim on the channel says so.
///
///  * A good claim: "hosted by owner", unless the line under the author
///    already names that account (the post was found on the owner's own
///    profile) or, with no found-at, the owner is the author.
///  * No claim: no host is named, an amber `!` says there is no owner's
///    signature to check.
///  * A bad claim: no host is named, a red `!` says a signature is given
///    and it is bad.
///  * A good claim that names another address: the host as above, and the
///    quiet shield of a signed copy.
///  * Could not be checked: the title alone.
///
/// An outside feed has no owner: its title is followed by the small feed
/// mark and nothing else.
class PostTitleBar extends StatelessWidget {
  final Post post;
  final String title;

  const PostTitleBar({super.key, required this.post, required this.title});

  static bool _same(String? a, String? b) =>
      a != null && b != null && a.toLowerCase() == b.toLowerCase();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final titleText = Flexible(
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tokens.starkWhite,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
    if (postIsOutside(post)) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        titleText,
        const SizedBox(width: 5),
        Icon(Icons.rss_feed_rounded,
            size: 13, color: tokens.textDim.withValues(alpha: 0.9)),
      ]);
    }
    final owner = post.channelOwnerAddress;
    final verdict = owner == null
        ? null
        : ChannelClaims.verdictForUrl(post.url ?? post.feedUrl ?? '');
    if (owner == null || verdict == null) {
      return Row(mainAxisSize: MainAxisSize.min, children: [titleText]);
    }
    return FutureBuilder<ChannelClaimVerdict>(
      future: verdict,
      builder: (context, snap) {
        final v = snap.data ?? ChannelClaimVerdict.unknown;
        final foundAt = post.feedFoundAtAccountAddress;
        final hasFoundAt = foundAt != null &&
            foundAt.isNotEmpty &&
            (post.feedRecordKey?.isNotEmpty ?? false);
        // Already said elsewhere on the screen: by the found-at line, or,
        // with none, by the author's own name.
        final saidElsewhere = hasFoundAt
            ? _same(foundAt, owner)
            : _same(owner, post.postAuthorAddress);
        final good = v.state == ChannelClaimState.good ||
            v.state == ChannelClaimState.copy;
        final dim = TextStyle(
            color: tokens.textDim, fontSize: 12, fontWeight: FontWeight.w400);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            titleText,
            if (good && !saidElsewhere) ...[
              Text(' ${context.l10n.channelHeaderHostedBy} ', style: dim),
              _Owner(address: owner),
            ],
            if (v.state == ChannelClaimState.copy) ...[
              const SizedBox(width: 5),
              const SignedCopyBadge(channel: true),
            ],
            if (v.state == ChannelClaimState.none)
              const ChannelHostMark(bad: false),
            if (v.state == ChannelClaimState.bad)
              const ChannelHostMark(bad: true),
          ],
        );
      },
    );
  }
}

/// The owner as a mini contact icon and a name, from the saved contact; the
/// short address until (or unless) one is found.
class _Owner extends StatelessWidget {
  final String address;
  const _Owner({required this.address});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final short = address.length < 10
        ? address
        : '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
    Future<Contact?> load() async {
      try {
        return await PublicOSContacts.getContact(
            EthereumAddress.fromHex(address));
      } catch (_) {
        return null;
      }
    }

    return FutureBuilder<Contact?>(
      future: load(),
      builder: (context, snap) {
        final c = snap.data;
        final name = c?.displayName;
        return Row(mainAxisSize: MainAxisSize.min, children: [
          if (c != null) ...[
            GlassContactIcon(contact: c, size: 15),
            const SizedBox(width: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              name == null || name.isEmpty ? short : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.starkWhite.withValues(alpha: 0.86),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ]);
      },
    );
  }
}
