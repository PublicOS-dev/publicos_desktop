import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Pattern A glass sub-form sheet for starting **one specific** proposal.
///
/// The org Management tab has no "New Proposal" FAB — each section
/// owns its own affordances (Add Member, Set Threshold, Add Wallet, etc.) and
/// each affordance calls this sheet pre-targeted with [action]. There is no
/// action picker inside; just the form for the requested action plus a single
/// CREATE PROPOSAL button.
///
/// Pops `true` if the vote was successfully started, `false` / `null` on
/// cancel or failure.
Future<bool?> showProposalFormSheet(
  BuildContext context, {
  required Contact group,
  required ManagementVoteAction action,
}) {
  return showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.m,
    builder: (_) => _ProposalFormSheet(group: group, action: action),
  );
}

/// Surfaced proposal types. **Note:** the contract also exposes
/// `ADD_SAFE_OWNER` / `REMOVE_SAFE_OWNER` / `CHANGE_SAFE_THRESHOLD`, but those
/// are vestigial — every org Safe is module-executed with a single
/// AccountBlueprint owner, so changing the owner set doesn't change who can
/// act. The real governance lever is the OrgStorage member set, surfaced as
/// Add Member / Remove Member elsewhere. They're intentionally not exposed
/// here.
enum ManagementVoteAction {
  setQuorumBps,
  setVoteDuration,
  registerAdditionalWallet,
  removeWallet,
  addSafeModule,
  removeSafeModule,
}

extension ManagementVoteActionExtension on ManagementVoteAction {
  String displayName(AppLocalizations l10n) {
    switch (this) {
      case ManagementVoteAction.setQuorumBps:
        return l10n.startNewVoteSheetActionSetQuorum;
      case ManagementVoteAction.setVoteDuration:
        return l10n.startNewVoteSheetActionSetDuration;
      case ManagementVoteAction.registerAdditionalWallet:
        return l10n.startNewVoteSheetActionAddWallet;
      case ManagementVoteAction.removeWallet:
        return l10n.startNewVoteSheetActionRemoveWallet;
      case ManagementVoteAction.addSafeModule:
        return l10n.startNewVoteSheetActionAddModule;
      case ManagementVoteAction.removeSafeModule:
        return l10n.startNewVoteSheetActionRemoveModule;
    }
  }

  String description(AppLocalizations l10n) {
    switch (this) {
      case ManagementVoteAction.setQuorumBps:
        return l10n.startNewVoteSheetDescSetQuorum;
      case ManagementVoteAction.setVoteDuration:
        return l10n.startNewVoteSheetDescSetDuration;
      case ManagementVoteAction.registerAdditionalWallet:
        return l10n.startNewVoteSheetDescAddWallet;
      case ManagementVoteAction.removeWallet:
        return l10n.startNewVoteSheetDescRemoveWallet;
      case ManagementVoteAction.addSafeModule:
        return l10n.startNewVoteSheetDescAddModule;
      case ManagementVoteAction.removeSafeModule:
        return l10n.startNewVoteSheetDescRemoveModule;
    }
  }

  IconData get icon {
    switch (this) {
      case ManagementVoteAction.setQuorumBps:
        return Icons.percent_rounded;
      case ManagementVoteAction.setVoteDuration:
        return Icons.timer_outlined;
      case ManagementVoteAction.registerAdditionalWallet:
        return Icons.account_balance_wallet_outlined;
      case ManagementVoteAction.removeWallet:
        return Icons.wallet_outlined;
      case ManagementVoteAction.addSafeModule:
        return Icons.extension_outlined;
      case ManagementVoteAction.removeSafeModule:
        return Icons.extension_off_outlined;
    }
  }
}

class _ProposalFormSheet extends StatefulWidget {
  final Contact group;
  final ManagementVoteAction action;

  const _ProposalFormSheet({
    required this.group,
    required this.action,
  });

  @override
  State<_ProposalFormSheet> createState() => _ProposalFormSheetState();
}

