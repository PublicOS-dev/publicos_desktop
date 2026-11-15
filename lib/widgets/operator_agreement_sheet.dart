// Ported from the mobile client's components/operator_agreement_sheet.dart;
// only the imports differ.
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/phigital_bottom_sheet.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_action_button.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The operator agreement, in one sheet. Every BSP / SSP registration door
/// checks that the caller's
/// account accepted the CURRENT operator agreement
/// (`_requireOperatorAgreement` in both registries); without this sheet no app
/// user could ever register a provider. Same reading rule as the citizenship
/// claim: the text comes off the chain
/// (`PublicOSAgreements.currentText(kindOperator)`), the ACCEPT button exists
/// only once the reader reached the end, and an expiring key is told up front
/// that it cannot sign (`agree` refuses it).
///
/// Returns `true` when the signature landed, whichever way the sheet was
/// closed afterwards, so the caller can reload and show REGISTER.
Future<bool> showOperatorAgreementSheet(BuildContext context) async {
  final signed = ValueNotifier<bool>(false);
  await showPhigitalBottomSheet<void>(
    context: context,
    // The body paints its own glass.
    wrapInChrome: false,
    maxWidth: DialogWidth.l,
    builder: (_, __) => OperatorAgreementSheet(signed: signed),
  );
  final result = signed.value;
  signed.dispose();
  return result;
}

enum _Phase {
  loading,
  needsPermanentKey,
  nothingPublished,
  loadFailed,
  reading,
  claiming,
  failed,
  done,
}

class OperatorAgreementSheet extends StatefulWidget {
  /// Flipped to true the moment the claim receipt lands. Owned by the caller,
  /// because a sheet dismissed by a drag returns nothing.
  final ValueNotifier<bool> signed;

  const OperatorAgreementSheet({super.key, required this.signed});

  @override
  State<OperatorAgreementSheet> createState() => _OperatorAgreementSheetState();
}

class _OperatorAgreementSheetState extends State<OperatorAgreementSheet> {
  final ScrollController _scroll = ScrollController();

  _Phase _phase = _Phase.loading;
  String _text = '';
  BigInt _version = BigInt.zero;
  bool _reachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _phase = _Phase.loading);
    try {
      final reads = await Future.wait<dynamic>([
        PublicOSAgreements.currentText(PublicOSAgreements.kindOperator),
        PublicOSAccounts.isActiveSessionPermanent(),
      ]);
      final agreement = reads[0] as ({BigInt version, String text})?;
      final permanent = reads[1] as bool?;
      if (!mounted) return;
      // An expiring key cannot take an irreversible step (the contract refuses
      // it); say so before the user reads two pages for nothing. An unknown
      // answer lets the contract decide.
      if (permanent == false) {
        setState(() => _phase = _Phase.needsPermanentKey);
        return;
      }
      if (agreement == null) {
        setState(() => _phase = _Phase.nothingPublished);
        return;
      }
      setState(() {
        _text = agreement.text;
        _version = agreement.version;
        _phase = _Phase.reading;
      });
      // A text short enough to need no scrolling has been read once painted.
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkFitsWithoutScroll());
    } catch (e) {
      Log.e('OperatorAgreement', 'Agreement load failed: $e');
      if (mounted) setState(() => _phase = _Phase.loadFailed);
    }
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

  Future<void> _claim() async {
    setState(() {
      _phase = _Phase.claiming;
      _error = null;
    });
    final ok = await PublicOSAgreements.agree(PublicOSAgreements.kindOperator);
    if (!mounted) return;
    if (ok) {
      widget.signed.value = true;
      setState(() => _phase = _Phase.done);
    } else {
      setState(() {
        _error = PublicOS.lastError;
        _phase = _Phase.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final busy = _phase == _Phase.claiming;

    return PopScope(
      // The transaction is in flight: closing the sheet would not undo it,
      // only hide its outcome.
      canPop: !busy,
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.borderMedium,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _phase == _Phase.done
                            ? l10n.operatorAgreementDoneTitle
                            : l10n.operatorAgreementTitle,
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
                      onPressed: busy ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(tokens, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(GlassTokens tokens, AppLocalizations l10n) {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: PhigitalLoadingWidget(size: 48));
      case _Phase.needsPermanentKey:
        return _notice(tokens, Icons.key_off_rounded,
            l10n.operatorAgreementNeedsPermanentKey);
      case _Phase.nothingPublished:
        return _notice(tokens, Icons.hourglass_empty_rounded,
            l10n.operatorAgreementNothingPublished);
      case _Phase.loadFailed:
        return _notice(
          tokens,
          Icons.cloud_off_rounded,
          l10n.operatorAgreementLoadFailed,
          action: SystemAppActionButton(
            label: l10n.operatorAgreementRetry,
            icon: Icons.refresh_rounded,
            onTap: _load,
          ),
        );
      case _Phase.claiming:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhigitalLoadingWidget(size: 56),
              const SizedBox(height: 18),
              Text(
                l10n.operatorAgreementSigning,
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
        );
      case _Phase.done:
        return _done(tokens, l10n);
      case _Phase.reading:
      case _Phase.failed:
        return _reading(tokens, l10n);
    }
  }

  Widget _notice(GlassTokens tokens, IconData icon, String text,
      {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: tokens.textDim),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 24), action],
        ],
      ),
    );
  }

  Widget _reading(GlassTokens tokens, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.operatorAgreementLead,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.operatorAgreementVersion(_version.toString()),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // The agreement, in its own box: a bordered reading pane the user
          // scrolls through, so "reached the end" is a fact about THIS box and
          // not about the sheet.
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
                    _text,
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
          if (_phase == _Phase.failed) ...[
            Text(
              _error == null || _error!.isEmpty
                  ? l10n.operatorAgreementFailed
                  : '${l10n.operatorAgreementFailed} $_error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.softDanger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // The button is EARNED by reading: until the box has been scrolled
          // to its end there is a hint where the button will be, in the same
          // height, so nothing jumps when it appears.
          SizedBox(
            height: 48,
            child: _reachedEnd
                ? SystemAppActionButton(
                    label: _phase == _Phase.failed
                        ? l10n.operatorAgreementRetry
                        : l10n.operatorAgreementAccept,
                    icon: Icons.draw_rounded,
                    onTap: _claim,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_double_arrow_down_rounded,
                          size: 18, color: tokens.textDim),
                      const SizedBox(width: 8),
                      Text(
                        l10n.operatorAgreementScrollHint,
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
    );
  }

  Widget _done(GlassTokens tokens, AppLocalizations l10n) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.handshake_rounded,
                  size: 72, color: tokens.connectedAccent),
              const SizedBox(height: 20),
              Text(
                l10n.operatorAgreementDoneTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.operatorAgreementDoneBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite.withValues(alpha: 0.85),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              SystemAppActionButton(
                label: l10n.operatorAgreementContinue,
                icon: Icons.arrow_forward_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
