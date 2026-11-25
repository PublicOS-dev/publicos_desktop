import 'package:publicos_core/publicos_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/widgets/phigital_loading_widget.dart';
import 'package:publicos_desktop/widgets/system_app_scaffold.dart';
import 'package:publicos_desktop/theme/theme_provider.dart' show PhigitalStyle;
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/utils/glass_sheet_dialog.dart';
import 'package:wallet/wallet.dart';
import 'package:publicos_desktop/router.dart';
import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';


class UserAccountSettings extends StatefulWidget {
  const UserAccountSettings({super.key});

  @override
  State<UserAccountSettings> createState() => _UserAccountSettingsState();
}

class _UserAccountSettingsState extends State<UserAccountSettings> {
  Color? selectedColor;
  Color? _userAccentColor;
  bool _isAddingRecoveryContact = false;
  bool _isAddingSession = false;
  bool _isRemovingSession = false;
  String? _sessionBeingRemoved;

  // Data loading state
  bool _isLoadingData = true;

  // Overlay status for in-page actions (color save, etc.). Null = no overlay.
  String? _actionStatus;

  // Recovery contacts data
  List<EthereumAddress> _recoveryContacts = [];
  int _recoveryThreshold = 0;
  List<Widget> _recoveryContactTiles = [];

  // Sessions data
  List<EthereumAddress> _sessions = [];
  List<Widget> _sessionTiles = [];
  final List<Color> availableColors = PhigitalStyle.colorPresets;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadCurrentColor() async {
    try {
      final colorRecord = await PublicOSContacts.getRecord('color', AppStateNotifier.currentMyContact!.publicosAddress!);
      if (colorRecord != null) {
        final color = Color(int.parse(colorRecord.value));
        setState(() {
          selectedColor = color;
          _userAccentColor = color;
        });
      } else {
        setState(() {
          _userAccentColor = Colors.blue.shade700;
        });
      }
    } catch (e) {
      print('Error loading color: $e');
      setState(() {
        _userAccentColor = Colors.blue.shade700;
      });
    }
  }

