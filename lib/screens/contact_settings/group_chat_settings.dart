import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/media_url_field.dart';
import 'package:publicos_desktop/widgets/inline_flow_host.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/screens/create_group_page.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Settings view for an XMTP group conversation.
///
/// In Core 1.0, groups live on `XmtpConversation`, not on `Contact`. This
/// widget takes the conversation `topic` and loads the rest (group name,
/// description, image, members) via `PublicOSConversations`.
class GroupChatSettings extends StatefulWidget {
  final String topic;

  const GroupChatSettings({
    super.key,
    required this.topic,
  });

  @override
  State<GroupChatSettings> createState() => _GroupChatSettingsState();
}

class _GroupChatSettingsState extends State<GroupChatSettings> {
  bool _isLoading = true;
  XmtpConversation? _conversation;
  final List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  final Map<String, Contact> _contactCache = {};
  final Set<String> _adminInboxIds = {};
  final Set<String> _superAdminInboxIds = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();
  bool _isSaving = false;
  String? _roleFilter; // null = All, 'superAdmin', 'admin', 'member'

  // Tracks an upload made *in this session* that hasn't been committed yet.
  // Cleared after a successful save; deleted on dispose if the user
  // navigates away without saving.
  int? _pendingUploadId;

  @override
  void initState() {
    super.initState();
    _memberSearchController.addListener(_filterMembers);
    _loadGroupData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _memberSearchController.dispose();
    final pending = _pendingUploadId;
    if (pending != null) {
      PublicOSSsp.deleteMedia(pending);
    }
    super.dispose();
  }

