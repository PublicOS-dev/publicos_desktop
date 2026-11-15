import 'dart:async';
import 'dart:math' as math;
import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/data/shell_prefs.dart';
import 'record_button.dart';
import 'profile_post_card.dart';
import '../../theme/theme_provider.dart';

/// Single source of truth for the profile-grid layout math. Any surface that
/// wants to render a card at the exact size it will have in the grid — the
/// edit-sheet preview, for example — should derive its dimensions from here
/// instead of hardcoding a cell size.
class ProfileGridGeometry {
  static const double spacing = 4;
  static const int columns = 4;

  static double cellWidth(double gridWidth) =>
      (gridWidth - spacing * (columns - 1)) / columns;

  static Size cardSize(double gridWidth, int width, int height) {
    final cw = cellWidth(gridWidth);
    return Size(
      cw * width + spacing * (width - 1),
      cw * height + spacing * (height - 1),
    );
  }
}

class ProfileGrid extends StatefulWidget {
  final List<Record> records;
  final Record? previewRecord;
  final Function(Record)? onRecordTap;
  final Function(Record)? onRecordDeleted;
  final bool isEditable;
  final bool isEditMode;
  final VoidCallback? onAddTap;

  /// Drag-reorder callback. Fires when the user
  /// drags a card onto another ([_wrapDraggable] — a plain mouse drag here,
  /// long-press in the client): [newOrder] is the full linear card
  /// order after the move, [moved] is the dragged card. The host computes the
  /// new rank (single move) or bakes the whole list (legacy/mixed profile) and
  /// persists. Null disables drag. Only wired in edit mode.
  ///
  /// **Awaited, and the future must not complete until the host's reload has
  /// finished.** The grid holds the previewed layout frozen for exactly that
  /// long — see [_ProfileGridState._frozenOrder]. A `void` callback would
  /// unfreeze on the next frame and the cards would snap back mid-write.
  final Future<void> Function(List<Record> newOrder, Record moved)? onReorder;

  /// Set the viewer's avatar from an NFT card's info dialog. Forwarded to each
  /// [RecordButton]; null hides the "use as avatar" action.
  final Future<bool> Function(NftAvatarRef ref)? onUseNftAsAvatar;

  /// The profile these records belong to — the NFT card's verified owner.
  /// Forwarded to the card's info dialog for the "owned by" mini avatar.
  final Contact? nftOwner;

  const ProfileGrid({
    super.key,
    required this.records,
    this.previewRecord,
    this.onRecordTap,
    this.onRecordDeleted,
    required this.isEditable,
    required this.isEditMode,
    this.onAddTap,
    this.onReorder,
    this.onUseNftAsAvatar,
    this.nftOwner,
  });

  @override
  State<ProfileGrid> createState() => _ProfileGridState();
}

/// How long a card takes to slide to a new slot. Every repack animates —
/// drag preview, post-save settle, an edit-sheet preview swapping in.
const Duration _kSettle = Duration(milliseconds: 220);
const Curve _kSettleCurve = Curves.easeOutCubic;

/// How close to the viewport edge the dragged card's centre has to get before
/// the page starts scrolling itself.
///
/// [EdgeDraggingAutoScroller] does not have a proximity threshold — it scrolls
/// only once the rect it is given hangs *past* the viewport edge. So the rect
/// we hand it is not the card: it is a thin probe of this half-height centred
/// on the card, which turns "the finger is near the edge" into the overhang
/// the API is actually looking for. Keeping the probe 1px wide also sidesteps
/// the assert that fires when a drag target is larger than its scrollable —
/// a card has no height ceiling and can legitimately be taller than the screen.
const double _kAutoScrollHotZone = 72;

/// `velocity = overshoot * scalar`. The SDK's own default for reorderable
/// lists (`reorderable_list.dart:611`), kept so this scrolls at the speed the
/// platform's drag-to-reorder does.
const double _kAutoScrollVelocity = 50;

class _ProfileGridState extends State<ProfileGrid> {
  @override
  void initState() {
    super.initState();
    // The autoplay preference lives outside this widget, so the grid has to be
    // told when it moves — otherwise flipping the switch would only take effect
    // on the next unrelated rebuild.
    ShellPrefs.autoplayCards.addListener(_onAutoplayChanged);
    ProfilePostCard.naturalHeights.addListener(_onPostHeights);
  }

  @override
  void dispose() {
    ShellPrefs.autoplayCards.removeListener(_onAutoplayChanged);
    ProfilePostCard.naturalHeights.removeListener(_onPostHeights);
    // A drag torn down mid-flight (navigating away, the profile reloading)
    // would otherwise leave the scroller driving a page this state no longer
    // owns.
    _stopAutoScroll();
    super.dispose();
  }

