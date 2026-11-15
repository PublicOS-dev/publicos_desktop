import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/expiration_picker_field.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Owner-only bottom sheet for managing per-post interaction rules.
///
/// Wires `/api/:address/channels/:slug/posts/:postUid/interaction-rules` via
/// `PublicOSChannels.listPostInteractionRules` / `addPostInteractionRule` /
/// `removePostInteractionRule`. Allow/Deny rules apply to BOTH comments AND
/// reactions on the post unconditionally — owner uses the post's per-type
/// policy enums (`commentPolicy` / `reactionPolicy`) for asymmetric access.
/// The caller resolves `slug` + `serverAddress` from the owning channel
/// before opening the sheet.
Future<void> showCommentRulesSheet(
  BuildContext context, {
  required Post post,
  required String slug,
  String? serverAddress,
}) {
  // DESKTOP DELTA: re-shelled from the client's bottom sheet to a centered
  // glass dialog (same pattern as the list sheets).
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m, maxHeight: 640),
        child: _CommentRulesSheet(
          post: post,
          slug: slug,
          serverAddress: serverAddress,
        ),
      ),
    ),
  );
}

class _CommentRulesSheet extends StatefulWidget {
  final Post post;
  final String slug;
  final String? serverAddress;
  const _CommentRulesSheet({
    required this.post,
    required this.slug,
    required this.serverAddress,
  });

  @override
  State<_CommentRulesSheet> createState() => _CommentRulesSheetState();
}

class _CommentRulesSheetState extends State<_CommentRulesSheet> {
  final TextEditingController _addrCtrl = TextEditingController();
  PostInteractionRuleType _newRuleType = PostInteractionRuleType.allow;
  DateTime? _newExpiresAt;

  List<PostInteractionRule> _rules = const [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _inlineError;

  bool get _canAdd {
    final v = _addrCtrl.text.trim();
    return !_isSubmitting && v.startsWith('0x') && v.length >= 10;
  }

  @override
  void initState() {
    super.initState();
    _addrCtrl.addListener(() => setState(() {}));
    // First load reads context.l10n, which is not allowed inside initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _inlineError = message);
  }

  String? _errorMessage(FeedServerApiResponse<dynamic> resp) {
    final err = resp.error;
    if (err == null) return null;
    return err['message'] as String? ?? err['code'] as String?;
  }

  Future<void> _load() async {
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    final resp = await PublicOSChannels.listPostInteractionRules(
      slug: widget.slug,
      postUid: widget.post.uid,
      serverAddress: widget.serverAddress,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (resp.success && resp.data != null) {
        _rules = resp.data!;
      } else {
        _showError(_errorMessage(resp) ?? l10n.commentRulesSheetLoadFailed);
      }
    });
  }

  Future<void> _add() async {
    if (!_canAdd) return;
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);
    final resp = await PublicOSChannels.addPostInteractionRule(
      slug: widget.slug,
      postUid: widget.post.uid,
      address: _addrCtrl.text.trim(),
      type: _newRuleType,
      expiresAt: _newExpiresAt?.toUtc().toIso8601String(),
      serverAddress: widget.serverAddress,
    );
    if (!mounted) return;
    if (resp.success && resp.data != null) {
      setState(() {
        _rules = [..._rules, resp.data!];
        _addrCtrl.clear();
        _newExpiresAt = null;
        _isSubmitting = false;
        _inlineError = null;
      });
    } else {
      setState(() => _isSubmitting = false);
      _showError(_errorMessage(resp) ?? l10n.commentRulesSheetAddFailed);
    }
  }

  Future<void> _remove(PostInteractionRule rule) async {
    final l10n = context.l10n;
    final resp = await PublicOSChannels.removePostInteractionRule(
      slug: widget.slug,
      postUid: widget.post.uid,
      address: rule.address,
      type: rule.type,
      serverAddress: widget.serverAddress,
    );
    if (!mounted) return;
    if (resp.success) {
      setState(() {
        _rules = _rules
            .where((r) => !(r.address.toLowerCase() == rule.address.toLowerCase() &&
                r.type == rule.type))
            .toList();
      });
    } else {
      _showError(_errorMessage(resp) ?? l10n.commentRulesSheetRemoveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // DESKTOP DELTA: fixed dialog card — no keyboard inset, no draggable
    // sheet, no drag handle (nothing to drag), all corners rounded. The rules
    // ListView owns its own controller since there is no sheet controller to
    // borrow (same shape as the manage-lists dialog).
    return Container(
            decoration: BoxDecoration(
              color: tokens.surfaceDeep,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderSubtle, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const _Header(),
                _AddBar(
                  controller: _addrCtrl,
                  type: _newRuleType,
                  canAdd: _canAdd,
                  isSubmitting: _isSubmitting,
                  onTypeChanged: (t) => setState(() => _newRuleType = t),
                  expiresAt: _newExpiresAt,
                  onExpiresChanged: (v) =>
                      setState(() => _newExpiresAt = v),
                  onSubmit: _add,
                ),
                if (_inlineError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.10),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.4),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _inlineError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ),
                          InkResponse(
                            onTap: () =>
                                setState(() => _inlineError = null),
                            radius: 16,
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: tokens.borderSubtle, height: 1),
                ),
                Expanded(
                  child: _isLoading && _rules.isEmpty
                      ? Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(tokens.textDim),
                            ),
                          ),
                        )
                      : _rules.isEmpty
                          ? _Empty(tokens: tokens)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              itemCount: _rules.length,
                              itemBuilder: (context, index) {
                                final rule = _rules[index];
                                return _RuleRow(
                                  rule: rule,
                                  onRemove: () => _remove(rule),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
  }
}

