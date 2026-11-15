import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/mention_autocomplete.dart';
import 'package:zero_mentions/zero_mentions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/profile/bio_display_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Glass-dark, draggable-with-pinned-action bottom sheet for editing the bio
/// profile record. Outer structure follows Pattern A (a draggable sheet with
/// a pinned footer).
Future<void> showEditBioSheet(
  BuildContext context, {
  Record? record,
  required Function(Record) onSave,
}) {
  // DELTA (desktop): sheet -> centered glass dialog.
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => EditBioSheet(record: record, onSave: onSave),
  );
}

class EditBioSheet extends StatefulWidget {
  final Record? record;
  final Function(Record) onSave;

  const EditBioSheet({super.key, this.record, required this.onSave});

  @override
  State<EditBioSheet> createState() => _EditBioSheetState();
}

class _EditBioSheetState extends State<EditBioSheet> {
  late MentionTextEditingController _bioController;
  final FocusNode _bioFocus = FocusNode();
  late int _selectedTextColor;
  late bool _borderVisible;
  late int _selectedBorderColor;
  late double _borderWidth;
  late double _borderRadius;

  final List<Color> _predefinedBorderColors = [
    Colors.transparent,
    Colors.black,
    Colors.white,
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.yellowAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.grey,
    Colors.blueGrey,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    // Mentions: the record keeps `@[0xAddr]` tokens, the field shows names.
    _bioController = mentionRecordController(widget.record?.value ?? '');
    _selectedTextColor = widget.record?.metadata['bioTextColor'] as int? ?? Colors.white.value;
    _borderVisible = widget.record?.metadata['bioBorderVisible'] as bool? ?? false;
    _selectedBorderColor = widget.record?.metadata['bioBorderColor'] as int? ?? Colors.grey.value;
    _borderWidth = (widget.record?.metadata['bioBorderWidth'] as num?)?.toDouble() ?? 1.0;
    _borderRadius = (widget.record?.metadata['borderRadius'] as num?)?.toDouble() ?? 8.0;

  }

