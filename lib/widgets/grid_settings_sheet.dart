import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/discover_contact_row.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Core setting keys — shared across clients so the same stored values
/// round-trip between devices signed into the same account.
const String _gridSizeKey = 'explorer_grid_size';
const String _textSizeKey = 'explorer_text_size';

/// Contacts-only setting keys. Persisted under a separate namespace so the
/// shared grid/text values stay in sync across Apps + Contacts while the
/// Contacts-specific options (layout, banner) stay local to the Contacts tab.
const String _contactsLayoutKey = 'contacts_layout';
const String _contactsShowBannerKey = 'contacts_show_contact_banner';

/// Read the stored grid size. Returns null on any failure — caller falls
/// back to its own default.
Future<int?> loadStoredGridSize() async {
  try {
    final record = await PublicOSSettings.getSetting(_gridSizeKey);
    if (record == null) return null;
    return int.tryParse(record.value);
  } catch (_) {
    return null;
  }
}

/// Read the stored text size. Returns null on any failure; callers fall
/// back to [TextSizeOption.m].
Future<TextSizeOption?> loadStoredTextSize() async {
  try {
    final record = await PublicOSSettings.getSetting(_textSizeKey);
    if (record == null) return null;
    return TextSizeOption.values.firstWhere(
      (o) => o.name == record.value,
      orElse: () => TextSizeOption.m,
    );
  } catch (_) {
    return null;
  }
}

/// Read the stored Contacts layout. Returns null on any failure; callers
/// fall back to [ContactsLayout.rows].
Future<ContactsLayout?> loadStoredContactsLayout() async {
  try {
    final record = await PublicOSSettings.getSetting(_contactsLayoutKey);
    if (record == null) return null;
    return ContactsLayout.values.firstWhere(
      (o) => o.name == record.value,
      orElse: () => ContactsLayout.rows,
    );
  } catch (_) {
    return null;
  }
}

/// Read the stored Contacts "show banner" preference. Returns null on any
/// failure; callers default to true (banners visible).
Future<bool?> loadStoredContactsShowBanner() async {
  try {
    final record = await PublicOSSettings.getSetting(_contactsShowBannerKey);
    if (record == null) return null;
    return record.value != 'false';
  } catch (_) {
    return null;
  }
}

/// 5-step text size scale. Drives the tile body font in the Apps + Contacts
/// grids. Shared by both tabs so the Settings chip opens the same sheet.
enum TextSizeOption {
  xs('XS', 10),
  s('S', 12),
  m('M', 14),
  l('L', 16),
  xl('XL', 18);

  /// Short label shown above the slider steps.
  final String label;

  /// Resolved font size in logical pixels.
  final double fontSize;

  const TextSizeOption(this.label, this.fontSize);
}

/// First-run defaults for the shared Explorer grid. Every surface that renders
/// the tile grid (Apps, Contacts, the org member picker, the send sheet) starts
/// here, so the tabs cannot drift apart the way they did when each held its own
/// literal. Superseded the moment the user stores their own values under
/// `explorer_grid_size` / `explorer_text_size`.
const int kDefaultGridSize = 5;
const TextSizeOption kDefaultTextSize = TextSizeOption.s;

/// Canonical tile geometry for the shared contact / app grid.
///
/// The tile has no fixed size: its height falls out of the viewport width,
/// the column count and the chosen label font. Every surface that renders the
/// grid (Apps, Contacts, the org member picker) computes it from here, so the
/// tabs stay visually identical — the proportions are defined once, the way
/// [kDefaultGridSize] / [kDefaultTextSize] define the defaults once.
///
/// Do NOT use `childAspectRatio` with this: the height is exact and goes in
/// as `mainAxisExtent`.
class GridGeom {
  /// Gap between tiles, both axes.
  static const double gap = 12.0;

  /// Label line-height multiplier. The label block is always exactly two
  /// lines tall, so short and long names occupy the same box.
  static const double lineHeight = 1.25;

  /// Vertical gap between the icon and the first label line.
  static const double iconToText = 8.0;

  /// Extra room under the second line — SpaceGrotesk paints below the line
  /// box, so without it a wrapped name loses its descenders.
  static const double descenderBuffer = 4.0;

  final double iconSize;
  final double fontSize;
  final double textBlockH;
  final double tileH;

  const GridGeom({
    required this.iconSize,
    required this.fontSize,
    required this.textBlockH,
    required this.tileH,
  });

