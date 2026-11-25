import 'package:flutter/material.dart';

import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/utils/notification_sound.dart';
import 'package:publicos_desktop/widgets/chat_appearance.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';

/// **DESKTOP-ONLY — the "Chat settings" dialog.**
///
/// Message options over the identity-tint bubble system: per SIDE (my
/// messages vs their messages) — text size, bubble color, text color, font
/// family (a system-font list), font weight — every control's DEFAULT state
/// means "the client's behavior" (identity tint, auto foreground, theme
/// metrics). Swatches come from the client's current `colorPresets` palette
/// (the same one the Account app's color picker uses, painted at full
/// opacity). Plus the message-chime toggle.
///
/// Entry: the "Chat settings" footer row under the conversation list (the
/// Contact-settings twin). The dialog floats over the pane and every change
/// applies instantly — `ChatAppearance` notifies, the visible chat restyles
/// live behind it.
Future<void> showChatSettingsDialog(BuildContext context) async {
  await ChatAppearance.instance.load();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => const _ChatSettingsDialog(),
  );
}

/// The system-font list: null = the theme default.
const _fontFamilies = <String?>[
  null,
  'Segoe UI',
  'Arial',
  'Georgia',
  'Times New Roman',
  'Consolas',
  'Courier New',
  'Verdana',
  'Comic Sans MS',
];

const _fontWeights = <FontWeight?>[
  null,
  FontWeight.w300,
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
  FontWeight.w700,
];

String _weightLabel(AppLocalizations l10n, FontWeight? w) {
  switch (w) {
    case FontWeight.w300:
      return l10n.desktopFontWeightLight;
    case FontWeight.w400:
      return l10n.desktopFontWeightNormal;
    case FontWeight.w500:
      return l10n.desktopFontWeightMedium;
    case FontWeight.w600:
      return l10n.desktopFontWeightSemiBold;
    case FontWeight.w700:
      return l10n.desktopFontWeightBold;
    default:
      return l10n.inboxIdDropdownDefaultLabel;
  }
}

class _ChatSettingsDialog extends StatefulWidget {
  const _ChatSettingsDialog();

  @override
  State<_ChatSettingsDialog> createState() => _ChatSettingsDialogState();
}

class _ChatSettingsDialogState extends State<_ChatSettingsDialog> {
  /// true = my messages, false = their messages.
  bool _editingOwn = true;
  bool _chimeEnabled = NotificationSound.instance.enabled;

