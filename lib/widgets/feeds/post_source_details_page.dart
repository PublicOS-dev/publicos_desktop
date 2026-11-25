import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

// PostSignatureVerifier is exported via publicos_core barrel.

/// Full-screen post source / verification page.
///
/// Pushed as a glass page from the post 3-dot menu's "View source" item.
/// Three layers of disclosure:
///   1. Top human card — avatar + name + channel + relative time + verify chip
///   2. WHO section — three always-visible rows: channel owner, post author,
///      signed by. Each address is resolved against the contacts service so
///      normal users see human names, not 0x addresses.
///   3. Technical details — every raw field, collapsed by default.
class PostSourceDetailsPage extends StatefulWidget {
  final Post post;

  /// **Desktop delta** -- see [PostDetailPage.onBack]. Rendered in-place, so it
  /// needs an explicit way back.
  final VoidCallback? onBack;

  const PostSourceDetailsPage({super.key, required this.post, this.onBack});

  @override
  State<PostSourceDetailsPage> createState() => _PostSourceDetailsPageState();
}

class _PostSourceDetailsPageState extends State<PostSourceDetailsPage> {
  /// address(lowercase) → Contact, populated as resolutions complete.
  final Map<String, Contact> _resolved = {};
  bool _resolving = true;

  /// Core's verdict on the signature (the once-per-post check, content off
  /// thread then the signer's account on chain); null while it runs.
  PostVerificationResult? _signature;

  @override
  void initState() {
    super.initState();
    _resolveContacts();
    PostSignatureVerifier.verdictOf(widget.post).then((r) {
      if (mounted) setState(() => _signature = r);
    });
  }

  Future<void> _resolveContacts() async {
    final addresses = <String>{};
    final p = widget.post;
    void add(String? a) {
      if (a != null && a.isNotEmpty) addresses.add(a.toLowerCase());
    }
    add(p.feedFoundAtAccountAddress);
    add(p.channelOwnerAddress);
    add(p.postAuthorAddress);
    add(p.signerAddress);
    if (addresses.isEmpty) {
      if (mounted) setState(() => _resolving = false);
      return;
    }
    // Local DB first to avoid the on-chain refresh that resolveByIdentifier
    // does even on local hits (it calls fetchContact for freshness, which
    // costs a chain round-trip per address — adds up under public-RPC rate
    // limits). Only fall back to the full chain walk when nothing local
    // matches (foreign accounts the user hasn't interacted with).
    final results = await Future.wait(addresses.map((addr) async {
      try {
        final local = await PublicOSContacts.searchContacts(addr);
        if (local != null) return MapEntry(addr, local);
        final remote = await PublicOSContacts.resolveByIdentifier(addr);
        return MapEntry(addr, remote);
      } catch (_) {
        return MapEntry(addr, null);
      }
    }));
    if (!mounted) return;
    setState(() {
      for (final e in results) {
        if (e.value != null) _resolved[e.key] = e.value!;
      }
      _resolving = false;
    });
  }

