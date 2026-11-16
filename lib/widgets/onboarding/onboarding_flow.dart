import 'dart:convert';
import 'package:publicos_desktop/widgets/contact_banner.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/constellation_background.dart';
import 'package:publicos_desktop/widgets/citizenship_claim_sheet.dart';
import 'package:publicos_desktop/widgets/domain_store_sheet.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/network_access_sheets.dart';
import 'package:publicos_desktop/widgets/server_rules_sheet.dart';
import 'package:publicos_desktop/widgets/nft_image.dart';
import 'package:publicos_desktop/widgets/onboarding/onboarding_explorer_stage.dart';
import 'package:publicos_desktop/widgets/phigital_bottom_sheet.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/pixel_confetti.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/profile/content_card.dart';
import 'package:publicos_desktop/widgets/profile/profile_grid.dart';
import 'package:publicos_desktop/widgets/profile/tab_icon_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';

// ════════════════════════════════════════════════════════════════════════════
//  THE DOING-TOUR ONBOARDING
//
//  THE onboarding: `explorer.dart` renders this in place of the shell
//  whenever `onboarding_completed` is unset, and App Settings →
//  "Watch onboarding" replays it in `previewMode`. A guided "build your
//  account" flow.
//
//  Built in the app's glass-dark style.
//
//  THE TEN STEPS — `enum _Step` is display order; the names are historical
//  (`yours` is S3 the inbox, and it comes BEFORE S4b/S4d/S4c so the card
//  fill can write a "text me" card):
//    S0  publicOs   PublicOS            — the intro
//    S1  domain     Your Domain         — skipped when the domain is compliant
//    S2  account    An account          — the org's card; must open its tabs
//    S3  yours      A way in            — the coached inbox stage; must land
//    S4b profile    Your account        — the bio; must choose one
//    S4d gift       the citizen kit     — citizens who have not minted, only
//    S4c cards      Your cards          — the prefill block + optional shuffle
//    S5  tabs       More tabs           — catalogue, copy only
//    S6  providers  Network access      — BSP + SSP, the only step that spends
//    S7  outro                          — where `_finish` lives
//
//  There is deliberately NO SKIP link: a top-right SKIP lets people bail
//  out of every setup. Its absence is the point, not an oversight.
// ════════════════════════════════════════════════════════════════════════════

// ── Page copy ───────────────────────────────────────────────────────────────
// Every user-facing word lives here, in reading order. Widgets below are
// layout only.

// S0 · PublicOS (intro): the pulsing Phigital logo lockup + title/body.
_TextPageCopy _s0PublicOs(AppLocalizations l) => _TextPageCopy(
      title: l.onbPublicosTitle,
      // No subtitle on any page — it would restate what the page already
      // shows. The `onb*Subtitle` strings are still in both .arb files,
      // unused.
      body: l.onbPublicosBody,
    );

// S1 · Your Domain. Card above, text below; the page carries a real action
// rather than being a slide in an explainer run.
String _s1Domain(AppLocalizations l, _DomainClass c) => switch (c) {
      _DomainClass.citizen => l.onbDomainBodyCitizen,
      _DomainClass.paidPrivate => l.onbDomainBodyPaid,
      _DomainClass.lapsedPrivate => l.onbDomainBodyRent,
      _DomainClass.unknown => l.onbMorphDomainBody,
    };

// S2 · This is an account. Shown on the PublicOS org card, not the user's own:
// the point is to look at a real, populated account before being asked to
// build one.
String _s2Account(AppLocalizations l) => l.onbAccountBody;

// S4b · This one is yours. Deliberately the SAME layout as S1/S2 — after two
// screens of "an account looks like this", the user's own card in the same
// frame reads as "…and this one is mine".
//
// It, not S3, carries the "you already have a name and an address" reveal;
// putting that line on both would fire the same reveal twice.
String _s4bProfile(AppLocalizations l) => l.onbProfileBody;

// S4d · A gift for citizens. Sits between the bio and the cards, and is a
// MINTING PAGE and nothing else — it writes no records and changes no profile.
// The profile has already been dressed in the free kit by S4b's fill, which is
// deliberate: someone who abandons the tour right here still leaves with a
// finished-looking profile, and the citizen tier is offered ON TOP of that
// rather than instead of it.
String _s4dGift(AppLocalizations l) => l.onbGiftBody;

// S4c · The profile cards. A page of its own so the bio page can be about
// the bio and nothing else: an account card, a nine-tile kit block, body
// copy AND a bio picker on one screen crowd out the bio — the only thing
// that page actually asks the user FOR.
String _s4cCards(AppLocalizations l) => l.onbCardsBody;

// S5 · What else a tab can be. **Show only — nothing on this page writes.**
// Its job is to name the surface these are added from, so the tour ends with
// the user knowing where to go rather than with one more thing to do.
String _s5Tabs(AppLocalizations l) => l.onbTabsBody;

// S3 · The inbox. Everything about identity has already been said by S4b, so
// this page has exactly one job left: there is still no way to reach you.
/// S0's copy. **The only page with a heading** — every other page has no
/// title, icon or hairline and announces itself through the `**bold**`
/// keyword in its body instead.
class _TextPageCopy {
  final String title;
  final String body;

  const _TextPageCopy({
    required this.title,
    required this.body,
  });
}

/// Identifies a step independently of its index, so the conditional flow can
/// drop steps without any page's behaviour depending on where it landed.
/// Which of the three things S1 has to tell the user they are.
///
/// **One derivation, two consumers.** The body copy and the status legend
/// below it both describe the same fact, and deriving it twice is how two
/// lines on one screen end up disagreeing — the page saying "already paid for"
/// over a legend reading "pay the domain fee". They both switch on this.
enum _DomainClass {
  /// Read failed, or not back yet. Says what a domain IS and nothing about
  /// this account — a page that guesses here would guess wrong out loud.
  unknown,

  /// The year-3000 sentinel: free for life.
  citizen,

  /// Private, covered until a date.
  paidPrivate,

  /// Private, lapsed or never paid — the only branch with something to do.
  lapsedPrivate,
}

/// Everything the tour knows about the account, from the chain.
///
/// **One object, one reader, one rule.** Facts spread over loose fields with
/// different refresh habits force every writer to patch its own fact by hand
/// and invent its own way to confirm the write. The worst form is reading
/// `isMinted` on the line after sending, before the transaction is mined,
/// which reports a failure about a mint that in fact succeeded.
///
/// The rule:
///
/// > A chain fact is read by exactly one function. Any write that could change
/// > one awaits its receipt and then re-runs that function. **No writer ever
/// > sets a fact by hand.**
///
/// Every field is TRI-STATE and null means *not known*, never *no*. The two
/// directions matter for different reasons: an unknown must never mint (a
/// transaction nobody asked for), and must never read as *already minted*
/// either (a citizen silently loses their gift).
class _ChainState {
  /// Domain paid-until, the raw timestamp behind [domainClass].
  final BigInt? domainPaidUntil;

  /// The post-lapse grace window, for the S1 legend.
  final BigInt? domainGrace;

  /// Whether the domain is currently compliant.
  final bool? domainCompliant;

  /// Whether the account holds citizenship. **Not the same fact as a lifetime
  /// domain** — root can stamp the `NEVER` sentinel on a private account, and a
  /// freshly-citizenized account is a citizen before the domain sync catches
  /// up. `CitizenKit.mint` gates on this one.
  final bool? isCitizen;

  /// Whether the citizen kit exists, from `CitizenKit.isMinted` — a view, so
  /// this is an answer rather than a caught revert.
  final bool? citizenKitMinted;

  /// Vouches received and today's threshold, read for a PRIVATE only: the
  /// pair that decides whether the claim sheet is offered.
  final BigInt? vouchCount;
  final BigInt? vouchThreshold;

  /// How many inbox IDs this ACCOUNT publishes on chain.
  ///
  /// Read with `getAllAccountInboxIds`, which is the account-scoped question
  /// **and** returns `null` on a failed read, so *unknown* survives as null
  /// instead of collapsing into zero. `accountInboxIdExists` cannot be used
  /// here: despite its name and its dartdoc it is a **global** lookup
  /// (`XmtpMemory.inboxIdToAccountAddress[id] != 0`), so it answers "is this
  /// inbox registered to *anybody*" and returns `false` on error besides.
  ///
  /// Deliberately about the account and not the device. Whether a key is
  /// activated *here* is a fact about a phone; whether an inbox is published is
  /// a fact about an identity, and only the second one decides what S3 has left
  /// to teach.
  final int? registeredInboxCount;

  /// The labels of those inboxes, from the same read — what the prefill's
  /// "text me" card links to (`/chat/<label>`). Null when the read failed.
  final List<String>? inboxLabels;

  /// The provider slug this account is assigned on each axis — `''` for none,
  /// **null for unknown**. Read off `SubsMemory.slugOf(axis, a)`.
  final String? bspAssigned;
  final String? sspAssigned;

  /// Whether each service is live right now, as the contract itself says —
  /// `SubsManager.isActive(axis, a)`, the one predicate every consumer uses
  /// (the SSP gate, Quests, this page). It folds in the assignment, the
  /// provider still existing, the balance past an open gate, dormancy and
  /// blocks, so nothing here re-derives it. null = the read did not land.
  final bool? bspLive;
  final bool? sspLive;

  /// `SubsManager.coveredUntil(a)`: ONE clock for both services,
  /// because one balance pays both. Private: when the balance runs out at
  /// today's rate, or dormancy if sooner. Citizen: dormancy only. 0 = never
  /// subscribed.
  final BigInt? coveredUntil;

  const _ChainState({
    this.domainPaidUntil,
    this.domainGrace,
    this.domainCompliant,
    this.isCitizen,
    this.citizenKitMinted,
    this.vouchCount,
    this.vouchThreshold,
    this.registeredInboxCount,
    this.inboxLabels,
    this.bspAssigned,
    this.sspAssigned,
    this.bspLive,
    this.sspLive,
    this.coveredUntil,
  });

  static const empty = _ChainState();

  /// Merge a fresh read over the old one, **keeping what the new read could not
  /// answer**. A failed sub-read must not erase a fact already known — that is
  /// how a working page goes blank on one bad round trip.
  _ChainState merge(_ChainState next) => _ChainState(
        domainPaidUntil: next.domainPaidUntil ?? domainPaidUntil,
        domainGrace: next.domainGrace ?? domainGrace,
        domainCompliant: next.domainCompliant ?? domainCompliant,
        isCitizen: next.isCitizen ?? isCitizen,
        citizenKitMinted: next.citizenKitMinted ?? citizenKitMinted,
        vouchCount: next.vouchCount ?? vouchCount,
        vouchThreshold: next.vouchThreshold ?? vouchThreshold,
        registeredInboxCount: next.registeredInboxCount ?? registeredInboxCount,
        inboxLabels: next.inboxLabels ?? inboxLabels,
        bspAssigned: next.bspAssigned ?? bspAssigned,
        sspAssigned: next.sspAssigned ?? sspAssigned,
        bspLive: next.bspLive ?? bspLive,
        sspLive: next.sspLive ?? sspLive,
        coveredUntil: next.coveredUntil ?? coveredUntil,
      );

  /// Whether each service is **live right now** — tri-state, null unknown.
  ///
  /// ⚠ **The contract's answer, never the slug.** A lapse never clears the
  /// assignment on chain, so an account whose balance ran out months ago still
  /// reports a provider. A page that tested the slug would greet them with
  /// *"you already have services"* and send them into `SSP_EXPIRED` on their
  /// first post. `isActive` is what the SSP gate asks, so it is what this page
  /// asks.
  bool? get bspActive => bspLive;
  bool? get sspActive => sspLive;

  /// Whether this account already publishes an inbox — **tri-state**, and the
  /// null matters more here than anywhere else in this class.
  ///
  /// S3 treats *unknown* as *yes*: a failed view call must not march someone
  /// who already has an inbox through a four-beat coach sequence to publish a
  /// second one they never asked for. This deliberately **inverts S1's rule**,
  /// where an unknown domain means the full tour — there, failing open buys
  /// more teaching; here it would buy pure friction. The gate exists to stop
  /// people skipping a setup they have not done, and has no business firing at
  /// someone who may well have done it.
  bool? get hasRegisteredInbox {
    final n = registeredInboxCount;
    return n == null ? null : n > 0;
  }

  /// Which of the three things S1 has to tell the user they are.
  _DomainClass get domainClass {
    final paid = domainPaidUntil;
    if (paid == null || paid == BigInt.zero) return _DomainClass.unknown;
    if (paid > _kDomainNeverSentinel) return _DomainClass.citizen;
    if (domainCompliant == true) return _DomainClass.paidPrivate;
    if (domainCompliant == false) return _DomainClass.lapsedPrivate;
    return _DomainClass.unknown;
  }

  /// S4d is for a citizen who does not yet hold their kit, and nobody else.
  /// **Only a confirmed pair opens it** — an unresolved read offers no mint,
  /// because a missed gift is recoverable on the next run while an offered
  /// mint that reverts is a dead end the user cannot interpret.
  bool get showGift => isCitizen == true && citizenKitMinted == false;

  /// A confirmed private with enough vouches for TODAY's threshold: what
  /// `VouchManager.onClaim` will say yes to.
  bool get citizenshipEligible =>
      isCitizen == false &&
      vouchCount != null &&
      vouchThreshold != null &&
      vouchCount! >= vouchThreshold!;

  /// The theme toggle needs the kit actually in hand. Gated on the mint itself
  /// rather than on having walked through the gift page, so there is no path
  /// that reaches a citizen theme without owning it.
  bool get canToggleTheme => isCitizen == true && citizenKitMinted == true;
}

/// ~year-3000 sentinel: a free-tier citizen (5+ char name) or a seeded root
/// holds the domain forever. Mirrors the Domain Store's lifetime check.
final BigInt _kDomainNeverSentinel = BigInt.from(32503680000 - 1);

enum _Step {
  publicOs,
  domain,
  account,
  // S3 sits BEFORE the profile steps:
  // the card fill on S4b writes a "text me" card only when the chain confirms
  // an inbox, so the inbox has to exist first.
  yours,
  profile,
  gift,
  cards,
  tabs,
  providers,
  outro,
}

/// What S6 is doing right now. Derived from [_ChainState] plus two local flags
/// — never stored, so there is no second copy of the truth to fall out of step.
enum _S6 {
  /// A service read has not settled. Show the rows as unknown, claim nothing.
  loading,

  /// Citizenship did not resolve. Auto cannot run — the two lanes are
  /// different contract calls and there is no safe default — so the page
  /// offers manual only, and SKIP regardless of class.
  unknown,

  /// Neither service is live.
  needBoth,

  /// Only the BSP is missing.
  needBsp,

  /// Only the SSP is missing.
  needSsp,

  /// A subscribe is in flight.
  running,

  /// An axis could not be set up. **This is the state that unlocks SKIP.**
  failed,

  /// Both services live. The step is complete — on arrival or just now.
  done,
}

/// Why an axis could not be set up. Only [funds] is ever claimed out loud, and
/// only after the balance has actually been observed to be short.
enum _S6Fail { unknown, funds, noProvider }

class OnboardingFlow extends StatefulWidget {
  final VoidCallback onComplete;

  /// Replay launched from App Settings → "Watch onboarding". Two effects:
  /// it never writes the `onboarding_completed` flag, and it **shows every
  /// step regardless of account state** — otherwise a fully set-up account
  /// (the developer's) would walk a one-page tour and there would be nothing
  /// to review. Live first-run gating is [_liveStepsForState].
  final bool previewMode;

  /// DESKTOP DELTA: whether the flow paints its own background
  /// (colour + constellation). The first-run host (`app_shell`) sets false
  /// and paints one constellation behind the whole window, because the flow
  /// sits in a 520 px column and its own background stops at the column's
  /// edges. The Settings replay is a column-sized dialog and keeps it.
  final bool drawBackground;

