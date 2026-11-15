import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/grid_settings_sheet.dart'
    show
        TextSizeOption,
        loadStoredTextSize,
        kDefaultGridSize,
        kDefaultTextSize,
        GridGeom;
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart' show AppStateNotifier;
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Pattern A glass-dark contact picker for adding members to an *existing*
/// org. Returns the selected `List<Contact>` via `Navigator.pop` (null on
/// dismiss).
///
/// Grid layout is the shared contact / app grid — `SliverLayoutBuilder` +
/// explicit math + `mainAxisExtent` + `AutomaticKeepAliveClientMixin` tiles.
/// Reads density + text size from the same `explorer_grid_size` /
/// `explorer_text_size` keys the Explorer uses so the picker matches the
/// user's preferred Contacts-tab density.
///
/// A top-level `showPickOrgMembersSheet(context, …)` that paints its own
/// glass-dark chrome.
Future<List<Contact>?> showPickOrgMembersSheet(
  BuildContext context, {
  List<EthereumAddress>? existingMemberAddresses,
}) {
  return showGlassSheetDialog<List<Contact>>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _PickOrgMembersSheet(
      existingMemberAddresses: existingMemberAddresses,
    ),
  );
}

/// Backwards-compat: a couple of older sites still import the class
/// directly. The new entry point is [showPickOrgMembersSheet]. This widget
/// renders the same body without the modal/chrome wrap, so an existing
/// `showPhigitalBottomSheet(builder: (_, __) => PickOrgMembersSheet(...))`
/// caller keeps working visually (though it'll get phigital chrome) until
/// it's migrated.
class PickOrgMembersSheet extends StatelessWidget {
  final List<EthereumAddress>? existingMemberAddresses;

  const PickOrgMembersSheet({
    super.key,
    this.existingMemberAddresses,
  });

  @override
  Widget build(BuildContext context) {
    return _PickOrgMembersSheet(
      existingMemberAddresses: existingMemberAddresses,
      includeChrome: false,
    );
  }
}

class _PickOrgMembersSheet extends StatefulWidget {
  final List<EthereumAddress>? existingMemberAddresses;
  /// When false, skip the surfaceDeep container + handle + header (used by
  /// the legacy `PickOrgMembersSheet` shim so it doesn't double-wrap chrome
  /// when hosted inside an external sheet).
  final bool includeChrome;

  const _PickOrgMembersSheet({
    this.existingMemberAddresses,
    this.includeChrome = true,
  });

  @override
  State<_PickOrgMembersSheet> createState() => _PickOrgMembersSheetState();
}

