import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';

/// Centered, muted "system line" for group membership + metadata events
/// (`xmtp.org/group_updated`). Rendered in the chat timeline *in place of* a
/// message bubble — no bubble chrome, no reactions, no long-press, no seen
/// indicator. One line per affected inbox / metadata change.
///
/// Each referenced person renders as an inline `[mini-icon] name` pair, so a
/// two-party event ("X added Y") shows both avatars next to their own names
/// rather than a single leading icon that mismatches the leading name.
///
/// `leave_request` (a member's self-removal request) is deliberately NOT
/// surfaced — libxmtp's `PendingSelfRemoveWorker` auto-honors it into a
/// `group_updated` removal within ~2s, and that removal is what we render here.
class GroupEventLine extends StatelessWidget {
  /// The decoded `group_updated` payload (membership + metadata deltas).
  final GroupUpdated event;

  /// The active user's inbox id, so we can say "you" instead of a name.
  final String myInboxId;

  /// Resolve an inbox id to a cached [Contact] (name + avatar). Returns null
  /// when the contact isn't cached; the inline piece then drops the mini-icon
  /// and falls back to a short id.
  final Contact? Function(String inboxId) contactLookup;

  const GroupEventLine({
    super.key,
    required this.event,
    required this.myInboxId,
    required this.contactLookup,
  });

  @override
  Widget build(BuildContext context) {
    final initiator = event.initiatedByInboxId;
    final rows = <Widget>[];

    for (final added in event.addedInboxes) {
      final who = added.inboxId;
      final spans = (initiator.isNotEmpty && initiator != who)
          ? [
              ..._person(initiator),
              const TextSpan(text: ' added '),
              ..._person(who),
            ]
          : [
              ..._person(who),
              const TextSpan(text: ' joined the conversation'),
            ];
      rows.add(_row(context, spans));
    }

    for (final removed in event.removedInboxes) {
      rows.add(_row(context, [
        ..._person(removed.inboxId),
        const TextSpan(text: ' left the conversation'),
      ]));
    }

    for (final change in event.metadataFieldChanges) {
      rows.add(_row(context, [
        ..._person(initiator),
        TextSpan(text: ' ${_metadataAction(change.fieldName, change.newValue)}'),
      ]));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }

  /// Inline spans for one referenced person: `[mini-icon] name`. The icon is
  /// dropped when the contact isn't cached (name-only fallback).
  List<InlineSpan> _person(String inboxId) {
    final contact = inboxId.isNotEmpty ? contactLookup(inboxId) : null;
    return [
      if (contact != null)
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GlassContactIcon(contact: contact, size: 16),
          ),
        ),
      TextSpan(
        text: _name(inboxId),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ];
  }

  /// Display name for an inbox id: "you" for self, the contact's display name
  /// if cached, otherwise a short `0x1234…abcd`-style id.
  String _name(String inboxId) {
    if (inboxId.isEmpty) return 'Someone';
    if (inboxId == myInboxId) return 'you';
    final name = contactLookup(inboxId)?.displayName;
    if (name != null && name.isNotEmpty) return name;
    if (inboxId.length >= 10) {
      return '${inboxId.substring(0, 6)}…${inboxId.substring(inboxId.length - 4)}';
    }
    return inboxId;
  }

  /// The verb phrase for a metadata change (no leading name — the caller
  /// prepends the initiator's `[icon] name`).
  String _metadataAction(String field, String newValue) {
    switch (field) {
      case 'group_name':
        return newValue.isNotEmpty
            ? 'named the conversation "$newValue"'
            : 'changed the conversation name';
      case 'group_image_url_square':
        return 'changed the conversation photo';
      case 'description':
        return 'changed the description';
      default:
        return 'updated the conversation';
    }
  }

  Widget _row(BuildContext context, List<InlineSpan> spans) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
