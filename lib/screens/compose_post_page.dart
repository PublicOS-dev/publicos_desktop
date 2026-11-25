import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// DESKTOP DELTA: the client imports image_picker here, but only for the XFile
// type (`_DraftMedia.file`). Desktop's media_picker delta is built on
// file_picker, so XFile comes straight from its home package.
import 'package:cross_file/cross_file.dart';
import 'dart:math' as math;
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';
import 'package:zero_mentions/zero_mentions.dart';

import 'package:publicos_desktop/widgets/feeds/channel_icon.dart';
import 'package:publicos_desktop/widgets/natural_ratio_media.dart';
import 'package:publicos_desktop/widgets/tappable_media.dart';
import 'package:publicos_desktop/widgets/feeds/feeds_settings_sheet.dart'
    show parsePostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/post_card.dart' show PostCard, PostLayoutMode;
import 'package:publicos_desktop/widgets/feeds/mention_suggestions.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:publicos_desktop/utils/media_dimensions.dart';
import 'package:publicos_desktop/utils/media_mime.dart';
import 'package:publicos_desktop/utils/media_picker.dart';
import 'package:publicos_desktop/utils/audio_picker.dart';
import 'package:publicos_desktop/utils/video_poster.dart';
import 'package:publicos_desktop/widgets/post_audio_row.dart';
import 'package:publicos_desktop/widgets/error/write_error_dispatcher.dart';
import 'package:publicos_desktop/screens/manage_server_page.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Glass push-page for creating or editing a post.
///
/// Single inline content area + optional toggleable extras for every field
/// the server's create/update post endpoints accept:
///  - channel (required) — picked via the pill in the top header
///  - text (required) — the main inline editor
///  - title (optional, toggleable) — turns the post into an "article"
///  - summary (optional, toggleable)
///  - link (optional, toggleable) — the external URL field
///  - heroMedia (the Hero button: images and videos, in pick order, up to
///    30; one is the banner the card shows, several are its hero pager)
///  - supportMedia (the Media button: images and videos, up to 30; the
///    card's carousel under the text)
///  - language (BCP-47, default 'en')
///  - tags (optional)
///  - mediaPost (the author's toggle in the top bar, shown with a hero;
///    defaults to "the first hero is a video", the author flips it)
///  - commentPolicy (open / approved / disabled)
///  - requireVerifiedComments (per-post citizenship override)
///
/// Three launch modes:
///  1. **Picker** — pass `channels`; user picks via the pill.
///     Optionally `initialChannel` to pre-select.
///  2. **Community / locked** — pass `forcedChannelSlug` + owner + server
///     + name. Channel pill is locked to the forced channel. Used when
///     the entry point is forum-context (poster can only post to that
///     forum).
///  3. **Edit** — pass `existing`. Channel pill is locked to the post's
///     channel; all fields pre-fill from the post.
///
/// Media: a pick shows its local
/// preview at once and starts uploading in the page's background through
/// the SELECTED feed's door (`uploadMedia` / `uploadPedia`, on that feed's
/// SSP so quota lands on the right server), with a progress ring per item.
/// Post waits for the uploads, then reconciles the door against the FINAL
/// feed (`PublicOSSsp.moveMedia`, both directions — the channel may have
/// changed after the pick), then creates / updates. The page stays open and
/// the Post button reads out the status until the post lands.
class ComposePostPage extends StatefulWidget {
  /// Channels available in the picker. Empty when launched in community /
  /// edit mode (channel pill is locked anyway).
  final List<Channel> channels;
  final Channel? initialChannel;
  final Post? existing;

  // Community-mode overrides — when forcedChannelSlug is set, the picker
  // is hidden and posts go to this slug+owner+server triple.
  final String? forcedChannelSlug;
  final String? forcedChannelOwner;
  final String? forcedChannelServer;
  final String? forcedChannelName;

  /// Community mode only: whether the forced channel is private. Routes media
  /// uploads to the pedia door (picker/edit modes read it off the Channel).
  final bool forcedChannelIsPrivate;

  /// Fired after a successful create/update so the caller can refresh.
  final VoidCallback? onPostSaved;

  const ComposePostPage({
    super.key,
    this.channels = const [],
    this.initialChannel,
    this.existing,
    this.forcedChannelSlug,
    this.forcedChannelOwner,
    this.forcedChannelServer,
    this.forcedChannelName,
    this.forcedChannelIsPrivate = false,
    this.onPostSaved,
  });

  /// The channel the user last posted to from the picker, remembered per
  /// account in a settings record (so that, with no own channel on screen,
  /// the composer does not just open on the first channel in the list).
  /// Written on a successful NEW post from the picker; edits and community
  /// (forced-channel) posts do not count.
  static const String lastChannelKey = 'compose_last_channel_id';

