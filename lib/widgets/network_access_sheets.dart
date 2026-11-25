import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/server_rules_sheet.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Shared bottom sheets for the BSP/SSP subscription actions. Treasury
/// ("Services") is the only consumer — BSP/SSP pages are status-and-discovery
/// surfaces and host no pay/subscribe flow.
///
/// The model is "pay as served". BSP and SSP
/// are INDEPENDENT goods on two axes (0 = BSP, 1 = SSP) of ONE contract pair,
/// and a private pays for both from ONE service balance: the fee accrues by
/// the second to whoever is the provider that second, is drawn from the
/// balance only while that provider is past its min-subscriber gate, and is
/// paid out when anyone settles. A citizen's share is minted — no balance
/// needed. There are no prepaid months, no renewals, no citizen windows: a
/// switch is `subscribe` with a new slug, effective now and paid to the
/// second; `withdraw` returns what the providers have not earned.
///
/// Action surface (`PublicOSTreasury`, over `SubsManager`):
///   subscribe(axis, slug, topUp)  — join / switch / top-up   (_SubscribeSheet)
///   topUpBalance(amount)          — deposit only             (_TopUpSheet)
///   withdrawBalance(amount)       — take the rest back       (_WithdrawSheet)
///   leave(axis)                   — stop one service         (_LeaveSheet)
///
/// State preconditions are enforced by the contract — these sheets only run
/// when Treasury has computed the right state.
enum ProviderKind { bsp, ssp }

extension on ProviderKind {
  String get upper => this == ProviderKind.bsp ? 'BSP' : 'SSP';
}

class ProviderEntry {
  final String slug;
  final String title;
  final String apiUrl;
  final String region;
  final EthereumAddress owner;
  final BigInt? subscriberCount;
  final BigInt? gateThreshold;
  final bool? gatePaid;

  const ProviderEntry({
    required this.slug,
    required this.title,
    required this.apiUrl,
    required this.region,
    required this.owner,
    this.subscriberCount,
    this.gateThreshold,
    this.gatePaid,
  });
}

// ─── Public API ─────────────────────────────────────────────────────────────

/// Open the directory picker. Returns the selected slug, or null if canceled.
/// `excludeSlug` hides the user's currently subscribed slug (avoids "switch to
/// the same provider" confusion).
Future<String?> pickProvider(
  BuildContext context, {
  required ProviderKind kind,
  String? excludeSlug,
}) {
  return showGlassSheetDialog<String>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _PickerSheet(kind: kind, excludeSlug: excludeSlug),
  );
}

/// Confirm subscription to [slug]. For privates this pays `months` of the
/// service fee (self-pay from the main Safe); for citizens the network mints
/// the fee. A "switch" is just a subscribe to a different slug. Returns true on
/// success.
Future<bool> confirmSubscribe(
  BuildContext context, {
  required ProviderKind kind,
  required String slug,
  required bool isCitizen,
  required bool isSwitch,
}) async {
  final result = await showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _SubscribeSheet(
      kind: kind,
      slug: slug,
      isCitizen: isCitizen,
      isSwitch: isSwitch,
    ),
  );
  return result == true;
}

/// Top up the shared service balance (no provider change), by amount; the
/// sheet shows about how many months it covers at today's fees.
Future<bool> confirmTopUp(BuildContext context) async {
  final result = await showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => const _TopUpSheet(),
  );
  return result == true;
}

/// Withdraw an amount of the unspent service balance to the MainSafe (MAX =
/// balance − accrued, rounded down to 0.01 OX).
Future<bool> confirmWithdraw(BuildContext context) async {
  final result = await showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => const _WithdrawSheet(),
  );
  return result == true;
}

/// Pay down [account]'s penalties from the caller's MainSafe (burned). Lives
/// with the service-balance sheets because penalties are what block the
/// services (`servicesBlocked`). [owed] prefills the field.
Future<bool> confirmPayPenalties(
  BuildContext context, {
  required EthereumAddress account,
  required BigInt owed,
}) async {
  final result = await showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _PayPenaltiesSheet(account: account, owed: owed),
  );
  return result == true;
}

/// Leave the assigned provider on one axis — single tap, no inputs.
Future<bool> confirmLeave(
  BuildContext context, {
  required ProviderKind kind,
  required String slug,
}) async {
  final result = await showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _LeaveSheet(kind: kind, slug: slug),
  );
  return result == true;
}

// ─── Picker sheet ───────────────────────────────────────────────────────────

class _PickerSheet extends StatefulWidget {
  final ProviderKind kind;
  final String? excludeSlug;

  const _PickerSheet({required this.kind, this.excludeSlug});

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  static const int _pageSize = 30;

