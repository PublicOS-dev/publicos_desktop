import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import '../theme/glass_tokens.dart';
import '../theme/shell_tones.dart';
import '../utils/app_history.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'glass_contact_icon.dart';
import 'glass_context_menu.dart';
import 'mini_copy_button.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// One shell destination. The single source of truth for both the [Sidebar]
/// nav and the [AppShell] content switch — keep nav labels and placeholder
/// panes in lockstep by reading from [kShellDestinations].
///
/// Index 0 (My Account) is rendered as the rail's user chip, NOT as a nav
/// row, so the nav list iterates `kShellDestinations.skip(1)`.
class ShellDestination {
  final int index;
  final IconData icon;
  final IconData selectedIcon;

  /// Papercraft tile art — the same
  /// file as the Apps dialog tile. When set, every rail row for this
  /// destination (footer row, system-app history row) paints it at 28px in
  /// place of the glyph; the glyph stays as the decode fallback.
  final String? asset;

  const ShellDestination(this.index, this.icon, this.selectedIcon,
      {this.asset});
}

/// Labels and blurbs resolve at render time — l10n needs a [BuildContext],
/// and [kShellDestinations] stays a compile-time const keyed by [index].
/// BSP / SSP are acronyms, identical in every locale.
extension ShellDestinationL10n on ShellDestination {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.keychainMyAccount,
      1 => l10n.explorerTabContacts,
      2 => l10n.explorerTabMessages,
      3 => l10n.explorerTabFeeds,
      4 => l10n.groupVotingViewWallets,
      5 => l10n.appsViewSystemTreasury,
      6 => 'BSP',
      7 => 'SSP',
      8 => l10n.appsViewSystemNodes,
      9 => l10n.walletChipSettings,
      10 => l10n.contactsViewFilterOrgs,
      11 => l10n.appsViewSystemSocialGraph,
      12 => l10n.accountCenterTitle,
      _ => '',
    };
  }

  /// One-line description used by the not-yet-migrated placeholder pane.
  String blurb(BuildContext context) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.desktopNavBlurbMyAccount,
      1 => l10n.desktopNavBlurbContacts,
      2 => l10n.desktopNavBlurbMessages,
      3 => l10n.desktopNavBlurbFeeds,
      4 => l10n.desktopNavBlurbWallets,
      5 => l10n.desktopNavBlurbTreasury,
      6 => l10n.desktopNavBlurbBsp,
      7 => l10n.desktopNavBlurbSsp,
      8 => l10n.desktopNavBlurbNodes,
      9 => l10n.desktopNavBlurbSettings,
      11 => l10n.desktopNavBlurbSocialGraph,
      12 => l10n.desktopNavBlurbAccount,
      _ => '',
    };
  }
}

const List<ShellDestination> kShellDestinations = [
  ShellDestination(
    0,
    Icons.person_outline,
    Icons.person,
  ),
  ShellDestination(
    1,
    Icons.people_outline,
    Icons.people,
  ),
  ShellDestination(
    2,
    Icons.chat_bubble_outline,
    Icons.chat_bubble,
  ),
  ShellDestination(
    3,
    Icons.rss_feed_outlined,
    Icons.rss_feed,
  ),
  ShellDestination(
    4,
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet,
  ),
  ShellDestination(
    5,
    Icons.account_balance_outlined,
    Icons.account_balance,
    asset: 'assets/system_apps/treasury.png',
  ),
  ShellDestination(
    6,
    Icons.dns_outlined,
    Icons.dns,
  ),
  ShellDestination(
    7,
    Icons.cloud_outlined,
    Icons.cloud,
  ),
  ShellDestination(
    8,
    Icons.hub_outlined,
    Icons.hub,
  ),
  ShellDestination(
    9,
    Icons.settings_outlined,
    Icons.settings,
    asset: 'assets/system_apps/settings.png',
  ),
  // RETIRED slot (index 10), the Orgs section: orgs live in Contacts,
  // behind the Personal/Orgs chips. Kept only
  // because this list is indexed positionally — it is off [kRailOrder] and
  // the shell routes nothing here.
  ShellDestination(
    10,
    Icons.corporate_fare_rounded,
    Icons.corporate_fare_rounded,
  ),
  // The trust-tree canvas, as its own destination (pane = GraphPane).
  ShellDestination(
    11,
    Icons.account_tree_outlined,
    Icons.account_tree,
    asset: 'assets/system_apps/social_graph.png',
  ),
  // The Account app (index 12). Distinct from
  // the rail's user chip (index 0), which opens
  // Contacts focused on yourself — the chip is "see my profile as
  // others do", this row is "manage my account" (devices, recovery, domain,
  // accent). The `manage_accounts` glyph carries that split; the chip's
  // `person` glyph stays as-is.
  ShellDestination(
    12,
    Icons.manage_accounts_outlined,
    Icons.manage_accounts,
    asset: 'assets/system_apps/account.png',
  ),
];

