import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/feeds/feed_favicon.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/utils/feed_metadata_utils.dart';

/// The identity line of one feed read on its own ("Go to feed" on a plain
/// feed — mobile `FeedReaderPage`, desktop's Feeds pane on a `FeedSource`
/// selection): a circular favicon + the feed's name.
///
/// The description and the details (site · updated · language) are NOT here:
/// they live in the posts list's own header card (`ChannelHeaderCard`), so
/// every single-feed surface — the browser's channel tabs too — shows them.
///
/// Twin: publicos_client `components/feeds/feed_reader_header.dart`.
class FeedReaderHeader extends StatefulWidget {
  final String feedUrl;
  final String? title;
  final EdgeInsetsGeometry padding;

  const FeedReaderHeader({
    super.key,
    required this.feedUrl,
    this.title,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 4),
  });

  @override
  State<FeedReaderHeader> createState() => _FeedReaderHeaderState();
}

class _FeedReaderHeaderState extends State<FeedReaderHeader> {
  /// Only when the caller has no title: the feed's own (shared 1 h cache).
  String? _fetchedTitle;

  @override
  void initState() {
    super.initState();
    _loadTitle();
  }

  @override
  void didUpdateWidget(FeedReaderHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feedUrl != widget.feedUrl) {
      _fetchedTitle = null;
      _loadTitle();
    }
  }

  Future<void> _loadTitle() async {
    if (widget.title != null) return;
    final url = widget.feedUrl;
    final m = await FeedMetadataUtils.getFeedMetadata(url);
    if (mounted && m != null && url == widget.feedUrl) {
      setState(() => _fetchedTitle = m.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final title = widget.title ??
        _fetchedTitle ??
        context.l10n.feedReaderPageFallbackTitle;
    return Padding(
      padding: widget.padding,
      child: Row(
        children: [
          FeedFavicon(
            feedUrl: widget.feedUrl,
            size: 32,
            cornerRadius: 16, // circular
            faviconFirst: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
