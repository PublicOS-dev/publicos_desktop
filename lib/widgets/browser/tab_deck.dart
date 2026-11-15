// The Browser's tab deck — desktop-only chrome with no publicos_client twin
// (the client's switcher is `components/browser/tab_selection_dropdown.dart`
// plus its address bar). Kept apart from `widgets/browser.dart` so that file
// keeps to the logic it shares with the client's `pages/browser.dart`.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/glass_context_menu.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Scheme stripped for display only — tooltip/copy/open keep the full URL.
String deckDisplayUrl(String url) =>
    url.replaceFirst(RegExp(r'^https?://'), '');

/// How long the active tab takes to grow into / shrink out of its inline URL.
/// Shared because the deck's overflow-reveal has to wait for it: the
/// tab's width is not settled by the next frame.
const Duration kDeckUrlReveal = Duration(milliseconds: 260);

/// Every tab is this tall, docked or not: a tab never grows vertically.
///
/// The docked Profile tab does not need extra height for its avatar plus two
/// text lines: [kDeckDockedAvatarSize] is 26 and the name + address column
/// measures 30, both inside 36 with margin to spare. Letting it grow would
/// cost a three-site invariant (deck padding, tab height, scroller viewport
/// all have to move together or the strip tears).
const double kDeckTabHeight = 36.0;

/// The avatar's size in a docked Profile tab, and the size its outgoing
/// person glyph grows to as the two crossfade. Bounded by [kDeckTabHeight] --
/// raise it and the tab starts clipping instead of growing, by design.
const double kDeckDockedAvatarSize = 26.0;

/// One browser tab. It paints NO selection shape of its own: the black hole
/// the selected tab sits in is [DeckSelection]'s slab, painted under the row
/// and slid from tab to tab. Inactive = transparent, rounded-top hover wash.
/// Icon-only when [label] is null (Settings).
///
/// When the ACTIVE tab carries an embedded [url] it grows rightward and shows
/// the URL inline after the label (dim mono), in place of a separate
/// address band. The slab tracks that growth frame by frame.
///
/// [launcher] tabs (web + app) render a small ↗ glyph after the label — the
/// visual contract that clicking fires the OS browser instead of selecting
/// the tab.
class ChromeTab extends StatefulWidget {
  final String? label;
  final String? url;
  final Widget leading;
  final String tooltip;

  /// This tab IS the current one — drives the inline-URL reveal and weight.
  final bool active;

  /// How much of the slab is on this tab right now, 0..1 — the new tab rises
  /// with the slide and the old one falls ([DeckSelectionScope.activeness]).
  /// Label tone, the docked pill and hover follow this rather than flipping
  /// on [active], so nothing changes colour before the slab
  /// has actually arrived.
  final double activeness;
  final bool launcher;

  /// The contact-coloured frame this tab sits on. Only the INACTIVE state
  /// reads it — an active tab sits in the slab, a hole onto `background`,
  /// and keeps the dark-surface tokens.
  final DeckPalette palette;

  /// Hand-off progress (0 banner in the content ... 1 banner in the deck).
  /// Every tab receives it -- inactive tabs need the readability pill once
  /// the frame is a photograph, not just the one tab that morphs.
  final double dock;

  /// Set on the Profile tab only. Docked, the tab stops naming a section and
  /// starts naming a person: [dockedTitle] crossfades over the label, and
  /// [dockedSubtitle] (the short address, null for a contact with no chain
  /// account) grows in beneath it.
  final String? dockedTitle;
  final String? dockedSubtitle;

  final VoidCallback onTap;

  const ChromeTab({
    super.key,
    this.label,
    this.url,
    required this.leading,
    required this.tooltip,
    required this.active,
    required this.activeness,
    required this.palette,
    this.launcher = false,
    this.dock = 0,
    this.dockedTitle,
    this.dockedSubtitle,
    required this.onTap,
  });

  /// Does this tab take on the avatar + name, and therefore grow?
  bool get morphs => dockedTitle != null;

  @override
  State<ChromeTab> createState() => _ChromeTabState();
}

