import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';

/// Nodes — PoA consensus node management. Port of publicos_client's
/// `node_screen.dart` (1271 lines) reskinned to the glass theme. Logic
/// verbatim — every Core call (`nodeRegistryMemoryContract.getNodeCount /
/// getAllNodes / getAccountAddressByNode / getNodeLabel`, `nodeRegistry
/// ManagerContract.getAllAccountNodes$2 / registerNode / updateNodeLabel /
/// removeNode`) is copied without changes.
class NodePage extends StatefulWidget {
  const NodePage({super.key});

  @override
  State<NodePage> createState() => _NodePageState();
}

class _NodePageState extends State<NodePage> {
  bool _isLoading = true;

  List<EthereumAddress> _myNodeAddresses = [];
  List<String> _myNodeLabels = [];

  BigInt _totalNodeCount = BigInt.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final addrHex = PublicOS.myPublicosAddress;
      if (addrHex == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final accountAddr = EthereumAddress.fromHex(addrHex);

      final nodeMem = PublicOSBsp.nodeRegistryMemoryContract;
      final nodeMgr = PublicOSBsp.nodeRegistryManagerContract;

      final count = await nodeMem.getNodeCount();
      final myNodes = await nodeMgr.getAllAccountNodes(
        (accountAddress: accountAddr),
      );

      if (mounted) {
        setState(() {
          _totalNodeCount = count;
          _myNodeAddresses = myNodes.nodeAddresses;
          _myNodeLabels = myNodes.labels;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemAppScaffold(
      // DESKTOP DELTA: centre in a 720px column instead of
      // stretching to the window edge — same width as `settings_pane`.
      maxContentWidth: 720,
      // DESKTOP DELTA: the body's RefreshIndicator is a PULL
      // gesture — a mouse cannot trigger it, so without this button the page
      // has no way to refresh at all. Mirrors the refresh action bsp_dialog
      // already uses (`bsp_dialog.dart:418`).
      actions: [
        Builder(
          builder: (context) => IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded,
                size: 19, color: GlassTokens.of(context).textDim),
            onPressed: () => _loadData(silent: true),
          ),
        ),
      ],
      title: context.l10n.nodePageTitle,
      icon: Icons.hub_rounded,
      pinHeader: true,
      builder: (context, scrollController, tokens) {
        return Stack(
          children: [
            if (!_isLoading)
              RefreshIndicator(
                onRefresh: () => _loadData(silent: true),
                color: tokens.starkWhite,
                backgroundColor: tokens.surfaceElevated,
                edgeOffset:
                    MediaQuery.of(context).padding.top + kToolbarHeight,
                child: _buildLoaded(scrollController, tokens),
              ),
            if (_isLoading)
              const Positioned(
                right: 16,
                bottom: 16,
                child: SafeArea(
                  child: PhigitalLoadingWidget(size: 28, showShadows: false),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLoaded(ScrollController c, GlassTokens tokens) {
    return ListView(
      controller: c,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        SizedBox(height: kToolbarHeight + 60),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: _buildSignersExplainer(tokens),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: _buildDirectorySection(tokens),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: _buildMyNodesSection(tokens),
        ),
      ],
    );
  }

  Widget _buildMyNodesSection(GlassTokens tokens) {
    final hasNodes = _myNodeAddresses.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(tokens, Icons.hub_rounded, context.l10n.nodePageMyNodes),
        const SizedBox(height: 14),
        if (!hasNodes)
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: tokens.fallbackAccent,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.nodePageNotSigner,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: List.generate(_myNodeAddresses.length, (i) {
              final addr = _myNodeAddresses[i];
              final label = _myNodeLabels[i];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == _myNodeAddresses.length - 1 ? 0 : 10,
                ),
                child: _MyNodeRow(
                  tokens: tokens,
                  address: addr,
                  label: label,
                  onTap: () => _showManageNodeSheet(addr, label),
                ),
              );
            }),
          ),
      ],
    );
  }

  Widget _buildDirectorySection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.explore_rounded,
          context.l10n.nodePageNodeDirectory,
          trailing: _pillBadge(
            tokens,
            '$_totalNodeCount',
            tokens.connectedAccent,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.nodePageDirectoryDescription,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        SystemAppActionButton(
          label: context.l10n.nodePageBrowseNodes,
          icon: Icons.list_rounded,
          onTap: _showNodeDirectorySheet,
        ),
      ],
    );
  }

  Widget _buildSignersExplainer(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.connectedAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.connectedAccent.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 20,
                  color: tokens.connectedAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.nodePageNotariesTitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.nodePageNotariesBody1,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.nodePageNotariesBody2,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.how_to_vote_rounded,
                size: 15,
                color: tokens.connectedAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.nodePageAdmittedByGovernance,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.connectedAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Section helpers.
  // ──────────────────────────────────────────────────────────────────────

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

  Widget _pillBadge(GlassTokens tokens, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: color,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Sheets
  // ──────────────────────────────────────────────────────────────────────

  void _showNodeDirectorySheet() {
    showGlassSheetDialog(
      context: context,
      width: DialogWidth.l,
      builder: (_) => _NodeDirectorySheet(totalCount: _totalNodeCount),
    );
  }

  void _showManageNodeSheet(EthereumAddress address, String label) {
    showGlassSheetDialog(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _ManageNodeSheet(
        nodeAddress: address,
        label: label,
        onChanged: _loadData,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// My-node row
// ═══════════════════════════════════════════════════════════════════════════

class _MyNodeRow extends StatelessWidget {
  final GlassTokens tokens;
  final EthereumAddress address;
  final String label;
  final VoidCallback onTap;

  const _MyNodeRow({
    required this.tokens,
    required this.address,
    required this.label,
    required this.onTap,
  });

  String _truncate(EthereumAddress a) {
    final hex = a.eip55With0x;
    if (hex.length <= 10) return hex;
    return '${hex.substring(0, 6)}...${hex.substring(hex.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tokens.glassFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.connectedAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.hub_rounded,
                  size: 18,
                  color: tokens.connectedAccent,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _truncate(address),
                      style: TextStyle(
                    fontFamily: 'monospace',
                        color: tokens.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: tokens.textDim,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Node directory sheet — paginated
// ═══════════════════════════════════════════════════════════════════════════

class _NodeEntry {
  final EthereumAddress nodeAddress;
  final EthereumAddress ownerAddress;
  final String label;
  Contact? ownerContact;

  _NodeEntry({
    required this.nodeAddress,
    required this.ownerAddress,
    required this.label,
  });
}

class _NodeDirectorySheet extends StatefulWidget {
  final BigInt totalCount;
  const _NodeDirectorySheet({required this.totalCount});

  @override
  State<_NodeDirectorySheet> createState() => _NodeDirectorySheetState();
}

class _NodeDirectorySheetState extends State<_NodeDirectorySheet> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  List<_NodeEntry> _nodes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _nodes = [];
      _offset = 0;
      _hasMore = true;
    });

    try {
      final nodeMem = PublicOSBsp.nodeRegistryMemoryContract;
      final nodeAddresses = await nodeMem.getAllNodes$2(
        (offset: BigInt.zero, limit: BigInt.from(_pageSize)),
      );
      if (!mounted) return;

      if (nodeAddresses.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      final entries = await _resolveEntries(nodeAddresses);
      if (!mounted) return;

      setState(() {
        _nodes = entries;
        _offset = nodeAddresses.length;
        _hasMore = nodeAddresses.length == _pageSize;
        _isLoading = false;
      });

      _resolveOwnerContacts(entries);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final nodeMem = PublicOSBsp.nodeRegistryMemoryContract;
      final nodeAddresses = await nodeMem.getAllNodes$2(
        (offset: BigInt.from(_offset), limit: BigInt.from(_pageSize)),
      );
      if (!mounted) return;

      if (nodeAddresses.isEmpty) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
        return;
      }

      final entries = await _resolveEntries(nodeAddresses);
      if (!mounted) return;

      setState(() {
        _nodes.addAll(entries);
        _offset = _offset + nodeAddresses.length;
        _hasMore = nodeAddresses.length >= _pageSize;
        _isLoadingMore = false;
      });

      _resolveOwnerContacts(entries);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<List<_NodeEntry>> _resolveEntries(
    List<EthereumAddress> addresses,
  ) async {
    final nodeMem = PublicOSBsp.nodeRegistryMemoryContract;
    final entries = <_NodeEntry>[];

    for (final nodeAddr in addresses) {
      try {
        final ownerAddr = await nodeMem.getAccountAddressByNode(
          (nodeAddress: nodeAddr),
        );
        final label = await nodeMem.getNodeLabel(
          (accountAddress: ownerAddr, nodeAddress: nodeAddr),
        );
        entries.add(_NodeEntry(
          nodeAddress: nodeAddr,
          ownerAddress: ownerAddr,
          label: label,
        ));
      } catch (_) {}
    }
    return entries;
  }

  Future<void> _resolveOwnerContacts(List<_NodeEntry> entries) async {
    for (final entry in entries) {
      try {
        final contact = await PublicOSContacts.searchContacts(
          entry.ownerAddress.eip55With0x,
        );
        if (!mounted) return;
        if (contact != null) {
          setState(() => entry.ownerContact = contact);
        }
      } catch (_) {}
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  String _truncateAddress(EthereumAddress addr) {
    final hex = addr.eip55With0x;
    if (hex.length <= 10) return hex;
    return '${hex.substring(0, 6)}...${hex.substring(hex.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (ctx, sheetController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _SheetHeader(
                  tokens: tokens,
                  title: context.l10n.nodePageNodeDirectory,
                  subtitle: context.l10n.nodePagePoaSubtitle,
                  trailing: Icon(
                    Icons.hub_outlined,
                    color: tokens.connectedAccent,
                    size: 22,
                  ),
                ),
                Expanded(child: _buildContent(tokens, sheetController)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(GlassTokens tokens, ScrollController sheetController) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: tokens.starkWhite,
          strokeWidth: 2,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: tokens.fallbackAccent,
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.nodePageFailedToLoad,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadInitialPage,
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: tokens.connectedAccent,
                ),
                label: Text(
                  context.l10n.actionRetry,
                  style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                    color: tokens.connectedAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_nodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hub_outlined,
                size: 48,
                color: tokens.textDim,
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.nodePageNoNodes,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _nodes.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _nodes.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: tokens.starkWhite,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final entry = _nodes[index];
          return _DirectoryNodeRow(
            tokens: tokens,
            entry: entry,
            truncate: _truncateAddress,
          );
        },
      ),
    );
  }
}

class _DirectoryNodeRow extends StatelessWidget {
  final GlassTokens tokens;
  final _NodeEntry entry;
  final String Function(EthereumAddress) truncate;

  const _DirectoryNodeRow({
    required this.tokens,
    required this.entry,
    required this.truncate,
  });

  @override
  Widget build(BuildContext context) {
    final contact = entry.ownerContact;
    final displayName =
        contact?.displayName ?? truncate(entry.ownerAddress);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.label,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              truncate(entry.nodeAddress),
              style: TextStyle(
                    fontFamily: 'monospace',
                color: tokens.textDim,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.nodePageRunBy,
                  style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 11,
                  ),
                ),
                if (contact != null) ...[
                  GlassContactIcon(
                    contact: contact,
                    address: entry.ownerAddress.eip55With0x,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                ] else ...[
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: tokens.textDim,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    displayName,
                    style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                      color: tokens.connectedAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ═══════════════════════════════════════════════════════════════════════════
// Manage node sheet — edit label + remove
// ═══════════════════════════════════════════════════════════════════════════

class _ManageNodeSheet extends StatefulWidget {
  final EthereumAddress nodeAddress;
  final String label;
  final VoidCallback? onChanged;

  const _ManageNodeSheet({
    required this.nodeAddress,
    required this.label,
    this.onChanged,
  });

  @override
  State<_ManageNodeSheet> createState() => _ManageNodeSheetState();
}

class _ManageNodeSheetState extends State<_ManageNodeSheet> {
  bool _isEditingLabel = false;
  bool _isSavingLabel = false;
  late final TextEditingController _labelController;
  late String _currentLabel;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _currentLabel = widget.label;
    _labelController = TextEditingController(text: _currentLabel);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _startEditingLabel() {
    setState(() {
      _isEditingLabel = true;
      _labelController.text = _currentLabel;
    });
  }

  void _cancelEditingLabel() {
    setState(() => _isEditingLabel = false);
  }

  Future<void> _saveLabel() async {
    final newLabel = _labelController.text.trim();
    if (newLabel.isEmpty || newLabel == _currentLabel) {
      setState(() => _isEditingLabel = false);
      return;
    }
    setState(() => _isSavingLabel = true);

    try {
      final credentials = PublicOS.currentBlockchainPrivateKey!;
      await PublicOSBsp.nodeRegistryManagerContract.updateNodeLabel(
        (nodeAddress: widget.nodeAddress, newLabel: newLabel),
        credentials: credentials,
      );
      if (!mounted) return;
      setState(() {
        _currentLabel = newLabel;
        _isEditingLabel = false;
        _isSavingLabel = false;
      });
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingLabel = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(context.l10n, e))),
      );
    }
  }

  Future<void> _showRemoveConfirmation() async {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(
          l10n.nodePageRemoveNodeTitle,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          l10n.nodePageRemoveNodeBody(widget.nodeAddress.eip55With0x),
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.dlgCancel,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.textDim),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.nodePageRemove,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',color: tokens.fallbackAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _removeNode();
    }
  }

  Future<void> _removeNode() async {
    setState(() => _isRemoving = true);
    try {
      final credentials = PublicOS.currentBlockchainPrivateKey!;
      await PublicOSBsp.nodeRegistryManagerContract.removeNode(
        (nodeAddress: widget.nodeAddress),
        credentials: credentials,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.nodePageNodeRemoved)),
      );
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRemoving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizedError(context.l10n, e))),
      );
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
      builder: (ctx, sheetController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _SheetHeader(
                  tokens: tokens,
                  title: context.l10n.nodePageManageNode,
                  subtitle: null,
                  trailing: Icon(
                    Icons.settings_rounded,
                    color: tokens.connectedAccent,
                    size: 22,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: sheetController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.nodePageAddress,
                          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                            color: tokens.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.nodeAddress.eip55With0x,
                          style: TextStyle(
                    fontFamily: 'monospace',
                            color: tokens.starkWhite,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildLabelSection(tokens),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: _isRemoving
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: tokens.fallbackAccent,
                                    strokeWidth: 2,
                                  ),
                                )
                              : OutlinedButton.icon(
                                  onPressed: _showRemoveConfirmation,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: tokens.fallbackAccent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: tokens.fallbackAccent
                                          .withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.delete_forever_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    context.l10n.nodePageRemoveNodeButton,
                                    style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelSection(GlassTokens tokens) {
    if (_isEditingLabel) {
      return Row(
        children: [
          Expanded(
            child: _GlassField(
              tokens: tokens,
              controller: _labelController,
              label: context.l10n.nodePageLabelField,
              enabled: !_isSavingLabel,
              onSubmitted: (_) => _saveLabel(),
            ),
          ),
          const SizedBox(width: 8),
          if (_isSavingLabel)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: tokens.connectedAccent,
                strokeWidth: 2,
              ),
            )
          else ...[
            IconButton(
              onPressed: _saveLabel,
              icon: Icon(
                Icons.check_rounded,
                color: tokens.connectedAccent,
              ),
              tooltip: context.l10n.nodePageSave,
            ),
            IconButton(
              onPressed: _cancelEditingLabel,
              icon: Icon(
                Icons.close_rounded,
                color: tokens.textDim,
              ),
              tooltip: context.l10n.dlgCancel,
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.nodePageLabelUpper,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentLabel,
                style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _startEditingLabel,
          icon: Icon(
            Icons.edit_outlined,
            color: tokens.connectedAccent,
          ),
          tooltip: context.l10n.nodePageEditLabel,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared sheet chrome helpers
// ═══════════════════════════════════════════════════════════════════════════

class _SheetHeader extends StatelessWidget {
  final GlassTokens tokens;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SheetHeader({
    required this.tokens,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final GlassTokens tokens;
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const _GlassField({
    required this.tokens,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
              fontFamily: 'SpaceGrotesk',
        color: enabled ? tokens.starkWhite : tokens.textDim,
        fontSize: 14,
      ),
      cursorColor: tokens.starkWhite,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
          color: tokens.textDim.withValues(alpha: 0.6),
          fontSize: 13,
        ),
        helperStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
          fontSize: 11,
        ),
        filled: true,
        fillColor: tokens.glassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: tokens.connectedAccent,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: tokens.borderSubtle.withValues(alpha: 0.5),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: tokens.fallbackAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: tokens.fallbackAccent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
