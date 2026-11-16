import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import '../theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
// The width presets are the feeds pane's desktop-only reading-width set,
// reused verbatim so both panes speak the same named sizes (single source,
// no drift). Only the default differs — see [kContactsProfileWidthDefault].
import 'feeds/feeds_settings_sheet.dart'
    show
        kReadingWidthPresets,
        kReadingWidthKey,
        kReadingWidthDefault,
        encodeReadingWidth,
        parseReadingWidth;

/// DESKTOP-ONLY — max width of the Contacts right-hand profile pane.
///
/// Same reasoning as the feeds reading width (the first desktop-only feature):
/// on a phone the profile IS the screen, but on a maximized desktop window an
/// unconstrained profile blows the banner, avatar and record grid up to sizes
/// nothing was designed for. The cap belongs to the user, not to a constant.
///
/// Persisted through PublicOSSettings like every reading setting, so it
/// round-trips across restarts and follows the account.
const String kContactsProfileWidthKey = 'contacts_profile_max_width';

/// Default = Magazine (740, a [kReadingWidthPresets] entry): the profile is
/// designed around the client's ~440 column, and an unconstrained desktop
/// pane blows the banner / avatar / record grid up to sizes nothing was drawn
/// for. Full stays available as an explicit preset choice.
const double kContactsProfileWidthDefault = 740;

/// Parse the persisted width. Defensive like `parseReadingWidth`, but with the
/// contacts default: anything unknown or corrupted collapses to the default. Only
/// widths the chips actually offer are accepted, so a stale/hand-edited
/// setting can't strand the user at a width with no chip.
double parseContactsProfileWidth(String? raw) {
  if (raw == null) return kContactsProfileWidthDefault;
  if (raw == 'full') return double.infinity;
  final parsed = double.tryParse(raw);
  if (parsed == null) return kContactsProfileWidthDefault;
  for (final p in kReadingWidthPresets) {
    if (p.width == parsed) return parsed;
  }
  return kContactsProfileWidthDefault;
}

/// DESKTOP-ONLY — max width of a CHAT tab body in the browser.
///
/// Separate from the profile width: profile, chat and feeds each keep their
/// own size. Default = Comfortable (620), narrower than the profile's
/// Magazine: bubbles carry their own inner padding, so the comfortable
/// measure lands earlier than it does for a profile's banner + record grid.
///
/// ⚠ A default MUST be a [kReadingWidthPresets] value — the parsers below
/// only accept widths the chips actually offer, so a non-preset default would
/// be silently rewritten on the first read.
const String kBrowserChatWidthKey = 'browser_chat_max_width';
const double kBrowserChatWidthDefault = 620;

/// Parse the persisted chat width. Same defensive shape as its two siblings.
double parseBrowserChatWidth(String? raw) {
  if (raw == null) return kBrowserChatWidthDefault;
  if (raw == 'full') return double.infinity;
  final parsed = double.tryParse(raw);
  if (parsed == null) return kBrowserChatWidthDefault;
  for (final p in kReadingWidthPresets) {
    if (p.width == parsed) return parsed;
  }
  return kBrowserChatWidthDefault;
}

/// The browser's content-width caps — **one per tab GROUP, not per tab**.
///
/// Seven tab kinds, four groups. Grouping is by the shape of the content, not
/// by the tab:
///
/// | Group | Kinds | Key |
/// |---|---|---|
/// | profile | profile · management · settings | [kContactsProfileWidthKey] |
/// | chat | chat | [kBrowserChatWidthKey] |
/// | feeds | feeds | [kReadingWidthKey] — **shared with the Feeds pane** |
/// | web | web · app | none; a page brings its own layout, so it fills |
///
/// The feeds group deliberately reads the SAME key as the Feeds destination,
/// so the width follows the content instead of the pane. Two surfaces write
/// one key; each re-reads at mount, and panes are rebuilt per destination
/// rather than kept in an IndexedStack, so the other surface catches up on
/// the next visit.
///
/// The kind → group mapping itself lives in `browser.dart`'s `_capOf`, since
/// `_TabKind` is private to that file.
class BrowserWidths {
  final double profile;
  final double chat;
  final double feeds;

  const BrowserWidths({
    required this.profile,
    required this.chat,
    required this.feeds,
  });

  const BrowserWidths.defaults()
    : profile = kContactsProfileWidthDefault,
      chat = kBrowserChatWidthDefault,
      feeds = kReadingWidthDefault;

  BrowserWidths copyWith({double? profile, double? chat, double? feeds}) =>
      BrowserWidths(
        profile: profile ?? this.profile,
        chat: chat ?? this.chat,
        feeds: feeds ?? this.feeds,
      );

  /// Read all three in one go. Every failure mode — missing record, unreadable
  /// store, junk value — collapses to that group's default, exactly like the
  /// single-key load it replaces.
  static Future<BrowserWidths> load() async {
    Future<String?> read(String key) async {
      try {
        return (await PublicOSSettings.getSetting(key))?.value;
      } catch (_) {
        return null;
      }
    }

    final raw = await Future.wait([
      read(kContactsProfileWidthKey),
      read(kBrowserChatWidthKey),
      read(kReadingWidthKey),
    ]);
    return BrowserWidths(
      profile: parseContactsProfileWidth(raw[0]),
      chat: parseBrowserChatWidth(raw[1]),
      feeds: parseReadingWidth(raw[2]),
    );
  }
}

