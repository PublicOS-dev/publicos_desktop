import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/widgets/feeds/member_list_editor.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/screens/manage_plans_page.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';

/// Channel settings — audience, then filter. A policy and its list are one
/// decision, so the moderation tabs and the edit form fold into one screen.
///
/// The design rules:
///   - Basics sit flat at the top (identity, not policy), with the Secret
///     listing toggle beside Language.
///   - Six accordion drawers, one open at a time. A closed drawer's hint IS
///     its verdict — there are no verdict boxes on the three gate drawers.
///   - Every gate asks the same two questions, and they AND: **audience**
///     (which set of people) then **filter** (what each of them must be).
///   - Lists are managed inline via the ONE list component
///     ([MemberListEditor]); the chevron on an option row opens the editor,
///     selecting the option never does.
///   - Changes apply immediately (one `updateChannel` per change) — this is
///     a settings screen, not a form with a Save button.
///
/// Vocabulary rules (server-capable, UI-hidden): the bare `account` tier is
/// never offered — "All PublicOS Accounts" SENDS `standing`. "No filter"
/// disappears the moment a read list is on, and the choice promotes to
/// Signed (the server normalises the same way on save — both ends agree).
class ChannelSettingsPage extends StatefulWidget {
  final Channel channel;

  /// Land with drawer 1's Private editor open, so the follow-request queue
  /// is on screen: a follow-request notification's tap.
  final bool openRequests;

  const ChannelSettingsPage({
    super.key,
    required this.channel,
    this.openRequests = false,
  });

  @override
  State<ChannelSettingsPage> createState() => _ChannelSettingsPageState();
}

class _ChannelSettingsPageState extends State<ChannelSettingsPage> {
  late Channel _channel = widget.channel;

  // -- The five lists + the request inbox -----------------------------------
  List<WhitelistEntry> _friends = const []; // account-wide whitelist
  List<WhitelistEntry> _channelList = const []; // this channel's whitelist
  List<WhitelistEntry> _customList = const []; // the interaction list
  List<PostPermissionEntry> _posters = const [];
  List<BanEntry> _bans = const [];
  List<FollowRequest> _requests = const [];
  bool _listsLoading = true;

  final Set<String> _friendsBusy = {};
  final Set<String> _channelListBusy = {};
  final Set<String> _customBusy = {};
  final Set<String> _postersBusy = {};
  final Set<String> _bansBusy = {};
  final Set<String> _requestsBusy = {};

  /// Which drawer is open (1..6, 0 = none). One at a time.
  int _openDrawer = 1;

  /// Which list editors are expanded. Selecting an option turns the source
  /// on; the chevron is what opens the editor.
  late final Set<String> _openEditors = {
    if (widget.openRequests) 'private',
  };

  /// Reactions follow comments unless the owner splits them. Initialized
  /// from the stored tiers so a channel that already diverges shows split.
  late bool _splitReact = _channel.reactionTier != _channel.commentTier;

  bool _saving = false;
  bool _deleting = false;

  late final TextEditingController _nameCtrl =
      TextEditingController(text: _channel.name);
  late final TextEditingController _descCtrl =
      TextEditingController(text: _channel.description);
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  static const Duration _requestsWindow = Duration(days: 14);

  String get _slug => _channel.slug;
  String? get _server => _channel.serverAddress;
  String get _ownerAddress =>
      _channel.ownerAddress ?? PublicOS.myPublicosAddress ?? '';

