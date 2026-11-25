import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import '../data/nft_avatar_prefs.dart';
import '../router_helpers.dart';
import '../theme/glass_tokens.dart';
import 'nft_avatar_fx.dart';
import 'nft_image.dart';
import 'shimmer_box.dart';

/// The canonical contact avatar.
///
/// Visual language:
///   - **Shape = class:** individuals get a rounded squircle (r≈40%), orgs a
///     sharper corner (r≈15%).
///   - **NFT = top-left sparkles** (+ optional shimmer sweep), shown only when
///     the NFT avatar is *verified-owned* AND the matching toggle is on.
///   - **Phantom badge = the private group** (bottom-left): non-citizen
///     individuals AND non-public orgs. Citizens and public orgs stay clean.
///   - **XMTP badge:** XMTP-native contacts that don't resolve to a PublicOS
///     chain account — group-chat stubs and persons known only by an inbox ID
///     (mutually exclusive with the phantom).
///
/// Membership (`isCitizen` / `isPublicOrg`) and the NFT verdict
/// (`verifiedNftAvatar`) arrive **already resolved** on the [Contact] — Core's
/// `fetchContact` resolves the artwork, verifies ownership, and caches the
/// verdict + membership (verify-at-fetch). This widget is purely
/// **presentational**: it reads those fields off the contact and never fetches,
/// verifies, or writes anything.
class GlassContactIcon extends StatefulWidget {
  /// Generates a unique Hero tag for a contact based on its best identifier.
  /// Uses publicosAddress for PublicOS accounts, falling back to the first
  /// registered inbox ID for plain XMTP contacts, so hero animations match
  /// across pages.
  static String? contactHeroTag(Contact? contact) {
    if (contact == null) return null;
    final address = contact.publicosAddress?.eip55With0x;
    if (address != null &&
        address != '0x0000000000000000000000000000000000000000') {
      return 'contact_$address';
    }
    final inboxId = contact.registeredInboxIDs?.firstOrNull?.inboxId;
    if (inboxId != null) return 'contact_$inboxId';
    return null;
  }

  /// The one "open this account" tap: the contact's profile (its address, or
  /// its inbox when it has no chain account), else the raw [address]. Null when
  /// there is no account to open (a group-chat stub, an `address` that is
  /// really an inbox id). Behind [opensProfile] and [ContactProfileTap].
  static VoidCallback? profileTap(
    BuildContext context, {
    Contact? contact,
    String? address,
  }) {
    const zero = '0x0000000000000000000000000000000000000000';
    // Desktop has no route stack: the profile opens in the shell's pane, so a
    // sheet or dialog this sits in has to be closed first or it stays on top.
    void closeOverlays() => Navigator.of(context, rootNavigator: true)
        .popUntil((r) => r.isFirst);
    if (contact != null) {
      final a = contact.publicosAddress?.eip55With0x;
      final hasAccount = a != null && a != zero;
      final hasInbox = contact.registeredInboxIDs?.isNotEmpty ?? false;
      if (hasAccount || hasInbox) {
        return () {
          closeOverlays();
          AppNav.toContact(context, contact);
        };
      }
    }
    if (address != null &&
        address.length == 42 &&
        address.startsWith('0x') &&
        address != zero) {
      return () {
        closeOverlays();
        AppNav.toProfile(context, address);
      };
    }
    return null;
  }

  final Contact? contact;
  final String? address;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// The icon itself opens this account's profile on tap: the contact's
  /// address (or its inbox when it has no chain account), else the raw
  /// [address]. One code path for every "who is this" avatar, so a row cannot
  /// forget it. Off by default because many rows give the tap another meaning
  /// (a picker selects, a conversation row opens the chat); an explicit
  /// [onTap] always wins. With nothing to open, the icon takes no tap.
  /// Client twin; the desktop delta is in `profileTap`.
  final bool opensProfile;