  /// Compute from the width available to the whole grid —
  /// `SliverConstraints.crossAxisExtent` or `BoxConstraints.maxWidth`.
  factory GridGeom.forWidth(
    double crossAxisExtent,
    int cols,
    TextSizeOption textSize,
  ) {
    final tileW = (crossAxisExtent - gap * (cols - 1)) / cols;
    final iconSize = (tileW * 0.72).clamp(36.0, 96.0);
    final fontSize = textSize.fontSize;
    final textBlockH = fontSize * lineHeight * 2 + descenderBuffer;
    return GridGeom(
      iconSize: iconSize,
      fontSize: fontSize,
      textBlockH: textBlockH,
      tileH: iconSize + iconToText + textBlockH,
    );
  }
}

/// Contacts tab layout — `grid` = the existing tile grid (avatars + names),
/// `rows` = the feeds-style `DiscoverContactRow` (full-bleed banner + avatar
/// + name + bio + capability hints).
enum ContactsLayout { grid, rows }

/// Glass bottom sheet with grid size + text size, plus optional Contacts-only
/// sections (layout, banner toggle, live preview). The Apps tab opens this
/// without the Contacts flags; the Contacts tab opens it with them.
///
/// Grid size + text size persist under shared `explorer_grid_size` /
/// `explorer_text_size` keys (kept in sync across Apps + Contacts). The
/// Contacts-only layout + banner persist under their own keys.
Future<void> showGridSettingsSheet(
  BuildContext context, {
  required int currentGridSize,
  required TextSizeOption currentTextSize,
  required ValueChanged<int> onGridSizeChanged,
  required ValueChanged<TextSizeOption> onTextSizeChanged,
  bool showLayoutToggle = false,
  ContactsLayout currentLayout = ContactsLayout.grid,
  ValueChanged<ContactsLayout>? onLayoutChanged,
  bool showBannerToggle = false,
  bool currentShowBanner = true,
  ValueChanged<bool>? onShowBannerChanged,
  bool showContactPreview = false,
  String? previewContactAddress,
}) {
  return showGlassSheetDialog(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _GridSettingsSheet(
      currentGridSize: currentGridSize,
      currentTextSize: currentTextSize,
      onGridSizeChanged: onGridSizeChanged,
      onTextSizeChanged: onTextSizeChanged,
      showLayoutToggle: showLayoutToggle,
      currentLayout: currentLayout,
      onLayoutChanged: onLayoutChanged,
      showBannerToggle: showBannerToggle,
      currentShowBanner: currentShowBanner,
      onShowBannerChanged: onShowBannerChanged,
      showContactPreview: showContactPreview,
      previewContactAddress: previewContactAddress,
    ),
  );
}

class _GridSettingsSheet extends StatefulWidget {
  final int currentGridSize;
  final TextSizeOption currentTextSize;
  final ValueChanged<int> onGridSizeChanged;
  final ValueChanged<TextSizeOption> onTextSizeChanged;
  final bool showLayoutToggle;
  final ContactsLayout currentLayout;
  final ValueChanged<ContactsLayout>? onLayoutChanged;
  final bool showBannerToggle;
  final bool currentShowBanner;
  final ValueChanged<bool>? onShowBannerChanged;
  final bool showContactPreview;
  final String? previewContactAddress;

  const _GridSettingsSheet({
    required this.currentGridSize,
    required this.currentTextSize,
    required this.onGridSizeChanged,
    required this.onTextSizeChanged,
    required this.showLayoutToggle,
    required this.currentLayout,
    required this.onLayoutChanged,
    required this.showBannerToggle,
    required this.currentShowBanner,
    required this.onShowBannerChanged,
    required this.showContactPreview,
    required this.previewContactAddress,
  });

  @override
  State<_GridSettingsSheet> createState() => _GridSettingsSheetState();
}

/// Allowed grid column counts — slider snaps to these.
const List<int> _gridSizeValues = [2, 3, 4, 5, 6];

class _GridSettingsSheetState extends State<_GridSettingsSheet> {
  late int _gridSize = widget.currentGridSize;
  late TextSizeOption _textSize = widget.currentTextSize;
  late ContactsLayout _layout = widget.currentLayout;
  late bool _showBanner = widget.currentShowBanner;

  Future<void> _saveGridSize(int size) async {
    try {
      final record = Record.asSettings(
        key: _gridSizeKey,
        value: size.toString(),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_gridSizeKey, record);
    } catch (_) {}
  }