// DESKTOP DELTA: the client's `_Handle` drag pill is gone — a dialog has
// nothing to drag.

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.commentRulesSheetTitle,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.commentRulesSheetDescription,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.45,
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
    );
  }
}

class _Empty extends StatelessWidget {
  final GlassTokens tokens;
  const _Empty({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gavel_rounded,
            size: 48,
            color: tokens.textDim,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.commentRulesSheetEmptyTitle,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              context.l10n.commentRulesSheetEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textDim, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  final TextEditingController controller;
  final PostInteractionRuleType type;
  final bool canAdd;
  final bool isSubmitting;
  final ValueChanged<PostInteractionRuleType> onTypeChanged;
  final DateTime? expiresAt;
  final ValueChanged<DateTime?> onExpiresChanged;
  final VoidCallback onSubmit;

  const _AddBar({
    required this.controller,
    required this.type,
    required this.canAdd,
    required this.isSubmitting,
    required this.onTypeChanged,
    required this.expiresAt,
    required this.onExpiresChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeSwitch(value: type, onChanged: onTypeChanged),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !isSubmitting,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onSubmit(),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9x]'),
                    ),
                  ],
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: '0x…',
                    hintStyle: TextStyle(
                      color: tokens.textDim,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: tokens.surfaceElevated,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: tokens.borderSubtle, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: tokens.borderSubtle, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: tokens.borderMedium, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AddButton(
                enabled: canAdd,
                isSubmitting: isSubmitting,
                onPressed: onSubmit,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ExpirationPickerField(
            value: expiresAt,
            onChanged: onExpiresChanged,
            label: type == PostInteractionRuleType.deny
                ? context.l10n.commentRulesSheetDenyUntil
                : context.l10n.commentRulesSheetAllowUntil,
            emptyText: type == PostInteractionRuleType.deny
                ? context.l10n.commentRulesSheetDenyForever
                : context.l10n.commentRulesSheetAllowForever,
          ),
        ],
      ),
    );
  }
}

class _TypeSwitch extends StatelessWidget {
  final PostInteractionRuleType value;
  final ValueChanged<PostInteractionRuleType> onChanged;

  const _TypeSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _SwitchSide(
            label: context.l10n.commentRulesSheetAllow,
            icon: Icons.check_circle_outline_rounded,
            selected: value == PostInteractionRuleType.allow,
            onTap: () => onChanged(PostInteractionRuleType.allow),
          ),
          _SwitchSide(
            label: context.l10n.commentRulesSheetDeny,
            icon: Icons.block_rounded,
            selected: value == PostInteractionRuleType.deny,
            onTap: () => onChanged(PostInteractionRuleType.deny),
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _SwitchSide extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool destructive;
  final VoidCallback onTap;

  const _SwitchSide({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = !selected
        ? tokens.textDim
        : (destructive
            ? Theme.of(context).colorScheme.error
            : tokens.starkWhite);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? (destructive
                    ? Theme.of(context).colorScheme.error.withValues(alpha: 0.10)
                    : tokens.glassFillHover)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _AddButton({
    required this.enabled,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: enabled ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: enabled ? tokens.borderMedium : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: isSubmitting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(tokens.textDim),
                  ),
                )
              : Text(
                  context.l10n.commentRulesSheetAddButton,
                  style: TextStyle(
                    color: enabled ? tokens.starkWhite : tokens.textDim,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final PostInteractionRule rule;
  final VoidCallback onRemove;

  const _RuleRow({required this.rule, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isDeny = rule.type == PostInteractionRuleType.deny;
    final addr = rule.address;
    final shortAddr = addr.length >= 10
        ? '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}'
        : addr;
    final expiresAtDate = rule.expiresAt != null
        ? DateTime.tryParse(rule.expiresAt!)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GlassContactIcon(address: addr, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shortAddr,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _formatRelative(context, rule.createdAt),
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11,
                      ),
                    ),
                    if (expiresAtDate != null) ...[
                      const SizedBox(width: 6),
                      ExpirationChip(value: expiresAtDate),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _RuleChip(isDeny: isDeny),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: tokens.textDim,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  String _formatRelative(BuildContext context, DateTime t) {
    final l10n = context.l10n;
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return l10n.commentRulesSheetJustNow;
    if (d.inHours < 1) return l10n.commentRulesSheetMinutesAgo(d.inMinutes);
    if (d.inDays < 1) return l10n.commentRulesSheetHoursAgo(d.inHours);
    return l10n.commentRulesSheetDaysAgo(d.inDays);
  }
}

class _RuleChip extends StatelessWidget {
  final bool isDeny;
  const _RuleChip({required this.isDeny});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = isDeny
        ? Theme.of(context).colorScheme.error
        : tokens.starkWhite;
    final bg = isDeny
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.10)
        : tokens.glassFill;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isDeny
            ? context.l10n.commentRulesSheetChipDeny
            : context.l10n.commentRulesSheetChipAllow,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
