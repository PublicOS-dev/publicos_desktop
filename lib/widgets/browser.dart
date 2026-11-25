import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/widgets/star_button.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/chat_no_key_state.dart';
import 'package:publicos_desktop/widgets/keychain_dialog.dart';
import 'package:publicos_desktop/screens/chat_screen.dart';
import 'package:publicos_desktop/screens/contact_settings_screen.dart';
import 'package:publicos_desktop/screens/profile_pane.dart';
import 'package:publicos_desktop/screens/profile_qr_page.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/utils/favicon_utils.dart';
import 'package:publicos_desktop/widgets/content_metrics_listener.dart';
import 'package:publicos_desktop/widgets/feeds/add_to_lists_sheet.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/widgets/feeds/channel_signin_dialogs.dart';
import 'package:publicos_desktop/widgets/feeds/posts_list.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/org_management/group_voting_view.dart';
import 'package:publicos_desktop/widgets/image_overlay.dart';
import 'package:publicos_desktop/widgets/nft_banner.dart';
import 'package:publicos_desktop/widgets/nft_info_dialog.dart';
import 'package:publicos_web3_bridge/publicos_web3_bridge.dart'
    show ChainRegistry; // the running page's chain, for the deck badge
import 'package:publicos_desktop/widgets/browser/publicos_webview.dart';
import 'package:publicos_desktop/widgets/contact_settings_dialog.dart';
import 'package:publicos_desktop/widgets/browser/web_key_indicator.dart';
import 'package:publicos_desktop/widgets/browser/tab_deck.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/fullscreen_overlay.dart';
import 'package:publicos_desktop/widgets/profile/edit_profile_background_sheet.dart';
import 'package:publicos_desktop/widgets/profile/constellation_canvas.dart';
import 'package:publicos_desktop/widgets/profile/edit_profile_image_sheet.dart';
import 'package:publicos_desktop/widgets/profile/profile_art_layout.dart';
import 'package:publicos_desktop/widgets/profile/manage_profile_tabs_sheet.dart';
import 'package:publicos_desktop/widgets/profile/profile_post_card.dart';
import 'package:publicos_desktop/widgets/profile/tab_icon_widget.dart'
    show TabTypeBadge;
import 'package:publicos_desktop/utils/app_history.dart';
import 'package:publicos_desktop/widgets/flag_sheet.dart';

/// Which door mounted the panel — decides the landing tab: Messages lands on
/// Chat, Contacts lands on Profile. After landing, traversal is free and
/// never leaves the section.
enum BrowserDoor { contacts, messages }

enum _TabKind { profile, chat, feeds, web, app, management, settings }

/// One launchable link on a registry app — derived from its typed pointers
/// (the client app-profile sheet's pointer set: `url` / `appstore_link` /
/// `playstore_link` / `apk_download` / `ipa_download`).
typedef _AppLink = ({String label, IconData icon, String url});

class _PanelTab {
  final _TabKind kind;
  final String label;
  final IconData icon;

  /// Chat tabs only — the peer inbox this tab converses with (null for the
  /// group chat tab, which rides the conversation topic instead).
  final String? inboxId;

  /// Feed/Web tabs only — the router record behind the tab (channel record →
  /// feed body; web-tab record → the URL the launcher fires).
  final Record? record;

  /// App tabs only — the registry app behind the tab (its pointers are the
  /// launchable links).
  final AppBookmark? app;

  /// Chat tabs only — true when this tab points at the inbox THIS DEVICE has
  /// loaded (`PublicOS.clientXmtpInboxId`). Shown dimmed and inert instead of
  /// hidden. Not a "my own profile" test: an org
  /// admin holding the org's Admin key matches it on the ORG's profile.
  final bool isLoadedInbox;

  const _PanelTab({
    required this.kind,
    required this.label,
    required this.icon,
    this.inboxId,
    this.record,
    this.app,
    this.isLoadedInbox = false,
  });

  /// Identity for preserving the selection across tab-list rebuilds.
  String get key =>
      '${kind.name}:${inboxId ?? record?.key ?? app?.appName ?? ''}';
}

/// THE shared per-contact content panel: one tabbed panel behind BOTH the
/// Contacts and Messages doors — Profile · Chat · Feeds · Web · Settings
/// (· Management for orgs). Every tab body is a
/// verbatim publicos_client port; this shell is presentation chrome only
/// (same class of thing as `InlineFlowHost`).
///
/// Tab rules per contact type are the client's `browser.dart _updateTabsList`
/// plus the record rules listed below.
/// The banner header is the client browser's collapsing header, ported:
/// profile + feed tabs land EXPANDED and the content's scroll
/// collapses it to the strip (avatar riding along); chat and the gated tabs
/// rest collapsed; tab switches animate between states. The header + every
/// tab body share the Contact-settings content-width cap.
///
/// - Profile: always (group card for group chats); the pane renders content
///   only (`externalHeader`) — the panel header owns banner/avatar/name.
/// - Chat: one tab per registered peer inbox (the loaded inbox rides along dimmed + inert); groups
///   always get exactly one (topic-direct, inboxId null).
/// - Feeds: one tab per non-expired channel record — PostsList over the
///   record URL (the client's channel-tab body), expanded-family.
/// - Web: one tab per non-expired web-tab record, RENDERED IN PLACE in the
///   embedded webview (`zero_webview_windows`), so a web record behaves the
///   way it does on mobile instead of firing outward.
///
///   A web tab takes the FULL container width, ignoring the Contact-settings
///   reader cap — that cap keeps long-form text at a readable measure, and a
///   web page brings its own responsive layout.
/// - Apps: one tab per registry app
///   (`PublicOSAppRegistry.getAllAccountApps`) carrying at least one
///   launchable link. An app with a `url` pointer RENDERS. An app whose only
///   pointers are store or download links still LAUNCHES — there is no page to
///   show for an `appstore_link` — one link firing directly, several opening
///   the picker dialog.
/// - The ↗ glyph marks **what the tap does**, not the tab kind
///   (`_isLauncherTab`): it appears only on tabs that open outside, so
///   it never claims an outcome the click will not produce.
/// - Management: orgs only.
/// - Settings: everyone except yourself (self-settings live in the Account
///   app).
///
/// Hosts should key the panel by contact identity so a selection change
/// remounts it (the contacts_pane `ValueKey(_keyOf(c))` pattern).
/// Named [Browser] to match the client's `browser.dart` — this widget IS the
/// desktop twin of that surface.
class Browser extends StatefulWidget {
  final Contact contact;
  final BrowserDoor door;

  /// Messages door, DMs: the conversation's peer inbox ID — lets the panel
  /// land on the right Chat tab immediately instead of waiting for the
  /// inbox-ID fetch.
  final String? initialInboxId;

  /// Apps landing (`AppNav.toApp` — the Apps dialog, the rail's history, the
  /// app-profile sheet): the registry app whose tab the panel should land on,
  /// the client's `/publicosAddress/:address/app/:appName` route. Seeded onto
  /// the strip at first paint, like [initialInboxId], then confirmed by the
  /// registry fetch.
  final AppBookmark? initialApp;

  /// Deep-link landing on a CUSTOM TAB — the `:key` of
  /// `/publicosAddress/:address/tab/:key`, which is the router record's own
  /// key (no `tab.`/`rss.` prefix is expected; a legacy `rss.<slug>`
  /// key is just a unique id). Covers both kinds: a `channel` record lands on
  /// the feed body, a `tab` record on the web body.
  ///
  /// Unlike [initialApp] there is nothing to seed at first paint — router
  /// records arrive with the Contact, so the tab already exists by the time
  /// the strip is built.
  final String? initialTabKey;

  /// DM topic fallback, passed through to `SimpleChatScreen` (the browser
  /// passes it "defensively when this browser was opened with a topic
  /// identifier" — same contract here; groups carry their topic on the
  /// Contact).
  final String? topic;

  /// The content-width caps, **one per tab group** (desktop-only settings,
  /// changed in the Settings dialog behind the contacts-list footer row).
  ///
  /// The kind → group mapping is [_BrowserState._capOf], the groups and
  /// their keys are [BrowserWidths]. `double.infinity` = fill.
  final BrowserWidths widths;

  /// Hard-reload the contact from chain — the host's sync (ProfilePane's
  /// pull-to-refresh routes through this).
  final Future<void> Function()? onRefresh;

  /// Open another contact's profile (the org-founder row).
  final void Function(Contact contact)? onOpenContact;

  /// Bubbled from the chat input when the user switches the active XMTP key —
  /// the ValueKey remount below handles the rebind; hosts may also want to
  /// refresh their conversation list.
  final VoidCallback? onActiveKeyChanged;

  /// Where the deck's selection slab last rested, owned by the host pane so
  /// it outlives this widget's per-contact remount: contact → contact slides
  /// the slab from there; a pane that is new (arrived from another rail
  /// screen) has none, and the slab enters from the left ([DeckSelection]).
  final DeckSelectionMemory? deckMemory;

