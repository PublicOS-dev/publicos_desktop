import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/screens/contact_settings/xmtp_contact_settings.dart';
import 'package:publicos_desktop/screens/contact_settings/group_account_settings.dart';
import 'package:publicos_desktop/screens/contact_settings/group_chat_settings.dart';
import 'package:publicos_desktop/screens/contact_settings/publicos_account_settings.dart';
// import 'package:publicos_desktop/screens/user_account_settings.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';

class ContactSettingsScreen extends StatelessWidget {
  final Contact? contact; // New input for the contact

  const ContactSettingsScreen({
    super.key,
    this.contact, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    // Use the contact passed to the widget, if null, fallback to PublicOS.selectedProfile
    final displayedContact = contact;

    if (displayedContact == null) {
      return Scaffold(
        body: Center(
          child: Text(context.l10n.contactSettingsScreenNoContactSelected),
        ),
      );
    }

    // The user's own profile never lands here: its settings live in the
    // Account system app, and `browser.dart` renders no Settings tab when you
    // browse yourself.

    // Check if this is a group account (publicosAddress + isOrgAccount)
    if (displayedContact.publicosAddress != null && displayedContact.isOrgAccount == true) {
      return GroupAccountSettings(groupContact: displayedContact);
    }

    // Check if this is an individual PublicOS account (has publicosAddress but not a group)
    if (displayedContact.publicosAddress != null) {
      return PublicOSAccountSettings(contact: displayedContact);
    }

    // XMTP group-chat stub — settings for the group itself (name/image/members).
    if (displayedContact.isGroupChat &&
        displayedContact.xmtpConversationTopic != null) {
      return GroupChatSettings(topic: displayedContact.xmtpConversationTopic!);
    }

    // All other contacts (XMTP-only DMs, unresolved contacts, etc.)
    return XmtpContactSettings(contact: displayedContact);
  }
}