  const OnboardingFlow({
    super.key,
    required this.onComplete,
    this.previewMode = false,
    this.drawBackground = true,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _controller = PageController();
  int _page = 0;

  // ── Chain facts ───────────────────────────────────────────────────────────
  //
  // **One object, one reader.** A writer that hand-patches the flag it has
  // just invalidated sets it from a read taken before the transaction is
  // mined, and the surfaces downstream disagree with it.
  //
  // The rule: **nothing sets a chain fact by hand.** A write awaits its
  // receipt and then calls [_refreshChainState]; the facts only ever come from
  // there.
  _ChainState _chain = _ChainState.empty;

  /// Whether the chain has answered **at least once**. Distinct from "the
  /// values are null" — it separates *not asked yet* from *asked and unknown*,
  /// which is what the S1 legend needs to decide between saying nothing and
  /// saying something wrong.
  bool _chainRead = false;

  /// True while a refresh is in flight, so overlapping page changes coalesce
  /// instead of stacking round trips.
  bool _chainRefreshing = false;

  _DomainClass get _domainClass => _chain.domainClass;
  bool get _showGift => _chain.showGift;
  bool get _canToggleTheme => _chain.canToggleTheme;

  /// Read every chain fact this flow gates on, in one pass.
  ///
  /// Reads are **independent and individually guarded**: one failure leaves its
  /// own field null and [_ChainState.merge] keeps whatever was already known,
  /// so a single bad round trip cannot blank a working page.
  ///
  /// Citizenship is asked before the kit because only a citizen can hold one —
  /// a non-citizen's tour costs one extra call, not two.
  Future<void> _refreshChainState() async {
    final addrHex = _selfAddressHex;
    if (addrHex.isEmpty || _chainRefreshing) return;
    _chainRefreshing = true;
    final account = EthereumAddress.fromHex(addrHex);

    BigInt? paidUntil;
    BigInt? grace;
    bool? compliant;
    bool? citizen;
    bool? minted;
    BigInt? vouchCount;
    BigInt? vouchThreshold;
    int? inboxCount;
    List<String>? inboxLabels;
    String? bspSlug;
    String? sspSlug;
    bool? bspLive;
    bool? sspLive;
    BigInt? coveredUntil;

    try {
      // The domain latches: compliance can only improve inside the few minutes
      // a tour lasts, so once it reads true there is nothing to re-ask.
      if (_chain.domainCompliant == true) {
        compliant = true;
        paidUntil = _chain.domainPaidUntil;
        grace = _chain.domainGrace;
      } else {
        try {
          paidUntil = await PublicOSTreasury.getDomainPaidUntil(account);
          compliant = await PublicOSTreasury.isDomainCompliant(account);
          grace = await PublicOSTreasury.getDomainEvictionGracePeriod();
        } catch (e) {
          Log.e('Onboarding', 'Domain read failed: $e');
        }
      }

      try {
        citizen = await PublicOSAccounts.isCitizen(account);
        if (citizen == true) {
          minted = await PublicOSCitizenKit.isKitMinted(account);
        } else if (citizen == false) {
          minted = false;
          // A private may already be ELIGIBLE: enough vouches for today's
          // threshold. Read here, inside the citizenship branch, because the
          // pair means nothing for a citizen and the claim sheet is the
          // first thing this flow shows when it is true.
          try {
            final e = await PublicOSAccounts.getCitizenshipEligibility(account);
            vouchCount = e.count;
            vouchThreshold = e.threshold;
          } catch (e) {
            Log.e('Onboarding', 'Eligibility read failed: $e');
          }
        }
      } catch (e) {
        Log.e('Onboarding', 'Citizen state read failed: $e');
      }

      // Unlike the domain, this one does NOT latch: an inbox can be published
      // mid-tour — that is the entire point of S3 — so it is re-asked on every
      // pass, and the pass that runs when the stage returns is what closes the
      // step.
      try {
        final all = await PublicOSXmtp.getAllAccountInboxIds(account);
        inboxCount = all?.inboxIds.length;
        inboxLabels = all?.labels;
      } catch (e) {
        Log.e('Onboarding', 'Inbox ID read failed: $e');
      }

      // ── The two service subscriptions ──
      //
      // Does not latch, for the same reason the inbox does not: S6 is where
      // these change, so the pass that runs after each receipt is what closes
      // the step.
      //
      // One read shape for every account class: `isActive(axis, a)` is the
      // contract's own verdict (assignment + provider + balance past an open
      // gate + dormancy + blocks), so there is no lane to pick and no clock to
      // compare. `coveredUntil` is the one date the rows show — one balance
      // pays both services.
      try {
        final mgr = PublicOSBsp.subsManagerContract;
        final mem = PublicOSBsp.subsMemoryContract;
        final reads = await Future.wait<dynamic>([
          mem.slugOf((axis: PublicOSTreasury.bspAxis, a: account)),
          mem.slugOf((axis: PublicOSTreasury.sspAxis, a: account)),
          mgr.isActive((axis: PublicOSTreasury.bspAxis, a: account)),
          mgr.isActive((axis: PublicOSTreasury.sspAxis, a: account)),
          mgr.coveredUntil((a: account)),
        ]);
        bspSlug = reads[0] as String;
        sspSlug = reads[1] as String;
        bspLive = reads[2] as bool;
        sspLive = reads[3] as bool;
        coveredUntil = reads[4] as BigInt;
      } catch (e) {
        Log.e('Onboarding', 'Service subscription read failed: $e');
      }

      if (!mounted) return;
      setState(() {
        _chain = _chain.merge(_ChainState(
          domainPaidUntil: paidUntil,
          domainGrace: grace,
          domainCompliant: compliant,
          isCitizen: citizen,
          citizenKitMinted: minted,
          vouchCount: vouchCount,
          vouchThreshold: vouchThreshold,
          registeredInboxCount: inboxCount,
          inboxLabels: inboxLabels,
          bspAssigned: bspSlug,
          sspAssigned: sspSlug,
          bspLive: bspLive,
          sspLive: sspLive,
          coveredUntil: coveredUntil,
        ));
        _chainRead = true;

        // Latched ONCE, inside the same setState that lands the read, on the
        // first pass where both services settled: did this account walk in
        // already set up? Everything after this can change — that is what S6
        // is for — so the question has to be asked before the page has had a
        // chance to answer it. (Inside the setState, not after it: a value the
        // first rebuild cannot see is a value the finished page renders
        // without.)
        if (_s6ArrivedDone == null &&
            _chain.bspActive != null &&
            _chain.sspActive != null) {
          _s6ArrivedDone = _chain.bspActive! && _chain.sspActive!;
        }
      });

      // The soulbound kit is minted off the back of a CONFIRMED-compliant
      // read, so it hangs here rather than in a caller — every path that
      // learns the domain is good also gets the kit.
      if (_chain.domainCompliant == true) _ensureSoulboundKit(account);
      if (_chain.isCitizen == true) _loadCitizenArt();
      _resyncSelfMembership(account, citizen);
      // Not awaited on purpose: the sheet waits on the user, and the refresh
      // it asks for afterwards must find this pass finished.
      _offerCitizenship();
    } finally {
      _chainRefreshing = false;
    }
  }

  /// The first screen an ELIGIBLE private sees: the
  /// citizen agreement, scrolled to the end, then ACCEPT AND CLAIM, then the
  /// burst. Offered once per run, never in the Settings replay. A landed claim
  /// re-reads the chain so the rest of the tour runs as a citizen's: the gift
  /// page appears, the providers step reads the citizen lane.
  bool _claimOffered = false;

  /// An eligible private who dismissed the sheet (or has not seen it yet) may
  /// continue as a private — allowed, and not much use — so the bottom bar
  /// keeps a second door open above CONTINUE (it relaunches the sheet) for as
  /// long as the claim is pending. Keyed on eligibility, not on the
  /// dismissal, so the slot is
  /// there from the first chain read and nothing shifts when the sheet closes;
  /// it leaves with the citizen re-read after a landed claim.
  bool get _claimPending =>
      !widget.previewMode &&
      _chain.citizenshipEligible &&
      _chain.isCitizen != true;

  Future<void> _relaunchClaim() async {
    final claimed = await showCitizenshipClaimSheet(context);
    if (!mounted || !claimed) return;
    await _refreshChainState();
  }

  Future<void> _offerCitizenship() async {
    if (widget.previewMode || _claimOffered || !_chain.citizenshipEligible) {
      return;
    }
    _claimOffered = true;
    if (!mounted) return;
    final claimed = await showCitizenshipClaimSheet(context);
    if (!mounted || !claimed) return;
    await _refreshChainState();
  }

  /// Bring the CACHED self contact's citizenship in line with the live read.
  ///
  /// The tour's copy reads [_chain.isCitizen] live, but every avatar (this
  /// tour's cards, the explorer icon, the wallet) paints the contact row's
  /// `isCitizen`, a **durable** flag `fetchContact` never re-reads unless told
  /// to. Without this, an account that logged in as a private, got vouched
  /// and restarted walks the whole tour with copy saying *citizen* over a
  /// ghost avatar, and keeps the ghost in the app until it opens its own
  /// profile. Same truth as that profile visit: `fetchContact(self,
  /// forceMembership: true)` re-reads membership, saves the row and emits on
  /// `selfContactUpdates`, which repaints every self surface at once.
  ///
  /// Only on a **confirmed disagreement**: an unresolved read (`null`) proves
  /// nothing, and a matching flag needs no full profile fetch. Covers both
  /// directions, citizen gained and citizen revoked.
  Future<void> _resyncSelfMembership(
      EthereumAddress account, bool? liveCitizen) async {
    if (liveCitizen == null || _membershipResyncing) return;
    final cached =
        (AppStateNotifier.currentMyContact ?? _selfContact)?.isCitizen;
    if (cached == liveCitizen) return;
    _membershipResyncing = true;
    try {
      final fresh = await PublicOSContacts.fetchContact(
        account,
        forceMembership: true,
      );
      Log.d('Onboarding',
          'Self membership resynced: ${cached ?? 'unknown'} -> ${fresh.isCitizen}');
      // `fetchContact` already emitted on `selfContactUpdates`; set it here too
      // so this page does not depend on the stream's timing.
      AppStateNotifier.setMyContact(fresh);
      if (mounted) setState(() => _selfContact = fresh);
    } catch (e) {
      Log.e('Onboarding', 'Self membership resync failed: $e');
    } finally {
      _membershipResyncing = false;
    }
  }

  /// Mint the soulbound kit if the account has none. Fire-and-forget: a
  /// failure is logged and the profile fill simply finds no kit to draw from.
  Future<void> _ensureSoulboundKit(EthereumAddress account) async {
    try {
      await PublicOSSoulbound.ensureKitMinted(account);
    } catch (e) {
      Log.e('Onboarding', 'Soulbound ensure failed: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  //  S6 · THE PROVIDERS FORK
  //
  //  One page, personalised on three chain facts and one user choice.
  // ════════════════════════════════════════════════════════════════════════

  /// A subscribe is in flight.
  bool _s6Running = false;

  /// The axis that could not be set up, and why. Null axis = nothing failed.
  ProviderKind? _s6FailedAxis;
  _S6Fail _s6Fail = _S6Fail.unknown;

  /// What the failed axis would have cost, when we managed to find out. Only
  /// non-null alongside [_S6Fail.funds] — it is what lets the copy name a
  /// figure instead of waving at one.
  BigInt? _s6FailCost;

  /// **The earned exit.** A citizen is offered no way out of this page until
  /// something actually fails — there is nothing to pay, so there is no reason
  /// to duck it — but a gate that cannot be closed is worse than the SKIP
  /// this flow leaves out on purpose. A private always has one (see
  /// [_s6ShowSkip]).
  bool _s6SkipUnlocked = false;

  /// Set when the user confirms the SKIP dialog. It **resolves** S6 — the step
  /// stops asking, its primary becomes a plain CONTINUE and the page can be
  /// advanced past. Without it the skip would be inert: the tour truncates the
  /// PageView at any step it will not let you leave, so `_next()` would have
  /// nowhere to go.
  bool _s6Skipped = false;

  /// Whether the account already had both services when it got here. Latched
  /// on the first settled read so the finished page can tell *"you already
  /// have these"* from *"you just set these up"*.
  bool? _s6ArrivedDone;

  /// Where S6 is, derived — never stored.
  _S6 get _s6State {
    if (_s6Running) return _S6.running;
    if (_s6FailedAxis != null) return _S6.failed;
    if (_chain.isCitizen == null) return _S6.unknown;
    final b = _chain.bspActive;
    final s = _chain.sspActive;
    if (b == null || s == null) return _S6.loading;
    if (b && s) return _S6.done;
    if (!b && !s) return _S6.needBoth;
    return b ? _S6.needSsp : _S6.needBsp;
  }

  bool _s6Missing(ProviderKind kind) =>
      (kind == ProviderKind.bsp ? _chain.bspActive : _chain.sspActive) != true;

  /// A private always carries SKIP — self-hosting is a real answer, not a
  /// dodge, and a private who runs their own node gets nothing from a BSP
  /// subscription. A citizen carries it only once something has broken. An
  /// unreadable class gets it too: we cannot apply "citizens have no skip"
  /// when we do not know the class, and without it one bad round trip is a
  /// trap.
  bool get _s6ShowSkip => _chain.isCitizen != true || _s6SkipUnlocked;

  /// The device's country, for region-matching a provider. Frequently null —
  /// which is why [resolveAutoProvider] falls back to the whole pool rather
  /// than failing.
  String? _s6Country(BuildContext context) =>
      Localizations.localeOf(context).countryCode;

  // The allow-list and the resolver live in `network_access_sheets.dart`
  // (`kAutoProviderSlugs` / `resolveAutoProvider`). Ordering: region first,
  // then LOWEST subscriber count.

  /// **The auto path.** BSP first, then SSP; one period each; and it stops dead
  /// on the first failure rather than carrying on to the next axis — one
  /// failure, one sentence, one exit, instead of two failures and a screen
  /// nobody can read.
  ///
  /// A private deposits one period into the shared service balance **only if
  /// the wallet can cover it**, and is asked first; otherwise it joins with no
  /// deposit at all — below a provider's min-subscriber gate the contract
  /// serves without charging, so an empty wallet is no reason to refuse a
  /// newcomer. The cost is read again only if something actually fails
  /// ([_s6ClassifyFail]).
  Future<void> _runS6Auto() async {
    if (_s6Running) return;
    final citizen = _chain.isCitizen;
    if (citizen == null) return; // unknown class never reaches the button
    final country = mounted ? _s6Country(context) : null;

    setState(() {
      _s6Running = true;
      _s6FailedAxis = null;
      _s6FailCost = null;
    });

    for (final kind in [ProviderKind.bsp, ProviderKind.ssp]) {
      if (!_s6Missing(kind)) continue;

      List<ProviderEntry> dir;
      try {
        dir = await fetchProviderDirectory(kind, 30);
      } catch (e) {
        Log.e('Onboarding', 'S6 directory read failed: $e');
        dir = const [];
      }
      final pick = resolveAutoProvider(dir, country);
      if (pick == null) {
        await _s6Fail_(kind, _S6Fail.noProvider);
        return;
      }

      // Privates are told what is about to leave their wallet, per service,
      // before it does — when the wallet has it. A wallet that cannot cover
      // one period joins with no deposit instead of being refused: served, not
      // charged, until the provider's gate opens. Citizens are charged nothing,
      // so there is nothing to announce and nothing to confirm.
      var topUp = BigInt.zero;
      if (!citizen) {
        final axis = kind == ProviderKind.bsp
            ? PublicOSTreasury.bspAxis
            : PublicOSTreasury.sspAxis;
        BigInt? cost;
        try {
          cost = await PublicOSTreasury.quoteBalance(axis, 1);
        } catch (e) {
          Log.e('Onboarding', 'S6 quote failed: $e');
        }
        final balance = await _s6Balance();
        if (cost != null && balance != null && balance >= cost) {
          final go = await _s6ConfirmDeposit(kind, pick);
          if (!go) {
            if (mounted) setState(() => _s6Running = false);
            return;
          }
          topUp = cost;
        }
      }

      // The SSP's rules are shown right before
      // its subscribe; subscribing IS the acceptance. Closing the sheet stops
      // the step the same way declining a deposit does.
      if (kind == ProviderKind.ssp) {
        if (!mounted) return;
        final go = await showServerRulesSheet(context,
            apiUrl: pick.apiUrl,
            serverName: pick.title.isNotEmpty ? pick.title : pick.slug);
        if (!go) {
          if (mounted) setState(() => _s6Running = false);
          return;
        }
      }

      final ok = await _s6Subscribe(kind, pick.slug, topUp);
      if (!ok) {
        await _s6ClassifyFail(kind, pick.slug);
        return;
      }
    }

    if (mounted) setState(() => _s6Running = false);
  }

  /// Send, await the receipt, re-read. The same three steps every write in
  /// this flow takes — no flag is ever set by hand.
  ///
  /// One verb for every account class — `subscribe(axis, slug,
  /// topUp)`. Citizenship only decided the deposit upstream: a citizen tops up
  /// nothing (the network mints their share), a private what [_runS6Auto]
  /// worked out. There is no wrong lane to send a citizen down.
  Future<bool> _s6Subscribe(
    ProviderKind kind,
    String slug,
    BigInt topUp,
  ) async {
    final creds = PublicOS.currentBlockchainPrivateKey;
    if (creds == null) return false;
    try {
      final axis = kind == ProviderKind.bsp
          ? PublicOSTreasury.bspAxis
          : PublicOSTreasury.sspAxis;
      final tx = await PublicOSTreasury.subscribe(axis, slug, topUp: topUp);
      if (tx == null) return false;
      final ok = await TxUtils.waitForReceipt(tx, label: 'S6 subscribe');
      if (!ok) return false;
      // A BSP subscription can move the live endpoint. Idempotent, and it
      // probes reachability before switching, so a dead endpoint cannot strand
      // the rest of the tour.
      await PublicOS.upgradeRpcPostAuth();
      await _refreshChainState();
      return true;
    } catch (e) {
      Log.e('Onboarding', 'S6 subscribe failed: $e');
      return false;
    }
  }

  /// Work out *why* an attempt failed, and only then say so.
  ///
  /// `waitForReceipt` returns a bare bool, and `false` covers a revert, a
  /// 40-second timeout and an RPC error alike — receipts carry no reason. So
  /// the balance and the gate are read **here**, after the fact: the page is
  /// allowed to say "not enough OX" only when the provider genuinely charges
  /// *and* the wallet was seen to be short. Everything else stays generic,
  /// which is the honest answer rather than a guess dressed as one.
  Future<void> _s6ClassifyFail(ProviderKind kind, String slug) async {
    var why = _S6Fail.unknown;
    BigInt? cost;
    try {
      final gate = kind == ProviderKind.bsp
          ? await PublicOSTreasury.getBspGateStatus(slug)
          : await PublicOSTreasury.getSspGateStatus(slug);
      if (gate.paid == true) {
        cost = kind == ProviderKind.bsp
            ? await PublicOSTreasury.quoteBspSub(1)
            : await PublicOSTreasury.quoteSspSub(1);
        final balance = await _s6Balance();
        // The only branch allowed to blame the wallet, and only because the
        // shortfall was actually observed rather than predicted.
        if (balance != null && balance < cost) {
          why = _S6Fail.funds;
        }
      }
    } catch (e) {
      Log.e('Onboarding', 'S6 failure classification failed: $e');
    }
    await _s6Fail_(kind, why, cost: why == _S6Fail.funds ? cost : null);
  }

  Future<void> _s6Fail_(
    ProviderKind kind,
    _S6Fail why, {
    BigInt? cost,
  }) async {
    if (!mounted) return;
    setState(() {
      _s6Running = false;
      _s6FailedAxis = kind;
      _s6Fail = why;
      _s6FailCost = cost;
      _s6SkipUnlocked = true; // every failure opens a way forward
    });
  }

  Future<BigInt?> _s6Balance() async {
    final hex = _selfAddressHex;
    if (hex.isEmpty) return null;
    try {
      final safe = await PublicOSSafe.getMainSafeAddress(
        EthereumAddress.fromHex(hex),
      );
      if (safe == null) return null;
      return await PublicOSTreasury.getTokenBalance(
        EthereumAddress.fromHex(safe),
      );
    } catch (e) {
      Log.e('Onboarding', 'S6 balance read failed: $e');
      return null;
    }
  }

  /// The per-service deposit notice — privates only, one axis at a time.
  ///
  /// It names the deposit: one period of this axis at today's fee, moved from
  /// the MainSafe into the shared service balance. Below the provider's gate
  /// nothing is drawn from it, but the deposit still happens and is
  /// withdrawable from Services — so the figure is honest either way.
  Future<bool> _s6ConfirmDeposit(ProviderKind kind, ProviderEntry entry) async {
    BigInt? cost;
    BigInt? balance;
    try {
      cost = kind == ProviderKind.bsp
          ? await PublicOSTreasury.quoteBspSub(1)
          : await PublicOSTreasury.quoteSspSub(1);
    } catch (e) {
      Log.e('Onboarding', 'S6 quote failed: $e');
    }
    balance = await _s6Balance();
    if (!mounted) return false;
    final l10n = context.l10n;
    // `wrapInChrome: false`: the sheet paints its own glass (the same shell the
    // provider picker and the subscribe sheet use), so wrapping it again would be
    // the double-chrome footgun.
    final ok = await showPhigitalBottomSheet<bool>(
      context: context,
      wrapInChrome: false,
      builder: (_, __) => _S6DepositSheet(
        title: kind == ProviderKind.bsp
            ? l10n.onbProvBspTitle
            : l10n.onbProvSspTitle,
        provider: entry,
        cost: cost,
        balance: balance,
      ),
    );
    return ok == true;
  }

  /// Manual — the ported pair. `pickProvider` then `confirmSubscribe`, which
  /// already branch on citizenship and already never quote a citizen. The step
  /// completes on the RETURN, not on the tap.
  Future<void> _s6PickManual(ProviderKind kind) async {
    if (_s6Running) return;
    final slug = await pickProvider(context, kind: kind);
    if (slug == null || !mounted) return;
    final ok = await confirmSubscribe(
      context,
      kind: kind,
      slug: slug,
      isCitizen: _chain.isCitizen == true,
      isSwitch: false,
    );
    if (!ok) return;
    await _refreshChainState();
  }

  /// SKIP — privates always, citizens once something has broken. It **advances
  /// to S7**; it never dismisses the tour.
  Future<void> _onS6Skip() async {
    final l10n = context.l10n;
    final missing = <String>[
      if (_s6Missing(ProviderKind.bsp)) l10n.onbProvBspTitle,
      if (_s6Missing(ProviderKind.ssp)) l10n.onbProvSspTitle,
    ].join(' · ');
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => _S6SkipDialog(missing: missing),
    );
    if (go != true) return;
    setState(() => _s6Skipped = true);
    _next();
  }

  // ── Identity ──────────────────────────────────────────────────────────────

  String get _selfAddressHex => PublicOS.myPublicosAddress ?? '';

  /// Thin placeholder until the real self-contact resolves, so the card never
  /// renders an empty frame on first paint.
  Contact _fallbackSelfContact() {
    final hex = _selfAddressHex;
    final existing = AppStateNotifier.currentMyContact ?? _selfContact;
    final name = existing?.displayName ?? 'you';
    return Contact(
      displayName: name,
      publicosDisplayName: name,
      publicosAddress: EthereumAddress.fromHex(
        hex.isNotEmpty ? hex : '0x0000000000000000000000000000000000000000',
      ),
    );
  }

  Contact _fallbackOrgContact() => Contact(
        displayName: _publicosOrgName,
        publicosDisplayName: _publicosOrgName,
        publicosAddress: EthereumAddress.fromHex(
          '0x0000000000000000000000000000000000000000',
        ),
      );

  Future<void> _loadSelf() async {
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) return;
    try {
      final contact =
          await PublicOSContacts.getContact(EthereumAddress.fromHex(addrHex));
      if (!mounted || contact == null) return;
      setState(() => _selfContact = contact);
    } catch (_) {
      // Offline / RPC down — the fallback contact carries the card.
    }
  }

  /// Resolve the PublicOS org by display name and read its published tabs.
  /// Best-effort: a failure leaves the card on its placeholder.
  Future<void> _loadOrg() async {
    try {
      final org = await PublicOSContacts.resolveByIdentifier(_publicosOrgName);
      if (!mounted || org == null) return;
      setState(() => _orgContact = org);

      // ── Tabs ──
      //
      // **Ported from `browser.dart` `_loadTabsAndApps`, not invented.** The
      // rule there is three-part and every part matters: router records only,
      // `tab` **OR `channel`** — feeds and websites are channels, so filtering
      // to `tab` alone leaves an org showing Profile/Chat/Management and
      // nothing it actually publishes — and expired records dropped.
      //
      // Read off `org.records`, which `resolveByIdentifier` already enriched
      // via `fetchContact(requireRecords: true)`. A second `getRecordsByType`
      // is best-effort and returns `[]` on failure, which would silently
      // replace a good tab list with none.
      final tabs = org.records
          .where((r) =>
              r.type == RecordType.router &&
              (r.routerSubtype == RouterSubtype.tab ||
                  r.routerSubtype == RouterSubtype.channel) &&
              !r.isExpired)
          .toList();
      if (mounted) setState(() => _orgTabs = tabs);

      // ── Apps ──
      //
      // A **separate on-chain source** from router records — an app is in the
      // App Registry, not in the profile's records, so nothing above finds it.
      // Only apps carrying a URL are listed, since the sheet's row is a link.
      final addr = org.publicosAddress;
      if (addr == null) return;
      try {
        final apps = await PublicOSAppRegistry.getAllAccountApps(addr);
        if (apps == null || !mounted) return;
        setState(() => _orgApps =
            apps.where((a) => a.url != null && a.url!.isNotEmpty).toList());
      } catch (e) {
        Log.e('Onboarding', 'Org apps read failed: $e');
      }
    } catch (_) {
      // Placeholder card, built-in tabs only.
    }
  }

  /// S2's gate: opening the tabs sheet is what unlocks NEXT, and it completes
  /// on the RETURN, not on the tap.
  Future<void> _openOrgTabs() async {
    final contact = _orgContact ?? _fallbackOrgContact();
    await showPhigitalBottomSheet(
      context: context,
      // The body paints its own glass — wrapping it again is the
      // double-chrome footgun.
      wrapInChrome: false,
      builder: (_, __) => _TabsSheet(
        accountName: contact.displayName,
        customTabs: _orgTabs,
        apps: _orgApps,
        isOrg: contact.isOrgAccount,
      ),
    );
    if (!mounted) return;
    setState(() => _orgTabsOpened = true);
  }

  /// Resolve the soulbound art once and keep it for the run — `PageView`
  /// disposes off-screen pages, so a widget-owned fetch would repeat forever.
  Future<void> _loadKitArt() async {
    if (_kitArt != null || _kitArtLoading) return;
    final addrHex = _selfAddressHex;
    if (addrHex.isEmpty) return;
    _kitArtLoading = true;
    try {
      final ids = await _ensureKitIds(EthereumAddress.fromHex(addrHex));
      if (ids == null) return;
      // pfp and banner join the card offsets: the cards page synthesises an
      // avatar/banner verdict for its theme preview, and a verdict without an
      // image is not usable — `GlassContactIcon` would fall through to initials.
      final offsets = <int>{
        _kKitPfpOffset,
        _kKitBannerOffset,
        ..._kKitLayout.map((t) => t.offset),
      }.toList();
      final resolved = await Future.wait(offsets.map((offset) async {
        try {
          final meta = await PublicOSContacts.resolveNftAvatarData(
            NftAvatarRef(
              chain: PublicOS.CHAIN_ID,
              standard: 'erc721',
              contract: PublicOSSoulbound.kitContractAddress,
              tokenId: ids[offset].toString(),
            ),
          );
          return MapEntry(offset, meta?['image'] as String?);
        } catch (_) {
          return MapEntry(offset, null);
        }
      }));
      if (!mounted) return;
      setState(() => _kitArt = {
            for (final e in resolved)
              if (e.value != null) e.key: e.value!,
          });
    } finally {
      _kitArtLoading = false;
    }
  }

  // ── The bio (S4b) ─────────────────────────────────────────────────────────

  /// The picker's current choice. Null until the user picks or types.
  String? _bioDraft;

  /// A bio confirmed written this run, so the page stops reading dirty without
  /// waiting for the contact refresh to come back around.
  String? _bioSavedLocal;

  bool _bioSaving = false;

  /// Bumped by *undo* to force [_BioPicker] to rebuild from its `initial` —
  /// the picker owns its controller, so restoring means a new identity.
  int _bioPickerEpoch = 0;

  String? get _bioSaved => _bioSavedLocal ?? _existingBio;
  String? get _bioCurrent => _bioDraft ?? _bioSaved;

  bool get _bioDirty {
    final cur = _bioCurrent;
    return cur != null && cur.isNotEmpty && cur != _bioSaved;
  }

  // ── The cards (S4c) ───────────────────────────────────────────────────────

  List<_CardSpec>? _cardSpecsSaved;
  List<_CardSpec>? _cardSpecsDraft;
  _KitTheme _cardThemeSaved = _KitTheme.soulbound;
  _KitTheme? _cardThemeDraft;
  bool _cardsSaving = false;
  final Random _rng = Random();

  /// Guards [_resyncSelfMembership] against overlapping chain passes.
  bool _membershipResyncing = false;

  /// The account's MainSafe, for the prefill's tip card. Null until read, and
  /// null for good if the read fails — then the prefill simply has no tip card.
  String? _mainSafeHex;

  _KitTheme get _cardTheme => _cardThemeDraft ?? _cardThemeSaved;
  _KitSource get _cardSource => _KitSource.of(_cardTheme);
  List<_CardSpec>? get _cardSpecs => _cardSpecsDraft ?? _cardSpecsSaved;

  /// Read the MainSafe once — the tip card's pay-to. Awaited by the S4b fill;
  /// S4c's reroll reads whatever is cached.
  Future<void> _loadMainSafe() async {
    if (_mainSafeHex != null) return;
    final hex = _selfAddressHex;
    if (hex.isEmpty) return;
    try {
      _mainSafeHex =
          await PublicOSSafe.getMainSafeAddress(EthereumAddress.fromHex(hex));
    } catch (e) {
      Log.e('Onboarding', 'MainSafe read failed: $e');
    }
  }

  /// Roll the prefill's special cards: which ones, their footprints and their
  /// content. Every call is a fresh draw — S4c's RANDOMIZE re-rolls content
  /// as well as layout.
  ///
  /// - **PublicOS** — always: one of five image + line pairs, 1×1 · 1×2 · 2×1 ·
  ///   2×2 (never 2×1 for the astronaut), linking the publicos org.
  /// - **Text me** — only if the chain CONFIRMS an inbox and returned a label
  ///   (`== true`, never `!= false`: S3 fails open on a dead read, so passing
  ///   it proves nothing). 1×1 or 2×1, a random gradient, `/chat/<label>`.
  /// - **Tips** — when the MainSafe is known: 1×1 or 2×1, jmsl's tip art or
  ///   plain teal, pays the user's own MainSafe in OX.
  List<Record> _rollPrefills() {
    final copy = _prefillCopy();
    final out = <Record>[];
    T pick<T>(List<T> options) => options[_rng.nextInt(options.length)];

    final img = pick(_kPrefillImages);
    final os = pick([
      (w: 1, h: 1),
      (w: 1, h: 2),
      if (img.wide) (w: 2, h: 1),
      (w: 2, h: 2),
    ]);
    out.add(_prefillCard(
      'os',
      w: os.w,
      h: os.h,
      line: copy[img.line]!,
      image: img.url,
      link: 'https://publicos.dev/publicosAddress/$_kPublicosOrgAddress',
    ));

    final self = _selfAddressHex;
    final label = (_chain.inboxLabels ?? const <String>[])
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (_chain.hasRegisteredInbox == true && self.isNotEmpty && label.isNotEmpty) {
      final s = pick([(w: 1, h: 1), (w: 2, h: 1)]);
      out.add(_prefillCard(
        'inbox',
        w: s.w,
        h: s.h,
        line: copy['inbox']!,
        gradient: _randomCardGradient(_rng),
        link: 'https://publicos.dev/publicosAddress/$self/chat/'
            '${Uri.encodeComponent(label.trim())}',
      ));
    }

    final safe = _mainSafeHex;
    if (safe != null && CardTip.isAddress(safe)) {
      final s = pick([(w: 1, h: 1), (w: 2, h: 1)]);
      final withImage = _rng.nextBool();
      out.add(_prefillCard(
        'tip',
        w: s.w,
        h: s.h,
        line: copy['tip']!,
        image: withImage ? _kTipImage : null,
        color: withImage ? null : _kTipColor,
        tip: CardTip(to: safe, chainId: PublicOS.CHAIN_ID, token: CardTip.ox),
      ));
    }
    return out;
  }

  /// Unsaved changes: a different arrangement, or a different source.
  bool get _cardsDirty =>
      (_cardSpecsDraft != null &&
          !(_cardSpecsSaved != null &&
              _sameShapes(_cardSpecsDraft!, _cardSpecsSaved!))) ||
      (_cardThemeDraft != null && _cardThemeDraft != _cardThemeSaved);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSelf();
    _loadOrg();
    _refreshChainState();
    _loadMainSafe();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  /// The steps a real first run shows for this account's state.
  ///
  /// The domain read is **three-state on purpose**: `true` skips S1, `false`
  /// ends the tour there (a lapsed account cannot publish an inbox, so the tour
  /// stops where their options stop), and **null keeps everything** — a failed
  /// read must never truncate a first-timer's setup.
  List<_Step> get _liveStepsForState {
    final compliant = _chain.domainCompliant;
    if (compliant == false) {
      return const [_Step.publicOs, _Step.domain];
    }
    return <_Step>[
      _Step.publicOs,
      if (compliant == null) _Step.domain,
      _Step.account,
      _Step.yours,
      _Step.profile,
      if (_showGift || _giftReached) _Step.gift, // see [_giftReached]
      _Step.cards,
      _Step.tabs,
      _Step.providers,
      _Step.outro,
    ];
  }

  /// Preview shows every step regardless of account state — the replay exists
  /// to walk the whole flow, not this account's slice of it.
  static const List<_Step> _allSteps = [
    _Step.publicOs,
    _Step.domain,
    _Step.account,
    _Step.yours,
    _Step.profile,
    _Step.gift,
    _Step.cards,
    _Step.tabs,
    _Step.providers,
    _Step.outro,
  ];

  /// Which steps this run actually walks.
  ///
  /// Preview shows the whole flow — **with one exception, and it is not a
  /// cosmetic one.** S4d's only control is a mint, and `CitizenKit.mint` is
  /// gated on citizenship at the contract, so for a confirmed private that page
  /// offers a button that can only revert. Worse, the page's primary IS that
  /// button until the gift opens (`openGift`), so there is nothing else to
  /// press: a private walking the replay stops dead on a page about a gift they
  /// cannot receive. Showing it is not "walking the whole flow", it is a trap.
  ///
  /// Only a **confirmed** private is skipped. An unresolved citizenship read
  /// keeps the page in preview, which is the right way round for a replay whose
  /// job is to show a developer every screen.
  List<_Step> get _steps {
    if (!widget.previewMode) return _liveStepsForState;
    if (_chain.isCitizen == false) {
      return _allSteps.where((s) => s != _Step.gift).toList(growable: false);
    }
    return _allSteps;
  }

  int get _pageCount => _steps.length;

  void _next() {
    if (_page >= _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    // A preview replay never claims the account finished the tour.
    if (!widget.previewMode) {
      try {
        await PublicOSSettings.setSetting(
          'onboarding_completed',
          Record.asSettings(
            key: 'onboarding_completed',
            value: 'true',
            isSystem: true,
            isExpired: false,
          ),
        );
      } catch (e) {
        Log.e('Onboarding', 'Could not store the completed flag: $e');
      }
    }
    widget.onComplete();
  }

  // ── The domain gate ───────────────────────────────────────────────────────
  // Read once at entry and cached for the run. Drives whether S1 is shown at
  // all, and (later) whether the chain-writing steps are reachable.
  //
  //   compliant      → S1 is skipped; the account already holds its domain.
  //   not compliant  → S1 is shown, and it is the account's way in.
  //   READ FAILED    → treat as NOT compliant and show the step. A returning
  //                    user loses ten seconds; wrongly skipping a real
  //                    first-timer costs them the entire setup.

  /// The signed-in user's own contact, for the identity card on S1.
  Contact? _selfContact;

  // ── S2's subject: the canonical PublicOS org ──────────────────────────────
  // Resolved by NAME, on-chain, exactly the way the explorer seeds it — no
  // address is baked in, so this survives a redeploy. Null while it resolves
  // (or if the chain is unreachable), in which case the card falls back to a
  // name-only placeholder and the sheet still lists Profile + Chat.
  static const String _publicosOrgName = 'PublicOS';
  Contact? _orgContact;
  List<Record> _orgTabs = const [];
  List<AppBookmark> _orgApps = const [];

  /// S2's gate: NEXT stays disabled until the tabs sheet has been opened and
  /// dismissed. The page's whole job is to make the user look inside an
  /// account once — an un-gated NEXT is exactly how a tour gets skipped.
  bool _orgTabsOpened = false;

  /// S1's gate, lapsed accounts only: the primary stays locked until the
  /// Domain Store has been opened and dismissed once. For a confirmed lapsed
  /// account S1 is the last page, so its primary is the way into the app, and
  /// nobody takes it with a lapsed domain before seeing where the fee is paid.
  /// Paying is not required; looking is.
  bool _domainStoreOpened = false;

  /// S3's gate, the same shape as S2's: the step is done when the user comes
  /// BACK from the inbox flow, not when they leave for it. Until then there is
  /// no way out of the tour — an enabled DONE sitting next to "add my first
  /// inbox" is an invitation to skip the one setup this whole flow exists to
  /// get done.
  bool _inboxCreated = false;

  /// The account's bio as already published on chain, if any — seeded into the
  /// picker as the user's own text and shown in the preview slot above it.
  ///
  /// **Both contact sources are searched, not just the first non-null one.**
  /// `AppStateNotifier.currentMyContact ?? _selfContact` looks equivalent and
  /// is not: the app-state contact can be present but carry no records (a
  /// lighter read, or a cache that predates the bio), and a `??` stops at the
  /// first non-null *contact* rather than the first one that answers the
  /// question. The freshly fetched `_selfContact` would then never be
  /// consulted, and an account with a published bio would read as having none.
  ///
  /// Expired records are skipped and the value is trimmed, matching the
  /// canonical lookup in `profile_page.dart` and `discover_contact_row.dart`,
  /// so a lapsed bio is never shown as current.
  String? get _existingBio {
    for (final contact in [AppStateNotifier.currentMyContact, _selfContact]) {
      for (final r in contact?.records ?? const <Record>[]) {
        if (r.profileSubtype == ProfileSubtype.text &&
            !r.isExpired &&
            r.value.trim().isNotEmpty) {
          return r.value.trim();
        }
      }
    }
    return null;
  }

  /// S4b's slot fill runs once per pass through the flow, whether or not it
  /// found anything to write.
  bool _slotsChecked = false;

  // ── Kit cache ────────────────────────────────────────────────────────────
  // Held on the FLOW rather than inside the widget that draws it. `PageView`
  // disposes an off-screen page, so a widget-owned cache is thrown away every
  // time the user walks past — and re-resolving costs 2 chain reads for the
  // ids plus 1 `tokenURI` per piece. None of it can change mid-tour: the kit
  // is soulbound and its art is a pure function of the holder's address.
  List<BigInt>? _kitIds;
  Map<int, String>? _kitArt;
  bool _kitArtLoading = false;

  /// The account's kit token ids, resolved at most once per run.
  Future<List<BigInt>?> _ensureKitIds(EthereumAddress account) async {
    final cached = _kitIds;
    if (cached != null) return cached;
    final ids = await PublicOSSoulbound.kitTokenIds(account);
    if (ids != null) _kitIds = ids;
    return ids;
  }

  // ── The citizen tier ─────────────────────────────────────────────────────
  // Two reads, both TRI-STATE, and neither may be collapsed to a bool.

  /// 🔴 **Citizenship, and NOT a lifetime domain.** These are different facts
  /// and must not be conflated: [_domainClass] is derived from
  /// `domainPaidUntil > sentinel`, while `CitizenKit.mint` gates on
  /// `CitizenshipManager.isCitizen`. Root can stamp the `NEVER` sentinel on a
  /// **private** account (`seedDomainNever`) — offering such an account the
  /// gift would produce a revert — and a freshly-citizenized account can be a
  /// real citizen *before* the domain sync stamps it, and must not be denied
  /// a kit they are entitled to.
  ///
  /// `null` = unread or failed. Never treated as either answer.

  /// Whether the citizen kit already exists for this account. Read through
  /// `CitizenKit.isMinted` — a **view**, so this is not a caught `ownerOf`
  /// revert, which cannot be told apart from a dead RPC.
  ///
  /// `null` is not `false` in **both** directions here: an unknown must never
  /// mint, and must never be read as *already minted* either, or a citizen
  /// silently loses their gift.

  /// The citizen kit's art, by tile. Resolved through `previewSVG`, which
  /// renders for an **unminted** account — so this is prefetched behind S4d's
  /// shimmer and the reveal is instant rather than a second loading state.
  Map<int, String>? _citizenArt;
  bool _citizenArtLoading = false;

  /// A mint is in flight.
  bool _minting = false;

  /// The gift is **shown open** — the frames carry art instead of a sheen.
  ///
  /// Three separate flags here, and the separation is load-bearing:
  /// [_citizenKitMinted] is a fact about the CHAIN, this is a fact about the
  /// PAGE, and [_giftBurst] is a fact about the ANIMATION. Collapsing any two
  /// of them breaks a real case — **a de-dup guard must never be the same
  /// variable as the displayed state**. It is also what lets a preview replay
  /// open the gift without sending a transaction.
  bool _giftOpened = false;

  /// The burst plays once. Walking back onto an already-open page shows the
  /// kit without re-firing it.
  bool _giftBurst = false;

  /// Set once S4d has been on screen this run, and never cleared.
  ///
  /// **The live step list must not change under the PageView.** S4d is in it
  /// only while `showGift` holds, and the mint itself turns that false, so
  /// without this the page would vanish the moment its own button succeeds.
  /// `_page` would keep its index, which then names S4c: the reveal never
  /// plays, and since no page change happens, `onPageChanged` never seeds the
  /// cards. Once shown, the gift stays for the rest of the run.
  bool _giftReached = false;

  /// Whether the page should be drawn open.
  ///
  /// **A preview replay always starts CLOSED**, whatever the chain says. It is
  /// the same rule that makes `previewMode` show every step regardless of
  /// account state: a developer whose kit is already minted would otherwise
  /// land on a finished page with nothing to watch — no shimmer, no reveal, no
  /// burst, and a primary already reading CONTINUE. The replay exists to show
  /// the beat, so it plays the beat.
  bool get _giftIsOpen => widget.previewMode
      ? _giftOpened
      : (_chain.citizenKitMinted == true || _giftOpened);

  /// Warm the citizen art. Thirteen reads, issued in parallel by Core.
  Future<void> _loadCitizenArt() async {
    if (_citizenArt != null || _citizenArtLoading) return;
    final addrHex = _selfAddressHex;
    if (addrHex.isEmpty) return;
    _citizenArtLoading = true;
    try {
      final art = await PublicOSCitizenKit.previewAllArt(
        EthereumAddress.fromHex(addrHex),
      );
      if (!mounted || art.isEmpty) return;
      setState(() => _citizenArt = art);
    } catch (e) {
      Log.e('Onboarding', 'Citizen art prefetch failed: $e');
    } finally {
      _citizenArtLoading = false;
    }
  }

  /// Mint the citizen kit, then reveal it.
  ///
  /// **Costs the user nothing** — 502,229 gas for all thirteen pieces in one
  /// transaction, at `gasPrice 0` on this chain. That is why there is no cost
  /// sheet and no confirmation step: the button *is* the confirmation.
  ///
  /// The reveal fires only on a **confirmed** mint. A failed send leaves the
  /// button saying MINT, which is what it should say.
  /// Open the gift.
  ///
  /// **A Settings replay opens it without minting.** Gating the whole
  /// interaction on `!previewMode` would not "keep preview safe" — it would
  /// make the page's one control unreachable and leave the primary reading
  /// CONTINUE over an unopened gift. What preview must not do is send a
  /// TRANSACTION; it can still play the reveal, which is the entire point of
  /// being able to watch the tour.
  Future<void> _openGift() async {
    if (_minting || _giftIsOpen) return;

    // **Gated on the KIT, not on preview mode.**
    //
    // Short-circuiting whenever `previewMode` is set would make the replay a
    // dead end for the one thing it exists to test: the mint never happens,
    // `isMinted` stays false, and the theme toggle on the next page — which
    // is gated on holding the kit — can never appear.
    //
    // Preview already writes to chain everywhere else in this flow: the slot
    // fill, the bio save and the card save all send real transactions.
    //
    // Keying on `_citizenKitMinted` is correct in both modes: an
    // account that already holds its kit just opens the box with no
    // transaction, and one that does not gets the mint it came for.
    if (_chain.citizenKitMinted == true) {
      setState(() {
        _giftOpened = true;
        _giftBurst = true;
      });
      return;
    }
    await _mintCitizenKit();
  }

  /// Mint the citizen kit.
  ///
  /// **send → receipt → refresh.** The same three steps every write in this
  /// flow takes: `mintKit` waits for its own receipt inside Core, and the
  /// truth afterwards comes from [_refreshChainState] rather than from a flag
  /// set here.
  ///
  /// `isMinted` must not be read on the line after sending — before the
  /// transaction is mined — or a mint that actually succeeded reads as
  /// failed, and the theme toggle on the next page stays hidden for a kit
  /// the account owns.
  Future<void> _mintCitizenKit() async {
    if (_minting) return;
    final addrHex = _selfAddressHex;
    if (addrHex.isEmpty) return;
    setState(() => _minting = true);

    final account = EthereumAddress.fromHex(addrHex);
    try {
      final tx = await PublicOSCitizenKit.mintKit(account);
      if (tx == null) {
        Log.e('Onboarding', 'Citizen kit mint did not confirm');
      } else {
        Log.d('Onboarding', 'Citizen kit mint confirmed (tx $tx)');
        await _refreshChainState();
      }
    } catch (e) {
      Log.e('Onboarding', 'Citizen kit mint failed: $e');
    }

    if (!mounted) return;
    final minted = _chain.citizenKitMinted == true;
    setState(() {
      _minting = false;
      if (minted) {
        _giftOpened = true;
        _giftBurst = true;
        // If S4c has already been seeded — the user walked forward, came back
        // and minted — its one-shot citizen default has been spent, so apply
        // it now. Without this the one path where the gift is opened second
        // lands on a cards page still previewing the free kit. Still only a
        // preview: the write waits for SAVE, as everywhere else.
        final seeded = _cardSpecsSaved;
        if (seeded != null && _cardThemeSaved != _KitTheme.citizen) {
          _cardThemeDraft = _KitTheme.citizen;
          _cardSpecsDraft = _retheme(
            _cardSpecsDraft ?? seeded,
            _KitSource.citizen,
          );
        }
      }
    });
  }

  /// Fill the profile slots the account has left empty, from its soulbound
  /// kit. Runs in the background the moment S4b is reached.
  ///
  /// **Each slot is judged on its own, and nothing already set is touched.**
  /// The rule per slot:
  ///
  /// | slot | rule |
  /// |---|---|
  /// | pfp | empty → set the kit's `+0` |
  /// | banner | empty → set the kit's `+1` |
  /// | cards | **all-or-nothing** — zero → set all three; one or more → none |
  /// | bio | empty → the picker, which the user answers themselves |
  ///
  /// **Cards are all-or-nothing on purpose.** Dropping three kit cards into a
  /// grid that already holds one would reorder what the user arranged: card
  /// order is `rank`, so new cards are not additions, they are a re-layout.
  ///
  /// **One transaction, not five.** `setMultipleRecords` is atomic, so a
  /// profile can never end up with a banner from the kit and no pfp because
  /// the second write failed halfway.
  ///
  /// No confirmation and no visible progress: records cost no ox, and
  /// the whole point of the screen is that the profile is already theirs when
  /// they look at it. A failure leaves the profile exactly as it was.
  // ── The one definition of "what a kit looks like on a profile" ───────────
  //
  // The theme toggle changes the source used to fill, not the logic of
  // filling. These three builders are what make that true in code rather
  // than in a comment. Both callers — S4b's
  // silent fill and S4c's save — produce their records here, so the two pages
  // cannot drift into writing different shapes for the same thing.
  //
  // **What is shared is the RECORD; what differs is the PREDICATE.** The
  // builder says what a kit looks like; each caller decides which slots it is
  // allowed to touch (S4b: only empty ones · S4c: empty ones, plus ones that
  // belong to the other kit). That split is what keeps a user's own photo safe
  // on both paths.

  NftAvatarRef _refFor(_KitSource source, BigInt id) => NftAvatarRef(
        chain: PublicOS.CHAIN_ID,
        standard: 'erc721',
        contract: source.contract,
        tokenId: id.toString(),
      );

  /// The avatar record for a kit.
  Record _kitAvatarRecord(_KitSource source, List<BigInt> ids) =>
      Record.asSettings(
        key: 'profile.avatar.nft',
        value: _refFor(source, ids[source.pfp]).encode(),
        isSystem: true,
      );

  /// The banner record for a kit.
  Record _kitBannerRecord(_KitSource source, List<BigInt> ids) =>
      Record.asSettings(
        key: 'profile.banner.nft',
        value: _refFor(source, ids[source.banner]).encode(),
        isSystem: true,
      );

  /// The card records for an arrangement.
  ///
  /// **Keys are positional** (`card.kit_0`, `card.kit_1`, …) and shared across
  /// both collections on purpose: a theme switch then *overwrites* index for
  /// index instead of laying a second set beside the first, and the two tiers
  /// can never both occupy the profile.
  ///
  /// Rank order IS packing order — the grid places by rank, so writing in list
  /// order is what reproduces the arrangement that was previewed rather than a
  /// reflow of it.
  List<Record> _kitCardRecords(
      _KitSource source, List<BigInt> ids, List<_CardSpec> specs) {
    final expiration = Record.never; // records do not expire
    String? rank;
    final out = <Record>[];
    var kitIndex = 0;
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      rank = keyBetween(rank, null);
      // A prefill card is already its own record; it only takes its rank.
      final prefill = spec.prefill;
      if (prefill != null) {
        out.add(prefill.copyWith(rank: rank));
        continue;
      }
      final id = ids[spec.offset];
      final k = kitIndex++;
      out.add(Record.asProfile(
        // Several tiles can reuse the same token, so the id alone would
        // collide — the index makes each record its own key while the VALUE
        // stays the shared NFT pointer. Counted over KIT tiles only, so the
        // specials interleaved among them leave no gaps in the numbering.
        key: 'card.kit_$k',
        value: _refFor(source, id).encode(),
        expiration: expiration,
        width: spec.w,
        height: spec.h,
        noTitle: true,
        rank: rank,
        customMetadataAttributes: {
          'cardKind': 'nft',
          'name': 'NFT #$id',
          // Keeps RecordButton's Hero / overlay behaviour consistent with
          // image cards.
          'isImageRecord': true,
        },
      ));
    }
    return out;
  }

  /// Does this record point at [source]'s contract? **The test for "ours to
  /// replace"** — a record pointing at the other kit is one this flow wrote
  /// and may rewrite; anything else is the user's.
  bool _pointsAt(Record r, _KitSource source) {
    final ref = NftAvatarRef.tryParse(r.value);
    return ref != null &&
        ref.contract.toLowerCase() == source.contract.toLowerCase();
  }

  Future<void> _fillEmptyProfileSlots() async {
    if (_slotsChecked) return;
    _slotsChecked = true; // once per run, whatever the outcome

    final addrHex = _selfAddressHex;
    if (addrHex.isEmpty) return;

    try {
      final account = EthereumAddress.fromHex(addrHex);
      final ids = await _ensureKitIds(account);
      if (ids == null) {
        // No kit — either the mint never landed or the read failed. Nothing to
        // write, and nothing to say about it on screen.
        Log.d('Onboarding', 'No kit for this account — no slots filled');
        return;
      }

      // The emptiness test is only as good as the profile it reads. An
      // unresolved contact has NO records, which is indistinguishable from an
      // account with an empty profile — and acting on that would paint kit art
      // over a profile the user had already filled. Not knowing is not the
      // same as empty, so an unresolved contact writes nothing and the run is
      // released for a later pass.
      final contact = AppStateNotifier.currentMyContact ?? _selfContact;
      if (contact == null) {
        Log.d('Onboarding', 'Own profile not loaded yet — no slots filled');
        _slotsChecked = false;
        return;
      }
      final records = contact.records;
      bool isSet(String key) =>
          records.any((r) => r.key == key && r.value.isNotEmpty);

      // **The fill is SOULBOUND and stays soulbound.** Its
      // job is not to place a theme — it is to make sure an account that never
      // personalises anything still has a profile worth looking at. The
      // citizen tier is offered one page later, as a gift, and swapped in only
      // if the user asks for it on S4c.
      const source0 = _KitTheme.soulbound;
      final source = _KitSource.of(source0);
      final batch = <Record>[];

      // ── pfp and banner — judged independently ──
      // Both surfaces have two records: a plain URL and an `.nft` pointer that
      // wins the render. Either one counts as "already set", or a user with a
      // photo would get a kit pointer silently painted over it.
      if (!isSet('profile.avatar') && !isSet('profile.avatar.nft')) {
        batch.add(_kitAvatarRecord(source, ids));
      }
      // A page background with no banner IS the banner (Core's
      // `bannerIsBackground`, on every host), so that slot is taken too: a
      // kit pointer there would paint over the owner's own picture.
      if (!isSet('profile.banner') &&
          !isSet('profile.banner.nft') &&
          contact.backgroundUrl == null) {
        batch.add(_kitBannerRecord(source, ids));
      }

      // ── cards — all, or none ──
      // Ranks are assigned by the builder rather than left null: an unranked
      // card dropped into a ranked grid reorders it, and these arrive
      // together, so their order is ours to fix.
      //
      // The cards are a random layout with the prefill's special cards in
      // it. The all-or-nothing rule holds: a profile with even one card of
      // its own gets none of this.
      final hasAnyCard =
          records.any((r) => r.profileSubtype == ProfileSubtype.card);
      if (!hasAnyCard) {
        await _loadMainSafe(); // the tip card's pay-to
        batch.addAll(_kitCardRecords(
          source,
          ids,
          _randomLayout(_rng, source, _rollPrefills()),
        ));
      }

      if (batch.isEmpty) {
        Log.d('Onboarding', 'Profile already personalised — nothing to fill');
        return;
      }

      Log.d('Onboarding', 'Filling ${batch.length} empty profile slots');
      final ok = await PublicOSContacts.setMultipleRecords(batch);
      Log.d(
        'Onboarding',
        ok ? 'Profile slots filled' : 'Profile slot fill returned false',
      );
      if (ok) {
        // The kit strip and the card both read the contact, so a successful
        // write should show up without leaving the page.
        if (mounted) setState(() {});
      } else {
        // A send that timed out or was rejected did NOT happen, so the run is
        // released and coming back to this page tries again. Latching the flag
        // on a failure would leave the profile empty for the rest of the tour
        // with no way to retry.
        _slotsChecked = false;
      }
    } catch (e) {
      // Never surfaces. A profile that could not be decorated is not a reason
      // to interrupt onboarding — but it is not done either, so let a later
      // pass retry it.
      _slotsChecked = false;
      Log.e('Onboarding', 'Profile slot fill failed: $e');
    }
  }

  /// Write S4b's bio as the account's `profile.bio` record.
  ///
  /// Same record the profile page's own bio editor writes — key, subtype and
  /// metadata all match `_showBioDialog`, so a bio set here is editable there
  /// afterwards with nothing special about it.
  ///
  /// No-op when the user chose nothing. Deliberately never overwrites an
  /// existing bio: S4b only fills empty slots, and the picker is only shown
  /// for an account that has none.
  /// Write the chosen bio, and wait for it.
  ///
  /// **Explicit and awaited**, unlike every other slot on this page. The art
  /// is written silently because the user never asked for it; the bio is the
  /// one thing they typed, so it gets a button that says SAVE CHANGES, a
  /// visible SAVING… state, and a result they can see before moving on.
  ///
  /// Same `profile.bio` record the profile page's own editor writes, so a bio
  /// set here is editable there afterwards with nothing special about it.
  Future<void> _saveBio() async {
    final bio = _bioCurrent;
    if (bio == null || bio.isEmpty || _bioSaving) return;
    setState(() => _bioSaving = true);

    var ok = false;
    try {
      ok = await PublicOSContacts.setRecord(
        Record.asProfile(
          key: 'profile.bio',
          value: bio,
          icon: Icons.person_rounded.codePoint,
          customMetadataAttributes: const {
            'bioTextColor': 0xFFFFFFFF,
            'bioBorderVisible': false,
            'bioBorderColor': 0xFF9E9E9E,
            'bioBorderWidth': 1.0,
            'borderRadius': 16.0,
          },
        ),
      );
      Log.d('Onboarding', ok ? 'Bio written' : 'Bio write returned false');
    } catch (e) {
      Log.e('Onboarding', 'Bio write failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _bioSaving = false;
      // Only a confirmed write clears the dirty state. A failed one leaves the
      // button on SAVE CHANGES, which is the honest thing for it to say.
      if (ok) _bioSavedLocal = bio;
    });
  }

  /// The account's card records, **in grid order**.
  ///
  /// Sorted by `rank`, because that is what the grid places by — the order
  /// they happen to sit in on the contact is not the order they appear in.
  /// Seeding the saved arrangement from unsorted records would make *undo*
  /// restore a different layout from the one that was saved.
  List<Record> get _cardRecords {
    final contact = AppStateNotifier.currentMyContact ?? _selfContact;
    final cards = (contact?.records ?? const <Record>[])
        .where((r) => r.profileSubtype == ProfileSubtype.card)
        .toList();
    cards.sort((a, b) => (a.rank ?? '').compareTo(b.rank ?? ''));
    return cards;
  }

  /// Which collection this profile's cards belong to, or `null` if they are
  /// not (all) a kit's.
  ///
  /// Decided from the records rather than from a "we wrote them" flag, because
  /// the flag is gone the moment the app restarts while the records are not.
  /// **The record already carries its own attribution** — an `NftAvatarRef`
  /// stores the contract address — so no extra state is needed to tell the
  /// tiers apart.
  ///
  /// Every card must point at the **same** kit. A profile with even one card
  /// of the user's own is theirs and an intro screen does not get to rearrange
  /// it; and a profile holding **both** tiers at once (a half-failed swap) is
  /// deliberately treated the same way — the arrangement it would restore on
  /// undo is not one this screen can name.
  _KitTheme? get _cardsKitTheme {
    final cards = _cardRecords;
    if (cards.isEmpty) return null;
    _KitTheme? seen;
    for (final r in cards) {
      // The prefill's special cards are the tour's too — known by their key
      // prefix — so they neither count as the user's nor name a theme.
      if (_isPrefillKey(r.key)) continue;
      final ref = NftAvatarRef.tryParse(r.value);
      if (ref == null) return null;
      final c = ref.contract.toLowerCase();
      final theme = c == _KitSource.soulbound.contract.toLowerCase()
          ? _KitTheme.soulbound
          : c == _KitSource.citizen.contract.toLowerCase()
              ? _KitTheme.citizen
              : null;
      if (theme == null) return null;
      if (seen != null && seen != theme) return null; // mixed tiers
      seen = theme;
    }
    return seen;
  }

  /// Whether the cards on this profile are **a kit's**, and therefore ours to
  /// offer shuffling.
  bool get _showingKitCards => _cardsKitTheme != null;

  /// The token ids for one collection.
  ///
  /// Soulbound's are a chain read cached on the flow; **the citizen tier's are
  /// pure arithmetic** — the account rides inside the id — so they resolve
  /// instantly and work for an account that has never minted.
  List<BigInt>? _idsFor(_KitTheme theme) {
    if (theme == _KitTheme.citizen) {
      final hex = _selfAddressHex;
      if (hex.isEmpty) return null;
      return PublicOSCitizenKit.tokenIdsFor(EthereumAddress.fromHex(hex));
    }
    return _kitIds;
  }

  /// The art map for one collection, in the shape the preview widgets want.
  Map<int, String>? _artFor(_KitTheme theme) =>
      theme == _KitTheme.citizen ? _citizenArt : _kitArt;

  /// Read the stored arrangement back off the records, so *undo* returns to
  /// what is actually on chain rather than to whatever this build happens to
  /// consider the default.
  /// **The arithmetic is the same for both tiers.** Soulbound's five ids are
  /// consecutive by construction; the citizen tier's thirteen are too, because
  /// `tokenId = (uint160(account) << 8) | tile` and `tile < 13 < 256` leaves
  /// the low byte free. So `id - first` recovers the offset either way — only
  /// the upper bound is per-collection.
  List<_CardSpec>? _specsFromRecords(_KitTheme theme) {
    final ids = _idsFor(theme);
    if (ids == null || ids.isEmpty) return null;
    final source = _KitSource.of(theme);
    final first = ids.first;
    final out = <_CardSpec>[];
    for (final r in _cardRecords) {
      if (_isPrefillKey(r.key)) {
        out.add((offset: -1, w: r.width, h: r.height, prefill: r));
        continue;
      }
      final ref = NftAvatarRef.tryParse(r.value);
      if (ref == null) return null;
      final id = BigInt.tryParse(ref.tokenId);
      if (id == null) return null;
      final offset = (id - first).toInt();
      if (offset < 0 || offset >= source.pieces) return null;
      out.add((offset: offset, w: r.width, h: r.height, prefill: null));
    }
    return out.isEmpty ? null : out;
  }

  /// Seed the saved arrangement once, when S4c is first shown — and, for a
  /// citizen who holds their kit, **open on the citizen theme**.
  ///
  /// **One rule serves both populations** (an account with a citizen
  /// collection defaults to citizen), which is why it is a default rather
  /// than a special case:
  ///
  /// | who | on chain | opens on | dirty? |
  /// |---|---|---|---|
  /// | just minted at S4d | soulbound (from S4b's fill) | citizen | **yes — SAVE is lit on arrival** |
  /// | returning citizen, already swapped | citizen | citizen | no |
  ///
  /// **Nothing auto-saves.** The default decides what is *previewed*; the
  /// write still needs the button. Without it a citizen could mint a gift on
  /// the page before and never once see it.
  void _seedCardSpecs() {
    if (_cardSpecsSaved != null) return;
    final theme = _cardsKitTheme;
    if (theme == null) return; // not a kit profile — nothing to seed
    final fromChain = _specsFromRecords(theme);
    if (fromChain == null) return;
    setState(() {
      _cardSpecsSaved = fromChain;
      _cardThemeSaved = theme;
      if (_canToggleTheme && theme != _KitTheme.citizen) {
        _cardThemeDraft = _KitTheme.citizen;
        _cardSpecsDraft = _retheme(fromChain, _KitSource.citizen);
      }
    });
  }

  /// Carry an arrangement across to another collection: **same footprints,
  /// new art**.
  ///
  /// The layout is the user's; the theme is only where the pictures come from.
  /// Re-deriving each offset from its own `w`/`h` (rather than mapping offset
  /// to offset) is what keeps a stretched piece on its own axis, and it is the
  /// same call the randomiser makes — one definition, two callers.
  List<_CardSpec> _retheme(List<_CardSpec> specs, _KitSource to) => [
        for (final s in specs)
          s.prefill != null
              ? s // a prefill card has no kit art to swap
              : (
                  offset: to.offsetForShape(s.w, s.h, _rng),
                  w: s.w,
                  h: s.h,
                  prefill: null,
                ),
      ];

  /// A new layout AND new special cards: RANDOMIZE re-rolls the specials'
  /// image, line, gradient and background too.
  void _randomizeCards() {
    setState(() => _cardSpecsDraft =
        _randomLayout(_rng, _cardSource, _rollPrefills()));
  }

  /// Switch the source the cards are filled from.
  void _setCardTheme(_KitTheme theme) {
    if (theme == _cardTheme) return;
    final base = _cardSpecs;
    setState(() {
      _cardThemeDraft = theme == _cardThemeSaved ? null : theme;
      if (base != null) {
        final rethemed = _retheme(base, _KitSource.of(theme));
        // Returning to the stored theme with the stored arrangement is not a
        // change — drop the draft so the button goes quiet, instead of
        // offering to save what is already there.
        _cardSpecsDraft = (theme == _cardThemeSaved &&
                _cardSpecsSaved != null &&
                _sameShapes(rethemed, _cardSpecsSaved!))
            ? null
            : rethemed;
      }
    });
  }

  /// Footprint-only comparison — the kit art may differ, the layout may not.
  /// A prefill card must also match in CONTENT: a reroll that kept every
  /// footprint but swapped the PublicOS image is still a change to save.
  static bool _sameShapes(List<_CardSpec> a, List<_CardSpec> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].w != b[i].w || a[i].h != b[i].h) return false;
      if (_prefillSignature(a[i].prefill) != _prefillSignature(b[i].prefill)) {
        return false;
      }
    }
    return true;
  }