  /// The remembered channel, resolved against [channels]; null when nothing
  /// is remembered or the channel is gone, so the caller falls back.
  static Future<Channel?> lastPostedChannel(List<Channel> channels) async {
    try {
      final record = await PublicOSSettings.getSetting(lastChannelKey);
      final id = int.tryParse(record?.value ?? '');
      if (id == null) return null;
      return channels.where((c) => c.id == id).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  static Future<void> rememberChannel(Channel channel) async {
    try {
      await PublicOSSettings.setSetting(
        lastChannelKey,
        Record.asSettings(
          key: lastChannelKey,
          value: channel.id.toString(),
          isExpired: false,
          isSystem: true,
        ),
      );
    } catch (_) {
      // Best effort: the post is saved either way.
    }
  }

  @override
  State<ComposePostPage> createState() => _ComposePostPageState();
}

/// 3-state comment policy for a post. Matches the server's
/// `comment_policy` enum ("open" | "approved" | "closed").
enum CommentPolicy { open, approved, disabled }

extension on CommentPolicy {
  IconData get icon {
    switch (this) {
      case CommentPolicy.open:
        return Icons.public_rounded;
      case CommentPolicy.approved:
        return Icons.fact_check_outlined;
      case CommentPolicy.disabled:
        return Icons.do_not_disturb_alt_rounded;
    }
  }
}

const List<({String code, String name})> _languages = [
  (code: 'en', name: 'English'),
  (code: 'es', name: 'Español'),
  (code: 'pt', name: 'Português'),
  (code: 'fr', name: 'Français'),
  (code: 'de', name: 'Deutsch'),
  (code: 'it', name: 'Italiano'),
  (code: 'ja', name: '日本語'),
  (code: 'zh', name: '中文'),
];

/// One media item the composer holds, from the moment it is picked to the
/// moment the post goes out. The list is where it sits (`_heroes`,
/// `_support`); the item only knows what it is, where its bytes are, and the
/// media object it will travel as:
///
///  - picked locally → `bytes` / `file` render the preview at once while the
///    upload runs in the page's background (`job`, `progress`) and the item
///    is measured (`measuring`: an image's pixels, a video's frame 0);
///  - uploaded → `url` and `media` are set (the server's hash, size and type
///    with the pixels measured here), behind the door the SELECTED feed
///    called for at pick time (`isPrivate`, `server`); a video's frame goes
///    up as its poster (`posterJob`) and becomes `media.thumbnailUrl`;
///  - already remote (edit mode) → `media` as the post carries it, kept
///    whole so the re-signed post names the same file.
///
/// The door is reconciled at Post against the FINAL feed
/// (`_reconcileDoors`).
class _DraftMedia {
  _DraftMedia.local(PickedMedia p)
      : file = p.file,
        bytes = p.bytes,
        filename = p.filename,
        mimeType = p.mimeType,
        isVideo = p.isVideo,
        isAudio = false,
        isPrivate = false;

  /// The post's sound track (the Audio button): one file, played by the
  /// composer's own row from these bytes while it uploads.
  _DraftMedia.audio(PickedAudio p)
      : file = null,
        bytes = p.bytes,
        filename = p.filename,
        mimeType = p.mimeType,
        isVideo = false,
        isAudio = true,
        isPrivate = false;

  _DraftMedia.remote(PostMedia remote, {this.server})
      : file = null,
        bytes = null,
        filename = '',
        mimeType = remote.mimeType,
        isVideo = remote.isVideo || isVideoUrl(remote.url),
        isAudio = remote.isAudio,
        url = remote.url,
        media = remote,
        width = remote.width,
        height = remote.height,
        progress = 1,
        isPrivate = remote.url.contains('/pedia/');

  /// The picked file (null for an existing post's media). Kept so a video,
  /// whose bytes are dropped after the upload, can still be re-uploaded.
  final XFile? file;

  /// The picked bytes: the preview (an image, or the clip the card plays
  /// right away: the composer plays the LOCAL file, uploading is the app's
  /// business, not the author's), and the re-upload source. Held for the
  /// life of the page; a file-born video is read into here at upload.
  Uint8List? bytes;
  final String filename;

  /// Sniffed at pick; replaced by the server's `content_type` after upload.
  String mimeType;
  final bool isVideo;

  /// The `audio` slot's item: no pixels, no poster; the upload names its
  /// type explicitly and the row learns its [durationSeconds].
  final bool isAudio;

  /// Audio: what the player reported once it opened the file; signed as
  /// `duration_in_seconds` at Post.
  num? durationSeconds;

  /// Set once the upload (or a move) lands.
  String? url;

  /// The SSP that holds the file.
  String? server;

  /// The door the file is behind today.
  bool isPrivate;

  /// 0..1 while uploading, 1 once done.
  double progress = 0;

  /// The upload in flight; resolves true when [url] is set, false when the
  /// item was dropped after a failure.
  Future<bool>? job;

  /// The media object this item travels as in the signed post: the upload's
  /// answer (hash, size, type) with the pixels measured here, or the edited
  /// post's own; a move and the poster patch it.
  PostMedia? media;

  /// Pixels: an image's own, a video's from its frame 0.
  int? width;
  int? height;

  /// A video's frame 0, extracted at pick; uploaded as the poster once the
  /// clip has a URL.
  VideoPoster? poster;

  /// The measuring in flight (image decode or frame extraction).
  Future<void>? measuring;

  /// The poster upload in flight.
  Future<void>? posterJob;

  bool get isUploaded => url != null;
}

class _ComposePostPageState extends State<ComposePostPage> {
  // Mention-aware body: styled @displayname while typing,
  // @[0xAddr] wire tokens at serialize() time. Body only — title/summary/url
  // stay plain (tokens there would leak into headers/notifications).
  late final MentionTextEditingController _bodyCtrl =
      MentionTextEditingController(
    displayNameFor: _mentionDisplayName,
    // = tokens.connectedAccent — controller is built before context exists.
    mentionStyle: const TextStyle(
      color: Color(0xFF64FFDA),
      fontWeight: FontWeight.w600,
    ),
  );
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _summaryCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _tagCtrl = TextEditingController();
  final FocusNode _bodyFocus = FocusNode();
  final FocusNode _tagFocus = FocusNode();

  Channel? _channel;
  Contact? _myContact;
  String _language = 'en';
  final List<String> _tags = [];

  // Media, two lists for the card's two places: the heroes (the Hero
  // button; the banner slot under the title, paged when there are several)
  // and the support media (the Media button; the carousel under the text),
  // each in the author's pick order. Items upload in the page's background
  // from the moment they are picked; `_save` waits for them and reconciles
  // the door (see `_DraftMedia`).
  final List<_DraftMedia> _heroes = [];
  final List<_DraftMedia> _support = [];

  /// The post's one sound track (the Audio button; PublicOS Feed v1
  /// `audio`): drawn as the card's audio row under the hero slot and above
  /// the text, from its local bytes while it uploads. [_audioLoop] is the
  /// author's intent, the row's loop toggle, signed as the object's `loop`.
  _DraftMedia? _audio;
  bool _audioLoop = false;

  /// The hero pager's page, for its `1/N` pill (two or more heroes).
  final PageController _heroPages = PageController();
  int _heroPage = 0;

  /// The post's `media_post` (PublicOS Feed v1 § Media posts: "the media is
  /// the focus", the header row drawn ON the first hero). The author's
  /// setting, flipped from the `_MediaPostToggle` in the top bar, which
  /// shows only while there is a hero. Defaults to "the first hero is a
  /// video" the moment the first hero lands (`_pickInto`), from the post
  /// itself on an edit; a cleared hero list hides the toggle and the next
  /// first hero re-applies the default. Sent as-is (false without heroes).
  bool _mediaPost = false;

  bool _showTitle = false;
  bool _showSummary = false;
  bool _showUrl = false;
  bool _showTags = false;
  CommentPolicy _commentPolicy = CommentPolicy.open;
  bool _requireVerifiedComments = false;
  // Reactions policy is independent of comments. Reuses CommentPolicy enum
  // since the three states are
  // identical; pickers differ only in their labels.
  CommentPolicy _reactionPolicy = CommentPolicy.open;
  bool _requireVerifiedReactions = false;

  bool _isSaving = false;

  /// The text caps of the selected feed's SSP (`GET /api/limits`), applied
  /// as length formatters on title / summary / body. null until fetched or
  /// when the host does not publish them; then nothing is capped here and
  /// the server's 413 stays the backstop. No counter is shown on purpose:
  /// the author simply cannot type past the cap.
  SspLimits? _limits;

  /// The card layout the page renders in, switched live from the toolbar
  /// (the composer IS the card).
  /// Opens on the user's reading layout (`rss_feeds_layout_mode`); the
  /// toggle here is a preview choice and is not written back.
  PostLayoutMode _layout = PostLayoutMode.compact;

  /// What the Post button says while [_isSaving]: "Uploading 2 of 3 · 62%"
  /// → "Moving media…" → "Posting…". The page stays open until the post
  /// lands (no outbox, the user waits here).
  String? _saveStatus;

  /// One picker at a time. Uploads themselves never block a pick.
  bool _isPicking = false;

  /// Local contacts for mention autocomplete + display-name resolution.
  /// One local-DB read at init; no chain reads, nothing persisted.
  List<Contact> _storedContacts = const [];

  /// The standard's caps (PublicOS Feed v1 § Limits): 30 hero items and 30
  /// support items. A composer never sends more, whatever a server would
  /// take.
  static const int _maxHeroItems = 30;
  static const int _maxSupportItems = 30;

  List<_DraftMedia> get _allMedia =>
      [..._heroes, ..._support, if (_audio != null) _audio!];
  int get _remainingHeroSlots => _maxHeroItems - _heroes.length;
  int get _remainingSupportSlots => _maxSupportItems - _support.length;

  bool get _isEdit => widget.existing != null;
  bool get _isCommunityLocked =>
      widget.forcedChannelSlug != null && !_isEdit;
  bool get _isChannelLocked => _isEdit || _isCommunityLocked;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      // The post's OWN channel, never a stand-in: the edit door (the post
      // card's menu) passes no channel list, and a `.first` fallback would
      // give the pill "Pick a channel" or another channel's name and privacy.
      // On edit the channel is locked. Not in the list →
      // read it from the post's own server below (_resolveEditChannel).
      _channel = widget.channels
          .where((c) => c.id == existing.channelId)
          .cast<Channel?>()
          .firstOrNull;
      // Body is seeded in _loadStoredContacts — after the local contacts
      // land, so rehydrated @[0xAddr] tokens get real display names.
      if (existing.title.isNotEmpty) {
        _titleCtrl.text = existing.title;
        _showTitle = true;
      }
      if ((existing.summary ?? '').isNotEmpty) {
        _summaryCtrl.text = existing.summary!;
        _showSummary = true;
      }
      if ((existing.externalUrl ?? '').isNotEmpty) {
        _urlCtrl.text = existing.externalUrl!;
        _showUrl = true;
      }
      final server = existing.serverAddress ?? _channel?.serverAddress;
      for (final m in existing.heroMedia) {
        _heroes.add(_DraftMedia.remote(m, server: server));
      }
      for (final m in existing.supportMedia) {
        _support.add(_DraftMedia.remote(m, server: server));
      }
      final audio = existing.audio;
      if (audio != null) {
        _audio = _DraftMedia.remote(audio, server: server)
          ..durationSeconds = audio.durationInSeconds;
        _audioLoop = audio.loop;
      }
      _mediaPost = existing.mediaPost;
      _language = existing.language ?? 'en';
      if (existing.tags != null) {
        _tags.addAll(existing.tags!);
        if (_tags.isNotEmpty) _showTags = true;
      }
      _commentPolicy = _policyFromPost(existing);
      _requireVerifiedComments = existing.requireVerifiedComments ?? false;
      _reactionPolicy = _reactionPolicyFromPost(existing);
      _requireVerifiedReactions = existing.requireVerifiedReactions ?? false;
    } else if (!_isCommunityLocked) {
      _channel = widget.initialChannel ??
          (widget.channels.isNotEmpty ? widget.channels.first : null);
    }
    _bodyCtrl.addListener(() => setState(() {}));
    _titleCtrl.addListener(() => setState(() {}));
    _urlCtrl.addListener(() => setState(() {}));
    _bodyFocus.addListener(() => setState(() {}));
    _loadMyContact();
    if (_isEdit && _channel == null) {
      _resolveEditChannel();
    } else {
      _loadLimits();
    }
    _loadLayout();
    _loadStoredContacts(seedBody: existing?.contentText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bodyFocus.requestFocus();
    });
  }

  Future<void> _loadStoredContacts({String? seedBody}) async {
    try {
      _storedContacts = await PublicOSContacts.getStoredContacts();
    } catch (_) {}
    if (!mounted) return;
    if (seedBody != null && seedBody.isNotEmpty) {
      _bodyCtrl.loadRaw(seedBody);
    }
    setState(() {});
  }

  // ------------------------------------------------------------- mentions

  /// Local-only display-name resolution (rehydrate/paste): stored contacts →
  /// truncated address. Never a chain read, never persisted.
  String _mentionDisplayName(String address) {
    final lower = address.toLowerCase();
    for (final c in _storedContacts) {
      if (c.publicosAddress?.eip55With0x.toLowerCase() == lower &&
          c.displayName.isNotEmpty) {
        return c.displayName;
      }
    }
    return truncatedAddress(address);
  }

  /// The chain half of the mention list: the holder of the typed name.
  late final MentionChainLookup _mentionChain = MentionChainLookup(() {
    if (mounted) setState(() {});
  });

  /// Stored contacts matching the active @-trigger, plus the account the
  /// chain says holds the typed name (first row), cap 8. (No commenters
  /// source here — a fresh post has none.)
  List<MentionCandidate> get _mentionCandidates {
    final t = _bodyCtrl.trigger;
    if (t == null) {
      _mentionChain.resultFor(null);
      return const [];
    }
    final q = t.query.toLowerCase();
    final out = <MentionCandidate>[];
    for (final c in _storedContacts) {
      final addr = c.publicosAddress?.eip55With0x;
      if (addr == null || c.displayName.isEmpty) continue;
      if (q.isNotEmpty &&
          !c.displayName.toLowerCase().contains(q) &&
          !addr.toLowerCase().startsWith(q)) {
        continue;
      }
      out.add(MentionCandidate(
          address: addr, display: c.displayName, contact: c));
    }
    return rankMentionCandidates(
        out, t.query, _mentionChain.resultFor(t.query));
  }

  void _pickMention(MentionCandidate c) {
    final t = _bodyCtrl.trigger;
    if (t == null) return;
    _bodyCtrl.insertMention(
      address: c.address,
      display: c.display,
      trigger: t,
    );
    _bodyFocus.requestFocus();
  }

  /// Edit: the post knows its channel (slug, owner, server), so read the
  /// channel object once for the pill's name, the privacy that routes media
  /// uploads, and the host's text caps. Until it lands the pill shows the
  /// post's feed title.
  Future<void> _resolveEditChannel() async {
    final p = widget.existing!;
    final slug = p.channelSlug;
    final owner = p.channelOwnerAddress ?? p.feedFoundAtAccountAddress;
    if (slug == null || slug.isEmpty || owner == null || owner.isEmpty) return;
    final resp = await PublicOSChannels.getChannel(
      ownerAddress: owner,
      slug: slug,
      serverAddress: p.serverAddress,
    );
    if (!mounted || !resp.success || resp.data == null) return;
    setState(() => _channel = resp.data);
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final server = _channel?.serverAddress;
    final limits = await PublicOSSsp.fetchLimits(serverAddress: server);
    if (!mounted || _channel?.serverAddress != server) return;
    setState(() => _limits = limits);
  }

  Future<void> _loadLayout() async {
    try {
      final l = await PublicOSSettings.getSetting('rss_feeds_layout_mode');
      if (!mounted || l == null) return;
      setState(() => _layout = parsePostLayoutMode(l.value));
    } catch (_) {}
  }

  Future<void> _loadMyContact() async {
    final addrHex = PublicOS.myPublicosAddress;
    if (addrHex == null) return;
    try {
      final me = await PublicOSContacts.searchContacts(addrHex);
      if (mounted && me != null) setState(() => _myContact = me);
    } catch (_) {}
  }

  @override
  void dispose() {
    _mentionChain.dispose();
    _bodyCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _urlCtrl.dispose();
    _tagCtrl.dispose();
    _bodyFocus.dispose();
    _tagFocus.dispose();
    _heroPages.dispose();
    super.dispose();
  }

  /// The server's rule (PublicOS Feed v1): a post needs one of title, text,
  /// hero media, support media, audio or link. Media alone is a post; a
  /// summary or tags alone are not.
  bool get _hasContent =>
      _bodyCtrl.text.trim().isNotEmpty ||
      (_showTitle && _titleCtrl.text.trim().isNotEmpty) ||
      (_showUrl && _urlCtrl.text.trim().isNotEmpty) ||
      _heroes.isNotEmpty ||
      _support.isNotEmpty ||
      _audio != null;

  bool get _canPost {
    if (_isSaving) return false;
    if (!_hasContent) return false;
    // An open title line must be filled before posting.
    if (_showTitle && _titleCtrl.text.trim().isEmpty) return false;
    // Edit mode pulls slug/owner/server from the existing post — no
    // Channel object needed in widget.channels (post_card opens compose
    // without passing the channels list).
    if (_isEdit) return true;
    if (_isCommunityLocked) return widget.forcedChannelSlug != null;
    return _channel != null;
  }

  /// Map the local UI enum to the server's `comment_policy` /
  /// `reaction_policy` wire string.
  String _policyToServer(CommentPolicy p) {
    switch (p) {
      case CommentPolicy.open:
        return 'open';
      case CommentPolicy.approved:
        return 'approved';
      case CommentPolicy.disabled:
        return 'closed';
    }
  }

  CommentPolicy _policyFromPost(Post post) {
    switch (post.commentPolicy) {
      case 'open':
        return CommentPolicy.open;
      case 'approved':
        return CommentPolicy.approved;
      case 'closed':
        return CommentPolicy.disabled;
    }
    return CommentPolicy.open;
  }

  CommentPolicy _reactionPolicyFromPost(Post post) {
    switch (post.reactionPolicy) {
      case 'open':
        return CommentPolicy.open;
      case 'approved':
        return CommentPolicy.approved;
      case 'closed':
        return CommentPolicy.disabled;
    }
    return CommentPolicy.open;
  }

  /// Resolve (slug, ownerAddress, serverAddress) for the currently active
  /// post target. Edit mode uses the post's stored fields (preserved by
  /// the Post.serverAddress refactor). Community-locked uses the forced
  /// values. Picker mode pulls from the selected channel.
  ({String slug, String? owner, String? server}) _activeTarget() {
    if (_isEdit) {
      final p = widget.existing!;
      return (
        slug: p.channelSlug ?? _channel?.slug ?? '',
        owner: p.channelOwnerAddress ??
            p.feedFoundAtAccountAddress ??
            _channel?.ownerAddress,
        server: p.serverAddress ?? _channel?.serverAddress,
      );
    }
    if (_isCommunityLocked) {
      return (
        slug: widget.forcedChannelSlug!,
        owner: widget.forcedChannelOwner,
        server: widget.forcedChannelServer,
      );
    }
    final c = _channel!;
    return (slug: c.slug, owner: c.ownerAddress, server: c.serverAddress);
  }

  Future<void> _save() async {
    if (!_canPost) return;
    // Wire form — mention runs become @[0xAddr] tokens. A post with no words
    // (media alone) carries no `text` key at all: Core writes the key only
    // for a non-empty string, so null here means "not in the signed object".
    final body = _bodyCtrl.serialize().trim();
    final text = body.isEmpty ? null : body;
    final title = _showTitle && _titleCtrl.text.trim().isNotEmpty
        ? _titleCtrl.text.trim()
        : null;
    final summary = _showSummary && _summaryCtrl.text.trim().isNotEmpty
        ? _summaryCtrl.text.trim()
        : null;
    final url = _showUrl && _urlCtrl.text.trim().isNotEmpty
        ? _urlCtrl.text.trim()
        : null;
    final commentPolicyStr = _policyToServer(_commentPolicy);
    final reactionPolicyStr = _policyToServer(_reactionPolicy);
    final tagsList = _tags.isEmpty ? null : List<String>.from(_tags);

    setState(() {
      _isSaving = true;
      _saveStatus =
          _uploadStatusText() ?? context.l10n.composePostPageStatusPosting;
    });

    // 1 · Wait for the uploads still running in the page's background. A
    // failed one has already dropped its item and shown its snackbar.
    if (!await _awaitUploads()) {
      _endSave();
      return;
    }
    if (!mounted) return;

    // 2 · The door follows the FINAL feed: every item uploaded behind the
    // other door (the channel changed after the pick) is moved server-side.
    final target = _activeTarget();
    if (!await _reconcileDoors(target)) {
      _endSave();
      return;
    }
    if (!mounted) return;
    setState(() => _saveStatus = context.l10n.composePostPageStatusPosting);

    // 3 · Post. The media travel as the signed media objects the uploads
    // produced (hash, size, type, pixels, a video's poster): the heroes in
    // pick order, then the support media. `media_post` is the author's
    // toggle (`_mediaPost`); it means nothing without a hero, so it goes
    // as false then.
    final heroes = [for (final m in _heroes) m.media!];
    final support = [for (final m in _support) m.media!];
    final mediaPost = _heroes.isNotEmpty && _mediaPost;
    // The sound track: the upload's object plus what only the composer
    // knows: the author's loop intent, the duration the row read, and a
    // name for a freshly picked file (its filename without the extension;
    // an edited post keeps the title it had).
    final audioDraft = _audio;
    final audio = audioDraft == null
        ? null
        : audioDraft.media?.copyWith(
            loop: _audioLoop,
            durationInSeconds: audioDraft.durationSeconds,
            title: audioDraft.bytes != null && audioDraft.filename.isNotEmpty
                ? audioDraft.filename.replaceFirst(RegExp(r'\.[^.]+$'), '')
                : null,
          );

    FeedServerApiResponse<Post> response;
    try {
      if (_isEdit) {
        // An edit is the whole post again, signed again: Core re-sends every
        // field from `post` unless given one here, and '' / [] clear what
        // the author removed (null would keep the old value), so the body
        // goes as '' when the author emptied it.
        response = await PublicOSChannels.updatePost(
          post: widget.existing!,
          title: title ?? '',
          text: body,
          summary: summary ?? '',
          link: url ?? '',
          heroMedia: heroes,
          supportMedia: support,
          audio: audio,
          removeAudio: audio == null && widget.existing!.audio != null,
          language: _language,
          tags: tagsList ?? const [],
          mediaPost: mediaPost,
          commentPolicy: commentPolicyStr,
          requireVerifiedComments: _requireVerifiedComments,
          reactionPolicy: reactionPolicyStr,
          requireVerifiedReactions: _requireVerifiedReactions,
          serverAddress: target.server,
        );
      } else {
        response = await PublicOSChannels.createPost(
          slug: target.slug,
          ownerAddress: target.owner,
          title: title,
          text: text,
          summary: summary,
          link: url,
          heroMedia: heroes,
          supportMedia: support,
          audio: audio,
          language: _language,
          tags: tagsList,
          mediaPost: mediaPost,
          commentPolicy: commentPolicyStr,
          requireVerifiedComments: _requireVerifiedComments,
          reactionPolicy: reactionPolicyStr,
          requireVerifiedReactions: _requireVerifiedReactions,
          serverAddress: target.server,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _endSave();
      handleWriteError(context, e);
      return;
    }

    if (!mounted) return;
    if (!response.success) {
      _endSave();
      final msg = response.error?['message'] as String? ??
          response.error?['code'] as String? ??
          (_isEdit
              ? context.l10n.composePostPageFailedUpdate
              : context.l10n.composePostPageFailedPublish);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_isChannelLocked && _channel != null) {
      await ComposePostPage.rememberChannel(_channel!);
      if (!mounted) return;
    }
    widget.onPostSaved?.call();
    Navigator.pop(context, response.data);
  }

  void _endSave() {
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _saveStatus = null;
    });
  }

  /// Whether the active post target is a PRIVATE channel — a pick then
  /// uploads through the pedia door (the composer auto-routes and never
  /// polices). Read at pick time AND at Post time: if the two disagree the
  /// channel changed in between, and `_reconcileDoors` moves the file.
  bool get _isPrivateTarget {
    if (_isCommunityLocked) return widget.forcedChannelIsPrivate;
    return _channel?.isPrivate ?? false;
  }

  // ---------------------------------------------------------------------------
  // Uploads — start at pick, run in the page's background, awaited at Post
  // ---------------------------------------------------------------------------

  /// Kick the upload of a just-picked item through the SELECTED feed's door,
  /// on the selected feed's SSP. The preview is already on screen from the
  /// local bytes; the ring on it follows [_DraftMedia.progress].
  void _startUpload(_DraftMedia m) {
    final target = _activeTarget();
    m.job = _upload(m, toPrivate: _isPrivateTarget, server: target.server);
  }

  /// Learn what the signed media object needs before the post can go: an
  /// image's pixels from its bytes; a video's frame 0 (its poster) and that
  /// frame's pixels. Runs from the pick in the background; the upload waits
  /// for it before building the media object. A failure leaves the item
  /// without pixels (the server then says so for a hero; a support item
  /// needs none). The hero pager's box follows the pixels once they land.
  void _startMeasure(_DraftMedia m) {
    m.measuring = _measure(m).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _measure(_DraftMedia m) async {
    // Audio has no pixels and no poster; its duration comes from the row's
    // player (`onDuration`), not from here.
    if (m.isAudio) return;
    if (m.isVideo) {
      final poster = await videoPosterOf(
        file: m.file,
        bytes: m.bytes,
        cacheKey: 'draft_poster_${m.file?.path ?? m.filename}',
      );
      if (poster == null) return;
      m.poster = poster;
      m.width = poster.width;
      m.height = poster.height;
    } else {
      final bytes = m.bytes ??= await m.file!.readAsBytes();
      final size = await imageSizeOf(bytes);
      if (size == null) return;
      m.width = size.$1;
      m.height = size.$2;
    }
  }

  /// Upload one item. Resolves true with [_DraftMedia.url] and
  /// [_DraftMedia.media] set; on failure drops the item from its list, shows
  /// the error, resolves false.
  Future<bool> _upload(
    _DraftMedia m, {
    required bool toPrivate,
    required String? server,
  }) async {
    final bytes = m.bytes ??= await m.file!.readAsBytes();
    if (!mounted) return false;
    var lastPct = -1;
    void onProgress(int sent, int total) {
      // Bytes handed to the socket, not acknowledged bytes: honest enough
      // for a ring. One setState per whole percent.
      final pct = total <= 0 ? 100 : sent * 100 ~/ total;
      if (pct == lastPct || !mounted) return;
      lastPct = pct;
      setState(() {
        m.progress = total <= 0 ? 1 : sent / total;
        if (_isSaving) _saveStatus = _uploadStatusText() ?? _saveStatus;
      });
    }

    PostMedia? uploaded;
    Map<String, dynamic>? error;
    try {
      // The pixels (and a video's frame 0) first: they travel in the signed
      // media object next to the hash and size the upload answers.
      await m.measuring;
      // Audio names its type: neither Core's sniffer nor the server's can
      // tell a headerless mp3 or a wav from a blob (both would answer 415).
      final mimeType = m.isAudio ? m.mimeType : null;
      if (toPrivate) {
        final resp = await PublicOSSsp.uploadPedia(
          bytes,
          m.filename,
          serverAddress: server,
          mimeType: mimeType,
          onProgress: onProgress,
        );
        if (resp.success && resp.data != null) {
          uploaded = resp.data!.toPostMedia(width: m.width, height: m.height);
        } else {
          error = resp.error;
        }
      } else {
        final resp = await PublicOSSsp.uploadMedia(
          bytes,
          m.filename,
          serverAddress: server,
          mimeType: mimeType,
          onProgress: onProgress,
        );
        if (resp.success && resp.data != null) {
          uploaded = resp.data!.toPostMedia(width: m.width, height: m.height);
        } else {
          error = resp.error;
        }
      }
    } catch (e) {
      if (!mounted) return false;
      _drop(m);
      handleWriteError(context, e,
          fallbackMessage: context.l10n.composePostPageUploadFailed);
      return false;
    }
    if (!mounted) return false;
    final up = uploaded;
    if (up == null) {
      _drop(m);
      if (error?['code'] == 'QUOTA_EXCEEDED') {
        _showQuotaExceeded(error, server);
      } else {
        _showError(error?['message'] as String? ??
            error?['code'] as String? ??
            context.l10n.composePostPageUploadFailed);
      }
      return false;
    }
    setState(() {
      m.url = up.url;
      m.media = up;
      m.isPrivate = toPrivate;
      m.server = server;
      if (up.mimeType.isNotEmpty) m.mimeType = up.mimeType;
      m.progress = 1;
    });
    // A video's frame 0 becomes its poster on the server, silently —
    // either door; the private one is sealed
    // per reader like the video — and the item's thumbnail.
    if (m.poster != null) m.posterJob = _sendPoster(m, server: server);
    return true;
  }

  /// Upload the item's frame 0 as the poster of the URL it has now; on
  /// success the media object points at it (`thumbnail_url`). Silent on
  /// failure: readers fall back to the old poster flow.
  Future<void> _sendPoster(_DraftMedia m, {required String? server}) async {
    final poster = m.poster;
    final url = m.url;
    if (poster == null || url == null) return;
    final ok =
        await uploadVideoPoster(videoUrl: url, poster: poster, server: server);
    if (!ok || !mounted || m.url != url) return;
    setState(() {
      m.media =
          m.media?.copyWith(thumbnailUrl: PublicOSSsp.posterUrlFor(url));
    });
  }

  /// Wait for every upload still in flight, then for the posters those
  /// uploads started. False if any upload failed (the failure path already
  /// dropped the item and spoke); a poster that failed costs nothing.
  Future<bool> _awaitUploads() async {
    final pending = _allMedia
        .where((m) => !m.isUploaded && m.job != null)
        .map((m) => m.job!)
        .toList();
    if (pending.isNotEmpty) {
      final results = await Future.wait(pending);
      if (!mounted || !results.every((ok) => ok)) return false;
    }
    final posters =
        _allMedia.map((m) => m.posterJob).whereType<Future<void>>().toList();
    if (posters.isNotEmpty) await Future.wait(posters);
    return mounted;
  }

  /// "Uploading 2 of 3 · 62%", or null when nothing is uploading.
  String? _uploadStatusText() {
    final all = _allMedia;
    final current = all.where((m) => !m.isUploaded).firstOrNull;
    if (current == null) return null;
    final done = all.where((m) => m.isUploaded).length;
    return context.l10n.composePostPageStatusUploading(
      done + 1,
      all.length,
      (current.progress * 100).round().clamp(0, 100),
    );
  }

  /// The door follows the FINAL feed. Every uploaded item behind the other
  /// door — or on another SSP — is moved (`POST /media/move`, both
  /// directions) or, when the SSP predates the route or the server changed,
  /// re-uploaded from the local bytes. Existing media of an edited post
  /// with nothing local to re-upload from keeps its URL.
  Future<bool> _reconcileDoors(
      ({String slug, String? owner, String? server}) target) async {
    final wantPrivate = _isPrivateTarget;
    final stale = _allMedia
        .where((m) =>
            m.isUploaded &&
            (m.isPrivate != wantPrivate ||
                (m.server ?? '') != (target.server ?? '')))
        .toList();
    for (final m in stale) {
      if (!mounted) return false;
      setState(() => _saveStatus = context.l10n.composePostPageStatusMoving);
      var reupload = (m.server ?? '') != (target.server ?? '');
      if (!reupload) {
        FeedServerApiResponse<MovedMedia> r;
        try {
          r = await PublicOSSsp.moveMedia(
            url: m.url!,
            toPrivate: wantPrivate,
            serverAddress: target.server,
          );
        } catch (e) {
          if (!mounted) return false;
          handleWriteError(context, e,
              fallbackMessage: context.l10n.composePostPageMoveFailed);
          return false;
        }
        if (!mounted) return false;
        final moved = r.data;
        if (r.success && moved != null) {
          setState(() {
            m.url = moved.url;
            m.isPrivate = wantPrivate;
            if (moved.contentType.isNotEmpty) m.mimeType = moved.contentType;
            // Same bytes, new address: the hash and pixels stay, the URL
            // (and the poster's, when it has one) follow.
            final media = m.media;
            if (media != null) {
              m.media = media.copyWith(
                url: moved.url,
                mimeType:
                    moved.contentType.isNotEmpty ? moved.contentType : null,
                thumbnailUrl: media.thumbnailUrl == null
                    ? null
                    : PublicOSSsp.posterUrlFor(moved.url),
              );
            }
          });
          // The server carries an existing poster across the move; this
          // re-send from the local frame covers media that never had one.
          if (m.poster != null) {
            m.posterJob = _sendPoster(m, server: target.server);
          }
          continue;
        }
        if (r.error?['code'] != 'ROUTE_MISSING') {
          _showError(r.error?['message'] as String? ??
              r.error?['code'] as String? ??
              context.l10n.composePostPageMoveFailed);
          return false;
        }
        reupload = true; // an older SSP without the move route
      }
      if (m.file == null && m.bytes == null) continue;
      setState(() {
        m.url = null; // the ring comes back while it re-uploads
        m.progress = 0;
      });
      m.job = _upload(m, toPrivate: wantPrivate, server: target.server);
      if (!await m.job!) return false;
    }
    return true;
  }

  /// Remove an item from whichever list holds it (a failed upload, or the
  /// user's ✕). The list closes ranks; the hero pager stays on a page that
  /// still exists.
  void _drop(_DraftMedia m) {
    if (!mounted) return;
    setState(() {
      _heroes.remove(m);
      _support.remove(m);
      if (identical(_audio, m)) _audio = null;
      _heroPage = _heroPage.clamp(0, math.max(0, _heroes.length - 1));
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// The one upload refusal a retry cannot fix: the account's media quota on
  /// that server is full. The bar stays until dismissed,
  /// says how full, and its action opens Manage server, where
  /// the media list and the quota bar are.
  void _showQuotaExceeded(Map<String, dynamic>? error, String? server) {
    final details = error?['details'];
    int mb(String key) =>
        details is Map ? ((details[key] as num?)?.toInt() ?? 0) : 0;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.composePostPageQuotaExceeded(mb('used_mb'), mb('quota_mb'))),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(minutes: 10),
        showCloseIcon: true,
        action: server == null
            ? null
            : SnackBarAction(
                label: l10n.feedsNavigationDrawerManageServer,
                onPressed: () => _openManageServer(server),
              ),
      ),
    );
  }

  /// Manage server for the feed's server, the way the feeds drawer opens it.
  Future<void> _openManageServer(String server) async {
    final info = await PublicOSSsp.getSSPServerInfo();
    if (!mounted) return;
    final ssp = info != null && info.apiUrl == server ? info : null;
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ManageServerPage(
          serverUrl: server,
          serverLabel: ssp == null
              ? server
              : (ssp.title.isNotEmpty ? ssp.title : ssp.slug),
          isSSP: ssp != null,
          sspSlug: ssp?.slug,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Picks
  // ---------------------------------------------------------------------------

  /// Hero: a multi-pick of images and videos appended to the heroes, up to
  /// the standard's 30. One hero is the banner the card shows under the
  /// title; several are its hero pager, swiped together.
  Future<void> _onAddHero() => _pickInto(
        _heroes,
        remaining: _remainingHeroSlots,
        limit: _maxHeroItems,
      );

  /// Media: a multi-pick of images and videos appended to the support media,
  /// up to the standard's 30. They are the card's carousel under the text.
  Future<void> _onAddSupport() => _pickInto(
        _support,
        remaining: _remainingSupportSlots,
        limit: _maxSupportItems,
      );

  /// Audio: one file, the post's sound track. A second pick replaces the
  /// first (the standard allows one `audio` object). It shows at once as the
  /// card's audio row, playing from its bytes, and starts uploading.
  Future<void> _onAddAudio() async {
    if (_isPicking || _isSaving) return;
    setState(() => _isPicking = true);
    try {
      final p = await pickAudio(context: context);
      if (!mounted || p == null) return;
      final m = _DraftMedia.audio(p);
      setState(() {
        _audio = m;
        _audioLoop = _heroes.isNotEmpty; // ambient under a hero, by default
      });
      _startUpload(m);
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  /// One picker at a time. Every pick goes to the end of [list] in pick
  /// order; each shows at once from its bytes, is measured, and starts
  /// uploading.
  Future<void> _pickInto(
    List<_DraftMedia> list, {
    required int remaining,
    required int limit,
  }) async {
    if (_isPicking || _isSaving) return;
    if (remaining <= 0) {
      _showError(context.l10n.composePostPageMediaLimit(limit));
      return;
    }
    setState(() => _isPicking = true);
    try {
      final picks = await pickMedia(
        context: context,
        limit: remaining,
        kind: MediaPickerKind.imageAndVideo,
      );
      if (!mounted || picks.isEmpty) return;
      final added = <_DraftMedia>[];
      final firstHero = identical(list, _heroes) && _heroes.isEmpty;
      setState(() {
        for (final p in picks.take(remaining)) {
          final m = _DraftMedia.local(p);
          list.add(m);
          added.add(m);
        }
        // The first hero sets the media-post default: a video leads, a
        // picture is a banner. The toggle shows from here on.
        if (firstHero) _mediaPost = added.first.isVideo;
      });
      for (final m in added) {
        _startMeasure(m);
        _startUpload(m);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _pickLanguage() async {
    final picked = await showGlassSheetDialog<String>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _LanguagePickerSheet(selected: _language),
    );
    if (picked != null) setState(() => _language = picked);
  }

  Future<void> _pickCommentPolicy() async {
    final result = await showGlassSheetDialog<(CommentPolicy, bool)>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _CommentPolicySheet(
        policy: _commentPolicy,
        requireVerified: _requireVerifiedComments,
      ),
    );
    if (result != null) {
      setState(() {
        _commentPolicy = result.$1;
        _requireVerifiedComments = result.$2;
      });
    }
  }

  Future<void> _pickReactionPolicy() async {
    final result = await showGlassSheetDialog<(CommentPolicy, bool)>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _ReactionPolicySheet(
        policy: _reactionPolicy,
        requireVerified: _requireVerifiedReactions,
      ),
    );
    if (result != null) {
      setState(() {
        _reactionPolicy = result.$1;
        _requireVerifiedReactions = result.$2;
      });
    }
  }

  Future<void> _pickChannel() async {
    if (_isChannelLocked || widget.channels.isEmpty) return;
    final picked = await showGlassSheetDialog<Channel>(
      context: context,
      width: DialogWidth.m,
      builder: (_) => _ChannelPickerSheet(
        channels: widget.channels,
        selected: _channel,
      ),
    );
    if (picked != null) {
      setState(() => _channel = picked);
      _loadLimits();
    }
  }

  void _addTagFromInput() {
    final raw = _tagCtrl.text.trim();
    if (raw.isEmpty) return;
    final parts = raw
        .split(RegExp(r'[,\s]+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    setState(() {
      for (final p in parts) {
        if (!_tags.contains(p)) _tags.add(p);
      }
      _tagCtrl.clear();
    });
  }

  String _channelPillName(BuildContext context) {
    if (_isCommunityLocked) {
      return widget.forcedChannelName ?? widget.forcedChannelSlug!;
    }
    final channelName = _channel?.name;
    if (channelName != null) return channelName;
    if (_isEdit) {
      final p = widget.existing!;
      final known = (p.feedTitle?.isNotEmpty ?? false)
          ? p.feedTitle!
          : (p.channelSlug ?? '');
      if (known.isNotEmpty) return known;
    }
    return context.l10n.composePostPagePickChannel;
  }

  static String _shortAddress(String a) {
    if (a.isEmpty) return '—';
    if (a.length < 10) return a;
    return '${a.substring(0, 6)}…${a.substring(a.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final mediaPadding = MediaQuery.of(context).padding;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: tokens.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              _TopBar(
                canPost: _canPost,
                isEdit: _isEdit,
                isSaving: _isSaving,
                status: _saveStatus,
                onClose: () => Navigator.pop(context),
                onPost: _save,
                channelPill: _ChannelPill(
                  name: _channelPillName(context),
                  isCommunity:
                      _isCommunityLocked || (_channel?.isOpen == true),
                  onTap: _isChannelLocked ? null : _pickChannel,
                  locked: _isChannelLocked,
                ),
                languagePill:
                    _LanguagePill(code: _language, onTap: _pickLanguage),
                mediaPostToggle: _heroes.isEmpty
                    ? null
                    : _MediaPostToggle(
                        value: _mediaPost,
                        onChanged: (v) => setState(() => _mediaPost = v),
                      ),
              ),
              // The post, as the card will show it, with the fields
              // inline. Edge to edge like a card in
              // a list; the page's own padding is only the bottom breathing
              // room above the chrome.
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildCard(context, tokens),
                ),
              ),
              // Mention autocomplete — pinned above the bottom chrome (and
              // therefore above the keyboard: resizeToAvoidBottomInset
              // shrinks this Column), not inline over the post content.
              if (_bodyFocus.hasFocus && _mentionCandidates.isNotEmpty)
                MentionSuggestionsPanel(
                  candidates: _mentionCandidates,
                  onPick: _pickMention,
                ),
              _CommentPolicyBar(
                policy: _commentPolicy,
                requireVerified: _requireVerifiedComments,
                onTap: _pickCommentPolicy,
              ),
              _ReactionPolicyBar(
                policy: _reactionPolicy,
                requireVerified: _requireVerifiedReactions,
                onTap: _pickReactionPolicy,
              ),
              _Toolbar(
                onAddHero: _onAddHero,
                onAddAudio: _onAddAudio,
                onAddMedia: _onAddSupport,
                heroCount: _heroes.length,
                audioActive: _audio != null,
                mediaCount: _support.length,
                onToggleTitle: () => setState(() {
                  _showTitle = !_showTitle;
                  if (!_showTitle) _titleCtrl.clear();
                }),
                onToggleSummary: () => setState(() {
                  _showSummary = !_showSummary;
                  if (!_showSummary) _summaryCtrl.clear();
                }),
                onToggleLink: () => setState(() {
                  _showUrl = !_showUrl;
                  if (!_showUrl) _urlCtrl.clear();
                }),
                onAddTag: () {
                  setState(() => _showTags = true);
                  // Wait one frame so the field is in the tree before we
                  // request focus on it.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _tagFocus.requestFocus();
                  });
                },
                titleActive: _showTitle,
                summaryActive: _showSummary,
                linkActive: _showUrl,
                tagsActive: _showTags,
                layout: _layout,
                onLayout: (l) => setState(() => _layout = l),
              ),
              SizedBox(height: mediaPadding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // The card — the page renders as PostCard does, in the chosen layout, with
  // the fields where the card shows them: title → banner → summary → body →
  // carousel → link → tags. Geometry and rhythm come from PostCard's public
  // constants (never copied), so the preview is the card. No action row:
  // there is nothing to react to while writing.
  // ==========================================================================

  bool get _isWide => _layout == PostLayoutMode.wide;

  /// A lone hero: the banner the card shows under the title. Null with no
  /// hero or with several (then the hero pager draws them).
  _DraftMedia? get _banner => _heroes.length == 1 ? _heroes.first : null;

  /// Wide + a hero + the media-post toggle ON: the hero block (the banner,
  /// or the pager) is the card's top and the header row sits on it, the way
  /// the card draws a `media_post` (`PostCard._buildHeroHeader`). Compact
  /// ignores the flag, like the card does.
  bool get _heroOnTop => _isWide && _heroes.isNotEmpty && _mediaPost;

  Widget _buildCard(BuildContext context, GlassTokens tokens) {
    final inset =
        _isWide ? PostCard.wideContentInset : PostCard.compactContentInset;
    final right = _isWide ? PostCard.wideContentInset : PostCard.hPadRight;
    final children = <Widget>[];
    if (_isWide) {
      children.add(_heroOnTop
          ? _buildHeroHeader(context, tokens)
          : _buildHeaderRow(context, tokens));
      children.add(_buildContentColumn(
        context,
        tokens,
        blockPad: PostCard.wideContentInset,
        includeBanner: !_heroOnTop,
      ));
    } else {
      // Compact: avatar column, then author row + content column tight
      // beneath it, like `_buildCompactBody`.
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(
            PostCard.hPad, PostCard.headerTopPad, PostCard.hPadRight, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildAvatar(),
            ),
            const SizedBox(width: PostCard.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAuthorLine(context, tokens),
                  _buildContentColumn(context, tokens),
                ],
              ),
            ),
          ],
        ),
      ));
    }
    // The support carousel: edge to edge, the first tile under the text
    // column, the add tile last. Appears with the first support item (Media
    // in the toolbar).
    if (_support.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_buildDraftCarousel(context, tokens, startInset: inset));
    }
    if (_showUrl) {
      children.add(Padding(
        padding: EdgeInsets.only(left: inset, right: right, top: 10),
        child: _InlineLineField(
          controller: _urlCtrl,
          hint: 'https://',
          keyboardType: TextInputType.url,
          pill: true,
          onClose: () => setState(() {
            _showUrl = false;
            _urlCtrl.clear();
          }),
        ),
      ));
    }
    if (_showTags) {
      children.add(Padding(
        padding: EdgeInsets.only(left: inset, right: right, top: 10),
        child: _TagsRow(
          tags: _tags,
          controller: _tagCtrl,
          focusNode: _tagFocus,
          onSubmit: _addTagFromInput,
          onRemove: (t) => setState(() {
            _tags.remove(t);
            if (_tags.isEmpty && _tagCtrl.text.isEmpty) _showTags = false;
          }),
        ),
      ));
    }
    children.add(const SizedBox(height: 14));
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildAvatar() => GlassContactIcon(
        contact: _myContact,
        address: PublicOS.myPublicosAddress ?? '',
        size: PostCard.avatarSize,
      );

  /// Wide header: avatar + author line at the card's offsets.
  Widget _buildHeaderRow(BuildContext context, GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PostCard.hPad, PostCard.headerTopPad, PostCard.hPadRight, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildAvatar(),
          ),
          const SizedBox(width: PostCard.gutter),
          Expanded(child: _buildAuthorLine(context, tokens)),
        ],
      ),
    );
  }

  /// The card's author line: the name alone. No time (a draft has none and
  /// "Just now" says nothing; an edit's date is the post's, not a field
  /// here) and no targets: the feed and language pills live in the top bar
  /// beside the close button.
  Widget _buildAuthorLine(BuildContext context, GlassTokens tokens) {
    final name =
        _myContact?.displayName ?? _shortAddress(PublicOS.myPublicosAddress ?? '');
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wide + media post: the hero block is the card's top, the header row on
  /// it over a short scrim (the card's `_buildHeroHeader`: black 55 % →
  /// transparent over 96 px, the row at its normal offsets). Each tile's
  /// remove button moves to the bottom corner so it never sits under the
  /// row, and the pager's counter drops under it.
  Widget _buildHeroHeader(BuildContext context, GlassTokens tokens) {
    return Stack(
      children: [
        _buildHeroBlock(tokens, radius: 0, headerOnTop: true),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: PostCard.videoBannerScrimHeight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _buildHeaderRow(context, tokens),
        ),
      ],
    );
  }

  /// The card's content column with the fields inline: title → hero block
  /// (the banner, or the pager) → summary → body. Same rhythm as
  /// `PostCard._buildContentColumn`: 8 px under the header (+4 in wide
  /// before a title), 8 title→hero, 6 else. [blockPad] > 0 (wide) pads
  /// every block except the hero block, which runs edge to edge with square
  /// corners.
  Widget _buildContentColumn(
    BuildContext context,
    GlassTokens tokens, {
    double blockPad = 0,
    bool includeBanner = true,
  }) {
    final children = <Widget>[];
    var first = true;
    void add(Widget w, {double gap = 6, bool isTitle = false, bool pad = true}) {
      final lead = first ? 8.0 + (blockPad > 0 && isTitle ? 4.0 : 0.0) : gap;
      children.add(SizedBox(height: lead));
      children.add(blockPad > 0 && pad
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: blockPad),
              child: w,
            )
          : w);
      first = false;
    }

    if (_showTitle) {
      add(_TitleField(controller: _titleCtrl, maxChars: _limits?.title),
          isTitle: true);
    }
    if (includeBanner && _heroes.isNotEmpty) {
      add(
        _buildHeroBlock(tokens, radius: blockPad > 0 ? 0 : 12),
        gap: 8,
        pad: false,
      );
    }
    // The audio row, where the card draws it: under the hero slot, above
    // the text. The same widget as the card's, playing the local file,
    // with the remove glyph at its right end. The upload's progress ring
    // is not drawn here: the Post pill reports it.
    final audio = _audio;
    if (audio != null) {
      final raw = _myContact?.getRecordValue('color');
      final v = raw == null ? null : int.tryParse(raw);
      add(
        PostAudioRow(
          key: ValueKey('draft_audio_${audio.filename}'),
          url: audio.url,
          bytes: audio.bytes,
          filename: audio.filename,
          title: audio.bytes != null
              ? audio.filename.replaceFirst(RegExp(r'\.[^.]+$'), '')
              : (audio.media?.title ?? '').isNotEmpty
                  ? audio.media!.title!
                  : (audio.url ?? '').split('/').last,
          durationHint: audio.durationSeconds,
          loop: _audioLoop,
          onLoopChanged: (v) => _audioLoop = v,
          color: v == null ? tokens.starkWhite : Color(v),
          eager: true,
          onDuration: (d) => audio.durationSeconds = d.inMilliseconds / 1000,
          onRemove: () => _drop(audio),
        ),
        gap: 8,
      );
    }
    if (_showSummary) {
      add(_InlineLineField(
        controller: _summaryCtrl,
        maxChars: _limits?.summary,
        hint: context.l10n.composePostPageSummaryHint,
        onClose: () => setState(() {
          _showSummary = false;
          _summaryCtrl.clear();
        }),
      ));
    }
    add(_BodyField(
      controller: _bodyCtrl,
      focusNode: _bodyFocus,
      maxChars: _limits?.body,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  /// The hero block as the card draws it (`PostCard._buildHero`): one hero
  /// is the banner at its natural ratio; two or more are the hero pager.
  /// [headerOnTop]: the header row is laid on this block (`_buildHeroHeader`),
  /// so the controls keep clear of it.
  Widget _buildHeroBlock(
    GlassTokens tokens, {
    required double radius,
    bool headerOnTop = false,
  }) {
    final banner = _banner;
    if (banner != null) {
      return _DraftTile(
        media: banner,
        onRemove: () => _drop(banner),
        natural: true,
        radius: radius,
        removeAtBottom: headerOnTop,
      );
    }
    return _buildDraftHeroPager(tokens,
        radius: radius, headerOnTop: headerOnTop);
  }

  /// Where a hero's top-right controls start when the header row is on it:
  /// under the row (14 pad + 40 avatar + 8), the card's `_heroControlsTop`.
  static const double _heroControlsTop =
      PostCard.headerTopPad + PostCard.avatarSize + 8;

  /// Two or more heroes: the card's hero pager with the drafts in it. One
  /// box the biggest item's shape, every item cover-cropped to it, swiped,
  /// a `1/N` pill top-right (under the header row when it is on the hero);
  /// each page keeps its remove glyph (bottom-right, clear of the pill).
  Widget _buildDraftHeroPager(
    GlassTokens tokens, {
    required double radius,
    bool headerOnTop = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = _heroBoxHeight(width);
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _heroPages,
                  itemCount: _heroes.length,
                  onPageChanged: (i) => setState(() => _heroPage = i),
                  itemBuilder: (context, i) {
                    final m = _heroes[i];
                    return _DraftTile(
                      media: m,
                      onRemove: () => _drop(m),
                      width: width,
                      height: height,
                      radius: 0,
                      removeAtBottom: true,
                    );
                  },
                ),
                Positioned(
                  top: headerOnTop ? _heroControlsTop : 8,
                  right: 8,
                  child: IgnorePointer(
                    child: _HeroCounter(
                      page: _heroPage,
                      count: _heroes.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The pager's box at [width], the card's rule (`PostCard._heroBoxHeight`):
  /// each hero's height from its measured pixels, the tallest wins, capped
  /// like a lone media (desktop's absolute bound). A hero not measured yet
  /// fills whatever the others decided; with no pixels anywhere the box is
  /// square.
  double _heroBoxHeight(double width) {
    double tallest = 0;
    for (final m in _heroes) {
      final w = m.width, h = m.height;
      if (w == null || h == null || w <= 0 || h <= 0) continue;
      final at = width * h / w;
      if (at > tallest) tallest = at;
    }
    if (tallest <= 0) tallest = width;
    return math.min(tallest, PostCard.singleMediaMaxHeight(width));
  }

  /// The card's carousel with the support drafts in it: one item renders at
  /// the card's single-media width and natural ratio; two or more are the
  /// fixed 200 px tiles in a horizontal scroller. The add tile closes the
  /// row while support slots remain.
  Widget _buildDraftCarousel(
    BuildContext context,
    GlassTokens tokens, {
    required double startInset,
  }) {
    final items = _support;
    final canAdd = _remainingSupportSlots > 0;
    if (items.length == 1) {
      return Padding(
        padding: EdgeInsets.only(left: startInset, right: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The card's single-media width and height cap (desktop's
            // absolute bounds, PostCard's constants).
            final w = constraints.maxWidth * PostCard.singleMediaWidthFactor;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: w,
                  child: _DraftTile(
                    media: items[0],
                    onRemove: () => _drop(items[0]),
                    natural: true,
                    naturalMaxHeight: PostCard.singleMediaMaxHeight(w),
                    radius: 14,
                  ),
                ),
                if (canAdd) ...[
                  const SizedBox(width: 8),
                  _AddMediaTile(onTap: _onAddSupport, width: 96, height: 96),
                ],
              ],
            );
          },
        ),
      );
    }
    final width = PostCard.mediaTileWidth(items.length);
    return SizedBox(
      height: PostCard.mediaTileHeight,
      child: HorizontalWheel(
        child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(left: startInset, right: 16),
        children: [
          for (final m in items) ...[
            _DraftTile(
              media: m,
              onRemove: () => _drop(m),
              width: width,
              height: PostCard.mediaTileHeight,
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          if (canAdd)
            _AddMediaTile(
              onTap: _onAddSupport,
              width: 120,
              height: PostCard.mediaTileHeight,
            ),
        ],
      ),
      ),
    );
  }
}

// ============================================================================
// Top bar
// ============================================================================

class _TopBar extends StatelessWidget {
  final bool canPost;
  final bool isEdit;
  final bool isSaving;

  /// Read out in the Post button while saving (uploading → moving → posting).
  final String? status;
  final VoidCallback onClose;
  final VoidCallback onPost;

  /// The post's targets, right of the close button (kept out
  /// of the preview's author line, so the card reads as it will be shown):
  /// the feed pill, the language pill, and, with a hero in the draft, the
  /// media-post toggle (`_MediaPostToggle`); null hides it.
  final Widget channelPill;
  final Widget languagePill;
  final Widget? mediaPostToggle;

  const _TopBar({
    required this.canPost,
    required this.onClose,
    required this.onPost,
    required this.channelPill,
    required this.languagePill,
    this.mediaPostToggle,
    this.isEdit = false,
    this.isSaving = false,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: isSaving ? null : onClose,
          ),
          // The pills in their own row so a long feed name ellipsizes
          // against the Post button instead of pushing it off the bar.
          Expanded(
            child: Row(
              children: [
                Flexible(child: channelPill),
                const SizedBox(width: 6),
                languagePill,
                if (mediaPostToggle != null) ...[
                  const SizedBox(width: 8),
                  mediaPostToggle!,
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _PostButton(
            enabled: canPost,
            label: isEdit
                ? context.l10n.composePostPageSave
                : context.l10n.composePostPagePost,
            isSaving: isSaving,
            status: status,
            onPressed: onPost,
          ),
        ],
      ),
    );
  }
}

class _PostButton extends StatelessWidget {
  final bool enabled;
  final bool isSaving;
  final String? status;
  final String label;
  final VoidCallback onPressed;

  const _PostButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'Post',
    this.isSaving = false,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: enabled || isSaving ? tokens.surfaceElevated : tokens.surfaceDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: enabled || isSaving
              ? tokens.borderMedium
              : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: enabled && !isSaving ? onPressed : null,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: isSaving
              // The status IS the spinner: the user reads what the page is
              // doing instead of watching a ring.
              ? Text(
                  status ?? label,
                  style: TextStyle(
                    color: tokens.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: enabled ? tokens.starkWhite : tokens.textDim,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// Media-post toggle (two glyphs: header above the media | header on it)
// ============================================================================

/// The `media_post` switch: a two-cell segmented control (the `_LayoutToggle`
/// shape: glass fill, 12 px corners, the selected cell washed) whose cells
/// are two hand-rolled glyphs, no icon font. Left = the header row above
/// the media (a banner post), right = the row laid on the media and the row
/// slot above left empty (a media post). The selected glyph is `starkWhite`,
/// the other `textDim`. Re-lays the preview live.
class _MediaPostToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MediaPostToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    Widget seg(bool v, String tooltip) {
      final on = value == v;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onChanged(v),
          child: Container(
            width: 40,
            height: 30,
            color: on ? tokens.glassFillHover : Colors.transparent,
            alignment: Alignment.center,
            // Two set glyphs, not drawings: stacked panes = the row above the
            // media; a frame with a small box inside = the row on it.
            child: Icon(
              v
                  ? Icons.picture_in_picture_alt_outlined
                  : Icons.view_agenda_outlined,
              size: 20,
              color: on ? tokens.starkWhite : tokens.textDim,
            ),
          ),
        ),
      );
    }

    return Material(
      color: tokens.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(false, context.l10n.composePostPageHeaderAboveMedia),
          seg(true, context.l10n.composePostPageHeaderOnMedia),
        ],
      ),
    );
  }
}

