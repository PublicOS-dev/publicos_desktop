import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:publicos_core/publicos_core.dart';
// DELTA(desktop): share sheet → native save dialog (utils/save_file.dart).
import 'package:publicos_desktop/utils/save_file.dart';

import 'package:publicos_desktop/widgets/messages/sheets/denied_conversations_sheet.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';
import 'package:publicos_desktop/widgets/error/error_l10n.dart';
import 'package:publicos_desktop/widgets/fullscreen_overlay.dart';

/// Glass messages tab settings — read-receipt toggles + a "show contact
/// banners" toggle + an entry point into the blocked-conversations sheet.
///
/// Persistence keys (`PublicOSSettings`, `Record.asSettings` shape, 365d):
/// - `read_receipt_send` (default false)
/// - `read_receipt_display` (default true)
/// - `messages_show_contact_banner` (default true)
/// Returns `true` if the user restored a backup (the caller should then do a
/// full conversation reload), otherwise `null`.
Future<bool?> showMessagesSettingsSheet(BuildContext context) {
  // DELTA(desktop): centered glass dialog instead of a bottom sheet.
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: DialogWidth.l,
          maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
        ),
        child: const _MessagesSettingsSheet(),
      ),
    ),
  );
}

class _MessagesSettingsSheet extends StatefulWidget {
  const _MessagesSettingsSheet();

  @override
  State<_MessagesSettingsSheet> createState() =>
      _MessagesSettingsSheetState();
}