  bool _loading = true;
  String? _error;
  List<ProviderEntry> _entries = const [];
  final Map<String, Contact?> _ownerContacts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await fetchProviderDirectory(widget.kind, _pageSize);
      final filtered = widget.excludeSlug == null
          ? entries
          : entries.where((e) => e.slug != widget.excludeSlug).toList();
      if (!mounted) return;
      setState(() {
        _entries = filtered;
        _loading = false;
      });
      unawaited(_loadOwnerContacts());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadOwnerContacts() async {
    for (final entry in _entries) {
      final key = entry.owner.eip55With0x.toLowerCase();
      if (_ownerContacts.containsKey(key)) continue;
      Contact? contact;
      try {
        contact = await PublicOSContacts.getContact(entry.owner);
        if (contact == null && PublicOS.web3Connected) {
          contact = await PublicOSContacts.fetchContact(entry.owner, requireRecords: true);
          await PublicOSContacts.saveContact(contact);
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() => _ownerContacts[key] = contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final upper = widget.kind.upper;
    return _SheetShell(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.netPickHeader(upper),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: tokens.textDim,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.kind == ProviderKind.bsp
                  ? context.l10n.netPickBspTitle
                  : context.l10n.netPickSspTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: tokens.starkWhite,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.kind == ProviderKind.bsp
                  ? context.l10n.netPickBspBody
                  : context.l10n.netPickSspBody,
              style: TextStyle(
                fontSize: 12,
                color: tokens.textDim,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: PixelRainLoadingWidget(size: 40, showShadows: false)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  localizedError(context.l10n, _error),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.redAccent),
                ),
              )
            else if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    context.l10n.netNoProviders(upper),
                    style:
                        TextStyle(fontSize: 12, color: tokens.textDim),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final entry = _entries[i];
                    return _ProviderCard(
                      entry: entry,
                      ownerContact: _ownerContacts[
                          entry.owner.eip55With0x.toLowerCase()],
                      onTap: () => Navigator.of(context).pop(entry.slug),
                    );
                  },
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _sheetButton(
                context,
                label: context.l10n.actionCancel,
                filled: false,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscribe / switch sheet ───────────────────────────────────────────────

class _SubscribeSheet extends StatefulWidget {
  final ProviderKind kind;
  final String slug;
  final bool isCitizen;
  final bool isSwitch;

  const _SubscribeSheet({
    required this.kind,
    required this.slug,
    required this.isCitizen,
    required this.isSwitch,
  });

  @override
  State<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<_SubscribeSheet> {
  ProviderEntry? _entry;
  Contact? _ownerContact;
  bool _loadingDetails = true;

  // Privates only. A switch defaults to no deposit — the balance is already
  // there and simply keeps paying the new provider; a first join to one month.
  late int _months = widget.isSwitch ? 0 : 1;
  BigInt? _unitFee; // one period of this axis, at today's fee
  bool _loadingQuote = false;
  BigInt? _quoteTotal;
  BigInt? _balance;
  EthereumAddress? _payerSafe;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _loadProvider();
    if (!widget.isCitizen) {
      await _loadPaymentContext();
      await _refreshQuote();
    }
  }

  Future<void> _loadProvider() async {
    try {
      final entry = await fetchProvider(widget.kind, widget.slug);
      Contact? contact;
      if (entry != null) {
        try {
          contact = await PublicOSContacts.getContact(entry.owner);
          if (contact == null && PublicOS.web3Connected) {
            contact = await PublicOSContacts.fetchContact(entry.owner, requireRecords: true);
            await PublicOSContacts.saveContact(contact);
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _ownerContact = contact;
        _loadingDetails = false;
      });
    } catch (e) {
      _setSheetError(e);
    }
  }

  Future<void> _loadPaymentContext() async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) return;
    try {
      final mainHex =
          await PublicOSSafe.getMainSafeAddress(EthereumAddress.fromHex(me));
      if (mainHex == null) return;
      final addr = EthereumAddress.fromHex(mainHex);
      final balance = await PublicOSTreasury.getTokenBalance(addr);
      if (!mounted) return;
      setState(() {
        _payerSafe = addr;
        _balance = balance;
      });
    } catch (_) {}
  }

  Future<void> _refreshQuote() async {
    if (widget.isCitizen) return;
    setState(() => _loadingQuote = true);
    try {
      final axis = widget.kind == ProviderKind.bsp
          ? PublicOSTreasury.bspAxis
          : PublicOSTreasury.sspAxis;
      final unit = _unitFee ?? await PublicOSTreasury.quoteBalance(axis, 1);
      if (!mounted) return;
      setState(() {
        _unitFee = unit;
        _quoteTotal = unit * BigInt.from(_months);
        _loadingQuote = false;
      });
    } catch (e) {
      _setSheetError(e);
    }
  }

  void _changeMonths(int delta) {
    final next = _months + delta;
    if (next < 0 || next > 12) return;
    setState(() => _months = next);
    _refreshQuote();
  }

  /// True when the provider sits below its min-subscriber gate: the contract
  /// serves and draws **nothing** from the balance until the gate opens. The
  /// deposit still moves into the balance (it is the user's, withdrawable from
  /// Services), so it is shown as what it is — a deposit, not a charge.
  bool get _gateWaived => _entry?.gatePaid == false;

  /// What leaves the MainSafe: the deposit (months × fee); 0 for no months.
  BigInt? get _effectiveTotal => _quoteTotal;

  bool get _canSubmit {
    if (_submitting || _loadingDetails || _entry == null) return false;
    if (widget.isCitizen) return true;
    if (_loadingQuote || _effectiveTotal == null || _balance == null) {
      return false;
    }
    return _balance! >= _effectiveTotal!;
  }

  /// Localize a caught error (load / quote / submit) for the inline banner.
  /// Sync helper so the async catch sites stay context-safe.
  void _setSheetError(Object e) {
    if (!mounted) return;
    setState(() {
      _loadingDetails = false;
      _loadingQuote = false;
      _submitting = false;
      _error = localizedError(context.l10n, e);
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final creds = PublicOS.currentBlockchainPrivateKey;
    if (creds == null) {
      setState(() => _error = context.l10n.netNoSession);
      return;
    }
    // An SSP's rules come right before the transaction; subscribing IS the
    // acceptance. Closing the sheet stops here.
    final entry = _entry;
    if (widget.kind == ProviderKind.ssp && entry != null) {
      final go = await showServerRulesSheet(context,
          apiUrl: entry.apiUrl,
          serverName: entry.title.isNotEmpty ? entry.title : entry.slug);
      if (!go || !mounted) return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final slug = widget.slug;
      final upper = widget.kind.upper;
      // One verb for every account class: subscribe(axis, slug,
      // topUp). A switch is the same call with a new slug — effective now, the
      // old provider paid to the second, nothing stranded. A citizen deposits
      // nothing; a private deposits the months chosen (0 = join on the balance
      // already there).
      final axis = widget.kind == ProviderKind.bsp
          ? PublicOSTreasury.bspAxis
          : PublicOSTreasury.sspAxis;
      final topUp =
          widget.isCitizen ? BigInt.zero : (_quoteTotal ?? BigInt.zero);
      final label = '${widget.isSwitch ? 'switch' : 'subscribe'}$upper';
      final txHash =
          await PublicOSTreasury.subscribe(axis, slug, topUp: topUp);
      if (txHash == null) throw Exception('$label was not submitted');
      final ok = await TxUtils.waitForReceipt(txHash, label: label);
      if (!ok) {
        throw Exception('$label reverted on-chain');
      }
      // Subscription is live — try to swing the active endpoint to the new
      // provider. Idempotent; falls back silently if unreachable.
      await PublicOS.upgradeRpcPostAuth();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _setSheetError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final upper = widget.kind.upper;
    final entry = _entry;
    final headerLabel = widget.isSwitch
        ? l10n.netSwitchHeader(upper)
        : l10n.netSubscribeHeader(upper);
    final actionLabel = _submitting
        ? (widget.isSwitch ? l10n.netSwitching : l10n.netSubscribing)
        : (widget.isSwitch ? l10n.netSwitch : l10n.netSubscribe);

    return _SheetShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: tokens.textDim,
              ),
            ),
            const SizedBox(height: 8),
            if (_loadingDetails) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: PixelRainLoadingWidget(size: 40, showShadows: false)),
              ),
            ] else if (entry == null) ...[
              Text(
                l10n.netProviderNotFound,
                style:
                    TextStyle(fontSize: 18, color: tokens.fallbackAccent),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.netSlugUnresolved(widget.slug, upper),
                style: TextStyle(fontSize: 12, color: tokens.textDim),
              ),
            ] else ...[
              Text(
                entry.title.isNotEmpty ? entry.title : entry.slug,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: tokens.starkWhite,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.slug +
                    (entry.region.isNotEmpty ? '  ·  ${entry.region}' : ''),
                style: TextStyle(fontSize: 12, color: tokens.textDim),
              ),
              const SizedBox(height: 18),
              _sheetKv(
                context,
                widget.kind == ProviderKind.bsp ? 'RPC' : 'API',
                entry.apiUrl.isEmpty ? '—' : entry.apiUrl,
              ),
              const SizedBox(height: 8),
              _runByRow(context, entry.owner, _ownerContact),
              const SizedBox(height: 16),
              _explainerBox(context, widget: widget),
              if (!widget.isCitizen) ...[
                const SizedBox(height: 18),
                _monthsRow(context, _months, _changeMonths,
                    label: l10n.netDepositMonths),
                const SizedBox(height: 12),
                _sheetKv(
                  context,
                  l10n.netProviderFee(upper),
                  _loadingQuote ? '—' : _formatPos(_unitFee),
                ),
                const SizedBox(height: 6),
                _sheetKv(
                  context,
                  l10n.netDeposit,
                  _loadingQuote
                      ? l10n.netCalculating
                      : _formatPos(_effectiveTotal),
                ),
                if (_gateWaived && !_loadingQuote) ...[
                  const SizedBox(height: 10),
                  _noteBox(context, l10n.netGateWaived),
                ],
                const SizedBox(height: 12),
                _sheetKv(
                  context,
                  l10n.netBalance,
                  _balance == null ? '—' : _formatPos(_balance),
                ),
                const SizedBox(height: 6),
                _sheetKv(
                  context,
                  l10n.netFromWallet,
                  _payerSafe == null
                      ? '—'
                      : l10n.netMainWallet(
                          _truncateAddr(_payerSafe!.eip55With0x)),
                ),
                if (_balance != null &&
                    _effectiveTotal != null &&
                    _balance! < _effectiveTotal!) ...[
                  const SizedBox(height: 10),
                  _warningBox(context, l10n.netInsufficientPos),
                ],
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _sheetButton(
                    context,
                    label: l10n.actionCancel,
                    filled: false,
                    onTap: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _sheetButton(
                    context,
                    label: actionLabel,
                    filled: true,
                    chainAction: true,
                    onTap: _canSubmit ? _submit : null,
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

// ─── Top-up sheet (the shared service balance) ──────────────────────────────

/// Deposit into the one balance both providers draw from. By AMOUNT, not by
/// months (months are only a way to size the deposit);
/// the line under the field translates it back: about N months of the services
/// you are subscribed to, at today's fees. Below a provider's min-subscriber
/// gate nothing is drawn, and the sheet says so instead of promising months.
class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet();

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  final TextEditingController _amount = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  BigInt? _balance;
  EthereumAddress? _payerSafe;
  BigInt? _bspFee; // per period, only when subscribed on that axis
  BigInt? _sspFee;
  bool _anyPaid = false; // at least one subscribed provider is past its gate
  String? _error;

  static const List<int> _chips = [1, 2, 5, 10];

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() => _error = null));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) return;
    final a = EthereumAddress.fromHex(me);
    try {
      final mainHex = await PublicOSSafe.getMainSafeAddress(a);
      if (mainHex != null) {
        final safe = EthereumAddress.fromHex(mainHex);
        _payerSafe = safe;
        _balance = await PublicOSTreasury.getTokenBalance(safe);
      }
    } catch (_) {}
    try {
      for (final axis in [PublicOSTreasury.bspAxis, PublicOSTreasury.sspAxis]) {
        final slug = await PublicOSTreasury.assignedSlug(axis, a);
        if (slug.isEmpty) continue;
        final fee = await PublicOSTreasury.quoteBalance(axis, 1);
        if (axis == PublicOSTreasury.bspAxis) {
          _bspFee = fee;
        } else {
          _sspFee = fee;
        }
        if (await PublicOSTreasury.isProviderPaid(axis, slug)) _anyPaid = true;
      }
    } catch (e) {
      _error = mounted ? localizedError(context.l10n, e) : null;
    }
    if (mounted) setState(() => _loading = false);
  }

  BigInt? get _value => _parseOx(_amount.text);

  /// "Covers about N months …" — or why it can't say months.
  String? _coverage(AppLocalizations l) {
    final v = _value;
    if (v == null || v <= BigInt.zero) return null;
    final rate = (_bspFee ?? BigInt.zero) + (_sspFee ?? BigInt.zero);
    if (rate == BigInt.zero) return l.networkAccessSheetsCoversNone;
    final months = (v.toDouble() / rate.toDouble()).toStringAsFixed(1);
    final line = (_bspFee != null && _sspFee != null)
        ? l.networkAccessSheetsCoversBoth(months)
        : l.networkAccessSheetsCoversOne(months, _bspFee != null ? 'BSP' : 'SSP');
    return _anyPaid ? line : '$line ${l.networkAccessSheetsGateNote}';
  }

  bool get _canSubmit {
    final v = _value;
    return !_submitting &&
        !_loading &&
        v != null &&
        v > BigInt.zero &&
        _balance != null &&
        v <= _balance!;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (PublicOS.currentBlockchainPrivateKey == null) {
      setState(() => _error = context.l10n.netNoSession);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      const label = 'topUpBalance';
      final txHash = await PublicOSTreasury.topUpBalance(_value!);
      if (txHash == null) throw Exception('$label was not submitted');
      final ok = await TxUtils.waitForReceipt(txHash, label: label);
      if (!ok) throw Exception('$label reverted on-chain');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = localizedError(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final v = _value;
    final coverage = _coverage(l10n);
    return _SheetShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.networkAccessSheetsTopUpHeader, style: _eyebrow(tokens)),
            const SizedBox(height: 8),
            Text(l10n.networkAccessSheetsTopUpTitle, style: _title(tokens)),
            const SizedBox(height: 4),
            Text(
              l10n.networkAccessSheetsTopUpBody,
              style:
                  TextStyle(fontSize: 12, color: tokens.textDim, height: 1.45),
            ),
            const SizedBox(height: 18),
            _amountField(context, _amount, l10n.networkAccessSheetsAmount),
            const SizedBox(height: 10),
            _amountChips(
              context,
              [for (final n in _chips) ('$n OX', BigInt.from(n) * _oneOx)],
              (wei) => _amount.text = _oxText(wei),
            ),
            if (coverage != null) ...[
              const SizedBox(height: 12),
              _noteBox(context, coverage),
            ],
            const SizedBox(height: 14),
            _sheetKv(
              context,
              l10n.netBalance,
              _balance == null ? '—' : _formatPos(_balance),
            ),
            const SizedBox(height: 6),
            _sheetKv(
              context,
              l10n.netFromWallet,
              _payerSafe == null
                  ? '—'
                  : l10n.netMainWallet(_truncateAddr(_payerSafe!.eip55With0x)),
            ),
            if (_balance != null && v != null && v > _balance!) ...[
              const SizedBox(height: 10),
              _warningBox(context, l10n.netInsufficientPos),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 22),
            _sheetActions(
              context,
              cancelEnabled: !_submitting,
              label: _submitting
                  ? l10n.networkAccessSheetsDepositing
                  : l10n.networkAccessSheetsDeposit,
              onTap: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pay-penalties sheet (community standards) ──────────────────────────────

/// `PenaltiesManager.payPenalties(account, amount)`: the session key calls,
/// the caller's MainSafe is burned, oldest penalty first, partial allowed.
/// The contract takes at most what is owed, so a larger amount is harmless
/// (the note says so); the MainSafe must hold only what will be burned.
class _PayPenaltiesSheet extends StatefulWidget {
  final EthereumAddress account;
  final BigInt owed;

  const _PayPenaltiesSheet({required this.account, required this.owed});

  @override
  State<_PayPenaltiesSheet> createState() => _PayPenaltiesSheetState();
}

class _PayPenaltiesSheetState extends State<_PayPenaltiesSheet> {
  final TextEditingController _amount = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  BigInt? _balance;
  EthereumAddress? _payerSafe;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount.text = _oxText(widget.owed);
    _amount.addListener(() => setState(() => _error = null));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) return;
    try {
      final mainHex =
          await PublicOSSafe.getMainSafeAddress(EthereumAddress.fromHex(me));
      if (mainHex != null) {
        final safe = EthereumAddress.fromHex(mainHex);
        _payerSafe = safe;
        _balance = await PublicOSTreasury.getTokenBalance(safe);
      }
    } catch (e) {
      _error = mounted ? localizedError(context.l10n, e) : null;
    }
    if (mounted) setState(() => _loading = false);
  }

  BigInt? get _value => _parseOx(_amount.text);

  /// What the burn will be: the contract settles at most what is owed.
  BigInt? get _burn {
    final v = _value;
    if (v == null) return null;
    return v > widget.owed ? widget.owed : v;
  }

  bool get _canSubmit {
    final b = _burn;
    return !_submitting &&
        !_loading &&
        b != null &&
        b > BigInt.zero &&
        _balance != null &&
        b <= _balance!;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (PublicOS.currentBlockchainPrivateKey == null) {
      setState(() => _error = context.l10n.netNoSession);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok =
        await PublicOSCommunityStandards.payPenalties(widget.account, _value!);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = localizedError(context.l10n, PublicOS.lastError,
            fallback: context.l10n.penaltiesPayFailed);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final v = _value;
    return _SheetShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.payPenaltiesHeader, style: _eyebrow(tokens)),
            const SizedBox(height: 8),
            Text(l10n.payPenaltiesTitle, style: _title(tokens)),
            const SizedBox(height: 4),
            Text(
              l10n.payPenaltiesBody,
              style:
                  TextStyle(fontSize: 12, color: tokens.textDim, height: 1.45),
            ),
            const SizedBox(height: 18),
            _amountField(context, _amount, l10n.networkAccessSheetsAmount),
            const SizedBox(height: 10),
            _amountChips(
              context,
              [('${l10n.payPenaltiesAll} · ${_formatPos(widget.owed)}', widget.owed)],
              (wei) => _amount.text = _oxText(wei),
            ),
            if (v != null && v > widget.owed) ...[
              const SizedBox(height: 12),
              _noteBox(context, l10n.payPenaltiesAboveOwed),
            ],
            const SizedBox(height: 14),
            _sheetKv(context, l10n.payPenaltiesOwed, _formatPos(widget.owed)),
            const SizedBox(height: 6),
            _sheetKv(
              context,
              l10n.netBalance,
              _balance == null ? '—' : _formatPos(_balance),
            ),
            const SizedBox(height: 6),
            _sheetKv(
              context,
              l10n.netFromWallet,
              _payerSafe == null
                  ? '—'
                  : l10n.netMainWallet(_truncateAddr(_payerSafe!.eip55With0x)),
            ),
            if (_balance != null && _burn != null && _burn! > _balance!) ...[
              const SizedBox(height: 10),
              _warningBox(context, l10n.netInsufficientPos),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style:
                    const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 22),
            _sheetActions(
              context,
              cancelEnabled: !_submitting,
              label: _submitting
                  ? l10n.payPenaltiesPaying
                  : l10n.payPenaltiesPay,
              onTap: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Withdraw sheet (the shared service balance) ────────────────────────────

/// Take an AMOUNT of the unspent balance back to the MainSafe (the contract
/// takes any amount). `withdraw`
/// settles first, so the ceiling is balance − accrued, rounded DOWN to
/// 0.01 OX: the accrual keeps ticking between the read and the receipt, and
/// one wei above what is left reverts. MAX fills that ceiling.
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final TextEditingController _amount = TextEditingController();
  bool _loading = true;
  bool _submitting = false;
  BigInt? _balance;
  BigInt? _accrued;
  BigInt? _held; // the part someone else added for this account, still unspent; null when nothing was ever added
  BigInt? _available;
  String? _error;

  static final BigInt _cent = BigInt.from(10).pow(16); // 0.01 OX

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() => _error = null));
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final me = PublicOS.myPublicosAddress;
    if (me == null) return;
    try {
      final a = EthereumAddress.fromHex(me);
      final acct = await PublicOSTreasury.getSubsAccount(a);
      final due = await PublicOSTreasury.previewSettle(a);
      final accrued = due.minted ? BigInt.zero : due.toBsp + due.toSsp;
      // The contract decides what can leave: balance − accrued, minus the
      // part someone else added for this account (providers spend that
      // part first; withdraw never returns it). `held` is what it keeps back.
      var avail = await PublicOSTreasury.withdrawable(a);
      var held = acct.balance - accrued - avail;
      if (held < BigInt.zero) held = BigInt.zero;
      avail = avail - (avail % _cent);
      if (!mounted) return;
      setState(() {
        _balance = acct.balance;
        _accrued = accrued;
        _held = acct.sponsored > BigInt.zero ? held : null;
        _available = avail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = localizedError(context.l10n, e);
      });
    }
  }

  BigInt? get _value => _parseOx(_amount.text);

  bool get _tooMuch {
    final v = _value;
    return v != null && _available != null && v > _available!;
  }

  bool get _canSubmit {
    final v = _value;
    return !_submitting && !_loading && v != null && v > BigInt.zero && !_tooMuch;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    if (PublicOS.currentBlockchainPrivateKey == null) {
      setState(() => _error = context.l10n.netNoSession);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      const label = 'withdrawBalance';
      final txHash = await PublicOSTreasury.withdrawBalance(_value!);
      if (txHash == null) throw Exception('$label was not submitted');
      final ok = await TxUtils.waitForReceipt(txHash, label: label);
      if (!ok) throw Exception('$label reverted on-chain');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = localizedError(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final nothing = !_loading && (_available ?? BigInt.zero) == BigInt.zero;
    return _SheetShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.networkAccessSheetsWithdrawHeader,
                style: _eyebrow(tokens)),
            const SizedBox(height: 8),
            Text(l10n.networkAccessSheetsWithdrawTitle, style: _title(tokens)),
            const SizedBox(height: 4),
            Text(
              l10n.networkAccessSheetsWithdrawBody,
              style:
                  TextStyle(fontSize: 12, color: tokens.textDim, height: 1.45),
            ),
            const SizedBox(height: 18),
            _sheetKv(context, l10n.netBalance,
                _loading ? '—' : _formatPos(_balance)),
            const SizedBox(height: 6),
            _sheetKv(context, l10n.networkAccessSheetsAccrued,
                _loading ? '—' : _formatPos(_accrued)),
            if (_held != null) ...[
              const SizedBox(height: 6),
              _sheetKv(context, l10n.networkAccessSheetsAddedForYou,
                  _formatPos(_held)),
            ],
            const SizedBox(height: 6),
            _sheetKv(context, l10n.networkAccessSheetsAvailable,
                _loading ? l10n.netCalculating : _formatPos(_available)),
            if (_held != null && _held! > BigInt.zero) ...[
              const SizedBox(height: 10),
              _noteBox(context, l10n.networkAccessSheetsAddedForYouNote),
            ],
            if (nothing) ...[
              const SizedBox(height: 10),
              _noteBox(context, l10n.networkAccessSheetsNothingToWithdraw),
            ] else ...[
              const SizedBox(height: 16),
              _amountField(context, _amount, l10n.networkAccessSheetsAmount),
              const SizedBox(height: 10),
              _amountChips(
                context,
                [
                  if (_available != null && _available! > BigInt.zero)
                    (l10n.networkAccessSheetsMax, _available!),
                ],
                (wei) => _amount.text = _oxText(wei),
              ),
              if (_tooMuch) ...[
                const SizedBox(height: 10),
                _warningBox(context, l10n.networkAccessSheetsAmountTooHigh),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 11, color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 22),
            _sheetActions(
              context,
              cancelEnabled: !_submitting,
              label: _submitting
                  ? l10n.networkAccessSheetsWithdrawing
                  : l10n.networkAccessSheetsWithdraw,
              onTap: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Amount input (top-up · withdraw) ───────────────────────────────────────

final BigInt _oneOx = BigInt.from(10).pow(18);

/// "2.5" → 2.5 OX in wei. Null for empty, malformed, or more than 18 decimals.
BigInt? _parseOx(String raw) {
  final t = raw.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final m = RegExp(r'^(\d*)(?:\.(\d{0,18}))?$').firstMatch(t);
  if (m == null) return null;
  final whole = m.group(1)!.isEmpty ? '0' : m.group(1)!;
  final frac = (m.group(2) ?? '').padRight(18, '0');
  return BigInt.parse(whole) * _oneOx + BigInt.parse(frac.isEmpty ? '0' : frac);
}

/// Wei → the plain decimal a person would type ("2", "0.45").
String _oxText(BigInt wei) {
  final whole = wei ~/ _oneOx;
  var frac = (wei % _oneOx).toString().padLeft(18, '0').replaceAll(RegExp(r'0+$'), '');
  return frac.isEmpty ? '$whole' : '$whole.$frac';
}

Widget _amountField(
    BuildContext context, TextEditingController controller, String label) {
  final tokens = GlassTokens.of(context);
  return TextField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w700, color: tokens.starkWhite),
    decoration: InputDecoration(
      labelText: label,
      suffixText: 'OX',
      filled: true,
      fillColor: tokens.glassFillHover,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: tokens.starkWhite),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

Widget _amountChips(BuildContext context, List<(String, BigInt)> chips,
    void Function(BigInt wei) onPick) {
  final tokens = GlassTokens.of(context);
  if (chips.isEmpty) return const SizedBox.shrink();
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (label, wei) in chips)
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onPick(wei),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: tokens.starkWhite,
              ),
            ),
          ),
        ),
    ],
  );
}

// ─── Leave sheet (one axis) ─────────────────────────────────────────────────

/// Stop one service now. `leave(axis)` settles to the second first, so the
/// provider is paid for exactly what it served; the balance is untouched.
class _LeaveSheet extends StatefulWidget {
  final ProviderKind kind;
  final String slug;

