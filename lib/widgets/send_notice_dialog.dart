// Ported from the mobile client's components/send_notice_sheet.dart. The
// body (SendNoticeBody) is the same; the client shows it in
// a bottom sheet, desktop in a centered glass dialog. Imports differ.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/network_access_sheets.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_action_button.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Send an SSP notice, desktop.
///
/// Pick a registered SSP (search over the provider directory), check it has a
/// `notice_key`, pick the kind, write, send. The letter is sealed to the SSP's
/// notice key and, for ordinary kinds, filed on chain as public evidence
/// (`PublicOSCommunityStandards.sendNotice`); the three sensitive kinds stay
/// off chain.
Future<void> showSendNoticeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final tokens = GlassTokens.of(context);
      return Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: tokens.surfaceDeep,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: DialogWidth.l,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.8,
                ),
                child: const SendNoticeBody(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

enum _Step { pick, write, sending, sent, failed }

/// The notice flow, shared by the mobile sheet and the desktop dialog.
class SendNoticeBody extends StatefulWidget {
  const SendNoticeBody({super.key});

  @override
  State<SendNoticeBody> createState() => _SendNoticeBodyState();
}

class _SendNoticeBodyState extends State<SendNoticeBody> {
  final _search = TextEditingController();
  final _about = TextEditingController();
  final _text = TextEditingController();

  _Step _step = _Step.pick;
  List<ProviderEntry>? _all;
  bool _loadFailed = false;
  ProviderEntry? _ssp;
  bool _checkingKey = false;
  String? _pickError;
  NoticeKind _kind = NoticeKind.takedown;
  NoticeSent? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _about.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _all = null;
      _loadFailed = false;
    });
    try {
      final list = await fetchProviderDirectory(ProviderKind.ssp, 200);
      if (mounted) setState(() => _all = list);
    } catch (e) {
      Log.e('SendNotice', 'SSP directory failed: $e');
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  Future<void> _pick(ProviderEntry e) async {
    setState(() {
      _checkingKey = true;
      _pickError = null;
    });
    final key = await PublicOSCommunityStandards.noticeKeyOf(e.slug);
    if (!mounted) return;
    if (key == null) {
      setState(() {
        _checkingKey = false;
        _pickError = context.l10n.noticeNoKey;
      });
      return;
    }
    setState(() {
      _checkingKey = false;
      _ssp = e;
      _step = _Step.write;
    });
  }

  Future<void> _send() async {
    final ssp = _ssp;
    if (ssp == null || _text.text.trim().isEmpty) return;
    setState(() {
      _step = _Step.sending;
      _error = null;
    });
    final r = await PublicOSCommunityStandards.sendNotice(
      host: ssp.slug,
      apiUrl: ssp.apiUrl,
      kind: _kind,
      text: _text.text.trim(),
      about: _about.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _result = r;
      _error = r == null ? PublicOS.lastError : null;
      _step = r == null ? _Step.failed : _Step.sent;
    });
  }

  String _kindLabel(AppLocalizations l10n, NoticeKind k) => switch (k) {
        NoticeKind.takedown => l10n.noticeTypeTakedown,
        NoticeKind.lawfulOrder => l10n.noticeTypeLawfulOrder,
        NoticeKind.ipClaim => l10n.noticeTypeIpClaim,
        NoticeKind.appeal => l10n.noticeTypeAppeal,
        NoticeKind.abuseReport => l10n.noticeTypeAbuseReport,
        NoticeKind.privacy => l10n.noticeTypePrivacy,
        NoticeKind.intimateImage => l10n.noticeTypeIntimateImage,
        NoticeKind.childSafety => l10n.noticeTypeChildSafety,
      };

  TextStyle _style(GlassTokens tokens,
          {double size = 14, Color? color, FontWeight? weight, double? spacing}) =>
      TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: color ?? tokens.starkWhite,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: spacing,
        height: 1.45,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final busy = _step == _Step.sending;
    return PopScope(
      canPop: !busy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(l10n.noticeTitle,
                      style: _style(tokens, size: 18, weight: FontWeight.w800, spacing: -0.3)),
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
    );
  }

  Widget _body(GlassTokens tokens, AppLocalizations l10n) {
    switch (_step) {
      case _Step.pick:
        return _pickView(tokens, l10n);
      case _Step.write:
        return _writeView(tokens, l10n);
      case _Step.sending:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhigitalLoadingWidget(size: 56),
              const SizedBox(height: 18),
              Text(l10n.noticeSending,
                  style: _style(tokens,
                      size: 11, color: tokens.textDim, weight: FontWeight.w800, spacing: 1.5)),
            ],
          ),
        );
      case _Step.sent:
        return _sentView(tokens, l10n);
      case _Step.failed:
        return _writeView(tokens, l10n, failed: true);
    }
  }

  Widget _field(GlassTokens tokens, TextEditingController c, String hint,
      {int minLines = 1, int maxLines = 1, ValueChanged<String>? onChanged, IconData? icon}) {
    return TextField(
      controller: c,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      style: _style(tokens),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: _style(tokens, color: tokens.textDim),
        prefixIcon: icon == null ? null : Icon(icon, color: tokens.textDim, size: 20),
        filled: true,
        fillColor: tokens.glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderMedium),
        ),
      ),
    );
  }

  Widget _pickView(GlassTokens tokens, AppLocalizations l10n) {
    final q = _search.text.trim().toLowerCase();
    final all = _all;
    final hits = all == null
        ? const <ProviderEntry>[]
        : all
            .where((e) =>
                q.isEmpty ||
                e.slug.toLowerCase().contains(q) ||
                e.title.toLowerCase().contains(q) ||
                e.apiUrl.toLowerCase().contains(q))
            .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(tokens, _search, l10n.noticeSearchHint,
              icon: Icons.search_rounded, onChanged: (_) => setState(() {})),
          if (_pickError != null) ...[
            const SizedBox(height: 10),
            Text(_pickError!, style: _style(tokens, size: 12, color: tokens.softDanger)),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: _loadFailed
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(l10n.noticeLoadFailed, style: _style(tokens, color: tokens.textDim)),
                      const SizedBox(height: 16),
                      SystemAppActionButton(
                          label: l10n.citizenClaimRetry, icon: Icons.refresh_rounded, onTap: _load),
                    ]),
                  )
                : all == null || _checkingKey
                    ? const Center(child: PhigitalLoadingWidget(size: 48))
                    : hits.isEmpty
                        ? Center(
                            child: Text(l10n.noticeNoResults,
                                style: _style(tokens, color: tokens.textDim)))
                        : ListView.separated(
                            itemCount: hits.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) {
                              final e = hits[i];
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _pick(e),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: tokens.glassFill,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: tokens.borderSubtle),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title.isEmpty ? e.slug : e.title,
                                          style: _style(tokens, weight: FontWeight.w700)),
                                      Text('${e.slug} · ${e.apiUrl}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: _style(tokens, size: 12, color: tokens.textDim)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _writeView(GlassTokens tokens, AppLocalizations l10n, {bool failed = false}) {
    final ssp = _ssp!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(ssp.title.isEmpty ? ssp.slug : ssp.title,
                  style: _style(tokens, weight: FontWeight.w700)),
            ),
            TextButton(
              onPressed: () => setState(() {
                _ssp = null;
                _step = _Step.pick;
              }),
              child: Text(l10n.noticeChange,
                  style: _style(tokens, size: 11, color: tokens.textDim, weight: FontWeight.w800, spacing: 1.2)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(l10n.noticeTypeLabel.toUpperCase(),
            style: _style(tokens, size: 10, color: tokens.textDim, weight: FontWeight.w800, spacing: 1.5)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in NoticeKind.values)
              ChoiceChip(
                label: Text(_kindLabel(l10n, k),
                    style: _style(tokens, size: 12, color: _kind == k ? tokens.surfaceDeep : tokens.starkWhite)),
                selected: _kind == k,
                selectedColor: tokens.starkWhite,
                backgroundColor: tokens.glassFill,
                side: BorderSide(color: tokens.borderSubtle),
                showCheckmark: false,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(_kind.offChain ? l10n.noticeOffChainNote : l10n.noticeOnChainNote,
            style: _style(tokens, size: 12, color: tokens.textDim)),
        const SizedBox(height: 14),
        _field(tokens, _about, l10n.noticeAboutHint, icon: Icons.link_rounded),
        const SizedBox(height: 10),
        _field(tokens, _text, l10n.noticeTextHint,
            minLines: 5, maxLines: 12, onChanged: (_) => setState(() {})),
        if (failed) ...[
          const SizedBox(height: 12),
          Text(
            _error == null || _error!.isEmpty ? l10n.noticeFailed : '${l10n.noticeFailed} $_error',
            style: _style(tokens, size: 12, color: tokens.softDanger),
          ),
        ],
        const SizedBox(height: 16),
        Opacity(
          opacity: _text.text.trim().isEmpty ? 0.4 : 1,
          child: SystemAppActionButton(
            label: failed ? l10n.citizenClaimRetry : l10n.noticeSend,
            icon: Icons.send_rounded,
            onTap: _text.text.trim().isEmpty ? null : _send,
          ),
        ),
      ],
    );
  }

  Widget _sentView(GlassTokens tokens, AppLocalizations l10n) {
    final r = _result!;
    final ssp = _ssp!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_read_rounded, size: 64, color: tokens.connectedAccent),
          const SizedBox(height: 18),
          Text(l10n.noticeSentTitle,
              textAlign: TextAlign.center,
              style: _style(tokens, size: 22, weight: FontWeight.w800, spacing: -0.4)),
          const SizedBox(height: 10),
          Text(l10n.noticeSentBody(ssp.title.isEmpty ? ssp.slug : ssp.title),
              textAlign: TextAlign.center, style: _style(tokens, color: tokens.textDim)),
          if (r.onChain) ...[
            const SizedBox(height: 6),
            Text(l10n.noticeSentOnChain(r.noticeId.toString()),
                textAlign: TextAlign.center, style: _style(tokens, size: 12, color: tokens.textDim)),
          ],
          const SizedBox(height: 24),
          SystemAppActionButton(
            label: l10n.noticeDone,
            icon: Icons.check_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
