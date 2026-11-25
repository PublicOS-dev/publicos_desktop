import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import '../router_helpers.dart';
import '../theme/glass_tokens.dart';
import '../widgets/inline_flow_host.dart';
import 'create_org_page.dart';
import '../widgets/contact_settings_dialog.dart';
import '../widgets/discover_contact_row.dart';
import '../widgets/explorer_chip.dart';
import '../widgets/glass_contact_icon.dart';
import '../widgets/glass_context_menu.dart';
import '../widgets/send_icon.dart';
import '../widgets/transactions/send_sheet.dart';
import '../widgets/grid_settings_sheet.dart';
import '../widgets/pixel_rain_loading_label.dart';
import '../widgets/browser.dart';
import '../widgets/browser/tab_deck.dart' show DeckSelectionMemory;
import '../widgets/shell_split.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

/// The Contacts feature pane (shell index 1) — individuals AND orgs in one
/// list, narrowed by the client's Personal / Orgs filter chips. Dual-pane: the
/// publicos_client contacts view re-shelled as a fixed-width **left nav**
/// (search + filter/sort chips + banner-behind rows), driving a **detail pane**
/// on the right. Direct Core (`PublicOSContacts`) + setState, no repo — the client's
/// `contacts_view.dart` recipe.
///
/// Left list + selection, with the selected contact's full profile ([ProfilePane])
/// on the right. Tapping a row selects it (teal nav tint) and renders its profile.
///
/// ⚠️ ROOT-ORG COUPLED, NOT RESOLVER-PINNED — changes with every chain
/// redeploy, and a stale value fails SILENTLY (default avatar, no error). Keep
/// in lockstep with `feeds_settings_sheet.dart`'s `_publicosAccountAddress`;
/// both re-point from `MR.getModuleAddress(keccak256("PUBLICOS_ROOT_ORG"))`.
const String _previewContactAddress =
    '0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD';

class ContactsPane extends StatefulWidget {
  /// The list card's width — public so the shell can morph into it.
  static const double listWidth = 380;

  /// The shell's ONE focus intent: null = focus the user's own profile (the
  /// My Account row), non-null = focus that contact (`AppNav.toContact` /
  /// `toProfile` — a post author's avatar, a mention tap). [focusToken] is a
  /// monotonic token rather than a bool because the request must re-fire even
  /// when this pane is already mounted and showing someone else — and for the
  /// *same* contact twice in a row (tap author → browse away → tap again).
  /// 0 = no request (normal Contacts navigation).
  ///
  /// Deliberately one (contact, token) pair, not a self-token + a contact-token:
  /// two pending tokens on a fresh mount would race each other (the async
  /// self-focus resolves last and stomps the contact focus — every mention tap
  /// lands on the user's own profile). With one pair, only the latest intent
  /// exists.
  final Contact? focusContact;
  final int focusToken;

  /// Apps landing (`AppNav.toApp`): with [focusContact], the
  /// registry app whose tab the Browser should land on — the client's
  /// `/publicosAddress/:address/app/:appName` route. Null = land on Profile.
  final AppBookmark? focusApp;

  /// Custom-tab landing (`AppNav.toTab`): with [focusContact], the
  /// router record key the Browser should open on.
  final String? focusTabKey;

  const ContactsPane({
    super.key,
    this.focusContact,
    this.focusToken = 0,
    this.focusApp,
    this.focusTabKey,
  });

  @override
  State<ContactsPane> createState() => _ContactsPaneState();
}

class _ContactsPaneState extends State<ContactsPane> {

  /// Where the Browser deck's selection slab last rested. Held here because
  /// the Browser remounts per contact and this pane does not: contact →
  /// contact slides the slab from it; a fresh pane (arrived from another rail
  /// screen) starts without one and the slab enters from the left.
  final DeckSelectionMemory _deckMemory = DeckSelectionMemory();

  // Grid/text density (shared with Apps tab via explorer_grid_size /
  // explorer_text_size keys). Ported from the client's `contacts_view`.
  int _gridSize = kDefaultGridSize;
  TextSizeOption _textSize = kDefaultTextSize;
  // Contacts-only layout state. Persisted under contacts_layout /
  // contacts_show_contact_banner (client keys, same Core settings rows).
  ContactsLayout _layout = ContactsLayout.rows;
  bool _showBanner = true;

  // Contact state
  List<Contact> _all = const [];
  Contact? _searchResult;
  bool _loading = true;
  bool _searching = false;
  String? _error;
  int _loadGen = 0;