  /// Load all data at once to prevent rebuilds during scrolling
  Future<void> _loadAllData() async {
    setState(() => _isLoadingData = true);

    try {
      await _loadCurrentColor();
      await _loadRecoveryContactsData();
      await _loadSessionsData();
    } catch (e) {
      print('Error loading settings data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  /// Load recovery contacts data and build tiles
  Future<void> _loadRecoveryContactsData() async {
    try {
      final recoveryData = await PublicOSRecovery.getMyRecoveryContacts();

      if (recoveryData != null) {
        _recoveryContacts = recoveryData.contacts;
        _recoveryThreshold = recoveryData.threshold;

        List<Widget> tiles = [];
        for (final contactAddress in recoveryData.contacts) {
          try {
            final contact = await PublicOSContacts.fetchContact(contactAddress);
            tiles.add(_buildRecoveryContactTile(contact));
          } catch (e) {
            final fallbackContact = Contact(
              displayName: _formatAddress(contactAddress.eip55With0x),
              publicosDisplayName: _formatAddress(contactAddress.eip55With0x),
              publicosAddress: contactAddress,
            );
            tiles.add(_buildRecoveryContactTile(fallbackContact));
          }
        }
        _recoveryContactTiles = tiles;
      } else {
        _recoveryContacts = [];
        _recoveryThreshold = 0;
        _recoveryContactTiles = [];
      }
    } catch (e) {
      print('Error loading recovery contacts: $e');
      _recoveryContacts = [];
      _recoveryThreshold = 0;
      _recoveryContactTiles = [];
    }
  }

  /// Load sessions data and build tiles
  Future<void> _loadSessionsData() async {
    try {
      final sessions = await PublicOSAccounts.getMySessions();
      _sessions = sessions;

      List<Widget> tiles = [];
      final currentSessionAddress = PublicOS.sessionBlockchainAddress?.toLowerCase();

      for (final sessionAddress in sessions) {
        final isCurrentSession = sessionAddress.eip55With0x.toLowerCase() == currentSessionAddress;
        tiles.add(_buildSessionTile(sessionAddress, isCurrentSession));
      }
      _sessionTiles = tiles;
    } catch (e) {
      print('Error loading sessions: $e');
      _sessions = [];
      _sessionTiles = [];
    }
  }

  Future<void> _updateColor(Color color) async {
    final l10n = context.l10n;
    setState(() => _actionStatus = l10n.acctSettingsSavingColor);
    try {
      final record = Record.asSettings(
        key: 'color',
        value: color.value.toString(),
        isSystem: true,
      );
      await PublicOSContacts.setRecord(record);
      if (!mounted) return;
      setState(() => _actionStatus = l10n.acctSettingsRefreshingProfile);
      final addrHex = PublicOS.myPublicosAddress;
      if (addrHex != null) {
        await AppStateNotifier.loadMyContact();
      }
      if (!mounted) return;
      setState(() {
        selectedColor = color;
        _userAccentColor = color;
        _actionStatus = null;
      });
    } catch (e) {
      if (mounted) {
        _errorSnack(e, fallback: (l) => l.errUpdateColorFailed);
        setState(() => _actionStatus = null);
      }
    }
  }

  String _formatAddress(String? address) {
    if (address == null || address.isEmpty || address.length < 10) {
      return 'Invalid Address';
    }
    return "${address.substring(0, 6)}...${address.substring(address.length - 4)}";
  }

  void _copyToClipboard(String text, String label) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.acctSettingsCopiedToClipboard(label))),
      );
    });
  }

  /// Show a caught error (or `PublicOS.lastError`) in a red snackbar, localized.
  /// Reading context.l10n in this sync method keeps async catch sites free of
  /// use_build_context_synchronously.
  void _errorSnack(Object? error, {String Function(AppLocalizations)? fallback}) {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizedError(l10n, error, fallback: fallback?.call(l10n))),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: const Center(
          child: PhigitalLoadingWidget(size: 32, showShadows: false),
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? 24 : 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeader(tokens, Icons.shield_rounded, context.l10n.acctSettingsRecoveryContacts),
                  const SizedBox(height: 12),
                  ..._buildStaticRecoveryContactsList(tokens),

                  const SizedBox(height: 28),

                  _sectionHeader(tokens, Icons.devices_rounded, context.l10n.acctSettingsDevices),
                  const SizedBox(height: 12),
                  ..._buildStaticSessionsList(tokens),

                  const SizedBox(height: 28),

                  _sectionHeader(tokens, Icons.palette_rounded, context.l10n.acctSettingsAccentColor),
                  const SizedBox(height: 12),
                  _buildColorPicker(tokens),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
        if (_actionStatus != null)
          Positioned.fill(
            child: Container(
              color: tokens.background.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PhigitalLoadingWidget(
                      size: 56,
                      pulse: true,
                      showShadows: false,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _actionStatus!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.textDim,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

  Widget _buildColorPicker(GlassTokens tokens) {
    return Container(
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
                .map((c) => _buildColorCircle(tokens, c)),
          ],
        ),
      )),
    );
  }

  Widget _buildColorCircle(GlassTokens tokens, Color color) {
    final isSelected = color == selectedColor;
    final isDark = color.computeLuminance() < 0.5;

    return GestureDetector(
      onTap: () => _updateColor(color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
        child: isSelected
            ? Icon(
                Icons.check_rounded,
                color: isDark ? Colors.white : Colors.black,
                size: 20,
              )
            : null,
      ),
    );
  }

  /// Build static recovery contacts list from loaded data
  List<Widget> _buildStaticRecoveryContactsList(GlassTokens tokens) {
    if (AppStateNotifier.currentMyContact?.publicosAddress == null) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                context.l10n.acctSettingsNoAccountSelected,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
              const SizedBox(height: 16),
              _buildAddRecoveryContactButton(),
            ],
          ),
        ),
      ];
    }

    if (_recoveryContacts.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                context.l10n.acctSettingsNoRecoveryContacts,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.acctSettingsAddTrustedContactsHint,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildAddRecoveryContactButton(),
            ],
          ),
        ),
      ];
    }

    List<Widget> widgets = [];

    if (_recoveryThreshold > 0) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: tokens.glassFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: tokens.textDim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.acctSettingsRecoveryThreshold(_recoveryThreshold, _recoveryContacts.length),
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    widgets.addAll(_recoveryContactTiles);
    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildAddRecoveryContactButton());

    return widgets;
  }

  /// Build static sessions list from loaded data
  List<Widget> _buildStaticSessionsList(GlassTokens tokens) {
    if (AppStateNotifier.currentMyContact?.publicosAddress == null) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.acctSettingsNoAccountSelected,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
            ),
          ),
        ),
      ];
    }

    if (_sessions.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                context.l10n.acctSettingsNoSessionsFound,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.acctSettingsSessionsDescShort,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildAddSessionButton(),
            ],
          ),
        ),
      ];
    }

    List<Widget> widgets = [];

    widgets.add(
      Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: tokens.textDim),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.acctSettingsSessionsInfoBanner,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.textDim,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    widgets.addAll(_sessionTiles);
    widgets.add(const SizedBox(height: 16));
    widgets.add(_buildAddSessionButton());

    return widgets;
  }

  Widget _buildSessionTile(EthereumAddress sessionAddress, bool isCurrentSession) {
    final tokens = GlassTokens.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final isBeingRemoved = _sessionBeingRemoved == sessionAddress.eip55With0x;
    final canRemove = _sessions.length > 1 && !isCurrentSession;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSession
              ? tokens.connectedAccent.withValues(alpha: 0.4)
              : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCurrentSession
                  ? tokens.connectedAccent.withValues(alpha: 0.12)
                  : tokens.glassFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrentSession
                    ? tokens.connectedAccent.withValues(alpha: 0.4)
                    : tokens.borderSubtle,
              ),
            ),
            child: Icon(
              isCurrentSession ? Icons.smartphone_rounded : Icons.devices_other_rounded,
              color: isCurrentSession ? tokens.connectedAccent : tokens.starkWhite,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _copyToClipboard(
                          sessionAddress.eip55With0x,
                          context.l10n.acctSettingsSessionAddressLabel,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _formatAddress(sessionAddress.eip55With0x),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: tokens.starkWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
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
                    ),
                    if (isCurrentSession)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tokens.connectedAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tokens.connectedAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          context.l10n.acctSettingsCurrentBadge,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            color: tokens.connectedAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isCurrentSession
                      ? context.l10n.acctSettingsThisDevice
                      : context.l10n.acctSettingsAuthorizedDevice,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            isBeingRemoved
                ? const PhigitalLoadingWidget(size: 20, showShadows: false)
                : InkResponse(
                    onTap: () => _showRemoveSessionConfirmation(sessionAddress),
                    radius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.remove_circle_outline_rounded,
                        color: errorColor,
                        size: 20,
                      ),
                    ),
                  ),
          if (!canRemove && !isCurrentSession)
            Tooltip(
              message: context.l10n.acctSettingsCannotRemoveSession,
              child: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: tokens.textDim,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddSessionButton() {
    return SystemAppActionButton(
      label: _isAddingSession
          ? context.l10n.acctSettingsAddingConfirming
          : context.l10n.acctSettingsAddSession,
      icon: Icons.add_rounded,
      onTap: _isAddingSession ? null : _showAddSessionBottomSheet,
    );
  }

  // There is no typed-address add-session path. Adding a session requires
  // an EIP-712 sig from the new session's key (lives on the other
  // device). The new device shows a `publicos-claim:` QR; the OS scanner
  // dispatches a `publicos://add_session/<payload>` deep link that opens
  // AddSessionDialog with the pre-built sig.
  void _showAddSessionBottomSheet() {
    final l10n = context.l10n;
    showGlassSheetDialog<void>(
      context: context,
      width: DialogWidth.m,
      builder: (sheetCtx) {
        final tokens = GlassTokens.of(sheetCtx);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SheetHeader(
                title: l10n.acctSettingsAddNewSession,
                onClose: () => Navigator.of(sheetCtx).pop(),
              ),
              const SizedBox(height: 8),
              _instructionCard(
                tokens,
                icon: Icons.qr_code_scanner_rounded,
                title: l10n.acctSettingsLinkNewDeviceTitle,
                body: l10n.acctSettingsLinkNewDeviceBody,
              ),
              const SizedBox(height: 12),
              _instructionCard(
                tokens,
                icon: Icons.lock_outline_rounded,
                title: l10n.acctSettingsWhyQrTitle,
                body: l10n.acctSettingsWhyQrBody,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _instructionCard(
    GlassTokens tokens, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tokens.starkWhite, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  color: tokens.starkWhite,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveSessionConfirmation(EthereumAddress sessionAddress) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        final errorColor = Theme.of(ctx).colorScheme.error;
        return AlertDialog(
          backgroundColor: tokens.surfaceDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          title: Text(
            l10n.acctSettingsRemoveSessionTitle,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.acctSettingsRemoveSessionConfirm,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.devices_other_rounded,
                      size: 20,
                      color: tokens.textDim,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatAddress(sessionAddress.eip55With0x),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: tokens.starkWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.fallbackAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.fallbackAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: tokens.fallbackAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.acctSettingsRemoveSessionWarning,
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 12,
                          color: tokens.fallbackAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.dlgCancel,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _removeSession(sessionAddress);
              },
              child: Text(
                l10n.acctSettingsRemove,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: errorColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeSession(EthereumAddress sessionAddress) async {
    if (_isRemovingSession) return;

    final l10n = context.l10n;
    setState(() {
      _isRemovingSession = true;
      _sessionBeingRemoved = sessionAddress.eip55With0x;
    });

    try {
      final success = await PublicOSAccounts.removeSession(sessionAddress);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.acctSettingsSessionRemoved),
              backgroundColor: Colors.green,
            ),
          );
          await _loadSessionsData();
          setState(() {});
        }
      } else {
        _errorSnack(PublicOS.lastError, fallback: (l) => l.errRemoveSessionFailed);
      }
    } catch (e) {
      _errorSnack(e, fallback: (l) => l.errRemoveSessionFailed);
    } finally {
      if (mounted) {
        setState(() {
          _isRemovingSession = false;
          _sessionBeingRemoved = null;
        });
      }
    }
  }

  Widget _buildRecoveryContactTile(Contact contact) {
    final tokens = GlassTokens.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          GlassContactIcon(opensProfile: true, contact: contact, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: ContactProfileTap(contact: contact, child: Column(
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
                Text(
                  _formatAddress(contact.publicosAddress?.eip55With0x ?? ''),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: tokens.textDim,
                  ),
                ),
              ],
            )),
          ),
          InkResponse(
            onTap: () => _removeRecoveryContact(contact.publicosAddress!),
            radius: 20,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.remove_circle_outline_rounded,
                color: errorColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRecoveryContactButton() {
    return SystemAppActionButton(
      label: _isAddingRecoveryContact
          ? context.l10n.acctSettingsAddingConfirming
          : context.l10n.acctSettingsAddRecoveryContact,
      icon: Icons.person_add_alt_1_rounded,
      onTap: _isAddingRecoveryContact ? null : _showAddRecoveryContactBottomSheet,
    );
  }

  void _showAddRecoveryContactBottomSheet() {
    final tokens = GlassTokens.of(context);
    showGlassSheetDialog<void>(
      context: context,
      width: DialogWidth.m,
      builder: (sheetContext) => AddRecoveryContactSheet(
        accentColor: tokens.starkWhite,
        onContactSelected: (contact) {
          Navigator.pop(sheetContext);
          _showRecoveryContactConfirmation(contact);
        },
      ),
    );
  }

  Future<void> _addRecoveryContact(EthereumAddress contactAddress) async {
    if (_isAddingRecoveryContact) return;

    final l10n = context.l10n;
    setState(() => _isAddingRecoveryContact = true);

    try {
      final success = await PublicOSRecovery.addRecoveryContact(contactAddress);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.acctSettingsRecoveryContactAdded),
              backgroundColor: Colors.green,
            ),
          );
          await _loadRecoveryContactsData();
          setState(() {});
        }
      } else {
        _errorSnack(PublicOS.lastError, fallback: (l) => l.errAddRecoveryFailed);
      }
    } catch (e) {
      _errorSnack(e, fallback: (l) => l.errAddRecoveryFailed);
    } finally {
      if (mounted) {
        setState(() => _isAddingRecoveryContact = false);
      }
    }
  }

  Future<void> _removeRecoveryContact(EthereumAddress contactAddress) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        final errorColor = Theme.of(ctx).colorScheme.error;
        return AlertDialog(
          backgroundColor: tokens.surfaceDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          title: Text(
            l10n.acctSettingsRemoveRecoveryTitle,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.acctSettingsRemoveRecoveryConfirm(
              _formatAddress(contactAddress.eip55With0x),
            ),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                l10n.dlgCancel,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                l10n.acctSettingsRemove,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: errorColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final success = await PublicOSRecovery.removeRecoveryContact(contactAddress);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.acctSettingsRecoveryContactRemoved),
                backgroundColor: Colors.green,
              ),
            );
            await _loadRecoveryContactsData();
            setState(() {});
          }
        } else {
          _errorSnack(PublicOS.lastError, fallback: (l) => l.errRemoveRecoveryFailed);
        }
      } catch (e) {
        _errorSnack(e, fallback: (l) => l.errRemoveRecoveryFailed);
      }
    }
  }

  void _showRecoveryContactConfirmation(Contact contact) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) {
        final tokens = GlassTokens.of(ctx);
        return AlertDialog(
          backgroundColor: tokens.surfaceDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tokens.borderSubtle),
          ),
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
          title: Text(
            l10n.acctSettingsAddRecoveryContactTitle,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.acctSettingsAddRecoveryIntro,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tokens.borderSubtle),
                ),
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
                            ),
                          ),
                          Text(
                            _formatAddress(
                              contact.publicosAddress?.eip55With0x ?? '',
                            ),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: tokens.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.fallbackAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.fallbackAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: tokens.fallbackAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.acctSettingsRecoveryPermissionsTitle,
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontWeight: FontWeight.w800,
                            color: tokens.fallbackAccent,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.acctSettingsRecoveryPermissionsBody,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        color: tokens.fallbackAccent,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.dlgCancel,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.textDim,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _addRecoveryContact(contact.publicosAddress!);
              },
              child: Text(
                l10n.acctSettingsAddRecoveryContactTitle,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: tokens.starkWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AddRecoveryContactSheet extends StatefulWidget {
  final Function(Contact) onContactSelected;
  final Color accentColor;

  /// Reuse for other "pick a friend" lists (the Account app's "who can add
  /// me to groups" uses this same sheet). Null = the recovery wording and
  /// the recovery exclusion list.
  final String? title;
  final String? heading;
  final String? description;

  /// Addresses (lowercase 0x) to leave out. When null the sheet leaves out
  /// the account's current recovery contacts, as it always did.
  final Set<String>? excludeAddresses;

  /// Hide org accounts (an org can never be on an individuals-only list).
  final bool individualsOnly;

  const AddRecoveryContactSheet({
    super.key,
    required this.onContactSelected,
    required this.accentColor,
    this.title,
    this.heading,
    this.description,
    this.excludeAddresses,
    this.individualsOnly = false,
  });

  @override
  State<AddRecoveryContactSheet> createState() => _AddRecoveryContactSheetState();
}

class _AddRecoveryContactSheetState extends State<AddRecoveryContactSheet> {
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingContacts = true;
  int _gridSize = 4;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;
    setState(() => _isLoadingContacts = true);

    try {
      List<Contact> newContacts = [];
      Set<String> addedContactIds = {};

      final currentUserAddress = AppStateNotifier.currentMyContact?.publicosAddress?.eip55With0x.toLowerCase();

      Set<String> existingRecoveryContacts = widget.excludeAddresses ?? {};
      if (widget.excludeAddresses == null) {
        try {
          final recoveryData = await PublicOSRecovery.getMyRecoveryContacts();
          if (recoveryData != null) {
            existingRecoveryContacts = recoveryData.contacts.map((contact) => contact.eip55With0x.toLowerCase()).toSet();
          }
        } catch (e) {
          print('AddRecoveryContactSheet: Warning - could not get existing recovery contacts: $e');
        }
      }

      final storedContacts = await PublicOSContacts.getStoredContacts();

      for (var contact in storedContacts) {
        final registeredInboxIDs = contact.registeredInboxIDs;
        if (registeredInboxIDs != null && registeredInboxIDs.isNotEmpty && contact.publicosAddress != null) {
          final contactAddress = contact.publicosAddress!.eip55With0x.toLowerCase();
          if (currentUserAddress != null && contactAddress == currentUserAddress) {
            continue;
          }

          if (existingRecoveryContacts.contains(contactAddress)) {
            continue;
          }

          if (widget.individualsOnly && contact.isOrgAccount) {
            continue;
          }

          final contactId = contact.publicosAddress?.eip55With0x ?? contact.displayName;
          if (!addedContactIds.contains(contactId)) {
            newContacts.add(contact);
            addedContactIds.add(contactId);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allContacts = newContacts;
          _filteredContacts = newContacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allContacts = [];
          _filteredContacts = [];
          _isLoadingContacts = false;
        });
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((contact) => contact.displayName.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 1.0,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _SheetHeader(
                title: widget.title ?? context.l10n.acctSettingsSelectRecoveryContact,
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildExplanation(tokens),
                        const SizedBox(height: 16),
                        _buildSearchBar(tokens),
                        const SizedBox(height: 16),
                        _buildContactsGrid(tokens),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExplanation(GlassTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.glassFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: tokens.starkWhite,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                widget.heading ?? context.l10n.acctSettingsChooseRecoveryContact,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w800,
                  color: tokens.starkWhite,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.description ?? context.l10n.acctSettingsChooseRecoveryDesc,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              color: tokens.textDim,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(GlassTokens tokens) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: tokens.borderSubtle, width: 1),
    );
    return TextField(
      controller: _searchController,
      style: TextStyle(
        fontFamily: 'SpaceGrotesk',
        color: tokens.starkWhite,
      ),
      decoration: InputDecoration(
        hintText: context.l10n.acctSettingsSearchContacts,
        hintStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          color: tokens.textDim,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: tokens.textDim,
        ),
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
      ),
    );
  }

  Widget _buildContactsGrid(GlassTokens tokens) {
    if (_isLoadingContacts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: PhigitalLoadingWidget(size: 32, showShadows: false),
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchController.text.isEmpty
                  ? Icons.contacts_rounded
                  : Icons.search_off_rounded,
              size: 48,
              color: tokens.textDim,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? context.l10n.acctSettingsNoContactsAvailable
                  : context.l10n.acctSettingsNoContactsFound,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.acctSettingsAddContactsFirst,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  color: tokens.textDim,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    // DESKTOP DELTA: sized from the REAL available width, not
    // `MediaQuery.size.width`.
    //
    // On a phone the window and the sheet are the same width, so the client
    // can use MediaQuery as a stand-in for "how much room do I have". On
    // desktop MediaQuery.size is the whole WINDOW — roughly 1600px behind a
    // ~600px sheet — so each tile would compute to ~380px, only one would fit
    // per run, and the grid would silently collapse into a single column.
    // LayoutBuilder asks the parent what it actually got.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Exact fit for `_gridSize` tiles per run: N tiles plus the N-1 gaps
        // the Wrap puts between them. The client's `-8` fudge compensates
        // for the same thing approximately.
        final available = constraints.maxWidth;
        final tileWidth =
            (available - (_gridSize - 1) * 8) / _gridSize;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _filteredContacts
              .map((contact) => SizedBox(
                    width: tileWidth,
                    child: _buildContactGridTile(tokens, contact, tileWidth),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildContactGridTile(
      GlassTokens tokens, Contact contact, double tileWidth) {
    // Both derived from the TILE, not the window (same DESKTOP DELTA as
    // above) — a wide window would inflate every icon to the 64px clamp.
    final isSmallScreen = tileWidth < 100;
    final iconSize = (tileWidth * 0.6).clamp(32.0, 64.0);

    final textSize = isSmallScreen ? 12.0 : 14.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Center(
            child: GlassContactIcon(
              contact: contact,
              size: iconSize,
              onTap: () => widget.onContactSelected(contact),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onContactSelected(contact),
            child: Text(
              contact.displayName,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: textSize,
                color: tokens.starkWhite,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sheet primitives (Pattern A) ────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: tokens.borderMedium,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.starkWhite,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close_rounded, color: tokens.starkWhite),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ─── Add Session sheet (Pattern A with pinned action footer) ──────────────

class _AddSessionSheet extends StatefulWidget {
  final List<EthereumAddress> existingSessions;
  final ValueChanged<EthereumAddress> onSubmit;

  const _AddSessionSheet({
    required this.existingSessions,
    required this.onSubmit,
  });

  @override
  State<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<_AddSessionSheet> {
  final TextEditingController _addressController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool _validate() {
    final l10n = context.l10n;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      setState(() => _errorMessage = l10n.acctSettingsErrorEnterAddress);
      return false;
    }
    if (!address.startsWith('0x') || address.length != 42) {
      setState(() => _errorMessage = l10n.acctSettingsErrorInvalidAddress);
      return false;
    }
    final exists = widget.existingSessions.any(
      (c) => c.eip55With0x.toLowerCase() == address.toLowerCase(),
    );
    if (exists) {
      setState(() => _errorMessage = l10n.acctSettingsErrorAddressAlreadySession);
      return false;
    }
    return true;
  }

  void _submit() {
    if (!_validate()) return;
    final address = EthereumAddress.fromHex(_addressController.text.trim());
    Navigator.pop(context);
    widget.onSubmit(address);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.surfaceDeep,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: tokens.borderSubtle, width: 1),
          ),
          child: Column(
            children: [
              const _SheetHandle(),
              _SheetHeader(
                title: context.l10n.acctSettingsAddNewSession,
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 280),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tokens.glassFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tokens.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: tokens.starkWhite,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.acctSettingsWhatIsSessionTitle,
                                    style: TextStyle(
                                      fontFamily: 'SpaceGrotesk',
                                      fontWeight: FontWeight.w700,
                                      color: tokens.starkWhite,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.acctSettingsWhatIsSessionBody,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tokens.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _addressController,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: tokens.starkWhite,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            labelText: context.l10n.acctSettingsEthereumAddressLabel,
                            hintText: '0x...',
                            hintStyle: TextStyle(color: tokens.textDim),
                            filled: true,
                            fillColor: tokens.surfaceElevated,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            errorText: _errorMessage,
                            prefixIcon: Icon(
                              Icons.account_balance_wallet,
                              color: tokens.textDim,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: tokens.borderSubtle,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: tokens.borderSubtle,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: tokens.borderMedium,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (_errorMessage != null) {
                              setState(() => _errorMessage = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: tokens.borderSubtle, height: 1),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SystemAppActionButton(
                    label: context.l10n.acctSettingsAddSession,
                    icon: Icons.add_rounded,
                    onTap: _submit,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