  Contact? _contactFor(String? address) {
    if (address == null || address.isEmpty) return null;
    return _resolved[address.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final post = widget.post;
    // The verdict flows into the signer row below: a signature is about the
    // signer, not the author, so the chip sits next to the Signer row.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          backgroundColor: tokens.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: tokens.starkWhite),
          // DESKTOP DELTA. On mobile this page is PUSHED, so Scaffold derives a
          // back button from the route stack automatically. Desktop renders it
          // IN PLACE inside the feeds reading column -- there is no route to pop,
          // so Flutter would give it no back affordance at all. [onBack] supplies
          // one; falling back to Navigator.pop keeps it correct if it is ever
          // pushed after all.
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            context.l10n.postSourceDetailsPageTitle,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              height: 1.2,
            ),
          ),
          centerTitle: false,
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _HumanHeader(
              post: post,
              // No channel-owner fallback: show the post's real author
              // (resolved, else its short address). Borrowing the owner's
              // identity here would misattribute authorship — e.g. a signing
              // key with no account on this chain would render as the owner.
              authorContact: _contactFor(post.postAuthorAddress),
              resolving: _resolving,
            ),
            if (_showDiscoveredVia(post))
              _DiscoveredViaSection(
                originAddress: post.feedFoundAtAccountAddress,
                originContact: _contactFor(post.feedFoundAtAccountAddress),
                resolving: _resolving,
              ),
            _WhoSection(
              ownerAddress: post.channelOwnerAddress,
              // No owner fallback. The author is resolved on its own; an
              // unresolved author shows its short address and a missing author
              // drops the row entirely (handled in _WhoSection). The channel
              // owner is the row directly above — reusing it here would lie
              // about who wrote the post (a key with no account surfacing
              // under the owner's name).
              authorAddress: post.postAuthorAddress,
              signerAddress: post.signerAddress,
              ownerContact: _contactFor(post.channelOwnerAddress),
              authorContact: _contactFor(post.postAuthorAddress),
              signerContact: _contactFor(post.signerAddress),
              signature: _signature,
              resolving: _resolving,
            ),
            _TechnicalDetailsBlock(post: post),
          ],
        ),
      ),
    );
  }
}

/// Whether to surface the "Discovered via" row — only when the feed URL was
/// published on a profile that isn't the channel's actual owner (e.g. an
/// org's record tab pointing at a channel a member hosts on their own
/// account). Collapsing the two into one "owner" field has burned us in
/// the past; separating them here keeps the user's trust model honest.
bool _showDiscoveredVia(Post p) {
  final origin = p.feedFoundAtAccountAddress?.toLowerCase();
  final owner = p.channelOwnerAddress?.toLowerCase();
  if (origin == null || origin.isEmpty) return false;
  if (owner == null || owner.isEmpty) return false;
  return origin != owner;
}

// ============================================================================
// Top — human-readable header
// ============================================================================

class _HumanHeader extends StatelessWidget {
  final Post post;
  final Contact? authorContact;
  final bool resolving;

