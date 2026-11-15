import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/widgets/glass_context_menu.dart';
import 'package:publicos_desktop/widgets/nft_verified_art.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

/// Unified NFT quick-pick grid — merges the EVM "previously used" history and
/// the Solana "mine + used" set into one searchable, filterable grid. Replaces
/// the separate `EthNftHistoryGrid` + `SolanaNftGrid`.
///
/// Sources (identical to the two grids it replaces — no new network surface):
///  - **EVM**: per-session `used_nft_avatars` history (`eip155`). EVM has no
///    on-chain enumeration, so this is history-only.
///  - **Solana**: NFTs currently held by the account's link-verified Solana
///    wallets (live `listOwnedSolanaNfts`) ∪ the Solana used-history, deduped by
///    mint. Enumeration *is* the ownership proof, so live mints always shimmer.
///
/// Filters / sort / search are pure view-state over the one loaded list — no
/// extra fetches. Owned tiles carry the verified shimmer; not-owned history
/// tiles dim but stay pickable. Verdicts older than [_ttl] re-verify on-chain in
/// the background and write back, and Solana tiles missing art hydrate lazily.
///
/// Selection bubbles a single [NftAvatarRef] (EVM or Solana) — the caller no
/// longer needs separate per-chain callbacks. The currently-chosen ref's
/// `toCaip19()` flows back in as [selectedKey] to highlight its tile.
/// Locks the grid to one protocol: the other source's load path is skipped
/// entirely (no Solana wallet enumeration on an EVM-locked grid and vice
/// versa) and its chain tokens never appear in the filter chips.
enum NftProtocolFilter { evm, solana }

class NftPickerGrid extends StatefulWidget {
  final EthereumAddress account;

  /// `toCaip19()` of the currently-selected ref (EVM or Solana), to highlight.
  final String? selectedKey;

  final void Function(NftAvatarRef ref, String? image, bool verified) onSelect;

  /// `null` = merged EVM ∪ Solana (the historical behavior).
  final NftProtocolFilter? protocol;

  const NftPickerGrid({
    super.key,
    required this.account,
    required this.onSelect,
    this.selectedKey,
    this.protocol,
  });

  @override
  State<NftPickerGrid> createState() => _NftPickerGridState();
}

/// One pickable NFT, from either source, normalized to a common shape.
class _Pick {
  final NftAvatarRef ref;
  String? image;
  bool loaded;
  bool verified; // owned → shimmer
  final bool isSolana;
  final int chain; // 0 for Solana
  final bool fromChain; // Solana live-enumerated (always owned)
  final int checkedAt; // verdict TTL anchor (millis); 0 for live
  final int lastSeenAt; // recency sort anchor
  final String searchBlob; // lowercased contract / token / mint / chain

  _Pick({
    required this.ref,
    required this.image,
    required this.loaded,
    required this.verified,
    required this.isSolana,
    required this.chain,
    required this.fromChain,
    required this.checkedAt,
    required this.lastSeenAt,
    required this.searchBlob,
  });
}

class _NftPickerGridState extends State<NftPickerGrid> {
  static const Duration _ttl = Duration(days: 7);

  bool _loading = true;
  final List<_Pick> _items = [];

  // View-state filters (no refetch).
  final TextEditingController _searchCtl = TextEditingController();
  bool? _owned; // null = all · true = mine · false = not mine
  String _chainTok = 'all'; // 'all' | 'solana' | 'evm:<id>'
  bool _recent = true; // recent-first vs oldest-first