/// Rail display order — decoupled from destination indexes, which are stable
/// ids baked into the shell switch and AppNav (index 10, the Orgs section,
/// is retired: orgs live in Contacts).
/// Treasury (5), Nodes (8) and Social Graph (11) are not on the rail:
/// they are APPS — Apps dialog tiles + rail history rows
/// (`utils/app_history.dart` `kSystemApps`).
/// Their destinations stay defined; they just have no rail rows.
/// Index 0 (My Account) renders as the user chip, not a nav row.
/// BSP (6) and SSP (7) are NOT rail rows — their launchers are the status
/// bar chips (rail = places you go, status bar = things you're connected
/// to). The destinations stay defined for AppNav.
const List<int> kRailOrder = [1, 2, 3, 4];

/// Rail FOOTER order — pinned to the bottom of the rail, below the scrolling
/// nav list. These are destinations you reach for
/// occasionally and want in a fixed place, not ones you scan past on the way
/// to Feeds; pinning also means they can't scroll away once the nav list
/// grows. Account sits directly above Settings (rather than folded into the
/// user chip, so the chip's Contacts-on-self behaviour stays untouched).
/// Same renderer as the nav rows, so
/// selection/hover/expand behave identically.
const List<int> kRailFooter = [12, 9];

/// Live state of one infra provider connection (chain RPC or SSP feed
/// server), shown in the shell [StatusBar]. Built by [AppShell]; the
/// presentation widgets are pure.
class ProviderStatus {
  /// null = checking / not loaded yet, true = reachable, false = down.
  final bool? reachable;

  /// Core's source classification — chain: 'bsp' | 'custom' | 'public';
  /// ssp: 'ssp' | 'custom' | 'override' | 'default'.
  final String source;

  /// Connected server's display name (provider title / custom label /
  /// fallback like 'Public node').
  final String? name;

  /// Compact endpoint (host) for tooltips.
  final String? endpoint;

  const ProviderStatus({
    this.reachable,
    this.source = '',
    this.name,
    this.endpoint,
  });
}