  /// Discard both the arrangement and the theme together — they were changed
  /// as one thing, so they come back as one thing.
  void _undoCards() {
    setState(() {
      _cardSpecsDraft = null;
      _cardThemeDraft = null;
    });
  }

  /// Persist the previewed arrangement.
  ///
  /// **Keys are positional** (`card.kit_0`, `card.kit_1`, …) so a new
  /// arrangement OVERWRITES the old one instead of piling up beside it. A
  /// shuffle can produce fewer tiles than the last, and there is no bulk
  /// delete anywhere in the system, so any
  /// surplus index is deleted one at a time — a handful of calls at most.
  /// The self contact as **S4c should draw it** — pfp and banner swapped to the
  /// previewed theme.
  ///
  /// The cards grid previews the draft from in-memory records, but the account
  /// card above it renders the real ones — so without this, picking CITIZEN
  /// changes the cards and leaves a soulbound pfp and banner sitting on top
  /// of them: two themes at once, only one of which SAVE would write.
  ///
  /// **Uses the same predicate as [_saveCards], deliberately.** An empty slot
  /// is filled, a slot holding the other kit is swapped, and anything else — a
  /// URL, a photo, an NFT the user owns — is left alone. Preview and save
  /// asking the same question is what makes the page honest: what is on screen
  /// is what the button will write, including when the answer is "nothing".
  ///
  /// The cached verdicts are blanked because a stale one still points at the
  /// *other* kit's art and would win over the swapped record. Emptied rather
  /// than nulled: `copyWith` is `??`-based and cannot clear a field, while
  /// `VerifiedNftAvatar.tryParse` returns null for unparseable input, which
  /// drops both widgets onto their resolve-for-display fallback.
  Contact _themedSelfContact(Contact base) {
    final theme = _cardThemeDraft;
    if (theme == null) return base; // nothing previewed — show the truth
    final ids = _idsFor(theme);
    if (ids == null) return base;

    final source = _KitSource.of(theme);
    final other = _KitSource.of(
      theme == _KitTheme.citizen ? _KitTheme.soulbound : _KitTheme.citizen,
    );

    final records = [...base.records];
    Record? at(String key) {
      for (final r in records) {
        if (r.key == key && r.value.isNotEmpty) return r;
      }
      return null;
    }

    bool swap(String key, Record replacement) {
      final plain = key.replaceAll('.nft', '');
      if (at(plain) != null) return false; // the user has their own
      final existing = at(key);
      if (existing != null && !_pointsAt(existing, other)) return false;
      records.removeWhere((r) => r.key == key);
      records.add(replacement);
      return true;
    }

    final avatarSwapped =
        swap('profile.avatar.nft', _kitAvatarRecord(source, ids));
    final bannerSwapped =
        swap('profile.banner.nft', _kitBannerRecord(source, ids));

    // ── The verdicts have to be SYNTHESISED, not cleared ──
    //
    // The two surfaces resolve differently and only one of them forgives a
    // miss. `NftBanner` re-resolves when the cached verdict does not match, so
    // blanking it merely costs a round trip. **`GlassContactIcon._resolve()` is
    // synchronous and never resolves an NFT itself** — a usable verdict is its
    // *only* route to NFT art, and without one it falls through to
    // `profile.avatar.resolved` / `avatarUrl` and then to initials. Blanking
    // both changes the banner and turns the pfp into a letter.
    //
    // So the preview builds a verdict of its own, from art the flow already
    // holds. `verifiedOwnership: true` is honest here: both kits live in the
    // account's own MainSafe, which is the same thing the real verifier checks.
    final art = _artFor(theme);
    String? verdict(int pieceOffset) {
      final image = art?[pieceOffset];
      if (image == null) return null;
      return VerifiedNftAvatar(
        pointer: _refFor(source, ids[pieceOffset]),
        metadata: {'image': image},
        verifiedOwnership: true,
        checkedAt: DateTime.now(),
      ).encode();
    }

    final avatarVerdict = avatarSwapped ? verdict(source.pfp) : null;
    final bannerVerdict = bannerSwapped ? verdict(source.banner) : null;

    return base.copyWith(
      records: records,
      // `copyWith` is `??`-based, so passing null leaves the stored verdict —
      // which is correct for a surface we did not swap.
      verifiedNftAvatar: avatarVerdict,
      verifiedNftBanner: bannerVerdict,
    );
  }

