import 'package:publicos_desktop/widgets/mention_autocomplete.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/media_url_field.dart';
import 'package:publicos_desktop/widgets/profile/profile_post_card.dart';
import 'package:publicos_desktop/widgets/profile/profile_grid.dart';
import 'package:publicos_desktop/widgets/profile/record_button.dart';
import 'package:publicos_desktop/theme/theme_provider.dart' show PhigitalStyle;
import 'package:publicos_desktop/widgets/profile/content_card.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/utils/own_wallets.dart';
import 'package:publicos_desktop/widgets/profile/ssp_media_grid.dart';
import 'package:publicos_desktop/widgets/profile/edit_profile_image_sheet.dart';
import 'package:publicos_desktop/widgets/nft_verified_art.dart';
import 'package:publicos_desktop/widgets/profile/social_strip.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// The social picker = Core's fixed list ([SocialLinks]): what a
/// user can set is exactly what a profile shows, hints and links included.
final _platformKeys = [for (final l in SocialLinks.all) l.key];

String? _buildSocialLink(String key, String handle) =>
    SocialLinks.of(key)?.buildLink(handle);

/// Card swatches = the **same ramp the Account app offers for the accent
/// colour** (`PhigitalStyle.colorPresets`: 46 tones, dark -> light within each
/// hue family, neutrals last), so the two pickers offer one set of colours
/// instead of two. The transparent swatch leads and belongs
/// to cards only: it is the spacer, an invisible card used to organise the grid
/// (see `record_button._buildSpacerDisplay`), which an accent colour has no use
/// for.
const _cardColors = [Colors.transparent, ...PhigitalStyle.colorPresets];

/// Fills a fresh card starts on: the blue mid tone, and violet -> pink for a
/// first gradient. Picked from the ramp above, not invented beside it.
const _kDefaultCardColor = Color(0xFF3b82f6);
const _kDefaultGradientFrom = Color(0xFF8b5cf6);
const _kDefaultGradientTo = Color(0xFFec4899);

enum _Flow {
  typeSelector,
  social,
  socialConfigure,
  /// The content card: text + image in one (content_card.dart).
  card,
  nftCard,
  /// An app card (`cardKind:'app'`): content belongs to the app, SIZE belongs
  /// to the owner. The only thing this flow edits is the footprint.
  appCard,
  /// A pinned post (`cardKind:'post'`): the
  /// value is the post's URL and is never edited, so this flow edits the
  /// footprint only. With [CreateRecordSheet.onPin] set it is the
  /// "Pin to profile" sheet: same form, plus where the card lands.
  postCard,
  /// A card kind this build does not recognise. Renders an explanation and
  /// offers NO save action, so the sheet can never rewrite a record it does
  /// not understand into a text card.
  unsupported,
}

// ---------------------------------------------------------------------------
// CreateRecordSheet
// ---------------------------------------------------------------------------

/// Glass-dark, draggable-with-pinned-action bottom sheet for creating or
/// editing a profile record.
Future<void> showCreateRecordSheet(
  BuildContext context, {
  Record? record,
  required Function(Record) onSave,
  ValueChanged<Record?>? onPreviewChanged,
  EthereumAddress? orgAddress,
  Future<void> Function(Record record, bool toTop)? onPin,
}) {
  // DELTA (desktop): sheet -> centered glass dialog. Wider than the default
  // because this surface carries a live card preview above the form.
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.xl,
    builder: (_) => CreateRecordSheet(
      record: record,
      onSave: onSave,
      onPreviewChanged: onPreviewChanged,
      orgAddress: orgAddress,
      onPin: onPin,
    ),
  );
}

/// What a tap on a content card does.
enum _TapAction { none, link, tip }

/// A card's background: exactly one of these is stored.
enum _BgMode { color, gradient, image }

const _kZeroAddress = '0x0000000000000000000000000000000000000000';

class CreateRecordSheet extends StatefulWidget {
  final Record? record;
  final Function(Record) onSave;
  final ValueChanged<Record?>? onPreviewChanged;

  /// Set when this sheet edits an **org** record: the save routes through a
  /// governance vote, and an org can have only one open vote at a time. When
  /// set, the sheet prefetches the org's active-vote state and disables Save
  /// (with a legend) while a vote is already open. Null for own-profile edits.
  final EthereumAddress? orgAddress;

  /// Pin mode: set by "Pin to profile" on a post,
  /// with [record] a draft `cardKind:'post'` card. The sheet then offers
  /// *Pin to top / Pin to bottom* and hands the choice here instead of
  /// calling [onSave]. Null everywhere else.
  final Future<void> Function(Record record, bool toTop)? onPin;

  const CreateRecordSheet({
    super.key,
    this.record,
    required this.onSave,
    this.onPreviewChanged,
    this.orgAddress,
    this.onPin,
  });

  @override
  State<CreateRecordSheet> createState() => _CreateRecordSheetState();
}

class _CreateRecordSheetState extends State<CreateRecordSheet> {
  static const String _kNoServerWarningDismissedKey =
      'dismissed_no_ssp_warning_image_record';

  _Flow _flow = _Flow.typeSelector;

  // Social state
  String? _selectedPlatform;
  final _handleController = TextEditingController();

  // Card state: the one content card (text + image in one). Read and
  // written through `ContentCard`.
  final _titleController = TextEditingController();
  // Mentions: the body keeps `@[0xAddr]` tokens; the field shows names.
  final _descriptionController = mentionRecordController('');
  final _descriptionFocus = FocusNode();
  final _linkController = TextEditingController();
  Color _cardColor = _kDefaultCardColor;
  _BgMode _bgMode = _BgMode.color;
  bool get _cardGradientMode => _bgMode == _BgMode.gradient;
  Color _gradientFrom = _kDefaultGradientFrom;
  Color _gradientTo = _kDefaultGradientTo;
  int _gradientStop = 0; // which stop the swatches edit: 0 = from, 1 = to
  double _gradientAngle = 135;
  double _cardOpacity = 1.0;
  String? _cardImage;
  int _cardWidth = 2;
  int _cardHeight = 1;
  String? _cardId;

  // The image picker is a sub-page of the card form: the form slides out
  // left and the picker comes in from the right. It must not sit inline as a
  // box that scrolls on its own: on a phone the swipe would scroll every
  // upload before the sheet moved.
  bool _imagePage = false;
  double _formScrollOffset = 0;
  ScrollController? _sheetScroll;

  // What a tap on the card does: nothing, open the link, or
  // tip. A card carries a link or a tip, never both.
  _TapAction _tapAction = _TapAction.none;
  final _tipAddressController = TextEditingController();
  List<OwnWallet> _tipWallets = const [];
  bool _tipWalletsRequested = false;
  int _tipChainId = kOxChainId;
  String _tipToken = CardTip.ox;
  // The MainSafe lookup on the pay-to address (D16): a MainSafe exists only on
  // 4489, so one paid on another chain is lost. `_tipCheckedAddress` is the
  // lowercased address the answer belongs to; `_tipToIsMainSafe` is null while
  // the lookup runs or after it failed (`_tipCheckFailed`).
  String? _tipCheckedAddress;
  bool? _tipToIsMainSafe;
  bool _tipCheckFailed = false;

  // The Upload tile drives a hidden MediaUrlField (its staging: preview,
  // Low/HD, quota, confirm); the uploads grid is reloaded after an upload.
  final _uploadUrlController = TextEditingController();
  final ScrollController _swatchScrollCtrl = ScrollController();
  final _uploadFieldKey = GlobalKey<MediaUrlFieldState>();
  final _uploadsGridKey = GlobalKey<SspMediaGridState>();

  // NFT card state — the picker returns a ref, then this flow sizes it.
  NftAvatarRef? _nftCardRef;
  String? _nftCardImage; // resolved art (preview only; not written on save)
  bool _nftCardOwned = false;
  int _nftCardWidth = 2;
  int _nftCardHeight = 2;
  String? _nftCardId; // post-`card.` portion (incl. the `nft_` prefix)

  // App card state — size only. Everything else on the record is the app's
  // and is carried through untouched by `Record.updateVisual`.
  int _appCardWidth = 2;
  int _appCardHeight = 2;

  // Pinned-post state (the URL is never edited; the footprint is not the
  // owner's either: always full width, as tall as the post).
  bool _pinToTop = false;
  /// The post's own media in front of the background (PostCardMeta).
  bool _postMedia = false;

  // Tracks an upload made *in this session* that hasn't been committed via
  // Save yet. If the sheet closes without a successful Save we delete it.
  int? _pendingUploadId;
  bool _saved = false;

  // null = still resolving. true = SSP / custom server available, uploads OK.
  // false = no server — dashed upload button + dismissable banner.
  bool? _hasServer;
  bool _noServerWarningDismissed = false;

  // Org-record sheets only (widget.orgAddress != null). null = still resolving;
  // true = the org already has an open vote (Save disabled — a second
  // startVote would revert); false = clear to save.
  bool? _orgVoteActive;

