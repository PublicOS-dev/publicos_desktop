import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// THE inbox-tab dialog — one surface behind every flow that changes which
/// chat tabs a profile publishes: the keychain's publish offer after a key
/// loads, and Register / Rename / Remove on the Inbox IDs page. One dialog,
/// one safety net: a duplicate label never spends gas, reverts, and dismisses
/// in silence.
///
/// It shows what the action DOES: the profile tabs you already publish, then
/// the one being added — dashed, filling in as you type — or, for a removal,
/// the one being taken away, struck through. Same idea on desktop, mimicking
/// the deck's tab strip instead of the switcher's rows.
///
/// It owns the write, so it can wait for the chain and keep the user here on
/// failure: [InboxTabResult.saved] is true only after the chain confirmed.
///
/// Chrome is the glass-dark dialog (`GlassTheme.glassBox` over
/// `surfaceDeep`, uppercase title, no tinted accent unless the action is
/// destructive).
///
/// Client twin: `publicos_client/lib/components/keychain/inbox_tab_dialog.dart`
/// (identical but for these imports and the preview's tighter geometry).
/// A label the contract accepts (`XmtpManager._validateLabel`: 1 to 31 bytes of
/// `[a-z0-9._-]`, first one `[a-z0-9_]`), made from any text: lowered, the rest
/// dropped. Without it a key named "publicBox" would pre-fill the field as it
/// is and the chain would refuse it ("label has invalid character"): the
/// field's formatters only run on typing, never on a pre-filled value.
String inboxLabelFrom(String text) {
  var s = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  s = s.replaceFirst(RegExp(r'^[.-]+'), '');
  return s.length > 31 ? s.substring(0, 31) : s;
}

enum InboxTabMode { register, rename, remove }

class InboxTabResult {
  /// True only when the chain accepted the write.
  final bool saved;

  /// The label as written (empty for a removal, or when nothing was saved).
  final String label;

  /// The keychain offer's "don't ask again" box; false everywhere else.
  final bool dontAskAgain;

  const InboxTabResult({
    required this.saved,
    this.label = '',
    this.dontAskAgain = false,
  });
}

/// [account] owns the directory being written to, [accountName] is its display
/// name (the fixed `name/` prefix, and the tab preview's owner). [inboxIdBytes]
/// is the inbox being named or removed. In [InboxTabMode.rename] and
/// [InboxTabMode.remove], [currentLabel] is the tab in question — excluded
/// from the duplicate check, and the one the preview marks. Returns null when
/// dismissed with nothing saved.
Future<InboxTabResult?> showInboxTabDialog(
  BuildContext context, {
  required EthereumAddress account,
  required String? accountName,
  required Uint8List inboxIdBytes,
  required InboxTabMode mode,
  required String title,
  required String cta,
  String? subtitle,
  String? currentLabel,
  String? initialLabel,
  bool offerDontAsk = false,
}) {
  return showDialog<InboxTabResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _InboxTabDialog(
      account: account,
      accountName: accountName,
      inboxIdBytes: inboxIdBytes,
      mode: mode,
      title: title,
      cta: cta,
      subtitle: subtitle,
      currentLabel: currentLabel,
      initialLabel: initialLabel,
      offerDontAsk: offerDontAsk,
    ),
  );
}

class _InboxTabDialog extends StatefulWidget {
  final EthereumAddress account;
  final String? accountName;
  final Uint8List inboxIdBytes;
  final InboxTabMode mode;
  final String title;
  final String cta;
  final String? subtitle;
  final String? currentLabel;
  final String? initialLabel;
  final bool offerDontAsk;

  const _InboxTabDialog({
    required this.account,
    required this.accountName,
    required this.inboxIdBytes,
    required this.mode,
    required this.title,
    required this.cta,
    this.subtitle,
    this.currentLabel,
    this.initialLabel,
    this.offerDontAsk = false,
  });

  @override
  State<_InboxTabDialog> createState() => _InboxTabDialogState();
}

class _InboxTabDialogState extends State<_InboxTabDialog> {
  final _controller = TextEditingController();

  /// Labels already published by this account, in directory order. Empty until
  /// the read lands; `null` while it is in flight.
  List<String>? _existing;

  bool _saving = false;
  bool _dontAsk = false;

  /// Shown under the field: the duplicate warning, or whatever the chain said.
  String? _error;

  bool get _isRemove => widget.mode == InboxTabMode.remove;