  void _filterMembers() {
    final query = _memberSearchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _members.where((member) {
        if (_roleFilter != null) {
          final isSuperAdmin = member['isSuperAdmin'] as bool;
          final isAdmin = member['isAdmin'] as bool;
          if (_roleFilter == 'superAdmin' && !isSuperAdmin) return false;
          if (_roleFilter == 'admin' && !isAdmin) return false;
          if (_roleFilter == 'member' && (isAdmin || isSuperAdmin)) return false;
        }
        if (query.isNotEmpty) {
          final inboxId = member['inboxId'] as String? ?? '';
          final address = member['address'] as String? ?? '';
          final contact = _contactCache[inboxId];
          final displayName = contact?.displayName ?? '';
          return displayName.toLowerCase().contains(query) ||
              inboxId.toLowerCase().contains(query) ||
              address.toLowerCase().contains(query);
        }
        return true;
      }).toList();
    });
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      final conv = await PublicOSConversations.getConversation(widget.topic);
      if (conv == null) {
        throw Exception('Conversation not found for topic ${widget.topic}');
      }
      _conversation = conv;

      _nameController.text = conv.groupName ?? '';
      _descriptionController.text = conv.groupDescription ?? '';
      _imageUrlController.text = conv.groupImageUrl ?? '';

      _members.clear();
      _adminInboxIds.clear();
      _superAdminInboxIds.clear();

      final results = await Future.wait([
        PublicOSConversations.listGroupMembers(widget.topic),
        PublicOSConversations.listGroupAdmins(widget.topic),
        PublicOSConversations.listGroupSuperAdmins(widget.topic),
      ]);

      final members = results[0];
      final admins = results[1];
      final superAdmins = results[2];

      for (final admin in admins) {
        final inboxId = admin['inboxId'];
        if (inboxId is String) {
          _adminInboxIds.add(inboxId);
        }
      }

      for (final superAdmin in superAdmins) {
        final inboxId = superAdmin['inboxId'];
        if (inboxId is String) {
          _superAdminInboxIds.add(inboxId);
        }
      }

      for (final member in members) {
        final inboxId = member['inboxId'];
        final address = member['address'];

        if (inboxId is String) {
          _members.add({
            'inboxId': inboxId,
            'address': address is List
                ? (address.isNotEmpty ? address.first.toString() : '')
                : (address?.toString() ?? ''),
            'isAdmin': _adminInboxIds.contains(inboxId),
            'isSuperAdmin': _superAdminInboxIds.contains(inboxId),
          });
        }
      }

      await _loadContactsForMembers();

      _filteredMembers = List.from(_members);
      _memberSearchController.clear();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading group data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }

  Future<void> _loadContactsForMembers() async {
    for (final member in _members) {
      final inboxId = member['inboxId'] as String?;
      final address = member['address'] as String?;
      if (inboxId == null) continue;

      try {
        Contact? contact = await PublicOSContacts.searchContacts(inboxId);
        if (contact == null && address != null && address.isNotEmpty) {
          contact = await PublicOSContacts.searchContacts(address);
        }

        if (contact != null) {
          _contactCache[inboxId] = contact;
        }
      } catch (e) {
        print('Error loading contact for $inboxId: $e');
      }
    }
  }

  Future<void> _updateGroupInfo() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupChatSettingsNameEmpty)),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updates = <String, String>{
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
      };

      await PublicOSConversations.updateGroup(widget.topic, updates);

      await PublicOSConversations.updateGroupMetadata(
        widget.topic,
        groupName: updates['name'],
        groupDescription: updates['description'],
        groupImageUrl: updates['imageUrl'],
      );

      _pendingUploadId = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.groupChatSettingsUpdateSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _removeMember(String inboxId, String address) async {
    try {
      await PublicOSConversations.removeGroupMembers(widget.topic, [inboxId]);
      await _loadGroupData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.groupChatSettingsMemberRemoved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }

  Future<void> _addMemberToGroup() async {
    final existingMemberInboxIds =
        _members.map((member) => member['inboxId'] as String).toList();

    // Same glass member picker as messages → New group, in add mode:
    // page 2 skipped, existing members filtered out, pops true on success.
    // DELTA(desktop): hosted in a big dialog via InlineFlowHost (client
    // pushes a CupertinoPageRoute).
    final bool? membersAdded = await showFlowPageDialog<bool>(
      context,
      page: CreateGroupPage.addMembers(
        topic: widget.topic,
        existingMemberInboxIds: existingMemberInboxIds,
      ),
    );

    if (membersAdded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.groupChatSettingsMembersAdded)),
      );
      _loadGroupData();
    }
  }

  Future<void> _toggleAdminRole(String inboxId, bool isAdmin) async {
    try {
      if (isAdmin) {
        await PublicOSConversations.removeGroupAdmin(widget.topic, inboxId);
      } else {
        await PublicOSConversations.addGroupAdmin(widget.topic, inboxId);
      }

      await _loadGroupData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isAdmin
                  ? context.l10n.groupChatSettingsAdminRemoved
                  : context.l10n.groupChatSettingsAdminGranted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }

  Future<void> _toggleSuperAdminRole(String inboxId, bool isSuperAdmin) async {
    try {
      if (isSuperAdmin) {
        await PublicOSConversations.removeGroupSuperAdmin(widget.topic, inboxId);
      } else {
        await PublicOSConversations.addGroupSuperAdmin(widget.topic, inboxId);
      }

      await _loadGroupData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isSuperAdmin
                  ? context.l10n.groupChatSettingsSuperAdminRemoved
                  : context.l10n.groupChatSettingsSuperAdminGranted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }

  Widget _buildMemberItem(GlassTokens tokens, Map<String, dynamic> member) {
    final inboxId = member['inboxId'] as String;
    final address = member['address'] as String;
    final isAdmin = member['isAdmin'] as bool;
    final isSuperAdmin = member['isSuperAdmin'] as bool;

    final cached = _contactCache[inboxId];
    // Fallback stub for a member whose local Contact hasn't landed yet
    // (resolveGroupMembers still running). Carries the inbox ID so the
    // profile launcher below always has a route.
    final contact = cached ??
        Contact(
          displayName: _formatAddress(address),
          sessions: address.isNotEmpty
              ? [
                  ContactSession(
                    address: EthereumAddress.fromHex(address),
                    label: 'main',
                  )
                ]
              : null,
          registeredInboxIDs: [InboxEntry(inboxId: inboxId, label: 'unknown')],
        );

    final roleLabel = isSuperAdmin
        ? context.l10n.groupChatSettingsRoleSuperAdmin
        : (isAdmin
            ? context.l10n.groupChatSettingsRoleAdmin
            : context.l10n.groupChatSettingsRoleMember);
    final roleColor = isSuperAdmin
        ? tokens.fallbackAccent
        : (isAdmin ? tokens.connectedAccent : tokens.textDim);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          // Avatar + name launch the member's profile — same launcher the
          // chat bubble uses (`AppNav.toContact` → focus the Contacts pane).
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => AppNav.toContact(context, contact),
              child: Row(
                children: [
                  GlassContactIcon(contact: contact, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.displayName,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.starkWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roleLabel,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _RoleIconButton(
            icon: isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.admin_panel_settings_outlined,
            active: isAdmin,
            activeColor: tokens.connectedAccent,
            tooltip: isAdmin
                ? context.l10n.groupChatSettingsRemoveAdmin
                : context.l10n.groupChatSettingsMakeAdmin,
            onTap: () => _toggleAdminRole(inboxId, isAdmin),
          ),
          _RoleIconButton(
            icon: isSuperAdmin ? Icons.star_rounded : Icons.star_outline_rounded,
            active: isSuperAdmin,
            activeColor: tokens.fallbackAccent,
            tooltip: isSuperAdmin
                ? context.l10n.groupChatSettingsRemoveSuperAdmin
                : context.l10n.groupChatSettingsMakeSuperAdmin,
            onTap: () => _toggleSuperAdminRole(inboxId, isSuperAdmin),
          ),
          _RoleIconButton(
            icon: Icons.person_remove_alt_1_outlined,
            active: true,
            activeColor: Theme.of(context).colorScheme.error,
            tooltip: context.l10n.groupChatSettingsRemoveMember,
            onTap: () => _removeMember(inboxId, address),
          ),
        ],
      ),
    );
  }

  String _formatAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  Widget _sectionHeader(
    GlassTokens tokens,
    IconData icon,
    String title, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: tokens.connectedAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _countPill(GlassTokens tokens, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: tokens.starkWhite,
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(GlassTokens tokens, {String? label, String? hint, Widget? prefixIcon}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
    );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
      ),
      hintStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.textDim,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: tokens.surfaceElevated,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    if (_isLoading) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: const Center(
          child: PhigitalLoadingWidget(size: 32, showShadows: false),
        ),
      );
    }

    final conv = _conversation;
    if (conv == null || conv.type != ConversationType.group) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: Center(
          child: Text(
            context.l10n.groupChatSettingsNotGroup,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
            ),
          ),
        ),
      );
    }

    final groupIconContact = Contact(
      displayName: conv.groupName ?? context.l10n.groupChatSettingsDefaultGroupName,
      isOrgAccount: true,
      records: (conv.groupImageUrl != null && conv.groupImageUrl!.isNotEmpty)
          ? [
              Record.asProfile(
                key: 'profile.avatar',
                value: conv.groupImageUrl!,
                expiration: DateTime.now().add(const Duration(days: 365)),
              )
            ]
          : const [],
    );

    final textStyle = TextStyle(
      fontFamily: 'SpaceGrotesk',
      color: tokens.starkWhite,
      fontSize: 14,
    );

    return Scaffold(
      backgroundColor: tokens.background,
      body: RefreshIndicator(
        onRefresh: _loadGroupData,
        color: tokens.starkWhite,
        backgroundColor: tokens.surfaceElevated,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(tokens, Icons.group_rounded,
                context.l10n.groupChatSettingsSectionDetails),
            const SizedBox(height: 16),
            Center(
              child: GlassContactIcon(
                contact: groupIconContact,
                size: 100,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    style: textStyle,
                    decoration: _fieldDecoration(tokens,
                        label: context.l10n.groupChatSettingsFieldName),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    style: textStyle,
                    maxLines: 2,
                    decoration: _fieldDecoration(tokens,
                        label: context.l10n.groupChatSettingsFieldDescription),
                  ),
                  const SizedBox(height: 12),
                  MediaUrlField(
                    controller: _imageUrlController,
                    enabled: !_isSaving,
                    decoration: _fieldDecoration(tokens,
                        label: context.l10n.groupChatSettingsFieldImageUrl),
                    onUploaded: (id) => _pendingUploadId = id,
                    onUploadDeleted: () => _pendingUploadId = null,
                  ),
                  const SizedBox(height: 16),
                  SystemAppActionButton(
                    label: _isSaving
                        ? context.l10n.groupChatSettingsSaving
                        : context.l10n.groupChatSettingsSaveChanges,
                    icon: Icons.save_rounded,
                    onTap: _isSaving ? null : _updateGroupInfo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionHeader(
              tokens,
              Icons.people_rounded,
              context.l10n.groupChatSettingsSectionMembers,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _countPill(tokens, _members.length),
                  const SizedBox(width: 8),
                  _AddMemberPill(onTap: _addMemberToGroup),
                ],
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _memberSearchController,
              style: textStyle,
              decoration: _fieldDecoration(
                tokens,
                hint: context.l10n.groupChatSettingsSearchHint,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: tokens.textDim,
                ),
              ),
            ),

            const SizedBox(height: 10),

            HorizontalWheel(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRoleChip(tokens, null, Icons.people_rounded,
                      context.l10n.groupChatSettingsFilterAll),
                  const SizedBox(width: 8),
                  _buildRoleChip(
                    tokens,
                    'superAdmin',
                    Icons.star_rounded,
                    context.l10n.groupChatSettingsFilterSuperAdmin,
                  ),
                  const SizedBox(width: 8),
                  _buildRoleChip(
                    tokens,
                    'admin',
                    Icons.admin_panel_settings_rounded,
                    context.l10n.groupChatSettingsFilterAdmin,
                  ),
                  const SizedBox(width: 8),
                  _buildRoleChip(
                    tokens,
                    'member',
                    Icons.person_outline_rounded,
                    context.l10n.groupChatSettingsFilterMember,
                  ),
                ],
              ),
            )),

            const SizedBox(height: 12),

            if (_members.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    context.l10n.groupChatSettingsNoMembers,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                    ),
                  ),
                ),
              )
            else if (_filteredMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    context.l10n
                        .groupChatSettingsNoMatch(_memberSearchController.text),
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: tokens.textDim,
                    ),
                  ),
                ),
              )
            else
              ClipRect(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 768),
                  child: SingleChildScrollView(
                    child: Column(
                      children: _filteredMembers
                          .map((m) => _buildMemberItem(tokens, m))
                          .toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(
    GlassTokens tokens,
    String? role,
    IconData icon,
    String label,
  ) {
    final isSelected = _roleFilter == role;
    final Color accent;
    if (role == 'superAdmin') {
      accent = tokens.fallbackAccent;
    } else if (role == 'admin') {
      accent = tokens.connectedAccent;
    } else {
      accent = tokens.starkWhite;
    }

    final int count;
    if (role == null) {
      count = _members.length;
    } else if (role == 'superAdmin') {
      count = _members.where((m) => m['isSuperAdmin'] as bool).length;
    } else if (role == 'admin') {
      count = _members.where((m) => m['isAdmin'] as bool).length;
    } else {
      count = _members
          .where((m) => !(m['isAdmin'] as bool) && !(m['isSuperAdmin'] as bool))
          .length;
    }

    final fg = isSelected ? accent : tokens.textDim;
    final bg = isSelected
        ? accent.withValues(alpha: 0.12)
        : Colors.transparent;
    final border = isSelected
        ? accent.withValues(alpha: 0.4)
        : tokens.borderSubtle;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: border, width: 1),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _roleFilter = role);
          _filterMembers();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                context.l10n.groupChatSettingsChipLabel(label, count),
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final String tooltip;
  final VoidCallback onTap;

  const _RoleIconButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final color = active ? activeColor : tokens.textDim;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _AddMemberPill extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMemberPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Material(
      color: tokens.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.borderMedium, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: tokens.starkWhite, size: 14),
              const SizedBox(width: 6),
              Text(
                context.l10n.groupChatSettingsAdd,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
