import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/widgets/nft_avatar_fx.dart';
import 'package:publicos_desktop/widgets/nft_verified_art.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/profile/nft_picker_grid.dart';
import 'package:publicos_desktop/widgets/profile/ssp_media_grid.dart';
import 'package:publicos_desktop/widgets/profile_image_picker.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/fullscreen_overlay.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// The source pane the sheet slides into after the landing's first decision.
enum _Pane { image, eth, solana }

/// The one pending selection — set only by explicit actions inside the open
/// pane, kept when sliding back to the landing (the PENDING chip on the
/// preview keeps it visible), replaced only by a new explicit pick.
sealed class _Pending {}

/// A plain image URL — typed, uploaded, or picked from the SSP uploads grid.
class _PendingImage extends _Pending {
  final String url;
  _PendingImage(this.url);
}

/// An NFT ref — grid tile (arrives resolved + verified) or manual entry
/// (resolves via the debounced lookup, [loading]/[error] track it).
class _PendingNft extends _Pending {
  final NftAvatarRef ref;
  String? image;
  bool owned;
  bool loading;
  bool error;
  _PendingNft(this.ref, {this.image, this.owned = false, this.loading = false})
      : error = false;
}

/// Glass-dark bottom sheet for editing the profile picture / banner, or
/// picking an NFT for a card. Flow: a truthful landing (preview of what's
/// LIVE on the profile — NFT-wins, exactly like the profile render — plus
/// the one decision: Image / Ethereum / Solana) sliding into a dedicated
/// pane per source. Preview + Save stay pinned outside the slide.
Future<void> showEditProfileImageSheet(
  BuildContext context, {
  required String type, // 'avatar' or 'banner'
  String? currentImageUrl,

  /// The NFT currently set on this surface (`profile.<surface>.nft`), so the
  /// landing can preview the live state instead of the URL fallback.
  NftAvatarRef? currentNft,

  /// Already-resolved art for [currentNft] (the caller usually has it from
  /// its own render) — passing it avoids a re-resolve flash on open.
  String? currentNftImage,

  /// Cached ownership verdict for [currentNft]; null = unknown (no badge).
  bool? currentNftOwned,
  required Function(Record) onSave,
}) {
  // DELTA (desktop): sheet -> centered glass dialog. Wide, because the NFT
  // panes are grids and the landing pins a preview above them.
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.xl,
    builder: (_) => EditProfileImageSheet(
      type: type,
      currentImageUrl: currentImageUrl,
      currentNft: currentNft,
      currentNftImage: currentNftImage,
      currentNftOwned: currentNftOwned,
      onSave: onSave,
    ),
  );
}

/// Open the same picker as a chooser (no record write): the chosen
/// [NftAvatarRef] bubbles to [onPick] and the caller decides how to persist it.
/// Used by the NFT-card create flow (`type: 'card'`) — its landing offers
/// only the two NFT sources.
Future<void> showEditProfileImageSheetAsPicker(
  BuildContext context, {
  required Function(NftAvatarRef) onPick,
}) {
  // DELTA (desktop): sheet -> centered glass dialog (same shell as above).
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.xl,
    builder: (_) => EditProfileImageSheet(type: 'card', onPick: onPick),
  );
}

class EditProfileImageSheet extends StatefulWidget {
  final String type; // 'avatar' | 'banner' | 'card'
  final String? currentImageUrl;

  /// The NFT currently live on this surface, or null. Drives the truthful
  /// landing preview + the remove affordance (an NFT wins the render, so
  /// remove clears the `.nft` pointer first).
  final NftAvatarRef? currentNft;
  final String? currentNftImage;
  final bool? currentNftOwned;

  /// avatar / banner: persists the chosen image/NFT as a profile record.
  final Function(Record)? onSave;

  /// card: bubbles the chosen NFT ref to the caller instead of writing.
  final Function(NftAvatarRef)? onPick;

  const EditProfileImageSheet({
    super.key,
    required this.type,
    this.currentImageUrl,
    this.currentNft,
    this.currentNftImage,
    this.currentNftOwned,
    this.onSave,
    this.onPick,
  }) : assert(onSave != null || onPick != null,
            'provide onSave (avatar/banner) or onPick (card)');

  @override
  State<EditProfileImageSheet> createState() => _EditProfileImageSheetState();
}

