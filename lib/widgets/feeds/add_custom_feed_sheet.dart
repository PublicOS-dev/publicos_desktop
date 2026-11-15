import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Manual-add bottom sheet: paste an RSS / Atom / JSON Feed URL, validate it
/// parses with at least one post, then add it.
///
/// Two modes, keyed on [listId]:
///   - `listId != null` — add the feed to that existing list
///     (`addFeedToList`).
///   - `listId == null` — follow the feed as its own `is_single` list
///     (`followFeedAsSingle`).
///
/// Either way the feed is stored with no `feedFoundAtAccountAddress` — there
/// is no on-chain discoverer for a manually-pasted feed, so the post-card
/// "via" line simply renders nothing (existing `foundAt == null` behavior).
/// Returns `true` if a feed was added so the caller can refresh.
Future<bool> showAddCustomFeedSheet(
  BuildContext context, {
  int? listId,
}) async {
  // DESKTOP DELTA: re-shelled from the client's bottom sheet to a glass dialog.
  final added = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: DialogWidth.m),
        child: _AddCustomFeedSheet(listId: listId),
      ),
    ),
  );
  return added ?? false;
}

class _AddCustomFeedSheet extends StatefulWidget {
  final int? listId;
  const _AddCustomFeedSheet({this.listId});

  @override
  State<_AddCustomFeedSheet> createState() => _AddCustomFeedSheetState();
}

enum _Phase { idle, checking, valid, error, adding }

class _AddCustomFeedSheetState extends State<_AddCustomFeedSheet> {
  final _controller = TextEditingController();

  _Phase _phase = _Phase.idle;
  String? _error;
  ParsedFeed? _feed;

  // The URL we actually validated — kept so "Add" stores exactly what we
  // fetched, not whatever the user typed afterwards.
  String? _validatedUrl;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trim, and prepend `https://` when the user left off a scheme.
  String _normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return url;
    final lower = url.toLowerCase();
    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }

  Future<void> _check() async {
    final url = _normalize(_controller.text);
    if (url.isEmpty) return;
    final l10n = context.l10n;
    FocusScope.of(context).unfocus();
    setState(() {
      _phase = _Phase.checking;
      _error = null;
      _feed = null;
      _validatedUrl = null;
    });

    try {
      final feed = await RssParser.fetchFeed(url);
      if (!mounted) return;
      if (feed.posts.isEmpty) {
        setState(() {
          _phase = _Phase.error;
          _error = l10n.addCustomFeedSheetNoPostsError;
        });
        return;
      }
      setState(() {
        _phase = _Phase.valid;
        _feed = feed;
        _validatedUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = _readableError(l10n, e);
      });
    }
  }

  /// Best-effort human message from `RssParser.fetchFeed`'s thrown string.
  /// It wraps everything as `Exception: Error fetching feed: <inner>` —
  /// `FEED_ERROR:HTTP_<code>` for non-200s, otherwise a parse / network
  /// failure we can't cleanly separate, so we point at the most common
  /// mistake (pasting the site URL instead of the feed URL).
  String _readableError(AppLocalizations l10n, Object e) {
    final s = e.toString();
    final httpMatch = RegExp(r'HTTP_(\d{3})').firstMatch(s);
    if (httpMatch != null) {
      return l10n.addCustomFeedSheetHttpError(httpMatch.group(1)!);
    }
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return l10n.addCustomFeedSheetNetworkError;
    }
    return l10n.addCustomFeedSheetReadError;
  }

  Future<void> _add() async {
    final url = _validatedUrl;
    final feed = _feed;
    if (url == null || feed == null) return;
    final l10n = context.l10n;
    setState(() => _phase = _Phase.adding);

    final title = feed.title.trim().isNotEmpty ? feed.title.trim() : null;
    final description =
        feed.description.trim().isNotEmpty ? feed.description.trim() : null;

    bool ok;
    if (widget.listId != null) {
      ok = await PublicOSFeedLists.addFeedToList(
        widget.listId!,
        url,
        title,
        description,
      );
    } else {
      final list = await PublicOSFeedLists.followFeedAsSingle(
        url,
        feedTitle: title,
        feedDescription: description,
      );
      ok = list != null;
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _phase = _Phase.error;
        _error = l10n.addCustomFeedSheetSaveError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final isList = widget.listId != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          // DESKTOP DELTA: all corners rounded, no drag handle — it floats as a
          // dialog rather than anchoring to the bottom edge.
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _header(tokens, isList),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _urlField(tokens),
                    const SizedBox(height: 12),
                    _checkButton(tokens),
                    if (_phase == _Phase.error && _error != null) ...[
                      const SizedBox(height: 14),
                      _errorBox(tokens),
                    ],
                    if (_phase == _Phase.valid ||
                        _phase == _Phase.adding) ...[
                      const SizedBox(height: 16),
                      _preview(tokens),
                      const SizedBox(height: 16),
                      _localOnlyNote(tokens),
                      const SizedBox(height: 14),
                      _addButton(tokens, isList),
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

  // DESKTOP DELTA: the client's drag handle is gone — a dialog has nothing to
  // drag. Its `_handle` builder went with it.

  Widget _header(GlassTokens tokens, bool isList) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isList
                    ? context.l10n.addCustomFeedSheetTitleList
                    : context.l10n.addCustomFeedSheetTitleFollow,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      );

  Widget _urlField(GlassTokens tokens) {
    return TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      onSubmitted: (_) => _check(),
      onChanged: (_) {
        // Any edit invalidates a prior check.
        if (_phase != _Phase.idle) {
          setState(() {
            _phase = _Phase.idle;
            _error = null;
            _feed = null;
            _validatedUrl = null;
          });
        }
      },
      style: TextStyle(color: tokens.starkWhite, fontSize: 14),
      decoration: InputDecoration(
        hintText: context.l10n.addCustomFeedSheetUrlHint,
        hintStyle: TextStyle(color: tokens.textDim, fontSize: 14),
        filled: true,
        fillColor: tokens.glassFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: tokens.borderMedium),
        ),
      ),
    );
  }

  Widget _checkButton(GlassTokens tokens) {
    final checking = _phase == _Phase.checking;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: tokens.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.borderMedium, width: 1),
        ),
        child: InkWell(
          onTap: checking ? null : _check,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: checking
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(tokens.textDim),
                      ),
                    )
                  : Text(
                      context.l10n.addCustomFeedSheetCheckButton,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBox(GlassTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.fallbackAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tokens.fallbackAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 16, color: tokens.fallbackAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(GlassTokens tokens) {
    final feed = _feed!;
    final previewPosts = feed.posts.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rss_feed_rounded,
                  size: 16, color: tokens.connectedAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feed.title.trim().isNotEmpty
                      ? feed.title.trim()
                      : context.l10n.addCustomFeedSheetUntitledFeed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (feed.description.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              feed.description.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.textDim,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(color: tokens.borderSubtle, height: 1),
          const SizedBox(height: 10),
          ...previewPosts.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5, right: 8),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: tokens.textDim,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.title.trim().isNotEmpty
                          ? p.title.trim()
                          : context.l10n.addCustomFeedSheetUntitledPost,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.starkWhite,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _localOnlyNote(GlassTokens tokens) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 14, color: tokens.textDim),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.l10n.addCustomFeedSheetLocalOnlyNote,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addButton(GlassTokens tokens, bool isList) {
    final adding = _phase == _Phase.adding;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: tokens.connectedAccent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: adding ? null : _add,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Center(
              child: adding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : Text(
                      isList
                          ? context.l10n.addCustomFeedSheetAddToListButton
                          : context.l10n.addCustomFeedSheetFollowFeedButton,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