  const _LeaveSheet({required this.kind, required this.slug});

  @override
  State<_LeaveSheet> createState() => _LeaveSheetState();
}

class _LeaveSheetState extends State<_LeaveSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (PublicOS.currentBlockchainPrivateKey == null) {
      setState(() => _error = context.l10n.netNoSession);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final axis = widget.kind == ProviderKind.bsp
          ? PublicOSTreasury.bspAxis
          : PublicOSTreasury.sspAxis;
      final label = 'leave${widget.kind.upper}';
      final txHash = await PublicOSTreasury.leave(axis);
      if (txHash == null) throw Exception('$label was not submitted');
      final ok = await TxUtils.waitForReceipt(txHash, label: label);
      if (!ok) throw Exception('$label reverted on-chain');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = localizedError(context.l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final upper = widget.kind.upper;
    return _SheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.networkAccessSheetsLeaveHeader(upper),
              style: _eyebrow(tokens)),
          const SizedBox(height: 8),
          Text(l10n.networkAccessSheetsLeaveTitle(widget.slug),
              style: _title(tokens)),
          const SizedBox(height: 4),
          Text(
            l10n.networkAccessSheetsLeaveBody,
            style: TextStyle(fontSize: 12, color: tokens.textDim, height: 1.45),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(fontSize: 11, color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 22),
          _sheetActions(
            context,
            cancelEnabled: !_submitting,
            label: _submitting
                ? l10n.networkAccessSheetsLeaving
                : l10n.networkAccessSheetsLeave,
            onTap: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ─── Provider card (used inside picker) ─────────────────────────────────────

class _ProviderCard extends StatelessWidget {
  final ProviderEntry entry;
  final Contact? ownerContact;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.entry,
    required this.ownerContact,
    required this.onTap,
  });

  String _truncateAddr(String addr) {
    if (addr.length <= 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  String _truncateUrl(String url) {
    if (url.length <= 38) return url;
    return '${url.substring(0, 35)}...';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title.isNotEmpty ? entry.title : entry.slug,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: tokens.starkWhite,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.slug +
                    (entry.region.isNotEmpty ? '  ·  ${entry.region}' : ''),
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.textDim,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _kvRow(tokens, context.l10n.netCardUrl,
                  _truncateUrl(entry.apiUrl.isEmpty ? '—' : entry.apiUrl)),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      context.l10n.netCardRunBy,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: tokens.textDim,
                      ),
                    ),
                  ),
                  GlassContactIcon(
                    contact: ownerContact,
                    address: entry.owner.eip55With0x,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      ownerContact?.publicosDisplayName ??
                          ownerContact?.displayName ??
                          _truncateAddr(entry.owner.eip55With0x),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.starkWhite,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (_subsLine(context.l10n) != null) ...[
                const SizedBox(height: 8),
                _kvRow(tokens, context.l10n.netCardSubs,
                    _subsLine(context.l10n)!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _subsLine(AppLocalizations l) {
    // Picker context: a user choosing/switching a provider only cares how many
    // others use it — the min-subscriber gate ("/15 · earning") is a provider
    // concern, shown on the BSP/SSP dashboards (bsp_screen / ssp_screen), not
    // here.
    final count = entry.subscriberCount;
    if (count == null) return null;
    final n = count.toInt();
    return l.netSubsCount(n);
  }

  Widget _kvRow(GlassTokens tokens, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: tokens.textDim,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: tokens.starkWhite,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Loaders (registry → ProviderEntry) ─────────────────────────────────────

/// Providers an unattended flow is willing to pair someone with — today the
/// onboarding tour's *set this up for me*.
///
/// Slugs, not addresses: a slug is registered under the same name on every
/// chain deployment, an address is not. This is an **auto-only** filter —
/// manual still
/// lists the whole directory, so a stranger who registers a provider tomorrow
/// can be chosen deliberately but will never be handed to someone by a button
/// that says "set this up for me".
///
/// Lives here, not in the onboarding flow, so BOTH clients carry it: this file
/// is mirrored byte for byte between publicos_client and publicos_desktop.
const Set<String> kAutoProviderSlugs = {
  'publicos',
  'publicos-de',
  'publicos-mx',
};

/// Which allow-listed provider an unattended flow picks.
///
/// Region-match on [country] (the device locale's country code, often null —
/// hence the fallback to the whole pool rather than a failure), then the
/// **LOWEST** subscriber count: spread new accounts across our own nodes.
///
/// Lowest, not highest: sorting highest first would concentrate accounts to
/// get one provider over its `minSubscribers` gate, an argument about
/// third-party providers competing for
/// a fee floor. The auto pool is our own three slugs, so the gate is not what
/// the pick should optimise; balancing load across the three regions is. If
/// non-allow-listed providers ever enter the auto pool, revisit — the
/// concentrate rule is right for them.
ProviderEntry? resolveAutoProvider(List<ProviderEntry> dir, String? country) {
  final pool = dir.where((e) => kAutoProviderSlugs.contains(e.slug)).toList();
  if (pool.isEmpty) return null;
  final local = pool.where((e) => e.region == country).toList();
  final from = local.isNotEmpty ? local : pool;
  from.sort((a, b) => (a.subscriberCount ?? BigInt.zero)
      .compareTo(b.subscriberCount ?? BigInt.zero));
  return from.first;
}

/// Enumerate the registered providers on one axis, newest page first.
///
/// **Public because the onboarding tour resolves its own provider** rather than
/// opening the picker sheet: S6's "set this up for me" needs the same directory
/// this sheet lists, and a second copy of the walk would be a second thing to
/// keep in step with the registry.
Future<List<ProviderEntry>> fetchProviderDirectory(
    ProviderKind kind, int limit) async {
  if (kind == ProviderKind.bsp) {
    final mem = PublicOSBsp.bspRegistryMemoryContract;
    final slugs = await mem
        .getBSPSlugs((offset: BigInt.zero, limit: BigInt.from(limit)));
    final entries = <ProviderEntry>[];
    for (final slug in slugs) {
      final entry = await fetchProvider(kind, slug);
      if (entry != null) entries.add(entry);
    }
    return entries;
  } else {
    final mem = PublicOSBsp.socialServerRegistryMemoryContract;
    final slugs = await mem.getSocialServerSlugs(
        (offset: BigInt.zero, limit: BigInt.from(limit)));
    final entries = <ProviderEntry>[];
    for (final slug in slugs) {
      final entry = await fetchProvider(kind, slug);
      if (entry != null) entries.add(entry);
    }
    return entries;
  }
}

/// One provider by slug, with its min-subscriber gate status attached.
/// Returns null when the slug does not resolve; never throws.
Future<ProviderEntry?> fetchProvider(
    ProviderKind kind, String slug) async {
  try {
    if (kind == ProviderKind.bsp) {
      final data = await PublicOSBsp.bspRegistryMemoryContract
          .getBSPBySlug((slug: slug));
      if (data == null) return null;
      final exists = data[0] as bool;
      if (!exists) return null;
      BigInt? subs;
      BigInt? threshold;
      bool? paid;
      try {
        final gate = await PublicOSTreasury.getBspGateStatus(slug);
        subs = gate.count;
        threshold = gate.threshold;
        paid = gate.paid;
      } catch (_) {}
      return ProviderEntry(
        slug: data[1] as String,
        title: data[2] as String,
        apiUrl: data[3] as String,
        region: data[4] as String,
        owner: data[5] as EthereumAddress,
        subscriberCount: subs,
        gateThreshold: threshold,
        gatePaid: paid,
      );
    } else {
      final data = await PublicOSBsp.socialServerRegistryMemoryContract
          .getSocialServerBySlug((slug: slug));
      if (data == null) return null;
      final exists = data[0] as bool;
      if (!exists) return null;
      BigInt? subs;
      BigInt? threshold;
      bool? paid;
      try {
        final gate = await PublicOSTreasury.getSspGateStatus(slug);
        subs = gate.count;
        threshold = gate.threshold;
        paid = gate.paid;
      } catch (_) {}
      return ProviderEntry(
        slug: data[1] as String,
        title: data[2] as String,
        apiUrl: data[3] as String,
        region: data[4] as String,
        owner: data[5] as EthereumAddress,
        subscriberCount: subs,
        gateThreshold: threshold,
        gatePaid: paid,
      );
    }
  } catch (_) {
    return null;
  }
}

// ─── Shared sheet primitives ────────────────────────────────────────────────

class _SheetShell extends StatelessWidget {
  final Widget child;

  const _SheetShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            // Borderless footer: the tone step to `surfaceDeep` at 92% is the
            // separation.
            color: tokens.surfaceDeep.withValues(alpha: 0.92),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ChainActionBadge extends StatelessWidget {
  const _ChainActionBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.connectedAccent,
      ),
    );
  }
}

Widget _sheetKv(BuildContext context, String label, String value) {
  final tokens = GlassTokens.of(context);
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
          style: TextStyle(fontSize: 12, color: tokens.starkWhite),
        ),
      ),
    ],
  );
}

Widget _sheetButton(
  BuildContext context, {
  required String label,
  required bool filled,
  required VoidCallback? onTap,
  bool chainAction = false,
}) {
  final tokens = GlassTokens.of(context);
  final labelText = Text(
    label,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
    ),
  );
  final child = chainAction
      ? Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _ChainActionBadge(),
            const SizedBox(width: 10),
            labelText,
          ],
        )
      : labelText;
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          filled ? tokens.starkWhite : Colors.white.withValues(alpha: 0.06),
      foregroundColor: filled ? tokens.background : tokens.starkWhite,
      disabledBackgroundColor: Colors.white.withValues(alpha: 0.03),
      disabledForegroundColor: tokens.textDim,
      padding: const EdgeInsets.symmetric(vertical: 14),
      // Fill, not ring, is what separates the primary from the quiet action —
      // same pair as the Connected-keys sheet's Save/Cancel.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide.none,
      ),
    ),
    onPressed: onTap,
    child: child,
  );
}