/// The shell rail — a *quiet*
/// floating panel on the shell canvas: icons-only at [ShellMetrics.railWidth],
/// expanding to labels on hover. The expansion OVERLAYS the pane to its right
/// (the shell reserves only the collapsed width and hosts this in a Stack),
/// so nothing reflows; a ~200ms hover-intent delay keeps a quick mouse pass
/// from flickering it open, and collapse is immediate on exit.
///
/// Selection is a grey filled rounded-square behind the active icon — not
/// a teal pill, on purpose: teal is the connected-state accent, not
/// a "you are here" marker.
///
/// Everything connection/keys-flavored lives in the [StatusBar] (identity
/// chip = keychain launcher, BSP/SSP chips = provider dialogs); the rail is
/// destinations only — no footer launchers — with ONE exception: the apps
/// block above the footer (last-visited history + the pinned Apps button),
/// which is "places you go" in the visited sense.
/// Pure presentation: all state lives in [AppShell].
class Sidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Signed-in user's own contact (may be null while it loads from the DB).
  final Contact? myContact;
  final String? myAddress;

  /// Count pill per nav row, keyed by [ShellDestination.index]; 0 or absent =
  /// no pill. Today only Messages uses it (incoming since the last visit).
  final Map<int, int> badges;

  /// "Last visited apps" — most recent first, the
  /// Core history (`PublicOSAppRegistry.getRecentApps`) as the shell holds
  /// it. Painted as the app's `icon` pointer in the same 40px box as a nav
  /// row, in a fading scroll column pinned above the Apps button.
  final List<AppBookmark> recentApps;

  /// Click on a history row: open the app (the owner's profile at the app's
  /// tab — `AppNav.toApp`).
  final ValueChanged<AppBookmark> onOpenApp;

  /// Right-click → "Remove from history".
  final ValueChanged<AppBookmark> onRemoveRecentApp;

  /// The pinned Apps button — opens the Apps big dialog.
  final VoidCallback onOpenApps;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.myContact,
    required this.myAddress,
    this.badges = const {},
    this.recentApps = const [],
    required this.onOpenApp,
    required this.onRemoveRecentApp,
    required this.onOpenApps,
  });

  /// Max visible history rows before the column scrolls (44px rows). The
  /// list itself is capped by Core (`recentAppsMax`, 100).
  static const int _historyVisibleRows = 4;

  /// Height of the fade at each end of the history column.
  static const double _historyFade = 14.0;

  /// Synthetic hover id for the Apps button (nav ids are 0..12).
  static const int _appsRowId = -1;

  static const _hoverIntent = Duration(milliseconds: 200);
  static const _animDuration = Duration(milliseconds: 160);
  static const _animCurve = Curves.easeOutCubic;

  /// Curve for the label fades. On expand the text holds back and fades in
  /// near the end of the width animation (easeInExpo ramps late), so it never
  /// flashes clipped to the right of the icons mid-slide; on collapse it
  /// drops out immediately (easeOutExpo ramps early).
  static Curve _labelCurve(bool open) =>
      open ? Curves.easeInExpo : Curves.easeOutExpo;

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _open = false;
  Timer? _intentTimer;
  int? _hovered;

  /// Hovered history row, by slug (history rows are not nav ids).
  String? _hoveredApp;

  final ScrollController _historyCtrl = ScrollController();

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opening an app moves it to the top of the history — bring the column
    // back to the top with it.
    final oldFirst =
        oldWidget.recentApps.isEmpty ? null : oldWidget.recentApps.first.appName;
    final newFirst =
        widget.recentApps.isEmpty ? null : widget.recentApps.first.appName;
    if (oldFirst != newFirst && _historyCtrl.hasClients) {
      _historyCtrl.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _intentTimer?.cancel();
    _historyCtrl.dispose();
    super.dispose();
  }

  void _onEnter() {
    _intentTimer?.cancel();
    _intentTimer = Timer(Sidebar._hoverIntent, () {
      if (mounted) setState(() => _open = true);
    });
  }

  void _onExit() {
    _intentTimer?.cancel();
    if (_open) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final tones = ShellTones.of(context);

    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: AnimatedContainer(
        duration: Sidebar._animDuration,
        curve: Sidebar._animCurve,
        width: _open ? ShellMetrics.railWidthOpen : ShellMetrics.railWidth,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: tones.chrome,
          // Borderless — tone carries the edge.
          borderRadius: BorderRadius.circular(ShellMetrics.radius),
          // Only the expanded rail floats over content — give it lift.
          boxShadow: _open
              ? [
                  BoxShadow(
                    color: tokens.glassShadow,
                    blurRadius: 24,
                    offset: const Offset(8, 0),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            const SizedBox(height: 6),
            _userChip(tokens),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                children: [
                  for (final i in kRailOrder)
                    _navItem(tokens, kShellDestinations[i]),
                ],
              ),
            ),
            // Apps block, bottom-to-top: Settings ·
            // Account · thin divider · Apps button · last-visited history ·
            // slim divider · the nav list above. Pinned with the footer so
            // it never scrolls away; the history column scrolls on its own
            // with faded edges.
            if (widget.recentApps.isNotEmpty) ...[
              _divider(tokens),
              _history(tokens),
            ],
            _divider(tokens),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _appsButton(tokens),
            ),
            _divider(tokens),
            // Pinned footer — outside the Expanded so it never scrolls.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final i in kRailFooter)
                    _navItem(tokens, kShellDestinations[i]),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  // ── User chip (My Account, index 0) ────────────────────────────────────────

  Widget _userChip(GlassTokens tokens) {
    final contact = widget.myContact;
    final name =
        contact?.publicosDisplayName ?? contact?.displayName ?? context.l10n.keychainMyAccount;
    final addr = widget.myAddress;
    final shortAddr = (addr != null && addr.length >= 10)
        ? '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}'
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: _railRow(
        tokens: tokens,
        id: 0,
        height: 48,
        iconBox: _iconBox(
          tokens,
          selected: false,
          hovered: _hovered == 0,
          child: _avatar(tokens, contact),
        ),
        selected: false,
        onTap: () => widget.onSelect(0),
        labelWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
            if (shortAddr != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shortAddr,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: tokens.textDim,
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Only tappable while the rail is expanded — collapsed, the
                  // label is invisible (opacity 0) and must not catch clicks.
                  IgnorePointer(
                    ignoring: !_open,
                    child: MiniCopyButton(value: addr!),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(GlassTokens tokens, Contact? contact) {
    if (contact != null) {
      return GlassContactIcon(contact: contact, size: 32);
    }
    // Pre-load skeleton — same footprint as the resolved avatar.
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(32 * (14 / 44)),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Icon(Icons.person_outline, size: 17, color: tokens.textDim),
    );
  }

  // ── Apps: history + the Apps button ───────────────────────────────────────

  /// A 1px rule between the rail's groups. Inset like the rows so it reads as
  /// a separator between icons, not a full-width bar.
  Widget _divider(GlassTokens tokens) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      color: tokens.borderSubtle,
    );
  }

  /// The last-visited column: up to [Sidebar._historyVisibleRows] rows tall,
  /// scrolling past that, with both edges faded out (no hard edge).
  /// The fade is a `dstIn` mask so the rows dissolve into the rail's
  /// own tone rather than into a painted colour.
  Widget _history(GlassTokens tokens) {
    const rowH = 44.0;
    final rows = widget.recentApps.length;
    final visible = rows.clamp(1, Sidebar._historyVisibleRows);
    final height = rowH * visible + Sidebar._historyFade;
    final scrolls = rows > Sidebar._historyVisibleRows;
    return SizedBox(
      height: height,
      child: ShaderMask(
        shaderCallback: (rect) {
          final f = Sidebar._historyFade / rect.height;
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0, f, 1 - f, 1],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _historyCtrl,
          physics: scrolls
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: Sidebar._historyFade / 2,
          ),
          itemCount: rows,
          itemExtent: rowH,
          itemBuilder: (_, i) => _historyRow(tokens, widget.recentApps[i]),
        ),
      ),
    );
  }

  /// One history row: the app's icon pointer in the nav-row icon box (the
  /// same 40px box, corner radius 12, so it sits in the rail's grid), label
  /// when the rail is open, right-click → remove. No selected state — an app
  /// is not a destination.
  Widget _historyRow(GlassTokens tokens, AppBookmark app) {
    final hovered = _hoveredApp == app.appName;
    // A system app (Treasury · Social Graph · Nodes) has no icon pointer and
    // no owner: it paints its own glyph and its localized pane label.
    final sys = systemAppOf(app);
    final icon = app.icon;
    final glyph = Icon(sys?.icon ?? Icons.apps_rounded,
        size: 20, color: hovered ? tokens.starkWhite : tokens.textDim);
    final label = sys != null
        ? kShellDestinations[sys.destination].label(context)
        : (app.displayName.trim().isNotEmpty ? app.displayName : app.appName);
    final sysAsset = sys == null ? null : kShellDestinations[sys.destination].asset;
    final art = sysAsset != null
        ? _railArt(sysAsset, glyph)
        : (sys == null && icon != null && icon.isNotEmpty)
        ? ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: ZeroCachedImage(
              imageUrl: icon,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => glyph,
            ),
          )
        : glyph;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredApp = app.appName),
      onExit: (_) => setState(() {
        if (_hoveredApp == app.appName) _hoveredApp = null;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onOpenApp(app),
        onSecondaryTapDown: (d) => _showHistoryMenu(app, d.globalPosition),
        child: SizedBox(
          height: 44,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: ShellMetrics.railWidthOpen - 12,
            child: Row(
              children: [
                _iconBox(tokens,
                    selected: false, hovered: hovered, child: art),
                const SizedBox(width: 10),
                Flexible(
                  child: AnimatedOpacity(
                    duration: Sidebar._animDuration,
                    curve: Sidebar._labelCurve(_open),
                    opacity: _open ? 1 : 0,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: hovered ? tokens.starkWhite : tokens.textDim,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHistoryMenu(AppBookmark app, Offset position) {
    GlassContextMenu.show(
      context,
      position: position,
      items: [
        GlassContextMenuItem(
          icon: Icons.history_toggle_off_rounded,
          label: context.l10n.desktopRemoveFromHistory,
          onTap: () => widget.onRemoveRecentApp(app),
        ),
      ],
    );
  }

  /// The pinned Apps button — a nav-shaped row that opens the Apps dialog.
  /// Never "selected": the dialog floats over whatever pane is up.
  Widget _appsButton(GlassTokens tokens) {
    final hovered = _hovered == Sidebar._appsRowId;
    return _railRow(
      tokens: tokens,
      id: Sidebar._appsRowId,
      iconBox: _iconBox(
        tokens,
        selected: false,
        hovered: hovered,
        child: Icon(Icons.apps_rounded,
            size: 20, color: hovered ? tokens.starkWhite : tokens.textDim),
      ),
      label: context.l10n.explorerTabApps,
      selected: false,
      onTap: widget.onOpenApps,
    );
  }

  // ── Nav items ──────────────────────────────────────────────────────────────

  Widget _navItem(GlassTokens tokens, ShellDestination d) {
    final selected = widget.selectedIndex == d.index;
    final hovered = _hovered == d.index;
    final fg = (selected || hovered) ? tokens.starkWhite : tokens.textDim;
    final badge = widget.badges[d.index] ?? 0;

    final iconBox = _iconBox(
      tokens,
      selected: selected,
      hovered: hovered,
      child: d.asset != null
          ? _railArt(d.asset!, Icon(d.icon, size: 20, color: fg))
          : Icon(selected ? d.selectedIcon : d.icon, size: 20, color: fg),
    );

    return _railRow(
      tokens: tokens,
      id: d.index,
      iconBox: badge > 0
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                iconBox,
                Positioned(
                  top: 0,
                  right: 0,
                  child: _BouncingBadge(
                    count: badge,
                    child: _countPill(tokens, badge),
                  ),
                ),
              ],
            )
          : iconBox,
      label: d.label(context),
      selected: selected,
      onTap: () => widget.onSelect(d.index),
    );
  }

  /// Bundled papercraft art at the same 28px / radius-9 size a registry app's
  /// network icon uses in [_historyRow], so art rows line up in the rail.
  Widget _railArt(String asset, Widget fallback) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.asset(
        asset,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        cacheWidth: (28 * dpr).round(),
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  /// The 40×40 icon container — the selection indicator lives HERE (a filled
  /// grey rounded-square), not on the whole row.
  /// Same pill as the status bar's chain bell (`status_bar.dart`), sat on the
  /// icon box's top-right corner — inside the 40px box, so the collapsed
  /// rail's hardEdge clip never cuts it.
  Widget _countPill(GlassTokens tokens, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.connectedAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'SpaceGrotesk',
          color: Color(0xFF0A0A0A),
        ),
      ),
    );
  }

  Widget _iconBox(
    GlassTokens tokens, {
    required bool selected,
    required bool hovered,
    required Widget child,
  }) {
    final Color bg;
    if (selected) {
      bg = tokens.glassFillHover;
    } else if (hovered) {
      bg = tokens.glassFill;
    } else {
      bg = Colors.transparent;
    }
    return AnimatedContainer(
      duration: Sidebar._animDuration,
      curve: Sidebar._animCurve,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: child),
    );
  }

  /// Shared row scaffold: icon box + label that fades in when the rail is
  /// open. Collapsed, the row is exactly the 40px icon box (52 rail − 2×6 pad).
  Widget _railRow({
    required GlassTokens tokens,
    required int id,
    required Widget iconBox,
    required bool selected,
    required VoidCallback onTap,
    String? label,
    Widget? labelWidget,
    double height = 44,
  }) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = id),
      onExit: (_) => setState(() {
        if (_hovered == id) _hovered = null;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: height,
          // Rows always lay out at the EXPANDED width and the rail's hardEdge
          // clip crops them while collapsed — collapsed slots are narrower
          // than icon+gap, so laying out inside them would overflow by design
          // (the debug 12px stripes). OverflowBox states that intent.
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: 0,
            maxWidth: ShellMetrics.railWidthOpen - 12,
            child: Row(
              children: [
              iconBox,
              const SizedBox(width: 10),
              Flexible(
                child: AnimatedOpacity(
                  duration: Sidebar._animDuration,
                  curve: Sidebar._labelCurve(_open),
                  opacity: _open ? 1 : 0,
                  child: labelWidget ??
                      Text(
                        label ?? '',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              selected ? tokens.starkWhite : tokens.textDim,
                        ),
                      ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hop on every count increase: up 8 px, settle, a smaller 3 px second hop,
/// 600 ms ease-out. Mounting is the 0 → 1 transition, so it hops then too.
class _BouncingBadge extends StatefulWidget {
  final int count;
  final Widget child;

  const _BouncingBadge({required this.count, required this.child});

  @override
  State<_BouncingBadge> createState() => _BouncingBadgeState();
}

class _BouncingBadgeState extends State<_BouncingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  late final Animation<double> _dy = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 25),
    TweenSequenceItem(tween: Tween(begin: -8, end: 0), weight: 25),
    TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 20),
    TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 30),
  ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_BouncingBadge old) {
    super.didUpdateWidget(old);
    if (widget.count > old.count) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dy,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, _dy.value), child: child),
      child: widget.child,
    );
  }
}