  /// Persist what the screen is showing — arrangement **and** theme.
  ///
  /// **All three surfaces move together**: the toggle moves pfp, banner and
  /// cards, matching what the fill covers.
  /// A profile wearing a citizen avatar over soulbound cards is not a theme,
  /// it is a half-applied one.
  ///
  /// ⚠ **The predicate is what protects the user, not the builder.** pfp and
  /// banner are rewritten **only when the record there points at the other
  /// kit** — i.e. only when this flow put it there. A photo the user chose is
  /// left exactly where it is, which is the same guarantee S4b's fill makes,
  /// expressed for a surface that is no longer empty.
  Future<void> _saveCards() async {
    final specs = _cardSpecs;
    final theme = _cardTheme;
    final ids = _idsFor(theme);
    if (specs == null || ids == null || _cardsSaving) return;
    setState(() => _cardsSaving = true);

    final source = _KitSource.of(theme);
    final other = _KitSource.of(
      theme == _KitTheme.citizen ? _KitTheme.soulbound : _KitTheme.citizen,
    );

    // Every card key on the profile BEFORE this save. Saving is defined as
    // "the profile ends up showing exactly what the screen shows", so anything
    // outside the new set has to go — see the delete pass below.
    final existingKeys = _cardRecords.map((r) => r.key).toSet();
    var ok = false;
    try {
      final batch = _kitCardRecords(source, ids, specs);

      // ── pfp and banner: replace ONLY the other kit's own pointers ──
      final contact = AppStateNotifier.currentMyContact ?? _selfContact;
      final records = contact?.records ?? const <Record>[];
      Record? at(String key) {
        for (final r in records) {
          if (r.key == key && r.value.isNotEmpty) return r;
        }
        return null;
      }

      // An empty slot is filled; a slot holding the other kit is swapped; a
      // slot holding anything else — a URL, a photo, an NFT the user owns — is
      // untouched. `profile.avatar` (the plain URL form) existing at all means
      // the user has their own, so the `.nft` pointer is not ours to write.
      final avatarNft = at('profile.avatar.nft');
      if (at('profile.avatar') == null &&
          (avatarNft == null || _pointsAt(avatarNft, other))) {
        batch.add(_kitAvatarRecord(source, ids));
      }
      final bannerNft = at('profile.banner.nft');
      if (at('profile.banner') == null &&
          (bannerNft == null || _pointsAt(bannerNft, other))) {
        batch.add(_kitBannerRecord(source, ids));
      }

      ok = await PublicOSContacts.setMultipleRecords(batch);
      if (ok) {
        // Delete every card that is NOT in the new set — by DIFFING THE REAL
        // RECORDS, not by counting indices.
        //
        // Counting indices is wrong twice over. It can only ever reach keys
        // this build happens to write, so cards under any other key scheme
        // become orphans that nothing in the app can remove. And it counts
        // keys that may not exist — `deleteRecord` REVERTS on a missing key,
        // so an over-count aborts the sweep mid-way.
        //
        // A diff has neither failure: it only ever names keys just read off
        // the profile, so every one of them exists, and it catches foreign
        // schemes, shrunken layouts and anything left by an older build.
        // Only CARD keys are swept. `existingKeys` is built from
        // `_cardRecords`, so the avatar and banner records added to the batch
        // above are never candidates for deletion — they are settings, not
        // cards, and a theme switch replaces them in place.
        //
        // `deleteRecord` reports failure by returning false, not by throwing,
        // so its result is what counts. A key
        // left behind makes the save a failure: the button stays on SAVE
        // CHANGES, and the next save's diff names the leftover again.
        final keep = batch.map((r) => r.key).toSet();
        var allRemoved = true;
        for (final key in existingKeys.where((k) => !keep.contains(k))) {
          // One stubborn key must not abort the rest of the sweep.
          if (await PublicOSContacts.deleteRecord(key)) {
            Log.d('Onboarding', 'Removed stale card $key');
          } else {
            allRemoved = false;
            Log.e('Onboarding',
                'Could not remove $key: ${PublicOS.lastError ?? 'unknown'}');
          }
        }
        if (!allRemoved) ok = false;
      }
      Log.d(
          'Onboarding',
          ok
              ? 'Card layout saved (${specs.length})'
              : 'Card save returned false');
    } catch (e) {
      Log.e('Onboarding', 'Card save failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _cardsSaving = false;
      // Only a confirmed write clears the dirty state; a failure leaves the
      // button on SAVE CHANGES, which is what it should say.
      if (ok) {
        _cardSpecsSaved = specs;
        _cardThemeSaved = theme;
        _cardSpecsDraft = null;
        _cardThemeDraft = null;
      }
    });
  }

  /// Discard the unsaved choice and go back to what is stored.
  void _undoBio() {
    setState(() {
      _bioDraft = null;
      _bioPickerEpoch++;
    });
  }

  /// Whether S3's gate is open.
  ///
  /// Three inputs, and the third is the interesting one: the sequence was
  /// walked this session, OR the account already publishes an inbox, OR **we
  /// could not tell** — see [_ChainState.hasRegisteredInbox] for why unknown
  /// opens rather than closes.
  bool get _inboxDone => _inboxCreated || _chain.hasRegisteredInbox != false;

