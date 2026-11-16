import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/post_card.dart' show PostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/translation_service.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/post_signature_mark.dart'
    show SignatureShimmerPrefs;
import 'package:publicos_desktop/widgets/feeds/emoji_picker_dialog.dart'
    show showEmojiPickerDialog;
import 'package:publicos_desktop/widgets/feeds/reaction_quick_bar.dart'
    show ReactionPrefs;
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Persistence keys — preserved from client's previous
/// `RssFeedsSettingsSheet` so saved values round-trip for existing users.
const String _titleKey = 'rss_feeds_title_text_size';
const String _bodyKey = 'rss_feeds_description_text_size';
/// Combined summary+body character budget for feed cards. 0 = show full.
const String _trimKey = 'rss_feeds_trim_chars';
/// `PostLayoutMode.name` (`compact` | `wide`). Missing or unrecognised → compact.
const String _layoutKey = 'rss_feeds_layout_mode';

/// Default reading settings. **PUBLIC and canonical — the feeds pane initialises
/// its own state from these.**
///
/// ⚠ In publicos_client these are private and `feeds_view` hard-codes its own
/// copies, which have DRIFTED: the client's body default is 15 here but
/// `_descriptionTextSize = 14.0` there, so a fresh account renders body text at
/// 14 while this sheet's slider reads 15 — and the first touch of the slider
/// silently jumps the text. Desktop fixes it at the root: the constants are
/// exported and the pane reads them, so there is only one number to be right.
/// Worth fixing upstream in the client too.
const double kTitleDefault = 16;
const double kBodyDefault = 15;
const int kTrimDefault = 400;
const PostLayoutMode kLayoutDefault = PostLayoutMode.compact;

// Internal aliases so the rest of this file stays byte-identical to the client.
const double _titleDefault = kTitleDefault;
const double _bodyDefault = kBodyDefault;
const int _trimDefault = kTrimDefault;
const PostLayoutMode _layoutDefault = kLayoutDefault;

/// Parse a persisted layout-mode string back into the enum. Defensive: any
/// unknown / corrupted value collapses to [_layoutDefault].
PostLayoutMode parsePostLayoutMode(String? raw) {
  for (final mode in PostLayoutMode.values) {
    if (mode.name == raw) return mode;
  }
  return _layoutDefault;
}

// ── Reading width — DESKTOP ONLY ───────────────────────────────────────────
//
// The first setting in this file that publicos_client does NOT have, and cannot
// meaningfully have: on a phone the reading column IS the screen, so there is no
// width to choose. On a desktop window it is the single biggest lever on how the
// feed reads -- a 520px column is a timeline, a 900px one is a magazine -- so it
// belongs to the user, not to a constant in our source.
//
// Presets rather than a free slider: the useful range is narrow and the
// interesting values are few, so naming them ("Magazine") says more than a
// number does. `double.infinity` = no cap, fill the pane.
const String kReadingWidthKey = 'rss_feeds_reading_width';
const double kReadingWidthDefault = 520;

class ReadingWidthPreset {
  final String label;
  final double width;
  const ReadingWidthPreset(this.label, this.width);
}

const List<ReadingWidthPreset> kReadingWidthPresets = [
  ReadingWidthPreset('Narrow', 440),
  ReadingWidthPreset('Cozy', 520),
  ReadingWidthPreset('Comfortable', 620),
  ReadingWidthPreset('Magazine', 740),
  ReadingWidthPreset('Wide', 900),
  ReadingWidthPreset('Full', double.infinity),
];

/// Parse the persisted width. Defensive, like [parsePostLayoutMode]: anything
/// unknown or corrupted collapses to the default rather than throwing.
double parseReadingWidth(String? raw) {
  if (raw == null) return kReadingWidthDefault;
  if (raw == 'full') return double.infinity;
  final parsed = double.tryParse(raw);
  if (parsed == null) return kReadingWidthDefault;
  // Only accept values we actually offer -- a stale/hand-edited setting can't
  // strand the user at a width the UI has no chip for.
  for (final p in kReadingWidthPresets) {
    if (p.width == parsed) return parsed;
  }
  return kReadingWidthDefault;
}

String encodeReadingWidth(double w) =>
    w == double.infinity ? 'full' : w.toString();

/// Slider ranges (the client's 12-24 / 10-20).
const double _titleMin = 12;
const double _titleMax = 24;
const double _bodyMin = 10;
const double _bodyMax = 20;
const double _trimMin = 100;
const double _trimMax = 1000;

