import 'dart:async';
import 'contact_banner.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Opens the unified **Domain Store** as a tall draggable sheet. Reused from
/// onboarding (Your Domain) and — later — the account center, which already
/// owns a domain-status section, so [showStatus] gates the top status header.
/// [account] defaults to the signed-in user.
///
/// You can search any name, preview who holds it (ephemerally — never
/// persisted), and see the length-tiered price for N months with the prepay
/// discount broken out. The live action is rule-aware: **RENEW** your own domain
/// (`payDomain`) or **CLAIM** a different name (`changeName` — a rename of your
/// account), each balance-gated and gated by the on-chain rules.
///
/// [onChanged] fires after a successful pay/claim so a caller can refresh the
/// surface behind the sheet.
///
/// [closeOnPaid] closes the sheet after a successful pay/claim. Onboarding
/// sets it: there the sheet was opened to do that one thing, and the tour
/// behind it re-reads the domain on the return.
Future<void> showDomainStoreSheet(
  BuildContext context, {
  bool showStatus = true,
  EthereumAddress? account,
  VoidCallback? onChanged,
  bool closeOnPaid = false,
}) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _DomainStoreSheet(
      showStatus: showStatus,
      account: account,
      onChanged: onChanged,
      closeOnPaid: closeOnPaid,
    ),
  );
}

/// What the focused name maps to under the contract rules.
enum _DomainActionKind { none, renew, claim }

class _DomainStoreSheet extends StatefulWidget {
  final bool showStatus;
  final EthereumAddress? account;
  final VoidCallback? onChanged;
  final bool closeOnPaid;

  const _DomainStoreSheet({
    required this.showStatus,
    this.account,
    this.onChanged,
    this.closeOnPaid = false,
  });

  @override
  State<_DomainStoreSheet> createState() => _DomainStoreSheetState();
}

class _DomainStoreSheetState extends State<_DomainStoreSheet> {
  /// ~year-3000 sentinel: a free-tier citizen / seeded root holds forever.
  static final BigInt _neverSentinel = BigInt.from(32503680000 - 1);

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  EthereumAddress? _account;
  Contact? _selfContact;
  String _ownName = '';

  // Account-level domain state. Loaded for both the (optional) status header
  // AND the business rules below, so it's read regardless of showStatus.
  BigInt? _paidUntil;
  bool? _compliant;
  bool _statusLoaded = false;

  // Rename-ticket ledger for the account (citizen free-change gate). A citizen
  // 5+ rename consumes the annual window or a bonus ticket; with neither the
  // rename still succeeds — the citizen pays a flat one-period fee and keeps
  // lifetime. Recurring-priced renames ignore it.
  ({bool annualOpen, BigInt nextAnnualAt, BigInt bonusTickets})? _renameQuota;

  // Citizenship — needed to spot a LIFETIME destination that still costs money
  // (a ticketless citizen taking a 5+ name pays a flat one-period fee but is
  // stamped NEVER): the quote alone can't distinguish that from a private's
  // recurring purchase, and months must stay locked for it.
  bool? _isCitizen;

  // Payment context for the live RENEW / CLAIM action.
  BigInt? _balance; // OX balance of the account's MainSafe (the payer)
  bool _submitting = false;
  String? _submitError;

  // Domain economy params.
  DomainInfo? _info;
  int _months = 1;
  int _maxMonths = 12;

  // Search state — ephemeral, never saved.
  String _query = '';
  bool _searching = false;
  int _searchSeq = 0; // drops out-of-order resolves (mirrors _quoteSeq)
  Contact? _searchedContact; // the holder, if the searched name is taken
  int? _claimStatus; // 0 avail · 1 evictable · 2 blocked · 3 cooldown · 4 yours
  NameValidationResult? _validation; // format check on the typed name
  NameTierLimits? _tierLimits; // governance-set name min/max, read once

  // Quote for the focused name (searched name, else the user's own). The
  // breakdown's money rows derive from the SETTLED snapshot (_quotedMonths /
  // _quotedLen), never the live inputs — so a half-applied month step can't
  // flash a wrong discount. _quoteSeq drops out-of-order responses.
  ({BigInt cost, bool isFree})? _quote;
  int _quoteSeq = 0;
  int? _quotedMonths;
  int? _quotedLen;
  bool _loadingQuote = true;

