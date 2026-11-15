// PORTED VERBATIM from publicos_client, with only the
// three mechanical import rewrites (components/->widgets/, pages/->
// screens/, glass_theme->glass_tokens). Presentation is deliberately
// duplicated between the two clients; the LOGIC behind these sheets is
// not -- it lives in publicos_web3_bridge and is shared.
//
// Still a bottom sheet, exactly as on mobile. Re-shelling it as a
// desktop dialog is a presentation change to make deliberately, not on
// the way past.
import 'dart:convert';

import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';
import 'package:publicos_desktop/widgets/signature_icon.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

enum SignatureRequestType {
  personalSign,
  ethSign,
  signTypedData,
  sendTransaction,
  signTransaction,
}

class SignatureRequestSheet extends StatefulWidget {
  final SignatureRequestType requestType;
  final String? message;
  final Map<String, dynamic>? transactionData;
  final dynamic typedData;
  final String? requestingOrigin;

  /// The address that WILL sign — the one the dApp named in `p.address` /
  /// `from`, already gated and resolved by the bridge.
  ///
  /// The sheet displays this and offers no way to change it. Reading the
  /// global web-key pointer and carrying a key switcher would be wrong
  /// twice: it could show a key that is not the one about to sign, and
  /// switching contradicts the whole point of honouring the address the dApp
  /// asked for. Null (the XMTP wallet-send-calls caller) falls back to the
  /// account's own session key, which is what signs there.
  final String? signingAddress;

  /// The browser's current chain (hex, e.g. `0x1189`). Shown as a network
  /// pill so the user can see which chain a signature/transaction targets —
  /// the at-a-glance "am I on PublicOS or an external chain?" cue. Especially
  /// important for `eth_sendTransaction`, which now broadcasts for real.
  final String? currentChainId;

  const SignatureRequestSheet({
    super.key,
    required this.requestType,
    this.message,
    this.transactionData,
    this.typedData,
    this.requestingOrigin,
    this.currentChainId,
    this.signingAddress,
  });

  /// Show the signature request sheet and return true if approved, false if rejected.
  ///
  /// PATTERN A ("Bottom sheet shell"): this sheet has a primary action
  /// button, so it is a DraggableScrollableSheet with a pinned footer, fired
  /// from showModalBottomSheet directly. Do NOT use showPhigitalBottomSheet
  /// for this pattern.
  ///
  /// That helper wraps the body in its OWN `SafeArea(top: false)`, and the
  /// footer below already has one — so the bottom inset would be applied
  /// TWICE: once outside the Container (lifting the whole sheet off the bottom
  /// of the screen, leaving the page visible underneath it) and once inside the
  /// footer (pushing the buttons up again, so they read as floating above the
  /// sheet rather than sitting in it).
  ///
  /// TWO DELIBERATE DEVIATIONS from Pattern A, both because this is a security
  /// prompt and not a form:
  ///   - `isDismissible: false` + `enableDrag: false` — an accidental swipe must
  ///     never ANSWER a signature request. (The DraggableScrollableSheet inside
  ///     still drags: `enableDrag` only governs the modal route's dismissal.)
  ///   - The footer keeps REJECT next to SIGN. The guide bans a bottom Cancel
  ///     because swipe-down/X already cancels — here BOTH of those are disabled
  ///     on purpose, so REJECT is the only way to say no, and the dApp is owed an
  ///     explicit rejection rather than a dismissal.
  static Future<bool> show({
    required BuildContext context,
    required SignatureRequestType requestType,
    String? message,
    Map<String, dynamic>? transactionData,
    dynamic typedData,
    String? requestingOrigin,
    String? currentChainId,
    String? signingAddress,
  }) async {
    final result = await showGlassSheetDialog<bool>(
      context: context,
      width: DialogWidth.m,
      barrierDismissible: false,
      builder: (_) => SignatureRequestSheet(
        requestType: requestType,
        message: message,
        transactionData: transactionData,
        typedData: typedData,
        requestingOrigin: requestingOrigin,
        currentChainId: currentChainId,
        signingAddress: signingAddress,
      ),
    );
    return result ?? false;
  }