Widget _runByRow(
    BuildContext context, EthereumAddress owner, Contact? ownerContact) {
  final tokens = GlassTokens.of(context);
  final name = ownerContact?.publicosDisplayName ??
      ownerContact?.displayName ??
      owner.eip55With0x;
  return Row(
    children: [
      SizedBox(
        width: 110,
        child: Text(
          context.l10n.netRunBy,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
      ),
      GlassContactIcon(
        opensProfile: true,
        contact: ownerContact,
        address: owner.eip55With0x,
        size: 22,
      ),
      const SizedBox(width: 8),
      Flexible(
        child: ContactProfileTap(contact: ownerContact, address: owner.eip55With0x, child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: tokens.starkWhite),
        )),
      ),
    ],
  );
}

Widget _explainerBox(
  BuildContext context, {
  required _SubscribeSheet widget,
}) {
  final tokens = GlassTokens.of(context);
  final l = context.l10n;
  late final String text;
  final upper = widget.kind.upper;
  if (widget.isCitizen) {
    text = widget.isSwitch
        ? l.netExplainCitizenSwitch(upper)
        : l.netExplainCitizenSubscribe(upper);
  } else {
    text = widget.isSwitch
        ? l.netExplainPrivateSwitch(upper)
        : l.netExplainPrivateSubscribe(upper);
  }
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: tokens.textDim, height: 1.5),
    ),
  );
}