  @override
  void initState() {
    super.initState();
    final hex = PublicOS.myPublicosAddress;
    _account = widget.account ??
        (hex != null ? EthereumAddress.fromHex(hex) : null);
    _searchCtrl.addListener(_onSearchChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final account = _account;
    if (account != null) {
      try {
        final c = await PublicOSContacts.getContact(account);
        if (mounted && c != null) {
          setState(() {
            _selfContact = c;
            _ownName = c.publicosDisplayName ?? c.displayName;
          });
        }
      } catch (_) {}
    }
    try {
      final info = await PublicOSTreasury.getDomainInfo();
      if (mounted) {
        setState(() {
          _info = info;
          _maxMonths = info.maxDomainMonths.toInt().clamp(1, 60);
        });
      }
    } catch (_) {}
    try {
      final limits = await PublicOSAccounts.getNameTierLimits();
      if (mounted) setState(() => _tierLimits = limits);
    } catch (_) {}
    // Read account domain state regardless of showStatus: the header is gated,
    // but the claim/price rules (lifetime lock, frozen-claim gate, free-rename
    // quota) need this data even when the header is hidden.
    if (account != null) {
      try {
        final paid = await PublicOSTreasury.getDomainPaidUntil(account);
        final compliant = await PublicOSTreasury.isDomainCompliant(account);
        if (mounted) {
          setState(() {
            _paidUntil = paid;
            _compliant = compliant;
            _statusLoaded = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _statusLoaded = true);
      }
      try {
        final q = await PublicOSAccounts.getRenameQuota(account: account);
        if (mounted) setState(() => _renameQuota = q);
      } catch (_) {}
      try {
        final cit = await PublicOSAccounts.isCitizen(account);
        if (mounted) setState(() => _isCitizen = cit);
      } catch (_) {}
      try {
        final mainHex = await PublicOSSafe.getMainSafeAddress(account);
        if (mainHex != null) {
          final bal = await PublicOSTreasury.getTokenBalance(
              EthereumAddress.fromHex(mainHex));
          if (mounted) setState(() => _balance = bal);
        }
      } catch (_) {}
    }
    await _refreshQuote();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchCtrl.text.trim();
      if (q == _query) return;
      // Run the canonical name validator before touching the chain.
      final validation = q.isEmpty
          ? null
          : DisplayNameValidator.validate(q,
              minLength: _storeMin, maxLength: _storeMax);
      setState(() {
        _query = q;
        _validation = validation;
      });
      if (q.isEmpty || (validation?.ok ?? false)) {
        _resolveSearch(q);
        _refreshQuote();
      } else {
        // Invalid format — skip the lookups + quote, clear stale results.
        setState(() {
          _searching = false;
          _searchedContact = null;
          _claimStatus = null;
          _quote = null;
          _loadingQuote = false;
        });
      }
    });
  }

  /// Resolve the typed name to its on-chain holder (if taken) for the preview.
  /// CHAIN-DIRECT: name → on-chain holder address → `fetchContact`. We do NOT use
  /// `resolveByIdentifier`, which matches LOCAL contacts first — including XMTP
  /// rows like a `*.farcaster.eth` that display as the name with an XMTP badge.
  /// `fetchContact` may cache the holder's row; the upcoming `bookmarked` flag is
  /// what will later separate real (bookmarked) contacts from searched ones.
  Future<void> _resolveSearch(String q) async {
    final seq = ++_searchSeq;
    if (q.isEmpty) {
      setState(() {
        _searchedContact = null;
        _claimStatus = null;
      });
      return;
    }
    // Clear the PREVIOUS name's results before awaiting, so the stale status
    // can't bleed through the async gap. Critical because your own name is a
    // prefix of what you type next (jmsl → jmsl8): without this, the resolved
    // own-name status 4 ("This is your name") shows for the new name until the
    // fresh read lands.
    setState(() {
      _searching = true;
      _searchedContact = null;
      _claimStatus = null;
    });
    Contact? contact;
    int? status;
    try {
      final addr =
          await PublicOSContacts.getPublicosAddressByPublicosDisplayName(q);
      if (addr != null &&
          addr !=
              EthereumAddress.fromHex(
                  '0x0000000000000000000000000000000000000000')) {
        contact = await PublicOSContacts.fetchContact(addr);
      }
    } catch (_) {}
    try {
      status = await PublicOSAccounts.getNameClaimStatus(q);
    } catch (_) {}
    // Only the latest in-flight resolve wins → an earlier, slower read of a
    // different name (the debounce cancels the timer, not the started request)
    // can't clobber the current one's results.
    if (!mounted || seq != _searchSeq) return;
    setState(() {
      _searchedContact = contact;
      _claimStatus = status;
      _searching = false;
    });
  }

  String get _nameForQuote => _query.isNotEmpty ? _query : _ownName;

  // The store explores claimable names from the absolute floor up (the
  // citizen/rename floor, ~3) — not the caller's private tier floor; pricing +
  // claimability are decided by the chain reads. Governance-set, read once.
  int get _storeMin => _tierLimits?.minCitizen ?? 3;
  int get _storeMax => _tierLimits?.maxChars ?? 32;

  // ── Rule predicates (derived from the domain contracts) ──────────────────

  /// The focused name IS the user's current name. An empty search box (showing
  /// your own domain) and typing your exact current name are the same thing —
  /// case-insensitive to mirror the contract's name hash, which folds A–Z.
  bool get _isOwnNameFocused {
    if (_query.isEmpty) return true;
    return _ownName.isNotEmpty && _query.toLowerCase() == _ownName.toLowerCase();
  }

  /// Claim status to DISPLAY. The chain returns 4 ("already yours") for your
  /// current name, but an empty box never hits the chain — synthesize it so the
  /// empty state and the typed-own-name state read identically.
  int? get _effectiveClaimStatus => _isOwnNameFocused ? 4 : _claimStatus;

  /// Is the focused name free for this user — i.e. nothing to pay, so the months
  /// stepper is meaningless and stays locked.
  ///
  /// For your OWN name the truth is the actual `domainPaidUntil`, NOT the rename
  /// quote: an account can carry the lifetime `NEVER` sentinel on a premium 3–4
  /// name (the sovereign `jmsl`, seeded via `seedDomainNever`), where
  /// `quoteName.isFree` is `false` (the contract's free check is
  /// `isCitizen && len >= freeTierMinChars`) yet it pays nothing forever. So OR
  /// in `_isLifetime`. (`quoteName.isFree` is also kept for the not-yet-synced
  /// live-chain citizen who is free-tier but hasn't been stamped `NEVER` yet —
  /// `payDomain` is a no-op for them too.)
  ///
  /// For a DIFFERENT name (a claim) the quote is correct: would taking that name
  /// be free for me.
  bool get _focusedIsFree {
    if (_isOwnNameFocused) return _isLifetime || (_quote?.isFree ?? false);
    return _quote?.isFree ?? false;
  }

  /// The user holds a `NEVER`-sentinel (lifetime) domain — a free-tier citizen
  /// or a seeded account. Never expires, never evictable.
  bool get _isLifetime {
    final paid = _paidUntil;
    return paid != null && paid > _neverSentinel;
  }

  /// The account is frozen by the consensus gate: its domain lapsed, so it can
  /// ONLY pay its own domain (`payDomain`) — `changeName` is not carved out, so
  /// it cannot claim a different name until it renews. Unknown compliance (read
  /// failed) does not block.
  bool get _isFrozen => _statusLoaded && _compliant == false && !_isLifetime;

  /// A free (citizen) rename is grantable right now — the annual window is open
  /// or a bonus ticket is held. Unknown quota does not pre-block.
  bool get _freeChangeAvailable {
    final q = _renameQuota;
    if (q == null) return true;
    return q.annualOpen || q.bonusTickets > BigInt.zero;
  }

  /// The FOCUSED name would be a LIFETIME (NEVER) hold for this user: they are
  /// a citizen and the name clears the free tier. Ticket or not, months are
  /// meaningless on this destination — a ticket makes it free, no ticket makes
  /// it a flat one-period fee (bucket B of domain_rename_pay) — so the months
  /// stepper stays locked and the projected expiry reads "Lifetime".
  bool get _focusedIsLifetimeDest {
    if (_isCitizen != true) return false;
    final freeMin = _info?.freeTierMinChars.toInt() ?? 5;
    return _nameForQuote.characters.length >= freeMin;
  }

  Future<void> _refreshQuote() async {
    final name = _nameForQuote;
    final account = _account;
    final monthsAtCall = _months;
    final lenAtCall = name.characters.length;
    final seq = ++_quoteSeq;
    if (name.isEmpty || account == null) {
      if (mounted) {
        setState(() {
          _quote = null;
          _quotedMonths = null;
          _quotedLen = null;
          _loadingQuote = false;
        });
      }
      return;
    }
    setState(() => _loadingQuote = true);
    try {
      final q = await PublicOSAccounts.quoteName(
        name,
        months: monthsAtCall,
        account: account,
      );
      // Only the latest in-flight request wins → no out-of-order overwrite.
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = q;
        _quotedMonths = monthsAtCall;
        _quotedLen = lenAtCall;
        _loadingQuote = false;
      });
    } catch (_) {
      // Invalid / too-short name etc. — show a dash, no crash.
      if (!mounted || seq != _quoteSeq) return;
      setState(() {
        _quote = null;
        _quotedMonths = null;
        _quotedLen = null;
        _loadingQuote = false;
      });
    }
  }

  void _changeMonths(int delta) {
    final next = _months + delta;
    if (next < 1 || next > _maxMonths) return;
    setState(() => _months = next);
    if (_query.isEmpty || (_validation?.ok ?? false)) _refreshQuote();
  }

  /// Undiscounted token price for a name of [len] characters, from the tier
  /// ladder. Null below the minimum length or before params load.
  double? _tierTokens(int len) {
    final info = _info;
    if (info == null || len < 3) return null;
    if (len == 3) return info.priceTier3Tokens;
    if (len == 4) return info.priceTier4Tokens;
    if (len == 5) return info.priceTier5Tokens;
    return info.priceTier6PlusTokens;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      // A DraggableScrollableSheet ignores the keyboard on its own; this keeps
      // the search field + body above the IME.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 1.0,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.travel_explore_rounded,
                        color: tokens.starkWhite, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.domainStoreTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded,
                          color: tokens.textDim, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showStatus) ...[
                          _statusHeader(tokens),
                          const SizedBox(height: 18),
                        ],
                        _searchBox(tokens),
                        const SizedBox(height: 16),
                        _StoreCard(
                          contact:
                              _query.isNotEmpty ? _searchedContact : _selfContact,
                          name: _query.isNotEmpty ? _query : _ownName,
                          searching: _searching,
                        ),
                        // Always shown — an empty box reads as "this is your name"
                        // (same as typing your current name).
                        const SizedBox(height: 8),
                        _availabilityLine(tokens),
                        ..._claimNotes(tokens),
                        const SizedBox(height: 20),
                        _breakdown(tokens),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: _claimFooter(tokens),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status header (gated by showStatus) ──────────────────────────────────

  Widget _statusHeader(GlassTokens tokens) {
    final paid = _paidUntil;
    final lifetime = paid != null && paid > _neverSentinel;
    final overdue = _statusLoaded && !lifetime && _compliant == false;
    final tone = overdue ? const Color(0xFFFFAB40) : tokens.starkWhite;

    String statusText;
    if (!_statusLoaded) {
      statusText = context.l10n.domainChecking;
    } else if (lifetime) {
      statusText = context.l10n.domainLifetimeStatus;
    } else if (paid == null || paid == BigInt.zero) {
      statusText = context.l10n.domainNotSet;
    } else {
      final dt = DateTime.fromMillisecondsSinceEpoch(paid.toInt() * 1000);
      statusText =
          '${overdue ? context.l10n.domainWasDue : context.l10n.domainPaidUntilLabel} ${_fmtDate(dt)}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: overdue
            ? tone.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdue ? tone.withValues(alpha: 0.3) : tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.l10n.domainYourDomain,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: tokens.textDim,
                ),
              ),
              const Spacer(),
              _statusBadge(tokens, lifetime: lifetime, overdue: overdue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _ownName.isEmpty ? '—' : _ownName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: tokens.starkWhite,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: overdue ? tone : tokens.textDim,
            ),
          ),
          if (overdue) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.domainGraceNote,
              style: TextStyle(
                fontSize: 11,
                color: tokens.textDim,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(GlassTokens tokens,
      {required bool lifetime, required bool overdue}) {
    final (label, color) = !_statusLoaded
        ? ('…', tokens.textDim)
        : lifetime
            ? (context.l10n.domainBadgeLifetime, tokens.starkWhite)
            : overdue
                ? (context.l10n.domainBadgeOverdue, const Color(0xFFFFAB40))
                : (context.l10n.domainBadgeActive, tokens.connectedAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }

  // ── Search ───────────────────────────────────────────────────────────────

  Widget _searchBox(GlassTokens tokens) {
    return TextField(
      controller: _searchCtrl,
      style: TextStyle(fontSize: 14, color: tokens.starkWhite),
      decoration: InputDecoration(
        filled: true,
        fillColor: tokens.surfaceElevated,
        isDense: true,
        hintText: context.l10n.domainSearchHint,
        hintStyle: TextStyle(color: tokens.textDim),
        prefixIcon: Icon(Icons.search_rounded, color: tokens.textDim, size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
        ),
      ),
    );
  }

  Widget _availabilityLine(GlassTokens tokens) {
    // A format error on the typed name takes precedence over claimability.
    final v = _validation;
    if (v != null && !v.ok) {
      const amber = Color(0xFFFFAB40);
      final warnings = _nameWarnings(_query);
      final list = warnings.isEmpty ? [_nameErrorText(v)] : warnings;
      // Show EVERY applicable warning at once (the canonical validator returns
      // only the first), stacked in a column.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(w,
                        style: const TextStyle(fontSize: 12, color: amber)),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    // Empty box / own-name focus before the name resolves: don't assert "this
    // is your name" until we actually know it.
    if (_isOwnNameFocused && _ownName.isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: tokens.textDim),
          const SizedBox(width: 6),
          Text(_statusLoaded ? '—' : context.l10n.domainChecking,
              style: TextStyle(fontSize: 12, color: tokens.textDim)),
        ],
      );
    }
    final status = _effectiveClaimStatus;
    final (label, color) = switch (status) {
      0 => (context.l10n.domainStatusAvailable, tokens.connectedAccent),
      1 => (context.l10n.domainStatusLapsed, const Color(0xFFFFAB40)),
      2 => (context.l10n.domainStatusTaken, tokens.textDim),
      3 => (context.l10n.domainStatusCooldown, tokens.textDim),
      4 => (context.l10n.domainStatusYours, tokens.connectedAccent),
      _ => (_searching ? context.l10n.domainChecking : '—', tokens.textDim),
    };
    return Row(
      children: [
        Icon(
          status == 0 || status == 4
              ? Icons.check_circle_outline_rounded
              : Icons.info_outline_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  /// Extra rule notes under the availability line. Today: the consensus
  /// freeze-gate — a lapsed account can only pay its OWN domain, never claim a
  /// different name, so claiming a claimable name is blocked until it renews.
  List<Widget> _claimNotes(GlassTokens tokens) {
    const amber = Color(0xFFFFAB40);
    final claimable =
        _effectiveClaimStatus == 0 || _effectiveClaimStatus == 1;
    if (!_isOwnNameFocused && claimable && _isFrozen) {
      return [
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 14, color: amber),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                context.l10n.domainStoreSheetOverdueRenewFirst,
                style: const TextStyle(fontSize: 12, color: amber, height: 1.35),
              ),
            ),
          ],
        ),
      ];
    }
    return const [];
  }

  /// Maps the canonical validator's reason to a short message (mirrors the
  /// account-center rename sheet). Names share one tier floor in the store
  /// (`_storeMin`); pricing differs by length, not validity.
  String _nameErrorText(NameValidationResult v) {
    return switch (v.reason) {
      NameValidationError.tooShort => context.l10n.domainNameTooShort(_storeMin),
      NameValidationError.tooLong => context.l10n.domainNameTooLong(_storeMax),
      NameValidationError.leadingNonAlpha => context.l10n.domainNameStartLetter,
      NameValidationError.trailingNonAlphanumeric =>
        context.l10n.domainNameEndDashUnderscore,
      NameValidationError.illegalChar => context.l10n.domainNameAllowed,
      NameValidationError.consecutiveDash => context.l10n.domainNameNoConsecDash,
      NameValidationError.consecutiveUnderscore =>
        context.l10n.domainNameNoConsecUnderscore,
      _ => '—',
    };
  }

  /// EVERY format violation for [name] at once (the canonical validator returns
  /// only the first). Mirrors `DisplayNameValidator`'s rule set.
  List<String> _nameWarnings(String name) {
    final out = <String>[];
    if (name.isEmpty) return out;
    final units = name.codeUnits;
    bool isAlpha(int c) =>
        (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
    bool isAlnum(int c) => isAlpha(c) || (c >= 0x30 && c <= 0x39);
    bool isAllowed(int c) => isAlnum(c) || c == 0x2D || c == 0x5F;

    final len = name.characters.length;
    if (len < _storeMin) out.add(context.l10n.domainNameTooShort(_storeMin));
    if (len > _storeMax) out.add(context.l10n.domainNameTooLong(_storeMax));
    if (!isAlpha(units.first)) out.add(context.l10n.domainNameStartLetter);
    if (!isAlnum(units.last)) out.add(context.l10n.domainNameEndDashUnderscore);
    if (units.any((c) => !isAllowed(c))) out.add(context.l10n.domainNameAllowed);
    if (name.contains('--')) out.add(context.l10n.domainNameNoConsecDash);
    if (name.contains('__')) out.add(context.l10n.domainNameNoConsecUnderscore);
    return out;
  }

  // ── Price breakdown (styled after the BSP/SSP subscribe sheet) ────────────

  Widget _breakdown(GlassTokens tokens) {
    final name = _nameForQuote;
    final len = name.characters.length;
    final valid = _query.isEmpty || (_validation?.ok ?? true);
    // For your own name this looks at the real paidUntil (lifetime sentinel),
    // not the rename quote — a premium NEVER name (jmsl) is free too.
    final isFree = valid && _focusedIsFree;
    // Bucket B: a ticketless citizen taking a 5+ name PAYS
    // a flat one-period fee but still lands on lifetime — months stay locked
    // and the money rows must not scale by the stepper.
    final flatLifetime = valid && !isFree && _focusedIsLifetimeDest;

    // Money rows derive from the SETTLED quote snapshot (its length + months),
    // not the live inputs — so stepping months can't flash a mismatched discount.
    final qLen = _quotedLen;
    final qMonths = _quotedMonths;
    final tier = (valid && qLen != null) ? _tierTokens(qLen) : null;
    final subtotal = (tier != null && qMonths != null && !isFree)
        ? tier * (flatLifetime ? 1 : qMonths)
        : null;
    final total = (_quote != null && valid && !isFree)
        ? _quote!.cost.toDouble() / 1e18
        : null;
    final discount =
        (subtotal != null && total != null) ? (subtotal - total) : null;
    final hasDiscount = discount != null && discount > 0.001;
    final discountLabel = (hasDiscount && subtotal != null)
        ? '−${_fmtPos(discount)}  ·  −${(discount / subtotal * 100).toStringAsFixed(0)}%'
        : '—';

    // Keep the last settled value while a new quote is in flight — only the very
    // first load (no prior quote) shows "Calculating…".
    final totalText = isFree
        ? context.l10n.domainFreeForYou
        : !valid
            ? '—'
            : (total != null
                ? _fmtPos(total)
                : (_loadingQuote ? context.l10n.domainCalculating : '—'));

    // ── Projected outcome after paying ──────────────────────────────────────
    // "Paid until": free → the lifetime sentinel ("Lifetime"); else the new
    // expiry, stacking onto max(now, current) exactly like the contract (and
    // clamping a current NEVER down to now, so a lifetime account taking a
    // premium name shows now+months, not year-3000).
    String paidUntilText;
    Color? paidUntilColor;
    if (isFree || flatLifetime) {
      // Free-covered OR flat-fee: a citizen-5+ destination is lifetime either way.
      paidUntilText = context.l10n.domainLifetimeNeverExpires;
      paidUntilColor = tokens.connectedAccent;
    } else if (valid && _quote != null && qMonths != null && _info != null) {
      final nowS = BigInt.from(DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final current = _paidUntil ?? BigInt.zero;
      var base = current > nowS ? current : nowS;
      if (base > _neverSentinel) base = nowS; // don't stack from the sentinel
      final after = base + BigInt.from(qMonths) * _info!.domainPeriod;
      paidUntilText =
          _fmtDate(DateTime.fromMillisecondsSinceEpoch(after.toInt() * 1000));
    } else {
      paidUntilText = _loadingQuote ? context.l10n.domainCalculating : '—';
    }

    // "Balance after": current wallet OX minus the cost (can go negative when
    // short — surfaced in amber alongside the insufficient-funds warning).
    final balanceAfter =
        (!isFree && valid && _balance != null && _quote != null)
            ? (_balance! - _quote!.cost).toDouble() / 1e18
            : null;

    // Every row keeps its label and shows "—" when it doesn't apply, so nothing
    // appears/disappears as you type or step months (no text jump).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kvRow(
          tokens,
          context.l10n.domainName,
          name.isEmpty ? '—' : '$name  ·  ${context.l10n.domainChars(len)}',
        ),
        const SizedBox(height: 14),
        // A free (citizen / lifetime) name is free for any period, and a
        // flat-fee lifetime claim (bucket B) charges one period regardless —
        // either way months are meaningless and the stepper stays locked.
        _monthsRow(tokens, context.l10n.domainMonths, _months, _changeMonths,
            enabled: !isFree && !flatLifetime),
        const SizedBox(height: 14),
        _kvRow(tokens, context.l10n.domainSubtotal,
            subtotal == null ? '—' : _fmtPos(subtotal)),
        const SizedBox(height: 8),
        _kvRow(tokens, context.l10n.domainDiscount, discountLabel,
            valueColor: hasDiscount ? tokens.connectedAccent : null),
        const SizedBox(height: 8),
        _kvRow(tokens, context.l10n.domainTotal, totalText,
            valueColor: isFree ? tokens.connectedAccent : null),
        const SizedBox(height: 8),
        // Projected expiry after this payment (stacks onto any time you have).
        _kvRow(tokens, context.l10n.domainPaidUntilLabel, paidUntilText,
            valueColor: paidUntilColor),
        // Balance + cost-before-commit: only meaningful when something is owed.
        if (!isFree && valid) ...[
          const SizedBox(height: 8),
          _kvRow(
            tokens,
            context.l10n.domainBalance,
            _balance == null ? '—' : _fmtPos(_balance!.toDouble() / 1e18),
            valueColor: _shortBalance ? const Color(0xFFFFAB40) : null,
          ),
          const SizedBox(height: 8),
          _kvRow(
            tokens,
            context.l10n.domainBalanceAfter,
            balanceAfter == null ? '—' : _fmtPos(balanceAfter),
            valueColor: _shortBalance ? const Color(0xFFFFAB40) : null,
          ),
          if (_shortBalance) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.domainNotEnoughPosNote,
              style: const TextStyle(fontSize: 11, color: Color(0xFFFFAB40)),
            ),
          ],
        ],
        const SizedBox(height: 10),
        _breakdownNote(tokens),
      ],
    );
  }

  /// The payer's MainSafe can't cover the focused (paid) name's cost. False for
  /// free names and while the quote / balance is still loading.
  bool get _shortBalance {
    final c = _quote?.cost;
    final b = _balance;
    if (_focusedIsFree || c == null || b == null) return false;
    return b < c;
  }

  /// The note under the price rows — context-aware:
  ///  • free + your own name → lifetime / citizen-free explainer;
  ///  • free + a different name → the rename-quota state (free renames are
  ///    quota-limited: annual window or a bonus ticket, else it reverts);
  ///  • paid → the prepay-discount + burn/stipend footnote.
  Widget _breakdownNote(GlassTokens tokens) {
    const amber = Color(0xFFFFAB40);
    final dim = TextStyle(fontSize: 11, color: tokens.textDim, height: 1.45);

    if (_focusedIsFree) {
      final freeMin = _info?.freeTierMinChars.toInt() ?? 5;
      if (_isOwnNameFocused) {
        return Text(
          _isLifetime
              ? context.l10n.domainNoteLifetime
              : context.l10n.domainNoteFreeCitizenChar(freeMin),
          style: dim,
        );
      }
      // A free CLAIM of a different name: a citizen rename, quota-gated.
      final q = _renameQuota;
      if (q == null) {
        return Text(context.l10n.domainNoteFreeCitizen, style: dim);
      }
      if (q.annualOpen) {
        return Text(
          context.l10n.domainNoteFreeAnnual,
          style: TextStyle(fontSize: 11, color: tokens.connectedAccent, height: 1.45),
        );
      }
      if (q.bonusTickets > BigInt.zero) {
        return Text(
          context.l10n.domainNoteFreeBonus(q.bonusTickets.toInt()),
          style: TextStyle(fontSize: 11, color: tokens.connectedAccent, height: 1.45),
        );
      }
      final next = DateTime.fromMillisecondsSinceEpoch(
          q.nextAnnualAt.toInt() * 1000);
      return Text(
        context.l10n.domainNoteNoFreeUntil(_fmtDate(next)),
        style: const TextStyle(fontSize: 11, color: amber, height: 1.45),
      );
    }

    // Bucket B: a lifetime destination with no ticket —
    // one flat period buys the name forever. Show when the free path reopens.
    if (_focusedIsLifetimeDest) {
      final q = _renameQuota;
      if (q == null || _isOwnNameFocused) {
        return Text(context.l10n.domainNoteFlatFee, style: dim);
      }
      final next =
          DateTime.fromMillisecondsSinceEpoch(q.nextAnnualAt.toInt() * 1000);
      return Text(
        context.l10n.domainNoteFlatFeeNextFree(_fmtDate(next)),
        style: dim,
      );
    }

    return Text(
      context.l10n.domainNoteDiscount(_trimNum(_info?.discountPercent ?? 0)),
      style: dim,
    );
  }

  /// Resolve the focused name to the live action under the contract rules:
  /// RENEW your own domain (`payDomain`), CLAIM a different name (`changeName`,
  /// a rename of your account), or a non-actionable info state (yours / taken /
  /// cooldown / frozen / no free change / not enough OX). `cost` is the OX
  /// owed (0 when free); `label`/`icon` drive the button.
  ({
    _DomainActionKind kind,
    bool submittable,
    bool isFree,
    BigInt cost,
    IconData icon,
    String label,
  }) _resolveAction() {
    none(IconData i, String l) => (
          kind: _DomainActionKind.none,
          submittable: false,
          isFree: false,
          cost: BigInt.zero,
          icon: i,
          label: l,
        );

    // Invalid typed name takes precedence.
    final v = _validation;
    if (_query.isNotEmpty && v != null && !v.ok) {
      return none(Icons.edit_off_rounded, context.l10n.domainEnterValidName);
    }
    // Still resolving the focused name's quote / claimability — don't let the
    // button fire against a stale months/cost.
    if (_loadingQuote || (_query.isNotEmpty && _searching)) {
      return none(Icons.lock_clock_rounded, context.l10n.domainBtnChecking);
    }

    final cost = _quote?.cost ?? BigInt.zero;
    final free = _focusedIsFree;

    // Your own name (empty box or typed).
    if (_isOwnNameFocused) {
      if (free) return none(Icons.verified_rounded, context.l10n.domainBtnYourName);
      // RENEW (payDomain) — allowed even while frozen: it IS the un-freeze.
      if (_quote == null || _balance == null) {
        return none(Icons.lock_clock_rounded, context.l10n.domainBtnChecking);
      }
      if (_balance! < cost) {
        return none(Icons.account_balance_wallet_outlined, context.l10n.domainBtnNotEnoughPos);
      }
      return (
        kind: _DomainActionKind.renew,
        submittable: true,
        isFree: false,
        cost: cost,
        icon: Icons.autorenew_rounded,
        label: '${context.l10n.domainBtnRenew} · ${_fmtPos(cost.toDouble() / 1e18)}',
      );
    }

    // A different name — claiming it renames your account to it.
    switch (_effectiveClaimStatus) {
      case 2:
        return none(Icons.block_rounded, context.l10n.domainBtnNameTaken);
      case 3:
        return none(Icons.hourglass_bottom_rounded, context.l10n.domainBtnOnCooldown);
      case 0:
      case 1:
        // changeName is not a consensus carve-out → a frozen account must renew
        // its own domain before it can claim a different name.
        if (_isFrozen) {
          return none(Icons.lock_rounded, context.l10n.domainBtnRenewFirst);
        }
        // Stale-snapshot guard: the quote said FREE but the ticket ledger reads
        // empty. On the pay-or-ticket contract this pair is contradictory — a
        // ticketless citizen quotes the flat fee, never free — so this only
        // fires on a mid-session race or against a chain running an older
        // contract (where a ticketless free rename reverts). Blocking beats
        // firing a tx whose cost differs from the confirmed one.
        if (free && !_freeChangeAvailable) {
          return none(Icons.confirmation_number_outlined, context.l10n.domainBtnNoFreeChange);
        }
        if (!free) {
          if (_quote == null || _balance == null) {
            return none(Icons.lock_clock_rounded, context.l10n.domainBtnChecking);
          }
          if (_balance! < cost) {
            return none(Icons.account_balance_wallet_outlined, context.l10n.domainBtnNotEnoughPos);
          }
        }
        return (
          kind: _DomainActionKind.claim,
          submittable: true,
          isFree: free,
          cost: cost,
          icon: free ? Icons.check_circle_outline_rounded : Icons.sell_outlined,
          label: free
              ? '${context.l10n.domainBtnClaim} "$_query"'
              : '${context.l10n.domainBtnClaim} "$_query" · ${_fmtPos(cost.toDouble() / 1e18)}',
        );
      default:
        return none(Icons.lock_clock_rounded, context.l10n.domainBtnChecking);
    }
  }

  // ── Footer: live RENEW / CLAIM, or a rule-aware disabled affordance ────────

  Widget _claimFooter(GlassTokens tokens) {
    final a = _resolveAction();
    final children = <Widget>[];

    if (_submitError != null) {
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          localizedError(context.l10n, _submitError),
          style: const TextStyle(fontSize: 11, color: Colors.redAccent),
        ),
      ));
    }

    if (_submitting) {
      children
          .add(_disabledAffordance(tokens, Icons.bolt_rounded, context.l10n.domainBtnSaving));
    } else if (a.submittable) {
      children.add(SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          // SystemAppActionButton's exact enabled frame.
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.glassFill,
            foregroundColor: tokens.starkWhite,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: tokens.borderMedium),
            ),
          ),
          onPressed: () => _onAction(a.kind, a.cost, a.isFree),
          icon: Icon(a.icon, size: 16),
          label: Text(
            a.label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ),
      ));
    } else {
      children.add(_disabledAffordance(tokens, a.icon, a.label));
    }

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  /// The dashed-disabled affordance — shared by the blocked /
  /// info states and the in-flight "saving" state.
  Widget _disabledAffordance(GlassTokens tokens, IconData icon, String label) {
    final dim = tokens.textDim.withValues(alpha: 0.55);
    return SizedBox(
      width: double.infinity,
      child: CustomPaint(
        painter: DashedRRectPainter(color: tokens.borderSubtle, radius: 10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: dim),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 12,
                  color: dim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAction(
      _DomainActionKind kind, BigInt cost, bool isFree) async {
    if (kind == _DomainActionKind.claim) {
      // Claiming a name renames your account to it — a meaningful, mostly
      // irreversible identity change (old name freed; a lapsed holder evicted).
      final ok = await _confirmClaim(cost, isFree);
      if (ok != true) return;
    }
    await _submit(kind);
  }

  Future<bool?> _confirmClaim(BigInt cost, bool isFree) {
    final tokens = GlassTokens.of(context);
    final evicting = _effectiveClaimStatus == 1;
    final body = StringBuffer()
      ..write(context.l10n.domainConfirmBecomes(_query))
      ..write(_ownName.isNotEmpty
          ? context.l10n.domainConfirmCurrentFreed(_ownName)
          : context.l10n.domainConfirmOldFreed);
    if (evicting) {
      body.write('\n\n${context.l10n.domainConfirmEvicts}');
    }
    final costLine = isFree
        ? context.l10n.domainConfirmFree
        : context.l10n.domainConfirmCost(_fmtPos(cost.toDouble() / 1e18));

    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: tokens.surfaceDeep,
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.domainConfirmTitle(_query),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.starkWhite,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body.toString(),
                style: TextStyle(
                    fontSize: 13, color: tokens.textDim, height: 1.45),
              ),
              const SizedBox(height: 10),
              Text(
                costLine,
                style: TextStyle(
                    fontSize: 12, color: tokens.starkWhite, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        context.l10n.domainBtnCancel,
                        style: TextStyle(
                          color: tokens.textDim,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.glassFill,
                        foregroundColor: tokens.starkWhite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: tokens.borderMedium),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        context.l10n.domainBtnClaimIt,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
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

  Future<void> _submit(_DomainActionKind kind) async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      if (kind == _DomainActionKind.renew) {
        final tx = await PublicOSTreasury.payDomain(_months);
        if (tx == null) {
          throw Exception(PublicOS.lastError ?? 'payDomain was not submitted');
        }
        final ok =
            await TxUtils.waitForReceipt(tx, label: 'payDomain($_months)');
        if (!ok) throw Exception('payDomain reverted on-chain');
      } else if (kind == _DomainActionKind.claim) {
        // setDisplayName wraps changeName(newName, months), waits for the
        // receipt, and write-throughs the new name to local storage + the DB.
        final ok =
            await PublicOSAccounts.setDisplayName(_query, months: _months);
        if (!ok) throw Exception(PublicOS.lastError ?? 'changeName failed');
      }
      if (!mounted) return;
      widget.onChanged?.call();
      // Back to the (now-updated) own-domain view + a full reload from chain.
      _searchCtrl.clear();
      setState(() {
        _submitting = false;
        _query = '';
        _validation = null;
        _searchedContact = null;
        _claimStatus = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(kind == _DomainActionKind.renew
              ? context.l10n.domainRenewed
              : context.l10n.domainClaimed),
        ),
      );
      if (widget.closeOnPaid) {
        Navigator.of(context).pop();
        return;
      }
      await _bootstrap();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = TxUtils.decodeRevertReason(e) ?? e.toString();
      });
    }
  }
}