// ============================================================================
// Channel + language pills
// ============================================================================

class _ChannelPill extends StatelessWidget {
  final String name;
  final bool isCommunity;
  final VoidCallback? onTap;
  final bool locked;

  const _ChannelPill({
    required this.name,
    required this.isCommunity,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border.all(color: tokens.borderMedium, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCommunity ? Icons.forum_outlined : Icons.rss_feed_rounded,
              size: 14,
              color: tokens.starkWhite,
            ),
            const SizedBox(width: 6),
            // Flexible + ellipsis: the pill sits in a Flexible slot of the
            // author line, and a long name would overflow it.
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.starkWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              locked
                  ? Icons.lock_outline_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: tokens.textDim,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String code;
  final VoidCallback onTap;

  const _LanguagePill({required this.code, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: tokens.surfaceElevated,
          border: Border.all(color: tokens.borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 13, color: tokens.textDim),
            const SizedBox(width: 5),
            Text(
              code.toUpperCase(),
              style: TextStyle(
                color: tokens.starkWhite,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Body / inline fields
// ============================================================================

class _BodyField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int? maxChars;

  const _BodyField(
      {required this.controller, required this.focusNode, this.maxChars});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // The card's body type (bodyMedium 14 / 1.4, 92 % white).
    final style = TextStyle(
      color: tokens.starkWhite.withValues(alpha: 0.92),
      fontSize: 14,
      height: 1.4,
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 2,
      maxLines: null,
      inputFormatters: [
        if (maxChars != null) LengthLimitingTextInputFormatter(maxChars),
      ],
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: style,
      decoration: InputDecoration(
        hintText: context.l10n.composePostPageBodyHint,
        hintStyle: style.copyWith(color: tokens.textDim),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _TitleField extends StatelessWidget {
  final TextEditingController controller;
  final int? maxChars;

  const _TitleField({required this.controller, this.maxChars});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // The card's title type (titleMedium 16 bold / 1.25).
    final style = TextStyle(
      color: tokens.starkWhite,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      height: 1.25,
    );
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 2,
      inputFormatters: [
        if (maxChars != null) LengthLimitingTextInputFormatter(maxChars),
      ],
      style: style,
      decoration: InputDecoration(
        hintText: context.l10n.composePostPageTitle,
        hintStyle: style.copyWith(color: tokens.textDim),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// A one-line field with a close glyph. Two looks, both the card's: the
/// summary (plain, the card's summary type) and, with [pill], the external
/// link pill (link glyph + dim 12 pt in a thin rounded border).
class _InlineLineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final VoidCallback onClose;
  final int? maxChars;
  final bool pill;

  const _InlineLineField({
    required this.controller,
    required this.hint,
    required this.onClose,
    this.keyboardType,
    this.maxChars,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final style = pill
        ? TextStyle(color: tokens.textDim, fontSize: 12)
        : TextStyle(
            color: tokens.starkWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.4,
          );
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: [
        if (maxChars != null) LengthLimitingTextInputFormatter(maxChars),
      ],
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(color: tokens.textDim),
        border: InputBorder.none,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
    final close = InkResponse(
      onTap: onClose,
      radius: 14,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(Icons.close_rounded,
            size: pill ? 14 : 16, color: tokens.textDim),
      ),
    );
    if (!pill) {
      return Row(
        children: [
          Expanded(child: field),
          const SizedBox(width: 8),
          close,
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 14, color: tokens.textDim),
          const SizedBox(width: 6),
          Expanded(child: field),
          const SizedBox(width: 6),
          close,
        ],
      ),
    );
  }
}

/// One draft item drawn as the card draws media: [natural] = the item's own
/// ratio at the width it is given (banner, single media), otherwise a fixed
/// [width] × [height] cover tile (the carousel). Over it: the upload ring
/// while the bytes are still going up, and the remove glyph.
class _DraftTile extends StatelessWidget {
  final _DraftMedia media;
  final VoidCallback onRemove;
  final bool natural;
  /// [natural] only: crop taller media to this height (single media, 9:16).
  final double? naturalMaxHeight;
  final double? width;
  final double? height;
  final double radius;
  final bool removeAtBottom;

  const _DraftTile({
    required this.media,
    required this.onRemove,
    this.natural = false,
    this.naturalMaxHeight,
    this.width,
    this.height,
    this.radius = 14,
    this.removeAtBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget face;
    if (natural) {
      // The local source first, for as long as the page lives: a picked
      // image from its bytes, a picked clip PLAYING from its bytes (the
      // upload is the app's business). Only a remote-born
      // item (editing) renders from its URL. Never switch a playing clip to
      // its URL once uploaded: it would restart.
      final bytes = media.bytes;
      if (bytes != null) {
        face = NaturalRatioMedia(
          imageBytes: media.isVideo ? null : bytes,
          videoBytes: media.isVideo ? bytes : null,
          filename: media.filename,
          heroTag: 'draft_${media.filename}',
          maxHeight: naturalMaxHeight,
          fillWidth: true,
          borderRadius: br,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } else if (media.url != null) {
        face = NaturalRatioMedia(
          mediaUrl: media.url,
          heroTag: 'draft_${media.filename}',
          maxHeight: naturalMaxHeight,
          fillWidth: true,
          borderRadius: br,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        );
      } else {
        // A file-born clip whose bytes are not read yet (the first frame
        // after a desktop pick): the play tile until the upload reads them.
        face = ClipRRect(
          borderRadius: br,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _MediaFace(media: media, playIconSize: 48),
          ),
        );
      }
    } else {
      face = ClipRRect(
        borderRadius: br,
        child: SizedBox(
          width: width,
          height: height,
          child: _MediaFace(
            media: media,
            playIconSize: 36,
            cacheWidth: 660,
            width: width,
            height: height,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: br,
      child: Stack(
        children: [
          face,
          _UploadScrim(media: media, ringSize: natural ? 32 : 24),
          // A video's top-right corner belongs to the player's expand
          // button, so a video's × always sits bottom-right (compact too),
          // where it cannot overlap the expand button.
          Positioned(
            top: (removeAtBottom || media.isVideo) ? null : 8,
            bottom: (removeAtBottom || media.isVideo) ? 8 : null,
            right: 8,
            child: _RemoveButton(onTap: onRemove, pad: 5, size: 14),
          ),
        ],
      ),
    );
  }
}

/// The `1/N` pill at the hero pager's top-right, the card's
/// (`PostCard._heroCounter`: black at 35 %, 24 px corners).
class _HeroCounter extends StatelessWidget {
  final int page;
  final int count;

  const _HeroCounter({required this.page, required this.count});

  @override
  Widget build(BuildContext context) {
    final shown = page.clamp(0, count - 1) + 1;
    return Semantics(
      label: '$shown / $count',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Text(
            '$shown/$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// The "add more" tile that closes the support carousel while slots remain.
class _AddMediaTile extends StatelessWidget {
  final Future<void> Function() onTap;
  final double width;
  final double height;

  const _AddMediaTile(
      {required this.onTap, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: width,
          height: height,
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 24,
            color: tokens.textDim,
          ),
        ),
      ),
    );
  }
}

/// What a draft item looks like: a play tile for a video, the local bytes
/// for a just-picked image, the cached network image for a remote one.
class _MediaFace extends StatelessWidget {
  final _DraftMedia media;
  final double playIconSize;

  /// Decode width for the local bytes (a phone photo is far larger than any
  /// preview box). Null = the screen's width in device pixels.
  final int? cacheWidth;

  /// The tile's box, handed to the video widget (it does not size itself).
  final double? width;
  final double? height;

  const _MediaFace({
    required this.media,
    required this.playIconSize,
    this.cacheWidth,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final bytes = media.bytes;
    if (media.isVideo) {
      // The clip itself, from its local bytes (every slot plays; the URL
      // is for the post, never for the preview). A remote-born clip
      // (editing) plays from its URL like a card tile; a file-born one shows
      // the play glyph only until the upload reads its bytes.
      if (bytes != null || media.url != null) {
        return TappableMedia(
          mediaUrl: bytes == null ? media.url : null,
          videoBytes: bytes,
          filename: media.filename,
          heroTag: 'draft_tile_${media.filename}',
          width: width,
          height: height,
          fit: BoxFit.cover,
          showExpandButton: false,
          videoTapToFullscreen: bytes == null,
          errorBuilder: (_, __, ___) => Container(color: tokens.surfaceDeep),
        );
      }
      return Container(
        color: tokens.surfaceDeep,
        child: Center(
          child: Icon(
            Icons.play_circle_outline,
            size: playIconSize,
            color: tokens.textDim,
          ),
        ),
      );
    }
    if (bytes != null) {
      final mq = MediaQuery.of(context);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth:
            cacheWidth ?? (mq.size.width * mq.devicePixelRatio).round(),
        errorBuilder: (_, __, ___) => Container(color: tokens.surfaceDeep),
      );
    }
    return ZeroCachedImage(
      imageUrl: media.url ?? '',
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: tokens.surfaceDeep),
      errorWidget: (_, __, ___) => Container(color: tokens.surfaceDeep),
    );
  }
}

/// A dim veil with a thin progress ring while the item is still uploading.
/// Hand-rolled ring; never a CircularProgressIndicator.
class _UploadScrim extends StatelessWidget {
  final _DraftMedia media;
  final double ringSize;
  const _UploadScrim({required this.media, required this.ringSize});

  @override
  Widget build(BuildContext context) {
    if (media.isUploaded) return const SizedBox.shrink();
    final tokens = GlassTokens.of(context);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        alignment: Alignment.center,
        child: SizedBox(
          width: ringSize,
          height: ringSize,
          child: CustomPaint(
            painter: _RingPainter(
              progress: media.progress,
              track: Colors.white.withValues(alpha: 0.25),
              color: tokens.starkWhite,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color color;
  const _RingPainter({
    required this.progress,
    required this.track,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final r = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 2 * math.pi, false, paint..color = track);
    canvas.drawArc(
      r,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  final double pad;
  final double size;
  const _RemoveButton({
    required this.onTap,
    required this.pad,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Icon(Icons.close_rounded, size: size, color: Colors.white),
        ),
      ),
    );
  }
}

// ============================================================================
// Attachments strip
// ============================================================================

// ============================================================================
// Tags row
// ============================================================================

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSubmit;
  final ValueChanged<String> onRemove;

  const _TagsRow({
    required this.tags,
    required this.controller,
    required this.onSubmit,
    required this.onRemove,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...tags.map(
          (t) => InkWell(
            onTap: () => onRemove(t),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 3, 6, 3),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.borderSubtle),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.close_rounded, size: 11, color: tokens.textDim),
                ],
              ),
            ),
          ),
        ),
        // Inline input — typing a space, comma, or pressing enter commits
        // the current word as a tag. Multi-add works too: paste
        // "foo bar, baz" and you get three tags. The hint nudges new users
        // toward the space-to-commit gesture.
        SizedBox(
          width: 180,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onSubmitted: (_) => onSubmit(),
            onChanged: (v) {
              if (v.isEmpty) return;
              final last = v.substring(v.length - 1);
              if (last == ' ' || last == ',' || last == '\n') {
                onSubmit();
              }
            },
            textInputAction: TextInputAction.done,
            style: TextStyle(color: tokens.starkWhite, fontSize: 12),
            decoration: InputDecoration(
              hintText: tags.isEmpty
                  ? context.l10n.composePostPageTagsHintEmpty
                  : context.l10n.composePostPageTagsHintMore,
              hintStyle: TextStyle(color: tokens.textDim, fontSize: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.tag_rounded,
                  size: 12,
                  color: tokens.textDim,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              border: InputBorder.none,
              isCollapsed: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Comment policy bar
// ============================================================================

class _CommentPolicyBar extends StatelessWidget {
  final CommentPolicy policy;
  final bool requireVerified;
  final VoidCallback onTap;

  const _CommentPolicyBar({
    required this.policy,
    required this.requireVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    final l10n = context.l10n;
    final label = switch (policy) {
      CommentPolicy.open => l10n.composePostPageCommentBarOpen,
      CommentPolicy.approved => l10n.composePostPageCommentBarApproved,
      CommentPolicy.disabled => l10n.composePostPageCommentBarDisabled,
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: tokens.borderSubtle, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(policy.icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (requireVerified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.composePostPageBadgeCitizen,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Reaction policy bar (sibling of _CommentPolicyBar — independent toggle).
// ============================================================================

class _ReactionPolicyBar extends StatelessWidget {
  final CommentPolicy policy;
  final bool requireVerified;
  final VoidCallback onTap;

  const _ReactionPolicyBar({
    required this.policy,
    required this.requireVerified,
    required this.onTap,
  });

  IconData get _icon {
    switch (policy) {
      case CommentPolicy.open:
        return Icons.emoji_emotions_outlined;
      case CommentPolicy.approved:
        return Icons.fact_check_outlined;
      case CommentPolicy.disabled:
        return Icons.do_not_disturb_alt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final accent = tokens.connectedAccent;
    final l10n = context.l10n;
    final label = switch (policy) {
      CommentPolicy.open => l10n.composePostPageReactionBarOpen,
      CommentPolicy.approved => l10n.composePostPageReactionBarApproved,
      CommentPolicy.disabled => l10n.composePostPageReactionBarDisabled,
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: tokens.borderSubtle, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(_icon, size: 16, color: accent),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (requireVerified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  l10n.composePostPageBadgeCitizen,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Comment policy sheet
// ============================================================================

class _CommentPolicySheet extends StatefulWidget {
  final CommentPolicy policy;
  final bool requireVerified;

  const _CommentPolicySheet({
    required this.policy,
    required this.requireVerified,
  });

  @override
  State<_CommentPolicySheet> createState() => _CommentPolicySheetState();
}

class _CommentPolicySheetState extends State<_CommentPolicySheet> {
  late CommentPolicy _policy = widget.policy;
  late bool _requireVerified = widget.requireVerified;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    context.l10n.composePostPageWhoCanReply,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            _PolicyRow(
              policy: CommentPolicy.open,
              label: context.l10n.composePostPagePolicyAnyone,
              subtitle: context.l10n.composePostPageCommentSubtitleAnyone,
              selected: _policy == CommentPolicy.open,
              onTap: () => setState(() => _policy = CommentPolicy.open),
            ),
            _PolicyRow(
              policy: CommentPolicy.approved,
              label: context.l10n.composePostPagePolicyAllowList,
              subtitle: context.l10n.composePostPageCommentSubtitleAllowList,
              selected: _policy == CommentPolicy.approved,
              onTap: () => setState(() => _policy = CommentPolicy.approved),
            ),
            _PolicyRow(
              policy: CommentPolicy.disabled,
              label: context.l10n.composePostPagePolicyDisabled,
              subtitle: context.l10n.composePostPageCommentSubtitleDisabled,
              selected: _policy == CommentPolicy.disabled,
              onTap: () => setState(() => _policy = CommentPolicy.disabled),
            ),
            Divider(color: tokens.borderSubtle, height: 1),
            InkWell(
              onTap: () =>
                  setState(() => _requireVerified = !_requireVerified),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 20, color: tokens.starkWhite),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.composePostPageRequireVerifiedCitizen,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.composePostPageCommentVerifiedSubtitle,
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: _requireVerified,
                      onChanged: (v) => setState(() => _requireVerified = v),
                      activeColor: tokens.connectedAccent,
                      inactiveTrackColor: tokens.surfaceElevated,
                      inactiveThumbColor: tokens.borderMedium,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  const Spacer(),
                  _SheetDoneButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (_policy, _requireVerified),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Reaction policy sheet (sibling of _CommentPolicySheet — independent
// toggle). Reuses _PolicyRow + the
// CommentPolicy enum since the three states map identically; only the
// human-facing copy and the verified-required wording differ.
// ============================================================================

class _ReactionPolicySheet extends StatefulWidget {
  final CommentPolicy policy;
  final bool requireVerified;

  const _ReactionPolicySheet({
    required this.policy,
    required this.requireVerified,
  });

  @override
  State<_ReactionPolicySheet> createState() => _ReactionPolicySheetState();
}

class _ReactionPolicySheetState extends State<_ReactionPolicySheet> {
  late CommentPolicy _policy = widget.policy;
  late bool _requireVerified = widget.requireVerified;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    context.l10n.composePostPageWhoCanReact,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            _PolicyRow(
              policy: CommentPolicy.open,
              label: context.l10n.composePostPagePolicyAnyone,
              subtitle: context.l10n.composePostPageReactionSubtitleAnyone,
              selected: _policy == CommentPolicy.open,
              onTap: () => setState(() => _policy = CommentPolicy.open),
            ),
            _PolicyRow(
              policy: CommentPolicy.approved,
              label: context.l10n.composePostPagePolicyAllowList,
              subtitle: context.l10n.composePostPageReactionSubtitleAllowList,
              selected: _policy == CommentPolicy.approved,
              onTap: () => setState(() => _policy = CommentPolicy.approved),
            ),
            _PolicyRow(
              policy: CommentPolicy.disabled,
              label: context.l10n.composePostPagePolicyDisabled,
              subtitle: context.l10n.composePostPageReactionSubtitleDisabled,
              selected: _policy == CommentPolicy.disabled,
              onTap: () => setState(() => _policy = CommentPolicy.disabled),
            ),
            Divider(color: tokens.borderSubtle, height: 1),
            InkWell(
              onTap: () =>
                  setState(() => _requireVerified = !_requireVerified),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined,
                        size: 20, color: tokens.starkWhite),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.composePostPageRequireVerifiedCitizen,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.composePostPageReactionVerifiedSubtitle,
                            style: TextStyle(
                              color: tokens.textDim,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch.adaptive(
                      value: _requireVerified,
                      onChanged: (v) => setState(() => _requireVerified = v),
                      activeColor: tokens.connectedAccent,
                      inactiveTrackColor: tokens.surfaceElevated,
                      inactiveThumbColor: tokens.borderMedium,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  const Spacer(),
                  _SheetDoneButton(
                    onPressed: () => Navigator.pop(
                      context,
                      (_policy, _requireVerified),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final CommentPolicy policy;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PolicyRow({
    required this.policy,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(policy.icon, size: 20, color: tokens.starkWhite),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? tokens.starkWhite : tokens.borderMedium,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.starkWhite,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDoneButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SheetDoneButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          child: Text(
            context.l10n.composePostPageDone,
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Language picker sheet
// ============================================================================

class _LanguagePickerSheet extends StatelessWidget {
  final String selected;
  const _LanguagePickerSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surfaceDeep,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text(
                context.l10n.composePostPageLanguageHeader,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            ..._languages.map(
              (l) => InkWell(
                onTap: () => Navigator.pop(context, l.code),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 42,
                        child: Text(
                          l.code.toUpperCase(),
                          style: TextStyle(
                            color: tokens.textDim,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          l.name,
                          style: TextStyle(
                            color: tokens.starkWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (l.code == selected)
                        Icon(Icons.check_rounded,
                            size: 20, color: tokens.connectedAccent),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Channel picker sheet
// ============================================================================

class _ChannelPickerSheet extends StatelessWidget {
  final List<Channel> channels;
  final Channel? selected;
  const _ChannelPickerSheet({required this.channels, this.selected});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text(
                context.l10n.composePostPageChannelHeader,
                style: TextStyle(
                  color: tokens.textDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ),
            ...channels.map(
              (c) => InkWell(
                onTap: () => Navigator.pop(context, c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      ChannelIcon(channel: c, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                color: tokens.starkWhite,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (c.description.isNotEmpty)
                              Text(
                                c.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: tokens.textDim,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (c.id == selected?.id)
                        Icon(Icons.check_rounded,
                            color: tokens.connectedAccent, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom toolbar
// ============================================================================

class _Toolbar extends StatelessWidget {
  final VoidCallback onAddHero;
  final VoidCallback onAddAudio;
  final VoidCallback onAddMedia;
  final VoidCallback onToggleTitle;
  final VoidCallback onToggleSummary;
  final VoidCallback onToggleLink;
  final VoidCallback onAddTag;
  final bool titleActive;
  final bool summaryActive;
  final bool linkActive;
  final bool tagsActive;

  /// How many heroes / support items the draft holds, shown on the two
  /// picker buttons.
  final int heroCount;
  final int mediaCount;

  /// The draft holds its sound track (one at most; a pick replaces it).
  final bool audioActive;
  final PostLayoutMode layout;
  final ValueChanged<PostLayoutMode> onLayout;

  const _Toolbar({
    required this.onAddHero,
    required this.onAddAudio,
    required this.onAddMedia,
    required this.audioActive,
    required this.onToggleTitle,
    required this.onToggleSummary,
    required this.onToggleLink,
    required this.onAddTag,
    required this.titleActive,
    required this.summaryActive,
    required this.linkActive,
    required this.tagsActive,
    required this.heroCount,
    required this.mediaCount,
    required this.layout,
    required this.onLayout,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    // Icons in page order (title → hero → summary → link → media → tags),
    // the live Compact | Wide toggle at the right. Two picker buttons for
    // the card's two media places: Hero (the banner slot, paged when
    // several) and Media (the carousel under the text), both multi-select,
    // each with its count. No character counter: the caps come from the SSP
    // and the fields simply stop.
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolBtn(
                      icon: Icons.title_rounded,
                      tooltip: context.l10n.composePostPageTitle,
                      active: titleActive,
                      onTap: onToggleTitle,
                    ),
                    _ToolBtn(
                      icon: Icons.panorama_outlined,
                      tooltip: context.l10n.composePostPageTooltipHero,
                      active: heroCount > 0,
                      count: heroCount,
                      onTap: onAddHero,
                    ),
                    _ToolBtn(
                      icon: Icons.audiotrack_rounded,
                      tooltip: context.l10n.composePostPageTooltipAudio,
                      active: audioActive,
                      onTap: onAddAudio,
                    ),
                    _ToolBtn(
                      icon: Icons.short_text_rounded,
                      tooltip: context.l10n.composePostPageTooltipSummary,
                      active: summaryActive,
                      onTap: onToggleSummary,
                    ),
                    _ToolBtn(
                      icon: Icons.link_rounded,
                      tooltip: context.l10n.composePostPageTooltipLink,
                      active: linkActive,
                      onTap: onToggleLink,
                    ),
                    _ToolBtn(
                      icon: Icons.perm_media_outlined,
                      tooltip: context.l10n.composePostPageTooltipMedia,
                      active: mediaCount > 0,
                      count: mediaCount,
                      onTap: onAddMedia,
                    ),
                    _ToolBtn(
                      icon: Icons.tag_rounded,
                      tooltip: context.l10n.composePostPageTooltipTags,
                      active: tagsActive,
                      onTap: onAddTag,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _LayoutToggle(layout: layout, onChanged: onLayout),
          ],
        ),
      ),
    );
  }
}

/// Compact | Wide, two glyphs in one thin pill. Re-lays the card live.
class _LayoutToggle extends StatelessWidget {
  final PostLayoutMode layout;
  final ValueChanged<PostLayoutMode> onChanged;

  const _LayoutToggle({required this.layout, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    Widget seg(PostLayoutMode mode, IconData icon, String tooltip) {
      final on = layout == mode;
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () => onChanged(mode),
          child: Container(
            width: 36,
            height: 30,
            color: on ? tokens.glassFillHover : Colors.transparent,
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 17,
              color: on ? tokens.starkWhite : tokens.textDim,
            ),
          ),
        ),
      );
    }

    return Material(
      color: tokens.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(PostLayoutMode.compact, Icons.view_agenda_outlined,
              context.l10n.feedsSettingsSheetLayoutCompact),
          seg(PostLayoutMode.wide, Icons.crop_landscape_outlined,
              context.l10n.feedsSettingsSheetLayoutWide),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;

  /// A picker button's item count, as a small accent pill on the icon's
  /// corner; 0 draws nothing.
  final int count;
  final VoidCallback onTap;

  const _ToolBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = active ? tokens.connectedAccent : tokens.textDim;
    Widget glyph = Icon(icon, size: 22, color: color);
    if (count > 0) {
      glyph = Stack(
        clipBehavior: Clip.none,
        children: [
          glyph,
          Positioned(
            right: -7,
            top: -5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.connectedAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: glyph,
        ),
      ),
    );
  }
}