  @override
  void initState() {
    super.initState();
    _initFromRecord();
    if (_flow == _Flow.card) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _scrollSwatchesToSelection());
    }
    _loadServerState();
    _loadOrgVoteState();
  }

  /// Prefetch the org's active-vote state when this sheet edits an org record,
  /// so Save can be gated before the user even fills the form. On error, fail
  /// open (let the eventual startVote surface any revert) rather than locking
  /// the user out on a transient RPC blip.
  Future<void> _loadOrgVoteState() async {
    final org = widget.orgAddress;
    if (org == null) return;
    bool active;
    try {
      // Parallel votes: Save is blocked only at the org's open-vote limit,
      // not whenever some vote is open.
      active = await PublicOSGovernance.isOrgAtOpenLimit(org.eip55With0x);
    } catch (_) {
      active = false;
    }
    if (mounted) setState(() => _orgVoteActive = active);
  }

  /// True while an org sheet can't save — a vote is open, or we're still
  /// resolving whether one is. Non-org sheets are never blocked.
  bool get _orgVoteBlocksSave =>
      widget.orgAddress != null && _orgVoteActive != false;

  Future<void> _loadServerState() async {
    final results = await Future.wait<dynamic>([
      PublicOSSsp.getActiveFeedServerUrl(),
      SharedPreferences.getInstance(),
    ]);
    if (!mounted) return;
    final activeUrl = results[0] as String?;
    final prefs = results[1] as SharedPreferences;
    setState(() {
      _hasServer = activeUrl != null;
      _noServerWarningDismissed =
          prefs.getBool(_kNoServerWarningDismissedKey) ?? false;
    });
  }

  Future<void> _dismissNoServerWarning() async {
    setState(() => _noServerWarningDismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kNoServerWarningDismissedKey, true);
    } catch (_) {}
  }

  void _initFromRecord() {
    final r = widget.record;
    if (r == null) return;

    final isNft = r.metadata['cardKind'] == 'nft';
    final isSocial = _platformKeys.contains(r.key);

    if (isSocial) {
      _selectedPlatform = r.key;
      _handleController.text = r.value;
      _flow = _Flow.socialConfigure;
    } else if (isNft) {
      // NFT card edit (resize) — cardKind wins over the isImageRecord flag it
      // also carries, so check it first.
      _nftCardRef = NftAvatarRef.tryParse(r.value);
      _nftCardImage = r.metadata['nftImage'] as String?;
      _nftCardOwned = r.metadata['nftOwned'] == true;
      _nftCardWidth = r.width;
      _nftCardHeight = r.height;
      _nftCardId = r.key.startsWith('card.') ? r.key.substring(5) : r.key;
      _flow = _Flow.nftCard;
      if (_nftCardImage == null && _nftCardRef != null) _resolveNftCardPreview();
    } else if (r.metadata['cardKind'] == PostCardMeta.kind) {
      // Pinned post: the content is not the owner's to edit (it is someone's
      // post, read live from its URL), and neither is its size: it is always
      // full width and as tall as the post. The owner edits the card's own
      // background (the content card's keys) and the post-media switch.
      final bgImage = r.metadata['image'];
      _cardImage = bgImage is String && bgImage.trim().isNotEmpty
          ? bgImage.trim()
          : null;
      final bgGradient = CardGradient.tryParse(r.metadata['gradient']);
      if (bgGradient != null) {
        _bgMode = _BgMode.gradient;
        _gradientFrom = bgGradient.from;
        _gradientTo = bgGradient.to;
        _gradientAngle = bgGradient.angle;
      }
      // No colour set means "no background of my own", not the content
      // card's blue default.
      _cardColor = r.color ?? Colors.transparent;
      if (_cardImage != null) _bgMode = _BgMode.image;
      _postMedia = r.metadata[PostCardMeta.postMedia] == true;
      _cardOpacity = (r.metadata['opacity'] as num?)?.toDouble() ?? 1.0;
      _flow = _Flow.postCard;
    } else if (r.metadata['cardKind'] == 'app') {
      // App card ("web_card") — authored by a third-party app, NOT by the
      // profile owner. Its picture and contents are the app's; its SIZE is
      // the owner's, and that is the whole editor here.
      //
      // The save path is `Record.updateVisual`, never a fresh `asProfile`:
      // the record's `value` (the AppCardRef) and every metadata key the app
      // wrote ride through untouched. View-time stamps (`appCard*`) are
      // dropped at `toChainValue`, so a resize writes exactly what the app
      // published plus the new footprint.
      _appCardWidth = r.width;
      _appCardHeight = r.height;
      _flow = _Flow.appCard;
    } else if (r.metadata['cardKind'] is String &&
        r.metadata['cardKind'] != 'text') {
      // A kind this build does not know. This branch exists to stop the
      // record being DESTROYED: without it an unrecognised kind falls through
      // to the text-card branch below, and `_saveCard` builds a FRESH
      // `Record.asProfile` with no merge of prior metadata while reusing the
      // existing `_cardId` — one tap-edit-save rewrites a structured card into
      // a plain text card in place. Refuse to open instead.
      _flow = _Flow.unsupported;
    } else {
      // Content card: a legacy text card, a legacy image card, or the merged
      // shape. One parser reads all three.
      final card = ContentCard.fromRecord(r);
      _titleController.text = card.title;
      _descriptionController.loadRaw(card.body);
      _linkController.text = card.link ?? '';
      final tip = card.tip;
      if (tip != null) {
        _tapAction = _TapAction.tip;
        _tipAddressController.text = tip.to;
        _tipChainId = tip.chainId;
        _tipToken = tip.token;
        // After the first frame: both lookups call setState.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadTipWallets();
          _checkTipAddress();
        });
      } else if (card.hasLink) {
        _tapAction = _TapAction.link;
      }
      _cardImage = card.image;
      final gradient = card.gradient;
      if (gradient != null) {
        _bgMode = _BgMode.gradient;
        _gradientFrom = gradient.from;
        _gradientTo = gradient.to;
        _gradientAngle = gradient.angle;
      }
      _cardColor = card.color ?? _kDefaultCardColor;
      // A card saved with an image (and maybe a colour under it, from before
      // the modes) opens in Image mode.
      if (_cardImage != null) _bgMode = _BgMode.image;
      _cardOpacity = card.opacity;
      _cardWidth = card.width;
      _cardHeight = card.height;
      _cardId = r.key.startsWith('card.') ? r.key.substring(5) : r.key;
      _flow = _Flow.card;
    }
  }

  @override
  void dispose() {
    widget.onPreviewChanged?.call(null);
    _handleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    _linkController.dispose();
    _tipAddressController.dispose();
    _uploadUrlController.dispose();
    _swatchScrollCtrl.dispose();
    final pending = _pendingUploadId;
    if (pending != null && !_saved) {
      // Fire and forget — sheet is gone, no UI to wait for.
      PublicOSSsp.deleteMedia(pending);
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Preview builders
  // ---------------------------------------------------------------------------

  void _pushSocialPreview() {
    if (_selectedPlatform == null) return;
    final handle = _handleController.text.trim();
    if (handle.isEmpty) {
      widget.onPreviewChanged?.call(null);
      return;
    }
    final name = socialDisplayNames[_selectedPlatform!] ?? _selectedPlatform!;
    final link = _buildSocialLink(_selectedPlatform!, handle);
    widget.onPreviewChanged?.call(Record.asProfile(
      key: _selectedPlatform!,
      value: handle,
      link: link,
      expiration: DateTime.now().add(const Duration(days: 365)),
      customMetadataAttributes: {'name': name, 'order': 0},
    ));
  }

  /// The form's card, through the one parser (content_card.dart).
  ContentCard _currentCard() => ContentCard(
        title: _titleController.text,
        body: _descriptionController.serialize(),
        image: _bgMode == _BgMode.image ? _cardImage : null,
        link: _tapAction == _TapAction.link ? _linkController.text : null,
        tip: _tapAction == _TapAction.tip ? _currentTip() : null,
        color: _bgMode == _BgMode.color ? _cardColor : null,
        gradient: _cardGradientMode
            ? CardGradient(
                from: _gradientFrom, to: _gradientTo, angle: _gradientAngle)
            : null,
        opacity: _cardOpacity,
        width: _cardWidth,
        height: _cardHeight,
      );

  /// The tip the form describes, or null while it is incomplete. The address
  /// is stored checksummed; the chain must be one the Send sheet can pay on.
  CardTip? _currentTip() {
    final a = _tipAddressController.text.trim();
    if (!CardTip.isAddress(a)) return null;
    if (_tipChain == null) return null;
    return CardTip(
      to: EthereumAddress.fromHex(a).eip55With0x,
      chainId: _tipChainId,
      token: _tipToken,
    );
  }

  ChainDef? get _tipChain {
    for (final c in kSendChains) {
      if (c.chainId == _tipChainId) return c;
    }
    return null;
  }

  static String _tipTokenId(TokenDef t) =>
      t.isOx ? CardTip.ox : (t.isNative ? CardTip.native : t.address!);

  /// D16: a MainSafe on any chain but 4489 cannot receive, so the save blocks.
  bool get _tipBlocked =>
      _tipChainId != kOxChainId &&
      _tipToIsMainSafe == true &&
      _tipCheckedAddress == _tipAddressController.text.trim().toLowerCase();

  /// Save is allowed when the tip is complete and, off 4489, the address has
  /// been checked and is not a MainSafe. On 4489 a MainSafe is the normal case.
  bool get _tipReady {
    if (_currentTip() == null) return false;
    if (_tipChainId == kOxChainId) return true;
    return _tipCheckedAddress ==
            _tipAddressController.text.trim().toLowerCase() &&
        _tipToIsMainSafe == false;
  }

  Future<void> _loadTipWallets() async {
    if (_tipWalletsRequested) return;
    _tipWalletsRequested = true;
    final myHex = PublicOS.myPublicosAddress;
    final owner = widget.orgAddress ??
        (myHex != null ? EthereumAddress.fromHex(myHex) : null);
    if (owner == null) return;
    final wallets = await loadOwnReceivingWallets(owner);
    if (!mounted) return;
    setState(() {
      _tipWallets = wallets;
      // A fresh tip defaults to the owner's main Safe, as a payment request does.
      if (_tipAddressController.text.trim().isEmpty && wallets.isNotEmpty) {
        final def = wallets.firstWhere(
          (w) => !w.isGroup && w.name == 'main',
          orElse: () => wallets.first,
        );
        _tipAddressController.text = def.address;
      }
    });
    _checkTipAddress();
    _pushCardPreview();
  }

  /// Is the pay-to address someone's MainSafe? `getSafeOwnerAccount` answers
  /// the zero address for "no", and null when the lookup itself failed.
  Future<void> _checkTipAddress() async {
    final a = _tipAddressController.text.trim();
    final key = a.toLowerCase();
    if (!CardTip.isAddress(a)) {
      setState(() {
        _tipCheckedAddress = null;
        _tipToIsMainSafe = null;
        _tipCheckFailed = false;
      });
      return;
    }
    if (_tipCheckedAddress == key && _tipToIsMainSafe != null) return;
    setState(() {
      _tipCheckedAddress = key;
      _tipToIsMainSafe = null;
      _tipCheckFailed = false;
    });
    final owner =
        await PublicOSSafe.getSafeOwnerAccount(EthereumAddress.fromHex(a));
    if (!mounted || _tipCheckedAddress != key) return;
    setState(() {
      if (owner == null) {
        _tipCheckFailed = true;
      } else {
        _tipToIsMainSafe = owner.eip55With0x.toLowerCase() != _kZeroAddress;
      }
    });
  }

  void _pushCardPreview() {
    if (_flow == _Flow.postCard) {
      _pushPostCardPreview();
      return;
    }
    widget.onPreviewChanged
        ?.call(_currentCard().toRecord(id: _cardId ?? ContentCard.newId()));
  }

  // ---------------------------------------------------------------------------
  // Save handlers
  // ---------------------------------------------------------------------------

  void _saveSocial() {
    if (_selectedPlatform == null) return;
    final handle = _handleController.text.trim();
    if (handle.isEmpty) return;
    final name = socialDisplayNames[_selectedPlatform!] ?? _selectedPlatform!;
    final link = _buildSocialLink(_selectedPlatform!, handle);
    _saved = true;
    widget.onSave(Record.asProfile(
      key: _selectedPlatform!,
      value: handle,
      link: link,
      expiration: DateTime.now().add(const Duration(days: 365)),
      customMetadataAttributes: {'name': name, 'order': 0},
    ));
  }

  // The chain takes at most Record.maxChainValueBytes per record (audit finding 4).
  // The fields have visible limits; the byte count covers what characters can't
  // (emoji, @mention tokens, the image and colours in the envelope).
  static const int _kTitleMax = 80;
  static const int _kDescriptionMax = 1000;
  static const int _kLinkMax = 512;

  int get _cardBytes =>
      _currentCard().toRecord(id: _cardId ?? ContentCard.newId()).chainValueBytes;

  Widget _cardSizeLine(GlassTokens tokens) {
    final l10n = context.l10n;
    final used = _cardBytes;
    const max = Record.maxChainValueBytes;
    final over = used > max;
    // Quiet until the card is three quarters full; amber when it can't be saved.
    if (!over && used < max * 3 ~/ 4) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        over ? l10n.createRecordPageCardTooLong(used - max) : l10n.createRecordPageCardSize(used, max),
        style: TextStyle(fontSize: 12, color: over ? Colors.amber : tokens.textDim),
      ),
    );
  }

  void _saveCard() {
    if (_cardBytes > Record.maxChainValueBytes) return;
    final id = _cardId ?? ContentCard.newId();
    _cardId = id;
    _saved = true;
    widget.onSave(_currentCard().toRecord(id: id));
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _goBack() {
    widget.onPreviewChanged?.call(null);
    setState(() {
      if (_flow == _Flow.socialConfigure) {
        _flow = _Flow.social;
      } else {
        _flow = _Flow.typeSelector;
      }
    });
  }

  bool get _isEditing => widget.record != null;
  bool get _showBack => !_isEditing && _flow != _Flow.typeSelector;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final (title, icon) = (_flow == _Flow.card || _flow == _Flow.postCard) && _imagePage
        ? (context.l10n.createRecordPageHeaderImage, Icons.image_outlined)
        : _headerFor(_flow);

    return DraggableScrollableSheet(
      // DELTA (desktop): the client anchors this sheet to the bottom of the
      // screen and lets the user drag it up and down. Inside a centered glass
      // dialog there is no screen edge to drag against, so the sheet fills its
      // dialog exactly. Sizing is the only structural change to this body.
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) {
        _sheetScroll = scrollCtrl;
        final pinnedAction = _buildPinnedAction(tokens);
        final fixedPreview = _buildFixedPreview(tokens);
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
                onBack: (_flow == _Flow.card || _flow == _Flow.postCard) && _imagePage
                    ? _closeImagePage
                    : (_showBack ? _goBack : null),
                onClose: () => Navigator.of(context).pop(),
              ),
              if (fixedPreview != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: fixedPreview,
                ),
                Container(height: 1, color: tokens.borderSubtle),
              ],
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_flow == _Flow.typeSelector) _buildTypeSelector(tokens),
                        if (_flow == _Flow.social) _buildPlatformGrid(tokens),
                        if (_flow == _Flow.socialConfigure)
                          _buildSocialConfigure(tokens),
                        if (_flow == _Flow.card) _buildCardPages(tokens),
                        if (_flow == _Flow.nftCard) _buildNftCardForm(tokens),
                        if (_flow == _Flow.appCard) _buildAppCardForm(tokens),
                        if (_flow == _Flow.postCard) _buildCardPages(tokens),
                        if (_flow == _Flow.unsupported)
                          _buildUnsupportedNotice(tokens),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              if (pinnedAction != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: pinnedAction,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Returns the fixed-top preview block for the current flow, or `null` for
  /// flows that don't need one. Text-card preview renders the in-progress
  /// record via `RecordButton` at its actual grid-cell aspect, matching the
  /// shape it will have on the profile grid.
  Widget? _buildFixedPreview(GlassTokens tokens) {
    if (_flow != _Flow.card) return null;
    return _CardPreview(
        record: _currentCard().toRecord(id: _cardId ?? 'preview'));
  }

  /// Returns the pinned-bottom action button for the current flow, or `null`
  /// for flows that have no save action (type-selector, platform-grid).
  Widget? _buildPinnedAction(GlassTokens tokens) {
    switch (_flow) {
      case _Flow.typeSelector:
      case _Flow.social:
        return null;
      case _Flow.socialConfigure:
        return _pinnedSaveAction(
          tokens: tokens,
          contentReady: _handleController.text.trim().isNotEmpty,
          onSave: _saveSocial,
        );
      case _Flow.card:
        // The picker is a sub-page: it saves nothing, a pick slides back.
        if (_imagePage) return null;
        return _pinnedSaveAction(
          tokens: tokens,
          // A transparent, empty card is a deliberate spacer: allow saving it.
          // Anything else needs something to show.
          contentReady: ((_bgMode == _BgMode.color && _cardColor.a == 0) ||
              _cardGradientMode ||
              (_bgMode == _BgMode.image && _cardImage != null) ||
              _titleController.text.trim().isNotEmpty ||
              _descriptionController.text.trim().isNotEmpty) &&
              (_tapAction != _TapAction.tip || _tipReady) &&
              _cardBytes <= Record.maxChainValueBytes,
          onSave: _saveCard,
        );
      case _Flow.nftCard:
        return _pinnedSaveAction(
          tokens: tokens,
          contentReady: _nftCardRef != null,
          onSave: _saveNftCard,
        );
      case _Flow.appCard:
        return _pinnedSaveAction(
          tokens: tokens,
          contentReady: widget.record != null,
          onSave: _saveAppCard,
        );
      case _Flow.postCard:
        if (_imagePage) return null;
        return _pinnedSaveAction(
          tokens: tokens,
          contentReady: widget.record != null,
          onSave: _savePostCard,
          label: widget.onPin != null
              ? context.l10n.createRecordPagePinAction
              : null,
          icon: widget.onPin != null ? Icons.push_pin_rounded : null,
        );
      // No save action at all — that is the point. There is no path from this
      // flow to a write.
      case _Flow.unsupported:
        return null;
    }
  }

  /// Builds the SAVE button for a flow, applying the org-vote gate: while an
  /// org vote is open (or still resolving) Save is disabled and a short legend
  /// explains why. Own-profile sheets pass straight through.
  Widget _pinnedSaveAction({
    required GlassTokens tokens,
    required bool contentReady,
    required VoidCallback onSave,
    String? label,
    IconData? icon,
  }) {
    final enabled = contentReady && !_orgVoteBlocksSave;
    final button = SystemAppActionButton(
      label: label ?? context.l10n.createRecordPageSave,
      icon: icon ?? Icons.check_rounded,
      onTap: enabled ? onSave : null,
    );
    // Non-org sheet, or org with no open vote — nothing to explain.
    if (widget.orgAddress == null || _orgVoteActive == false) return button;
    final legend = _orgVoteActive == null
        ? context.l10n.createRecordPageCheckingVote
        : context.l10n.createRecordPageVoteInProgress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            legend,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              color: tokens.textDim,
            ),
          ),
        ),
        button,
      ],
    );
  }

  (String, IconData) _headerFor(_Flow flow) {
    switch (flow) {
      case _Flow.typeSelector:
        return (
          _isEditing
              ? context.l10n.createRecordPageHeaderEdit
              : context.l10n.createRecordPageHeaderAdd,
          Icons.add_rounded
        );
      case _Flow.social:
        return (context.l10n.createRecordPageHeaderPickPlatform,
            Icons.hub_rounded);
      case _Flow.socialConfigure:
        final key = _selectedPlatform;
        final name = key == null
            ? context.l10n.createRecordPageHeaderSocial
            : (socialDisplayNames[key] ?? key).toUpperCase();
        return (name, Icons.hub_rounded);
      case _Flow.card:
        return (context.l10n.createRecordPageHeaderCard,
            Icons.dashboard_customize_rounded);
      case _Flow.nftCard:
        return (context.l10n.createRecordPageHeaderNftCard,
            Icons.diamond_rounded);
      case _Flow.appCard:
        return (context.l10n.createRecordPageHeaderAppCard,
            Icons.widgets_rounded);
      case _Flow.postCard:
        return (context.l10n.createRecordPageHeaderPostCard,
            Icons.push_pin_rounded);
      case _Flow.unsupported:
        return (context.l10n.createRecordPageHeaderUnknownCard,
            Icons.help_outline_rounded);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Type selector
  // ---------------------------------------------------------------------------

  Widget _buildTypeSelector(GlassTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _typeCardRow(
          tokens: tokens,
          icon: Icons.hub_rounded,
          label: context.l10n.createRecordPageTypeSocialLabel,
          description: context.l10n.createRecordPageTypeSocialDesc,
          onTap: () => setState(() => _flow = _Flow.social),
          example: _socialExample(tokens),
        ),
        const SizedBox(height: 10),
        _typeCardRow(
          tokens: tokens,
          icon: Icons.dashboard_customize_rounded,
          label: context.l10n.createRecordPageTypeCardLabel,
          description: context.l10n.createRecordPageTypeCardDesc,
          onTap: () {
            setState(() => _flow = _Flow.card);
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _scrollSwatchesToSelection());
          },
          example: _textCardExample(tokens),
        ),
        const SizedBox(height: 10),
        _typeCardRow(
          tokens: tokens,
          icon: Icons.diamond_rounded,
          label: context.l10n.createRecordPageTypeNftLabel,
          description: context.l10n.createRecordPageTypeNftDesc,
          onTap: _openNftCardPicker,
          example: _imageExample(tokens),
        ),
      ],
    );
  }

  /// NFT card: open the shared picker as a chooser (NFT-only), then on pick
  /// build a `card.nft_*` record with `cardKind:'nft'`. There's no in-page flow
  /// for it — the picker IS the form. `fetchContact` resolves the art + verifies
  /// ownership (against the record owner) into the record metadata at view time.
  /// Open the shared picker (NFT-only) as a chooser; on pick, enter the
  /// `_Flow.nftCard` sizing form (preview + width/height) just like the image
  /// flow. The verdict shown is for preview only — `fetchContact` recomputes
  /// the real one (against the record owner) when the card is next viewed.
  Future<void> _openNftCardPicker() async {
    HapticFeedback.lightImpact();
    NftAvatarRef? picked;
    await showEditProfileImageSheetAsPicker(
      context,
      onPick: (ref) => picked = ref,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _nftCardRef = picked;
      _nftCardImage = null;
      _nftCardOwned = false;
      _nftCardId = null;
      _nftCardWidth = 2;
      _nftCardHeight = 2;
      _flow = _Flow.nftCard;
    });
    _resolveNftCardPreview();
  }

  /// Resolve the picked NFT's art + ownership (against my account, or the org)
  /// for the form preview + the live grid preview.
  Future<void> _resolveNftCardPreview() async {
    final ref = _nftCardRef;
    if (ref == null) return;
    try {
      final meta = ref.isSolana
          ? await PublicOSWallets.resolveSolanaNftData(ref.mint!)
          : await PublicOSContacts.resolveNftAvatarData(ref);
      final img = (meta?['image'] ?? meta?['image_url']) as String?;
      final myHex = PublicOS.myPublicosAddress;
      final owner = widget.orgAddress ??
          (myHex != null ? EthereumAddress.fromHex(myHex) : null);
      final owned = owner != null
          ? await PublicOSContacts.verifyNftOwnership(ref, owner)
          : false;
      if (!mounted) return;
      setState(() {
        _nftCardImage = (img != null && img.isNotEmpty) ? img : null;
        _nftCardOwned = owned;
      });
      _pushNftCardPreview();
    } catch (_) {
      // leave preview empty → NftVerifiedArt shows its fallback
    }
  }

  void _pushNftCardPreview() {
    final ref = _nftCardRef;
    if (ref == null) {
      widget.onPreviewChanged?.call(null);
      return;
    }
    final id = _nftCardId ?? 'nft_preview';
    widget.onPreviewChanged?.call(Record.asProfile(
      key: 'card.$id',
      value: ref.encode(),
      expiration: DateTime.now().add(const Duration(days: 365)),
      width: _nftCardWidth,
      height: _nftCardHeight,
      noTitle: true,
      customMetadataAttributes: {
        'cardKind': 'nft',
        'name': ref.isSolana ? 'NFT' : 'NFT #${ref.tokenId}',
        'isImageRecord': true,
        // Preview-only: carry the resolved art so the grid preview paints now.
        // NOT written on save — fetchContact recomputes/persists the verdict.
        if (_nftCardImage != null) 'nftImage': _nftCardImage,
        'nftOwned': _nftCardOwned,
      },
    ));
  }

  void _saveNftCard() {
    final ref = _nftCardRef;
    if (ref == null) return;
    final id = _nftCardId ??
        'nft_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    _nftCardId = id;
    _saved = true;
    widget.onSave(Record.asProfile(
      key: 'card.$id',
      value: ref.encode(),
      expiration: DateTime.now().add(const Duration(days: 365)),
      width: _nftCardWidth,
      height: _nftCardHeight,
      noTitle: true,
      customMetadataAttributes: {
        'cardKind': 'nft',
        'name': ref.isSolana ? 'NFT' : 'NFT #${ref.tokenId}',
        // Keeps RecordButton's Hero / overlay behavior consistent with images.
        'isImageRecord': true,
      },
    ));
  }

  // ---------------------------------------------------------------------------
  // App card — size only
  // ---------------------------------------------------------------------------

  /// Push the resized record into the live grid preview, exactly as it will
  /// be saved: same key, same value, same app metadata, new footprint.
  void _pushAppCardPreview() {
    final r = widget.record;
    if (r == null) return;
    widget.onPreviewChanged?.call(
        r.updateVisual(width: _appCardWidth, height: _appCardHeight));
  }

  /// A resize is a metadata edit and nothing else. `updateVisual` copies the
  /// record and rewrites `width`/`height`; `toChainValue` drops the view-time
  /// `appCard*` stamps on the way out. The app's `value` is never touched.
  void _saveAppCard() {
    final r = widget.record;
    if (r == null) return;
    _saved = true;
    widget.onSave(r.updateVisual(width: _appCardWidth, height: _appCardHeight));
  }

  // ---------------------------------------------------------------------------
  // Pinned post — size only (+ placement when pinning)
  // ---------------------------------------------------------------------------

  /// The card as it will be written: same key, same URL value, every other
  /// metadata key carried, then the footprint and the background (the
  /// content card's keys: `color` = the colour or the gradient's first stop,
  /// `gradient`, `image`, `opacity`). A transparent colour with no gradient
  /// and no image writes NO background, so the card keeps the post's look.
  Record? _postCardRecord() {
    final r = widget.record;
    if (r == null) return null;
    final m = Map<String, dynamic>.from(r.metadata)
      ..['opacity'] = _cardOpacity
      ..remove('image')
      ..remove('gradient')
      ..remove('color');
    switch (_bgMode) {
      case _BgMode.image:
        if (_cardImage != null) m['image'] = _cardImage;
      case _BgMode.gradient:
        m['gradient'] = CardGradient(
                from: _gradientFrom, to: _gradientTo, angle: _gradientAngle)
            .toMetadata();
        m['color'] = _gradientFrom.toARGB32();
      case _BgMode.color:
        if (_cardColor.a > 0) m['color'] = _cardColor.toARGB32();
    }
    if (_postMedia) {
      m[PostCardMeta.postMedia] = true;
    } else {
      m.remove(PostCardMeta.postMedia);
    }
    return r.copyWith(metadata: m);
  }

  void _pushPostCardPreview() {
    final r = _postCardRecord();
    if (r != null) widget.onPreviewChanged?.call(r);
  }

  /// Same shape as the app card's save: `updateVisual` keeps the key, the
  /// URL and every metadata key, and rewrites the footprint. In pin mode the
  /// placement goes to [CreateRecordSheet.onPin], which owns the rank.
  void _savePostCard() {
    final r = _postCardRecord();
    if (r == null) return;
    _saved = true;
    final onPin = widget.onPin;
    if (onPin != null) {
      onPin(r, _pinToTop);
    } else {
      widget.onSave(r);
    }
  }

  Widget _buildPostCardForm(GlassTokens tokens) {
    final l10n = context.l10n;
    final url = widget.record?.value ?? '';
    final draft = _postCardRecord();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PostCardPreview(
          url: url,
          child: draft == null
              ? ProfilePostCard(url: url, interactive: false)
              : ProfilePostCard.fromRecord(draft, interactive: false),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.createRecordPagePostCardSizeLead,
          style: TextStyle(color: tokens.textDim, fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 16),
        // The pointer, shown and never editable: the card IS this URL.
        _label(l10n.createRecordPagePostCardLink, tokens),
        const SizedBox(height: 6),
        _PostLinkRow(url: url, tokens: tokens),
        const SizedBox(height: 14),
        _PostMediaSwitch(
          value: _postMedia,
          tokens: tokens,
          onChanged: (v) {
            setState(() => _postMedia = v);
            _pushPostCardPreview();
          },
        ),
        const SizedBox(height: 18),
        _labelRow(l10n.createRecordPageLabelBackground,
            '${(_cardOpacity * 100).round()}%', tokens),
        const SizedBox(height: 8),
        _buildBackgroundModeToggle(tokens),
        const SizedBox(height: 10),
        if (_bgMode == _BgMode.image) ...[
          _buildImageRow(tokens),
          const SizedBox(height: 10),
        ] else ...[
          if (_cardGradientMode) ...[
            _buildGradientStops(tokens),
            const SizedBox(height: 10),
          ],
          _buildColorPicker(tokens),
        ],
        _buildOpacitySlider(tokens),
        if (widget.onPin != null) ...[
          const SizedBox(height: 20),
          _label(context.l10n.createRecordPagePinPlacement, tokens),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final top in const [true, false]) ...[
                Expanded(
                  child: _PlacementChip(
                    label: top
                        ? context.l10n.createRecordPagePinTop
                        : context.l10n.createRecordPagePinBottom,
                    icon: top
                        ? Icons.vertical_align_top_rounded
                        : Icons.vertical_align_bottom_rounded,
                    selected: _pinToTop == top,
                    tokens: tokens,
                    onTap: () => setState(() => _pinToTop = top),
                  ),
                ),
                if (top) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAppCardForm(GlassTokens tokens) {
    final r = widget.record;
    final slug = r?.metadata[AppCardMeta.appSlug] as String? ?? '';
    final image = r?.metadata[AppCardMeta.image] as String?;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GridCellPreview(
          width: _appCardWidth,
          height: _appCardHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image == null || image.isEmpty
                ? Container(
                    color: tokens.glassFill,
                    alignment: Alignment.center,
                    child: Icon(Icons.widgets_rounded,
                        size: 28, color: tokens.textDim),
                  )
                // The still is a full-bleed texture by the card protocol's own
                // rule, so `cover` at any footprint is what the grid will show.
                : ZeroCachedImage(imageUrl: image, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.createRecordPageAppCardSizeLead(
              slug.isEmpty ? context.l10n.createRecordPageAppCardGenericApp : slug),
          style: TextStyle(color: tokens.textDim, fontSize: 12.5, height: 1.5),
        ),
        const SizedBox(height: 16),
        _buildSizePicker(
          tokens: tokens,
          width: _appCardWidth,
          height: _appCardHeight,
          maxWidth: 4,
          maxHeight: 4,
          onWidthChanged: (w) {
            setState(() => _appCardWidth = w);
            _pushAppCardPreview();
          },
          onHeightChanged: (h) {
            setState(() => _appCardHeight = h);
            _pushAppCardPreview();
          },
        ),
      ],
    );
  }

  /// Shown for a card kind this build does not recognise. Deliberately has no
  /// form and no save action — the sheet's only job here is to explain and get
  /// out of the way, because the alternative (falling through to the text-card
  /// form) would silently overwrite the record.
  Widget _buildUnsupportedNotice(GlassTokens tokens) {
    final kind = widget.record?.metadata['cardKind'] as String?;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline_rounded,
                      size: 18, color: tokens.textDim),
                  const SizedBox(width: 8),
                  Text(
                    kind == null || kind.isEmpty ? 'card' : kind,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.createRecordPageUnknownCardBody,
                style: TextStyle(
                    color: tokens.textDim, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.createRecordPageUnknownCardHint,
                style: TextStyle(
                    color: tokens.textDim.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNftCardForm(GlassTokens tokens) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GridCellPreview(
          width: _nftCardWidth,
          height: _nftCardHeight,
          child: NftVerifiedArt(
            image: _nftCardImage,
            verifiedOwner: _nftCardOwned,
            borderRadius: BorderRadius.circular(12),
            fxSize: 40,
            focusedSparkles: true,
          ),
        ),
        const SizedBox(height: 16),
        _buildSizePicker(
          tokens: tokens,
          width: _nftCardWidth,
          height: _nftCardHeight,
          maxWidth: 4,
          maxHeight: 4,
          onWidthChanged: (w) {
            setState(() => _nftCardWidth = w);
            _pushNftCardPreview();
          },
          onHeightChanged: (h) {
            setState(() => _nftCardHeight = h);
            _pushNftCardPreview();
          },
        ),
      ],
    );
  }

  /// Full-width clickable row: icon chip + (label / description) + example
  /// preview pinned to the right. Replaces the old 3-up squashed grid.
  Widget _typeCardRow({
    required GlassTokens tokens,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
    required Widget example,
  }) {
    final accent = tokens.connectedAccent;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: tokens.surfaceElevated,
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: tokens.starkWhite,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: tokens.textDim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 76, height: 76, child: example),
          ],
        ),
      ),
    );
  }

  /// 2×2 grid of mini social icons on a glass card — mirrors how the
  /// profile's social strip lays out per-platform glyphs.
  Widget _socialExample(GlassTokens tokens) {
    const sampleKeys = ['com.twitter', 'com.instagram', 'com.github', 'app.bsky'];
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sampleKeys
                .sublist(0, 2)
                .map((k) => _miniSocial(k, tokens))
                .toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sampleKeys
                .sublist(2, 4)
                .map((k) => _miniSocial(k, tokens))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _miniSocial(String key, GlassTokens tokens) {
    final brand = socialBrandColors[key] ?? tokens.starkWhite;
    final icon = socialIconForKey(key, size: 20, color: brand);
    return icon ?? Icon(Icons.language_rounded, size: 20, color: brand);
  }

  /// Mini text card filled with the user's `color` record — same gesture
  /// the real text-card render uses on the profile grid.
  Widget _textCardExample(GlassTokens tokens) {
    final colorValue =
        AppStateNotifier.currentMyContact?.getRecordValue('color');
    Color fill = tokens.connectedAccent;
    if (colorValue != null) {
      try {
        fill = Color(int.parse(colorValue));
      } catch (_) {}
    }
    final isDark = fill.computeLuminance() < 0.5;
    final fg = isDark ? Colors.white : Colors.black;
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          context.l10n.createRecordPageExampleTitle,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: fg,
          ),
        ),
      ),
    );
  }

  /// Large image icon on a glass card — quick read of "this slot is a
  /// photo or graphic".
  Widget _imageExample(GlassTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 40,
          color: tokens.starkWhite.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2a — Social: platform grid
  // ---------------------------------------------------------------------------

  Widget _buildPlatformGrid(GlassTokens tokens) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _platformKeys.length,
      itemBuilder: (context, index) {
        final key = _platformKeys[index];
        final name = socialDisplayNames[key] ?? key;
        final brandColor = socialBrandColors[key] ?? tokens.textDim;
        final icon = socialIconForKey(key, size: 22, color: brandColor);

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedPlatform = key;
              _handleController.clear();
              _flow = _Flow.socialConfigure;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon ?? Icon(Icons.language_rounded, size: 22, color: brandColor),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(fontSize: 9, color: tokens.starkWhite),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2a — Social: configure handle
  // ---------------------------------------------------------------------------

  Widget _buildSocialConfigure(GlassTokens tokens) {
    final key = _selectedPlatform!;
    final name = socialDisplayNames[key] ?? key;
    final brandColor = socialBrandColors[key] ?? tokens.textDim;
    final icon = socialIconForKey(key, size: 20, color: brandColor);
    final hint = SocialLinks.of(key)?.hint ?? context.l10n.createRecordPageHandleHint;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon ?? Icon(Icons.language_rounded, size: 20, color: brandColor),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              key,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: tokens.textDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label(context.l10n.createRecordPageLabelHandle, tokens),
        const SizedBox(height: 6),
        _inputField(
          tokens: tokens,
          controller: _handleController,
          hint: hint,
          onChanged: (_) {
            setState(() {});
            _pushSocialPreview();
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2b — Text Card
  // ---------------------------------------------------------------------------

  /// The card form and its image sub-page, sliding horizontally: forward
  /// (to the picker) the form leaves left and the picker enters from the
  /// right; back reverses. 260 ms in / 220 ms out, easeOutCubic (the styling
  /// guide's slide-route timing).
  Widget _buildCardPages(GlassTokens tokens) {
    final forward = _imagePage;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: forward ? 260 : 220),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey<bool>(_imagePage);
          final dir = forward ? 1.0 : -1.0;
          final begin = Offset(incoming ? dir : -dir, 0);
          return SlideTransition(
            position: Tween(begin: begin, end: Offset.zero).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeOutCubic.flipped,
              ),
            ),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<bool>(_imagePage),
          child: _imagePage
              ? _buildImagePage(tokens)
              : (_flow == _Flow.postCard
                  ? _buildPostCardForm(tokens)
                  : _buildCardForm(tokens)),
        ),
      ),
    );
  }

  void _openImagePage() {
    HapticFeedback.lightImpact();
    final sc = _sheetScroll;
    _formScrollOffset = sc != null && sc.hasClients ? sc.offset : 0;
    setState(() => _imagePage = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sc != null && sc.hasClients) sc.jumpTo(0);
    });
  }

  void _closeImagePage() {
    if (!_imagePage) return;
    final sc = _sheetScroll;
    setState(() => _imagePage = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (sc != null && sc.hasClients) {
        sc.jumpTo(_formScrollOffset.clamp(0, sc.position.maxScrollExtent));
      }
    });
  }

  /// Content first (title, text, what a tap does), then the look (image,
  /// background), then the footprint.
  Widget _buildCardForm(GlassTokens tokens) {
    final l10n = context.l10n;
    void refresh() {
      setState(() {});
      _pushCardPreview();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l10n.createRecordPageLabelTitle, tokens),
        const SizedBox(height: 6),
        _inputField(
          tokens: tokens,
          controller: _titleController,
          hint: l10n.createRecordPageCardTitleHint,
          maxLength: _kTitleMax,
          onChanged: (_) => refresh(),
        ),
        const SizedBox(height: 12),
        _label(l10n.createRecordPageLabelDescription, tokens),
        const SizedBox(height: 6),
        _inputField(
          tokens: tokens,
          controller: _descriptionController,
          focusNode: _descriptionFocus,
          hint: l10n.createRecordPageDescriptionHint,
          maxLines: 2,
          maxLength: _kDescriptionMax,
          onChanged: (_) => refresh(),
        ),
        MentionAutocomplete(controller: _descriptionController, focusNode: _descriptionFocus),
        const SizedBox(height: 12),
        _label(l10n.createRecordPageLabelWhenTapped, tokens),
        const SizedBox(height: 6),
        _buildTapActionToggle(tokens),
        if (_tapAction == _TapAction.link) ...[
          const SizedBox(height: 8),
          _inputField(
            tokens: tokens,
            controller: _linkController,
            hint: 'https://...',
            maxLength: _kLinkMax,
            onChanged: (_) => refresh(),
          ),
        ],
        if (_tapAction == _TapAction.tip) ...[
          const SizedBox(height: 10),
          _buildTipForm(tokens, refresh),
        ],
        _cardSizeLine(tokens),
        const SizedBox(height: 18),
        _labelRow(l10n.createRecordPageLabelBackground,
            '${(_cardOpacity * 100).round()}%', tokens),
        const SizedBox(height: 8),
        _buildBackgroundModeToggle(tokens),
        const SizedBox(height: 10),
        if (_bgMode == _BgMode.image) ...[
          _buildImageRow(tokens),
          const SizedBox(height: 10),
        ] else ...[
          if (_cardGradientMode) ...[
            _buildGradientStops(tokens),
            const SizedBox(height: 10),
          ],
          _buildColorPicker(tokens),
        ],
        _buildOpacitySlider(tokens),
        const SizedBox(height: 18),
        _buildSizePicker(
          tokens: tokens,
          width: _cardWidth,
          height: _cardHeight,
          maxWidth: 4,
          maxHeight: 4,
          onWidthChanged: (w) {
            setState(() => _cardWidth = w);
            _pushCardPreview();
          },
          onHeightChanged: (h) {
            setState(() => _cardHeight = h);
            _pushCardPreview();
          },
        ),
      ],
    );
  }

  /// One row for the image: a thumbnail (or an empty tile), and a way into
  /// the picker sub-page.
  Widget _buildImageRow(GlassTokens tokens) {
    final l10n = context.l10n;
    final img = _cardImage;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openImagePage,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: img != null
                    ? ZeroCachedImage(imageUrl: img, fit: BoxFit.cover)
                    : ColoredBox(
                        color: tokens.surfaceElevated,
                        child: Icon(Icons.image_outlined,
                            size: 18, color: tokens.textDim),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                img != null
                    ? l10n.createRecordPageImageChange
                    : l10n.createRecordPageImageNone,
                style: TextStyle(
                  fontSize: 13,
                  color: img != null ? tokens.starkWhite : tokens.textDim,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tokens.textDim),
          ],
        ),
      ),
    );
  }

  /// Nothing / Link / Tip, styled as the background mode toggle.
  Widget _buildTapActionToggle(GlassTokens tokens) {
    final l10n = context.l10n;
    Widget segment(String label, _TapAction action) {
      final selected = _tapAction == action;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (selected) return;
            HapticFeedback.lightImpact();
            setState(() => _tapAction = action);
            if (action == _TapAction.tip) _loadTipWallets();
            _pushCardPreview();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? tokens.surfaceElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? tokens.starkWhite : tokens.textDim,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          segment(l10n.createRecordPageTapNothing, _TapAction.none),
          const SizedBox(width: 3),
          segment(l10n.createRecordPageTapLink, _TapAction.link),
          const SizedBox(width: 3),
          segment(l10n.createRecordPageTapTip, _TapAction.tip),
        ],
      ),
    );
  }

  /// The tip action's form: who is paid (one of the owner's wallets, or a
  /// typed address), and on which chain + token. No amount, ever.
  Widget _buildTipForm(GlassTokens tokens, VoidCallback refresh) {
    final l10n = context.l10n;
    final typed = _tipAddressController.text.trim();
    final chain = _tipChain;

    void onAddress() {
      refresh();
      _checkTipAddress();
    }

    Widget walletRow(OwnWallet w) {
      final selected = typed.toLowerCase() == w.address.toLowerCase();
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            _tipAddressController.text = w.address;
            onAddress();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? tokens.connectedAccent : tokens.borderSubtle,
              ),
            ),
            child: Row(
              children: [
                w.contact != null
                    ? GlassContactIcon(contact: w.contact!, size: 28)
                    : GlassContactIcon(address: w.address, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: tokens.starkWhite),
                      ),
                      Text(
                        _tipShort(w.address),
                        style: TextStyle(fontSize: 11, color: tokens.textDim),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: tokens.connectedAccent),
              ],
            ),
          ),
        ),
      );
    }

    Widget chip(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: () {
          if (selected) return;
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? tokens.surfaceElevated : tokens.glassFill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? tokens.connectedAccent : tokens.borderSubtle,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? tokens.starkWhite : tokens.textDim,
            ),
          ),
        ),
      );
    }

    // A hand-written record may name a token outside our list; keep it
    // selectable rather than silently swapping it.
    final chainTokens = chain?.tokens ?? const <TokenDef>[];
    final tokenKnown = chainTokens.any((t) => _tipTokenId(t) == _tipToken);

    String? status;
    Color? statusColor;
    if (typed.isNotEmpty && !CardTip.isAddress(typed)) {
      status = l10n.createRecordPageTipInvalidAddress;
      statusColor = tokens.softDanger;
    } else if (_tipBlocked) {
      status = l10n.unifiedSendSheetSafeOtherNetwork;
      statusColor = const Color(0xFFFFAB40);
    } else if (_tipChainId != kOxChainId && CardTip.isAddress(typed)) {
      if (_tipCheckFailed) {
        status = l10n.createRecordPageTipCheckFailed;
        statusColor = tokens.softDanger;
      } else if (_tipToIsMainSafe == null) {
        status = l10n.createRecordPageTipChecking;
        statusColor = tokens.textDim;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(l10n.createRecordPageLabelTipPayTo, tokens),
        const SizedBox(height: 6),
        ..._tipWallets.map(walletRow),
        _inputField(
          tokens: tokens,
          controller: _tipAddressController,
          hint: l10n.createRecordPageTipAddressHint,
          onChanged: (_) => onAddress(),
        ),
        const SizedBox(height: 12),
        _label(l10n.createRecordPageLabelTipNetwork, tokens),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final c in kSendChains)
              chip(c.name, c.chainId == _tipChainId, () {
                setState(() {
                  _tipChainId = c.chainId;
                  _tipToken = _tipTokenId(c.defaultToken);
                });
                onAddress();
              }),
          ],
        ),
        if (chainTokens.length > 1 || !tokenKnown) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in chainTokens)
                chip(t.symbol, _tipTokenId(t) == _tipToken, () {
                  setState(() => _tipToken = _tipTokenId(t));
                  refresh();
                }),
              if (!tokenKnown && chain != null)
                chip(_tipShort(_tipToken), true, () {}),
            ],
          ),
        ],
        if (status != null) ...[
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.createRecordPageTipNoAmount,
          style: TextStyle(
            fontSize: 11,
            color: tokens.textDim.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  static String _tipShort(String a) =>
      a.length < 12 ? a : '${a.substring(0, 6)}…${a.substring(a.length - 4)}';

  Widget _labelRow(String label, String trailing, GlassTokens tokens) {
    return Row(
      children: [
        _label(label, tokens),
        const Spacer(),
        Text(
          trailing,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: tokens.textDim.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundModeToggle(GlassTokens tokens) {
    Widget segment(String label, _BgMode mode) {
      final selected = _bgMode == mode;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (selected) return;
            HapticFeedback.lightImpact();
            setState(() => _bgMode = mode);
            _pushCardPreview();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? tokens.surfaceElevated : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? tokens.starkWhite : tokens.textDim,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          segment(context.l10n.createRecordPageBackgroundColor, _BgMode.color),
          const SizedBox(width: 3),
          segment(context.l10n.createRecordPageBackgroundGradient,
              _BgMode.gradient),
          const SizedBox(width: 3),
          segment(context.l10n.createRecordPageBackgroundImage, _BgMode.image),
        ],
      ),
    );
  }

  /// Gradient direction presets, CSS angles (see `CardGradient`).
  static const List<(double, IconData)> _gradientAngles = [
    (90, Icons.east_rounded),
    (135, Icons.south_east_rounded),
    (180, Icons.south_rounded),
    (225, Icons.south_west_rounded),
  ];

  Widget _buildGradientStops(GlassTokens tokens) {
    final accent = tokens.connectedAccent;
    Widget stop(String label, Color color, int index) {
      final selected = _gradientStop == index;
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _gradientStop = index);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.5)
                  : tokens.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color.a == 0 ? tokens.surfaceElevated : color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? tokens.starkWhite : tokens.textDim,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            stop(context.l10n.createRecordPageGradientFrom, _gradientFrom, 0),
            const SizedBox(width: 8),
            stop(context.l10n.createRecordPageGradientTo, _gradientTo, 1),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (deg, icon) in _gradientAngles)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _gradientAngle = deg);
                    _pushCardPreview();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _gradientAngle == deg
                          ? tokens.surfaceElevated
                          : tokens.glassFill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: _gradientAngle == deg ? accent : tokens.textDim,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpacitySlider(GlassTokens tokens) {
    final accent = tokens.connectedAccent;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        activeTrackColor: accent,
        inactiveTrackColor: tokens.borderMedium,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
      ),
      child: Slider(
        value: _cardOpacity.clamp(0.0, 1.0),
        onChanged: (v) {
          setState(() => _cardOpacity = v);
          _pushCardPreview();
        },
      ),
    );
  }

  /// None, Upload, then the user's uploads on their SSP (newest first), in
  /// the profile-picture editor's grid: three rows show, the rest scroll.
  /// The image sub-page: None, Upload and your uploads, laid out in full so
  /// the sheet scrolls them (no nested scroll box). A pick sets the image and
  /// slides back to the form; the pinned preview shows it the whole time.
  Widget _buildImagePage(GlassTokens tokens) {
    final l10n = context.l10n;
    final canUpload = _hasServer == true;
    void pick(String? url) {
      setState(() => _cardImage = url);
      _pushCardPreview();
      _closeImagePage();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasServer == false && !_noServerWarningDismissed) ...[
          _NoServerWarning(
            tokens: tokens,
            message: l10n.createRecordPageNoServerWarningCard,
            onDismiss: _dismissNoServerWarning,
          ),
          const SizedBox(height: 10),
        ],
        // The upload staging is MediaUrlField's; the Upload tile opens it and
        // its URL row stays hidden. Above the grid, so the staging card shows
        // next to the tile that opened it rather than after every upload.
        MediaUrlField(
          key: _uploadFieldKey,
          controller: _uploadUrlController,
          showUrlRow: false,
          noServer: !canUpload,
          onUploaded: (id) {
            _pendingUploadId = id;
            _uploadsGridKey.currentState?.reload();
            pick(_uploadUrlController.text.trim());
          },
          onUploadDeleted: () => _pendingUploadId = null,
        ),
        const SizedBox(height: 8),
        SspMediaGrid(
          key: _uploadsGridKey,
          selectedUrl: _cardImage,
          onSelect: (file) => pick(file.url),
          leading: [
            SspMediaGridActionTile(
              icon: Icons.block_rounded,
              label: l10n.createRecordPageImageNone,
              selected: _cardImage == null,
              onTap: () => pick(null),
            ),
            SspMediaGridActionTile(
              icon: Icons.add_rounded,
              label: l10n.createRecordPageImageUpload,
              enabled: canUpload,
              onTap: () => _uploadFieldKey.currentState?.pickImage(),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  Widget _label(String text, GlassTokens tokens) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: tokens.textDim,
      ),
    );
  }

  Widget _inputField({
    required GlassTokens tokens,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      maxLength: maxLength,
      // The limit holds without a counter under every field; the size line
      // below the form speaks when the card gets close to the chain's limit.
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
      onChanged: onChanged,
      style: TextStyle(fontSize: 13, color: tokens.starkWhite),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: tokens.textDim.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: tokens.glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: tokens.connectedAccent.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // Swatch geometry mirrors the Account app's accent strip
  // (`account_center_page._accentSwatch`: 44 px swatch, 10 px gap, radius 14,
  // a check on the selected one), so the two pickers read as one control. The
  // gap lives in the separator, so `stride` below stays size + gap.
  static const double _swatchSize = 44;
  static const double _swatchGap = 10;

  Widget _buildColorPicker(GlassTokens tokens) {
    final active = _cardGradientMode
        ? (_gradientStop == 0 ? _gradientFrom : _gradientTo)
        : _cardColor;
    final list = HorizontalWheel(child: ListView.separated(
      controller: _swatchScrollCtrl,
      scrollDirection: Axis.horizontal,
      itemCount: _cardColors.length,
      separatorBuilder: (_, __) => const SizedBox(width: _swatchGap),
      itemBuilder: (_, i) => _colorSwatch(tokens, _cardColors[i], active),
    ));
    return SizedBox(
      height: _swatchSize,
      child: ScrollConfiguration(
        // DESKTOP DELTA: Flutter drag-scrolls with touch/stylus only, so with a
        // mouse every swatch past the pane edge is unreachable by dragging.
        // Same fix as the Account accent strip and the Messages chip bar.
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: list,
      ));
  }

  Widget _colorSwatch(GlassTokens tokens, Color c, Color active) {
    final selected = active.toARGB32() == c.toARGB32();
    final transparent = c.a == 0;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          if (!_cardGradientMode) {
            _cardColor = c;
          } else if (_gradientStop == 0) {
            _gradientFrom = c;
          } else {
            _gradientTo = c;
          }
        });
        _pushCardPreview();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _swatchSize,
        height: _swatchSize,
        decoration: BoxDecoration(
          // The transparent (spacer) swatch cannot show its own colour, so it
          // gets a faint glass fill and a "no colour" glyph instead.
          color: transparent ? tokens.glassFill : c,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tokens.starkWhite : tokens.borderSubtle,
            width: selected ? 2 : 1,
          ),
        ),
        child: transparent
            ? Icon(Icons.format_color_reset_outlined,
                size: 18, color: selected ? tokens.starkWhite : tokens.textDim)
            : (selected
                ? Icon(Icons.check_rounded,
                    size: 20, color: _swatchForeground(c))
                : null),
      ),
    );
  }

  /// Black or white by max contrast, crossover at luminance 0.179 - the same
  /// rule as the chat bubble and the Account accent preview. Hand-copied per
  /// file like every other site of it; retuning the rule means editing all
  /// of them.
  Color _swatchForeground(Color fill) =>
      fill.computeLuminance() < 0.179 ? Colors.white : Colors.black;

  /// Bring the current pick into view once the form paints. With 47 swatches
  /// the selection is usually off-screen, and a picker that opens without
  /// showing your own colour is one you cannot trust
  /// (`account_center_page._scrollAccentToSelection`, same arithmetic).
  void _scrollSwatchesToSelection() {
    if (!_swatchScrollCtrl.hasClients) return;
    final active = _cardGradientMode
        ? (_gradientStop == 0 ? _gradientFrom : _gradientTo)
        : _cardColor;
    final index =
        _cardColors.indexWhere((c) => c.toARGB32() == active.toARGB32());
    if (index < 0) return; // a colour from outside the ramp (legacy card)
    const stride = _swatchSize + _swatchGap;
    final viewport = _swatchScrollCtrl.position.viewportDimension;
    final offset = (index * stride) - (viewport / 2) + (_swatchSize / 2);
    _swatchScrollCtrl
        .jumpTo(offset.clamp(0.0, _swatchScrollCtrl.position.maxScrollExtent));
  }

  /// The footprint picker: a 4x4 map of the profile grid. Tapping a square
  /// sets the card's far corner (width = column, height = row).
  Widget _buildSizePicker({
    required GlassTokens tokens,
    required int width,
    required int height,
    required int maxWidth,
    required int maxHeight,
    required ValueChanged<int> onWidthChanged,
    required ValueChanged<int> onHeightChanged,
  }) {
    const double cell = 26;
    const double gap = 4;
    final accent = tokens.connectedAccent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context.l10n.createRecordPageLabelSize, tokens),
        const SizedBox(height: 8),
        Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < 4; r++)
                  Padding(
                    padding: EdgeInsets.only(bottom: r < 3 ? gap : 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var c = 0; c < 4; c++)
                          Padding(
                            padding: EdgeInsets.only(right: c < 3 ? gap : 0),
                            child: GestureDetector(
                              onTap: c < maxWidth && r < maxHeight
                                  ? () {
                                      HapticFeedback.selectionClick();
                                      if (c + 1 != width) onWidthChanged(c + 1);
                                      if (r + 1 != height) {
                                        onHeightChanged(r + 1);
                                      }
                                    }
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: cell,
                                height: cell,
                                decoration: BoxDecoration(
                                  color: c < width && r < height
                                      ? accent.withValues(alpha: 0.28)
                                      : tokens.glassFill,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$width \u00d7 $height',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.createRecordPageSizeNote,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: tokens.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;
  final GlassTokens tokens;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _Header({
    required this.title,
    required this.icon,
    required this.tokens,
    required this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              tooltip: context.l10n.createRecordPageBack,
              icon: Icon(Icons.arrow_back_rounded,
                  color: tokens.textDim, size: 20),
              onPressed: onBack,
            )
          else
            const SizedBox(width: 8),
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
            tooltip: context.l10n.createRecordPageClose,
            icon: Icon(Icons.close_rounded, color: tokens.textDim, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// No-server warning banner — same shape as EditProfileImageSheet.
// ---------------------------------------------------------------------------

class _NoServerWarning extends StatelessWidget {
  final GlassTokens tokens;
  final String message;
  final VoidCallback onDismiss;

  const _NoServerWarning({
    required this.tokens,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.fallbackAccent;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, size: 16, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: tokens.starkWhite,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onDismiss();
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: tokens.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image-record preview — matches the card aspect ratio the user has picked
// so they see the actual shape they're about to commit. Empty / error /
// loaded states mirror the EditProfileImageSheet preview.
// ---------------------------------------------------------------------------

/// Sizes [child] to exactly the proportions the card will have in the profile
/// grid, using [ProfileGridGeometry] against the form width — so the size
/// preview matches reality (a 1-wide card is ¼ width, a 1×3 stays compact)
/// instead of an AspectRatio that fills the form and overflows on tall cards.
/// Tall cells are scaled down (aspect preserved) to a max height so the preview
/// always fits without scrolling.
/// "Post media as background" on a pinned post: independent of the card's
/// background, and drawn in front of it when on.
class _PostMediaSwitch extends StatelessWidget {
  final bool value;
  final GlassTokens tokens;
  final ValueChanged<bool> onChanged;

  const _PostMediaSwitch({
    required this.value,
    required this.tokens,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.createRecordPagePostMedia,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.createRecordPagePostMediaHint,
                  style: TextStyle(color: tokens.textDim, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: tokens.connectedAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// The pinned post's URL, read-only: selectable, one
/// line, and a copy button. The card stores nothing else about the post.
class _PostLinkRow extends StatelessWidget {
  final String url;
  final GlassTokens tokens;

  const _PostLinkRow({required this.url, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: tokens.textDim),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              url,
              maxLines: 1,
              style: TextStyle(
                  color: tokens.textDim, fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 16, color: tokens.textDim),
            tooltip: context.l10n.createRecordPagePostCardLinkCopy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(context.l10n.createRecordPagePostCardLinkCopied),
                behavior: SnackBarBehavior.floating,
              ));
            },
          ),
        ],
      ),
    );
  }
}

/// One side of the pin sheet's *Pin to top / Pin to bottom* choice.
class _PlacementChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final GlassTokens tokens;
  final VoidCallback onTap;

  const _PlacementChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.7)
                  : tokens.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? accent : tokens.textDim),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? tokens.starkWhite : tokens.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A pinned post in the editor, sized the way the profile grid sizes it:
/// full width, as tall as the post (published by the card itself), capped at
/// PostCardMeta.maxRows rows of this width's cells; one row until measured.
class _PostCardPreview extends StatelessWidget {
  final String url;
  final Widget child;

  const _PostCardPreview({required this.url, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cap =
            ProfileGridGeometry.cardSize(w, 4, PostCardMeta.maxRows).height;
        return ValueListenableBuilder<Map<String, double>>(
          valueListenable: ProfilePostCard.naturalHeights,
          builder: (context, _, __) {
            final natural = ProfilePostCard.naturalHeightFor(url, w);
            // Unmeasured: two rows (the grid's starting height for a post).
            final h = natural == null
                ? ProfileGridGeometry.cardSize(w, 4, 2).height
                : natural.clamp(0.0, cap);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: w,
              height: h,
              child: child,
            );
          },
        );
      },
    );
  }
}

class _GridCellPreview extends StatelessWidget {
  final int width;
  final int height;
  final Widget child;

  const _GridCellPreview({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const maxHeight = 260.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        var size =
            ProfileGridGeometry.cardSize(constraints.maxWidth, width, height);
        if (size.height > maxHeight) {
          final s = maxHeight / size.height;
          size = Size(size.width * s, size.height * s);
        }
        return Center(
          child: SizedBox(width: size.width, height: size.height, child: child),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Text-card preview — renders the in-progress text card via `RecordButton`
// at 1:1 with its deployed size on the profile grid. Uses
// `ProfileGridGeometry` against the available width so the cell math matches
// the grid behind the sheet exactly (sheet content and profile page both have
// 16-px horizontal padding, so `LayoutBuilder.maxWidth` here equals the
// grid's `gridWidth`).
// ---------------------------------------------------------------------------

class _CardPreview extends StatelessWidget {
  final Record record;

  const _CardPreview({required this.record});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = ProfileGridGeometry.cardSize(
          constraints.maxWidth,
          record.width,
          record.height,
        );
        return Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: RecordButton(
              record: record,
              onTap: () {},
              onDelete: () {},
              isEditable: false,
              isEditMode: false,
            ),
          ),
        );
      },
    );
  }
}
