import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/feeds/feed_source.dart';
import 'package:publicos_desktop/widgets/feeds/gate_locked_shell.dart';
import 'package:publicos_desktop/widgets/pixel_rain_loading_widget.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';

/// Locked-state body shown in place of the post list when the user opens a
/// private channel they're not following yet.
///
/// **Self-contained** — takes a [Channel] and calls `PublicOSChannels`
/// methods directly (`getChannelsByAddress` to resolve follow status,
/// `requestFollow` / `cancelFollow` for the action buttons). No repo
/// coupling.
///
/// State machine (tracked internally):
///  - resolving → spinner while the initial status fetch lands
///  - `null`     → Request access button (never requested, or cancelled)
///  - `pending`  → Pending approval chip + Cancel request button
///  - `approved` → placeholder + fires [onApproved] so the parent can swap
///                 this widget out for the real post list
///  - `denied` / `rejected` → same visual as `null` with an extra message
///                 explaining the previous decision
///  - `blacklisted` → terminal blocked state (no Request button); set when
///                 the server returns 403 `BLACKLISTED` on a request attempt.
///                 No client-side recovery — user must contact the owner.
///
/// Pull-to-refresh wraps the whole body — swiping down re-runs the
/// resolve call so users can manually re-check approval status.
///
/// The icon tile, primary button and acting placeholder come from
/// `gate_locked_shell.dart` — shared with the paywall and
/// tier bodies so the three refusal screens cannot drift apart.
class PrivateFeedLockedWidget extends StatefulWidget {
  final Channel channel;
  final VoidCallback? onApproved;
  final Color? accentColor;

  /// `follow_status` from the refusal body (Core
  /// `FeedGateException.channel`). Non-null → the first paint needs no
  /// network; pull-to-refresh still re-resolves via the object route.
  final String? initialStatus;

  const PrivateFeedLockedWidget({
    super.key,
    required this.channel,
    this.onApproved,
    this.accentColor,
    this.initialStatus,
  });

  @override
  State<PrivateFeedLockedWidget> createState() =>
      _PrivateFeedLockedWidgetState();
}