/// Glass bottom sheet with title + body text size sliders for the feeds
/// reading view. Live-updates post cards underneath via the on-change
/// callbacks, and persists each change to `PublicOSSettings` so values
/// survive app restarts and round-trip across devices signed into the
/// same account.
///
/// Opens via `showFeedsSettingsSheet(context, ...)`. Called from the
/// feeds drawer footer Settings row + the feeds view's public
/// `showSettingsSheet()` method.
/// **DESKTOP DELTA — the sheet is a PAGE.**
///
/// The client opens this as a `DraggableScrollableSheet` whose whole reason to
/// exist is mobile gesture: opens at 70%, drag up to 95%, drag down to dismiss,
/// with the inner scroll's controller wired to the sheet's position so
/// overscroll-at-top hands off to a sheet-drag. On desktop that is meaningless —
/// there is nothing to drag.
///
/// So it renders **in place in the feeds reading column** with a back arrow,
/// reusing the same detail-stack `FeedsPane` already uses for post detail:
/// whatever you were reading is remembered, and Back puts
/// you straight back on it. `FeedsPane` mounts [FeedsSettingsView] directly;
/// there is no `showFeedsSettingsSheet` on desktop.
class FeedsSettingsView extends StatefulWidget {
  final double titleSize;
  final double bodySize;
  final int? trimChars;
  final PostLayoutMode layoutMode;
  final ValueChanged<double> onTitleChanged;
  final ValueChanged<double> onBodyChanged;
  final ValueChanged<int?> onTrimChanged;
  final ValueChanged<PostLayoutMode> onLayoutChanged;

  /// Reader-wide auto-sign-in flipped.
  /// The host refetches so the very next fetch honours the new posture.
  final ValueChanged<bool>? onAutoSigninChanged;

  /// DESKTOP-ONLY. Max width of the feeds reading column.
  final double readingWidth;
  final ValueChanged<double> onReadingWidthChanged;

  /// Back to whatever was in the reading column before settings opened.
  final VoidCallback onBack;

  const FeedsSettingsView({
    super.key,
    required this.titleSize,
    required this.bodySize,
    required this.trimChars,
    required this.layoutMode,
    required this.onTitleChanged,
    required this.onBodyChanged,
    required this.onTrimChanged,
    required this.onLayoutChanged,
    this.onAutoSigninChanged,
    required this.readingWidth,
    required this.onReadingWidthChanged,
    required this.onBack,
  });

  @override
  State<FeedsSettingsView> createState() => _FeedsSettingsViewState();
}

class _FeedsSettingsViewState extends State<FeedsSettingsView> {
  /// Was the DraggableScrollableSheet's controller on mobile; here it is just a
  /// plain scroll controller for the body.
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  late double _title = widget.titleSize;
  late double _body = widget.bodySize;
  late bool _trimEnabled = widget.trimChars != null && widget.trimChars! > 0;
  late double _trimLength =
      (widget.trimChars != null && widget.trimChars! > 0)
          ? widget.trimChars!.toDouble().clamp(_trimMin, _trimMax)
          : _trimDefault.toDouble();
  late PostLayoutMode _layout = widget.layoutMode;
  late double _readingWidth = widget.readingWidth;

  // Feed video (here, not in app Settings: both only ever apply to feeds).
  // Same Core keys; defaults match Core's getters.
  int _videoMb = 35;
  bool _videoAutoplay = true;
  bool _sigShimmer = true;
  int _sigSeconds = SignatureShimmerPrefs.defaultSeconds;
  String _doubleTap = ReactionPrefs.heart;

  /// The Settings page's accordion: one group open at a time, session-only.
  String? _openGroup = 'layout';