  @override
  void initState() {
    super.initState();
    // Inline basics fields commit on blur — the settings-screen equivalent
    // of pressing done. A mid-typing rebuild never writes.
    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _commitName();
    });
    _descFocus.addListener(() {
      if (!_descFocus.hasFocus) _commitDescription();
    });
    _loadLists();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  /// All six datasets in parallel; each failure leaves the others intact.
  Future<void> _loadLists() async {
    final results = await Future.wait([
      PublicOSChannels.listAccountWhitelist(serverAddress: _server)
          .then((r) => r.success ? (r.data ?? const <WhitelistEntry>[]) : null),
      PublicOSChannels.listWhitelist(slug: _slug, serverAddress: _server)
          .then((r) => r.success ? (r.data ?? const <WhitelistEntry>[]) : null),
      PublicOSChannels.listInteractionList(slug: _slug, serverAddress: _server)
          .then((r) => r.success ? (r.data ?? const <WhitelistEntry>[]) : null),
      PublicOSChannels.listPosters(slug: _slug, serverAddress: _server)
          .then((r) =>
              r.success ? (r.data ?? const <PostPermissionEntry>[]) : null),
      PublicOSChannels.listBans(slug: _slug, serverAddress: _server)
          .then((r) => r.success ? (r.data ?? const <BanEntry>[]) : null),
      PublicOSChannels.listFollowers(
        slug: _slug,
        serverAddress: _server,
        statuses: const ['pending', 'ignored'],
        startDate: DateTime.now().subtract(_requestsWindow),
      ).then((r) => r.success ? (r.data?.followRequests ?? const []) : null),
    ]);
    if (!mounted) return;
    setState(() {
      _listsLoading = false;
      if (results[0] != null) _friends = results[0] as List<WhitelistEntry>;
      if (results[1] != null) _channelList = results[1] as List<WhitelistEntry>;
      if (results[2] != null) _customList = results[2] as List<WhitelistEntry>;
      if (results[3] != null) {
        _posters = results[3] as List<PostPermissionEntry>;
      }
      if (results[4] != null) _bans = results[4] as List<BanEntry>;
      if (results[5] != null) _requests = results[5] as List<FollowRequest>;
    });
  }

  /// One channel-config write. The response carries the updated channel;
  /// server address / id never travel on the wire, so they're re-attached
  /// (dropping them would silently repoint every later call at the default
  /// server).
  Future<bool> _apply(
    Future<FeedServerApiResponse<Channel>> Function() call,
  ) async {
    setState(() => _saving = true);
    try {
      final r = await call();
      if (!mounted) return false;
      if (r.success && r.data != null) {
        setState(() {
          _channel = r.data!.copyWith(
            serverAddress: _channel.serverAddress,
            serverId: _channel.serverId,
            ownerAddress: _channel.ownerAddress,
            postCount: r.data!.postCount ?? _channel.postCount,
          );
          _saving = false;
        });
        return true;
      }
      handleWriteError(
        context,
        r.error ?? context.l10n.manageChannelPageUnknownError,
        fallbackMessage: r.error?['message']?.toString() ??
            context.l10n.manageChannelPageUnknownError,
      );
    } catch (e) {
      if (mounted) handleWriteError(context, e);
    }
    if (mounted) setState(() => _saving = false);
    return false;
  }

  // ---------------------------------------------------------------------------
  // Derived state — read everything through these, never the raw fields.
  // ---------------------------------------------------------------------------

  bool get _readFriendsOn => _channel.readUseFriends;
  bool get _readPrivateOn => _channel.readUseChannelList;
  bool get _readListed => _readFriendsOn || _readPrivateOn;

  /// The read filter as the UI vocabulary knows it. The bare `account` rung
  /// renders under its promoted name (standing); `anyone` with a list on
  /// renders as signed — the state the server would normalise to anyway.
  String get _readFilter {
    final t = _channel.readTier;
    if (t == GateTier.account) return GateTier.standing;
    if (_readListed && t == GateTier.anyone) return GateTier.signed;
    return t;
  }

  /// Writes offer only two rungs (standing / citizen) — the ladder's lower
  /// rungs are list membership there, not filter options.
  String _writeFilter(String tier) =>
      tier == GateTier.citizen ? GateTier.citizen : GateTier.standing;

  String get _postFilter => _writeFilter(_channel.postingTier);
  String get _talkFilter => _writeFilter(_channel.commentTier);
  String get _reactFilter => _writeFilter(_channel.reactionTier);

  /// Comments audience is ONE choice. `interact_use_channel_list` is
  /// server-capable but UI-hidden — a channel that only has it on renders
  /// as Anyone until the owner picks something here.
  String get _talkAudience => _channel.interactUseInteractionList
      ? 'own'
      : _channel.interactUseFriends
          ? 'friends'
          : 'all';

  int get _pendingRequests => _requests.where((r) => r.isPending).length;

  // ---------------------------------------------------------------------------
  // Config writes
  // ---------------------------------------------------------------------------

  void _toggleReadAudience({bool? friends, bool? private}) {
    final newFriends = friends ?? _readFriendsOn;
    final newPrivate = private ?? _readPrivateOn;
    // Turning a list on while "No filter" is selected promotes to Signed —
    // the list forces an envelope, so leaving `anyone` stored would only be
    // a state the server reinterprets (it normalises the same way on save).
    final promote =
        (newFriends || newPrivate) && _channel.readTier == GateTier.anyone;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          readUseFriends: friends,
          readUseChannelList: private,
          readIdentity: promote ? GateTier.signed : null,
          serverAddress: _server,
        ));
  }

  void _setReadFilter(String tier) {
    if (tier == _channel.readTier) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          readIdentity: tier,
          serverAddress: _server,
        ));
  }

  void _setPostingPolicy(String policy) {
    if (policy == _channel.postingPolicy) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          postingPolicy: policy,
          serverAddress: _server,
        ));
  }

  void _setPostFilter(String tier) {
    if (tier == _channel.postingIdentity) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          postingIdentity: tier,
          serverAddress: _server,
        ));
  }

  /// One radio choice maps onto the three server switches — mutually
  /// exclusive here even though the switches stay independent for API
  /// callers. Custom's tick-your-readers panel subsumes any union.
  void _setTalkAudience(String v) {
    if (v == _talkAudience) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          interactUseFriends: v == 'friends',
          interactUseInteractionList: v == 'own',
          interactUseChannelList: false,
          serverAddress: _server,
        ));
  }

  void _setTalkFilter(String tier) {
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          commentIdentity: tier,
          // Reactions follow comments unless split.
          reactionIdentity: _splitReact ? null : tier,
          serverAddress: _server,
        ));
  }

  void _setReactFilter(String tier) {
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          reactionIdentity: tier,
          serverAddress: _server,
        ));
  }

  void _toggleSplitReact() {
    if (_splitReact) {
      // Collapsing the split folds reactions back onto comments.
      setState(() => _splitReact = false);
      if (_channel.reactionTier != _channel.commentTier) {
        _apply(() => PublicOSChannels.updateChannel(
              slug: _slug,
              reactionIdentity: _channel.commentTier,
              serverAddress: _server,
            ));
      }
    } else {
      setState(() => _splitReact = true);
    }
  }

  /// Opens (true) or closes (false) one of the three PublicOS Feed v1
  /// interaction settings; the others are left alone.
  void _setInteractionPolicy({bool? quote, bool? repost, bool? reply}) {
    String? p(bool? open) => open == null ? null : (open ? 'open' : 'closed');
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          quotePolicy: p(quote),
          repostPolicy: p(repost),
          replyPolicy: p(reply),
          serverAddress: _server,
        ));
  }

  void _setSecret(bool v) {
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          secret: v,
          serverAddress: _server,
        ));
  }

  void _setLanguage(String tag) {
    if (tag == _channel.language) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          language: tag,
          serverAddress: _server,
        ));
  }

  void _commitName() {
    final v = _nameCtrl.text.trim();
    if (v.isEmpty || v == _channel.name) {
      _nameCtrl.text = _channel.name;
      return;
    }
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          name: v,
          serverAddress: _server,
        ));
  }

  void _commitDescription() {
    final v = _descCtrl.text.trim();
    if (v == _channel.description) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          description: v,
          serverAddress: _server,
        ));
  }

  Future<void> _editIcon() async {
    final url = await _promptText(
      title: context.l10n.chsIconTitle,
      initial: _channel.iconUrl ?? '',
      hint: 'https://…',
    );
    if (url == null) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          iconUrl: url,
          serverAddress: _server,
        ));
  }

  Future<void> _renameSlug() async {
    final raw = await _promptText(
      title: context.l10n.chsAddressTitle,
      initial: _slug,
      hint: 'my-channel',
      mono: true,
    );
    if (raw == null) return;
    final slug = _slugify(raw);
    if (slug.isEmpty || slug == _slug) return;
    await _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          newSlug: slug,
          serverAddress: _server,
        ));
  }

  Future<void> _editRateLimit() async {
    final v = await _promptNumber(
      title: context.l10n.chsPostDailyLimit,
      current: _channel.postRateLimit,
    );
    if (v == null || v == _channel.postRateLimit) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          postRateLimit: v,
          serverAddress: _server,
        ));
  }

  Future<void> _editMaxPosts() async {
    final v = await _promptNumber(
      title: context.l10n.chsVisShowNewest,
      current: _channel.maxPosts ?? 0,
    );
    if (v == null || v == (_channel.maxPosts ?? 0)) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          maxPosts: v,
          serverAddress: _server,
        ));
  }

  Future<void> _editMaxDays() async {
    final v = await _promptNumber(
      title: context.l10n.chsVisHideOlder,
      current: _channel.maxDays ?? 0,
    );
    if (v == null || v == (_channel.maxDays ?? 0)) return;
    _apply(() => PublicOSChannels.updateChannel(
          slug: _slug,
          maxDays: v,
          serverAddress: _server,
        ));
  }

  String _slugify(String input) {
    final lower = input.trim().toLowerCase();
    final stripped = lower.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    final hyphenated = stripped.replaceAll(RegExp(r'[\s-]+'), '-');
    return hyphenated.replaceAll(RegExp(r'^-|-$'), '');
  }

  // ---------------------------------------------------------------------------
  // List writes — one handler pair per list, all through the ONE component.
  // ---------------------------------------------------------------------------

  Future<void> _listAdd(
    Set<String> busy,
    String address,
    Future<FeedServerApiResponse<void>> Function() call,
    Future<void> Function() reload,
  ) async {
    setState(() => busy.add(address.toLowerCase()));
    final r = await call();
    if (!mounted) return;
    setState(() => busy.remove(address.toLowerCase()));
    if (r.success) {
      await reload();
    } else {
      handleWriteError(context, r.error ?? context.l10n.chsFailAdd,
          fallbackMessage:
              r.error?['message']?.toString() ?? context.l10n.chsFailAdd);
    }
  }

  Future<void> _listRemove(
    Set<String> busy,
    String address,
    Future<FeedServerApiResponse<void>> Function() call,
    Future<void> Function() reload,
  ) async {
    setState(() => busy.add(address.toLowerCase()));
    final r = await call();
    if (!mounted) return;
    setState(() => busy.remove(address.toLowerCase()));
    if (r.success) {
      await reload();
    } else {
      handleWriteError(context, r.error ?? context.l10n.chsFailRemove,
          fallbackMessage:
              r.error?['message']?.toString() ?? context.l10n.chsFailRemove);
    }
  }

  Future<void> _reloadFriends() async {
    final r = await PublicOSChannels.listAccountWhitelist(serverAddress: _server);
    if (mounted && r.success) setState(() => _friends = r.data ?? const []);
  }

  Future<void> _reloadChannelList() async {
    final r = await PublicOSChannels.listWhitelist(
        slug: _slug, serverAddress: _server);
    if (mounted && r.success) setState(() => _channelList = r.data ?? const []);
  }

  Future<void> _reloadCustomList() async {
    final r = await PublicOSChannels.listInteractionList(
        slug: _slug, serverAddress: _server);
    if (mounted && r.success) setState(() => _customList = r.data ?? const []);
  }

  Future<void> _reloadPosters() async {
    final r =
        await PublicOSChannels.listPosters(slug: _slug, serverAddress: _server);
    if (mounted && r.success) setState(() => _posters = r.data ?? const []);
  }

  Future<void> _reloadBans() async {
    final r =
        await PublicOSChannels.listBans(slug: _slug, serverAddress: _server);
    if (mounted && r.success) setState(() => _bans = r.data ?? const []);
  }

  // -- Requests (accept-and-badge) ------------------------------------------

  Future<void> _approveRequest(FollowRequest req) async {
    setState(() => _requestsBusy.add(req.uid));
    final r = await PublicOSChannels.approveFollower(
      slug: _slug,
      requestUid: req.uid,
      serverAddress: _server,
    );
    if (!mounted) return;
    setState(() => _requestsBusy.remove(req.uid));
    if (r.success) {
      setState(() =>
          _requests = _requests.where((x) => x.uid != req.uid).toList());
      // Approval creates the whitelist row server-side; re-pull so the new
      // member appears with its real server row.
      await _reloadChannelList();
    } else {
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailApprove,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailApprove);
    }
  }

  Future<void> _ignoreRequest(FollowRequest req) async {
    setState(() => _requestsBusy.add(req.uid));
    final r = await PublicOSChannels.ignoreFollower(
      slug: _slug,
      requestUid: req.uid,
      serverAddress: _server,
    );
    if (!mounted) return;
    setState(() => _requestsBusy.remove(req.uid));
    if (r.success && r.data != null) {
      setState(() => _requests = [
            for (final x in _requests) x.uid == req.uid ? r.data! : x,
          ]);
    } else {
      handleWriteError(
          context, r.error ?? context.l10n.manageChannelPageFailIgnore,
          fallbackMessage: r.error?['message']?.toString() ??
              context.l10n.manageChannelPageFailIgnore);
    }
  }

  // ---------------------------------------------------------------------------
  // Monetization / export / delete
  // ---------------------------------------------------------------------------

  Future<void> _openPlans() async {
    final changed = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(builder: (_) => ManagePlansPage(channel: _channel)),
    );
    if (changed == true && mounted) await _reloadChannel();
  }

  /// Re-pull the channel row (plans write access_entries behind this page's
  /// back; a rename elsewhere would land here too).
  Future<void> _reloadChannel() async {
    final addr = PublicOS.myPublicosAddress;
    if (addr == null) return;
    // The channel OBJECT, per channel.
    // `access_entries` travel for every caller, so an unsigned object read
    // still brings the plans this page needs.
    final res = await PublicOSChannels.getChannel(
      ownerAddress: addr,
      slug: _slug,
      serverAddress: _server,
    );
    if (!mounted || !res.success || res.data == null) return;
    setState(() => _channel = res.data!.copyWith(
          serverAddress: _channel.serverAddress,
          serverId: _channel.serverId,
        ));
  }

  String? _exportUrl(String format) {
    final server = _server;
    final owner = _ownerAddress;
    if (server == null || server.isEmpty || owner.isEmpty || _slug.isEmpty) {
      return null;
    }
    final base =
        server.endsWith('/') ? server.substring(0, server.length - 1) : server;
    return '$base/api/$owner/channels/$_slug/$format';
  }

  Future<void> _copyExport(String format, String label) async {
    final l10n = context.l10n;
    final url = _exportUrl(format);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.manageChannelPageMissingServerInfo),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.manageChannelPageExportUrlCopied(label)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onDeleteChannel() async {
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
          l10n.manageChannelPageDeleteTitle,
          style: TextStyle(color: tokens.starkWhite),
        ),
        content: Text(
          l10n.manageChannelPageDeleteBody(_channel.name),
          style: TextStyle(color: tokens.textDim, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text(l10n.dlgCancel, style: TextStyle(color: tokens.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.manageChannelPageDelete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final response = await PublicOSChannels.deleteChannel(
        slug: _slug,
        serverAddress: _server,
      );
      if (!mounted) return;
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.manageChannelPageDeleted(_channel.name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // signal caller to refresh
      } else {
        handleWriteError(
          context,
          response.error ?? context.l10n.manageChannelPageUnknownError,
          fallbackMessage: response.error?['message']?.toString() ??
              context.l10n.manageChannelPageUnknownError,
        );
        setState(() => _deleting = false);
      }
    } catch (e) {
      if (!mounted) return;
      handleWriteError(context, e);
      setState(() => _deleting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Hints — a closed drawer's hint IS its verdict, compressed. Shared
  // grammar: wallets are named
  // OUTSIDE the filter qualifier because a hand-listed wallet skips the
  // account/citizen check; STANDING wears the "PublicOS account" language;
  // "readers" always means drawer 1's audience.
  // ---------------------------------------------------------------------------

  String _hint1(AppLocalizations l10n) {
    if (!_readListed) {
      switch (_readFilter) {
        case GateTier.signed:
          return l10n.chsH1Signed;
        case GateTier.standing:
          return l10n.chsH1Standing;
        case GateTier.citizen:
          return l10n.chsH1Citizen;
        default:
          return l10n.chsH1Anyone;
      }
    }
    final both = _readFriendsOn && _readPrivateOn;
    switch (_readFilter) {
      case GateTier.citizen:
        return both
            ? l10n.chsH1ListedCitizenBoth
            : _readFriendsOn
                ? l10n.chsH1ListedCitizenFriends
                : l10n.chsH1ListedCitizenOwn;
      case GateTier.standing:
        return both
            ? l10n.chsH1ListedStandingBoth
            : _readFriendsOn
                ? l10n.chsH1ListedStandingFriends
                : l10n.chsH1ListedStandingOwn;
      default: // signed
        return both
            ? l10n.chsH1ListedSignedBoth
            : _readFriendsOn
                ? l10n.chsH1ListedSignedFriends
                : l10n.chsH1ListedSignedOwn;
    }
  }

  String _hint2(AppLocalizations l10n) {
    switch (_channel.postingPolicy) {
      case 'open':
        return _postFilter == GateTier.citizen
            ? l10n.chsH2OpenCitizen
            : l10n.chsH2OpenStanding;
      case 'approved':
        return _postFilter == GateTier.citizen
            ? l10n.chsH2ApprovedCitizen
            : l10n.chsH2ApprovedStanding;
      default:
        return l10n.chsH2Owner;
    }
  }

  String _hint3(AppLocalizations l10n) {
    final String h;
    switch (_talkAudience) {
      case 'own':
        h = _talkFilter == GateTier.citizen
            ? l10n.chsH3CustomCitizen
            : l10n.chsH3CustomStanding;
        break;
      case 'friends':
        h = _talkFilter == GateTier.citizen
            ? l10n.chsH3FriendsCitizen
            : l10n.chsH3FriendsStanding;
        break;
      default:
        h = _talkFilter == GateTier.citizen
            ? l10n.chsH2OpenCitizen
            : l10n.chsH2OpenStanding;
    }
    return _splitReact ? '$h · ${l10n.chsH3ReactionsDiffer}' : h;
  }

  String _hint5(AppLocalizations l10n) {
    final maxPosts = _channel.maxPosts ?? 0;
    final maxDays = _channel.maxDays ?? 0;
    var h = maxPosts > 0 ? l10n.chsVisNewest(maxPosts) : l10n.chsVisAll;
    if (maxDays > 0) h = '$h · ${l10n.chsVisDays(maxDays)}';
    return h;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: tokens.starkWhite),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                _channel.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.chsTitleLabel,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: PhigitalLoadingWidget(size: 16, showShadows: false),
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, color: tokens.starkWhite),
            color: tokens.surfaceDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: tokens.borderSubtle),
            ),
            onSelected: (v) {
              switch (v) {
                case 'json':
                  _copyExport('json', 'JSON Feed');
                  break;
                case 'rss':
                  _copyExport('rss', 'RSS');
                  break;
                case 'atom':
                  _copyExport('atom', 'Atom');
                  break;
                case 'delete':
                  if (!_deleting) _onDeleteChannel();
                  break;
              }
            },
            itemBuilder: (_) => [
              _menuItem(tokens, 'json', Icons.rss_feed_rounded,
                  l10n.manageChannelPageMenuCopyJson),
              _menuItem(tokens, 'rss', Icons.rss_feed_rounded,
                  l10n.manageChannelPageMenuCopyRss),
              _menuItem(tokens, 'atom', Icons.rss_feed_rounded,
                  l10n.manageChannelPageMenuCopyAtom),
              const PopupMenuDivider(),
              _menuItem(tokens, 'delete', Icons.delete_outline_rounded,
                  l10n.manageChannelPageMenuDelete,
                  destructive: true),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _buildBasics(tokens, l10n),
          _buildDrawer(
            n: 1,
            title: l10n.chsDrawerRead,
            hint: _hint1(l10n),
            panel: _buildReadPanel(tokens, l10n),
          ),
          _buildDrawer(
            n: 2,
            title: l10n.chsDrawerPost,
            hint: _hint2(l10n),
            panel: _buildPostPanel(tokens, l10n),
          ),
          _buildDrawer(
            n: 3,
            title: l10n.chsDrawerTalk,
            hint: _hint3(l10n),
            panel: _buildTalkPanel(tokens, l10n),
          ),
          _buildDrawer(
            n: 4,
            title: l10n.chsDrawerBlocked,
            hint: _bans.isEmpty
                ? l10n.chsH4Nobody
                : l10n.chsH4Count(_bans.length),
            panel: _buildBlockedPanel(tokens, l10n),
          ),
          _buildDrawer(
            n: 5,
            title: l10n.chsDrawerVisibility,
            hint: _hint5(l10n),
            panel: _buildVisibilityPanel(tokens, l10n),
          ),
          _buildDrawer(
            n: 6,
            title: l10n.chsDrawerMonetization,
            hint: _channel.isPaid ? l10n.chsH6Paid : l10n.chsH6Free,
            panel: _buildMonetizationPanel(tokens, l10n),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    GlassTokens tokens,
    String value,
    IconData icon,
    String label, {
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFE57373) : tokens.starkWhite;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Basics — flat, always visible. The channel's identity, not a policy.
  // ---------------------------------------------------------------------------

  Widget _buildBasics(GlassTokens tokens, AppLocalizations l10n) {
    final host = Uri.tryParse(_server ?? '')?.host ?? (_server ?? '');
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                name: _channel.name,
                iconUrl: _channel.iconUrl,
                onTap: _editIcon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BasicField(
                      label: l10n.chsFieldName,
                      controller: _nameCtrl,
                      focusNode: _nameFocus,
                    ),
                    _BasicField(
                      label: l10n.chsFieldDescription,
                      controller: _descCtrl,
                      focusNode: _descFocus,
                      hint: l10n.chsDescriptionHint,
                      maxLines: 3,
                      dim: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _renameSlug,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(text: l10n.chsFieldAddress),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text.rich(
                          TextSpan(
                            text: '$host/',
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            children: [
                              TextSpan(
                                text: _slug,
                                style: TextStyle(
                                  color: tokens.starkWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_outlined,
                          size: 13, color: tokens.textDim),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(text: l10n.chsFieldLanguage),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          label: 'English',
                          selected: _channel.language == 'en',
                          onTap: () => _setLanguage('en'),
                        ),
                        _Chip(
                          label: 'Español',
                          selected: _channel.language == 'es',
                          onTap: () => _setLanguage('es'),
                        ),
                        if (_channel.language != 'en' &&
                            _channel.language != 'es')
                          _Chip(
                            label: _channel.language,
                            selected: true,
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Secret is the ONE listing lever, orthogonal to every gate
              // below: on = the channel leaves your public channel list
              // (even if the channel itself is public); reading by URL is
              // untouched — an unlisted video. Lives in basics, not a
              // drawer: it is a property of the channel, not a policy.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _FieldLabel(text: l10n.chsFieldSecret),
                  Switch.adaptive(
                    value: _channel.secret,
                    onChanged: _setSecret,
                    activeThumbColor: tokens.connectedAccent,
                    inactiveTrackColor: tokens.surfaceElevated,
                    inactiveThumbColor: tokens.borderMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _FieldLabel(text: l10n.chsFieldServer),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  host.isEmpty ? '—' : host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.starkWhite, fontSize: 12.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.chsServerLocked,
                style: TextStyle(color: tokens.textDim, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer shell
  // ---------------------------------------------------------------------------

  Widget _buildDrawer({
    required int n,
    required String title,
    required String hint,
    required List<Widget> panel,
  }) {
    final tokens = GlassTokens.of(context);
    final open = _openDrawer == n;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _openDrawer = open ? 0 : n),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    child: Text(
                      '$n',
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.42,
                    ),
                    child: Text(
                      hint,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.chevron_right_rounded,
                        size: 16, color: tokens.textDim),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...panel,
          if (open) const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer 1 — Who can read it
  // ---------------------------------------------------------------------------

  List<Widget> _buildReadPanel(GlassTokens tokens, AppLocalizations l10n) {
    final listed = _readListed;
    return [
      _PanelNote(text: l10n.chsReadNote),
      _PanelSubHead(text: l10n.chsSubAudience),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: !listed,
        label: l10n.chsAudAnyone,
        sub: l10n.chsAudAnyoneSub,
        onTap: () {
          // "Anyone" IS the absence of lists.
          if (listed) _toggleReadAudience(friends: false, private: false);
        },
      ),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: _readFriendsOn,
        label: l10n.chsAudFriends,
        sub: l10n.chsAudFriendsSub,
        count: _readFriendsOn ? _friends.length : null,
        editorOpen: _openEditors.contains('friends'),
        onChevron:
            _readFriendsOn ? () => _toggleEditor('friends') : null,
        onTap: () => _toggleReadAudience(friends: !_readFriendsOn),
      ),
      if (_readFriendsOn && _openEditors.contains('friends'))
        _nest(
          tokens,
          MemberListEditor(
            entries: [
              for (final e in _friends)
                MemberEntry(
                  address: e.address,
                  isOrg: e.isOrg,
                  expiresAt: e.expiresAt == null
                      ? null
                      : DateTime.tryParse(e.expiresAt!),
                ),
            ],
            busy: _friendsBusy,
            searchHint: l10n.chsSearchHint,
            emptyLabel: l10n.chsListEmpty,
            onAdd: (a) => _listAdd(
              _friendsBusy,
              a,
              () => PublicOSChannels.addAccountToWhitelist(
                  address: a, serverAddress: _server),
              _reloadFriends,
            ),
            onRemove: (a) => _listRemove(
              _friendsBusy,
              a,
              () => PublicOSChannels.removeAccountFromWhitelist(
                  address: a, serverAddress: _server),
              _reloadFriends,
            ),
          ),
        ),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: _readPrivateOn,
        label: l10n.chsAudPrivate,
        sub: l10n.chsAudPrivateSub,
        count: _readPrivateOn ? _channelList.length : null,
        badge: _readPrivateOn && _pendingRequests > 0
            ? '$_pendingRequests'
            : null,
        editorOpen: _openEditors.contains('private'),
        onChevron:
            _readPrivateOn ? () => _toggleEditor('private') : null,
        onTap: () => _toggleReadAudience(private: !_readPrivateOn),
      ),
      if (_readPrivateOn && _openEditors.contains('private'))
        _nest(
          tokens,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MemberListEditor(
                entries: [
                  for (final e in _channelList)
                    MemberEntry(
                      address: e.address,
                      isOrg: e.isOrg,
                      expiresAt: e.expiresAt == null
                          ? null
                          : DateTime.tryParse(e.expiresAt!),
                    ),
                ],
                busy: _channelListBusy,
                searchHint: l10n.chsSearchHint,
                emptyLabel: l10n.chsListEmpty,
                onAdd: (a) => _listAdd(
                  _channelListBusy,
                  a,
                  () => PublicOSChannels.addToWhitelist(
                      slug: _slug, address: a, serverAddress: _server),
                  _reloadChannelList,
                ),
                onRemove: (a) => _listRemove(
                  _channelListBusy,
                  a,
                  () => PublicOSChannels.removeFromWhitelist(
                      slug: _slug, address: a, serverAddress: _server),
                  _reloadChannelList,
                ),
              ),
              if (_requests.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    l10n.chsSubRequests.toUpperCase(),
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                for (final req in _requests)
                  _RequestTile(
                    request: req,
                    busy: _requestsBusy.contains(req.uid),
                    onApprove: () => _approveRequest(req),
                    onIgnore:
                        req.isPending ? () => _ignoreRequest(req) : null,
                  ),
              ],
            ],
          ),
        ),
      _PanelSubHead(text: l10n.chsSubFilter),
      _PanelNote(
        text: listed ? l10n.chsFilterNoteListed : l10n.chsFilterNoteNone,
      ),
      // "No filter" is unreachable once a list is on: the list forces an
      // envelope, so the server would read it as "signed" anyway.
      if (!listed)
        _OptionRow(
          kind: _OptionKind.radio,
          on: _readFilter == GateTier.anyone,
          label: l10n.chsFilterNone,
          sub: l10n.chsFilterNoneSub,
          onTap: () => _setReadFilter(GateTier.anyone),
        ),
      _OptionRow(
        kind: _OptionKind.radio,
        on: _readFilter == GateTier.signed,
        label: l10n.chsFilterSigned,
        sub: l10n.chsFilterSignedSub,
        onTap: () => _setReadFilter(GateTier.signed),
      ),
      // What the user sees as "All PublicOS Accounts" is the STANDING tier;
      // the bare `account` rung is server-capable but never offered.
      _OptionRow(
        kind: _OptionKind.radio,
        on: _readFilter == GateTier.standing,
        label: l10n.chsFilterStanding,
        sub: l10n.chsFilterStandingSub,
        onTap: () => _setReadFilter(GateTier.standing),
      ),
      _OptionRow(
        kind: _OptionKind.radio,
        on: _readFilter == GateTier.citizen,
        label: l10n.chsFilterCitizen,
        sub: l10n.chsFilterCitizenSub,
        onTap: () => _setReadFilter(GateTier.citizen),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Drawer 2 — Who can post
  // ---------------------------------------------------------------------------

  List<Widget> _buildPostPanel(GlassTokens tokens, AppLocalizations l10n) {
    final policy = _channel.postingPolicy;
    return [
      _PanelNote(text: l10n.chsPostNote),
      _PanelSubHead(text: l10n.chsSubAudience),
      _OptionRow(
        kind: _OptionKind.radio,
        on: policy == 'owner',
        label: l10n.chsPostOwner,
        sub: l10n.chsPostOwnerSub,
        onTap: () => _setPostingPolicy('owner'),
      ),
      _OptionRow(
        kind: _OptionKind.radio,
        on: policy == 'open',
        label: l10n.chsPostOpen,
        sub: l10n.chsPostOpenSub,
        onTap: () => _setPostingPolicy('open'),
      ),
      _OptionRow(
        kind: _OptionKind.radio,
        on: policy == 'approved',
        label: l10n.chsPostApproved,
        sub: l10n.chsPostApprovedSub,
        count: policy == 'approved' ? _posters.length : null,
        editorOpen: _openEditors.contains('posters'),
        onChevron:
            policy == 'approved' ? () => _toggleEditor('posters') : null,
        onTap: () => _setPostingPolicy('approved'),
      ),
      if (policy == 'approved' && _openEditors.contains('posters'))
        _nest(
          tokens,
          MemberListEditor(
            entries: [
              for (final e in _posters)
                MemberEntry(
                  address: e.address,
                  isOrg: e.isOrg,
                  expiresAt: e.expiresAt == null
                      ? null
                      : DateTime.tryParse(e.expiresAt!),
                ),
            ],
            busy: _postersBusy,
            searchHint: l10n.chsSearchHint,
            emptyLabel: l10n.chsListEmpty,
            onAdd: (a) => _listAdd(
              _postersBusy,
              a,
              () => PublicOSChannels.addPoster(
                  slug: _slug, address: a, serverAddress: _server),
              _reloadPosters,
            ),
            onRemove: (a) => _listRemove(
              _postersBusy,
              a,
              () => PublicOSChannels.removePoster(
                  slug: _slug, address: a, serverAddress: _server),
              _reloadPosters,
            ),
          ),
        ),
      if (policy != 'owner') ...[
        _PanelSubHead(text: l10n.chsSubFilter),
        _PanelNote(text: l10n.chsPostFilterGrp),
        _OptionRow(
          kind: _OptionKind.radio,
          on: _postFilter == GateTier.standing,
          label: l10n.chsFilterStanding,
          onTap: () => _setPostFilter(GateTier.standing),
        ),
        _OptionRow(
          kind: _OptionKind.radio,
          on: _postFilter == GateTier.citizen,
          label: l10n.chsFilterCitizen,
          onTap: () => _setPostFilter(GateTier.citizen),
        ),
        _ValueRow(
          label: l10n.chsPostDailyLimit,
          sub: l10n.chsPostDailyLimitSub,
          value: '${_channel.postRateLimit}',
          onTap: _editRateLimit,
        ),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Drawer 3 — Who can comment and react
  // ---------------------------------------------------------------------------

  List<Widget> _buildTalkPanel(GlassTokens tokens, AppLocalizations l10n) {
    final aud = _talkAudience;
    // The Custom panel has TWO MODES, decided by drawer 1's audience:
    // public read → search-and-add on the interaction list itself; gated
    // read → the whole live read audience enlisted with a tick per row.
    // Nothing copies between lists, so nothing can de-sync: the ticks write
    // the commenters list, the pool IS the read audience.
    final gated = _readListed;
    final customLower =
        _customList.map((e) => e.address.toLowerCase()).toSet();
    return [
      _PanelNote(text: l10n.chsTalkNote),
      _PanelSubHead(text: l10n.chsSubAudience),
      _OptionRow(
        kind: _OptionKind.radio,
        on: aud == 'all',
        label: l10n.chsTalkAll,
        sub: l10n.chsTalkAllSub,
        onTap: () => _setTalkAudience('all'),
      ),
      // "My friends" here is JUST the switch — the list is managed where it
      // lives (drawer 1), never from the comments drawer.
      _OptionRow(
        kind: _OptionKind.radio,
        on: aud == 'friends',
        label: l10n.chsTalkFriends,
        sub: l10n.chsTalkFriendsSub,
        onTap: () => _setTalkAudience('friends'),
      ),
      _OptionRow(
        kind: _OptionKind.radio,
        on: aud == 'own',
        label: l10n.chsTalkCustom,
        sub: l10n.chsTalkCustomSub,
        count: aud == 'own' ? _customList.length : null,
        editorOpen: _openEditors.contains('custom'),
        onChevron: aud == 'own' ? () => _toggleEditor('custom') : null,
        onTap: () => _setTalkAudience('own'),
      ),
      if (aud == 'own' && _openEditors.contains('custom'))
        _nest(
          tokens,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                child: Text(
                  gated ? l10n.chsTalkModeGated : l10n.chsTalkModePublic,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              if (gated)
                MemberListEditor(
                  entries: _readAudiencePool(),
                  busy: _customBusy,
                  searchHint: l10n.chsTalkSearchGated,
                  emptyLabel: l10n.chsListEmpty,
                  ticked: customLower,
                  onTick: (a, ticked) => ticked
                      ? _listAdd(
                          _customBusy,
                          a,
                          () => PublicOSChannels.addToInteractionList(
                              slug: _slug,
                              address: a,
                              serverAddress: _server),
                          _reloadCustomList,
                        )
                      : _listRemove(
                          _customBusy,
                          a,
                          () => PublicOSChannels.removeFromInteractionList(
                              slug: _slug,
                              address: a,
                              serverAddress: _server),
                          _reloadCustomList,
                        ),
                )
              else
                MemberListEditor(
                  entries: [
                    for (final e in _customList)
                      MemberEntry(
                        address: e.address,
                        isOrg: e.isOrg,
                        expiresAt: e.expiresAt == null
                            ? null
                            : DateTime.tryParse(e.expiresAt!),
                      ),
                  ],
                  busy: _customBusy,
                  searchHint: l10n.chsSearchHint,
                  emptyLabel: l10n.chsListEmpty,
                  onAdd: (a) => _listAdd(
                    _customBusy,
                    a,
                    () => PublicOSChannels.addToInteractionList(
                        slug: _slug, address: a, serverAddress: _server),
                    _reloadCustomList,
                  ),
                  onRemove: (a) => _listRemove(
                    _customBusy,
                    a,
                    () => PublicOSChannels.removeFromInteractionList(
                        slug: _slug, address: a, serverAddress: _server),
                    _reloadCustomList,
                  ),
                ),
            ],
          ),
        ),
      _PanelSubHead(text: l10n.chsSubFilter),
      _PanelNote(text: l10n.chsTalkFilterGrp),
      _OptionRow(
        kind: _OptionKind.radio,
        on: _talkFilter == GateTier.standing,
        label: l10n.chsFilterStanding,
        sub: l10n.chsFilterStandingDefaultSub,
        onTap: () => _setTalkFilter(GateTier.standing),
      ),
      _OptionRow(
        kind: _OptionKind.radio,
        on: _talkFilter == GateTier.citizen,
        label: l10n.chsFilterCitizen,
        onTap: () => _setTalkFilter(GateTier.citizen),
      ),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: _splitReact,
        label: l10n.chsTalkSplit,
        sub: l10n.chsTalkSplitSub,
        onTap: _toggleSplitReact,
      ),
      if (_splitReact) ...[
        _PanelSubHead(text: l10n.chsSubReactions),
        _OptionRow(
          kind: _OptionKind.radio,
          on: _reactFilter == GateTier.standing,
          label: l10n.chsFilterStanding,
          onTap: () => _setReactFilter(GateTier.standing),
        ),
        _OptionRow(
          kind: _OptionKind.radio,
          on: _reactFilter == GateTier.citizen,
          label: l10n.chsFilterCitizen,
          onTap: () => _setReactFilter(GateTier.citizen),
        ),
      ],
      // PublicOS Feed v1 interaction settings: what other channels may do
      // with these posts. On = `open`;
      // off = `closed`, and the SSP's quote check answers no for that kind.
      _PanelSubHead(text: l10n.chsSubOtherChannels),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: _channel.quotePolicy != 'closed',
        label: l10n.chsAllowQuotes,
        sub: l10n.chsAllowQuotesSub,
        onTap: () => _setInteractionPolicy(quote: _channel.quotePolicy == 'closed'),
      ),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: _channel.repostPolicy != 'closed',
        label: l10n.chsAllowReposts,
        sub: l10n.chsAllowRepostsSub,
        onTap: () => _setInteractionPolicy(repost: _channel.repostPolicy == 'closed'),
      ),
      _OptionRow(
        kind: _OptionKind.checkbox,
        on: _channel.replyPolicy != 'closed',
        label: l10n.chsAllowReplies,
        sub: l10n.chsAllowRepliesSub,
        onTap: () => _setInteractionPolicy(reply: _channel.replyPolicy == 'closed'),
      ),
    ];
  }

  /// The live read audience — union of whichever read lists are on. The
  /// pool is a POINTER to those lists (dedup by address), never a copy.
  List<MemberEntry> _readAudiencePool() {
    final seen = <String>{};
    final pool = <MemberEntry>[];
    if (_readFriendsOn) {
      for (final e in _friends) {
        if (seen.add(e.address.toLowerCase())) {
          pool.add(MemberEntry(address: e.address, isOrg: e.isOrg));
        }
      }
    }
    if (_readPrivateOn) {
      for (final e in _channelList) {
        if (seen.add(e.address.toLowerCase())) {
          pool.add(MemberEntry(address: e.address, isOrg: e.isOrg));
        }
      }
    }
    return pool;
  }

  // ---------------------------------------------------------------------------
  // Drawer 4 — Blocked
  // ---------------------------------------------------------------------------

  List<Widget> _buildBlockedPanel(GlassTokens tokens, AppLocalizations l10n) {
    return [
      _PanelNote(text: l10n.chsBlockedNote),
      _nest(
        tokens,
        MemberListEditor(
          entries: [
            for (final e in _bans)
              MemberEntry(address: e.address, note: e.reason),
          ],
          busy: _bansBusy,
          searchHint: l10n.chsSearchHint,
          emptyLabel: l10n.chsBlockedEmpty,
          onAdd: (a) => _listAdd(
            _bansBusy,
            a,
            () => PublicOSChannels.ban(
                slug: _slug, address: a, serverAddress: _server),
            _reloadBans,
          ),
          onRemove: (a) => _listRemove(
            _bansBusy,
            a,
            () => PublicOSChannels.unban(
                slug: _slug, address: a, serverAddress: _server),
            _reloadBans,
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Drawer 5 — Visibility
  // ---------------------------------------------------------------------------

  List<Widget> _buildVisibilityPanel(GlassTokens tokens, AppLocalizations l10n) {
    final maxPosts = _channel.maxPosts ?? 0;
    final maxDays = _channel.maxDays ?? 0;
    final total = _channel.postCount;
    return [
      _PanelNote(text: l10n.chsVisibilityNote),
      _ValueRow(
        label: l10n.chsVisShowNewest,
        value: maxPosts > 0 ? l10n.chsVisPosts(maxPosts) : l10n.chsVisAll,
        onTap: _editMaxPosts,
      ),
      _ValueRow(
        label: l10n.chsVisHideOlder,
        value: maxDays > 0 ? l10n.chsVisDays(maxDays) : l10n.chsVisOff,
        onTap: _editMaxDays,
      ),
      if (total != null && maxPosts > 0 && total > maxPosts)
        _VerdictBox(text: l10n.chsVisVerdict(total, maxPosts, total - maxPosts)),
    ];
  }

  // ---------------------------------------------------------------------------
  // Drawer 6 — Monetization
  // ---------------------------------------------------------------------------

  List<Widget> _buildMonetizationPanel(
      GlassTokens tokens, AppLocalizations l10n) {
    final plans = _channel.payableEntries.length;
    return [
      _PanelNote(text: l10n.chsMonetizationNote),
      _ValueRow(
        label: l10n.chsMonPlans,
        sub: plans == 0 ? l10n.chsMonPlansNone : null,
        value: plans == 0 ? '' : l10n.chsMonPlansCount(plans),
        onTap: _openPlans,
      ),
      _VerdictBox(
        text: _channel.isPaid
            ? l10n.chsMonVerdictPaid
            : l10n.chsMonVerdictFree,
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Small helpers
  // ---------------------------------------------------------------------------

  void _toggleEditor(String key) {
    setState(() {
      if (!_openEditors.remove(key)) _openEditors.add(key);
    });
  }

  /// Flat list editor: no left accent — a faint wash on
  /// the phone's base gutter. Ownership is already said three ways
  /// (position under the option, the chevron, the wash).
  Widget _nest(GlassTokens tokens, Widget child) {
    return Container(
      color: tokens.glassFill,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _listsLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: PhigitalLoadingWidget(size: 18, showShadows: false),
              ),
            )
          : child,
    );
  }

  Future<String?> _promptText({
    required String title,
    required String initial,
    String? hint,
    bool mono = false,
    bool numeric = false,
  }) {
    // The dialog OWNS its controller (State-held, disposed at unmount).
    // Creating the controller here and disposing it right after
    // `await showDialog` blew Flutter's `_dependents.isEmpty` assertion on
    // barrier dismiss: the future completes while the dialog is still
    // animating out, so its TextField sat attached to a disposed controller
    // for the length of the exit transition.
    return showDialog<String>(
      context: context,
      builder: (_) => _TextPromptDialog(
        title: title,
        initial: initial,
        hint: hint,
        mono: mono,
        numeric: numeric,
      ),
    );
  }

  /// Integer prompt for the server's count fields (`post_rate_limit`,
  /// `max_posts`, `max_days`): the SSP takes a JSON number cast to int and
  /// silently drops anything else, and <= 0 means "off". So the field is
  /// digits-only (no sign, no decimal, no letters) on a number keyboard;
  /// empty saves as 0.
  Future<int?> _promptNumber({
    required String title,
    required int current,
  }) async {
    final raw = await _promptText(
      title: title,
      initial: current == 0 ? '' : '$current',
      hint: '0',
      mono: true,
      numeric: true,
    );
    if (raw == null) return null;
    return raw.isEmpty ? 0 : int.tryParse(raw);
  }
}

// ============================================================================
// Panel primitives
// ============================================================================

/// One-field prompt dialog. Owns its [TextEditingController] so disposal
/// happens at widget unmount — AFTER the route's exit animation completes.
/// Pops with the trimmed text on Save, null on Cancel / barrier dismiss.
class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String initial;
  final String? hint;
  final bool mono;
  final bool numeric;

  const _TextPromptDialog({
    required this.title,
    required this.initial,
    required this.hint,
    required this.mono,
    this.numeric = false,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      backgroundColor: tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.borderSubtle),
      ),
      title: Text(
        widget.title,
        style: TextStyle(color: tokens.starkWhite, fontSize: 15),
      ),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: widget.numeric ? TextInputType.number : null,
        inputFormatters:
            widget.numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(
          color: tokens.starkWhite,
          fontSize: 13,
          fontFamily: widget.mono ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: tokens.textDim, fontSize: 13),
          filled: true,
          fillColor: tokens.surfaceElevated,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.dlgCancel,
              style: TextStyle(color: tokens.textDim)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(
            context.l10n.createChannelPageSave,
            style: TextStyle(
              color: tokens.starkWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

enum _OptionKind { radio, checkbox }

/// One option row: a radio dot or checkbox, label + dim subtitle, and —
/// while the option is ON — an optional member count + chevron that opens
/// the inline list editor. The chevron never toggles the option
/// (a separate tap target), and count + chevron only render with the
/// option on: an editor for a switched-off source would edit nothing.
class _OptionRow extends StatelessWidget {
  final _OptionKind kind;
  final bool on;
  final String label;
  final String? sub;
  final int? count;
  final String? badge;
  final bool editorOpen;
  final VoidCallback onTap;
  final VoidCallback? onChevron;

  const _OptionRow({
    required this.kind,
    required this.on,
    required this.label,
    required this.onTap,
    this.sub,
    this.count,
    this.badge,
    this.editorOpen = false,
    this.onChevron,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    Widget control;
    if (kind == _OptionKind.radio) {
      control = Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: on ? accent : tokens.borderMedium,
            width: 1.5,
          ),
        ),
        child: on
            ? Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: accent),
                ),
              )
            : null,
      );
    } else {
      control = Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: on ? accent : tokens.borderMedium,
            width: 1.5,
          ),
          color: on ? accent.withValues(alpha: 0.18) : null,
        ),
        child: on
            ? Icon(Icons.check_rounded, size: 12, color: accent)
            : null,
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            control,
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: on ? tokens.starkWhite : tokens.textDim,
                      fontSize: 12.5,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style: TextStyle(
                        color: tokens.textDim,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: tokens.fallbackAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: tokens.fallbackAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            if (count != null) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (onChevron != null)
              GestureDetector(
                // The chevron opens/closes the editor WITHOUT toggling the
                // option the row selects.
                onTap: onChevron,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 1),
                  child: AnimatedRotation(
                    turns: editorOpen ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 17,
                      color: tokens.textDim,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PanelSubHead extends StatelessWidget {
  final String text;

  const _PanelSubHead({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: tokens.textDim,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
          fontFamily: 'SpaceGrotesk',
        ),
      ),
    );
  }
}

class _PanelNote extends StatelessWidget {
  final String text;

  const _PanelNote({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 16, 8),
      child: Text(
        text,
        style: TextStyle(color: tokens.textDim, fontSize: 11, height: 1.45),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String value;
  final VoidCallback onTap;

  const _ValueRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 10, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        TextStyle(color: tokens.starkWhite, fontSize: 12.5),
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub!,
                      style:
                          TextStyle(color: tokens.textDim, fontSize: 10.5),
                    ),
                  ],
                ],
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 11.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 15, color: tokens.textDim),
          ],
        ),
      ),
    );
  }
}

class _VerdictBox extends StatelessWidget {
  final String text;

  const _VerdictBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 10, 16, 2),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Text(
        text,
        style: TextStyle(color: tokens.textDim, fontSize: 11.5, height: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: tokens.textDim,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        fontFamily: 'SpaceGrotesk',
      ),
    );
  }
}

/// Borderless inline field for basics — label over value, hairline under,
/// commits on blur (the parent owns the FocusNode listeners).
class _BasicField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final int maxLines;
  final bool dim;

  const _BasicField({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.hint,
    this.maxLines = 1,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: label),
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            minLines: 1,
            style: TextStyle(
              color: dim ? tokens.textDim : tokens.starkWhite,
              fontSize: dim ? 12.5 : 13.5,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(color: tokens.textDim, fontSize: 12.5),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: tokens.borderSubtle, width: 0.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: tokens.borderMedium, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: selected ? tokens.surfaceElevated : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? tokens.borderMedium : tokens.borderSubtle,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? tokens.starkWhite : tokens.textDim,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String name;
  final String? iconUrl;
  final VoidCallback onTap;

  const _IconTile({
    required this.name,
    required this.iconUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final initials = name.isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .map((w) => w[0])
            .take(2)
            .join()
            .toUpperCase();
    final url = iconUrl;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderMedium),
              color: tokens.surfaceElevated,
            ),
            child: url != null && url.isNotEmpty
                ? ZeroCachedImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    width: 58,
                    height: 58,
                  )
                : Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'SpaceGrotesk',
                      ),
                    ),
                  ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.surfaceDeep,
                border: Border.all(color: tokens.borderMedium),
              ),
              child:
                  Icon(Icons.edit_outlined, size: 10, color: tokens.textDim),
            ),
          ),
        ],
      ),
    );
  }
}