  @override
  void initState() {
    super.initState();
    _controller.text = inboxLabelFrom(widget.initialLabel ?? '');
    _controller.addListener(_onTyped);
    _loadExisting();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTyped);
    _controller.dispose();
    super.dispose();
  }

  void _onTyped() {
    // A fresh keystroke clears a chain error: it described the previous name.
    if (_error != null) {
      setState(() => _error = null);
    } else {
      setState(() {});
    }
  }

  Future<void> _loadExisting() async {
    try {
      final dir = await PublicOSXmtp.getAllAccountInboxIds(widget.account);
      if (!mounted) return;
      setState(() {
        _existing = dir == null
            ? const <String>[]
            : dir.labels.where((l) => l.trim().isNotEmpty).toList();
      });
    } catch (_) {
      if (mounted) setState(() => _existing = const <String>[]);
    }
  }

  String get _typed => _controller.text.trim().toLowerCase();

  /// The labels a new name would collide with — everything published except
  /// the tab being renamed or removed.
  List<String> get _taken {
    final all = _existing ?? const <String>[];
    final own = widget.currentLabel?.toLowerCase();
    return all.where((l) => l.toLowerCase() != own).toList();
  }

  bool get _isDuplicate =>
      _typed.isNotEmpty && _taken.any((l) => l.toLowerCase() == _typed);

  bool get _canSave {
    if (_saving || _existing == null) return false;
    if (_isRemove) return true;
    return _typed.isNotEmpty &&
        !_isDuplicate &&
        _typed != widget.currentLabel?.toLowerCase();
  }

  /// The write itself, awaited HERE: the dialog stays open and explains a
  /// failure instead of dismissing silently. Core returns
  /// false rather than throwing, so a revert has no message of its own — the
  /// two knowable causes (someone else's inbox, a name you already use) are
  /// caught before spending anything.
  Future<void> _save() async {
    final label = inboxLabelFrom(_controller.text.trim());
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.mode == InboxTabMode.register) {
        final owner =
            await PublicOSXmtp.getAccountAddressByInboxId(widget.inboxIdBytes);
        if (owner != null) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _error = context.l10n.inboxTabOtherOwner;
          });
          return;
        }
      }
      final bool ok;
      switch (widget.mode) {
        case InboxTabMode.register:
          ok = await PublicOSXmtp.registerInboxId(widget.inboxIdBytes, label);
        case InboxTabMode.rename:
          ok =
              await PublicOSXmtp.updateInboxIdLabel(widget.inboxIdBytes, label);
        case InboxTabMode.remove:
          ok = await PublicOSXmtp.removeInboxId(widget.inboxIdBytes);
      }
      if (!mounted) return;
      if (ok) {
        Navigator.pop(
          context,
          InboxTabResult(
            saved: true,
            label: _isRemove ? (widget.currentLabel ?? '') : label,
            dontAskAgain: _dontAsk,
          ),
        );
        return;
      }
      setState(() {
        _saving = false;
        _error = context.l10n.inboxTabSaveFailed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = context.l10n.inboxTabSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final prefix = (widget.accountName == null || widget.accountName!.isEmpty)
        ? null
        : '${widget.accountName}/';
    // Amber only when the action takes something away — the app is monochrome
    // by default.
    final accent = _isRemove ? tokens.fallbackAccent : tokens.starkWhite;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: GlassTheme.glassBox(context).copyWith(
            color: tokens.surfaceDeep,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRemove ? Icons.tab_unselected : Icons.tab_rounded,
                      size: 20,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        widget.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.starkWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      height: 1.5,
                      color: tokens.textDim,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _preview(tokens),
                if (!_isRemove) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !_saving,
                    style: TextStyle(
                        fontFamily: 'SpaceGrotesk', color: tokens.starkWhite),
                    // The contract's own charset (`XmtpManager._validateLabel`):
                    // 31 bytes, `[a-z0-9._-]`. Uppercase is lowered, not dropped.
                    maxLength: 31,
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (_, next) =>
                            next.copyWith(text: next.text.toLowerCase()),
                      ),
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._-]')),
                    ],
                    decoration: InputDecoration(
                      hintText: l10n.inboxIdsLabelHint,
                      hintStyle: TextStyle(
                          fontFamily: 'SpaceGrotesk', color: tokens.textDim),
                      prefixText: prefix,
                      prefixStyle: TextStyle(
                          fontFamily: 'SpaceGrotesk', color: tokens.textDim),
                      filled: true,
                      fillColor: tokens.glassFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: tokens.borderMedium),
                      ),
                      errorText: _isDuplicate
                          ? l10n.inboxTabDuplicate(_typed)
                          : _error,
                    ),
                    onSubmitted: (_) {
                      if (_canSave) _save();
                    },
                  ),
                ],
                if (_isRemove && _error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      color: tokens.softDanger,
                    ),
                  ),
                ],
                if (widget.offerDontAsk)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _dontAsk,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() => _dontAsk = v ?? false),
                    title: Text(l10n.keychainOfferRegDontAsk,
                        style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 13,
                            color: tokens.textDim)),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.starkWhite,
                          side: BorderSide(color: tokens.borderMedium),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(
                                  context,
                                  InboxTabResult(
                                      saved: false, dontAskAgain: _dontAsk),
                                ),
                        child: Text(
                          l10n.actionCancel,
                          style: const TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: tokens.background,
                          disabledBackgroundColor: tokens.glassFill,
                          disabledForegroundColor: tokens.textDim,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _canSave ? _save : null,
                        child: _saving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.background,
                                ),
                              )
                            : Text(
                                widget.cta,
                                style: const TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The point of the dialog: your profile's chat tabs, then what the action
  /// changes — a dashed tab being added, or the one being taken away struck
  /// through. DELTA(desktop): the client mirrors the switcher sheet's rows;
  /// this side mirrors the browser deck's tab strip, so the rows are tighter
  /// (28 px glyph box, 13 px label) and read as deck tabs.
  Widget _preview(GlassTokens tokens) {
    final l10n = context.l10n;
    final existing = _existing;
    if (existing == null) {
      return SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: tokens.textDim),
          ),
        ),
      );
    }

    final shown = _taken.take(2).toList();
    final hidden = _taken.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (shown.isEmpty && widget.mode == InboxTabMode.register)
          // First ever: the same tab-shaped space, no chat glyph, saying the
          // profile has none yet. Not in rename/remove — there
          // the tab in question IS the profile's inbox, it just moved down.
          _row(tokens, label: l10n.inboxTabNoneYet, glyph: null, muted: true)
        else if (shown.isNotEmpty)
          for (final label in shown) _row(tokens, label: label),
        if (hidden > 0)
          Padding(
            padding: const EdgeInsets.only(left: 40, top: 2, bottom: 2),
            child: Text(
              l10n.inboxTabMore(hidden),
              style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.textDim),
            ),
          ),
        if (_isRemove)
          // The mirror image of adding one: the tab that is going away, struck
          // through in the warning tone.
          _row(
            tokens,
            label: widget.currentLabel?.isNotEmpty == true
                ? widget.currentLabel!
                : l10n.browserTabChat,
            going: true,
          )
        else
          _row(
            tokens,
            label: _controller.text.trim().isEmpty
                ? l10n.inboxIdsLabelHint
                : _controller.text.trim(),
            ghost: true,
            muted: _controller.text.trim().isEmpty,
          ),
      ],
    );
  }

  Widget _row(
    GlassTokens tokens, {
    required String label,
    IconData? glyph = Icons.chat_bubble_outline_rounded,
    bool ghost = false,
    bool muted = false,
    bool going = false,
  }) {
    final fg = going
        ? tokens.fallbackAccent
        : muted
            ? tokens.textDim
            : tokens.starkWhite;
    final box = SizedBox(
      width: 28,
      height: 28,
      child: ghost
          ? CustomPaint(
              painter: _DashedBoxPainter(
                  color: _isDuplicate ? tokens.softDanger : tokens.borderMedium),
              child: Center(
                child: Icon(Icons.add_rounded, size: 15, color: fg),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: going
                    ? tokens.fallbackAccent.withValues(alpha: 0.12)
                    : tokens.glassFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: glyph == null
                  ? null
                  : Center(
                      child: Icon(going ? Icons.tab_unselected : glyph,
                          size: 15, color: fg)),
            ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          box,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                decoration: going ? TextDecoration.lineThrough : null,
                decorationColor: tokens.fallbackAccent,
                color: ghost && _isDuplicate ? tokens.softDanger : fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A dashed rounded square, the tab that does not exist yet. Hand-drawn rather
/// than pulled in as a package (no dotted-border dependency for one box).
class _DashedBoxPainter extends CustomPainter {
  final Color color;
  const _DashedBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    final path = Path()..addRRect(rrect);
    const dash = 4.0;
    const gap = 3.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color;
}
