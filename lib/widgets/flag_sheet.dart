// Ported from the mobile client's components/flag_sheet.dart; only the
// imports differ.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/phigital_bottom_sheet.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_action_button.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// The flag sheet: the one door every flag goes through — a post or comment
/// "⋯" menu, the flag button on a channel's counts line, the flag button on a
/// profile.
///
/// Opens on the caller's own flag when there is one, with WITHDRAW while it
/// is open; a closed one past the re-flag cooldown opens on the categories
/// again (one open flag per person per target, then a court-set cooldown).
/// Otherwise: the 12 public categories, then the three private kinds
/// (privacy · intimate images · child safety), which are never flags and only
/// explain that they go to the host as a notice.
///
/// [url] is the content's address as served (the target is
/// `keccak256(prefix + url)`); '' for a profile. The host slug is matched here
/// from [url] against the registered SSPs (client-side); no
/// match = a flag with no host, which the contract allows.
///
/// Returns true when a flag was filed or withdrawn.
Future<bool> showFlagSheet(
  BuildContext context, {
  required EthereumAddress owner,
  required FlagTargetKind kind,
  String url = '',
  Uint8List? target,
}) async {
  final changed = ValueNotifier<bool>(false);
  await showPhigitalBottomSheet<void>(
    context: context,
    // The body paints its own glass.
    wrapInChrome: false,
    builder: (_, __) =>
        FlagSheet(
        owner: owner, kind: kind, url: url, target: target, changed: changed),
  );
  final result = changed.value;
  changed.dispose();
  return result;
}

/// The label for a category id; an id the court enabled later shows its number.
String flagCategoryLabel(AppLocalizations l10n, int id) => switch (id) {
      0 => l10n.flagCategory0,
      1 => l10n.flagCategory1,
      2 => l10n.flagCategory2,
      3 => l10n.flagCategory3,
      4 => l10n.flagCategory4,
      5 => l10n.flagCategory5,
      6 => l10n.flagCategory6,
      7 => l10n.flagCategory7,
      8 => l10n.flagCategory8,
      9 => l10n.flagCategory9,
      10 => l10n.flagCategory10,
      11 => l10n.flagCategory11,
      _ => l10n.flagCategoryUnknown(id.toString()),
    };

/// What a stored flag points at, read back from its url (the chain keeps only
/// the hash): a comment's url carries `/comments/`, a post's `/posts/`, a
/// profile flag has none.
FlagTargetKind flagKindOf(Flag f) {
  if (f.isProfile) return FlagTargetKind.profile;
  if (f.url.contains('/comments/')) return FlagTargetKind.comment;
  if (f.url.contains('/posts/')) return FlagTargetKind.post;
  return FlagTargetKind.feed;
}

String flagKindLabel(AppLocalizations l10n, FlagTargetKind k) => switch (k) {
      FlagTargetKind.post => l10n.flagKindPost,
      FlagTargetKind.comment => l10n.flagKindComment,
      FlagTargetKind.feed => l10n.flagKindChannel,
      FlagTargetKind.media => l10n.flagKindPost,
      FlagTargetKind.profile => l10n.flagKindProfile,
    };

String flagDate(BuildContext context, DateTime d) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(d);

/// One status line for a flag (expiry is worked out, not stored).
String flagStatusText(BuildContext context, Flag f) {
  final l10n = context.l10n;
  return switch (f.status) {
    FlagStatus.active => f.isOpen
        ? l10n.flagStatusOpenUntil(flagDate(context, f.expiresAt))
        : l10n.flagStatusExpired,
    FlagStatus.withdrawn => l10n.flagStatusWithdrawn,
    FlagStatus.removed => l10n.flagStatusRemoved,
    FlagStatus.cleared => l10n.flagStatusCleared,
  };
}

/// A comment's own address: its post's URL + `/comments/<uid>` (the server's
/// route; a reply's `targetUrl` already points at a comment, so cut back to
/// the post first). Null when the target is not a PublicOS post URL.
String? commentFlagUrl(String targetUrl, String commentUid) {
  final m = RegExp(r'^(.*?/posts/[^/?#]+)').firstMatch(targetUrl);
  if (m == null || commentUid.isEmpty) return null;
  return '${m.group(1)}/comments/$commentUid';
}

/// A channel's flag address: its base `…/api/<owner>/channels/<slug>`, with
/// no format ending, so the same channel read as JSON, RSS or Atom is one
/// target. Null when [feedUrl] is not a PublicOS channel.
String? channelFlagUrl(String feedUrl) =>
    RegExp(r'^(.*?/api/0x[0-9a-fA-F]{40}/channels/[^/?#]+)')
        .firstMatch(feedUrl)
        ?.group(1);

enum _Phase { loading, already, choosing, sending, failed, done }

