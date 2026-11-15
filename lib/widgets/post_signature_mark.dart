import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// The post card's time segment with the signature mark. The mark flags
/// posts that are NOT signed, to encourage signed posts.
///
/// Negative differentiator: a verified signature shows nothing, an UNSIGNED
/// post gets an amber `!` right of the time, a BAD signature a red one. No
/// crypto runs here: `PostSignatureVerifier.quickState` answers "unsigned"
/// from the fields alone, and `verdictOf` is Core's once-per-instance,
/// off-thread check for signed posts (verify at arrival, display after).
///
/// Tap → a dialog that explains the three states and names this post's.
/// Long-press → on a verified post, the author's name shimmers once in
/// rainbow (the Easter egg, see [SignedAuthorName]); on the others, the same
/// dialog.
///
/// ONE mark per card: when the post's server is not a
/// registered SSP, [PostServerMark] shows on the feed-context line and this
/// `!` stays hidden; the server dialog then explains both. Until the server
/// verdict settles the `!` waits too, so it never flashes and goes.
class PostSignatureMark extends StatelessWidget {
  final Post post;

  /// The time text.
  final Widget child;

  const PostSignatureMark({
    super.key,
    required this.post,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final serverUrl = postServerUrlOf(post);
    final known = PublicOSSsp.sspRegistrationIfKnown(serverUrl);
    if (known != null) return _withServer(context, known);
    return FutureBuilder<SspRegistration>(
      future: PublicOSSsp.sspRegistrationOf(serverUrl),
      // null = still deciding: the `!` waits (see the class doc).
      builder: (context, snap) => _withServer(context, snap.data),
    );
  }

  Widget _withServer(BuildContext context, SspRegistration? server) {
    // The server's amber `!` stands in for this one's amber (one mark per
    // card); a RED mark is never hidden: a bad signature always wins.
    final serverHidesAmber =
        server == null || server == SspRegistration.unregistered;
    if (PostSignatureVerifier.quickState(post) == PostSignatureState.unsigned) {
      return _row(context, PostSignatureState.unsigned,
          serverHidesAmber: serverHidesAmber);
    }
    return FutureBuilder<PostVerificationResult>(
      future: PostSignatureVerifier.verdictOf(post),
      builder: (context, snap) => _row(
        context,
        snap.data?.state,
        serverHidesAmber: serverHidesAmber,
        chainUnavailable: snap.data?.chainUnavailable ?? false,
      ),
    );
  }

  /// Red for a bad signature, always. Amber for an unsigned post and for a
  /// signed one the chain could not vouch for ([chainUnavailable]: not
  /// checked, not bad); the server's own amber mark hides those two.
  Widget _row(
    BuildContext context,
    PostSignatureState? state, {
    required bool serverHidesAmber,
    bool chainUnavailable = false,
  }) {
    final tokens = GlassTokens.of(context);
    final isBad = state == PostSignatureState.bad && !chainUnavailable;
    final Color? markColor = switch (state) {
      PostSignatureState.bad when !chainUnavailable =>
        Theme.of(context).colorScheme.error,
      PostSignatureState.bad || PostSignatureState.unsigned =>
        serverHidesAmber ? null : tokens.fallbackAccent,
      _ => null,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPostSignatureDialog(context, state,
          chainUnavailable: chainUnavailable),
      onLongPress: () {
        if (state == PostSignatureState.checked) {
          playSignatureShimmer(post);
        } else {
          showPostSignatureDialog(context, state,
              chainUnavailable: chainUnavailable);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (markColor != null) ...[
            const SizedBox(width: 5),
            Semantics(
              label: isBad
                  ? context.l10n.postSigMarkBad
                  : chainUnavailable
                      ? context.l10n.postSigMarkUnchecked
                      : context.l10n.postSigMarkUnsigned,
              child: Text(
                '!',
                style: TextStyle(
                  color: markColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The three states, explained; this post's row is the lit one. A null
/// [state] is a signed post still being checked: it reads as signed. A bad
/// verdict with [chainUnavailable] is a fourth situation, "not checked":
/// the signature holds on this device but the chain could not say whose key
/// it is, so the dialog says so instead of calling the post bad.
Future<void> showPostSignatureDialog(
  BuildContext context,
  PostSignatureState? state, {
  bool chainUnavailable = false,
}) {
  final tokens = GlassTokens.of(context);
  final l10n = context.l10n;
  final s = state ?? PostSignatureState.checked;
  final unchecked = s == PostSignatureState.bad && chainUnavailable;
  final error = Theme.of(context).colorScheme.error;
  final (Color accent, IconData icon, String title) = unchecked
      ? (
          tokens.fallbackAccent,
          Icons.cloud_off_rounded,
          l10n.postSigTitleUnchecked,
        )
      : switch (s) {
          PostSignatureState.unsigned => (
              tokens.fallbackAccent,
              Icons.edit_off_rounded,
              l10n.postSigTitleUnsigned,
            ),
          PostSignatureState.bad => (
              error,
              Icons.warning_amber_rounded,
              l10n.postSigTitleBad,
            ),
          PostSignatureState.checked => (
              tokens.connectedAccent,
              Icons.verified_rounded,
              l10n.postSigTitleChecked,
            ),
        };

  Widget row(PostSignatureState? rowState, Widget glyph, String text) {
    final current = unchecked ? rowState == null : rowState == s;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Center(child: glyph)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              current ? '$text  ${l10n.postSigThisPost}' : text,
              style: TextStyle(
                color: current ? tokens.starkWhite : tokens.textDim,
                fontSize: 13,
                height: 1.35,
                fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bang(Color c) => Text(
        '!',
        style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w900),
      );

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(
        minWidth: DialogWidth.min,
        maxWidth: DialogWidth.s,
      ),
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      title: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(
            PostSignatureState.checked,
            Icon(Icons.check_rounded, color: tokens.connectedAccent, size: 16),
            l10n.postSigExplainChecked,
          ),
          row(
            PostSignatureState.unsigned,
            bang(tokens.fallbackAccent),
            l10n.postSigExplainUnsigned,
          ),
          row(PostSignatureState.bad, bang(error), l10n.postSigExplainBad),
          if (unchecked)
            row(
              null,
              Icon(Icons.cloud_off_rounded,
                  color: tokens.fallbackAccent, size: 16),
              l10n.postSigExplainUnchecked,
            ),
          const SizedBox(height: 10),
          Text(
            l10n.postSigEncourage,
            style: TextStyle(color: tokens.textDim, fontSize: 12, height: 1.35),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.postSigDialogClose),
        ),
      ],
    ),
  );
}

/// The URL that names the server a post is served from: the feed's own URL,
/// else the post's permalink. Both live on the SSP (or the outside server)
/// that serves the feed; `PublicOSSsp.canonicalSspUrlOf` reduces either to
/// `scheme://host[:port]`.
String postServerUrlOf(Post post) => post.feedUrl ?? post.url ?? '';

/// The second negative mark: an
/// amber `!` right of the feed-context line when the post's server is NOT a
/// registered SSP (Core's `sspRegistrationOf`: one chain read per server,
/// cached 7 days). A registered server, or a chain that could not say, shows
/// nothing. [child] is the feed-context line; with none, the `!` stands
/// alone on its row. Tap → [showPostServerDialog], which explains the server
/// and, when the post is unsigned too, the missing signature: one mark, one
/// dialog (the signature `!` hides when this one shows).
class PostServerMark extends StatelessWidget {
  final Post post;
  final Widget? child;

  const PostServerMark({super.key, required this.post, this.child});

  @override
  Widget build(BuildContext context) {
    final serverUrl = postServerUrlOf(post);
    final known = PublicOSSsp.sspRegistrationIfKnown(serverUrl);
    if (known != null) return _row(context, known);
    return FutureBuilder<SspRegistration>(
      future: PublicOSSsp.sspRegistrationOf(serverUrl),
      builder: (context, snap) =>
          _row(context, snap.data ?? SspRegistration.unknown),
    );
  }

  Widget _row(BuildContext context, SspRegistration server) {
    if (server != SspRegistration.unregistered) {
      return child ?? const SizedBox.shrink();
    }
    final tokens = GlassTokens.of(context);
    final mark = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showPostServerDialog(context, post),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          label: context.l10n.postSrvMark,
          child: Text(
            '!',
            style: TextStyle(
              color: tokens.fallbackAccent,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
    if (child == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Align(alignment: Alignment.centerLeft, child: mark),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Flexible(child: child!), mark],
    );
  }
}

/// The server dialog: a server that follows the feed protocol on its own,
/// on the open internet, not within the PublicOS network (the wording must
/// not make it sound rogue); plus the missing signature, in one line, when
/// the post is unsigned as well.
Future<void> showPostServerDialog(BuildContext context, Post post) {
  final tokens = GlassTokens.of(context);
  final l10n = context.l10n;
  final accent = tokens.fallbackAccent;
  final unsigned =
      PostSignatureVerifier.quickState(post) == PostSignatureState.unsigned;

  Widget row(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(
        minWidth: DialogWidth.min,
        maxWidth: DialogWidth.s,
      ),
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      title: Row(
        children: [
          Icon(Icons.public_rounded, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.postSrvTitle,
              style: TextStyle(
                color: accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(l10n.postSrvExplainServer),
          if (unsigned) row(l10n.postSrvExplainUnsigned),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.postSigDialogClose),
        ),
      ],
    ),
  );
}

/// The Easter egg: a long-press
/// on a verified post makes the author's name shimmer once in rainbow, in
/// place, then it is plain again. Nothing covers the card, no extra font.
///
/// The card calls [playSignatureShimmer] with the post; every
/// [SignedAuthorName] showing that same `Post` instance plays. The signal is
/// memoised per instance (an `Expando`, like Core's verdict), so the card's
/// build functions carry nothing extra.
void playSignatureShimmer(Post post) => _signalOf(post).play();

final Expando<_ShimmerSignal> _signals = Expando('signatureShimmer');
_ShimmerSignal _signalOf(Post post) => _signals[post] ??= _ShimmerSignal();

class _ShimmerSignal extends ChangeNotifier {
  void play() => notifyListeners();
}

const List<Color> _rainbow = [
  Color(0xFFFF5F6D),
  Color(0xFFFFC371),
  Color(0xFFF9F871),
  Color(0xFF7CF29C),
  Color(0xFF5AD1FF),
  Color(0xFFA77BFF),
];

/// Reader setting: whether a verified author's name shimmers on
/// its own, and how often (every 4 to 10 seconds). The `TranslationPrefs` shape — generic settings
/// plus a static cache — and [changes], so names already on screen re-arm
/// when the settings sheet moves a value.
class SignatureShimmerPrefs {
  SignatureShimmerPrefs._();

  static const String kEnabledKey = 'signature_shimmer_enabled';
  static const String kSecondsKey = 'signature_shimmer_seconds';
  static const int minSeconds = 4;
  static const int maxSeconds = 10;
  static const int defaultSeconds = 6;

  static bool? _enabledCache;
  static int? _secondsCache;

  /// Bumps whenever a value changes; every [SignedAuthorName] listens.
  static final ChangeNotifier changes = _PrefsNotifier();

  /// Default true: a verified name shines on its own.
  static Future<bool> isEnabled() async {
    if (_enabledCache != null) return _enabledCache!;
    try {
      final r = await PublicOSSettings.getSetting(kEnabledKey);
      final v = r?.value;
      _enabledCache = v == null ? true : v == 'true';
    } catch (_) {
      _enabledCache = true;
    }
    return _enabledCache!;
  }

  static Future<void> setEnabled(bool value) async {
    _enabledCache = value;
    (changes as _PrefsNotifier).bump();
    try {
      await PublicOSSettings.setSetting(
        kEnabledKey,
        Record.asSettings(
          key: kEnabledKey,
          value: value ? 'true' : 'false',
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 365)),
        ),
      );
    } catch (_) {}
  }

  /// Seconds between shines, [minSeconds]..[maxSeconds], default 6.
  static Future<int> seconds() async {
    if (_secondsCache != null) return _secondsCache!;
    try {
      final r = await PublicOSSettings.getSetting(kSecondsKey);
      final v = int.tryParse(r?.value ?? '');
      _secondsCache = (v ?? defaultSeconds).clamp(minSeconds, maxSeconds);
    } catch (_) {
      _secondsCache = defaultSeconds;
    }
    return _secondsCache!;
  }

  static Future<void> setSeconds(int value) async {
    final v = value.clamp(minSeconds, maxSeconds);
    _secondsCache = v;
    (changes as _PrefsNotifier).bump();
    try {
      await PublicOSSettings.setSetting(
        kSecondsKey,
        Record.asSettings(
          key: kSecondsKey,
          value: '$v',
          isSystem: true,
          expiration: DateTime.now().add(const Duration(days: 365)),
        ),
      );
    } catch (_) {}
  }
}

class _PrefsNotifier extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// The author's name on a post card. Idle it is the plain [Text]; when its
/// post's signature shimmer plays, a rainbow band sweeps through the glyphs
/// once (1.8 s, eased), the colour outside the band staying the style's own,
/// so the name never leaves its place or changes size.
///
/// A verified name also shines on its own: once Core's
/// memoised verdict says `checked` and [SignatureShimmerPrefs] is on, a
/// timer replays the band every N seconds, phased per name so a column of
/// verified posts doesn't flash in unison. No haptic on those; the hold on
/// the `!` mark keeps its light tap.
class SignedAuthorName extends StatefulWidget {
  final Post post;
  final String name;
  final TextStyle style;

  const SignedAuthorName({
    super.key,
    required this.post,
    required this.name,
    required this.style,
  });

  @override
  State<SignedAuthorName> createState() => _SignedAuthorNameState();
}

class _SignedAuthorNameState extends State<SignedAuthorName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _c.reset();
        setState(() {});
      }
    });
  _ShimmerSignal? _signal;
  Timer? _loop;

  @override
  void initState() {
    super.initState();
    _listen();
    SignatureShimmerPrefs.changes.addListener(_arm);
    _arm();
  }

  @override
  void didUpdateWidget(SignedAuthorName old) {
    super.didUpdateWidget(old);
    if (!identical(old.post, widget.post)) {
      _listen();
      _arm();
    }
  }

  /// The self-playing shine. Re-armed when the post changes or the setting
  /// moves; cancelled on dispose, so an off-screen card costs nothing.
  Future<void> _arm() async {
    _loop?.cancel();
    _loop = null;
    final post = widget.post;
    if (PostSignatureVerifier.quickState(post) == PostSignatureState.unsigned) {
      return;
    }
    final verdict = await PostSignatureVerifier.verdictOf(post);
    if (!mounted || !identical(post, widget.post)) return;
    if (verdict.state != PostSignatureState.checked) return;
    if (!await SignatureShimmerPrefs.isEnabled()) return;
    final every = await SignatureShimmerPrefs.seconds();
    if (!mounted || !identical(post, widget.post)) return;
    final phase = widget.name.hashCode.abs() % (every * 1000);
    _loop = Timer(Duration(milliseconds: phase), () {
      if (!mounted) return;
      _shine();
      _loop = Timer.periodic(Duration(seconds: every), (_) => _shine());
    });
  }

  void _shine() {
    if (!mounted || _c.isAnimating) return;
    _c.forward(from: 0);
    setState(() {});
  }

  void _listen() {
    _signal?.removeListener(_play);
    _signal = _signalOf(widget.post)..addListener(_play);
  }

  void _play() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    _c.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _loop?.cancel();
    SignatureShimmerPrefs.changes.removeListener(_arm);
    _signal?.removeListener(_play);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Text(
      widget.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
    if (!_c.isAnimating) return text;
    final base = widget.style.color ?? Colors.white;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            // A band 1.4x the name wide travels from fully left of the
            // glyphs to fully right of them; clamped edges keep the base
            // colour everywhere the band is not.
            final band = bounds.width * 1.4;
            final left = -band + t * (bounds.width + band);
            return LinearGradient(colors: [base, ..._rainbow, base])
                .createShader(Rect.fromLTWH(left, 0, band, bounds.height));
          },
          child: child,
        );
      },
      child: text,
    );
  }
}