class _EditProfileImageSheetState extends State<EditProfileImageSheet>
    with SingleTickerProviderStateMixin {
  static const String _kNoServerWarningDismissedKey =
      'dismissed_no_ssp_warning_profile_image';

  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;

  // Tracks an upload made *in this session* that hasn't been committed via
  // Save yet. If the sheet closes without a successful Save, we delete it so
  // it doesn't sit on the user's quota. Files merely *selected* from the
  // uploads grid never touch this — they pre-exist and must never be deleted.
  int? _pendingUploadId;
  bool _saved = false;

  final GlobalKey<SspMediaGridState> _uploadsKey =
      GlobalKey<SspMediaGridState>();

  // ── Landing ⇄ pane slide ─────────────────────────────────────────────────
  // _stepCtrl 0 = landing · 1 = the chosen source's pane. _pane = which pane
  // the detail side renders (set on pick, kept while sliding back out).
  late final AnimationController _stepCtrl;
  _Pane? _pane;

  // Manual-entry expander inside the eth/solana panes (collapsed by
  // default, grid-first).
  bool _manualOpen = false;

  // ── The one pending selection ────────────────────────────────────────────
  _Pending? _pending;

  // ── Live-NFT art for the landing preview, when the caller didn't pass it ──
  String? _liveNftImage;
  bool _liveNftLoading = false;
  bool _liveNftError = false;

  // ── Manual EVM fields ──
  int _nftChain = 1; // Ethereum mainnet default
  final TextEditingController _contractController = TextEditingController();
  final TextEditingController _tokenIdController = TextEditingController();
  Timer? _nftDebounce;

  // ── Owned-token lookup for the manual contract field ──
  // Typing a contract asks it which tokens this account holds, so the user can
  // pick instead of knowing an id by heart. Base ERC-721 has no enumeration, so
  // an EMPTY result is the normal case on mainnet, NOT an error — the id field
  // stays exactly as it was and nothing is shown. See
  // PublicOSContacts.listOwnedErc721 for the tiers it tries.
  List<String> _ownedIds = const [];
  bool _ownedLoading = false;
  String? _ownedKey; // '<chain>:<contract>' the current list belongs to
  Timer? _ownedDebounce;

  // ── Manual Solana fields ──
  final TextEditingController _solanaMintController = TextEditingController();
  Timer? _solanaDebounce;
  String? _solanaMint;

  bool get _solanaMintValid {
    final m = _solanaMintController.text.trim();
    if (m.length < 32 || m.length > 44) return false;
    try {
      return PublicOSWallets.base58Decode(m).length == 32;
    } catch (_) {
      return false;
    }
  }

  bool get _isContractValid =>
      RegExp(r'^0x[0-9a-fA-F]{40}$').hasMatch(_contractController.text.trim());
  bool get _isTokenIdValid =>
      RegExp(r'^\d+$').hasMatch(_tokenIdController.text.trim());
  bool get _nftReady => _isContractValid && _isTokenIdValid;

  // Manual entry is always erc721 (no UI selector). A grid pick carries its
  // own stored standard in the ref it bubbles, so erc1155 from history still
  // saves/verifies correctly.
  NftAvatarRef _buildNftRef() => NftAvatarRef(
        chain: _nftChain,
        standard: 'erc721',
        contract: _contractController.text.trim(),
        tokenId: _tokenIdController.text.trim(),
      );

  bool get _isAvatar => widget.type == 'avatar';
  bool get _isBanner => widget.type == 'banner';
  bool get _isCard => widget.type == 'card';
  bool get _hasNft => widget.currentNft != null;
  bool get _hasExistingImage =>
      widget.currentImageUrl != null &&
      widget.currentImageUrl!.trim().isNotEmpty;
  bool get _hasValidUrl => _isValidUrl(_urlController.text);

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _urlController.addListener(_onUrlChanged);
    _contractController.addListener(_onNftFieldChanged);
    _tokenIdController.addListener(_onNftFieldChanged);
    _solanaMintController.addListener(_onSolanaMintChanged);
    // Truthful landing: if an NFT is live but the caller had no resolved art
    // in hand, resolve it in the background.
    if (widget.currentNft != null && widget.currentNftImage == null) {
      _resolveLiveNftArt();
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _contractController.dispose();
    _tokenIdController.dispose();
    _solanaMintController.dispose();
    _nftDebounce?.cancel();
    _ownedDebounce?.cancel();
    _solanaDebounce?.cancel();
    _stepCtrl.dispose();
    final pending = _pendingUploadId;
    if (pending != null && !_saved) {
      PublicOSSsp.deleteMedia(pending); // fire and forget
    }
    super.dispose();
  }

  Future<void> _resolveLiveNftArt() async {
    final ref = widget.currentNft;
    if (ref == null) return;
    setState(() => _liveNftLoading = true);
    try {
      final meta = ref.isSolana
          ? await PublicOSWallets.resolveSolanaNftData(ref.mint!)
          : await PublicOSContacts.resolveNftAvatarData(ref);
      if (!mounted) return;
      final img = (meta?['image'] ?? meta?['image_url']) as String?;
      setState(() {
        _liveNftImage = (img != null && img.isNotEmpty) ? img : null;
        _liveNftError = img == null || img.isEmpty;
        _liveNftLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveNftLoading = false;
          _liveNftError = true;
        });
      }
    }
  }

  // ── Selection wiring ──────────────────────────────────────────────────────

  void _onUrlChanged() {
    if (!mounted) return;
    setState(() {
      if (_hasValidUrl) {
        _pending = _PendingImage(_urlController.text.trim());
      } else if (_pending is _PendingImage) {
        // Field cleared / no longer valid → the image selection goes with it.
        _pending = null;
      }
    });
  }

  void _onNftFieldChanged() {
    if (mounted) setState(() {});
    _maybeLoadOwnedTokens();
    _nftDebounce?.cancel();
    if (!_nftReady) return;
    _nftDebounce = Timer(const Duration(milliseconds: 500), _resolveEthSelection);
  }

  /// Ask the typed contract which tokens this account holds. Debounced, and
  /// keyed on chain+contract so switching chain re-asks but retyping the same
  /// address does not.
  void _maybeLoadOwnedTokens() {
    final contract = _contractController.text.trim();
    final myHex = PublicOS.myPublicosAddress;
    if (!_isContractValid || myHex == null) {
      _ownedDebounce?.cancel();
      if (_ownedKey != null || _ownedIds.isNotEmpty || _ownedLoading) {
        setState(() {
          _ownedKey = null;
          _ownedIds = const [];
          _ownedLoading = false;
        });
      }
      return;
    }
    final key = '$_nftChain:${contract.toLowerCase()}';
    if (key == _ownedKey) return; // already have (or are fetching) this one

    _ownedDebounce?.cancel();
    _ownedDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() {
        _ownedKey = key;
        _ownedIds = const [];
        _ownedLoading = true;
      });
      // ForAccount, not the single-address form: PublicOS assets sit on the
      // MainSafe, so enumerating the account address alone would find nothing.
      final ids = await PublicOSContacts.listOwnedErc721ForAccount(
        contract,
        EthereumAddress.fromHex(myHex),
        chain: _nftChain,
      );
      if (!mounted) return;
      // A later edit may have moved on while this was in flight.
      if (_ownedKey != key) return;
      setState(() {
        _ownedIds = ids;
        _ownedLoading = false;
      });
    });
  }

  void _onSolanaMintChanged() {
    if (mounted) setState(() {});
    _solanaDebounce?.cancel();
    if (!_solanaMintValid) {
      _solanaMint = null;
      return;
    }
    _solanaMint = _solanaMintController.text.trim();
    _solanaDebounce =
        Timer(const Duration(milliseconds: 500), _resolveSolanaSelection);
  }

  /// Adopt a grid tile's pick directly — it already carries a TTL-fresh image +
  /// ownership verdict, so no re-resolve flash.
  void _onGridSelect(NftAvatarRef ref, String? image, bool verified) {
    setState(() {
      _pending = _PendingNft(ref, image: image, owned: verified);
    });
  }

  /// Uploads-grid tap: adopt the file's URL (mirrored into the URL field so
  /// the two affordances never disagree); tapping the selected tile again
  /// deselects.
  void _onUploadSelect(MediaFile file) {
    final p = _pending;
    if (p is _PendingImage && p.url == file.url) {
      _urlController.clear(); // listener clears the pending image
      return;
    }
    _urlController.text = file.url; // listener sets the pending image
  }

  Future<void> _resolveEthSelection() async {
    if (!_nftReady) return;
    final ref = _buildNftRef();
    final pending = _PendingNft(ref, loading: true);
    setState(() => _pending = pending);
    try {
      final meta = await PublicOSContacts.resolveNftAvatarData(ref);
      if (!mounted || _pending != pending) return;
      if (meta == null) {
        setState(() {
          pending.loading = false;
          pending.error = true;
        });
        return;
      }
      final img = (meta['image'] ?? meta['image_url']) as String?;
      final owned = await _verifyMine(ref);
      if (!mounted || _pending != pending) return;
      setState(() {
        pending.image = (img != null && img.isNotEmpty) ? img : null;
        pending.error = img == null || img.isEmpty;
        pending.owned = owned;
        pending.loading = false;
      });
    } catch (_) {
      if (mounted && _pending == pending) {
        setState(() {
          pending.loading = false;
          pending.error = true;
        });
      }
    }
  }

  Future<void> _resolveSolanaSelection() async {
    final mint = _solanaMint;
    if (mint == null) return;
    final ref = NftAvatarRef.solana(mint: mint);
    final pending = _PendingNft(ref, loading: true);
    setState(() => _pending = pending);
    try {
      final meta = await PublicOSWallets.resolveSolanaNftData(mint);
      final img = (meta?['image'] ?? meta?['image_url']) as String?;
      final owned = await _verifySolanaMine(mint);
      if (!mounted || _pending != pending) return;
      setState(() {
        pending.image = (img != null && img.isNotEmpty) ? img : null;
        pending.error = img == null || img.isEmpty;
        pending.owned = owned;
        pending.loading = false;
      });
    } catch (_) {
      if (mounted && _pending == pending) {
        setState(() {
          pending.loading = false;
          pending.error = true;
        });
      }
    }
  }

  /// Does the EVM NFT [ref] resolve to one of *my* addresses? Drives the
  /// preview's "You own this NFT" badge. Save never gates on this.
  ///
  /// Delegates to [PublicOSContacts.verifyNftOwnership] rather than repeating
  /// the rule. A local copy of it would be two places for "what counts as
  /// mine" to drift apart — and that rule is not trivial:
  /// sessions u MainSafe u verified linked wallets, plus a Safe-to-account
  /// reverse lookup so a sub-Safe still resolves. One definition, one checker.
  Future<bool> _verifyMine(NftAvatarRef ref) async {
    final myHex = PublicOS.myPublicosAddress;
    if (myHex == null) return false;
    return PublicOSContacts.verifyNftOwnership(
      ref,
      EthereumAddress.fromHex(myHex),
    );
  }

  /// Does any of my link-verified Solana wallets currently own [mint]?
  Future<bool> _verifySolanaMine(String mint) async {
    final myHex = PublicOS.myPublicosAddress;
    if (myHex == null) return false;
    try {
      final me = EthereumAddress.fromHex(myHex);
      final wallets = await PublicOSWallets.getWallets(me);
      for (final w in wallets) {
        if (w.protocol != PublicOSWallets.protoSolana) continue;
        if (!PublicOSWallets.verifySolanaWalletLink(account: me, wallet: w)) {
          continue;
        }
        final ownerB58 = utf8.decode(w.addressData);
        if (await PublicOSWallets.accountOwnsSolanaMint(ownerB58, mint)) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Save / delete ─────────────────────────────────────────────────────────

  String get _saveLabel {
    final l10n = context.l10n;
    if (_isLoading) return l10n.editProfileImageSheetSaving;
    if (_pending is _PendingNft || _isCard) {
      return _isCard
          ? l10n.editProfileImageSheetUseNft
          : l10n.editProfileImageSheetSaveNft;
    }
    return _isAvatar
        ? l10n.editProfileImageSheetSavePicture
        : l10n.editProfileImageSheetSaveBanner;
  }

  VoidCallback? get _saveAction {
    if (_isLoading) return null;
    final p = _pending;
    if (p is _PendingNft) return _handleSaveNft;
    if (p is _PendingImage) {
      // Card has no plain-image record path (no onSave).
      return _isCard ? null : _handleSaveImage;
    }
    return null;
  }

  Future<void> _handleSaveNft() async {
    final p = _pending;
    if (p is! _PendingNft) return;
    if (_isCard) {
      widget.onPick?.call(p.ref);
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final record = Record.asSettings(
      key: _isBanner ? 'profile.banner.nft' : 'profile.avatar.nft',
      value: p.ref.encode(),
      isSystem: true,
      expiration: DateTime.now().add(const Duration(days: 365)),
    );
    await _commitRecords(
        [record], context.l10n.editProfileImageSheetSaveNftError);
  }

  Future<void> _handleSaveImage() async {
    final p = _pending;
    if (p is! _PendingImage) return;
    final expiration = DateTime.now().add(const Duration(days: 365));
    final records = <Record>[
      Record.asSettings(
        key: _isAvatar ? 'profile.avatar' : 'profile.banner',
        value: p.url,
        isSystem: true,
        expiration: expiration,
      ),
      // Picking an image while an NFT is live means "display THIS" — and the
      // NFT pointer wins the render, so it must be cleared too. The image
      // lands first: if the clear fails mid-way, the profile still shows the
      // NFT (consistent, retryable), never an avatar gap.
      if (_hasNft)
        Record.asSettings(
          key: _isAvatar ? 'profile.avatar.nft' : 'profile.banner.nft',
          value: '',
          isSystem: true,
          expiration: expiration,
        ),
    ];
    await _commitRecords(
        records, context.l10n.editProfileImageSheetSaveImageError);
  }

  /// Shared save path for every avatar/banner write: lock the screen behind the
  /// canonical "Saving to chain..." overlay, await the chain write(s) + refresh
  /// (one onSave call per record, in order), then dismiss + pop.
  Future<void> _commitRecords(List<Record> records, String errorFallback) async {
    final l10n = context.l10n;
    final overlay = FullscreenOverlay.showTransaction(
        context, l10n.editProfileImageSheetSavingToChain);
    setState(() => _isLoading = true);
    try {
      for (final record in records) {
        await widget.onSave!(record);
      }
      _saved = true;
      overlay.dismiss();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      overlay.dismiss();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(l10n, e, fallback: errorFallback)),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final tokens = GlassTokens.of(dialogContext);
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          backgroundColor: tokens.surfaceElevated,
          title: Text(
            _isAvatar
                ? l10n.editProfileImageSheetRemoveAvatarConfirmTitle
                : l10n.editProfileImageSheetRemoveBannerConfirmTitle,
            style: TextStyle(color: tokens.starkWhite),
          ),
          content: Text(
            l10n.editProfileImageSheetRemoveConfirmBody,
            style: TextStyle(color: tokens.textDim),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.editProfileImageSheetRemoveAction,
                  style: TextStyle(color: tokens.fallbackAccent)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // An NFT wins the render, so removing clears the `.nft` pointer; otherwise
    // clear the classic URL record.
    final String key = _hasNft
        ? (_isAvatar ? 'profile.avatar.nft' : 'profile.banner.nft')
        : (_isAvatar ? 'profile.avatar' : 'profile.banner');
    final record = Record.asSettings(
      key: key,
      value: '',
      isSystem: true,
      expiration: DateTime.now().add(const Duration(days: 365)),
    );
    await _commitRecords([record], l10n.editProfileImageSheetRemoveImageError);
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    return Uri.tryParse(url)?.hasAbsolutePath ?? false;
  }

  // ── Preview (pinned, truthful) ─────────────────────────────────────────────
  //
  // Render order mirrors the profile itself with "pending" stacked on top:
  // pending selection → live NFT → live URL image → empty. When the shown
  // NFT is owned, an ownership legend (the canonical sparkles + label) sits
  // below the art — below, not overlaid, so it never overflows the small
  // avatar preview.

  Widget _buildPreview(GlassTokens tokens) {
    final bool wide = _isBanner;
    final double aspect = wide ? 3.0 : 1.0;
    final double widthFactor = wide ? 0.66 : 0.30;
    final radius = BorderRadius.circular(wide ? 12 : 14);

    Widget inner;
    bool ownedShown = false;

    final p = _pending;
    if (p is _PendingNft) {
      inner = _pendingNftInner(tokens, radius, wide, p);
      ownedShown = p.image != null && p.owned;
    } else if (p is _PendingImage) {
      inner = _imagePreviewInner(tokens, radius, p.url);
    } else if (_hasNft) {
      inner = _liveNftInner(tokens, radius, wide);
      ownedShown = (widget.currentNftImage ?? _liveNftImage) != null &&
          (widget.currentNftOwned ?? false);
    } else if (_hasExistingImage) {
      inner = _imagePreviewInner(tokens, radius, widget.currentImageUrl!.trim());
    } else {
      inner = _emptyPreviewInner(tokens, radius);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: AspectRatio(aspectRatio: aspect, child: inner),
          ),
        ),
        if (ownedShown)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _OwnedSparkleLegend(tokens: tokens),
          ),
      ],
    );
  }

  Widget _pendingNftInner(
      GlassTokens tokens, BorderRadius radius, bool wide, _PendingNft p) {
    if (p.image == null) {
      if (p.loading) return _spinnerBox(tokens, radius);
      return _msgBox(
          tokens,
          radius,
          p.error
              ? context.l10n.editProfileImageSheetNftLoadError
              : context.l10n.editProfileImageSheetNftResolving);
    }
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        NftVerifiedArt(
          image: p.image,
          verifiedOwner: p.owned,
          borderRadius: radius,
          fxSize: 44,
          focusedSparkles: true,
          sparkleCorner:
              wide ? SparkleCorner.bottomRight : SparkleCorner.topLeft,
        ),
        if (p.loading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: radius,
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                    child: PhigitalLoadingWidget(size: 24, showShadows: false)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _liveNftInner(GlassTokens tokens, BorderRadius radius, bool wide) {
    final image = widget.currentNftImage ?? _liveNftImage;
    if (image == null) {
      if (_liveNftLoading) return _spinnerBox(tokens, radius);
      return _msgBox(
          tokens,
          radius,
          _liveNftError
              ? context.l10n.editProfileImageSheetNftLoadError
              : context.l10n.editProfileImageSheetNftResolving);
    }
    return NftVerifiedArt(
      image: image,
      verifiedOwner: widget.currentNftOwned ?? false,
      borderRadius: radius,
      fxSize: 44,
      focusedSparkles: true,
      sparkleCorner: wide ? SparkleCorner.bottomRight : SparkleCorner.topLeft,
    );
  }

  Widget _imagePreviewInner(
      GlassTokens tokens, BorderRadius radius, String url) {
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        color: tokens.glassFill,
        child: ZeroCachedImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => const Center(
              child: PhigitalLoadingWidget(size: 22, showShadows: false)),
          errorWidget: (_, __, ___) => Center(
            child: Icon(Icons.broken_image_outlined,
                size: 28, color: tokens.fallbackAccent.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }

  Widget _emptyPreviewInner(GlassTokens tokens, BorderRadius radius) =>
      Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: radius,
          border: Border.all(color: tokens.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Icon(
            _isBanner ? Icons.panorama_rounded : Icons.account_circle_rounded,
            size: 34,
            color: tokens.textDim.withValues(alpha: 0.5),
          ),
        ),
      );

  Widget _spinnerBox(GlassTokens tokens, BorderRadius radius) => Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: radius,
          border: Border.all(color: tokens.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Center(
            child: PhigitalLoadingWidget(size: 28, showShadows: false)),
      );

  Widget _msgBox(GlassTokens tokens, BorderRadius radius, String msg) =>
      Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: radius,
          border: Border.all(color: tokens.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 12)),
          ),
        ),
      );

  // ── Landing ⇄ pane slide (the sheet body) ─────────────────────────────────

  Widget _buildBody(GlassTokens tokens) {
    // Build each side once per rebuild (not per animation frame). Keyed so the
    // pane keeps its element identity across the single↔stack swap at the
    // slide endpoints.
    final landing = KeyedSubtree(
        key: const ValueKey('landing'), child: _landingPane(tokens));
    final detail = KeyedSubtree(
        key: const ValueKey('pane'),
        child: _detailPane(tokens, _pane ?? _Pane.eth));

    // AnimatedSize eases the height between the (short) landing and the
    // (taller) source panes so the horizontal slide doesn't snap vertically.
    // It also animates the manual expander toggling inside a pane.
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: _stepCtrl,
        builder: (context, _) {
          final t = _stepCtrl.value;
          // At rest render a single side so the box sizes to it exactly.
          if (t <= 0.001) return landing;
          if (t >= 0.999) return detail;
          // Mid-slide: both sides ride one horizontal track — landing slides
          // out left (0 → -1·w), pane slides in from the right (+1·w → 0).
          return LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth;
              return ClipRect(
                child: Stack(
                  children: [
                    Transform.translate(
                      offset: Offset(-t * w, 0),
                      child: SizedBox(width: w, child: landing),
                    ),
                    Transform.translate(
                      offset: Offset((1 - t) * w, 0),
                      child: SizedBox(width: w, child: detail),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openPane(_Pane pane) {
    HapticFeedback.lightImpact();
    setState(() {
      _pane = pane;
      _manualOpen = false;
    });
    _stepCtrl.forward();
  }

  Widget _landingPane(GlassTokens tokens) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionLabel(tokens, l10n.editProfileImageSheetSectionSource),
        if (!_isCard) ...[
          _sourceButton(tokens,
              icon: Icons.image_outlined,
              label: l10n.editProfileImageSheetSourceImage,
              sublabel: l10n.editProfileImageSheetSourceImageSub,
              onTap: () => _openPane(_Pane.image)),
          const SizedBox(height: 8),
        ],
        _sourceButton(tokens,
            leading: const ChainIcon(protocol: PublicOSWallets.protoEvm, size: 18),
            label: l10n.editProfileImageSheetSourceEth,
            sublabel: l10n.editProfileImageSheetSourceEthSub,
            onTap: () => _openPane(_Pane.eth)),
        const SizedBox(height: 8),
        _sourceButton(tokens,
            leading:
                const ChainIcon(protocol: PublicOSWallets.protoSolana, size: 18),
            label: l10n.editProfileImageSheetSourceSolana,
            sublabel: l10n.editProfileImageSheetSourceSolanaSub,
            onTap: () => _openPane(_Pane.solana)),
        // Remove affordance — landing-scoped: it operates on the LIVE state
        // (clears the NFT pointer when one is set — it wins the render — else
        // the classic URL record), not on whatever is being composed.
        if (!_isCard && (_hasExistingImage || _hasNft)) ...[
          const SizedBox(height: 20),
          _RemoveRow(
            tokens: tokens,
            label: _hasNft
                ? (_isAvatar
                    ? context.l10n.editProfileImageSheetRemoveNftAvatar
                    : context.l10n.editProfileImageSheetRemoveNftBanner)
                : context.l10n.editProfileImageSheetRemoveFromProfile,
            sublabel: context.l10n.editProfileImageSheetClearsRecord,
            onTap: _isLoading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _handleDelete();
                  },
          ),
        ],
      ],
    );
  }

  Widget _detailPane(GlassTokens tokens, _Pane pane) {
    switch (pane) {
      case _Pane.image:
        return _imagePane(tokens);
      case _Pane.eth:
        return _ethPane(tokens);
      case _Pane.solana:
        return _solanaPane(tokens);
    }
  }

  Widget _imagePane(GlassTokens tokens) {
    final p = _pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(tokens, context.l10n.editProfileImageSheetSourceImage),
        const SizedBox(height: 8),
        ProfileImagePicker(
          controller: _urlController,
          isAvatar: _isAvatar,
          currentImageUrl: widget.currentImageUrl,
          enabled: !_isLoading,
          showPreview: false,
          onUploaded: (id) {
            _pendingUploadId = id;
            // The fresh upload is part of the library now — surface it in
            // the grid (server returns newest-first), already selected via
            // the mirrored URL.
            _uploadsKey.currentState?.reload();
          },
          onUploadDeleted: () => _pendingUploadId = null,
          noServerMessage: _isAvatar
              ? context.l10n.editProfileImageSheetNoServerAvatar
              : context.l10n.editProfileImageSheetNoServerBanner,
          dismissedWarningPrefsKey: _kNoServerWarningDismissedKey,
        ),
        const SizedBox(height: 18),
        _sectionLabel(
            tokens, context.l10n.editProfileImageSheetSectionYourUploads),
        SspMediaGrid(
          key: _uploadsKey,
          selectedUrl: p is _PendingImage ? p.url : null,
          onSelect: _onUploadSelect,
          enabled: !_isLoading,
        ),
      ],
    );
  }

  Widget _ethPane(GlassTokens tokens) {
    final myHex = PublicOS.myPublicosAddress;
    final p = _pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(tokens, context.l10n.editProfileImageSheetSourceEth),
        const SizedBox(height: 8),
        _sectionLabel(tokens, context.l10n.editProfileImageSheetSectionNftsEvm),
        if (myHex == null)
          Text(context.l10n.editProfileImageSheetNoActiveAccount,
              style: TextStyle(color: tokens.textDim, fontSize: 12))
        else
          NftPickerGrid(
            account: EthereumAddress.fromHex(myHex),
            protocol: NftProtocolFilter.evm,
            selectedKey: p is _PendingNft ? p.ref.toCaip19() : null,
            onSelect: _onGridSelect,
          ),
        const SizedBox(height: 14),
        _manualExpander(
          tokens,
          prompt: context.l10n.editProfileImageSheetManualPromptEth,
          fields: [
            _fieldLabel(tokens, context.l10n.editProfileImageSheetFieldChain),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _nftChain,
                  isExpanded: true,
                  dropdownColor: tokens.surfaceElevated,
                  style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: 14),
                  items: PublicOSContacts.nftChainNames.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: _isLoading
                      ? null
                      : (v) {
                          if (v != null) {
                            setState(() => _nftChain = v);
                            _onNftFieldChanged();
                          }
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel(tokens, context.l10n.editProfileImageSheetFieldContract),
            const SizedBox(height: 6),
            _nftTextField(tokens, _contractController, '0x…'),
            _ownedTokenStrip(tokens),
            const SizedBox(height: 12),
            _fieldLabel(tokens, context.l10n.editProfileImageSheetFieldTokenId),
            const SizedBox(height: 6),
            _nftTextField(tokens, _tokenIdController, '1234', number: true),
            const SizedBox(height: 10),
            _fallbackNote(tokens),
          ],
        ),
      ],
    );
  }

  Widget _solanaPane(GlassTokens tokens) {
    final myHex = PublicOS.myPublicosAddress;
    final p = _pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _backRow(tokens, context.l10n.editProfileImageSheetSourceSolana),
        const SizedBox(height: 8),
        _sectionLabel(
            tokens, context.l10n.editProfileImageSheetSectionNftsSolana),
        if (myHex == null)
          Text(context.l10n.editProfileImageSheetNoActiveAccount,
              style: TextStyle(color: tokens.textDim, fontSize: 12))
        else
          NftPickerGrid(
            account: EthereumAddress.fromHex(myHex),
            protocol: NftProtocolFilter.solana,
            selectedKey: p is _PendingNft ? p.ref.toCaip19() : null,
            onSelect: _onGridSelect,
          ),
        const SizedBox(height: 14),
        _manualExpander(
          tokens,
          prompt: context.l10n.editProfileImageSheetManualPromptSolana,
          fields: [
            _fieldLabel(
                tokens, context.l10n.editProfileImageSheetFieldSolanaMint),
            const SizedBox(height: 6),
            _nftTextField(tokens, _solanaMintController, 'e.g. 4Cma66…BeaF'),
            const SizedBox(height: 10),
            _fallbackNote(tokens),
          ],
        ),
      ],
    );
  }

  /// Collapsed manual-entry expander — a dashed one-liner that
  /// opens into the pane's manual fields. The pane-level AnimatedSize eases
  /// the height change.
  Widget _manualExpander(GlassTokens tokens,
      {required String prompt, required List<Widget> fields}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  setState(() => _manualOpen = !_manualOpen);
                },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderMedium),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(prompt,
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          color: tokens.textDim)),
                ),
                Text(context.l10n.editProfileImageSheetManualCta,
                    style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.connectedAccent)),
                Icon(
                  _manualOpen
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: tokens.connectedAccent,
                ),
              ],
            ),
          ),
        ),
        if (_manualOpen) ...[
          const SizedBox(height: 12),
          ...fields,
        ],
      ],
    );
  }

  Widget _sourceButton(
    GlassTokens tokens, {
    IconData? icon,
    Widget? leading,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: _isLoading ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 22,
                  child: Center(
                      child: leading ??
                          Icon(icon, size: 16, color: tokens.connectedAccent))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.starkWhite)),
                    const SizedBox(height: 2),
                    Text(sublabel,
                        style: TextStyle(
                            fontSize: 11,
                            color: tokens.textDim,
                            height: 1.25)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textDim),
            ],
          ),
        ),
      );

  Widget _backRow(GlassTokens tokens, String label) => GestureDetector(
        onTap: _isLoading ? null : () => _stepCtrl.reverse(),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(Icons.chevron_left_rounded,
                  size: 18, color: tokens.connectedAccent),
              const SizedBox(width: 2),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: tokens.connectedAccent)),
            ],
          ),
        ),
      );

  Widget _fieldLabel(GlassTokens tokens, String s) => Text(
        s,
        style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2),
      );

  Widget _nftTextField(
          GlassTokens tokens, TextEditingController c, String hint,
          {bool number = false}) =>
      TextField(
        controller: c,
        enabled: !_isLoading,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: TextStyle(
            fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: tokens.textDim),
          filled: true,
          fillColor: tokens.glassFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.connectedAccent)),
        ),
      );

  /// The owned-token strip that sits under the contract field.
  ///
  /// Renders nothing at all when the contract supports no enumeration — that is
  /// the majority case on mainnet and it is not a failure, so it must not look
  /// like one. The manual id field below stays the way in.
  Widget _ownedTokenStrip(GlassTokens tokens) {
    if (_ownedLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            const PhigitalLoadingWidget(size: 16, showShadows: false),
            const SizedBox(width: 8),
            Text(
              context.l10n.editProfileImageSheetTokensLoading,
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 11),
            ),
          ],
        ),
      );
    }
    if (_ownedIds.isEmpty) return const SizedBox.shrink();

    final selected = _tokenIdController.text.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.editProfileImageSheetTokensOwned(_ownedIds.length),
            style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 11),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ownedIds.map((id) {
              final isSel = id == selected;
              return GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        _tokenIdController.text = id; // fires _onNftFieldChanged
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSel
                        ? tokens.connectedAccent.withValues(alpha: 0.18)
                        : tokens.glassFill,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isSel
                          ? tokens.connectedAccent
                          : tokens.borderSubtle,
                    ),
                  ),
                  child: Text(
                    '#$id',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      color: isSel ? tokens.starkWhite : tokens.textDim,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _fallbackNote(GlassTokens tokens) => Text(
        context.l10n.editProfileImageSheetFallbackNote,
        style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            height: 1.3),
      );

  Widget _sectionLabel(GlassTokens tokens, String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(s.toUpperCase(),
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: tokens.connectedAccent)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: tokens.borderSubtle)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final title = _isAvatar
        ? context.l10n.editProfileImageSheetTitleAvatar
        : _isCard
            ? context.l10n.editProfileImageSheetTitleCard
            : context.l10n.editProfileImageSheetTitleBanner;
    final icon = _isAvatar
        ? Icons.account_circle_rounded
        : _isCard
            ? Icons.dashboard_customize_rounded
            : Icons.panorama_rounded;

    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        // DELTA (desktop): the client anchors this sheet to the bottom of the
        // screen and lets the user drag it up and down. Inside a centered glass
        // dialog there is no screen edge to drag against, so the sheet fills its
        // dialog exactly. Sizing is the only structural change to this body.
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
                _Header(
                  title: title,
                  icon: icon,
                  tokens: tokens,
                  onClose:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                ),
                // Preview is pinned below the header (outside the scroll view)
                // so the truthful LIVE/PENDING state stays in view while the
                // landing/pane content scrolls beneath it.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                  child: _buildPreview(tokens),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: _buildBody(tokens),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SystemAppActionButton(
                          label: _saveLabel,
                          icon: Icons.check_rounded,
                          onTap: _saveAction,
                        ),
                        if (_pending == null && !_isLoading) ...[
                          const SizedBox(height: 6),
                          Text(
                            context.l10n.editProfileImageSheetPickSourceHint,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 10,
                              letterSpacing: 0.6,
                              color: tokens.textDim.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;
  final GlassTokens tokens;
  final VoidCallback? onClose;

  const _Header({
    required this.title,
    required this.icon,
    required this.tokens,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: tokens.glassFill,
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: tokens.starkWhite,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.editProfileImageSheetClose,
            icon: Icon(Icons.close_rounded, color: tokens.textDim, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _RemoveRow extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final String sublabel;
  final VoidCallback? onTap;

  const _RemoveRow({
    required this.tokens,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.fallbackAccent;
    final disabled = onTap == null;
    final borderColor =
        disabled ? tokens.borderSubtle : accent.withValues(alpha: 0.45);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: disabled ? tokens.textDim : accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: disabled ? tokens.textDim : accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 11, color: tokens.textDim),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: tokens.textDim),
          ],
        ),
      ),
    );
  }
}