  /// Hand off to the coach sequence, then let the chain say what happened.
  ///
  /// The stage's return value is not trusted as state — it decides nothing.
  /// [_refreshChainState] re-reads `getAllAccountInboxIds` on the way back and
  /// that read is what moves the gate, which is the same rule every other write
  /// in this flow follows: **no writer sets a fact by hand.** `_inboxCreated`
  /// stays as the record that the user *walked* the sequence, which is a
  /// different fact from whether an inbox exists and is worth keeping apart —
  /// someone who completes the walk and whose confirming read then times out
  /// should not be sent round again.
  Future<void> _addFirstInbox() async {
    // `CupertinoPageRoute`, not `MaterialPageRoute` — and not
    // `fullscreenDialog` either. Material's slide-UP is the one route
    // animation nothing else in this app uses (BSP, SSP, Treasury and the
    // Browser all slide horizontally), so the stage would arrive like a
    // modal in a tour that otherwise moves sideways, and lose the iOS
    // edge-swipe-back. Horizontal in, horizontal out, and the tour page it
    // came from parallaxes underneath instead of being covered.
    final walked = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        builder: (_) => const OnboardingExplorerStage(),
      ),
    );
    if (!mounted) return;
    if (walked == true) setState(() => _inboxCreated = true);
    await _refreshChainState();
  }

  /// Opens the real Domain Store sheet — the same widget the account center
  /// uses. `showStatus: true` because this page has no status header of its
  /// own above the sheet.
  /// Open the Domain Store, then re-read the domain on the way back.
  ///
  /// Paying is the one thing on S1 that can change the shape of the rest of
  /// the tour, and the opening read in [initState] is already stale by then.
  /// Without this re-read the exact user this step exists for — someone who
  /// arrives lapsed and pays during S1 — finishes the session with no kit and
  /// no profile step, because `_domainCompliant` is still the `false` the
  /// first read returned.
  ///
  /// Same rule as every other gate here: the step completes on the RETURN, not
  /// on the tap. [_loadDomainStatus] re-runs the whole gate, so the mint fires
  /// from its usual place and needs no special case of its own.
  Future<void> _openDomainStore() async {
    // `closeOnPaid`: here the sheet was opened to pay, so a payment that
    // lands closes it and the tour moves on from the re-read below.
    await showDomainStoreSheet(context, showStatus: true, closeOnPaid: true);
    if (!mounted) return;
    setState(() => _domainStoreOpened = true);
    await _refreshChainState();
  }

  /// Live domain status shown under the S1 body: free for life / paid until a
  /// date / reserved (lapsed) and needing cover. Null until the read lands or
  /// if it failed — the page still works, it just says less.
  Widget? _domainStatusCallout(GlassTokens tokens) {
    final paid = _chain.domainPaidUntil;
    if (!_chainRead || paid == null || paid == BigInt.zero) {
      return null;
    }

    final String text;
    final Color tone;
    final IconData icon;
    final klass = _domainClass;
    if (klass == _DomainClass.citizen) {
      text = 'Your domain is free as a right.';
      tone = tokens.starkWhite;
      icon = Icons.verified_outlined;
    } else if (klass == _DomainClass.paidPrivate) {
      final dt = DateTime.fromMillisecondsSinceEpoch(paid.toInt() * 1000);
      text = 'Your domain is paid until ${_fmtStatusDate(dt)}.';
      tone = tokens.starkWhite;
      icon = Icons.event_available_outlined;
    } else {
      final grace = _chain.domainGrace ?? BigInt.zero;
      final until =
          DateTime.fromMillisecondsSinceEpoch((paid + grace).toInt() * 1000);
      text = 'Your domain is reserved until ${_fmtStatusDate(until)}, '
          'pay the domain fee to keep it.';
      tone = const Color(0xFFFFAB40);
      icon = Icons.schedule_outlined;
    }

    // A plain legend (no box / border) so it reads as non-interactive status —
    // the bordered glass pill is reserved for the real action below it.
    final attention = tone != tokens.starkWhite; // amber = lapsed/reserved
    final textColor = attention ? tone : tokens.textDim;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 15, color: tone),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtStatusDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final steps = _steps;
    // The gate can shrink the flow after a chain read lands, so a settled page
    // index can briefly point past the end.
    final page = _page.clamp(0, steps.length - 1);
    final isLastPage = page == steps.length - 1;

    // Steps that gate the primary until their own action has been done. Both
    // work the same way — the step completes on the RETURN, not on the tap.
    // A locked CTA reads its precondition into its own label
    // rather than showing a greyed CONTINUE the user cannot explain.
    final String? lockReason = switch (steps[page]) {
      // Confirmed lapsed only. An unread domain (null) never locks: a failed
      // chain read must not be what holds someone on this page.
      _Step.domain
          when _chain.domainCompliant == false && !_domainStoreOpened =>
        l10n.onbDomainManageFirst,
      _Step.account when !_orgTabsOpened => l10n.onbAccountOpenTabsFirst,
      // A bio is the one thing S4b asks the user FOR — the art it writes
      // silently. Nobody leaves this page without one.
      _Step.profile when _bioCurrent == null => l10n.onbProfileChooseBioFirst,
      // Mid-write: locked, and saying so.
      _Step.profile when _bioSaving => l10n.onbBioSaving,
      _Step.cards when _cardsSaving => l10n.onbCardsSaving,
      // Mid-mint: locked, and saying so. Thirteen `_safeMint`s in one
      // transaction is not instant, and a live button during it would invite a
      // second send.
      _Step.gift when _minting => l10n.onbGiftMinting,
      _Step.yours when !_inboxDone => l10n.onbYoursCreateInboxFirst,
      // ── S6 ──
      //
      // The page's primary is its ACTION while anything is missing (see
      // `s6Auto` below), so the only states that lock it are the ones where
      // pressing it could not do anything: mid-write, not read yet, class
      // unresolved, or an attempt that already failed. In every one of those
      // the way forward is SKIP — which privates always have and citizens earn
      // the moment something breaks, so the lock is never uncloseable.
      _Step.providers when _s6Running => l10n.onbProvWorking,
      _Step.providers
          when !_s6Skipped &&
              (_s6State == _S6.loading ||
                  _s6State == _S6.unknown ||
                  _s6State == _S6.failed) =>
        l10n.onbProvSetUpFirst,
      _ => null,
    };
    final locked = lockReason != null;

    /// S6's primary IS the one-tap setup while a service is missing — the same
    /// two-stage shape S4b and S4d use, one page later: it does the page's work
    /// and stays put, and only once both services are live does it become the
    /// plain continue. Its label names the axis it is about to handle.
    final s6Auto = steps[page] == _Step.providers &&
        !_s6Skipped &&
        (_s6State == _S6.needBoth ||
            _s6State == _S6.needBsp ||
            _s6State == _S6.needSsp);

    // S4b's primary is a TWO-STAGE button, which is why it cannot just be a
    // label: with unsaved changes it SAVES and stays put, and only once the
    // write has landed does it become the plain continue. The user watches
    // the save finish rather than have it slip out the door behind them.
    // Both S4b and S4c use the same two-stage primary: with unsaved changes
    // it SAVES and stays put, and only once the write lands does it become the
    // plain continue.
    final saveBio = steps[page] == _Step.profile && _bioDirty;
    final saveCards = steps[page] == _Step.cards && _cardsDirty;

    // S4d's primary is the same two-stage shape, one beat earlier: it says
    // OPEN GIFT until the gift is open, then CONTINUE.
    //
    // ⚠ **Not gated on `previewMode`.** Such a gate would not keep preview
    // safe — it would make the page's one control unreachable and leave the
    // primary saying CONTINUE over a gift nobody could open. `_openGift`
    // draws the preview/live line where it belongs: at the transaction.
    final openGift = steps[page] == _Step.gift && !_giftIsOpen;
    final saveFirst = saveBio || saveCards;

    final primaryLabel = lockReason ??
        (openGift
            ? l10n.onbGiftOpen
            : s6Auto
                ? switch (_s6State) {
                    _S6.needBsp => l10n.onbProvAutoBsp,
                    _S6.needSsp => l10n.onbProvAutoSsp,
                    _ => l10n.onbProvAuto,
                  }
                : saveFirst
                    ? l10n.onbBioSaveChanges
                    : isLastPage
                        ? (widget.previewMode ? l10n.onbDone : l10n.onbEnter)
                        : l10n.onbContinue);
    final VoidCallback primaryAction = openGift
        ? _openGift
        : s6Auto
            ? _runS6Auto
            : saveBio
                ? _saveBio
                : (saveCards ? _saveCards : _next);

    /// Whether pressing the primary PERFORMS the page's action rather than
    /// merely leaving it — which is what earns the solid white treatment.
    /// Opening the gift mints, saving writes, and the last page enters the
    /// app; plain CONTINUE does none of those and goes ghost.
    final commits = openGift || saveFirst || isLastPage || s6Auto;

    /// Whether this step may be LEFT — the predicate the forward swipe uses.
    ///
    /// Not the same question as `locked`, and conflating them leaves the
    /// biggest gates open. On S4d, S4b/S4c and S6 the primary is not disabled
    /// at all: it is doing the page's own work — open the gift, save the
    /// changes, set up the providers — so `locked` is false while the step is
    /// still very much unfinished. The honest test is **would pressing the
    /// primary actually move us on**, and only a plain CONTINUE does that.
    final canAdvance = !locked && !openGift && !saveFirst && !s6Auto;

    return Scaffold(
      backgroundColor:
          widget.drawBackground ? tokens.background : Colors.transparent,
      body: Stack(
        children: [
          if (widget.drawBackground)
            const Positioned.fill(child: ConstellationBackground()),
          SafeArea(
            child: Column(
              children: [
                // NO SKIP — with exactly one exception, and it is narrow on
                // purpose.
                //
                // A top-right SKIP is how setups never get done, so no
                // teaching page has one. S6 is
                // different in kind: it is the one step that can ask a user for
                // *money*, and the one whose outcome a user can legitimately
                // already have arranged for themselves — a private running
                // their own node with a custom RPC gets nothing from a BSP
                // subscription. So a private always has a way past it, and a
                // citizen earns one the moment an attempt actually fails
                // ([_s6ShowSkip]) — because a locked step with no exit is worse
                // than a skip link.
                //
                // It reserves its height either way, so no page shifts under
                // the user when the exit appears mid-flow.
                SizedBox(
                  height: 46,
                  child: steps[page] == _Step.providers && _s6ShowSkip
                      ? Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: TextButton(
                              onPressed: _onS6Skip,
                              child: Text(
                                l10n.onbProvSkip,
                                style: TextStyle(
                                  // Brighter once it is an EXIT from a failure
                                  // rather than a standing option — the same
                                  // link, doing a different job.
                                  color: _s6SkipUnlocked
                                      ? tokens.fallbackAccent
                                      : tokens.textDim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) {
                      setState(() => _page = i);
                      // The art is written the moment S4b is reached, in the
                      // background — by the time the user has read the page,
                      // the profile behind it is already theirs.
                      // S4c seeds its arrangement from what is on chain, so
                      // undo returns to the real thing rather than a default.
                      if (steps[i] == _Step.cards) {
                        _seedCardSpecs();
                        // Also warmed on S4b, but S4c is the page that cannot
                        // do its job without it — a shuffled preview paints
                        // from this map, so it must not depend on the previous
                        // page having been visited.
                        _loadKitArt();
                      }
                      if (steps[i] == _Step.profile) {
                        _fillEmptyProfileSlots();
                        // Warm the kit art here, one page before S4c needs it
                        // as a fallback — resolved once and kept for the run.
                        _loadKitArt();
                      }
                      // The shimmer is REAL LOADING, not a stand-in for it:
                      // `previewSVG` renders an unminted kit, so the thirteen
                      // pieces resolve while the page holds their shapes, and
                      // the reveal has nothing left to wait for.
                      if (steps[i] == _Step.gift) {
                        _giftReached = true;
                        _loadCitizenArt();
                      }
                    },
                    // ── A locked step cannot be swiped past ──
                    //
                    // The primary button reads its precondition into its own
                    // label and refuses to advance, but a freely scrollable
                    // PageView would let every gate in the tour (open the
                    // tabs sheet, choose a bio, publish an inbox, set up your
                    // providers) be walked straight past with a thumb. That
                    // is a SKIP link wearing a different coat.
                    //
                    // Blocking it by TRUNCATING the list rather than by killing
                    // the scroll physics, because the two directions are not
                    // the same question: going forward past an unmet gate is
                    // the thing to stop, going BACK is always legitimate — the
                    // flow re-checks its facts on back-navigation and a user
                    // re-reading an earlier page skips nothing. With no page
                    // built beyond the current one there is simply nothing to
                    // swipe onto, and the backward swipe is untouched.
                    //
                    // Keyed on `canAdvance`, NOT on `locked`: the pages
                    // whose primary is busy doing their own work (the
                    // gift, a save, the providers) are the ones most worth
                    // holding, and they are not "locked" at all.
                    itemCount: canAdvance ? steps.length : page + 1,
                    itemBuilder: (context, i) {
                      switch (steps[i]) {
                        case _Step.publicOs:
                          return _ScrollSafePage(
                            child: _LogoTextPage(copy: _s0PublicOs(l10n)),
                          );
                        case _Step.domain:
                          return _ScrollSafePage(
                            child: ListenableBuilder(
                              listenable: AppStateNotifier.instance!,
                              builder: (context, _) => _CardOverTextPage(
                                body: _s1Domain(l10n, _domainClass),
                                contact: AppStateNotifier.currentMyContact ??
                                    _selfContact ??
                                    _fallbackSelfContact(),
                                address: _selfAddressHex,
                                nameFocus: 1,
                                statusCallout: _domainStatusCallout(tokens),
                                actionLabel: 'MANAGE MY DOMAIN',
                                onAction: _openDomainStore,
                              ),
                            ),
                          );
                        case _Step.account:
                          return _ScrollSafePage(
                            child: _CardOverTextPage(
                              body: _s2Account(l10n),
                              contact: _orgContact ?? _fallbackOrgContact(),
                              address:
                                  _orgContact?.publicosAddress?.eip55With0x ??
                                      '',
                              // The card's own tab switcher, pulsing until it
                              // has been opened. This is the page's only
                              // affordance and the thing that unlocks NEXT.
                              onTabs: _openOrgTabs,
                              tabsAttention: !_orgTabsOpened,
                            ),
                          );
                        case _Step.profile:
                          return _ScrollSafePage(
                            child: ListenableBuilder(
                              listenable: AppStateNotifier.instance!,
                              builder: (context, _) => _CardOverTextPage(
                                body: _s4bProfile(l10n),
                                // True colours — no legibility wash here.
                                dimBanner: false,
                                contact: AppStateNotifier.currentMyContact ??
                                    _selfContact ??
                                    _fallbackSelfContact(),
                                address: _selfAddressHex,
                                bodyStrong: true,
                                // INSIDE the card, not a box glued under it.
                                // The bio is part of the profile it previews,
                                // so the card draws it itself — a separate
                                // widget stacked below a card of fixed height
                                // gets squeezed to nothing and shows no text.
                                bio: _bioCurrent,
                                bioEmptyLabel: l10n.onbProfileBioEmpty,
                                // The picker is PERMANENT. Hiding it once a
                                // bio exists would leave a user who comes
                                // back from the cards page no way to change
                                // their mind — the page would go read-only
                                // behind them.
                                options: _BioPicker(
                                  // The key carries the saved bio's VALUE, not
                                  // just the undo epoch. The picker seeds
                                  // itself in `initState`, so it reads
                                  // `initial` exactly once — and the self
                                  // contact resolves asynchronously, which
                                  // means a picker built before that read
                                  // lands would keep an empty field forever
                                  // while the preview above it shows the bio.
                                  // Same reason as the cards preview's key:
                                  // a key that omits the value cannot see
                                  // the value change.
                                  //
                                  // Safe against typing — a keystroke moves
                                  // `_bioDraft`, never `_bioSaved`, so the key
                                  // holds still and the field keeps focus.
                                  key: ValueKey(
                                      '$_bioPickerEpoch|${_bioSaved ?? ''}'),
                                  writeOwnHint: l10n.onbProfileBioWriteOwn,
                                  presets: [
                                    l10n.onbProfileBioPreset1,
                                    l10n.onbProfileBioPreset2,
                                    l10n.onbProfileBioPreset3,
                                  ],
                                  initial: _bioCurrent,
                                  onChanged: (bio) =>
                                      setState(() => _bioDraft = bio),
                                ),
                                // Undo appears only with something to undo.
                                actionLabel: l10n.onbBioUndo,
                                actionIcon: Icons.undo_rounded,
                                onAction: _bioDirty ? _undoBio : null,
                              ),
                            ),
                          );
                        case _Step.gift:
                          return _ScrollSafePage(
                            child: _GiftPage(
                              body: _s4dGift(l10n),
                              art: _citizenArt,
                              revealed: _giftIsOpen,
                              playConfetti: _giftBurst,
                            ),
                          );
                        case _Step.cards:
                          // The theme toggle is PINNED under the scroll, not
                          // inside it: as the last thing in the page, a tall
                          // profile would push it off screen and the user
                          // would have to scroll the whole profile away to
                          // find it.
                          return Column(
                            children: [
                              Expanded(
                                child: _ScrollSafePage(
                            child: ListenableBuilder(
                              listenable: AppStateNotifier.instance!,
                              builder: (context, _) => _CardOverTextPage(
                                body: _s4cCards(l10n),
                                contact: _themedSelfContact(
                                  AppStateNotifier.currentMyContact ??
                                      _selfContact ??
                                      _fallbackSelfContact(),
                                ),
                                address: _selfAddressHex,
                                dimBanner: false,
                                bodyFirst: true,
                                feature: _ProfileCardsPreview(
                                  contact: AppStateNotifier.currentMyContact ??
                                      _selfContact,
                                  kitArt: _artFor(_cardTheme),
                                  // Only a kit profile previews a draft; a
                                  // user's own cards are rendered as they are.
                                  previewSpecs:
                                      _showingKitCards ? _cardSpecs : null,
                                  kitIds: _idsFor(_cardTheme),
                                  kitContract: _cardSource.contract,
                                ),
                                // Shuffle + undo appear ONLY on a kit profile.
                                // Someone who brought their own cards sees the
                                // grid and a continue button, nothing else.
                                options: _showingKitCards
                                    ? _ActionButton(
                                        label: l10n.onbCardsRandomize,
                                        icon: Icons.shuffle_rounded,
                                        onTap: _randomizeCards,
                                      )
                                    : null,
                                actionLabel: l10n.onbCardsUndo,
                                actionIcon: Icons.undo_rounded,
                                onAction: _showingKitCards && _cardsDirty
                                    ? _undoCards
                                    : null,
                              ),
                            ),
                                ),
                              ),
                              if (_canToggleTheme)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      _kPageHPad, 10, _kPageHPad, 4),
                                  child: _ThemeToggle(
                                    theme: _cardTheme,
                                    soulboundArt: _kitArt?[
                                        _KitSource.soulbound.squares.first],
                                    citizenArt: _citizenArt?[
                                        _KitSource.citizen.squares.first],
                                    soulboundLabel: l10n.onbThemeSoulbound,
                                    citizenLabel: l10n.onbThemeCitizen,
                                    onPick: _setCardTheme,
                                  ),
                                ),
                            ],
                          );
                        case _Step.yours:
                          // Three chain states, two pages. `true` and `null`
                          // share a page — both leave CONTINUE live — but not a
                          // sentence: only `true` has earned the right to say
                          // the account HAS an inbox. Telling someone they
                          // already have one because a view call timed out is a
                          // lie told on the screen whose whole subject is what
                          // is published about them.
                          final hasInbox = _chain.hasRegisteredInbox;
                          return _ScrollSafePage(
                            child: ListenableBuilder(
                              listenable: AppStateNotifier.instance!,
                              builder: (context, _) => _CardOverTextPage(
                                body: switch (hasInbox) {
                                  false => l10n.onbYoursBody,
                                  true => l10n.onbYoursHaveBody,
                                  null => l10n.onbYoursUnknownBody,
                                },
                                contact: AppStateNotifier.currentMyContact ??
                                    _selfContact ??
                                    _fallbackSelfContact(),
                                address: _selfAddressHex,
                                actionLabel: hasInbox == false
                                    ? l10n.onbYoursAddInbox
                                    : l10n.onbYoursShowMeHow,
                                actionIcon: Icons.tab_rounded,
                                onAction: _addFirstInbox,
                              ),
                            ),
                          );
                        case _Step.tabs:
                          return _ScrollSafePage(
                            child: ListenableBuilder(
                              listenable: AppStateNotifier.instance!,
                              builder: (context, _) => _CardOverTextPage(
                                body: _s5Tabs(l10n),
                                contact: _themedSelfContact(
                                  AppStateNotifier.currentMyContact ??
                                      _selfContact ??
                                      _fallbackSelfContact(),
                                ),
                                address: _selfAddressHex,
                                options: _TabKindList(
                                  // Only claim the inbox is there when the
                                  // chain says so. `null` and `false` both
                                  // render the row without its badge: a page
                                  // telling someone they published an inbox
                                  // they declined is the failure this whole
                                  // flow exists to avoid.
                                  inboxAdded: _chain.hasRegisteredInbox == true,
                                ),
                              ),
                            ),
                          );
                        case _Step.providers:
                          final citizen = _chain.isCitizen;
                          return _ScrollSafePage(
                            child: ListenableBuilder(
                              listenable: AppStateNotifier.instance!,
                              builder: (context, _) => _CardOverTextPage(
                                // Three-way, and the unknown branch says only
                                // what a BSP and an SSP ARE — never anything
                                // about this account, which is the one thing
                                // it does not know.
                                body: switch (citizen) {
                                  true => l10n.onbProvBodyCitizen,
                                  false => l10n.onbProvBodyPrivate,
                                  null => l10n.onbProvBodyUnknown,
                                },
                                contact: _themedSelfContact(
                                  AppStateNotifier.currentMyContact ??
                                      _selfContact ??
                                      _fallbackSelfContact(),
                                ),
                                address: _selfAddressHex,
                                // Rows, callout and the manage buttons all go
                                // in `options` as ONE column. The page's other
                                // slots render in a fixed order that would put
                                // the buttons above the callout, and the order
                                // here is load-bearing: state, then why, then
                                // what you can do about it.
                                options: _S6Options(
                                  state: _s6State,
                                  chain: _chain,
                                  arrivedDone: _s6ArrivedDone == true,
                                  failedAxis: _s6FailedAxis,
                                  fail: _s6Fail,
                                  failCost: _s6FailCost,
                                  onManage: _s6PickManual,
                                ),
                              ),
                            ),
                          );
                        case _Step.outro:
                          return const _ScrollSafePage(child: _OutroPage());
                      }
                    },
                  ),
                ),
                // The pending claim's second door — see [_claimPending].
                // A text link in the S6-skip voice (accent, spaced caps), its
                // own reserved slot so the primary below never moves.
                if (_claimPending)
                  SizedBox(
                    height: 40,
                    child: Center(
                      child: TextButton(
                        onPressed: _relaunchClaim,
                        child: Text(
                          l10n.onbClaimCitizenship,
                          style: TextStyle(
                            color: tokens.fallbackAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
                  child: SizedBox(
                    width: double.infinity,
                    // Disabled is NOT an opacity drop on the white pill (that
                    // leaves a bright button still reading as
                    // live). It swaps to the dashed / no-fill / dim treatment
                    // at identical geometry, so nothing shifts when it unlocks.
                    child: locked
                        ? _PrimaryDisabledButton(
                            label: primaryLabel,
                            busy: _bioSaving || _cardsSaving || _minting,
                          )
                        // ── Two tiers, keyed to whether the press DOES
                        // something ──
                        //
                        // Solid white on every primary would make the
                        // brightest thing on screen the way OUT — and a
                        // max-contrast exit that is always available teaches
                        // "tap here to make this go away": a SKIP link in
                        // the shape of a button.
                        //
                        // White means **this commits something** — SAVE
                        // CHANGES, and ENTER at the end of the tour. Plain
                        // CONTINUE is navigation, so it goes ghost: present,
                        // reachable, and quieter than the page's own action.
                        // The brightest element on a page is the thing the
                        // page is asking the user to do.
                        : _PrimaryButton(
                            label: primaryLabel,
                            onTap: primaryAction,
                            solid: commits,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(steps.length, (i) {
                    final active = i == page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? tokens.starkWhite
                            : tokens.starkWhite.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  PAGE LAYOUTS
// ════════════════════════════════════════════════════════════════════════════

/// S0's layout: the Phigital logo inline with the title, then subtitle, rule,
/// body.
class _LogoTextPage extends StatelessWidget {
  final _TextPageCopy copy;

  const _LogoTextPage({required this.copy});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Centred, with no hairline. S0 has no card, so the logo lockup IS
          // its masthead — centring it is what makes it read as one.
          //
          // `Center` rather than a Column-wide `crossAxisAlignment`: the body
          // copy below stays left-aligned, which is where prose belongs.
          //
          // **The WORD is centred, not the lockup**: the logo
          // hangs off its left wherever it falls. An invisible spacer on the
          // right balances the logo's LAYOUT box — `PhigitalLoadingWidget`
          // lays out at `size * 2.9` (room for the orbiting moon), not `size`
          // — minus the 4px of `letterSpacing` Flutter leaves after the last
          // glyph, so it's the ink that centres.
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const PhigitalLoadingWidget(
                  size: 28,
                  pulse: true,
                  showShadows: false,
                ),
                Text(
                  copy.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: tokens.starkWhite,
                  ),
                ),
                const SizedBox(width: 28 * 2.9 - 4),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            copy.body,
            style: TextStyle(
              fontSize: 14,
              color: tokens.starkWhite,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// The S1 layout, and the shape every later "this is about your account"
/// page reuses: **title line, then the identity card, then the words.**
/// The single 60px hairline sits under the heading rather than under the card,
/// so it closes the title block and leaves the card in clear space of its own
/// between the heading and the body.
///
/// Text at the top with the card pinned to the bottom of the screen makes
/// the account read as decoration trailing the copy. Here the heading names
/// the subject, the card
/// shows it, and the body then talks about what you're looking at — so the
/// copy lands on something already on screen. The card is a plain in-flow
/// child, not an overlay, so it scrolls with the text and no page has to
/// reserve a slot for it.
// ════════════════════════════════════════════════════════════════════════════
//  S6 · the page body
// ════════════════════════════════════════════════════════════════════════════

/// Everything under S6's copy: the two service rows, the callout explaining
/// the current state, and the manage buttons.
///
/// **One widget in the `options` slot rather than three slots.** The page
/// renders `feature`, `options`, `statusCallout` and `actionLabel` in
/// a fixed order that would put the buttons above the callout — and the order
/// here carries meaning: what your state is, then why, then what you can do
/// about it. `options` takes an arbitrary widget, so the whole cluster lives
/// in one.
class _S6Options extends StatelessWidget {
  final _S6 state;
  final _ChainState chain;
  final bool arrivedDone;
  final ProviderKind? failedAxis;
  final _S6Fail fail;
  final BigInt? failCost;
  final void Function(ProviderKind) onManage;

  const _S6Options({
    required this.state,
    required this.chain,
    required this.arrivedDone,
    required this.failedAxis,
    required this.fail,
    required this.failCost,
    required this.onManage,
  });

  bool _missing(ProviderKind k) =>
      (k == ProviderKind.bsp ? chain.bspActive : chain.sspActive) != true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Manage buttons only for what is actually missing, and never while a
    // write is in flight or the class is unresolved-and-therefore-unwritable.
    final showBsp = state != _S6.running && _missing(ProviderKind.bsp);
    final showSsp = state != _S6.running && _missing(ProviderKind.ssp);
    // Built once. Calling the builder twice — to null-check it and then to
    // render it — makes two different widgets and two rebuilds of the same
    // block.
    final callout = _callout(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _S6Row(
          kind: ProviderKind.bsp,
          title: l10n.onbProvBspTitle,
          assigned: chain.bspAssigned,
          active: chain.bspActive,
          until: chain.coveredUntil,
          isCitizen: chain.isCitizen,
          failed: failedAxis == ProviderKind.bsp,
          running: state == _S6.running && _missing(ProviderKind.bsp),
        ),
        const SizedBox(height: 8),
        _S6Row(
          kind: ProviderKind.ssp,
          title: l10n.onbProvSspTitle,
          assigned: chain.sspAssigned,
          active: chain.sspActive,
          until: chain.coveredUntil,
          isCitizen: chain.isCitizen,
          failed: failedAxis == ProviderKind.ssp,
          running: state == _S6.running && !_missing(ProviderKind.bsp),
        ),
        if (callout != null) ...[
          const SizedBox(height: 16),
          callout,
        ],
        if (showBsp || showSsp) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              if (showBsp)
                Expanded(
                  child: _ActionButton(
                    label: l10n.onbProvChooseBsp,
                    icon: Icons.hub_rounded,
                    onTap: () => onManage(ProviderKind.bsp),
                  ),
                ),
              if (showBsp && showSsp) const SizedBox(width: 8),
              if (showSsp)
                Expanded(
                  child: _ActionButton(
                    label: l10n.onbProvChooseSsp,
                    icon: Icons.rss_feed_rounded,
                    onTap: () => onManage(ProviderKind.ssp),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// The one block that explains the current state. Null on the plain
  /// "nothing set up yet" page, which needs no explanation beyond its copy.
  Widget? _callout(BuildContext context) {
    final l10n = context.l10n;
    switch (state) {
      case _S6.failed:
        final svc = failedAxis == ProviderKind.bsp
            ? l10n.onbProvBspTitle
            : l10n.onbProvSspTitle;
        return _S6Callout(
          danger: true,
          label: l10n.onbProvFailLabel,
          // Only the funds branch is allowed to name a cause, and only
          // because the balance was read AFTER the attempt and seen to be
          // short. Everything else says what is true — that we do not know.
          body: switch (fail) {
            _S6Fail.funds => l10n.onbProvFailFunds(
                svc,
                failCost == null ? '' : _formatOx(failCost!),
              ),
            _S6Fail.noProvider => l10n.onbProvFailNoProvider(svc),
            _S6Fail.unknown => l10n.onbProvFailGeneric(svc),
          },
          treasury: l10n.onbProvTreasuryHint,
        );
      case _S6.done:
        return _S6Callout(
          label: arrivedDone
              ? l10n.onbProvAlreadyLabel
              : l10n.onbProvCostLabel,
          body: arrivedDone
              ? l10n.onbProvAlreadyWhy
              : (chain.isCitizen == true
                  ? l10n.onbProvFreeWhy
                  : l10n.onbProvPaidWhy),
          treasury: arrivedDone ? null : l10n.onbProvTreasuryHint,
        );
      case _S6.unknown:
        return _S6Callout(
          danger: true,
          label: l10n.onbProvUnknownLabel,
          body: l10n.onbProvUnknownWhy,
        );
      default:
        return null;
    }
  }
}

/// One service row. Says exactly what is known and nothing more — an
/// unresolved read renders as *could not check*, never as *not connected*.
class _S6Row extends StatelessWidget {
  final ProviderKind kind;
  final String title;
  final String? assigned;
  final bool? active;
  final BigInt? until;
  final bool? isCitizen;
  final bool failed;
  final bool running;

  const _S6Row({
    required this.kind,
    required this.title,
    required this.assigned,
    required this.active,
    required this.until,
    required this.isCitizen,
    required this.failed,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    final (Color accent, String badge) = failed
        ? (tokens.softDanger, l10n.onbProvStateFailed)
        : running
            ? (tokens.fallbackAccent, l10n.onbProvStateWorking)
            : active == true
                ? (tokens.connectedAccent, l10n.onbProvStatePaired)
                : (tokens.textDim, l10n.onbProvStateNone);

    // The subtitle is the one place this row can lie, so it is built from what
    // resolved rather than from what we hoped for. A lapsed subscription still
    // names its provider — the slug survives a lapse on chain — but the badge
    // beside it does not say PAIRED.
    final String subtitle;
    if (active == null) {
      subtitle = l10n.onbProvUnknownRow;
    } else if (active == true) {
      subtitle = isCitizen == true
          ? l10n.onbProvRenewsItself
          : l10n.onbProvPaidTo(_formatUntil(until));
    } else if ((assigned ?? '').isNotEmpty) {
      subtitle = l10n.onbProvLapsed(assigned!);
    } else {
      subtitle = l10n.onbProvNone;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active == true || failed || running
              ? accent.withValues(alpha: 0.30)
              : tokens.borderSubtle,
        ),
        color: active == true || failed || running
            ? accent.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.035),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderSubtle),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: Icon(
              kind == ProviderKind.bsp
                  ? Icons.hub_rounded
                  : Icons.rss_feed_rounded,
              size: 17,
              color: tokens.starkWhite.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Once a provider is resolved the row leads with its NAME —
                  // "PublicOS MX" tells the user more than "Network access"
                  // does, and the generic title has already done its job in
                  // the page copy above.
                  (assigned ?? '').isNotEmpty && active == true
                      ? assigned!
                      : title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tokens.starkWhite,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: tokens.textDim.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: accent.withValues(alpha: 0.42)),
              color: accent.withValues(alpha: 0.08),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The state callout under the rows — a label, a sentence, and (when there is
/// something the user can do about it later) a Treasury pointer carrying the
/// Treasury app's own icon, so the destination is recognisable before they
/// get there.
class _S6Callout extends StatelessWidget {
  final String label;
  final String body;
  final String? treasury;
  final bool danger;

  const _S6Callout({
    required this.label,
    required this.body,
    this.treasury,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = danger ? tokens.softDanger : tokens.connectedAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: danger ? 0.30 : 0.16)),
        color: accent.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: danger ? accent : tokens.textDim,
            ),
          ),
          const SizedBox(height: 9),
          _richBody(
            body,
            TextStyle(
              fontSize: 12,
              color: tokens.textDim,
              height: 1.55,
            ),
            tokens.starkWhite,
          ),
          if (treasury != null) ...[
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tokens.borderSubtle)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: tokens.connectedAccent.withValues(alpha: 0.30),
                      ),
                      color:
                          tokens.connectedAccent.withValues(alpha: 0.10),
                    ),
                    // The Treasury app's own icon (`treasury_page.dart`), not a
                    // generic wallet glyph — the point is that they recognise
                    // the place when they get there.
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 14,
                      color: tokens.connectedAccent,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _richBody(
                      treasury!,
                      TextStyle(
                        fontSize: 11,
                        color: tokens.textDim,
                        height: 1.45,
                      ),
                      tokens.starkWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The per-service deposit notice — privates only, one axis at a time, shown
/// before anything leaves the wallet.
class _S6DepositSheet extends StatelessWidget {
  final String title;
  final ProviderEntry provider;
  final BigInt? cost;
  final BigInt? balance;

  const _S6DepositSheet({
    required this.title,
    required this.provider,
    required this.cost,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    // Glass-dark shell, the twin of `network_access_sheets.dart`'s `_SheetShell`
    // (top radius 20, blur 30, `surfaceDeep` at 92 %), with its own drag handle
    // — the host passes `wrapInChrome: false`, so nothing else paints one.
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
          color: tokens.surfaceDeep.withValues(alpha: 0.92),
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: tokens.borderMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.onbProvDepositLabel.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: tokens.textDim,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.title.isEmpty ? provider.slug : provider.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: tokens.starkWhite,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$title · ${provider.region}',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                cost == null ? '—' : _formatOx(cost!),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.fallbackAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _richBody(
            l10n.onbProvDepositWhy(
              balance == null ? '—' : _formatOx(balance!),
            ),
            TextStyle(fontSize: 12, color: tokens.textDim, height: 1.55),
            tokens.starkWhite,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: l10n.actionCancel,
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                flex: 2,
                child: _ActionButton(
                  label: l10n.onbProvDepositGo,
                  icon: Icons.account_balance_rounded,
                  filled: true,
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
          ),
        ),
      ),
    );
  }
}

/// The skip confirmation. Cancel / Skip, and it carries the Treasury icon
/// because that is where the thing being skipped can still be done.
///
/// A dialog rather than a bare link: a one-tap exit is precisely the failure
/// the no-SKIP rule was written against.
class _S6SkipDialog extends StatelessWidget {
  final String missing;

  const _S6SkipDialog({required this.missing});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return Dialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
      backgroundColor: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.borderMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: tokens.connectedAccent.withValues(alpha: 0.32),
                ),
                color: tokens.connectedAccent.withValues(alpha: 0.10),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                size: 23,
                color: tokens.connectedAccent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.onbProvSkipTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tokens.starkWhite,
              ),
            ),
            const SizedBox(height: 9),
            _richBody(
              l10n.onbProvSkipBody(missing),
              TextStyle(fontSize: 12.5, color: tokens.textDim, height: 1.6),
              tokens.starkWhite,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: l10n.actionCancel,
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _ActionButton(
                    label: l10n.onbProvSkip,
                    icon: Icons.arrow_forward_rounded,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// OX with two decimals, from the token's 18. Display only.
String _formatOx(BigInt wei) {
  final whole = wei ~/ BigInt.from(10).pow(18);
  final frac = (wei % BigInt.from(10).pow(18)) ~/ BigInt.from(10).pow(16);
  return '$whole.${frac.toString().padLeft(2, '0')} OX';
}

/// A `paidUntil` as a short date, for the row subtitle.
String _formatUntil(BigInt? until) {
  if (until == null || until == BigInt.zero) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(
    until.toInt() * 1000,
  );
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
}

/// One row of the outro: an app's icon, its name, and what it is for.
class _OutroEntry {
  final String asset;
  final String title;
  final String body;

  const _OutroEntry({
    required this.asset,
    required this.title,
    required this.body,
  });
}

/// The three things the outro introduces: Manual, Library, Support. The
/// Library's art is the classical building. Same list as the client's
/// `_outroCopy`.
List<_OutroEntry> _outroCopy(AppLocalizations l) => <_OutroEntry>[
      _OutroEntry(
        asset: 'assets/onboarding/manual.png',
        title: l.onbManualTitle,
        body: l.onbManualBody,
      ),
      _OutroEntry(
        asset: 'assets/onboarding/library.png',
        title: l.onbLibraryTitle,
        body: l.onbLibraryBody,
      ),
      _OutroEntry(
        asset: 'assets/onboarding/support.png',
        title: l.onbSupportTitle,
        body: l.onbSupportBody,
      ),
    ];

/// S7 — the outro. Three apps, named and explained, then out.
///
/// **The second and last page in the tour that carries a heading.** Every page
/// between S0 and here leads with the account card and lets the body's
/// `**bold**` keyword name it, because those pages are all *about the user's
/// own account* and a title over the card just restated it. This one is not
/// about their account at all — it is three things elsewhere in the app — so
/// there is no card to lead with and the title does the naming, exactly as S0's
/// does at the other end. The pair bookends the flow.
///
/// The primary and the dots come from the shared chrome: the outro is the last
/// entry in [_OnboardingFlowState._allSteps], so `isLastPage` already makes the
/// button read ENTER PUBLICOS (or DONE on a replay) and gives it the solid
/// white treatment reserved for a press that *does* something.
class _OutroPage extends StatelessWidget {
  const _OutroPage();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.onbGetAroundTitle,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: tokens.starkWhite,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onbGetAroundSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: tokens.textDim,
              letterSpacing: 1,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 1,
            width: 60,
            color: tokens.starkWhite.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 32),
          for (final entry in _outroCopy(l10n)) ...[
            _OutroCard(entry: entry),
            const SizedBox(height: 28),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// An outro row — icon tile, title, body. The body carries its own `**bold**`
/// keywords and goes through [_richBody], the same parser every other page in
/// this flow uses, rather than a second copy of the same three lines.
class _OutroCard extends StatelessWidget {
  final _OutroEntry entry;

  const _OutroCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // No border: the icon art carries the tile.
            boxShadow: [
              BoxShadow(
                color: tokens.starkWhite.withValues(alpha: 0.1),
                blurRadius: 24,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(entry.asset, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: tokens.starkWhite,
                ),
              ),
              const SizedBox(height: 8),
              _richBody(
                entry.body,
                TextStyle(
                  fontSize: 13,
                  color: tokens.starkWhite,
                  height: 1.6,
                ),
                tokens.starkWhite,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardOverTextPage extends StatelessWidget {
  /// The page's words. Carries its own subject as a `**bold**` span — with
  /// no heading this is the only thing naming what the page is for.
  final String body;
  final Contact contact;
  final String address;

  /// 0→1 — shade the card and relight only the display name. On S1 this is
  /// the whole point of showing the card: the page is about the readable name.
  /// Later pages that show the card for a different reason pass 0.
  final double nameFocus;

  /// When set, the card carries its tab switcher in the top-right corner.
  /// [tabsAttention] makes it pulse — the nudge stops the moment it is used.
  final VoidCallback? onTabs;
  final bool tabsAttention;

  /// Darken the banner under a legibility gradient. On by default; **off on
  /// S4b**, whose whole point is showing the kit's true colours.
  final bool dimBanner;

  /// Draw the words ABOVE the account card.
  ///
  /// **S4c only.** Everywhere else the card comes first and the body talks
  /// about something already on screen. The cards page inverts that because
  /// its body is an *instruction* — it tells the user what the controls below
  /// will do, so it has to be read before the thing it acts on.
  final bool bodyFirst;

  /// S4b's live bio, drawn INSIDE the card by [_AccountCard] itself. Passing
  /// [bioEmptyLabel] is what turns the block on; [bio] is null until one is
  /// picked and the label stands in for it.
  final String? bio;
  final String? bioEmptyLabel;

  /// Render the body larger and brighter — for a page whose copy is an
  /// **instruction** rather than a description. The default weight makes the
  /// body quieter than the controls under it, which is backwards when the body
  /// is the only imperative on the page.
  final bool bodyStrong;

  /// Optional strip directly beneath the card. S4b hangs the account's three
  /// kit cards here rather than inside [_AccountCard]: the card is the same
  /// widget on four pages, and forking it for one of them is how the shared
  /// frame stops being shared.
  final Widget? feature;

  /// Optional block after the body — S4b's bio picker.
  final Widget? options;

  /// Optional live status line between body and action.
  final Widget? statusCallout;

  /// Optional action below the options — S1's Domain Store, S4b's undo.
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  const _CardOverTextPage({
    required this.body,
    required this.contact,
    required this.address,
    this.nameFocus = 0,
    this.onTabs,
    this.tabsAttention = false,
    this.dimBanner = true,
    this.bio,
    this.bioEmptyLabel,
    this.bodyStrong = false,
    this.bodyFirst = false,
    this.feature,
    this.options,
    this.statusCallout,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.travel_explore_rounded,
  });

  /// The card sizes itself — banner block plus, on S4b, the bio under it.
  /// A fixed height with the bio hung underneath as a separate widget would
  /// leave the bio no room to draw its own text.
  Widget _card() => _AccountCard(
        contact: contact,
        address: address,
        addressReveal: 1,
        recordsReveal: 1,
        accountCue: 0,
        nameFocus: nameFocus,
        onTabs: onTabs,
        tabsAttention: tabsAttention,
        dimBanner: dimBanner,
        bio: bio,
        bioEmptyLabel: bioEmptyLabel,
      );

  Widget _words(GlassTokens tokens) => _richBody(
        body,
        bodyStrong
            ? TextStyle(
                fontSize: 15.5,
                height: 1.5,
                color: tokens.starkWhite.withValues(alpha: 0.80),
              )
            : TextStyle(fontSize: 14, color: tokens.textDim, height: 1.6),
        tokens.starkWhite,
      );

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kPageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── The account, and the words ──
          //
          // Card first everywhere except S4c. No heading, icon tile or
          // hairline: on a page already showing the user their own account,
          // a 26px word above it restates what the card says, so the body's
          // **bold keyword** carries the "what is this page" job and sits
          // directly under the card it talks about.
          //
          // [bodyFirst] inverts it for the cards page, whose body is an
          // instruction rather than a description — it has to be read before
          // the thing it acts on.
          for (final w in bodyFirst
              ? [_words(tokens), const SizedBox(height: 22), _card()]
              : [_card(), const SizedBox(height: 22), _words(tokens)])
            w,
          if (feature != null) ...[
            const SizedBox(height: 18),
            feature!,
          ],
          if (options != null) ...[
            const SizedBox(height: 12),
            options!,
          ],
          if (statusCallout != null) ...[
            const SizedBox(height: 16),
            statusCallout!,
          ],
          // ── The secondary action, with its space always reserved ──
          //
          // Keyed on the LABEL, not the handler. The two conditional callers
          // (S4b's and S4c's undo) pass a label always and a handler only when
          // there is something to undo, so *label present, handler absent* means
          // exactly "this page has this button, it just is not live right now".
          // S1 passes both — always live. S2 and S3 pass neither, and reserve
          // nothing.
          //
          // Reserved rather than conditionally built, because `undo` appears the
          // moment a preset is picked or a card shuffled and vanishes on save —
          // and every one of those would shift the page under the user's thumb
          // mid-interaction. It fades instead: same footprint throughout, so
          // nothing below it moves.
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            AnimatedOpacity(
              opacity: onAction == null ? 0 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: IgnorePointer(
                // Invisible is not the same as absent: without this the ghost
                // would still take taps aimed at whatever sits beneath it.
                ignoring: onAction == null,
                child: _ActionButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  onTap: onAction ?? () {},
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Piece offsets inside a five-token kit. `+0` pfp · `+1` banner · `+2..+4`
/// the three cards. These are the contract's own ordering, not a convention
/// this file invents.
const int _kKitPfpOffset = 0;
const int _kKitBannerOffset = 1;
const int _kKitHorizontalOffset = 2;
const int _kKitVerticalOffset = 3;
const int _kKitSquareOffset = 4;

// ════════════════════════════════════════════════════════════════════════════
//  THE TWO KITS  ·  one layout, two sources
// ════════════════════════════════════════════════════════════════════════════

/// Which collection a profile's kit art comes from.
///
/// **Everything about the layout is shared; only the SOURCE differs.** The
/// toggle changes the source used to fill, and [_KitSource] is what makes
/// that true in code rather than
/// in a comment: the arrangement, the footprints, the packing and the record
/// shape all live in one place, and the theme only decides which contract and
/// which token id each piece resolves to.
enum _KitTheme {
  /// Tier 1. Every account, free, five tokens with **one** square reused.
  soulbound,

  /// Tier 2. Citizens only, minted once, thirteen tokens with **nine**
  /// distinct squares.
  citizen,
}

/// Everything the layout needs to know about one collection.
///
/// The roles line up piece for piece between the tiers, which is the whole
/// reason a single layout can serve both:
///
/// | role | soulbound | citizen |
/// |---|---|---|
/// | pfp | `+0` | tile `1` |
/// | banner | `+1` | tile `0` |
/// | horizontal (stretches) | `+2` | tile `2` *rule* |
/// | vertical (stretches) | `+3` | tile `3` *spine* |
/// | square | `+4` — **one** | tiles `4..12` — **nine** |
class _KitSource {
  final _KitTheme theme;

  /// The contract the records point at. **Also the theme's identity on chain**
  /// — a stored card is attributed back to its tier by this address, never by
  /// a local flag, because the flag is gone after a restart and the record is
  /// not.
  final String contract;

  /// Piece count, for the bounds check when reading ids back off records.
  final int pieces;

  final int pfp;
  final int banner;
  final int horizontal;
  final int vertical;

  /// Every offset that can supply a 1×1. Tier 1 has one, tier 2 has nine —
  /// **the only shape difference between the collections.**
  final List<int> squares;

  const _KitSource({
    required this.theme,
    required this.contract,
    required this.pieces,
    required this.pfp,
    required this.banner,
    required this.horizontal,
    required this.vertical,
    required this.squares,
  });

  static final _KitSource soulbound = _KitSource(
    theme: _KitTheme.soulbound,
    contract: PublicOSSoulbound.kitContractAddress,
    pieces: PublicOSSoulbound.piecesPerKit,
    pfp: _kKitPfpOffset,
    banner: _kKitBannerOffset,
    horizontal: _kKitHorizontalOffset,
    vertical: _kKitVerticalOffset,
    squares: const [_kKitSquareOffset],
  );

  static final _KitSource citizen = _KitSource(
    theme: _KitTheme.citizen,
    contract: PublicOSCitizenKit.kitContractAddress,
    pieces: PublicOSCitizenKit.tilesPerKit,
    pfp: PublicOSCitizenKit.avatarTile,
    banner: PublicOSCitizenKit.bannerTile,
    horizontal: PublicOSCitizenKit.ruleTile,
    vertical: PublicOSCitizenKit.spineTile,
    squares: PublicOSCitizenKit.cardTiles,
  );

  static _KitSource of(_KitTheme t) =>
      t == _KitTheme.citizen ? citizen : soulbound;

  /// Which offset supplies the art for a footprint.
  ///
  /// **Shape decides the piece, not the other way round.** A stretched SVG is
  /// built for its axis (`4000x1000` and `1000x4000`, both
  /// `preserveAspectRatio="none"`), so a horizontal piece dropped into a tall
  /// slot would smear. Deriving the offset from `w`/`h` here — in ONE place —
  /// is what makes both the randomiser and a theme switch correct by
  /// construction rather than by matching cases.
  ///
  /// A 1×1 draws from [squares] at random. Under tier 1 that is a pool of one,
  /// so there is nothing to draw; under tier 2 it is a free draw from nine,
  /// **repeats allowed and leftovers allowed**, which keeps a single code
  /// path across both tiers.
  int offsetForShape(int w, int h, Random rng) {
    if (w > 1) return horizontal;
    if (h > 1) return vertical;
    return squares[rng.nextInt(squares.length)];
  }
}

/// One tile in the starter layout: which kit piece supplies its art, and where
/// it sits on the profile grid.
class _KitTile {
  /// Kit piece offset — the art. **Reused across tiles on purpose.**
  final int offset;
  final int col;
  final int row;
  final int w;
  final int h;
  const _KitTile(this.offset, this.col, this.row, this.w, this.h);
}

const int _kKitCols = ProfileGridGeometry.columns; // 4
const int _kKitRows = 4;

/// The starter arrangement — **the single definition**, shared by the preview
/// strip and the writer, so a card can never be previewed at one size and
/// written at another.
///
/// ```
///  ┌───┬───────┬───┐
///  │   │  2x1  │1x1│
///  │   ├───┬───┼───┤
///  │1x3│1x1│   │1x1│
///  │   ├───┤1x2├───┤
///  │   │1x1│   │1x1│
///  ├───┴───┴───┴───┤
///  │      4x1      │
///  └───────────────┘
/// ```
///
/// **Nine tiles from three tokens.** A record points at an NFT; nothing stops
/// two records pointing at the *same* one, and ownership verifies for every
/// copy because it is the same token in the same Safe. So the kit's one
/// horizontal, one vertical and one square are each reused at several sizes.
///
/// **The mixed footprints are the message.** A new profile that arrives as
/// nine identical squares teaches that cards are a fixed grid; one that
/// arrives as 1x1, 2x1, 1x2, 1x3 and 4x1 teaches — without a word of copy —
/// that the user can resize and rearrange. That is the whole reason this is a
/// layout rather than a row.
///
/// It tiles the 4x4 exactly: 3 + 2 + 1 + 1 + 2 + 1 + 1 + 1 + 4 = **16 cells,
/// no gaps**. Change one entry and the arithmetic has to be redone.
///
/// The stretched tiles work because the art is built for it: the horizontal
/// (`4000x1000`) and vertical (`1000x4000`) SVGs carry
/// `preserveAspectRatio="none"`, so they take whatever box they are given.
const List<_KitTile> _kKitLayout = [
  _KitTile(_kKitVerticalOffset, 0, 0, 1, 3), // tall column, left
  _KitTile(_kKitHorizontalOffset, 1, 0, 2, 1), // short bar, top
  _KitTile(_kKitSquareOffset, 3, 0, 1, 1),
  _KitTile(_kKitSquareOffset, 1, 1, 1, 1),
  _KitTile(_kKitVerticalOffset, 2, 1, 1, 2), // half-height column, middle
  _KitTile(_kKitSquareOffset, 3, 1, 1, 1),
  _KitTile(_kKitSquareOffset, 1, 2, 1, 1),
  _KitTile(_kKitSquareOffset, 3, 2, 1, 1),
  _KitTile(_kKitHorizontalOffset, 0, 3, 4, 1), // full-width bar, bottom
];

/// One card in a kit arrangement: which piece supplies the art, and the
/// footprint it takes on the profile grid.
///
/// **No position.** The grid packs by rank, so the *order* of a list of these
/// is the arrangement — storing coordinates too would give two sources of
/// truth for where a card sits, and the records only carry one of them.
///
/// [prefill] is set for the prefill's own content cards (inbox · PublicOS ·
/// tip): the record IS the card, footprint
/// included, and [offset] is unused (-1). Null for every kit tile.
typedef _CardSpec = ({int offset, int w, int h, Record? prefill});

/// A random arrangement of the kit that tiles the 4×4 block exactly.
///
/// **Every tile is 1×N or N×1 — never 2×2 or larger.** That is not
/// only taste: each kit has one horizontal, one vertical and (at least) one
/// square piece, and a chunky block has no art that fits it. Shape and art are
/// chosen together here, so a horizontal SVG never lands in a tall slot.
///
/// **Identical under both collections.** It picks footprints; [source] turns
/// each footprint into an offset. Tier 2's nine squares therefore need no
/// second algorithm — the pool is simply longer.
///
/// Fills the first free cell each pass, taking a random legal footprint from
/// it. Filling the *first* free cell is what guarantees termination and a
/// gapless tiling: every cell becomes "first free" eventually, and a piece
/// only ever extends right or down from it into cells already known free.
///
/// **Starts from [occupied]**, which may already hold the prefill's special
/// cards (see [_randomLayout]); the kit fills every cell still free. Returns
/// each tile with its top-left cell, because the caller interleaves them with
/// the specials by position before ranking.
List<({int r, int c, _CardSpec spec})> _randomKitTiles(
    Random rng, _KitSource source, List<List<bool>> occupied) {
  final out = <({int r, int c, _CardSpec spec})>[];

  // How many of each direction the layout already carries. Drives the decay
  // below, and counted separately so the two directions never suppress one
  // another.
  var usedHorizontal = 0;
  var usedVertical = 0;

  while (true) {
    int? fr;
    int? fc;
    outer:
    for (var r = 0; r < _kKitRows; r++) {
      for (var c = 0; c < _kKitCols; c++) {
        if (!occupied[r][c]) {
          fr = r;
          fc = c;
          break outer;
        }
      }
    }
    if (fr == null || fc == null) break;

    var maxW = 0;
    while (fc + maxW < _kKitCols && !occupied[fr][fc + maxW]) {
      maxW++;
    }
    var maxH = 0;
    while (fr + maxH < _kKitRows && !occupied[fr + maxH][fc]) {
      maxH++;
    }

    // ── Pick a SHAPE CLASS first, then a size inside it ──
    //
    // Choosing uniformly over every candidate footprint is quietly biased
    // toward bars, and not by a little: at a fresh 4x4 corner the options are
    // one square, three widths and three heights, so the square comes up
    // **1 time in 7** even though it is one of only three shapes. A multi-cell
    // shape wins simply because it has more sizes to offer.
    //
    // Picking the class first removes that entirely — square, horizontal and
    // vertical compete as three things, not as one against six.
    //
    // **Then each direction decays as it gets used**: the
    // first bar is full weight, a second is worth half, a third a third. The
    // two directions count separately, so a layout that already has a long
    // horizontal still happily takes a vertical — it is the *repetition* of a
    // direction that gets discouraged, not the mixing of them. The square never
    // decays, which is what makes it the thing a crowded grid falls back to.
    final options = <({int cls, double weight})>[
      (cls: 0, weight: 1.0), // square — always available, never decays
      if (maxW >= 2) (cls: 1, weight: 1.0 / (1 + usedHorizontal)),
      if (maxH >= 2) (cls: 2, weight: 1.0 / (1 + usedVertical)),
    ];

    final total = options.fold<double>(0, (a, o) => a + o.weight);
    var roll = rng.nextDouble() * total;
    var cls = options.first.cls;
    for (final o in options) {
      roll -= o.weight;
      if (roll <= 0) {
        cls = o.cls;
        break;
      }
    }

    // Size is uniform WITHIN the class — the weighting is about which shape,
    // not about how long it is.
    final ({int w, int h}) shape;
    switch (cls) {
      case 1:
        shape = (w: 2 + rng.nextInt(maxW - 1), h: 1);
        usedHorizontal++;
      case 2:
        shape = (w: 1, h: 2 + rng.nextInt(maxH - 1));
        usedVertical++;
      default:
        shape = (w: 1, h: 1);
    }
    final _CardSpec pick = (
      offset: source.offsetForShape(shape.w, shape.h, rng),
      w: shape.w,
      h: shape.h,
      prefill: null,
    );
    for (var dr = 0; dr < pick.h; dr++) {
      for (var dc = 0; dc < pick.w; dc++) {
        occupied[fr + dr][fc + dc] = true;
      }
    }
    out.add((r: fr, c: fc, spec: pick));
  }
  return out;
}

/// A random profile: the prefill's special cards dropped at random spots,
/// then the kit filling every cell left.
///
/// **Biggest special first**, each at a random position where it fits. The
/// kit always closes the gaps — a 1×1 fits any hole — so the result tiles the
/// 4×4 exactly. Three big specials can box each other out, so a failed
/// placement re-rolls the whole layout; with no specials it never fails.
///
/// 🔑 **Ranks follow the row-major order of each tile's top-left cell**, specials
/// and kit interleaved. The grid packs by rank (first free cell, monotonic
/// cursor), and for a gapless tiling that order reproduces the drawn layout
/// exactly.
List<_CardSpec> _randomLayout(
    Random rng, _KitSource source, List<Record> prefills) {
  final bySize = [...prefills]
    ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
  for (var attempt = 0; attempt < 50; attempt++) {
    final occupied = List.generate(
      _kKitRows,
      (_) => List.filled(_kKitCols, false),
    );
    final placed = <({int r, int c, _CardSpec spec})>[];
    var ok = true;
    for (final p in bySize) {
      final w = p.width.clamp(1, _kKitCols);
      final h = p.height.clamp(1, _kKitRows);
      final spots = <({int r, int c})>[];
      for (var r = 0; r + h <= _kKitRows; r++) {
        for (var c = 0; c + w <= _kKitCols; c++) {
          var free = true;
          for (var dr = 0; dr < h && free; dr++) {
            for (var dc = 0; dc < w; dc++) {
              if (occupied[r + dr][c + dc]) {
                free = false;
                break;
              }
            }
          }
          if (free) spots.add((r: r, c: c));
        }
      }
      if (spots.isEmpty) {
        ok = false;
        break;
      }
      final at = spots[rng.nextInt(spots.length)];
      for (var dr = 0; dr < h; dr++) {
        for (var dc = 0; dc < w; dc++) {
          occupied[at.r + dr][at.c + dc] = true;
        }
      }
      placed.add((r: at.r, c: at.c, spec: (offset: -1, w: w, h: h, prefill: p)));
    }
    if (!ok) continue;
    placed.addAll(_randomKitTiles(rng, source, occupied));
    placed.sort((a, b) =>
        (a.r * _kKitCols + a.c).compareTo(b.r * _kKitCols + b.c));
    return [for (final t in placed) t.spec];
  }
  // Fifty failed placements means the specials cannot share one grid; drop
  // them rather than write nothing.
  return _randomLayout(rng, source, const []);
}

// ════════════════════════════════════════════════════════════════════════════
//  THE PREFILL'S SPECIAL CARDS
// ════════════════════════════════════════════════════════════════════════════
//
// The kit alone shows one thing a profile can do. Up to three content cards
// join it to teach the rest: a "text me" card that opens the user's own inbox,
// a PublicOS card (an image + one line) that opens the publicos org, and a tip
// card that pays the user's MainSafe. Each is ONE line, a verb + an emoji, in
// the card's body: the body has no link-glyph reserve, so the line survives a
// 1-wide card (the title's 30 px both-side reserve cuts it to two letters).

/// Key prefix of the prefill's own cards. **The prefix is how S4c knows a card
/// is the tour's to reshuffle** rather than the user's, the same way a kit card
/// is known by its contract — derived from the record, never from a flag.
const String _kPrefillKeyPrefix = 'card.prefill_';

bool _isPrefillKey(String key) => key.startsWith(_kPrefillKeyPrefix);

/// The `publicos` org — where the PublicOS card goes.
///
/// ⚠️ ROOT-ORG COUPLED, like `feeds_settings_sheet.dart`'s copy of the same
/// address: an account is a CREATE-deployed Blueprint, so this dies with every
/// chain redeploy. Re-point on any reset, reading it from the registry:
/// `MR.getModuleAddress(keccak256("PUBLICOS_ROOT_ORG"))`.
const String _kPublicosOrgAddress =
    '0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD';

/// The tip card's image — jmsl's own tip card art (`card.muithqez`) — or, half
/// the time, its plain teal.
const String _kTipImage =
    'https://feeds.publicos.dev/media/accec038.1790456629.jpg';
const Color _kTipColor = Color(0xFF0F766E);

/// The five PublicOS cards: an image and the line it carries.
///
/// Hosted under **jmsl's** SSP account. Deleting them from jmsl's media list
/// breaks this card on every profile that has it. Square art with the
/// subject in the centre, so it survives a 1×1, 1×2, 2×1 or 2×2 crop —
/// except the astronaut, whose head and feet a 2×1 cuts ([wide] false).
const List<({String url, String line, bool wide})> _kPrefillImages = [
  (
    url: 'https://feeds.publicos.dev/media/a6d42d73.1791064909.jpg',
    line: 'explore', // astronaut
    wide: false,
  ),
  (
    url: 'https://feeds.publicos.dev/media/3f77a74d.1791064911.jpg',
    line: 'discover', // earth cutaway
    wide: true,
  ),
  (
    url: 'https://feeds.publicos.dev/media/a7fd97c6.1791064912.jpg',
    line: 'hi', // scattered planets
    wide: true,
  ),
  (
    url: 'https://feeds.publicos.dev/media/c39aef61.1791064914.jpg',
    line: 'join', // solar system
    wide: true,
  ),
  (
    url: 'https://feeds.publicos.dev/media/36686070.1791064915.jpg',
    line: 'build', // domed city
    wide: true,
  ),
];

/// Every line, in every language the prefill speaks.
///
/// **Hardcoded on purpose, not in the .arb files**: the app ships en + es only
/// and Flutter resolves every other locale to en, but these cards are written
/// to chain in the language of the *device* (the languages covering most
/// people, English for the rest). Chinese and Hindi are left out
/// deliberately. Everything outside es and en is a machine translation
/// awaiting a native read.
const Map<String, Map<String, String>> _kPrefillCopy = {
  'en': {
    'inbox': 'Text me 📬',
    'tip': 'Tips 🪙',
    'explore': 'Explore 🔭',
    'discover': 'Discover 🌍',
    'hi': 'Say hi 👋',
    'join': 'Join 🚀',
    'build': 'Build 🛠️',
  },
  'es': {
    'inbox': 'Escríbeme 📬',
    'tip': 'Propinas 🪙',
    'explore': 'Explora 🔭',
    'discover': 'Descubre 🌍',
    'hi': 'Saluda 👋',
    'join': 'Únete 🚀',
    'build': 'Construye 🛠️',
  },
  'pt': {
    'inbox': 'Me escreve 📬',
    'tip': 'Gorjetas 🪙',
    'explore': 'Explore 🔭',
    'discover': 'Descubra 🌍',
    'hi': 'Diga oi 👋',
    'join': 'Participe 🚀',
    'build': 'Construa 🛠️',
  },
  'fr': {
    'inbox': 'Écris-moi 📬',
    'tip': 'Pourboires 🪙',
    'explore': 'Explore 🔭',
    'discover': 'Découvre 🌍',
    'hi': 'Dis bonjour 👋',
    'join': 'Rejoins-nous 🚀',
    'build': 'Construis 🛠️',
  },
  'de': {
    'inbox': 'Schreib mir 📬',
    'tip': 'Trinkgeld 🪙',
    'explore': 'Erkunde 🔭',
    'discover': 'Entdecke 🌍',
    'hi': 'Sag hallo 👋',
    'join': 'Mach mit 🚀',
    'build': 'Bau mit 🛠️',
  },
  'ru': {
    'inbox': 'Напиши мне 📬',
    'tip': 'Чаевые 🪙',
    'explore': 'Исследуй 🔭',
    'discover': 'Открывай 🌍',
    'hi': 'Привет! 👋',
    'join': 'Вступай 🚀',
    'build': 'Создавай 🛠️',
  },
  'ja': {
    'inbox': 'メッセージしてね 📬',
    'tip': 'チップ 🪙',
    'explore': '探検しよう 🔭',
    'discover': '発見しよう 🌍',
    'hi': 'あいさつしよう 👋',
    'join': '参加しよう 🚀',
    'build': 'つくろう 🛠️',
  },
  'ar': {
    'inbox': 'راسلني 📬',
    'tip': 'إكراميات 🪙',
    'explore': 'استكشف 🔭',
    'discover': 'اكتشف 🌍',
    'hi': 'قل مرحبًا 👋',
    'join': 'انضم 🚀',
    'build': 'ابنِ 🛠️',
  },
  'id': {
    'inbox': 'Chat aku 📬',
    'tip': 'Tip 🪙',
    'explore': 'Jelajahi 🔭',
    'discover': 'Temukan 🌍',
    'hi': 'Sapa 👋',
    'join': 'Gabung 🚀',
    'build': 'Bangun 🛠️',
  },
  'vi': {
    'inbox': 'Nhắn tôi 📬',
    'tip': 'Tiền tip 🪙',
    'explore': 'Khám phá 🔭',
    'discover': 'Tìm hiểu 🌍',
    'hi': 'Chào nhé 👋',
    'join': 'Tham gia 🚀',
    'build': 'Xây dựng 🛠️',
  },
  'tr': {
    'inbox': 'Bana yaz 📬',
    'tip': 'Bahşiş 🪙',
    'explore': 'Keşfet 🔭',
    'discover': 'Bul 🌍',
    'hi': 'Selam ver 👋',
    'join': 'Katıl 🚀',
    'build': 'İnşa et 🛠️',
  },
};

/// The prefill's language: the **device's**, when the table has it; English
/// otherwise. Read off the platform, not the app — the app's own locale is
/// only ever en or es. Malay reads the Indonesian lines; pt-PT reads pt-BR's.
Map<String, String> _prefillCopy() {
  var code = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  if (code == 'ms') code = 'id';
  return _kPrefillCopy[code] ?? _kPrefillCopy['en']!;
}

/// A random two-stop gradient for the inbox card:
/// saturated, mid-light, the second hue 30–100° from the first.
CardGradient _randomCardGradient(Random rng) {
  final h1 = rng.nextInt(360).toDouble();
  final h2 = (h1 + 30 + rng.nextInt(70)) % 360;
  const angles = [90.0, 135.0, 180.0, 45.0];
  return CardGradient(
    from: HSLColor.fromAHSL(1, h1, 0.70, 0.52).toColor(),
    to: HSLColor.fromAHSL(1, h2, 0.72, 0.42).toColor(),
    angle: angles[rng.nextInt(angles.length)],
  );
}

/// One prefill card, as the content-card editor would write it: one line in
/// the body, no title, never expiring. [kind] becomes the key
/// (`card.prefill_<kind>`), so a reshuffle overwrites it in place.
Record _prefillCard(
  String kind, {
  required int w,
  required int h,
  required String line,
  String? image,
  CardGradient? gradient,
  Color? color,
  String? link,
  CardTip? tip,
}) =>
    ContentCard(
      body: line,
      image: image,
      gradient: gradient,
      color: color,
      link: link,
      tip: tip,
      width: w,
      height: h,
    ).toRecord(id: 'prefill_$kind');

/// What a prefill card looks like, for change detection — everything a reroll
/// can change, nothing the chain adds (rank, expiration).
String _prefillSignature(Record? r) => r == null
    ? ''
    : '${r.key}|${r.value}|${r.link}|${r.metadata['image']}|'
        '${jsonEncode(r.metadata['gradient'])}|${r.metadata['color']}|'
        '${jsonEncode(r.metadata['tip'])}';

/// The kit block — the starter layout drawn at the size it will occupy on the
/// profile.
///
/// `+0` pfp and `+1` banner are absent by design: the account card above
/// already paints both, and showing them again would be the same art twice.
///
/// **Pure renderer.** It resolves nothing: the art is fetched once by the flow
/// (`_loadKitArt`) and handed down, because `PageView` disposes an off-screen
/// page and a widget-owned fetch would repeat on every visit.
class _KitStrip extends StatelessWidget {
  /// Art by kit offset — three entries for nine tiles. Null while unresolved.
  final Map<int, String>? images;

  const _KitStrip({required this.images});

  @override
  Widget build(BuildContext context) {
    const double gap = ProfileGridGeometry.spacing;

    // Width from MediaQuery, NOT a LayoutBuilder: this lives inside
    // _ScrollSafePage's IntrinsicHeight, where a LayoutBuilder throws on every
    // frame. MediaQuery needs no layout pass.
    final double avail = MediaQuery.sizeOf(context).width - (_kPageHPad * 2);
    final double cell = (avail - gap * (_kKitCols - 1)) / _kKitCols;
    double extent(int n) => cell * n + gap * (n - 1);

    // The block reserves its full size from the first frame — the SizedBox is
    // pure arithmetic and does not depend on the children — so the tiles can
    // be withheld until the art resolves and then cascade in without the page
    // reflowing under them.
    return SizedBox(
      width: extent(_kKitCols),
      height: extent(_kKitRows),
      child: images == null
          ? null
          : Stack(
              children: [
                for (var i = 0; i < _kKitLayout.length; i++)
                  Positioned(
                    left: _kKitLayout[i].col * (cell + gap),
                    top: _kKitLayout[i].row * (cell + gap),
                    width: extent(_kKitLayout[i].w),
                    height: extent(_kKitLayout[i].h),
                    // The same entrance the profile grid uses, so the cards a
                    // user meets during onboarding arrive exactly the way they
                    // will arrive on their profile afterwards.
                    child: ProfileCardPopIn(
                      index: i,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: images![_kKitLayout[i].offset] == null
                              ? null
                              // `fill` for the same reason as [_GiftTile]: the
                              // horizontal and vertical pieces are authored
                              // `preserveAspectRatio="none"`, so `cover` crops
                              // art that asked to be stretched.
                              : NftImage(
                                  url: images![_kKitLayout[i].offset]!,
                                  fit: BoxFit.fill,
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// S4c's subject — the account's profile cards, read-only, clipped to the top
/// rows.
///
/// **Two sources, and the first one is normally right.** By the time this page
/// is reached `_fillEmptyProfileSlots` has already run on S4b, so an account
/// that had no cards now has the nine kit cards on chain and an account that
/// had its own kept them (the all-or-nothing rule wrote none). Either way the
/// real records are the truth, and rendering them means the user is looking at
/// their actual profile rather than a mock of it.
///
/// The [_KitStrip] fallback covers the window where the write has landed but
/// the contact has not refreshed yet — and the case where the write failed, so
/// the page still shows the kit the account owns rather than an empty box.
class _ProfileCardsPreview extends StatelessWidget {
  final Contact? contact;

  /// The flow's cached kit art, for the fallback path.
  final Map<int, String>? kitArt;

  /// The kit arrangement being previewed, when the user is shuffling. Built
  /// into in-memory records so a shuffle is **visible before it is written** —
  /// the whole point of randomise-until-you-like-it is that the chain is not
  /// involved until SAVE. Null on a profile whose cards are the user's own.
  final List<_CardSpec>? previewSpecs;

  /// Kit token ids, to point the preview records at real art.
  final List<BigInt>? kitIds;

  /// Which collection the preview records point at. **A record carries its own
  /// contract**, so the preview has to be told which kit it is drawing — an
  /// in-memory record built against the wrong address would preview art the
  /// save would not write.
  final String? kitContract;

  const _ProfileCardsPreview({
    required this.contact,
    required this.kitArt,
    this.previewSpecs,
    this.kitIds,
    this.kitContract,
  });

  /// Rows of the grid to show. Four is the kit's own height, so the fresh case
  /// fits exactly; a long-standing profile is cropped to its top rows.
  static const int _rows = _kKitRows;

  /// In-memory records for a previewed arrangement — never written, never
  /// persisted, and discarded on undo.
  List<Record> _previewRecords() {
    final specs = previewSpecs!;
    final ids = kitIds!;
    final expiration = Record.never; // records do not expire
    String? rank;
    final out = <Record>[];
    var kitIndex = 0;
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      rank = keyBetween(rank, null);
      final prefill = spec.prefill;
      if (prefill != null) {
        out.add(prefill.copyWith(rank: rank));
        continue;
      }
      final id = ids[spec.offset];
      out.add(Record.asProfile(
        key: 'card.kit_${kitIndex++}',
        value: NftAvatarRef(
          chain: PublicOS.CHAIN_ID,
          standard: 'erc721',
          contract: kitContract ?? PublicOSSoulbound.kitContractAddress,
          tokenId: id.toString(),
        ).encode(),
        expiration: expiration,
        width: spec.w,
        height: spec.h,
        noTitle: true,
        rank: rank,
        customMetadataAttributes: {
          'cardKind': 'nft',
          'name': 'NFT #$id',
          'isImageRecord': true,
          // **The preview has to carry its own art.** `RecordButton` paints
          // from `metadata['nftImage']`, which `fetchContact` stashes when it
          // loads a contact — "here we just paint". A hand-built record has
          // never been through that, so without this it shimmers forever.
          //
          // Deliberately NOT written on save: on chain the record carries only
          // the pointer, and Core resolves the art on fetch. Baking a data-URI
          // SVG into a stored record would put the whole image on chain twice.
          if (kitArt?[spec.offset] != null) 'nftImage': kitArt![spec.offset],
          // The kit lives in the account's own MainSafe, so the verified
          // sparkle is truthful here rather than decorative.
          'nftOwned': true,
        },
      ));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cards = (previewSpecs != null && kitIds != null)
        ? _previewRecords()
        : contact?.records
                .where((r) => r.profileSubtype == ProfileSubtype.card)
                .toList() ??
            const <Record>[];

    if (cards.isEmpty) return _KitStrip(images: kitArt);

    const double gap = ProfileGridGeometry.spacing;
    final double avail = MediaQuery.sizeOf(context).width - (_kPageHPad * 2);
    final double cell = (avail - gap * (ProfileGridGeometry.columns - 1)) /
        ProfileGridGeometry.columns;
    final double height = cell * _rows + gap * (_rows - 1);

    // The height is TIGHT, and that is what makes this safe inside
    // _ScrollSafePage's IntrinsicHeight: a tight-height ConstrainedBox answers
    // an intrinsic query from its own constraints and never asks the child —
    // so ProfileGrid's internal LayoutBuilder is never reached by the
    // intrinsic pass (which would throw).
    return SizedBox(
      height: height,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: double.infinity,
          child: IgnorePointer(
            // Read-only: no edit mode, no add button, no reorder, no taps.
            // The real grid is one screen away and this is a look, not a tool.
            child: ProfileGrid(
              // A new arrangement is a new grid: without this the cards would
              // slide between layouts instead of arriving as a fresh wave.
              // The VALUE is in the key, not just the footprint: a theme
              // switch keeps every key and every size and changes only the
              // token the record points at, so a shape-only key would leave
              // the old art on screen.
              // A prefill reroll can keep key, size and line and change only
              // the image or gradient, so those join the key too.
              key: ValueKey(cards
                  .map((r) => '${r.key}:${r.width}x${r.height}:${r.value}'
                      ':${r.metadata['image']}:${r.metadata['gradient']}')
                  .join('|')),
              records: cards,
              isEditable: false,
              isEditMode: false,
              nftOwner: contact,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  S4d  ·  THE GIFT  —  shimmer, mint, reveal
// ════════════════════════════════════════════════════════════════════════════

/// The citizen kit, held as SHAPES before it exists and filled in once it does.
///
/// **The same shapes as the next screen** — a banner, an avatar and the 4×4
/// card block, at the geometry `_ProfileCardsPreview` uses — so the reveal
/// lands in the exact frames the profile will wear. Before the mint each frame
/// carries a travelling shimmer; after it, the real art.
///
/// > [!warning] No `LayoutBuilder` anywhere in here. Every page sits inside
/// > `_ScrollSafePage`'s `IntrinsicHeight`, which `LayoutBuilder` cannot answer
/// > — it throws every frame and takes the page down. Widths come from
/// > `MediaQuery.sizeOf` and every box has a tight height.
class _GiftKitPreview extends StatelessWidget {
  /// Art by tile, or null while it resolves. Prefetched behind the shimmer via
  /// `previewSVG`, which renders for an account that has not minted — so this
  /// is usually already populated by the time [revealed] flips.
  final Map<int, String>? art;

  /// Whether the kit exists. Drives shape-vs-art, and nothing else.
  final bool revealed;

  const _GiftKitPreview({required this.art, required this.revealed});

  static const double _bannerAspect = 3.0; // the banner SVG is 3000x1000
  static const double _avatar = 56;

  @override
  Widget build(BuildContext context) {
    const double gap = ProfileGridGeometry.spacing;
    final double avail = MediaQuery.sizeOf(context).width - (_kPageHPad * 2);
    final double cell = (avail - gap * (ProfileGridGeometry.columns - 1)) /
        ProfileGridGeometry.columns;
    final double gridH = cell * _kKitRows + gap * (_kKitRows - 1);
    final double bannerH = avail / _bannerAspect;

    Widget tileAt(int tile, double w, double h, {double? radius}) => _GiftTile(
          // `(revealed ? art : null)?[…]` and not `revealed ? art?[…] : null`
          // — the parser cannot tell `?[` from the ternary's `?`.
          image: (revealed ? art : null)?[tile],
          width: w,
          height: h,
          radius: radius,
          masked: !revealed,
        );

    // Which citizen tile fills each slot of the layout.
    //
    // The gift page draws the kit's OWN arrangement, not the user's saved one:
    // this page is about the collection, the arrangement is the next screen's
    // subject. Roles map across tiers, so the same layout constant serves both.
    //
    // **The nine squares are handed out in order, without repeating.** The
    // layout is written in tier-1 offsets, where one square is reused nine
    // times because tier 1 only HAS one; tier 2 has nine distinct ones, and a
    // reveal that showed the same square nine times would undersell the very
    // thing it exists to show.
    final tiles = <_KitTile, int>{};
    var nextSquare = 0;
    for (final t in _kKitLayout) {
      tiles[t] = _citizenTileForOffset(t.offset, () {
        final squares = _KitSource.citizen.squares;
        return squares[nextSquare++ % squares.length];
      });
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── banner, with the avatar overlapping it the way the profile does ──
        SizedBox(
          height: bannerH + _avatar / 2,
          width: avail,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              tileAt(PublicOSCitizenKit.bannerTile, avail, bannerH),
              Positioned(
                left: 12,
                top: bannerH - _avatar / 2,
                child: tileAt(
                  PublicOSCitizenKit.avatarTile,
                  _avatar,
                  _avatar,
                  // The rounded square every other pfp in the app wears.
                  radius: _avatar * _kAvatarRadiusFactor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── the card block, at the kit's own layout ──
        SizedBox(
          height: gridH,
          width: avail,
          child: Stack(
            children: [
              for (final t in _kKitLayout)
                Positioned(
                  left: t.col * (cell + gap),
                  top: t.row * (cell + gap),
                  width: t.w * cell + (t.w - 1) * gap,
                  height: t.h * cell + (t.h - 1) * gap,
                  child: _GiftTile(
                    image: (revealed ? art : null)?[tiles[t]],
                    width: double.infinity,
                    height: double.infinity,
                    masked: !revealed,
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    // ── ONE sweep for the whole block, not one per tile ──
    //
    // Per-tile shimmer is wrong twice over, and both faults come from the same
    // root: a gradient expressed in a tile's OWN normalised space. The band's
    // angle then depends on the tile's aspect — a 1×3 column shears nearly
    // vertical while a 4×1 bar runs nearly flat — and each tile runs its own
    // clock, so the page reads as several animations jumping past each other
    // rather than one light crossing it.
    //
    // A single mask over the whole block fixes both at once: one phase, and an
    // angle fixed in PIXELS (see [_SweepShimmer]) so every frame — bar, column
    // or square — shows the identical inclination. The shapes are still the
    // next screen's real shapes; only the light is shared.
    return revealed ? content : _SweepShimmer(child: content);
  }
}

/// Translate a soulbound layout offset to the citizen tile that plays the same
/// role. The layout constant is written in tier-1 offsets, and the roles line
/// up piece for piece — this is the one place that correspondence is spelled
/// out for drawing purposes.
///
/// [nextSquare] supplies the 1×1s. It is a callback rather than a value
/// because tier 2 has nine of them and the caller decides how they are dealt —
/// the reveal walks them in order so no square appears twice.
int _citizenTileForOffset(int offset, int Function() nextSquare) {
  final c = _KitSource.citizen;
  if (offset == _kKitHorizontalOffset) return c.horizontal;
  if (offset == _kKitVerticalOffset) return c.vertical;
  if (offset == _kKitPfpOffset) return c.pfp;
  if (offset == _kKitBannerOffset) return c.banner;
  return nextSquare();
}

/// One frame: the art if there is any, a travelling shimmer if there is not.
class _GiftTile extends StatelessWidget {
  final String? image;
  final double width;
  final double height;

  /// Corner radius. The avatar passes the app's squircle radius — **not** a
  /// circle: PublicOS pfps are rounded squares everywhere else, and a round one
  /// here would make the gift preview the only screen disagreeing with the
  /// profile the user is about to see.
  final double? radius;

  /// Whether a [_SweepShimmer] is masking this tile.
  ///
  /// **It decides the empty plate's colour, and getting it wrong flashes.**
  /// Under the mask the plate must be OPAQUE WHITE — `BlendMode.srcIn` takes
  /// shape from it and colour from the shader, so anything else is discarded.
  /// Outside the mask that same white would be painted for real, and since the
  /// reveal drops the mask and swaps the plate for art in the same frame, the
  /// tile would cross-fade *from solid white* on its way to the picture. So an
  /// unmasked empty tile paints the dim plate instead.
  final bool masked;

  const _GiftTile({
    required this.image,
    required this.width,
    required this.height,
    this.radius,
    this.masked = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius ?? 8.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          // **`StackFit.expand`, and this is what makes the art fill its slot.**
          //
          // `AnimatedSwitcher`'s default layout is a `Stack` with the default
          // `StackFit.loose`, so the child is handed LOOSE constraints. Under
          // loose constraints `SvgPicture` sizes itself to the picture's own
          // aspect and `BoxFit.fill` never gets anything to stretch — the fit
          // can only act on a box it has been given. The rule is authored 4:1
          // and the spine 1:4, so a tile whose slot happens to be 4x1 or 1x4
          // fills correctly and every other slot letterboxes: a 4:1 rule in a
          // 2x1 slot lays itself out half-height and centred, so the bars
          // and columns read as thin with dead space around them.
          //
          // `_KitStrip` and the profile grid do not need this because they
          // hand `NftImage` tight constraints directly — no switcher in
          // between.
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          ),
          child: image == null
              ? ColoredBox(
                  key: const ValueKey('plate'),
                  color: masked
                      ? const Color(0xFFFFFFFF)
                      : tokens.starkWhite.withValues(alpha: 0.05),
                  child: const SizedBox.expand(),
                )
              : NftImage(
                  key: ValueKey(image),
                  url: image!,
                  // **`fill`, not `cover`** — the kit art asks to be stretched
                  // and `cover` refuses, which makes the proportions look
                  // wrong.
                  //
                  // `rule` is authored `viewBox="0 0 4000 1000"` and `spine`
                  // `0 0 1000 4000`, both with `preserveAspectRatio="none"`:
                  // *squash me into whatever box you are given*. `cover`
                  // overrides that and CROPS — a 4:1 rule in a 2x1 slot loses
                  // half its length and the rest is zoomed, so the stripes come
                  // out fatter than the same art beside them in a 1x1.
                  //
                  // Every kit piece is authored to fill its slot exactly
                  // (banner 3:1 `slice`, avatar and cards 1:1, rule and spine
                  // `none`), so `fill` is faithful for all of them and identical
                  // to `cover` for the square ones. It is scoped to kit art on
                  // purpose: a user's own NFT still wants `cover`, since
                  // squashing someone's photograph is not a kindness.
                  fit: BoxFit.fill,
                  // The box is already tight around this; `renderSize` is the
                  // decode hint, which vector art ignores anyway.
                  renderSize: width.isFinite ? width : null,
                ),
        ),
      ),
    );
  }
}

/// One travelling sheen across everything it wraps.
///
/// **The angle is fixed in PIXELS, and that is the whole point.** A
/// `LinearGradient` positioned with `Alignment` lives in the target's own
/// normalised space, so the same begin/end renders at a different visual angle
/// on every differently-shaped box — which makes a 1×3 column and a 4×1 bar
/// disagree, and makes the block look like several
/// animations rather than one light. Here the band's direction and width are
/// computed in device pixels from the bounds the mask is given, so every frame
/// under it shows the identical inclination, and one controller drives them
/// all so there is a single phase.
///
/// Uses `BlendMode.srcIn`: the child supplies SHAPE ONLY (opaque white plates)
/// and this supplies every colour, which is why the sheen cannot leak outside
/// the tiles and why no gap between them ever lights up.
class _SweepShimmer extends StatefulWidget {
  final Widget child;
  const _SweepShimmer({super.key, required this.child});

  @override
  State<_SweepShimmer> createState() => _SweepShimmerState();
}

class _SweepShimmerState extends State<_SweepShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  /// Downward pixels per rightward pixel. A gentle lean — enough to read as a
  /// sheen rather than a wipe, shallow enough that a tall column does not spend
  /// most of the cycle dark.
  static const double _tilt = 0.30;

  /// Half the band's width, in pixels.
  static const double _halfBand = 90;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final base = tokens.starkWhite.withValues(alpha: 0.05);
    final peak = tokens.starkWhite.withValues(alpha: 0.16);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (Rect bounds) {
          final w = bounds.width;
          final h = bounds.height;

          // Unit vector along the sweep, in pixels.
          final len = sqrt(1 + _tilt * _tilt);
          final ux = 1 / len;
          final uy = _tilt / len;

          // How far the block extends along that direction, so the band can
          // start fully off one end and finish fully off the other regardless
          // of the block's shape.
          final extent = w * ux.abs() + h * uy.abs();
          final travel = extent + _halfBand * 2;
          final centre = -_halfBand + travel * _c.value;

          // Band edges as pixel points, measured from the top-left corner
          // along the sweep direction.
          final p0x = (centre - _halfBand) * ux;
          final p0y = (centre - _halfBand) * uy;
          final p1x = (centre + _halfBand) * ux;
          final p1y = (centre + _halfBand) * uy;

          // Pixels → Alignment. This is the conversion that keeps the angle
          // honest: the shape's own dimensions are divided back out, so what
          // was specified in pixels arrives as pixels.
          Alignment toAlign(double px, double py) => Alignment(
              w == 0 ? 0 : (2 * px / w) - 1, h == 0 ? 0 : (2 * py / h) - 1);

          return LinearGradient(
            begin: toAlign(p0x, p0y),
            end: toAlign(p1x, p1y),
            colors: [base, peak, base],
            stops: const [0.0, 0.5, 1.0],
            // Clamp, so everything the band has not reached sits at `base`
            // rather than repeating the sheen across the block.
            tileMode: TileMode.clamp,
          ).createShader(bounds);
        },
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// S4d's page: the shapes, the words, and a burst when the kit lands.
class _GiftPage extends StatelessWidget {
  final String body;
  final Map<int, String>? art;
  final bool revealed;

  /// Play the burst. Deliberately separate from [revealed] — the mint state is
  /// a fact about the chain and this is a fact about the animation, so a user
  /// who walks back onto an already-minted page sees their kit without the
  /// confetti firing again.
  final bool playConfetti;

  const _GiftPage({
    required this.body,
    required this.art,
    required this.revealed,
    required this.playConfetti,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kPageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GiftKitPreview(art: art, revealed: revealed),
              const SizedBox(height: 22),
              _richBody(
                body,
                TextStyle(
                  fontSize: 14,
                  color: tokens.textDim,
                  height: 1.6,
                ),
                tokens.starkWhite,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        if (playConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: PixelConfetti(colors: _kitConfettiColors(art)),
            ),
          ),
      ],
    );
  }
}

/// The kit's own colours, read straight out of its SVGs.
///
/// **The burst is made of the gift.** Picking festive colours by hand would be
/// a second palette competing with the one the user was just given — and the
/// citizen kit draws from 2,048 of them, so any fixed choice clashes with most
/// of the collection. Reading the art means the confetti always matches the
/// exact kit on screen, with no coordination needed between the two.
///
/// Drops the extremes: the near-black ground and the near-white paper are the
/// two colours the tiles are *mostly* made of, so keeping them would give a
/// burst that reads as grey static against a dark page.
List<Color> _kitConfettiColors(Map<int, String>? art) {
  if (art == null || art.isEmpty) return const [];
  final seen = <int>{};
  // A few tiles is plenty — one kit shares a palette across all of them, and
  // decoding thirteen SVGs to find the same six colours would be waste.
  for (final uri in art.values.take(4)) {
    final svg = _decodeDataSvg(uri);
    if (svg == null) continue;
    for (final m in RegExp(r'#([0-9a-fA-F]{6})').allMatches(svg)) {
      final rgb = int.tryParse(m.group(1)!, radix: 16);
      if (rgb == null) continue;
      final c = Color(0xFF000000 | rgb);
      final l = c.computeLuminance();
      if (l < 0.06 || l > 0.96) continue;
      seen.add(0xFF000000 | rgb);
      if (seen.length >= 6) break;
    }
    if (seen.length >= 6) break;
  }
  return seen.map(Color.new).toList();
}

/// Pull the SVG text out of a `data:image/svg+xml;base64,…` URI.
String? _decodeDataSvg(String uri) {
  try {
    final i = uri.indexOf(',');
    if (i < 0) return null;
    final payload = uri.substring(i + 1);
    if (!uri.substring(0, i).contains('base64')) return Uri.decodeFull(payload);
    return utf8.decode(base64.decode(payload));
  } catch (_) {
    return null;
  }
}

/// S4c's source switch: two swatches, each wearing its own collection's 1×1.
///
/// **It shows the theme rather than naming it.** The label is there for
/// screen readers and for the moment before the art resolves, but the swatch
/// is the control — a user picking between two look-and-feels should be
/// looking at them.
class _ThemeToggle extends StatelessWidget {
  final _KitTheme theme;
  final String? soulboundArt;
  final String? citizenArt;
  final String soulboundLabel;
  final String citizenLabel;
  final ValueChanged<_KitTheme> onPick;

  const _ThemeToggle({
    required this.theme,
    required this.soulboundArt,
    required this.citizenArt,
    required this.soulboundLabel,
    required this.citizenLabel,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ThemeChip(
            label: soulboundLabel,
            art: soulboundArt,
            selected: theme == _KitTheme.soulbound,
            onTap: () => onPick(_KitTheme.soulbound),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ThemeChip(
            label: citizenLabel,
            art: citizenArt,
            selected: theme == _KitTheme.citizen,
            onTap: () => onPick(_KitTheme.citizen),
          ),
        ),
      ],
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final String? art;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.art,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            // Selection is a border weight and a lift, never an opacity drop
            // on the unselected one — a dimmed live control reads as disabled.
            color: selected ? tokens.starkWhite : tokens.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
          color: selected
              ? tokens.starkWhite.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 30,
                height: 30,
                child: art == null
                    // Same plate-plus-mask contract as the gift block: shape
                    // from the child, colour from the sweep.
                    ? const _SweepShimmer(
                        child: ColoredBox(
                          color: Color(0xFFFFFFFF),
                          child: SizedBox.expand(),
                        ),
                      )
                    : NftImage(
                        url: art!,
                        fit: BoxFit.cover,
                        renderSize: 30,
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: selected ? tokens.starkWhite : tokens.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// S4b's bio picker — a write-your-own field over three preset choices.
///
/// Single-select: typing clears the chosen preset, choosing a preset clears
/// what was typed. There is no Set button — the bio commits on leaving the
/// page, the same way every other S4b slot is written without asking.
///
/// The presets are drawn as **separate cards, not menu rows**. They are the
/// one real choice on the page, and a flat list of dim text read as filler
/// next to the account card above them.
class _BioPicker extends StatefulWidget {
  final String writeOwnHint;
  final List<String> presets;

  /// The bio already chosen this session, if the user is coming BACK to this
  /// page. `PageView` disposes a page once it is far enough off-screen, so
  /// without this the picker returns blank while the slot above it still shows
  /// the draft the parent kept — the page contradicting itself.
  final String? initial;

  /// Fires on every change with the bio as it currently stands, or null when
  /// nothing is chosen.
  final ValueChanged<String?> onChanged;

  const _BioPicker({
    super.key,
    required this.writeOwnHint,
    required this.presets,
    required this.onChanged,
    this.initial,
  });

  @override
  State<_BioPicker> createState() => _BioPickerState();
}

class _BioPickerState extends State<_BioPicker> {
  final TextEditingController _controller = TextEditingController();
  int? _chosen;

  @override
  void initState() {
    super.initState();
    // Restore the standing choice — and this is also how an account that
    // ARRIVES with a bio gets it back: **a bio we did not write is the user's
    // own text**, so it lands in the write-your-own field and shows in the
    // preview, exactly as if they had just typed it.
    //
    // The one exception is an exact match against a preset, which lights that
    // preset up instead. Exact on purpose: near-misses stay custom, because a
    // bio that merely resembles one of ours is still theirs and quietly
    // swapping it for our wording would be an edit nobody asked for.
    final initial = widget.initial?.trim();
    if (initial == null || initial.isEmpty) return;
    final i = widget.presets.indexWhere((p) => p.trim() == initial);
    if (i >= 0) {
      _chosen = i;
    } else {
      _controller.text = initial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(int i) {
    setState(() {
      _chosen = i;
      _controller.clear();
    });
    widget.onChanged(widget.presets[i]);
  }

  void _typed(String value) {
    // Always rebuild, not just when a preset is being cleared: the input's own
    // lit border reads `_controller.text`. Leaving that to the parent's
    // setState would work today and break the moment this picker is used by a
    // host that does not rebuild on every keystroke.
    setState(() => _chosen = null);
    widget.onChanged(value.trim().isEmpty ? null : value.trim());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Write-your-own first: the option that is actually theirs sits above
        // the ones we wrote for them.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _controller.text.trim().isNotEmpty
                  ? tokens.starkWhite.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: TextField(
            controller: _controller,
            onChanged: _typed,
            maxLines: 2,
            minLines: 1,
            style: TextStyle(fontSize: 14, color: tokens.starkWhite),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: widget.writeOwnHint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: tokens.textDim,
                fontWeight: FontWeight.w500,
              ),
              icon: Icon(Icons.edit_outlined, size: 17, color: tokens.textDim),
            ),
          ),
        ),
        for (var i = 0; i < widget.presets.length; i++) ...[
          const SizedBox(height: 8),
          _BioPresetRow(
            text: widget.presets[i],
            selected: _chosen == i,
            onTap: () => _pick(i),
          ),
        ],
      ],
    );
  }
}

/// One preset bio, as a card the user picks.
///
/// Unselected it still reads as an offer — full-strength text, its own fill
/// and border. Selected it gains a lit border, a brighter fill, a left accent
/// bar and a check, so the choice is unmistakable at a glance rather than a
/// subtle tint difference.
class _BioPresetRow extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _BioPresetRow({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: double.infinity,
        decoration: BoxDecoration(
          // Unselected rows carry almost nothing: with the bio living in the
          // card above, these are a LIST TO PICK FROM, and four filled
          // panels would compete with the thing they are meant to fill.
          color: selected
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? tokens.starkWhite.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.07),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tokens.starkWhite.withValues(alpha: 0.10),
                    blurRadius: 18,
                  ),
                ]
              : null,
        ),
        // ONE indicator: the highlight above (fill + bright border + glow)
        // is it. No accent bar and no check circle; the text keeps its
        // weight shift.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: selected
                  ? tokens.starkWhite
                  : tokens.starkWhite.withValues(alpha: 0.70),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal padding every onboarding page uses. Shared so the kit block
/// can size itself to the same content width without measuring anything.
const double _kPageHPad = 36;

/// Render body copy with `**bold**` spans.
///
/// With no page headings, the body is the only thing telling the user
/// what the page is for — so the subject word carries the weight a title
/// would: *your **bio***, *your **profile cards***, *publish an **inbox***.
/// A deliberately tiny parser: `**` toggles, nothing else is markup, and an
/// unclosed marker just renders the rest of the string bold rather than
/// throwing. Copy lives in the `.arb` files, so translators mark their own
/// keyword — which in Spanish is rarely the same word position.
Text _richBody(String text, TextStyle base, Color boldColor) {
  final parts = text.split('**');
  return Text.rich(
    TextSpan(
      children: [
        for (var i = 0; i < parts.length; i++)
          TextSpan(
            text: parts[i],
            style: i.isOdd
                ? base.copyWith(
                    fontWeight: FontWeight.w700,
                    color: boldColor,
                  )
                : null,
          ),
      ],
      style: base,
    ),
  );
}

/// Corner radius factor for an avatar, as a fraction of its size.
///
/// **The app's pfp is a rounded square, not a circle.** Mirrors
/// `GlassContactIcon`'s shape-by-class rule for the individual case.
///
/// There is no org factor here: this file draws nothing that has to match
/// the icon's org shape. Anything that needs the branch should be asking
/// the shared widget for it, not restating the rule here.
const double _kAvatarRadiusFactor = 0.40;

/// The card's banner block height — 88px, so the card reads identically to
/// the one in the account center. On S4b the bio adds its own height under
/// it.
const double _kCardH = 88;

class _ScrollSafePage extends StatelessWidget {
  final Widget child;

  const _ScrollSafePage({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// Left-hand glyph. Defaults to S1's compass so the Domain Store button is
  /// unchanged; S4b's undo passes its own.
  final IconData icon;

  /// Solid stark-white treatment for the one press in a sheet that *does*
  /// something — the subscribe sheets' primary. Default is the quiet glass fill.
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon = Icons.travel_explore_rounded,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fg = filled ? tokens.background : tokens.starkWhite;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: filled
                ? tokens.starkWhite
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The pinned identity "scene": the morph card with the safe peeking out from
/// behind it. The safe is a sibling BEHIND the card (drawn first), free to
/// overflow the card box (Clip.none) so its lower half shows past the card's
/// bottom-right corner.

class _AccountCard extends StatefulWidget {
  final Contact contact;
  final String address;
  final double addressReveal;
  final double recordsReveal;
  final double accountCue;

  /// 0→1 — shade the whole card and relight only the display name.
  ///
  /// The domain IS the account's readable identity, so the page that teaches
  /// it needs the eye to land there and nowhere else. Rather than restyle the
  /// card for one screen (which would fork it from the card the user meets
  /// everywhere else in the app), the card is drawn exactly as always and then
  /// a scrim is laid over it with the name redrawn on top. The user still sees
  /// their own familiar card; it is simply dimmed around the one part this
  /// page is about.
  final double nameFocus;

  /// The card's own tab switcher, in the top-right corner. Only rendered when
  /// a page hands it a callback — the card is inert everywhere else.
  final VoidCallback? onTabs;
  final bool tabsAttention;

  /// Darken the banner under a legibility gradient. On by default; **off on
  /// S4b**, whose whole point is showing the kit's true colours.
  final bool dimBanner;

  /// S4b's bio, drawn inside the card under the banner block. [bioEmptyLabel]
  /// non-null is what turns the block on; [bio] is null until one is picked,
  /// and the label stands in for it.
  final String? bio;
  final String? bioEmptyLabel;

  const _AccountCard({
    required this.contact,
    required this.address,
    required this.addressReveal,
    required this.recordsReveal,
    required this.accountCue,
    this.nameFocus = 0,
    this.onTabs,
    this.tabsAttention = false,
    this.dimBanner = true,
    this.bio,
    this.bioEmptyLabel,
  });

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard>
    with SingleTickerProviderStateMixin {
  // Drives the card's "breathing" loading glow — a soft halo that swells and
  // fades behind the still-empty card, then settles to nothing as the real
  // banner + avatar reveal on the Records stage. One full breath per cycle.
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    )..repeat();
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  String get _shortAddress {
    final address = widget.address;
    return address.length >= 10
        ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
        : address;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final contact = widget.contact;
    // `address` + `name` live in _footer with the row they belong to.
    final r = widget.recordsReveal;
    final skeleton = (1 - r).clamp(0.0, 1.0).toDouble();
    final base = GlassTheme.glassBox(context);

    // The card body — blurred glass fill + banner/avatar/name. Built ONCE; only
    // the breathing shadow around it (below) animates per frame.
    const cardRadius = BorderRadius.all(Radius.circular(16));

    // The banner block — fixed 88px, everything in it positioned against that
    // height. On S4b the bio is appended UNDER it inside the same glass, so
    // the card grows instead of the bio being clipped by a fixed frame.
    final banner = SizedBox(
      height: _kCardH,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Banner + its legibility gradient build in at the Records
          // stage. Always laid out (preloaded under an opacity fade) so
          // there's no pop-in when they appear.
          Opacity(
            opacity: r,
            // NFT banner first ([ContactBanner]): S4b writes the kit banner
            // as an NFT, and a URL-only read would show the stock default
            // photo next to the kit pfp.
            child: ContactBanner(
              contact: contact,
              fallback: _bannerFallback(tokens),
              fxSize: 28,
            ),
          ),
          // The legibility wash. Off on S4b, where the banner IS the
          // subject — that page exists to show the kit's real colours,
          // and a 15→65% black ramp is exactly what a colour is not.
          // Safe to drop because the name and address carry their own
          // `Shadow(black54, blur 6)` in [_footer]; the wash was
          // reinforcement, never the only thing holding them up.
          if (widget.dimBanner)
            Opacity(
              opacity: r,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
          // The footer layout is FINAL from the first frame — nothing
          // slides into place. The avatar slot (60px) and the address line
          // are reserved from the start (just invisible), so the name sits
          // in its real spot on Domain; the address blurs in below it on
          // Contract, and the avatar + banner fade into their places on
          // Records. Each element builds in where it already belongs.
          _footer(tokens, ghost: false),
          // ── Name focus ──
          // A scrim over the whole card face, then the display name
          // redrawn on top of it. Everything the card shows — banner,
          // avatar, address — falls back behind the shade; only the
          // readable name stays lit. See [_AccountCard.nameFocus].
          if (widget.nameFocus > 0) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color:
                      Colors.black.withValues(alpha: 0.62 * widget.nameFocus),
                ),
              ),
            ),
            _footer(tokens, ghost: true),
          ],
          // The tab switcher, drawn LAST so neither the banner gradient
          // nor a focus scrim can sit on top of it. It is the only
          // interactive thing on the card.
          if (widget.onTabs != null)
            Positioned(
              top: 10,
              right: 12,
              child: _TabsButton(
                attention: widget.tabsAttention,
                onTap: widget.onTabs,
              ),
            ),
        ],
      ),
    );

    final content = ClipRRect(
      borderRadius: cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: base.color,
            borderRadius: cardRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              banner,
              if (widget.bioEmptyLabel != null) _bio(tokens),
            ],
          ),
        ),
      ),
    );

    // A soft white halo that BREATHES strictly BEHIND the card while it's still
    // "empty" (skeleton), in place of a loading shimmer. It's painted as a
    // halo with the card footprint punched out (see _BreathGlowPainter) so it
    // never bleeds through the translucent glass / the card's backdrop blur — it
    // fades to nothing as the records reveal fills the card in. Knobs: glow
    // alpha 0.06→0.26, blur sigma 3→12.
    return AnimatedBuilder(
      animation: _breathe,
      child: content,
      builder: (context, child) {
        final breath = (1 - cos(_breathe.value * 2 * pi)) / 2; // smooth 0→1→0
        final glow = (0.06 + 0.20 * breath) * skeleton;
        // The card itself: the corner-fix border on top, plus the Account-page
        // capstone glow (a plain drop shadow — it only shows once the card is
        // filled with an opaque banner, so it never bleeds through the glass).
        final card = Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (widget.accountCue > 0)
                BoxShadow(
                  color: tokens.starkWhite
                      .withValues(alpha: 0.12 * widget.accountCue),
                  blurRadius: 26 * widget.accountCue,
                ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: child,
        );
        if (glow <= 0.001) return card;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BreathGlowPainter(
                  color: tokens.starkWhite.withValues(alpha: glow),
                  radius: 16,
                  sigma: 3 + 9 * breath,
                ),
              ),
            ),
            card,
          ],
        );
      },
    );
  }

  /// The bio, inside the card, under the banner block. S4b only.
  ///
  /// No blur and no glass of its own — it is already inside the card's, which
  /// is the point: one shape, one backdrop, the bio reading as part of the
  /// profile above it rather than a fifth panel competing with the presets.
  /// A hairline separates it from the banner and nothing else does.
  Widget _bio(GlassTokens tokens) {
    final bio = widget.bio;
    final empty = bio == null || bio.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: empty ? 0.02 : 0.05),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only the empty state carries an icon — it is a prompt to write.
          // A written bio gets paired quotes in the string instead.
          if (empty) ...[
            Icon(Icons.edit_outlined, size: 16, color: tokens.textDim),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              empty ? widget.bioEmptyLabel! : '“$bio”',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontStyle: FontStyle.italic,
                // `textDim` (60% white) is too faint to be the only text in a
                // near-transparent box, which is what the empty state is.
                color: empty
                    ? tokens.starkWhite.withValues(alpha: 0.80)
                    : tokens.starkWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The card's footer row — avatar slot, display name, address line.
  ///
  /// Built by one method and used twice so the two copies cannot drift: the
  /// real footer, and (under [_AccountCard.nameFocus]) a **ghost** drawn over
  /// the focus scrim. In the ghost the avatar and address are still laid out
  /// but painted at zero opacity, so they hold their space and the ghost name
  /// lands pixel-for-pixel on the real one underneath — the emphasis reads as
  /// the rest of the card dimming, never as the name moving.
  Widget _footer(GlassTokens tokens, {required bool ghost}) {
    final contact = widget.contact;
    final name = contact.displayName;
    final r = widget.recordsReveal;
    final skeleton = (1 - r).clamp(0.0, 1.0).toDouble();
    // Everything except the name is invisible in the ghost pass.
    final around = ghost ? 0.0 : 1.0;

    return Positioned(
      // Fill the card vertically so the avatar + name sit at the card's true
      // vertical centre, not bottom-anchored.
      left: 16,
      right: 16,
      top: 0,
      bottom: 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar slot: a calm placeholder squircle (the icon's own shape)
          // cross-fades into the real icon as the records reveal — no sweep,
          // matching the breathing load.
          SizedBox(
            width: 60,
            height: 60,
            child: Opacity(
              opacity: around,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (skeleton > 0)
                    Opacity(
                      opacity: skeleton,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(60 * 0.40),
                          border: Border.all(color: tokens.borderSubtle),
                        ),
                      ),
                    ),
                  Opacity(
                    opacity: r,
                    child: GlassContactIcon(
                      contact: contact,
                      address: widget.address,
                      size: 60,
                    ),
                  ),
                  // ── There is deliberately NO ring over the icon here ──
                  //
                  // A 2px ring in the page colour drawn as a sibling ON TOP
                  // of the icon would keep the avatar from reading as a
                  // hole punched in the banner (it matters most on S4b, where
                  // the banner is undarkened and the kit's pfp and banner are
                  // generated from the same address, so they can meet as
                  // near-identical tones with no edge between them).
                  //
                  // But `GlassContactIcon` draws its **phantom badge**
                  // overhanging this exact corner, and a stroke painted over
                  // the icon cuts straight through it, making the badge look
                  // see-through.
                  //
                  // ⚠ If S4b's avatar/banner edge needs separating, do
                  // NOT add a ring here: anything drawn outside the
                  // icon is drawn over its badges. The affordance belongs to
                  // the shared widget, which already takes a `borderColor` for
                  // exactly this and simply has its border block commented out.
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: tokens.starkWhite,
                    shadows: ghost
                        // Over the scrim the name gets a soft white lift
                        // instead of the legibility drop-shadow — it is the
                        // only lit thing on the card, so it should read as
                        // glowing rather than as sitting on a dark plate.
                        ? [
                            Shadow(
                              color: tokens.starkWhite.withValues(alpha: 0.45),
                              blurRadius: 18,
                            ),
                          ]
                        : const [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                  ),
                ),
                const SizedBox(height: 2),
                // Address builds in (blur → sharp) in its final slot; Opacity 0
                // still reserves the line so the name never shifts between
                // Domain and Contract — and, in the ghost pass, so the two
                // names stay aligned.
                Opacity(
                  opacity: around,
                  child: _BlurIn(
                    reveal: widget.addressReveal,
                    child: Text(
                      _shortAddress,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: tokens.starkWhite,
                        shadows: const [
                          Shadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerFallback(GlassTokens tokens) {
    final c = widget.contact.iconColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.25), tokens.surfaceDeep],
        ),
      ),
    );
  }
}

/// Paints the morph card's breathing "aura": a blurred, card-shaped glow with
/// the card footprint punched back out, so only the OUTER halo survives. Drawn
/// BEHIND the translucent, backdrop-blurred card, this keeps the glow from
/// bleeding through the glass or being pulled inside by the card's own blur —
/// it reads as a soft halo around the card edges. Driven by the breath value.
class _BreathGlowPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double sigma;

  const _BreathGlowPainter({
    required this.color,
    required this.radius,
    required this.sigma,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.saveLayer((Offset.zero & size).inflate(3 * sigma + 4), Paint());
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
    // Cut the card footprint back out → only the outer halo remains.
    canvas.drawRRect(rrect, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BreathGlowPainter old) =>
      old.color != color || old.sigma != sigma || old.radius != radius;
}

/// Blurs a child in as [reveal] climbs 0→1 (sigma 6→0) on top of a fade. Used
/// for the address "blur in" on the Contract stage.
class _BlurIn extends StatelessWidget {
  final double reveal;
  final Widget child;

  const _BlurIn({required this.reveal, required this.child});

  @override
  Widget build(BuildContext context) {
    final t = reveal.clamp(0.0, 1.0).toDouble();
    final sigma = (1 - t) * 6;
    final faded = Opacity(opacity: t, child: child);
    if (sigma < 0.05) return faded;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: faded,
    );
  }
}

/// The safe glyph at the card's bottom-right corner. [reveal] 0→1 drives a plain
/// vertical bob — it comes DOWN then settles back UP to its resting peek. No
/// horizontal slide, no rotation. At rest (reveal 1) it sits partially tucked
/// under the card so the vault reads as part of the account. Knob: [_bobDepth].

/// The bottom primary, in one of two weights.
///
/// [solid] is the loud one and is spent deliberately: it marks a press that
/// **performs** something — saving a bio or an arrangement, entering the app.
/// Everything else is navigation and renders as a ghost, so a page's own
/// action (the presets, the tabs button, ADD MY FIRST INBOX) stays the
/// brightest thing on it.
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool solid;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.solid,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            // The ghost is borderless. With no ring to keep it from reading
            // as disabled, its FILL takes that job: 10% white. Disabled is
            // the dashed outline with no fill at all, so a filled, ringless
            // pill stays tellable apart from it.
            backgroundColor: solid
                ? tokens.starkWhite
                : Colors.white.withValues(alpha: 0.10),
            foregroundColor: solid
                ? tokens.background
                : tokens.starkWhite.withValues(alpha: 0.72),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryDisabledButton extends StatelessWidget {
  final String label;

  /// A write is in flight, so the button carries the canonical loader beside
  /// its label.
  ///
  /// **Busy is not the same disabled as blocked.** The dashed treatment says
  /// *you cannot press this yet*; a save in progress needs to say *this is
  /// working* — same geometry, so nothing shifts when it resolves, but with
  /// something moving so the wait reads as progress rather than a dead button.
  /// It also replaces the ellipsis: an animation says "in progress" better
  /// than three dots that never move.
  final bool busy;

  const _PrimaryDisabledButton({required this.label, this.busy = false});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return CustomPaint(
      painter: DashedRRectPainter(color: tokens.borderSubtle, radius: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                // A working button is not a barred one — the busy label reads
                // at full strength, the blocked one stays dimmed.
                color: busy
                    ? tokens.starkWhite.withValues(alpha: 0.85)
                    : tokens.textDim.withValues(alpha: 0.55),
              ),
            ),
            if (busy) ...[
              const SizedBox(width: 12),
              // **Pixel rain, not the logo loader.** Two loaders exist and they
              // are constructor-compatible, which makes reaching for the wrong
              // one easy and silent — `PixelRainLoadingWidget` is the one that
              // belongs beside hard-edged type in a button.
              //
              // Boxed at the text's own line height so it can NEVER change the
              // row's height: this widget takes `size` as its real edge (a
              // 16x16 grid), unlike the logo loader whose container is
              // `size * 2.9`. Without the box the button would grow the instant
              // a save started and the page would nudge under the user.
              SizedBox(
                width: 18,
                height: 18,
                child: PixelRainLoadingWidget(
                  size: 18,
                  showShadows: false,
                  color: tokens.starkWhite.withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabsButton extends StatefulWidget {
  final bool attention;
  final VoidCallback? onTap;

  const _TabsButton({required this.attention, this.onTap});

  @override
  State<_TabsButton> createState() => _TabsButtonState();
}

class _TabsButtonState extends State<_TabsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.attention) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TabsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.attention && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.attention && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_pulse.value);
          final on = widget.attention;
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08 + (on ? 0.06 * t : 0)),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: tokens.starkWhite
                    .withValues(alpha: on ? 0.35 + 0.45 * t : 0.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                ),
                if (on)
                  BoxShadow(
                    color: tokens.starkWhite.withValues(alpha: 0.15 + 0.4 * t),
                    blurRadius: 6 + 12 * t,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: tokens.starkWhite.withValues(alpha: 0.85),
            ),
          );
        },
      ),
    );
  }
}

/// Read-only sheet listing an account's tabs — the same set the browser's tab
/// selector shows: the built-in Profile + Chat, then whatever the account
/// publishes (websites, feeds). Settings omitted.
///
/// **No fabricated rows.** The card above it is a REAL account (PublicOS),
/// so inventing tabs for it would be a lie on screen — the whole point of S2
/// is that the user is looking at something true. What the account actually
/// publishes is what shows.
class _TabsSheet extends StatelessWidget {
  final String accountName;
  final List<Record> customTabs;
  final List<AppBookmark> apps;
  final bool isOrg;

  const _TabsSheet({
    required this.accountName,
    required this.customTabs,
    required this.apps,
    required this.isOrg,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;

    final rows = <Widget>[
      _row(
        tokens,
        icon: Icon(Icons.person_outline,
            size: 18, color: tokens.starkWhite.withValues(alpha: 0.9)),
        name: l10n.onbTabProfile,
        type: l10n.onbTabProfile,
      ),
      _row(
        tokens,
        icon: Icon(Icons.chat_bubble_outline,
            size: 18, color: tokens.starkWhite.withValues(alpha: 0.9)),
        name: l10n.onbTabChat,
        type: l10n.onbTabChat,
      ),
      // Web + feed tabs — the account's router records.
      for (final record in customTabs)
        _row(
          tokens,
          icon: SizedBox(
            width: 22,
            height: 22,
            child: TabIconWidget(record: record, size: 22),
          ),
          name: record.metadata['name'] as String? ?? l10n.onbTabFallback,
          type: record.routerSubtype == RouterSubtype.channel
              ? l10n.onbTabFeed
              : l10n.onbTabWebsite,
        ),
      // Registered apps — a separate on-chain source from router records.
      for (final app in apps)
        _row(
          tokens,
          icon: Icon(Icons.apps_rounded,
              size: 18, color: tokens.starkWhite.withValues(alpha: 0.9)),
          name: app.displayName.isNotEmpty ? app.displayName : app.appName,
          type: l10n.onbTabApp,
        ),
      // Org accounts carry a Management tab; PublicOS is one, so leaving it
      // out would make the sheet disagree with what the browser shows.
      if (isOrg)
        _row(
          tokens,
          icon: Icon(Icons.admin_panel_settings_rounded,
              size: 18, color: tokens.starkWhite.withValues(alpha: 0.9)),
          name: l10n.onbTabManagement,
          type: l10n.onbTabOrg,
        ),
    ];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep.withValues(alpha: 0.94),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: tokens.starkWhite.withValues(alpha: 0.12)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: tokens.starkWhite.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 14),
                  child: Text(
                    // Names the account whose tabs these are, so the sheet
                    // reads as a fact about the card above it.
                    l10n.onbTabsSheetTitle(accountName),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: tokens.starkWhite,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rows,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One tab row. The type label is a plain dim caption, not a tinted chip
  /// (teal / amber / blue per type): the app is monochrome and colour
  /// carries meaning, never category.
  Widget _row(
    GlassTokens tokens, {
    required Widget icon,
    required String name,
    required String type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(width: 22, height: 22, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.starkWhite,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: tokens.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

/// S5's list of what a tab can be.
///
/// **Read off the app's real surfaces.** The app adds tabs from
/// `create_tab_sheet` (**Web page** and **Channel**, with those exact labels
/// and glyphs) and inboxes from the Inbox IDs page. There is no in-app route
/// to add an AI-assistant tab — app entries are registered on chain outside
/// the client — so it is not listed. A teaching screen that names a control
/// the user cannot find teaches them the app is broken.
///
/// The rule: *when a screen imitates an existing surface, read that
/// surface, not an older imitation of it.*
class _TabKindList extends StatelessWidget {
  /// Whether the account actually publishes an inbox. Drives the badge only —
  /// the row is listed either way, because "an inbox" is a thing a tab can be
  /// whether or not this account has one yet.
  final bool inboxAdded;

  const _TabKindList({required this.inboxAdded});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TabKindRow(
          icon: Icons.inbox_rounded,
          title: l10n.onbTabsInboxTitle,
          subtitle: l10n.onbTabsInboxSub,
          badge: inboxAdded ? l10n.onbTabsAdded : null,
        ),
        const SizedBox(height: 8),
        _TabKindRow(
          // `create_tab_sheet.dart`'s own glyph and label for this kind.
          icon: Icons.language_rounded,
          title: l10n.createTabSheetKindWeb,
          subtitle: l10n.onbTabsWebSub,
        ),
        const SizedBox(height: 8),
        _TabKindRow(
          icon: Icons.rss_feed_rounded,
          title: l10n.createTabSheetKindChannel,
          subtitle: l10n.onbTabsChannelSub,
        ),
        const SizedBox(height: 8),
        _TabKindRow(
          icon: Icons.inbox_rounded,
          title: l10n.onbTabsAnotherTitle,
          subtitle: l10n.onbTabsAnotherSub,
        ),
      ],
    );
  }
}

/// One kind of tab, as a row. **Inert on purpose** — no `onTap`, no chevron,
/// no ripple. Every other list in this tour is something to act on; this one is
/// a menu the user is being shown, and giving the rows an affordance they do
/// not have would send them tapping at a page that cannot answer.
class _TabKindRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  const _TabKindRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: tokens.textDim),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tokens.starkWhite,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: tokens.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.connectedAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: tokens.connectedAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