  const Browser({
    super.key,
    required this.contact,
    required this.door,
    this.initialInboxId,
    this.initialApp,
    this.initialTabKey,
    this.topic,
    this.widths = const BrowserWidths.defaults(),
    this.onRefresh,
    this.onOpenContact,
    this.onActiveKeyChanged,
    this.deckMemory,
  });

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser>
    with TickerProviderStateMixin {
  List<_PanelTab> _tabs = const [];
  String? _currentKey;

  /// In-flight guard for the deck's reload button (`_reloadProfile`). Not
  /// `setState`-backed: the visible progress is the host's loader, so this
  /// only exists to swallow a second click.
  bool _reloading = false;

  // ── Collapsing header (the client's browser header machinery, ported) ─────
  //
  // One controller, value == expansion progress (0 collapsed strip … 1 fully
  // expanded banner). Tab switches ANIMATE it (forward for the expanded
  // family, reverse otherwise — `_updateProfileAnimationState`); on expanded
  // tabs the content's scroll DRIVES it 1:1 (`_syncHeaderToScroll`), so the
  // content rises in lockstep with the shrinking header, then scrolls under
  // the opaque strip. Constants are the desktop pane's (banner 190 / avatar
  // 104 from ProfilePane's static header; collapsed strip 56/32 from the
  // client); status-bar height is 0 on desktop, so it's dropped from the
  // client's math.
  late final AnimationController _headerAnim;

  // -- The banner dock ------------------------------------------------------
  //
  // PHASE 2 of the header's life, past the point where `_headerAnim` bottoms
  // out. Once the header is fully collapsed to the strip and the user keeps
  // scrolling, the strip's CONTENTS -- banner slice, avatar, name/address --
  // migrate up into the tab deck: the deck's contact-swatch fill crossfades
  // to the banner art and the Profile tab morphs its glyph + label into the
  // avatar + display name. The banner becomes the frame around the tabs.
  //
  // The strip itself does NOT move, and the banner does not animate on top
  // of it. Its geometry is frozen the moment phase 1 ends -- the 56px band
  // stays as the content's opaque ceiling, emptied. So this whole phase is
  // opacity work:
  // no translate, no clip, no reflow, nothing for the content to jump over.
  //
  // Deliberately a SECOND controller rather than an extension of the scroll
  // range, for a structural reason: the docked state is CHROME state, not
  // page state. It has to survive a tab switch and be settable by tab
  // identity ("Chat rests docked"), which a value derived from the current
  // page's scroll offset cannot express. Being time-based also guarantees it
  // rests at 0 or 1 -- a flick can never park the user's banner half-poured
  // into the deck.
  late final AnimationController _dockAnim;

  /// Dock trigger, in content-scroll pixels past the collapse point. The 8px
  /// band is anti-jitter only: `_syncHeaderToScroll` already clamps progress to
  /// 0 across it, so those pixels are visually inert in both directions and
  /// the hand-off still reads as starting the instant the strip lands.
  static const double _dockThreshold = 8.0;

  /// Shorter than the 300ms tab-switch. Fade and shrink both ride this one
  /// controller, so they finish together by construction rather than by
  /// matching two numbers.
  static const Duration _kDockDuration = Duration(milliseconds: 200);

  /// The width-cap tween. Shorter than the dock: the cap moves
  /// the banner AND the body under it, so it wants to be over before the eye
  /// settles on either.
  static const Duration _kCapDuration = Duration(milliseconds: 160);

  static const double _collapsedHeaderHeight = 56.0;
  static const double _collapsedAvatarSize = 32.0;
  static const double _expandedBannerHeight = 190.0;
  static const double _expandedAvatarSize = 104.0;
  static const double _hPad = 16.0;
  static const Duration _kAnimationDuration = Duration(milliseconds: 300);

  double _headerHeightAt(double t) =>
      _collapsedHeaderHeight +
      (_expandedBannerHeight - _collapsedHeaderHeight) * t;

  double _avatarSizeAt(double t) =>
      _collapsedAvatarSize + (_expandedAvatarSize - _collapsedAvatarSize) * t;

  /// Client `_calculateAvatarY`: collapsed = centered in the strip; expanded =
  /// straddling the banner's bottom edge (the /2.8 is the client's straddle
  /// ratio).
  double _avatarYAt(double t) {
    final s = _avatarSizeAt(t);
    final startY = (_collapsedHeaderHeight - s) / 2;
    final endY = _expandedBannerHeight - s / 2.8;
    return startY + (endY - startY) * t;
  }

  /// Client `_expandedVisualHeight`: banner height or the straddling avatar's
  /// bottom, whichever is lower — used as the content top inset AND as the
  /// scroll travel over which the header collapses.
  double get _expandedVisualHeight {
    final base = _headerHeightAt(1);
    final avatarBottom = _avatarYAt(1) + _avatarSizeAt(1);
    return base > avatarBottom ? base : avatarBottom + 8;
  }

  /// How much of the collapsed strip the dock has taken back, in pixels.
  ///
  /// The strip stays a real 56px band for the whole of phase 1. But once its
  /// contents leave for the deck the band is empty, and an empty band is just
  /// a gap between the tabs and the content. So phase 2 closes it: the
  /// header's height and the content's offset shed the same 56 pixels on the
  /// same curve, which is why the content rises into the space instead of a
  /// hole opening under the deck.
  ///
  /// Deliberately NOT folded into `_expandedVisualHeight` -- that getter
  /// feeds `dist`, the scroll travel the trigger is measured against, and a
  /// travel that moved while the animation ran would fight its own trigger.
  double get _dockRelief => _collapsedHeaderHeight * _headerDock;

  /// The expanded-header family (client `_isExpandedHeaderTab`): these tabs
  /// land with the banner fully expanded and their content's scroll collapses
  /// it. Everything else rests DOCKED -- banner in the deck, strip emptied.
  ///
  /// The family is the client's (profile / management / channel).
  /// `GroupVotingView` accepts `topInset` and consumes it exactly as the
  /// client's does (`edgeOffset` + list top padding), so management needs
  /// only the family line plus the real inset at the mount site.
  ///
  /// Settings is NOT in the family: `ContactSettingsScreen` takes no
  /// `topInset`, so it would have to be plumbed first.
  bool get _isExpandedHeaderTab => _isExpandedHeaderTabFor(_current);

  /// The same test against an arbitrary tab — `_selectTab` needs to ask it of
  /// the tab it is about to move to, before `_current` has moved.
  bool _isExpandedHeaderTabFor(_PanelTab t) =>
      t.kind == _TabKind.profile ||
      t.kind == _TabKind.feeds ||
      t.kind == _TabKind.management;

  /// Client `_syncHeaderToScroll`, verbatim math: progress = 1 − scrolled /
  /// travel. Fed by a [ContentMetricsListener] (outer vertical list only,
  /// update + metrics notifications, never start/end: those can fire inside
  /// layout and an animation-value write there asserts; the metrics one
  /// covers a shrinking page whose `pixels` Flutter corrects without a
  /// scroll update).
  void _syncHeaderToScroll(ScrollMetrics metrics) {
    if (!_isExpandedHeaderTab) return;
    if (_focusedPost != null) return;
    final double dist = (_expandedVisualHeight - _collapsedHeaderHeight)
        .clamp(1.0, double.infinity);
    final double px = metrics.pixels < 0 ? 0 : metrics.pixels;
    final double progress = (1 - (px / dist)).clamp(0.0, 1.0);
    if ((_headerAnim.value - progress).abs() > 0.001) {
      _headerAnim.value = progress;
    }
    // Phase 2's trigger. Deliberately NOT overscroll -- a feed never reaches
    // its bottom, and top-overscroll is the wrong end. Ordering on the way
    // back up falls out for free: the header cannot begin re-expanding until
    // px < dist, which is already below the undock point, so the deck always
    // empties before the banner starts growing again.
    _setDocked(px >= dist + _dockThreshold);
  }

  /// The reader width cap this tab's body is drawn at. Extracted from `_body`
  /// so a tab switch can compare the outgoing and incoming caps BEFORE it
  /// commits, which is the only way to know whether the header is about to be
  /// re-measured mid-animation.
  ///
  /// Four groups for seven kinds ([BrowserWidths]) — profile/management/
  /// settings share the account's own pages, feeds gets the reading measure it
  /// shares with the Feeds destination, chat gets its own, and a web page
  /// brings its own layout so it always fills.
  double _capOf(_PanelTab t) {
    switch (t.kind) {
      case _TabKind.web:
      case _TabKind.app:
        return double.infinity;
      case _TabKind.chat:
        return widget.widths.chat;
      case _TabKind.feeds:
        return widget.widths.feeds;
      case _TabKind.profile:
      case _TabKind.management:
      case _TabKind.settings:
        return widget.widths.profile;
    }
  }

  /// Drives [_animatedCap]. Rests at 1 (= "show the current tab's own cap").
  late final AnimationController _capAnim;
  double _capFrom = double.infinity;
  double _capTo = double.infinity;

  /// The cap the frame is actually drawn at.
  ///
  /// **Why a tween exists at all.** The cap is per-group, so two tabs that
  /// share the banner can want different widths — profile 740 → feeds 520 is
  /// the typical case. `_isExpandedHeaderTabFor` keeps the banner
  /// on screen across that switch, so the width cannot simply be re-measured
  /// the way [_headerSnapped] handles a switch to a collapsed tab: it would be
  /// the exact jump the snap rule exists to avoid, except with nothing hidden
  /// to cover it. So the width is animated.
  ///
  /// Safe **because of where it runs**: a webview can never be in the expanded
  /// family, so no relayout-per-frame page is ever inside a moving cap — the
  /// reason the snap exists instead of a tween on the other switches.
  double get _animatedCap {
    final resting = _capOf(_current);
    if (!_capAnim.isAnimating) return resting;
    final t = Curves.easeOutCubic.transform(_capAnim.value);
    return _capFrom + (_capTo - _capFrom) * t;
  }

  /// Start the tween into the newly selected tab's cap, or snap.
  ///
  /// Snaps (and it must) when either end is `double.infinity` — there is no
  /// lerp to a Full-width cap — and when the header is being snapped away
  /// anyway, which is every switch that leaves the expanded family: the banner
  /// is gone in the same frame, so there is nothing for the width to jump in
  /// front of, and the outgoing side may be a webview.
  void _updateCapAnimation(double from) {
    final to = _capOf(_current);
    if (_headerSnapped || from == to || !from.isFinite || !to.isFinite) {
      _capAnim.value = 1;
      return;
    }
    _capFrom = from;
    _capTo = to;
    _capAnim.forward(from: 0);
  }

  /// Treat the header as fully docked no matter where the tween actually is.
  ///
  /// The header and the content share one `ConstrainedBox`, and its cap is a
  /// function of the tab kind — so switching from a capped tab (a feed at
  /// the reader width, banner expanded) to an uncapped one (a web tab) makes
  /// the header **full width in a single frame**, while the dock has only just
  /// started running. The banner is never animated across that width; it is
  /// re-measured, and then spends 200ms shrinking and fading at a width it
  /// never had. That is the jump.
  ///
  /// Rather than animate a width — which would drag the CONTENT's width along
  /// with it and relayout a webview every frame — the header simply skips its
  /// exit on those switches: an instant disappearance beats the jump. It is
  /// gone in the same frame the width changes, so the full-width frame is
  /// never drawn.
  ///
  /// **The deck half is deliberately NOT snapped.** `_tabDeck` keeps reading
  /// `_dockAnim` directly, so the banner still pours into the tab bar and the
  /// Profile tab still morphs, at full duration — the deck is full width on
  /// every tab, so nothing up there is re-measured and there is no jump to
  /// avoid. Only the half that lives inside the cap gives up its animation.
  bool _headerSnapped = false;

  /// The dock value the CONTENT side should use — the header's height and
  /// opacity, and the strip's closing relief. [_tabDeck] must not use this.
  ///
  /// The expanded-family test is an INVARIANT, not a repeat of `_selectTab`'s
  /// direction logic: a tab whose header must be visible can never be snapped,
  /// whoever moved `_currentKey`. `_rebuildTabs` can reassign it on its own
  /// when a record lapses out from under the selection, and that path does not
  /// run `_updateHeaderAnimationState` — without this guard a stale flag
  /// would leave a profile tab with no banner at all.
  double get _headerDock =>
      (_headerSnapped && !_isExpandedHeaderTab) ? 1.0 : _dockAnim.value;

  /// Drive the dock toward [docked]. Idempotent -- `forward`/`reverse` on an
  /// already-settled controller is a no-op, so the scroll handler can call
  /// this on every notification.
  void _setDocked(bool docked) {
    if (docked) {
      _dockAnim.forward();
    } else {
      _dockAnim.reverse();
    }
  }

  /// Client `_updateProfileAnimationState`: animate toward the tab's resting
  /// state on switch (the scroll then takes over on expanded tabs).
  ///
  /// The dock rides along, because it is the other half of the same resting
  /// state: expanded-family tabs land undocked (banner in the content),
  /// everything else lands docked (banner in the deck). Both controllers run
  /// together rather than in sequence -- at mid-switch the banner is
  /// simultaneously shrinking and dissolving into the deck, which is the
  /// hand-off frame the design asks for. If that reads muddy on a tall
  /// banner, delay the dock with an `Interval(0.35, 1.0)` curve here.
  void _updateHeaderAnimationState() {
    if (_isExpandedHeaderTab) {
      _headerAnim.forward();
      _dockAnim.reverse();
    } else {
      _headerAnim.reverse();
      _dockAnim.forward();
    }
  }

  /// Chat tabs resolved asynchronously (inbox-ID fetch); seeded synchronously
  /// for groups and for the Messages door's `initialInboxId` so landing on
  /// Chat never waits on the network.
  List<_PanelTab> _chatTabs = const [];

  /// App launcher tabs, resolved asynchronously from the on-chain registry
  /// (apps aren't on the Contact — same class of fetch as [_loadChatTabs]).
  List<_PanelTab> _appTabs = const [];

  /// Published by SimpleChatScreen once a topic resolves — drives the tab
  /// strip's gear (the client hangs it on the browser address bar).
  VoidCallback? _chatSettingsOpener;

  /// Does the running page hold ANY connect grant? Driven by the webview's own
  /// `ConnectGate` via `onConnectionChanged`, and it is the ONLY thing that
  /// puts the web key indicator on screen — no grant, no glyph. Resets to
  /// false with every webview remount, because that widget is keyed on the URL.
  bool _webConnected = false;

  /// The running page's own [ChainRegistry], handed over by the webview,
  /// the chain it currently reads on, and a reload for it. Held only so the
  /// deck cluster can show the chain and move it: the registry belongs to
  /// the webview and dies with it, which is what makes "PublicOS on every
  /// fresh page" true rather than a remembered setting.
  ChainRegistry? _webChains;
  String? _webChainId;
  Future<void> Function()? _webViewReload;

  /// The user picked another chain from the deck's chain badge.
  ///
  /// Switching moves **this tab only** — `switchChain` writes the page's own
  /// registry, which decides what `eth_chainId` answers, which node reads are
  /// proxied to, and which chain a transaction is signed for under EIP-155.
  ///
  /// Then it **reloads the page**, and that is the part that makes the control
  /// useful rather than decorative. The switch already emits `chainChanged`,
  /// which is everything the spec asks and everything a modern dApp needs —
  /// but a dApp written before wallets could switch reads the chain once on
  /// mount and never listens, so without the reload the user switches and
  /// watches nothing happen. Those are exactly the sites this exists for.
  Future<void> _switchWebChain(String chainId) async {
    final registry = _webChains;
    if (registry == null) return;
    try {
      registry.switchChain(chainId); // fires onChainChanged → badge re-renders
      await _webViewReload?.call();
    } catch (e) {
      // 4902 on a chain we do not carry. The picker only offers chains from
      // the registry, so this is a "cannot happen" that must still not crash.
      debugPrint('[web3] chain switch to $chainId refused: $e');
    }
  }

  /// Does the running page have in-page history? Driven by the webview's
  /// `onCanGoBackChanged`, which WebView2 pushes as an event on every
  /// navigation edge. Imported from the client: without a listener the deck
  /// has no way back out of a link a dApp has navigated into.
  bool _webViewCanGoBack = false;

  /// The running webview's `goBack()`, handed over on controller creation.
  ///
  /// A closure, not a controller: the two engines' controller types have
  /// nothing in common, so `PublicOSWebView` hands out the one capability the
  /// host actually needs rather than leaking `WebView2Controller` upward.
  /// Cleared whenever the webview remounts (it is keyed on the URL).
  Future<void> Function()? _webViewGoBack;

  /// Bumped whenever the key indicator's picker changes this site's grants.
  /// Handed to the webview, whose `didUpdateWidget` re-reads the set and tells
  /// the running page. A revision rather than a selected-key label, because
  /// switching the preferred key does not change what a site may see — the
  /// permission does.
  int _grantsRevision = 0;

  /// `accounts[0]` for the current page, from the webview's
  /// `onActiveAccountChanged` — feeds the key chip's emoji.
  String? _webActiveAccount;

  /// Is the ACTIVE channel tab's feed in any of the user's lists? Drives the
  /// deck cluster's Follow (bookmark) icon — filled when followed. Client
  /// browser's `_isCurrentRssFeedInList` (the client's address-bar per-tab
  /// actions live in the deck's top-right cluster here).
  bool _currentFeedInList = false;

  // ── Channel sign-in on a feeds tab ────────────────────────────────────
  // The client browser's address-bar key, as a deck slot: exists iff the
  // channel has signalled sign-in (a row), colour = the RULE's answer, click
  // → Allow · Deny · Forget, then the list refetches. The ASK lives in
  // PostsList (shared with the feeds pane).
  ChannelSigninPref? _signinPref;
  bool _signinEffective = false;
  int _channelRefreshTick = 0;

  String? get _channelTabUrl =>
      _current.kind == _TabKind.feeds ? _current.record?.value : null;

  Future<void> _refreshSigninPref() async {
    final url = _channelTabUrl;
    if (url == null || url.isEmpty) {
      if (_signinPref != null && mounted) {
        setState(() {
          _signinPref = null;
          _signinEffective = false;
        });
      }
      return;
    }
    final pref = await PublicOSChannelSignin.getPref(url);
    final effective =
        pref == null ? false : await PublicOSChannelSignin.shouldSign(url);
    if (!mounted || _channelTabUrl != url) return;
    setState(() {
      _signinPref = pref;
      _signinEffective = effective;
    });
  }

  Future<void> _showSigninMenu() async {
    final pref = _signinPref;
    final url = _channelTabUrl;
    if (pref == null || url == null) return;
    final choice = await showChannelSigninMenu(
      context,
      pref: pref,
      effective: _signinEffective,
    );
    if (choice == null || !mounted) return;
    await PublicOSChannelSignin.setDecision(url, choice.decision);
    await _refreshSigninPref();
    if (!mounted) return;
    setState(() => _channelRefreshTick++);
  }

  /// Client `_isCurrentAppBookmarked` — the deck's bookmark button state for
  /// an app tab.
  bool _currentAppBookmarked = false;

  bool get _isGroup => widget.contact.isGroupChat;

  /// True when the panel shows the signed-in account (browser.dart
  /// `_isViewingSelf`): self-settings live in the Account app, not here.
  bool get _isSelf {
    final address = widget.contact.publicosAddress;
    final mine = AppStateNotifier.currentMyContact?.publicosAddress;
    return address != null && mine != null &&
        address.eip55With0x == mine.eip55With0x;
  }

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: _kAnimationDuration,
    );
    _dockAnim = AnimationController(vsync: this, duration: _kDockDuration);
    _capAnim = AnimationController(
      vsync: this,
      duration: _kCapDuration,
      value: 1,
    );
  }

  /// Everything the panel seeds at mount that needs localized strings runs
  /// here, not in [initState]: tab labels resolve through `context.l10n`,
  /// and an inherited lookup inside `initState` throws in debug builds.
  /// `didChangeDependencies` fires once before the first build, so the order
  /// and the first paint are unchanged.
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _refreshAccountFollowState();
    _seedChatTabs();
    _seedAppTab();
    _rebuildTabs(selectLanding: true);
    // Land at the tab's resting state — no entrance animation. The panel is
    // keyed per contact and the browser keeps no scroll memory, so a fresh
    // mount on Profile is always expanded + undocked and one on Chat always
    // docked, with nothing moving on arrival.
    _headerAnim.value = _isExpandedHeaderTab ? 1.0 : 0.0;
    _dockAnim.value = _isExpandedHeaderTab ? 0.0 : 1.0;
    _loadChatTabs();
    _loadAppTabs();
    _loadOrgMembership();
    // Landing tab may be a channel — seed the Follow icon's state.
    _checkCurrentFeedInList();
    // Landing tab may be an app (AppNav.toApp) — seed the bookmark button,
    // count the visit, and if the app has nothing to render (store links
    // only) fire it the way a click on its tab would.
    final landingApp = widget.initialApp;
    if (landingApp != null && _current.kind == _TabKind.app) {
      _checkCurrentAppBookmarkStatus();
      _recordAppOpen(landingApp);
    } else if (landingApp != null) {
      final launcher = _appTabs
          .where((t) => t.app?.appName == landingApp.appName)
          .toList();
      if (launcher.isNotEmpty) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _selectTab(launcher.first));
      }
    }
  }

  /// Apps landing: put the arrival app's tab on the strip at first paint so
  /// the panel can land on it without waiting for the registry fetch — the
  /// `initialInboxId` pattern. `_loadAppTabs` then CONFIRMS it (its no-flicker
  /// compare is by slug + label, and the seeded tab is built by the same
  /// `_appTabFor`, so a fetch that lists the app leaves the strip untouched).
  void _seedAppTab() {
    final app = widget.initialApp;
    if (app == null || _appLinksOf(context.l10n, app).isEmpty) return;
    _appTabs = [_appTabFor(app)];
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _dockAnim.dispose();
    _capAnim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant Browser oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Hosts remount on selection change (keyed panel); this path covers the
    // same contact coming back refreshed from a chain sync — record-derived
    // tabs (Feeds/Web) may have appeared or lapsed. Chat tabs follow the
    // client's rule (browser.dart `_initializeChatState`): re-seed from local
    // records only when EMPTY — never stomp tabs the chain fetch already
    // confirmed (that's the local→chain→local flicker).
    if (widget.contact != oldWidget.contact) {
      if (widget.contact.publicosAddress != oldWidget.contact.publicosAddress) {
        _refreshAccountFollowState();
      }
      if (_chatTabs.isEmpty) _seedChatTabs();
      _rebuildTabs(selectLanding: false);
      _loadChatTabs();
      _loadAppTabs();
      _loadOrgMembership();
      _checkCurrentFeedInList();
      if (_profileIdentity(widget.contact) !=
          _profileIdentity(oldWidget.contact)) {
        _resetHeaderForProfileRemount();
      }
      // A different contact is a different profile; edit rights were resolved
      // against the old one and _loadOrgMembership has not answered yet.
      _isEditMode = false;
      // A chain sync hands the SAME account back as a new instance; only a
      // different account closes an open post.
      if (widget.contact.publicosAddress != oldWidget.contact.publicosAddress) {
        _focusedPost = null;
      }
    }
  }

  /// Who the profile pane is showing — its key (`_tabBody`). A chain sync
  /// hands the same account back as a NEW `Contact` instance (`Contact`
  /// overrides neither `==` nor `hashCode`), so the key must be built from
  /// identity, never the object: keyed on `contact.hashCode`, every sync
  /// would remount the pane and replay every card's entrance animation.
  static String _profileIdentity(Contact c) =>
      c.publicosAddress?.eip55With0x ?? c.xmtpConversationTopic ?? c.displayName;

  /// A different account REMOUNTS the profile body (its key is
  /// [_profileIdentity]), so the header has to be put back where a fresh mount
  /// would leave it: the new `_ProfilePaneState`'s scroll starts at 0, while
  /// the header's two controllers are Browser state and would otherwise stay
  /// wherever the last scroll left them — content at the top, header collapsed
  /// and docked, and `topInset` of empty band in between.
  ///
  /// Only on a change of identity. A refreshed copy of the SAME account keeps
  /// its pane (and its scroll), so the header must keep matching it.
  ///
  /// Snapped, not animated: the body does not ease back to the top, it is
  /// simply rebuilt there, so the header has to arrive in the same frame or
  /// it animates over content that already moved. Setting a controller's
  /// `value` rebuilds both `AnimatedBuilder`s, so no `setState`.
  ///
  /// Profile only — it is the only body keyed on the contact. A feed tab is
  /// keyed on its record and keeps both its scroll and its header.
  void _resetHeaderForProfileRemount() {
    if (_current.kind != _TabKind.profile) return;
    // A post is open over the profile: keep the header collapsed; the profile
    // underneath remounted at the top, so Back returns to a fresh profile.
    if (_focusedPost != null) {
      _focusSavedHeader = 1.0;
      _focusSavedDock = 0.0;
      return;
    }
    _headerAnim.value = 1.0;
    _dockAnim.value = 0.0;
  }

  // ── Tab construction ──────────────────────────────────────────────────────

  /// Synchronous chat tabs: the group's single topic-tab, or a placeholder
  /// tab for the Messages door's known peer inbox.
  ///
  /// LOCAL-FIRST (client parity, browser.dart `_initializeChatState`): chat
  /// tabs paint synchronously from the contact's locally stored
  /// `registeredInboxIDs` — one per inbox, carrying the locally stored label
  /// "so first paint matches what the chain sync will later confirm; 'Chat'
  /// is only the empty-label fallback". The chain fetch then CONFIRMS rather
  /// than introduces tabs in the common case, so the strip doesn't jump.
  void _seedChatTabs() {
    if (_isGroup) {
      _chatTabs = [
        _PanelTab(
          kind: _TabKind.chat,
          label: context.l10n.browserTabChat,
          icon: Icons.chat_bubble_outline,
        ),
      ];
      return;
    }

    final tabs = _localChatTabs();

    // Messages door: make sure the conversation we arrived on has its tab on
    // first paint even if the local record set lags behind.
    final seeded = widget.initialInboxId;
    if (seeded != null && !tabs.any((t) => t.inboxId == seeded)) {
      tabs.insert(
        0,
        _PanelTab(
          kind: _TabKind.chat,
          label: context.l10n.browserTabChat,
          icon: Icons.chat_bubble_outline,
          inboxId: seeded,
        ),
      );
    }
    _chatTabs = tabs;
  }

  /// The client's `_localChatTabsFor`, verbatim rules: one tab per locally
  /// stored [InboxEntry], stored label ('Chat' fallback). The loaded key's own
  /// inbox is flagged rather than skipped — shown dimmed and inert.
  List<_PanelTab> _localChatTabs() {
    final tabs = <_PanelTab>[];
    for (final entry in widget.contact.registeredInboxIDs ?? <InboxEntry>[]) {
      final label = entry.label.trim();
      tabs.add(
        _PanelTab(
          kind: _TabKind.chat,
          label: label.isNotEmpty ? label : context.l10n.browserTabChat,
          icon: Icons.chat_bubble_outline,
          inboxId: entry.inboxId,
          isLoadedInbox: _isLoadedInbox(entry.inboxId),
        ),
      );
    }
    return tabs;
  }

  /// Phase 2 — the browser's chain fetch (browser.dart:648-717):
  /// `getAllAccountInboxIds` for publicos contacts replaces the local tabs
  /// when it lands. XMTP-only contacts have no chain listing — their local
  /// tabs ARE the truth, nothing to fetch.
  Future<void> _loadChatTabs() async {
    final l10n = context.l10n; // resolved before the awaits below
    if (_isGroup) return;
    final contact = widget.contact;
    if (contact.publicosAddress == null) return;
    final tabs = <_PanelTab>[];

    try {
      final inboxData =
          await PublicOSXmtp.getAllAccountInboxIds(contact.publicosAddress!);
      if (inboxData == null) return; // no listing → keep the local paint
      for (int i = 0; i < inboxData.inboxIds.length; i++) {
        final inboxIdHex = inboxData.inboxIds[i]
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        final label = (i < inboxData.labels.length &&
                inboxData.labels[i].trim().isNotEmpty)
            ? inboxData.labels[i]
            : l10n.browserTabChat;
        tabs.add(
          _PanelTab(
            kind: _TabKind.chat,
            label: label,
            isLoadedInbox: _isLoadedInbox(inboxIdHex),
            icon: Icons.chat_bubble_outline,
            inboxId: inboxIdHex,
          ),
        );
      }
    } catch (_) {
      // Fetch failed → keep the local-first paint; a Messages-door tab still
      // converses (it came in with a live inbox ID).
      return;
    }

    if (!mounted) return;
    // Keep the arrival tab if the chain listing lags behind the live
    // conversation.
    final seeded = widget.initialInboxId;
    if (seeded != null && !tabs.any((t) => t.inboxId == seeded)) {
      tabs.insert(
        0,
        _PanelTab(
          kind: _TabKind.chat,
          label: l10n.browserTabChat,
          icon: Icons.chat_bubble_outline,
          inboxId: seeded,
        ),
      );
    }
    // The common case: the chain confirms exactly what the local records
    // painted. Skip the rebuild entirely so the strip never flickers.
    if (_sameTabs(tabs, _chatTabs)) return;
    setState(() {
      _chatTabs = tabs;
      _rebuildTabs(selectLanding: false);
    });
  }

  static bool _sameTabs(List<_PanelTab> a, List<_PanelTab> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      // isLoadedInbox is compared too: switching keys changes only the flag,
      // and the strip must repaint for the dim to move.
      if (a[i].inboxId != b[i].inboxId ||
          a[i].label != b[i].label ||
          a[i].isLoadedInbox != b[i].isLoadedInbox) {
        return false;
      }
    }
    return true;
  }

  /// True when [inboxId] is the inbox loaded into XMTP on this device right
  /// now. Twin of the client's `_isLoadedInbox`.
  bool _isLoadedInbox(String inboxId) {
    final current = PublicOS.clientXmtpInboxId;
    return current != null &&
        current.isNotEmpty &&
        inboxId.toLowerCase() == current.toLowerCase();
  }

  /// The app's launchable links, in launch-priority order — web app first
  /// (the client's only tab-worthy pointer), then stores, then direct
  /// downloads. Pointer keys are the client app-profile sheet's, verbatim.
  static List<_AppLink> _appLinksOf(AppLocalizations l10n, AppBookmark app) {
    final specs = <(String, String, IconData)>[
      ('url', l10n.desktopAppLinkWebApp, Icons.public_rounded),
      ('appstore_link', l10n.desktopAppLinkAppStore, Icons.apple_rounded),
      ('playstore_link', l10n.desktopAppLinkPlayStore, Icons.android_rounded),
      ('apk_download', l10n.appProfileSheetDownloadApk, Icons.android_rounded),
      ('ipa_download', l10n.appProfileSheetDownloadIpa, Icons.apple_rounded),
    ];
    return [
      for (final (type, label, icon) in specs)
        if ((app.getPointer(type)?.value ?? '').trim().isNotEmpty)
          (label: label, icon: icon, url: app.getPointer(type)!.value.trim()),
    ];
  }

  /// The URL a tab RENDERS in the embedded webview, or `null` when it has
  /// nothing renderable and must still fire the OS browser.
  ///
  /// Anything we can actually show renders: a web record and a web app
  /// render in place like they do on mobile.
  ///
  /// What launches instead: an app whose only pointers are store or download
  /// links. An `appstore_link` is not a page to render — there is nothing to
  /// put in a webview — so those carry the `↗` and fire outward. This
  /// is why desktop's tab filter can stay wider than the client's `url`-only
  /// one without lying about what a tab does.
  static String? _renderableUrl(_PanelTab t) {
    switch (t.kind) {
      case _TabKind.web:
        final url = t.record?.tabUrl?.trim();
        return (url == null || url.isEmpty) ? null : url;
      case _TabKind.app:
        final url = t.app?.getPointer('url')?.value.trim();
        return (url == null || url.isEmpty) ? null : url;
      default:
        return null;
    }
  }

  /// Whether this tab behaves as a launcher — drives the `↗` glyph, so
  /// the glyph never claims an outcome the tap will not produce.
  static bool _isLauncherTab(_PanelTab t) =>
      (t.kind == _TabKind.web || t.kind == _TabKind.app) &&
      _renderableUrl(t) == null;

  /// Registry fetch → launcher tabs. Wider filter than the client's
  /// `url != null` (its tabs must render in the webview): on desktop every
  /// link launches externally anyway, so any app with at least one launchable
  /// link earns a tab — link-less registry entries stay off the strip.
  /// Is the VIEWER a member of the org being browsed? Gates the Management
  /// tab's write controls (start vote / cast / delegate).
  ///
  /// Resolution copied verbatim from the client (`pages/browser.dart:774-790`):
  /// list the orgs the signed-in account belongs to, then test whether the
  /// browsed contact is one of them. Same guard triple (org account · has a
  /// publicos address · we have one too) and the same fail-closed catch.
  bool _isOrgMember = false;

  /// Profile edit mode. The client keeps this on `browser.dart` too, and for
  /// the same reason: the toggle lives in the chrome, the writes live in
  /// `ProfilePane`, and the avatar/banner/background/tabs surfaces are the
  /// header's own — none of which the body can own.
  bool _isEditMode = false;

  /// A pinned post opened IN the content area: the post page covers the
  /// profile and the header collapses
  /// the way a chat tab's does; Back animates the header to where it was.
  /// The profile stays mounted underneath, so its scroll is untouched.
  Widget Function(VoidCallback onBack)? _focusedPost;
  double _focusSavedHeader = 1;
  double _focusSavedDock = 0;

  void _openPostInPlace(Widget Function(VoidCallback onBack) builder) {
    if (_focusedPost == null) {
      _focusSavedHeader = _headerAnim.value;
      _focusSavedDock = _dockAnim.value;
    }
    setState(() => _focusedPost = builder);
    _headerAnim.animateTo(0, curve: Curves.easeOutCubic);
    _dockAnim.animateTo(1, curve: Curves.easeOutCubic);
  }

  void _closePostInPlace() {
    if (_focusedPost == null) return;
    setState(() => _focusedPost = null);
    _headerAnim.animateTo(_focusSavedHeader, curve: Curves.easeOutCubic);
    _dockAnim.animateTo(_focusSavedDock, curve: Curves.easeOutCubic);
  }

  /// Who may write to the profile currently on screen.
  bool get _canEditProfile =>
      _isSelf || (widget.contact.isOrgAccount && _isOrgMember);

  Future<void> _loadOrgMembership() async {
    final contact = widget.contact;
    final me = AppStateNotifier.currentMyContact?.publicosAddress;
    if (!(contact.isOrgAccount == true) ||
        contact.publicosAddress == null ||
        me == null) {
      if (_isOrgMember && mounted) setState(() => _isOrgMember = false);
      return;
    }
    try {
      final userGroups = await PublicOSGovernance.getOrgsForAccount(me);
      final isMember = userGroups.any((g) =>
          g.eip55With0x.toLowerCase() ==
          contact.publicosAddress!.eip55With0x.toLowerCase());
      if (mounted) setState(() => _isOrgMember = isMember);
    } catch (_) {
      if (mounted) setState(() => _isOrgMember = false);
    }
  }

  Future<void> _loadAppTabs() async {
    final address = widget.contact.publicosAddress;
    if (address == null) return;
    List<AppBookmark>? apps;
    try {
      apps = await PublicOSAppRegistry.getAllAccountApps(address);
    } catch (_) {
      return; // fetch failed → keep whatever painted
    }
    if (apps == null || !mounted) return;
    final tabs = <_PanelTab>[
      for (final app in apps)
        if (_appLinksOf(context.l10n, app).isNotEmpty) _appTabFor(app),
    ];
    // No-flicker rule, same as chat: skip the rebuild when nothing changed.
    if (_sameAppTabs(tabs, _appTabs)) return;
    setState(() {
      _appTabs = tabs;
      _rebuildTabs(selectLanding: false);
    });
  }

  static _PanelTab _appTabFor(AppBookmark app) => _PanelTab(
        kind: _TabKind.app,
        label: app.displayName.trim().isNotEmpty ? app.displayName : app.appName,
        icon: Icons.apps_rounded,
        app: app,
      );

  static bool _sameAppTabs(List<_PanelTab> a, List<_PanelTab> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].app?.appName != b[i].app?.appName ||
          a[i].label != b[i].label) {
        return false;
      }
    }
    return true;
  }

  void _rebuildTabs({required bool selectLanding}) {
    final contact = widget.contact;

    // Record-derived tabs — client parity (browser custom tabs): ONE tab per
    // non-expired router record, ordered by the record's own order. Channel
    // records mount the feed body (PostsList over the record URL); web-tab
    // records mount the web body.
    final feedTabs = contact.records
        .where((r) => r.routerSubtype == RouterSubtype.channel && !r.isExpired)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final webTabs = contact.records
        .where((r) => r.routerSubtype == RouterSubtype.tab && !r.isExpired)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final tabs = <_PanelTab>[
      _PanelTab(
        kind: _TabKind.profile,
        label: context.l10n.browserTabProfile,
        icon: Icons.person_outline,
      ),
      ..._chatTabs,
      for (final r in feedTabs)
        _PanelTab(
          kind: _TabKind.feeds,
          label: r.tabName ?? context.l10n.browserTabChannel,
          icon: Icons.rss_feed_rounded,
          record: r,
        ),
      for (final r in webTabs)
        _PanelTab(
          kind: _TabKind.web,
          label: r.tabName ?? context.l10n.browserTabWeb,
          icon: Icons.language,
          record: r,
        ),
      ..._appTabs,
      if (contact.isOrgAccount == true)
        _PanelTab(
          kind: _TabKind.management,
          label: context.l10n.browserTabManagement,
          icon: Icons.how_to_vote_outlined,
        ),
      if (!_isSelf)
        _PanelTab(
          kind: _TabKind.settings,
          label: context.l10n.browserTabSettings,
          icon: Icons.settings_outlined,
        ),
    ];

    _tabs = tabs;

    if (selectLanding) {
      // Apps landing outranks the door: land on the arrival app's tab when it
      // has something to render (a launcher-only app can never be current —
      // initState fires it instead).
      final landingApp = widget.initialApp;
      _PanelTab? appTab;
      if (landingApp != null) {
        for (final t in tabs) {
          if (t.kind == _TabKind.app &&
              t.app?.appName == landingApp.appName &&
              _renderableUrl(t) != null) {
            appTab = t;
            break;
          }
        }
      }
      // A `/tab/:key` deep link, matched on the ROUTER RECORD'S KEY across
      // both kinds (channel + web). Client parity: an unmatched key is NOT an
      // error, it just lands on the profile -- the record may have expired or
      // been deleted since the link was shared.
      _PanelTab? tabLanding;
      final landingTabKey = widget.initialTabKey;
      if (landingTabKey != null && landingTabKey.isNotEmpty) {
        for (final t in tabs) {
          if ((t.kind == _TabKind.feeds || t.kind == _TabKind.web) &&
              t.record?.key == landingTabKey) {
            tabLanding = t;
            break;
          }
        }
      }
      if (tabLanding != null) {
        _currentKey = tabLanding.key;
      } else if (landingTabKey != null && landingTabKey.isNotEmpty) {
        // Asked for a tab that is not on this profile -- expired, deleted, or
        // a mistyped key. Land on the profile (client parity) but TELL the
        // user: a deep link that silently shows a profile instead of the tab
        // it named is indistinguishable from one that did nothing at all.
        // Same string the client's browser shows for the same failure.
        // Post-frame because this runs during a build.
        _currentKey = tabs.first.key;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(context.l10n.browserTabNotFound)),
          );
        });
      } else if (appTab != null) {
        _currentKey = appTab.key;
      } else if (widget.door == BrowserDoor.messages) {
        // Land on the chat tab of the inbox the conversation was opened on,
        // not the contact's first inbox: otherwise someone with two inboxes
        // opens the first one whichever row was tapped. The
        // client selects `_selectedChatInboxId` the same way. The seed above
        // guarantees that tab exists.
        final chat = tabs.where((t) => t.kind == _TabKind.chat).toList();
        final arrived = widget.initialInboxId?.toLowerCase();
        final match = arrived == null
            ? null
            : chat.where((t) => t.inboxId?.toLowerCase() == arrived).firstOrNull;
        _currentKey = (match ?? (chat.isNotEmpty ? chat.first : tabs.first)).key;
      } else {
        // An XMTP contact (no PublicOS address) has no profile to land on, so
        // it opens on its conversation. Port of the client's
        // `AppNav.toContact` (router_helpers.dart): address -> profile, else
        // first inbox -> chat. Without it every Contacts-door open of an XMTP
        // contact (a list row, a bubble avatar, a group member) would show an
        // empty profile and never the chat. The inbox this device has loaded
        // is skipped: the client's self-chat guard lands that on the profile.
        final address = contact.publicosAddress?.eip55With0x;
        final hasAddress = address != null &&
            address != '0x0000000000000000000000000000000000000000';
        final xmtpChat = hasAddress || _isGroup
            ? null
            : tabs
                .where((t) =>
                    t.kind == _TabKind.chat &&
                    t.inboxId != null &&
                    !t.isLoadedInbox)
                .firstOrNull;
        _currentKey = (xmtpChat ?? tabs.first).key;
      }
    } else if (!tabs.any((t) => t.key == _currentKey)) {
      // A tab that no longer exists can't stay selected (client parity).
      _currentKey = tabs.first.key;
    }
  }

  _PanelTab get _current =>
      _tabs.firstWhere((t) => t.key == _currentKey, orElse: () => _tabs.first);

  // ── Mature-content gate (client browser.dart twin) ─────────────────────────
  // A profile whose owner set `mature_content: true` paints nothing until the
  // viewer says they are 18+; the yes is kept per profile in Core settings
  // (`mature_ok.<address>`). The browser lives inside a pane here, so "Go
  // back" can't pop: it leaves a small placeholder with a button to ask again,
  // and picking another contact moves on as usual.

  String? _matureCleared;
  String? _matureAskingFor;
  String? _matureDeclined;

  String? get _matureGateKey {
    final c = widget.contact;
    if (!c.isMatureContent) return null;
    return c.publicosAddress?.eip55With0x ?? c.displayName;
  }

  void _scheduleMatureGate(String key, {bool force = false}) {
    if (_matureAskingFor == key && !force) return;
    _matureAskingFor = key;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingKey = 'mature_ok.$key';
      var ok = false;
      if (!force) {
        try {
          ok = (await PublicOSSettings.getSetting(settingKey))?.value == 'true';
        } catch (_) {} // signed out: ask every time
      }
      if (!mounted) return;
      if (!ok) ok = await _askMatureGate() == true;
      if (!mounted) return;
      if (!ok) {
        setState(() => _matureDeclined = key);
        return;
      }
      try {
        await PublicOSSettings.setSetting(
          settingKey,
          Record.asSettings(
            key: settingKey,
            value: 'true',
            isSystem: true,
          ),
        );
      } catch (_) {}
      if (mounted) setState(() => _matureCleared = key);
    });
  }

  Future<bool?> _askMatureGate() {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final text = TextStyle(
        fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 13, height: 1.4);
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(
            minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.matureGateTitle,
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontWeight: FontWeight.w800)),
        content: Text(l10n.matureGateBody, style: text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.matureGateBack,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.matureGateContinue,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  /// What the pane shows while a mature profile is uncleared.
  Widget _matureGatePlaceholder(GlassTokens tokens, String key) {
    final l10n = context.l10n;
    if (_matureDeclined != key) return const SizedBox.expand();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_outlined, size: 28, color: tokens.textDim),
          const SizedBox(height: 10),
          Text(l10n.matureGateTitle,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() => _matureDeclined = null);
              _scheduleMatureGate(key, force: true);
            },
            child: Text(l10n.matureGateContinue,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final matureKey = _matureGateKey;
    if (matureKey != null && _matureCleared != matureKey) {
      if (_matureDeclined != matureKey) _scheduleMatureGate(matureKey);
      return _matureGatePlaceholder(tokens, matureKey);
    }
    return Column(
      children: [
        // The deck repaints on the dock because it is the receiving half of
        // the hand-off: its fill crossfades to the banner and the Profile tab
        // morphs into the contact.
        AnimatedBuilder(
          animation: _dockAnim,
          builder: (context, _) => _tabDeck(tokens),
        ),
        // The slim fused edge doubles as the deck/body divider — no 1px
        // hairline is needed.
        _deckEdge(tokens),
        Expanded(
          child: Stack(
            children: [
              // The page background (client browser.dart `build`, Layer 0):
              // profile tab only, cover-fit, the same 30% black scrim, fading
              // rather than popping when you move between the profile and
              // another tab. DELTA — it follows the reader-width cap like
              // `_body`, not the whole body: cover-fit over a wide window
              // blows a normal image up to the window's width, so it comes
              // out pixelated and cropped hard.
              if (_profileBackgroundUrl case final url?)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _current.kind == _TabKind.profile ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: AnimatedBuilder(
                        animation: _capAnim,
                        builder: (context, child) => Center(
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: _animatedCap),
                            child: child,
                          ),
                        ),
                        // One scale with the banner (ProfileArtLayout):
                        // the background starts where the banner starts,
                        // so the seam lines up.
                        child: SizedBox.expand(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              // A new height moves the shared scale: the
                              // banner (laid out by width only) rebuilds
                              // on the next frame to follow.
                              if (c.maxHeight != _artViewHeight) {
                                _artViewHeight = c.maxHeight;
                                WidgetsBinding.instance.addPostFrameCallback(
                                    (_) => _artSizeReady());
                              }
                              if (_bgAsBannerUrl == null) {
                                return _buildPageBackground(url, c.maxWidth);
                              }
                              // Standing in for the banner: rides the header.
                              return AnimatedBuilder(
                                animation:
                                    Listenable.merge([_headerAnim, _dockAnim]),
                                builder: (context, _) => _buildPageBackground(
                                    url, c.maxWidth,
                                    slide: true),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(child: _body(tokens)),
            ],
          ),
        ),
      ],
    );
  }

  /// Height of the body under the deck (the background's view), recorded by
  /// the background layer's layout so the banner can share its geometry.
  double _artViewHeight = 0;

  /// The plain banner URL the shared art geometry is built from; null for an
  /// NFT banner (its art keeps its own cover fit) or no banner.
  String? get _plainBannerUrl {
    if (widget.contact.bannerIsBackground) return null;
    final url = widget.contact.bannerUrl;
    return widget.contact.nftBanner == null && url.isNotEmpty ? url : null;
  }

  /// No banner of any kind but a page background: the background stands in
  /// for the banner. Desktop slides it up with the header
  /// ([_bgSlide]): on the profile tab the whole page background rides along,
  /// so header and page stay one picture; elsewhere only the header shows it.
  /// Core's [Contact.bannerIsBackground] decides: removed (empty
  /// record) and never set (no record, where `bannerUrl` answers the default
  /// banner) both fall back.
  String? get _bgAsBannerUrl => widget.contact.bannerIsBackground
      ? widget.contact.backgroundUrl
      : null;

  /// How far the header's collapse (and the dock) has lifted the banner box:
  /// 0 expanded, negative as it closes. Read inside a builder on
  /// `_headerAnim` + `_dockAnim`.
  double get _bgSlide =>
      (_headerHeightAt(_headerAnim.value) - _collapsedHeaderHeight * _headerDock)
          .clamp(0.0, _expandedBannerHeight) -
      _expandedBannerHeight;

  void _artSizeReady() {
    if (mounted) setState(() {});
  }

  /// Banner + background geometry, one rule on every host
  /// ([ProfileArtLayout]), measured against the EXPANDED header
  /// so the seam lines up at rest and the collapse only trims the banner.
  ProfileArtLayout? _artLayout(double viewWidth) => ProfileArtLayout.compute(
        background:
            ProfileArtLayout.sizeOf(_profileBackgroundUrl, _artSizeReady),
        banner: ProfileArtLayout.sizeOf(_plainBannerUrl, _artSizeReady),
        viewWidth: viewWidth,
        viewHeight: _artViewHeight,
        boxHeight: _expandedBannerHeight,
      );

  /// The page background in the capped column, under the 30% scrim. Held
  /// back until both sizes are known so it never lands, then jumps.
  /// [slide]: standing in for the banner, the picture rides the header up
  /// ([_bgSlide]) but never so far that its bottom leaves the bottom of the
  /// view. The offset moves the image INSIDE the clip, so it never paints
  /// over the deck and the header's copy stays in its strip.
  Widget _buildPageBackground(String url, double viewWidth,
      {bool slide = false}) {
    final layout = _artLayout(viewWidth);
    final bgHeight = layout?.backgroundHeight;
    if (layout == null ||
        bgHeight == null ||
        (_plainBannerUrl != null && layout.bannerAspect == null)) {
      return const SizedBox.shrink();
    }
    final double floor = _artViewHeight - (layout.top + bgHeight);
    final double dy = slide
        ? (_bgSlide < floor ? floor : _bgSlide).clamp(double.negativeInfinity, 0.0)
        : 0.0;
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            left: layout.leftIn(viewWidth),
            top: layout.top + dy,
            width: layout.width,
            height: bgHeight,
            // The publicos org's profile runs the publicos.dev constellation
            // live in the still's place (an Easter egg). Same box, so
            // the banner seam and the header copy line up exactly.
            child: _showsLiveConstellation
                ? const ConstellationCanvas()
                : Image(
                    image: ZeroCachedImageProvider(url),
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
          ),
          Positioned.fill(
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  /// The live constellation stands in for the background image: only on the
  /// publicos org, only on its profile tab (other tabs show the still banner).
  bool get _showsLiveConstellation =>
      _current.kind == _TabKind.profile &&
      ConstellationCanvas.isFor(
          displayName: widget.contact.displayName,
          isOrg: widget.contact.isOrgAccount);

  /// The live `_osux_profile_background_url_` value, or null when unset.
  String? get _profileBackgroundUrl {
    for (final rec in widget.contact.records) {
      if (rec.key == _kProfileBackgroundKey &&
          !rec.isExpired &&
          rec.value.trim().isNotEmpty) {
        return rec.value.trim();
      }
    }
    return null;
  }

  // ── The chrome-tab deck ────────────────────────────────────────────────────
  //
  // Browser-style tabs on a raised deck; the active tab sits in a slab
  // painted in the CONTENT tone (`background`) that fuses with the deck edge
  // below — also `background` — via its outward base curves. The slab slides
  // between tabs; the widgets live in `widgets/browser/tab_deck.dart`, this
  // method only assembles them.
  // The strip is the chrome and the selected tab is a hole cut through it
  // onto the black stage, so tab and body are literally one surface (a
  // lighter tab on a darker strip reads as a floating chip).
  // The strip carries the BROWSED CONTACT'S COLOUR — the same `color`
  // record, at the same full opacity, that paints their chat
  // bubbles (`messages/message_widget.dart` `_brandColor`). The frame around
  // someone's tabs and the bubbles inside their chat are one identity
  // signal, and because ShellPanel clips at radius 16 the frame fills the
  // content panel's top corners. Consequence — the fill is an arbitrary
  // user-chosen swatch, so EVERY chrome foreground on the frame derives from
  // it via `DeckPalette` instead of holding a fixed token; only the active
  // tab, being a hole onto `background`, keeps the dark-surface tokens.
  // The active tab grows its embedded URL inline to the right of its label
  // (no grow/hide band motion),
  // and the deck's top-right is the button cluster. On a LAUNCHER tab the
  // ↗ glyph after the label is the visual contract that clicking fires the
  // OS browser instead of changing the content area; a launcher never
  // becomes the active tab.

  /// Selects [tab], or fires it outward when it is a launcher: anything
  /// renderable renders in place, like it does on mobile.
  ///
  /// What fires outward: an app whose only pointers are store or
  /// download links. There is no page to show for an `appstore_link`.
  void _selectTab(_PanelTab tab) {
    // The loaded inbox is shown but inert: clicking it does nothing. You
    // cannot converse with yourself.
    if (tab.isLoadedInbox) return;
    // Clicking the tab you are already on while a pinned post covers it is
    // Back: close the post and restore the header, rather than re-landing.
    if (tab.key == _currentKey && _focusedPost != null) {
      _closePostInPlace();
      return;
    }
    if (_isLauncherTab(tab)) {
      if (tab.kind == _TabKind.web) {
        _launchExternal(tab.record?.tabUrl);
        return;
      }
      final links = _appLinksOf(context.l10n, tab.app!);
      // A visit is a visit — a store-only app fired outward counts in the
      // rail's last-visited history like a rendered one.
      _recordAppOpen(tab.app!);
      if (links.length == 1) {
        _launchExternal(links.first.url);
      } else if (links.length > 1) {
        _showAppLinksDialog(tab.app!, links);
      }
      return;
    }
    // Decided BEFORE `_currentKey` moves, because it is a comparison between
    // the outgoing tab's cap and the incoming one's.
    //
    // Only one direction needs the snap. Leaving a capped tab for an uncapped
    // one re-measures a VISIBLE header, so it skips its exit. The way back is
    // already safe and must animate normally: the header is at dock 1 when a
    // web tab is up — zero height, zero opacity — so the cap snapping back
    // to the reader width is invisible, and the header then grows in already
    // at the right width. Hence the expanded-family test rather than a bare
    // `capChanged`: it clears the flag on exactly that return trip.
    final capChanged = _capOf(tab) != _capOf(_current);
    // The width the frame is CURRENTLY drawn at, not the outgoing tab's
    // resting cap — a fast second switch must continue from where the running
    // tween actually is, or the body snaps back before moving again.
    final capBefore = _animatedCap;
    _headerSnapped = capChanged && !_isExpandedHeaderTabFor(tab);
    setState(() {
      _focusedPost = null;
      _currentKey = tab.key;
      // Edit mode is a mode of the PROFILE tab only. Leaving it drops the mode
      // (client browser.dart:1479) — coming back to a still-editing profile
      // after a detour through a chat is not something anyone expects.
      if (tab.kind != _TabKind.profile) _isEditMode = false;
      if (tab.kind != _TabKind.chat) {
        if (_chatSettingsOpener != null) {
          debugPrint('[browser] leaving chat for ${tab.kind} — '
              'clearing chat settings opener');
        }
        _chatSettingsOpener = null;
      }
    });
    // Header animates toward the new tab's resting state
    // (client `_selectTab` → `_updateProfileAnimationState`).
    _updateHeaderAnimationState();
    // ...and the shared cap toward the new tab's group width. After the
    // setState, so `_capOf(_current)` reads the tab we just moved to.
    _updateCapAnimation(capBefore);
    _checkCurrentFeedInList();
    _checkCurrentAppBookmarkStatus();
    // "Last visited apps": the app tab became current (an open is a
    // selection in the browser, whichever door it came through).
    if (tab.kind == _TabKind.app && tab.app != null) _recordAppOpen(tab.app!);
  }

  /// Record the visit in Core's history and wake the rail (`RecentApps`).
  /// Fire-and-forget: history must never block a tab switch.
  void _recordAppOpen(AppBookmark app) {
    RecentApps.instance.recordOpen(app);
  }

  /// Client `_checkCurrentAppBookmarkStatus`, over the current tab's app.
  Future<void> _checkCurrentAppBookmarkStatus() async {
    final app = _current.kind == _TabKind.app ? _current.app : null;
    if (app == null) {
      if (_currentAppBookmarked && mounted) {
        setState(() => _currentAppBookmarked = false);
      }
      return;
    }
    final isBookmarked = await PublicOSAppRegistry.isAppBookmarked(
      app.appName,
      app.ownerAccountAddress,
    );
    if (mounted) setState(() => _currentAppBookmarked = isBookmarked);
  }

  /// Client `_toggleBookmarkCurrentApp`, verbatim logic + strings; the deck's
  /// bookmark button on an app tab. This is the ONLY bookmark-writing surface
  /// a normal desktop user has — it is what makes the Apps dialog's
  /// Bookmarked chip reachable.
  Future<void> _toggleBookmarkCurrentApp() async {
    final app = _current.kind == _TabKind.app ? _current.app : null;
    if (app == null) return;

    if (_currentAppBookmarked) {
      final success = await PublicOSAppRegistry.removeBookmark(
        app.appName,
        app.ownerAccountAddress,
      );
      if (mounted) {
        final l10n = context.l10n;
        if (success) {
          setState(() => _currentAppBookmarked = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.browserRemovedApp(app.displayName))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.browserFailedRemoveBookmark)),
          );
        }
      }
    } else {
      final success = await PublicOSAppRegistry.bookmarkApp(app);
      if (mounted) {
        final l10n = context.l10n;
        if (success) {
          setState(() => _currentAppBookmarked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(l10n.browserBookmarkedApp(app.displayName))),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.browserFailedBookmarkApp)),
          );
        }
      }
    }
  }

  // ── Deck cluster actions (client browser's per-tab address-bar icons) ────

  /// Client `_checkCurrentRssFeedInList`, verbatim rule: a plain membership
  /// scan across every list — no list outranks another.
  Future<void> _checkCurrentFeedInList() async {
    final t = _current;
    final url = t.kind == _TabKind.feeds ? (t.record?.value ?? '') : '';
    if (url.isEmpty) {
      if (_currentFeedInList && mounted) {
        setState(() => _currentFeedInList = false);
      }
      return;
    }
    try {
      var inAny = false;
      for (final list in await PublicOSFeedLists.getUserLists()) {
        final feeds = await PublicOSFeedLists.getFeedsInList(list.id);
        if (feeds.any((f) => feedUrlKey(f.feedUrl) == feedUrlKey(url))) {
          inAny = true;
          break;
        }
      }
      if (mounted) setState(() => _currentFeedInList = inAny);
    } catch (_) {
      if (mounted) setState(() => _currentFeedInList = false);
    }
  }

  /// Client `_showAddToListBottomSheet`: the single Follow affordance for a
  /// channel — the add-to-lists sheet, anchored on the channel's record.key.
  Future<void> _followCurrentChannel() async {
    final t = _current;
    if (t.kind != _TabKind.feeds || t.record == null) return;
    final result = await showAddToListsSheet(
      context,
      feedUrl: t.record!.value,
      feedTitle: t.label,
      feedDescription: null,
      feedFoundAtAccountAddress: widget.contact.publicosAddress?.eip55With0x,
      feedRecordKey: t.record!.key,
    );
    if (result == true) _checkCurrentFeedInList();
  }

  /// Client `_copyProfileLink`, verbatim.
  void _copyProfileLink() {
    final address = widget.contact.publicosAddress?.eip55With0x;
    if (address == null) return;
    Clipboard.setData(
        ClipboardData(text: 'https://publicos.dev/publicosAddress/$address'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.browserProfileLinkCopied)),
      );
    }
  }

  /// Deck-cluster reload: the host's hard chain-pull ([Browser.onRefresh]),
  /// the same one ProfilePane's pull-to-refresh calls. Re-entrancy guarded so
  /// a double-click can't stack two `fetchContact`s — the host's generation
  /// counter would drop the loser anyway, but the second read is free to skip.
  Future<void> _reloadProfile() async {
    final refresh = widget.onRefresh;
    if (refresh == null || _reloading) return;
    _reloading = true;
    try {
      await refresh();
    } finally {
      _reloading = false;
    }
  }

  /// Client `_openProfileQR` — desktop pushes the same page as a route
  /// (select_account_screen does likewise for the account QR).
  void _openProfileQR() {
    final address = widget.contact.publicosAddress?.eip55With0x;
    if (address == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileQrPage(
          address: address,
          contact: widget.contact,
          displayName: widget.contact.displayName,
        ),
      ),
    );
  }

  /// One deck-cluster button — the chat gear's exact chrome, shared.
  Widget _deckButton(
    DeckPalette pal,
    double dock, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      // Docked, these glyphs sit on arbitrary photography instead of a flat
      // swatch, and `DeckPalette`'s luminance derivation has nothing
      // meaningful left to derive from. The pill carries their contrast now.
      child: GlassPill(
        dock: dock,
        radius: BorderRadius.circular(8),
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          iconSize: 16,
          // Cluster glyphs sit ON the contact-coloured frame, so they follow
          // it — a fixed `textDim` would vanish on a pale swatch.
          icon: Icon(icon, color: color ?? GlassPill.fgAt(pal.fgDim, dock)),
          tooltip: tooltip,
        ),
      ),
    );
  }

  /// Whether the viewer follows this ACCOUNT — i.e. it sits in `FollowedAccounts`
  /// for at least ONE list. Deliberately NOT "any of its channels appears
  /// somewhere as a single": following a person and bookmarking one of their
  /// channels are different acts, and only the former lights this up.
  bool _isFollowingAccount = false;

  /// Is this account STARRED (client twin)? A starred contact is
  /// one the user gets chain notifications about.
  bool _isStarred = false;

  /// Offered on another account's profile; never on the user's own, never on
  /// the publicos org (always starred, no toggle).
  bool get _starShown =>
      widget.contact.publicosAddress != null &&
      !_isSelf &&
      !PublicOSContacts.isAlwaysStarred(widget.contact.publicosAddress!);

  /// Re-entry guard for the follow tap. No spinner — the sheet is the only
  /// writer and every write is local DB, so the icon just flips when it lands.
  bool _togglingAccountFollow = false;

  // -----------------------------------------------------------------------
  // ACCOUNT FOLLOW — lives here, not in ProfilePane, so the button can
  // sit in the deck cluster, like the client's address bar.
  // -----------------------------------------------------------------------

  /// Re-read whether the viewer follows this account. Cheap indexed lookup;
  /// called on init, on contact change, and after a follow/unfollow. Self and
  /// address-less profiles are never "followed".
  /// Re-read the star. Runs with the follow read, so it follows the same
  /// lifecycle (init, contact change).
  Future<void> _refreshStarState() async {
    final account = widget.contact.publicosAddress;
    var starred = false;
    if (account != null && !_isSelf) {
      try {
        starred = await PublicOSContacts.isStarred(account);
      } catch (_) {}
    }
    if (mounted && starred != _isStarred) setState(() => _isStarred = starred);
  }

  /// Star or un-star this account. A profile that is not a stored contact yet
  /// is saved by the same call.
  Future<void> _toggleStarCurrentAccount() async {
    if (!_starShown) return;
    final next = !_isStarred;
    setState(() => _isStarred = next); // the button answers at once
    try {
      final now = await PublicOSContacts.setStarred(widget.contact, next);
      if (mounted && now != _isStarred) setState(() => _isStarred = now);
    } catch (_) {
      if (mounted) setState(() => _isStarred = !next);
    }
  }

  Future<void> _refreshAccountFollowState() async {
    _refreshStarState();
    final addr = widget.contact.publicosAddress?.eip55With0x;
    final session = PublicOS.sessionBlockchainAddress;
    if (addr == null || session == null || _isSelf) {
      if (mounted && _isFollowingAccount) {
        setState(() => _isFollowingAccount = false);
      }
      return;
    }
    // `listId` omitted → "followed in ANY list".
    final following = await PublicOS.database
        .isFollowingAccount(session: session, account: addr);
    if (!mounted) return;
    setState(() => _isFollowingAccount = following);
  }

  /// ONE affordance, one destination: the add-to-list sheet. It opens in
  /// account mode, pre-checked with every list this account is already in, so
  /// the same surface both follows and manages membership. There is no separate
  /// follow-vs-manage path, and no magic list to toggle against.
  Future<void> _toggleFollowCurrentAccount() async {
    final account = widget.contact.publicosAddress;
    final session = PublicOS.sessionBlockchainAddress;
    if (account == null || session == null || _isSelf) return;
    if (_togglingAccountFollow) return;
    final accountEip55 = account.eip55With0x;

    _togglingAccountFollow = true;
    try {
      final changed = await showAddToListsSheet(
        context,
        accountAddress: accountEip55,
        feedTitle: widget.contact.publicosDisplayName ?? widget.contact.displayName,
      );

      // Dedupe only makes sense after an actual add. Sweep every list the
      // account now belongs to, so a channel isn't counted twice in any of
      // them.
      if (changed == true) {
        final listIds = await PublicOS.database
            .listsContainingAccount(session: session, account: accountEip55);
        for (final listId in listIds) {
          await _cleanupSingleFollowsForAccount(account, listId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.desktopFollowFailed(e))),
        );
      }
    }
    _togglingAccountFollow = false;
    if (!mounted) return;
    await _refreshAccountFollowState();
  }

  /// After an account is added to a list, drop that list's channel-singles that
  /// the account now covers — otherwise the same channel renders twice, once
  /// account-derived and once as its own row.
  ///
  /// Scoped to the list(s) the sheet just committed to, and matched on
  /// `record.key` rather than URL so a re-pointed channel still dedupes. Rows
  /// with no record key are RAW URLs — a hand-pasted feed that merely happens
  /// to live at the same address is not the account's channel, so it is left
  /// alone.
  Future<void> _cleanupSingleFollowsForAccount(
    EthereumAddress account,
    int listId,
  ) async {
    try {
      final keys = (await PublicOSFollows.resolveProfileChannels(account))
          .map((c) => c.key)
          .toSet();
      if (keys.isEmpty) return;

      final owner = account.eip55With0x;
      for (final f in await PublicOSFeedLists.getFeedsInList(listId)) {
        final key = f.feedRecordKey;
        if (key == null || key.isEmpty) continue; // raw URL — leave it alone
        if (f.feedFoundAtAccountAddress != owner) continue; // another owner's
        if (keys.contains(key)) {
          await PublicOSFeedLists.removeFeedFromList(listId, f.id);
        }
      }
    } catch (e) {
      debugPrint('reverse-cleanup failed for ${account.eip55With0x}: $e');
    }
  }

  /// Wraps one deck-cluster action so it animates in and out instead of
  /// appearing and vanishing between frames.
  ///
  /// Pass `null` for "this action does not apply right now" instead of leaving
  /// the entry out of the list. That is the whole trick: a child dropped from a
  /// `Row` is gone before it can animate, so the slot keeps the last one it was
  /// given and plays it out itself.
  ///
  /// It also makes the cluster's child COUNT constant, which matters more than
  /// it looks: these buttons carry no keys, so Flutter matches them positionally
  /// between builds. With `if`s in the list, adding one shifts every element
  /// after it onto a different state object.
  Widget _deckSlot({required bool visible, required Widget Function() build}) {
    return DeckSlot(child: visible ? build() : null);
  }

  void _launchExternal(String? url) {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) launchUrl(uri);
  }

  /// The multi-link picker: one row per launchable link, each opening in the
  /// OS browser (there's nowhere else for them to go on desktop).
  void _showAppLinksDialog(AppBookmark app, List<_AppLink> links) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _AppLinksDialog(app: app, links: links),
    );
  }

  /// The browsed contact's swatch, read exactly as the chat bubble reads it
  /// (`message_widget._brandColor`): the `color` record is a stringified ARGB
  /// int, and an absent/unparseable one falls back to the same indigo the
  /// peer bubble uses — so a contact with no swatch frames identically to the
  /// way their messages already paint.
  DeckPalette get _deckPalette {
    final raw = widget.contact.getRecordValue('color');
    final argb = int.tryParse(raw ?? '');
    return DeckPalette(
        argb == null ? Colors.indigo.shade700 : Color(argb));
  }

  Widget _tabDeck(GlassTokens tokens) {
    // Everything except Settings scrolls in the deck (web tabs included —
    // they're real tabs); Settings pins into the top-right button
    // cluster so it never scrolls away on tab-heavy contacts. The cluster is
    // the home for panel-level buttons: the conversation-settings gear while
    // a chat tab is up, Settings, and whatever comes next.
    final deckTabs =
        _tabs.where((t) => t.kind != _TabKind.settings).toList();
    final settingsTabs =
        _tabs.where((t) => t.kind == _TabKind.settings).toList();
    // The deck's right corner holds ONE gear, and which settings it means is
    // decided by the tab you are on: the profile's gear is the CONTACT
    // settings, a chat's gear is that conversation's settings. A gear pinned
    // there permanently would still mean "contact settings" on a chat tab,
    // with the conversation gear squeezed in beside it wearing the identical
    // `settings_outlined` glyph.
    //
    // `|| onSettings` keeps it rendered while it is the ACTIVE tab; without it
    // the tab would erase itself the moment you opened it.
    final onSettings = _current.kind == _TabKind.settings;
    final showContactSettingsTab =
        settingsTabs.isNotEmpty && (_current.kind == _TabKind.profile || onSettings);
    final gear =
        _current.kind == _TabKind.chat && _chatSettingsOpener != null;
    // Gate for the profile action group. The slots are always present, so
    // the gate is applied inside each one.
    final onProfile = _current.kind == _TabKind.profile &&
        _focusedPost == null &&
        widget.contact.publicosAddress != null;
    final pal = _deckPalette;
    final dock = _dockAnim.value.clamp(0.0, 1.0);

    return Stack(
      children: [
        // The swatch, and the banner poured over it. Both sit OUTSIDE the
        // padding so the art runs edge to edge behind the tabs. It crossfades
        // over the swatch rather than replacing it,
        // which is why the hand-off reads as one identity settling instead of
        // two unrelated fills swapping -- `_deckPalette` and this art come off
        // the same contact.
        Positioned.fill(child: ColoredBox(color: pal.fill)),
        if (dock > 0.001)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: dock,
                child: _deckBannerArt(tokens),
              ),
            ),
          ),
        // The selection slab sits between the frame and the tabs, and owns
        // the scroller's controller + every tab's key so it can find the one
        // it rests on. `sel` is its handle for the row below.
        DeckSelection(
          activeId: _current.key,
          memory: widget.deckMemory,
          fill: tokens.background,
          builder: (context, sel) => Padding(
          padding: const EdgeInsets.only(top: 10, left: 4, right: 14),
          // Stated, not inferred. Letting the Row's tallest child set the
          // height would make the deck's size depend on which tabs happen to
          // be realized in the horizontal scroller.
          child: SizedBox(
            height: kDeckTabHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
              Expanded(
                child: DeckScroller(
                  palette: pal,
                  dock: dock,
                  selection: sel,
                  entries: [
                    for (final t in deckTabs)
                      DeckEntry(
                        id: t.key,
                        icon: t.icon,
                        label: t.label,
                        // The glyph tracks what the TAP DOES, not the tab kind:
                        // a web tab that renders in place must not wear an "opens
                        // outside" mark.
                        launcher: _isLauncherTab(t),
                        onPick: () => _selectTab(t),
                        // Dimmed and inert: the inbox this device has loaded.
                        child: Opacity(
                          opacity: t.isLoadedInbox ? 0.4 : 1.0,
                          child: ChromeTab(
                          label: t.label,
                          url: _urlOf(t),
                          leading: _tabLeading(t, tokens, pal, dock,
                              activeness: sel.activeness(t.key)),
                          tooltip: _tooltipFor(t),
                          active: t.key == _current.key,
                          activeness: sel.activeness(t.key),
                          palette: pal,
                          launcher: _isLauncherTab(t),
                          dock: dock,
                          // Only the Profile tab morphs: docked, it stops saying
                          // "Profile" and starts saying who this is.
                          dockedTitle: t.kind == _TabKind.profile
                              ? widget.contact.displayName
                              : null,
                          dockedSubtitle:
                              t.kind == _TabKind.profile ? _shortAddress : null,
                          onTap: () => _selectTab(t),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Per-tab actions (client address-bar icons → deck cluster).
              // Profile: the profile action group below. Channel:
              // Follow/add-to-lists. Chat: gear. Web/app: the web key
              // indicator.
              //
              // The indicator is the client's address-bar chip in the slot the
              // cluster gives it (`components/browser/web_key_indicator.dart`,
              // ported). Mounted on the webview-bearing kinds only,
              // the same guard the client's `_displayedTab` check makes — and
              // a non-renderable app tab can never BE `_current` (it fires the
              // OS browser instead), so reaching here means a webview really
              // is up. It renders nothing until `_webConnected`, so an
              // unconnected page shows no chip at all: it is the visible
              // consequence of a grant, not a launcher for one.
              //
              // Deliberately AFTER the back chevron — see its note.
              // Webview back chevron — the client's, imported.
              // Shown on the webview-bearing kinds only while the embedded page
              // has in-page history.
              //
              // It sits to the LEFT of the key glyph, and that order is
              // load-bearing, not a preference: this cluster is pinned to the
              // right of an `Expanded` scroller, so adding or removing an item
              // shifts everything to its LEFT and nothing to its right. The
              // chevron comes and goes with `_webViewCanGoBack` — every first
              // in-page navigation — so with the key glyph before it the key
              // would jump sideways on a page the user had not touched.
              _deckSlot(
                visible: _webViewCanGoBack &&
                    (_current.kind == _TabKind.web ||
                        _current.kind == _TabKind.app),
                build: () => _deckButton(pal, dock,
                    icon: Icons.chevron_left_rounded,
                    tooltip: context.l10n.registerAppBottomSheetBack,
                    onPressed: () => _webViewGoBack?.call(),
                  ),
                ),
                _deckSlot(
                  visible:
                      _current.kind == _TabKind.web ||
                      _current.kind == _TabKind.app,
                  build: () => Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: GlassPill(
                      dock: dock,
                      radius: BorderRadius.circular(8),
                      child: WebKeyIndicator(
                        connected: _webConnected,
                        activeAddress: _webActiveAccount,
                        // Same revision the webview watches: it also tells the
                        // chip to re-count this site's visible keys.
                        grantsRevision: _grantsRevision,
                        // Nothing up here may hold a fixed token — the
                        // frame is an arbitrary user swatch, and docked it is
                        // their photograph.
                        accent: GlassPill.fgAt(pal.fg, dock),
                        foreground: GlassPill.fgAt(pal.fgDim, dock),
                        origin: Uri.tryParse(_renderableUrl(_current) ?? ''),
                        // The picker changed this site's permission. Bump the
                        // revision so the webview re-reads the set and tells the
                        // running page.
                        onGrantsChanged: () =>
                            setState(() => _grantsRevision++),
                        chainId: _webChainId,
                        onChainSelected: _switchWebChain,
                      ),
                    ),
                  ),
                ),
              // Profile actions. `onProfile` is factored out because every one
              // of these is gated on it as well as on its own condition — a
              // slot is always present, so the gate cannot be an outer `if`;
              // it goes inside each `visible`.
              _deckSlot(
                // Reload the profile from chain. Desktop-only affordance: the
                // client reaches the same host sync through ProfilePane's
                // pull-to-refresh, which is a touch idiom — with a mouse there
                // is no way to ask for a fresh read at all. Same callback, so
                // the host's PhigitalLoadingWidget is the progress indicator
                // for both paths (contacts_pane / messages_pane `_syncing`).
                visible: onProfile && widget.onRefresh != null,
                build: () => _deckButton(pal, dock,
                    icon: Icons.refresh_rounded,
                    tooltip: context.l10n.desktopReloadProfile,
                    onPressed: _reloadProfile,
                  ),
                ),
                _deckSlot(
                  visible: onProfile,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: Icons.qr_code_2_rounded,
                    tooltip: context.l10n.desktopProfileQr,
                    onPressed: _openProfileQR,
                  ),
                ),
                _deckSlot(
                  visible: onProfile,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: Icons.share_outlined,
                    tooltip: context.l10n.desktopCopyProfileLink,
                    onPressed: _copyProfileLink,
                  ),
                ),
                _deckSlot(
                  // Star, left of the follow button: fills
                  // yellow with a bounce and a few confetti when turned on.
                  // Edit stays inline here: the deck has the width, and no
                  // "…" menu to move it into (that is a phone rule).
                  visible: onProfile && _starShown,
                  build: () => Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Tooltip(
                      message: context.l10n.browserStarTooltip,
                      child: StarButton(
                        starred: _isStarred,
                        onTap: _toggleStarCurrentAccount,
                        idleColor: GlassPill.fgAt(pal.fgDim, dock),
                        pill: (glyph) => GlassPill(
                          dock: dock,
                          radius: BorderRadius.circular(8),
                          child: glyph,
                        ),
                      ),
                    ),
                  ),
                ),
                _deckSlot(
                  // Follow the ACCOUNT — moved here from the profile body
                  // Only a real on-chain account that isn't you:
                  // XMTP-only contacts have no address to follow.
                  visible: onProfile &&
                      widget.contact.publicosAddress != null &&
                      !_isSelf,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: _isFollowingAccount
                        ? Icons.how_to_reg_rounded
                        : Icons.person_add_alt_1_rounded,
                    tooltip: _isFollowingAccount
                        ? context.l10n.desktopFollowTooltipManageLists
                        : context.l10n.desktopFollowTooltipFollow,
                    onPressed: _toggleFollowCurrentAccount,
                  ),
                ),
                _deckSlot(
                  visible: onProfile && _canEditProfile && _isEditMode,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: Icons.tab_rounded,
                    tooltip: context.l10n.browserManageTabs,
                    onPressed: _openManageProfileTabs,
                  ),
                ),
                _deckSlot(
                  visible: onProfile && _canEditProfile && _isEditMode,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: Icons.wallpaper_rounded,
                    tooltip: context.l10n.desktopPageBackground,
                    onPressed: _showEditProfileBackgroundSheet,
                  ),
                ),
                _deckSlot(
                  // Edit toggle. The client carries this in its address-bar
                  // action row; the deck cluster is the desktop equivalent.
                  // Order matches the client: Reload · QR ·
                  // Share · Follow · Manage tabs · Background · Edit, so Edit
                  // is always the rightmost profile action and Background sits
                  // just left of it.
                  visible: onProfile && _canEditProfile,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: _isEditMode
                        ? Icons.edit_off_rounded
                        : Icons.edit_rounded,
                    color: _isEditMode
                        ? Theme.of(context).colorScheme.error
                        : null,
                    tooltip: _isEditMode
                        ? context.l10n.desktopDoneEditing
                        : context.l10n.desktopEditProfile,
                    onPressed: () => setState(() => _isEditMode = !_isEditMode),
                  ),
                ),
                _deckSlot(
                  // Flag — someone else's profile (people and orgs), right of
                  // edit, left of the tabs chevron. Opens
                  // the shared flag sheet. The client's address-bar twin.
                  visible: onProfile &&
                      widget.contact.publicosAddress != null &&
                      !_isSelf,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: Icons.flag_outlined,
                    tooltip: context.l10n.flagAction,
                    onPressed: () => showFlagSheet(
                      context,
                      owner: widget.contact.publicosAddress!,
                      kind: FlagTargetKind.profile,
                    ),
                  ),
                ),
                _deckSlot(
                  // Channel sign-in key — the client browser's address-bar
                  // icon. Only once the channel has signalled sign-in;
                  // glyph = the rule's answer.
                  visible: _current.kind == _TabKind.feeds && _signinPref != null,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: _signinEffective
                        ? Icons.vpn_key_rounded
                        : Icons.vpn_key_off_rounded,
                    color: _signinEffective ? pal.fg : null,
                    tooltip: context.l10n.channelSigninMenuTitle,
                    onPressed: _showSigninMenu,
                  ),
                ),
                _deckSlot(
                  visible:
                      _current.kind == _TabKind.feeds &&
                      _current.record != null,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: _currentFeedInList
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_outlined,
                    color: _currentFeedInList ? pal.fg : null,
                    tooltip: _currentFeedInList
                        ? context.l10n.desktopFollowedManageLists
                        : context.l10n.desktopFollowAddToList,
                    onPressed: _followCurrentChannel,
                  ),
                ),
                _deckSlot(
                  // The client browser's bookmark button (address-bar action
                  // row, app tabs only) — its desktop twin.
                  visible:
                      _current.kind == _TabKind.app && _current.app != null,
                  build: () => _deckButton(
                    pal,
                    dock,
                    icon: _currentAppBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_add_outlined,
                    color: _currentAppBookmarked ? pal.fg : null,
                    tooltip: _currentAppBookmarked
                        ? context.l10n.desktopBookmarkedRemove
                        : context.l10n.desktopBookmarkThisApp,
                    onPressed: _toggleBookmarkCurrentApp,
                  ),
                ),
                // NOT a DeckSlot, deliberately: wrapped in a slot this button
                // has failed to appear, so it stays a plain conditional child
                // until the slot animation is ruled out as the cause.
                if (gear)
                  _deckButton(
                    pal,
                    dock,
                    icon: Icons.settings_outlined,
                    tooltip: context.l10n.conversationSettingsSheetTitle,
                    onPressed: _chatSettingsOpener!,
                  ),
                if (showContactSettingsTab) ...[
                  Container(
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.only(
                      left: 5,
                      right: 5,
                      bottom: 10,
                    ),
                    // The divider reads off the swatch, which the banner is now
                    // covering -- fade it out rather than leave a hairline sitting
                    // at the wrong contrast on someone's photo.
                    color: pal.divider.withValues(
                      alpha: pal.divider.a * (1 - dock),
                    ),
                  ),
                  // Pinned outside the scroller, so it is keyed here: the
                  // slab slides out of the deck to rest on it.
                  KeyedSubtree(
                    key: sel.keyOf(settingsTabs.first.key),
                    child: ChromeTab(
                      leading: _tabLeading(
                        settingsTabs.first,
                        tokens,
                        pal,
                        dock,
                        activeness: sel.activeness(settingsTabs.first.key),
                      ),
                      tooltip: settingsTabs.first.label,
                      active: settingsTabs.first.key == _current.key,
                      activeness: sel.activeness(settingsTabs.first.key),
                      palette: pal,
                      dock: dock,
                      onTap: () => _selectTab(settingsTabs.first),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  /// The contact's address, short form, for the docked Profile tab's second
  /// line. Null for a contact with no chain account (a plain XMTP stub), in
  /// which case the tab shows the display name alone.
  String? get _shortAddress {
    final addr = widget.contact.publicosAddress?.eip55With0x;
    if (addr == null || addr.length < 12) return null;
    return '${addr.substring(0, 6)}\u2026${addr.substring(addr.length - 4)}';
  }

  /// The banner art as the DECK wears it: no expansion opacity, no tap, no
  /// hero -- just the image, cropped hard into a ~46px band. A contact with
  /// no banner yields the bare swatch, which is a defined outcome and not a
  /// fallback: the tab morph still plays, and the frame simply stays the
  /// colour it already was.
  Widget _deckBannerArt(GlassTokens tokens) {
    final contact = widget.contact;
    if (contact.nftBanner != null) return NftBanner(contact: contact);
    final bannerUrl = contact.bannerUrl;
    if (_bgAsBannerUrl != null || bannerUrl.isEmpty) {
      // No banner but a background: the deck wears the background's top,
      // under the page's 30% scrim.
      final bg = _bgAsBannerUrl;
      if (bg == null) return const SizedBox.shrink();
      return Stack(
        fit: StackFit.expand,
        children: [
          ZeroCachedImage(
            imageUrl: bg,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
        ],
      );
    }
    return ZeroCachedImage(
      imageUrl: bannerUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  /// Each tab's leading art, per kind. Every kind that HAS a real art source
  /// draws it: feeds via [FeedFavicon], web + app via [TabArt], and — docked
  /// — profile via the contact's own [GlassContactIcon]. The rest keep their
  /// glyph, chat deliberately so (the label already names the conversation,
  /// and a monogram square reads as noise).
  /// [pal] is the contact-coloured frame the INACTIVE tabs sit on; the active
  /// tab is a hole onto `background`, so its glyphs keep the dark-surface
  /// tokens (`starkWhite` / `connectedAccent`) and never follow the frame.
  /// [dock] carries the hand-off: it swaps the Profile tab's glyph for the
  /// contact's actual avatar, and shifts every other inactive glyph off the
  /// swatch-derived tone onto the pill's (the swatch is behind a photo now).
  Widget _tabLeading(
      _PanelTab t, GlassTokens tokens, DeckPalette pal, double dock,
      {required double activeness}) {
    // The glyph walks from the frame tone to the active one as the slab
    // arrives (and back as it leaves), in step with the label.
    final dim = GlassPill.fgAt(pal.fgDim, dock);
    Color on(Color activeTone) => Color.lerp(dim, activeTone, activeness)!;
    switch (t.kind) {
      case _TabKind.profile:
        // The morph's leading half. Both glyphs are square and share the
        // lerped box, so the person outline grows into the avatar's footprint
        // as it dissolves -- no reflow mid-crossfade, and the tab's width
        // eases rather than stepping.
        final size = 15 + (kDeckDockedAvatarSize - 15) * dock;
        if (dock <= 0.001) {
          return Icon(t.icon,
              size: 15, color: on(tokens.connectedAccent));
        }
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (dock < 0.999)
                Opacity(
                  opacity: 1 - dock,
                  child: Icon(t.icon,
                      size: size,
                      color: on(tokens.connectedAccent)),
                ),
              Opacity(
                opacity: dock,
                child: GlassContactIcon(contact: widget.contact, size: size),
              ),
            ],
          ),
        );
      case _TabKind.chat:
        final chatGlyph = Icon(
          Icons.chat_bubble_outline_rounded,
          size: 15,
          color: on(tokens.starkWhite),
        );
        if (!t.isLoadedInbox) return chatGlyph;
        // The inbox this device has loaded: the keychain's "loaded key" sim in
        // the tab-type notch, as on the client's switcher row. Scaled to
        // 12 px for the 15 px glyph (the art badges are 14 on 20); the glyph
        // keeps its footprint, so the tab doesn't reflow when keys switch.
        return SizedBox(
          width: 15,
          height: 15,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              chatGlyph,
              Positioned(
                right: -5,
                bottom: -5,
                child: Transform.scale(
                  scale: 12 / TabTypeBadge.size,
                  alignment: Alignment.bottomRight,
                  child: const TabTypeBadge(icon: Icons.sim_card_rounded),
                ),
              ),
            ],
          ),
        );
      case _TabKind.feeds:
        // The REAL feed icon, the same [FeedFavicon] the Feeds pane draws —
        // metadata `imageUrl` (channel logo, RSS `<image>`, Atom `<logo>`) →
        // site favicon → RSS glyph, off the shared 1 h FeedMetadataUtils
        // cache. FeedFavicon holds a fixed footprint across
        // resolving/loading/error, so the tab never reflows mid-resolve.
        final feedUrl = t.record?.value;
        if (feedUrl == null || feedUrl.isEmpty) {
          return Icon(
            Icons.rss_feed_rounded,
            size: 15,
            color: on(tokens.connectedAccent),
          );
        }
        return _withTypeBadge(
          FeedFavicon(
            feedUrl: feedUrl,
            size: 20,
            // The fallback glyph rides the deck frame on inactive tabs, so it
            // follows the swatch like every other chrome foreground.
            fallbackColor: on(tokens.starkWhite),
          ),
          icon: Icons.rss_feed_rounded,
          hasArt: true,
        );
      case _TabKind.web:
        // The tab's own favicon, derived from the record URL exactly as
        // the client's TabIconWidget derives it for a webview tab.
        final webUrl = t.record?.tabUrl;
        final hasWebArt = webUrl != null && webUrl.isNotEmpty;
        return _withTypeBadge(
          TabArt(
            imageUrl: hasWebArt ? FaviconUtils.getFaviconUrl(webUrl) : null,
            fallback: Icons.language,
            fallbackColor: on(tokens.starkWhite),
            size: 20,
          ),
          icon: Icons.language_rounded,
          hasArt: hasWebArt,
        );
      case _TabKind.app:
        // The registry icon the app publishes. Same source the client
        // uses (`appBookmark.icon`) and the same source wallet_view already
        // renders app icons from on this side.
        final appIcon = t.app?.icon;
        return _withTypeBadge(
          TabArt(
            imageUrl: appIcon,
            fallback: Icons.apps_rounded,
            fallbackColor: on(tokens.starkWhite),
            size: 20,
          ),
          icon: Icons.apps_rounded,
          hasArt: appIcon != null && appIcon.isNotEmpty,
        );
      // profile · chat · management · settings keep their glyph: there is no
      // art source for them on either client (the client's TabIconWidget only
      // resolves channel + webview records, and its app branch reads the
      // bookmark), and chat DELIBERATELY carries no monogram.
      default:
        return Icon(
          t.icon,
          size: 15,
          color: on(tokens.connectedAccent),
        );
    }
  }

  /// The client's tab-type notch ([TabTypeBadge] — tab switcher sheet, Manage
  /// tabs sheet, address-bar avatar) on a deck tab's art, bottom-right. Web,
  /// app and feeds tabs: a favicon or app icon alone doesn't say which kind
  /// of tab it is; profile · chat · management · settings are
  /// self-describing. Shown only when the tab HAS an art URL,
  /// the client's rule — with no art the art widget already draws the type
  /// glyph. The badge is the client's 16 px component scaled to 14 px on
  /// 20 px art; the widget stays byte-identical to the client's. A fixed
  /// 20 px footprint, so the tab never reflows.
  Widget _withTypeBadge(Widget art,
      {required IconData icon, required bool hasArt}) {
    if (!hasArt) return art;
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          art,
          Positioned(
            right: -5,
            bottom: -5,
            child: Transform.scale(
              scale: 14 / TabTypeBadge.size,
              alignment: Alignment.bottomRight,
              child: TabTypeBadge(icon: icon),
            ),
          ),
        ],
      ),
    );
  }

  String _tooltipFor(_PanelTab t) {
    switch (t.kind) {
      case _TabKind.chat:
        return context.l10n.desktopTabTooltipChat(t.label);
      case _TabKind.feeds:
        return context.l10n.desktopTabTooltipChannel(t.label);
      case _TabKind.web:
      case _TabKind.app:
        final renderable = _renderableUrl(t);
        if (renderable != null) return '${t.label} — $renderable';
        // Nothing renderable: say so, rather than showing a URL that will open
        // somewhere else.
        if (t.kind == _TabKind.web) {
          return context.l10n.desktopTabTooltipOpensExternal(t.label);
        }
        final links = _appLinksOf(context.l10n, t.app!);
        return links.length == 1
            ? context.l10n.desktopTabTooltipOpensExternalUrl(
                t.label,
                links.first.url,
              )
            : context.l10n.desktopTabTooltipOpensExternalLinks(
                t.label,
                links.length,
              );
      default:
        return t.label;
    }
  }

  /// A tab's embedded URL, if it has one — shown inline in the ACTIVE tab.
  /// Channel tabs carry their feed URL in `record.value` (the exact field the
  /// feed body mounts). Web/app launcher tabs never activate, so they carry
  /// none — their URL lives in the tooltip.
  String? _urlOf(_PanelTab t) {
    // The active tab shows its URL for every kind that HAS one (feeds and
    // web tabs — a `RouterSubtype.tab` record's value is the page URL the
    // webview renders).
    final url = switch (t.kind) {
      _TabKind.feeds || _TabKind.web => t.record?.value,
      _ => null,
    };
    return (url == null || url.isEmpty) ? null : url;
  }

  /// The constant surface the active tab fuses into — a slim edge painted in
  /// the CONTENT tone (the URL lives inside the tab, so nothing here grows
  /// or hides; that tone is `background`, matching the body below it).
  Widget _deckEdge(GlassTokens tokens) =>
      Container(height: 4, color: tokens.background);

  Widget _body(GlassTokens tokens) {
    // The width cap (Contact settings → content width) applies to EVERY tab
    // body — banner included, so header and content share edges. Inside the
    // cap: the client browser's layout — content fills the
    // area (carrying its own top inset), the animated header overlays the
    // top; on expanded tabs the content's scroll drives the collapse.
    // DELTA — a webview ignores the reader width cap.
    // The cap exists so long-form text keeps a readable measure; a rendered
    // web page brings its own layout and its own responsive breakpoints, and
    // squeezing it into a text column makes a site think it is on a narrow
    // screen. Web tabs take the whole container.
    // DELTA — the cap is per tab GROUP and can therefore change
    // between two tabs that share the banner, so it is animated rather than
    // read once (`_animatedCap`). The Stack rides through as `child`: the
    // tween re-lays out the frame, it does not rebuild the body.
    return AnimatedBuilder(
      animation: _capAnim,
      builder: (context, child) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _animatedCap),
          child: child,
        ),
      ),
      child: PostFocusScope(
      open: _openPostInPlace,
      child: Stack(
        children: [
          // One offset covers every tab kind, because each one's total top
          // inset already ends at the strip: profile/management carry
          // `_expandedVisualHeight` and are scrolled by `dist`, feeds pads
          // 56 over a `dist` inset, and the collapsed family pads a flat
          // 56. Lifting the viewport by the relief lands all four with
          // their content flush under the deck at dock 1.
          //
          // `bottom: 0` is what makes this a lift and not a crop -- the
          // viewport grows by the same amount it moves, so its bottom edge
          // stays put and no content is pushed off the end.
          //
          // The body goes through AnimatedBuilder's `child` slot on
          // purpose: the offset is a layout change, and passing the subtree
          // through keeps `_tabBody` from rebuilding a whole ProfilePane on
          // every frame of the hand-off.
          AnimatedBuilder(
            animation: _dockAnim,
            child: _isExpandedHeaderTab
                ? ContentMetricsListener(
                    onMetrics: _syncHeaderToScroll,
                    child: _tabBody(tokens),
                  )
                // Collapsed-family tabs sit below the strip; during the
                // 300ms switch the header briefly animates over their top
                // edge (client behavior).
                : Padding(
                    padding: const EdgeInsets.only(top: _collapsedHeaderHeight),
                    child: _tabBody(tokens),
                  ),
            builder: (context, child) => Positioned(
              top: -_dockRelief,
              left: 0,
              right: 0,
              bottom: 0,
              child: child!,
            ),
          ),
          // A pinned post opened in place: above the profile (which keeps its
          // scroll), below the header, laid out like a collapsed-family tab.
          if (_focusedPost != null)
            AnimatedBuilder(
              animation: _dockAnim,
              child: ColoredBox(
                color: tokens.background,
                child: Padding(
                  padding: const EdgeInsets.only(top: _collapsedHeaderHeight),
                  child: KeyedSubtree(
                    // A new builder is a new post: remount, never reuse the
                    // last post's State.
                    key: ObjectKey(_focusedPost),
                    child: _focusedPost!(_closePostInPlace),
                  ),
                ),
              ),
              builder: (context, child) => Positioned(
                top: -_dockRelief,
                left: 0,
                right: 0,
                bottom: 0,
                child: child!,
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: Listenable.merge([_headerAnim, _dockAnim]),
              builder: (context, _) => _buildHeader(tokens),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _tabBody(GlassTokens tokens) {
    final tab = _current;
    switch (tab.kind) {
      case _TabKind.profile:
        // The client's browser↔ProfilePage split: the panel header owns
        // banner/avatar/name, the pane renders content starting topInset
        // below and its scroll drives the collapse.
        return ProfilePane(
          // Keyed on WHO, never on the Contact object. With
          // `contact.hashCode`, the chain sync hands over a fresh Contact for
          // the same account, the hash changes, the whole pane remounts and
          // every profile card replays its entrance, which the grid's own
          // keyed slot (profile_pane.dart) cannot survive. A
          // different contact already remounts the whole Browser (both
          // callers key it on the contact), and ProfilePane.didUpdateWidget
          // takes a refreshed copy in place.
          key: ValueKey('panel-profile:${_profileIdentity(widget.contact)}'),
          contact: widget.contact,
          onRefresh: widget.onRefresh,
          onOpenContact: widget.onOpenContact,
          externalHeader: true,
          topInset: _expandedVisualHeight,
          isEditMode: _isEditMode,
          isOrgMember: _isOrgMember,
          onUseNftAsAvatar: _isSelf ? null : _useNftAsAvatar,
        );

      case _TabKind.chat:
        // The browser's mount contract, re-derived (browser.dart:3812-3835):
        // the ValueKey remounts the screen on an XMTP key switch so a fresh
        // _initialize() re-resolves the (new key ↔ peer) DM topic; groups pass
        // inboxId null and ride the contact's topic. Chat is collapsed-family:
        // the _body branch pads it below the strip.
        //
        // No inbox loaded: the chat is not built at all (it
        // threw a red error resolving a topic against no inbox); a "load a
        // key" tile stands in. `xmtpKeyEpoch` rebuilds this branch when a key
        // is loaded or switched from the status bar, so the chat mounts (or
        // remounts on the new inbox) by itself.
        return ValueListenableBuilder<int>(
          valueListenable: xmtpKeyEpoch,
          builder: (context, _, __) => PublicOS.clientXmtpInboxId == null
              ? ChatNoKeyState(onLoadKeys: _loadKeysForChat)
              : SimpleChatScreen(
                  key: ValueKey(
                      'chat:${tab.inboxId}:${PublicOS.clientXmtpInboxId}'),
                  contact: widget.contact,
                  inboxId: _isGroup ? null : tab.inboxId,
                  topic: widget.topic,
                  onActiveKeyChanged: widget.onActiveKeyChanged,
                  onChatSettingsAvailable: _onChatSettingsAvailable,
                ),
        );

      case _TabKind.feeds:
        // The client's channel-tab body (browser.dart:3642-3653) verbatim in
        // structure: content padded by the COLLAPSED height, PostsList's
        // topInset carries the expanded remainder — channel tabs are
        // expanded-family, so the feed lands
        // with the banner expanded and its scroll collapses it.
        return Padding(
          padding: const EdgeInsets.only(top: _collapsedHeaderHeight),
          child: PostsList(
            key: ValueKey('panel-feed:${tab.record?.key}'),
            feeds: [
              FeedSource(
                url: tab.record?.value ?? '',
                title: tab.label,
                foundAtContact: widget.contact,
                recordKey: tab.record?.key,
              ),
            ],
            displayName: tab.label,
            color: ThemeProvider.tealPrimary,
            topInset: _expandedVisualHeight - _collapsedHeaderHeight,
            // The deck's key follows the row after every settled load, and
            // refetches when the menu changes the decision.
            refreshTick: _channelRefreshTick,
            onLoadingChanged: (loading) {
              if (!loading) _refreshSigninPref();
            },
          ),
        );

      case _TabKind.web:
      case _TabKind.app:
        final url = _renderableUrl(tab);
        // A tab with nothing renderable never becomes _current — it fires the
        // OS browser and the selection stays put. Unreachable, kept for the
        // exhaustive switch.
        if (url == null) return const SizedBox.shrink();
        return PublicOSWebView(
          // Keyed on the URL so switching between two web tabs rebuilds the
          // engine rather than re-pointing one, matching the client's
          // `ValueKey(urlToLoad)` on its own webview.
          key: ValueKey(url),
          initialUrl: url,
          // Re-read on every rebuild, which is what makes the indicator's
          // `onGrantsChanged` do something: the host's setState hands the
          // webview a new revision and its `didUpdateWidget` re-evaluates the
          // running page's grants.
          grantsRevision: _grantsRevision,
          // The connect event: true → the chip appears, false → it hides.
          onConnectionChanged: (connected) {
            if (connected != _webConnected) {
              setState(() => _webConnected = connected);
            }
          },
          onActiveAccountChanged: (address) {
            if (address != _webActiveAccount) {
              setState(() => _webActiveAccount = address);
            }
          },
          // In-page history, so the deck can offer a way back. Both are fired
          // during init, before the first frame this widget produces, so the
          // setState is guarded on a real change to avoid a build-phase
          // rebuild on a value that did not move.
          onControllerCreated: (goBack) => _webViewGoBack = goBack,
          onReloadCreated: (reload) => _webViewReload = reload,
          // This page's chain registry + its chain. Both belong to the
          // webview; we hold them so the deck badge can render and switch.
          onChainRegistryCreated: (registry) => _webChains = registry,
          onChainChanged: (chainId) {
            if (chainId != _webChainId) {
              setState(() => _webChainId = chainId);
            }
          },
          onCanGoBackChanged: (canGoBack) {
            if (canGoBack != _webViewCanGoBack) {
              setState(() => _webViewCanGoBack = canGoBack);
            }
          },
          onError: (e) => debugPrint('[browser] webview error: $e'),
        );

      case _TabKind.management:
        // Imported from publicos_client — the client mounts the
        // same widget from `pages/browser.dart:3608` (`_buildManagementWidget`)
        // with the same four arguments.
        //
        // Management is in the expanded-header family, so `topInset` is the
        // client's `_expandedVisualHeight` and not 0. `_body` does not pad
        // this tab -- the expanded branch mounts it under the overlay header
        // and lets its scroll drive the collapse, exactly as the client does.
        // Passing 0 would leave the first vote card under the banner.
        return GroupVotingView(
          contact: widget.contact,
          isOrgMember: _isOrgMember,
          topInset: _expandedVisualHeight,
          onContactRefresh: widget.onRefresh,
        );

      case _TabKind.settings:
        // The client's per-contact settings router (contact_settings_screen →
        // 4 pages by contact type), mounted as the tab body exactly like the
        // browser's settings tab.
        return ContactSettingsScreen(contact: widget.contact);
    }
  }

  // ── The animated header (client `_buildAddressBar` + `_buildBanner` +
  // `_buildAvatarAndName`, desktop-shaped: no status bar, no close button, no
  // marquee/mini-icon/edit-pencil mobile chrome — the tab strip above owns
  // navigation) ─────────────────────────────────────────────────────────────

  // ── Profile editing (client `browser.dart`) ──────────────────────────────
  //
  // The four surfaces the profile BODY cannot own, because they belong to the
  // header or to the tab strip: avatar, banner, page background, and the tab
  // list. Each forks the same way `ProfilePane`'s writes do — own profile is a
  // direct Core write, an org routes the same change through governance.

  /// True when the currently-viewed org has an open vote on chain. After an
  /// org write this is what separates a threshold-1 auto-execute (no vote) from
  /// a threshold-N proposal members still have to approve.
  Future<bool> _isOrgVoteOpen() async {
    if (!widget.contact.isOrgAccount || _isSelf) return false;
    final addr = widget.contact.publicosAddress;
    if (addr == null) return false;
    try {
      return await PublicOSGovernance.hasPendingVoteBy(
          addr.eip55With0x, PublicOS.myPublicosAddress);
    } catch (_) {
      return false;
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Avatar / banner picker. Hands the sheet the LIVE NFT state (ref + already
  /// resolved art + ownership verdict) so its landing previews what the profile
  /// actually renders — NFT wins — with no re-resolve flash.
  void _showEditImageSheet(String type, String? currentUrl) {
    if (!_canEditProfile) return;
    final contact = widget.contact;

    final nft = type == 'avatar'
        ? contact.nftAvatar
        : type == 'banner'
            ? contact.nftBanner
            : null;
    var nftVerdict = type == 'avatar'
        ? contact.verifiedNftAvatarData
        : type == 'banner'
            ? contact.verifiedNftBannerData
            : null;
    // A verdict cached for a DIFFERENT pointer is stale — seeding the preview
    // with the wrong art is worse than letting it resolve fresh.
    if (nft == null || (nftVerdict != null && !nftVerdict.matches(nft))) {
      nftVerdict = null;
    }

    showEditProfileImageSheet(
      context,
      type: type,
      currentImageUrl: currentUrl,
      currentNft: nft,
      currentNftImage: nftVerdict?.imageUrl,
      currentNftOwned: nftVerdict?.verifiedOwnership,
      onSave: (record) async {
        final l10n = context.l10n;
        bool saved = false;
        if (_isSelf) {
          saved = await PublicOSContacts.setRecord(record);
        } else if (contact.isOrgAccount &&
            _isOrgMember &&
            contact.publicosAddress != null) {
          saved = await PublicOSGovernance.startVoteSetRecord(
            contact.publicosAddress!,
            key: record.key,
            value: jsonEncode(record.toChainValue()),
            expiration: record.chainExpiration,
            recordType: BigInt.from(record.type.index),
            customType: record.subtype ?? '',
          );
        }

        if (saved) {
          final voteOpen = await _isOrgVoteOpen();
          // Full reload so a newly-opened vote shows.
          await widget.onRefresh?.call();
          _snack(voteOpen
              ? l10n.browserVoteStartedMembersApprove
              : l10n.browserProfileImageUpdated);
        } else if (contact.isOrgAccount && !_isSelf) {
          _snack(l10n.browserCouldNotStartVote);
        }
      },
    );
  }

  /// Set an NFT (from a card's info dialog) as the signed-in user's avatar.
  /// Always a self-write — you are setting YOUR avatar — so there is no
  /// governance path here. Returns success so the dialog can close itself.
  Future<bool> _useNftAsAvatar(NftAvatarRef ref) async {
    final l10n = context.l10n;
    final overlay =
        FullscreenOverlay.showTransaction(context, l10n.browserSavingToChain);
    try {
      final record = Record.asSettings(
        key: 'profile.avatar.nft',
        value: ref.encode(),
        isSystem: true,
      );
      final ok = await PublicOSContacts.setRecord(record);
      if (ok) {
        overlay.updateMessage(l10n.browserRefreshingProfile);
        await AppStateNotifier.loadMyContact();
        await widget.onRefresh?.call();
      }
      _snack(ok ? l10n.browserAvatarUpdated : l10n.browserCouldNotSetAvatar);
      return ok;
    } catch (_) {
      _snack(l10n.browserCouldNotSetAvatar);
      return false;
    } finally {
      overlay.dismiss();
    }
  }

  static const String _kProfileBackgroundKey = '_osux_profile_background_url_';

  void _showEditProfileBackgroundSheet() {
    if (!_canEditProfile || !_isEditMode) return;

    String? currentBackgroundImageUrl;
    for (final rec in widget.contact.records) {
      if (rec.key == _kProfileBackgroundKey &&
          !rec.isExpired &&
          rec.value.trim().isNotEmpty) {
        currentBackgroundImageUrl = rec.value;
        break;
      }
    }

    // The glass-dialog shell lives in the sheet's own opener (DELTA there).
    showEditProfileBackgroundSheet(
      context,
      currentUrl: currentBackgroundImageUrl,
      onSave: _saveProfileBackgroundImage,
    );
  }

  Future<void> _saveProfileBackgroundImage(String imageUrl) async {
    if (!_canEditProfile) return;
    final contact = widget.contact;
    final l10n = context.l10n;
    final isOrgWrite =
        contact.isOrgAccount && _isOrgMember && contact.publicosAddress != null;

    try {
      bool success = false;

      // An empty URL means "remove it" — deleting the record, never writing an
      // empty value.
      if (imageUrl.trim().isEmpty) {
        if (_isSelf) {
          success = await PublicOSContacts.deleteRecord(_kProfileBackgroundKey);
        } else if (isOrgWrite) {
          success = await PublicOSGovernance.startVoteDeleteRecord(
            contact.publicosAddress!,
            _kProfileBackgroundKey,
          );
        }
      } else {
        final backgroundRecord = Record.asProfile(
          key: _kProfileBackgroundKey,
          value: imageUrl,
          icon: Icons.hide_image_outlined.codePoint,
        );
        if (_isSelf) {
          success = await PublicOSContacts.setRecord(backgroundRecord);
        } else if (isOrgWrite) {
          success = await PublicOSGovernance.startVoteSetRecord(
            contact.publicosAddress!,
            key: backgroundRecord.key,
            value: jsonEncode(backgroundRecord.toChainValue()),
            expiration:
                backgroundRecord.chainExpiration,
            recordType: BigInt.from(backgroundRecord.type.index),
            customType: backgroundRecord.subtype ?? '',
          );
        }
      }

      if (success) {
        final voteOpen = await _isOrgVoteOpen();
        await widget.onRefresh?.call();
        _snack(voteOpen
            ? l10n.browserVoteStartedMembersApprove
            : imageUrl.trim().isEmpty
                ? l10n.browserProfileBackgroundRemoved
                : l10n.browserProfileBackgroundUpdated);
      } else {
        _snack(l10n.browserFailedUpdateBackground);
      }
    } catch (e) {
      if (mounted) _snack(localizedError(context.l10n, e));
    }
  }

  /// The tab list itself — add / rename / reorder / delete the router records
  /// this panel's own tab strip is built from. On save the contact reloads, so
  /// the strip rebuilds from chain.
  Future<void> _openManageProfileTabs() async {
    final result = await showManageProfileTabsSheet(
      context: context,
      contact: _isSelf ? null : widget.contact,
      isOrgMember: _isOrgMember,
    );
    if (result == true) await widget.onRefresh?.call();
  }

  Widget _buildHeader(GlassTokens tokens) {
    final progress = _headerAnim.value;
    // Phase 2 only ever multiplies opacities in here. Every height, offset
    // and size below is still phase 1's alone, which is what freezes the
    // strip in place while its contents leave for the deck.
    final dock = _headerDock;

    final relief = _collapsedHeaderHeight * dock;
    final baseH = (_headerHeightAt(progress) - relief).clamp(0.0, 1e9);
    final avatarSize = _avatarSizeAt(progress);
    final avatarY = _avatarYAt(progress);
    final avatarBottom = avatarY + avatarSize;
    // Client `adjustedHeaderHeight`: tall enough for the banner or the
    // straddling avatar, whichever hangs lower -- then the dock's relief
    // comes off that too, or the straddling avatar's 44px floor would hold
    // the band open at exactly the moment it is supposed to close.
    final rawH = _headerHeightAt(progress) > avatarBottom
        ? _headerHeightAt(progress)
        : avatarBottom + progress * 8;
    final adjustedH = (rawH - relief).clamp(0.0, 1e9);

    return SizedBox(
      height: adjustedH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: baseH,
            child: _buildBannerArt(tokens, progress, dock),
          ),
          // Collapse shade — fades IN as the header collapses (client: 0
          // expanded → 0.12 collapsed) so the avatar/name stay legible against
          // the banner slice. Never eats touches.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: baseH,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      // None over a background standing in for the banner on
                      // the profile tab: it would seam against the page.
                      Colors.black.withValues(
                          alpha: _current.kind == _TabKind.profile &&
                                  _bgAsBannerUrl != null
                              ? 0
                              : (1 - progress) * 0.12 * (1 - dock)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Edit pencils — banner and avatar, mirroring the client. Both fade
          // out over the last 10% of the collapse and leave the tree below
          // that, so a collapsing header can never have them catching clicks
          // meant for the deck or the content underneath.
          if (_current.kind == _TabKind.profile &&
              _isEditMode &&
              _canEditProfile &&
              progress > 0.9) ...[
            Positioned(
              right: _hPad,
              top: baseH - 36,
              child: Opacity(
                opacity: ((progress - 0.9) / 0.1).clamp(0.0, 1.0) * (1 - dock),
                child: _editPencil(
                  tokens,
                  context.l10n.desktopEditBanner,
                  () => _showEditImageSheet('banner', widget.contact.bannerUrl),
                ),
              ),
            ),
            Positioned(
              left: _hPad + avatarSize - 18,
              top: avatarBottom - 28,
              child: Opacity(
                opacity: ((progress - 0.9) / 0.1).clamp(0.0, 1.0) * (1 - dock),
                child: _editPencil(
                  tokens,
                  context.l10n.desktopEditAvatar,
                  () => _showEditImageSheet('avatar', widget.contact.avatarUrl),
                ),
              ),
            ),
          ],
          // Avatar + name: the other half of what migrates. IgnorePointer
          // tracks the fade so a fully docked (invisible) avatar can't keep
          // swallowing clicks over the emptied band -- its tap target is the
          // Profile tab now.
          Positioned(
            left: _hPad,
            top: avatarY,
            right: _hPad,
            child: IgnorePointer(
              ignoring: dock > 0.5,
              child: Opacity(
                opacity: (1 - dock).clamp(0.0, 1.0),
                child: _buildAvatarAndName(tokens, progress, avatarSize),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The header's edit affordance — the client's `_buildEditButton`, given a
  /// cursor and a tooltip because this one is reached with a mouse.
  Widget _editPencil(GlassTokens tokens, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              shape: BoxShape.circle,
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(Icons.edit_rounded, size: 16, color: tokens.starkWhite),
          ),
        ),
      ),
    );
  }

  /// Client `_buildBanner`: NFT banner art wins over the plain URL; empty →
  /// pane background (opaque, so scrolled content hides under the strip).
  /// Opacity rides the expansion (0.4 collapsed → 1.0 expanded), then rides
  /// [dock] back to 0 as the art migrates into the deck.
  ///
  /// The opaque `tokens.background` floor is what survives that fade, and it
  /// is the whole point of keeping the strip: at dock 1 this widget is a bare
  /// 56px band that the content still scrolls under, so nothing reflows and
  /// no row is ever clipped by the deck itself. Every branch needs that floor
  /// -- the NFT one too (it cannot rely on `NftBanner` being opaque, because
  /// the art can fade to nothing).
  ///
  /// Tappable only on the Profile tab, and only while there is art to tap.
  /// A plain banner placed by [_artLayout]: its bottom on the strip's
  /// bottom (the collapse trims it from the top), its width the shared art
  /// width. Until its size is known: cover, bottom-anchored.
  Widget _placeBanner(Widget Function(BoxFit, Alignment) image) {
    return LayoutBuilder(builder: (context, c) {
      final layout = _artLayout(c.maxWidth);
      if (layout == null || layout.bannerAspect == null) {
        return image(BoxFit.cover, Alignment.bottomCenter);
      }
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: layout.leftIn(c.maxWidth),
            bottom: 0,
            width: layout.width,
            height: layout.bannerHeight,
            child: image(BoxFit.fill, Alignment.center),
          ),
        ],
      );
    });
  }

  Widget _buildBannerArt(GlassTokens tokens, double progress, double dock) {
    final contact = widget.contact;
    final bannerUrl = contact.bannerUrl;
    final nftBanner = contact.nftBanner;
    final nftVerdict = contact.verifiedNftBannerData;
    final bannerOpacity =
        ((0.4 + 0.6 * progress) * (1 - dock)).clamp(0.0, 1.0);
    final bool bannerTappable =
        _current.kind == _TabKind.profile && bannerOpacity > 0.01;

    Widget content;
    VoidCallback? onTap;

    if (nftBanner != null) {
      content = ColoredBox(
        color: tokens.background,
        child: Opacity(
          opacity: bannerOpacity,
          child: NftBanner(contact: contact),
        ),
      );
      if (bannerTappable && nftVerdict != null) {
        onTap = () => showNftInfoDialogFor(
              context,
              ref: nftBanner,
              cache: nftVerdict,
              owner: contact,
            );
      }
    } else if (_bgAsBannerUrl != null || bannerUrl.isEmpty) {
      final bg = _bgAsBannerUrl;
      content = ColoredBox(
        color: tokens.background,
        child: bg == null
            ? null
            // The background as the banner, slid up with the header. No
            // collapse fade on the profile tab, where the page background
            // under it is the same picture at the same offset.
            : Opacity(
                opacity: _current.kind == _TabKind.profile ? 1 : bannerOpacity,
                child: LayoutBuilder(
                  builder: (context, c) =>
                      _buildPageBackground(bg, c.maxWidth, slide: true),
                ),
              ),
      );
    } else {
      final heroTag = 'banner_image_$bannerUrl';
      content = ColoredBox(
        color: tokens.background,
        child: Opacity(
          opacity: bannerOpacity,
          child: _placeBanner(
            (fit, alignment) => Hero(
              tag: heroTag,
              child: ZeroCachedImage(
                imageUrl: bannerUrl,
                fit: fit,
                alignment: alignment,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                errorWidget: (_, __, ___) =>
                    ColoredBox(color: tokens.surfaceDeep),
              ),
            ),
          ),
        ),
      );
      if (bannerTappable) {
        onTap = () => Navigator.push(
              context,
              PageRouteBuilder(
                opaque: false,
                barrierColor: Colors.transparent,
                transitionDuration: const Duration(milliseconds: 300),
                reverseTransitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (ctx, _, __) => ImageOverlay(
                  imageUrl: bannerUrl,
                  heroTag: heroTag,
                  onClose: () => Navigator.pop(ctx),
                ),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
      }
    }

    final art = ClipRect(child: content);
    if (onTap == null) return art;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: art),
    );
  }

  /// Client `_buildAvatarAndName`: the canonical GlassContactIcon at the
  /// lerped size/position, name (+ short address) beside it. Avatar tap =
  /// NFT info dialog for a verified NFT avatar, full-screen image otherwise.
  Widget _buildAvatarAndName(
      GlassTokens tokens, double progress, double avatarSize) {
    final contact = widget.contact;
    final addr = contact.publicosAddress?.eip55With0x;

    final avatarUrl = contact.avatarUrl;
    VoidCallback? onAvatarTap;
    if (contact.nftAvatar != null && contact.verifiedNftAvatarData != null) {
      onAvatarTap = () => showNftInfoDialog(context, contact);
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      final heroTag = 'avatar_image_$avatarUrl';
      onAvatarTap = () => Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.transparent,
              transitionDuration: const Duration(milliseconds: 300),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              pageBuilder: (ctx, _, __) => ImageOverlay(
                imageUrl: avatarUrl,
                heroTag: heroTag,
                onClose: () => Navigator.pop(ctx),
              ),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: onAvatarTap != null
              ? SystemMouseCursors.click
              : MouseCursor.defer,
          child: GestureDetector(
            onTap: onAvatarTap,
            child: GlassContactIcon(contact: contact, size: avatarSize),
          ),
        ),
        const SizedBox(width: 12),
        // The name + address sit on the avatar's BOTTOM edge at rest (progress
        // 1), clear of the banner the avatar straddles, and slide up to the
        // avatar's centre as the header collapses, so the 56px strip still
        // reads centred. `Alignment(-1, progress)` is the whole lerp.
        Expanded(
          child: SizedBox(
            height: avatarSize,
            // OverflowBox, not Align: mid-collapse the avatar is briefly
            // shorter than name + address (≈40px vs ~44px), and a clamped
            // box would report a bottom overflow. This lets the column exceed
            // the avatar while aligning.
            child: OverflowBox(
              alignment: Alignment(-1, progress),
              minHeight: 0,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // "name/Tab" like the client's header (`_getCurrentTabPath`,
                  // hidden on the profile tab): the tab strip names the tab
                  // too, but the header is where the eye lands.
                  Text.rich(
                    TextSpan(
                      text: contact.displayName,
                      children: [
                        if (_current.kind != _TabKind.profile)
                          TextSpan(
                            text: '/${_current.label}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: tokens.starkWhite.withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14 + 6 * progress,
                      fontWeight: FontWeight.w700,
                      color: tokens.starkWhite,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                  if (addr != null) _CopyableAddress(address: addr),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// SimpleChatScreen publishes/retracts its conversation-settings opener as
  /// topics resolve; it can fire during build, so defer the setState. Method
  /// tear-offs of the same State compare equal — dedupe to avoid loops.
  /// The no-key tile's action: the keychain, then the chat if an inbox was
  /// loaded there.
  Future<void> _loadKeysForChat() async {
    final before = PublicOS.clientXmtpInboxId;
    await showKeychainDialog(context,
        myContact: AppStateNotifier.currentMyContact);
    if (PublicOS.clientXmtpInboxId == before) return;
    xmtpKeyEpoch.value++;
    widget.onActiveKeyChanged?.call();
  }

  void _onChatSettingsAvailable(VoidCallback? opener) {
    if (_chatSettingsOpener == opener) {
      debugPrint('[browser] chat settings opener unchanged '
          '(${opener == null ? "still null" : "still live"}) — deduped');
      return;
    }
    debugPrint('[browser] chat settings opener -> '
        '${opener == null ? "NULL (gear hides)" : "live (gear shows)"}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _chatSettingsOpener = opener);
    });
  }
}

/// The header's account address line: truncated display + a small copy glyph,
/// the whole row one click target — copies the FULL address (never the
/// truncated form). Copy feedback = teal check for 1.2s, no snack.
class _CopyableAddress extends StatefulWidget {
  final String address;

  const _CopyableAddress({required this.address});

  @override
  State<_CopyableAddress> createState() => _CopyableAddressState();
}

class _CopyableAddressState extends State<_CopyableAddress> {
  bool _hover = false;
  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.address));
    _timer?.cancel();
    setState(() => _copied = true);
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final addr = widget.address;
    final color = _copied
        ? tokens.connectedAccent
        : (_hover ? tokens.starkWhite : tokens.textDim);
    return Tooltip(
      message: context.l10n.selectAccountScreenCopyAddress,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          // Without this the gaps between the address text and the copy glyph
          // are dead: a Row hit-tests its children, not itself.
          behavior: HitTestBehavior.opaque,
          onTap: _copy,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}',
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 11,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The multi-link app picker: the app's identity up top, one hoverable row
/// per launchable link below — every row opens in the OS browser (desktop has
/// no embedded webview). Same dialog chrome as the NFT info dialog.
class _AppLinksDialog extends StatelessWidget {
  final AppBookmark app;
  final List<_AppLink> links;

  const _AppLinksDialog({required this.app, required this.links});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final description = app.description?.trim();
    return Dialog(
      backgroundColor: tokens.surfaceElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.displayName.trim().isNotEmpty
                    ? app.displayName
                    : app.appName,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.starkWhite,
                ),
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              for (final link in links)
                _AppLinkRow(
                  link: link,
                  onTap: () {
                    Navigator.pop(context);
                    final uri = Uri.tryParse(link.url);
                    if (uri != null) launchUrl(uri);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppLinkRow extends StatefulWidget {
  final _AppLink link;
  final VoidCallback onTap;

  const _AppLinkRow({required this.link, required this.onTap});

  @override
  State<_AppLinkRow> createState() => _AppLinkRowState();
}

class _AppLinkRowState extends State<_AppLinkRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        // A Container with a `decoration` (rather than a `color`) is a
        // DecoratedBox, which does not hit-test itself -- so without `opaque`
        // this row's 10x9 padding is dead and only the text is clickable.
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _hover ? tokens.glassFillHover : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.link.icon,
                  size: 16,
                  color: _hover ? tokens.connectedAccent : tokens.textDim),
              const SizedBox(width: 10),
              Text(
                widget.link.label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hover ? tokens.starkWhite : tokens.textDim,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  deckDisplayUrl(widget.link.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 10.5,
                    color: tokens.textDim.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded,
                  size: 12,
                  color: _hover ? tokens.connectedAccent : tokens.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