  void _onAutoplayChanged() {
    if (mounted) setState(_demoted.clear);
  }

  /// Grid box, so a drag's global pointer position can be made local.
  final GlobalKey _gridKey = GlobalKey();

  // ─── Drag preview ────────────────────────────────────────────────────────
  //
  // While a card is in flight the grid repacks live, so the user sees the
  // layout the drop would produce rather than a highlighted target square.
  //
  // The hit-test geometry is FROZEN at drag start (`_dragFrozen`) while the
  // render repacks freely. That split is not an optimisation — it is the only
  // thing that keeps the preview from oscillating. If the pointer resolved
  // against the *previewed* layout, dragging A onto B would slide B out from
  // under the finger, resolve to C, repack, and jitter forever.

  /// The card in flight, or null.
  Record? _dragging;

  /// Its on-screen size, captured at drag start — [_onDragMove] needs it to
  /// turn the feedback widget's top-left into the card's centre.
  Size _dragSize = Size.zero;

  /// The linear card order as it stood at drag start. Every preview is
  /// [_reordered] applied to *this*, never to the previous preview, so the
  /// answer depends only on where the finger is.
  List<Record>? _dragOrder;

  /// The pack of [_dragOrder] — the geometry the pointer hit-tests against.
  _PackResult? _dragFrozen;

  /// Row count at drag start; the box is never allowed to shrink below it
  /// mid-drag.
  int _dragRows = 0;

  /// Where the dragged card would land, as an index into [_dragOrder].
  int? _dragInsertAt;

  /// Scrolls the enclosing page when the dragged card nears a viewport edge.
  /// Without it the page is pinned for the duration of a drag, so on a tall
  /// profile the slots that are off-screen when you pick a card up are the
  /// slots you can never drop it into.
  EdgeDraggingAutoScroller? _autoScroller;

  /// Where inside the card the finger grabbed it, captured once at drag start
  /// by [_wrapDraggable]'s anchor hook. Turns a pointer position back into the
  /// card's own rect.
  Offset _grabOffset = Offset.zero;

  /// The dragged card's centre in GLOBAL coordinates, last seen.
  ///
  /// Kept because auto-scroll moves the page while the finger holds still: no
  /// pointer event fires, but the content slides under it, so the landing slot
  /// genuinely changes. [_resolveFromLastPointer] re-runs off this on every
  /// scroll tick. Without it the cards sit frozen while the page slides past.
  Offset? _lastDragCentre;

  /// The previewed order, held from the drop until the host's save **and
  /// reload** have finished. Nothing is persisted and nothing is written
  /// locally: the cards simply do not move while the chain write is in
  /// flight. If it failed, the reload returns the old order and they animate
  /// back to where they were; if it succeeded, they are already standing
  /// where the reload puts them, so unfreezing is invisible.
  List<Record>? _frozenOrder;

  /// Last pack + cell pitch computed in [build]. Read only by [_onDragStarted],
  /// which needs the geometry the user is *currently looking at* and has no
  /// `LayoutBuilder` constraints of its own to recompute it from.
  _PackResult? _lastPack;
  double _lastCellPitch = 0;

  /// Top of every row (+ one past the last), computed in [build]. Rows are
  /// square except a post card's, so a pointer's row is looked up here, not
  /// divided by the pitch.
  List<double> _lastRowTops = const [];

  void _onPostHeights() {
    if (mounted) setState(() {});
  }

  bool get _dragEnabled =>
      widget.isEditable && widget.isEditMode && widget.onReorder != null;

  /// Cards that have already played their entrance ([ProfileCardPopIn]). The
  /// first build of a profile is one wave — every card is new, so they cascade
  /// in packing order. A card added afterwards is alone in its wave and pops
  /// immediately instead of waiting out a stagger it never belonged to.
  final Set<String> _entered = <String>{};

  /// Desktop resolves `all` from a device-local preference; everything else
  /// is the shared rule. See [LivePolicy] for why the count is a runtime
  /// policy rather than a design assumption.
  LivePolicy get _policy {
    if (widget.isEditMode) return LivePolicy.none;
    return ShellPrefs.autoplayCards.value ? LivePolicy.all : LivePolicy.onTap;
  }

  /// The ONE card promoted under [LivePolicy.onTap], by record key.
  ///
  /// "At most one live at a time" is a fact about the GRID, so a per-card
  /// boolean could not enforce it: promoting one demotes the incumbent for
  /// free, because it is a single field.
  String? _liveCardKey;

  /// Cards individually stopped while the policy is [LivePolicy.all].
  ///
  /// Without this the stop control would be inert in autoplay. A control
  /// that does nothing is worse than no control.
  final Set<String> _demoted = <String>{};