  const _HumanHeader({
    required this.post,
    required this.authorContact,
    required this.resolving,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final displayName = authorContact?.displayName ??
        (resolving ? '…' : _shortAddress(post.postAuthorAddress));
    final channelName = post.feedTitle ??
        (post.channelSlug != null
            ? '#${post.channelSlug}'
            : context.l10n.postSourceDetailsPageUnknownChannel);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border.all(color: tokens.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (authorContact != null)
                  GlassContactIcon(opensProfile: true, contact: authorContact, size: 44)
                else
                  GlassContactIcon(
                    opensProfile: true,
                    address: post.postAuthorAddress ??
                        post.feedFoundAtAccountAddress ??
                        '',
                    size: 44,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ContactProfileTap(contact: authorContact, address: post.postAuthorAddress ?? post.feedFoundAtAccountAddress, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.postSourceDetailsPagePostedIn(channelName),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        post.formattedDate,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// "Discovered via" — shown only when the feed's origin profile differs from
// the channel's actual owner. Gives the user context about how they reached
// this post without conflating "where I found the URL" with "who owns it".
// ============================================================================

class _DiscoveredViaSection extends StatelessWidget {
  final String? originAddress;
  final Contact? originContact;
  final bool resolving;

  const _DiscoveredViaSection({
    required this.originAddress,
    required this.originContact,
    required this.resolving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: context.l10n.postSourceDetailsPageDiscoveredVia),
        _WhoRow(
          label: context.l10n.postSourceDetailsPageFoundOn,
          subtitle: context.l10n.postSourceDetailsPageFoundOnSubtitle,
          address: originAddress,
          contact: originContact,
          resolving: resolving,
        ),
        const _SectionDivider(),
      ],
    );
  }
}

// ============================================================================
// WHO — three always-visible identity rows
// ============================================================================

class _WhoSection extends StatelessWidget {
  final String? ownerAddress;
  final String? authorAddress;
  final String? signerAddress;
  final Contact? ownerContact;
  final Contact? authorContact;
  final Contact? signerContact;

  /// Null while Core is still checking.
  final PostVerificationResult? signature;
  final bool resolving;

  const _WhoSection({
    required this.ownerAddress,
    required this.authorAddress,
    required this.signerAddress,
    required this.ownerContact,
    required this.authorContact,
    required this.signerContact,
    required this.signature,
    required this.resolving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: context.l10n.postSourceDetailsPageWho),
        _WhoRow(
          label: context.l10n.postSourceDetailsPageChannelOwner,
          subtitle: context.l10n.postSourceDetailsPageChannelOwnerSubtitle,
          address: ownerAddress,
          contact: ownerContact,
          resolving: resolving,
        ),
        // Only when the post actually carries an author. No owner fallback:
        // present → resolved name or short address; absent → nothing (the
        // channel owner already has its own row right above).
        if (authorAddress != null && authorAddress!.isNotEmpty)
          _WhoRow(
            label: context.l10n.postSourceDetailsPagePostAuthor,
            subtitle: context.l10n.postSourceDetailsPagePostAuthorSubtitle,
            address: authorAddress,
            contact: authorContact,
            resolving: resolving,
          ),
        // Signer is a session EOA (an authorized key) that signed on behalf of
        // a publicos account. Show the raw session address as the primary
        // identity; the resolved Contact is the parent ACCOUNT (not the
        // session itself) — surface that relationship explicitly so users
        // understand "0x123…456 session of jmsl" instead of just "jmsl".
        // The signature-verification chip lives inline here (not at the top
        // of the card) so the "Signature checked" label visually binds to
        // the signer key + registered-to account, not the author display.
        _SignerRow(
          sessionAddress: signerAddress,
          parentAccount: signerContact,
          signature: signature,
          resolving: resolving,
        ),
        const _SectionDivider(),
      ],
    );
  }
}

class _SignerRow extends StatelessWidget {
  final String? sessionAddress;
  final Contact? parentAccount;
  final PostVerificationResult? signature;
  final bool resolving;

  const _SignerRow({
    required this.sessionAddress,
    required this.parentAccount,
    required this.signature,
    required this.resolving,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final hasAddress = sessionAddress != null && sessionAddress!.isNotEmpty;
    final shortSession = hasAddress ? _shortAddress(sessionAddress) : '—';
    final parentName = parentAccount?.displayName;

    return InkWell(
      onTap: hasAddress ? () => _copy(context, sessionAddress!) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar uses the parent account so users see jmsl's identity,
            // not a generic key icon. Falls back to address-derived initials
            // if the parent didn't resolve.
            if (parentAccount != null)
              GlassContactIcon(contact: parentAccount, size: 32)
            else if (hasAddress)
              GlassContactIcon(address: sessionAddress!, size: 32)
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: tokens.textDim,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.l10n.postSourceDetailsPageSignedBy,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shortSession,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.starkWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parentName != null && parentName.isNotEmpty
                        ? context.l10n
                            .postSourceDetailsPageSessionOf(parentName)
                        : (resolving && hasAddress
                            ? context.l10n.postSourceDetailsPageResolvingParent
                            : context.l10n.postSourceDetailsPageWhoHeldKey),
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Chip sits under the signer subtitle so the validation
                  // claim is read against the signer identity directly,
                  // not against the author name at the top of the card.
                  _ResultChip(signature: signature),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhoRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final String? address;
  final Contact? contact;
  final bool resolving;

  const _WhoRow({
    required this.label,
    required this.subtitle,
    required this.address,
    required this.contact,
    required this.resolving,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final hasAddress = address != null && address!.isNotEmpty;
    final displayName = contact?.displayName ??
        (resolving && hasAddress ? '…' : (hasAddress ? _shortAddress(address) : '—'));
    return InkWell(
      onTap: hasAddress ? () => _copy(context, address!) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (contact != null)
              GlassContactIcon(contact: contact, size: 32)
            else if (hasAddress)
              GlassContactIcon(address: address!, size: 32)
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: tokens.textDim,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.starkWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _shortAddress(String? a) {
  if (a == null || a.isEmpty) return '—';
  if (a.length < 10) return a;
  return '${a.substring(0, 6)}…${a.substring(a.length - 4)}';
}

// ============================================================================
// Bottom — technical details (collapsible wrapper for raw field sections)
// ============================================================================

class _TechnicalDetailsBlock extends StatefulWidget {
  final Post post;
  const _TechnicalDetailsBlock({required this.post});

  @override
  State<_TechnicalDetailsBlock> createState() => _TechnicalDetailsBlockState();
}

class _TechnicalDetailsBlockState extends State<_TechnicalDetailsBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: tokens.textDim,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.postSourceDetailsPageTechnicalDetails,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  _expanded
                      ? context.l10n.postSourceDetailsPageHide
                      : context.l10n.postSourceDetailsPageShow,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          _Section(
            label: context.l10n.postSourceDetailsPageSectionIdentifiers,
            rows: [
              _KV(label: 'uid', value: post.uid),
              _KV(label: 'account_id', value: post.accountId?.toString()),
              _KV(label: 'channel_id', value: post.channelId?.toString()),
              _KV(label: 'post_author_address', value: post.postAuthorAddress),
              _KV(
                label: 'feed_found_at_account_address',
                value: post.feedFoundAtAccountAddress,
              ),
            ],
          ),
          _Section(
            label: context.l10n.postSourceDetailsPageSectionServer,
            rows: [
              _KV(label: 'url', value: post.url),
              _KV(label: 'server_address', value: post.serverAddress),
              _KV(label: 'comments_url', value: post.commentsUrl),
            ],
          ),
          _Section(
            label: context.l10n.postSourceDetailsPageSectionSource,
            rows: [
              _KV(label: 'feed_title', value: post.feedTitle),
              _KV(label: 'feed_url', value: post.feedUrl),
              _KV(label: 'channel_slug', value: post.channelSlug),
              _KV(label: 'language', value: post.language),
            ],
          ),
          _Section(
            label: context.l10n.postSourceDetailsPageSectionContent,
            rows: [
              _KV(
                label: 'title',
                value: post.title.isEmpty ? null : post.title,
              ),
              _KV(label: 'summary', value: post.summary, multiline: true),
              _KV(
                label: 'content_text',
                value: post.contentText,
                multiline: true,
              ),
              _KV(label: 'external_url', value: post.externalUrl),
            ],
          ),
          if (post.heroMedia.isNotEmpty)
            _MediaSection(
              label: context.l10n
                  .postSourceDetailsPageHeroMedia(post.heroMedia.length),
              items: post.heroMedia,
            ),
          if (post.supportMedia.isNotEmpty)
            _MediaSection(
              label: context.l10n
                  .postSourceDetailsPageSupportMedia(post.supportMedia.length),
              items: post.supportMedia,
            ),
          if (post.audio != null)
            _MediaSection(
              label: context.l10n.postSourceDetailsPageAudio,
              items: [post.audio!],
            ),
          if (post.authors != null && post.authors!.isNotEmpty)
            _AuthorsSection(authors: post.authors!),
          _Section(
            label: context.l10n.postSourceDetailsPageSectionTimestamps,
            rows: [
              _KV(
                label: 'created_at',
                value: post.createdAt.toIso8601String(),
              ),
              _KV(
                label: 'date_modified',
                value: post.dateModified?.toIso8601String() ?? '—',
              ),
            ],
          ),
          _Section(
            label: context.l10n.postSourceDetailsPageSectionEngagement,
            rows: [
              _KV(label: 'comment_policy', value: post.commentPolicy),
              _KV(
                label: 'require_verified_comments',
                value: post.requireVerifiedComments?.toString(),
              ),
              _KV(label: 'reaction_policy', value: post.reactionPolicy),
              _KV(
                label: 'require_verified_reactions',
                value: post.requireVerifiedReactions?.toString(),
              ),
              _KV(
                label: 'comments_count',
                value: post.commentsCount?.toString(),
              ),
              _KV(label: 'reactions', value: post.reactions),
              _KV(label: 'score', value: post.score.toString()),
              _KV(label: 'upvotes', value: post.upvotes.toString()),
              _KV(label: 'downvotes', value: post.downvotes.toString()),
              _KV(label: 'user_vote', value: post.userVote?.toString()),
            ],
          ),
          if (post.tags != null && post.tags!.isNotEmpty)
            _TagsSection(tags: post.tags!),
          _Section(
            label: context.l10n.postSourceDetailsPageSectionSignature,
            rows: [
              _KV(label: 'signature', value: post.signature, multiline: true),
              _KV(label: 'signer_address', value: post.signerAddress),
              _KV(
                label: 'signed_object',
                value: post.signedObject,
                multiline: true,
              ),
            ],
          ),
          _RawJsonSection(post: post),
        ],
      ],
    );
  }
}

// ============================================================================
// Section shell + primitives
// ============================================================================

class _Section extends StatelessWidget {
  final String label;
  final List<_KV> rows;

  const _Section({required this.label, required this.rows});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final visible = rows.where((r) => r.value != null && r.value!.isNotEmpty).toList();
    if (visible.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(label: label),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              context.l10n.postSourceDetailsPageNone,
              style: TextStyle(color: tokens.textDim, fontSize: 12),
            ),
          ),
          const _SectionDivider(),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: label),
        ...visible.map((r) => _KvRow(kv: r)),
        const _SectionDivider(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Text(
        label,
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Divider(color: tokens.borderSubtle, height: 1),
    );
  }
}

class _KV {
  final String label;
  final String? value;
  final bool multiline;
  const _KV({required this.label, this.value, this.multiline = false});
}

class _KvRow extends StatelessWidget {
  final _KV kv;
  const _KvRow({required this.kv});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final value = kv.value!;
    return InkWell(
      onTap: () => _copy(context, value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kv.label,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: kv.multiline ? null : 2,
              overflow: kv.multiline ? null : TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _copy(BuildContext context, String value) {
  Clipboard.setData(ClipboardData(text: value));
  HapticFeedback.lightImpact();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(context.l10n.postSourceDetailsPageCopied),
      duration: const Duration(milliseconds: 900),
    ),
  );
}

// ============================================================================
// Media (tabular): hero_media, support_media, audio
// ============================================================================

class _MediaSection extends StatelessWidget {
  final String label;
  final List<PostMedia> items;
  const _MediaSection({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: label),
        ...items.asMap().entries.map((e) {
          final i = e.key;
          final a = e.value;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                border: Border.all(color: tokens.borderSubtle, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$i · ${a.mimeType}',
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _copy(context, a.url),
                    child: Text(
                      a.url,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (a.title != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'title: ${a.title}',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (a.sizeInBytes != null)
                    Text(
                      'size: ${a.sizeInBytes}',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (a.width != null && a.height != null)
                    Text(
                      'pixels: ${a.width} x ${a.height}',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (a.durationInSeconds != null)
                    Text(
                      'duration: ${a.durationInSeconds}s',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (a.thumbnailUrl != null)
                    Text(
                      'thumbnail: ${a.thumbnailUrl}',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  if (a.sha256 != null)
                    Text(
                      'sha256: ${a.sha256}',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        const _SectionDivider(),
      ],
    );
  }
}

// ============================================================================
// Authors
// ============================================================================

class _AuthorsSection extends StatelessWidget {
  final List<PostAuthor> authors;
  const _AuthorsSection({required this.authors});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: context.l10n.postSourceDetailsPageAuthors(authors.length),
        ),
        ...authors.map(
          (a) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                border: Border.all(color: tokens.borderSubtle, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'name: ${a.name}',
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (a.url != null) ...[
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _copy(context, a.url!),
                      child: Text(
                        'url: ${a.url}',
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                  if (a.avatar != null) ...[
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _copy(context, a.avatar!),
                      child: Text(
                        'avatar: ${a.avatar}',
                        style: TextStyle(
                          color: tokens.textDim,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const _SectionDivider(),
      ],
    );
  }
}

// ============================================================================
// Tags
// ============================================================================

class _TagsSection extends StatelessWidget {
  final List<String> tags;
  const _TagsSection({required this.tags});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          label: context.l10n.postSourceDetailsPageTags(tags.length),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: tokens.borderSubtle,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                        fontFamily: 'monospace',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const _SectionDivider(),
      ],
    );
  }
}

// ============================================================================
// Verification result chip — used inside the human header.
// ============================================================================

/// The verdict as a chip: checked, bad, unsigned, "not checked" (the chain
/// could not be asked whose key signed: amber, not red), or "checking"
/// while Core is still at it (null).
class _ResultChip extends StatelessWidget {
  final PostVerificationResult? signature;

  const _ResultChip({required this.signature});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final s = signature;
    final (Color fg, IconData icon, String label) = s == null
        ? (
            tokens.textDim,
            Icons.hourglass_top_rounded,
            context.l10n.postSourceDetailsPageSignatureChecking,
          )
        : s.chainUnavailable
            ? (
                tokens.fallbackAccent,
                Icons.cloud_off_rounded,
                context.l10n.postSourceDetailsPageSignatureUnchecked,
              )
            : switch (s.state) {
                PostSignatureState.checked => (
                    tokens.connectedAccent,
                    Icons.verified_rounded,
                    context.l10n.postSourceDetailsPageSignatureChecked,
                  ),
                PostSignatureState.bad => (
                    Theme.of(context).colorScheme.error,
                    Icons.gpp_bad_rounded,
                    context.l10n.postSourceDetailsPageBadSignature,
                  ),
                PostSignatureState.unsigned => (
                    tokens.textDim,
                    Icons.lock_open_rounded,
                    context.l10n.postSourceDetailsPageNoSignature,
                  ),
              };
    final reason = s?.reason ?? '';
    final bg = fg.withValues(alpha: 0.10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: fg.withValues(alpha: 0.4), width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        if (reason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            reason,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// Raw JSON
// ============================================================================

class _RawJsonSection extends StatefulWidget {
  final Post post;
  const _RawJsonSection({required this.post});

  @override
  State<_RawJsonSection> createState() => _RawJsonSectionState();
}

class _RawJsonSectionState extends State<_RawJsonSection> {
  /// Collapsed-state max-height in logical pixels — about 8 lines of
  /// monospace 11pt at 1.5 line-height.
  static const double _collapsedHeight = 140;

  bool _expanded = false;

  String get _prettyJson {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(widget.post.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final json = _prettyJson;
    final body = Padding(
      padding: const EdgeInsets.all(12),
      child: SelectableText(
        json,
        style: TextStyle(
          color: tokens.starkWhite.withValues(alpha: 0.92),
          fontSize: 11,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Row(
            children: [
              Text(
                context.l10n.postSourceDetailsPageRawJson,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              _SmallGlassButton(
                icon: Icons.copy_rounded,
                label: context.l10n.postSourceDetailsPageCopy,
                onTap: () => _copy(context, json),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border.all(color: tokens.borderSubtle, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  if (_expanded)
                    body
                  else
                    SizedBox(
                      height: _collapsedHeight,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: body,
                      ),
                    ),
                  // Fade-out gradient at the bottom of the collapsed view to
                  // hint at clipped content.
                  if (!_expanded)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 36,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                tokens.surfaceElevated.withValues(alpha: 0),
                                tokens.surfaceElevated,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Center(
            child: _SmallGlassButton(
              icon: _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              label: _expanded
                  ? context.l10n.postSourceDetailsPageShowLess
                  : context.l10n.postSourceDetailsPageShowMore,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallGlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallGlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: tokens.starkWhite),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