  ChatAppearance get _ap => ChatAppearance.instance;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: DialogWidth.l,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(tokens),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _previewArea(tokens),
                      const SizedBox(height: 10),
                      _localOnlyNote(tokens),
                      const SizedBox(height: 14),
                      Divider(color: tokens.borderSubtle, height: 1),
                      const SizedBox(height: 14),
                      _chimeRow(tokens),
                      const SizedBox(height: 14),
                      Divider(color: tokens.borderSubtle, height: 1),
                      const SizedBox(height: 14),
                      _sideToggle(tokens),
                      const SizedBox(height: 16),
                      _sizeSection(tokens),
                      const SizedBox(height: 16),
                      _colorSection(
                        tokens,
                        title: context.l10n.desktopBubbleColorSection,
                        defaultLabel: context.l10n.manageServerPageIdentity,
                        note: context.l10n.desktopBubbleColorIdentityNote,
                        current: _ap.bubbleColorFor(_editingOwn),
                        onPick: (c) async {
                          await _ap.setBubbleColor(_editingOwn, c);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      _colorSection(
                        tokens,
                        title: context.l10n.editBioSheetSectionTextColor,
                        defaultLabel: context.l10n.desktopAutoLabel,
                        current: _ap.textColorFor(_editingOwn),
                        onPick: (c) async {
                          await _ap.setTextColor(_editingOwn, c);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      _fontSection(tokens),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Icon(Icons.forum_outlined, size: 18, color: tokens.connectedAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.desktopChatSettingsHeader,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: tokens.starkWhite,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, size: 18, color: tokens.textDim),
          ),
        ],
      ),
    );
  }

  /// Live preview — one incoming bubble (left) + one outgoing bubble (right),
  /// painted with the EFFECTIVE values (override ?? identity tint ?? the
  /// client's fallbacks) through the same contrast rule message_widget uses,
  /// so the preview is exactly what the chat renders.
  Widget _previewArea(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _previewBubble(
              isMe: false,
              text: context.l10n.desktopPreviewTheirMessages,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _previewBubble(
              isMe: true,
              text: context.l10n.desktopPreviewYourMessages,
            ),
          ),
        ],
      ),
    );
  }

  /// message_widget's effective-style math, mirrored: identity tint (my
  /// on-chain `color` record / the peer fallback indigo) under the overrides,
  /// auto black/white at the 0.179 luminance crossover.
  Widget _previewBubble({required bool isMe, required String text}) {
    final ap = _ap;
    final Color identity = isMe
        ? Color(int.tryParse(
                AppStateNotifier.currentMyContact?.getRecordValue('color') ??
                    '') ??
            Colors.blue.shade700.toARGB32())
        : Colors.indigo.shade700;
    final fill = ap.bubbleColorFor(isMe) ?? identity;
    final fg = ap.textColorFor(isMe) ??
        (fill.computeLuminance() < 0.179 ? Colors.white : Colors.black);

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: ap.textSizeFor(isMe) ?? 16,
          fontFamily: ap.fontFamilyFor(isMe),
          fontWeight: ap.fontWeightFor(isMe),
        ),
      ),
    );
  }

  Widget _localOnlyNote(GlassTokens tokens) {
    return Row(
      children: [
        Icon(Icons.visibility_outlined, size: 14, color: tokens.fallbackAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.desktopChatAppearanceLocalNote,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              color: tokens.textDim,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chimeRow(GlassTokens tokens) {
    return Row(
      children: [
        Icon(Icons.notifications_active_outlined,
            size: 16, color: tokens.textDim),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.desktopMessageChimeTitle,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: tokens.starkWhite,
                ),
              ),
              Text(
                context.l10n.desktopMessageChimeSubtitle,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  color: tokens.textDim,
                ),
              ),
            ],
          ),
        ),
        // Preview the synthesized bell.
        IconButton(
          onPressed: () => NotificationSound.instance.playForced(),
          icon: Icon(Icons.play_circle_outline,
              size: 18, color: tokens.textDim),
          tooltip: context.l10n.feedsSettingsSheetPreview,
        ),
        Switch(
          value: _chimeEnabled,
          activeThumbColor: tokens.connectedAccent,
          onChanged: (v) async {
            await NotificationSound.instance.setEnabled(v);
            setState(() => _chimeEnabled = v);
          },
        ),
      ],
    );
  }

  Widget _sideToggle(GlassTokens tokens) {
    Widget chip(String label, bool own) {
      final active = _editingOwn == own;
      return Expanded(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => setState(() => _editingOwn = own),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? tokens.glassFill : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active
                      ? tokens.connectedAccent.withValues(alpha: 0.45)
                      : tokens.borderSubtle,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? tokens.starkWhite : tokens.textDim,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(context.l10n.desktopChipMyMessages, true),
        const SizedBox(width: 8),
        chip(context.l10n.desktopChipTheirMessages, false),
      ],
    );
  }

  Widget _label(GlassTokens tokens, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: tokens.textDim,
      ),
    );
  }

  Widget _sizeSection(GlassTokens tokens) {
    final current = _ap.textSizeFor(_editingOwn);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label(tokens, context.l10n.gridSettingsSheetSectionTextSize),
            const Spacer(),
            Text(
              current == null ? context.l10n.inboxIdDropdownDefaultLabel : current.round().toString(),
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: tokens.textDim,
              ),
            ),
            if (current != null)
              _clearChip(tokens, () async {
                await _ap.setTextSize(_editingOwn, null);
                setState(() {});
              }),
          ],
        ),
        Slider(
          value: (current ?? 16).clamp(11, 24),
          min: 11,
          max: 24,
          divisions: 13,
          activeColor: tokens.connectedAccent,
          onChanged: (v) async {
            await _ap.setTextSize(_editingOwn, v.roundToDouble());
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _clearChip(GlassTokens tokens, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Icon(Icons.replay_rounded, size: 14, color: tokens.textDim),
        ),
      ),
    );
  }

  Widget _colorSection(
    GlassTokens tokens, {
    required String title,
    required String defaultLabel,
    required Color? current,
    required Future<void> Function(Color?) onPick,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(tokens, title),
        // What the default chip means (bubble color: the Color record).
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              color: tokens.textDim,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // The default chip — clears the override back to client behavior.
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onPick(null),
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: current == null
                          ? tokens.connectedAccent
                          : tokens.borderMedium,
                      width: current == null ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    defaultLabel,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: current == null
                          ? tokens.connectedAccent
                          : tokens.textDim,
                    ),
                  ),
                ),
              ),
            ),
            for (final c in PhigitalStyle.colorPresets)
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onPick(c),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: current == c
                            ? tokens.starkWhite
                            : tokens.borderSubtle,
                        width: current == c ? 2 : 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _fontSection(GlassTokens tokens) {
    final family = _ap.fontFamilyFor(_editingOwn);
    final weight = _ap.fontWeightFor(_editingOwn);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(tokens, context.l10n.desktopFontSection),
              const SizedBox(height: 6),
              _dropdown<String?>(
                tokens,
                value: family,
                items: _fontFamilies,
                labelOf: (f) => f ?? context.l10n.inboxIdDropdownDefaultLabel,
                styleOf: (f) => TextStyle(fontFamily: f),
                onChanged: (f) async {
                  await _ap.setFontFamily(_editingOwn, f);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(tokens, context.l10n.desktopWeightSection),
              const SizedBox(height: 6),
              _dropdown<FontWeight?>(
                tokens,
                value: weight,
                items: _fontWeights,
                labelOf: (w) => _weightLabel(context.l10n, w),
                styleOf: (w) => TextStyle(fontWeight: w),
                onChanged: (w) async {
                  await _ap.setFontWeight(_editingOwn, w);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>(
    GlassTokens tokens, {
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required TextStyle Function(T) styleOf,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: tokens.surfaceElevated,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.starkWhite,
          ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: Text(
                  labelOf(item),
                  style: styleOf(item).copyWith(fontSize: 12),
                ),
              ),
          ],
          onChanged: (v) => onChanged(v as T),
        ),
      ),
    );
  }
}