  /// Cards whose live half was promoted and then FAILED to load.
  ///
  /// A runtime failure, not a trust verdict: the walk cleared the URL, the app
  /// simply did not serve it. A Set rather than one key because under
  /// [LivePolicy.all] several can fail independently.
  final Set<String> _liveFailed = <String>{};

  /// Whether this card should be running right now.
  bool _isLive(Record r) {
    if (_liveFailed.contains(r.key)) return false;
    switch (_policy) {
      case LivePolicy.none:
        return false;
      case LivePolicy.all:
        return r.metadata[AppCardMeta.live] != null && !_demoted.contains(r.key);
      case LivePolicy.onTap:
        return _liveCardKey == r.key;
    }
  }

  @override
  void didUpdateWidget(ProfileGrid old) {
    super.didUpdateWidget(old);
    // Entering edit mode demotes everything: a live frame must not be
    // draggable, and the edit affordances sit exactly where the page paints.
    // The policy already returns `none`, so this only clears the bookkeeping.
    if (widget.isEditMode && !old.isEditMode) {
      _liveCardKey = null;
      _demoted.clear();
    }
  }

  void _toggleLive(Record r) {
    setState(() {
      if (_policy == LivePolicy.all) {
        // Everything is live by default here, so the toggle is about stopping.
        _demoted.contains(r.key) ? _demoted.remove(r.key) : _demoted.add(r.key);
      } else {
        _liveCardKey = _liveCardKey == r.key ? null : r.key;
      }
      // A fresh attempt clears the previous failure, or one bad load would
      // poison the card for the rest of the session.
      _liveFailed.remove(r.key);
    });
  }

  void _liveFailed_(Record r) {
    if (!mounted) return;
    setState(() {
      if (_liveCardKey == r.key) _liveCardKey = null; // fall back to the image
      _liveFailed.add(r.key); // ...and say so; the user asked for this
    });
  }

  /// The linear card order the packer reads: ranked records first (by rank),
  /// then unranked in input order. Drag positions are computed against this.
  List<Record> _linearOrder(List<Record> records) {
    final ranked = records.where((r) => r.rank != null).toList()
      ..sort((a, b) => a.rank!.compareTo(b.rank!));
    final unranked = records.where((r) => r.rank == null).toList();
    return [...ranked, ...unranked];
  }

  /// Move [moved] to [targetIndex] in [order].
  ///
  /// **The one reorder function.** The live preview packs its result and the
  /// drop hands the very same list to [ProfileGrid.onReorder]; two functions
  /// here would let the preview promise a layout the save does not produce.
  ///
  /// Dropping *onto a card* is ambiguous about before-or-after; resolving to
  /// an insertion **index** is not, so no "shift toward drop" rule is
  /// needed. Dropping a later
  /// card onto an earlier one lands before it and vice versa,
  /// as a consequence of removing before inserting rather than as a special
  /// case: after `removeAt(from)` an occupant at a *later* index has shifted
  /// down one, so inserting at [targetIndex] lands after it.
  List<Record> _reordered(List<Record> order, Record moved, int targetIndex) {
    final from = order.indexWhere((r) => r.key == moved.key);
    if (from < 0) return order;
    final out = List<Record>.from(order)..removeAt(from);
    out.insert(targetIndex.clamp(0, out.length), moved);
    return out;
  }

  /// Grid-local point → insertion index in [_dragOrder], resolved against the
  /// **frozen** pack.
  ///
  /// [frozen.placements] is in linear order by construction: `_packGrid` walks
  /// the ranked block (rank-sorted) then the unranked block (input order),
  /// which is exactly what [_linearOrder] returns. So a placement's index in
  /// that list *is* its index in the order.
  ///
  /// Returns null for a hole that still has cards after it — the caller then
  /// holds its previous answer rather than thrashing between two readings of
  /// an empty cell.
  int? _insertIndexAt(Offset local, _PackResult frozen, int cols) {
    if (_lastCellPitch <= 0) return null;
    final int col = (local.dx / _lastCellPitch).floor().clamp(0, cols - 1);
    final int row = _rowAt(local.dy);

    for (int i = 0; i < frozen.placements.length; i++) {
      final p = frozen.placements[i];
      if (col >= p.col && col < p.col + p.w &&
          row >= p.row && row < p.row + p.h) {
        return i;
      }
    }
    // Past every card → append. Dragging to the empty tail is a real intent
    // that per-card targets cannot express at all.
    final int lastCell =
        frozen.occupied.isEmpty ? -1 : frozen.occupied.reduce(math.max);
    if (row * cols + col > lastCell) return frozen.placements.length;
    return null;
  }

