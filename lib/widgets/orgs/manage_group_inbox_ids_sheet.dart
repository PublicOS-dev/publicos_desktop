import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
// DELTA(desktop): keychain = the re-shell dialog, same as every door.
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/widgets/keychain_dialog.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Pattern A glass-dark sheet for managing an org's registered inbox IDs.
///
/// Pops `true` when any add / remove / relabel succeeded so the host
/// (org Management tab) reloads. Pops `null` / `false` on plain dismiss.
Future<bool?> showManageGroupInboxIdsSheet(
  BuildContext context, {
  required EthereumAddress orgAddress,
  required String groupName,
}) {
  return showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.l,
    builder: (_) => _ManageGroupInboxIdsSheet(
      orgAddress: orgAddress,
      groupName: groupName,
    ),
  );
}

class _GroupInboxIdData {
  final String inboxId;
  final String label;
  final bool hasLocalKey;
  final bool isRegisteredToGroup;
  final bool isRegisteredToOtherAccount;
  final String? registeredToAddress;
  final Contact? registeredToContact;

  const _GroupInboxIdData({
    required this.inboxId,
    required this.label,
    required this.hasLocalKey,
    required this.isRegisteredToGroup,
    required this.isRegisteredToOtherAccount,
    this.registeredToAddress,
    this.registeredToContact,
  });

  bool get canAddToGroup =>
      hasLocalKey && !isRegisteredToGroup && !isRegisteredToOtherAccount;
}

class _ManageGroupInboxIdsSheet extends StatefulWidget {
  final EthereumAddress orgAddress;
  final String groupName;

  const _ManageGroupInboxIdsSheet({
    required this.orgAddress,
    required this.groupName,
  });

  @override
  State<_ManageGroupInboxIdsSheet> createState() =>
      _ManageGroupInboxIdsSheetState();
}

