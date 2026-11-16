import 'dart:convert';
import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/profile/create_tab_sheet.dart';
import 'package:publicos_desktop/widgets/profile/tab_icon_widget.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/widgets/dashed_add_button.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';

/// Launches the Manage Tabs sheet. Wrapper mirrors the Switch-tab sheet
/// (`browser.dart::_showTabPickerSheet`) so the surface reads as the same
/// family — same `surfaceDeep` chrome, same handle bar, same title row,
/// same row shape — with the chevron swapped for edit/delete and a
/// dashed "Add new tab" at the bottom.
///
/// Returns `true` when any tab was changed (record save/delete, inbox-tab
/// rename/remove). The dirty flag is captured in a closure rather than the
/// pop result so it survives swipe-to-dismiss (which pops with null).
Future<bool?> showManageProfileTabsSheet({
  required BuildContext context,
  Contact? contact,
  bool isOrgMember = false,
}) {
  bool dirty = false;
  // DELTA (desktop): sheet -> centered glass dialog. The `.then` result
  // contract below is untouched, so every caller stays verbatim.
  return showGlassSheetDialog<bool>(
    context: context,
    width: DialogWidth.l,
    builder: (sheetCtx) {
      return ManageProfileTabsSheet(
        contact: contact,
        isOrgMember: isOrgMember,
        onDirty: () => dirty = true,
      );
    },
  ).then((result) => result ?? (dirty ? true : null));
}

/// One row of the on-chain XMTP inbox-id registry, shown as a "chat tab".
/// The browser's tab switcher hides the entry matching the currently loaded
/// XMTP key (you can't message yourself); here we list ALL of them — this is
/// management, and the hidden one still needs rename/delete.
class _InboxTabEntry {
  final Uint8List inboxIdBytes;
  final String inboxIdHex;
  final String label;
  final bool isActiveKey;

  const _InboxTabEntry({
    required this.inboxIdBytes,
    required this.inboxIdHex,
    required this.label,
    required this.isActiveKey,
  });
}

class ManageProfileTabsSheet extends StatefulWidget {
  final Contact? contact;
  final bool isOrgMember;
  final VoidCallback? onDirty;

  const ManageProfileTabsSheet({
    super.key,
    this.contact,
    this.isOrgMember = false,
    this.onDirty,
  });

  @override
  State<ManageProfileTabsSheet> createState() => _ManageProfileTabsSheetState();
}

class _ManageProfileTabsSheetState extends State<ManageProfileTabsSheet> {
  List<Record> _profileTabs = [];
  List<_InboxTabEntry> _inboxTabs = [];
  bool _loadingRecords = true;
  bool _loadingInbox = true;
  int _mutating = 0;
  String? _error;
  String? _inboxError;

