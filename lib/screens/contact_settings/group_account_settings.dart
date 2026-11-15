import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

class GroupAccountSettings extends StatefulWidget {
  final Contact groupContact;

  const GroupAccountSettings({
    super.key,
    required this.groupContact,
  });

  @override
  State<GroupAccountSettings> createState() => _GroupAccountSettingsState();
}

class _GroupAccountSettingsState extends State<GroupAccountSettings> {
  bool _isLoading = true;
  int _quorumBps = 0;
  bool _isCurrentUserMember = false;
  List<EthereumAddress> _memberAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    if (widget.groupContact.publicosAddress == null) return;

    setState(() => _isLoading = true);

    try {
      final currentUserAddress = AppStateNotifier.currentMyContact?.publicosAddress;
      if (currentUserAddress != null) {
        _isCurrentUserMember = await PublicOSGovernance.isOrgMember(
          widget.groupContact.publicosAddress!,
          currentUserAddress,
        );
      }

      final results = await Future.wait([
        PublicOSGovernance.getOrgMembers(widget.groupContact.publicosAddress!),
        PublicOSGovernance.getOrgQuorumBps(
            widget.groupContact.publicosAddress!.eip55With0x),
      ]);

      _memberAddresses = results[0] as List<EthereumAddress>;
      _quorumBps = (results[1] as BigInt?)?.toInt() ?? 0;

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading group data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar(context.l10n.groupAccountSettingsCopiedToClipboard);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _leaveOrg() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        final errorColor = Theme.of(ctx).colorScheme.error;
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          backgroundColor: tokens.surfaceDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          title: Text(
            l10n.groupAccountSettingsLeaveOrgTitle,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.groupAccountSettingsLeaveOrgConfirm(
              widget.groupContact.displayName,
            ),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.dlgCancel,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.groupAccountSettingsLeaveButton,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: errorColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final groupAddress = widget.groupContact.publicosAddress!.eip55With0x;
      final success = await PublicOSGovernance.leaveOrg(groupAddress);

      if (success && mounted) {
        _showSnackBar(
          l10n.groupAccountSettingsLeftOrgMessage(
            widget.groupContact.displayName,
          ),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        _showSnackBar(l10n.groupAccountSettingsLeaveOrgFailed);
      }
    } catch (e) {
      print('Error leaving org: $e');
      if (mounted) _showSnackBar(localizedError(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.background,
      body: _isLoading
          ? const Center(
              child: PhigitalLoadingWidget(size: 32, showShadows: false),
            )
          : RefreshIndicator(
              onRefresh: _loadGroupData,
              color: tokens.starkWhite,
              backgroundColor: tokens.surfaceElevated,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGroupInfo(tokens),
                    if (_isCurrentUserMember) ...[
                      const SizedBox(height: 24),
                      _buildLeaveOrgSection(tokens),
                    ],
                    const SizedBox(height: 24),
                    _buildRefreshSection(tokens),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGroupInfo(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.domain_rounded,
          context.l10n.groupAccountSettingsOrgIdentity,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.groupContact.publicosDisplayName != null) ...[
                _labeledValue(
                  tokens,
                  context.l10n.groupAccountSettingsNameLabel,
                  widget.groupContact.publicosDisplayName!,
                  valueStyle: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: tokens.borderSubtle),
                const SizedBox(height: 16),
              ],
              _buildCopyableInfoRow(
                tokens,
                context.l10n.groupAccountSettingsPublicosAddressLabel,
                widget.groupContact.publicosAddress?.eip55With0x,
                Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.how_to_vote_outlined,
                    size: 18,
                    color: tokens.textDim,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _labeledValue(
                      tokens,
                      context.l10n.groupAccountSettingsVotingQuorumLabel,
                      context.l10n.groupAccountSettingsVotingQuorumValue(
                        (_quorumBps / 100).round(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(GlassTokens tokens, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: tokens.connectedAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledValue(
    GlassTokens tokens,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildCopyableInfoRow(
    GlassTokens tokens,
    String label,
    String? value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: tokens.textDim),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              if (value != null)
                InkWell(
                  onTap: () => _copyToClipboard(value),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatAddress(value),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: tokens.starkWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: tokens.textDim,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  context.l10n.groupAccountSettingsNotAvailable,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveOrgSection(GlassTokens tokens) {
    final canLeave = _memberAddresses.length > 1;
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.warning_amber_rounded,
          context.l10n.groupAccountSettingsDangerZone,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: errorColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.groupAccountSettingsLeaveThisOrg,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.groupAccountSettingsLeaveThisOrgDescription,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              _DestructiveActionButton(
                label: canLeave
                    ? context.l10n.groupAccountSettingsLeaveOrgButton
                    : context.l10n.groupAccountSettingsCannotLeaveLastMember,
                icon: Icons.logout_rounded,
                onTap: canLeave ? _leaveOrg : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshSection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.storage_outlined,
          context.l10n.groupAccountSettingsDataSection,
        ),
        const SizedBox(height: 12),
        SystemAppActionButton(
          label: context.l10n.groupAccountSettingsRefreshOrgData,
          icon: Icons.refresh_rounded,
          onTap: _loadGroupData,
        ),
      ],
    );
  }
}

/// Mirrors [SystemAppActionButton] but with destructive tints.
/// Same shell, error foreground + error.withValues(alpha: 0.4) border. Dashed-disabled when [onTap] is null.
class _DestructiveActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _DestructiveActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final disabled = onTap == null;
    if (disabled) {
      final disabledColor = tokens.textDim.withValues(alpha: 0.55);
      return SizedBox(
        width: double.infinity,
        child: CustomPaint(
          painter: DashedRRectPainter(
            color: tokens.borderSubtle,
            radius: 10,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: disabledColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    fontSize: 12,
                    color: disabledColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: errorColor.withValues(alpha: 0.1),
          foregroundColor: errorColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: errorColor.withValues(alpha: 0.4)),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
