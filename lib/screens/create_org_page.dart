import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/revert_reason_l10n.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Full-screen page for creating a new PublicOS organization. Replaces the
/// phigital `CreatePublicOSOrgSheet` bottom sheet.
///
/// Flow: page 1 picks members from the stored-contacts list (PublicOS
/// accounts only, with a public-org toggle that narrows to citizens);
/// page 2 captures name + voting threshold. Create calls
/// `PublicOSGovernance.createOrg(...)`, which waits for the tx receipt and
/// returns the new org's address.
///
/// This page is a pure imperative route — it owns no router knowledge. On
/// success it `Navigator.pop`s with the new org's on-chain address; if the
/// user dismisses it (close button, system back) it pops `null`. The
/// caller (which lives on a go_router page) decides where to go next.
///
/// While the create tx is in flight the page is a non-dismissable
/// blocking screen — the org create is a single on-chain tx that the user
/// must not interrupt mid-flight.
class CreateOrgPage extends StatefulWidget {
  const CreateOrgPage({super.key});

  @override
  State<CreateOrgPage> createState() => _CreateOrgPageState();
}

class _CreateOrgPageState extends State<CreateOrgPage> {
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  List<Contact> _availableContacts = [];
  final List<Contact> _selectedContacts = [];

  bool _isLoadingContacts = true;
  bool _isCreating = false;
  int _currentPage = 0;
  int _threshold = 1;

  bool _isPublic = false;

  // Citizenship of the creator + selected members, resolved when the user
  // taps Next (page 1 → page 2). Reads the locally-cached `Contact.isCitizen`
  // (enriched on profile visit) and only hits the chain for members whose
  // cache is still null — so it's a handful of calls at most, not a scan of
  // every contact. Keyed by lowercase eip55 address. Absent = unknown.
  Map<String, bool> _citizenship = {};
  bool _checkingMembers = false;

  // Live org-name validation, mirroring new_account_dialog. Tier limits are
  // read once from chain (governance-set, rarely change) with safe
  // fallbacks; the name floor depends on public-vs-private.
  NameTierLimits? _tierLimits;
  NameValidationResult? _nameValidation;

  // Org-creation rate-limit state for the current account, read once on open.
  // `createOrg` blocks a creator for a tier-split cooldown after their last
  // org; surfacing it here means the wait is visible *before* the user fills
  // the form, not just as a post-submit revert. Null until loaded / on error.
  OrgCreationCooldown? _orgCooldown;

