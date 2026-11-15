import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_bottom_sheet.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// A card widget that displays voting information with expandable details.
///
/// Glass-dark surface. Status colour roles: active → `fallbackAccent`
/// (pending / needs attention),
/// executed → `connectedAccent` (approved), cancelled → `colorScheme.error`,
/// expired → `textDim` (neutral / dead).
class VoteCard extends StatefulWidget {
  final VoteHistoryItem vote;
  final bool canVote;
  final VoidCallback? onVote;

  const VoteCard({
    super.key,
    required this.vote,
    this.canVote = false,
    this.onVote,
  });

  @override
  State<VoteCard> createState() => _VoteCardState();
}

class _VoteCardState extends State<VoteCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  String _votersSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, Contact?> _contactCache = {};
  final Map<String, String?> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color _statusColor(GlassTokens tokens) {
    switch (widget.vote.status) {
      case VoteStatus.active:
        return tokens.fallbackAccent;
      case VoteStatus.executed:
        return tokens.connectedAccent;
      case VoteStatus.cancelled:
        return Theme.of(context).colorScheme.error;
      case VoteStatus.expired:
        return tokens.textDim;
      case VoteStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.vote.status) {
      case VoteStatus.active:
        return Icons.pending_actions_outlined;
      case VoteStatus.executed:
        return Icons.check_circle_outline;
      case VoteStatus.cancelled:
        return Icons.cancel_outlined;
      case VoteStatus.expired:
        return Icons.schedule_outlined;
      case VoteStatus.failed:
        return Icons.block_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final statusColor = _statusColor(tokens);
    final isActive = widget.vote.isActive;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? tokens.fallbackAccent.withValues(alpha: 0.4)
              : tokens.borderSubtle,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Accent top border for active votes
          if (isActive)
            Container(height: 2, color: tokens.fallbackAccent),
          // Main content
          GestureDetector(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(tokens, statusColor),
                  const SizedBox(height: 14),
                  _buildProgressSection(tokens),
                  if (widget.vote.isActive && widget.canVote) ...[
                    const SizedBox(height: 14),
                    SystemAppActionButton(
                      label: context.l10n.voteCardCastVote,
                      icon: Icons.how_to_vote_rounded,
                      onTap: widget.onVote,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Expanded content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(tokens),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(GlassTokens tokens, Color statusColor) {
    return Row(
      children: [
        // Status icon
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Icon(_getStatusIcon(), color: statusColor, size: 18),
        ),
        const SizedBox(width: 12),
        // Title and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.vote.actionDisplayName,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.starkWhite,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getTimeDisplay(),
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.textDim,
                ),
              ),
            ],
          ),
        ),
        // Status badge
        _buildStatusBadge(statusColor),
        const SizedBox(width: 8),
        // Expand icon
        RotationTransition(
          turns: _rotateAnimation,
          child: Icon(
            Icons.expand_more_rounded,
            color: tokens.textDim,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        widget.vote.statusDisplayName.toUpperCase(),
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          color: statusColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildProgressSection(GlassTokens tokens) {
    final progress = widget.vote.progressPercentage;
    final isComplete = widget.vote.yesVotes >= widget.vote.requiredThreshold;
    final fillColor = isComplete
        ? tokens.connectedAccent
        : widget.vote.isActive
            ? tokens.fallbackAccent
            : tokens.borderMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: tokens.glassFillHover,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Vote count
        Row(
          children: [
            Icon(Icons.how_to_vote_outlined, size: 14, color: tokens.textDim),
            const SizedBox(width: 6),
            Text(
              '${widget.vote.yesVotes}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.starkWhite,
              ),
            ),
            Text(
              context.l10n.voteCardVotesOfThreshold(widget.vote.requiredThreshold),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: tokens.textDim,
              ),
            ),
            if (widget.vote.isActive) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tokens.fallbackAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: tokens.fallbackAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pending_outlined,
                        size: 12, color: tokens.fallbackAccent),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.voteCardPending,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 11,
                        color: tokens.fallbackAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: tokens.borderSubtle, height: 1),
          const SizedBox(height: 12),

          // Initiator
          _buildInitiatorRow(tokens),
          const SizedBox(height: 14),

          // Timestamps
          _buildTimestampRow(tokens, context.l10n.voteCardStarted,
              widget.vote.startTime,
              isStart: true),
          if (widget.vote.endTime != null) ...[
            const SizedBox(height: 8),
            _buildTimestampRow(
              tokens,
              widget.vote.isExecuted
                  ? context.l10n.voteCardExecuted
                  : context.l10n.voteCardEnded,
              widget.vote.endTime!,
            ),
          ],

          // Parameters
          if (widget.vote.displayParameters.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSectionLabel(tokens, context.l10n.voteCardDetails),
            const SizedBox(height: 8),
            ...widget.vote.displayParameters.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildParameterRow(tokens, entry.key, entry.value),
              );
            }),
          ],

          // Voters
          if (widget.vote.voters.isNotEmpty) ...[
            const SizedBox(height: 16),
            ..._buildVotersSection(tokens),
          ],
        ],
      ),
    );
  }

  Widget _buildInitiatorRow(GlassTokens tokens) {
    return FutureBuilder<Contact?>(
      future: _getContactFromAddress(widget.vote.initiator),
      builder: (context, snapshot) {
        final contact = snapshot.data;

        return Row(
          children: [
            GlassContactIcon(
              contact: contact,
              address: widget.vote.initiator,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.voteCardInitiatedBy,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: tokens.textDim,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    contact?.displayName ?? _formatAddress(widget.vote.initiator),
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.starkWhite,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimestampRow(GlassTokens tokens, String label, DateTime dateTime,
      {bool isStart = false}) {
    return Row(
      children: [
        Icon(
          isStart
              ? Icons.play_circle_outline
              : Icons.stop_circle_outlined,
          size: 16,
          color: tokens.textDim,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.textDim,
          ),
        ),
        Text(
          _formatDateTime(dateTime),
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 12,
            color: tokens.starkWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(GlassTokens tokens, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: tokens.textDim,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildParameterRow(GlassTokens tokens, String key, String value) {
    return GestureDetector(
      onTap: () => _showParameterDetail(context, key, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: tokens.glassFillHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Text(
              key,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                color: tokens.textDim,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: tokens.starkWhite,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded, size: 14, color: tokens.textDim),
          ],
        ),
      ),
    );
  }

  void _showParameterDetail(BuildContext context, String key, String value) {
    final tokens = GlassTokens.of(context);
    showPhigitalBottomSheet(
      context: context,
      wrapInChrome: false,
      builder: (ctx, sheetDark) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20), // a dialog on desktop: all four corners
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: tokens.borderMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: tokens.starkWhite,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: value));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.voteCardCopied(key)),
                                behavior: SnackBarBehavior.fixed,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: tokens.surfaceElevated,
                              border: Border.all(color: tokens.borderMedium),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded,
                                    size: 14, color: tokens.starkWhite),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.voteCardCopy,
                                  style: TextStyle(
                                    fontFamily: 'SpaceGrotesk',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: tokens.starkWhite,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Full content
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: tokens.glassFillHover,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: SelectableText(
                        value,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          height: 1.5,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildVotersSection(GlassTokens tokens) {
    final filteredVoters = _getFilteredVoters();

    return [
      Row(
        children: [
          _buildSectionLabel(
              tokens, context.l10n.voteCardVoters(widget.vote.voters.length)),
          const Spacer(),
          if (widget.vote.voters.length > 10)
            // DESKTOP DELTA: the client uses
            // `width: MediaQuery.size.width * 0.4`. On a phone that is 40% of
            // the row; on desktop MediaQuery.size is the WINDOW, while this
            // card sits inside the browser's much narrower content column — so
            // the field would overflow the Row. Flexible + a max bounds it to
            // the space the Row actually has.
            Flexible(
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: SizedBox(
              height: 34,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _votersSearchQuery = value.toLowerCase());
                },
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.starkWhite,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.voteCardSearchHint,
                  hintStyle: TextStyle(color: tokens.textDim, fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 16, color: tokens.textDim),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  filled: true,
                  fillColor: tokens.surfaceElevated,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            ))),
        ],
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 80,
        child: filteredVoters.isEmpty
            ? Center(
                child: Text(
                  _votersSearchQuery.isNotEmpty
                      ? context.l10n.voteCardNoMatches
                      : context.l10n.voteCardNoVoters,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              )
            : // DESKTOP DELTA: Flutter's default ScrollBehavior excludes
                // mouse from dragDevices, so without this the horizontal strip
                // is undraggable with a mouse. Same approach as
                // `explorer_chip.dart:177`.
                ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: HorizontalWheel(child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredVoters.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _buildVoterItem(tokens, filteredVoters[index]),
                  );
                },
              ))),
      ),
    ];
  }

  Widget _buildVoterItem(GlassTokens tokens, String voterAddress) {
    return FutureBuilder<Contact?>(
      future: _getContactFromAddress(voterAddress),
      builder: (context, snapshot) {
        final contact = snapshot.data;

        return SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContactIcon(
                contact: contact,
                address: voterAddress,
                size: 40,
              ),
              const SizedBox(height: 6),
              Text(
                contact?.displayName ?? _formatAddress(voterAddress),
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  color: tokens.textDim,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeDisplay() {
    final l10n = context.l10n;
    final now = DateTime.now();
    final difference = now.difference(widget.vote.startTime);

    if (widget.vote.isActive) {
      if (difference.inHours < 1) {
        return l10n.voteCardMinutesAgo(difference.inMinutes);
      } else if (difference.inDays < 1) {
        return l10n.voteCardHoursAgo(difference.inHours);
      } else {
        return l10n.voteCardDaysAgoShort(difference.inDays);
      }
    } else {
      if (difference.inDays < 1) {
        return l10n.voteCardToday;
      } else if (difference.inDays == 1) {
        return l10n.voteCardYesterday;
      } else if (difference.inDays < 7) {
        return l10n.voteCardDaysAgo(difference.inDays);
      } else {
        return l10n.voteCardWeeksAgo((difference.inDays / 7).floor());
      }
    }
  }

  String _formatAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  String _formatDateTime(DateTime dateTime) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (difference.inDays == 0) {
      return l10n.voteCardTodayAt(time);
    } else if (difference.inDays == 1) {
      return l10n.voteCardYesterdayAt(time);
    } else if (difference.inDays < 7) {
      final weekdays = [
        l10n.voteCardWeekdayMon,
        l10n.voteCardWeekdayTue,
        l10n.voteCardWeekdayWed,
        l10n.voteCardWeekdayThu,
        l10n.voteCardWeekdayFri,
        l10n.voteCardWeekdaySat,
        l10n.voteCardWeekdaySun,
      ];
      return l10n.voteCardWeekdayAt(weekdays[dateTime.weekday - 1], time);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  List<String> _getFilteredVoters() {
    if (_votersSearchQuery.isEmpty) {
      return widget.vote.voters;
    }

    return widget.vote.voters.where((voterAddress) {
      if (voterAddress.toLowerCase().contains(_votersSearchQuery)) {
        return true;
      }
      final cachedName = _nameCache[voterAddress];
      if (cachedName != null && cachedName.toLowerCase().contains(_votersSearchQuery)) {
        return true;
      }
      return false;
    }).toList();
  }

  Future<Contact?> _getContactFromAddress(String address) async {
    if (_contactCache.containsKey(address)) {
      return _contactCache[address];
    }

    try {
      final ethAddress = EthereumAddress.fromHex(address);
      Contact? contact;

      contact = await PublicOSContacts.searchContacts(address);

      if (contact == null) {
        String? displayName = await PublicOSContacts.getPublicosDisplayNameByAccountAddress(ethAddress);
        if (displayName != null) {
          contact = await PublicOSContacts.searchContacts(displayName);
        }
      }

      if (contact == null) {
        try {
          contact = await PublicOSContacts.fetchContact(ethAddress);
        } catch (e) {
          // Continue to fallback
        }
      }

      if (contact == null) {
        String? displayName = _nameCache[address];
        if (displayName == null) {
          displayName = await PublicOSContacts.getPublicosDisplayNameByAccountAddress(ethAddress);
          _nameCache[address] = displayName;
        }
      } else {
        _nameCache[address] = contact.displayName;
      }

      _contactCache[address] = contact;
      return contact;
    } catch (e) {
      _contactCache[address] = null;
      return null;
    }
  }
}