class _ManageGroupInboxIdsSheetState
    extends State<_ManageGroupInboxIdsSheet> {
  List<_GroupInboxIdData> _inboxIds = const [];
  bool _isLoading = true;
  String? _inlineError;
  bool _anyChanged = false;
  String? _busyInboxId;

  @override
  void initState() {
    super.initState();
    // First fetch reads context.l10n, which is not allowed inside initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchInboxIds());
  }

  /// Local contact first, then the chain (saved for next time). Same
  /// lookup as the network-access sheets' owner row.
  Future<Contact?> _resolveContact(EthereumAddress address) async {
    try {
      var contact = await PublicOSContacts.getContact(address);
      if (contact == null && PublicOS.web3Connected) {
        contact = await PublicOSContacts.fetchContact(address,
            requireRecords: true);
        await PublicOSContacts.saveContact(contact);
      }
      return contact;
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchInboxIds() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _inlineError = null;
    });
    final l10n = context.l10n;

    try {
      final currentUserAddress =
          AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
      if (currentUserAddress == null) {
        throw Exception('Current user address not available');
      }

      final Map<String, _GroupInboxIdData> inboxMap = {};

      final keys = await _fetchLocalKeys();
      for (final keyData in keys) {
        final address = keyData['address'] as String;
        try {
          final inboxId = await PublicOSConversations.inboxIdFromAddress(address);
          if (inboxId != null && inboxId.isNotEmpty) {
            inboxMap[inboxId] = _GroupInboxIdData(
              inboxId: inboxId,
              label: keyData['label'] as String,
              hasLocalKey: true,
              isRegisteredToGroup: false,
              isRegisteredToOtherAccount: false,
            );
          }
        } catch (_) {}
      }

      final groupRegisteredIds =
          await PublicOSXmtp.getAllAccountInboxIds(widget.orgAddress);
      if (groupRegisteredIds != null) {
        for (int i = 0; i < groupRegisteredIds.inboxIds.length; i++) {
          final inboxIdString =
              bytes32ToString(groupRegisteredIds.inboxIds[i]);
          final label = i < groupRegisteredIds.labels.length
              ? groupRegisteredIds.labels[i]
              : l10n.manageGroupInboxIdsSheetDefaultLabel;

          final existing = inboxMap[inboxIdString];
          inboxMap[inboxIdString] = _GroupInboxIdData(
            inboxId: inboxIdString,
            label: label.isNotEmpty
                ? label
                : (existing?.label ??
                    l10n.manageGroupInboxIdsSheetDefaultLabel),
            hasLocalKey: existing?.hasLocalKey ?? false,
            isRegisteredToGroup: true,
            isRegisteredToOtherAccount: false,
            registeredToAddress: widget.orgAddress.eip55With0x,
          );
        }
      }

      for (final entry in inboxMap.entries.toList()) {
        if (!entry.value.isRegisteredToGroup && entry.value.hasLocalKey) {
          try {
            final exists = await PublicOSXmtp.accountInboxIdExists(
              StringToBytes(entry.key),
            );
            if (exists) {
              final ownerAddress = await PublicOSXmtp.getAccountAddressByInboxId(
                StringToBytes(entry.key),
              );
              final isOtherAccount = ownerAddress != null &&
                  ownerAddress != widget.orgAddress &&
                  ownerAddress !=
                      EthereumAddress.fromHex(
                        '0x0000000000000000000000000000000000000000',
                      );

              final ownerContact =
                  isOtherAccount ? await _resolveContact(ownerAddress) : null;

              inboxMap[entry.key] = _GroupInboxIdData(
                inboxId: entry.value.inboxId,
                label: entry.value.label,
                hasLocalKey: entry.value.hasLocalKey,
                isRegisteredToGroup: false,
                isRegisteredToOtherAccount: isOtherAccount,
                registeredToAddress: ownerAddress?.eip55With0x,
                registeredToContact: ownerContact,
              );
            }
          } catch (_) {}
        }
      }

      final inboxList = inboxMap.values.toList()
        ..sort((a, b) {
          if (a.isRegisteredToGroup && !b.isRegisteredToGroup) return -1;
          if (!a.isRegisteredToGroup && b.isRegisteredToGroup) return 1;
          if (a.canAddToGroup && !b.canAddToGroup) return -1;
          if (!a.canAddToGroup && b.canAddToGroup) return 1;
          return a.label.toLowerCase().compareTo(b.label.toLowerCase());
        });

      if (!mounted) return;
      setState(() {
        _inboxIds = inboxList;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineError = l10n.manageGroupInboxIdsSheetLoadFailed;
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLocalKeys() async {
    final currentUserAddress =
        AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
    if (currentUserAddress == null) return const [];
    try {
      final fetchedKeys = await PublicOSKeychain.fetchKeys(currentUserAddress);
      return fetchedKeys
          .map((k) => {
                'label': k['label'] as String,
                'address': k['address'] as String,
              })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _addToGroup(_GroupInboxIdData inboxData) async {
    final l10n = context.l10n;
    setState(() {
      _busyInboxId = inboxData.inboxId;
      _inlineError = null;
    });
    try {
      final success = await PublicOSGovernance.registerInboxIdForOrg(
        widget.orgAddress,
        StringToBytes(inboxData.inboxId),
        inboxData.label,
      );
      if (success) {
        _anyChanged = true;
        await _fetchInboxIds();
      } else {
        if (mounted) {
          setState(() =>
              _inlineError = l10n.manageGroupInboxIdsSheetAddFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _inlineError = localizedError(
              l10n,
              e,
              fallback: l10n.manageGroupInboxIdsSheetAddFailed,
            ));
      }
    } finally {
      if (mounted) setState(() => _busyInboxId = null);
    }
  }

  Future<void> _removeFromGroup(_GroupInboxIdData inboxData) async {
    final l10n = context.l10n;
    final confirmed = await _confirmDialog(
      title: l10n.manageGroupInboxIdsSheetRemoveTitle,
      body: l10n.manageGroupInboxIdsSheetRemoveBody(
        inboxData.label,
        widget.groupName,
      ),
      confirmLabel: l10n.manageGroupInboxIdsSheetRemoveConfirm,
    );
    if (confirmed != true) return;

    setState(() {
      _busyInboxId = inboxData.inboxId;
      _inlineError = null;
    });
    try {
      final success = await PublicOSGovernance.removeInboxIdForOrg(
        widget.orgAddress,
        StringToBytes(inboxData.inboxId),
      );
      if (success) {
        _anyChanged = true;
        await _fetchInboxIds();
      } else {
        if (mounted) {
          setState(() =>
              _inlineError = l10n.manageGroupInboxIdsSheetRemoveFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _inlineError = localizedError(
              l10n,
              e,
              fallback: l10n.manageGroupInboxIdsSheetRemoveFailed,
            ));
      }
    } finally {
      if (mounted) setState(() => _busyInboxId = null);
    }
  }

  Future<void> _editLabel(_GroupInboxIdData inboxData) async {
    final l10n = context.l10n;
    final newLabel = await _labelDialog(initial: inboxData.label);
    if (newLabel == null || newLabel == inboxData.label) return;

    setState(() {
      _busyInboxId = inboxData.inboxId;
      _inlineError = null;
    });
    try {
      final success = await PublicOSGovernance.updateInboxIdLabelForOrg(
        widget.orgAddress,
        StringToBytes(inboxData.inboxId),
        newLabel,
      );
      if (success) {
        _anyChanged = true;
        await _fetchInboxIds();
      } else {
        if (mounted) {
          setState(() => _inlineError =
              l10n.manageGroupInboxIdsSheetLabelUpdateFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _inlineError = localizedError(
              l10n,
              e,
              fallback: l10n.manageGroupInboxIdsSheetLabelUpdateFailed,
            ));
      }
    } finally {
      if (mounted) setState(() => _busyInboxId = null);
    }
  }

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    HapticFeedback.selectionClick();
  }

  Future<void> _openKeychain() async {
    // DELTA(desktop): the client mounts KeychainSheet as a bottom sheet;
    // desktop uses the re-shell dialog with myContact.
    await showKeychainDialog(
      context,
      myContact: AppStateNotifier.currentMyContact,
    );
    if (mounted) await _fetchInboxIds();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
    required String confirmLabel,
  }) {
    final tokens = GlassTokens.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dlgCancel,
                style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<String?> _labelDialog({required String initial}) {
    final tokens = GlassTokens.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
        title: Text(
          context.l10n.manageGroupInboxIdsSheetEditLabelTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.manageGroupInboxIdsSheetLabelHint,
            hintStyle: TextStyle(color: tokens.textDim),
            counterStyle: TextStyle(color: tokens.textDim, fontSize: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderMedium),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.dlgCancel,
                style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () {
              final v = controller.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: Text(
              context.l10n.manageGroupInboxIdsSheetSave,
              style: TextStyle(
                color: tokens.starkWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Pattern A close paths (swipe-down, X) don't pass our `_anyChanged`
        // through. When popped via _close(), we override below.
      },
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 1.0,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollCtrl) {
          return Container(
            decoration: BoxDecoration(
              color: tokens.surfaceDeep,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.borderSubtle, width: 1),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _SheetHeader(
                  tokens: tokens,
                  title: context.l10n.manageGroupInboxIdsSheetSheetTitle,
                  subtitle: widget.groupName,
                  onClose: _close,
                ),
                if (_inlineError != null)
                  _InlineError(
                    tokens: tokens,
                    message: _inlineError!,
                    onDismiss: () => setState(() => _inlineError = null),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: PhigitalLoadingWidget(size: 32))
                      : _inboxIds.isEmpty
                          ? _EmptyState(tokens: tokens)
                          : ListView.separated(
                              controller: scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              itemCount: _inboxIds.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final data = _inboxIds[i];
                                return _InboxIdRow(
                                  tokens: tokens,
                                  data: data,
                                  busy: _busyInboxId == data.inboxId,
                                  onCopy: () => _copyId(data.inboxId),
                                  onAdd: data.canAddToGroup
                                      ? () => _addToGroup(data)
                                      : null,
                                  onRemove: data.isRegisteredToGroup
                                      ? () => _removeFromGroup(data)
                                      : null,
                                  onEditLabel: data.isRegisteredToGroup
                                      ? () => _editLabel(data)
                                      : null,
                                );
                              },
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
                    child: SystemAppActionButton(
                      label: context.l10n.manageGroupInboxIdsSheetManageKeys,
                      icon: Icons.key_rounded,
                      onTap: _openKeychain,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _close() {
    Navigator.of(context).pop(_anyChanged);
  }
}

// ─── Pattern A primitives ────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.tokens,
    required this.title,
    required this.onClose,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              Icons.inbox_outlined,
              color: tokens.connectedAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
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

class _InlineError extends StatelessWidget {
  final GlassTokens tokens;
  final String message;
  final VoidCallback onDismiss;

  const _InlineError({
    required this.tokens,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final err = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: err.withValues(alpha: 0.08),
          border: Border.all(color: err.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: err),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: err,
                  fontSize: 12,
                ),
              ),
            ),
            InkResponse(
              onTap: onDismiss,
              radius: 18,
              child: Icon(Icons.close_rounded, size: 14, color: err),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final GlassTokens tokens;
  const _EmptyState({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.glassFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 28,
                color: tokens.textDim,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.manageGroupInboxIdsSheetEmptyTitle,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.manageGroupInboxIdsSheetEmptyBody,
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
}

class _InboxIdRow extends StatelessWidget {
  final GlassTokens tokens;
  final _GroupInboxIdData data;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onEditLabel;

  const _InboxIdRow({
    required this.tokens,
    required this.data,
    required this.busy,
    required this.onCopy,
    this.onAdd,
    this.onRemove,
    this.onEditLabel,
  });

  @override
  Widget build(BuildContext context) {
    final err = Theme.of(context).colorScheme.error;

    final (statusIcon, statusColor) = switch (data) {
      _GroupInboxIdData(isRegisteredToGroup: true) => (
          Icons.check_circle_rounded,
          tokens.connectedAccent,
        ),
      _GroupInboxIdData(isRegisteredToOtherAccount: true) => (
          Icons.block_rounded,
          tokens.fallbackAccent,
        ),
      _GroupInboxIdData(canAddToGroup: true) => (
          Icons.add_circle_outline_rounded,
          tokens.starkWhite,
        ),
      _ => (Icons.help_outline_rounded, tokens.textDim),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: data.isRegisteredToGroup
              ? tokens.connectedAccent.withValues(alpha: 0.4)
              : tokens.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Icon(statusIcon, size: 16, color: statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.label,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: data.isRegisteredToOtherAccount
                            ? tokens.textDim
                            : tokens.starkWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shortenString(data.inboxId),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: tokens.textDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: PhigitalLoadingWidget(size: 18, showShadows: false),
                )
              else ...[
                _RowIconBtn(
                  tokens: tokens,
                  icon: Icons.copy_rounded,
                  color: tokens.textDim,
                  onTap: onCopy,
                ),
                if (onEditLabel != null)
                  _RowIconBtn(
                    tokens: tokens,
                    icon: Icons.edit_outlined,
                    color: tokens.textDim,
                    onTap: onEditLabel!,
                  ),
                if (onRemove != null)
                  _RowIconBtn(
                    tokens: tokens,
                    icon: Icons.remove_circle_outline_rounded,
                    color: err,
                    onTap: onRemove!,
                  ),
                if (onAdd != null)
                  _RowIconBtn(
                    tokens: tokens,
                    icon: Icons.add_circle_outline_rounded,
                    color: tokens.starkWhite,
                    onTap: onAdd!,
                  ),
              ],
            ],
          ),
          if (data.isRegisteredToOtherAccount &&
              data.registeredToAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 42),
              child: _RegisteredToLine(
                tokens: tokens,
                address: data.registeredToAddress!,
                contact: data.registeredToContact,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Registered to [icon] [name]": the owner as a mini avatar + display name,
/// falling back to the short address. The l10n string is split at its
/// placeholder so word order stays the translator's.
class _RegisteredToLine extends StatefulWidget {
  final GlassTokens tokens;
  final String address;
  final Contact? contact;

  const _RegisteredToLine({
    required this.tokens,
    required this.address,
    required this.contact,
  });

  @override
  State<_RegisteredToLine> createState() => _RegisteredToLineState();
}

class _RegisteredToLineState extends State<_RegisteredToLine> {
  GlassTokens get tokens => widget.tokens;
  String get address => widget.address;
  Contact? get contact => widget.contact;

  /// The name opens the same account as its mini-icon.
  TapGestureRecognizer? _nameTap;

  @override
  void dispose() {
    _nameTap?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _nameTap?.dispose();
    _nameTap = null;
    final open = GlassContactIcon.profileTap(context,
        contact: contact, address: address);
    if (open != null) _nameTap = TapGestureRecognizer()..onTap = open;
    const marker = '\u0000';
    final parts =
        context.l10n.manageGroupInboxIdsSheetRegisteredTo(marker).split(marker);
    final name = contact?.publicosDisplayName ??
        contact?.displayName ??
        shortenString(address);
    final style = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.fallbackAccent.withValues(alpha: 0.8),
      fontSize: 10,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: parts.first),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GlassContactIcon(
                opensProfile: true,
                contact: contact,
                address: address,
                size: 14,
              ),
            ),
          ),
          TextSpan(
            text: name,
            style: style.copyWith(fontWeight: FontWeight.w700),
            recognizer: _nameTap,
          ),
          if (parts.length > 1) TextSpan(text: parts.sublist(1).join()),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _RowIconBtn extends StatelessWidget {
  final GlassTokens tokens;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RowIconBtn({
    required this.tokens,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
