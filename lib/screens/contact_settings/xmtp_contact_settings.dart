import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/theme_provider.dart' show PhigitalStyle;
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

class XmtpContactSettings extends StatefulWidget {
  final Contact contact;

  const XmtpContactSettings({
    super.key,
    required this.contact,
  });

  @override
  State<XmtpContactSettings> createState() => _XmtpContactSettingsState();
}

class _XmtpContactSettingsState extends State<XmtpContactSettings> {
  late Contact _contact;
  Color? selectedColor;
  bool _isUpdatingDetails = false;
  final TextEditingController _displayNameController = TextEditingController();
  final List<Color> availableColors = PhigitalStyle.colorPresets;

  /// True for any non-PublicOS contact (with or without a DM conversation topic).
  /// Covers: XMTP-only contacts, group member stubs, unresolved contacts.
  bool get isXmtpOnlyContact => _contact.publicosAddress == null;

  void _copyToClipboard(String text, String label) {
    final message = context.l10n.xmtpContactSettingsCopiedToClipboard(label);
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty || address.length < 10) {
      return context.l10n.xmtpContactSettingsInvalidAddress;
    }
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      if (isXmtpOnlyContact) {
        final colorValue = _contact.getRecordValue('color');
        if (colorValue != null) {
          setState(() {
            selectedColor = Color(int.parse(colorValue));
          });
        }

        _displayNameController.text = _contact.displayName;
      }
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _updateDisplayName(String newName) async {
    if (!isXmtpOnlyContact || newName.isEmpty) return;

    try {
      final record = Record.asSettings(
        key: 'displayName',
        value: newName,
        isSystem: true,
        expiration: DateTime.now().add(const Duration(days: 365)),
      );

      final updatedRecords = List<Record>.from(_contact.records);
      final existingNameIndex = updatedRecords.indexWhere((r) => r.key == 'displayName');
      if (existingNameIndex != -1) {
        updatedRecords[existingNameIndex] = record;
      } else {
        updatedRecords.add(record);
      }

      final updatedContact = _contact.copyWith(
        records: updatedRecords,
        displayName: newName,
      );

      await PublicOSContacts.saveContact(updatedContact);

      setState(() {
        _contact = updatedContact;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xmtpContactSettingsDisplayNameUpdated)),
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

  Future<void> _updateContactColor(Color color) async {
    if (!isXmtpOnlyContact) return;

    try {
      final record = Record.asSettings(
        key: 'color',
        // ignore: deprecated_member_use
        value: color.value.toString(),
        isSystem: true,
        expiration: DateTime.now().add(const Duration(days: 365)),
      );

      final updatedRecords = List<Record>.from(_contact.records);
      final existingColorIndex = updatedRecords.indexWhere((r) => r.key == 'color');
      if (existingColorIndex != -1) {
        updatedRecords[existingColorIndex] = record;
      } else {
        updatedRecords.add(record);
      }

      final updatedContact = _contact.copyWith(records: updatedRecords);

      await PublicOSContacts.saveContact(updatedContact);

      setState(() {
        _contact = updatedContact;
        selectedColor = color;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xmtpContactSettingsColorUpdated)),
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

  /// Re-resolve contact details from ENS/Farcaster/Base
  Future<void> _updateContactDetails() async {
    if (!isXmtpOnlyContact) return;

    setState(() {
      _isUpdatingDetails = true;
    });

    try {
      final resolvedContact = await PublicOSContacts.resolveContact(_contact, forceResolve: true);

      setState(() {
        _contact = resolvedContact;
        _isUpdatingDetails = false;
      });

      await _loadCurrentSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.xmtpContactSettingsDetailsUpdated)),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdatingDetails = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizedError(context.l10n, e))),
        );
      }
    }
  }

  Widget _buildColorCircle(GlassTokens tokens, Color color) {
    final isSelected = color == selectedColor;
    return GestureDetector(
      onTap: () => _updateContactColor(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? tokens.starkWhite : tokens.borderSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(GlassTokens tokens, IconData icon, String title) {
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
      ],
    );
  }

  Widget _buildCopyableField(GlassTokens tokens, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
          ),
          if (value != null)
            InkWell(
              onTap: () => _copyToClipboard(value, label),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text(
                      _formatAddress(value),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: tokens.starkWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: tokens.textDim,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    if (!isXmtpOnlyContact) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: Center(
          child: Text(
            context.l10n.xmtpContactSettingsUnsupportedContact,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: tokens.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(tokens, Icons.info_outline_rounded, context.l10n.xmtpContactSettingsContactInformation),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.borderSubtle, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCopyableField(
                  tokens,
                  context.l10n.xmtpContactSettingsPrimaryInboxId,
                  _contact.registeredInboxIDs?.firstOrNull?.inboxId,
                ),
              ],
            ),
          ),

          if (_contact.sessions != null && _contact.sessions!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _sectionHeader(tokens, Icons.devices_rounded, context.l10n.xmtpContactSettingsClientsSection),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              constraints: BoxConstraints(
                maxHeight: (_contact.sessions!.length > 6 ? 6 : _contact.sessions!.length) * 48.0,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: _contact.sessions!.length > 6
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _contact.sessions!.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: tokens.borderSubtle,
                ),
                itemBuilder: (context, index) {
                  final sessionItem = _contact.sessions![index];
                  final address = sessionItem.address.eip55With0x;
                  final label = sessionItem.label.toLowerCase();
                  final isRecovery = label == 'recovery';
                  final chipColor =
                      isRecovery ? tokens.fallbackAccent : tokens.starkWhite;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          _formatAddress(address),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: tokens.starkWhite,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isRecovery
                                ? tokens.fallbackAccent.withValues(alpha: 0.12)
                                : tokens.glassFill,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isRecovery
                                  ? tokens.fallbackAccent.withValues(alpha: 0.4)
                                  : tokens.borderSubtle,
                            ),
                          ),
                          child: Text(
                            sessionItem.label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: chipColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkResponse(
                          onTap: () => _copyToClipboard(
                              address, context.l10n.xmtpContactSettingsAddressLabel),
                          radius: 18,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: tokens.textDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          _sectionHeader(tokens, Icons.edit_rounded, context.l10n.xmtpContactSettingsDisplayName),
          const SizedBox(height: 12),
          TextField(
            controller: _displayNameController,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: tokens.surfaceElevated,
              hintText: context.l10n.xmtpContactSettingsEnterDisplayName,
              hintStyle: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
              ),
            ),
            onSubmitted: _updateDisplayName,
          ),

          const SizedBox(height: 24),

          _sectionHeader(tokens, Icons.palette_rounded, context.l10n.xmtpContactSettingsChatColor),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tokens.borderSubtle, width: 1),
            ),
            child: HorizontalWheel(child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (selectedColor != null) _buildColorCircle(tokens, selectedColor!),
                  ...availableColors
                      .where((color) => color != selectedColor)
                      .map((color) => _buildColorCircle(tokens, color)),
                ],
              ),
            )),
          ),

          const SizedBox(height: 28),

          SystemAppActionButton(
            label: context.l10n.xmtpContactSettingsSaveChanges,
            icon: Icons.save_rounded,
            onTap: () => _updateDisplayName(_displayNameController.text),
          ),

          const SizedBox(height: 12),

          SystemAppActionButton(
            label: _isUpdatingDetails
                ? context.l10n.xmtpContactSettingsUpdating
                : context.l10n.xmtpContactSettingsUpdateContactDetails,
            icon: Icons.refresh_rounded,
            onTap: _isUpdatingDetails ? null : _updateContactDetails,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
