import 'package:publicos_desktop/l10n/app_localizations.dart';
import 'package:publicos_desktop/widgets/error/revert_reason_l10n.dart';

/// Client-side resolver: maps an error thrown by `PublicOS_Core` (or anywhere)
/// to a localized, user-facing message.
///
/// i18n is a client concern: `PublicOS_Core`
/// stays i18n-neutral, so we interpret its output here rather than localize
/// inside the SDK. Resolution order:
///   1. A chain-revert string → delegate to [localizedRevertReason].
///   2. A known Core prose message (matched after stripping `Exception: `) → a
///      catalog key.
///   3. [fallback] if the caller gave one, else a generic localized message.
///
/// Step 2 is the brittle part — it string-matches Core's English prose. It is
/// isolated here on purpose; if Core gains typed error codes, this can route
/// on the code instead. Until a phrase is mapped it
/// falls through to the generic fallback, so converting a call site (replacing
/// `Text('Error: $e')` with `localizedError(l10n, e)`) is always safe — the
/// worst case is the generic message, never a raw English blob in a Spanish UI.
String localizedError(
  AppLocalizations l10n,
  Object? error, {
  String? fallback,
}) {
  if (error == null) return fallback ?? l10n.errorGeneric;

  var msg = error.toString();
  const exPrefix = 'Exception: ';
  if (msg.startsWith(exPrefix)) msg = msg.substring(exPrefix.length);
  msg = msg.trim();

  // 0. The node refused the transaction at admission (consensus Rule 2): no
  // contract ran, so there is no revert reason to translate. Almost always a
  // lapsed domain (only payDomain still goes through). The exact reason is on
  // the node's `publicos_whyTxRejected`.
  if (msg.contains('PermissionDenied')) return l10n.errTxRefusedByNetwork;

  // 1. Chain reverts (RPCError / execution-reverted / contract-prefixed) — the
  // revert mapper already covers these phrases.
  if (msg.contains('execution reverted') ||
      msg.contains('with msg "') ||
      msg.startsWith('RPCError')) {
    return localizedRevertReason(l10n, msg, fallback: fallback);
  }

  // 2a. Variable-suffix Core messages (label/length embedded).
  if (msg.startsWith('Invalid key length:')) return l10n.errInvalidKeyLength;
  if (msg.startsWith('Private key not found for label:')) {
    return l10n.errKeyNotFound;
  }
  if (msg.startsWith('Key data not found for label:')) return l10n.errKeyNotFound;
  if (msg.startsWith('Failed to load comments:') ||
      msg.startsWith('Failed to load replies:')) {
    return l10n.errLoadContent;
  }
  // Auth guard-rails with varying suffixes ('Authentication required',
  // 'Authentication and X required', 'Authentication failed: ...').
  if (msg.startsWith('Authentication')) return l10n.errNotAuthenticated;

  // 2b. Exact-match Core prose.
  switch (msg) {
    // Keychain — labels / import.
    case 'A key with this label already exists':
      return l10n.errKeyLabelExists;
    case 'Invalid mnemonic phrase':
      return l10n.errInvalidMnemonic;
    case 'Invalid base64 format':
      return l10n.errInvalidBase64;
    case 'Database key cannot be empty':
      return l10n.errDbKeyEmpty;
    case 'Key metadata not found':
      return l10n.errKeyMetadataNotFound;
    case 'No current user address available':
      return l10n.errNoUserAddress;
    case 'No XMTP identity selected':
      return l10n.errNoXmtpIdentity;
    case 'Temporary blockchain key not found':
      return l10n.errKeyNotFound;
    // Channels — comments / reactions.
    case 'Post does not support comments':
      return l10n.errCommentsNotSupported;
    case 'Post does not support reactions':
      return l10n.errReactionsNotSupported;
    // Guard-rails (collapsed): auth / server.
    case 'Authentication required':
    case 'Not authenticated':
    case 'No account address available':
    case 'PublicOS Auth: Core not Authenticated':
      return l10n.errNotAuthenticated;
    case 'Core not initialized':
      return l10n.errNotInitialized;
    case 'Cannot delete the currently active account':
      return l10n.errCannotDeleteActiveAccount;
    case 'No server available':
      return l10n.errNoServer;
    default:
      // Unmapped / nested-wrapper / unknown → generic. Map more phrases here
      // as each Core domain is swept (channels, accounts, conversations, ssp).
      return fallback ?? l10n.errorGeneric;
  }
}
