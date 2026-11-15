import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Glass-dark sheet to delegate the caller's ballot to another member
/// (default lane). Delegation is snapshot-scoped — it takes effect for
/// proposals created AFTER it lands, never rewrites an in-flight vote. The
/// delegatee must be a current member; each `(org, tag)` delegation consumes
/// one of the per-user cap slots.
///
/// Pops `true` if a delegation change landed, `false` / `null` otherwise.
Future<bool?> showDelegateVoteSheet(
  BuildContext context, {
  required String orgAddress,
  required String myAddress,
  required String? currentDelegatee,
  required List<Contact> members,
}) {
  return showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _DelegateVoteSheet(
      orgAddress: orgAddress,
      myAddress: myAddress,
      currentDelegatee: currentDelegatee,
      members: members,
    ),
  );
}

class _DelegateVoteSheet extends StatefulWidget {
  final String orgAddress;
  final String myAddress;
  final String? currentDelegatee;
  final List<Contact> members;

  const _DelegateVoteSheet({
    required this.orgAddress,
    required this.myAddress,
    required this.currentDelegatee,
    required this.members,
  });

  @override
  State<_DelegateVoteSheet> createState() => _DelegateVoteSheetState();
}

class _DelegateVoteSheetState extends State<_DelegateVoteSheet> {
  bool _isSubmitting = false;
  String? _errorText;

  // Delegation-cap usage (used / cap). Null while loading or on read failure.
  ({int used, int cap})? _usage;

  /// The pending selection: null = vote myself (clear), else a member address.
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentDelegatee;
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final usage = await PublicOSGovernance.getDelegationUsage(
        widget.orgAddress, widget.myAddress);
    if (mounted) setState(() => _usage = usage);
  }

  bool get _isDirty {
    final a = _selected?.toLowerCase();
    final b = widget.currentDelegatee?.toLowerCase();
    return a != b;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();
    try {
      final success = await PublicOSGovernance.delegateVote(
        widget.orgAddress,
        delegateeAddress: _selected, // null = clear back to self
      );
      if (!mounted) return;
      if (success) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorText = l10n.delegateVoteSheetErrorFailed;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = localizedError(l10n, e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _Header(
              tokens: tokens,
              title: l10n.delegateVoteSheetTitle,
              onClose: () => Navigator.pop(context, false),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _InfoPill(tokens: tokens, text: l10n.delegateVoteSheetBlurb),
                  if (_usage != null && _usage!.used > 0) ...[
                    const SizedBox(height: 10),
                    _CapPill(
                      tokens: tokens,
                      text: l10n.delegateVoteSheetCap(_usage!.used, _usage!.cap),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // "Vote myself" (clear delegation) option.
                  _SelectRow(
                    tokens: tokens,
                    leading: Icon(Icons.person_outline_rounded,
                        color: tokens.starkWhite, size: 22),
                    title: l10n.delegateVoteSheetVoteMyself,
                    subtitle: l10n.delegateVoteSheetVoteMyselfSubtitle,
                    selected: _selected == null,
                    onTap: _isSubmitting
                        ? null
                        : () => setState(() {
                              _selected = null;
                              _errorText = null;
                            }),
                  ),
                  const SizedBox(height: 14),
                  _SectionLabel(
                    tokens: tokens,
                    text: l10n.delegateVoteSheetDelegateTo,
                  ),
                  const SizedBox(height: 6),
                  if (widget.members.isEmpty)
                    _InfoPill(
                        tokens: tokens,
                        text: l10n.delegateVoteSheetNoMembers)
                  else
                    for (final m in widget.members)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SelectRow(
                          tokens: tokens,
                          leading: GlassContactIcon(contact: m, size: 32),
                          title: m.displayName,
                          subtitle: _short(m.publicosAddress?.eip55With0x ?? ''),
                          selected: _selected?.toLowerCase() ==
                              m.publicosAddress?.eip55With0x.toLowerCase(),
                          onTap: _isSubmitting
                              ? null
                              : () => setState(() {
                                    _selected = m.publicosAddress?.eip55With0x;
                                    _errorText = null;
                                  }),
                        ),
                      ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    _ErrorPill(
                      tokens: tokens,
                      message: _errorText!,
                      onDismiss: () => setState(() => _errorText = null),
                    ),
                  ],
                ],
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
                child: _isSubmitting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child:
                              PhigitalLoadingWidget(size: 28, showShadows: false),
                        ),
                      )
                    : SystemAppActionButton(
                        label: _selected == null
                            ? l10n.delegateVoteSheetConfirmClear
                            : l10n.delegateVoteSheetConfirm,
                        icon: Icons.how_to_reg_rounded,
                        onTap: _isDirty ? _submit : null,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _short(String addr) => addr.length > 10
      ? '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}'
      : addr;
}

class _SelectRow extends StatelessWidget {
  final GlassTokens tokens;
  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _SelectRow({
    required this.tokens,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected
              ? tokens.connectedAccent.withValues(alpha: 0.10)
              : tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? tokens.connectedAccent : tokens.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? tokens.connectedAccent : tokens.starkWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: tokens.textDim,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, color: tokens.connectedAccent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final GlassTokens tokens;
  final String text;
  const _SectionLabel({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: tokens.textDim,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final GlassTokens tokens;
  final String text;
  const _InfoPill({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: tokens.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.textDim,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CapPill extends StatelessWidget {
  final GlassTokens tokens;
  final String text;
  const _CapPill({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.fallbackAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.fallbackAccent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.layers_outlined, size: 14, color: tokens.fallbackAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                color: tokens.starkWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final GlassTokens tokens;
  final String message;
  final VoidCallback onDismiss;

  const _ErrorPill({
    required this.tokens,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: errorColor.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: errorColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, color: errorColor, size: 14),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final VoidCallback onClose;

  const _Header({
    required this.tokens,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(
              Icons.how_to_reg_rounded,
              color: tokens.connectedAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