class _PickOrgMembersSheetState extends State<_PickOrgMembersSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<Contact> _availableContacts = const [];
  final Set<EthereumAddress> _selected = <EthereumAddress>{};
  bool _isLoading = true;
  int _gridSize = kDefaultGridSize;
  TextSizeOption _textSize = kDefaultTextSize;

  // Memoized filter — recompute only when source / query / selection changes.
  List<Contact>? _cachedFiltered;
  List<Contact>? _filteredKeySource;
  String _filteredKeyQuery = '';
  int _filteredKeySelectionLen = -1;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadSettings();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        PublicOSSettings.getSetting('explorer_grid_size'),
        loadStoredTextSize(),
      ]);
      if (!mounted) return;
      setState(() {
        _gridSize = int.tryParse((results[0] as Record?)?.value ?? '') ??
            kDefaultGridSize;
        _textSize = (results[1] as TextSizeOption?) ?? kDefaultTextSize;
      });
    } catch (_) {
      // Silent — defaults stand.
    }
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final stored = await PublicOSContacts.getStoredContacts();
      final me = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
      final existing = widget.existingMemberAddresses != null
          ? widget.existingMemberAddresses!
              .map((addr) => addr.eip55With0x.toLowerCase())
              .toSet()
          : <String>{};

      // Filter out: zero address, current user, org accounts, existing members.
      final pool = stored.where((c) {
        final addr = c.publicosAddress;
        if (addr == null) return false;
        final eip55 = addr.eip55With0x;
        if (eip55 == '0x0000000000000000000000000000000000000000') return false;
        if (me != null && eip55 == me) return false;
        if (c.isOrgAccount) return false;
        if (existing.contains(eip55.toLowerCase())) return false;
        return true;
      }).toList();

      if (!mounted) return;
      setState(() {
        _availableContacts = pool;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableContacts = const [];
        _isLoading = false;
      });
    }
  }

  List<Contact> get _filteredContacts {
    final query = _searchController.text.toLowerCase();
    if (_cachedFiltered != null &&
        identical(_filteredKeySource, _availableContacts) &&
        _filteredKeyQuery == query &&
        _filteredKeySelectionLen == _selected.length) {
      return _cachedFiltered!;
    }
    final list = _availableContacts.where((c) {
      if (query.isEmpty) return true;
      return c.displayName.toLowerCase().contains(query) ||
          c.publicosDisplayName?.toLowerCase().contains(query) == true ||
          c.publicosAddress?.eip55With0x.toLowerCase().contains(query) == true;
    }).toList();
    _cachedFiltered = list;
    _filteredKeySource = _availableContacts;
    _filteredKeyQuery = query;
    _filteredKeySelectionLen = _selected.length;
    return list;
  }

  void _toggle(Contact contact) {
    final addr = contact.publicosAddress;
    if (addr == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(addr)) {
        _selected.remove(addr);
      } else {
        _selected.add(addr);
      }
    });
  }

  void _confirm() {
    if (_selected.isEmpty) return;
    final picked = _availableContacts
        .where((c) => c.publicosAddress != null && _selected.contains(c.publicosAddress))
        .toList();
    Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    if (!widget.includeChrome) {
      // Legacy embed — no chrome, no draggable scroller.
      return _buildBody(tokens, scrollCtrl: null);
    }

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _Header(
                tokens: tokens,
                title: context.l10n.pickOrgMembersSheetTitle,
                subtitle: _selected.isEmpty
                    ? context.l10n.pickOrgMembersSheetSubtitleEmpty
                    : context.l10n
                        .pickOrgMembersSheetSubtitleSelected(_selected.length),
                onClose: () => Navigator.pop(context),
              ),
              Expanded(child: _buildBody(tokens, scrollCtrl: scrollCtrl)),
              if (_selected.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SystemAppActionButton(
                      label: context.l10n
                          .pickOrgMembersSheetAddButton(_selected.length),
                      icon: Icons.person_add_alt_rounded,
                      onTap: _confirm,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(GlassTokens tokens, {required ScrollController? scrollCtrl}) {
    if (_isLoading) {
      return const Center(child: PhigitalLoadingWidget(size: 32));
    }

    final filtered = _filteredContacts;
    final hasQuery = _searchController.text.isNotEmpty;

    return CustomScrollView(
      controller: scrollCtrl,
      slivers: [
        SliverToBoxAdapter(
          child: RepaintBoundary(
            child: _SearchField(
              controller: _searchController,
              tokens: tokens,
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  hasQuery
                      ? context.l10n.pickOrgMembersSheetNoMatch
                      : context.l10n.pickOrgMembersSheetNoContacts,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, sliverConstraints) {
                // Canonical tile geometry — one definition, shared with the
                // Apps and Contacts grids. See [GridGeom].
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
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    final isSelected = c.publicosAddress != null &&
                        _selected.contains(c.publicosAddress);
                    return _PickTile(
                      key: ValueKey(
                        c.publicosAddress?.eip55With0x ?? c.displayName,
                      ),
                      contact: c,
                      iconSize: geom.iconSize,
                      fontSize: geom.fontSize,
                      lineHeight: GridGeom.lineHeight,
                      iconToText: GridGeom.iconToText,
                      textBlockH: geom.textBlockH,
                      isSelected: isSelected,
                      onTap: () => _toggle(c),
                      tokens: tokens,
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Grid tile — copies the explorer's `_ContactTile` math + perf shape (the
/// canonical grid pattern). Adds a selection ring/check overlay so picking
/// reads at a glance.
class _PickTile extends StatefulWidget {
  final Contact contact;
  final double iconSize;
  final double fontSize;
  final double lineHeight;
  final double iconToText;
  final double textBlockH;
  final bool isSelected;
  final VoidCallback onTap;
  final GlassTokens tokens;

  const _PickTile({
    super.key,
    required this.contact,
    required this.iconSize,
    required this.fontSize,
    required this.lineHeight,
    required this.iconToText,
    required this.textBlockH,
    required this.isSelected,
    required this.onTap,
    required this.tokens,
  });

  @override
  State<_PickTile> createState() => _PickTileState();
}

class _PickTileState extends State<_PickTile> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // load-bearing — wires up keep-alive
    final ringColor = widget.isSelected
        ? widget.tokens.connectedAccent
        : Colors.transparent;
    final checkSize = (widget.iconSize * 0.32).clamp(16.0, 22.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: widget.iconSize,
            height: widget.iconSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Selection ring sits as a slightly larger transparent
                // wrapper so it doesn't compete with GlassContactIcon's
                // own internal border.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: GlassContactIcon(
                      contact: widget.contact,
                      size: widget.iconSize - 4,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: checkSize,
                      height: checkSize,
                      decoration: BoxDecoration(
                        color: widget.tokens.connectedAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.tokens.surfaceDeep, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: checkSize * 0.6,
                        color: widget.tokens.surfaceDeep,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: widget.iconToText),
          SizedBox(
            height: widget.textBlockH,
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
                  color: widget.isSelected
                      ? widget.tokens.starkWhite
                      : widget.tokens.starkWhite,
                  fontSize: widget.fontSize,
                  fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                  height: widget.lineHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final GlassTokens tokens;

  const _SearchField({required this.controller, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          border: Border.all(color: tokens.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontSize: 14,
          ),
          cursorColor: tokens.starkWhite,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: tokens.textDim,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(Icons.close_rounded, color: tokens.textDim, size: 18),
                  onPressed: () => controller.clear(),
                );
              },
            ),
            hintText: context.l10n.pickOrgMembersSheetSearchHint,
            hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 14,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _Header({
    required this.tokens,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(
              Icons.person_add_alt_rounded,
              color: tokens.connectedAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