  // Filter / sort / search. Personal/Orgs chips, not a separate Orgs rail
  // section: an org is a contact like any other, so one list with the
  // client's two toggles.
  bool _showPersonal = true;
  bool _showOrgs = true;

  /// The Starred chip (client twin): on = only starred contacts,
  /// the ones the user gets chain notifications about; off = every stored
  /// contact. On by default, kept on the device under [_starredOnlyKey].
  bool _starredOnly = true;
  static const String _starredOnlyKey = 'contacts_starred_only';
  bool _sortAsc = true;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Selection (drives the detail pane)
  Contact? _selected;

  /// A chain sync is in flight for [_selected]. Drives the small corner
  /// indicator — the pane keeps rendering the local copy underneath, exactly
  /// like the client (local-first, never a blocking loader on the profile).
  bool _syncing = false;

  /// Bumped on every selection. In-flight chain reads carry the generation they
  /// were started under and drop themselves once it goes stale — the stand-in
  /// for cancelling a Future, which Dart doesn't offer.
  int _selectGen = 0;

  /// The app the Browser lands on for the CURRENT selection (Apps landing),
  /// null for an ordinary select. [_landingGen] bumps per app landing so the
  /// keyed Browser remounts even when the same contact is already up — the
  /// landing is a mount-time contract (`Browser.initialApp`), like the
  /// Messages door's `initialInboxId`.
  AppBookmark? _landingApp;
  String? _landingTabKey;
  int _landingGen = 0;