  /// The row under [dy]: looked up in [_lastRowTops] (a post card's row is
  /// not square); below the grid, whole pitches past its last row, so
  /// dragging to the empty tail still appends.
  int _rowAt(double dy) {
    final tops = _lastRowTops;
    if (dy <= 0) return 0;
    if (tops.length < 2) return (dy / _lastCellPitch).floor();
    final int rows = tops.length - 1;
    if (dy >= tops[rows]) {
      return rows + ((dy - tops[rows]) / _lastCellPitch).floor();
    }
    int row = 0;
    while (row + 1 < rows && dy >= tops[row + 1]) {
      row++;
    }
    return row;
  }

  void _onDragStarted(Record record, Size size) {
    final pack = _lastPack;
    if (pack == null) return;
    // Found by ancestry rather than plumbed: the page's SingleChildScrollView
    // has no controller of its own (`profile_page.dart:821`). Null when the
    // grid is hosted outside a scrollable — drag still works, it just cannot
    // scroll.
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _autoScroller = EdgeDraggingAutoScroller(
        scrollable,
        velocityScalar: _kAutoScrollVelocity,
        onScrollViewScrolled: _resolveFromLastPointer,
      );
    }
    final order = _linearOrder(widget.records);
    int rows = 0;
    for (final p in pack.placements) {
      rows = math.max(rows, p.row + p.h);
    }
    setState(() {
      _dragging = record;
      _dragSize = size;
      _dragOrder = order;
      _dragFrozen = pack;
      _dragRows = rows;
      _dragInsertAt = order.indexWhere((r) => r.key == record.key);
    });
  }

  /// Stops the page scrolling and drops the scroller. Safe to call twice.
  void _stopAutoScroll() {
    _autoScroller?.stopAutoScroll();
    _autoScroller = null;
    _lastDragCentre = null;
  }

  /// Cleared on cancel and on drag end. Guarded because [_onDrop] runs first
  /// and has already taken the state over into [_frozenOrder]; without the
  /// guard the end callback would fire a pointless rebuild on top of it.
  void _clearDrag() {
    if (_dragging == null) return;
    _stopAutoScroll();
    setState(() {
      _dragging = null;
      _dragOrder = null;
      _dragFrozen = null;
      _dragInsertAt = null;
      _dragSize = Size.zero;
    });
  }

  /// Driven by the DRAGGABLE, not by the drop target.
  ///
  /// `DragTarget.onMove` stops firing the moment the card leaves the target's
  /// bounds — which is precisely the gesture this exists to serve. Dragging a
  /// card toward the top of a tall profile takes it off the grid and over the
  /// banner, and a target-driven scroll would cut out exactly then, so the
  /// page could never start moving. `Draggable.onDragUpdate` reports for the
  /// whole drag, wherever the pointer is.
  void _onDragUpdate(DragUpdateDetails d) {
    if (_dragFrozen == null || _dragOrder == null) return;
    // The pointer is not the card. Under `childDragAnchorStrategy` the card
    // keeps the grab offset, so a card grabbed by its corner sits down-right
    // of the finger; [_grabOffset] converts back to the card's CENTRE, which
    // is what the user is aiming and what they see land.
    _lastDragCentre = d.globalPosition -
        _grabOffset +
        Offset(_dragSize.width / 2, _dragSize.height / 2);
    _autoScroller?.startAutoScrollIfNecessary(Rect.fromCenter(
      center: _lastDragCentre!,
      width: 1,
      height: _kAutoScrollHotZone * 2,
    ));
    _resolveFromLastPointer();
  }

  /// The ONE place the landing slot is decided, for both of the things that
  /// can change it: the finger moving, and the page scrolling under a still
  /// finger. Splitting them is how the preview ends up alive on one and dead
  /// on the other.
  void _resolveFromLastPointer() {
    final frozen = _dragFrozen;
    final centre = _lastDragCentre;
    if (frozen == null || centre == null) return;
    final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    // globalToLocal is what makes scrolling free: the frozen pack is in
    // GRID-local cells, and the grid's box moves in global space as the page
    // scrolls, so the conversion absorbs the scroll with no bookkeeping.
    final idx = _insertIndexAt(
        box.globalToLocal(centre), frozen, ProfileGridGeometry.columns);
    // Repack only when the ANSWER changes. Most pointer moves resolve to the
    // same cell, and a setState per move would rebuild every RecordButton.
    if (idx != null && idx != _dragInsertAt) {
      setState(() => _dragInsertAt = idx);
    }
  }

  /// Commits whatever the preview is currently showing, wherever the finger
  /// was released.
  ///
  /// **This deliberately does not care where the pointer is.** A grid-level
  /// `DragTarget` only accepts a release inside its
  /// own bounds — so dragging a card to the top of a tall profile, waiting for
  /// the page to auto-scroll, and letting go would **silently discard the
  /// move**, because by then the finger is over the banner. Widening the
  /// target does not fix that: the boundary is invisible, and the
  /// preview is promising a landing slot the entire time the finger is outside
  /// it. Release-to-cancel is not a discoverable gesture; alongside a live
  /// preview it is an actively misleading one. So: what you see is what gets
  /// written, and a release that resolves to no movement is the no-op below.
  Future<void> _onDrop() async {
    final order = _dragOrder;
    final moved = _dragging;
    final idx = _dragInsertAt;
    final cb = widget.onReorder;
    if (order == null || moved == null || idx == null || cb == null) {
      _clearDrag();
      return;
    }
    final next = _reordered(order, moved, idx);
    if (next.indexWhere((r) => r.key == moved.key) ==
        order.indexWhere((r) => r.key == moved.key)) {
      _clearDrag(); // dropped back where it started
      return;
    }
    _stopAutoScroll();
    // ONE setState: clearing the drag and raising the freeze in two would put
    // a frame between them in which the layout reverts, and the cards would
    // visibly flash back before the save started.
    setState(() {
      _dragging = null;
      _dragOrder = null;
      _dragFrozen = null;
      _dragInsertAt = null;
      _dragSize = Size.zero;
      _frozenOrder = next;
    });
    try {
      await cb(next, moved);
    } finally {
      // Unfreeze regardless of outcome. Success: the reload already put the
      // cards here, so nothing moves. Failure (or an org vote, which changes
      // no records yet): the reload returns the old order and they animate
      // back — the honest picture either way.
      if (mounted) setState(() => _frozenOrder = null);
    }
  }

  Widget _dragFeedback(Widget child, double w, double h) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: w,
        height: h,
        child: Opacity(opacity: 0.9, child: child),
      ),
    );
  }

  /// Wraps a card cell so it can be picked up.
  ///
  /// The card is a drag SOURCE only — the drop target is the grid as a whole
  /// ([build]), because a per-card target hit-tests its own *rendered*
  /// position and the whole point of the preview is that those positions move.
  ///
  /// **DELTA (desktop): `Draggable`, not the client's `LongPressDraggable`.**
  /// Long-press is a touch idiom — it exists on mobile to disambiguate picking
  /// a card up from dragging the page. With a mouse there is nothing to
  /// disambiguate (the page scrolls on the wheel), so the hold is pure latency:
  /// the card simply does not move for half a second, which reads as "reorder
  /// wasn't ported" rather than as a delay. A plain `Draggable` still loses the
  /// arena to a click that does not move, so tap-to-edit is unaffected.
  ///
  /// A touch gesture ported verbatim is a desktop bug, not a faithful port.
  Widget _wrapDraggable(Record record, double w, double h, Widget child) {
    return Draggable<Record>(
      data: record,
      // Inert while a save is in flight, rather than unwrapping the cell. The
      // widget TYPE has to stay put: swapping `Draggable(child:)` for a bare
      // cell would replace the element under the keyed `AnimatedPositioned`,
      // rebuilding every RecordButton — and re-resolving its NFT art — twice
      // per save. (This is about the RUNTIME swap; permanently choosing
      // `Draggable` over the client's `LongPressDraggable` above is fine,
      // because the type is then the same on every build.)
      maxSimultaneousDrags: _frozenOrder == null ? 1 : 0,
      // The default anchor strategy, with the answer kept. It runs exactly
      // once, at drag start, with the pointer position — the only moment the
      // grab offset is knowable — and returning it unchanged leaves the drag
      // feeling identical.
      dragAnchorStrategy: (d, ctx, pos) {
        _grabOffset = childDragAnchorStrategy(d, ctx, pos);
        return _grabOffset;
      },
      onDragStarted: () => _onDragStarted(record, Size(w, h)),
      onDragUpdate: _onDragUpdate,
      // `onDragEnd` fires on every release and is the only callback that does.
      // `onDraggableCanceled` would fire first on the same release, so wiring
      // both would commit twice.
      onDragEnd: (_) => _onDrop(),
      feedback: _dragFeedback(child, w, h),
      // The ghost IS the landing indicator. The preview pack has already moved
      // this cell's `AnimatedPositioned` to the card's future slot, so the box
      // outlined in green is literally where the card will be — not a drawing
      // of it. A separate overlay would be a second source of geometry, and a
      // preview built on its own guess drifts from the thing it previews.
      childWhenDragging: _PreviewGlow(
        width: w,
        height: h,
        color: ThemeProvider.successDark,
        child: Opacity(opacity: 0.35, child: child),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The add button is not a drop target and its slot moves with every
        // repack, so it is noise during a drag.
        final bool showAdd = widget.isEditable &&
            widget.isEditMode &&
            widget.onAddTap != null &&
            _dragging == null;
        if (widget.records.isEmpty && widget.previewRecord == null && !showAdd) {
          return const SizedBox.shrink();
        }

        final double gridWidth = constraints.maxWidth;
        final double cw = ProfileGridGeometry.cellWidth(gridWidth);
        const double sp = ProfileGridGeometry.spacing;
        const int cols = ProfileGridGeometry.columns;

        // Three layout sources, in precedence order:
        //   1. drag in flight → the previewed order, packed LINEAR
        //   2. save in flight → the frozen order, packed LINEAR
        //   3. otherwise      → widget.records (+ edit preview), two-block
        //
        // 1 and 2 pack linear because that is what the write produces: any
        // unranked card bakes the WHOLE list into rank order
        // (`profile_page.dart::_onReorderCards` → `withRanks`), so after a save
        // there is only ever one block. On a legacy/mixed profile the preview
        // therefore shows the ranked/unranked break closing — which is not a
        // glitch, it is what saving does, and it is better seen before the
        // write than discovered after it.
        final Record? preview = widget.previewRecord;
        final List<Record> layoutRecords;
        final bool linear;
        final Record? dragging = _dragging;
        final List<Record>? dragOrder = _dragOrder;
        final int? insertAt = _dragInsertAt;
        if (dragging != null && dragOrder != null && insertAt != null) {
          layoutRecords = _reordered(dragOrder, dragging, insertAt);
          linear = true;
        } else if (_frozenOrder != null) {
          layoutRecords = _frozenOrder!;
          linear = true;
        } else {
          // Apply the preview: replace the same-key record in place (carrying
          // its rank so an edit-preview keeps its slot), otherwise append it.
          final list = List<Record>.from(widget.records);
          if (preview != null) {
            final int i = list.indexWhere((r) => r.key == preview.key);
            if (i >= 0) {
              final existingRank = list[i].rank;
              list[i] = (existingRank != null && preview.rank == null)
                  ? preview.copyWith(rank: existingRank)
                  : preview;
            } else {
              list.add(preview);
            }
          }
          layoutRecords = list;
          linear = false;
        }

        // Two-block 2D first-fit pack: ranked rows on top, unranked below.
        final packed = _packGrid(layoutRecords, cols, linear: linear);

        // Stashed for [_onDragStarted]: it freezes the geometry the user is
        // currently looking at, and cannot recompute it (no constraints of its
        // own). Written in build deliberately — no setState, idempotent, and
        // the alternative is duplicating the pack.
        _lastPack = packed;
        _lastCellPitch = cw + sp;

        // Add button: first free slot after the last card, filling its row.
        _Placement? add;
        if (showAdd) {
          final int pos =
              _firstFree(packed.occupied, packed.lastFloor, 1, 1, cols);
          final int col = pos % cols;
          add = _Placement(null, col, pos ~/ cols, cols - col, 1);
        }

        int totalRows = 0;
        for (final p in packed.placements) {
          totalRows = math.max(totalRows, p.row + p.h);
        }
        if (add != null) totalRows = math.max(totalRows, add.row + add.h);
        // Never let the box SHRINK mid-drag. A preview that pulls the page up
        // under the finger moves the grid away from the pointer, which is the
        // same class of bug as hit-testing the previewed layout.
        if (dragging != null) totalRows = math.max(totalRows, _dragRows);
        if (totalRows == 0) return const SizedBox.shrink();

        double extent(int n) => n * cw + (n - 1) * sp;
        // Rows are square cells, except a pinned post's row, which is as tall
        // as the post needs, capped at PostCardMeta.maxRows rows; past that
        // the card scrolls. Until the card has measured itself it gets one
        // row, then animates to its height (AnimatedPositioned).
        final rowH = List<double>.filled(totalRows, cw);
        final double postCap = extent(PostCardMeta.maxRows);
        for (final p in packed.placements) {
          final r = p.record!;
          if (r.metadata['cardKind'] != PostCardMeta.kind) continue;
          // RecordButton wraps the card in a 2px margin on every side.
          final natural =
              ProfilePostCard.naturalHeightFor(r.value, gridWidth - 4);
          // Unmeasured: two rows, the typical post, so the loading skeleton
          // fits and the settle to the real height is small.
          rowH[p.row] = natural != null
              ? math.min(natural + 4, postCap)
              : math.min(extent(2), postCap);
        }
        final tops = List<double>.filled(totalRows + 1, 0);
        for (int i = 0; i < totalRows; i++) {
          tops[i + 1] = tops[i] + rowH[i] + sp;
        }
        _lastRowTops = tops;
        final double gridHeight = tops[totalRows] - sp;
        double colX(int n) => n * (cw + sp);
        double rowY(int n) => tops[n];
        double spanH(int row, int n) => tops[row + n] - sp - tops[row];

        final children = <Widget>[];
        int wave = 0;
        for (final p in packed.placements) {
          final record = p.record!;
          final bool isPreview =
              preview != null && record.key == preview.key;
          final int waveIndex = _entered.add(record.key) ? wave++ : 0;
          final double w = extent(p.w);
          final double h = spanH(p.row, p.h);
          Widget cell = RecordButton(
            record: record,
            onTap: () => widget.onRecordTap?.call(record),
            onDelete: () => widget.onRecordDeleted?.call(record),
            isEditable: widget.isEditable && !isPreview,
            isEditMode: widget.isEditMode && !isPreview,
            isLive: !isPreview && _isLive(record),
            onToggleLive: isPreview ? null : () => _toggleLive(record),
            liveFailed: !isPreview && _liveFailed.contains(record.key),
            onLiveFailed: isPreview ? null : () => _liveFailed_(record),
            onUseNftAsAvatar: widget.onUseNftAsAvatar,
            nftOwner: widget.nftOwner,
          );
          if (isPreview) {
            // A preview cell is a ghost of a card being edited — never live,
            // and never entering: it is already on screen conceptually.
            cell = _PreviewGlow(width: w, height: h, child: cell);
          } else if (_dragEnabled) {
            cell = _wrapDraggable(record, w, h, cell);
          }
          // Keyed so a repack moves the existing element instead of building
          // a fresh one at the new slot. That element identity is what lets
          // [AnimatedPositioned] tween the move: without the key the card is a
          // different element there and has nothing to animate between.
          children.add(AnimatedPositioned(
            key: ValueKey<String>(record.key),
            duration: _kSettle,
            curve: _kSettleCurve,
            left: colX(p.col),
            top: rowY(p.row),
            width: w,
            height: h,
            child: ProfileCardPopIn(index: waveIndex, child: cell),
          ));
        }
        if (add != null) {
          children.add(AnimatedPositioned(
            key: const ValueKey<String>('__add__'),
            duration: _kSettle,
            curve: _kSettleCurve,
            left: colX(add.col),
            top: rowY(add.row),
            width: extent(add.w),
            height: spanH(add.row, add.h),
            child: _AddButton(onTap: widget.onAddTap!),
          ));
        }

        final Widget grid = AnimatedContainer(
          key: _gridKey,
          duration: _kSettle,
          curve: _kSettleCurve,
          width: gridWidth,
          height: gridHeight,
          // Clip.none so a card still in flight when the box shrinks is not
          // sliced off mid-animation.
          child: Stack(clipBehavior: Clip.none, children: children),
        );

        // NO DragTarget, anywhere. Position tracking belongs to the
        // draggable ([_onDragUpdate]) and so does the drop ([_onDrop]) — a
        // target would tie both to the card still being over the grid, which
        // is exactly what it stops being when you drag toward the top of a
        // tall profile.
        return grid;
      },
    );
  }
}