  @override
  void initState() {
    super.initState();
    // After the first frame: the fetch reads `context.l10n` synchronously
    // (`_fetchInboxTabs`, the no-address error), which throws inside
    // initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchProfileTabs();
    });
  }

  bool get _canManageTabs {
    if (widget.contact == null) return true;
    if (widget.contact!.isOrgAccount) {
      return widget.isOrgMember;
    }
    return false;
  }

  bool get _isOrgTarget =>
      widget.contact?.isOrgAccount == true &&
      widget.contact?.publicosAddress != null;

  /// Legend for the pinned bottom-right loading row. Null = row hidden.
  String? get _loadingLegend {
    if (_loadingRecords) {
      return context.l10n.manageProfileTabsSheetLoadingWebFeedTabs;
    }
    if (_loadingInbox) return context.l10n.manageProfileTabsSheetLoadingInboxTabs;
    if (_mutating > 0) return context.l10n.manageProfileTabsSheetUpdatingTabs;
    return null;
  }

  void _markDirty() => widget.onDirty?.call();

  /// True when the viewed org has an open vote on chain. Used after an
  /// org tab write to tell a threshold-1 auto-execute (change already
  /// applied) from a threshold-N proposal members still need to approve.
  Future<bool> _isOrgVoteOpen() async {
    final addr = widget.contact?.publicosAddress;
    if (widget.contact?.isOrgAccount != true || addr == null) return false;
    try {
      return await PublicOSGovernance.hasPendingVoteBy(
          addr.eip55With0x, PublicOS.myPublicosAddress);
    } catch (_) {
      return false;
    }
  }

  EthereumAddress? get _targetAddress {
    if (widget.contact != null) return widget.contact!.publicosAddress;
    return AppStateNotifier.currentMyContact?.publicosAddress;
  }

  /// Kicks off both sources concurrently; each renders as it lands.
  Future<void> _fetchProfileTabs() async {
    if (!mounted) return;
    final targetAddress = _targetAddress;
    if (targetAddress == null) {
      setState(() {
        _error = context.l10n.manageProfileTabsSheetNoAddressError;
        _loadingRecords = false;
        _loadingInbox = false;
      });
      return;
    }
    setState(() {
      _loadingRecords = true;
      _loadingInbox = true;
      _error = null;
      _inboxError = null;
    });
    _fetchRouterTabs(targetAddress);
    _fetchInboxTabs(targetAddress);
  }

  Future<void> _fetchRouterTabs(EthereumAddress targetAddress) async {
    try {
      final allRouterRecords = await PublicOSContacts.getRecordsByType(
        RecordType.router,
        targetAccountAddress: targetAddress,
      );

      final tabs = allRouterRecords.where((record) {
        bool isTab = record.routerSubtype == RouterSubtype.tab ||
            record.routerSubtype == RouterSubtype.channel;
        bool notExpired = !record.isExpired;
        return isTab && notExpired;
      }).toList();

      tabs.sort((a, b) {
        final aName = (a.metadata['name'] as String? ?? '').toLowerCase();
        final bName = (b.metadata['name'] as String? ?? '').toLowerCase();
        return aName.compareTo(bName);
      });

      if (!mounted) return;
      setState(() {
        _profileTabs = tabs;
        _loadingRecords = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = localizedError(context.l10n, e);
        _loadingRecords = false;
      });
    }
  }

  /// On-chain XMTP registry read — deliberately UNFILTERED. The browser
  /// skips the entry matching `PublicOS.clientXmtpInboxId` when building
  /// chat tabs; here that entry shows with an ACTIVE KEY chip instead.
  Future<void> _fetchInboxTabs(EthereumAddress targetAddress) async {
    final l10n = context.l10n;
    try {
      final inboxData = await PublicOSXmtp.getAllAccountInboxIds(targetAddress);
      final entries = <_InboxTabEntry>[];
      if (inboxData != null) {
        final currentInboxId = PublicOS.clientXmtpInboxId?.toLowerCase();
        for (int i = 0; i < inboxData.inboxIds.length; i++) {
          final bytes =
              Uint8List.fromList(List<int>.from(inboxData.inboxIds[i]));
          final hex =
              bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          final label = (i < inboxData.labels.length)
              ? inboxData.labels[i]
              : l10n.manageProfileTabsSheetChatFallback;
          entries.add(_InboxTabEntry(
            inboxIdBytes: bytes,
            inboxIdHex: hex,
            label: label,
            isActiveKey:
                currentInboxId != null && hex.toLowerCase() == currentInboxId,
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        _inboxTabs = entries;
        _loadingInbox = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inboxError = l10n.manageProfileTabsSheetInboxLoadError;
        _loadingInbox = false;
      });
    }
  }

  void _showCreateTabSheet([Record? tabToEdit]) {
    showCreateTabSheet(
      context,
      record: tabToEdit,
      onSave: (Record recordToSave) async {
        try {
          bool success;

          if (_isOrgTarget) {
            // Org record — route through governance. startVoteSetRecord
            // resolves once the startVote tx is confirmed mined: threshold-1
            // orgs apply the tab in that tx, threshold-N open a vote.
            success = await PublicOSGovernance.startVoteSetRecord(
              widget.contact!.publicosAddress!,
              key: recordToSave.key,
              value: jsonEncode(recordToSave.toChainValue()),
              expiration:
                  recordToSave.chainExpiration,
              recordType: BigInt.from(recordToSave.type.index),
              customType: recordToSave.subtype ?? '',
            );
          } else {
            success = await PublicOSContacts.setRecord(recordToSave);
            if (success) {
              final myAddress = widget.contact?.publicosAddress;
              if (myAddress != null) {
                // Nested try: the chain write ALREADY succeeded. A failed
                // post-commit refresh must not reach the outer catch, which
                // would show "failed to save" for a tab that saved fine.
                try {
                  final fresh = await PublicOSContacts.fetchContact(
                    myAddress,
                    requireRecords: true,
                  );
                  await PublicOSContacts.saveContact(fresh);
                } catch (e) {
                  debugPrint('post-commit refresh failed (write succeeded): $e');
                }
              }
            }
          }

          if (success) {
            _markDirty();
            final voteOpen = await _isOrgVoteOpen();
            await _fetchProfileTabs();
            if (mounted) {
              final String msg;
              if (voteOpen) {
                msg = context.l10n.manageProfileTabsSheetVoteStarted;
              } else {
                msg = tabToEdit == null
                    ? context.l10n.manageProfileTabsSheetTabCreated
                    : context.l10n.manageProfileTabsSheetTabUpdated;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  behavior: SnackBarBehavior.fixed,
                ),
              );
            }
          } else {
            throw Exception('Failed to save tab to PublicOSContacts.');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localizedError(context.l10n, e)),
                behavior: SnackBarBehavior.fixed,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _deleteTab(Record tabToDelete) async {
    final tabName = tabToDelete.metadata['name'] as String? ??
        context.l10n.manageProfileTabsSheetUnnamedTab;
    final confirmed = await _confirmDelete(
      title: context.l10n.manageProfileTabsSheetDeleteTabTitle,
      body: context.l10n.manageProfileTabsSheetDeleteTabBody(tabName),
    );

    if (confirmed == true) {
      if (!mounted) return;
      setState(() => _mutating++);
      try {
        bool success;

        if (_isOrgTarget) {
          // Org record — route through governance (threshold-1 → deleted in
          // the startVote tx; threshold-N → vote now open).
          success = await PublicOSGovernance.startVoteDeleteRecord(
            widget.contact!.publicosAddress!,
            tabToDelete.key,
          );
        } else {
          success = await PublicOSContacts.deleteRecord(tabToDelete.key);
          if (success) {
            final myAddress = widget.contact?.publicosAddress;
            if (myAddress != null) {
              // Nested try — same reason as the save path: the delete already
              // committed on chain; a failed refresh must not report failure.
              try {
                final fresh = await PublicOSContacts.fetchContact(
                  myAddress,
                  requireRecords: true,
                );
                await PublicOSContacts.saveContact(fresh);
              } catch (e) {
                debugPrint('post-commit refresh failed (delete succeeded): $e');
              }
            }
          }
        }

        if (success) {
          _markDirty();
          final voteOpen = await _isOrgVoteOpen();
          await _fetchProfileTabs();
          if (mounted) {
            final actionText = voteOpen
                ? context.l10n.manageProfileTabsSheetVoteStarted
                : context.l10n.manageProfileTabsSheetTabDeleted;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(actionText),
                behavior: SnackBarBehavior.fixed,
              ),
            );
          }
        } else {
          throw Exception('Failed to delete tab from PublicOSContacts.');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizedError(context.l10n, e)),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _mutating--);
      }
    }
  }

  /// Rename an inbox-id tab — label only (the id itself is the key).
  /// Self → direct XmtpManager write; org → governance vote flow, same
  /// threshold-1 / threshold-N semantics as record saves.
  Future<void> _renameInboxTab(_InboxTabEntry entry) async {
    final newLabel = await _promptInboxLabel(entry.label);
    if (newLabel == null || newLabel.isEmpty || newLabel == entry.label) {
      return;
    }
    if (!mounted) return;
    setState(() => _mutating++);
    try {
      final bool success = _isOrgTarget
          ? await PublicOSGovernance.updateInboxIdLabelForOrg(
              widget.contact!.publicosAddress!, entry.inboxIdBytes, newLabel)
          : await PublicOSXmtp.updateInboxIdLabel(entry.inboxIdBytes, newLabel);
      if (success) {
        _markDirty();
        final voteOpen = await _isOrgVoteOpen();
        await _fetchProfileTabs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(voteOpen
                  ? context.l10n.manageProfileTabsSheetVoteStarted
                  : context.l10n.manageProfileTabsSheetInboxRenamed),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      } else {
        throw Exception('Failed to update inbox label.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(context.l10n, e)),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _mutating--);
    }
  }

  Future<void> _deleteInboxTab(_InboxTabEntry entry) async {
    final confirmed = await _confirmDelete(
      title: context.l10n.manageProfileTabsSheetRemoveInboxTitle,
      body: context.l10n.manageProfileTabsSheetRemoveInboxBody(entry.label),
      confirmLabel: context.l10n.manageProfileTabsSheetActionRemove,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _mutating++);
    try {
      final bool success = _isOrgTarget
          ? await PublicOSGovernance.removeInboxIdForOrg(
              widget.contact!.publicosAddress!, entry.inboxIdBytes)
          : await PublicOSXmtp.removeInboxId(entry.inboxIdBytes);
      if (success) {
        _markDirty();
        final voteOpen = await _isOrgVoteOpen();
        await _fetchProfileTabs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(voteOpen
                  ? context.l10n.manageProfileTabsSheetVoteStarted
                  : context.l10n.manageProfileTabsSheetInboxRemoved),
              behavior: SnackBarBehavior.fixed,
            ),
          );
        }
      } else {
        throw Exception('Failed to remove inbox ID.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizedError(context.l10n, e)),
            behavior: SnackBarBehavior.fixed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _mutating--);
    }
  }

  /// Small glass label prompt — shape borrowed from
  /// `manage_inbox_ids_page.dart::_promptLabel`.
  Future<String?> _promptInboxLabel(String initial) {
    final tokens = GlassTokens.of(context);
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
        title: Text(
          context.l10n.manageProfileTabsSheetRenameInboxTitle,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            color: tokens.starkWhite,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 14,
            color: tokens.starkWhite,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.manageProfileTabsSheetLabelHint,
            hintStyle: TextStyle(color: tokens.textDim),
            filled: true,
            fillColor: tokens.surfaceElevated,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.dlgCancel,
                style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(
              context.l10n.manageProfileTabsSheetSave,
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

  Future<bool?> _confirmDelete({
    required String title,
    required String body,
    String? confirmLabel,
  }) {
    final tokens = GlassTokens.of(context);
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          backgroundColor: tokens.surfaceDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              color: tokens.starkWhite,
            ),
          ),
          content: Text(
            body,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.dlgCancel,
                  style: TextStyle(color: tokens.textDim)),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                  confirmLabel ?? context.l10n.manageProfileTabsSheetActionDelete),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isGroupAccount = widget.contact?.isOrgAccount == true;
    final title = isGroupAccount
        ? context.l10n.manageProfileTabsSheetGroupTitle
        : context.l10n.manageProfileTabsSheetTitle;
    final legend = _loadingLegend;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + close — matches Switch tab.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                child: Row(
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
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(child: _buildBody(tokens, isGroupAccount)),
              // Pinned loading/updating row — rain loader bottom-right,
              // legend to its left. Rows above render as each source lands.
              if (legend != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        legend,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          color: tokens.textDim,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const PixelRainLoadingWidget(
                          size: 24, showShadows: false),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(GlassTokens tokens, bool isGroupAccount) {
    final canManage = _canManageTabs;
    final children = <Widget>[];

    if (_error != null) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Text(
          _error!,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
            color: Theme.of(context).colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
      ));
    }

    for (final tab in _profileTabs) {
      children.add(_buildTabRow(tab, tokens, viewOnly: !canManage));
    }

    if (_inboxTabs.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
        child: Text(
          context.l10n.manageProfileTabsSheetInboxTabsHeader,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ));
      for (final entry in _inboxTabs) {
        children.add(_buildInboxRow(entry, tokens, viewOnly: !canManage));
      }
    }

    if (_inboxError != null) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
        child: Text(
          _inboxError!,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
          ),
        ),
      ));
    }

    if (!canManage) {
      // View-only: rows render without edit/delete, plus an inline note.
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
        child: Text(
          isGroupAccount
              ? context.l10n.manageProfileTabsSheetOnlyGroupMembers
              : context.l10n.manageProfileTabsSheetViewOnly,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
          ),
        ),
      ));
    } else {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: DashedAddButton(
          label: context.l10n.manageProfileTabsSheetAddNewTab,
          icon: Icons.add_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            _showCreateTabSheet();
          },
        ),
      ));
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 12),
      children: children,
    );
  }

  /// 36px leading icon with the type badge notched into the bottom-right
  /// corner — same affordance as the browser header's mini tab icon.
  Widget _buildLeadingIcon(GlassTokens tokens,
      {required Widget child, required IconData badgeIcon}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: child,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: TabTypeBadge(icon: badgeIcon),
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow(
    Record tab,
    GlassTokens tokens, {
    bool viewOnly = false,
  }) {
    final isRss = tab.routerSubtype == RouterSubtype.channel;

    final leading = _buildLeadingIcon(
      tokens,
      badgeIcon: isRss ? Icons.rss_feed_rounded : Icons.language_rounded,
      child: TabIconWidget(record: tab, size: 36),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: viewOnly
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  _showCreateTabSheet(tab);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.metadata['name'] as String? ??
                        context.l10n.manageProfileTabsSheetUnnamedTab,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: tokens.starkWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!viewOnly) ...[
                  _RowIconButton(
                    icon: Icons.edit_rounded,
                    color: tokens.starkWhite,
                    onTap: () => _showCreateTabSheet(tab),
                  ),
                  const SizedBox(width: 4),
                  _RowIconButton(
                    icon: Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => _deleteTab(tab),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInboxRow(
    _InboxTabEntry entry,
    GlassTokens tokens, {
    bool viewOnly = false,
  }) {
    final leading = _buildLeadingIcon(
      tokens,
      badgeIcon: Icons.chat_bubble_rounded,
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 18,
        color: tokens.textDim,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: viewOnly
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  _renameInboxTab(entry);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                leading,
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.label,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: tokens.starkWhite,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.isActiveKey) ...[
                        const SizedBox(width: 8),
                        // Why this row never shows in the tab switcher:
                        // it's the loaded XMTP key (can't chat with self).
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: tokens.borderSubtle, width: 1),
                          ),
                          child: Text(
                            context.l10n.manageProfileTabsSheetActiveKey,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                              color: tokens.textDim,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!viewOnly) ...[
                  _RowIconButton(
                    icon: Icons.edit_rounded,
                    color: tokens.starkWhite,
                    onTap: () => _renameInboxTab(entry),
                  ),
                  const SizedBox(width: 4),
                  _RowIconButton(
                    icon: Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () => _deleteInboxTab(entry),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RowIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