  /// Optional Hero tag — wraps the icon in a [Hero] for cross-page transitions
  /// (e.g. the browser address-bar avatar → profile page). Pair with
  /// [contactHeroTag] to derive a stable tag from a contact.
  final String? heroTag;

  /// Optional override for the frame border colour. When set, draws a solid
  /// 2px ring in this colour instead of the default subtle glass border — used
  /// for cutout separation against a background (e.g. avatar over a banner).
  final Color? borderColor;

  /// Optional fixed decode resolution for the avatar image, independent of the
  /// layout [size]. Set this when [size] is *animated* (e.g. the social-graph
  /// fly): a per-frame-changing size otherwise re-targets the underlying image
  /// decoder every frame, which bounces `ZeroCachedImage` back to its
  /// placeholder (the initials view) — a strobe. Pinning the decode size to the
  /// animation's destination keeps one stable decode and pre-warms the cache at
  /// the size the avatar lands at. Defaults to [size].
  final double? decodeSize;

  const GlassContactIcon({
    super.key,
    this.contact,
    this.address,
    this.size = 64.0,
    this.onTap,
    this.onLongPress,
    this.opensProfile = false,
    this.heroTag,
    this.borderColor,
    this.decodeSize,
  });

  @override
  State<GlassContactIcon> createState() => _GlassContactIconState();
}