class _ChromeTabState extends State<ChromeTab>
    with SingleTickerProviderStateMixin {
  bool _hover = false;

  /// Drives the inline URL's horizontal reveal.
  ///
  /// The URL does not pop in and out with the selection (that would snap the
  /// tab between its 180 and 360 px caps in a single frame): the tab GROWS to
  /// admit it and SHRINKS to expel it. The animation — not a flag — is what
  /// keeps the outgoing tab's URL mounted while it collapses; keying the
  /// widget tree off `active` alone would drop the text instantly and there
  /// would be nothing left to shrink.
  late final AnimationController _urlAnim;

  /// Typed concrete, not as `Animation<double>`, so it can be disposed —
  /// Flutter leak-tracks an undisposed CurvedAnimation.
  late final CurvedAnimation _urlT;

  /// The resting state this tab's URL animates toward.
  bool get _wantsUrl => widget.active && widget.url != null;

  @override
  void initState() {
    super.initState();
    _urlAnim = AnimationController(
      vsync: this,
      duration: kDeckUrlReveal,
      // Land AT the resting state instead of animating from zero: a deck that
      // rebuilds (contact sync, a lapsed record) must not replay the reveal on
      // every already-active tab.
      value: _wantsUrl ? 1 : 0,
    );
    _urlT = CurvedAnimation(
      parent: _urlAnim,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(ChromeTab old) {
    super.didUpdateWidget(old);
    if (_wantsUrl) {
      _urlAnim.forward();
    } else {
      _urlAnim.reverse();
    }
  }

  @override
  void dispose() {
    _urlT.dispose();
    _urlAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final dock = widget.dock.clamp(0.0, 1.0);
    final a = widget.activeness.clamp(0.0, 1.0);
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          // The pill is for tabs sitting ON the banner. Under the slab (a hole
          // onto `background`) it must not be: a wash would tint the slab off
          // `background` and break its match with `_deckEdge`. It fades with
          // `activeness`, not with `active`, so it neither vanishes from the
          // old tab while the slab is still leaving nor lingers on the new one.
          child: GlassPill(
              dock: dock * (1 - a),
              radius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: Container(
                height: kDeckTabHeight,
                padding: EdgeInsets.symmetric(
                    horizontal: widget.label == null ? 12 : 16),
                // ALWAYS a decoration, transparent on the active tab — never
                // `null`. `Container` only inserts its `DecoratedBox` when a
                // decoration is set, so toggling null on select would change
                // the tree shape above `leading` and remount the tab's art: a
                // feed tab's FeedFavicon would restart on its RSS glyph and
                // flash it for a moment.
                decoration: BoxDecoration(
                  // The hover wash follows the frame — a fixed white
                  // `glassFillHover` is invisible on a pale swatch.
                  color: a < 0.01 && _hover
                      ? widget.palette.hover
                      : Colors.transparent,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                ),
                // The inline URL is an active-tab affordance only — inactive
                // tabs stay label-sized so the deck isn't crowded by every URL
                // at once. `t` interpolates that: the 180 px label cap grows to
                // the 360 px URL cap as the reveal runs, and the URL segment
                // itself is wiped in by width factor, so the tab's whole
                // silhouette eases open and shut.
                child: AnimatedBuilder(
                  animation: _urlT,
                  builder: (context, _) {
                    final t = _urlT.value.clamp(0.0, 1.0);
                    return ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: 180 + 180 * t + 90 * dock),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          widget.leading,
                          if (widget.label != null) ...[
                            SizedBox(width: 7 + 3 * dock),
                            Flexible(
                              child: widget.morphs
                                  ? _dockedLabel(tokens, dock)
                                  : Text(
                                      widget.label!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'SpaceGrotesk',
                                        fontSize: 13,
                                        fontWeight: widget.active
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: Color.lerp(
                                          GlassPill.fgAt(
                                              widget.palette.fgDim, dock),
                                          tokens.starkWhite,
                                          a,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                          // Mounted for the whole reveal, both directions, and
                          // skipped entirely at rest so inactive tabs never lay
                          // out a URL they don't show. NOT `Flexible` — a flex
                          // child would re-ellipsize against a changing cap on
                          // every frame, which reads as text reflowing rather
                          // than a tab opening. Fixed cap + ClipRect + width
                          // factor makes it a clean horizontal wipe.
                          if (widget.url != null && t > 0) ...[
                            ClipRect(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                widthFactor: t,
                                child: Opacity(
                                  opacity: t,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 9),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 200,
                                          ),
                                          child: Text(
                                            deckDisplayUrl(
                                              widget.url!,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: 'JetBrainsMono',
                                              fontSize: 10.5,
                                              color: tokens.textDim.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Copy + open-external,
                                        // icons only, riding the same wipe
                                        // as the URL. Their own tap targets
                                        // sit inside the tab's GestureDetector
                                        // and win the arena, so neither
                                        // re-selects the tab.
                                        const SizedBox(width: 4),
                                        _UrlIcon(
                                          icon: Icons.copy_rounded,
                                          tooltip:
                                              context.l10n.walletActionCopy,
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(text: widget.url!),
                                            );
                                            ScaffoldMessenger.maybeOf(context)
                                              ?..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    context
                                                        .l10n
                                                        .postCardLinkCopied,
                                                  ),
                                                ),
                                              );
                                          },
                                        ),
                                        _UrlIcon(
                                          icon: Icons.open_in_new_rounded,
                                          tooltip: context
                                              .l10n
                                              .manageServerPageOpenInBrowser,
                                          onTap: () {
                                            final uri = Uri.tryParse(
                                              widget.url!,
                                            );
                                            if (uri != null) launchUrl(uri);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (widget.launcher) ...[
                            const SizedBox(width: 6),
                            // Launcher tabs never activate, so their ↗
                            // always sits on the frame and always follows it.
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 11,
                              color: GlassPill.fgAt(widget.palette.fg, dock)
                                  .withValues(alpha: _hover ? 0.95 : 0.55),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
    );
  }

  /// The morphing tab's text half. Two lines that behave differently on
  /// purpose:
  ///
  /// - the primary line CROSSFADES "Profile" against the display name inside
  ///   a fixed-height box, because both are single-line and swapping them in
  ///   place is what makes it read as one label becoming another rather than
  ///   two labels trading places;
  /// - the address GROWS IN under it by height factor, since there is nothing
  ///   for it to replace.
  ///
  /// The fixed 17px box is why this branch exists at all instead of a Stack
  /// around the plain label: a Stack would size to the taller docked column
  /// and leave every undocked tab at that height.
  Widget _dockedLabel(GlassTokens tokens, double dock) {
    final sub = widget.dockedSubtitle;
    final fg = Color.lerp(GlassPill.fgAt(widget.palette.fgDim, dock),
        tokens.starkWhite, widget.activeness.clamp(0.0, 1.0))!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 17,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              if (dock < 0.999)
                Opacity(
                  opacity: 1 - dock,
                  child: Text(
                    widget.label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight:
                          widget.active ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              if (dock > 0.001)
                Opacity(
                  opacity: dock,
                  child: Text(
                    widget.dockedTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (sub != null)
          ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              heightFactor: dock,
              // REQUIRED: `Align` shrink-wraps only on the axes that have
              // a factor, and takes `constraints.biggest` on the others. With
              // height alone it claims the full 270px cap, dragging the
              // Column -- and the tab -- out to it. With both, the tab sizes
              // to its content and only grows when the name actually needs it.
              widthFactor: 1,
              child: Opacity(
                opacity: dock,
                child: Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9.5,
                    color: fg.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One deck-cluster action, animated in and out.
///
/// Give it the action's widget while the action applies and `null` once it does
/// not. It keeps the last child it was handed so the outgoing one still has
/// something to animate; a child simply dropped from the `Row` would be gone
/// before the first frame of an exit.
///
/// Two things move together, and both are needed (horizontal only, no
/// vertical rise):
///
///  * **width** (`SizeTransition`, horizontal) — without it the neighbours jump
///    the instant an action appears. This cluster is pinned right of an
///    `Expanded` scroller, so a width change shifts everything to its LEFT;
///    animating the width is what turns that shift into a slide.
///  * **opacity** — carries the change on its own if the motion is missed.
///
/// **In and out are deliberately not symmetrical.** Entering takes 200ms on an
/// ease-out; leaving takes 120ms and is mostly the fade (`easeIn`, so the
/// opacity goes early and the width closes after). A full reverse of the
/// entrance reads as lag on tab switches, which are rapid and back-to-back —
/// the outgoing set has to be out of the way before the incoming one is
/// interesting.
class DeckSlot extends StatefulWidget {
  final Widget? child;
  const DeckSlot({super.key, this.child});

  @override
  State<DeckSlot> createState() => _DeckSlotState();
}

class _DeckSlotState extends State<DeckSlot>
    with SingleTickerProviderStateMixin {
  static const Duration _kIn = Duration(milliseconds: 200);
  static const Duration _kOut = Duration(milliseconds: 120);

  late final AnimationController _ctrl;

  /// The last non-null child. Survives its own removal so it can be animated
  /// away; replaced only when a new one arrives.
  Widget? _last;

  @override
  void initState() {
    super.initState();
    _last = widget.child;
    _ctrl = AnimationController(
      vsync: this,
      duration: _kIn,
      reverseDuration: _kOut,
      // A slot that starts out visible starts settled: the cluster should not
      // play an entrance for every button just because the panel mounted.
      value: widget.child != null ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(DeckSlot old) {
    super.didUpdateWidget(old);
    if (widget.child != null) {
      _last = widget.child;
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = _last;
    // Fully out and nothing pending: occupy no space at all, so a cluster of
    // mostly-hidden slots costs the Row nothing.
    if (child == null || (_ctrl.isDismissed && widget.child == null)) {
      return const SizedBox.shrink();
    }

    final curved = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    );

    return SizeTransition(
      axis: Axis.horizontal,
      // Collapse toward the LEFT edge, so a slot closing does not drag its
      // right-hand neighbours with it.
      alignment: Alignment.centerLeft,
      sizeFactor: curved,
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

/// One 15px glyph trailing the in-tab URL (copy / open external). Its own
/// InkWell nests inside the tab's GestureDetector so the inner gesture wins
/// and the tab is not re-selected.
class _UrlIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _UrlIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          hoverColor: tokens.glassFillHover,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Icon(
              icon,
              size: 15,
              color: tokens.textDim.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// The readability pill the deck grows once it is wearing a photograph.
///
/// Undocked this is a pass-through -- literally the same widget tree the deck
/// has always built, so the resting look is unchanged and there is no blur
/// cost at all. Docked it is a small backdrop blur plus a dark wash, which is
/// what lets a label survive over an arbitrary user banner without dropping a
/// full-width scrim over art the user picked to be seen.
///
/// [fgAt] is its other half: every chrome foreground in the deck is derived
/// from the contact's swatch by luminance ([DeckPalette]), and once a photo
/// covers that swatch the derivation has nothing true left to say. This walks
/// those tones toward white as the dock closes, to match the wash.
class GlassPill extends StatelessWidget {
  final double dock;
  final BorderRadius radius;
  final Widget child;

  const GlassPill({
    super.key,
    required this.dock,
    required this.radius,
    required this.child,
  });

  static Color fgAt(Color base, double dock) => Color.lerp(
      base, Colors.white.withValues(alpha: 0.92), dock.clamp(0.0, 1.0))!;

  @override
  Widget build(BuildContext context) {
    // One tree shape at every dock value — switched off, never removed. An
    // early `return child` at rest made the wrapper appear and vanish as dock
    // crossed zero (and on every tab select, since the active tab passes
    // dock 0), which remounted everything under it — tab art included.
    final on = dock > 0.001;
    return ClipRRect(
      borderRadius: radius,
      clipBehavior: on ? Clip.antiAlias : Clip.none,
      child: BackdropFilter(
        enabled: on,
        filter: ImageFilter.blur(sigmaX: 10 * dock, sigmaY: 10 * dock),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.30 * dock),
            borderRadius: radius,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Network art for a tab whose icon comes from a URL — the web tab's favicon
/// and the app tab's registry icon. Every tab that has an icon shows it.
///
/// Feed tabs do NOT come through here: they use [FeedFavicon], which owns a
/// richer chain (feed metadata `imageUrl` → site favicon → RSS glyph) that a
/// plain favicon lookup can't reproduce. Splitting them keeps each source
/// honest rather than forcing one widget to guess which chain to run.
///
/// Holds a fixed footprint across loading and error, like [FeedFavicon], so a
/// tab never reflows while its art resolves.
class TabArt extends StatelessWidget {
  final String? imageUrl;
  final IconData fallback;

  /// Derived from the deck frame — these tabs are launchers, so their glyph
  /// is always drawn on the contact's swatch and can never hold a fixed token.
  final Color fallbackColor;

  final double size;

  const TabArt({
    super.key,
    required this.imageUrl,
    required this.fallback,
    required this.fallbackColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(fallback, size: size, color: fallbackColor);
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return SizedBox(width: size, height: size, child: glyph);
    }
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        // Same soft-square as FeedFavicon's default so the two kinds of art
        // sit on one silhouette in the same deck.
        borderRadius: BorderRadius.circular(size / 5.5),
        child: ZeroCachedImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => glyph,
          errorWidget: (_, __, ___) => glyph,
        ),
      ),
    );
  }
}

/// The deck frame's palette, derived from the browsed contact's own swatch.
///
/// The deck frame is painted in the contact's
/// `color` record — the SAME source, at the same full opacity, that paints
/// their chat bubbles (`messages/message_widget.dart` `_brandColor`). The
/// frame around a contact's tabs and the bubbles inside their chat are
/// one identity signal.
///
/// Because the fill is an arbitrary user-chosen swatch, nothing drawn ON the
/// frame may keep a fixed light-on-dark token — a `textDim` label would go
/// invisible on a pale swatch. Every chrome foreground therefore derives from
/// the fill here, by the same WCAG crossover the bubbles use.
class DeckPalette {
  final Color fill;

  const DeckPalette(this.fill);

  /// Relative luminance at which white and black contrast equally against a
  /// fill — `sqrt(1.05 * 0.05) - 0.05`. Picking the better of the two on
  /// either side guarantees >= 4.5:1 against ANY fill. Deliberately the same
  /// constant as `message_widget._fgCrossover` and `chat_settings_dialog`;
  /// it is duplicated per-file in this repo rather than shared, and it is NOT
  /// the naive `< 0.5` midpoint (that fails 23 of the 46 presets).
  static const double _fgCrossover = 0.179;

  /// Primary foreground on the frame — the active/emphasised chrome glyph.
  Color get fg =>
      fill.computeLuminance() < _fgCrossover ? Colors.white : Colors.black;

  /// Resting label + icon tone (the `textDim` role, refitted to the fill).
  Color get fgDim => fg.withValues(alpha: 0.62);

  /// Inactive-tab hover wash (the `glassFillHover` role). Must follow the
  /// fill: a white wash is invisible on a pale swatch, a black one on a dark.
  Color get hover => fg.withValues(alpha: 0.10);

  /// The Settings divider (the `borderMedium` role).
  Color get divider => fg.withValues(alpha: 0.22);
}

/// How long the selection slab takes to slide from one tab to the next — and,
/// on a Browser arriving from another rail screen, in from off the deck's
/// left edge. Same length and curve as the inline-URL reveal, which runs at
/// the same moment on the tab the slab is heading for.
const Duration kDeckSlide = Duration(milliseconds: 260);

/// Where the slab last was, carried across Browser remounts.
///
/// The hosts key the Browser by contact, so it remounts on every contact
/// switch and cannot hold this itself. The host PANE owns one for its whole
/// life:
///
///  * contact → contact inside the pane: the new Browser finds the old
///    position here and the slab slides from it to wherever it rests now;
///  * arriving from another rail screen: a destination switch disposes the
///    pane (`ShellMorph` drops the outgoing one), the memory goes with it,
///    and the slab enters from off the deck's left edge.
///
/// No flag decides between the two. The first case has a memory and the
/// second does not.
class DeckSelectionMemory {
  Rect? _rect;
  Rect? _clip;
}

/// What a deck row needs from the [DeckSelection] it sits in.
class DeckSelectionScope {
  /// One stable key per tab id. Every tab — scrolled or pinned — must be
  /// wrapped in its key, or the slab cannot find it.
  final GlobalKey Function(String id) keyOf;

  /// 0..1: how much of the slab is on this tab right now. The tab being
  /// selected rises with the slide, the one being left falls, all others 0.
  final double Function(String id) activeness;

  /// The tab scroller's controller. Owned here so a scroll repaints the slab.
  final ScrollController scroll;

  /// The scroller's viewport box — the slab is clipped to it while it sits on
  /// a scrolled tab, exactly as that tab is.
  final GlobalKey viewportKey;

  /// Wrap a row whose layout can move a tab. The scroller's viewport is a
  /// relayout boundary, so a width change inside it (the inline-URL reveal, a
  /// tab appearing) never reaches the deck-level watcher; the scroller wraps
  /// its own row with this.
  final Widget Function(Widget child) watchLayout;

  const DeckSelectionScope._({
    required this.keyOf,
    required this.activeness,
    required this.scroll,
    required this.viewportKey,
    required this.watchLayout,
  });
}

/// The ONE owner of the selected tab's silhouette: a slab under the tab row
/// that slides to whichever tab is current.
///
/// One owner, because a silhouette painted from a rect measured AFTER each
/// frame (scroll listener, post-frame callbacks, a ticker after a pick) can
/// fall a frame behind and leave flares under a tab that is not selected.
/// Here the rect is resolved INSIDE `paint`, after the same frame's
/// layout, so it cannot lag: the slab is where the tab is, every frame.
///
/// Paint order is what makes one layer enough: swatch → banner → slab → tabs.
/// A tab's pill fades by [DeckSelectionScope.activeness], so the pill that
/// would square the flares off is gone by the time the slab
/// rests under it, and the scroller's edge fades and chevron still sit above.
class DeckSelection extends StatefulWidget {
  /// The current tab's id; a change slides the slab there.
  final String? activeId;

  /// The host pane's memory; null reads as "no previous position".
  final DeckSelectionMemory? memory;

  /// The slab colour — `background`, the surface the body and `_deckEdge`
  /// are painted in, so tab, edge and body read as one.
  final Color fill;

  final Widget Function(BuildContext context, DeckSelectionScope selection)
      builder;

  const DeckSelection({
    super.key,
    required this.activeId,
    this.memory,
    required this.fill,
    required this.builder,
  });

  @override
  State<DeckSelection> createState() => _DeckSelectionState();
}

class _DeckSelectionState extends State<DeckSelection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide =
      AnimationController(vsync: this, duration: kDeckSlide);

  /// Typed concrete so it can be disposed (leak-tracked, like `_urlT`).
  late final CurvedAnimation _t =
      CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic);

  final ScrollController _scroll = ScrollController();
  final GlobalKey _paintKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();
  final Map<String, GlobalKey> _keys = {};
  final _LayoutPing _layout = _LayoutPing();

  /// Where the current slide started, in this widget's coordinates. Captured
  /// from what was last PAINTED, so a pick made mid-slide continues from the
  /// slab's real position instead of jumping to the old tab first.
  String? _fromId;
  Rect? _from;
  Rect? _fromClip;
  bool _fromOffLeft = false;

  Rect? _painted;
  Rect? _paintedClip;

  @override
  void initState() {
    super.initState();
    final m = widget.memory;
    if (m?._rect != null) {
      _from = m!._rect;
      _fromClip = m._clip;
    } else {
      _fromOffLeft = true;
    }
    _slide.forward();
  }

  @override
  void didUpdateWidget(DeckSelection old) {
    super.didUpdateWidget(old);
    if (old.activeId != widget.activeId) {
      _fromId = old.activeId;
      // Nothing painted yet (the first tab was not laid out) = the entry
      // slide never started, so it keeps its off-left origin.
      if (_painted != null) {
        _from = _painted;
        _fromClip = _paintedClip;
        _fromOffLeft = false;
      }
      _slide.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _t.dispose();
    _slide.dispose();
    _scroll.dispose();
    _layout.dispose();
    super.dispose();
  }

  GlobalKey _keyOf(String id) =>
      _keys[id] ??= GlobalKey(debugLabel: 'deck-tab:$id');

  double _activeness(String id) {
    if (id == widget.activeId) return _t.value;
    if (id == _fromId) return 1 - _t.value;
    return 0;
  }

  Widget _watch(Widget child) =>
      _LayoutReporter(onLayout: _layout.ping, child: child);

  /// A tab's box and the clip the slab wears on it, in this widget's
  /// coordinates. Valid only during paint (layout is done for the frame).
  ({Rect rect, Rect clip})? _locate(String? id, RenderBox self) {
    if (id == null) return null;
    final box = _keys[id]?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = MatrixUtils.transformRect(
        box.getTransformTo(self), Offset.zero & box.size);
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is RenderBox && viewport.hasSize && _isInside(box, viewport)) {
      final v = MatrixUtils.transformRect(
          viewport.getTransformTo(self), Offset.zero & viewport.size);
      return (
        rect: rect,
        clip: Rect.fromLTRB(v.left, 0, v.right, self.size.height),
      );
    }
    // A pinned tab (Settings) — its own box plus room for the flares.
    const k = _SlabPainter.r;
    return (
      rect: rect,
      clip: Rect.fromLTRB(rect.left - k, 0, rect.right + k, self.size.height),
    );
  }

  static bool _isInside(RenderObject box, RenderObject ancestor) {
    for (RenderObject? p = box.parent; p != null; p = p.parent) {
      if (identical(p, ancestor)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilt per slide frame: the tabs read `activeness` while it moves.
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final scope = DeckSelectionScope._(
          keyOf: _keyOf,
          activeness: _activeness,
          scroll: _scroll,
          viewportKey: _viewportKey,
          watchLayout: _watch,
        );
        return Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  key: _paintKey,
                  painter: _SlabPainter(
                    this,
                    repaint: Listenable.merge([_scroll, _layout]),
                  ),
                ),
              ),
            ),
            _watch(widget.builder(context, scope)),
          ],
        );
      },
    );
  }
}

/// Paints the slab: a top-rounded body whose bottom corners flare OUTWARD by
/// [r], fusing it into the `_deckEdge` strip below — the chrome-tab shape.
class _SlabPainter extends CustomPainter {
  final _DeckSelectionState s;
  static const double r = 10;

  _SlabPainter(this.s, {required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final self = s._paintKey.currentContext?.findRenderObject();
    if (self is! RenderBox) return;
    final to = s._locate(s.widget.activeId, self);
    if (to == null) return;
    final t = s._t.value;

    final Rect from;
    final Rect fromClip;
    if (s._fromOffLeft) {
      // Fully past the deck's left edge, flare included, at the target's size.
      from = to.rect.translate(-(to.rect.right + r), 0);
      fromClip = Rect.fromLTRB(0, 0, to.clip.right, size.height);
    } else {
      from = s._from ?? to.rect;
      fromClip = s._fromClip ?? to.clip;
    }
    final rect = Rect.lerp(from, to.rect, t)!;
    // Mid-slide the slab may cross from the scroller to a pinned tab, so it
    // wears the union of both ends' clips; at rest, exactly the target's.
    final clip = t >= 1 ? to.clip : fromClip.expandToInclude(to.clip);

    s._painted = rect;
    s._paintedClip = clip;
    s.widget.memory
      ?.._rect = rect
      .._clip = clip;

    canvas.save();
    canvas.clipRect(clip);
    canvas.drawPath(_silhouette(rect), Paint()..color = s.widget.fill);
    canvas.restore();
  }

  static Path _silhouette(Rect b) => Path()
    ..moveTo(b.left - r, b.bottom)
    ..quadraticBezierTo(b.left, b.bottom, b.left, b.bottom - r)
    ..lineTo(b.left, b.top + r)
    ..quadraticBezierTo(b.left, b.top, b.left + r, b.top)
    ..lineTo(b.right - r, b.top)
    ..quadraticBezierTo(b.right, b.top, b.right, b.top + r)
    ..lineTo(b.right, b.bottom - r)
    ..quadraticBezierTo(b.right, b.bottom, b.right + r, b.bottom)
    ..close();

  // Its inputs are live render boxes, not fields — always repaint when asked.
  @override
  bool shouldRepaint(covariant _SlabPainter old) => true;
}

class _LayoutPing extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Reports every layout pass of its child, so a tab that moved without a
/// rebuild or a scroll (a neighbour growing its URL, a cluster slot opening)
/// still repaints the slab. Notifying from layout is safe: it only marks the
/// slab for paint, and paint runs after layout.
class _LayoutReporter extends SingleChildRenderObjectWidget {
  final VoidCallback onLayout;

  const _LayoutReporter({required this.onLayout, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderLayoutReporter(onLayout);

  @override
  void updateRenderObject(
          BuildContext context, _RenderLayoutReporter renderObject) =>
      renderObject.onLayout = onLayout;
}

class _RenderLayoutReporter extends RenderProxyBox {
  VoidCallback onLayout;

  _RenderLayoutReporter(this.onLayout);

  @override
  void performLayout() {
    super.performLayout();
    onLayout();
  }
}

/// One scroller entry: the rendered tab plus the identity the overflow menu
/// needs to list it (icon + label + launcher flag) and the pick action (same
/// as clicking the tab itself).
class DeckEntry {
  final String id;
  final IconData icon;
  final String label;
  final bool launcher;
  final Widget child;
  final VoidCallback onPick;

  const DeckEntry({
    required this.id,
    required this.icon,
    required this.label,
    required this.launcher,
    required this.child,
    required this.onPick,
  });
}

/// Horizontal tab scroller with overflow affordances: edge fades appear only
/// when there IS clipped content on that side (a plain ListView clips its
/// tail invisibly), and a pinned chevron on the right edge opens a
/// [GlassContextMenu] listing ONLY the currently clipped tabs (it
/// complements wheel scrolling, doesn't replace it). Picking a
/// content tab selects it and auto-scrolls it into view (post-frame, because
/// the active tab grows its inline URL and reflows the deck first); picking a
/// launcher tab just fires it, like clicking the tab would.
///
/// It draws no selection: the slab under it belongs to [DeckSelection], which
/// also owns this scroller's controller, viewport key and entry keys.
class DeckScroller extends StatefulWidget {
  final List<DeckEntry> entries;

  /// The frame the fades must dissolve INTO — the contact-coloured deck fill.
  /// A fade to any other colour draws a visible band at the edge.
  final DeckPalette palette;

  /// Hand-off progress. Both overflow affordances below are painted in the
  /// swatch on the assumption that the swatch is what sits behind them;
  /// docked, the banner does, and an opaque swatch block would punch a hole
  /// straight through the art. Both dissolve instead.
  final double dock;

  final DeckSelectionScope selection;

  const DeckScroller({
    super.key,
    required this.entries,
    required this.palette,
    this.dock = 0,
    required this.selection,
  });

  @override
  State<DeckScroller> createState() => _DeckScrollerState();
}

class _DeckScrollerState extends State<DeckScroller> {
  bool _fadeLeft = false;
  bool _fadeRight = false;

  ScrollController get _ctrl => widget.selection.scroll;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(DeckScroller old) {
    super.didUpdateWidget(old);
    if (!identical(old.selection.scroll, _ctrl)) {
      old.selection.scroll.removeListener(_update);
      _ctrl.addListener(_update);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!mounted || !_ctrl.hasClients) return;
    final pos = _ctrl.position;
    final left = pos.pixels > 2;
    final right = pos.pixels < pos.maxScrollExtent - 2;
    if (left != _fadeLeft || right != _fadeRight) {
      setState(() {
        _fadeLeft = left;
        _fadeRight = right;
      });
    }
  }

  /// The entries whose tab is (partly) outside the viewport right now —
  /// measured live off each tab's RenderBox, because the overflow set is
  /// dynamic: the active tab grows with its inline URL and reflows the rest.
  List<DeckEntry> _clippedEntries() {
    final viewport = context.findRenderObject();
    if (viewport is! RenderBox) return const [];
    final width = viewport.size.width;
    // A few px of tolerance so a tab kissing the fade doesn't count as hidden.
    const tol = 6.0;
    final out = <DeckEntry>[];
    for (final e in widget.entries) {
      final box =
          widget.selection.keyOf(e.id).currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final dx = box.localToGlobal(Offset.zero, ancestor: viewport).dx;
      if (dx < -tol || dx + box.size.width > width + tol) out.add(e);
    }
    return out;
  }

  void _openOverflowMenu() {
    final clipped = _clippedEntries();
    if (clipped.isEmpty) return;
    final chevron = _chevronKey.currentContext?.findRenderObject();
    if (chevron is! RenderBox) return;
    final anchor = chevron
        .localToGlobal(Offset(chevron.size.width / 2, chevron.size.height));
    GlassContextMenu.show(
      context,
      position: anchor,
      items: [
        for (final e in clipped)
          GlassContextMenuItem(
            icon: e.icon,
            // The launcher contract travels into the menu — same ↗ the tab
            // itself carries.
            label: e.launcher ? '${e.label} ↗' : e.label,
            onTap: () {
              e.onPick();
              if (!e.launcher) _revealAfterPick(e.id);
            },
          ),
      ],
    );
  }

  /// Scroll a menu-picked tab into view — in TWO passes.
  ///
  /// The first is post-frame, so selection has already rebuilt the deck. That
  /// is not sufficient: the newly active tab grows its inline URL over a
  /// 260 ms animation, so the offsets this pass aims at keep moving under it
  /// — a tab picked from the far edge could be centred at its narrow width
  /// and then widen straight back out of view. The second pass runs once the silhouette
  /// has settled and corrects for it; same curve, so it reads as the tail of
  /// the first scroll rather than a second animation.
  void _revealAfterPick(String id) {
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureVisible(id, const Duration(milliseconds: 250)));
    Future.delayed(
      kDeckUrlReveal + const Duration(milliseconds: 20),
      () => _ensureVisible(id, const Duration(milliseconds: 160)),
    );
  }

  void _ensureVisible(String id, Duration duration) {
    final ctx = widget.selection.keyOf(id).currentContext;
    if (!mounted || ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: 0.5,
    );
  }

  final GlobalKey _chevronKey = GlobalKey();

  Widget _fade({required bool leftEdge}) {
    return IgnorePointer(
      child: Container(
        width: 24,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: leftEdge ? Alignment.centerLeft : Alignment.centerRight,
            end: leftEdge ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              widget.palette.fill
                  .withValues(alpha: 1 - widget.dock.clamp(0.0, 1.0)),
              widget.palette.fill.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final overflow = _fadeLeft || _fadeRight;
    return SizedBox(
      key: widget.selection.viewportKey,
      height: kDeckTabHeight,
      // Metrics change without scrolling when tabs appear/lapse — keep the
      // fades honest on both signals.
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _update();
          return false;
        },
        child: Stack(
          children: [
            HorizontalWheel(child: SingleChildScrollView(
              controller: _ctrl,
              scrollDirection: Axis.horizontal,
              // 10px side padding = room for the slab's outward flares on the
              // first and last tab; the right side also clears the pinned
              // chevron when it's up.
              padding: EdgeInsets.only(left: 10, right: overflow ? 34 : 10),
              child: widget.selection.watchLayout(
                Row(
                  children: [
                    for (final e in widget.entries)
                      KeyedSubtree(
                        key: widget.selection.keyOf(e.id),
                        child: e.child,
                      ),
                  ],
                ),
              ),
            )),
            if (_fadeLeft)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: _fade(leftEdge: true),
              ),
            if (_fadeRight)
              Positioned(
                right: overflow ? 28 : 0,
                top: 0,
                bottom: 0,
                child: _fade(leftEdge: false),
              ),
            if (overflow)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: _OverflowChevron(
                  key: _chevronKey,
                  palette: widget.palette,
                  dock: widget.dock,
                  onTap: _openOverflowMenu,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The pinned more-tabs affordance: a slim chevron column on the deck's right
/// edge, painted SOLID in the deck frame's own colour so the tabs
/// sliding under the fade never bleed into it. Visible only while something
/// is clipped (same signal as the fades).
class _OverflowChevron extends StatefulWidget {
  final DeckPalette palette;
  final double dock;
  final VoidCallback onTap;

  const _OverflowChevron(
      {super.key, required this.palette, this.dock = 0, required this.onTap});

  @override
  State<_OverflowChevron> createState() => _OverflowChevronState();
}

class _OverflowChevronState extends State<_OverflowChevron> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.desktopMoreTabs,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          // The chevron is a BUTTON: its whole box is the target, not just the
          // glyph. Explicit rather than leaning on whether the Container's
          // `color` happens to hit-test -- see web_key_indicator's note.
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: 28,
            alignment: Alignment.center,
            color: widget.palette.fill
                .withValues(alpha: 1 - widget.dock.clamp(0.0, 1.0)),
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _hover ? widget.palette.hover : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: _hover ? widget.palette.fg : widget.palette.fgDim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