  int get _nameMinLength => _isPublic
      ? (_tierLimits?.minPublicOrg ?? 4)
      : (_tierLimits?.minPrivate ?? 8);
  int get _nameMaxLength => _tierLimits?.maxChars ?? 32;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadTierLimits();
    _loadOrgCooldown();
    _searchController.addListener(() => setState(() {}));
    _pageController.addListener(_onPageChanged);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (_currentPage != page) {
      setState(() => _currentPage = page);
    }
  }

  // ---- name validation ------------------------------------------------------

  Future<void> _loadTierLimits() async {
    try {
      final limits = await PublicOSAccounts.getNameTierLimits();
      if (!mounted) return;
      setState(() => _tierLimits = limits);
      _onNameChanged(); // re-validate against the live limits
    } catch (_) {
      // Fallbacks in the getters apply — non-fatal.
    }
  }

  /// Read the current account's org-creation cooldown so page 1 can warn the
  /// user up front if they're still rate-limited. Non-fatal on error — the
  /// banner just won't show, and createOrg's pre-flight still catches it.
  Future<void> _loadOrgCooldown() async {
    final myAddr = AppStateNotifier.currentMyContact?.publicosAddress;
    if (myAddr == null) return;
    try {
      final cooldown = await PublicOSAccounts.getOrgCreationCooldown(myAddr);
      if (!mounted) return;
      setState(() => _orgCooldown = cooldown);
    } catch (_) {
      // Non-fatal — leave the banner hidden.
    }
  }

  void _onNameChanged() {
    setState(() {
      _nameValidation = DisplayNameValidator.validate(
        _nameController.text.trim(),
        minLength: _nameMinLength,
        maxLength: _nameMaxLength,
      );
    });
  }

  // ---- loading + filtering --------------------------------------------------

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoadingContacts = true);
    try {
      final stored = await PublicOSContacts.getStoredContacts();
      final myAddr =
          AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;

      final filtered = stored.where((c) {
        final addr = c.publicosAddress?.eip55With0x;
        if (addr == null ||
            addr == '0x0000000000000000000000000000000000000000') {
          return false;
        }
        if (myAddr != null && addr == myAddr) return false;
        if (c.isOrgAccount) return false;
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _availableContacts = filtered;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _availableContacts = [];
          _isLoadingContacts = false;
        });
      }
    }
  }

  List<Contact> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();
    // Grid shows every PublicOS contact regardless of the public/private
    // toggle — citizenship is checked on the picked members at Next time,
    // not by filtering (or scanning) the whole list up front.
    final pool =
        _availableContacts.where((c) => !_selectedContacts.contains(c));

    if (query.isEmpty) return pool.toList();
    return pool.where((c) {
      return c.displayName.toLowerCase().contains(query) ||
          c.publicosDisplayName?.toLowerCase().contains(query) == true ||
          c.publicosAddress?.eip55With0x.toLowerCase().contains(query) ==
              true;
    }).toList();
  }

  /// Resolve citizenship for the creator + selected members. Reads the
  /// locally-cached `Contact.isCitizen` first; only members whose cache is
  /// still null hit the chain, in parallel. Populates [_citizenship].
  Future<void> _checkSelectedCitizenship() async {
    setState(() => _checkingMembers = true);
    final result = <String, bool>{};
    final creator = AppStateNotifier.currentMyContact;
    final toCheck = <Contact>[
      if (creator != null) creator,
      ..._selectedContacts,
    ];

    final needChain = <EthereumAddress>[];
    for (final c in toCheck) {
      final addr = c.publicosAddress;
      if (addr == null) continue;
      final key = addr.eip55With0x.toLowerCase();
      if (c.isCitizen != null) {
        result[key] = c.isCitizen!;
      } else {
        needChain.add(addr);
      }
    }

    if (needChain.isNotEmpty) {
      final checks = await Future.wait(
        needChain.map((a) async {
          try {
            return MapEntry(
                a.eip55With0x.toLowerCase(), await PublicOSAccounts.isCitizen(a));
          } catch (_) {
            return null; // unknown — leave absent, treated as non-citizen
          }
        }),
      );
      for (final e in checks) {
        if (e != null) result[e.key] = e.value;
      }
    }

    if (mounted) {
      setState(() {
        _citizenship = result;
        _checkingMembers = false;
      });
    }
  }

  void _onPublicToggled(bool value) {
    // Cheap now — no contact scan, no member pruning. Non-citizen picks are
    // flagged on page 2 and skipped at create time. Only the name floor
    // changes by tier (public 4+, private 8+), so just re-validate.
    setState(() => _isPublic = value);
    _onNameChanged();
  }

  // ---- selection mechanics --------------------------------------------------

  void _toggleContact(Contact contact) {
    setState(() {
      if (_selectedContacts.contains(contact)) {
        _selectedContacts.remove(contact);
      } else {
        _selectedContacts.add(contact);
      }
      _clampThreshold();
    });
  }

  void _clampThreshold() {
    final maxThreshold = _selectedContacts.length + 1;
    if (_threshold > maxThreshold) _threshold = maxThreshold;
    if (_threshold < 1) _threshold = 1;
  }

  // ---- create ---------------------------------------------------------------

  Future<void> _createOrg() async {
    final name = _nameController.text.trim();
    if (_nameValidation?.ok != true) {
      _snack('Fix the organization name first');
      return;
    }
    if (_selectedContacts.isEmpty) {
      _snack('Select at least one member');
      return;
    }

    final myAddress = AppStateNotifier.currentMyContact?.publicosAddress;
    if (myAddress == null) {
      _snack('Your account address is unavailable — try again');
      return;
    }

    setState(() => _isCreating = true);
    try {
      // For a public org, silently skip members who aren't citizens — they
      // were already flagged on page 2. The creator is always included;
      // a non-citizen creator is caught by createOrg's pre-flight.
      final initialMembers = <EthereumAddress>[myAddress];
      for (final contact in _selectedContacts) {
        final addr = contact.publicosAddress;
        if (addr == null) continue;
        if (_isPublic &&
            _citizenship[addr.eip55With0x.toLowerCase()] != true) {
          continue;
        }
        initialMembers.add(addr);
      }
      // Skipping members can drop the count below the chosen threshold —
      // clamp so the contract's `threshold <= memberCount` rule holds.
      final effectiveThreshold = _threshold > initialMembers.length
          ? initialMembers.length
          : _threshold;

      // createOrg waits for the tx receipt and returns the new org's
      // on-chain address (decoded from the OrgCreated event).
      final orgAddress = await PublicOSGovernance.createOrg(
        displayName: name,
        initialMembers: initialMembers,
        initialThreshold: effectiveThreshold,
        isPublic: _isPublic,
      );

      if (!mounted) return;
      if (orgAddress != null) {
        // Hand the new org's address back to the caller and close. The
        // caller opens the profile via the router — this page never
        // touches go_router itself.
        Navigator.of(context).pop(orgAddress.eip55With0x);
      } else {
        setState(() => _isCreating = false);
        // createOrg decodes the contract revert into PublicOS.lastError;
        // humanize it so the user sees a real reason, not a -32000 code.
        _snack(localizedRevertReason(
          context.l10n,
          PublicOS.lastError,
          fallback: context.l10n.revertCreateOrgFailed,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      _snack('Error creating organization: $e');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---- navigation helpers ---------------------------------------------------

  Future<void> _goToNextPage() async {
    // Resolve member citizenship before showing page 2 so the per-member
    // badges are accurate the moment the page appears.
    await _checkSelectedCitizenship();
    if (!mounted) return;
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  bool _handleBack() {
    if (_currentPage == 1) {
      _goToPreviousPage();
      return false;
    }
    return true;
  }

  // ---- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return PopScope(
      // Fully blocked while the create tx is in flight.
      canPop: _currentPage == 0 && !_isCreating,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isCreating) _goToPreviousPage();
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _isCreating
              ? null
              : IconButton(
                  icon: Icon(
                    _currentPage == 0
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    color: tokens.starkWhite,
                  ),
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    if (_handleBack()) navigator.pop();
                  },
                ),
          title: Text(
            _currentPage == 0 ? 'Add members' : 'Organization details',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: tokens.background,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _MembersPage(
                        tokens: tokens,
                        searchController: _searchController,
                        isLoadingContacts: _isLoadingContacts,
                        isPublic: _isPublic,
                        selectedContacts: _selectedContacts,
                        filteredContacts: _filteredContacts,
                        onToggleContact: _toggleContact,
                        onPublicToggled: _onPublicToggled,
                        orgCooldown: _orgCooldown,
                      ),
                      _DetailsPage(
                        tokens: tokens,
                        nameController: _nameController,
                        isPublic: _isPublic,
                        threshold: _threshold,
                        selectedContacts: _selectedContacts,
                        onThresholdChanged: (v) =>
                            setState(() => _threshold = v),
                        nameValidation: _nameValidation,
                        nameMinLength: _nameMinLength,
                        nameMaxLength: _nameMaxLength,
                        citizenship: _citizenship,
                        onRemoveMember: _toggleContact,
                      ),
                    ],
                  ),
                ),
                _BottomActionBar(
                  tokens: tokens,
                  currentPage: _currentPage,
                  canGoNext:
                      _selectedContacts.isNotEmpty && !_checkingMembers,
                  canCreate: _nameValidation?.ok == true &&
                      _selectedContacts.isNotEmpty &&
                      !_isCreating,
                  // Page 0: spinner while resolving member citizenship.
                  // Page 1: spinner while the create tx is in flight.
                  isCreating: _isCreating || _checkingMembers,
                  onNext: _goToNextPage,
                  onCreate: _createOrg,
                ),
              ],
            ),
            if (_isCreating) _CreatingOverlay(tokens: tokens),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Non-dismissable creating overlay