/// Which group a chip row edits.
enum BrowserWidthGroup { profile, chat, feeds }

/// Browser settings as a small glass dialog, fired from the footer row under
/// the contact list. Desktop-only settings live here; for now that is the
/// three content-width groups. The dialog floats over the pane, so picking a
/// preset visibly resizes the body behind it (same self-preview the feeds
/// settings page gets by living in the reading column).
///
/// Labelled just "Settings": it configures the browser, not a contact. The
/// file, this function and the persisted keys keep their older names on
/// purpose (a rename costs every call site and buys nothing).
Future<void> showContactSettingsDialog(
  BuildContext context, {
  required BrowserWidths widths,
  required ValueChanged<BrowserWidths> onWidthsChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ContactSettingsDialog(
      widths: widths,
      onWidthsChanged: onWidthsChanged,
    ),
  );
}

class _ContactSettingsDialog extends StatefulWidget {
  final BrowserWidths widths;
  final ValueChanged<BrowserWidths> onWidthsChanged;

  const _ContactSettingsDialog({
    required this.widths,
    required this.onWidthsChanged,
  });

  @override
  State<_ContactSettingsDialog> createState() => _ContactSettingsDialogState();
}

class _ContactSettingsDialogState extends State<_ContactSettingsDialog> {
  late BrowserWidths _widths = widget.widths;

  static String _keyOf(BrowserWidthGroup group) {
    switch (group) {
      case BrowserWidthGroup.profile:
        return kContactsProfileWidthKey;
      case BrowserWidthGroup.chat:
        return kBrowserChatWidthKey;
      case BrowserWidthGroup.feeds:
        // Shared with the Feeds destination on purpose — see [BrowserWidths].
        return kReadingWidthKey;
    }
  }

  double _widthOf(BrowserWidthGroup group) {
    switch (group) {
      case BrowserWidthGroup.profile:
        return _widths.profile;
      case BrowserWidthGroup.chat:
        return _widths.chat;
      case BrowserWidthGroup.feeds:
        return _widths.feeds;
    }
  }

  BrowserWidths _withGroup(BrowserWidthGroup group, double width) {
    switch (group) {
      case BrowserWidthGroup.profile:
        return _widths.copyWith(profile: width);
      case BrowserWidthGroup.chat:
        return _widths.copyWith(chat: width);
      case BrowserWidthGroup.feeds:
        return _widths.copyWith(feeds: width);
    }
  }

  Future<void> _save(BrowserWidthGroup group, double width) async {
    // Same save shape as the feeds `_saveReadingWidth`.
    final key = _keyOf(group);
    try {
      final record = Record.asSettings(
        key: key,
        value: encodeReadingWidth(width),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(key, record);
    } catch (_) {}
  }

  void _pick(BrowserWidthGroup group, double width) {
    final next = _withGroup(group, width);
    setState(() => _widths = next);
    _save(group, width);
    widget.onWidthsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        // 460, not the older 400: three chip rows instead of one, and the
        // widest preset row ("Comfortable"/"Magazine") then lands in two
        // lines per group rather than three.
        width: DialogWidth.m,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: tokens.starkWhite),
                const SizedBox(width: 10),
                Text(
                  context.l10n.desktopBrowserSettingsHeader,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.createRecordPageClose,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: tokens.textDim,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.desktopContentWidthSection,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.desktopContentWidthHint,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 12,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 14),
            // One row per width GROUP, in deck order — the same order the
            // kinds appear in the browser's tab strip.
            _groupRow(
              tokens,
              label: context.l10n.desktopContentWidthProfile,
              group: BrowserWidthGroup.profile,
            ),
            _groupRow(
              tokens,
              label: context.l10n.desktopContentWidthChat,
              group: BrowserWidthGroup.chat,
            ),
            _groupRow(
              tokens,
              label: context.l10n.desktopContentWidthFeeds,
              note: context.l10n.desktopContentWidthFeedsHint,
              group: BrowserWidthGroup.feeds,
              last: true,
            ),
          ],
        ),
      ),
    );
  }

  /// One group: its name, an optional note, and the shared preset chips.
  Widget _groupRow(
    GlassTokens tokens, {
    required String label,
    required BrowserWidthGroup group,
    String? note,
    bool last = false,
  }) {
    final width = _widthOf(group);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'SpaceGrotesk',
                ),
              ),
              if (note != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    note,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in kReadingWidthPresets)
                _chip(
                  tokens,
                  label: preset.label,
                  active: width == preset.width,
                  onTap: () => _pick(group, preset.width),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Same chip look as the feeds `_ReadingWidthRow`.
  Widget _chip(
    GlassTokens tokens, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? tokens.glassFillHover : tokens.surfaceElevated,
            border: Border.all(
              color: active ? tokens.borderMedium : tokens.borderSubtle,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? tokens.starkWhite : tokens.textDim,
              fontSize: 12,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