class _PrivateFeedLockedWidgetState extends State<PrivateFeedLockedWidget> {
  bool _isResolving = true;
  bool _isActing = false;
  bool _noOwner = false;
  String? _status;
  String? _resolveError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStatus;
    if (initial != null) {
      _status = initial == 'blocked' ? 'blacklisted' : initial;
      _isResolving = false;
      if (_status == 'approved') widget.onApproved?.call();
    } else {
      _resolveStatus();
    }
  }

  Future<void> _resolveStatus() async {
    final owner = widget.channel.ownerAddress;
    if (owner == null || owner.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isResolving = false;
        _noOwner = true;
      });
      return;
    }
    setState(() {
      _isResolving = true;
      _resolveError = null;
      _noOwner = false;
    });

    // Sign the request so the server returns our follow_status. Without
    // a signed envelope the server omits per-user state entirely, so
    // nobody can enumerate another address's status.
    // The channel OBJECT, per channel — never the owner listing. Signs
    // under the same rule as a read, so a denied channel never learns who
    // is asking.
    final resp = await PublicOSChannels.getChannel(
      ownerAddress: owner,
      slug: widget.channel.slug,
      serverAddress: widget.channel.serverAddress,
    );
    if (!mounted) return;
    final l10n = context.l10n;

    if (resp.success && resp.data != null) {
      final match = resp.data;
      if (match != null) {
        // Server-side `'blocked'` is the same terminal state we set
        // locally as `'blacklisted'` when a request attempt returns
        // BLACKLISTED. Map to the local name so the existing UI branch
        // (no Request button, blocked-copy blurb) lights up either way.
        final raw = match.followStatus;
        final status = raw == 'blocked' ? 'blacklisted' : raw;
        setState(() {
          _status = status;
          _isResolving = false;
        });
        if (status == 'approved') {
          widget.onApproved?.call();
        }
        return;
      }
    }

    setState(() {
      _isResolving = false;
      _resolveError =
          _errorMessage(resp) ?? l10n.privateFeedLockedWidgetCouldNotResolve;
    });
  }

  Future<void> _request() async {
    if (_isActing) return;
    final owner = widget.channel.ownerAddress;
    if (owner == null || owner.isEmpty) {
      _showNoOwner();
      return;
    }
    setState(() => _isActing = true);

    final resp = await PublicOSChannels.requestFollow(
      ownerAddress: owner,
      slug: widget.channel.slug,
      serverAddress: widget.channel.serverAddress,
    );
    if (!mounted) return;
    final l10n = context.l10n;

    if (resp.success) {
      setState(() {
        _status = 'pending';
        _isActing = false;
      });
      return;
    }
    final code = resp.error?['code'] as String? ?? '';
    // Idempotent: server says we already have an open request — drop straight
    // into pending without surfacing a noisy error.
    if (code == 'FOLLOW_REQUEST_EXISTS') {
      setState(() {
        _status = 'pending';
        _isActing = false;
      });
      return;
    }
    // Server says we're already whitelisted — local follow-status was stale.
    // Re-resolve; the next pass will land `approved` and fire `onApproved`.
    if (code == 'ALREADY_WHITELISTED') {
      setState(() => _isActing = false);
      _resolveStatus();
      return;
    }
    // Server says we're blacklisted — terminal. No Request button, no
    // cancel, no recourse from the client.
    if (code == 'BLACKLISTED') {
      setState(() {
        _status = 'blacklisted';
        _isActing = false;
      });
      return;
    }
    setState(() => _isActing = false);
    handleWriteError(
        context, resp.error ?? l10n.privateFeedLockedWidgetRequestFailed,
        fallbackMessage:
            _errorMessage(resp) ?? l10n.privateFeedLockedWidgetRequestFailed);
  }

  Future<void> _cancel() async {
    if (_isActing) return;
    final owner = widget.channel.ownerAddress;
    if (owner == null || owner.isEmpty) {
      _showNoOwner();
      return;
    }
    setState(() => _isActing = true);

    final resp = await PublicOSChannels.cancelFollow(
      ownerAddress: owner,
      slug: widget.channel.slug,
      serverAddress: widget.channel.serverAddress,
    );
    if (!mounted) return;
    final l10n = context.l10n;

    if (resp.success) {
      setState(() {
        _status = null;
        _isActing = false;
      });
      return;
    }
    setState(() => _isActing = false);
    handleWriteError(
        context, resp.error ?? l10n.privateFeedLockedWidgetCancelFailed,
        fallbackMessage:
            _errorMessage(resp) ?? l10n.privateFeedLockedWidgetCancelFailed);
  }

  /// A tap must never die silently: say why nothing can be sent.
  void _showNoOwner() {
    debugPrint('[PrivateFeedLock] no owner address for ${widget.channel.slug}');
    final msg = context.l10n.privateFeedLockedWidgetNoOwnerAddress;
    handleWriteError(context, msg, fallbackMessage: msg);
  }

  String? _errorMessage(FeedServerApiResponse<dynamic> resp) {
    final err = resp.error;
    if (err == null) return null;
    return err['message'] as String? ?? err['code'] as String?;
  }

  String _statusBlurb(bool isDenied, bool isBlocked) {
    final l10n = context.l10n;
    if (_status == 'pending') {
      return l10n.privateFeedLockedWidgetBlurbPending;
    }
    if (isBlocked) {
      return l10n.privateFeedLockedWidgetBlurbBlocked;
    }
    if (isDenied) {
      return l10n.privateFeedLockedWidgetBlurbDenied;
    }
    return l10n.privateFeedLockedWidgetBlurbDefault;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return RefreshIndicator(
      onRefresh: _resolveStatus,
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _buildBody(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GlassTokens tokens) {
    if (_isResolving) {
      // Unobtrusive corner loader — the pixel rain reads as ambient activity
      // in the bottom-right rather than a blocking center spinner.
      return const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.only(right: 24, bottom: 24),
          child: PixelRainLoadingWidget(size: 48, showShadows: false),
        ),
      );
    }

    // Approved → render nothing; parent received onApproved and is
    // swapping us out for the real content.
    if (_status == 'approved') {
      return const SizedBox.shrink();
    }

    final isDenied = _status == 'denied' || _status == 'rejected';
    final isBlocked = _status == 'blacklisted';
    final errorText = _noOwner
        ? context.l10n.privateFeedLockedWidgetNoOwnerAddress
        : _resolveError;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GateIconTile(),
            const SizedBox(height: 28),
            Text(
              widget.channel.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            if (widget.channel.description.isNotEmpty)
              Text(
                widget.channel.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 18),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderSubtle, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                context.l10n.privateFeedLockedWidgetPrivateBadge,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _statusBlurb(isDenied, isBlocked),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 12,
                height: 1.55,
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.fallbackAccent,
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 26),
            // Blacklisted is terminal — no client-side action makes sense
            // (Request would just bounce, Cancel has nothing to cancel).
            if (!isBlocked)
              _ActionArea(
                status: _status,
                acting: _isActing,
                onRequest: _request,
                onCancel: _cancel,
                accentColor: widget.accentColor,
              ),
          ],
        ),
      ),
    );
  }
}

