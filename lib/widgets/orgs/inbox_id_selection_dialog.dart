import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Dialog shown when a contact has multiple registered inbox IDs and the user
/// needs to pick one to add to a group. Returns a `{inboxId, label}` map via
/// `Navigator.pop` on selection.
class InboxIdSelectionDialog extends StatefulWidget {
  final Contact contact;
  final List<InboxEntry> availableInboxIds;

  const InboxIdSelectionDialog({
    super.key,
    required this.contact,
    required this.availableInboxIds,
  });

  @override
  State<InboxIdSelectionDialog> createState() => _InboxIdSelectionDialogState();
}

class _InboxIdSelectionDialogState extends State<InboxIdSelectionDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.inboxIdSelectionDialogTitle(
              widget.contact.displayName)),
          const SizedBox(height: 4),
          Text(
            context.l10n.inboxIdSelectionDialogSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.availableInboxIds.length,
          itemBuilder: (context, index) {
            final entry = widget.availableInboxIds[index];
            final inboxId = entry.inboxId;
            final label = entry.label;
            final shortId = inboxId.length > 12
                ? '${inboxId.substring(0, 6)}..${inboxId.substring(inboxId.length - 6)}'
                : inboxId;

            return ListTile(
              leading: GlassContactIcon(
                contact: widget.contact,
                size: 40,
              ),
              title: Text(
                widget.contact.displayName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                label.isNotEmpty ? '$label · $shortId' : shortId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              onTap: () {
                Navigator.pop(context, {
                  'inboxId': inboxId,
                  'label': label,
                });
              },
            );
          },
        ),
      ),
    );
  }
}