/// The three private kinds sit below the 12 public categories with ids of
/// their own (never sent: they are not flags).
const _privacy = -1, _intimate = -2, _childSafety = -3;

class FlagSheet extends StatefulWidget {
  final EthereumAddress owner;
  final FlagTargetKind kind;
  final String url;

  /// The stored target, when reopening a flag from a list (the kind read back
  /// from a url is a guess; the hash is not). Null = computed from kind + url.
  final Uint8List? target;

  /// Flipped to true once a flag lands or is withdrawn. Owned by the caller,
  /// because a sheet dismissed by a drag returns nothing.
  final ValueNotifier<bool> changed;

  const FlagSheet({
    super.key,
    required this.owner,
    required this.kind,
    required this.url,
    this.target,
    required this.changed,
  });

  @override
  State<FlagSheet> createState() => _FlagSheetState();
}

class _FlagSheetState extends State<FlagSheet> {
  /// SSP slug by api host, filled once per app run (a handful of servers).
  static Map<String, String>? _slugByHost;

  final TextEditingController _note = TextEditingController();
  _Phase _phase = _Phase.loading;
  Flag? _mine;
  // When the caller may flag this again (their closed flag + the court's
  // re-flag cooldown); null while their flag is open or before the read.
  DateTime? _againAt;
  int? _category;
  bool _withdrawing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _note.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Uint8List get _target =>
      widget.target ?? PublicOSCommunityStandards.flagTarget(widget.kind, widget.url);

  Future<void> _load() async {
    try {
      final mine = await PublicOSCommunityStandards.getMyFlagOn(widget.owner, _target);
      DateTime? againAt;
      if (mine != null) {
        // One open flag each; after it closes, a new one once the cooldown has
        // passed since it was filed.
        final cooldown = await PublicOSCommunityStandards.reflagCooldown();
        againAt = mine.createdAt.add(cooldown);
      }
      if (!mounted) return;
      final free = mine == null ||
          (!mine.isOpen && !DateTime.now().isBefore(againAt!));
      setState(() {
        _mine = mine;
        _againAt = againAt;
        _phase = free ? _Phase.choosing : _Phase.already;
      });
    } catch (e) {
      Log.e('FlagSheet', 'load failed: $e');
      // Let the contract decide: a second flag reverts with its own reason.
      if (mounted) setState(() => _phase = _Phase.choosing);
    }
  }

  /// The registered SSP serving [url], by host; '' when none matches.
  static Future<String> _hostSlugFor(String url) async {
    final host = Uri.tryParse(url)?.host ?? '';
    if (host.isEmpty) return '';
    if (_slugByHost == null) {
      final map = <String, String>{};
      try {
        final mem = PublicOSBsp.socialServerRegistryMemoryContract;
        final total = await mem.getTotalSocialServerCount();
        final slugs =
            await mem.getSocialServerSlugs((offset: BigInt.zero, limit: total));
        for (final slug in slugs) {
          // struct tuple: [exists, slug, title, apiUrl, region, owner]
          final s = await mem.getSocialServerBySlug((slug: slug)) as List;
          if (s[0] != true) continue;
          final h = Uri.tryParse(s[3] as String)?.host ?? '';
          if (h.isNotEmpty) map[h] = slug;
        }
        _slugByHost = map;
      } catch (e) {
        Log.w('FlagSheet', 'SSP list unavailable, flag goes without a host: $e');
        return '';
      }
    }
    return _slugByHost![host] ?? '';
  }

  bool get _isPrivateKind => _category != null && _category! < 0;

