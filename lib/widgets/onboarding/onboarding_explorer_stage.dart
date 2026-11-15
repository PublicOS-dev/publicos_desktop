/// The doing-tour's inbox stage — a **mock** Messages tab that exists only to
/// be coached over.
///
/// ## Why a mock and not the live explorer
///
/// Running the coach sequence over the real explorer needs the tour to step
/// aside and come back, and it leaves every real control one mistap away
/// from carrying the user off into the app mid-lesson. **A stage has no
/// navigation because none is wired**, so there is no bug to find: the only
/// reachable thing on the screen is the control the spotlight is on.
///
/// ## What is real here, and what is paint
///
/// | | |
/// |---|---|
/// | the account icon + name | **real** — `AppStateNotifier.currentMyContact` |
/// | the keychain chip | **real `ExplorerChip`**, with the same arguments the live `MessagesChipBar` passes when no key is loaded |
/// | the keychain it opens | **real keychain dialog** (`showKeychainDialog`), in `tour` mode |
/// | the register dialog | **real** — the sheet fires it itself |
/// | chain + SSP indicators | painted green, unconditionally |
/// | search field | inert — a shape, no controller behaviour |
/// | the message list | permanently the no-keys empty state |
///
/// The split is deliberate: everything the user is being taught to *do* is the
/// real control doing the real thing, and everything that is only scenery is
/// scenery. Nothing here fakes an action.
///
/// The chip is drawn directly rather than by handing `currentKeyLabel: null` to
/// the real `MessagesChipBar` (which does collapse to exactly this one chip)
/// because the spotlight has to measure the **chip**, and the bar builds its
/// children internally where no key can reach them. Same primitive, same
/// arguments, one rect we can point at.
library;

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/keychain_dialog.dart';
import 'package:publicos_desktop/widgets/onboarding/onboarding_coach.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Runs the four-beat inbox sequence and pops with the result.
///
/// Returns **true** when the account ends the sequence with an inbox published
/// on chain, **false** otherwise. The caller re-reads chain state either way —
/// this bool decides what to *say*, never what is true.
class OnboardingExplorerStage extends StatefulWidget {
  const OnboardingExplorerStage({super.key});

  @override
  State<OnboardingExplorerStage> createState() =>
      _OnboardingExplorerStageState();
}

class _OnboardingExplorerStageState extends State<OnboardingExplorerStage> {
  final CoachController _coach = CoachController();

  final GlobalKey _chipKey = GlobalKey();
  final GlobalKey _generateKey = GlobalKey();
  final GlobalKey _simKey = GlobalKey();

  /// Set once the sequence has seen a registered inbox. Read on the way out.
  bool _published = false;

  @override
  void initState() {
    super.initState();
    // The chip has to be laid out before it can be measured.
    WidgetsBinding.instance.addPostFrameCallback((_) => _beatOne());
  }

  @override
  void dispose() {
    _coach.dispose();
    super.dispose();
  }

  void _beatOne() {
    if (!mounted) return;
    _coach.show(
      context,
      CoachMark(
        targetKey: _chipKey,
        text: context.l10n.onbCoachKeychain,
        side: CoachSide.below,
      ),
    );
  }

  /// Beats 2 and 3 live inside the sheet, so they are driven from here while it
  /// is open: the spotlight moves from GENERATE to the SIM the moment a key
  /// exists to point at.
  ///
  /// The sheet is opened as an ordinary modal route — the coach floats above it
  /// from the root overlay. Hosting the sheet inside this page's own `Stack`
  /// would put the spotlight in reach but break `KeychainSheet`'s
  /// `Navigator.pop`, which would then close **this** route instead.
  Future<void> _openKeychain() async {
    // **Resume by state, not from the top.** A second walk through the flow —
    // after declining the register dialog, or after leaving mid-way — must not
    // ask for another key: the user ends up with a keychain full of keys they
    // did not want, and the beat they actually need is the one after. Beat 2
    // is skipped whenever a key already exists, which is the same
    // "each step's done is observable" rule the tour's own gates follow.
    var hasKeys = false;
    final addr = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    if (addr != null) {
      try {
        hasKeys = (await PublicOSKeychain.fetchKeys(addr)).isNotEmpty;
      } catch (_) {
        // Unreadable — start from the top. An extra beat is cheaper than a
        // sequence that skips the only step this flow exists for.
      }
    }
    if (!mounted) return;

    _coach.show(
      context,
      hasKeys
          ? CoachMark(
              targetKey: _simKey,
              text: context.l10n.onbCoachSim,
              side: CoachSide.above,
            )
          : CoachMark(
              targetKey: _generateKey,
              text: context.l10n.onbCoachGenerate,
              side: CoachSide.above,
            ),
    );

    // DESKTOP DELTA: the keychain is a dialog here, not a bottom sheet; the
    // coach measures the target's own route, so it stacks the same way.
    await showKeychainDialog(
        context,
        myContact: AppStateNotifier.currentMyContact,
        onboardingMode: KeychainOnboardingMode.tour,
        tourGenerateKey: _generateKey,
        tourSimKey: _simKey,
        // Fires once the key exists — which is exactly when beat 2 finishes,
        // because generating is the only way to change the list in `tour`
        // mode. Advancing on the RESULT rather than on the tap is the same
        // rule the tour's own gates follow.
        //
        // ⚠ `_generateNewKey` must call this (as wallet-toggle, web-key-set
        // and emoji edits do). Beat 3 depends on it, so if that call goes
        // away the spotlight silently never reaches the SIM.
        onKeysChanged: _onKeysChanged,
    );

    if (!mounted) return;
    // The sheet is gone; its controls cannot be spotlighted any more.
    _coach.hide();
    await _resolve();
  }