// ============================================================================

class _CreatingOverlay extends StatelessWidget {
  final GlassTokens tokens;
  const _CreatingOverlay({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: tokens.background.withValues(alpha: 0.92),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PhigitalLoadingWidget(size: 56),
                const SizedBox(height: 24),
                Text(
                  'Creating your organization',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Writing to the chain and waiting for confirmation. '
                  'This can take up to a minute — keep the app open.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Page 1 — Member selection
// ============================================================================

class _MembersPage extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController searchController;
  final bool isLoadingContacts;
  final bool isPublic;
  final List<Contact> selectedContacts;
  final List<Contact> filteredContacts;
  final void Function(Contact) onToggleContact;
  final void Function(bool) onPublicToggled;
  // Null until loaded / on error. The banner only renders when limited.
  final OrgCreationCooldown? orgCooldown;

  const _MembersPage({
    required this.tokens,
    required this.searchController,
    required this.isLoadingContacts,
    required this.isPublic,
    required this.selectedContacts,
    required this.filteredContacts,
    required this.onToggleContact,
    required this.onPublicToggled,
    required this.orgCooldown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (orgCooldown?.isLimited == true)
          _OrgCooldownBanner(tokens: tokens, cooldown: orgCooldown!),
        _SearchField(
          controller: searchController,
          tokens: tokens,
          hint: 'Search contacts by name or address',
        ),
        _PublicOrgToggle(
          tokens: tokens,
          isPublic: isPublic,
          onChanged: onPublicToggled,
        ),
        if (selectedContacts.isNotEmpty)
          _SelectedMembersStrip(
            contacts: selectedContacts,
            tokens: tokens,
            onRemove: onToggleContact,
          ),
        Expanded(
          child: _ContactGrid(
            tokens: tokens,
            isLoading: isLoadingContacts,
            contacts: filteredContacts,
            hasQuery: searchController.text.trim().isNotEmpty,
            onTapContact: onToggleContact,
          ),
        ),
      ],
    );
  }
}

/// Page-1 banner shown when the current account is still inside the
/// org-creation cooldown. Purely informational — it makes the wait visible
/// before the user invests effort in the form; createOrg's pre-flight still
/// blocks the actual submit if they push through anyway.
class _OrgCooldownBanner extends StatelessWidget {
  final GlassTokens tokens;
  final OrgCreationCooldown cooldown;
  const _OrgCooldownBanner({required this.tokens, required this.cooldown});

  /// Coarse "1d 22h" / "22h 15m" / "15m" / "<1m" — one or two units, no
  /// false precision for what's only ever a rough heads-up.
  static String _formatRemaining(Duration d) {
    if (d.inMinutes < 1) return '<1m';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    if (hours > 0) return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    return '${minutes}m';
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Local-time "May 16, 2:35 PM".
  static String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    final h24 = local.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm = h24 < 12 ? 'AM' : 'PM';
    final mins = local.minute.toString().padLeft(2, '0');
    return '${_months[local.month - 1]} ${local.day}, $h12:$mins $ampm';
  }

  /// "2 days" / "7 days" / "36 hours" — the applicable tier cadence.
  static String _formatCooldown(Duration d) {
    if (d.inDays > 0 && d.inHours % 24 == 0) {
      return d.inDays == 1 ? '1 day' : '${d.inDays} days';
    }
    final hours = d.inHours;
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  @override
  Widget build(BuildContext context) {
    final next = cooldown.nextAllowedAt!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: tokens.fallbackAccent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.fallbackAccent.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.hourglass_bottom_rounded,
                size: 18, color: tokens.fallbackAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organization cooldown active',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'You created an organization recently. You can create '
                    'another in ${_formatRemaining(cooldown.remaining)} — '
                    'on ${_formatWhen(next)}.',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cooldown.isCitizen ? "Citizen" : "Standard"} accounts '
                    'can create one organization every '
                    '${_formatCooldown(cooldown.cooldown)}.',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final GlassTokens tokens;
  final String hint;
  const _SearchField({
    required this.controller,
    required this.tokens,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: controller,
        style: TextStyle(
            fontFamily: 'SpaceGrotesk', color: tokens.starkWhite),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk', color: tokens.textDim),
          prefixIcon: Icon(Icons.search_rounded, color: tokens.textDim),
          filled: true,
          fillColor: tokens.glassFill,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: tokens.borderMedium),
          ),
        ),
      ),
    );
  }
}

