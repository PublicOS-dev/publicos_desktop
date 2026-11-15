import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/router.dart';

// Assuming TextSizeOption is accessible, e.g., defined globally or passed differently.
// For now, using a direct double for textSize.
// If TextSizeOption from add_members_sheet.dart is needed, it should be moved to a shared location.

class ContactSelectItemWithInboxId extends StatelessWidget {
  final Contact contact;
  final bool isSelected;
  final VoidCallback onTap;
  final double textSize; // Directly use double for font size

  const ContactSelectItemWithInboxId({
    super.key,
    required this.contact,
    required this.isSelected,
    required this.onTap,
    this.textSize = 14.0, // Default text size
  });

  Color get _accentColor {
    // Attempt to get accent color from PublicOS, fallback to teal primary
    return Color(
      int.tryParse(
            AppStateNotifier.currentMyContact?.getRecordValue('color') ?? '',
          ) ??
          ThemeProvider.tealPrimary.value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? _accentColor.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: _accentColor, width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GlassContactIcon(
              contact: contact,
              size: 60, // Slightly smaller to accommodate text
            ),
            const SizedBox(height: 6),
            Text(
              contact.displayName,
              style: TextStyle(
                fontSize: textSize,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Builder(builder: (context) {
              final inboxId = contact.registeredInboxIDs?.firstOrNull?.inboxId;
              final inboxLabel = inboxId != null && inboxId.isNotEmpty
                  ? (inboxId.length > 10
                      ? '${inboxId.substring(0, 6)}...${inboxId.substring(inboxId.length - 4)}'
                      : inboxId)
                  : 'No Inbox ID';
              return Text(
                inboxLabel,
                style: TextStyle(
                  fontSize: textSize - 3, // Smaller for inbox ID
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }),
          ],
        ),
      ),
    );
  }
}
