// Ported from the mobile client's components/server_rules_sheet.dart; only
// the imports and the dialog width differ.
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/phigital_bottom_sheet.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_action_button.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// An SSP's house rules + privacy notice, shown right before the subscribe
/// transaction: subscribing means accepting the terms. The text comes from the
/// server itself, `GET <apiUrl>/privacy_and_agreements`; nothing is signed or
/// sent back, the subscribe transaction that follows IS the acceptance.
///
/// Same reading rule as the operator agreement sheet it mirrors: the ACCEPT
/// button appears once the reader reached the end of the pane. A server with no
/// rules file, or one that does not answer, is said so plainly and the user
/// still decides.
///
/// Returns true when the user chose to go on (accepted, or subscribed anyway);
/// false when they closed the sheet.
Future<bool> showServerRulesSheet(BuildContext context,
    {required String apiUrl, required String serverName}) async {
  final accepted = ValueNotifier<bool>(false);
  await showPhigitalBottomSheet<void>(
    context: context,
    // The body paints its own glass.
    wrapInChrome: false,
    maxWidth: DialogWidth.l,
    builder: (_, __) =>
        ServerRulesSheet(apiUrl: apiUrl, serverName: serverName, accepted: accepted),
  );
  final result = accepted.value;
  accepted.dispose();
  return result;
}

class ServerRulesSheet extends StatefulWidget {
  final String apiUrl;
  final String serverName;

  /// Set to true when the user goes on. Owned by the caller, because a sheet
  /// dismissed by a drag returns nothing.
  final ValueNotifier<bool> accepted;

  const ServerRulesSheet({
    super.key,
    required this.apiUrl,
    required this.serverName,
    required this.accepted,
  });

  @override
  State<ServerRulesSheet> createState() => _ServerRulesSheetState();
}

class _ServerRulesSheetState extends State<ServerRulesSheet> {
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  SspRules? _rules;
  SspRulesStatus _status = SspRulesStatus.unreachable;
  bool _reachedEnd = false;

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
    setState(() => _loading = true);
    final r = await PublicOSSsp.fetchRules(widget.apiUrl);
    if (!mounted) return;
    setState(() {
      _rules = r.rules;
      _status = r.status;
      _loading = false;
    });
    // Rules short enough to need no scrolling have been read once painted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFitsWithoutScroll());
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

  void _goOn() {
    widget.accepted.value = true;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return FractionallySizedBox(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.netServerRulesTitle,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.starkWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          widget.serverName,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.textDim,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(tokens, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _body(GlassTokens tokens, AppLocalizations l10n) {
    if (_loading) return const Center(child: PhigitalLoadingWidget(size: 48));
    final rules = _rules;
    if (rules == null) {
      return _notice(
        tokens,
        _status == SspRulesStatus.unreachable
            ? Icons.cloud_off_rounded
            : Icons.hourglass_empty_rounded,
        _status == SspRulesStatus.unreachable
            ? l10n.netServerRulesUnreachable
            : l10n.netServerRulesMissing,
        l10n,
      );
    }
    final lang = Localizations.localeOf(context).languageCode;
    final heading = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.textDim,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.5,
    );
    final body = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.starkWhite,
      fontSize: 14,
      height: 1.55,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.netServerRulesAccept,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite.withValues(alpha: 0.85),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.netServerRulesVersion(rules.version.toString(), rules.effectiveFrom),
            style: heading,
          ),
          const SizedBox(height: 12),
          // The rules and the privacy notice, in one bordered reading pane, so
          // "reached the end" is a fact about THIS box and not about the sheet.
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.netServerRulesTitle.toUpperCase(), style: heading),
                      const SizedBox(height: 8),
                      Text(rules.rulesFor(lang), style: body),
                      const SizedBox(height: 22),
                      Text(l10n.netServerPrivacyTitle.toUpperCase(), style: heading),
                      const SizedBox(height: 8),
                      Text(rules.privacyFor(lang), style: body),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          // The button is EARNED by reading; until then a hint sits in the
          // same height, so nothing jumps when it appears.
          SizedBox(
            height: 48,
            child: _reachedEnd
                ? SystemAppActionButton(
                    label: l10n.netServerRulesAcceptButton,
                    icon: Icons.check_rounded,
                    onTap: _goOn,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_double_arrow_down_rounded,
                          size: 18, color: tokens.textDim),
                      const SizedBox(width: 8),
                      Text(l10n.operatorAgreementScrollHint, style: heading),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _notice(GlassTokens tokens, IconData icon, String text, AppLocalizations l10n) {
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
          const SizedBox(height: 24),
          SystemAppActionButton(
            label: l10n.netServerRulesSubscribeAnyway,
            icon: Icons.arrow_forward_rounded,
            onTap: _goOn,
          ),
          if (_status == SspRulesStatus.unreachable) ...[
            const SizedBox(height: 12),
            SystemAppActionButton(
              label: l10n.operatorAgreementRetry,
              icon: Icons.refresh_rounded,
              onTap: _load,
            ),
          ],
        ],
      ),
    );
  }
}