  Future<void> _saveTextSize(TextSizeOption size) async {
    try {
      final record = Record.asSettings(
        key: _textSizeKey,
        value: size.name,
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_textSizeKey, record);
    } catch (_) {}
  }

  Future<void> _saveLayout(ContactsLayout layout) async {
    try {
      final record = Record.asSettings(
        key: _contactsLayoutKey,
        value: layout.name,
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_contactsLayoutKey, record);
    } catch (_) {}
  }

  Future<void> _saveShowBanner(bool value) async {
    try {
      final record = Record.asSettings(
        key: _contactsShowBannerKey,
        value: value.toString(),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_contactsShowBannerKey, record);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                child: Row(
                  children: [
                    Text(
                      context.l10n.gridSettingsSheetTitle,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          Icon(Icons.close_rounded, color: tokens.starkWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (widget.showLayoutToggle) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    context.l10n.gridSettingsSheetSectionLayout,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _LayoutSegment(
                    layout: _layout,
                    tokens: tokens,
                    onChanged: (next) {
                      if (next == _layout) return;
                      setState(() => _layout = next);
                      _saveLayout(next);
                      widget.onLayoutChanged?.call(next);
                    },
                  ),
                ),
              ],
              // Grid size (applies to both Apps and Contacts when in grid
              // layout; hidden for Contacts when rows is selected).
              if (_layout == ContactsLayout.grid) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    context.l10n.gridSettingsSheetSectionGridSize,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _gridSizeValues.map((n) {
                      return Text(
                        '$n',
                        style: TextStyle(
                          color: _gridSize == n
                              ? tokens.connectedAccent
                              : tokens.textDim,
                          fontSize: 12,
                          fontWeight: _gridSize == n
                              ? FontWeight.w800
                              : FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: tokens.connectedAccent,
                      inactiveTrackColor:
                          tokens.connectedAccent.withValues(alpha: 0.2),
                      thumbColor: tokens.connectedAccent,
                      overlayColor:
                          tokens.connectedAccent.withValues(alpha: 0.2),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _gridSize
                          .clamp(_gridSizeValues.first, _gridSizeValues.last)
                          .toDouble(),
                      min: _gridSizeValues.first.toDouble(),
                      max: _gridSizeValues.last.toDouble(),
                      divisions: _gridSizeValues.length - 1,
                      onChanged: (v) {
                        final next = v.round();
                        if (next == _gridSize) return;
                        setState(() => _gridSize = next);
                        _saveGridSize(next);
                        widget.onGridSizeChanged(next);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Center(
                    child: Text(
                      context.l10n.gridSettingsSheetColumnCount(_gridSize),
                      style: TextStyle(
                        color: tokens.connectedAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  context.l10n.gridSettingsSheetSectionTextSize,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: TextSizeOption.values
                      .map((o) => Text(
                            o.label,
                            style: TextStyle(
                              color: _textSize == o
                                  ? tokens.connectedAccent
                                  : tokens.textDim,
                              fontSize: 11,
                              fontWeight: _textSize == o
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                          ))
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: tokens.connectedAccent,
                    inactiveTrackColor:
                        tokens.connectedAccent.withValues(alpha: 0.2),
                    thumbColor: tokens.connectedAccent,
                    overlayColor:
                        tokens.connectedAccent.withValues(alpha: 0.2),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: TextSizeOption.values
                        .indexOf(_textSize)
                        .toDouble(),
                    min: 0,
                    max: (TextSizeOption.values.length - 1).toDouble(),
                    divisions: TextSizeOption.values.length - 1,
                    onChanged: (v) {
                      final next = TextSizeOption.values[v.round()];
                      if (next == _textSize) return;
                      setState(() => _textSize = next);
                      _saveTextSize(next);
                      widget.onTextSizeChanged(next);
                    },
                  ),
                ),
              ),
              // Banner toggle — only in rows layout where the banner actually
              // shows (it's the 12%-opacity full-bleed behind each row).
              if (widget.showBannerToggle &&
                  _layout == ContactsLayout.rows) ...[
                const SizedBox(height: 4),
                _ToggleRow(
                  label: context.l10n.gridSettingsSheetShowBannersLabel,
                  subtitle: context.l10n.gridSettingsSheetShowBannersSubtitle,
                  value: _showBanner,
                  tokens: tokens,
                  onChanged: (v) {
                    if (v == _showBanner) return;
                    setState(() => _showBanner = v);
                    _saveShowBanner(v);
                    widget.onShowBannerChanged?.call(v);
                  },
                ),
              ],
              // Preview — only when both the layout toggle and a preview
              // address are wired. Renders the active layout with the
              // hardcoded contact so the user can see the effect live.
              if (widget.showContactPreview &&
                  widget.previewContactAddress != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    context.l10n.gridSettingsSheetSectionPreview,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _ContactPreview(
                    address: widget.previewContactAddress!,
                    layout: _layout,
                    showBanner: _showBanner,
                    textSize: _textSize,
                    tokens: tokens,
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      context.l10n.gridSettingsSheetPreviewText(
                          _textSize.label),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: _textSize.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout segment — two-pill Grid / Rows selector
// ---------------------------------------------------------------------------

class _LayoutSegment extends StatelessWidget {
  final ContactsLayout layout;
  final GlassTokens tokens;
  final ValueChanged<ContactsLayout> onChanged;

  const _LayoutSegment({
    required this.layout,
    required this.tokens,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LayoutSegmentTile(
              icon: Icons.grid_view_rounded,
              label: context.l10n.gridSettingsSheetLayoutGrid,
              active: layout == ContactsLayout.grid,
              tokens: tokens,
              onTap: () => onChanged(ContactsLayout.grid),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _LayoutSegmentTile(
              icon: Icons.view_agenda_rounded,
              label: context.l10n.gridSettingsSheetLayoutRows,
              active: layout == ContactsLayout.rows,
              tokens: tokens,
              onTap: () => onChanged(ContactsLayout.rows),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoutSegmentTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final GlassTokens tokens;
  final VoidCallback onTap;

  const _LayoutSegmentTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? tokens.connectedAccent : tokens.textDim;
    return Material(
      color: active
          ? tokens.connectedAccent.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: color,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner toggle row (matches messages_settings_sheet.dart's _ToggleRow shape)
// ---------------------------------------------------------------------------

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final GlassTokens tokens;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: tokens.connectedAccent,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live preview — resolves a hardcoded Contact (local-first, chain-fallback,
// mirrors `feeds_settings_sheet.dart`'s _PreviewCardState pattern) and
// renders it in the active layout so toggles read live.
// ---------------------------------------------------------------------------

class _ContactPreview extends StatefulWidget {
  final String address;
  final ContactsLayout layout;
  final bool showBanner;
  final TextSizeOption textSize;
  final GlassTokens tokens;

  const _ContactPreview({
    required this.address,
    required this.layout,
    required this.showBanner,
    required this.textSize,
    required this.tokens,
  });

  @override
  State<_ContactPreview> createState() => _ContactPreviewState();
}

class _ContactPreviewState extends State<_ContactPreview> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  /// Local-first, chain-fallback. Mirrors the canonical
  /// `searchContacts → fetchContact → saveContact` ladder used elsewhere
  /// (see `feeds_settings_sheet.dart`'s `_PreviewCardState`). Silent on
  /// failure — placeholder stays.
  Future<void> _resolve() async {
    try {
      final addr = EthereumAddress.fromHex(widget.address);
      var contact = await PublicOSContacts.getContact(addr);
      if (contact == null && PublicOS.web3Connected) {
        try {
          contact = await PublicOSContacts.fetchContact(addr, requireRecords: true);
          await PublicOSContacts.saveContact(contact);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _contact = contact);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final contact = _contact;

    return Container(
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: contact == null
            ? const SizedBox(height: 96)
            : (widget.layout == ContactsLayout.rows
                ? DiscoverContactRow(
                    contact: contact,
                    showBanner: widget.showBanner,
                    showChevron: false,
                    onTap: null,
                  )
                : _GridTilePreview(
                    contact: contact,
                    textSize: widget.textSize,
                    tokens: tokens,
                  )),
      ),
    );
  }
}

/// Single grid tile rendered to match `contacts_view.dart`'s `_ContactTile`
/// shape (avatar + 2-line name). Sized for the preview frame, not the live
/// grid — the live grid sizes from the column count.
class _GridTilePreview extends StatelessWidget {
  final Contact contact;
  final TextSizeOption textSize;
  final GlassTokens tokens;

  const _GridTilePreview({
    required this.contact,
    required this.textSize,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    const iconSize = 72.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContactIcon(contact: contact, size: iconSize),
          const SizedBox(height: 8),
          Text(
            contact.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: textSize.fontSize,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