/// Ownership legend under the preview: the canonical NFT sparkles (the same
/// [NftSparklesPainter] pixels that twinkle on owned art) + "You own this
/// NFT". Using the sparkles as the mark — instead of a check icon — teaches
/// the sparkle/shimmer = ownership association.
///
/// The shared painter staggers its 6 pixels across the first ~4s of a 10s
/// cycle and stays dark for the rest; here the controller loops just that
/// active window (t · 0.4 over 4s) so the legend twinkles continuously.
class _OwnedSparkleLegend extends StatefulWidget {
  final GlassTokens tokens;

  const _OwnedSparkleLegend({required this.tokens});

  @override
  State<_OwnedSparkleLegend> createState() => _OwnedSparkleLegendState();
}

class _OwnedSparkleLegendState extends State<_OwnedSparkleLegend>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    // The painter clusters its pixels toward the top-left of its box; nudge
    // the whole burst toward the slot's center so it sits balanced against
    // the label (paint-only shift, sparkles may graze outside — that's their
    // "live overlay" character).
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Transform.translate(
            offset: const Offset(5, 5),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) =>
                  CustomPaint(painter: NftSparklesPainter(_anim.value * 0.4)),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          context.l10n.editProfileImageSheetOwnNft,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: tokens.starkWhite.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
