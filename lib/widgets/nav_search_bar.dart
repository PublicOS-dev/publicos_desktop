import 'package:flutter/material.dart';
// Keep this import for general access

class NavSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? hintText; // This will become a fallback/unused for animated part
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;

  // New properties for animated hint text
  final PageController? pageController;
  final List<String> movingHintWords; // e.g., ['Identities', 'XMTP', 'Wallets']

  const NavSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.pageController, // Make optional
    this.movingHintWords = const [], // Provide a default empty list
  });

  @override
  State<NavSearchBar> createState() => _NavSearchBarState();
}

class _NavSearchBarState extends State<NavSearchBar> {
  bool _isComposing = false;
  double _currentPageOffset = 0.0;
  FocusNode? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateIsComposing);
    _isComposing = widget.controller.text.isNotEmpty;

    // Listen to pageController scroll events
    widget.pageController?.addListener(_handlePageScroll);

    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateIsComposing);
    widget.pageController?.removeListener(_handlePageScroll);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _updateIsComposing() {
    if (mounted && (widget.controller.text.isNotEmpty != _isComposing)) {
      setState(() {
        _isComposing = widget.controller.text.isNotEmpty;
      });
    }
  }

  void _handlePageScroll() {
    if (widget.pageController != null && widget.pageController!.hasClients) {
      setState(() {
        _currentPageOffset = widget.pageController!.page ?? widget.pageController!.initialPage.toDouble();
      });
    }
  }

  void _handleSubmitted(String text) {
    if (text.isNotEmpty && widget.enabled) {
      widget.onSubmitted?.call(text);
    }
  }

  void _clearSearch() {
    if (widget.enabled) {
      widget.controller.clear();
      widget.onChanged?.call('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    // Determine the current and next hint word based on scroll offset
    final int currentPageIndex = _currentPageOffset.floor();
    final double scrollFraction = _currentPageOffset - currentPageIndex;

    final String currentWord = currentPageIndex < widget.movingHintWords.length ? widget.movingHintWords[currentPageIndex] : '';
    final String nextWord = (currentPageIndex + 1) < widget.movingHintWords.length ? widget.movingHintWords[currentPageIndex + 1] : '';
    final currentFocusNode = widget.focusNode ?? _internalFocusNode;

    return GestureDetector(
        onTap: () {
          if (currentFocusNode != null && !currentFocusNode.hasFocus) {
            currentFocusNode.requestFocus();
          }
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.040, // 7% of screen height
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.0),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Stack(
            // Use a Stack to layer the fixed text and animated text
            children: [
              TextField(
                controller: widget.controller,
                focusNode: currentFocusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                onChanged: (text) {
                  _updateIsComposing();
                  widget.onChanged?.call(text.toLowerCase());
                },
                onSubmitted: widget.enabled ? _handleSubmitted : null,
                decoration: InputDecoration(
                  hintText: '', // Empty hint text, we'll draw it manually
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none, 
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28), 
                    borderSide: BorderSide.none,
                  ),
                  hintStyle: textStyle,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  suffixIcon: _isComposing
                      ? IconButton(
                          icon: Icon(Icons.clear, color: theme.colorScheme.onSurfaceVariant),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 1,
                minLines: 1,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
              ),
              if (!_isComposing && widget.enabled) // Only show animated hint when not composing
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0), // Match TextField padding
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Search ', // Fixed "Search " prefix
                            style: textStyle,
                          ),
                          // Use a SizedBox and ClipRect to manage the animated word
                          SizedBox(
                            width: 100, // Adjust this width as needed for your longest word
                            child: ClipRect(
                              child: Stack(
                                children: [
                                  // Current word sliding out to the left
                                  Transform.translate(
                                    offset: Offset(-scrollFraction * 100, 0), // Adjust 100 for animation speed
                                    child: Opacity(
                                      opacity: 1 - scrollFraction,
                                      child: Text(currentWord, style: textStyle),
                                    ),
                                  ),
                                  // Next word sliding in from the right
                                  Transform.translate(
                                    offset: Offset((1 - scrollFraction) * 100, 0), // Adjust 100 for animation speed
                                    child: Opacity(
                                      opacity: scrollFraction,
                                      child: Text(nextWord, style: textStyle),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }
}
