import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Overlapping mini avatars: the org Management **Members** tile, and a
/// channel header's **Writers**. Its sibling `ContactStack` (fade + `+N`) is
/// to be merged with it later.
///
/// Static stack of up to 6 randomly-picked contacts. If the source list has
/// more than 6, a "+N" tile is appended at the end. No scroll, no fade —
/// every tile renders at full opacity. The random pick is taken once and
/// reused across rebuilds (re-shuffled only when the source list changes).
class MembersStack extends StatefulWidget {
  final GlassTokens tokens;
  final List<Contact> contacts;
  final VoidCallback onTap;

  /// Multiplies every size and stride. 1 = the Members tile (36 px lead);
  /// a channel header's credits line uses a smaller one.
  final double scale;

  /// Take only the stack's own width instead of centring it in all the width
  /// offered. Needed inside a `Wrap` / inline row (a channel header's credits
  /// line); the Members tile leaves it off and stays centred in its slot.
  final bool shrinkWrap;

  /// Wraps each tile (index 0 = leftmost), e.g. to move the tiles one by
  /// one. The feeds header's fly-in uses it (`ListMiniStackFlyIn`).
  final Widget Function(int index, Widget tile)? tileWrap;

  /// How many tiles a stack of [contacts] people draws ("+N" tile included).
  static int tileCount(int contacts) =>
      contacts > _maxVisible ? _maxVisible + 1 : contacts;

  static const _maxVisible = 6;
  static const _itemSize = 36.0;
  // Fixed per-index sizes (leftmost = index 0). Index ≥ list length clamps
  // to the last entry.
  static const List<double> _tileSizes = [36, 34, 32, 30, 28, 26, 24];
  // Fixed per-index strides — gap from tile i to tile i+1, leftmost gap
  // first. Strides narrow toward the right so overlap *grows* across the
  // row instead of shrinking: gaps 24/20/16/12/9/7 vs sizes above →
  // overlaps 12/14/16/18/19/19. Index ≥ list length clamps to last entry.
  static const List<double> _tileStrides = [24, 20, 16, 12, 9, 7];

  const MembersStack({
    super.key,
    required this.tokens,
    required this.contacts,
    required this.onTap,
    this.scale = 1.0,
    this.shrinkWrap = false,
    this.tileWrap,
  });

  @override
  State<MembersStack> createState() => _MembersStackState();
}

class _MembersStackState extends State<MembersStack> {
  late List<Contact> _picked;

  @override
  void initState() {
    super.initState();
    _picked = _pickFrom(widget.contacts);
  }

  @override
  void didUpdateWidget(MembersStack old) {
    super.didUpdateWidget(old);
    if (!_sameSet(old.contacts, widget.contacts)) {
      _picked = _pickFrom(widget.contacts);
    }
  }

  static List<Contact> _pickFrom(List<Contact> src) {
    final copy = List<Contact>.from(src)..shuffle();
    return copy.take(MembersStack._maxVisible).toList();
  }

  static bool _sameSet(List<Contact> a, List<Contact> b) {
    if (a.length != b.length) return false;
    String key(Contact c) =>
        c.publicosAddress?.eip55With0x.toLowerCase() ?? c.displayName;
    final as = a.map(key).toSet();
    final bs = b.map(key).toSet();
    return as.length == bs.length && as.containsAll(bs);
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.contacts.length > MembersStack._maxVisible;
    final itemCount = _picked.length + (hasMore ? 1 : 0);
    if (itemCount == 0) {
      return SizedBox(height: MembersStack._itemSize * widget.scale);
    }
    // Cumulative left positions: tile i sits at sum of strides[0..i-1].
    final lefts = List<double>.filled(itemCount, 0);
    for (var i = 1; i < itemCount; i++) {
      const strides = MembersStack._tileStrides;
      final step = strides[(i - 1) < strides.length
          ? (i - 1)
          : strides.length - 1];
      lefts[i] = lefts[i - 1] + step * widget.scale;
    }
    final lastSize = _sizeFor(itemCount - 1);
    final innerWidth = lefts[itemCount - 1] + lastSize;

    // Right-to-left build order: leftmost tile renders last so it stays
    // frontmost in the stack.
    final tiles = <Widget>[
      for (var i = itemCount - 1; i >= 0; i--)
        _buildTile(i, lefts[i], hasMore),
    ];

    return SizedBox(
      height: MembersStack._itemSize * widget.scale,
      child: Align(
        alignment: Alignment.center,
        widthFactor: widget.shrinkWrap ? 1.0 : null,
        child: SizedBox(
          width: innerWidth,
          height: MembersStack._itemSize * widget.scale,
          child: Stack(clipBehavior: Clip.none, children: tiles),
        ),
      ),
    );
  }

  double _sizeFor(int i) {
    const sizes = MembersStack._tileSizes;
    return sizes[i < sizes.length ? i : sizes.length - 1] * widget.scale;
  }

  Widget _buildTile(int i, double leftPx, bool hasMore) {
    final scaledSize = _sizeFor(i);
    final isPlus = hasMore && i == _picked.length;
    final Widget tile = Center(
      child: _StackTile(
        tokens: widget.tokens,
        size: scaledSize,
        contact: isPlus ? null : _picked[i],
        isPlus: isPlus,
        onTap: widget.onTap,
      ),
    );
    return Positioned(
      left: leftPx,
      top: 0,
      bottom: 0,
      child: widget.tileWrap?.call(i, tile) ?? tile,
    );
  }
}

class _StackTile extends StatelessWidget {
  final GlassTokens tokens;
  final double size;
  final Contact? contact;
  final bool isPlus;
  final VoidCallback onTap;

  const _StackTile({
    required this.tokens,
    required this.size,
    required this.contact,
    required this.isPlus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Match GlassContactIcon's radius ratio (14/44) so the + tile is the
    // same rounded-square shape as the contact dots next to it.
    final radius = size * (14 / 44);

    final inner = isPlus
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: tokens.borderMedium),
            ),
            child: Icon(
              Icons.add_rounded,
              // + glyph uses the same color as the border so the tile reads
              // as a single graphic instead of a green CTA.
              color: tokens.borderMedium,
              size: size * 0.5,
            ),
          )
        : SizedBox(
            width: size,
            height: size,
            child: GlassContactIcon(contact: contact!, size: size),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: inner,
      ),
    );
  }
}
