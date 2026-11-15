import 'package:publicos_desktop/l10n/app_localizations.dart';

/// Client-side, localized port of `PublicOS_Core`'s `TxUtils.humanizeRevertReason`.
///
/// i18n is a client concern: `PublicOS_Core`
/// stays i18n-neutral, so instead of displaying Core's English copy we re-map
/// the raw Solidity revert phrase → localized copy here. The raw phrases (the
/// switch cases) are the stable on-chain contract; the copy is ours.
///
/// Normalization mirrors `TxUtils.humanizeRevertReason` (the RPCError
/// `with msg "..."` shape, the `execution reverted:` marker, surrounding-quote
/// strip). Keep the case set in sync with Core's `map` until Core has typed
/// error codes — at which point this routes on the code instead of the
/// phrase.
String localizedRevertReason(
  AppLocalizations l10n,
  String? raw, {
  String? fallback,
}) {
  final fb = fallback ?? l10n.revertGeneric;
  if (raw == null || raw.trim().isEmpty) return fb;
  var msg = raw.trim();

  // Pull the reason out of a raw `RPCError.toString()` (`got code -32000 with
  // msg "..."`) when the decoder returned null.
  final withMsg = RegExp(r'with msg "([^"]+)"').firstMatch(msg);
  if (withMsg != null) msg = withMsg.group(1)!.trim();

  // Some nodes embed `execution reverted: <reason>`.
  const marker = 'execution reverted:';
  final idx = msg.indexOf(marker);
  if (idx >= 0) {
    msg = msg.substring(idx + marker.length).trim();
  } else if (msg.toLowerCase() == 'execution reverted') {
    return fb;
  }
  msg = msg.replaceAll(RegExp(r'^"|"$'), '');

  switch (msg) {
    // AccountManager — create/name.
    case 'AccountManager: Account creation paused':
      return l10n.revertCreationPaused;
    case 'AccountManager: Display name cannot be empty':
      return l10n.revertNameEmpty;
    case 'AccountManager: Minter must be citizen':
      return l10n.revertMinterNotCitizen;
    case 'AccountManager: Display name fails charset/tier':
      return l10n.revertNameCharsetTier;
    case 'AccountManager: Display name already taken':
      return l10n.revertNameTaken;
    case 'AccountManager: Display name in cooldown or reserved':
      return l10n.revertNameReservedCooldown;
    case 'AccountManager: Name cooldown active':
      return l10n.revertNameCooldown;
    case 'AccountManager: Rename quota exhausted':
      return l10n.revertRenameQuota;
    case 'AccountManager: NotRegisteredSender':
      return l10n.revertNotRegisteredSender;
    // AccountManager — createOrg.
    case 'AccountManager: Org creation rate-limited':
      return l10n.revertOrgRateLimited;
    case 'AccountManager: Org must have initial members':
      return l10n.revertOrgNeedsMembers;
    case 'AccountManager: Initial threshold must be positive':
      return l10n.revertThresholdPositive;
    case 'AccountManager: Initial threshold cannot exceed member count':
      return l10n.revertThresholdExceedsMembers;
    case 'AccountManager: Initial member is not a valid individual account':
      return l10n.revertMemberNotIndividual;
    case 'AccountManager: Public org creator must be a citizen':
      return l10n.revertPublicOrgCreatorCitizen;
    case 'AccountManager: Public org members must be citizens':
      return l10n.revertPublicOrgMembersCitizens;
    // OrgManager — startVote preflight.
    case 'OrgManager: Caller is not a registered session':
      return l10n.revertNotRegisteredSession;
    case 'OrgManager: Caller\'s account is not a member of this org':
      return l10n.revertNotOrgMember;
    case 'OrgManager: Target address is not an org account':
      return l10n.revertNotOrgAccount;
    case 'OrgManager: Vote already active for this org':
      return l10n.revertVoteAlreadyActive;
    // OrgManager — ADD_MEMBER preflight.
    case 'OrgManager: Invalid member address':
      return l10n.revertInvalidMemberAddress;
    case 'OrgManager: Address is already a member':
      return l10n.revertAlreadyMember;
    case 'OrgManager: memberToAdd must be a valid individual account':
      return l10n.revertMemberMustBeIndividual;
    case 'OrgManager: CitizenshipManager not registered':
      return l10n.revertOracleUnavailable;
    case 'OrgManager: Public org can only add citizen members':
      return l10n.revertPublicOrgAddCitizen;
    // OrgManager — REMOVE_MEMBER preflight.
    case 'OrgManager: Address is not a member':
      return l10n.revertNotMember;
    case 'OrgManager: Cannot remove the last member':
      return l10n.revertCannotRemoveLastMember;
    case 'OrgManager: Removal would violate threshold rule':
      return l10n.revertRemovalViolatesThreshold;
    // OrgStorage — downstream safety net (same copy as the OrgManager twins).
    case 'OrgStorage: Org not initialized':
      return l10n.revertOrgNotInitialized;
    case 'OrgStorage: Address is already a member':
      return l10n.revertAlreadyMember;
    case 'OrgStorage: Address is not a member':
      return l10n.revertNotMember;
    case 'OrgStorage: Invalid member address':
      return l10n.revertInvalidMemberAddress;
    default:
      // Unknown reason: strip the `ContractName: ` prefix and surface the raw
      // reason — same last-resort as Core, better than an RPC blob.
      return msg.replaceFirst(RegExp(r'^[A-Z][A-Za-z0-9_]+:\s*'), '');
  }
}
