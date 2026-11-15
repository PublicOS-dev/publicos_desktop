import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/feeds/mention_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders a bio record as its styled card. The same widget powers the
/// read-only profile bio AND the editor: pass a [controller] and it becomes a
/// WYSIWYG text field inside the very card it would render — so what you type
/// is exactly what shows on the profile, no separate preview needed.
class BioDisplayWidget extends StatelessWidget {
  final Record? record;

  /// When non-null the card is editable: a [TextField] bound to this controller
  /// replaces the static text, styled identically. When null the card is a
  /// read-only [Text].
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  /// The bio card never grows past this; longer text scrolls inside. Keeps a
  /// many-line bio from pushing surrounding layout (e.g. the edit sheet's
  /// pinned Save button) off-screen — caps the *max* only, so short bios stay
  /// compact.
  static const double _maxHeight = 280;

  const BioDisplayWidget({
    Key? key,
    this.record,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.hintText,
    this.inputFormatters,
    this.maxLength,
  }) : super(key: key);

  bool get _isEditable => controller != null;

  @override
  Widget build(BuildContext context) {
    final String bioText = (record?.value.isNotEmpty ?? false) ? record!.value : '';

    // Only the text colour is honoured. The bio is plain text on the profile's
    // one gutter, so it shares its left edge with the avatar, social strip and
    // cards; records may still carry border keys (visibility / colour / width
    // / corner radius), which are simply ignored.
    // `bioTextColor` returns Colors.transparent (NOT null) when a text record
    // carries no valid `bioTextColor` metadata -- e.g. a bio written by a tool
    // or an older client that omitted styling. Transparent text renders
    // invisible, which reads to the user as "the bio won't display" even though
    // the record is fine. Treat unset/transparent as the default white so a
    // valid bio is never drawn invisible.
    final Color rawTextColor = record?.bioTextColor ?? Colors.white;
    final Color textColor = rawTextColor.a == 0 ? Colors.white : rawTextColor;
    // final bool borderIsVisible = record?.bioBorderIsVisible ?? false;
    // final Color borderColor = record?.bioBorderColor ?? Colors.grey.shade300;
    // final double borderWidth = record?.bioBorderWidth ?? 1.0;
    // final double radius = record?.borderRadius ?? 8.0;

    // Get alignment from record metadata (default to left for cleaner look)
    final String alignmentStr = record?.metadata['alignment'] as String? ?? 'left';
    final TextAlign textAlign = alignmentStr == 'center'
        ? TextAlign.center
        : alignmentStr == 'right'
            ? TextAlign.right
            : TextAlign.left;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 14,
      height: 1.5,
    );

    final Widget content = _isEditable
        // maxLines:null lets the field grow with content; the ConstrainedBox
        // below caps it at _maxHeight and the field scrolls internally past
        // that. The maxLength counter is suppressed (counterText:'') so it
        // doesn't break the card look — the sheet shows a count below instead.
        ? TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            maxLines: null,
            textAlign: textAlign,
            cursorColor: textColor,
            style: textStyle,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              counterText: '',
              hintText: hintText,
              hintStyle: textStyle.copyWith(
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          )
        // Mentions: `@[0xAddr]` tokens render as tappable names.
        : MentionText(
            bioText,
            style: textStyle,
            textAlign: textAlign,
          );

    // No box: no fill, border, radius or inner padding — the host's gutter owns
    // the left edge, so the first glyph lines up with the avatar.
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: _maxHeight),
        // The editable TextField scrolls itself when it overflows; the
        // read-only Text needs an explicit scroll view.
        child: _isEditable ? content : SingleChildScrollView(child: content),
      ),
    );
  }
}