class _GlassContactIconState extends State<GlassContactIcon>
    with SingleTickerProviderStateMixin {
  String? _imageUrl;
  Color? _iconColor;
  String _initials = '?';

  bool _isOrg = false;
  bool _isXmtpOnly = false;
  bool _verifiedNft = false;

  /// null = unknown (no badge yet); true = private group (phantom).
  bool? _isPrivate;

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _resolve();
    // Sparkle/shimmer prefs are in-memory statics (default ON). Load them once
    // OFF the image path — they gate only the animation, never the image — so a
    // cached avatar paints in a single synchronous frame instead of waiting on
    // a settings read it never needed.
    NftAvatarPrefs.ensureLoaded().then((_) {
      if (!mounted) return;
      if (_verifiedNft) setState(() {}); // adopt a non-default toggle
      _maybeAnimate();
    });
  }

  @override
  void didUpdateWidget(covariant GlassContactIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.contact, widget.contact) ||
        oldWidget.address != widget.address) {
      _resolve();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _maybeAnimate() {
    final wantAnim =
        _verifiedNft && (NftAvatarPrefs.sparkles || NftAvatarPrefs.shimmer);
    if (wantAnim) {
      if (!_anim.isAnimating) _anim.repeat();
    } else if (_anim.isAnimating) {
      _anim.stop();
    }
  }

  /// Read every renderable field off the [Contact] in a single synchronous
  /// pass — the data layer (Core `fetchContact`) has already resolved the NFT
  /// artwork, ownership verdict, and membership flag, so there is nothing to
  /// fetch here. Called from [initState] and [didUpdateWidget]; in both, build()
  /// runs right after, so the fields need no setState of their own.
  void _resolve() {
    final contact = widget.contact;
    final address = widget.address;

    // Shape = class. XMTP group chats render with the org (sharper) shape too.
    _isOrg =
        (contact?.isOrgAccount ?? false) || (contact?.isGroupChat ?? false);
    // XMTP badge: any contact with no PublicOS chain account that we know from
    // XMTP — group-chat stubs (identified by a conversation topic, no inbox IDs)
    // and persons known only by a registered inbox ID. Both live purely in XMTP,
    // never on chain.
    _isXmtpOnly = contact != null &&
        contact.publicosAddress == null &&
        (contact.isGroupChat ||
            (contact.registeredInboxIDs?.isNotEmpty ?? false));

    // Image + verified flag from the best synchronously-known source: a fresh,
    // matching cached NFT verdict wins; else the resolved/URL avatar; else
    // initials. `verifiedNftAvatarData` is a parsed DB column (synchronous), so
    // a cached NFT avatar paints immediately — no await, no chain call. The
    // image bytes themselves are then disk-cached by ZeroCachedImage downstream.
    final ref = contact?.nftAvatar;
    final cache = contact?.verifiedNftAvatarData;
    final cacheUsable = ref != null &&
        cache != null &&
        cache.matches(ref) &&
        (cache.imageUrl?.isNotEmpty ?? false);
    if (cacheUsable) {
      _imageUrl = cache.imageUrl;
      _verifiedNft = cache.verifiedOwnership;
    } else {
      final url = contact?.getRecordValue('profile.avatar.resolved') ??
          contact?.avatarUrl;
      _imageUrl = (url != null && url.isNotEmpty) ? url : null;
      _verifiedNft = false;
    }

    if (contact != null) {
      _iconColor = contact.iconColor;
      _initials = contact.initials;
    } else if (address != null && address.isNotEmpty) {
      final hash = address.hashCode;
      _iconColor =
          HSLColor.fromAHSL(1.0, (hash % 360).toDouble(), 0.7, 0.6).toColor();
      _initials =
          address.length >= 4 ? address.substring(2, 4).toUpperCase() : '?';
    } else {
      _iconColor = null;
      _initials = '?';
    }

    // Phantom badge from the membership flag resolved at fetch time.
    _isPrivate = _cachedPrivacy(contact);

    _maybeAnimate();
  }

  /// The phantom-badge verdict from data already on the contact, or null when
  /// it hasn't been fetched yet (→ no badge until [_resolveMembership] lands).
  /// Clean (no badge) = citizen individual / public org; private = the inverse.
  bool? _cachedPrivacy(Contact? contact) {
    if (contact == null) return null;
    if (contact.isOrgAccount) {
      return contact.isPublicOrg == null ? null : contact.isPublicOrg == false;
    }
    return contact.isCitizen == null ? null : contact.isCitizen == false;
  }

  Widget _buildInitialsView(Color color) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontSize: widget.size * 0.35,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final size = widget.size;
    // Shape = class: individual rounded squircle, org sharper corner.
    final radius = size * (_isOrg ? 0.15 : 0.40);
    final color = _iconColor ?? tokens.textDim;

    // Loading is not the same state as absent. `_resolve()` already decided
    // synchronously whether this contact has artwork, so an avatar that is
    // *going* to be a picture must never spend its first frames wearing the
    // initials tile — it waits on a neutral skeleton instead. The initials stay
    // where they mean something: no artwork at all (the else branch), or
    // artwork that failed to load (NftImage's `fallback`).
    final Widget avatar = _imageUrl != null
        ? NftImage(
            url: _imageUrl!,
            fit: BoxFit.cover,
            renderSize: widget.decodeSize ?? size,
            placeholder: _AvatarSkeleton(
              size: size,
              radius: radius,
              base: tokens.surfaceElevated,
              highlight: Color.alphaBlend(
                tokens.starkWhite.withValues(alpha: 0.10),
                tokens.surfaceElevated,
              ),
            ),
            fallback: _buildInitialsView(color),
          )
        : _buildInitialsView(color);

    final Widget framed = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
        // border: Border.all(
        //   color: widget.borderColor ?? tokens.starkWhite.withValues(alpha: 0.2),
        //   width: widget.borderColor != null ? 2 : 1,
        // ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      ),
    );

    final showSparkles = _verifiedNft && NftAvatarPrefs.sparkles;
    final showShimmer = _verifiedNft && NftAvatarPrefs.shimmer;
    final badgeSize = size * 0.34;

    final children = <Widget>[framed];

    if (showShimmer) {
      children.add(Positioned.fill(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: NftShimmerPainter(_anim.value),
            ),
          ),
        ),
      ));
    }

    if (showSparkles) {
      // Overhang the top-left corner so several pixels sit OUTSIDE the avatar
      // frame — proof the mark is a live overlay, not baked into the image.
      final fxSize = size * 0.55;
      children.add(Positioned(
        top: -size * 0.05,
        left: -size * 0.05,
        width: fxSize,
        height: fxSize,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) =>
              CustomPaint(painter: NftSparklesPainter(_anim.value)),
        ),
      ));
    }

    // Bottom-left badge slot (overhangs the corner). XMTP and phantom share it
    // and are mutually exclusive.
    if (_isXmtpOnly) {
      children.add(Positioned(
        left: -badgeSize * 0.28,
        bottom: -badgeSize * 0.28,
        child: _XmtpBadge(size: badgeSize, ringColor: tokens.surfaceElevated),
      ));
    } else if (_isPrivate == true) {
      // A private individual that declares `automated_account` wears a robot
      // instead of the ghost. Never on a citizen: the private check above
      // already rules that out. Same as the mobile client.
      final c = widget.contact;
      final robot = c != null && c.isAutomatedAccount && !c.isOrgAccount;
      children.add(Positioned(
        left: -badgeSize * 0.28,
        bottom: -badgeSize * 0.28,
        child: robot
            ? _RobotBadge(
                size: badgeSize,
                bg: tokens.surfaceElevated,
                fg: tokens.textDim,
              )
            : _PhantomBadge(
                size: badgeSize,
                bg: tokens.surfaceElevated,
                ghost: tokens.textDim,
              ),
      ));
    }

    final Widget stack = SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: children),
    );

    final onTap = widget.onTap ??
        (widget.opensProfile
            ? GlassContactIcon.profileTap(context,
                contact: widget.contact, address: widget.address)
            : null);
    final hasGesture = onTap != null || widget.onLongPress != null;
    final tappable = hasGesture
        ? GestureDetector(
            onTap: onTap,
            onLongPress: widget.onLongPress,
            child: stack,
          )
        : stack;

    final Widget result = widget.heroTag != null
        ? Hero(tag: widget.heroTag!, child: tappable)
        : tappable;

    return RepaintBoundary(child: result);
  }
}