/// One placed cell in the grid. [record] is null only for the add button.
class _Placement {
  final Record? record;
  final int col;
  final int row;
  final int w;
  final int h;
  const _Placement(this.record, this.col, this.row, this.w, this.h);
}

class _PackResult {
  final List<_Placement> placements;
  final Set<int> occupied; // row-major cell indices: row * cols + col
  final int lastFloor; // row-major index of the last placed card's origin
  const _PackResult(this.placements, this.occupied, this.lastFloor);
}

/// Two-block 2D first-fit packer for the profile grid.
///
/// Ranked records pack into the top block (rows `0..k`, in rank order); unranked
/// records pack into a fresh block starting on the row *below*, even if the
/// ranked block's last row still had free cells. Within each block a monotonic
/// cursor only moves forward, so a wide/tall card that can't fit in the cells
/// remaining on a row leaves a permanent hole behind it — filled only by
/// dragging (re-ranking) a card into it, never auto-backfilled by a later card.
_PackResult _packGrid(List<Record> records, int cols, {bool linear = false}) {
  final occupied = <int>{};
  final placements = <_Placement>[];

  final ranked = <Record>[];
  final unranked = <Record>[];
  if (!linear) {
    for (final r in records) {
      (r.rank != null ? ranked : unranked).add(r);
    }
    // Robust against an unsorted input: the read path already returns ranked
    // records in rank order, but sort defensively so the grid is correct
    // regardless of which load path (chain vs DB) produced `records`.
    ranked.sort((a, b) => a.rank!.compareTo(b.rank!));
  }

  int lastFloor = 0;
  int maxRow = -1;

  void packBlock(List<Record> block, int startRow) {
    int floor = startRow * cols;
    for (final r in block) {
      // A pinned post is always full width and one row in the PACK; its row
      // then takes the post's own pixel height. A
      // full-width card sits alone on its row, so nothing spans it.
      final bool isPost = r.metadata['cardKind'] == PostCardMeta.kind;
      final int w = isPost ? cols : math.max(1, math.min(cols, r.width));
      final int h = isPost ? 1 : math.max(1, r.height);
      final int pos = _firstFree(occupied, floor, w, h, cols);
      final int col = pos % cols;
      final int row = pos ~/ cols;
      for (int dr = 0; dr < h; dr++) {
        for (int dc = 0; dc < w; dc++) {
          occupied.add((row + dr) * cols + (col + dc));
        }
      }
      placements.add(_Placement(r, col, row, w, h));
      if (row + h - 1 > maxRow) maxRow = row + h - 1;
      floor = pos; // monotonic cursor — only moves forward
      lastFloor = pos;
    }
  }

  if (linear) {
    packBlock(records, 0);
  } else {
    packBlock(ranked, 0);
    packBlock(unranked, ranked.isEmpty ? 0 : maxRow + 1);
  }
  return _PackResult(placements, occupied, lastFloor);
}