  /// DESKTOP-ONLY: the browser's content-width caps, one per tab group
  /// (Settings dialog → Content width). Mirrors the feeds reading width — and
  /// the feeds group literally IS it. See `contact_settings_dialog.dart`.
  BrowserWidths _widths = const BrowserWidths.defaults();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadContacts();
    _loadProfileWidth();
    _loadStoredSettings();
    if (widget.focusToken > 0) _applyFocus();
  }

  /// Client-verbatim (`contacts_view._loadStoredSettings`): the shared
  /// `explorer_grid_size` / `explorer_text_size` density plus the
  /// Contacts-only `contacts_layout` + `contacts_show_contact_banner`.
  Future<void> _loadStoredSettings() async {
    final results = await Future.wait([
      loadStoredGridSize(),
      loadStoredTextSize(),
      loadStoredContactsLayout(),
      loadStoredContactsShowBanner(),
    ]);
    if (!mounted) return;
    setState(() {
      final grid = results[0] as int?;
      final text = results[1] as TextSizeOption?;
      final layout = results[2] as ContactsLayout?;
      final showBanner = results[3] as bool?;
      if (grid != null) _gridSize = grid;
      if (text != null) _textSize = text;
      if (layout != null) _layout = layout;
      if (showBanner != null) _showBanner = showBanner;
    });
    try {
      final rec = await PublicOSSettings.getSetting(_starredOnlyKey);
      if (rec != null && mounted) {
        setState(() => _starredOnly = rec.value != 'false');
      }
    } catch (_) {}
  }

  void _setStarredOnly(bool value) {
    if (_starredOnly == value) return;
    setState(() => _starredOnly = value);
    () async {
      try {
        await PublicOSSettings.setSetting(
          _starredOnlyKey,
          Record.asSettings(
              key: _starredOnlyKey, value: value.toString(), isSystem: true),
        );
      } catch (_) {}
    }();
  }

  /// Starred, or the publicos org (always starred, no toggle).
  bool _isStarred(Contact c) =>
      c.bookmarked == true ||
      (c.publicosAddress != null &&
          PublicOSContacts.isAlwaysStarred(c.publicosAddress!));

  /// Client-verbatim (`contacts_view._openSettings`). The sheet itself is the
  /// 0-delta mirror in `widgets/grid_settings_sheet.dart`.
  void _openSettings() {
    showGridSettingsSheet(
      context,
      currentGridSize: _gridSize,
      currentTextSize: _textSize,
      onGridSizeChanged: (v) => setState(() => _gridSize = v),
      onTextSizeChanged: (v) => setState(() => _textSize = v),
      showLayoutToggle: true,
      currentLayout: _layout,
      onLayoutChanged: (v) => setState(() => _layout = v),
      showBannerToggle: true,
      currentShowBanner: _showBanner,
      onShowBannerChanged: (v) => setState(() => _showBanner = v),
      showContactPreview: true,
      previewContactAddress: _previewContactAddress,
    );
  }

  /// All three browser width groups in one read. Every failure mode collapses
  /// to defaults inside [BrowserWidths.load], so there is nothing to guard
  /// here.
  Future<void> _loadProfileWidth() async {
    final widths = await BrowserWidths.load();
    if (mounted) setState(() => _widths = widths);
  }

  @override
  void didUpdateWidget(covariant ContactsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The shell bumped the token — My Account clicked again, or someone tapped
    // a post author / mention. Routed through [_select] like any other row, so
    // it renders the local copy instantly and refreshes from chain behind it.
    if (widget.focusToken != oldWidget.focusToken && widget.focusToken > 0) {
      _applyFocus();
    }
  }

  /// Apply the shell's focus intent: a contact if one was passed, else self.
  void _applyFocus() {
    final c = widget.focusContact;
    if (c != null) {
      _select(c, landingApp: widget.focusApp, landingTabKey: widget.focusTabKey);
    } else {
      _focusSelf();
    }
  }

  /// Select the signed-in user's own profile in the detail pane.
  ///
  /// Read from the local DB (the self contact is persisted by `restoreSession`),
  /// then routed through [_select] like any other row — so it renders instantly
  /// and refreshes from chain behind it, same as picking someone from the list.
  ///
  /// Note the left list deliberately **excludes** self (see `_loadContacts`), so
  /// no row highlights here — the profile simply opens. That's intended: your own
  /// account isn't one of your contacts.
  Future<void> _focusSelf() async {
    final hex = PublicOS.myPublicosAddress;
    if (hex == null) return;
    try {
      final me = await PublicOSContacts.getContact(
        EthereumAddress.fromHex(hex),
      );
      if (!mounted || me == null) return;
      _select(me);
    } catch (_) {
      // No local self-contact (shouldn't happen post-login) — leave the pane be.
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _loadContacts({bool showSpinner = true}) async {
    final gen = ++_loadGen;
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final myAddr = PublicOS.myPublicosAddress?.toLowerCase();
      final loaded = await PublicOSContacts.getStoredContacts();
      if (gen != _loadGen || !mounted) return;

      const zero = '0x0000000000000000000000000000000000000000';
      final filtered = loaded.where((c) {
        final addr = c.publicosAddress?.eip55With0x.toLowerCase();
        if (addr == null) return false;
        if (addr == zero) return false;
        if (myAddr != null && addr == myAddr) return false;
        return true;
      }).toList();

      setState(() {
        _all = filtered;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (gen != _loadGen || !mounted) return;
      setState(() {
        _all = const [];
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    final next = _searchCtrl.text;
    if (next == _query) return;
    setState(() => _query = next);
    _handleSearchResolution();
  }

  /// When the local filter comes up empty but the user typed a real identifier
  /// (address / inbox / on-chain name), reach to Core and surface the match as
  /// a single result prepended to the list.
  Future<void> _handleSearchResolution() async {
    final trimmed = _query.trim();
    if (trimmed.isEmpty) {
      if (_searchResult != null || _searching) {
        setState(() {
          _searchResult = null;
          _searching = false;
        });
      }
      return;
    }
    setState(() => _searching = true);
    try {
      final resolved = await PublicOSContacts.resolveByIdentifier(trimmed);
      if (!mounted) return;
      if (resolved == null) {
        setState(() {
          _searchResult = null;
          _searching = false;
        });
        return;
      }
      final resolvedInbox = resolved.registeredInboxIDs?.firstOrNull?.inboxId;
      final alreadyLocal = _all.any((c) {
        final byAddress = c.publicosAddress != null &&
            c.publicosAddress == resolved.publicosAddress;
        final byInbox = resolvedInbox != null &&
            (c.registeredInboxIDs?.any((e) => e.inboxId == resolvedInbox) ??
                false);
        return byAddress || byInbox;
      });
      setState(() {
        _searchResult = alreadyLocal ? null : resolved;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResult = null;
        _searching = false;
      });
    }
  }

  // Filter mutators — the client's `contacts_view` guard verbatim: turning one
  // chip off while the other is already off turns the other back on, so the
  // list can never be filtered to nothing.
  void _setShowPersonal(bool value) {
    if (_showPersonal == value) return;
    setState(() {
      if (!value && !_showOrgs) _showOrgs = true;
      _showPersonal = value;
    });
  }

  void _setShowOrgs(bool value) {
    if (_showOrgs == value) return;
    setState(() {
      if (!value && !_showPersonal) _showPersonal = true;
      _showOrgs = value;
    });
  }

  List<Contact> get _filteredContacts {
    Iterable<Contact> view = _all;

    // The Starred chip narrows the LIST only. A search looks through every
    // stored contact, as it always has.
    if (_starredOnly && _query.trim().isEmpty) {
      view = view.where(_isStarred);
    }

    if (!_showPersonal || !_showOrgs) {
      view = view.where((c) {
        final isOrg = c.isOrgAccount;
        if (isOrg && !_showOrgs) return false;
        if (!isOrg && !_showPersonal) return false;
        return true;
      });
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      view = view.where((c) {
        if (c.displayName.toLowerCase().contains(q)) return true;
        if (c.publicosDisplayName?.toLowerCase().contains(q) == true) {
          return true;
        }
        if (c.publicosAddress?.eip55With0x.toLowerCase().contains(q) == true) {
          return true;
        }
        final inboxHit = c.registeredInboxIDs
                ?.any((e) => e.inboxId.toLowerCase().contains(q)) ??
            false;
        if (inboxHit) return true;
        final sessionHit = c.sessions
                ?.any((cl) => cl.address.eip55With0x.toLowerCase().contains(q)) ??
            false;
        return sessionHit;
      });
    }

    final list = view.toList();
    list.sort((a, b) {
      final cmp =
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      return _sortAsc ? cmp : -cmp;
    });

    if (_searchResult != null && _query.trim().isNotEmpty) {
      list.insert(0, _searchResult!);
    }
    return list;
  }

  // ── Selection ───────────────────────────────────────────────────────────────

  String _keyOf(Contact c) =>
      c.publicosAddress?.eip55With0x ?? c.displayName;

  bool _isSelected(Contact c) =>
      _selected != null && _keyOf(_selected!) == _keyOf(c);

  /// Select a contact: render the **local** copy immediately, then pull a fresh
  /// one from chain in the background. This is publicos_client's contract —
  /// `browser.dart` renders local-first and fires a single `_syncFromChain` on
  /// open — and it matters here because the rows come from `getStoredContacts`,
  /// whose records can be stale (or, for a contact seeded/discovered but never
  /// opened, near-empty). Without this the profile would render whatever the DB
  /// happened to hold and never move.
  ///
  /// Every selection takes a new [_selectGen]. A Dart Future can't be cancelled,
  /// so the generation IS the cancellation: an older chain read still completes,
  /// but finds its generation stale and drops everything it was going to do —
  /// no setState, no spinner change. Same device the list already uses
  /// (`_loadGen`).
  void _select(Contact c, {AppBookmark? landingApp, String? landingTabKey}) {
    final gen = ++_selectGen;
    setState(() {
      _selected = c;
      _syncing = true;
      _landingApp = landingApp;
      _landingTabKey = landingTabKey;
      // One generation counter for BOTH landing kinds: it exists to force a
      // Browser remount when the same contact is re-focused with a new
      // landing, and only one landing can be in flight at a time.
      if (landingApp != null || landingTabKey != null) _landingGen++;
    });
    if (c.createdAt == null) _fillStoredJoined(gen);
    _syncSelectedFromChain(gen);
  }

  /// A contact handed in from outside the list (a post author, a mention, a
  /// search hit) may not carry the stored "Joined" date. Read it from the
  /// local row so the profile shows it at once, not when the chain sync lands.
  Future<void> _fillStoredJoined(int gen) async {
    final addr = _selected?.publicosAddress;
    if (addr == null) return;
    try {
      final stored = await PublicOSContacts.getContact(addr);
      final joined = stored?.createdAt;
      if (joined == null || !mounted || gen != _selectGen) return;
      final current = _selected;
      if (current == null || current.createdAt != null) return;
      setState(() => _selected = current.copyWith(createdAt: joined));
    } catch (_) {
      // No local row: the chain sync fills it.
    }
  }

  // ── Context menu (right-click a row) ────────────────────────────────────────

  /// The client's contact context menu (`contacts_view._showContactContextMenu`),
  /// same items, same order, same destructive tier.
  ///
  /// **Desktop delta on the first item.** The client's is *Share* — it hands the
  /// publicos.dev universal link to the OS share sheet (share_plus), which
  /// doesn't exist on Windows. Same link, put on the clipboard instead.
  void _showContactMenu(Contact contact, Offset position) {
    final address = contact.publicosAddress?.eip55With0x;
    GlassContextMenu.show(
      context,
      position: position,
      // The browser pills' glass, as in the client.
      frosted: true,
      items: [
        // Send to this contact: the one known recipient skips to the amount,
        // and the sheet's target defaults to their Main Safe.
        if (contact.publicosAddress != null)
          GlassContextMenuItem(
            iconBuilder: (size, color) =>
                SendCoinsIcon(size: size, color: color),
            label: context.l10n.contactsViewSend,
            onTap: () => showSendSheet(
              context: context,
              config: SendSheetConfig(
                targetMode: SendTargetMode.fixed,
                candidates: [
                  SendCandidate(
                    address: contact.publicosAddress!,
                    contact: contact,
                  ),
                ],
              ),
            ),
          ),
        if (address != null)
          GlassContextMenuItem(
            icon: Icons.copy_rounded,
            label: context.l10n.postCardCopyLink,
            onTap: () => _copyContactLink(address),
          ),
        // Star: this contact raises chain notifications. Not offered for the
        // publicos org, which is always starred.
        if (contact.publicosAddress != null &&
            !PublicOSContacts.isAlwaysStarred(contact.publicosAddress!))
          GlassContextMenuItem(
            icon: contact.bookmarked == true
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            label: contact.bookmarked == true
                ? context.l10n.contactsViewUnstar
                : context.l10n.contactsViewStar,
            onTap: () async {
              try {
                await PublicOSContacts.setStarred(
                    contact, contact.bookmarked != true);
              } catch (_) {}
              if (mounted) await _loadContacts(showSpinner: false);
            },
          ),
        GlassContextMenuItem(
          icon: Icons.delete_outline_rounded,
          label: context.l10n.keychainDelete,
          destructive: true,
          onTap: () => _confirmDeleteContact(contact),
        ),
      ],
    );
  }

  void _copyContactLink(String address) {
    // The same universal link the client shares — publicos.dev resolves it back
    // into a profile in-app.
    Clipboard.setData(
      ClipboardData(text: 'https://publicos.dev/publicosAddress/$address'),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.browserProfileLinkCopied)));
  }

  /// Destructive-tier glass confirm (error colour on icon + title) before the
  /// delete, exactly as the client does.
  Future<void> _confirmDeleteContact(Contact contact) async {
    final tokens = GlassTokens.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: errorColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.contactsViewDeleteContactTitle,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: errorColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          context.l10n.contactsViewDeleteConfirm(contact.displayName),
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            color: tokens.textDim,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.keychainDelete, style: TextStyle(color: errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _deleteContact(contact);
  }

  Future<void> _deleteContact(Contact contact) async {
    try {
      await PublicOSContacts.removeContact(contact);
      if (!mounted) return;
      // The detail pane can't outlive the row it was showing.
      if (_selected != null && _keyOf(_selected!) == _keyOf(contact)) {
        setState(() {
          _selected = null;
          _syncing = false;
        });
        _selectGen++; // strand any chain read still in flight for it
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.contactsViewRemovedFromContacts(contact.displayName))),
      );
      await _loadContacts(showSpinner: false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.contactsViewFailedToRemove)));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Two floating shell panels: the list card + the content card on canvas,
    // not a hard split with a 1px divider.
    return ShellSplit(
      listWidth: ContactsPane.listWidth,
      list: _leftList(tokens),
      content: _detail(tokens),
    );
  }

  // ── Left list ───────────────────────────────────────────────────────────────

  Widget _leftList(GlassTokens tokens) {
    return Column(
      children: [
        _searchField(tokens),
        _chipBar(tokens),
        Expanded(child: _listBody(tokens)),
        // Footer: Contact settings (desktop-only) — same idea as the feeds
        // drawer's Reading settings row.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(color: tokens.borderSubtle, height: 1),
        ),
        _settingsRow(tokens),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Create an org. Reproduces the client's `_showCreateOrgSheet` verbatim:
  /// CreateOrgPage is a pure imperative route that pops with the new org's
  /// address (or null if dismissed); on success open its profile, then refresh
  /// the list so the new org appears. The only delta is the shell — desktop
  /// runs route-shaped pages in a dialog over a nested Navigator
  /// (`showFlowPageDialog`) instead of pushing, so the page's own
  /// `Navigator.pop(address)` still returns a result unchanged.
  Future<void> _createOrg() async {
    final orgAddress = await showFlowPageDialog<String>(
      context,
      page: const CreateOrgPage(),
    );
    if (orgAddress == null || !mounted) return;
    await AppNav.toProfile(context, orgAddress);
    if (!mounted) return;
    _loadContacts();
  }

  Widget _settingsRow(GlassTokens tokens) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showContactSettingsDialog(
          context,
          widths: _widths,
          onWidthsChanged: (w) => setState(() => _widths = w),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 17, color: tokens.textDim),
              const SizedBox(width: 12),
              Text(
                context.l10n.desktopContactSettings,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(GlassTokens tokens) {
    return Padding(
      // 12 top, not 14 — homologated with the messages field.
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        // Borderless — one tone step down from the
        // list panel carries the field's edge, no hairline.
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontSize: 14,
          ),
          cursorColor: tokens.starkWhite,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon:
                Icon(Icons.search_rounded, size: 18, color: tokens.textDim),
            suffixIcon: _searching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: tokens.textDim,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : (_query.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded,
                            size: 16, color: tokens.textDim),
                        splashRadius: 16,
                        onPressed: _searchCtrl.clear,
                      )),
            // Desktop copy: the client's "Search name, address, or inbox" is
            // used on Messages only.
            hintText: context.l10n.desktopContactsSearchHint,
            hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _chipBar(GlassTokens tokens) {
    // The client's `_ContactsChipBar`, same chips in the same order:
    // Personal · Orgs | sort | New Org · settings.
    //
    // Spacing follows the messages bar's rhythm: 16 between chips of different
    // kinds, 8 between siblings. `borderless` is the chip's default, so it is
    // not passed here.
    return ExplorerChipBar(
      children: [
        ExplorerChip(
          label: context.l10n.contactsViewFilterStarred,
          icon: _starredOnly ? Icons.star_rounded : Icons.star_border_rounded,
          active: _starredOnly,
          onTap: () => _setStarredOnly(!_starredOnly),
        ),
        const SizedBox(width: 16),
        ExplorerChip(
          label: context.l10n.contactsViewFilterPersonal,
          icon: Icons.person_outline_rounded,
          active: _showPersonal,
          onTap: () => _setShowPersonal(!_showPersonal),
        ),
        const SizedBox(width: 8),
        ExplorerChip(
          label: context.l10n.contactsViewFilterOrgs,
          icon: Icons.corporate_fare_rounded,
          active: _showOrgs,
          onTap: () => _setShowOrgs(!_showOrgs),
        ),
        const SizedBox(width: 16),
        ExplorerChip(
          label: _sortAsc ? context.l10n.contactsViewSortAsc : context.l10n.contactsViewSortDesc,
          icon: _sortAsc
              ? Icons.arrow_upward_rounded
              : Icons.arrow_downward_rounded,
          active: true,
          onTap: () => setState(() => _sortAsc = !_sortAsc),
        ),
        const SizedBox(width: 16),
        ExplorerChip(
          label: context.l10n.contactsViewNewOrg,
          icon: Icons.add_business_rounded,
          active: false,
          onTap: _createOrg,
        ),
        const SizedBox(width: 8),
        // The client's chip-bar tune icon (`_ContactsChipBar.onSettings`) —
        // grid density / text size / rows-vs-grid / banner toggle.
        ExplorerChip(
          label: context.l10n.desktopLayoutChip,
          icon: Icons.tune_rounded,
          active: false,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _listBody(GlassTokens tokens) {
    if (_loading && _all.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: tokens.starkWhite,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null && _all.isEmpty) {
      return _stateMessage(
        tokens,
        icon: Icons.error_outline_rounded,
        title: context.l10n.contactsViewFailedToLoad,
        body: _error!,
        accent: tokens.fallbackAccent,
      );
    }
    final contacts = _filteredContacts;
    if (contacts.isEmpty) {
      final hasQuery = _query.trim().isNotEmpty;
      return _stateMessage(
        tokens,
        icon: hasQuery
            ? Icons.search_off_rounded
            : Icons.people_outline_rounded,
        title: hasQuery
            ? context.l10n.voteCardNoMatches
            : context.l10n.contactsViewNoContactsYet,
        body: hasQuery
            ? context.l10n.contactsViewNoMatchesHint
            // Contacts exist, none starred, and the chip is on.
            : (_starredOnly && _all.isNotEmpty)
                ? context.l10n.contactsViewNoStarred
                : context.l10n.contactsViewEmptyHint,
      );
    }
    if (_layout == ContactsLayout.rows) {
      return RefreshIndicator(
        onRefresh: () => _loadContacts(showSpinner: false),
        color: tokens.starkWhite,
        backgroundColor: tokens.surfaceElevated,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          itemCount: contacts.length,
          itemBuilder: (_, i) {
            final c = contacts[i];
            // Desktop delta: the client opens this menu on LONG-PRESS; on a
            // mouse the native gesture is right-click, so it hangs off
            // onSecondaryTapDown (which carries the pointer position the menu
            // anchors to).
            return GestureDetector(
              onSecondaryTapDown: (d) => _showContactMenu(c, d.globalPosition),
              child: DiscoverContactRow(
                key: ValueKey(_keyOf(c)),
                contact: c,
                showBanner: _showBanner,
                showChevron: false,
                selected: _isSelected(c),
                onTap: () => _select(c),
              ),
            );
          },
        ),
      );
    }
    // Grid layout — the client's `contacts_view` grid branch verbatim
    // (SliverLayoutBuilder + GridGeom + keep-alive tiles); only the host
    // scroll view differs (CustomScrollView here, the client's is the page).
    return RefreshIndicator(
      onRefresh: () => _loadContacts(showSpinner: false),
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, sliverConstraints) {
                // Canonical tile geometry — one definition, shared with the
                // Apps grid and the org member picker. See [GridGeom].
                final geom = GridGeom.forWidth(
                  sliverConstraints.crossAxisExtent,
                  _gridSize,
                  _textSize,
                );

                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    mainAxisSpacing: GridGeom.gap,
                    crossAxisSpacing: GridGeom.gap,
                    mainAxisExtent: geom.tileH,
                  ),
                  itemCount: contacts.length,
                  itemBuilder: (_, i) => _ContactTile(
                    key: ValueKey(_keyOf(contacts[i])),
                    contact: contacts[i],
                    iconSize: geom.iconSize,
                    fontSize: geom.fontSize,
                    lineHeight: GridGeom.lineHeight,
                    iconToText: GridGeom.iconToText,
                    textBlockH: geom.textBlockH,
                    selected: _isSelected(contacts[i]),
                    onTap: () => _select(contacts[i]),
                    onSecondaryTap: (pos) => _showContactMenu(contacts[i], pos),
                    tokens: tokens,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stateMessage(
    GlassTokens tokens, {
    required IconData icon,
    required String title,
    required String body,
    Color? accent,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: accent ?? tokens.textDim),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Right detail — the full profile ─────────────────────────────────────────

  /// Hard-reload the selected contact from chain and push the fresh copy back
  /// down into [ProfilePane]. This pane owns the contact lifecycle (the client's
  /// `browser.dart` `_syncFromChain` role); ProfilePane is pure display.
  ///
  /// Fired on selection and by pull-to-refresh. Also re-resolves the NFT avatar /
  /// banner verdicts and the citizen / public-org flags — `fetchContact` is what
  /// computes and persists all of those, so a contact only ever gets its verified
  /// art and badges once it has been through here.
  ///
  /// Race-guarded by [_selectGen] — clicking down a list fires one of these per
  /// row and they land out of order. Anything but the newest generation is inert:
  /// it never touches `_selected` and never clears `_syncing`.
  ///
  /// Comparing *addresses* instead would be subtly wrong: on A → B → A the
  /// stale first read for A finds the selection back on A, passes the check,
  /// and lands its old result — then clears the spinner while the newest read
  /// is still in flight. The generation can't be fooled that way.
  ///
  /// [gen] is null for pull-to-refresh, which takes the current generation.
  Future<void> _syncSelectedFromChain([int? gen]) async {
    final g = gen ?? _selectGen;
    final addr = _selected?.publicosAddress;
    if (addr == null) {
      // Nothing to sync (an XMTP-only contact has no chain account). Release the
      // spinner _select optimistically raised — otherwise it hangs forever.
      if (mounted && _syncing && g == _selectGen) {
        setState(() => _syncing = false);
      }
      return;
    }

    if (gen == null && mounted) setState(() => _syncing = true);
    try {
      final fetched = await PublicOSContacts.fetchContact(addr);
      if (g != _selectGen || !mounted) return; // superseded — drop it
      // The "Joined" row: keep the date we already hold on screen, and let
      // the chain read replace it only if it comes back different.
      final fresh = await _withCreatedAt(
        fetched.copyWith(createdAt: _selected?.createdAt),
      );
      if (g != _selectGen || !mounted) return;
      await PublicOSContacts.saveContact(fresh);
      if (g != _selectGen || !mounted) return;
      setState(() => _selected = fresh);
    } catch (_) {
      // Chain down / unreachable — keep the local copy on screen.
    } finally {
      // Only the newest generation owns the spinner.
      if (mounted && g == _selectGen && _syncing) {
        setState(() => _syncing = false);
      }
    }
  }

  /// Port of publicos_client `browser.dart` `_withCreatedAt`: returns [c] with
  /// `Contact.createdAt` read from chain. The stored value is what the profile
  /// shows while this runs; it is replaced only when the chain answers with a
  /// different date. Pure: no setState, no save. A failed or empty read
  /// returns [c] unchanged.
  Future<Contact> _withCreatedAt(Contact c) async {
    final addr = c.publicosAddress;
    if (addr == null) return c;
    try {
      final created = await PublicOSAccounts.getAccountCreatedAt(
        addr,
        isOrg: c.isOrgAccount,
      );
      if (created == null) return c;
      final held = c.createdAt;
      if (held != null && held.isAtSameMomentAs(created)) return c;
      return c.copyWith(createdAt: created);
    } catch (_) {
      return c;
    }
  }

  Widget _detail(GlassTokens tokens) {
    final c = _selected;
    if (c == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_outlined, size: 56, color: tokens.textDim),
            const SizedBox(height: 14),
            Text(
              context.l10n.desktopSelectContactTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.desktopSelectContactHint,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // The right pane is the shared Browser (Profile · Chat · Feeds · Web ·
        // Settings), landing on Profile — the Contacts door. The desktop-only
        // width cap (Contact settings → Content width) lives inside the panel
        // and applies to every tab body.
        Positioned.fill(
          child: Browser(
            // Re-mount on selection change so the panel + ProfilePane
            // re-resolve tabs / founder / group description for the new
            // contact.
            key: ValueKey(_landingApp != null
                ? '${_keyOf(c)}|app:${_landingApp!.appName}#$_landingGen'
                : _landingTabKey != null
                    ? '${_keyOf(c)}|tab:$_landingTabKey#$_landingGen'
                    : _keyOf(c)),
            contact: c,
            door: BrowserDoor.contacts,
            initialApp: _landingApp,
            initialTabKey: _landingTabKey,
            widths: _widths,
            onRefresh: _syncSelectedFromChain,
            onOpenContact: _select,
            deckMemory: _deckMemory,
          ),
        ),
        // The profile's only loading affordance — the local copy stays on
        // screen and the chain sync lands underneath it (client parity: no
        // blocking loader on a profile).
        //
        // Rain + the wave-animated "Loading", the same loader the feed/app
        // tabs a click away use, so switching panes never swaps the loader.
        //
        // `PixelRainLoadingCorner` owns its own placement (IgnorePointer →
        // SafeArea → bottomRight → the shared inset), which is why there is no
        // Positioned wrapper: the position living inside the widget is what
        // stops the two apps drifting apart.
        if (_syncing) const PixelRainLoadingCorner(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grid tile — ported from the client's `contacts_view._ContactTile`.
// Desktop deltas: the long-press context menu becomes right-click
// (`onSecondaryTapDown`), a `MouseRegion` gives the tile a pointer cursor,
// and the selected tile carries the same teal tint the rows use (the client
// has no selection — it navigates away on tap; here the tile stays visible
// beside the profile it opened).
// ---------------------------------------------------------------------------

/// Keep-alive so tiles that scroll out of view aren't disposed and rebuilt —
/// avatar image decode is the dominant per-tile cost and a rebuild causes
/// scroll lag.
class _ContactTile extends StatefulWidget {
  final Contact contact;
  final double iconSize;
  final double fontSize;
  final double lineHeight;
  final double iconToText;
  final double textBlockH;
  final bool selected;
  final VoidCallback onTap;
  final void Function(Offset globalPosition) onSecondaryTap;
  final GlassTokens tokens;

  const _ContactTile({
    super.key,
    required this.contact,
    required this.iconSize,
    required this.fontSize,
    required this.lineHeight,
    required this.iconToText,
    required this.textBlockH,
    required this.selected,
    required this.onTap,
    required this.onSecondaryTap,
    required this.tokens,
  });

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Pre-resolved fields. SliverGrid.builder already wraps each child in a
  // RepaintBoundary (`addRepaintBoundaries: true`), so we don't add another
  // here. The `displayName` is read directly off `widget.contact` (cheap).
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTapDown: (details) =>
            widget.onSecondaryTap(details.globalPosition),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.selected
                ? widget.tokens.connectedAccent.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GlassContactIcon(
                contact: widget.contact,
                size: widget.iconSize,
              ),
              SizedBox(height: widget.iconToText),
              SizedBox(
                height: widget.textBlockH,
                // OverflowBox lets the Text lay itself out at its natural
                // height (which includes glyph descenders past the line box)
                // and paint into the row gap below — fixes "y/g/p second line
                // gets clipped" without growing the tile.
                child: OverflowBox(
                  minHeight: 0,
                  maxHeight: double.infinity,
                  alignment: Alignment.topCenter,
                  child: Text(
                    widget.contact.displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: widget.tokens.starkWhite,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w600,
                      height: widget.lineHeight,
                    ),
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
