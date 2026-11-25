import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_mentions/zero_mentions.dart';

import 'package:publicos_desktop/widgets/feeds/mention_suggestions.dart';

/// Mention support for a plain record editor (the bio, a text card's body).
/// Same wire form as posts
/// (`@[0xAddr]`), same panel and candidate rule as the post composer (stored
/// contacts, name-contains or address-prefix, cap 8); no notification, since
/// a record never passes a server.
///
/// Build the controller with [mentionRecordController], then put
/// [MentionAutocomplete] right under the field: it shows the panel while the
/// field has focus and an `@` run is open.
MentionTextEditingController mentionRecordController(String raw) {
  final c = MentionTextEditingController(
    displayNameFor: (a) => truncatedAddress(a),
    // = tokens.connectedAccent (built before a context exists), as the composer.
    mentionStyle: const TextStyle(color: Color(0xFF64FFDA), fontWeight: FontWeight.w600),
  );
  if (raw.isNotEmpty) c.loadRaw(raw);
  return c;
}

class MentionAutocomplete extends StatefulWidget {
  const MentionAutocomplete({super.key, required this.controller, required this.focusNode});

  final MentionTextEditingController controller;
  final FocusNode focusNode;

  @override
  State<MentionAutocomplete> createState() => _MentionAutocompleteState();
}

class _MentionAutocompleteState extends State<MentionAutocomplete> {
  List<Contact> _contacts = const [];
  late final MentionChainLookup _chain = MentionChainLookup(_changed);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
    widget.focusNode.addListener(_changed);
    PublicOSContacts.getStoredContacts().then((all) {
      if (mounted) setState(() => _contacts = all);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    widget.focusNode.removeListener(_changed);
    _chain.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  List<MentionCandidate> get _candidates {
    final t = widget.controller.trigger;
    if (t == null) {
      _chain.resultFor(null);
      return const [];
    }
    final q = t.query.toLowerCase();
    final out = <MentionCandidate>[];
    for (final c in _contacts) {
      final addr = c.publicosAddress?.eip55With0x;
      if (addr == null || c.displayName.isEmpty) continue;
      if (q.isNotEmpty && !c.displayName.toLowerCase().contains(q) && !addr.toLowerCase().startsWith(q)) {
        continue;
      }
      out.add(MentionCandidate(address: addr, display: c.displayName, contact: c));
    }
    return rankMentionCandidates(out, t.query, _chain.resultFor(t.query));
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.focusNode.hasFocus ? _candidates : const <MentionCandidate>[];
    if (candidates.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: MentionSuggestionsPanel(
        candidates: candidates,
        onPick: (c) {
          final t = widget.controller.trigger;
          if (t == null) return;
          widget.controller.insertMention(address: c.address, display: c.display, trigger: t);
          widget.focusNode.requestFocus();
        },
      ),
    );
  }
}