class _ProposalFormSheetState extends State<_ProposalFormSheet> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorText;

  int _currentQuorumBps = 0;
  int _currentDurationSeconds = 0;
  List<Wallet> _existingWallets = const [];

  final TextEditingController _walletNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  /// Register-wallet: a Safe on the PublicOS chain, or a key account (EOA,
  /// chain-agnostic). The vote carries the type (1 EOA · 2 SAFE); the contract
  /// stores the chain as given, so an EOA must send 0.
  bool _walletIsSafe = false;
  final TextEditingController _quorumController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  Wallet? _selectedWalletToRemove;

  // SET_VOTE_DURATION engine bounds (seconds): [1h, 30d].
  static const int _minDurationHours = 1;
  static const int _maxDurationHours = 720;

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();
  }

  @override
  void dispose() {
    _walletNameController.dispose();
    _addressController.dispose();
    _quorumController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupInfo() async {
    if (widget.group.publicosAddress == null) return;
    // NB: do NOT read `context.l10n` here — this runs from initState(), so its
    // synchronous prefix executes before initState() completes, and touching an
    // inherited widget (Localizations) then throws → the sheet would hang on the
    // loading state forever. Read l10n lazily in the catch, after the first
    // await (same reasoning as send_sheet's `_loadWallets`).
    try {
      final orgAddress = widget.group.publicosAddress!;
      final walletList = await PublicOSWallets.getWallets(orgAddress);
      // Only the two governance-knob forms need the current engine values.
      BigInt? quorumBps;
      BigInt? durationSeconds;
      if (widget.action == ManagementVoteAction.setQuorumBps) {
        quorumBps = await PublicOSGovernance.getOrgQuorumBps(orgAddress.eip55With0x);
      } else if (widget.action == ManagementVoteAction.setVoteDuration) {
        durationSeconds =
            await PublicOSGovernance.getOrgVoteDuration(orgAddress.eip55With0x);
      }

      if (mounted) {
        setState(() {
          _currentQuorumBps = quorumBps?.toInt() ?? 0;
          _currentDurationSeconds = durationSeconds?.toInt() ?? 0;
          _existingWallets = walletList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = context.l10n.startNewVoteSheetErrorLoadFailed;
        });
      }
    }
  }

  bool _validateForm() {
    final l10n = context.l10n;
    switch (widget.action) {
      case ManagementVoteAction.setQuorumBps:
        final pct = int.tryParse(_quorumController.text.trim());
        if (pct == null || pct < 0 || pct > 100) {
          setState(() => _errorText = l10n.startNewVoteSheetErrorQuorumRange);
          return false;
        }
        break;

      case ManagementVoteAction.setVoteDuration:
        final h = int.tryParse(_durationController.text.trim());
        if (h == null || h < _minDurationHours || h > _maxDurationHours) {
          setState(() => _errorText = l10n.startNewVoteSheetErrorDurationRange);
          return false;
        }
        break;

      case ManagementVoteAction.registerAdditionalWallet:
        if (_walletNameController.text.trim().isEmpty) {
          setState(
              () => _errorText = l10n.startNewVoteSheetErrorWalletNameRequired);
          return false;
        }
        if (_addressController.text.trim().isEmpty) {
          setState(
              () => _errorText = l10n.startNewVoteSheetErrorWalletAddressRequired);
          return false;
        }
        if (!_isValidAddress(_addressController.text.trim())) {
          setState(
              () => _errorText = l10n.startNewVoteSheetErrorInvalidWalletAddress);
          return false;
        }
        break;

      case ManagementVoteAction.removeWallet:
        if (_selectedWalletToRemove == null) {
          setState(() => _errorText = l10n.startNewVoteSheetErrorSelectWallet);
          return false;
        }
        if (_selectedWalletToRemove!.isMainSafe) {
          setState(() => _errorText = l10n.startNewVoteSheetErrorCannotRemoveMain);
          return false;
        }
        break;

      case ManagementVoteAction.addSafeModule:
      case ManagementVoteAction.removeSafeModule:
        if (_addressController.text.trim().isEmpty) {
          setState(() => _errorText = l10n.startNewVoteSheetErrorAddressRequired);
          return false;
        }
        if (!_isValidAddress(_addressController.text.trim())) {
          setState(() => _errorText = l10n.startNewVoteSheetErrorInvalidAddress);
          return false;
        }
        break;
    }

    setState(() => _errorText = null);
    return true;
  }

  bool _isValidAddress(String address) {
    try {
      EthereumAddress.fromHex(address);
      return true;
    } catch (_) {
      return false;
    }
  }

  Uint8List? _hexAddrToBytes(String addr) {
    try {
      EthereumAddress.fromHex(addr);
      final hex = addr.startsWith('0x') ? addr.substring(2) : addr;
      if (hex.length != 40) return null;
      final bytes = Uint8List(20);
      for (var i = 0; i < 20; i++) {
        bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitVote() async {
    if (!_validateForm()) return;
    if (widget.group.publicosAddress == null) return;

    final l10n = context.l10n;
    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final orgAddress = widget.group.publicosAddress!.eip55With0x;
      bool success = false;

      switch (widget.action) {
        case ManagementVoteAction.setQuorumBps:
          final pct = int.parse(_quorumController.text.trim());
          success = await PublicOSGovernance.startVoteSetQuorumBps(
            orgAddress,
            pct * 100, // percent → basis points
          );
          break;

        case ManagementVoteAction.setVoteDuration:
          final hours = int.parse(_durationController.text.trim());
          success = await PublicOSGovernance.startVoteSetVoteDuration(
            orgAddress,
            hours * 3600, // hours → seconds
          );
          break;

        case ManagementVoteAction.registerAdditionalWallet:
          final addressData = _hexAddrToBytes(_addressController.text.trim());
          if (addressData == null) {
            setState(() {
              _errorText = l10n.startNewVoteSheetErrorInvalidWalletAddress;
              _isSubmitting = false;
            });
            return;
          }
          success = await PublicOSGovernance.startVoteRegisterWallet(
            orgAddress,
            protocol: PublicOSWallets.protoEvm,
            addressData: addressData,
            chainId: _walletIsSafe ? PublicOS.CHAIN_ID : 0,
            label: _walletNameController.text.trim(),
            walletType: _walletIsSafe ? 2 : 1,
          );
          break;

        case ManagementVoteAction.removeWallet:
          final w = _selectedWalletToRemove!;
          success = await PublicOSGovernance.startVoteRemoveWallet(
            orgAddress,
            protocol: w.protocol,
            addressData: w.addressData,
            chainId: w.chainId,
          );
          break;

        case ManagementVoteAction.addSafeModule:
          success = await PublicOSGovernance.startVoteAddSafeModule(
            orgAddress,
            _addressController.text.trim(),
          );
          break;

        case ManagementVoteAction.removeSafeModule:
          success = await PublicOSGovernance.startVoteRemoveSafeModule(
            orgAddress,
            _addressController.text.trim(),
          );
          break;
      }

      if (mounted) {
        if (success) {
          HapticFeedback.mediumImpact();
          Navigator.pop(context, true);
        } else {
          setState(() {
            _errorText = l10n.startNewVoteSheetErrorStartFailed;
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorText = localizedError(l10n, e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return DraggableScrollableSheet(
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
            const SizedBox(height: 8),
            _Header(
              tokens: tokens,
              action: widget.action,
              onClose: () => Navigator.pop(context, false),
            ),
            Expanded(
              child: _isLoading
                  ? _LoadingState(tokens: tokens)
                  : SingleChildScrollView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 280),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DescriptionPill(
                              tokens: tokens,
                              text: widget.action.description(context.l10n),
                            ),
                            const SizedBox(height: 18),
                            _buildFormContent(tokens),
                            if (_errorText != null) ...[
                              const SizedBox(height: 16),
                              _ErrorPill(
                                tokens: tokens,
                                message: _errorText!,
                                onDismiss: () =>
                                    setState(() => _errorText = null),
                              ),
                            ],
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
                child: _isSubmitting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: PhigitalLoadingWidget(
                            size: 28,
                            showShadows: false,
                          ),
                        ),
                      )
                    : SystemAppActionButton(
                        label: context.l10n.startNewVoteSheetCreateProposal,
                        icon: Icons.how_to_vote_rounded,
                        onTap: _submitVote,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(GlassTokens tokens) {
    switch (widget.action) {
      case ManagementVoteAction.setQuorumBps:
        return _buildQuorumForm(tokens);
      case ManagementVoteAction.setVoteDuration:
        return _buildDurationForm(tokens);
      case ManagementVoteAction.registerAdditionalWallet:
        return _buildRegisterWalletForm(tokens);
      case ManagementVoteAction.removeWallet:
        return _buildRemoveWalletForm(tokens);
      case ManagementVoteAction.addSafeModule:
        return _buildAddressForm(tokens,
            context.l10n.startNewVoteSheetModuleAddressLabel, '0x...',
            Icons.extension_outlined);
      case ManagementVoteAction.removeSafeModule:
        return _buildAddressForm(tokens,
            context.l10n.startNewVoteSheetModuleAddressLabel, '0x...',
            Icons.extension_outlined);
    }
  }

  Widget _buildQuorumForm(GlassTokens tokens) {
    final currentPct = (_currentQuorumBps / 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CurrentValuePill(
          tokens: tokens,
          label: context.l10n.startNewVoteSheetQuorumCurrentPrefix,
          value: '$currentPct%',
        ),
        const SizedBox(height: 14),
        _buildTextField(
          tokens,
          controller: _quorumController,
          label: context.l10n.startNewVoteSheetQuorumLabel,
          hint: context.l10n.startNewVoteSheetQuorumHint,
          icon: Icons.percent_rounded,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildDurationForm(GlassTokens tokens) {
    final currentHours = _currentDurationSeconds > 0
        ? (_currentDurationSeconds / 3600).round()
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CurrentValuePill(
          tokens: tokens,
          label: context.l10n.startNewVoteSheetDurationCurrentPrefix,
          value: context.l10n.startNewVoteSheetDurationHours(currentHours),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          tokens,
          controller: _durationController,
          label: context.l10n.startNewVoteSheetDurationLabel,
          hint: context.l10n.startNewVoteSheetDurationHint(
              _minDurationHours, _maxDurationHours),
          icon: Icons.timer_outlined,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  Widget _buildRegisterWalletForm(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          tokens,
          controller: _walletNameController,
          label: context.l10n.startNewVoteSheetWalletNameLabel,
          hint: context.l10n.startNewVoteSheetWalletNameHint,
          icon: Icons.label_outline,
        ),
        const SizedBox(height: 14),
        _buildTextField(
          tokens,
          controller: _addressController,
          label: context.l10n.startNewVoteSheetWalletAddressLabel,
          hint: '0x...',
          icon: Icons.account_balance_wallet_outlined,
          monospace: true,
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.startNewVoteSheetWalletTypeLabel,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final safe in const [false, true]) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _walletIsSafe = safe),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _walletIsSafe == safe
                          ? tokens.starkWhite.withValues(alpha: 0.12)
                          : tokens.glassFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      safe
                          ? context.l10n.startNewVoteSheetWalletTypeSafe
                          : context.l10n.startNewVoteSheetWalletTypeKey,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _walletIsSafe == safe ? tokens.starkWhite : tokens.textDim,
                      ),
                    ),
                  ),
                ),
              ),
              if (!safe) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.startNewVoteSheetWalletTypeHint,
          style: TextStyle(fontSize: 11, height: 1.4, color: tokens.textDim),
        ),
      ],
    );
  }

  Widget _buildRemoveWalletForm(GlassTokens tokens) {
    final removableWallets =
        _existingWallets.where((w) => !w.isMainSafe).toList();

    if (removableWallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.fallbackAccent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tokens.fallbackAccent.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: tokens.fallbackAccent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.startNewVoteSheetNoRemovableWallets,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.starkWhite,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.startNewVoteSheetSelectWalletHeader,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: tokens.textDim,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        ...removableWallets.map((w) {
          final isSelected = identical(_selectedWalletToRemove, w);
          final title = w.label.isNotEmpty
              ? w.label
              : context.l10n.startNewVoteSheetProtocolWalletTitle('${w.protocol}');
          final addressDisplay = w.protocol == PublicOSWallets.protoEvm
              ? _formatAddress(w.addressHex)
              : w.toCaip10();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedWalletToRemove = w;
                  _errorText = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tokens.connectedAccent.withValues(alpha: 0.10)
                      : tokens.glassFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? tokens.connectedAccent
                        : tokens.borderSubtle,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.connectedAccent.withValues(alpha: 0.15)
                            : tokens.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: isSelected
                            ? tokens.connectedAccent
                            : tokens.starkWhite,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? tokens.connectedAccent
                                  : tokens.starkWhite,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            addressDisplay,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: tokens.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        color: tokens.connectedAccent,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAddressForm(
    GlassTokens tokens,
    String label,
    String hint,
    IconData icon,
  ) {
    return _buildTextField(
      tokens,
      controller: _addressController,
      label: label,
      hint: hint,
      icon: icon,
      monospace: true,
    );
  }

  Widget _buildTextField(
    GlassTokens tokens, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool monospace = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontFamily: monospace ? 'monospace' : 'SpaceGrotesk',
        fontSize: 14,
        color: tokens.starkWhite,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
        ),
        hintStyle: TextStyle(
          fontFamily: monospace ? 'monospace' : 'SpaceGrotesk',
          color: tokens.textDim,
        ),
        prefixIcon: Icon(icon, color: tokens.textDim, size: 20),
        filled: true,
        fillColor: tokens.surfaceElevated,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class _Header extends StatelessWidget {
  final GlassTokens tokens;
  final ManagementVoteAction action;
  final VoidCallback onClose;

  const _Header({
    required this.tokens,
    required this.action,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Icon(
              action.icon,
              color: tokens.connectedAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              action.displayName(context.l10n),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// A compact "Current: X" chip shown above a knob-setting form (quorum,
/// duration) so the voter sees the value they're about to change.
class _CurrentValuePill extends StatelessWidget {
  final GlassTokens tokens;
  final String label;
  final String value;

  const _CurrentValuePill({
    required this.tokens,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              color: tokens.textDim,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tokens.starkWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionPill extends StatelessWidget {
  final GlassTokens tokens;
  final String text;

  const _DescriptionPill({required this.tokens, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: tokens.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.textDim,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final GlassTokens tokens;
  final String message;
  final VoidCallback onDismiss;

  const _ErrorPill({
    required this.tokens,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: errorColor.withValues(alpha: 0.40),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: errorColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, color: errorColor, size: 14),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final GlassTokens tokens;
  const _LoadingState({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PhigitalLoadingWidget(size: 32),
          const SizedBox(height: 16),
          Text(
            context.l10n.startNewVoteSheetLoading,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