  void _onKeysChanged() {
    if (!mounted) return;
    // Beat 3: the key now exists, so point at its SIM. Deferred a frame — the
    // row is built by the rebuild this callback precedes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_coach.isShowing) return;
      _coach.show(
        context,
        CoachMark(
          targetKey: _simKey,
          text: context.l10n.onbCoachSim,
          side: CoachSide.above,
        ),
      );
    });
  }

  /// Ask the chain whether the sequence actually landed, and leave.
  ///
  /// Beat 4 is the sheet's own register dialog, so there is nothing here to
  /// coach — only to verify. `getAllAccountInboxIds` is the account-scoped
  /// question and returns **null** on a failed read, which is left as *not
  /// published*: the page this returns to re-reads chain state itself and is
  /// written to fail open, so a bad read here costs nothing.
  Future<void> _resolve() async {
    final addr = AppStateNotifier.currentMyContact?.publicosAddress;
    if (addr != null) {
      try {
        final all = await PublicOSXmtp.getAllAccountInboxIds(addr);
        _published = (all?.inboxIds.isNotEmpty) ?? false;
      } catch (_) {
        _published = false;
      }
    }
    if (mounted) Navigator.of(context).pop(_published);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // No `AppBar`, no `BottomNavigationBar`, no back button: the only way off
    // this screen is finishing the sequence.
    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          children: [
            _StageAppBar(tokens: tokens),
            _StageSearchField(tokens: tokens),
            ExplorerChipBar(
              children: [
                // The live bar's no-key chip, argument for argument
                // (`messages_chip_bar.dart` — label, key glyph, inactive, in
                // the fallback accent because it is the one call to action).
                ExplorerChip(
                  key: _chipKey,
                  label: context.l10n.messagesChipBarNoKey,
                  icon: Icons.vpn_key_rounded,
                  active: false,
                  accentColor: tokens.fallbackAccent,
                  onTap: _openKeychain,
                ),
              ],
            ),
            Expanded(child: _StageEmptyState(tokens: tokens)),
          ],
        ),
      ),
    );
  }
}

/// The explorer's app bar, minus everything that navigates.
///
/// The account icon and name are read live — this is the user's own face, and a
/// placeholder here would undercut the one screen whose subject is *your*
/// identity. The two status glyphs are painted `connectedAccent` outright: the
/// stage is not connected to anything, and a red dot on a teaching screen reads
/// as a problem the user has to solve before continuing.
class _StageAppBar extends StatelessWidget {
  final GlassTokens tokens;

  const _StageAppBar({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: tokens.background.withValues(alpha: 0.95),
      height: kToolbarHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: AppStateNotifier.instance!,
                builder: (context, _) {
                  final me = AppStateNotifier.currentMyContact;
                  return Row(
                    children: [
                      GlassContactIcon(
                        contact: me,
                        address: me?.publicosAddress?.eip55With0x ?? '',
                        size: 40,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          me?.publicosDisplayName ?? me?.displayName ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tokens.starkWhite,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Icon(Icons.link_rounded, size: 20, color: tokens.connectedAccent),
            const SizedBox(width: 8),
            Icon(Icons.cloud_outlined,
                size: 20, color: tokens.connectedAccent),
          ],
        ),
      ),
    );
  }
}

/// The search field as a shape. No controller, no callbacks, not focusable —
/// a `TextField` here would take the keyboard on first tap and shove the whole
/// stage up under the coach bubble.
class _StageSearchField extends StatelessWidget {
  final GlassTokens tokens;

  const _StageSearchField({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 18, color: tokens.textDim),
            const SizedBox(width: 10),
            Text(
              context.l10n.messagesViewSearchHint,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The messages tab's own no-keys state, reproduced — including the line that
/// names the SIM icon, which is the very beat the sequence is about to teach.
class _StageEmptyState extends StatelessWidget {
  final GlassTokens tokens;

  const _StageEmptyState({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: tokens.textDim),
            const SizedBox(height: 24),
            Text(
              context.l10n.messagesViewNoKeysTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: context.l10n.messagesViewNoKeysSubtitleBefore),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(Icons.sim_card_outlined,
                        size: 15, color: tokens.starkWhite),
                  ),
                  TextSpan(text: context.l10n.messagesViewNoKeysSubtitleAfter),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