/// The name (or any text block) beside a [GlassContactIcon] that opens the
/// profile: wrap it in this so avatar and name behave as one target. Same tap
/// as [GlassContactIcon.opensProfile]; with no account to open it is inert.
class ContactProfileTap extends StatelessWidget {
  final Contact? contact;
  final String? address;
  final Widget child;

  const ContactProfileTap({
    super.key,
    this.contact,
    this.address,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final onTap =
        GlassContactIcon.profileTap(context, contact: contact, address: address);
    if (onTap == null) return child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: child,
    );
  }
}

/// The waiting state of an avatar that *has* artwork on the way — a neutral
/// block in the frame colour, sweeping while the image resolves.
///
/// Owns its ticker, which is the point: [NftImage] stops building the
/// placeholder the instant the image lands, so this widget is disposed and the
/// ticker goes with it. Nothing has to observe the load to switch the animation
/// off.
///
/// Below [_sweepFloor] the sweep reads as flicker rather than motion (the feed's
/// 14px byline avatar), so small icons get a flat fill.
class _AvatarSkeleton extends StatefulWidget {
  final double size;
  final double radius;
  final Color base;
  final Color highlight;

  const _AvatarSkeleton({
    required this.size,
    required this.radius,
    required this.base,
    required this.highlight,
  });

  /// Smallest icon that still earns an animated sweep.
  static const double _sweepFloor = 24.0;

  static const Duration _period = Duration(milliseconds: 1200);

  /// Shared phase clock. Each skeleton seeds its own controller from the same
  /// elapsed time, so a list of avatars loading at once sweeps in step without
  /// anyone having to host a controller they can all share.
  static final Stopwatch _phase = Stopwatch()..start();

  @override
  State<_AvatarSkeleton> createState() => _AvatarSkeletonState();
}