  bool get _canSubmit =>
      _category != null &&
      !_isPrivateKind &&
      // The contract counts bytes, not characters (an accent is two).
      utf8.encode(_note.text.trim()).length <= PublicOSCommunityStandards.flagNoteMaxBytes;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _phase = _Phase.sending;
      _error = null;
    });
    final host = await _hostSlugFor(widget.url);
    final ok = await PublicOSCommunityStandards.flag(
      owner: widget.owner,
      kind: widget.kind,
      url: widget.url,
      host: host,
      category: _category!,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      widget.changed.value = true;
      setState(() => _phase = _Phase.done);
    } else {
      setState(() {
        _error = PublicOS.lastError;
        _phase = _Phase.failed;
      });
    }
  }

  Future<void> _withdraw() async {
    setState(() {
      _withdrawing = true;
      _error = null;
    });
    final ok = await PublicOSCommunityStandards.unflag(widget.owner, _target);
    if (!mounted) return;
    if (ok) {
      widget.changed.value = true;
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(context.l10n.flagWithdrawn)));
      Navigator.of(context).pop();
    } else {
      setState(() {
        _withdrawing = false;
        _error = PublicOS.lastError;
      });
    }
  }

  String _title(AppLocalizations l10n) => switch (widget.kind) {
        FlagTargetKind.post || FlagTargetKind.media => l10n.flagSheetTitlePost,
        FlagTargetKind.comment => l10n.flagSheetTitleComment,
        FlagTargetKind.feed => l10n.flagSheetTitleChannel,
        FlagTargetKind.profile => l10n.flagSheetTitleProfile,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final busy = _phase == _Phase.sending || _withdrawing;

    return PopScope(
      // A transaction is in flight: closing would not undo it, only hide it.
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
                    Icon(Icons.flag_outlined, size: 20, color: tokens.softDanger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _phase == _Phase.already ? l10n.flagAlreadyTitle : _title(l10n),
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
      case _Phase.sending:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const PhigitalLoadingWidget(size: 56),
              const SizedBox(height: 18),
              Text(l10n.flagSending, style: _eyebrow(tokens)),
            ],
          ),
        );
      case _Phase.done:
        return _notice(tokens, Icons.flag_rounded, l10n.flagDone);
      case _Phase.already:
        return _already(tokens, l10n);
      case _Phase.choosing:
      case _Phase.failed:
        return _choosing(tokens, l10n);
    }
  }

  TextStyle _eyebrow(GlassTokens tokens) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      );

  TextStyle _body14(GlassTokens tokens) => TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.starkWhite.withValues(alpha: 0.85),
        fontSize: 14,
        height: 1.45,
      );

  Widget _notice(GlassTokens tokens, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: tokens.textDim),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: _body14(tokens)),
        ],
      ),
    );
  }

  Widget _errorLine(GlassTokens tokens, AppLocalizations l10n, String lead) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        // Through the app's error translator, never the raw node message.
        localizedError(l10n, _error, fallback: lead),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.softDanger,
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _already(GlassTokens tokens, AppLocalizations l10n) {
    final f = _mine!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.flagFiledOn(flagCategoryLabel(l10n, f.category), flagDate(context, f.createdAt)),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(flagStatusText(context, f), style: _eyebrow(tokens)),
          if (f.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(f.note, style: _body14(tokens)),
          ],
          const Spacer(),
          if (!f.isOpen && _againAt != null)
            Text(
              l10n.flagAgainOn(flagDate(context, _againAt!)),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 12),
            ),
          if (f.isOpen) ...[
            Text(
              l10n.flagWithdrawNote(flagDate(context, _againAt ?? f.createdAt)),
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.textDim, fontSize: 12),
            ),
            const SizedBox(height: 10),
            if (_error != null) _errorLine(tokens, l10n, l10n.flagFailed),
            SizedBox(
              height: 48,
              child: SystemAppActionButton(
                label: _withdrawing ? l10n.flagWithdrawing : l10n.flagWithdraw,
                icon: Icons.undo_rounded,
                onTap: _withdrawing ? null : _withdraw,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _choosing(GlassTokens tokens, AppLocalizations l10n) {
    final public = PublicOSCommunityStandards.flagCategories;
    final private = [
      (_privacy, l10n.flagPrivacy),
      (_intimate, l10n.flagIntimate),
      (_childSafety, l10n.flagChildSafety),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.flagSheetLead, style: _body14(tokens)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                for (final id in public) _option(tokens, id, flagCategoryLabel(l10n, id)),
                const SizedBox(height: 14),
                Text(l10n.flagPrivateHeader, style: _eyebrow(tokens)),
                const SizedBox(height: 6),
                for (final (id, label) in private) _option(tokens, id, label),
                if (_isPrivateKind) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tokens.glassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.borderSubtle),
                    ),
                    child: Text(l10n.flagPrivateBody, style: _body14(tokens)),
                  ),
                ],
              ],
            ),
          ),
          if (_category != null && !_isPrivateKind) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _note,
              maxLength: PublicOSCommunityStandards.flagNoteMaxBytes,
              maxLines: 2,
              minLines: 1,
              style: TextStyle(fontFamily: 'SpaceGrotesk', color: tokens.starkWhite, fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.flagNoteHint,
                hintStyle: TextStyle(color: tokens.textDim),
                filled: true,
                fillColor: tokens.glassFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: tokens.borderSubtle),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (_phase == _Phase.failed) _errorLine(tokens, l10n, l10n.flagFailed),
          SizedBox(
            height: 48,
            child: SystemAppActionButton(
              label: l10n.flagSubmit,
              icon: Icons.flag_rounded,
              accent: tokens.softDanger,
              onTap: _canSubmit ? _submit : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(GlassTokens tokens, int id, String label) {
    final selected = _category == id;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() {
        _category = id;
        if (_phase == _Phase.failed) _phase = _Phase.choosing;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: selected ? tokens.softDanger : tokens.textDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