Widget _monthsRow(
  BuildContext context,
  int months,
  void Function(int delta) onChange, {
  String? label,
}) {
  final tokens = GlassTokens.of(context);
  return Row(
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label ?? context.l10n.netMonths,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
      ),
      _Stepper(icon: Icons.remove, onTap: () => onChange(-1)),
      SizedBox(
        width: 60,
        child: Center(
          child: Text(
            '$months',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tokens.starkWhite,
            ),
          ),
        ),
      ),
      _Stepper(icon: Icons.add, onTap: () => onChange(1)),
    ],
  );
}

class _Stepper extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _Stepper({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: tokens.starkWhite, size: 18),
        ),
      ),
    );
  }
}

/// Neutral counterpart of [_warningBox] — for a fact that is good news (a
/// waived charge), where orange would read as a problem.
Widget _noteBox(BuildContext context, String text) {
  final tokens = GlassTokens.of(context);
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: tokens.connectedAccent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: tokens.connectedAccent),
    ),
  );
}

Widget _warningBox(BuildContext context, String text) {
  return Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
    ),
  );
}

String _formatPos(BigInt? wei) {
  if (wei == null) return '—';
  final t = wei.toDouble() / 1e18;
  return '${t.toStringAsFixed(2)} OX';
}

String _truncateAddr(String addr) {
  if (addr.length <= 12) return addr;
  return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
}

// ─── Shared styles + the cancel/confirm row for the sheets ──────────────────

TextStyle _eyebrow(GlassTokens tokens) => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      color: tokens.textDim,
    );

TextStyle _title(GlassTokens tokens) => TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: tokens.starkWhite,
      letterSpacing: 0.5,
    );

Widget _sheetActions(
  BuildContext context, {
  required bool cancelEnabled,
  required String label,
  required VoidCallback? onTap,
}) {
  return Row(
    children: [
      Expanded(
        child: _sheetButton(
          context,
          label: context.l10n.actionCancel,
          filled: false,
          onTap: cancelEnabled ? () => Navigator.of(context).pop() : null,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: _sheetButton(
          context,
          label: label,
          filled: true,
          chainAction: true,
          onTap: onTap,
        ),
      ),
    ],
  );
}
