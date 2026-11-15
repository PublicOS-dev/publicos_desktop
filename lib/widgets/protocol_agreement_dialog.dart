// DESKTOP DELTA: the client shows this as a bottom sheet
// (components/protocol_agreement_sheet.dart); desktop shows it as
// a centered glass dialog. The reading rule and the strings are the same.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/system_app_action_button.dart';

/// The protocol agreement, shown before a NEW account is made. It is not
/// shown when adding a client to an existing account, whose owner already
/// saw it.
///
/// The new key's create-account consent carries the current PROTOCOL version
/// (`signCreateAccountConsent` reads it live), so the account accepts this
/// text when it is minted; agreement clause 16 says no app may ask for that
/// signature without showing the agreement first. [agreement] is loaded by the
/// caller (`PublicOSAgreements.currentText`). ACCEPT AND CONTINUE exists only
/// once the reader reached the end of the text; a text that fits without
/// scrolling counts as read.
///
/// Returns `true` only when the user accepted.
Future<bool> showProtocolAgreementDialog(
  BuildContext context, {
  required ({BigInt version, String text}) agreement,
}) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ProtocolAgreementDialog(agreement: agreement),
  );
  return accepted == true;
}

class _ProtocolAgreementDialog extends StatefulWidget {
  final ({BigInt version, String text}) agreement;
  const _ProtocolAgreementDialog({required this.agreement});

  @override
  State<_ProtocolAgreementDialog> createState() =>
      _ProtocolAgreementDialogState();
}

class _ProtocolAgreementDialogState extends State<_ProtocolAgreementDialog> {
  final ScrollController _scroll = ScrollController();
  bool _reachedEnd = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFitsWithoutScroll());
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _checkFitsWithoutScroll() {
    if (!mounted || !_scroll.hasClients) return;
    if (_scroll.position.maxScrollExtent <= 0 && !_reachedEnd) {
      setState(() => _reachedEnd = true);
    }
  }

  void _onScroll() {
    if (_reachedEnd || !_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 12) {
      setState(() => _reachedEnd = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final maxH = MediaQuery.sizeOf(context).height * 0.8;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            decoration: BoxDecoration(
              color: tokens.surfaceDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: DialogWidth.l, maxHeight: maxH),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.protocolAgreementTitle,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.starkWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.protocolAgreementLead,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.protocolAgreementVersion(widget.agreement.version.toString()),
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: tokens.glassFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Scrollbar(
                        controller: _scroll,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                          child: Text(
                            widget.agreement.text,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              color: tokens.starkWhite,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: _reachedEnd
                        ? SystemAppActionButton(
                            label: l10n.protocolAgreementAccept,
                            icon: Icons.check_rounded,
                            onTap: () => Navigator.of(context).pop(true),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.keyboard_double_arrow_down_rounded,
                                  size: 18, color: tokens.textDim),
                              const SizedBox(width: 8),
                              Text(
                                l10n.protocolAgreementScrollHint,
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  color: tokens.textDim,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
