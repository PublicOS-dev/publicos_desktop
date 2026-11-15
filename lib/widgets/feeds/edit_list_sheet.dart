import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Bottom sheet for creating or editing a feed list's metadata
/// (name + icon).
///
/// `existing == null` → create mode (random emoji default, "Create list").
/// `existing != null` → edit mode (pre-fills name + icon, "Save").
/// Returns the saved [FeedList] on success, null on cancel.
///
/// Calls Core directly via `PublicOSFeedLists.createList` /
/// `PublicOSFeedLists.updateList` (no repo layer).
Future<FeedList?> showEditListSheet(
  BuildContext context, {
  FeedList? existing,
  String? defaultName,
}) {
  // DESKTOP DELTA: re-shelled from the client's bottom sheet to a glass dialog.
  return showDialog<FeedList?>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m),
        child:
            _EditListSheet(existing: existing, defaultName: defaultName),
      ),
    ),
  );
}

class _EditListSheet extends StatefulWidget {
  final FeedList? existing;
  final String? defaultName;
  const _EditListSheet({this.existing, this.defaultName});

  @override
  State<_EditListSheet> createState() => _EditListSheetState();
}

class _EditListSheetState extends State<_EditListSheet> {
  static const _defaultEmojis = [
    '⭐', '🛠', '📚', '🌌', '🔭', '🌱', '🧪', '🧠', '🛰', '📰',
    '🪐', '🔥', '💡', '🗺', '🎙', '🎲', '🎨', '🧩', '🛤', '⚙️',
  ];

  late final TextEditingController _nameCtrl;
  late String _icon;
  bool _isSaving = false;
  String? _errorText;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final initialName =
        widget.existing?.name ?? widget.defaultName ?? '';
    _nameCtrl = TextEditingController(text: initialName);
    _icon = widget.existing?.icon ??
        _defaultEmojis[math.Random().nextInt(_defaultEmojis.length)];
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && !_isSaving;

  Future<void> _pickIcon() async {
    final picked = await showEmojiPickerDialog(
      context,
      currentEmoji: _icon,
    );
    if (picked != null && mounted) setState(() => _icon = picked);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    final FeedList? result = _isEdit
        ? await PublicOSFeedLists.updateList(
            widget.existing!.id,
            name: name,
            icon: _icon,
          )
        : await PublicOSFeedLists.createList(name, icon: _icon);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _isSaving = false;
        _errorText = _isEdit
            ? l10n.editListSheetFailedUpdate
            : l10n.editListSheetFailedCreate;
      });
      return;
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          // DESKTOP DELTA: all corners rounded, no drag handle — it floats as a
          // dialog rather than anchoring to the bottom edge.
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
                  children: [
                    Text(
                      _isEdit
                          ? context.l10n.editListSheetTitleEdit
                          : context.l10n.editListSheetTitleNew,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: tokens.starkWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconChip(emoji: _icon, onTap: _pickIcon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: tokens.starkWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.editListSheetNameHint,
                          hintStyle: TextStyle(
                            color: tokens.textDim,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  context.l10n.editListSheetIconHint,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _SaveButton(
                  enabled: _canSave,
                  isEdit: _isEdit,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final String emoji;
  final VoidCallback onTap;

  const _IconChip({required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border.all(color: tokens.borderMedium, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 30)),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool enabled;
  final bool isEdit;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.enabled,
    required this.isEdit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: enabled ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled ? tokens.borderMedium : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              isEdit
                  ? context.l10n.editListSheetSave
                  : context.l10n.editListSheetCreate,
              style: TextStyle(
                color: enabled ? tokens.starkWhite : tokens.textDim,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
