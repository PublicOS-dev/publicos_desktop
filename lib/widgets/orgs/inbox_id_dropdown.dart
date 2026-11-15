import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

class InboxIdDropdown extends StatelessWidget {
  final Contact contact;
  final List<Map<String, dynamic>> inboxIds;
  final Function(Contact, String, String) onInboxIdSelected;
  final bool showAbove;

  const InboxIdDropdown({
    super.key,
    required this.contact,
    required this.inboxIds,
    required this.onInboxIdSelected,
    this.showAbove = false,
  });

  String _formatInboxId(String inboxId) {
    if (inboxId.length <= 8) return inboxId;
    return '${inboxId.substring(0, 4)}...${inboxId.substring(inboxId.length - 4)}';
  }

  void _copyToClipboard(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.inboxIdDropdownCopied),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(20),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: PhigitalStyle.cardBackground(isDark),
        borderRadius: BorderRadius.circular(PhigitalStyle.radiusCard),
        border: Border.all(color: PhigitalStyle.cardBorder(isDark), width: 1),
        boxShadow: PhigitalStyle.cardShadow(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with contact icon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: PhigitalStyle.subtleTint(isDark),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(PhigitalStyle.radiusCard),
                topRight: Radius.circular(PhigitalStyle.radiusCard),
              ),
            ),
            child: Column(
              children: [
                GlassContactIcon(
                  contact: contact,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  contact.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.inboxIdDropdownSelectTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha:0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Options
          ...inboxIds.asMap().entries.map((entry) {
            final index = entry.key;
            final inboxIdData = entry.value;
            final inboxId = inboxIdData['inboxId'] as String;
            final label = inboxIdData['label'] as String? ?? context.l10n.inboxIdDropdownDefaultLabel;
            final isLast = index == inboxIds.length - 1;
            
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha:0.3),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => onInboxIdSelected(contact, inboxId, label),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Inbox icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inbox_outlined,
                          size: 20,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Label and inbox ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatInboxId(inboxId),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha:0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Copy button
                      IconButton(
                        onPressed: () => _copyToClipboard(inboxId, context),
                        icon: Icon(
                          Icons.copy_outlined,
                          size: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha:0.6),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}