class _AvatarSkeletonState extends State<_AvatarSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: _AvatarSkeleton._period,
    );
    _syncSweep();
  }

  @override
  void didUpdateWidget(covariant _AvatarSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `size` is animated on a few surfaces (the social-graph fly), so it can
    // cross the floor mid-flight.
    if (oldWidget.size != widget.size) _syncSweep();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Run the sweep only at sizes where it reads as motion, phase-aligned to the
  /// shared clock. A stopped controller costs nothing per frame, so the small
  /// case just leaves it idle rather than skipping construction.
  void _syncSweep() {
    if (widget.size < _AvatarSkeleton._sweepFloor) {
      if (_ctrl.isAnimating) _ctrl.stop();
      return;
    }
    if (_ctrl.isAnimating) return;
    final periodMs = _AvatarSkeleton._period.inMilliseconds;
    _ctrl
      ..value = (_AvatarSkeleton._phase.elapsedMilliseconds % periodMs) /
          periodMs
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size < _AvatarSkeleton._sweepFloor) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return ShimmerBox(
      progress: _ctrl,
      width: widget.size,
      height: widget.size,
      radius: widget.radius,
      base: widget.base,
      highlight: widget.highlight,
    );
  }
}

/// The automated-account badge: the phantom's disc with a robot in it, for a
/// private account that declares `automated_account` (same as the client).
class _RobotBadge extends StatelessWidget {
  final double size;
  final Color bg;
  final Color fg;
  const _RobotBadge({required this.size, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Icon(Icons.smart_toy_rounded, size: size * 0.62, color: fg),
      ),
    );
  }
}

/// The phantom (ghost) badge — marks a private-group account. Borderless cutout:
/// a filled disc in the container color with a little ghost floating in it.
class _PhantomBadge extends StatelessWidget {
  final double size;
  final Color bg;
  final Color ghost;
  const _PhantomBadge(
      {required this.size, required this.bg, required this.ghost});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.62, size * 0.62),
          painter: _GhostPainter(ghost),
        ),
      ),
    );
  }
}

/// The private-account ghost — the same badge `GlassContactIcon` hangs on a
/// private account's avatar — as a standalone glyph, for inline use in text
/// (the Services page summary).
class PhantomBadge extends StatelessWidget {
  final double size;
  const PhantomBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return _PhantomBadge(
      size: size,
      bg: tokens.surfaceElevated,
      ghost: tokens.textDim,
    );
  }
}

class _GhostPainter extends CustomPainter {
  final Color color;
  _GhostPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Body: rounded dome top + wavy bottom hem.
    final path = Path();
    path.moveTo(w * 0.06, h);
    path.lineTo(w * 0.06, h * 0.45);
    path.arcToPoint(
      Offset(w * 0.94, h * 0.45),
      radius: Radius.circular(w * 0.44),
      clockwise: true,
    );
    path.lineTo(w * 0.94, h);
    // three little humps along the bottom
    path.cubicTo(w * 0.80, h * 0.86, w * 0.70, h * 0.86, w * 0.62, h);
    path.cubicTo(w * 0.54, h * 0.86, w * 0.46, h * 0.86, w * 0.38, h);
    path.cubicTo(w * 0.30, h * 0.86, w * 0.20, h * 0.86, w * 0.06, h);
    path.close();
    canvas.drawPath(path, paint);

    // Eyes (knockout in the bg color is not available here; draw darker dots).
    final eye = Paint()..color = const Color(0xFF0C0E13);
    canvas.drawCircle(Offset(w * 0.38, h * 0.50), w * 0.07, eye);
    canvas.drawCircle(Offset(w * 0.62, h * 0.50), w * 0.07, eye);
  }

  @override
  bool shouldRepaint(covariant _GhostPainter old) => old.color != color;
}

/// XMTP-only contact badge — the XMTP logo in the same bottom-left slot, with a
/// container-color ring so it blends. Mutually exclusive with the phantom.
class _XmtpBadge extends StatelessWidget {
  final double size;
  final Color ringColor;
  const _XmtpBadge({required this.size, required this.ringColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: size * 0.10),
      ),
      child: ClipOval(
        child: Image.asset('assets/xmtp.jpg', fit: BoxFit.cover),
      ),
    );
  }
}
