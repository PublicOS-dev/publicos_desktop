import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Enhanced vote card that displays detailed transaction information for
/// executeSafeTx votes.
///
/// Glass-dark surface — shares the
/// status-colour roles with [VoteCard]: active → `fallbackAccent`,
/// executed → `connectedAccent`, cancelled → `colorScheme.error`,
/// expired → `textDim`.
class EnhancedVoteCard extends StatefulWidget {
  final VoteHistoryItem vote;
  final bool canVote;
  final VoidCallback? onVote;

  const EnhancedVoteCard({
    super.key,
    required this.vote,
    this.canVote = false,
    this.onVote,
  });

  @override
  State<EnhancedVoteCard> createState() => _EnhancedVoteCardState();
}

class _EnhancedVoteCardState extends State<EnhancedVoteCard> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  String _votersSearchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Cache for resolved contact data
  final Map<String, Contact?> _contactCache = {};
  final Map<String, String?> _nameCache = {};

  SafeTransactionDetails? _transactionDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Analyze transaction if it's an executeSafeTx vote
    if (widget.vote.actionType == VoteActionType.executeSafeTx) {
      _transactionDetails = SafeTransactionAnalyzer.analyzeTransaction(widget.vote.parameters);
      _loadContactsForTransaction();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContactsForTransaction() async {
    if (_transactionDetails == null) return;

    try {
      // Load contact information for transaction participants
      final toContact = await _getContactFromAddress(_transactionDetails!.to);
      final currentUserAddress = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x;
      Contact? fromContact;

      if (currentUserAddress != null) {
        fromContact = await _getContactFromAddress(currentUserAddress);
      }

      if (mounted) {
        setState(() {
          _transactionDetails = SafeTransactionDetails(
            to: _transactionDetails!.to,
            value: _transactionDetails!.value,
            data: _transactionDetails!.data,
            type: _transactionDetails!.type,
            methodName: _transactionDetails!.methodName,
            decodedParameters: _transactionDetails!.decodedParameters,
            toContact: toContact,
            fromContact: fromContact,
          );
        });
      }
    } catch (e) {
      print('Error loading contacts for transaction: $e');
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
    HapticFeedback.lightImpact();
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

  IconData _statusIcon() {
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
          if (isActive) Container(height: 2, color: tokens.fallbackAccent),
          // Main card content
          GestureDetector(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      _buildStatusIcon(tokens, statusColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getEnhancedActionDisplayName(),
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
                      _buildStatusChip(statusColor),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: tokens.textDim,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Enhanced transaction summary for executeSafeTx
                  if (widget.vote.actionType == VoteActionType.executeSafeTx &&
                      _transactionDetails != null)
                    _buildTransactionSummary(tokens),

                  const SizedBox(height: 8),

                  // Progress bar
                  _buildProgressBar(tokens),
                  const SizedBox(height: 8),

                  // Vote count
                  Text(
                    context.l10n.enhancedVoteCardVotesCount(
                        widget.vote.yesVotes, widget.vote.requiredThreshold),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: tokens.textDim,
                    ),
                  ),

                  // Vote button for active votes
                  if (widget.vote.isActive && widget.canVote) ...[
                    const SizedBox(height: 12),
                    SystemAppActionButton(
                      label: context.l10n.enhancedVoteCardCastVote,
                      icon: Icons.how_to_vote_rounded,
                      onTap: widget.onVote,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expandable details
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: _buildExpandedContent(tokens),
          ),
        ],
      ),
    );
  }

  String _getEnhancedActionDisplayName() {
    if (widget.vote.actionType == VoteActionType.executeSafeTx && _transactionDetails != null) {
      if (_transactionDetails!.isEthTransfer) {
        return context.l10n
            .enhancedVoteCardSendValue(_transactionDetails!.displayValue);
      } else if (_transactionDetails!.isContractCall) {
        return context.l10n.enhancedVoteCardExecuteMethod(
            _transactionDetails!.methodName ??
                context.l10n.enhancedVoteCardContractCall);
      }
    }
    return widget.vote.actionDisplayName;
  }

  Widget _buildTransactionSummary(GlassTokens tokens) {
    if (_transactionDetails == null) return const SizedBox.shrink();

    final isTransfer = _transactionDetails!.isEthTransfer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.glassFillHover,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Row(
        children: [
          // Transaction icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTransfer
                  ? tokens.connectedAccent.withValues(alpha: 0.12)
                  : tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTransfer
                    ? tokens.connectedAccent.withValues(alpha: 0.3)
                    : tokens.borderSubtle,
              ),
            ),
            child: Icon(
              isTransfer ? Icons.send_rounded : Icons.code_rounded,
              size: 16,
              color: isTransfer ? tokens.connectedAccent : tokens.starkWhite,
            ),
          ),
          const SizedBox(width: 12),
          // Transaction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // From contact
                    if (_transactionDetails!.fromContact != null) ...[
                      GlassContactIcon(
                        contact: _transactionDetails!.fromContact,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _transactionDetails!.fromContact!.displayName,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ] else ...[
                      Text(
                        context.l10n.enhancedVoteCardGroupWallet,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: tokens.textDim),
                    const SizedBox(width: 8),
                    // To contact
                    if (_transactionDetails!.toContact != null) ...[
                      GlassContactIcon(
                        contact: _transactionDetails!.toContact,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _transactionDetails!.toContact!.displayName,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: tokens.starkWhite,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      Text(
                        _transactionDetails!.formattedTo,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.starkWhite,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_transactionDetails!.ethValue > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    _transactionDetails!.displayValue,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: tokens.connectedAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(GlassTokens tokens, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Icon(_statusIcon(), color: statusColor, size: 18),
    );
  }

  Widget _buildStatusChip(Color statusColor) {
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

  Widget _buildProgressBar(GlassTokens tokens) {
    final fillColor = widget.vote.isActive
        ? tokens.fallbackAccent
        : widget.vote.isExecuted
            ? tokens.connectedAccent
            : tokens.borderMedium;

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: tokens.glassFillHover,
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: widget.vote.progressPercentage.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
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

          // Initiator with contact icon
          _buildInitiatorRow(tokens),
          const SizedBox(height: 12),

          // Enhanced transaction details for executeSafeTx
          if (widget.vote.actionType == VoteActionType.executeSafeTx &&
              _transactionDetails != null)
            _buildDetailedTransactionInfo(tokens),

          // Start time
          _buildDetailRow(tokens, context.l10n.enhancedVoteCardStarted,
              _formatDateTime(widget.vote.startTime)),
          const SizedBox(height: 8),

          // End time
          if (widget.vote.endTime != null)
            _buildDetailRow(
              tokens,
              widget.vote.isExecuted
                  ? context.l10n.enhancedVoteCardExecuted
                  : context.l10n.enhancedVoteCardEnded,
              _formatDateTime(widget.vote.endTime!),
            ),
          if (widget.vote.endTime != null) const SizedBox(height: 8),

          // Voters section
          if (widget.vote.voters.isNotEmpty) ..._buildVotersSection(tokens),
        ],
      ),
    );
  }

  Widget _buildDetailedTransactionInfo(GlassTokens tokens) {
    if (_transactionDetails == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(tokens, context.l10n.enhancedVoteCardTransactionDetails),
        const SizedBox(height: 8),
        _buildDetailRow(
            tokens,
            context.l10n.enhancedVoteCardType,
            _transactionDetails!.isEthTransfer
                ? context.l10n.enhancedVoteCardEthTransfer
                : context.l10n.enhancedVoteCardContractCall),
        const SizedBox(height: 4),
        _buildDetailRow(
            tokens, context.l10n.enhancedVoteCardTo, _transactionDetails!.formattedTo),
        const SizedBox(height: 4),
        if (_transactionDetails!.ethValue > 0)
          _buildDetailRow(tokens, context.l10n.enhancedVoteCardAmount,
              _transactionDetails!.displayValue),
        if (_transactionDetails!.methodName != null) ...[
          const SizedBox(height: 4),
          _buildDetailRow(tokens, context.l10n.enhancedVoteCardMethod,
              _transactionDetails!.methodName!),
        ],
        if (_transactionDetails!.decodedParameters != null &&
            _transactionDetails!.decodedParameters!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildSectionLabel(tokens, context.l10n.enhancedVoteCardParameters),
          const SizedBox(height: 4),
          ..._transactionDetails!.decodedParameters!.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _buildDetailRow(tokens, entry.key, entry.value.toString()),
            ),
          ),
        ],
        const SizedBox(height: 12),
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

  Widget _buildDetailRow(GlassTokens tokens, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              color: tokens.textDim,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: tokens.starkWhite,
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeDisplay() {
    final l10n = context.l10n;
    final now = DateTime.now();
    final startTime = widget.vote.startTime;
    final difference = now.difference(startTime);

    if (widget.vote.isActive) {
      if (difference.inHours < 1) {
        return l10n.enhancedVoteCardMinutesAgo(difference.inMinutes);
      } else if (difference.inDays < 1) {
        return l10n.enhancedVoteCardHoursAgo(difference.inHours);
      } else {
        return l10n.enhancedVoteCardDaysAgoShort(difference.inDays);
      }
    } else {
      if (difference.inDays < 1) {
        return l10n.enhancedVoteCardToday;
      } else if (difference.inDays == 1) {
        return l10n.enhancedVoteCardYesterday;
      } else if (difference.inDays < 7) {
        return l10n.enhancedVoteCardDaysAgo(difference.inDays);
      } else {
        return l10n.enhancedVoteCardWeeksAgo((difference.inDays / 7).floor());
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
      return l10n.enhancedVoteCardTodayAt(time);
    } else if (difference.inDays == 1) {
      return l10n.enhancedVoteCardYesterdayAt(time);
    } else if (difference.inDays < 7) {
      final weekdays = [
        l10n.enhancedVoteCardWeekdayMon,
        l10n.enhancedVoteCardWeekdayTue,
        l10n.enhancedVoteCardWeekdayWed,
        l10n.enhancedVoteCardWeekdayThu,
        l10n.enhancedVoteCardWeekdayFri,
        l10n.enhancedVoteCardWeekdaySat,
        l10n.enhancedVoteCardWeekdaySun,
      ];
      return l10n.enhancedVoteCardWeekdayAt(weekdays[dateTime.weekday - 1], time);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Build initiator row with contact icon and name
  Widget _buildInitiatorRow(GlassTokens tokens) {
    return FutureBuilder<Contact?>(
      future: _getContactFromAddress(widget.vote.initiator),
      builder: (context, snapshot) {
        final contact = snapshot.data;

        return Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                context.l10n.enhancedVoteCardInitiatedBy,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.textDim,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  GlassContactIcon(
                    contact: contact,
                    address: widget.vote.initiator,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact?.displayName ??
                              _formatAddress(widget.vote.initiator),
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.starkWhite,
                          ),
                        ),
                        if (contact != null)
                          Text(
                            _formatAddress(widget.vote.initiator),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: tokens.textDim,
                            ),
                          ),
                      ],
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

  /// Build voters section with search and horizontal scroll
  List<Widget> _buildVotersSection(GlassTokens tokens) {
    final filteredVoters = _getFilteredVoters();

    return [
      // Header with count
      Row(
        children: [
          _buildSectionLabel(tokens,
              context.l10n.enhancedVoteCardVotersCount(widget.vote.voters.length)),
          const Spacer(),
          // Search box (40% width) - only show when >10 voters
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
                  setState(() {
                    _votersSearchQuery = value.toLowerCase();
                  });
                },
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.starkWhite,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.enhancedVoteCardSearchVoters,
                  hintStyle: TextStyle(color: tokens.textDim, fontSize: 12),
                  prefixIcon:
                      Icon(Icons.search, size: 16, color: tokens.textDim),
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
                    borderSide:
                        BorderSide(color: tokens.borderMedium, width: 1.5),
                  ),
                ),
              ),
            ))),
        ],
      ),
      const SizedBox(height: 8),

      // Horizontal scrollable voters list
      SizedBox(
        height: 80, // Fixed height for consistent layout
        child: filteredVoters.isEmpty
            ? Center(
                child: Text(
                  _votersSearchQuery.isNotEmpty
                      ? context.l10n.enhancedVoteCardNoVotersMatch
                      : context.l10n.enhancedVoteCardNoVotersYet,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              )
            : // DESKTOP DELTA: Flutter's default ScrollBehavior excludes
                // mouse from dragDevices, so without this the horizontal strip
                // is undraggable with a mouse. Same fix as
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
                  final voterAddress = filteredVoters[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildVoterItem(tokens, voterAddress),
                  );
                },
              ))),
      ),
    ];
  }

  /// Build individual voter item with contact icon
  Widget _buildVoterItem(GlassTokens tokens, String voterAddress) {
    return FutureBuilder<Contact?>(
      future: _getContactFromAddress(voterAddress),
      builder: (context, snapshot) {
        final contact = snapshot.data;

        return SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassContactIcon(
                contact: contact,
                address: voterAddress,
                size: 40,
              ),
              const SizedBox(height: 4),
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

  /// Get filtered voters based on search query
  List<String> _getFilteredVoters() {
    if (_votersSearchQuery.isEmpty) {
      return widget.vote.voters;
    }

    return widget.vote.voters.where((voterAddress) {
      // Check if address matches
      if (voterAddress.toLowerCase().contains(_votersSearchQuery)) {
        return true;
      }

      // Check if cached name matches
      final cachedName = _nameCache[voterAddress];
      if (cachedName != null && cachedName.toLowerCase().contains(_votersSearchQuery)) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Get enriched contact from address with caching
  Future<Contact?> _getContactFromAddress(String address) async {
    if (_contactCache.containsKey(address)) {
      return _contactCache[address];
    }

    try {
      final ethAddress = EthereumAddress.fromHex(address);
      Contact? contact;

      // Step 1: Try to find locally stored contact first (searchLocalContact)
      // Try by address first, then by display name if we can resolve one
      contact = await PublicOSContacts.searchContacts(address);

      // If not found by address, try to get the display name and search by that
      if (contact == null) {
        String? displayName = await PublicOSContacts.getPublicosDisplayNameByAccountAddress(ethAddress);
        if (displayName != null) {
          contact = await PublicOSContacts.searchContacts(displayName);
        }
      }

      // Step 2: If not found locally, try harder with fetchContact
      if (contact == null) {
        try {
          contact = await PublicOSContacts.fetchContact(ethAddress);
        } catch (e) {
          print('Failed to get updated contact for $address: $e');
          // Continue to fallback
        }
      }

      // Step 3: If still no contact, cache the display name for search filtering
      if (contact == null) {
        String? displayName = _nameCache[address];
        if (displayName == null) {
          displayName = await PublicOSContacts.getPublicosDisplayNameByAccountAddress(ethAddress);
          _nameCache[address] = displayName;
        }
      } else {
        // Cache the contact's display name for search filtering
        _nameCache[address] = contact.displayName;
      }

      _contactCache[address] = contact;
      return contact;
    } catch (e) {
      print('Error resolving contact for $address: $e');
      _contactCache[address] = null;
      return null;
    }
  }
}