/// One follow request: avatar · name · filter badge · Approve (+ Ignore for
/// pending). Accept-and-badge: a filter-blocked request still LANDS, and
/// Approve is always real — the whitelist row waits behind the filter, so
/// the owner approves with eyes open instead of hitting a silent dead end.
class _RequestTile extends StatefulWidget {
  final FollowRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback? onIgnore;

  const _RequestTile({
    required this.request,
    required this.busy,
    required this.onApprove,
    this.onIgnore,
  });

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final c = await lookupMemberContact(widget.request.requesterAddress);
    if (!mounted || c == null) return;
    setState(() => _contact = c);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    final address = widget.request.requesterAddress;
    final short = shortMemberAddress(address);
    final displayName = _contact?.displayName;
    final hasName = displayName != null && displayName.isNotEmpty;

    // Badge from the live filter check. `unknown` = the chain read failed —
    // owner information fails soft where the gates fail closed.
    final (String, Color)? badge = switch (widget.request.filterStatus) {
      'passes' => (l10n.chsReqPasses, tokens.connectedAccent),
      'blocked' => (l10n.chsReqBlocked, tokens.fallbackAccent),
      'unknown' => (l10n.chsReqUnknown, tokens.textDim),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          GlassContactIcon(
            contact: _contact,
            address: address,
            size: 28,
            onTap: () {
              final c = _contact;
              if (c != null) {
                AppNav.toContact(context, c);
              } else {
                AppNav.toProfile(context, address);
              }
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? displayName : short,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: hasName ? null : 'monospace',
                  ),
                ),
                if (badge != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: badge.$2.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badge.$1,
                        style: TextStyle(
                          color: badge.$2,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (widget.busy)
            const SizedBox(
              width: 14,
              height: 14,
              child: PhigitalLoadingWidget(size: 14, showShadows: false),
            )
          else ...[
            if (widget.onIgnore != null) ...[
              _SmallAction(
                label: l10n.manageChannelPageActionIgnore,
                onTap: widget.onIgnore!,
              ),
              const SizedBox(width: 6),
            ],
            _SmallAction(
              label: l10n.manageChannelPageActionApprove,
              onTap: widget.onApprove,
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.borderMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