class _PublicOrgToggle extends StatelessWidget {
  final GlassTokens tokens;
  final bool isPublic;
  final void Function(bool) onChanged;
  const _PublicOrgToggle({
    required this.tokens,
    required this.isPublic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPublic
                ? tokens.connectedAccent.withValues(alpha: 0.5)
                : tokens.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isPublic
                  ? Icons.verified_rounded
                  : Icons.corporate_fare_rounded,
              size: 20,
              color: isPublic ? tokens.connectedAccent : tokens.textDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Public organization',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.starkWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPublic
                        ? 'Citizens only — can register providers, nodes, '
                            'and receive grants'
                        : 'Any individual account can be a member',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isPublic,
              onChanged: onChanged,
              activeColor: tokens.connectedAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedMembersStrip extends StatelessWidget {
  final List<Contact> contacts;
  final GlassTokens tokens;
  final void Function(Contact) onRemove;
  const _SelectedMembersStrip({
    required this.contacts,
    required this.tokens,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      // DESKTOP DELTA: mouse-draggable horizontal strip
      // (`explorer_chip.dart:177` precedent).
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: HorizontalWheel(child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: contacts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final contact = contacts[i];
          return SizedBox(
            width: 68,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassContactIcon(contact: contact, size: 44),
                    const SizedBox(height: 6),
                    Text(
                      contact.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        color: tokens.starkWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 4,
                  top: -4,
                  child: GestureDetector(
                    onTap: () => onRemove(contact),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: tokens.fallbackAccent,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: tokens.background, width: 2),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: tokens.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ))),
    );
  }
}

class _ContactGrid extends StatelessWidget {
  final GlassTokens tokens;
  final bool isLoading;
  final List<Contact> contacts;
  final bool hasQuery;
  final void Function(Contact) onTapContact;

  const _ContactGrid({
    required this.tokens,
    required this.isLoading,
    required this.contacts,
    required this.hasQuery,
    required this.onTapContact,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: PhigitalLoadingWidget(size: 32));
    }

    if (contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_outlined,
                  size: 48, color: tokens.textDim),
              const SizedBox(height: 12),
              Text(
                hasQuery
                    ? 'No contacts match'
                    : 'No PublicOS contacts available',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add PublicOS contacts first, then create an org.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // DESKTOP DELTA: the breakpoint reads the WIDGET's width, not the
    // window's. `MediaQuery.size.width` is always >= 600 on desktop, so it
    // would pin 6 columns even when this grid is inside a narrow dialog column.
    return LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 600 ? 6 : 4;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: contacts.length,
      itemBuilder: (_, i) {
        final contact = contacts[i];
        return _ContactTile(
          contact: contact,
          tokens: tokens,
          onTap: () => onTapContact(contact),
        );
      },
    );
    });
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final GlassTokens tokens;
  final VoidCallback onTap;
  const _ContactTile({
    required this.contact,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          border: Border.all(color: tokens.borderSubtle),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContactIcon(contact: contact, size: 48),
            const SizedBox(height: 8),
            Text(
              contact.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.starkWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Page 2 — Organization details
// ============================================================================

class _DetailsPage extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController nameController;
  final bool isPublic;
  final int threshold;
  final List<Contact> selectedContacts;
  final void Function(int) onThresholdChanged;
  final NameValidationResult? nameValidation;
  final int nameMinLength;
  final int nameMaxLength;
  // Resolved on Next — keyed by lowercase eip55 address. Absent/false means
  // the member can't join a public org.
  final Map<String, bool> citizenship;
  final void Function(Contact) onRemoveMember;

  const _DetailsPage({
    required this.tokens,
    required this.nameController,
    required this.isPublic,
    required this.threshold,
    required this.selectedContacts,
    required this.onThresholdChanged,
    required this.nameValidation,
    required this.nameMinLength,
    required this.nameMaxLength,
    required this.citizenship,
    required this.onRemoveMember,
  });

  bool? _citizenOf(Contact c) {
    final addr = c.publicosAddress?.eip55With0x.toLowerCase();
    return addr == null ? null : citizenship[addr];
  }

  /// Live, actionable error text for the name field — mirrors
  /// new_account_dialog's `_usernameErrorText`. Returns null when the field
  /// is valid or simply empty (don't nag an untouched field).
  String? _nameErrorText() {
    final v = nameValidation;
    if (v == null || v.ok) return null;
    switch (v.reason!) {
      case NameValidationError.empty:
        return null;
      case NameValidationError.tooShort:
        final deficit = nameMinLength - v.byteLength;
        return '${isPublic ? "Public" : "Private"} org needs '
            '$nameMinLength+ characters (need $deficit more)';
      case NameValidationError.tooLong:
        return 'Max $nameMaxLength characters';
      case NameValidationError.leadingNonAlpha:
        return 'Must start with a letter';
      case NameValidationError.trailingNonAlphanumeric:
        return 'Cannot end with - or _';
      case NameValidationError.illegalChar:
        return 'Allowed: a-z  A-Z  0-9  -  _';
      case NameValidationError.consecutiveDash:
        return 'No consecutive --';
      case NameValidationError.consecutiveUnderscore:
        return 'No consecutive __';
    }
  }

  @override
  Widget build(BuildContext context) {
    final myContact = AppStateNotifier.currentMyContact;
    final memberCount = selectedContacts.length + 1;
    final maxThreshold = memberCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'ORGANIZATION NAME', tokens: tokens),
          const SizedBox(height: 6),
          TextField(
            controller: nameController,
            style: TextStyle(
                fontFamily: 'SpaceGrotesk', color: tokens.starkWhite),
            decoration: InputDecoration(
              hintText: isPublic ? 'publicos-dao' : 'my_org_team',
              hintStyle: TextStyle(
                  fontFamily: 'SpaceGrotesk', color: tokens.textDim),
              errorText: _nameErrorText(),
              errorStyle: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.fallbackAccent,
                  fontSize: 11),
              filled: true,
              fillColor: tokens.glassFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.borderMedium),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: tokens.fallbackAccent.withValues(alpha: 0.6)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: tokens.fallbackAccent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _OrgNameRules(
            tokens: tokens,
            isPublic: isPublic,
            minLength: nameMinLength,
            maxLength: nameMaxLength,
          ),
          const SizedBox(height: 22),

          _FieldLabel(text: 'VOTING THRESHOLD', tokens: tokens),
          const SizedBox(height: 6),
          Text(
            '$threshold of $memberCount member'
            '${memberCount == 1 ? '' : 's'} must approve actions',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: threshold.toDouble().clamp(1, maxThreshold.toDouble()),
            min: 1,
            max: maxThreshold.toDouble(),
            divisions: maxThreshold > 1 ? maxThreshold - 1 : null,
            label: '$threshold',
            activeColor: tokens.connectedAccent,
            onChanged: maxThreshold > 1
                ? (v) => onThresholdChanged(v.round())
                : null,
          ),
          const SizedBox(height: 12),

          _FieldLabel(text: 'MEMBERS ($memberCount)', tokens: tokens),
          const SizedBox(height: 10),
          if (myContact != null)
            _MemberRow(
              contact: myContact,
              tokens: tokens,
              isCreator: true,
              isPublic: isPublic,
              isCitizen: _citizenOf(myContact),
              onRemove: null, // can't remove yourself
            ),
          ...selectedContacts.map(
            (c) => _MemberRow(
              contact: c,
              tokens: tokens,
              isPublic: isPublic,
              isCitizen: _citizenOf(c),
              onRemove: () => onRemoveMember(c),
            ),
          ),

          if (isPublic) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tokens.connectedAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded,
                      size: 16, color: tokens.connectedAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Public org — citizens only, can register providers '
                      'and receive grants.',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 12,
                        height: 1.35,
                      ),
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

/// Static rules card for the org name — mirrors new_account_dialog's
/// `_PrivateAccountRules`. The length floor follows the public/private
/// tier; live "what's wrong" feedback is the TextField's errorText.
class _OrgNameRules extends StatelessWidget {
  final GlassTokens tokens;
  final bool isPublic;
  final int minLength;
  final int maxLength;

  const _OrgNameRules({
    required this.tokens,
    required this.isPublic,
    required this.minLength,
    required this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPublic
                    ? Icons.verified_rounded
                    : Icons.corporate_fare_rounded,
                size: 13,
                color: tokens.connectedAccent,
              ),
              const SizedBox(width: 6),
              Text(
                isPublic ? 'PUBLIC ORG NAME' : 'PRIVATE ORG NAME',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.connectedAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _OrgRuleLine(tokens: tokens, text: '$minLength–$maxLength characters'),
          _OrgRuleLine(
              tokens: tokens, text: 'Letters, digits, "-" and "_" only'),
          _OrgRuleLine(tokens: tokens, text: 'Must start with a letter'),
          _OrgRuleLine(
              tokens: tokens, text: 'No spaces, no "--" or "__" runs'),
          const SizedBox(height: 6),
          Text(
            isPublic
                ? 'Public org names can be shorter ($minLength+). The name is '
                    'permanent — orgs cannot be renamed after creation.'
                : 'Private orgs need $minLength+ characters; make it public for '
                    'a shorter name. The name is permanent — orgs cannot be '
                    'renamed after creation.',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrgRuleLine extends StatelessWidget {
  final GlassTokens tokens;
  final String text;
  const _OrgRuleLine({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: tokens.textDim,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Contact contact;
  final GlassTokens tokens;
  final bool isCreator;
  final bool isPublic;
  /// Resolved citizenship — null = unknown (treated as can't-join-public).
  final bool? isCitizen;
  /// null for the creator row (can't remove yourself).
  final VoidCallback? onRemove;
  const _MemberRow({
    required this.contact,
    required this.tokens,
    required this.isPublic,
    required this.isCitizen,
    required this.onRemove,
    this.isCreator = false,
  });

  @override
  Widget build(BuildContext context) {
    // For a public org, anyone who isn't a confirmed citizen is flagged —
    // they'll be skipped at create time.
    final flagged = isPublic && isCitizen != true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          GlassContactIcon(contact: contact, size: 32),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              contact.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isCreator) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.connectedAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'You',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.connectedAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          if (flagged) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.fallbackAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: tokens.fallbackAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                isCreator
                    ? "Private — can't make a public org"
                    : "Private — can't join public org",
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.fallbackAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: tokens.textDim,
                ),
              ),
            ),
          ] else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final GlassTokens tokens;
  const _FieldLabel({required this.text, required this.tokens});
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ============================================================================
// Bottom action bar
// ============================================================================

class _BottomActionBar extends StatelessWidget {
  final GlassTokens tokens;
  final int currentPage;
  final bool canGoNext;
  final bool canCreate;
  final bool isCreating;
  final VoidCallback onNext;
  final VoidCallback onCreate;
  const _BottomActionBar({
    required this.tokens,
    required this.currentPage,
    required this.canGoNext,
    required this.canCreate,
    required this.isCreating,
    required this.onNext,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final isPageOne = currentPage == 0;
    final enabled = isPageOne ? canGoNext : canCreate;
    final label = isPageOne ? 'NEXT' : 'CREATE ORGANIZATION';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.starkWhite,
              foregroundColor: tokens.background,
              disabledBackgroundColor:
                  tokens.starkWhite.withValues(alpha: 0.25),
              disabledForegroundColor:
                  tokens.background.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed:
                enabled ? (isPageOne ? onNext : onCreate) : null,
            child: isCreating
                ? const PhigitalLoadingWidget(size: 18, showShadows: false)
                : Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