  @override
  void dispose() {
    _bioController.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Record _buildPreviewRecord() {
    return Record.asProfile(
      key: widget.record?.key ?? 'profile.bio',
      value: _bioController.serialize(),
      expiration: DateTime.now().add(const Duration(days: 365)),
      icon: Icons.person_rounded.codePoint,
      customMetadataAttributes: {
        'bioTextColor': _selectedTextColor,
        'bioBorderVisible': _borderVisible,
        'bioBorderColor': _selectedBorderColor,
        'bioBorderWidth': _borderWidth,
        'borderRadius': _borderRadius,
      },
    );
  }

  void _handleSave() {
    final newRecord = Record.asProfile(
      key: widget.record?.key ?? 'profile.bio',
      value: _bioController.serialize(),
      expiration: DateTime.now().add(const Duration(days: 365)),
      customMetadataAttributes: {
        'bioTextColor': _selectedTextColor,
        'bioBorderVisible': _borderVisible,
        'bioBorderColor': _selectedBorderColor,
        'bioBorderWidth': _borderWidth,
        'borderRadius': _borderRadius,
      },
      icon: Icons.person_rounded.codePoint,
    );
    widget.onSave(newRecord);
  }

  Widget _buildColorSelector(int selectedColorValue, ValueChanged<int> onSelected, List<Color> colorOptions) {
    final tokens = GlassTokens.of(context);
    return HorizontalWheel(child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: colorOptions.map((color) {
          final bool isSelected = color.value == selectedColorValue;
          final bool isActuallyTransparent = color == Colors.transparent;
          final Color displayColor = isActuallyTransparent ? tokens.glassFill : color;
          final bool isDark = displayColor.computeLuminance() < 0.5;

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onSelected(color.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: tokens.connectedAccent, width: 3)
                    : Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: isActuallyTransparent
                  ? Icon(Icons.format_color_reset, color: tokens.textDim, size: 20)
                  : (isSelected ? Icon(Icons.check_rounded, color: isDark ? Colors.white : Colors.black, size: 20) : null),
            ),
          );
        }).toList(),
      ),
    ));
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tokens.connectedAccent),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: tokens.starkWhite,
            ),
          ),
        ],
      ),
    );
  }

  // Only the (commented-out) border width / corner radius sliders used this.
  // ignore: unused_element
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final tokens = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: tokens.starkWhite, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(color: tokens.starkWhite, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: tokens.connectedAccent,
            thumbColor: tokens.connectedAccent,
            overlayColor: tokens.connectedAccent.withValues(alpha: 0.2),
            inactiveTrackColor: tokens.borderSubtle,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // Pattern A load-bearing wrap: a DraggableScrollableSheet sizes against the
    // full screen and ignores the keyboard on its own, so the IME paints over
    // the pinned SAVE BIO footer. This Padding shrinks the sheet to the space
    // above the keyboard, keeping the footer reachable.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
      // DELTA (desktop): the client anchors this sheet to the bottom of the
      // screen and lets the user drag it up and down. Inside a centered glass
      // dialog there is no screen edge to drag against, so the sheet fills its
      // dialog exactly. Sizing is the only structural change to this body.
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) {
        // iOS: the bio field is multiline, so the return key inserts a newline
        // instead of submitting — and the keyboard overlays the pinned SAVE BIO
        // button. Tapping any empty area of the sheet drops focus so the button
        // becomes reachable. (Drag-to-dismiss is wired on the scroll view below.)
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              _Header(
                tokens: tokens,
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The editor IS the bio card — you type directly into
                      // what renders on the profile, styled live by the
                      // controls below. No separate preview to keep in sync.
                      BioDisplayWidget(
                        record: _buildPreviewRecord(),
                        controller: _bioController,
                        focusNode: _bioFocus,
                        hintText: context.l10n.editBioSheetHint,
                        maxLength: 400,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(400),
                          // Collapse any run of 2+ newlines to a single break so
                          // consecutive blank returns can't pile up.
                          FilteringTextInputFormatter.deny(
                            RegExp(r'\n{2,}'),
                            replacementString: '\n',
                          ),
                        ],
                      ),
                      MentionAutocomplete(controller: _bioController, focusNode: _bioFocus),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _bioController,
                          builder: (context, value, _) => Text(
                            context.l10n.editBioSheetCharCount(value.text.characters.length, 400),
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      _buildSectionHeader(context.l10n.editBioSheetSectionTextColor, Icons.format_color_text_rounded),
                      _buildColorSelector(
                        _selectedTextColor,
                        (colorValue) => setState(() => _selectedTextColor = colorValue),
                        _predefinedBorderColors.where((c) => c != Colors.transparent).toList(),
                      ),
                      // No border options: the bio renders as plain
                      // text so it shares the avatar's left edge; only the text
                      // colour is honoured at render. The border state above is
                      // still read + written back, so existing records keep their
                      // values untouched.
                      // _buildSectionHeader(context.l10n.editBioSheetSectionBorder, Icons.border_style_rounded),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     color: tokens.glassFill,
                      //     borderRadius: BorderRadius.circular(12),
                      //     border: Border.all(color: tokens.borderSubtle),
                      //   ),
                      //   child: SwitchListTile(
                      //     title: Text(context.l10n.editBioSheetShowBorder, style: TextStyle(color: tokens.starkWhite, fontSize: 14)),
                      //     value: _borderVisible,
                      //     activeColor: tokens.connectedAccent,
                      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //     onChanged: (value) => setState(() => _borderVisible = value),
                      //   ),
                      // ),
                      // if (_borderVisible) ...[
                      //   const SizedBox(height: 16),
                      //   Text(context.l10n.editBioSheetBorderColor, style: TextStyle(color: tokens.starkWhite, fontSize: 14, fontWeight: FontWeight.w500)),
                      //   const SizedBox(height: 8),
                      //   _buildColorSelector(
                      //     _selectedBorderColor,
                      //     (colorValue) => setState(() => _selectedBorderColor = colorValue),
                      //     _predefinedBorderColors,
                      //   ),
                      //   const SizedBox(height: 16),
                      //   _buildSlider(
                      //     label: context.l10n.editBioSheetBorderWidth,
                      //     value: _borderWidth,
                      //     min: 0.5,
                      //     max: 5.0,
                      //     divisions: 9,
                      //     onChanged: (value) => setState(() => _borderWidth = value),
                      //   ),
                      //   const SizedBox(height: 8),
                      //   _buildSlider(
                      //     label: context.l10n.editBioSheetCornerRadius,
                      //     value: _borderRadius,
                      //     min: 0.0,
                      //     max: 30.0,
                      //     divisions: 30,
                      //     onChanged: (value) => setState(() => _borderRadius = value),
                      //   ),
                      // ],
                    ],
                  ),
                  ),
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
                  child: SystemAppActionButton(
                    label: context.l10n.editBioSheetSave,
                    icon: Icons.check_rounded,
                    onTap: _handleSave,
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final VoidCallback onClose;

  const _Header({required this.tokens, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final accent = tokens.connectedAccent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: tokens.glassFill,
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.edit_note_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.editBioSheetTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: tokens.starkWhite,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.editBioSheetClose,
            icon: Icon(Icons.close_rounded, color: tokens.textDim, size: 20),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