  @override
  void initState() {
    super.initState();
    _searchCtl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void didUpdateWidget(covariant NftPickerGrid old) {
    super.didUpdateWidget(old);
    if (old.account != widget.account || old.protocol != widget.protocol) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  String _chainTokOf(_Pick p) => p.isSolana ? 'solana' : 'evm:${p.chain}';

  String _chainLabel(String tok) {
    if (tok == 'all') return context.l10n.nftPickerGridAllChains;
    if (tok == 'solana') return 'Solana';
    final id = int.tryParse(tok.substring(4));
    return PublicOSContacts.nftChainNames[id] ??
        context.l10n.nftPickerGridChainFallback(id ?? 0);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _items.clear();
    });
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final merged = <_Pick>[];

    // 1. EVM — used-history only (no enumeration). Skipped when locked to
    // Solana.
    if (widget.protocol != NftProtocolFilter.solana) {
    try {
      final rows = await PublicOSContacts.getUsedNftAvatars(namespace: 'eip155');
      for (final row in rows) {
        merged.add(_Pick(
          ref: PublicOSContacts.refFromUsedRow(row),
          image: row.imageUrl,
          loaded: row.imageUrl != null,
          verified: row.verifiedOwnership,
          isSolana: false,
          chain: row.chain,
          fromChain: false,
          checkedAt: row.checkedAt,
          lastSeenAt: row.lastSeenAt,
          searchBlob:
              '${row.contract} ${row.tokenId} ${row.chainName ?? ''}'.toLowerCase(),
        ));
      }
    } catch (_) {/* EVM history unavailable → just no EVM tiles */}
    }

    // 2. Solana — live holdings ∪ used-history, deduped by mint (live first).
    // Skipped when locked to EVM.
    if (widget.protocol != NftProtocolFilter.evm) {
    try {
      final wallets = await PublicOSWallets.getWallets(widget.account);
      final owners = <String>[];
      for (final w in wallets) {
        if (w.protocol != PublicOSWallets.protoSolana) continue;
        if (!PublicOSWallets.verifySolanaWalletLink(
            account: widget.account, wallet: w)) {
          continue;
        }
        owners.add(utf8.decode(w.addressData)); // non-EVM: utf8 of base58
      }

      final liveMints = <String>{};
      for (final o in owners) {
        for (final m in await PublicOSWallets.listOwnedSolanaNfts(o)) {
          liveMints.add(m);
        }
      }

      final usedRows =
          await PublicOSContacts.getUsedNftAvatars(namespace: 'solana');
      final usedByMint = <String, UsedNftAvatarRow>{
        for (final r in usedRows)
          if (r.mint != null) r.mint!: r,
      };

      for (final m in liveMints) {
        final cached = usedByMint[m];
        merged.add(_Pick(
          ref: NftAvatarRef.solana(mint: m),
          image: cached?.imageUrl,
          loaded: cached?.imageUrl != null,
          verified: true,
          isSolana: true,
          chain: 0,
          fromChain: true,
          checkedAt: cached?.checkedAt ?? 0,
          // Live holdings are "now" — sort to the top of recent.
          lastSeenAt: cached?.lastSeenAt ?? nowMs,
          searchBlob: '$m solana'.toLowerCase(),
        ));
      }
      for (final row in usedRows) {
        final mint = row.mint;
        if (mint == null || liveMints.contains(mint)) continue;
        merged.add(_Pick(
          ref: NftAvatarRef.solana(mint: mint),
          image: row.imageUrl,
          loaded: row.imageUrl != null,
          verified: row.verifiedOwnership,
          isSolana: true,
          chain: 0,
          fromChain: false,
          checkedAt: row.checkedAt,
          lastSeenAt: row.lastSeenAt,
          searchBlob: '$mint solana'.toLowerCase(),
        ));
      }
    } catch (_) {/* Solana wallet/RPC issue → just no Solana tiles */}
    }

    if (!mounted) return;
    setState(() {
      _items.addAll(merged);
      _loading = false;
    });
    _hydrateAndReverify();
  }

