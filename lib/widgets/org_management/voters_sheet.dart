import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/router_helpers.dart';

/// The roster of a live vote (a list sheet in the live card's language):
/// the tally as one For / Abstain / Against bar with
/// the quorum tick and a plain sentence, then VOTED and PENDING members as
/// flat rows. No boxed stats, no bordered rows. A row tap closes the sheet
/// and opens that member's profile (`AppNav.toContact`). Read-only: casting
/// happens on the live card.
Future<void> showVotersSheet(
  BuildContext context, {
  required VoteHistoryItem vote,
  required List<Contact> members,
}) {
  return showGlassSheetDialog<void>(
    context: context,
    width: DialogWidth.l,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetCtx) => _VotersSheet(
      vote: vote,
      members: members,
      onOpen: (c) {
        Navigator.of(sheetCtx).pop();
        AppNav.toContact(context, c);
      },
    ),
  );
}

class _VotersSheet extends StatelessWidget {
  final VoteHistoryItem vote;
  final List<Contact> members;
  final ValueChanged<Contact> onOpen;

  const _VotersSheet({
    required this.vote,
    required this.members,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final l10n = context.l10n;
    // `vote.voters` = everyone who cast a ballot (any support); per-person
    // support isn't attributed, the weighted split is the bar above.
    final votedLower = vote.voters.map((v) => v.toLowerCase()).toSet();
    final voted = <Contact>[];
    final pending = <Contact>[];
    for (final c in members) {
      final a = c.publicosAddress?.eip55With0x.toLowerCase();
      (a != null && votedLower.contains(a) ? voted : pending).add(c);
    }

    final floor = vote.requiredThreshold;
    final missing = floor - vote.forVotes - vote.abstainVotes;
    final sentence = missing > 0
        ? l10n.groupVotingViewNeedsMore(missing, floor)
        : (vote.forVotes <= vote.againstVotes ? l10n.groupVotingViewForMustLead : null);

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
              const SizedBox(height: 12),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.votersSheetTitle,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: tokens.starkWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Tally
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Count(
                          value: vote.forVotes,
                          label: l10n.votersSheetStatFor,
                          color: tokens.connectedAccent,
                          tokens: tokens,
                        ),
                        const SizedBox(width: 18),
                        _Count(
                          value: vote.abstainVotes,
                          label: l10n.votersSheetStatAbstain,
                          color: tokens.textDim,
                          tokens: tokens,
                        ),
                        const SizedBox(width: 18),
                        _Count(
                          value: vote.againstVotes,
                          label: l10n.votersSheetStatAgainst,
                          color: tokens.softDanger,
                          tokens: tokens,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _Bar(
                      tokens: tokens,
                      forW: vote.forVotes.toDouble(),
                      abstainW: vote.abstainVotes.toDouble(),
                      againstW: vote.againstVotes.toDouble(),
                      total: (members.length < floor ? floor : members.length).toDouble(),
                      floor: floor.toDouble(),
                    ),
                    if (sentence != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        sentence,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    if (voted.isNotEmpty) ...[
                      _SectionLabel(
                        text: l10n.votersSheetVoted(voted.length),
                        color: tokens.connectedAccent,
                      ),
                      for (final c in voted)
                        _Row(tokens: tokens, contact: c, voted: true, onTap: () => onOpen(c)),
                    ],
                    if (pending.isNotEmpty) ...[
                      _SectionLabel(
                        text: l10n.votersSheetPending(pending.length),
                        color: tokens.textDim,
                      ),
                      for (final c in pending)
                        _Row(tokens: tokens, contact: c, voted: false, onTap: () => onOpen(c)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final GlassTokens tokens;

  const _Count({
    required this.value,
    required this.label,
    required this.color,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: tokens.textDim,
          ),
        ),
      ],
    );
  }
}

/// Same bar as the live vote card: For green from the left, Abstain grey,
/// Against red from the right, a white tick at the quorum floor.
class _Bar extends StatelessWidget {
  final GlassTokens tokens;
  final double forW;
  final double abstainW;
  final double againstW;
  final double total;
  final double floor;

  const _Bar({
    required this.tokens,
    required this.forW,
    required this.abstainW,
    required this.againstW,
    required this.total,
    required this.floor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      double px(double v) => total <= 0 ? 0 : (v / total).clamp(0.0, 1.0) * w;
      final forPx = px(forW);
      final abstainPx = px(abstainW).clamp(0.0, w - forPx);
      final againstPx = px(againstW).clamp(0.0, w - forPx - abstainPx);
      final tick = (px(floor) - 1).clamp(0.0, w - 2);
      return SizedBox(
        height: 14,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(
                  children: [
                    Positioned.fill(child: Container(color: tokens.glassFillHover)),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: forPx,
                      child: Container(color: tokens.connectedAccent),
                    ),
                    Positioned(
                      left: forPx,
                      top: 0,
                      bottom: 0,
                      width: abstainPx,
                      child: Container(color: tokens.textDim.withValues(alpha: 0.6)),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: againstPx,
                      child: Container(color: tokens.softDanger),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: tick,
              top: 0,
              height: 14,
              width: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.starkWhite.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }
}

/// Pattern C row: no border, ripple on tap, avatar + name + short address.
class _Row extends StatelessWidget {
  final GlassTokens tokens;
  final Contact contact;
  final bool voted;
  final VoidCallback onTap;

  const _Row({
    required this.tokens,
    required this.contact,
    required this.voted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final addr = contact.publicosAddress?.eip55With0x ?? '';
    final addrShort = addr.length > 10
        ? '${addr.substring(0, 6)}…${addr.substring(addr.length - 4)}'
        : addr;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Opacity(
                  opacity: voted ? 1.0 : 0.5,
                  child: GlassContactIcon(contact: contact, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.displayName,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: voted ? tokens.starkWhite : tokens.textDim,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        addrShort,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: tokens.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (voted)
                  Icon(Icons.check_rounded, color: tokens.connectedAccent, size: 18),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: tokens.textDim, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
