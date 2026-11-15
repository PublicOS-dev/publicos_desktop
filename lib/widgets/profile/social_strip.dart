import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'record_button.dart';
import '../../theme/glass_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

const socialBrandColors = <String, Color>{
  'com.twitter': Color(0xFF1d9bf0),
  'com.instagram': Color(0xFFe4405f),
  'com.github': Color(0xFF8b949e),
  'app.bsky': Color(0xFF0085ff),
  'com.linkedin': Color(0xFF0a66c2),
  'com.discord': Color(0xFF5865f2),
  'org.telegram': Color(0xFF26a5e4),
  'com.reddit': Color(0xFFff4500),
  'com.youtube': Color(0xFFff0000),
  'xyz.farcaster': Color(0xFF8a63d2),
  'url': Color(0xFF64748b),
  'email': Color(0xFF64748b),
};

class SocialStrip extends StatefulWidget {
  final List<Record> records;
  final Record? previewRecord;
  final bool isEditMode;
  final bool richMode;
  final VoidCallback? onAddSocial;
  final ValueChanged<Record>? onEditSocial;
  final ValueChanged<Record>? onDeleteSocial;
  final ValueChanged<bool>? onRichModeChanged;

  const SocialStrip({
    super.key,
    required this.records,
    this.previewRecord,
    this.isEditMode = false,
    this.richMode = false,
    this.onAddSocial,
    this.onEditSocial,
    this.onDeleteSocial,
    this.onRichModeChanged,
  });

  @override
  State<SocialStrip> createState() => _SocialStripState();
}