/// Parses a feed URL of the shape
/// `${serverAddress}/api/${ownerAddress}/channels/${slug}/{json|rss|atom}`
/// into a minimal [Channel] stub suitable for passing to
/// [PrivateFeedLockedWidget]. The stub has enough info (owner + slug +
/// serverAddress) for `_resolveStatus` to hit the Core API and fetch the
/// real channel record. Returns null if the URL doesn't match the
/// expected shape.
///
/// Used by the RSS browser surfaces (feed_browser_page, feed_posts_list)
/// which only know a feed by URL. The main feeds tab always has a real
/// [Channel] in hand and never needs this helper.
/// Per-feed access state for list-aware UIs (feeds_view banner, manage
/// lists sheet badges, expanded-list compact CTA). Resolved via
/// [hydrateFeedAccess] using the existing `getChannelsByAddress` metadata
/// endpoint — no probe-on-403, no new endpoint, no persistence.
class FeedAccessState {
  final bool isPrivate;
  final String? followStatus; // null / pending / approved / denied / rejected
  final int? postCount;

  const FeedAccessState({
    required this.isPrivate,
    this.followStatus,
    this.postCount,
  });

  bool get isApproved => followStatus == 'approved';
  bool get isPending => followStatus == 'pending';
  bool get isLockedNoAccess => isPrivate && !isApproved;
  bool get isLockedAndPending => isPrivate && isPending;
}

/// Batch-resolves access state for a list of feed URLs in a single round of
/// `getChannelsByAddress` calls grouped per `(serverAddress, ownerAddress)`.
/// Returns a map keyed by `feedUrl`. URLs that don't parse as channel feeds
/// are silently skipped (they're treated as public — no entry returned).
///
/// Pass a non-null [userAddress] to receive per-user `followStatus` (the
/// call signs a `list_channels` envelope so the server unlocks status for
/// the signer). Pass null to resolve structural fields only (isPrivate,
/// postCount). The `userAddress` value itself isn't put on the wire — the
/// signer is identified entirely by the signature.
Future<Map<String, FeedAccessState>> hydrateFeedAccess(
  List<String> feedUrls, {
  required String? userAddress,
}) async {
  final result = <String, FeedAccessState>{};
  if (feedUrls.isEmpty) return result;

  // One object call PER CHANNEL — never grouped per owner: an owner listing
  // would fetch every channel of an owner to learn about one. The object route
  // is not a read event, so hydrating a long list costs the owner's KPI
  // nothing; each call signs under its own channel's rule.
  await Future.wait(feedUrls.map((url) async {
    final stub = channelStubFromFeedUrl(url);
    if (stub == null) return;
    final owner = stub.ownerAddress;
    if (owner == null || owner.isEmpty) return;
    final resp = await PublicOSChannels.getChannel(
      ownerAddress: owner,
      slug: stub.slug,
      serverAddress: stub.serverAddress,
    );
    if (!resp.success || resp.data == null) return;
    final ch = resp.data!;
    result[url] = FeedAccessState(
      isPrivate: ch.isPrivate,
      followStatus: ch.followStatus,
      postCount: ch.postCount,
    );
  }));

  return result;
}

class _ActionArea extends StatelessWidget {
  final String? status;
  final bool acting;
  final Future<void> Function() onRequest;
  final Future<void> Function() onCancel;
  final Color? accentColor;

  const _ActionArea({
    required this.status,
    required this.acting,
    required this.onRequest,
    required this.onCancel,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    if (acting) {
      return const GateActingIndicator();
    }
    if (status == 'pending') {
      return Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.fallbackAccent.withValues(alpha: 0.10),
              border: Border.all(
                color: tokens.fallbackAccent.withValues(alpha: 0.4),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: tokens.fallbackAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.privateFeedLockedWidgetPendingChip,
                  style: TextStyle(
                    color: tokens.fallbackAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GatePrimaryButton(
            label: context.l10n.privateFeedLockedWidgetCancelRequest,
            onPressed: onCancel,
            destructive: true,
          ),
        ],
      );
    }
    return GatePrimaryButton(
      label: context.l10n.privateFeedLockedWidgetRequestAccess,
      icon: Icons.vpn_key_rounded,
      onPressed: onRequest,
      accentColor: accentColor,
    );
  }
}