  @override
  State<SignatureRequestSheet> createState() => _SignatureRequestSheetState();
}

class _SignatureRequestSheetState extends State<SignatureRequestSheet> {
  bool _isProcessing = false;
  String? _currentKeyLabel;
  String? _currentKeyEmoji;
  String? _signingAddress;
  bool _isSessionKey = true;
  bool _isLoadingKeyInfo = true;

  /// The Raw data row's fold. One flag is enough: each request type shows a
  /// single raw payload (the hex message, the typed data, or the calldata).
  bool _rawOpen = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentKeyInfo();
  }

  /// Resolve the DISPLAY for [SignatureRequestSheet.signingAddress] — the
  /// address the bridge already decided will sign.
  ///
  /// Matching is by ADDRESS, never by the web-key label: the label is
  /// display-only, survives a rename, and pointed at the preferred key rather
  /// than the signing one. An address we cannot name still renders — the
  /// address itself is the truth, and refusing to show an unnamed key would
  /// hide a real signing request.
  Future<void> _loadCurrentKeyInfo() async {
    try {
      final userAddress =
          AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
      final wanted =
          (widget.signingAddress ?? PublicOS.sessionBlockchainAddress ?? '')
              .toLowerCase();
      final session = (PublicOS.sessionBlockchainAddress ?? '').toLowerCase();

      if (wanted.isEmpty || wanted == session || userAddress == null) {
        if (mounted) {
          setState(() {
            _signingAddress =
                wanted.isEmpty ? PublicOS.sessionBlockchainAddress : wanted;
            _isSessionKey = true;
            _isLoadingKeyInfo = false;
          });
        }
        return;
      }

      final keys = await PublicOSKeychain.fetchKeys(userAddress);
      final keyData = keys.firstWhere(
        (k) => ((k['address'] ?? '') as String).toLowerCase() == wanted,
        orElse: () => <String, dynamic>{},
      );
      if (mounted) {
        setState(() {
          _currentKeyLabel = keyData['label'] as String?;
          _currentKeyEmoji = keyData['emoji'] as String? ?? '🔑';
          _signingAddress = widget.signingAddress;
          _isSessionKey = false;
          _isLoadingKeyInfo = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading key info: $e');
      if (mounted) {
        setState(() {
          _signingAddress =
              widget.signingAddress ?? PublicOS.sessionBlockchainAddress;
          _isLoadingKeyInfo = false;
        });
      }
    }
  }

  String get _title {
    final l10n = context.l10n;
    switch (widget.requestType) {
      case SignatureRequestType.personalSign:
        return l10n.signatureRequestSheetTitleSignMessage;
      case SignatureRequestType.ethSign:
        return l10n.signatureRequestSheetTitleSignData;
      case SignatureRequestType.signTypedData:
        return l10n.signatureRequestSheetTitleSignTypedData;
      case SignatureRequestType.sendTransaction:
        return l10n.signatureRequestSheetTitleSendTransaction;
      case SignatureRequestType.signTransaction:
        return l10n.signatureRequestSheetTitleSignTransaction;
    }
  }

  /// The header mark for this request.
  ///
  /// A Widget rather than an `IconData` because the signing requests use
  /// [SignatureIcon], an inline-SVG glyph: Flutter's bundled `Icons` font has
  /// no signature mark (it is a Material *Symbols* glyph, a newer font than the
  /// Material *Icons* Flutter ships), and the `Icons.edit_document` that stood
  /// in for it reads as "edit a file" rather than "put your name to this".
  Widget _iconFor(Color color, {double size = 26}) {
    switch (widget.requestType) {
      case SignatureRequestType.personalSign:
      case SignatureRequestType.ethSign:
      case SignatureRequestType.signTypedData:
      case SignatureRequestType.signTransaction:
        // Every "sign this" request gets the signature mark. `signTransaction`
        // joined them here (it used `Icons.draw`, a scribble) — signing a
        // transaction and signing a message are the same act to the user, and
        // what separates them is the body of the sheet, not its glyph.
        return SignatureIcon(size: size, color: color);
      case SignatureRequestType.sendTransaction:
        // NOT a signature: this one broadcasts. The send arrow is the whole
        // distinction, so it stays.
        return Icon(Icons.send, color: color, size: size);
    }
  }

  String get _actionButtonText {
    final l10n = context.l10n;
    switch (widget.requestType) {
      case SignatureRequestType.personalSign:
      case SignatureRequestType.ethSign:
        return l10n.signatureRequestSheetActionSignMessage;
      case SignatureRequestType.signTypedData:
        return l10n.signatureRequestSheetActionSignData;
      case SignatureRequestType.sendTransaction:
        return l10n.signatureRequestSheetActionSend;
      case SignatureRequestType.signTransaction:
        return l10n.signatureRequestSheetActionSign;
    }
  }

  // PublicOS mainnet chain id (4489 = 0x1189). External chains get an amber
  // pill as a subtle "you're off PublicOS" cue now that sends broadcast for real.
  static const _publicOSChainId = '0x1189';

  /// Names the chain from the app's one registry — see `chainNameForHex` in
  /// `lib/data/chain_registry.dart`. This was a hardcoded `switch` duplicated
  /// byte-for-byte in `connect_request_sheet.dart`.
  String _chainName(String? hexChainId) {
    final name = chainNameForHex(hexChainId);
    if (name != null) return name;
    return hexChainId == null
        ? context.l10n.signatureRequestSheetChainUnknown
        : context.l10n.signatureRequestSheetChainNamed(hexChainId);
  }

  /// The chain, as a detail row rather than a header pill.
  ///
  /// The header is the *identity* of the request — glyph, title, origin —
  /// and the chain is a *fact about the transaction*, which is where a reader
  /// goes looking for it. A pill would also be the widest thing competing
  /// with the origin for the same row.
  ///
  /// It reads [SignatureRequestSheet.currentChainId], the browser's chain, NOT
  /// the `chainId` field in the dApp's payload: the executor takes the chain
  /// from the registry, so the browser's is the one that will actually be used
  /// and the payload's is decoration.
  Widget _buildNetworkRow(GlassTokens tokens) {
    final chain = _parseChainIdField(widget.currentChainId);
    final isPublicOS = widget.currentChainId == _publicOSChainId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(context.l10n.signatureRequestSheetLabelNetwork,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    color: tokens.textDim)),
          ),
          // The same brand marks the NFT-avatar grids use, keyed by chain id.
          // An unmapped chain falls back to the generic Ethereum diamond, so
          // the row never renders empty.
          if (chain != null) ...[
            NftChainIcon(chain: chain, size: 16),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              _chainName(widget.currentChainId),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                // Off-chain still reads as a warning, exactly as the pill did:
                // the accent is the only thing that said "this is not PublicOS".
                color: isPublicOS ? tokens.starkWhite : tokens.fallbackAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceElevated,
        title: Row(
          children: [
            Icon(Icons.info_outline, color: tokens.connectedAccent),
            const SizedBox(width: 8),
            Text(l10n.signatureRequestSheetInfoTitle,
                style: TextStyle(color: tokens.starkWhite)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.signatureRequestSheetInfoBody1,
              style: TextStyle(
                  color: tokens.starkWhite, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.signatureRequestSheetInfoBody2,
              style: TextStyle(color: tokens.textDim),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.signatureRequestSheetInfoWarning,
              style: TextStyle(
                  color: tokens.fallbackAccent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.signatureRequestSheetInfoGotIt,
                style: TextStyle(color: tokens.connectedAccent)),
          ),
        ],
      ),
    );
  }

  /// The `0x...` payload as UTF-8 text, or null when it is not text.
  ///
  /// Strict on purpose. `String.fromCharCodes` reads every byte as Latin-1
  /// and never fails: a hash would render as garbage under MESSAGE and
  /// accented text would come out mojibake. Invalid UTF-8, bad hex, or
  /// control characters (valid UTF-8 can still be binary) mean nobody can read
  /// it, so the sheet says so and leaves the bytes to the Raw data row.
  String? _decodeHexMessage(String hexMessage) {
    final hex =
        hexMessage.startsWith('0x') ? hexMessage.substring(2) : hexMessage;
    if (hex.isEmpty) return '';
    if (hex.length.isOdd) return null;
    try {
      final bytes = <int>[];
      for (var i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      final text = utf8.decode(bytes);
      final binary = text.runes.any((r) =>
          (r < 0x20 && r != 0x09 && r != 0x0A && r != 0x0D) || r == 0x7F);
      return binary ? null : text;
    } on FormatException {
      return null;
    }
  }

  /// Gas limit as a plain grouped number.
  ///
  /// It arrived raw — `0x158f5` — which is unreadable to anyone who is not
  /// mentally converting hex, and this is a sheet whose whole job is letting a
  /// person decide. `88,309` says the same thing. The raw hex is not preserved
  /// anywhere on the row: a gas limit is a magnitude, and the exact word is
  /// still in CONTRACT DATA for anyone who wants it.
  String _formatGas(String? hexGas) {
    if (hexGas == null || hexGas.isEmpty) return '';
    try {
      final hex = hexGas.startsWith('0x') ? hexGas.substring(2) : hexGas;
      return _grouped(BigInt.parse(hex, radix: 16));
    } catch (_) {
      // Unparseable: show what we were given rather than inventing a number.
      return hexGas;
    }
  }

  /// Thousands separators, without dragging in `intl` for one call site.
  String _grouped(BigInt n) {
    final digits = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  String _formatValue(String? hexValue) {
    if (hexValue == null || hexValue.isEmpty) return '0 ETH';
    try {
      String hex = hexValue;
      if (hex.startsWith('0x')) hex = hex.substring(2);
      final wei = BigInt.parse(hex, radix: 16);
      final eth = wei / BigInt.from(10).pow(18);
      return '${eth.toStringAsFixed(6)} ETH';
    } catch (e) {
      return hexValue;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.l10n.signatureRequestSheetCopiedToClipboard),
          duration: const Duration(seconds: 1)),
    );
  }

  // ── Glass text helpers ──────────────────────────────────────────────────
  TextStyle _label(GlassTokens t) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        fontSize: 11,
        color: t.textDim,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // Pattern A. The DraggableScrollableSheet is anchored to the BOTTOM of
    // the screen, so the Container's background runs edge-to-edge down to the
    // very bottom — which a `SizedBox(height: 0.85 * screen)` inside a
    // SafeArea cannot do.
    // The bottom inset is applied in exactly ONE place: the pinned footer.
    return Padding(
      // A DraggableScrollableSheet sizes against the FULL screen and ignores the
      // keyboard on its own. Nothing here focuses an input today, but the shell
      // is the shell — leaving this out is how the next person's text field ends
      // up under the IME.
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 1.0,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  // Explicit, because it is the half of the alignment fix
                  // that is not obvious: both text lines are capped, so the
                  // column's height is bounded and centring holds for every
                  // request type and every origin length. (The glyph has no
                  // plate, so the column is the taller of the two and the
                  // glyph centres against IT, which is why this has to stay
                  // explicit rather than falling back to the default.)
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bare glyph, no plate: a boxed icon reads as a button in
                    // a sheet where the only buttons are at the bottom. Sized
                    // to carry the header on its own, with no container
                    // behind it.
                    _iconFor(tokens.connectedAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _title,
                            // Both lines are CAPPED AT ONE, which is what keeps
                            // the glyph and the title aligned. Unbounded, a
                            // long dApp URL wraps to four lines, grows the
                            // row, and leaves the centred glyph floating
                            // beside a title pinned to the top.
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: tokens.starkWhite,
                            ),
                          ),
                          if (widget.requestingOrigin != null)
                            Text(
                              widget.requestingOrigin!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 11,
                                color: tokens.textDim,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showInfoDialog,
                      icon: Icon(Icons.info_outline,
                          color: tokens.textDim, size: 20),
                      tooltip: context.l10n.signatureRequestSheetInfoTooltip,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  // Load-bearing: this is what lets a scroll past the top edge
                  // drag the sheet UP toward maxChildSize. The handle and header
                  // only ever drag DOWN; drag-up lives inside the scrollable.
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: ConstrainedBox(
                    // Guarantees there is always something to grab, even for a
                    // one-line message — otherwise a short request leaves no
                    // scrollable area and the sheet cannot be dragged back up.
                    constraints: const BoxConstraints(minHeight: 280),
                    child: Column(
                      // Load-bearing: a SingleChildScrollView hands its child
                      // unbounded height, and a default mainAxisSize.max Column
                      // then tries to expand to infinity.
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountCard(tokens),
                        const SizedBox(height: 20),
                        _buildRequestContent(tokens),
                      ],
                    ),
                  ),
                ),
              ),
              _buildActionButtons(tokens),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(GlassTokens tokens) {
    final currentContact = AppStateNotifier.currentMyContact;
    final address = _signingAddress ?? '0x0000...0000';

    final bool showAvatar = _isSessionKey;
    final String emoji = _currentKeyEmoji ?? '🔑';
    final String name = !_isSessionKey && _currentKeyLabel != null
        ? _currentKeyLabel!
        : (currentContact?.displayName ??
            context.l10n.signatureRequestSheetMyAccount);
    final bool showKeyBadge = !_isSessionKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.signatureRequestSheetSigningWith,
            style: _label(tokens)),
        const SizedBox(height: 8),
        // NOT tappable. The dApp named this address and the bridge honours it;
        // offering to change it here would contradict the answer the page is
        // about to receive. There is no key switcher on this row — permission
        // is chosen per site, in the connect/keys picker, not mid-signature.
        Container(
          padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (showAvatar)
                  currentContact != null
                      ? GlassContactIcon(contact: currentContact, size: 44)
                      : Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                tokens.connectedAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(Icons.account_circle,
                              color: tokens.connectedAccent),
                        )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tokens.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child:
                            Text(emoji, style: const TextStyle(fontSize: 24))),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isLoadingKeyInfo
                      ? const PhigitalLoadingWidget(
                          size: 16, showShadows: false)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'SpaceGrotesk',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.starkWhite,
                                    ),
                                  ),
                                ),
                                if (showKeyBadge) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: tokens.connectedAccent
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                        context
                                            .l10n.signatureRequestSheetKeyBadge,
                                        style: TextStyle(
                                          fontFamily: 'SpaceGrotesk',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: tokens.connectedAccent,
                                        )),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () => _copyToClipboard(address),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    shortenString(address, isAddress: true),
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: tokens.textDim,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.copy,
                                      size: 12, color: tokens.textDim),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
        ),
      ],
    );
  }

  Widget _buildRequestContent(GlassTokens tokens) {
    switch (widget.requestType) {
      case SignatureRequestType.personalSign:
      case SignatureRequestType.ethSign:
        return _buildMessageContent(tokens);
      case SignatureRequestType.signTypedData:
        return _buildTypedDataContent(tokens);
      case SignatureRequestType.sendTransaction:
      case SignatureRequestType.signTransaction:
        return _buildTransactionContent(tokens);
    }
  }

  Future<void> _onApprove() async {
    setState(() => _isProcessing = true);
    Navigator.pop(context, true);
  }

  Widget _glassBox(GlassTokens tokens,
      {required Widget child, double? maxHeight}) {
    return Container(
      width: double.infinity,
      constraints:
          maxHeight != null ? BoxConstraints(maxHeight: maxHeight) : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildMessageContent(GlassTokens tokens) {
    final message = widget.message ?? '';
    final isHex = message.startsWith('0x');
    // A plain-text message is its own raw form, so only a hex payload gets a
    // Raw data row. A hex payload that is not text says so instead of
    // rendering bytes as characters.
    final decoded = isHex ? _decodeHexMessage(message) : message;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.signatureRequestSheetSectionMessage,
            style: _label(tokens)),
        const SizedBox(height: 8),
        _glassBox(
          tokens,
          child: decoded != null
              ? SelectableText(
                  decoded,
                  style: TextStyle(fontSize: 13, color: tokens.starkWhite),
                )
              : Text(
                  context.l10n.signatureRequestSheetNotReadableText,
                  style: TextStyle(fontSize: 13, color: tokens.textDim),
                ),
        ),
        if (isHex) ...[
          const SizedBox(height: 12),
          _buildRawData(tokens, message),
        ],
      ],
    );
  }

  /// A request's raw payload folded behind one row: `RAW DATA ... chevron`.
  ///
  /// Closed by default: the readable part of the request sits above it, and
  /// hex or EIP-712 JSON is not something a person reads before signing. Open,
  /// it shows the payload with a copy button.
  Widget _buildRawData(GlassTokens tokens, String data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _rawOpen = !_rawOpen),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Text(context.l10n.signatureRequestSheetRawData,
                    style: _label(tokens)),
                const Spacer(),
                AnimatedRotation(
                  turns: _rawOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded,
                      size: 20, color: tokens.textDim),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_rawOpen
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _glassBox(
                    tokens,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: SingleChildScrollView(
                            child: SelectableText(
                              data,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: tokens.textDim,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _copyToClipboard(data),
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: Text(
                              context.l10n.signatureRequestSheetCopy,
                              style: const TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                fontSize: 11,
                              ),
                            ),
                            style: TextButton.styleFrom(
                                foregroundColor: tokens.starkWhite),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTypedDataContent(GlassTokens tokens) {
    String displayData;
    if (widget.typedData is String) {
      displayData = widget.typedData;
    } else if (widget.typedData is Map) {
      displayData = _prettyPrintJson(widget.typedData);
    } else {
      displayData = widget.typedData?.toString() ??
          context.l10n.signatureRequestSheetNoData;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.signatureRequestSheetSectionTypedData,
            style: _label(tokens)),
        const SizedBox(height: 4),
        _buildRawData(tokens, displayData),
      ],
    );
  }

  String _prettyPrintJson(dynamic json, {int indent = 0}) {
    if (json is Map) {
      if (json.isEmpty) return '{}';
      final buffer = StringBuffer('{\n');
      final entries = json.entries.toList();
      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('${'  ' * (indent + 1)}"${entry.key}": ');
        buffer.write(_prettyPrintJson(entry.value, indent: indent + 1));
        if (i < entries.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write('${'  ' * indent}}');
      return buffer.toString();
    } else if (json is List) {
      if (json.isEmpty) return '[]';
      final buffer = StringBuffer('[\n');
      for (var i = 0; i < json.length; i++) {
        buffer.write(
            '${'  ' * (indent + 1)}${_prettyPrintJson(json[i], indent: indent + 1)}');
        if (i < json.length - 1) buffer.write(',');
        buffer.write('\n');
      }
      buffer.write('${'  ' * indent}]');
      return buffer.toString();
    } else if (json is String) {
      return '"$json"';
    } else {
      return json.toString();
    }
  }

  /// Parse a chainId field that may be a hex string ('0x2105'), an int, or a
  /// decimal string. Null if absent/unparseable → token meta can't resolve.
  int? _parseChainIdField(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String && raw.isNotEmpty) {
      if (raw.startsWith('0x') || raw.startsWith('0X')) {
        return int.tryParse(raw.substring(2), radix: 16);
      }
      return int.tryParse(raw);
    }
    return null;
  }

  /// Prominent "Sending N TOKEN" row for an ERC-20 transfer — the real amount
  /// lives in the calldata, not `value` (which is 0 for a token transfer).
  Widget _buildTokenTransferRow(
      GlassTokens tokens, Erc20Transfer t, int? chainId) {
    return FutureBuilder<TokenMeta?>(
      future: chainId != null
          ? PublicOSWallets.resolveTokenMeta(chainId, t.token)
          : Future.value(null),
      builder: (context, snap) {
        final meta = snap.data;
        final amount = meta != null
            ? PublicOSWallets.formatTokenAmount(t.rawAmount, meta.decimals,
                symbol: meta.symbol)
            : context.l10n.signatureRequestSheetRawTokenAmount(
                t.rawAmount, shortenString(t.token, isAddress: true));
        return _buildTxDetailRow(tokens,
            context.l10n.signatureRequestSheetLabelSending, amount, null);
      },
    );
  }

  Widget _buildTransactionContent(GlassTokens tokens) {
    final tx = widget.transactionData ?? {};
    final to = tx['to'] as String?;
    final value = tx['value'] as String?;
    final data = tx['data'] as String?;
    final gas = tx['gas'] as String?;
    final chainId = _parseChainIdField(tx['chainId']);
    final transfer =
        to != null ? PublicOSWallets.decodeErc20Transfer(to, data) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.signatureRequestSheetSectionTransaction,
            style: _label(tokens)),
        const SizedBox(height: 10),
        // First, because it frames everything under it: an amount and a
        // recipient mean different things on a different chain.
        _buildNetworkRow(tokens),
        if (transfer != null) ...[
          // ERC-20 token transfer: show the decoded amount + true recipient,
          // and label `to` as the token contract so 0-ETH `value` isn't read as
          // "nothing is being sent".
          _buildTokenTransferRow(tokens, transfer, chainId),
          _buildTxDetailRow(
              tokens,
              context.l10n.signatureRequestSheetLabelRecipient,
              shortenString(transfer.recipient, isAddress: true),
              transfer.recipient),
          _buildTxDetailRow(
              tokens,
              context.l10n.signatureRequestSheetLabelToken,
              shortenString(to!, isAddress: true),
              to),
        ] else if (to != null)
          _buildTxDetailRow(tokens, context.l10n.signatureRequestSheetLabelTo,
              shortenString(to, isAddress: true), to,
              mono: true),
        _buildTxDetailRow(tokens, context.l10n.signatureRequestSheetLabelValue,
            _formatValue(value), null),
        if (gas != null)
          _buildTxDetailRow(tokens,
              context.l10n.signatureRequestSheetLabelGasLimit,
              _formatGas(gas), null),
        // The calldata is the transaction's raw form: the rows above already
        // say what it does in words, so the hex folds away.
        if (data != null && data != '0x' && data.isNotEmpty) ...[
          const SizedBox(height: 4),
          _buildRawData(tokens, data),
        ],
      ],
    );
  }

  Widget _buildTxDetailRow(
      GlassTokens tokens, String label, String value, String? copyValue,
      {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 13,
                    color: tokens.textDim)),
          ),
          Expanded(
            child: GestureDetector(
              onTap:
                  copyValue != null ? () => _copyToClipboard(copyValue) : null,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontFamily: mono ? 'monospace' : 'SpaceGrotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tokens.starkWhite,
                      ),
                    ),
                  ),
                  if (copyValue != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.copy, size: 14, color: tokens.textDim),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(GlassTokens tokens) {
    final approveDisabled = _isProcessing;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      // No rule above the buttons (borderless).
      decoration: const BoxDecoration(),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _isProcessing ? null : () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: tokens.starkWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide.none,
                ),
                child: Text(context.l10n.signatureRequestSheetActionReject,
                    style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        fontSize: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: approveDisabled ? null : _onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tokens.glassFill,
                  foregroundColor: tokens.starkWhite,
                  disabledBackgroundColor:
                      tokens.glassFill.withValues(alpha: 0.4),
                  disabledForegroundColor:
                      tokens.textDim.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide.none,
                  ),
                ),
                // The same mark the header carries, so the glyph the user
                // read at the top is the one they press. (Was
                // `Icons.account_balance_rounded` — a bank, which said
                // "chain action" but not *which* action.)
                //
                // The colour is passed explicitly rather than inherited: an
                // `Icon` inside `ElevatedButton.icon` picks up `foregroundColor`
                // on its own, but `SignatureIcon` paints through a `srcIn`
                // filter and would ignore it — including the disabled tint.
                icon: _isProcessing
                    ? const PhigitalLoadingWidget(size: 16, showShadows: false)
                    : _iconFor(
                        approveDisabled
                            ? tokens.textDim.withValues(alpha: 0.5)
                            : tokens.starkWhite,
                        size: 16,
                      ),
                label: Text(
                  _actionButtonText,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
