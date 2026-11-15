import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Horizontal overlapping stack of contact avatars with a right-edge fade
/// and a `+N` chip when the list exceeds [maxVisible].
///
/// Used in two places on the org Management screen:
///   1. Membership tile — flat list, no voter styling
///   2. Live vote roster — pass [votedAddresses] to ring members who have
///      cast a ballot (For/Against/Abstain, since the 3-way engine) with the
///      connected accent and dim the members who haven't voted yet
///
/// The fade is anchored to the right edge in absolute pixels (last ~56 px
/// fades to transparent), so the `+N` chip — absolutely positioned at
/// `right: 0` — always sits in a clean area regardless of how many dots fit.
class ContactStack extends StatelessWidget {
  final List<Contact> contacts;

  /// EIP-55 addresses of members who have cast a ballot on the active vote.
  /// When non-empty, all dots are styled: voters get a 2px connected-accent
  /// ring, non-voters are dimmed. Empty = neutral styling (used by Members).
  /// NB "voted" means participated — not necessarily a For vote (3-way engine).
  final Set<String> votedAddresses;

  final VoidCallback? onTap;
  final int maxVisible;
  final double dotSize;

  const ContactStack({
    super.key,
    required this.contacts,
    this.votedAddresses = const <String>{},
    this.onTap,
    this.maxVisible = 10,
    this.dotSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final visible = contacts.take(maxVisible).toList();
    final overflow = contacts.length - visible.length;
    final hasVoterStyling = votedAddresses.isNotEmpty;
    // Overlap scales with dot size so big avatars still hug each other.
    final overlap = dotSize * 0.30;

    final stackInnerWidth = visible.isEmpty
        ? 0.0
        : dotSize + (visible.length - 1) * (dotSize - overlap);

    // Z-order: leftmost dot is the biggest and frontmost; subsequent dots
    // shrink and recede behind it. Iterate right-to-left so later children
    // (Stack paints later = on top) are the LEFTmost ones.
    const minScale = 0.72;
    final shrinkPerStep = visible.length <= 1 ? 0.0 : (1.0 - minScale) / (visible.length - 1);

    final stackedDots = SizedBox(
      width: stackInnerWidth,
      height: dotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = visible.length - 1; i >= 0; i--)
            () {
              final scale = (1.0 - i * shrinkPerStep).clamp(minScale, 1.0);
              final scaledSize = dotSize * scale;
              return Positioned(
                left: i * (dotSize - overlap),
                top: (dotSize - scaledSize) / 2,
                child: _Dot(
                  contact: visible[i],
                  size: scaledSize,
                  isVoted: hasVoterStyling && _hasVoted(visible[i]),
                  isDimmed: hasVoterStyling && !_hasVoted(visible[i]),
                  tokens: tokens,
                ),
              );
            }(),
        ],
      ),
    );

    final maskedStack = ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          // Fade only the trailing ~56 px (chip width + small breathing room)
          // so the +N chip lands in a fully transparent zone. When the stack
          // is shorter than the available width, fading the empty right side
          // is a no-op visually.
          final w = rect.width;
          if (w <= 0) return const LinearGradient(colors: [Colors.black, Colors.black]).createShader(rect);
          // Fade zone scales with dot size so a trailing avatar dissolves
          // behind the +N chip regardless of how big the avatars are.
          final fadeZone = dotSize + 16;
          final fadeStart = ((w - fadeZone) / w).clamp(0.0, 1.0);
          final fadeEnd = ((w - 6) / w).clamp(0.0, 1.0);
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.0, fadeStart, fadeEnd],
            colors: const [Colors.black, Colors.black, Color(0x00000000)],
          ).createShader(rect);
        },
        child: Align(
          alignment: Alignment.centerLeft,
          child: stackedDots,
        ),
      ),
    );

    final body = SizedBox(
      height: dotSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: maskedStack),
          if (overflow > 0)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: _MoreChip(
                  count: overflow,
                  tokens: tokens,
                  // Chip stays compact even when avatars are big — otherwise
                  // a "+2" pill becomes square-chunky at dotSize=40. Centered
                  // vertically in the stack row.
                  height: dotSize.clamp(22.0, 26.0),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: body,
      ),
    );
  }

  bool _hasVoted(Contact c) {
    final addr = c.publicosAddress?.eip55With0x;
    return addr != null && votedAddresses.contains(addr);
  }
}

class _Dot extends StatelessWidget {
  final Contact contact;
  final double size;
  final bool isVoted;
  final bool isDimmed;
  final GlassTokens tokens;

  const _Dot({
    required this.contact,
    required this.size,
    required this.isVoted,
    required this.isDimmed,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final color = contact.iconColor;
    final initials = contact.initials;
    final imageUrl = contact.getRecordValue('profile.avatar.resolved') ??
        contact.avatarUrl;
    final radius = size * (6 / 22);
    final ringColor = isVoted ? tokens.connectedAccent : tokens.surfaceDeep;
    final ringWidth = isVoted ? 2.0 : 1.0;

    final inner = (imageUrl != null && imageUrl.isNotEmpty)
        ? ZeroCachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialsView(color, initials),
            errorWidget: (_, __, ___) => _initialsView(color, initials),
          )
        : _initialsView(color, initials);

    Widget framed = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ringColor, width: ringWidth),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: inner,
      ),
    );

    if (isDimmed) {
      framed = Opacity(opacity: 0.45, child: framed);
    }

    return framed;
  }

  Widget _initialsView(Color color, String initials) {
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;
  final GlassTokens tokens;
  final double height;

  const _MoreChip({
    required this.count,
    required this.tokens,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Text(
        '+$count',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tokens.textDim,
        ),
      ),
    );
  }
}