  /// Background pass: hydrate Solana tiles missing art, and re-verify any
  /// history verdict aged past the TTL (skips Solana live tiles — already
  /// authoritative). RPC-friendly: one item at a time, write-back on change.
  Future<void> _hydrateAndReverify() async {
    for (var i = 0; i < _items.length; i++) {
      if (!mounted) return;
      final p = _items[i];

      if (p.isSolana && (!p.loaded || p.image == null)) {
        final meta = await PublicOSWallets.resolveSolanaNftData(p.ref.mint!);
        if (!mounted) return;
        final img = (meta?['image'] ?? meta?['image_url']) as String?;
        setState(() {
          p.image = img;
          p.loaded = true;
        });
        await PublicOSContacts.recordUsedNftAvatar(
          p.ref,
          imageUrl: img,
          verifiedOwnership: p.fromChain ? true : p.verified,
        );
      }

      if (p.isSolana && p.fromChain) continue; // live = authoritative
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - p.checkedAt < _ttl.inMilliseconds) continue;
      final owned =
          await PublicOSContacts.verifyNftOwnership(p.ref, widget.account);
      if (!mounted) return;
      await PublicOSContacts.recordUsedNftAvatar(
        p.ref,
        imageUrl: p.image,
        verifiedOwnership: owned,
        checkedAt: DateTime.now(),
      );
      if (owned != p.verified) setState(() => p.verified = owned);
    }
  }

  /// Long-press quick options. Refresh is always offered (it's the recovery
  /// path for a blank/stale tile). Remove-from-recents only makes sense for
  /// history rows — a live-enumerated Solana holding would just re-appear on
  /// the next load, so those tiles don't offer it.
  void _showTileMenu(_Pick p, Offset position) {
    GlassContextMenu.show(
      context,
      position: position,
      items: [
        GlassContextMenuItem(
          icon: Icons.refresh_rounded,
          label: context.l10n.nftPickerGridRefresh,
          onTap: () => _refreshPick(p),
        ),
        if (!p.fromChain)
          GlassContextMenuItem(
            icon: Icons.delete_outline_rounded,
            label: context.l10n.nftPickerGridRemoveFromRecents,
            destructive: true,
            onTap: () => _removeFromRecents(p),
          ),
      ],
    );
  }

  /// Full re-derive for one tile: drop the cached image bytes (disk + memory),
  /// re-resolve metadata on-chain, re-verify ownership, write the fresh verdict
  /// back to the history row. The recovery path for a blank or stale tile.
  Future<void> _refreshPick(_Pick p) async {
    final oldImage = p.image;
    setState(() {
      p.image = null;
      p.loaded = false;
    });

    Future<void> evict(String url) async {
      if (url.startsWith('data:')) return; // inline art — nothing cached
      await ZeroCachedImage.evictFromCache(url);
      PaintingBinding.instance.imageCache.evict(ZeroCachedImageProvider(url));
    }

    if (oldImage != null) await evict(oldImage);

    final meta = p.isSolana
        ? await PublicOSWallets.resolveSolanaNftData(p.ref.mint!)
        : await PublicOSContacts.resolveNftAvatarData(p.ref);
    final img = (meta?['image'] ?? meta?['image_url']) as String?;
    if (img != null && img != oldImage) await evict(img);

    final owned =
        await PublicOSContacts.verifyNftOwnership(p.ref, widget.account);
    await PublicOSContacts.recordUsedNftAvatar(
      p.ref,
      imageUrl: img,
      verifiedOwnership: owned,
      checkedAt: DateTime.now(),
    );
    // Keep the rendered profile in lockstep with the picker: if this tile is
    // the user's own current avatar/banner/card, propagate the fresh verdict
    // into the contact verdict cache too — not just `used_nft_avatars`. The
    // whole point of refresh is to re-bless a stale tile, so the live badge
    // must move with it. No-op when the ref isn't a current self pointer.
    await PublicOSContacts.syncSelfNftVerdict(
      widget.account,
      p.ref,
      metadata: meta,
      owned: owned,
    );

    if (!mounted) return;
    setState(() {
      p.image = img;
      p.loaded = true;
      p.verified = owned;
    });
  }

  Future<void> _removeFromRecents(_Pick p) async {
    await PublicOSContacts.removeUsedNftAvatar(p.ref);
    if (!mounted) return;
    setState(() => _items.remove(p));
  }

  List<_Pick> get _filtered {
    Iterable<_Pick> r = _items;
    if (_owned == true) {
      r = r.where((p) => p.verified);
    } else if (_owned == false) {
      r = r.where((p) => !p.verified);
    }
    if (_chainTok != 'all') r = r.where((p) => _chainTokOf(p) == _chainTok);
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.isNotEmpty) r = r.where((p) => p.searchBlob.contains(q));
    final list = r.toList();
    list.sort((a, b) => _recent
        ? b.lastSeenAt.compareTo(a.lastSeenAt)
        : a.lastSeenAt.compareTo(b.lastSeenAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child:
            Center(child: PhigitalLoadingWidget(size: 26, showShadows: false)),
      );
    }
    if (_items.isEmpty) {
      return _note(tokens, context.l10n.nftPickerGridEmpty);
    }

    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _searchField(tokens),
        const SizedBox(height: 8),
        _chipsRow(tokens),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          _note(tokens, context.l10n.nftPickerGridNoMatch)
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final p = filtered[i];
              final tappable = p.loaded && p.image != null;
              return GestureDetector(
                onTap: tappable
                    ? () => widget.onSelect(p.ref, p.image, p.verified)
                    : null,
                // Long-press works even on a blank/unloaded tile — Refresh IS
                // the recovery path when the art never resolved.
                onLongPressStart: (d) => _showTileMenu(p, d.globalPosition),
                child: NftPickTile(
                  image: p.image,
                  verified: p.verified,
                  chainBadge: p.isSolana
                      ? const NftChainIcon(solana: true)
                      : NftChainIcon(chain: p.chain),
                  selected: p.ref.toCaip19() == widget.selectedKey,
                  loading: !p.loaded,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _searchField(GlassTokens tokens) => TextField(
        controller: _searchCtl,
        style: TextStyle(
            fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: context.l10n.nftPickerGridSearchHint,
          hintStyle: TextStyle(color: tokens.textDim, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: tokens.textDim),
          suffixIcon: _searchCtl.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, size: 16, color: tokens.textDim),
                  onPressed: () => _searchCtl.clear(),
                ),
          filled: true,
          fillColor: tokens.glassFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.connectedAccent)),
        ),
      );

  Widget _chipsRow(GlassTokens tokens) {
    final chainToks = <String>{'all', ..._items.map(_chainTokOf)}.toList();
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _chip(tokens, context.l10n.nftPickerGridMine, _owned == true,
            () => setState(() => _owned = _owned == true ? null : true)),
        _chip(tokens, context.l10n.nftPickerGridNotMine, _owned == false,
            () => setState(() => _owned = _owned == false ? null : false)),
        // Chain filter — only worth showing when there's more than one chain.
        if (chainToks.length > 2)
          _menuChip<String>(
            tokens,
            label: _chainLabel(_chainTok),
            active: _chainTok != 'all',
            value: _chainTok,
            items: chainToks
                .map((t) => PopupMenuItem(value: t, child: Text(_chainLabel(t))))
                .toList(),
            onSelected: (t) => setState(() => _chainTok = t),
          ),
        _chip(
          tokens,
          _recent ? context.l10n.nftPickerGridRecent : context.l10n.nftPickerGridOldest,
          true,
          () => setState(() => _recent = !_recent),
          icon: _recent ? Icons.south_rounded : Icons.north_rounded,
        ),
      ],
    );
  }

  Widget _chip(GlassTokens tokens, String label, bool active, VoidCallback onTap,
      {IconData? icon}) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? tokens.connectedAccent.withValues(alpha: 0.15) : tokens.glassFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: active
                  ? tokens.connectedAccent.withValues(alpha: 0.4)
                  : tokens.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 13,
                  color: active ? tokens.connectedAccent : tokens.textDim),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? tokens.connectedAccent : tokens.textDim)),
          ],
        ),
      ),
    );
  }

  Widget _menuChip<T>(
    GlassTokens tokens, {
    required String label,
    required bool active,
    required T value,
    required List<PopupMenuEntry<T>> items,
    required ValueChanged<T> onSelected,
  }) {
    return PopupMenuButton<T>(
      initialValue: value,
      color: tokens.surfaceElevated,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? tokens.connectedAccent.withValues(alpha: 0.15) : tokens.glassFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: active
                  ? tokens.connectedAccent.withValues(alpha: 0.4)
                  : tokens.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: active ? tokens.connectedAccent : tokens.textDim)),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: active ? tokens.connectedAccent : tokens.textDim),
          ],
        ),
      ),
    );
  }

  Widget _note(GlassTokens tokens, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk', fontSize: 12.5, color: tokens.textDim),
        ),
      );
}
