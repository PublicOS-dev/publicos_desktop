import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/account_resolve_field.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/screens/channel_settings_page.dart';
import 'package:publicos_desktop/screens/create_channel_page.dart';
import 'package:publicos_desktop/screens/manage_files_page.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Single canonical "manage everything about your relationship with this
/// feed server" page. Reached from two entry points:
///   1. Feeds left drawer → "Manage server" row
///   2. SSP page Subscription section → "MANAGE SERVER" button
///
/// Both push via [CupertinoPageRoute] so the slide-from-right + iOS
/// edge-swipe-back are consistent with Treasury / BSP / SSP / Browser.
///
/// Six sections, each via [_sectionHeader] (no outer card):
///   1. Identity (read-only) — server label + URL + SSP/CUSTOM pill
///   2. Author profile — display_name / bio / avatar_url editable; the
///      shape readers see in non-PublicOS RSS clients
///   3. Media — quota bar + a "Manage files" button; the file list itself
///      is its own screen, [ManageFilesPage]
///   4. Channels — list, per-row tap → ManageChannelPage; create →
///      CreateChannelPage (both reused, no duplicated edit logic)
///   5. Posters whitelist (account-wide)
///   6. Bans (account-wide)
class ManageServerPage extends StatefulWidget {
  final String serverUrl;
  final String serverLabel;
  final bool isSSP;
  final String? sspSlug;

  const ManageServerPage({
    super.key,
    required this.serverUrl,
    required this.serverLabel,
    required this.isSSP,
    this.sspSlug,
  });

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  bool _loading = true;
  String? _error;

  // Loaded data
  FeedAccount? _account;
  List<Channel> _channels = const [];
  MediaListResponse? _media;
  PediaListResponse? _pedia;
  List<BanEntry> _bans = const [];
  List<String> _existingTabUrls = const [];

  // Author form
  late final TextEditingController _displayNameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _avatarUrlCtrl;
  bool _savingAuthor = false;
  String? _authorError;

  // Moderation form
  final TextEditingController _addBanAddrCtrl = TextEditingController();
  final TextEditingController _addBanReasonCtrl = TextEditingController();
  bool _addingBan = false;