// ── Shared bits ─────────────────────────────────────────────────────────────

/// A label/value row mirroring the BSP/SSP subscribe sheet (`_sheetKv`): a fixed
/// 110px label column + an expanded value.
Widget _kvRow(GlassTokens tokens, String label, String value,
    {Color? valueColor}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(fontSize: 12, color: valueColor ?? tokens.starkWhite),
        ),
      ),
    ],
  );
}

/// Months stepper mirroring the subscribe sheet (`_monthsRow` + `_Stepper`).
Widget _monthsRow(
  GlassTokens tokens,
  String label,
  int months,
  void Function(int delta) onChange, {
  bool enabled = true,
}) {
  return Row(
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
      ),
      _StepBtn(icon: Icons.remove, onTap: () => onChange(-1), enabled: enabled),
      SizedBox(
        width: 60,
        child: Center(
          child: Text(
            enabled ? '$months' : '—',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: enabled ? tokens.starkWhite : tokens.textDim,
            ),
          ),
        ),
      ),
      _StepBtn(icon: Icons.add, onTap: () => onChange(1), enabled: enabled),
    ],
  );
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _StepBtn({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.borderMedium),
            ),
            child: Icon(icon, color: tokens.starkWhite, size: 18),
          ),
        ),
      ),
    );
  }
}

