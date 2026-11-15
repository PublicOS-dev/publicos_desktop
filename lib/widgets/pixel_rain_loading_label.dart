import 'package:flutter/material.dart';

import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/wave_text.dart';

/// The blocking loading affordance: pixel rain, then a wave-animated caption.
///
/// **One loader for "you have nothing to look at yet", in both apps.** Every
/// way into a blocking load shows this same pair, the rain plus its caption.
///
/// **Not for peripheral hints.** "Refreshing" — there may be more soon, but you
/// can already read the page — keeps its small bare [PixelRainLoadingWidget]
/// with no caption (`feeds_pane.dart`'s 18px header hint). The caption is what
/// separates *blocking* from *peripheral*; putting it on both erases the
/// distinction the two affordances exist to draw.
///
/// ⚠ **Same edit twice** — twin of
/// `publicos_client/lib/components/pixel_rain_loading_label.dart`, identical
/// apart from the import block.
class PixelRainLoadingLabel extends StatelessWidget {
  /// Edge of the rain grid. The caption scales with it.
  final double size;

  /// Defaults to the localised "Loading…" — pass one when the surface can say
  /// something more specific about the work ("Loading app", "Publishing…").
  final String? label;

  /// Lay the caption out under the rain rather than beside it. Use it where
  /// the loader sits in a narrow column; the row is the default because it
  /// reads as one object at a glance.
  final bool vertical;

  const PixelRainLoadingLabel({
    super.key,
    this.size = 28,
    this.label,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final text = label ?? context.l10n.bootLoading;
    final style = TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontWeight: FontWeight.w600,
      color: tokens.textDim,
      // Tracks the mark so the pair keeps its proportions at any size.
      fontSize: size * 0.46,
      letterSpacing: 1.5,
    );
    final mark = PixelRainLoadingWidget(size: size, showShadows: false);
    final caption = WaveText(text: text, style: style);

    return Semantics(
      label: text,
      excludeSemantics: true,
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [mark, SizedBox(height: size * 0.4), caption],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [mark, SizedBox(width: size * 0.5), caption],
            ),
    );
  }
}

/// The loader in its canonical place: **bottom-right of its parent.**
///
/// Position is part of the widget, not the call site. Both apps mount this
/// and get the identical corner, so it cannot drift. Fills its parent and
/// swallows
/// no taps, so it works as a `Stack`/`Positioned.fill` child and as a body.
///
/// It does NOT clear the system bottom bar by default: most parents already
/// end above it (the Explorer pads its tabs by gesture bar + nav but leaves
/// `MediaQuery` untouched, so a `SafeArea` here counted the bar twice). A
/// parent that runs to the physical bottom edge passes [safeBottom].
class PixelRainLoadingCorner extends StatelessWidget {
  /// Passed through to [PixelRainLoadingLabel].
  final String? label;

  /// Mark size. The caption scales off it.
  final double size;

  /// Override [inset]'s right / bottom for one surface; null keeps the
  /// shared 16 / 16.
  final double? right;
  final double? bottom;

  /// Also clear the system bottom bar (gesture handle / 3-button nav). Only
  /// for a parent that reaches the physical bottom edge, e.g. the browser.
  final bool safeBottom;

  const PixelRainLoadingCorner({
    super.key,
    this.label,
    this.size = 28,
    this.right,
    this.bottom,
    this.safeBottom = false,
  });

  /// The one corner inset, shared by both apps. A larger inset reads as
  /// floating on a phone.
  static const inset = EdgeInsets.only(right: 16, bottom: 16);

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: SafeArea(
          top: false,
          left: false,
          bottom: safeBottom,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: inset.copyWith(right: right, bottom: bottom),
              child: PixelRainLoadingLabel(size: size, label: label),
            ),
          ),
        ),
      );
}