  // Per-row busy sets — keyed by stable id so concurrent ops don't blink
  final Set<int> _busyChannelIds = {};
  final Set<String> _busyAddresses = {};

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _avatarUrlCtrl = TextEditingController();
    // Trigger rebuild so the SAVE button enables/disables as the user types
    _displayNameCtrl.addListener(_onAuthorFieldChanged);
    _bioCtrl.addListener(_onAuthorFieldChanged);
    _avatarUrlCtrl.addListener(_onAuthorFieldChanged);
    _loadData();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _avatarUrlCtrl.dispose();
    _addBanAddrCtrl.dispose();
    _addBanReasonCtrl.dispose();
    super.dispose();
  }

  void _onAuthorFieldChanged() {
    if (mounted) setState(() {});
  }

  // ── Load ────────────────────────────────────────────────────────────────

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      if (!mounted) return;
      setState(() => _loading = true);
    }
    try {
      final myAddress = PublicOS.myPublicosAddress;
      if (myAddress == null) {
        if (mounted) {
          setState(() {
            if (!silent) _loading = false;
            _error = context.l10n.manageServerPageNoActiveAccount;
          });
        }
        return;
      }
      final results = await Future.wait([
        PublicOSChannels.getChannelsByAddress(
          myAddress,
          serverAddress: widget.serverUrl,
        ),
        PublicOSSsp.listMedia(serverAddress: widget.serverUrl),
        PublicOSChannels.listAccountBans(serverAddress: widget.serverUrl),
        _loadExistingTabUrls(),
        PublicOSSsp.listPedia(serverAddress: widget.serverUrl),
      ]);

      if (!mounted) return;

      final channelsResp = results[0] as FeedServerApiResponse<
          ({List<Channel> channels, FeedAccount? account})>;
      final mediaResp =
          results[1] as FeedServerApiResponse<MediaListResponse>;
      final bansResp = results[2] as FeedServerApiResponse<List<BanEntry>>;
      final pediaResp =
          results[4] as FeedServerApiResponse<PediaListResponse>;

      setState(() {
        _channels = channelsResp.success && channelsResp.data != null
            ? channelsResp.data!.channels
            : const [];
        _account = channelsResp.success ? channelsResp.data?.account : null;
        _media = mediaResp.success ? mediaResp.data : null;
        _pedia = pediaResp.success ? pediaResp.data : null;
        _bans = bansResp.success ? (bansResp.data ?? const []) : const [];
        _syncAuthorControllersFromAccount();
        if (!silent) _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) _loading = false;
        _error = localizedError(context.l10n, e);
      });
    }
  }

  Future<void> _loadExistingTabUrls() async {
    try {
      final records =
          await PublicOSContacts.getRecordsByType(RecordType.router);
      final urls = records
          .where((r) => r.routerSubtype == RouterSubtype.channel)
          .map((r) => r.value)
          .toList();
      if (mounted) setState(() => _existingTabUrls = urls);
    } catch (_) {}
  }

  void _syncAuthorControllersFromAccount() {
    final a = _account;
    if (a == null) return;
    if (_displayNameCtrl.text != a.displayName) {
      _displayNameCtrl.text = a.displayName;
    }
    if (_bioCtrl.text != a.bio) {
      _bioCtrl.text = a.bio;
    }
    if (_avatarUrlCtrl.text != a.avatarUrl) {
      _avatarUrlCtrl.text = a.avatarUrl;
    }
  }

  bool get _authorDirty {
    final a = _account;
    if (a == null) return false;
    return _displayNameCtrl.text != a.displayName ||
        _bioCtrl.text != a.bio ||
        _avatarUrlCtrl.text != a.avatarUrl;
  }

  // ── Author save ─────────────────────────────────────────────────────────

  Future<void> _saveAuthorProfile() async {
    if (!_authorDirty || _savingAuthor) return;
    setState(() {
      _savingAuthor = true;
      _authorError = null;
    });
    try {
      final response = await PublicOSChannels.updateFeedAccount(
        displayName: _displayNameCtrl.text,
        bio: _bioCtrl.text,
        avatarUrl: _avatarUrlCtrl.text,
        serverAddress: widget.serverUrl,
      );
      if (!mounted) return;
      if (response.success) {
        _snack(context.l10n.manageServerPageAuthorUpdated);
        await _loadData(silent: true);
      } else {
        setState(() {
          _authorError = response.error?['message']?.toString() ??
              context.l10n.manageServerPageAuthorUpdateFailed;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _authorError = localizedError(context.l10n, e));
      }
    } finally {
      if (mounted) setState(() => _savingAuthor = false);
    }
  }

  // ── Channels ────────────────────────────────────────────────────────────

  String _channelJsonUrl(Channel channel) {
    final addr = PublicOS.myPublicosAddress ?? '';
    return '${widget.serverUrl}/api/$addr/channels/${channel.slug}/json';
  }

  Future<void> _addChannelAsTab(Channel channel) async {
    if (_busyChannelIds.contains(channel.id)) return;
    setState(() => _busyChannelIds.add(channel.id));
    try {
      final url = _channelJsonUrl(channel);
      final record = Record.asRouter(
        key: 'rss.${channel.slug}',
        routerSubtype: RouterSubtype.channel,
        value: url,
        name: channel.name,
        expiration: DateTime.now().add(const Duration(days: 365)),
      );
      final ok = await PublicOSContacts.setRecord(record);
      if (ok && mounted) await _loadExistingTabUrls();
    } finally {
      if (mounted) setState(() => _busyChannelIds.remove(channel.id));
    }
  }

  Future<void> _removeChannelFromTabs(Channel channel) async {
    if (_busyChannelIds.contains(channel.id)) return;
    setState(() => _busyChannelIds.add(channel.id));
    try {
      final url = _channelJsonUrl(channel);
      final records =
          await PublicOSContacts.getRecordsByType(RecordType.router);
      final tab = records.firstWhere(
        (r) => r.routerSubtype == RouterSubtype.channel && r.value == url,
        orElse: () => throw StateError('Tab not found'),
      );
      final ok = await PublicOSContacts.deleteRecord(tab.key);
      if (ok && mounted) await _loadExistingTabUrls();
    } catch (_) {
      // Silent — most likely the record was already gone.
    } finally {
      if (mounted) setState(() => _busyChannelIds.remove(channel.id));
    }
  }

  Future<void> _copyChannelUrl(Channel channel) async {
    final url = _channelJsonUrl(channel);
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: url));
    _snack(l10n.manageServerPageCopied(url));
  }

  Future<void> _editChannel(Channel channel) async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ChannelSettingsPage(channel: channel),
      ),
    );
    if (mounted) await _loadData(silent: true);
  }

  Future<void> _createChannel() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => const CreateChannelPage(),
      ),
    );
    if (mounted) await _loadData(silent: true);
  }

  /// Opens the file library. The quota bar is re-read on return: files may
  /// have been deleted there.
  Future<void> _openManageFiles() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ManageFilesPage(serverUrl: widget.serverUrl),
      ),
    );
    if (mounted) await _loadData(silent: true);
  }

  Future<void> _deleteChannel(Channel channel) async {
    final l10n = context.l10n;
    final confirm = await _confirm(
      title: l10n.manageServerPageDeleteChannelTitle,
      body: l10n.manageServerPageDeleteChannelBody(channel.name),
      destructive: true,
    );
    if (confirm != true || !mounted) return;
    setState(() => _busyChannelIds.add(channel.id));
    try {
      final response = await PublicOSChannels.deleteChannel(
        slug: channel.slug,
        serverAddress: widget.serverUrl,
      );
      if (!mounted) return;
      if (response.success) {
        _snack(l10n.manageServerPageDeletedNamed(channel.name));
        await _loadData(silent: true);
      } else {
        _snack(response.error?['message']?.toString() ??
            l10n.manageServerPageDeleteFailed);
      }
    } finally {
      if (mounted) setState(() => _busyChannelIds.remove(channel.id));
    }
  }

  // ── Bans ────────────────────────────────────────────────────────────────

  Future<void> _addBan() async {
    final addr = _addBanAddrCtrl.text.trim();
    final reason = _addBanReasonCtrl.text.trim();
    if (addr.isEmpty || _addingBan) return;
    final l10n = context.l10n;
    setState(() => _addingBan = true);
    // Username → account address; raw 0x input passes through untouched.
    final resolved = await resolveAccountInput(addr);
    if (!mounted) return;
    if (resolved == null) {
      setState(() => _addingBan = false);
      _snack(l10n.accountResolveNoMatch);
      return;
    }
    try {
      final response = await PublicOSChannels.addAccountBan(
        address: resolved,
        reason: reason.isNotEmpty ? reason : null,
        serverAddress: widget.serverUrl,
      );
      if (!mounted) return;
      if (response.success) {
        _addBanAddrCtrl.clear();
        _addBanReasonCtrl.clear();
        await _loadData(silent: true);
      } else {
        _snack(response.error?['message']?.toString() ??
            l10n.manageServerPageBanFailed);
      }
    } finally {
      if (mounted) setState(() => _addingBan = false);
    }
  }

  Future<void> _removeBan(String address) async {
    if (_busyAddresses.contains(address)) return;
    final l10n = context.l10n;
    setState(() => _busyAddresses.add(address));
    try {
      final response = await PublicOSChannels.removeAccountBan(
        address: address,
        serverAddress: widget.serverUrl,
      );
      if (!mounted) return;
      if (response.success) {
        await _loadData(silent: true);
      } else {
        _snack(response.error?['message']?.toString() ??
            l10n.manageServerPageUnbanFailed);
      }
    } finally {
      if (mounted) setState(() => _busyAddresses.remove(address));
    }
  }

  // ── Misc helpers ────────────────────────────────────────────────────────

  String _truncAddr(String a) =>
      a.length <= 10 ? a : '${a.substring(0, 6)}…${a.substring(a.length - 4)}';

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    bool destructive = false,
  }) {
    final tokens = GlassTokens.of(context);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        backgroundColor: tokens.surfaceDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.borderSubtle),
        ),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dlgCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: destructive
                  ? Theme.of(ctx).colorScheme.error
                  : tokens.connectedAccent,
            ),
            child: Text(destructive
                ? context.l10n.manageServerPageDelete
                : context.l10n.manageServerPageConfirm),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SystemAppScaffold(
      title: context.l10n.manageServerPageTitle,
      icon: Icons.dns_rounded,
      pinHeader: true,
      builder: (context, scrollController, tokens) {
        return Stack(
          children: [
            if (!_loading)
              RefreshIndicator(
                onRefresh: () => _loadData(silent: true),
                color: tokens.starkWhite,
                backgroundColor: tokens.surfaceElevated,
                edgeOffset:
                    MediaQuery.of(context).padding.top + kToolbarHeight,
                child: _buildLoaded(scrollController, tokens),
              ),
            if (_loading)
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
        const SizedBox(height: kToolbarHeight + 60),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: _buildIdentitySection(tokens),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: _buildAuthorSection(tokens),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: _buildMediaSection(tokens),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          child: _buildChannelsSection(tokens),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: _buildBansSection(tokens),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: _errorBanner(tokens, _error!),
          ),
      ],
    );
  }

  // ── Section: Identity ───────────────────────────────────────────────────

  Widget _buildIdentitySection(GlassTokens tokens) {
    final pillColor =
        widget.isSSP ? tokens.connectedAccent : tokens.starkWhite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          widget.isSSP ? Icons.verified_rounded : Icons.storage_rounded,
          context.l10n.manageServerPageIdentity,
          trailing: _pillBadge(
            tokens,
            widget.isSSP ? 'SSP' : context.l10n.manageServerPageCustomPill,
            pillColor,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.isSSP
              ? context.l10n.manageServerPageIdentityDescSsp
              : context.l10n.manageServerPageIdentityDescCustom,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _kvRow(tokens, context.l10n.manageServerPageLabel, widget.serverLabel),
        const SizedBox(height: 4),
        _kvRow(tokens, context.l10n.manageServerPageUrl, widget.serverUrl),
        if (widget.isSSP && widget.sspSlug != null) ...[
          const SizedBox(height: 4),
          _kvRow(tokens, context.l10n.manageServerPageSlug, widget.sspSlug!),
        ],
      ],
    );
  }

  // ── Section: Author profile ─────────────────────────────────────────────

  Widget _buildAuthorSection(GlassTokens tokens) {
    final account = _account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.person_outline_rounded,
          context.l10n.manageServerPageAuthorProfile,
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.manageServerPageAuthorDesc,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        if (account != null) ...[
          _kvRow(tokens, context.l10n.manageServerPageHandle,
              '@${account.username}'),
          const SizedBox(height: 4),
          _kvRow(
            tokens,
            context.l10n.manageServerPageNote,
            context.l10n.manageServerPageHandleNote,
          ),
          const SizedBox(height: 16),
        ],
        _glassField(
          tokens,
          controller: _displayNameCtrl,
          label: context.l10n.manageServerPageDisplayName,
          hint: context.l10n.manageServerPageDisplayNameHint,
        ),
        const SizedBox(height: 12),
        _glassField(
          tokens,
          controller: _bioCtrl,
          label: context.l10n.manageServerPageBio,
          hint: context.l10n.manageServerPageBioHint,
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _glassField(
          tokens,
          controller: _avatarUrlCtrl,
          label: context.l10n.manageServerPageAvatarUrl,
          hint: 'https://…',
        ),
        if (_authorError != null) ...[
          const SizedBox(height: 12),
          _inlineError(tokens, _authorError!, () {
            setState(() => _authorError = null);
          }),
        ],
        const SizedBox(height: 14),
        SystemAppActionButton(
          label: _savingAuthor
              ? context.l10n.manageServerPageSaving
              : context.l10n.manageServerPageSaveAuthorProfile,
          icon: Icons.save_outlined,
          onTap: (_authorDirty && !_savingAuthor) ? _saveAuthorProfile : null,
        ),
      ],
    );
  }

  // ── Section: Media ──────────────────────────────────────────────────────

  Widget _buildMediaSection(GlassTokens tokens) {
    final listedFiles =
        (_media?.files.length ?? 0) + (_pedia?.files.length ?? 0);
    final usageMB = (_media?.quota.usedMb ?? 0).toDouble();
    final quotaMB = (_media?.quota.totalMb ?? 0).toDouble();
    final fileCount = _media?.quota.fileCount ?? 0;
    final maxFiles = _media?.quota.maxFiles ?? -1;
    final usageRatio = quotaMB > 0 ? (usageMB / quotaMB).clamp(0.0, 1.0) : 0.0;
    final overFiles = maxFiles > 0 && fileCount >= maxFiles;
    final overSize = quotaMB > 0 && usageRatio >= 1.0;
    final barColor = (usageRatio >= 0.9 || overSize)
        ? tokens.fallbackAccent
        : tokens.connectedAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.perm_media_outlined,
          context.l10n.manageServerPageMedia,
          trailing: _pillBadge(
            tokens,
            context.l10n.manageServerPageFilesPill(listedFiles),
            tokens.starkWhite,
          ),
        ),
        const SizedBox(height: 14),
        // Quota bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              quotaMB > 0
                  ? context.l10n.manageServerPageQuotaUsed(
                      usageMB.toStringAsFixed(1),
                      quotaMB.toStringAsFixed(0),
                    )
                  : context.l10n.manageServerPageQuotaUsedNoTotal(
                      usageMB.toStringAsFixed(1),
                    ),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
            Text(
              maxFiles > 0
                  ? context.l10n.manageServerPageFileCountWithMax(
                      fileCount, maxFiles)
                  : context.l10n.manageServerPageFileCount(fileCount),
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 11,
                color: tokens.textDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: usageRatio,
            minHeight: 6,
            backgroundColor: tokens.glassFill,
            color: barColor,
          ),
        ),
        if (overFiles || overSize) ...[
          const SizedBox(height: 8),
          Text(
            overFiles && overSize
                ? context.l10n.manageServerPageQuotaFullBoth
                : overFiles
                    ? context.l10n.manageServerPageFileCountLimit
                    : context.l10n.manageServerPageStorageQuotaFull,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              color: tokens.fallbackAccent,
            ),
          ),
        ],
        const SizedBox(height: 14),
        // The file list lives on its own screen (ManageFilesPage). Built here,
        // every row at once, a full library made this whole page unusable.
        SystemAppActionButton(
          label: context.l10n.manageServerPageManageFiles,
          icon: Icons.folder_open_rounded,
          onTap: _openManageFiles,
        ),
      ],
    );
  }

  // ── Section: Channels ───────────────────────────────────────────────────

  Widget _buildChannelsSection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.rss_feed_rounded,
          context.l10n.manageServerPageChannels,
          trailing: _pillBadge(
            tokens,
            '${_channels.length}',
            tokens.starkWhite,
          ),
        ),
        const SizedBox(height: 14),
        if (_channels.isEmpty)
          _emptyHint(tokens, context.l10n.manageServerPageNoChannels)
        else
          ..._channels.map((c) => _buildChannelRow(tokens, c)),
        const SizedBox(height: 14),
        SystemAppActionButton(
          label: context.l10n.manageServerPageCreateChannel,
          icon: Icons.add_rounded,
          onTap: _createChannel,
        ),
      ],
    );
  }

  Widget _buildChannelRow(GlassTokens tokens, Channel channel) {
    final isInTabs = _existingTabUrls.contains(_channelJsonUrl(channel));
    final busy = _busyChannelIds.contains(channel.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              channel.isCommunity
                  ? Icons.forum_outlined
                  : Icons.rss_feed_rounded,
              size: 18,
              color: tokens.connectedAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          channel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: tokens.starkWhite,
                          ),
                        ),
                      ),
                      if (channel.isPrivate) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_rounded,
                            size: 12, color: tokens.fallbackAccent),
                      ],
                      if (channel.requireRent) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.toll_outlined,
                            size: 12, color: tokens.textDim),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/${channel.slug}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: tokens.textDim,
                    ),
                  ),
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: PhigitalLoadingWidget(size: 16, showShadows: false),
              )
            else ...[
              _rowAction(
                tokens,
                icon: Icons.link_rounded,
                tooltip: context.l10n.manageServerPageCopyUrl,
                onTap: () => _copyChannelUrl(channel),
              ),
              _rowAction(
                tokens,
                icon: isInTabs ? Icons.tab_unselected : Icons.tab_rounded,
                tooltip: isInTabs
                    ? context.l10n.manageServerPageRemoveFromTabs
                    : context.l10n.manageServerPageAddAsTab,
                color: isInTabs
                    ? tokens.fallbackAccent
                    : tokens.connectedAccent,
                onTap: () => isInTabs
                    ? _removeChannelFromTabs(channel)
                    : _addChannelAsTab(channel),
              ),
              _rowAction(
                tokens,
                icon: Icons.settings_outlined,
                tooltip: context.l10n.manageServerPageSettings,
                onTap: () => _editChannel(channel),
              ),
              _rowAction(
                tokens,
                icon: Icons.delete_outline_rounded,
                tooltip: context.l10n.manageServerPageDelete,
                color: Theme.of(context).colorScheme.error,
                onTap: () => _deleteChannel(channel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section: Bans ───────────────────────────────────────────────────────

  Widget _buildBansSection(GlassTokens tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          tokens,
          Icons.block_rounded,
          context.l10n.manageServerPageBans,
          trailing: _pillBadge(
            tokens,
            '${_bans.length}',
            _bans.isEmpty ? tokens.starkWhite : tokens.fallbackAccent,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.l10n.manageServerPageBansDesc,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        AccountResolveField(
          controller: _addBanAddrCtrl,
          hint: context.l10n.manageServerPageAddressHint,
          dense: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _glassField(
                tokens,
                controller: _addBanReasonCtrl,
                label: '',
                hint: context.l10n.manageServerPageReasonHint,
                dense: true,
              ),
            ),
            const SizedBox(width: 8),
            _rowAction(
              tokens,
              icon: _addingBan
                  ? Icons.hourglass_top
                  : Icons.person_add_disabled_rounded,
              tooltip: context.l10n.manageServerPageBan,
              color: Theme.of(context).colorScheme.error,
              onTap: _addingBan ? null : _addBan,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_bans.isEmpty)
          _emptyHint(tokens, context.l10n.manageServerPageNoBans)
        else
          ..._bans.map((b) => _addressRow(
                tokens,
                address: b.address,
                subtitle: (b.reason ?? '').isNotEmpty ? b.reason : null,
                onRemove: () => _removeBan(b.address),
                removeIcon: Icons.undo_rounded,
                removeTooltip: context.l10n.manageServerPageUnban,
                removeColor: tokens.connectedAccent,
              )),
      ],
    );
  }

  // ── Reusable atoms ──────────────────────────────────────────────────────

  Widget _addressRow(
    GlassTokens tokens, {
    required String address,
    String? subtitle,
    required VoidCallback onRemove,
    required IconData removeIcon,
    required String removeTooltip,
    required Color removeColor,
  }) {
    final busy = _busyAddresses.contains(address);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncAddr(address),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        color: tokens.textDim,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: PhigitalLoadingWidget(size: 16, showShadows: false),
              )
            else
              _rowAction(
                tokens,
                icon: removeIcon,
                tooltip: removeTooltip,
                color: removeColor,
                onTap: onRemove,
              ),
          ],
        ),
      ),
    );
  }

  Widget _rowAction(
    GlassTokens tokens, {
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    Color? color,
  }) {
    final c = onTap == null ? tokens.textDim.withValues(alpha: 0.5) : (color ?? tokens.starkWhite);
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: c),
        ),
      ),
    );
  }

  Widget _glassField(
    GlassTokens tokens, {
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool monospace = false,
    bool dense = false,
  }) {
    final hasLabel = label.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasLabel) ...[
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: tokens.textDim,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          maxLines: maxLines,
          inputFormatters: monospace
              ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9x]'))]
              : null,
          style: TextStyle(
            fontFamily: monospace ? 'monospace' : 'SpaceGrotesk',
            fontSize: dense ? 12 : 13,
            color: tokens.starkWhite,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.surfaceElevated,
            hintText: hint,
            hintStyle: TextStyle(color: tokens.textDim, fontSize: dense ? 12 : 13),
            isDense: dense,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: dense ? 10 : 12,
            ),
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
              borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyHint(GlassTokens tokens, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            color: tokens.textDim,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _inlineError(GlassTokens tokens, String message, VoidCallback onClose) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 14, color: color),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(GlassTokens tokens, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.fallbackAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.fallbackAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: tokens.fallbackAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.fallbackAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Canonical helpers (mirror Treasury / SSP shape exactly) ─────────────

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

  Widget _kvRow(GlassTokens tokens, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: tokens.textDim,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: tokens.starkWhite,
            ),
          ),
        ),
      ],
    );
  }
}