/// The single account card — banner + contact icon + name, **no address** (the
/// store is about names, not wallets). Ephemeral: it just paints whatever
/// [contact] it's handed; nothing is persisted.
class _StoreCard extends StatelessWidget {
  final Contact? contact;
  final String name;

  /// While true, the pixel-rain (rainfall) loader shows in the card's top-right
  /// — the search is resolving this name on-chain.
  final bool searching;

  const _StoreCard({
    required this.contact,
    required this.name,
    this.searching = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final addr = contact?.publicosAddress?.eip55With0x ?? '';

    // Structure mirrors select_account_screen's account card verbatim:
    // ClipRRect(16) → BackdropFilter → Container(clipBehavior + glassBox) →
    // 88px banner Stack (banner/fallback + darkening gradient + avatar/name).
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: GlassTheme.glassBox(context),
          child: SizedBox(
            height: 88,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContactBanner(
                  contact: contact,
                  fallback: _fallback(tokens),
                ),
                DecoratedBox(
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
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GlassContactIcon(
                        contact: contact,
                        address: addr,
                        size: 60,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name.isEmpty ? '—' : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: tokens.starkWhite,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 6),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (searching)
                  const Positioned(
                    top: 12,
                    right: 14,
                    child: PixelRainLoadingWidget(
                      size: 26,
                      showShadows: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallback(GlassTokens tokens) {
    final c = contact?.iconColor ?? tokens.surfaceElevated;
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

// ── Formatting ───────────────────────────────────────────────────────────────

String _fmtDate(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

String _trimNum(double v) {
  final s = v.toStringAsFixed(2);
  if (s.endsWith('.00')) return s.substring(0, s.length - 3);
  if (s.endsWith('0')) return s.substring(0, s.length - 1);
  return s;
}

String _fmtPos(double v) => '${_trimNum(v)} OX';