/// First free row-major position at or after [fromIndex] where a [w]×[h]
/// footprint fits within [cols] columns. Scans left-to-right, top-to-bottom.
int _firstFree(Set<int> occ, int fromIndex, int w, int h, int cols) {
  int idx = fromIndex;
  while (true) {
    final int col = idx % cols;
    final int row = idx ~/ cols;
    if (col > cols - w) {
      idx = (row + 1) * cols; // no room on this row for a w-wide card
      continue;
    }
    bool fits = true;
    for (int dr = 0; dr < h && fits; dr++) {
      for (int dc = 0; dc < w && fits; dc++) {
        if (occ.contains((row + dr) * cols + (col + dc))) fits = false;
      }
    }
    if (fits) return idx;
    idx++;
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeProvider.tealPrimary.withValues(alpha: 0.4),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: ThemeProvider.tealPrimary.withValues(alpha: 0.5),
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Pulsing outline + glow around a cell. Two callers, two colours, one class:
/// **teal** is the edit-sheet ghost (a card being edited), **green** is a drag
/// landing slot (where the card in flight would come to rest).
class _PreviewGlow extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Widget child;
  const _PreviewGlow({
    required this.width,
    required this.height,
    required this.child,
    this.color = ThemeProvider.tealLight,
  });

  @override
  State<_PreviewGlow> createState() => _PreviewGlowState();
}

class _PreviewGlowState extends State<_PreviewGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + 0.15 * t),
                blurRadius: 8 + 8 * t,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: widget.color.withValues(alpha: 0.5 + 0.3 * t),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Public because the onboarding kit block plays the same cascade