class _SocialStripState extends State<SocialStrip>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.previewRecord != null) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant SocialStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.previewRecord != null && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.previewRecord == null && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<Record> get _allRecords {
    final list = List<Record>.from(widget.records);
    if (widget.previewRecord != null) {
      // If editing an existing record, replace it in-place instead of appending
      final existingIdx = list.indexWhere(
        (r) => r.key == widget.previewRecord!.key,
      );
      if (existingIdx >= 0) {
        list[existingIdx] = widget.previewRecord!;
      } else {
        list.add(widget.previewRecord!);
      }
    }
    return list;
  }

  bool _isPreview(Record record) =>
      widget.previewRecord != null && identical(record, widget.previewRecord);

  Future<void> _launchLink(BuildContext context, Record record) async {
    if (record.link == null) return;
    final uri = Uri.parse(record.link!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.socialStripCouldNotLaunch(record.link!)),
          behavior: SnackBarBehavior.fixed,
        ),
      );
    }
  }

  Color _brandColor(String key) =>
      socialBrandColors[key] ?? const Color(0xFF64748b);

  @override
  Widget build(BuildContext context) {
    final all = _allRecords;
    if (all.isEmpty && !widget.isEditMode) return const SizedBox.shrink();

    final tokens = GlassTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // No horizontal inset (mirrors publicos_client): the host
        // page owns the gutter, so the first icon / mini card lands on it.
        widget.richMode
            ? _buildRichGrid(tokens, all)
            : _buildIconRow(tokens, all),
      ],
    );
  }

  /// The bare slide switch (icon ↔ rich). Shared by the icon-mode toggle tile
  /// and the rich-mode toggle card.
  Widget _buildSwitch(GlassTokens tokens) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 32,
      height: 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        color: widget.richMode
            ? tokens.connectedAccent
            : tokens.surfaceElevated,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: widget.richMode
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Icon-mode mode-toggle: a tile matching the icon/add tiles, with just the
  /// switch inside (no labels — too narrow at 36px). Sits after the add tile.
  Widget _buildToggleTile(GlassTokens tokens) {
    return GestureDetector(
      onTap: () => widget.onRichModeChanged?.call(!widget.richMode),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderMedium, width: 1.5),
        ),
        child: Center(child: _buildSwitch(tokens)),
      ),
    );
  }

  /// Rich-mode mode-toggle: a card matching the add card, with the switch
  /// flanked by `Icon` / `Rich` titles; the active side's label is brightened
  /// so it doubles as the state indicator. Sits after the add card.
  Widget _buildToggleRichCard(GlassTokens tokens) {
    TextStyle label(bool active) => TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: 11,
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      color: active ? tokens.starkWhite : tokens.textDim,
    );
    return GestureDetector(
      onTap: () => widget.onRichModeChanged?.call(!widget.richMode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderMedium, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Icon', style: label(!widget.richMode)),
            const SizedBox(width: 6),
            _buildSwitch(tokens),
            const SizedBox(width: 6),
            Text('Rich', style: label(widget.richMode)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconRow(GlassTokens tokens, List<Record> all) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...all.map((r) => _buildIconTile(tokens, r)),
        if (widget.isEditMode && widget.onAddSocial != null)
          _buildAddTile(tokens),
        if (widget.isEditMode && widget.onRichModeChanged != null)
          _buildToggleTile(tokens),
      ],
    );
  }

  Widget _buildAddTile(GlassTokens tokens) {
    return GestureDetector(
      onTap: widget.onAddSocial,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderMedium, width: 1.5),
        ),
        child: Center(
          child: Icon(Icons.add_rounded, size: 18, color: tokens.starkWhite),
        ),
      ),
    );
  }

  Widget _buildIconTile(GlassTokens tokens, Record record) {
    final color = _brandColor(record.key);
    final icon = socialGlyphForRecord(record, size: 18, color: Colors.white);
    final isPreview = _isPreview(record);
    final isEdit = widget.isEditMode && !isPreview;

    final VoidCallback? tileOnTap = isEdit
        ? () => widget.onEditSocial?.call(record)
        : (record.link != null ? () => _launchLink(context, record) : null);

    // Desktop delta: GestureDetector doesn't change the pointer — claim the click
    // cursor only when the tile actually opens something.
    Widget tile = MouseRegion(
      cursor: tileOnTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: tileOnTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child:
                icon ??
                const Icon(
                  Icons.language_rounded,
                  size: 18,
                  color: Colors.white,
                ),
          ),
        ),
      ),
    );

    if (isPreview) {
      tile = _wrapWithPulse(tile, tokens, borderRadius: 10);
    }

    if (isEdit && widget.onDeleteSocial != null) {
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => widget.onDeleteSocial!(record),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return tile;
  }

  /// Rich mode: two columns of link rows.
  ///
  /// **Chromeless**: no outer container, no background colour. A rich row is
  /// the brand tile plus its two lines sitting directly on the profile, so
  /// the only filled shape in the block is the brand colour itself. Two
  /// consequences worth keeping: the rows carry no horizontal padding of their
  /// own, which is what lines their icons up with the bio and the card grid on
  /// the shared profile gutter; and the spacings below do the separating work
  /// borders would, so they are wider than a bordered grid would need.
  ///
  /// The **add** and **mode-toggle** cells deliberately KEEP their chrome --
  /// they are controls, not content, and an unbordered button in edit mode
  /// reads as a link that does nothing.
  Widget _buildRichGrid(GlassTokens tokens, List<Record> all) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 10,
      childAspectRatio: 3.1,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ...all.map((r) => _buildRichCard(tokens, r)),
        if (widget.isEditMode && widget.onAddSocial != null)
          _buildAddRichCard(tokens),
        if (widget.isEditMode && widget.onRichModeChanged != null)
          _buildToggleRichCard(tokens),
      ],
    );
  }

  Widget _buildAddRichCard(GlassTokens tokens) {
    return GestureDetector(
      onTap: widget.onAddSocial,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderMedium, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 16, color: tokens.starkWhite),
            const SizedBox(width: 4),
            Text(
              context.l10n.socialStripAdd,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tokens.starkWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichCard(GlassTokens tokens, Record record) {
    final color = _brandColor(record.key);
    final icon = socialGlyphForRecord(record, size: 18, color: Colors.white);
    final platformName = socialDisplayName(record.key);
    final isPreview = _isPreview(record);
    final isEdit = widget.isEditMode && !isPreview;

    Widget card = GestureDetector(
      // Opaque: with the plate gone the row is mostly empty space, and a
      // hit-test that only lands on the glyph or the glyphs of the text would
      // make a link that visibly spans the cell feel broken.
      behavior: HitTestBehavior.opaque,
      onTap: isEdit
          ? () => widget.onEditSocial?.call(record)
          : (record.link != null ? () => _launchLink(context, record) : null),
      // No plate and no border: the row is content, so it sits on the
      // profile the way the bio and the cards do. `behavior: opaque` on the
      // GestureDetector above is what keeps the whole cell tappable now that
      // there is no filled box to catch the press.
      child: SizedBox(
        height: double.infinity,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Center(
                child:
                    icon ??
                    const Icon(
                      Icons.language_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platformName,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    record.value,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 11.5,
                      color: tokens.textDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (isPreview) {
      card = _wrapWithPulse(card, tokens, borderRadius: 10);
    }

    if (isEdit && widget.onDeleteSocial != null) {
      card = Stack(
        clipBehavior: Clip.none,
        children: [
          card,
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: () => widget.onDeleteSocial!(record),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }

  Widget _wrapWithPulse(
    Widget child,
    GlassTokens tokens, {
    required double borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final glowOpacity = _pulseAnimation.value * 0.7;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius + 2),
            boxShadow: [
              BoxShadow(
                color: tokens.connectedAccent.withValues(alpha: glowOpacity),
                blurRadius: 6 + (_pulseAnimation.value * 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius + 1),
              border: Border.all(
                color: tokens.connectedAccent.withValues(
                  alpha: 0.4 + (glowOpacity * 0.6),
                ),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}
