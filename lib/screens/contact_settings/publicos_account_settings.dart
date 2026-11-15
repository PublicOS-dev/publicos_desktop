import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:wallet/wallet.dart';

/// Settings screen for viewing a PublicOS individual account (not self, not group).
///
/// Displays informative, read-only data about the contact's on-chain identity:
/// - Account address and username
/// - Registered XMTP Inbox IDs
/// - Session wallet addresses
/// - Current conversation details
/// - Block/unblock action
class PublicOSAccountSettings extends StatefulWidget {
  final Contact contact;

  const PublicOSAccountSettings({
    super.key,
    required this.contact,
  });

  @override
  State<PublicOSAccountSettings> createState() => _PublicOSAccountSettingsState();
}

class _PublicOSAccountSettingsState extends State<PublicOSAccountSettings> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  late Contact _contact;
  List<Map<String, String>> _registeredInboxIds = [];
  List<EthereumAddress> _sessionAddresses = [];

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    setState(() => _isLoading = true);

    try {
      if (_contact.publicosAddress != null) {
        await _loadRegisteredInboxIds();
        await _loadSessionAddresses();
      }

      if (_contact.publicosAddress != null) {
        final updatedContact = await PublicOSContacts.fetchContact(_contact.publicosAddress!);
        if (mounted) {
          setState(() {
            _contact = updatedContact;
          });
        }
      }
    } catch (e) {
      print('Error loading account data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRegisteredInboxIds() async {
    if (_contact.publicosAddress == null) return;

    try {
      final result = await PublicOSXmtp.getAllAccountInboxIds(_contact.publicosAddress!);
      if (result == null || result.inboxIds.isEmpty) {
        _registeredInboxIds = [];
        return;
      }

      final List<Map<String, String>> inboxData = [];
      for (int i = 0; i < result.inboxIds.length; i++) {
        inboxData.add({
          'id': bytes32ToString(result.inboxIds[i]),
          'label': i < result.labels.length ? result.labels[i] : '',
        });
      }
      _registeredInboxIds = inboxData;
    } catch (e) {
      print('Error loading registered inbox IDs: $e');
      _registeredInboxIds = [];
    }
  }

  Future<void> _loadSessionAddresses() async {
    if (_contact.publicosAddress == null) return;

    try {
      final sessions = await PublicOSBsp.accountMemoryContract.getAccountSessions(
        (accountAddress: _contact.publicosAddress!),
      );
      _sessionAddresses = sessions;
    } catch (e) {
      print('Error loading session addresses: $e');
      _sessionAddresses = [];
    }
  }

  Future<void> _refreshContact() async {
    final l10n = context.l10n;
    setState(() => _isRefreshing = true);

    try {
      final resolvedContact = await PublicOSContacts.resolveContact(_contact, forceResolve: true);
      await _loadRegisteredInboxIds();
      await _loadSessionAddresses();

      if (mounted) {
        setState(() {
          _contact = resolvedContact;
          _isRefreshing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.publicosAccountSettingsContactRefreshed)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(l10n, e))),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    final l10n = context.l10n;
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.publicosAccountSettingsCopiedToClipboard(label))),
      );
    });
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty || address.length < 10) {
      return context.l10n.publicosAccountSettingsNotAvailable;
    }
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: const Center(
          child: PhigitalLoadingWidget(size: 32, showShadows: false),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.background,
      body: RefreshIndicator(
        onRefresh: _refreshContact,
        color: tokens.starkWhite,
        backgroundColor: tokens.surfaceElevated,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountIdentitySection(tokens),
              const SizedBox(height: 24),
              _buildRegisteredInboxIdsSection(tokens),
              const SizedBox(height: 24),
              _buildSessionWalletsSection(tokens),
              const SizedBox(height: 24),
              _buildConversationSection(tokens),
              const SizedBox(height: 24),
              _buildActionsSection(tokens),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    GlassTokens tokens,
    IconData icon,
    String title, {
    Widget? trailing,
  }) {
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
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _countPill(GlassTokens tokens, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: tokens.starkWhite,
        ),
      ),
    );
  }

  Widget _sectionHint(GlassTokens tokens, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        hint,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          color: tokens.textDim,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _glassCard(GlassTokens tokens, Widget child, {EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: child,
    );
  }

  Widget _emptyCard(GlassTokens tokens, IconData icon, String label) {
    return _glassCard(
      tokens,
      Column(
        children: [
          Icon(icon, size: 32, color: tokens.textDim),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
    );
  }

  Widget _buildAccountIdentitySection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(tokens, Icons.verified_user_rounded, context.l10n.publicosAccountSettingsAccountIdentity),
        const SizedBox(height: 12),
        _glassCard(
          tokens,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_contact.publicosDisplayName != null) ...[
                _labeledBlock(
                  tokens,
                  context.l10n.publicosAccountSettingsUsernameLabel,
                  _contact.publicosDisplayName!,
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
                context.l10n.publicosAccountSettingsAccountAddressLabel,
                _contact.publicosAddress?.eip55With0x,
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labeledBlock(
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

  Widget _buildRegisteredInboxIdsSection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.inbox_rounded,
          context.l10n.publicosAccountSettingsRegisteredInboxIds,
          trailing: _countPill(tokens, _registeredInboxIds.length),
        ),
        const SizedBox(height: 8),
        _sectionHint(tokens, context.l10n.publicosAccountSettingsRegisteredInboxIdsHint),
        const SizedBox(height: 12),
        if (_registeredInboxIds.isEmpty)
          _emptyCard(tokens, Icons.inbox_outlined, context.l10n.publicosAccountSettingsNoInboxIds)
        else
          _glassCard(
            tokens,
            Column(
              children: _registeredInboxIds.asMap().entries.map((entry) {
                final index = entry.key;
                final inboxData = entry.value;
                final isLast = index == _registeredInboxIds.length - 1;

                return Column(
                  children: [
                    _buildInboxIdTile(tokens, inboxData),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 8,
                        endIndent: 8,
                        color: tokens.borderSubtle,
                      ),
                  ],
                );
              }).toList(),
            ),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildInboxIdTile(GlassTokens tokens, Map<String, String> inboxData) {
    final inboxId = inboxData['id'] ?? '';
    final rawLabel = inboxData['label'] ?? '';
    final label = rawLabel.isEmpty ? context.l10n.publicosAccountSettingsUnlabeled : rawLabel;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Icons.mail_outline_rounded,
              color: tokens.starkWhite,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatAddress(inboxId),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: tokens.textDim,
                  ),
                ),
              ],
            ),
          ),
          InkResponse(
            onTap: () => _copyToClipboard(inboxId, context.l10n.publicosAccountSettingsInboxIdLabel),
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: tokens.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionWalletsSection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.devices_rounded,
          context.l10n.publicosAccountSettingsSessionWallets,
          trailing: _countPill(tokens, _sessionAddresses.length),
        ),
        const SizedBox(height: 8),
        _sectionHint(tokens, context.l10n.publicosAccountSettingsSessionWalletsHint),
        const SizedBox(height: 12),
        if (_sessionAddresses.isEmpty)
          _emptyCard(tokens, Icons.devices_other, context.l10n.publicosAccountSettingsNoSessions)
        else
          _glassCard(
            tokens,
            Column(
              children: _sessionAddresses.asMap().entries.map((entry) {
                final index = entry.key;
                final address = entry.value;
                final isLast = index == _sessionAddresses.length - 1;

                return Column(
                  children: [
                    _buildSessionTile(tokens, address, index),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 8,
                        endIndent: 8,
                        color: tokens.borderSubtle,
                      ),
                  ],
                );
              }).toList(),
            ),
            padding: EdgeInsets.zero,
          ),
      ],
    );
  }

  Widget _buildSessionTile(GlassTokens tokens, EthereumAddress address, int index) {
    final isMain = index == 0;
    final iconColor = isMain ? tokens.connectedAccent : tokens.starkWhite;
    final iconBg = isMain
        ? tokens.connectedAccent.withValues(alpha: 0.12)
        : tokens.glassFill;
    final iconBorder = isMain
        ? tokens.connectedAccent.withValues(alpha: 0.4)
        : tokens.borderSubtle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconBorder),
            ),
            child: Icon(
              isMain ? Icons.smartphone_rounded : Icons.devices_other_rounded,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _formatAddress(address.eip55With0x),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: tokens.starkWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (isMain) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.connectedAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tokens.connectedAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          context.l10n.publicosAccountSettingsPrimaryBadge,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: tokens.connectedAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.publicosAccountSettingsSessionNumber(index + 1),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              ],
            ),
          ),
          InkResponse(
            onTap: () => _copyToClipboard(address.eip55With0x, context.l10n.publicosAccountSettingsSessionAddressLabel),
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: tokens.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSection(GlassTokens tokens) {
    final primaryInboxId = _contact.registeredInboxIDs?.firstOrNull?.inboxId;
    if (primaryInboxId == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(tokens, Icons.chat_bubble_outline_rounded, context.l10n.publicosAccountSettingsConversation),
        const SizedBox(height: 8),
        _sectionHint(tokens, context.l10n.publicosAccountSettingsConversationHint),
        const SizedBox(height: 12),
        _glassCard(
          tokens,
          _buildCopyableInfoRow(
            tokens,
            context.l10n.publicosAccountSettingsPrimaryInboxIdLabel,
            primaryInboxId,
            Icons.inbox_outlined,
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
                  onTap: () => _copyToClipboard(value, label),
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
                  context.l10n.publicosAccountSettingsNotAvailable,
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

  Widget _buildActionsSection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(tokens, Icons.settings_rounded, context.l10n.publicosAccountSettingsActions),
        const SizedBox(height: 12),
        SystemAppActionButton(
          label: _isRefreshing
              ? context.l10n.publicosAccountSettingsRefreshing
              : context.l10n.publicosAccountSettingsRefreshContactDetails,
          icon: Icons.refresh_rounded,
          onTap: _isRefreshing ? null : _refreshContact,
        ),
      ],
    );
  }
}