/// (publicos_client `onboarding_flow.dart`). One animation in two places is one class — a
/// second copy would drift the moment either was tuned.
class ProfileCardPopIn extends StatefulWidget {
  /// Position in the entrance wave, not in the grid — see [_ProfileGridState._entered].
  final int index;
  final Widget child;
  const ProfileCardPopIn({super.key, required this.index, required this.child});

  @override
  State<ProfileCardPopIn> createState() => _ProfileCardPopInState();
}

class _ProfileCardPopInState extends State<ProfileCardPopIn>
    with SingleTickerProviderStateMixin {
  // tabpop: .4s cubic-bezier(.2,1.2,.4,1), animation-delay = index * 22ms.
  static const Duration _duration = Duration(milliseconds: 400);
  static const Duration _stagger = Duration(milliseconds: 22);
  static const Cubic _curve = Cubic(0.2, 1.2, 0.4, 1.0);
  static const double _from = 0.4;

  late final AnimationController _ctrl;
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    final wait = _stagger * widget.index;
    if (wait == Duration.zero) {
      _ctrl.forward();
    } else {
      _delay = Timer(wait, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        // The wrappers STAY after the entrance, resting at opacity 1 / scale
        // 1 (the curve ends at 1). Returning the bare child on completion
        // would change the tree's shape under the card, so Flutter would
        // rebuild every card from scratch ~400 ms after it appeared: pinned
        // posts flash their skeleton, app cards re-create their webviews
        // (twin of the client's).
        final double t = _ctrl.isCompleted ? 1.0 : _curve.transform(_ctrl.value);
        return Opacity(
          // The curve overshoots past 1 to give the spring its bounce; scale
          // wants that, opacity cannot take it.
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: _from + (1 - _from) * t, child: child),
        );
      },
    );
  }
}