class _MessagesSettingsSheetState extends State<_MessagesSettingsSheet> {
  bool _sendReceipts = false; // Default: do not send
  bool _showReceipts = true; // Default: do display
  bool _showContactBanners = true; // Default: do show
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        PublicOSSettings.getSetting('read_receipt_send'),
        PublicOSSettings.getSetting('read_receipt_display'),
        PublicOSSettings.getSetting('messages_show_contact_banner'),
      ]);
      if (!mounted) return;
      setState(() {
        _sendReceipts = results[0]?.value == 'true';
        _showReceipts = results[1]?.value != 'false';
        _showContactBanners = results[2]?.value != 'false';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _persist(String key, bool value) async {
    final record = Record.asSettings(
      key: key,
      value: value.toString(),
      isExpired: false,
      isSystem: true,
    );
    await PublicOSSettings.setSetting(key, record);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        // DELTA(desktop): full radius + no drag handle — centered dialog.
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHeader(
              title: context.l10n.messagesSettingsSheetTitle,
              tokens: tokens,
              onClose: () => Navigator.pop(context),
            ),
            _ToggleRow(
              label: context.l10n.messagesSettingsSheetSendReceiptsLabel,
              subtitle: context.l10n.messagesSettingsSheetSendReceiptsSubtitle,
              value: _sendReceipts,
              onChanged: _loading
                  ? null
                  : (v) {
                      setState(() => _sendReceipts = v);
                      _persist('read_receipt_send', v);
                    },
              tokens: tokens,
            ),
            _ToggleRow(
              label: context.l10n.messagesSettingsSheetShowReceiptsLabel,
              subtitle: context.l10n.messagesSettingsSheetShowReceiptsSubtitle,
              value: _showReceipts,
              onChanged: _loading
                  ? null
                  : (v) {
                      setState(() => _showReceipts = v);
                      _persist('read_receipt_display', v);
                    },
              tokens: tokens,
            ),
            _ToggleRow(
              label: context.l10n.messagesSettingsSheetShowBannersLabel,
              subtitle: context.l10n.messagesSettingsSheetShowBannersSubtitle,
              value: _showContactBanners,
              onChanged: _loading
                  ? null
                  : (v) {
                      setState(() => _showContactBanners = v);
                      _persist('messages_show_contact_banner', v);
                    },
              tokens: tokens,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Divider(color: tokens.borderSubtle, height: 1),
            ),
            _ActionTile(
              icon: Icons.block_rounded,
              label: context.l10n.messagesSettingsSheetBlockedConvosLabel,
              subtitle: context.l10n.messagesSettingsSheetBlockedConvosSubtitle,
              tokens: tokens,
              onTap: () {
                Navigator.pop(context);
                // DELTA(desktop): denied list in a centered glass dialog.
                showDialog(
                  context: context,
                  builder: (dialogCtx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: DialogWidth.m,
                        maxHeight:
                            MediaQuery.of(dialogCtx).size.height * 0.85,
                      ),
                      child: const DeniedConversationsSheet(),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Divider(color: tokens.borderSubtle, height: 1),
            ),
            // Raw database backup: download the .db3 file + copy its
            // encryption key. Restoring the pair on a fresh device keeps the
            // SAME installation (no device-slot burned), unlike the archive
            // flow. Restore itself lives in the key setup flow (activating a
            // key on a device with no local DB), not here — restoring over a
            // live database would be a destructive replace.
            _ActionTile(
              icon: Icons.download_rounded,
              label: context.l10n.messagesSettingsSheetDownloadDbLabel,
              subtitle: context.l10n.messagesSettingsSheetDownloadDbSubtitle,
              tokens: tokens,
              onTap: _downloadDatabaseFile,
            ),
            _ActionTile(
              icon: Icons.key_rounded,
              label: context.l10n.messagesSettingsSheetCopyDbKeyLabel,
              subtitle: context.l10n.messagesSettingsSheetCopyDbKeySubtitle,
              tokens: tokens,
              onTap: _copyEncryptionKey,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ENCRYPTED ARCHIVE BACKUP (libxmtp native, password-protected). Export writes
  // an encrypted .xmtpBak through the system share sheet; restore picks a file,
  // previews its header, then imports into the MLS store. The password derives
  // the key in the plugin — a wrong password simply fails to decrypt.
  // ============================================================================

  static const _backupTag = 'BackupUI';

  // ==========================================================================
  // RAW DATABASE BACKUP (file + encryption key). Downloading the .db3 and its
  // key lets the user restore the SAME installation on another device — the
  // network sees one installation, so no device slot is spent (unlike the
  // archive import, which registers a new installation). Restore happens in
  // the key setup flow (activating a key on a device without a local DB).
  // ==========================================================================

  String _dbBackupName() {
    // Name with the FULL inbox id so a fresh-device restore can recover it
    // from the filename (Android/iOS key the local DB path on the inbox id;
    // the restoring device doesn't know it yet). The plugin parses
    // `xmtp-<token>-<64hex>.db3`. Date is intentionally omitted — it would
    // break the parse; the share sheet lets the user rename to save.
    final inboxId = PublicOS.clientXmtpInboxId ?? 'unknown';
    return 'xmtp-db-$inboxId.db3';
  }

  Future<void> _downloadDatabaseFile() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final userAddress = PublicOS.myPublicosAddress;
    final label = PublicOS.currentXmtpKeyLabel;
    if (userAddress == null || label == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.messagesSettingsSheetNoActiveKey)));
      return;
    }

    // Warn: the file is useless without the encryption key, and vice versa.
    final proceed = await _showConfirm(
      l10n.messagesSettingsSheetDownloadDbLabel,
      l10n.messagesSettingsSheetDownloadDbWarning,
    );
    if (proceed != true || !mounted) return;

    final overlay = FullscreenOverlay.showBlocking(
        context, l10n.messagesSettingsSheetPreparingDb);
    try {
      final tmpDir = await getTemporaryDirectory();
      final path =
          '${tmpDir.path}${Platform.pathSeparator}${_dbBackupName()}';
      await PublicOSKeychain.downloadXmtpDatabase(userAddress, label, path);
      final file = File(path);
      final bytes = await file.exists() ? await file.length() : 0;
      Log.i(_backupTag, '[DB] exported $bytes bytes → ${file.path}');
      // DELTA(desktop): share sheet → native save dialog; cancel is silent.
      overlay.dismiss();
      final saved = await saveFileWithDialog(
        sourcePath: file.path,
        suggestedName: file.uri.pathSegments.last,
      );
      if (!mounted || saved == null) return;
      messenger.showSnackBar(SnackBar(
          content: Text(
              l10n.messagesSettingsSheetBackupReady(file.uri.pathSegments.last))));
    } catch (e, st) {
      overlay.dismiss();
      Log.e(_backupTag, '[DB] export failed: $e\n$st');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
          content: Text(localizedError(l10n, e,
              fallback: l10n.messagesSettingsSheetBackupFailed))));
    }
  }

  Future<void> _copyEncryptionKey() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final userAddress = PublicOS.myPublicosAddress;
    final label = PublicOS.currentXmtpKeyLabel;
    if (userAddress == null || label == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.messagesSettingsSheetNoActiveKey)));
      return;
    }

    final proceed = await _showConfirm(
      l10n.messagesSettingsSheetCopyDbKeyLabel,
      l10n.messagesSettingsSheetCopyDbKeyWarning,
    );
    if (proceed != true) return;

    final key =
        await PublicOSKeychain.exportXmtpDbKeyForLabel(userAddress, label);
    if (key == null) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.messagesSettingsSheetNoActiveKey)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: key));
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.messagesSettingsSheetKeyCopied)));
  }

  Future<bool?> _showConfirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.dlgCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.messagesSettingsSheetContinue),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ENCRYPTED ARCHIVE BACKUP (libxmtp .xmtpBak). Superseded in the UI by the
  // raw-DB backup above (the archive import registers a NEW installation,
  // burning a device slot; the raw-DB restore keeps the same installation).
  // Kept — not deleted — so the working export/import path can be re-surfaced.
  // --------------------------------------------------------------------------

  // ignore: unused_element
  String _defaultBackupName() {
    final inboxId = PublicOS.clientXmtpInboxId ?? 'unknown';
    final inbox8 = inboxId.length >= 8 ? inboxId.substring(0, 8) : inboxId;
    final ymd = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'xmtp-backup-$inbox8-$ymd.xmtpBak';
  }

  // ignore: unused_element
  Future<void> _downloadBackup() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final password = await _promptPassword(
      title: l10n.messagesSettingsSheetBackupPasswordTitle,
      message: l10n.messagesSettingsSheetBackupPasswordMessage,
      actionLabel: l10n.messagesSettingsSheetCreateBackup,
      requireConfirm: true,
    );
    if (password == null || !mounted) return;

    final overlay = FullscreenOverlay.showBlocking(
      context,
      l10n.messagesSettingsSheetEncryptingBackup,
    );
    try {
      final tmpDir = await getTemporaryDirectory();
      final path =
          '${tmpDir.path}${Platform.pathSeparator}${_defaultBackupName()}';
      await PublicOSXmtp.exportArchive(path, password);
      final file = File(path);
      final bytes = await file.exists() ? await file.length() : 0;
      Log.i(_backupTag, '[BACKUP] export wrote $bytes bytes → ${file.path}');
      // DELTA(desktop): share sheet → native save dialog; cancel is silent.
      overlay.dismiss();
      final saved = await saveFileWithDialog(
        sourcePath: file.path,
        suggestedName: file.uri.pathSegments.last,
      );
      if (saved == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.messagesSettingsSheetBackupReady(
              file.uri.pathSegments.last)),
        ),
      );
    } catch (e, st) {
      overlay.dismiss();
      Log.e(_backupTag, '[BACKUP] export failed: $e\n$st');
      messenger.showSnackBar(SnackBar(
        content: Text(localizedError(l10n, e,
            fallback: l10n.messagesSettingsSheetBackupFailed)),
      ));
    }
  }

  // ignore: unused_element
  Future<void> _restoreBackup() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    // 1. Pick the file.
    final XFile? picked;
    try {
      picked = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(
            label: l10n.messagesSettingsSheetBackupFileTypeLabel,
            extensions: const ['xmtpBak'],
          ),
        ],
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(localizedError(l10n, e,
            fallback: l10n.messagesSettingsSheetCouldNotOpenFile)),
      ));
      return;
    }
    if (picked == null || !mounted) return;
    final path = picked.path;

    // 2. Password.
    final password = await _promptPassword(
      title: l10n.messagesSettingsSheetRestoreBackup,
      message: l10n.messagesSettingsSheetRestorePasswordMessage,
      actionLabel: l10n.messagesSettingsSheetContinue,
      requireConfirm: false,
    );
    if (password == null || !mounted) return;

    // 3. Read the header (also verifies the password / inbox).
    final overlay = FullscreenOverlay.showBlocking(
        context, l10n.messagesSettingsSheetReadingBackup);
    final ArchiveMetadata meta;
    try {
      meta = await PublicOSXmtp.archiveMetadata(path, password);
      overlay.dismiss();
    } catch (e, st) {
      overlay.dismiss();
      Log.e(_backupTag, '[RESTORE] archiveMetadata failed: $e\n$st');
      if (!mounted) return;
      await _showErrorDialog(
        l10n.messagesSettingsSheetCouldNotOpenBackupTitle,
        l10n.messagesSettingsSheetCouldNotOpenBackupMessage,
      );
      return;
    }
    if (!mounted) return;

    // 4. Preview + confirm.
    final proceed = await _showMetadataConfirm(meta);
    if (proceed != true || !mounted) return;

    // 5. Import, then signal the caller to do a full reload.
    final overlay2 = FullscreenOverlay.showBlocking(
      context,
      l10n.messagesSettingsSheetRestoringBackup,
    );
    try {
      await PublicOSXmtp.importArchive(path, password);
      overlay2.dismiss();
      if (!mounted) return;
      Navigator.pop(context, true); // messages view reloads conversations
    } catch (e, st) {
      overlay2.dismiss();
      Log.e(_backupTag, '[RESTORE] importArchive failed: $e\n$st');
      if (!mounted) return;
      await _showErrorDialog(
          l10n.messagesSettingsSheetRestoreFailed, localizedError(l10n, e));
    }
  }

  /// Prompt for a password. When [requireConfirm], a second field must match.
  Future<String?> _promptPassword({
    required String title,
    required String message,
    required String actionLabel,
    required bool requireConfirm,
  }) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.m),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 12.5, height: 1.4)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: l10n.messagesSettingsSheetPasswordLabel),
              ),
              if (requireConfirm) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText:
                          l10n.messagesSettingsSheetConfirmPasswordLabel),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style:
                        const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.dlgCancel),
            ),
            ElevatedButton(
              onPressed: () {
                final pw = controller.text;
                if (pw.isEmpty) {
                  setLocal(
                      () => error = l10n.messagesSettingsSheetEnterPassword);
                  return;
                }
                if (requireConfirm && pw != confirmController.text) {
                  setLocal(
                      () => error = l10n.messagesSettingsSheetPasswordsNoMatch);
                  return;
                }
                Navigator.pop(dialogContext, pw);
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showMetadataConfirm(ArchiveMetadata meta) {
    final l10n = context.l10n;
    final tokens = GlassTokens.of(context);
    final exported = DateFormat('yyyy-MM-dd HH:mm').format(
        DateTime.fromMicrosecondsSinceEpoch(meta.exportedAtNs ~/ 1000)
            .toLocal());
    final scope = meta.elements.isEmpty
        ? 'Messages + Consent'
        : meta.elements.map((e) => e.name).join(' + ');
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(l10n.messagesSettingsSheetRestoreThisBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _metaRow(l10n.messagesSettingsSheetMetaCreated, exported, tokens),
            _metaRow(l10n.messagesSettingsSheetMetaContents, scope, tokens),
            const SizedBox(height: 12),
            Text(
              l10n.messagesSettingsSheetRestoreMergeNote,
              style: TextStyle(color: tokens.textDim, fontSize: 12, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.dlgCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.messagesSettingsSheetRestore),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value, GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: tokens.textDim)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String title, String message) {
    final l10n = context.l10n;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        constraints: const BoxConstraints(minWidth: DialogWidth.min, maxWidth: DialogWidth.s),
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.messagesSettingsSheetOk),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final GlassTokens tokens;
  final VoidCallback onClose;
  const _SheetHeader({
    required this.title,
    required this.tokens,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
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

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final GlassTokens tokens;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.starkWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: tokens.connectedAccent,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final GlassTokens tokens;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.tokens,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Icon(icon, color: tokens.starkWhite, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.starkWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: tokens.textDim,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
