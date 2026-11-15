import 'package:flutter/material.dart';
import 'contact_banner.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/glass_tokens.dart';
import 'glass_contact_icon.dart';
import 'selection_pill.dart';
import 'social_icons.dart';

/// A contact row — publicos_client's `components/feeds/discover_contact_row.dart`
/// re-shelled for the desktop contacts left-nav. Same visual language: a
/// 12%-opacity full-bleed banner behind a left [GlassContactIcon] + name + bio.
///
/// Desktop deltas:
///   - the client row's trailing capability/social glyph grid is dropped — its
///     actions are in-app-browser-coupled (`AppNav.toTab`, which exists here
///     but isn't wired into this row) and need the branded social-icon
///     helpers (flutter_svg), not ported.
///   - adds [selected] (the shared [SelectionPill] + a glassFill wash) since
///     this drives a detail pane, where the client row navigated away.
class DiscoverContactRow extends StatefulWidget {
  final Contact contact;
  final VoidCallback? onTap;
  final double iconSize;
  final bool showBanner;
  final bool showChevron;
  final bool selected;

  const DiscoverContactRow({
    super.key,
    required this.contact,
    this.onTap,
    this.iconSize = 56,
    this.showBanner = true,
    this.showChevron = false,
    this.selected = false,
  });

  @override
  State<DiscoverContactRow> createState() => _DiscoverContactRowState();
}

/// Keep-alive so rows scrolled out of view aren't disposed + rebuilt —
/// otherwise [GlassContactIcon] re-resolves + re-decodes the avatar on every
/// scroll-back, which reads as the icon flickering. Mirrors the client.
class _DiscoverContactRowState extends State<DiscoverContactRow>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Capability detection (matches the client row) ──────────────────────────
  // First feed/website tab, ranked-first then unranked (profile order).
  Record? get _firstFeed => _firstTab(RouterSubtype.channel);
  Record? get _firstWebsite => _firstTab(RouterSubtype.tab);

  Record? _firstTab(RouterSubtype subtype) {
    final all = widget.contact.records
        .where((r) => r.routerSubtype == subtype && !r.isExpired)
        .toList();
    if (all.isEmpty) return null;
    final ranked = all.where((r) => r.rank != null).toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));
    final unranked = all.where((r) => r.rank == null).toList();
    return [...ranked, ...unranked].first;
  }

  /// Launchable socials in profile order — skips ones with no link or no
  /// drawable glyph (no branded icon AND no MaterialIcons codepoint). Capped
  /// at 6 (the trailing grid's slot count).
  List<Record> get _socials {
    final all = widget.contact.records
        .where(
          (r) =>
              r.profileSubtype == ProfileSubtype.social &&
              !r.isExpired &&
              (r.link?.trim().isNotEmpty ?? false) &&
              (socialIconForKey(r.key) != null || r.icon != null),
        )
        .toList();
    final ranked = all.where((r) => r.rank != null).toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));
    final unranked = all.where((r) => r.rank == null).toList();
    return [...ranked, ...unranked].take(6).toList();
  }

  /// First non-empty, non-expired `profile.bio` record (canonical lookup,
  /// matches profile_page.dart: `ProfileSubtype.text`).
  String? get _bio {
    for (final r in widget.contact.records) {
      if (r.profileSubtype == ProfileSubtype.text &&
          !r.isExpired &&
          r.value.trim().isNotEmpty) {
        return r.value.trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tokens = GlassTokens.of(context);
    final name =
        widget.contact.publicosDisplayName ?? widget.contact.displayName;

    return SelectionPill(
      selected: widget.selected,
      child: Material(
        color: widget.selected ? tokens.glassFill : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: Stack(
            children: [
              if (widget.showBanner)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.12,
                    child: ClipRect(
                      child: ContactBanner(
                        contact: widget.contact,
                        fallback: const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: widget.iconSize + 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GlassContactIcon(
                        contact: widget.contact,
                        size: widget.iconSize,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: tokens.starkWhite,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (_bio != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                _bio!,
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 12,
                                  color: tokens.textDim,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TrailingIconGrid(
                        tokens: tokens,
                        feed: _firstFeed,
                        website: _firstWebsite,
                        socials: _socials,
                      ),
                      if (widget.showChevron) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: tokens.textDim,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing 2×3 icon grid — capability glyphs first (RSS, Website — same icons
/// the browser tab bar uses), then the contact's socials fill the remaining
/// slots, quiet monochrome so the block reads as metadata next to the name.
/// Renders nothing when the contact has neither.
///
/// Desktop delta: the RSS/Website glyphs are passive hints (the client fires
/// them into the in-app Browser via `AppNav.toTab`, not wired into this row
/// on desktop); the social glyphs are tappable → `launchUrl` (external).
class _TrailingIconGrid extends StatelessWidget {
  static const int _maxSlots = 6;
  static const int _perRow = 3;

  final GlassTokens tokens;
  final Record? feed;
  final Record? website;
  final List<Record> socials;

  const _TrailingIconGrid({
    required this.tokens,
    required this.feed,
    required this.website,
    required this.socials,
  });

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      if (feed != null)
        _IconSlot(
          tooltip: 'RSS',
          glyph: Icon(Icons.rss_feed_rounded, size: 17, color: tokens.textDim),
        ),
      if (website != null)
        _IconSlot(
          tooltip: 'Website',
          glyph: Icon(Icons.language_rounded, size: 17, color: tokens.textDim),
        ),
      for (final r in socials) _SocialSlot(tokens: tokens, record: r),
    ];
    if (slots.isEmpty) return const SizedBox.shrink();
    final visible = slots.take(_maxSlots).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: visible.take(_perRow).toList(),
        ),
        if (visible.length > _perRow)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: visible.skip(_perRow).toList(),
          ),
      ],
    );
  }
}

/// One fixed 28×28 grid slot — uniform geometry lines the two rows into
/// columns. With [onTap] the whole slot is the hit target.
class _IconSlot extends StatelessWidget {
  final String tooltip;
  final Widget glyph;
  final VoidCallback? onTap;

  const _IconSlot({required this.tooltip, required this.glyph, this.onTap});

  @override
  Widget build(BuildContext context) {
    final slot = SizedBox(
      width: 28,
      height: 28,
      child: Center(
        child: Tooltip(message: tooltip, child: glyph),
      ),
    );
    if (onTap == null) return slot;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: slot,
    );
  }
}

/// A social in a grid slot — branded glyph if known, MaterialIcons codepoint
/// fallback otherwise; tap launches the record's link externally.
class _SocialSlot extends StatelessWidget {
  final GlassTokens tokens;
  final Record record;

  const _SocialSlot({required this.tokens, required this.record});

  Future<void> _launch() async {
    final uri = Uri.tryParse(record.link!);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return _IconSlot(
      tooltip: socialDisplayName(record.key),
      onTap: _launch,
      glyph:
          socialIconForKey(record.key, size: 17, color: tokens.textDim) ??
          Icon(
            // Custom codepoint from chain data (not const) — same dynamic-icon
            // fallback the client uses; needs --no-tree-shake-icons on release.
            // ignore: non_const_argument_for_const_parameter
            IconData(record.icon!, fontFamily: 'MaterialIcons'),
            size: 17,
            color: tokens.textDim,
          ),
    );
  }
}