  // Translation prefs (mobile-only section; hidden when !isSupported).
  bool _autoSignin = false;
  bool _translationsEnabled = true;
  bool _translationWifiOnly = true;
  Set<String> _disabledSources = const <String>{};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Re-read persisted values from Core so the sheet opens in sync with
  /// what's stored, even if the parent was stale.
  Future<void> _loadSettings() async {
    try {
      final titleRecord = await PublicOSSettings.getSetting(_titleKey);
      final bodyRecord = await PublicOSSettings.getSetting(_bodyKey);
      final trimRecord = await PublicOSSettings.getSetting(_trimKey);
      final layoutRecord = await PublicOSSettings.getSetting(_layoutKey);
      final widthRecord = await PublicOSSettings.getSetting(kReadingWidthKey);
      final autoSignin = await PublicOSSettings.getFeedsAutoSignin();
      final videoMb = await PublicOSSettings.getVideoAutoloadThresholdMb();
      final videoAutoplay = await PublicOSSettings.getVideoAutoplayInFeed();
      final sigShimmer = await SignatureShimmerPrefs.isEnabled();
      final sigSeconds = await SignatureShimmerPrefs.seconds();
      final doubleTap = await ReactionPrefs.doubleTapEmoji();
      if (!mounted) return;
      setState(() {
        _autoSignin = autoSignin;
        _videoMb = videoMb;
        _videoAutoplay = videoAutoplay;
        _sigShimmer = sigShimmer;
        _sigSeconds = sigSeconds;
        _doubleTap = doubleTap;
        if (titleRecord != null) {
          final parsed = double.tryParse(titleRecord.value);
          if (parsed != null) _title = parsed.clamp(_titleMin, _titleMax);
        }
        if (bodyRecord != null) {
          final parsed = double.tryParse(bodyRecord.value);
          if (parsed != null) _body = parsed.clamp(_bodyMin, _bodyMax);
        }
        if (trimRecord != null) {
          final parsed = int.tryParse(trimRecord.value);
          if (parsed != null) {
            _trimEnabled = parsed > 0;
            if (parsed > 0) {
              _trimLength = parsed.toDouble().clamp(_trimMin, _trimMax);
            }
          }
        }
        if (layoutRecord != null) {
          _layout = parsePostLayoutMode(layoutRecord.value);
        }
        if (widthRecord != null) {
          _readingWidth = parseReadingWidth(widthRecord.value);
        }
      });
      // Translation prefs are read through TranslationPrefs (cached after
      // first hit) so the source-language list reflects what post/comment
      // cards will actually see.
      if (TranslationService.isSupported) {
        final enabled = await TranslationPrefs.isEnabled();
        final disabled = await TranslationPrefs.disabledSources();
        final wifiOnly = await TranslationPrefs.wifiOnly();
        if (!mounted) return;
        setState(() {
          _translationsEnabled = enabled;
          _disabledSources = disabled;
          _translationWifiOnly = wifiOnly;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveTitle(double size) async {
    try {
      final record = Record.asSettings(
        key: _titleKey,
        value: size.toString(),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_titleKey, record);
    } catch (_) {}
  }

  Future<void> _saveBody(double size) async {
    try {
      final record = Record.asSettings(
        key: _bodyKey,
        value: size.toString(),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_bodyKey, record);
    } catch (_) {}
  }

  /// Persist trim length. Stores 0 when disabled (easier to round-trip than
  /// deleting the key); consumer treats 0 as "show full".
  Future<void> _saveTrim(int chars) async {
    try {
      final record = Record.asSettings(
        key: _trimKey,
        value: chars.toString(),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_trimKey, record);
    } catch (_) {}
  }

  Future<void> _saveLayout(PostLayoutMode mode) async {
    try {
      final record = Record.asSettings(
        key: _layoutKey,
        value: mode.name,
        isSystem: true,
      );
      await PublicOSSettings.setSetting(_layoutKey, record);
    } catch (_) {}
  }

  /// DESKTOP-ONLY. Same shape as [_saveLayout] -- persisted through
  /// PublicOSSettings, so it round-trips across restarts (and follows the
  /// account to another desktop signed into it).
  Future<void> _saveReadingWidth(double width) async {
    try {
      final record = Record.asSettings(
        key: kReadingWidthKey,
        value: encodeReadingWidth(width),
        isSystem: true,
      );
      await PublicOSSettings.setSetting(kReadingWidthKey, record);
    } catch (_) {}
  }

  void _setVideoMb(double mb) {
    final v = mb.round();
    setState(() {
      _videoMb = v;
    });
    PublicOSSettings.setVideoAutoloadThresholdMb(v);
  }

  void _setVideoAutoplay(bool on) {
    setState(() {
      _videoAutoplay = on;
    });
    PublicOSSettings.setVideoAutoplayInFeed(on);
  }

  void _setSigShimmer(bool on) {
    setState(() => _sigShimmer = on);
    SignatureShimmerPrefs.setEnabled(on);
  }

  void _setSigSeconds(double v) {
    final s = v.round();
    setState(() => _sigSeconds = s);
    SignatureShimmerPrefs.setSeconds(s);
  }

  Future<void> _pickDoubleTap() async {
    final picked = await showEmojiPickerDialog(context, currentEmoji: _doubleTap);
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => _doubleTap = picked);
    ReactionPrefs.setDoubleTapEmoji(picked);
  }

  String _videoMbText(BuildContext context) {
    final l10n = context.l10n;
    if (_videoMb <= 0) return l10n.feedsSettingsSheetVideoAlwaysAsk;
    if (_videoMb >= 500) return l10n.feedsSettingsSheetVideoNoLimit;
    return '$_videoMb MB';
  }

  /// One collapsible group (the Settings page's `_group`, sheet-sized): a
  /// header row, the body growing under it. Rows keep their own 20 px inset.
  Widget _group({
    required String id,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final open = _openGroup == id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 0),
          child: _GroupHeader(
            icon: icon,
            title: title,
            open: open,
            onTap: () => setState(() {
              _openGroup = open ? null : id;
            }),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  void _emitTrim() {
    final effective = _trimEnabled ? _trimLength.round() : 0;
    _saveTrim(effective);
    widget.onTrimChanged(effective > 0 ? effective : null);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // DESKTOP: sizing is just the reading column. The header (back / title /
    // preview) is pinned and the Expanded SingleChildScrollView fills the rest.
    // On mobile this scroll is wired to the DraggableScrollableSheet's own
    // controller so overscroll-at-top hands off to a sheet drag; there is no
    // sheet here, so it is a plain controller.
    // DESKTOP DELTA: no sheet chrome. The drag handle and the rounded top corners
    // are the sheet's affordances, and the close X pops a route that does not
    // exist here. A page gets a back arrow instead.
    return Container(
      color: tokens.surfaceDeep,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded,
                        color: tokens.starkWhite),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.feedsSettingsSheetTitle,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            // ---- Pinned header: preview always visible ----
            _PreviewCard(
              titleSize: _title,
              bodySize: _body,
              layoutMode: _layout,
            ),
            // ---- Scrollable controls (everything below the preview) ----
            // Expanded fills the remaining sheet height; the controller is
            // the one the parent DraggableScrollableSheet handed us, which
            // means overscroll at the inner top propagates to the sheet
            // (shrinks it, and dismisses past minChildSize).
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    _group(
                      id: 'layout',
                      icon: Icons.view_agenda_outlined,
                      title: context.l10n.feedsSettingsSheetGroupLayout,
                      children: [
                        _LayoutToggleRow(
                          mode: _layout,
                          onChanged: (m) {
                            setState(() => _layout = m);
                            _saveLayout(m);
                            widget.onLayoutChanged(m);
                          },
                        ),
                        // DESKTOP-ONLY (see kReadingWidthPresets). Sits under
                        // Layout because they answer the same question: how
                        // wide does a post get to be. The settings page is
                        // itself rendered in the reading column, so the control
                        // previews itself.
                        _ReadingWidthRow(
                          width: _readingWidth,
                          onChanged: (w) {
                            setState(() => _readingWidth = w);
                            _saveReadingWidth(w);
                            widget.onReadingWidthChanged(w);
                          },
                        ),
                        _Slider(
                          label: context.l10n.feedsSettingsSheetTitleSizeLabel,
                          value: _title,
                          min: _titleMin,
                          max: _titleMax,
                          onChanged: (v) {
                            setState(() => _title = v);
                            _saveTitle(v);
                            widget.onTitleChanged(v);
                          },
                        ),
                        _Slider(
                          label: context.l10n.feedsSettingsSheetBodySizeLabel,
                          value: _body,
                          min: _bodyMin,
                          max: _bodyMax,
                          onChanged: (v) {
                            setState(() => _body = v);
                            _saveBody(v);
                            widget.onBodyChanged(v);
                          },
                        ),
                        _TrimToggleRow(
                          enabled: _trimEnabled,
                          onChanged: (v) {
                            setState(() => _trimEnabled = v);
                            _emitTrim();
                          },
                        ),
                        if (_trimEnabled)
                          _Slider(
                            label: context.l10n.feedsSettingsSheetTrimAtLabel,
                            value: _trimLength,
                            min: _trimMin,
                            max: _trimMax,
                            valueSuffix:
                                ' ${context.l10n.feedsSettingsSheetTrimUnit}',
                            onChanged: (v) {
                              setState(() => _trimLength = v);
                              _emitTrim();
                            },
                          ),
                      ],
                    ),
                    // No Scrolling group: the swipe snap is phone-only.
                    _group(
                      id: 'reactions',
                      icon: Icons.favorite_border_rounded,
                      title: context.l10n.feedsSettingsSheetGroupReactions,
                      children: [
                        _EmojiPickRow(
                          label: context.l10n.feedsSettingsSheetDoubleTapLabel,
                          subtitle: context.l10n.feedsSettingsSheetDoubleTapHint,
                          emoji: _doubleTap,
                          onTap: _pickDoubleTap,
                        ),
                      ],
                    ),
                    _group(
                      id: 'signature',
                      icon: Icons.verified_outlined,
                      title: context.l10n.feedsSettingsSheetGroupSignature,
                      children: [
                        _SwitchRow(
                          label: context.l10n.feedsSettingsSheetSigShimmerLabel,
                          subtitle: _sigShimmer
                              ? context.l10n.feedsSettingsSheetSigShimmerOn
                              : context.l10n.feedsSettingsSheetSigShimmerOff,
                          value: _sigShimmer,
                          onChanged: _setSigShimmer,
                        ),
                        if (_sigShimmer)
                          _Slider(
                            label: context.l10n.feedsSettingsSheetSigShimmerEveryLabel,
                            value: _sigSeconds.toDouble(),
                            min: SignatureShimmerPrefs.minSeconds.toDouble(),
                            max: SignatureShimmerPrefs.maxSeconds.toDouble(),
                            divisions: SignatureShimmerPrefs.maxSeconds -
                                SignatureShimmerPrefs.minSeconds,
                            valueSuffix: ' s',
                            hint: context.l10n.feedsSettingsSheetSigShimmerEveryHint,
                            onChanged: _setSigSeconds,
                          ),
                      ],
                    ),
                    _group(
                      id: 'video',
                      icon: Icons.play_circle_outline,
                      title: context.l10n.feedsSettingsSheetGroupVideo,
                      children: [
                        _SwitchRow(
                          label: context.l10n.feedsSettingsSheetVideoAutoplayLabel,
                          subtitle: _videoAutoplay
                              ? context.l10n.feedsSettingsSheetVideoAutoplayOn
                              : context.l10n.feedsSettingsSheetVideoAutoplayOff,
                          value: _videoAutoplay,
                          onChanged: _setVideoAutoplay,
                        ),
                        if (_videoAutoplay)
                          _Slider(
                            label: context.l10n.feedsSettingsSheetVideoAutoloadLabel,
                            value: _videoMb.toDouble(),
                            min: 0,
                            max: 500,
                            divisions: 100,
                            valueText: _videoMbText(context),
                            hint: context.l10n.feedsSettingsSheetVideoAutoloadHint,
                            onChanged: _setVideoMb,
                          ),
                      ],
                    ),
                    // DESKTOP DELTA: the translation controls drive Google ML
                    // Kit, Android/iOS only, so desktop shows a legend instead
                    // of an absence.
                    _group(
                      id: 'translation',
                      icon: Icons.translate_rounded,
                      title: context.l10n.feedsSettingsSheetGroupTranslation,
                      children: const [
                        _TranslationsComingSoonRow(),
                      ],
                    ),
                    _group(
                      id: 'signin',
                      icon: Icons.key_outlined,
                      title: context.l10n.feedsSettingsSheetGroupSignin,
                      children: [
                        _AutoSigninToggleRow(
                          enabled: _autoSignin,
                          onChanged: (v) async {
                            setState(() => _autoSignin = v);
                            await PublicOSSettings.setFeedsAutoSignin(v);
                            widget.onAutoSigninChanged?.call(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _ResetButton(
                        onTap: () {
                          setState(() {
                            _title = _titleDefault;
                            _body = _bodyDefault;
                            _trimEnabled = false;
                            _trimLength = _trimDefault.toDouble();
                            _layout = _layoutDefault;
                            _readingWidth = kReadingWidthDefault;
                            _translationsEnabled = true;
                            _translationWifiOnly = true;
                            _disabledSources = const <String>{};
                          });
                          _setVideoMb(35);
                          _setVideoAutoplay(true);
                          _saveTitle(_titleDefault);
                          _saveBody(_bodyDefault);
                          _saveTrim(0);
                          _saveLayout(_layoutDefault);
                          _saveReadingWidth(kReadingWidthDefault);
                          widget.onReadingWidthChanged(kReadingWidthDefault);
                          if (TranslationService.isSupported) {
                            TranslationPrefs.reset();
                          }
                          widget.onTitleChanged(_titleDefault);
                          widget.onBodyChanged(_bodyDefault);
                          widget.onTrimChanged(null);
                          widget.onLayoutChanged(_layoutDefault);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faithful mock of a `PostCard` (`components/feeds/post_card.dart`) — same
/// avatar size, gutter, author-line composition, feed-context subtitle, and
/// title/body cascade — so the live-updating font-size sliders preview
/// against the exact shape users will see in the feed. Hand-rolled (not a
/// real `PostCard`) because constructing a real Post graph for a preview
/// surface is overkill; the layout constants are mirrored so divergence is
/// visible at a glance if post_card drifts.
///
/// The author contact is the on-chain "publicos" group — resolved local
/// first, falls back to a chain fetch, then saves locally so subsequent
/// opens are instant. While resolving, an initials placeholder + "publicos"
/// label render so the layout doesn't shift when the avatar lands.
class _PreviewCard extends StatefulWidget {
  final double titleSize;
  final double bodySize;
  final PostLayoutMode layoutMode;

  const _PreviewCard({
    required this.titleSize,
    required this.bodySize,
    required this.layoutMode,
  });

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard> {
  // Mirrors post_card.dart's avatar/gutter constants so the preview reads
  // identically.
  static const double _avatarSize = 36;
  static const double _gutter = 12;

  /// On-chain "publicos" group account. Hardcoded for the preview so the
  /// mock post + via-line both point at the canonical brand contact.
  /// Re-point on any chain redeploy:
  /// `MR.getModuleAddress(keccak256("PUBLICOS_ROOT_ORG"))`.
  static const String _publicosAccountAddress =
      '0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD';

  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _resolveContact();
  }

  /// Local-first, chain-fallback. Mirrors the canonical
  /// `searchContacts → fetchContact → saveContact` ladder in
  /// `PublicOSContacts.resolveByIdentifier`. Silent on failure — the
  /// placeholder tile stays.
  Future<void> _resolveContact() async {
    try {
      final addr = EthereumAddress.fromHex(_publicosAccountAddress);
      var contact = await PublicOSContacts.getContact(addr);
      if (contact == null && PublicOS.web3Connected) {
        try {
          contact = await PublicOSContacts.fetchContact(addr, requireRecords: true);
          await PublicOSContacts.saveContact(contact);
        } catch (_) {
          // Chain fetch failed (offline / RPC down) — placeholder stays.
        }
      }
      if (!mounted) return;
      setState(() => _contact = contact);
    } catch (_) {
      // EthereumAddress.fromHex shouldn't fail on a hardcoded literal; swallow
      // defensively.
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final contact = _contact;
    final displayName = contact?.displayName ?? 'publicos';

    final avatar = SizedBox(
      width: _avatarSize,
      height: _avatarSize,
      child: contact != null
          ? GlassContactIcon(contact: contact, size: _avatarSize)
          : const _PreviewAvatarPlaceholder(size: _avatarSize),
    );

    final authorBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.2),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('·', style: TextStyle(color: tokens.textDim)),
              const SizedBox(width: 6),
              Text(
                context.l10n.feedsSettingsSheetJustNow,
                style: TextStyle(color: tokens.textDim, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        _PreviewFeedContextSubtitle(
          feedName: 'Zocalo',
          foundAtContact: contact,
          foundAtDisplayName: displayName,
          tokens: tokens,
        ),
      ],
    );

    final titleText = Text(
      'publicos is live',
      style: TextStyle(
        color: tokens.starkWhite,
        fontSize: widget.titleSize,
        fontWeight: FontWeight.bold,
        height: 1.25,
      ),
    );

    final bodyText = Text(
      'alpha is out. on-chain since this morning, providers '
      'signed up, rent flowing. if the next week is quiet '
      'I\'ll call it a win.',
      style: TextStyle(
        color: tokens.starkWhite.withValues(alpha: 0.92),
        fontSize: widget.bodySize,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: widget.layoutMode == PostLayoutMode.wide
          ? const EdgeInsets.fromLTRB(0, 12, 0, 14)
          : const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: widget.layoutMode == PostLayoutMode.wide
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                  child: Text(
                    context.l10n.feedsSettingsSheetPreviewLabel,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(width: _gutter),
                      Expanded(child: authorBlock),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: titleText,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: bodyText,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.feedsSettingsSheetPreviewLabel,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    avatar,
                    const SizedBox(width: _gutter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          authorBlock,
                          const SizedBox(height: 12),
                          titleText,
                          const SizedBox(height: 10),
                          bodyText,
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Pre-resolve placeholder: same rounded square as `GlassContactIcon`'s
/// initials state, muted teal background, "p" centered. Keeps layout
/// stable while the chain/local lookup is in flight.
class _PreviewAvatarPlaceholder extends StatelessWidget {
  final double size;
  const _PreviewAvatarPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2E7E78);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        'p',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

/// Mirrors `post_card.dart::_buildFeedContextSubtitle` + `_buildViaLine`:
/// `[rss icon] feedName · via [mini contact icon] foundAtDisplayName`.
/// Pulled into its own widget so the preview reads as a single
/// composition; the real post_card keeps its own copy to stay close to
/// the actual rendering pipeline.
class _PreviewFeedContextSubtitle extends StatelessWidget {
  final String feedName;
  final Contact? foundAtContact;
  final String foundAtDisplayName;
  final GlassTokens tokens;

  const _PreviewFeedContextSubtitle({
    required this.feedName,
    required this.foundAtContact,
    required this.foundAtDisplayName,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 2,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rss_feed_rounded, size: 11, color: tokens.textDim),
              const SizedBox(width: 4),
              Text(
                feedName,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text('·', style: TextStyle(color: tokens.textDim)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.feedsSettingsSheetVia,
                  style: TextStyle(color: tokens.textDim, fontSize: 11)),
              const SizedBox(width: 5),
              SizedBox(
                width: 14,
                height: 14,
                child: foundAtContact != null
                    ? GlassContactIcon(
                        contact: foundAtContact!,
                        size: 14,
                      )
                    : const _PreviewAvatarPlaceholder(size: 14),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  foundAtDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  /// Unit displayed after the numeric value (default 'pt' for font-size use).
  final String valueSuffix;

  /// Replaces `value + valueSuffix` on the right ("Always ask", "35 MB").
  final String? valueText;

  /// A dim line under the label.
  final String? hint;

  /// Step count; null = the size-based default below.
  final int? divisions;

  const _Slider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.valueSuffix = 'pt',
    this.valueText,
    this.hint,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                valueText ?? '${value.toStringAsFixed(0)}$valueSuffix',
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hint!,
                style: TextStyle(color: tokens.textDim, fontSize: 11),
              ),
            ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: tokens.starkWhite,
              inactiveTrackColor: tokens.borderSubtle,
              thumbColor: tokens.starkWhite,
              overlayColor: tokens.starkWhite.withValues(alpha: 0.12),
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              // Font sliders step by 1; larger ranges use ~50 divisions so the
              // thumb doesn't feel jittery at every pixel movement.
              divisions: divisions ??
                  ((max - min) > 50 ? 50 : (max - min).toInt()),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented Wide | Compact selector. Visually mirrors the slider rows above
/// (small uppercase label) so the section reads as a single settings block.
/// Active pill paints `glassFillHover` + `borderMedium` over `surfaceElevated`
/// so the selection reads clearly without competing with the slider thumbs.
class _LayoutToggleRow extends StatelessWidget {
  final PostLayoutMode mode;
  final ValueChanged<PostLayoutMode> onChanged;

  const _LayoutToggleRow({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.feedsSettingsSheetLayoutLabel,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border.all(color: tokens.borderSubtle, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                // Wide first, on the left.
                _segment(
                  context,
                  tokens,
                  label: context.l10n.feedsSettingsSheetLayoutWide,
                  active: mode == PostLayoutMode.wide,
                  onTap: () => onChanged(PostLayoutMode.wide),
                ),
                _segment(
                  context,
                  tokens,
                  label: context.l10n.feedsSettingsSheetLayoutCompact,
                  active: mode == PostLayoutMode.compact,
                  onTap: () => onChanged(PostLayoutMode.compact),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    GlassTokens tokens, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? tokens.glassFillHover : Colors.transparent,
              border: Border.all(
                color: active ? tokens.borderMedium : Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: active ? tokens.starkWhite : tokens.textDim,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact row with label + switch for the "trim long posts" toggle.
class _TrimToggleRow extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TrimToggleRow({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.feedsSettingsSheetTrimLongPostsLabel,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? context.l10n.feedsSettingsSheetTrimLongPostsOn
                      : context.l10n.feedsSettingsSheetTrimLongPostsOff,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: tokens.starkWhite,
            activeTrackColor: tokens.borderMedium,
            inactiveThumbColor: tokens.textDim,
            inactiveTrackColor: tokens.borderSubtle,
          ),
        ],
      ),
    );
  }
}

/// Reader-wide default for feed sign-in: ON signs every channel the user has
/// not said no to, asks nothing and writes no per-channel decision; OFF
/// means each channel asks once. Mirrors
/// `_TrimToggleRow` so the section reads as a sibling reading preference.
class _AutoSigninToggleRow extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _AutoSigninToggleRow({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.feedsSettingsSheetAutoSigninLabel,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? context.l10n.feedsSettingsSheetAutoSigninOn
                      : context.l10n.feedsSettingsSheetAutoSigninOff,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: tokens.starkWhite,
            activeTrackColor: tokens.borderMedium,
            inactiveThumbColor: tokens.textDim,
            inactiveTrackColor: tokens.borderSubtle,
          ),
        ],
      ),
    );
  }
}

/// Master on/off for the post/comment "Translate from {lang}" affordance.
/// Visually mirrors `_TrimToggleRow` so the section reads as a sibling
/// reading-preference. Sub-label flips to describe the active state.
class _TranslationToggleRow extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _TranslationToggleRow({
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.feedsSettingsSheetTranslationsLabel,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? context.l10n.feedsSettingsSheetTranslationsOn
                      : context.l10n.feedsSettingsSheetTranslationsOff,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: tokens.starkWhite,
            activeTrackColor: tokens.borderMedium,
            inactiveThumbColor: tokens.textDim,
            inactiveTrackColor: tokens.borderSubtle,
          ),
        ],
      ),
    );
  }
}

/// Whether language packs may download over mobile data, or only on Wi-Fi.
/// Sits under [_TranslationToggleRow], mirroring its shape. ON (default) ⇒ a
/// translate that needs a ~30 MB pack waits for Wi-Fi (the card shows
/// "Waiting for Wi-Fi…"); OFF ⇒ packs download over whatever connection is up.
class _TranslationWifiRow extends StatelessWidget {
  final bool wifiOnly;
  final ValueChanged<bool> onChanged;

  const _TranslationWifiRow({
    required this.wifiOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.feedsSettingsSheetWifiOnlyLabel,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  wifiOnly
                      ? context.l10n.feedsSettingsSheetWifiOnlyOn
                      : context.l10n.feedsSettingsSheetWifiOnlyOff,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: wifiOnly,
            onChanged: onChanged,
            activeColor: tokens.starkWhite,
            activeTrackColor: tokens.borderMedium,
            inactiveThumbColor: tokens.textDim,
            inactiveTrackColor: tokens.borderSubtle,
          ),
        ],
      ),
    );
  }
}

/// Scrollable per-source-language toggle list. Each row defaults ON
/// (suggest); user flips OFF the languages they read fluently so the hint
/// stops appearing on those posts. The device locale is excluded — there's
/// nothing to translate FROM your own UI language TO itself.
///
/// The container is capped at ~8 rows; the inner [ListView] scrolls.
class _TranslationSourceList extends StatelessWidget {
  /// BCP-47 base code of the system locale; this row is filtered out.
  final String deviceLanguage;

  /// Codes the user has turned OFF. Anything not in this set is ON.
  final Set<String> disabledSources;

  /// Called with (code, suggested). `suggested=true` ⇒ user turned the
  /// language ON (remove from disabled set); `false` ⇒ turned OFF.
  final void Function(String code, bool suggested) onToggle;

  const _TranslationSourceList({
    required this.deviceLanguage,
    required this.disabledSources,
    required this.onToggle,
  });

  /// Approximate row height; container height = 8 * this so exactly 8 rows
  /// land inside without clipping a 9th.
  static const double _rowHeight = 44;
  static const int _visibleRowsCap = 8;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // Build entries: every supported language except the device locale,
    // sorted alphabetically by display name.
    final entries = kPostLangNames.entries
        .where((e) => e.key != deviceLanguage)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.feedsSettingsSheetSuggestFromLabel,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border.all(color: tokens.borderSubtle, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              maxHeight: _rowHeight * _visibleRowsCap,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: tokens.borderSubtle.withValues(alpha: 0.4),
              ),
              itemBuilder: (_, i) {
                final e = entries[i];
                final code = e.key;
                final name = e.value;
                final on = !disabledSources.contains(code);
                return SizedBox(
                  height: _rowHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: on,
                            onChanged: (v) => onToggle(code, v),
                            activeColor: tokens.starkWhite,
                            activeTrackColor: tokens.borderMedium,
                            inactiveThumbColor: tokens.textDim,
                            inactiveTrackColor: tokens.borderSubtle,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
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
}

/// The Settings page's group header, sheet copy (each screen
/// keeps its own private `_GroupHeader`). Grey glyph + title + a chevron that
/// turns 90° when open; the open group gets a light `glassFill` wash.
class _GroupHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool open;
  final VoidCallback onTap;

  const _GroupHeader({
    required this.icon,
    required this.title,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = open ? tokens.starkWhite : tokens.textDim;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: open
              ? tokens.glassFill
              : tokens.glassFill.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            AnimatedRotation(
              turns: open ? 0.25 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.chevron_right_rounded, size: 18, color: fg),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Label + one-line state + switch: the shape of `_TrimToggleRow`, for rows
/// whose strings come from the caller.
/// A `_SwitchRow`-shaped row whose control is the chosen emoji in a glass
/// disc; the tap opens the full picker (the Reactions group).
class _EmojiPickRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final String emoji;
  final VoidCallback onTap;

  const _EmojiPickRow({
    required this.label,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Material(
            color: tokens.surfaceElevated,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.borderMedium),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: tokens.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: tokens.starkWhite,
            activeTrackColor: tokens.borderMedium,
            inactiveThumbColor: tokens.textDim,
            inactiveTrackColor: tokens.borderSubtle,
          ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ResetButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              context.l10n.feedsSettingsSheetReset,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// **Desktop-only.** Stands in for the client's translation controls, which
/// cannot work here (ML Kit is Android/iOS-only). Says so, rather than leaving a
/// silent hole where the client has a feature.
class _TranslationsComingSoonRow extends StatelessWidget {
  const _TranslationsComingSoonRow();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(Icons.translate_rounded, size: 18, color: tokens.textDim),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Translations \u2014 coming soon',
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **DESKTOP-ONLY.** Reading-column width, as named presets.
///
/// A Wrap rather than the segmented Row [_LayoutToggleRow] uses: six segments
/// would each be ~80px inside the (deliberately narrow) settings column, and the
/// labels are the whole point -- "Magazine" tells you what you are choosing in a
/// way that "740" does not. Wrapping keeps it legible at the Narrow preset,
/// which is exactly when it is hardest to fit.
class _ReadingWidthRow extends StatelessWidget {
  final double width;
  final ValueChanged<double> onChanged;

  const _ReadingWidthRow({required this.width, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'READING WIDTH',
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
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
                  onTap: () => onChanged(preset.width),
                ),
            ],
          ),
        ],
      ),
    );
  }

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
