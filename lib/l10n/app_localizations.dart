import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the app. Content stays in its original language.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystemDefault;

  /// No description provided for @revertGeneric.
  ///
  /// In en, this message translates to:
  /// **'The chain rejected the transaction.'**
  String get revertGeneric;

  /// No description provided for @revertAuthorizeFailed.
  ///
  /// In en, this message translates to:
  /// **'Authorize failed.'**
  String get revertAuthorizeFailed;

  /// No description provided for @revertRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start recovery.'**
  String get revertRecoveryFailed;

  /// No description provided for @revertAccountCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Account creation failed.'**
  String get revertAccountCreationFailed;

  /// No description provided for @revertCreateOrgFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the organization.'**
  String get revertCreateOrgFailed;

  /// No description provided for @revertCreationPaused.
  ///
  /// In en, this message translates to:
  /// **'Account creation is paused right now.'**
  String get revertCreationPaused;

  /// No description provided for @revertNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Username can\'t be empty.'**
  String get revertNameEmpty;

  /// No description provided for @revertMinterNotCitizen.
  ///
  /// In en, this message translates to:
  /// **'Only citizens can create new accounts. Get vouched in first.'**
  String get revertMinterNotCitizen;

  /// No description provided for @revertNameCharsetTier.
  ///
  /// In en, this message translates to:
  /// **'That username doesn\'t fit the rules (length, charset, or leading character).'**
  String get revertNameCharsetTier;

  /// No description provided for @revertNameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken.'**
  String get revertNameTaken;

  /// No description provided for @revertNameReservedCooldown.
  ///
  /// In en, this message translates to:
  /// **'That username is reserved or in cooldown — try another.'**
  String get revertNameReservedCooldown;

  /// No description provided for @revertNameCooldown.
  ///
  /// In en, this message translates to:
  /// **'That username is in cooldown — try another.'**
  String get revertNameCooldown;

  /// No description provided for @revertRenameQuota.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your free name change for this year and have no bonus left.'**
  String get revertRenameQuota;

  /// No description provided for @revertNotRegisteredSender.
  ///
  /// In en, this message translates to:
  /// **'This wallet isn\'t registered as a session of any account.'**
  String get revertNotRegisteredSender;

  /// No description provided for @revertOrgRateLimited.
  ///
  /// In en, this message translates to:
  /// **'You created an org recently — there\'s a cooldown before you can create another.'**
  String get revertOrgRateLimited;

  /// No description provided for @revertOrgNeedsMembers.
  ///
  /// In en, this message translates to:
  /// **'An org needs at least one member.'**
  String get revertOrgNeedsMembers;

  /// No description provided for @revertThresholdPositive.
  ///
  /// In en, this message translates to:
  /// **'The voting threshold must be at least 1.'**
  String get revertThresholdPositive;

  /// No description provided for @revertThresholdExceedsMembers.
  ///
  /// In en, this message translates to:
  /// **'The voting threshold can\'t be higher than the number of members.'**
  String get revertThresholdExceedsMembers;

  /// No description provided for @revertMemberNotIndividual.
  ///
  /// In en, this message translates to:
  /// **'One of the members isn\'t a valid individual account.'**
  String get revertMemberNotIndividual;

  /// No description provided for @revertPublicOrgCreatorCitizen.
  ///
  /// In en, this message translates to:
  /// **'Only citizens can create a public org.'**
  String get revertPublicOrgCreatorCitizen;

  /// No description provided for @revertPublicOrgMembersCitizens.
  ///
  /// In en, this message translates to:
  /// **'Every member of a public org must be a citizen.'**
  String get revertPublicOrgMembersCitizens;

  /// No description provided for @revertNotRegisteredSession.
  ///
  /// In en, this message translates to:
  /// **'Your wallet isn\'t a registered session of any account.'**
  String get revertNotRegisteredSession;

  /// No description provided for @revertNotOrgMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a member of this org — only members can start a vote.'**
  String get revertNotOrgMember;

  /// No description provided for @revertNotOrgAccount.
  ///
  /// In en, this message translates to:
  /// **'That address isn\'t an org account.'**
  String get revertNotOrgAccount;

  /// No description provided for @revertVoteAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'There\'s already an active vote on this org — wait for it to resolve before starting another.'**
  String get revertVoteAlreadyActive;

  /// No description provided for @revertInvalidMemberAddress.
  ///
  /// In en, this message translates to:
  /// **'The selected member address is invalid.'**
  String get revertInvalidMemberAddress;

  /// No description provided for @revertAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'That account is already a member.'**
  String get revertAlreadyMember;

  /// No description provided for @revertMemberMustBeIndividual.
  ///
  /// In en, this message translates to:
  /// **'You can only add an individual account as a member, not an org account.'**
  String get revertMemberMustBeIndividual;

  /// No description provided for @revertOracleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Citizenship check unavailable right now — try again later.'**
  String get revertOracleUnavailable;

  /// No description provided for @revertPublicOrgAddCitizen.
  ///
  /// In en, this message translates to:
  /// **'This is a public org — every new member must be a citizen.'**
  String get revertPublicOrgAddCitizen;

  /// No description provided for @revertNotMember.
  ///
  /// In en, this message translates to:
  /// **'That account isn\'t a member.'**
  String get revertNotMember;

  /// No description provided for @revertCannotRemoveLastMember.
  ///
  /// In en, this message translates to:
  /// **'You can\'t remove the last member of an org.'**
  String get revertCannotRemoveLastMember;

  /// No description provided for @revertRemovalViolatesThreshold.
  ///
  /// In en, this message translates to:
  /// **'Removing them would leave fewer members than the voting threshold — lower the threshold first.'**
  String get revertRemovalViolatesThreshold;

  /// No description provided for @revertOrgNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'This org isn\'t initialized.'**
  String get revertOrgNotInitialized;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @sendRecipientLookupFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t look up where to send this. Nothing was sent.'**
  String get sendRecipientLookupFailed;

  /// No description provided for @sendRecipientRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get sendRecipientRetry;

  /// No description provided for @errTxRefusedByNetwork.
  ///
  /// In en, this message translates to:
  /// **'The network refused this transaction. Usually that means your domain is overdue: renew it in Account › Domain, then try again.'**
  String get errTxRefusedByNetwork;

  /// No description provided for @errKeyLabelExists.
  ///
  /// In en, this message translates to:
  /// **'A key with this label already exists.'**
  String get errKeyLabelExists;

  /// No description provided for @errInvalidMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Invalid recovery phrase.'**
  String get errInvalidMnemonic;

  /// No description provided for @errInvalidBase64.
  ///
  /// In en, this message translates to:
  /// **'Invalid base64 format.'**
  String get errInvalidBase64;

  /// No description provided for @errDbKeyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Database key can\'t be empty.'**
  String get errDbKeyEmpty;

  /// No description provided for @errKeyMetadataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Key metadata not found.'**
  String get errKeyMetadataNotFound;

  /// No description provided for @errKeyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Key not found.'**
  String get errKeyNotFound;

  /// No description provided for @errInvalidKeyLength.
  ///
  /// In en, this message translates to:
  /// **'Invalid key length (expected 32 bytes).'**
  String get errInvalidKeyLength;

  /// No description provided for @errNoUserAddress.
  ///
  /// In en, this message translates to:
  /// **'No current user address available.'**
  String get errNoUserAddress;

  /// No description provided for @errNoXmtpIdentity.
  ///
  /// In en, this message translates to:
  /// **'No messaging identity selected.'**
  String get errNoXmtpIdentity;

  /// No description provided for @errNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in for that.'**
  String get errNotAuthenticated;

  /// No description provided for @errNoServer.
  ///
  /// In en, this message translates to:
  /// **'No server available right now. Try again later.'**
  String get errNoServer;

  /// No description provided for @errCommentsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This post doesn\'t allow comments.'**
  String get errCommentsNotSupported;

  /// No description provided for @errReactionsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This post doesn\'t allow reactions.'**
  String get errReactionsNotSupported;

  /// No description provided for @errLoadContent.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this. Try again.'**
  String get errLoadContent;

  /// No description provided for @signInToReact.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to react.'**
  String get signInToReact;

  /// No description provided for @sspNotSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to {slug} to write here.'**
  String sspNotSubscribed(String slug);

  /// No description provided for @sspWrong.
  ///
  /// In en, this message translates to:
  /// **'You\'re on {slug}. Switch to write here.'**
  String sspWrong(String slug);

  /// No description provided for @sspExpired.
  ///
  /// In en, this message translates to:
  /// **'Your subscription to {slug} expired.'**
  String sspExpired(String slug);

  /// No description provided for @sspGateFailed.
  ///
  /// In en, this message translates to:
  /// **'Can\'t verify your subscription right now. Try again.'**
  String get sspGateFailed;

  /// No description provided for @sspThisServer.
  ///
  /// In en, this message translates to:
  /// **'this server'**
  String get sspThisServer;

  /// No description provided for @sspAnotherServer.
  ///
  /// In en, this message translates to:
  /// **'another server'**
  String get sspAnotherServer;

  /// No description provided for @sspActionSubscribe.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE'**
  String get sspActionSubscribe;

  /// No description provided for @sspActionSwitch.
  ///
  /// In en, this message translates to:
  /// **'SWITCH'**
  String get sspActionSwitch;

  /// No description provided for @sspActionRenew.
  ///
  /// In en, this message translates to:
  /// **'RENEW'**
  String get sspActionRenew;

  /// No description provided for @errNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'The app isn\'t ready yet. Try again in a moment.'**
  String get errNotInitialized;

  /// No description provided for @errCannotDeleteActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'You can\'t delete the account you\'re currently using.'**
  String get errCannotDeleteActiveAccount;

  /// No description provided for @errUpdateColorFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the color.'**
  String get errUpdateColorFailed;

  /// No description provided for @errRemoveSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the session.'**
  String get errRemoveSessionFailed;

  /// No description provided for @errAddRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add the recovery contact.'**
  String get errAddRecoveryFailed;

  /// No description provided for @errRemoveRecoveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove the recovery contact.'**
  String get errRemoveRecoveryFailed;

  /// No description provided for @errSelectAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t select that account.'**
  String get errSelectAccountFailed;

  /// No description provided for @errCreateKeysFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the keys.'**
  String get errCreateKeysFailed;

  /// No description provided for @errImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import that. Check the value and try again.'**
  String get errImportFailed;

  /// No description provided for @errCheckActivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check activation.'**
  String get errCheckActivationFailed;

  /// No description provided for @errDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the account.'**
  String get errDeleteAccountFailed;

  /// No description provided for @errDeleteKeyPairFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the key pair.'**
  String get errDeleteKeyPairFailed;

  /// No description provided for @errResetAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reset the app.'**
  String get errResetAppFailed;

  /// No description provided for @errAddWalletFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t link the wallet.'**
  String get errAddWalletFailed;

  /// No description provided for @errCastVoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t cast your vote.'**
  String get errCastVoteFailed;

  /// No description provided for @errTranslateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t translate this.'**
  String get errTranslateFailed;

  /// No description provided for @notifComment.
  ///
  /// In en, this message translates to:
  /// **'{name} commented on your post'**
  String notifComment(String name);

  /// No description provided for @notifReply.
  ///
  /// In en, this message translates to:
  /// **'{name} replied to your comment'**
  String notifReply(String name);

  /// No description provided for @notifMention.
  ///
  /// In en, this message translates to:
  /// **'{name} mentioned you'**
  String notifMention(String name);

  /// No description provided for @notifReactionPost.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted to your post'**
  String notifReactionPost(String name);

  /// No description provided for @notifReactionComment.
  ///
  /// In en, this message translates to:
  /// **'{name} reacted to your comment'**
  String notifReactionComment(String name);

  /// No description provided for @notifFollowRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} asked to follow your channel'**
  String notifFollowRequest(String name);

  /// No description provided for @notifFollowApproved.
  ///
  /// In en, this message translates to:
  /// **'{name} let you into their channel'**
  String notifFollowApproved(String name);

  /// No description provided for @notificationsScreenPostUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this post'**
  String get notificationsScreenPostUnavailable;

  /// No description provided for @notificationsScreenChannelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this channel'**
  String get notificationsScreenChannelUnavailable;

  /// No description provided for @notificationsScreenCommented.
  ///
  /// In en, this message translates to:
  /// **' commented on your post'**
  String get notificationsScreenCommented;

  /// No description provided for @notificationsScreenReplied.
  ///
  /// In en, this message translates to:
  /// **' replied to your comment'**
  String get notificationsScreenReplied;

  /// No description provided for @notificationsScreenMentioned.
  ///
  /// In en, this message translates to:
  /// **' mentioned you'**
  String get notificationsScreenMentioned;

  /// No description provided for @notificationsScreenReactedPost.
  ///
  /// In en, this message translates to:
  /// **' reacted to your post'**
  String get notificationsScreenReactedPost;

  /// No description provided for @notificationsScreenReactedComment.
  ///
  /// In en, this message translates to:
  /// **' reacted to your comment'**
  String get notificationsScreenReactedComment;

  /// No description provided for @notificationsScreenFollowRequested.
  ///
  /// In en, this message translates to:
  /// **' asked to follow your channel'**
  String get notificationsScreenFollowRequested;

  /// No description provided for @notificationsScreenFollowApproved.
  ///
  /// In en, this message translates to:
  /// **' let you into their channel'**
  String get notificationsScreenFollowApproved;

  /// No description provided for @notifAvatarYou.
  ///
  /// In en, this message translates to:
  /// **'You updated your avatar'**
  String get notifAvatarYou;

  /// No description provided for @notifAvatarThey.
  ///
  /// In en, this message translates to:
  /// **'{name} updated their avatar'**
  String notifAvatarThey(String name);

  /// No description provided for @notifBannerYou.
  ///
  /// In en, this message translates to:
  /// **'You updated your banner'**
  String get notifBannerYou;

  /// No description provided for @notifBannerThey.
  ///
  /// In en, this message translates to:
  /// **'{name} updated their banner'**
  String notifBannerThey(String name);

  /// No description provided for @notifBioYou.
  ///
  /// In en, this message translates to:
  /// **'You updated your bio'**
  String get notifBioYou;

  /// No description provided for @notifBioThey.
  ///
  /// In en, this message translates to:
  /// **'{name} updated their bio'**
  String notifBioThey(String name);

  /// No description provided for @notifProfileYou.
  ///
  /// In en, this message translates to:
  /// **'You updated your profile'**
  String get notifProfileYou;

  /// No description provided for @notifProfileThey.
  ///
  /// In en, this message translates to:
  /// **'{name} updated their profile'**
  String notifProfileThey(String name);

  /// No description provided for @notifTabsYou.
  ///
  /// In en, this message translates to:
  /// **'You updated your tabs'**
  String get notifTabsYou;

  /// No description provided for @notifTabsThey.
  ///
  /// In en, this message translates to:
  /// **'{name} updated their tabs'**
  String notifTabsThey(String name);

  /// No description provided for @notifVouchedYou.
  ///
  /// In en, this message translates to:
  /// **'{name} vouched for you 🎉'**
  String notifVouchedYou(String name);

  /// No description provided for @notifVouchedByYou.
  ///
  /// In en, this message translates to:
  /// **'You vouched for {name}'**
  String notifVouchedByYou(String name);

  /// No description provided for @notifVouchedOther.
  ///
  /// In en, this message translates to:
  /// **'{actor} vouched for {target}'**
  String notifVouchedOther(String actor, String target);

  /// No description provided for @notifCitizenYou.
  ///
  /// In en, this message translates to:
  /// **'You\'re now a citizen 🎉'**
  String get notifCitizenYou;

  /// No description provided for @notifCitizenThey.
  ///
  /// In en, this message translates to:
  /// **'{name} is now a citizen 🎉'**
  String notifCitizenThey(String name);

  /// No description provided for @notifRentYou.
  ///
  /// In en, this message translates to:
  /// **'You paid your domain — {months, plural, =1{1 month} other{{months} months}}'**
  String notifRentYou(int months);

  /// No description provided for @notifRentThey.
  ///
  /// In en, this message translates to:
  /// **'{name} paid their domain — {months, plural, =1{1 month} other{{months} months}}'**
  String notifRentThey(String name, int months);

  /// No description provided for @notifEvictedYou.
  ///
  /// In en, this message translates to:
  /// **'Your account was evicted for non-payment'**
  String get notifEvictedYou;

  /// No description provided for @notifEvictedThey.
  ///
  /// In en, this message translates to:
  /// **'{name} was evicted for non-payment'**
  String notifEvictedThey(String name);

  /// No description provided for @notifNameChangedYou.
  ///
  /// In en, this message translates to:
  /// **'You changed your name'**
  String get notifNameChangedYou;

  /// No description provided for @notifNameNowYou.
  ///
  /// In en, this message translates to:
  /// **'You\'re now @{name}'**
  String notifNameNowYou(String name);

  /// No description provided for @notifNameChangedThey.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed their name'**
  String notifNameChangedThey(String actor);

  /// No description provided for @notifNameNowThey.
  ///
  /// In en, this message translates to:
  /// **'{actor} is now @{name}'**
  String notifNameNowThey(String actor, String name);

  /// No description provided for @notifDisplayChangedYou.
  ///
  /// In en, this message translates to:
  /// **'You changed your display name'**
  String get notifDisplayChangedYou;

  /// No description provided for @notifDisplayToYou.
  ///
  /// In en, this message translates to:
  /// **'You changed your display name to {name}'**
  String notifDisplayToYou(String name);

  /// No description provided for @notifDisplayChangedThey.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed their display name'**
  String notifDisplayChangedThey(String actor);

  /// No description provided for @notifDisplayToThey.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed their display name to {name}'**
  String notifDisplayToThey(String actor, String name);

  /// Money arrived in one of the user's own wallets, sender unknown/unnamed. amount is pre-formatted with its symbol (e.g. '5 OX').
  ///
  /// In en, this message translates to:
  /// **'Received {amount} in {wallet}'**
  String notifTransferIn(String amount, String wallet);

  /// Money arrived from a known contact.
  ///
  /// In en, this message translates to:
  /// **'{actor} sent {amount} to {wallet}'**
  String notifTransferInFrom(String actor, String amount, String wallet);

  /// No description provided for @notifTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Sent {amount} from {wallet}'**
  String notifTransferOut(String amount, String wallet);

  /// No description provided for @notifTransferOutTo.
  ///
  /// In en, this message translates to:
  /// **'Sent {amount} from {wallet} to {target}'**
  String notifTransferOutTo(String amount, String wallet, String target);

  /// A transfer between two of the user's OWN wallets — one event, not a send + receive pair.
  ///
  /// In en, this message translates to:
  /// **'Moved {amount} from {wallet} to {target}'**
  String notifTransferSelf(String amount, String wallet, String target);

  /// No description provided for @notifWalletGroup.
  ///
  /// In en, this message translates to:
  /// **'Wallet activity'**
  String get notifWalletGroup;

  /// No description provided for @notifKindTransferIn.
  ///
  /// In en, this message translates to:
  /// **'Money received'**
  String get notifKindTransferIn;

  /// No description provided for @notifKindTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Money sent'**
  String get notifKindTransferOut;

  /// No description provided for @notifKindTransferSelf.
  ///
  /// In en, this message translates to:
  /// **'Between your wallets'**
  String get notifKindTransferSelf;

  /// No description provided for @bootInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing core systems...'**
  String get bootInitializing;

  /// No description provided for @bootCheckingAuth.
  ///
  /// In en, this message translates to:
  /// **'Checking authentication...'**
  String get bootCheckingAuth;

  /// No description provided for @bootCheckingLogin.
  ///
  /// In en, this message translates to:
  /// **'Checking login...'**
  String get bootCheckingLogin;

  /// No description provided for @bootRestoringSession.
  ///
  /// In en, this message translates to:
  /// **'Restoring session...'**
  String get bootRestoringSession;

  /// No description provided for @bootConnectingChain.
  ///
  /// In en, this message translates to:
  /// **'Connecting to chain...'**
  String get bootConnectingChain;

  /// No description provided for @bootLoadingKeys.
  ///
  /// In en, this message translates to:
  /// **'Loading keys...'**
  String get bootLoadingKeys;

  /// No description provided for @bootConnectingFeed.
  ///
  /// In en, this message translates to:
  /// **'Connecting to feed server...'**
  String get bootConnectingFeed;

  /// No description provided for @bootLoadingMessages.
  ///
  /// In en, this message translates to:
  /// **'Loading messages...'**
  String get bootLoadingMessages;

  /// No description provided for @bootSettingUpNotifs.
  ///
  /// In en, this message translates to:
  /// **'Setting up notifications...'**
  String get bootSettingUpNotifs;

  /// No description provided for @bootOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening...'**
  String get bootOpening;

  /// No description provided for @bootLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get bootLoading;

  /// No description provided for @bootRetry.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get bootRetry;

  /// No description provided for @bootErrCoreInit.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize core systems'**
  String get bootErrCoreInit;

  /// No description provided for @bootErrAuthNeeded.
  ///
  /// In en, this message translates to:
  /// **'Authentication needed to continue'**
  String get bootErrAuthNeeded;

  /// No description provided for @bootErrUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred during initialization. Please try again.'**
  String get bootErrUnexpected;

  // The app lock (no Windows Hello, or an app PIN): screens/app_lock_screen.
  String get lockNoLockTitle;
  String get lockNoLockBody;
  String get lockOpenSettings;
  String get lockIHaveSetLock;
  String get lockSetPinInstead;
  String get lockSetPinTitle;
  String get lockSetPinBody;
  String get lockConfirmPinTitle;
  String get lockPinMismatch;
  String get lockEnterPinTitle;
  String lockWrongPin(int count);
  String get lockForgotPin;
  String get lockLockedTitle;
  String get lockLockedBody;
  String get lockResetButton;
  String get lockResetTitle;
  String get lockResetBody;
  String get lockResetConfirm;

  /// No description provided for @onbPublicosTitle.
  ///
  /// In en, this message translates to:
  /// **'PublicOS'**
  String get onbPublicosTitle;

  /// No description provided for @onbPublicosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Own your self'**
  String get onbPublicosSubtitle;

  /// No description provided for @onbPublicosBody.
  ///
  /// In en, this message translates to:
  /// **'PublicOS is a social platform with its own infrastructure, governance, and economy: a public institution on the internet, owned by the people who use it.\n\nYou get a full domain of your own, a place to post, organize, and monetize any way you want.\n\nEverything runs in the open and is decided by liquid democracy: every rule, every vote, every token, verifiable by anyone.\n\n'**
  String get onbPublicosBody;

  /// No description provided for @onbInfraTitle.
  ///
  /// In en, this message translates to:
  /// **'How does it work?'**
  String get onbInfraTitle;

  /// No description provided for @onbInfraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two networks, one place'**
  String get onbInfraSubtitle;

  /// No description provided for @onbInfraBody.
  ///
  /// In en, this message translates to:
  /// **'PublicOS economy takes common internet mechanics and runs them as public services democratically managed on a blockchain, no enterprise owns your stuff:\n\n- Account data and business logic are run and stored transparently on a blockchain\n\n- Your posts, photos and files live on an email like network, where independent providers all connect to each other\n'**
  String get onbInfraBody;

  /// No description provided for @onbAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get onbAccountsTitle;

  /// No description provided for @onbAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The four account types you\'ll interact with in PublicOS'**
  String get onbAccountsSubtitle;

  /// No description provided for @onbAccountsSelfPrefix.
  ///
  /// In en, this message translates to:
  /// **'You\'re currently a '**
  String get onbAccountsSelfPrefix;

  /// No description provided for @onbCitizenWord.
  ///
  /// In en, this message translates to:
  /// **'citizen'**
  String get onbCitizenWord;

  /// No description provided for @onbPrivateWord.
  ///
  /// In en, this message translates to:
  /// **'private'**
  String get onbPrivateWord;

  /// No description provided for @onbCitizenLabel.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get onbCitizenLabel;

  /// No description provided for @onbCitizenDesc.
  ///
  /// In en, this message translates to:
  /// **'Humans vouched on a social graph, free public services, one vote.'**
  String get onbCitizenDesc;

  /// No description provided for @onbPublicOrgLabel.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC ORG'**
  String get onbPublicOrgLabel;

  /// No description provided for @onbPublicOrgDesc.
  ///
  /// In en, this message translates to:
  /// **'Citizen collectives of any type and size.'**
  String get onbPublicOrgDesc;

  /// No description provided for @onbPrivateLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get onbPrivateLabel;

  /// No description provided for @onbPrivateDesc.
  ///
  /// In en, this message translates to:
  /// **'Anonymous accounts, no vouching needed.'**
  String get onbPrivateDesc;

  /// No description provided for @onbPrivateOrgLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE ORG'**
  String get onbPrivateOrgLabel;

  /// No description provided for @onbPrivateOrgDesc.
  ///
  /// In en, this message translates to:
  /// **'Citizen and private mixed collectives for groups and businesses.'**
  String get onbPrivateOrgDesc;

  /// No description provided for @onbMorphAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Account'**
  String get onbMorphAccountTitle;

  /// No description provided for @onbMorphAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get onbMorphAccountSubtitle;

  /// No description provided for @onbMorphAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you do on PublicOS runs through one smart account. \n\nIt\'s your name and address, it keeps your records, assets and a public record of keys you authorize to sign with.\n\nLet\'s see how it comes together.'**
  String get onbMorphAccountBody;

  /// No description provided for @onbMorphDomainTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Domain'**
  String get onbMorphDomainTitle;

  /// No description provided for @onbMorphDomainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The name people use to find you'**
  String get onbMorphDomainSubtitle;

  /// No description provided for @onbMorphDomainBody.
  ///
  /// In en, this message translates to:
  /// **'Your **domain** is your readable name, the handle others type to reach you.'**
  String get onbMorphDomainBody;

  /// No description provided for @onbDomainBodyCitizen.
  ///
  /// In en, this message translates to:
  /// **'Your **domain** is your readable name, the handle others type to reach you.\n\nYou hold **citizenship**, so yours is free for life.'**
  String get onbDomainBodyCitizen;

  /// No description provided for @onbDomainBodyPaid.
  ///
  /// In en, this message translates to:
  /// **'Your **domain** is your readable name, the handle others type to reach you.\n\nYour account is **private**, and your domain is **already paid for**.'**
  String get onbDomainBodyPaid;

  /// No description provided for @onbDomainBodyRent.
  ///
  /// In en, this message translates to:
  /// **'Your **domain** is your readable name, the handle others type to reach you.\n\nPrivate accounts pay a **domain fee** to keep theirs. Set yours up below and you\'re ready.'**
  String get onbDomainBodyRent;

  /// No description provided for @onbMorphAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Account Address'**
  String get onbMorphAddressTitle;

  /// No description provided for @onbMorphAddressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What the domain points at'**
  String get onbMorphAddressSubtitle;

  /// No description provided for @onbMorphAddressBody.
  ///
  /// In en, this message translates to:
  /// **'Your domain may change, but it always resolves to the same address on the chain.\n\nIt\'s your account\'s smart contract address, it runs by PublicOS rules, and holds your account\'s data.'**
  String get onbMorphAddressBody;

  /// No description provided for @onbMorphRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Records'**
  String get onbMorphRecordsTitle;

  /// No description provided for @onbMorphRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What your account holds'**
  String get onbMorphRecordsSubtitle;

  /// No description provided for @onbMorphRecordsBody.
  ///
  /// In en, this message translates to:
  /// **'Records are pieces of information you choose to make public like your avatar and banner, the tabs that point out to your chats, your websites, your feeds.\n\n Take a look, open the tabs sheet.'**
  String get onbMorphRecordsBody;

  /// No description provided for @onbMorphSafeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Safe'**
  String get onbMorphSafeTitle;

  /// No description provided for @onbMorphSafeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where your assets are kept'**
  String get onbMorphSafeSubtitle;

  /// No description provided for @onbMorphSafeBody.
  ///
  /// In en, this message translates to:
  /// **'Linked to your account sits a federated safe: a smart vault that holds your tokens and assets.\n\nIt\'s programmable, you can set rules and modules to manage as you like.'**
  String get onbMorphSafeBody;

  /// No description provided for @onbBspTitle.
  ///
  /// In en, this message translates to:
  /// **'Blockchain Provider'**
  String get onbBspTitle;

  /// No description provided for @onbBspSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your gateway to the chain'**
  String get onbBspSubtitle;

  /// No description provided for @onbBspBody.
  ///
  /// In en, this message translates to:
  /// **'BSPs are public notaries. They verify every transaction is valid and signed by you, record it and share with other BSPs threading a ledger anyone can audit.\n\nIt is one transparent spreadsheet of balances and smart contracts. BSPs keep it running and connect you to it.'**
  String get onbBspBody;

  /// No description provided for @onbBspPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'As a private, you can connect via the Public RPC or subscribe to a BSP (each sets its own fair-use policy).'**
  String get onbBspPrivateNote;

  /// No description provided for @onbSspTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Provider'**
  String get onbSspTitle;

  /// No description provided for @onbSspSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where your feeds live'**
  String get onbSspSubtitle;

  /// No description provided for @onbSspBody.
  ///
  /// In en, this message translates to:
  /// **'An SSP hosts what any social media app would: your feeds, media, and social content.\n\nPick one to get started, or bring your own. You can always explore PublicOS first and add one later.'**
  String get onbSspBody;

  /// No description provided for @onbSspPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'As a private account this is an optional subscription, paid directly to your provider.'**
  String get onbSspPrivateNote;

  /// No description provided for @onbProviderCitizenNote.
  ///
  /// In en, this message translates to:
  /// **'Free for you, the network covers provider fees for citizens.'**
  String get onbProviderCitizenNote;

  /// No description provided for @onbEconomyTitle.
  ///
  /// In en, this message translates to:
  /// **'Economy'**
  String get onbEconomyTitle;

  /// No description provided for @onbEconomySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sovereign'**
  String get onbEconomySubtitle;

  /// No description provided for @onbEconomyBody.
  ///
  /// In en, this message translates to:
  /// **'PublicOS runs its own currency, **ox ¤**, managed like a national economy.\n\n**Contractors** (BSPs and SSPs) run the services. PublicOS mints ox to cover citizens\' use of them.\n\n**Domains** are a second market: citizens get one as a public right, while the rest trade on the open market.\n\nThe idea: **you are the platform\'s value**, so you earn a little ox whenever services are paid. Check the Treasury often.'**
  String get onbEconomyBody;

  /// No description provided for @onbContractTitle.
  ///
  /// In en, this message translates to:
  /// **'The social contract'**
  String get onbContractTitle;

  /// No description provided for @onbContractSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our constitution'**
  String get onbContractSubtitle;

  /// No description provided for @onbContractBody.
  ///
  /// In en, this message translates to:
  /// **'Citizenship is a public right. In return, you honor one pledge:\n\n**Vouched accounts are humans.** If it ever mattered, you could point to a real person behind anyone you vouch for.\n\nYou vouch for **humanity, not morality**. You are never responsible for what others do, only for the truth of your vouch.'**
  String get onbContractBody;

  /// No description provided for @onbKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get onbKeysTitle;

  /// No description provided for @onbKeysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The ink behind your signature'**
  String get onbKeysSubtitle;

  /// No description provided for @onbKeysBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you do on chain is \"signed\" with your keys, the way a pen signs in ink.\n\n**Private key**: your secret. A signature made with it proves it\'s you, and only you can make one. Never share it.\n\n**Public address**: your shareable identifier. It lets anyone confirm a signature is really yours.\n\nCreate your first key, and keep its recovery phrase somewhere safe.'**
  String get onbKeysBody;

  /// No description provided for @onbXmtpTitle.
  ///
  /// In en, this message translates to:
  /// **'XMTP'**
  String get onbXmtpTitle;

  /// No description provided for @onbXmtpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private messaging, no middleman'**
  String get onbXmtpSubtitle;

  /// No description provided for @onbXmtpBody.
  ///
  /// In en, this message translates to:
  /// **'PublicOS messages run on XMTP\'s decentralized network.\n\n**Many inboxes.** Make as many separate ones as you want.\n\n**No middleman.** End to end encrypted.\n\nAny key can create or join an Inbox ID.'**
  String get onbXmtpBody;

  /// No description provided for @onbInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox IDs'**
  String get onbInboxTitle;

  /// No description provided for @onbInboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your messaging address'**
  String get onbInboxSubtitle;

  /// No description provided for @onbInboxBody.
  ///
  /// In en, this message translates to:
  /// **'Treat inbox IDs as emails, some are to be kept off chain and private, some are public and shareable.\n\nPublish it to your profile with the \"tab\" button so people can reach you, it links your account to your messaging inbox on-chain.'**
  String get onbInboxBody;

  /// No description provided for @onbGetAroundTitle.
  ///
  /// In en, this message translates to:
  /// **'Get around PublicOS'**
  String get onbGetAroundTitle;

  /// No description provided for @onbGetAroundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Three things worth knowing'**
  String get onbGetAroundSubtitle;

  /// No description provided for @onbManualTitle.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get onbManualTitle;

  /// No description provided for @onbManualBody.
  ///
  /// In en, this message translates to:
  /// **'Everything about PublicOS, at your own pace, what the words mean, how the money works, what you can do. In your **Apps**.'**
  String get onbManualBody;

  /// No description provided for @onbLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get onbLibraryTitle;

  /// No description provided for @onbLibraryBody.
  ///
  /// In en, this message translates to:
  /// **'How PublicOS works, in depth: what things cost, the rules, every contract. In your **Apps**.'**
  String get onbLibraryBody;

  /// No description provided for @onbSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get onbSupportTitle;

  /// No description provided for @onbSupportBody.
  ///
  /// In en, this message translates to:
  /// **'An assistant lives on the **publicos** profile, under **support**. Ask it anything, in **any language**.'**
  String get onbSupportBody;

  /// No description provided for @onbDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get onbDone;

  /// No description provided for @onbEnter.
  ///
  /// In en, this message translates to:
  /// **'ENTER PUBLICOS'**
  String get onbEnter;

  /// No description provided for @onbContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get onbContinue;

  /// Onboarding bottom bar: the link above CONTINUE that re-opens the citizenship claim sheet for an eligible private who dismissed it (2026-10-16).
  ///
  /// In en, this message translates to:
  /// **'CLAIM CITIZENSHIP'**
  String get onbClaimCitizenship;

  /// No description provided for @onbChooseBsp.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A BSP'**
  String get onbChooseBsp;

  /// No description provided for @onbChooseSsp.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE AN SSP'**
  String get onbChooseSsp;

  /// No description provided for @onbOpenTabsFirst.
  ///
  /// In en, this message translates to:
  /// **'OPEN MY TABS FIRST'**
  String get onbOpenTabsFirst;

  /// No description provided for @onbSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'SKIP FOR NOW'**
  String get onbSkipForNow;

  /// No description provided for @onbSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onbSkip;

  /// No description provided for @onbRedoHintTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set'**
  String get onbRedoHintTitle;

  /// No description provided for @onbRedoHintBody.
  ///
  /// In en, this message translates to:
  /// **'Want to keep learning? Open the Users Manual app, it\'s already in your Apps. You can pick or change your providers any time from the Settings app, and redo this whole intro from there too.'**
  String get onbRedoHintBody;

  /// No description provided for @onbYoursCreateInboxFirst.
  ///
  /// In en, this message translates to:
  /// **'CREATE YOUR INBOX FIRST'**
  String get onbYoursCreateInboxFirst;

  /// No description provided for @onbYoursTitle.
  ///
  /// In en, this message translates to:
  /// **'A WAY IN'**
  String get onbYoursTitle;

  /// No description provided for @onbYoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A profile, but no door.'**
  String get onbYoursSubtitle;

  /// No description provided for @onbYoursBody.
  ///
  /// In en, this message translates to:
  /// **'You have an account, but there\'s still no way to reach you.\n\nPublish an **inbox** as a tab and people can find you under your name.'**
  String get onbYoursBody;

  /// No description provided for @onbYoursAddInbox.
  ///
  /// In en, this message translates to:
  /// **'ADD MY FIRST INBOX'**
  String get onbYoursAddInbox;

  /// No description provided for @onbYoursHaveBody.
  ///
  /// In en, this message translates to:
  /// **'You already have an **inbox**, people can reach you under your name.\n\nWant to see how another one gets published?'**
  String get onbYoursHaveBody;

  /// No description provided for @onbYoursUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Your **inbox** may already be published, we couldn\'t check just now.\n\nCarry on, or walk through publishing one.'**
  String get onbYoursUnknownBody;

  /// No description provided for @onbYoursShowMeHow.
  ///
  /// In en, this message translates to:
  /// **'SHOW ME HOW'**
  String get onbYoursShowMeHow;

  /// No description provided for @onbTabsBody.
  ///
  /// In en, this message translates to:
  /// **'Your name can hold more than one **tab**. You published an inbox, that is one.\n\nEverything below is added later from your account page. Nothing else is needed today.'**
  String get onbTabsBody;

  /// No description provided for @onbTabsAdded.
  ///
  /// In en, this message translates to:
  /// **'ADDED'**
  String get onbTabsAdded;

  /// No description provided for @onbTabsInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get onbTabsInboxTitle;

  /// No description provided for @onbTabsInboxSub.
  ///
  /// In en, this message translates to:
  /// **'the one you just published'**
  String get onbTabsInboxSub;

  /// No description provided for @onbTabsWebSub.
  ///
  /// In en, this message translates to:
  /// **'your site, under your name'**
  String get onbTabsWebSub;

  /// No description provided for @onbTabsChannelSub.
  ///
  /// In en, this message translates to:
  /// **'a feed people can follow'**
  String get onbTabsChannelSub;

  /// No description provided for @onbTabsAnotherTitle.
  ///
  /// In en, this message translates to:
  /// **'Another inbox'**
  String get onbTabsAnotherTitle;

  /// No description provided for @onbTabsAnotherSub.
  ///
  /// In en, this message translates to:
  /// **'work, public, as many as you like'**
  String get onbTabsAnotherSub;

  /// No description provided for @onbCoachKeychain.
  ///
  /// In en, this message translates to:
  /// **'Your keys live in the **keychain**. Open it.'**
  String get onbCoachKeychain;

  /// No description provided for @onbCoachGenerate.
  ///
  /// In en, this message translates to:
  /// **'Your messages arrive in an **inbox** outside, and an inbox has its own lock. You can put up as many inboxes as you like. Let's cut the key for your first one.'**
  String get onbCoachGenerate;

  /// No description provided for @onbCoachHouse.
  ///
  /// In en, this message translates to:
  /// **'This is your **keychain**. Think of your account as your house. You already have the key to the front door: it's the one marked **SESSION**.'**
  String get onbCoachHouse;

  /// No description provided for @onbCoachContinue.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to continue'**
  String get onbCoachContinue;

  /// No description provided for @onbCoachSim.
  ///
  /// In en, this message translates to:
  /// **'Now switch it on for messaging, tap the **SIM**. That is what gives the key an inbox, and how you swap keys later.'**
  String get onbCoachSim;

  /// No description provided for @onbProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR ACCOUNT'**
  String get onbProfileTitle;

  /// No description provided for @onbProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Same parts. Already yours.'**
  String get onbProfileSubtitle;

  /// No description provided for @onbProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Let\'s fill in your **bio**.'**
  String get onbProfileBody;

  /// No description provided for @onbProfileChooseBioFirst.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE A BIO FIRST'**
  String get onbProfileChooseBioFirst;

  /// No description provided for @onbBioSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get onbBioSaveChanges;

  /// No description provided for @onbBioSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING'**
  String get onbBioSaving;

  /// No description provided for @onbBioUndo.
  ///
  /// In en, this message translates to:
  /// **'UNDO CHANGES'**
  String get onbBioUndo;

  /// No description provided for @onbProfileBioEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your bio is still empty.'**
  String get onbProfileBioEmpty;

  /// No description provided for @onbProfileNextCards.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE WITH MY CARDS'**
  String get onbProfileNextCards;

  /// No description provided for @onbCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'YOUR CARDS'**
  String get onbCardsTitle;

  /// No description provided for @onbCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Already on your profile.'**
  String get onbCardsSubtitle;

  /// No description provided for @onbCardsBody.
  ///
  /// In en, this message translates to:
  /// **'Select a **theme** and some **cards** for your profile.'**
  String get onbCardsBody;

  /// No description provided for @onbCardsRandomize.
  ///
  /// In en, this message translates to:
  /// **'RANDOMIZE'**
  String get onbCardsRandomize;

  /// No description provided for @onbCardsUndo.
  ///
  /// In en, this message translates to:
  /// **'UNDO CHANGES'**
  String get onbCardsUndo;

  /// No description provided for @onbCardsSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING'**
  String get onbCardsSaving;

  /// No description provided for @onbGiftBody.
  ///
  /// In en, this message translates to:
  /// **'🎁 A **gift for citizens**, a collectible theme kit for your profile.'**
  String get onbGiftBody;

  /// No description provided for @onbGiftOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN GIFT'**
  String get onbGiftOpen;

  /// No description provided for @onbGiftMinting.
  ///
  /// In en, this message translates to:
  /// **'OPENING'**
  String get onbGiftMinting;

  /// No description provided for @onbThemeSoulbound.
  ///
  /// In en, this message translates to:
  /// **'STARTER'**
  String get onbThemeSoulbound;

  /// No description provided for @onbThemeCitizen.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get onbThemeCitizen;

  /// No description provided for @onbProfileBioPrompt.
  ///
  /// In en, this message translates to:
  /// **'Say something about yourself.'**
  String get onbProfileBioPrompt;

  /// No description provided for @onbProfileBioWriteOwn.
  ///
  /// In en, this message translates to:
  /// **'Write your own…'**
  String get onbProfileBioWriteOwn;

  /// No description provided for @onbProfileBioPreset1.
  ///
  /// In en, this message translates to:
  /// **'Citizen of PublicOS. Building in the open.'**
  String get onbProfileBioPreset1;

  /// No description provided for @onbProfileBioPreset2.
  ///
  /// In en, this message translates to:
  /// **'Here for the feeds, the forums, and the friends.'**
  String get onbProfileBioPreset2;

  /// No description provided for @onbProfileBioPreset3.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything, my inbox is on my profile.'**
  String get onbProfileBioPreset3;

  /// No description provided for @onbAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'AN ACCOUNT'**
  String get onbAccountTitle;

  /// No description provided for @onbAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This one belongs to PublicOS.'**
  String get onbAccountSubtitle;

  /// No description provided for @onbAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Every **account** is built the same way: a readable name, its address, and whatever it chooses to publish.\n\nPublished **tabs** are the account\'s menu. Open PublicOS\'s tabs and take a look.'**
  String get onbAccountBody;

  /// No description provided for @onbAccountOpenTabsFirst.
  ///
  /// In en, this message translates to:
  /// **'OPEN THE TABS FIRST'**
  String get onbAccountOpenTabsFirst;

  /// No description provided for @onbDomainManageFirst.
  ///
  /// In en, this message translates to:
  /// **'MANAGE YOUR DOMAIN FIRST'**
  String get onbDomainManageFirst;

  /// No description provided for @onbTabsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{account} · tabs'**
  String onbTabsSheetTitle(String account);

  /// No description provided for @onbTabApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get onbTabApp;

  /// No description provided for @onbTabManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get onbTabManagement;

  /// No description provided for @onbTabOrg.
  ///
  /// In en, this message translates to:
  /// **'Org'**
  String get onbTabOrg;

  /// No description provided for @onbTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get onbTabProfile;

  /// No description provided for @onbTabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get onbTabChat;

  /// No description provided for @onbTabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get onbTabFeed;

  /// No description provided for @onbTabWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get onbTabWebsite;

  /// No description provided for @onbTabFallback.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get onbTabFallback;

  /// No description provided for @onbTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add tab'**
  String get onbTabAdd;

  /// No description provided for @onbTabExampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Example tabs'**
  String get onbTabExampleTitle;

  /// No description provided for @onbInboxRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'REGISTER INBOX ID'**
  String get onbInboxRegisterTitle;

  /// No description provided for @onbInboxRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register this inbox to your on-chain profile.'**
  String get onbInboxRegisterSubtitle;

  /// No description provided for @onbInboxHint.
  ///
  /// In en, this message translates to:
  /// **'main, work, …'**
  String get onbInboxHint;

  /// No description provided for @onbInboxRegister.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get onbInboxRegister;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get actionCancel;

  /// No description provided for @domainStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Domain Store'**
  String get domainStoreTitle;

  /// No description provided for @domainChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get domainChecking;

  /// No description provided for @domainLifetimeStatus.
  ///
  /// In en, this message translates to:
  /// **'Lifetime — your domain never expires'**
  String get domainLifetimeStatus;

  /// No description provided for @domainNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set yet'**
  String get domainNotSet;

  /// No description provided for @domainWasDue.
  ///
  /// In en, this message translates to:
  /// **'Was due'**
  String get domainWasDue;

  /// No description provided for @domainPaidUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get domainPaidUntilLabel;

  /// No description provided for @domainYourDomain.
  ///
  /// In en, this message translates to:
  /// **'YOUR DOMAIN'**
  String get domainYourDomain;

  /// No description provided for @domainGraceNote.
  ///
  /// In en, this message translates to:
  /// **'Renew to keep your name and your write access. You\'re in the grace window, so it\'s still yours for now.'**
  String get domainGraceNote;

  /// No description provided for @domainBadgeLifetime.
  ///
  /// In en, this message translates to:
  /// **'LIFETIME'**
  String get domainBadgeLifetime;

  /// No description provided for @domainBadgeOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get domainBadgeOverdue;

  /// No description provided for @domainBadgeActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get domainBadgeActive;

  /// No description provided for @domainSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search a name…'**
  String get domainSearchHint;

  /// No description provided for @domainStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available to claim'**
  String get domainStatusAvailable;

  /// No description provided for @domainStatusLapsed.
  ///
  /// In en, this message translates to:
  /// **'Holder lapsed — claimable'**
  String get domainStatusLapsed;

  /// No description provided for @domainStatusTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get domainStatusTaken;

  /// No description provided for @domainStatusCooldown.
  ///
  /// In en, this message translates to:
  /// **'On cooldown'**
  String get domainStatusCooldown;

  /// No description provided for @domainStatusYours.
  ///
  /// In en, this message translates to:
  /// **'This is your name'**
  String get domainStatusYours;

  /// No description provided for @domainFreeForYou.
  ///
  /// In en, this message translates to:
  /// **'Free for you'**
  String get domainFreeForYou;

  /// No description provided for @domainCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get domainCalculating;

  /// No description provided for @domainLifetimeNeverExpires.
  ///
  /// In en, this message translates to:
  /// **'Lifetime — never expires'**
  String get domainLifetimeNeverExpires;

  /// No description provided for @domainName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get domainName;

  /// No description provided for @domainChars.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 char} other{{count} chars}}'**
  String domainChars(int count);

  /// No description provided for @domainSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get domainSubtotal;

  /// No description provided for @domainDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount *'**
  String get domainDiscount;

  /// No description provided for @domainTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get domainTotal;

  /// No description provided for @domainBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get domainBalance;

  /// No description provided for @domainBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get domainBalanceAfter;

  /// No description provided for @domainNotEnoughPosNote.
  ///
  /// In en, this message translates to:
  /// **'Not enough OX in your wallet for this.'**
  String get domainNotEnoughPosNote;

  /// No description provided for @domainNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters'**
  String domainNameTooShort(int min);

  /// No description provided for @domainNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} characters'**
  String domainNameTooLong(int max);

  /// No description provided for @domainNameStartLetter.
  ///
  /// In en, this message translates to:
  /// **'Must start with a letter'**
  String get domainNameStartLetter;

  /// No description provided for @domainNameEndDashUnderscore.
  ///
  /// In en, this message translates to:
  /// **'Can\'t end in - or _'**
  String get domainNameEndDashUnderscore;

  /// No description provided for @domainNameAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed: a–z 0–9 - _'**
  String get domainNameAllowed;

  /// No description provided for @domainNameNoConsecDash.
  ///
  /// In en, this message translates to:
  /// **'No consecutive --'**
  String get domainNameNoConsecDash;

  /// No description provided for @domainNameNoConsecUnderscore.
  ///
  /// In en, this message translates to:
  /// **'No consecutive __'**
  String get domainNameNoConsecUnderscore;

  /// No description provided for @domainMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get domainMonths;

  /// No description provided for @domainRenewed.
  ///
  /// In en, this message translates to:
  /// **'Domain renewed'**
  String get domainRenewed;

  /// No description provided for @domainClaimed.
  ///
  /// In en, this message translates to:
  /// **'Name claimed'**
  String get domainClaimed;

  /// No description provided for @domainEnterValidName.
  ///
  /// In en, this message translates to:
  /// **'ENTER A VALID NAME'**
  String get domainEnterValidName;

  /// No description provided for @domainBtnChecking.
  ///
  /// In en, this message translates to:
  /// **'CHECKING…'**
  String get domainBtnChecking;

  /// No description provided for @domainBtnYourName.
  ///
  /// In en, this message translates to:
  /// **'THIS IS YOUR NAME'**
  String get domainBtnYourName;

  /// No description provided for @domainBtnNotEnoughPos.
  ///
  /// In en, this message translates to:
  /// **'NOT ENOUGH OX'**
  String get domainBtnNotEnoughPos;

  /// No description provided for @domainBtnRenew.
  ///
  /// In en, this message translates to:
  /// **'RENEW'**
  String get domainBtnRenew;

  /// No description provided for @domainBtnNameTaken.
  ///
  /// In en, this message translates to:
  /// **'NAME TAKEN'**
  String get domainBtnNameTaken;

  /// No description provided for @domainBtnOnCooldown.
  ///
  /// In en, this message translates to:
  /// **'ON COOLDOWN'**
  String get domainBtnOnCooldown;

  /// No description provided for @domainBtnRenewFirst.
  ///
  /// In en, this message translates to:
  /// **'RENEW YOUR DOMAIN FIRST'**
  String get domainBtnRenewFirst;

  /// No description provided for @domainBtnNoFreeChange.
  ///
  /// In en, this message translates to:
  /// **'NO FREE CHANGE LEFT'**
  String get domainBtnNoFreeChange;

  /// No description provided for @domainBtnClaim.
  ///
  /// In en, this message translates to:
  /// **'CLAIM'**
  String get domainBtnClaim;

  /// No description provided for @domainBtnSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING TO CHAIN…'**
  String get domainBtnSaving;

  /// No description provided for @domainBtnCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get domainBtnCancel;

  /// No description provided for @domainBtnClaimIt.
  ///
  /// In en, this message translates to:
  /// **'CLAIM IT'**
  String get domainBtnClaimIt;

  /// No description provided for @domainNoteLifetime.
  ///
  /// In en, this message translates to:
  /// **'Lifetime — your domain never expires, so there\'s nothing to renew and no months to pick.'**
  String get domainNoteLifetime;

  /// No description provided for @domainNoteFreeCitizenChar.
  ///
  /// In en, this message translates to:
  /// **'Free for you as a citizen on a {min}+ character name.'**
  String domainNoteFreeCitizenChar(int min);

  /// No description provided for @domainNoteFreeCitizen.
  ///
  /// In en, this message translates to:
  /// **'Free for you as a citizen.'**
  String get domainNoteFreeCitizen;

  /// No description provided for @domainNoteFreeAnnual.
  ///
  /// In en, this message translates to:
  /// **'This change is free — it uses your once-a-year free name change.'**
  String get domainNoteFreeAnnual;

  /// No description provided for @domainNoteFreeBonus.
  ///
  /// In en, this message translates to:
  /// **'This change is free — it spends 1 of your {count, plural, =1{1 bonus name-change ticket} other{{count} bonus name-change tickets}}.'**
  String domainNoteFreeBonus(int count);

  /// No description provided for @domainNoteNoFreeUntil.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your yearly free change and hold no bonus tickets, so this free change isn\'t available until {date}. You earn a ticket each time you gain citizenship.'**
  String domainNoteNoFreeUntil(String date);

  /// No description provided for @domainNoteFlatFee.
  ///
  /// In en, this message translates to:
  /// **'One-time fee — as a citizen this name is yours for life, no renewals. 98% of what you pay is burned, 2% is shared with verified PublicOS Domains.'**
  String get domainNoteFlatFee;

  /// No description provided for @domainNoteFlatFeeNextFree.
  ///
  /// In en, this message translates to:
  /// **'One-time fee — as a citizen this name is yours for life, no renewals. Your next free change opens {date}.'**
  String domainNoteFlatFeeNextFree(String date);

  /// No description provided for @domainNoteDiscount.
  ///
  /// In en, this message translates to:
  /// **'* Prepay more months for a bigger discount — about {pct}% off each extra month, up to a cap. 98% of what you pay is burned, 2% is shared with verified PublicOS Domains.'**
  String domainNoteDiscount(String pct);

  /// No description provided for @domainConfirmBecomes.
  ///
  /// In en, this message translates to:
  /// **'Your account becomes \"{name}\". '**
  String domainConfirmBecomes(String name);

  /// No description provided for @domainConfirmCurrentFreed.
  ///
  /// In en, this message translates to:
  /// **'Your current name \"{name}\" is freed (30-day cooldown if you\'re a citizen).'**
  String domainConfirmCurrentFreed(String name);

  /// No description provided for @domainConfirmOldFreed.
  ///
  /// In en, this message translates to:
  /// **'Your old name is freed (30-day cooldown if you\'re a citizen).'**
  String get domainConfirmOldFreed;

  /// No description provided for @domainConfirmEvicts.
  ///
  /// In en, this message translates to:
  /// **'The current holder\'s domain has lapsed, so claiming evicts them onto a junk name.'**
  String get domainConfirmEvicts;

  /// No description provided for @domainConfirmFree.
  ///
  /// In en, this message translates to:
  /// **'Free for you.'**
  String get domainConfirmFree;

  /// No description provided for @domainConfirmCost.
  ///
  /// In en, this message translates to:
  /// **'Cost: {cost}  ·  98% burned, 2% shared with verified PublicOS Domains.'**
  String domainConfirmCost(String cost);

  /// No description provided for @domainConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim \"{name}\"'**
  String domainConfirmTitle(String name);

  /// No description provided for @dlgCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dlgCancel;

  /// No description provided for @dlgOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dlgOk;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @keychainTitle.
  ///
  /// In en, this message translates to:
  /// **'Keychain'**
  String get keychainTitle;

  /// No description provided for @keychainGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Keychain'**
  String get keychainGroupTitle;

  /// No description provided for @keychainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your messaging and wallet keys'**
  String get keychainSubtitle;

  /// No description provided for @keychainGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Managing keys for {name}'**
  String keychainGroupSubtitle(String name);

  /// No description provided for @keychainGenTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate New Key'**
  String get keychainGenTitle;

  /// No description provided for @keychainGenGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate New Group Key'**
  String get keychainGenGroupTitle;

  /// No description provided for @keychainKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Key Label'**
  String get keychainKeyLabel;

  /// No description provided for @keychainKeyLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a label for this key'**
  String get keychainKeyLabelHint;

  /// No description provided for @keychainGenExplain.
  ///
  /// In en, this message translates to:
  /// **'You\'re about to generate a new key. It is stored on this device only. This does not register it as a session or turn on messaging.'**
  String get keychainGenExplain;

  /// No description provided for @keychainGenEmojiHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick an emoji'**
  String get keychainGenEmojiHint;

  /// No description provided for @keychainGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get keychainGenerate;

  /// No description provided for @keychainImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get keychainImport;

  /// No description provided for @keychainKeyCreated.
  ///
  /// In en, this message translates to:
  /// **'Key created'**
  String get keychainKeyCreated;

  /// No description provided for @keychainRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'RECOVERY PHRASE'**
  String get keychainRecoveryTitle;

  /// No description provided for @keychainRecoveryWarning.
  ///
  /// In en, this message translates to:
  /// **'Write down these 12 words. This is the only way to recover your key. Store it offline. Never share it.'**
  String get keychainRecoveryWarning;

  /// No description provided for @keychainDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Key'**
  String get keychainDeleteTitle;

  /// No description provided for @keychainDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the key \"{label}\"? This action cannot be undone.'**
  String keychainDeleteConfirm(String label);

  /// No description provided for @keychainDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get keychainDelete;

  /// No description provided for @keychainKeyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Key deleted successfully'**
  String get keychainKeyDeleted;

  /// No description provided for @keychainDeleteLoadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Key loaded on XMTP'**
  String get keychainDeleteLoadedTitle;

  /// No description provided for @keychainDeleteLoadedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" is the key your messages run on right now. Deleting it signs messaging out on this device. Sure to delete it?'**
  String keychainDeleteLoadedBody(Object label);

  /// No description provided for @keychainDeleteContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get keychainDeleteContinue;

  /// No description provided for @keychainDeleteLoadedPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you store the recovery phrase?'**
  String get keychainDeleteLoadedPhraseTitle;

  /// No description provided for @keychainDeleteLoadedPhraseBody.
  ///
  /// In en, this message translates to:
  /// **'Without the phrase or the private key, this key and the messages tied to it cannot be recovered. This cannot be undone.'**
  String get keychainDeleteLoadedPhraseBody;

  /// No description provided for @keychainKeyDeletedUnloaded.
  ///
  /// In en, this message translates to:
  /// **'Key deleted. Messaging is off until you pick a key.'**
  String get keychainKeyDeletedUnloaded;

  /// No description provided for @keychainKeyUnloaded.
  ///
  /// In en, this message translates to:
  /// **'Key unloaded. Messaging is off until you load a key.'**
  String get keychainKeyUnloaded;

  /// No description provided for @keychainAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get keychainAddressCopied;

  /// No description provided for @keychainPrivKeyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Private key not found'**
  String get keychainPrivKeyNotFound;

  /// No description provided for @keychainImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Key'**
  String get keychainImportTitle;

  /// No description provided for @keychainImportGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Group Key'**
  String get keychainImportGroupTitle;

  /// No description provided for @keychainImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import using mnemonic or private key'**
  String get keychainImportSubtitle;

  /// No description provided for @keychainEnterLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Key Label'**
  String get keychainEnterLabelTitle;

  /// No description provided for @keychainImportLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a label for this imported key'**
  String get keychainImportLabelHint;

  /// No description provided for @keychainDbMismatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Local Messages Exist'**
  String get keychainDbMismatchTitle;

  /// No description provided for @keychainDbMismatchBody.
  ///
  /// In en, this message translates to:
  /// **'This device has cached messages for wallet {wallet}... from a previous session, but the encryption key no longer matches.\n\nTo continue importing, local messages for this key will be erased. Messages on the XMTP network are not affected.'**
  String keychainDbMismatchBody(String wallet);

  /// No description provided for @keychainEraseContinue.
  ///
  /// In en, this message translates to:
  /// **'Erase & Continue'**
  String get keychainEraseContinue;

  /// No description provided for @keychainInstallCapTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Limit Reached'**
  String get keychainInstallCapTitle;

  /// No description provided for @keychainInstallCapBody.
  ///
  /// In en, this message translates to:
  /// **'This key already has 10 registered XMTP devices — the protocol maximum. To use it here, older device registrations must be revoked first.\n\nWallet: {wallet}...'**
  String keychainInstallCapBody(String wallet);

  /// No description provided for @keychainInstallCapRevokeAll.
  ///
  /// In en, this message translates to:
  /// **'Revoke all other devices'**
  String get keychainInstallCapRevokeAll;

  /// No description provided for @keychainInstallCapRevokeAllDetail.
  ///
  /// In en, this message translates to:
  /// **'Quick recovery: ALL existing registrations of this key are revoked and the import retries. Every other device or app using this key stops sending and receiving until you sign in there again.'**
  String get keychainInstallCapRevokeAllDetail;

  /// No description provided for @keychainInstallCapSelective.
  ///
  /// In en, this message translates to:
  /// **'Revoke selectively on another device'**
  String get keychainInstallCapSelective;

  /// No description provided for @keychainInstallCapSelectiveDetail.
  ///
  /// In en, this message translates to:
  /// **'Open the app on another device where this key still works, go to Manage Inbox IDs, and revoke individual devices there. Then retry the import here.'**
  String get keychainInstallCapSelectiveDetail;

  /// No description provided for @keychainInstallCapConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke all other devices?'**
  String get keychainInstallCapConfirmTitle;

  /// No description provided for @keychainInstallCapConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This signs a revocation for every other registration of this key and cannot be undone. Continue?'**
  String get keychainInstallCapConfirmBody;

  /// No description provided for @keychainInstallCapRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not revoke the other devices: {error}'**
  String keychainInstallCapRevokeFailed(String error);

  /// No description provided for @keychainSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Loading a key you already used on another device, and you have its message backup? Restore it here. If this key is new, there is nothing to restore — start fresh.'**
  String get keychainSetupHint;

  /// No description provided for @keychainOfferRegTitle.
  ///
  /// In en, this message translates to:
  /// **'PUBLISH THIS INBOX?'**
  String get keychainOfferRegTitle;

  /// No description provided for @keychainOfferRegBody.
  ///
  /// In en, this message translates to:
  /// **'This key is active and has an inbox ID ({id}). Publish it as a tab on your profile so people can message you.'**
  String keychainOfferRegBody(String id);

  /// No description provided for @keychainOfferRegLabel.
  ///
  /// In en, this message translates to:
  /// **'Tab name'**
  String get keychainOfferRegLabel;

  /// No description provided for @keychainOfferRegDontAsk.
  ///
  /// In en, this message translates to:
  /// **'Don\'t suggest again for any key'**
  String get keychainOfferRegDontAsk;

  /// No description provided for @keychainOfferRegKeepPrivate.
  ///
  /// In en, this message translates to:
  /// **'Keep private'**
  String get keychainOfferRegKeepPrivate;

  /// No description provided for @keychainOfferRegPublish.
  ///
  /// In en, this message translates to:
  /// **'PUBLISH'**
  String get keychainOfferRegPublish;

  /// No description provided for @keychainOfferRegLater.
  ///
  /// In en, this message translates to:
  /// **'NOT NOW'**
  String get keychainOfferRegLater;

  /// No description provided for @appSettingsPageInboxPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Offer to publish new inboxes'**
  String get appSettingsPageInboxPromptTitle;

  /// No description provided for @appSettingsPageInboxPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After a key is activated, ask whether to publish its inbox ID as a profile tab.'**
  String get appSettingsPageInboxPromptSubtitle;

  /// No description provided for @keychainSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up messaging on this device'**
  String get keychainSetupTitle;

  /// No description provided for @keychainSetupBody.
  ///
  /// In en, this message translates to:
  /// **'This key has no message database on this device yet. Choose how to set it up:'**
  String get keychainSetupBody;

  /// No description provided for @keychainSetupCreateFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get keychainSetupCreateFresh;

  /// No description provided for @keychainSetupCreateFreshDetail.
  ///
  /// In en, this message translates to:
  /// **'Register this device with the key and start a new, empty message history. Uses one of the key\'s 10 device slots.'**
  String get keychainSetupCreateFreshDetail;

  /// No description provided for @keychainSetupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get keychainSetupRestore;

  /// No description provided for @keychainSetupRestoreDetail.
  ///
  /// In en, this message translates to:
  /// **'Load a database file you downloaded from another device, together with its encryption key. Keeps your message history and does not use a device slot.'**
  String get keychainSetupRestoreDetail;

  /// No description provided for @keychainRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore database backup'**
  String get keychainRestoreTitle;

  /// No description provided for @keychainRestoreFileTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'XMTP database'**
  String get keychainRestoreFileTypeLabel;

  /// No description provided for @keychainRestoreKeyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Paste the database encryption key from the device you made the backup on.'**
  String get keychainRestoreKeyPrompt;

  /// No description provided for @keychainRestoreKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Encryption key'**
  String get keychainRestoreKeyHint;

  /// No description provided for @keychainRestoreFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get keychainRestoreFailedTitle;

  /// No description provided for @keychainClientReloaded.
  ///
  /// In en, this message translates to:
  /// **'Client reloaded with key \"{label}\"'**
  String keychainClientReloaded(String label);

  /// No description provided for @keychainInboxAlreadyReg.
  ///
  /// In en, this message translates to:
  /// **'This Inbox ID is already registered'**
  String get keychainInboxAlreadyReg;

  /// No description provided for @keychainRegInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Current Inbox ID'**
  String get keychainRegInboxTitle;

  /// No description provided for @keychainRegInboxPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter a label for this Inbox ID: {id}'**
  String keychainRegInboxPrompt(String id);

  /// No description provided for @keychainLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get keychainLabelField;

  /// No description provided for @keychainEnterLabelPlease.
  ///
  /// In en, this message translates to:
  /// **'Please enter a label'**
  String get keychainEnterLabelPlease;

  /// No description provided for @keychainRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get keychainRegister;

  /// No description provided for @keychainInboxRegOther.
  ///
  /// In en, this message translates to:
  /// **'This inbox ID is already registered to another account'**
  String get keychainInboxRegOther;

  /// No description provided for @keychainInboxRegOk.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID registered successfully'**
  String get keychainInboxRegOk;

  /// No description provided for @keychainInboxRegFail.
  ///
  /// In en, this message translates to:
  /// **'Failed to register inbox ID'**
  String get keychainInboxRegFail;

  /// No description provided for @keychainEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Key Label'**
  String get keychainEditTitle;

  /// No description provided for @keychainEditHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new label for this key'**
  String get keychainEditHint;

  /// No description provided for @keychainSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get keychainSave;

  /// No description provided for @keychainLabelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Key label updated successfully'**
  String get keychainLabelUpdated;

  /// No description provided for @keychainWalletEnabled.
  ///
  /// In en, this message translates to:
  /// **'Wallet enabled for \"{label}\"'**
  String keychainWalletEnabled(String label);

  /// No description provided for @keychainWalletDisabled.
  ///
  /// In en, this message translates to:
  /// **'Wallet disabled for \"{label}\"'**
  String keychainWalletDisabled(String label);

  /// No description provided for @keychainWebKeySet.
  ///
  /// In en, this message translates to:
  /// **'Preferred key set to \"{name}\"'**
  String keychainWebKeySet(String name);

  /// No description provided for @keychainSessionKey.
  ///
  /// In en, this message translates to:
  /// **'Session Key'**
  String get keychainSessionKey;

  /// No description provided for @keychainEmojiUpdated.
  ///
  /// In en, this message translates to:
  /// **'Emoji updated for \"{label}\"'**
  String keychainEmojiUpdated(String label);

  /// No description provided for @keychainCopyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy {label}'**
  String keychainCopyTooltip(String label);

  /// No description provided for @keychainNoKeys.
  ///
  /// In en, this message translates to:
  /// **'No additional keys'**
  String get keychainNoKeys;

  /// No description provided for @keychainActivateHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the SIM icon on a key to use it for messaging.'**
  String get keychainActivateHint;

  /// No description provided for @keychainMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get keychainMyAccount;

  /// No description provided for @keychainSessionBadge.
  ///
  /// In en, this message translates to:
  /// **'SESSION'**
  String get keychainSessionBadge;

  /// No description provided for @keychainSessionKeyUnavail.
  ///
  /// In en, this message translates to:
  /// **'Session key not available'**
  String get keychainSessionKeyUnavail;

  /// No description provided for @keychainUnnamedKey.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Key'**
  String get keychainUnnamedKey;

  /// No description provided for @keychainUnknownAddr.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get keychainUnknownAddr;

  /// No description provided for @keychainToggleXmtpKey.
  ///
  /// In en, this message translates to:
  /// **'Current XMTP key'**
  String get keychainToggleXmtpKey;

  /// No description provided for @keychainToggleXmtpSub.
  ///
  /// In en, this message translates to:
  /// **'Use this key to send and receive encrypted messages. Only one key at a time can be active for messaging.'**
  String get keychainToggleXmtpSub;

  /// No description provided for @keychainToggleWebKey.
  ///
  /// In en, this message translates to:
  /// **'Preferred key'**
  String get keychainToggleWebKey;

  /// No description provided for @keychainToggleWebSub.
  ///
  /// In en, this message translates to:
  /// **'Sites that have no active key of their own see this one first — the account most dApps treat as you. It does not give any site access on its own; that is decided per site, where you can also pick a different active key.'**
  String get keychainToggleWebSub;

  /// No description provided for @keychainToggleWallet.
  ///
  /// In en, this message translates to:
  /// **'Show in wallet list'**
  String get keychainToggleWallet;

  /// No description provided for @keychainToggleWalletSub.
  ///
  /// In en, this message translates to:
  /// **'Include this key in the Keychain filter of the Wallet tab, so you can send from it directly.'**
  String get keychainToggleWalletSub;

  /// No description provided for @keychainActionEmoji.
  ///
  /// In en, this message translates to:
  /// **'Change emoji'**
  String get keychainActionEmoji;

  /// No description provided for @keychainActionEmojiSub.
  ///
  /// In en, this message translates to:
  /// **'Pick a new icon to recognize this key at a glance.'**
  String get keychainActionEmojiSub;

  /// No description provided for @keychainActionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename label'**
  String get keychainActionRename;

  /// No description provided for @keychainActionRenameSub.
  ///
  /// In en, this message translates to:
  /// **'The label is just a local nickname — the key and address stay the same.'**
  String get keychainActionRenameSub;

  /// No description provided for @keychainActionExport.
  ///
  /// In en, this message translates to:
  /// **'Export private key'**
  String get keychainActionExport;

  /// No description provided for @keychainActionExportSub.
  ///
  /// In en, this message translates to:
  /// **'Reveal the raw hex so you can import this key in another client. Treat it like a password.'**
  String get keychainActionExportSub;

  /// No description provided for @keychainActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get keychainActionDelete;

  /// No description provided for @keychainActionDeleteSub.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove this key from this device. Make sure you have it backed up first.'**
  String get keychainActionDeleteSub;

  /// No description provided for @importModePhrase.
  ///
  /// In en, this message translates to:
  /// **'PHRASE'**
  String get importModePhrase;

  /// No description provided for @importModePrivateKey.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE KEY'**
  String get importModePrivateKey;

  /// No description provided for @importHintMnemonic.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 word3 word4 ...'**
  String get importHintMnemonic;

  /// No description provided for @importLabelMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12 or 24-word recovery phrase'**
  String get importLabelMnemonic;

  /// No description provided for @importLabelPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Enter private key as hex string'**
  String get importLabelPrivateKey;

  /// No description provided for @importEnterMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Please enter a mnemonic phrase'**
  String get importEnterMnemonic;

  /// No description provided for @importEnterPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter a private key'**
  String get importEnterPrivateKey;

  /// No description provided for @importImporting.
  ///
  /// In en, this message translates to:
  /// **'IMPORTING...'**
  String get importImporting;

  /// No description provided for @netPickHeader.
  ///
  /// In en, this message translates to:
  /// **'PICK A {provider}'**
  String netPickHeader(String provider);

  /// No description provided for @netPickBspTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Blockchain Service Provider'**
  String get netPickBspTitle;

  /// No description provided for @netPickSspTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Social Service Provider'**
  String get netPickSspTitle;

  /// No description provided for @netPickBspBody.
  ///
  /// In en, this message translates to:
  /// **'Tap one. The next sheet confirms the subscription; as a private you can deposit your first months into your service balance in the same transaction.'**
  String get netPickBspBody;

  /// No description provided for @netPickSspBody.
  ///
  /// In en, this message translates to:
  /// **'Tap one. The next sheet confirms the subscription; as a private you can deposit your first months into your service balance in the same transaction.'**
  String get netPickSspBody;

  /// No description provided for @netNoProviders.
  ///
  /// In en, this message translates to:
  /// **'No {provider}s available in the registry.'**
  String netNoProviders(String provider);

  /// No description provided for @netSwitchHeader.
  ///
  /// In en, this message translates to:
  /// **'SWITCH {provider}'**
  String netSwitchHeader(String provider);

  /// No description provided for @netSubscribeHeader.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE TO {provider}'**
  String netSubscribeHeader(String provider);

  /// No description provided for @netSwitching.
  ///
  /// In en, this message translates to:
  /// **'SWITCHING…'**
  String get netSwitching;

  /// No description provided for @netSubscribing.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBING…'**
  String get netSubscribing;

  /// No description provided for @netSwitch.
  ///
  /// In en, this message translates to:
  /// **'SWITCH'**
  String get netSwitch;

  /// No description provided for @netSubscribe.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE'**
  String get netSubscribe;

  /// No description provided for @netProviderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Provider not found'**
  String get netProviderNotFound;

  /// No description provided for @netSlugUnresolved.
  ///
  /// In en, this message translates to:
  /// **'The slug \"{slug}\" did not resolve to a registered {provider}.'**
  String netSlugUnresolved(String slug, String provider);

  /// No description provided for @netProviderFee.
  ///
  /// In en, this message translates to:
  /// **'{provider} fee'**
  String netProviderFee(String provider);

  /// No description provided for @netTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get netTotal;

  /// No description provided for @netCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get netCalculating;

  /// No description provided for @netBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get netBalance;

  /// No description provided for @netFromWallet.
  ///
  /// In en, this message translates to:
  /// **'From wallet'**
  String get netFromWallet;

  /// No description provided for @netMainWallet.
  ///
  /// In en, this message translates to:
  /// **'main · {addr}'**
  String netMainWallet(String addr);

  /// No description provided for @netInsufficientPos.
  ///
  /// In en, this message translates to:
  /// **'Insufficient OX balance for this deposit.'**
  String get netInsufficientPos;

  /// No description provided for @netGateWaived.
  ///
  /// In en, this message translates to:
  /// **'This provider is still below its minimum subscribers, so nothing is drawn from your balance until it gets there. What you deposit stays yours — withdraw it any time from Services.'**
  String get netGateWaived;

  /// No description provided for @netServerRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'This server\'s rules'**
  String get netServerRulesTitle;

  /// No description provided for @netServerPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get netServerPrivacyTitle;

  /// No description provided for @netServerRulesVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} · from {date}'**
  String netServerRulesVersion(Object version, Object date);

  /// No description provided for @netServerRulesAccept.
  ///
  /// In en, this message translates to:
  /// **'Subscribing means you read and accept the protocol agreement and this server\'s rules.'**
  String get netServerRulesAccept;

  /// No description provided for @netServerRulesMissing.
  ///
  /// In en, this message translates to:
  /// **'This server has not published its rules. You can still subscribe.'**
  String get netServerRulesMissing;

  /// No description provided for @netServerRulesUnreachable.
  ///
  /// In en, this message translates to:
  /// **'This server\'s rules could not be loaded right now. You can still subscribe.'**
  String get netServerRulesUnreachable;

  /// No description provided for @netServerRulesAcceptButton.
  ///
  /// In en, this message translates to:
  /// **'Accept and subscribe'**
  String get netServerRulesAcceptButton;

  /// No description provided for @netServerRulesSubscribeAnyway.
  ///
  /// In en, this message translates to:
  /// **'Subscribe anyway'**
  String get netServerRulesSubscribeAnyway;

  /// No description provided for @netNoSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get netNoSession;

  /// No description provided for @netRunBy.
  ///
  /// In en, this message translates to:
  /// **'Run by'**
  String get netRunBy;

  /// No description provided for @netMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get netMonths;

  /// No description provided for @netCardUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get netCardUrl;

  /// No description provided for @netCardRunBy.
  ///
  /// In en, this message translates to:
  /// **'RUN BY'**
  String get netCardRunBy;

  /// No description provided for @netCardSubs.
  ///
  /// In en, this message translates to:
  /// **'SUBS'**
  String get netCardSubs;

  /// No description provided for @netSubsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subscriber} other{{count} subscribers}}'**
  String netSubsCount(int count);

  /// No description provided for @netExplainCitizenSwitch.
  ///
  /// In en, this message translates to:
  /// **'This switches your assigned {provider}, effective now. You don\'t pay anything — the network mints the {provider} fee on your behalf while you use the app.'**
  String netExplainCitizenSwitch(String provider);

  /// No description provided for @netExplainCitizenSubscribe.
  ///
  /// In en, this message translates to:
  /// **'This sets your assigned {provider}. Citizens don\'t pay; the network mints the {provider} fee on your behalf while you use the app.'**
  String netExplainCitizenSubscribe(String provider);

  /// No description provided for @netExplainPrivateSwitch.
  ///
  /// In en, this message translates to:
  /// **'This switches you to a new {provider}, effective now — the old one is paid to the second, nothing is stranded. The fee keeps drawing from your one service balance; the months below are an optional top-up.'**
  String netExplainPrivateSwitch(String provider);

  /// No description provided for @netExplainPrivateSubscribe.
  ///
  /// In en, this message translates to:
  /// **'This subscribes you to this {provider}. The fee accrues by the second and is drawn from your service balance only while the provider has enough subscribers to be paid; the months below are deposited into that balance now and are yours to withdraw while unspent.'**
  String netExplainPrivateSubscribe(String provider);

  /// No description provided for @walletAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get walletAddressCopied;

  /// No description provided for @walletSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet settings'**
  String get walletSettingsTitle;

  /// No description provided for @walletManagerLabel.
  ///
  /// In en, this message translates to:
  /// **'WALLET MANAGER'**
  String get walletManagerLabel;

  /// No description provided for @walletSelectManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select wallet manager'**
  String get walletSelectManagerTitle;

  /// No description provided for @walletNoManagerApps.
  ///
  /// In en, this message translates to:
  /// **'No wallet manager apps bookmarked.\nBookmark an app with the \"wallet_manager\" category to use it here.'**
  String get walletNoManagerApps;

  /// No description provided for @walletEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get walletEditLabel;

  /// No description provided for @walletEditIcon.
  ///
  /// In en, this message translates to:
  /// **'Edit icon'**
  String get walletEditIcon;

  /// No description provided for @walletActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get walletActivityTitle;

  /// No description provided for @walletWatchOnlyCantSign.
  ///
  /// In en, this message translates to:
  /// **'Watch-only wallet: this device doesn\'t hold its key, so it can\'t sign.'**
  String get walletWatchOnlyCantSign;

  /// No description provided for @walletActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.\nRecent OX transfers will appear here.'**
  String get walletActivityEmpty;

  /// No description provided for @walletActivityTxCopied.
  ///
  /// In en, this message translates to:
  /// **'Transaction hash copied'**
  String get walletActivityTxCopied;

  /// No description provided for @walletActivitySentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to'**
  String get walletActivitySentTo;

  /// No description provided for @walletActivityReceivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from'**
  String get walletActivityReceivedFrom;

  /// No description provided for @walletRemoveWallet.
  ///
  /// In en, this message translates to:
  /// **'Remove wallet'**
  String get walletRemoveWallet;

  /// No description provided for @walletLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Wallet label'**
  String get walletLabelHint;

  /// No description provided for @walletSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get walletSave;

  /// No description provided for @walletLabelUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update label'**
  String get walletLabelUpdateFailed;

  /// No description provided for @walletLabelUpdateSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Label update submitted'**
  String get walletLabelUpdateSubmitted;

  /// No description provided for @walletRemoveWalletConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove wallet?'**
  String get walletRemoveWalletConfirmTitle;

  /// No description provided for @walletRemoveWalletBodyNoLabel.
  ///
  /// In en, this message translates to:
  /// **'This wallet will be removed from your directory.'**
  String get walletRemoveWalletBodyNoLabel;

  /// No description provided for @walletRemoveWalletBody.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be removed from your directory.'**
  String walletRemoveWalletBody(String label);

  /// No description provided for @walletRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get walletRemove;

  /// No description provided for @walletRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove wallet'**
  String get walletRemoveFailed;

  /// No description provided for @walletRemoved.
  ///
  /// In en, this message translates to:
  /// **'Wallet removed'**
  String get walletRemoved;

  /// No description provided for @walletChipLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get walletChipLinked;

  /// No description provided for @walletChipGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get walletChipGroup;

  /// No description provided for @walletChipManageKeys.
  ///
  /// In en, this message translates to:
  /// **'Manage Keys'**
  String get walletChipManageKeys;

  /// No description provided for @walletChipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get walletChipSettings;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Wallets Found'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your wallets will appear here.'**
  String get walletEmptySubtitle;

  /// No description provided for @walletLinkNewWallet.
  ///
  /// In en, this message translates to:
  /// **'Link new wallet'**
  String get walletLinkNewWallet;

  /// No description provided for @walletBadgePrimary.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get walletBadgePrimary;

  /// No description provided for @walletBadgeGroup.
  ///
  /// In en, this message translates to:
  /// **'GROUP'**
  String get walletBadgeGroup;

  /// No description provided for @walletBadgeKey.
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get walletBadgeKey;

  /// No description provided for @walletBadgeLinked.
  ///
  /// In en, this message translates to:
  /// **'LINKED'**
  String get walletBadgeLinked;

  /// No description provided for @walletUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get walletUnlink;

  /// No description provided for @walletActionSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get walletActionSend;

  /// No description provided for @walletActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get walletActionCopy;

  /// No description provided for @walletActionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get walletActionManage;

  /// No description provided for @walletOwnerUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get walletOwnerUnknown;

  /// No description provided for @walletNoManagerSelected.
  ///
  /// In en, this message translates to:
  /// **'No wallet manager selected'**
  String get walletNoManagerSelected;

  /// No description provided for @walletSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get walletSelect;

  /// No description provided for @walletChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get walletChange;

  /// No description provided for @walletChainLinkingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{chain} linking is coming soon.'**
  String walletChainLinkingComingSoon(String chain);

  /// No description provided for @walletConnectHeader.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get walletConnectHeader;

  /// No description provided for @walletLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Label · required'**
  String get walletLabelRequired;

  /// No description provided for @walletChainDetected.
  ///
  /// In en, this message translates to:
  /// **'{chain} detected'**
  String walletChainDetected(String chain);

  /// No description provided for @walletPickKeyError.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet key to link.'**
  String get walletPickKeyError;

  /// No description provided for @walletNoActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'No active account.'**
  String get walletNoActiveAccount;

  /// No description provided for @walletLinked.
  ///
  /// In en, this message translates to:
  /// **'Wallet linked'**
  String get walletLinked;

  /// No description provided for @walletPasteProofError.
  ///
  /// In en, this message translates to:
  /// **'Paste the proof from the signing page.'**
  String get walletPasteProofError;

  /// No description provided for @walletInvalidProofError.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid proof. Copy the whole “proof for PublicOS” from the signing page.'**
  String get walletInvalidProofError;

  /// No description provided for @walletProofMissingWalletSig.
  ///
  /// In en, this message translates to:
  /// **'Proof is missing the wallet or signature.'**
  String get walletProofMissingWalletSig;

  /// No description provided for @walletProofWrongAccount.
  ///
  /// In en, this message translates to:
  /// **'This proof was signed for a different account. Re-sign for this account.'**
  String get walletProofWrongAccount;

  /// No description provided for @walletProofBadBase58.
  ///
  /// In en, this message translates to:
  /// **'Signature is not valid base58.'**
  String get walletProofBadBase58;

  /// No description provided for @walletProofVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'This proof didn\'t verify for your account. Make sure you signed for this account on the linking page.'**
  String get walletProofVerifyFailed;

  /// No description provided for @walletSolanaLinked.
  ///
  /// In en, this message translates to:
  /// **'Solana wallet linked'**
  String get walletSolanaLinked;

  /// No description provided for @walletProofMissingFields.
  ///
  /// In en, this message translates to:
  /// **'Proof is missing the wallet, signature, or deadline.'**
  String get walletProofMissingFields;

  /// No description provided for @walletProofMalformed.
  ///
  /// In en, this message translates to:
  /// **'Proof is malformed.'**
  String get walletProofMalformed;

  /// No description provided for @walletInvalidProofBundle.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a valid proof bundle.'**
  String get walletInvalidProofBundle;

  /// No description provided for @walletProofNotEthereum.
  ///
  /// In en, this message translates to:
  /// **'That proof is not an Ethereum wallet proof.'**
  String get walletProofNotEthereum;

  /// No description provided for @walletLinkWithoutLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Link wallet without label?'**
  String get walletLinkWithoutLabelTitle;

  /// No description provided for @walletLinkWithoutLabelBody.
  ///
  /// In en, this message translates to:
  /// **'A label helps you tell this wallet apart from your others. You can still add one later.'**
  String get walletLinkWithoutLabelBody;

  /// No description provided for @walletLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get walletLink;

  /// No description provided for @walletLinkWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Link Wallet'**
  String get walletLinkWalletTitle;

  /// No description provided for @walletLinkExplainer.
  ///
  /// In en, this message translates to:
  /// **'Linking publishes an on-chain pointer saying a wallet is yours. Others can then pick one of your accounts to send you funds, and what you hold can show on your profile: tokens, and the NFTs that are how the chain records property. It stays a pointer. The protocol never gains access to the wallet.'**
  String get walletLinkExplainer;

  /// No description provided for @walletLabelOptional.
  ///
  /// In en, this message translates to:
  /// **'LABEL (optional)'**
  String get walletLabelOptional;

  /// No description provided for @walletLabelExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coinbase, Cold storage'**
  String get walletLabelExampleHint;

  /// No description provided for @walletLinkingAction.
  ///
  /// In en, this message translates to:
  /// **'LINKING…'**
  String get walletLinkingAction;

  /// No description provided for @walletLinkWalletAction.
  ///
  /// In en, this message translates to:
  /// **'LINK WALLET'**
  String get walletLinkWalletAction;

  /// No description provided for @walletSignOnBrowser.
  ///
  /// In en, this message translates to:
  /// **'Sign on browser'**
  String get walletSignOnBrowser;

  /// No description provided for @walletHidePaste.
  ///
  /// In en, this message translates to:
  /// **'Hide paste'**
  String get walletHidePaste;

  /// No description provided for @walletPasteProof.
  ///
  /// In en, this message translates to:
  /// **'Paste proof'**
  String get walletPasteProof;

  /// No description provided for @walletPasteBundleHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the proof bundle from the signing page'**
  String get walletPasteBundleHint;

  /// No description provided for @walletLinking.
  ///
  /// In en, this message translates to:
  /// **'Linking...'**
  String get walletLinking;

  /// No description provided for @walletLinkPastedProof.
  ///
  /// In en, this message translates to:
  /// **'Link pasted proof'**
  String get walletLinkPastedProof;

  /// No description provided for @walletNoKeychainKeys.
  ///
  /// In en, this message translates to:
  /// **'No keychain keys to link here. Use \"Link with MetaMask\" above to link an external wallet, or add a key to your keychain first.'**
  String get walletNoKeychainKeys;

  /// No description provided for @walletKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'WALLET KEY'**
  String get walletKeyLabel;

  /// No description provided for @walletKeyDefault.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get walletKeyDefault;

  /// No description provided for @walletPasteProofLabel.
  ///
  /// In en, this message translates to:
  /// **'PASTE PROOF'**
  String get walletPasteProofLabel;

  /// No description provided for @walletPasteProofBundleHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the “proof for PublicOS” bundle'**
  String get walletPasteProofBundleHint;

  /// No description provided for @walletOpenPhantom.
  ///
  /// In en, this message translates to:
  /// **'Open Phantom'**
  String get walletOpenPhantom;

  /// No description provided for @walletLinkMetaMask.
  ///
  /// In en, this message translates to:
  /// **'Link with MetaMask'**
  String get walletLinkMetaMask;

  /// No description provided for @walletOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get walletOr;

  /// No description provided for @walletCouldNotOpenPhantom.
  ///
  /// In en, this message translates to:
  /// **'Could not open Phantom. Is it installed?'**
  String get walletCouldNotOpenPhantom;

  /// No description provided for @walletDirectoryNotReady.
  ///
  /// In en, this message translates to:
  /// **'Wallet directory not ready, try again.'**
  String get walletDirectoryNotReady;

  /// No description provided for @walletCouldNotOpenLinkingPage.
  ///
  /// In en, this message translates to:
  /// **'Could not open the linking page'**
  String get walletCouldNotOpenLinkingPage;

  /// No description provided for @walletCouldNotOpenMetaMask.
  ///
  /// In en, this message translates to:
  /// **'Could not open MetaMask. Is it installed?'**
  String get walletCouldNotOpenMetaMask;

  /// No description provided for @walletChainComingSoonLong.
  ///
  /// In en, this message translates to:
  /// **'{chain} linking is coming soon. The directory already supports it on chain — the in-app signing flow lands after EVM.'**
  String walletChainComingSoonLong(String chain);

  /// No description provided for @acctSettingsSavingColor.
  ///
  /// In en, this message translates to:
  /// **'Saving color...'**
  String get acctSettingsSavingColor;

  /// No description provided for @acctSettingsRefreshingProfile.
  ///
  /// In en, this message translates to:
  /// **'Refreshing profile...'**
  String get acctSettingsRefreshingProfile;

  /// No description provided for @acctSettingsSessionAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Session address'**
  String get acctSettingsSessionAddressLabel;

  /// No description provided for @acctSettingsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String acctSettingsCopiedToClipboard(String label);

  /// No description provided for @acctSettingsRecoveryContacts.
  ///
  /// In en, this message translates to:
  /// **'Recovery Contacts'**
  String get acctSettingsRecoveryContacts;

  /// No description provided for @acctSettingsDevices.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get acctSettingsDevices;

  /// No description provided for @acctSettingsAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get acctSettingsAccentColor;

  /// No description provided for @accentColorRecordNotice.
  ///
  /// In en, this message translates to:
  /// **'Your accent color is a public profile record, kept on-chain. It tints your message bubbles and fills your profile cards, so anyone who can see your profile can see it.'**
  String get accentColorRecordNotice;

  /// No description provided for @accentColorBubbleNotice.
  ///
  /// In en, this message translates to:
  /// **'Your message bubbles are painted in it exactly as you pick it. Text switches between black and white to stay readable.'**
  String get accentColorBubbleNotice;

  /// No description provided for @accentColorPreviewSample.
  ///
  /// In en, this message translates to:
  /// **'This is how your messages will look.'**
  String get accentColorPreviewSample;

  /// No description provided for @accentColorPreviewTime.
  ///
  /// In en, this message translates to:
  /// **'12:45'**
  String get accentColorPreviewTime;

  /// No description provided for @accentColorSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE COLOR'**
  String get accentColorSave;

  /// No description provided for @accentColorDiscard.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get accentColorDiscard;

  /// No description provided for @accentColorSaved.
  ///
  /// In en, this message translates to:
  /// **'Accent color saved'**
  String get accentColorSaved;

  /// No description provided for @accentColorUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get accentColorUnsaved;

  /// No description provided for @acctSettingsNoAccountSelected.
  ///
  /// In en, this message translates to:
  /// **'No account selected'**
  String get acctSettingsNoAccountSelected;

  /// No description provided for @acctSettingsNoRecoveryContacts.
  ///
  /// In en, this message translates to:
  /// **'No recovery contacts configured'**
  String get acctSettingsNoRecoveryContacts;

  /// No description provided for @acctSettingsAddTrustedContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Add trusted contacts who can help recover your account'**
  String get acctSettingsAddTrustedContactsHint;

  /// No description provided for @acctSettingsRecoveryThreshold.
  ///
  /// In en, this message translates to:
  /// **'Recovery threshold: {threshold}/{total} contacts needed to approve recovery'**
  String acctSettingsRecoveryThreshold(int threshold, int total);

  /// No description provided for @acctSettingsNoSessionsFound.
  ///
  /// In en, this message translates to:
  /// **'No sessions found'**
  String get acctSettingsNoSessionsFound;

  /// No description provided for @acctSettingsSessionsDescShort.
  ///
  /// In en, this message translates to:
  /// **'Sessions are wallet addresses authorized to control your account'**
  String get acctSettingsSessionsDescShort;

  /// No description provided for @acctSettingsSessionsInfoBanner.
  ///
  /// In en, this message translates to:
  /// **'Sessions are keys that can act as your account. Each phone, computer or wallet you use holds its own.'**
  String get acctSettingsSessionsInfoBanner;

  /// No description provided for @acctSettingsCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get acctSettingsCurrentBadge;

  /// No description provided for @acctSettingsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This session'**
  String get acctSettingsThisDevice;

  /// No description provided for @acctSettingsAuthorizedDevice.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get acctSettingsAuthorizedDevice;

  /// No description provided for @acctSettingsCannotRemoveSession.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove - at least one session required'**
  String get acctSettingsCannotRemoveSession;

  /// No description provided for @acctSettingsAddingConfirming.
  ///
  /// In en, this message translates to:
  /// **'ADDING & CONFIRMING…'**
  String get acctSettingsAddingConfirming;

  /// No description provided for @acctSettingsAddSession.
  ///
  /// In en, this message translates to:
  /// **'ADD SESSION'**
  String get acctSettingsAddSession;

  /// No description provided for @acctSettingsAddNewSession.
  ///
  /// In en, this message translates to:
  /// **'Add New Session'**
  String get acctSettingsAddNewSession;

  /// No description provided for @acctSettingsLinkNewDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a session'**
  String get acctSettingsLinkNewDeviceTitle;

  /// No description provided for @acctSettingsLinkNewDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'On the other phone or computer, open PublicOS, tap the QR button on the new key\'s card, choose ADD SESSION and sign. Then scan that QR with this camera; the confirm sheet opens by itself.'**
  String get acctSettingsLinkNewDeviceBody;

  /// No description provided for @acctSettingsWhyQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Why a QR?'**
  String get acctSettingsWhyQrTitle;

  /// No description provided for @acctSettingsWhyQrBody.
  ///
  /// In en, this message translates to:
  /// **'The new session proves it agreed to be added by signing an EIP-712 consent with its own key. The QR carries that signature here, so you can submit it from a session you already have.'**
  String get acctSettingsWhyQrBody;

  /// No description provided for @acctSettingsRemoveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Session'**
  String get acctSettingsRemoveSessionTitle;

  /// No description provided for @acctSettingsRemoveSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this session?'**
  String get acctSettingsRemoveSessionConfirm;

  /// No description provided for @acctSettingsRemoveSessionWarning.
  ///
  /// In en, this message translates to:
  /// **'This session will no longer be able to act as your account.'**
  String get acctSettingsRemoveSessionWarning;

  /// No description provided for @acctSettingsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get acctSettingsRemove;

  /// No description provided for @acctSettingsSessionRemoved.
  ///
  /// In en, this message translates to:
  /// **'Session removed and confirmed on blockchain!'**
  String get acctSettingsSessionRemoved;

  /// No description provided for @acctSettingsAddRecoveryContact.
  ///
  /// In en, this message translates to:
  /// **'ADD RECOVERY CONTACT'**
  String get acctSettingsAddRecoveryContact;

  /// No description provided for @acctSettingsRecoveryContactAdded.
  ///
  /// In en, this message translates to:
  /// **'Recovery contact added and confirmed on blockchain!'**
  String get acctSettingsRecoveryContactAdded;

  /// No description provided for @acctSettingsRemoveRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Recovery Contact'**
  String get acctSettingsRemoveRecoveryTitle;

  /// No description provided for @acctSettingsRemoveRecoveryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this recovery contact?\n\nAddress: {address}\n\nThey will no longer be able to help recover your account.'**
  String acctSettingsRemoveRecoveryConfirm(String address);

  /// No description provided for @acctSettingsRecoveryContactRemoved.
  ///
  /// In en, this message translates to:
  /// **'Recovery contact removed and confirmed on blockchain!'**
  String get acctSettingsRecoveryContactRemoved;

  /// No description provided for @acctSettingsAddRecoveryContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Recovery Contact'**
  String get acctSettingsAddRecoveryContactTitle;

  /// No description provided for @acctSettingsAddRecoveryIntro.
  ///
  /// In en, this message translates to:
  /// **'You are about to add this contact as a recovery contact for your account:'**
  String get acctSettingsAddRecoveryIntro;

  /// No description provided for @acctSettingsRecoveryPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Contact Permissions'**
  String get acctSettingsRecoveryPermissionsTitle;

  /// No description provided for @acctSettingsRecoveryPermissionsBody.
  ///
  /// In en, this message translates to:
  /// **'This contact will be able to:\nVote to add new session addresses to your account\nHelp you recover access if you lose your device\nCannot access your funds or messages directly'**
  String get acctSettingsRecoveryPermissionsBody;

  /// No description provided for @acctSettingsSelectRecoveryContact.
  ///
  /// In en, this message translates to:
  /// **'Select Recovery Contact'**
  String get acctSettingsSelectRecoveryContact;

  /// No description provided for @acctSettingsChooseRecoveryContact.
  ///
  /// In en, this message translates to:
  /// **'Choose a Recovery Contact'**
  String get acctSettingsChooseRecoveryContact;

  /// No description provided for @acctSettingsChooseRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a trusted contact who can help you recover your account if you lose access. They will be able to vote on adding new session addresses to your account.'**
  String get acctSettingsChooseRecoveryDesc;

  /// No description provided for @acctSettingsSearchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts…'**
  String get acctSettingsSearchContacts;

  /// No description provided for @acctSettingsNoContactsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No contacts available'**
  String get acctSettingsNoContactsAvailable;

  /// No description provided for @acctSettingsNoContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get acctSettingsNoContactsFound;

  /// No description provided for @acctSettingsAddContactsFirst.
  ///
  /// In en, this message translates to:
  /// **'Add some contacts first to set them as recovery contacts'**
  String get acctSettingsAddContactsFirst;

  /// No description provided for @acctSettingsErrorEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter an address'**
  String get acctSettingsErrorEnterAddress;

  /// No description provided for @acctSettingsErrorInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Ethereum address format'**
  String get acctSettingsErrorInvalidAddress;

  /// No description provided for @acctSettingsErrorAddressAlreadySession.
  ///
  /// In en, this message translates to:
  /// **'This address is already a session'**
  String get acctSettingsErrorAddressAlreadySession;

  /// No description provided for @acctSettingsWhatIsSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'What is a Session?'**
  String get acctSettingsWhatIsSessionTitle;

  /// No description provided for @acctSettingsWhatIsSessionBody.
  ///
  /// In en, this message translates to:
  /// **'A session is a wallet address authorized to control your account. Add a new session to use your account from another device or wallet.'**
  String get acctSettingsWhatIsSessionBody;

  /// No description provided for @acctSettingsEthereumAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Ethereum Address'**
  String get acctSettingsEthereumAddressLabel;

  /// No description provided for @inboxIdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox IDs'**
  String get inboxIdsTitle;

  /// No description provided for @inboxIdsInboxesHeader.
  ///
  /// In en, this message translates to:
  /// **'Inboxes'**
  String get inboxIdsInboxesHeader;

  /// No description provided for @inboxIdsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load inbox IDs'**
  String get inboxIdsLoadError;

  /// No description provided for @inboxIdsRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get inboxIdsRetry;

  /// No description provided for @inboxIdsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No inbox IDs yet'**
  String get inboxIdsEmptyTitle;

  /// No description provided for @inboxIdsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an XMTP key from the keychain to get started.'**
  String get inboxIdsEmptySubtitle;

  /// No description provided for @inboxIdsNoLocalKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'No local key on this device'**
  String get inboxIdsNoLocalKeyTitle;

  /// No description provided for @inboxIdsNoLocalKeyBody.
  ///
  /// In en, this message translates to:
  /// **'This inbox is registered on your account but no private key for it lives on this device, so we can\'t load identities or installations. Import the key from another device (keychain or mnemonic) to manage it here.'**
  String get inboxIdsNoLocalKeyBody;

  /// No description provided for @inboxIdsNotSetUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Not set up on this device'**
  String get inboxIdsNotSetUpTitle;

  /// No description provided for @inboxIdsNotSetUpBody.
  ///
  /// In en, this message translates to:
  /// **'This key is on this device, but it isn\'t set up for messages here, so its inbox can\'t be shown. Select the key in the keychain to set it up.'**
  String get inboxIdsNotSetUpBody;

  /// No description provided for @inboxIdsLinkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked keys'**
  String get inboxIdsLinkedAccounts;

  /// No description provided for @inboxIdsInstallations.
  ///
  /// In en, this message translates to:
  /// **'Installations'**
  String get inboxIdsInstallations;

  /// No description provided for @inboxIdsQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get inboxIdsQuickActions;

  /// No description provided for @inboxIdsRecoveryBadge.
  ///
  /// In en, this message translates to:
  /// **'RECOVERY'**
  String get inboxIdsRecoveryBadge;

  /// No description provided for @inboxIdsThisDeviceBadge.
  ///
  /// In en, this message translates to:
  /// **'THIS DEVICE'**
  String get inboxIdsThisDeviceBadge;

  /// No description provided for @inboxIdsEthereumWallet.
  ///
  /// In en, this message translates to:
  /// **'Ethereum wallet'**
  String get inboxIdsEthereumWallet;

  /// No description provided for @inboxIdsPasskey.
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get inboxIdsPasskey;

  /// No description provided for @inboxIdsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get inboxIdsUnknown;

  /// No description provided for @inboxIdsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String inboxIdsDaysAgo(int count);

  /// No description provided for @inboxIdsHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String inboxIdsHoursAgo(int count);

  /// No description provided for @inboxIdsMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String inboxIdsMinutesAgo(int count);

  /// No description provided for @inboxIdsCreatedAgo.
  ///
  /// In en, this message translates to:
  /// **'Created {time}'**
  String inboxIdsCreatedAgo(String time);

  /// No description provided for @inboxIdsRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Inbox ID'**
  String get inboxIdsRegisterTitle;

  /// No description provided for @inboxIdsRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register this inbox to your on-chain profile.'**
  String get inboxIdsRegisterSubtitle;

  /// No description provided for @inboxIdsEditLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get inboxIdsEditLabelTitle;

  /// No description provided for @inboxIdsEditLabelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rename this inbox in your on-chain profile.'**
  String get inboxIdsEditLabelSubtitle;

  /// No description provided for @inboxTabNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No public inbox yet'**
  String get inboxTabNoneYet;

  /// No description provided for @inboxTabOtherOwner.
  ///
  /// In en, this message translates to:
  /// **'This inbox is already registered to another account.'**
  String get inboxTabOtherOwner;

  /// No description provided for @inboxTabSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save. Nothing was written to the chain.'**
  String get inboxTabSaveFailed;

  /// No description provided for @inboxTabDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already have a tab named {name}'**
  String inboxTabDuplicate(String name);

  /// No description provided for @inboxTabMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String inboxTabMore(int count);

  /// No description provided for @inboxIdsRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove tab'**
  String get inboxIdsRemoveTooltip;

  /// No description provided for @inboxIdsAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add tab'**
  String get inboxIdsAddTooltip;

  /// No description provided for @inboxIdsLabelHint.
  ///
  /// In en, this message translates to:
  /// **'main, work, …'**
  String get inboxIdsLabelHint;

  /// No description provided for @inboxIdsSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get inboxIdsSave;

  /// No description provided for @inboxIdsContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get inboxIdsContinue;

  /// No description provided for @inboxIdsRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove inbox ID?'**
  String get inboxIdsRemoveTitle;

  /// No description provided for @inboxIdsRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your on-chain profile. Other users will no longer see this inbox listed on your account.'**
  String inboxIdsRemoveBody(String name);

  /// No description provided for @inboxIdsRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get inboxIdsRemoveAction;

  /// No description provided for @inboxIdsRevokeInstallationTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this installation?'**
  String get inboxIdsRevokeInstallationTitle;

  /// No description provided for @inboxIdsRevokeInstallationBody.
  ///
  /// In en, this message translates to:
  /// **'This device will lose access to messages under this inbox.\n\n{id}'**
  String inboxIdsRevokeInstallationBody(String id);

  /// No description provided for @inboxIdsRevokeAction.
  ///
  /// In en, this message translates to:
  /// **'REVOKE'**
  String get inboxIdsRevokeAction;

  /// No description provided for @inboxIdsRevokeAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke all other installations?'**
  String get inboxIdsRevokeAllTitle;

  /// No description provided for @inboxIdsRevokeAllBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will revoke access for 1 other device. Those devices will need to re-authenticate to regain access.} other{This will revoke access for {count} other devices. Those devices will need to re-authenticate to regain access.}}'**
  String inboxIdsRevokeAllBody(int count);

  /// No description provided for @inboxIdsRevokeAllAction.
  ///
  /// In en, this message translates to:
  /// **'REVOKE ALL'**
  String get inboxIdsRevokeAllAction;

  /// No description provided for @inboxIdsRemoveAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove account from inbox?'**
  String get inboxIdsRemoveAccountTitle;

  /// No description provided for @inboxIdsRemoveAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the account from your inbox.\n\n{id}'**
  String inboxIdsRemoveAccountBody(String id);

  /// No description provided for @inboxIdsOfflineRecovery.
  ///
  /// In en, this message translates to:
  /// **'Offline recovery'**
  String get inboxIdsOfflineRecovery;

  /// No description provided for @inboxIdsOfflineRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'This revokes ALL installations for this inbox without needing an active XMTP client. Use when you\'re locked out due to too many installations (limit: 10).\n\nYou\'ll need to provide your recovery key.'**
  String get inboxIdsOfflineRecoveryBody;

  /// No description provided for @inboxIdsConfirmRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm recovery'**
  String get inboxIdsConfirmRecoveryTitle;

  /// No description provided for @inboxIdsConfirmRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 installation. All installations will be revoked. You will need to re-authenticate on any device you want to use.} other{Found {count} installations. All installations will be revoked. You will need to re-authenticate on any device you want to use.}}'**
  String inboxIdsConfirmRecoveryBody(int count);

  /// No description provided for @inboxIdsRevokingInstallations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Revoking 1 installation…} other{Revoking {count} installations…}}'**
  String inboxIdsRevokingInstallations(int count);

  /// No description provided for @inboxIdsRevokedInstallations.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Revoked 1 installation} other{Revoked {count} installations}}'**
  String inboxIdsRevokedInstallations(int count);

  /// No description provided for @inboxIdsKeyAlreadyLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Key already linked'**
  String get inboxIdsKeyAlreadyLinkedTitle;

  /// No description provided for @inboxIdsKeyAlreadyLinkedBodyKeychain.
  ///
  /// In en, this message translates to:
  /// **'This key is already linked to another XMTP inbox. If you proceed, it will be moved to your current inbox and you may lose access to the previous inbox unless you have another key linked to it.'**
  String get inboxIdsKeyAlreadyLinkedBodyKeychain;

  /// No description provided for @inboxIdsProceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'PROCEED ANYWAY'**
  String get inboxIdsProceedAnyway;

  /// No description provided for @inboxIdsKeyAlreadyLinkedBodyImport.
  ///
  /// In en, this message translates to:
  /// **'This key is already linked to another XMTP inbox. Proceeding will move it to your current inbox and you may lose access to the previous inbox.'**
  String get inboxIdsKeyAlreadyLinkedBodyImport;

  /// No description provided for @inboxIdsProceed.
  ///
  /// In en, this message translates to:
  /// **'PROCEED'**
  String get inboxIdsProceed;

  /// No description provided for @inboxIdsSelectRecoveryKey.
  ///
  /// In en, this message translates to:
  /// **'SELECT RECOVERY KEY'**
  String get inboxIdsSelectRecoveryKey;

  /// No description provided for @inboxIdsSelectKeyToLink.
  ///
  /// In en, this message translates to:
  /// **'SELECT KEY TO LINK'**
  String get inboxIdsSelectKeyToLink;

  /// No description provided for @inboxIdsSelectKey.
  ///
  /// In en, this message translates to:
  /// **'SELECT KEY'**
  String get inboxIdsSelectKey;

  /// No description provided for @inboxIdsKeyPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Multiple keys found. Select one to use for {purpose}.'**
  String inboxIdsKeyPickerSubtitle(String purpose);

  /// No description provided for @inboxIdsPurposeRevokeInstallation.
  ///
  /// In en, this message translates to:
  /// **'revoking installation'**
  String get inboxIdsPurposeRevokeInstallation;

  /// No description provided for @inboxIdsPurposeRevokeAllOthers.
  ///
  /// In en, this message translates to:
  /// **'revoking all other installations'**
  String get inboxIdsPurposeRevokeAllOthers;

  /// No description provided for @inboxIdsRecoveryKeyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'RECOVERY KEY'**
  String get inboxIdsRecoveryKeyDialogTitle;

  /// No description provided for @inboxIdsRecoveryKeyDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How would you like to provide the recovery key?'**
  String get inboxIdsRecoveryKeyDialogSubtitle;

  /// No description provided for @inboxIdsMethodPickKeychainTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick from keychain'**
  String get inboxIdsMethodPickKeychainTitle;

  /// No description provided for @inboxIdsMethodPickKeychainSubtitleShort.
  ///
  /// In en, this message translates to:
  /// **'Select an existing key'**
  String get inboxIdsMethodPickKeychainSubtitleShort;

  /// No description provided for @inboxIdsMethodPickKeychainSubtitleLong.
  ///
  /// In en, this message translates to:
  /// **'Select an existing key from your keychain'**
  String get inboxIdsMethodPickKeychainSubtitleLong;

  /// No description provided for @inboxIdsEnterPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Enter private key'**
  String get inboxIdsEnterPrivateKey;

  /// No description provided for @inboxIdsEnterMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Enter mnemonic'**
  String get inboxIdsEnterMnemonic;

  /// No description provided for @inboxIdsHintPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'0x…'**
  String get inboxIdsHintPrivateKey;

  /// No description provided for @inboxIdsHintMnemonic.
  ///
  /// In en, this message translates to:
  /// **'word1 word2 word3 …'**
  String get inboxIdsHintMnemonic;

  /// No description provided for @inboxIdsMethodPrivateKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hex-encoded private key'**
  String get inboxIdsMethodPrivateKeySubtitle;

  /// No description provided for @inboxIdsMethodMnemonicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'12 or 24 word recovery phrase'**
  String get inboxIdsMethodMnemonicSubtitle;

  /// No description provided for @inboxIdsAddAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'ADD KEY'**
  String get inboxIdsAddAccountTitle;

  /// No description provided for @inboxIdsAddAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Link another key to this inbox.'**
  String get inboxIdsAddAccountSubtitle;

  /// No description provided for @inboxIdsMethodImportKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Import key'**
  String get inboxIdsMethodImportKeyTitle;

  /// No description provided for @inboxIdsMethodImportKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import from mnemonic or private key'**
  String get inboxIdsMethodImportKeySubtitle;

  /// No description provided for @inboxIdsMethodQrTitle.
  ///
  /// In en, this message translates to:
  /// **'QR from another phone'**
  String get inboxIdsMethodQrTitle;

  /// No description provided for @inboxIdsMethodQrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'On the phone that holds the key: Keychain, open the key, Add to another inbox. Then scan its QR with this phone\'s camera.'**
  String get inboxIdsMethodQrSubtitle;

  /// No description provided for @linkKeyPickInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'ADD {address} TO WHICH INBOX?'**
  String linkKeyPickInboxTitle(String address);

  /// No description provided for @linkKeyNoInboxes.
  ///
  /// In en, this message translates to:
  /// **'This phone has no inbox to add the key to.'**
  String get linkKeyNoInboxes;

  /// No description provided for @linkKeyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'ADD KEY'**
  String get linkKeyConfirmTitle;

  /// No description provided for @linkKeyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to add {address} to inbox {inbox}?'**
  String linkKeyConfirmBody(String address, String inbox);

  /// No description provided for @linkKeyAddedTitle.
  ///
  /// In en, this message translates to:
  /// **'KEY ADDED'**
  String get linkKeyAddedTitle;

  /// No description provided for @linkKeyAddedBody.
  ///
  /// In en, this message translates to:
  /// **'{address} is now part of inbox {inbox}. This phone did not keep the key.\n\nOn the phone that showed the QR, open the keychain and tap Refresh.'**
  String linkKeyAddedBody(String address, String inbox);

  /// No description provided for @linkKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'This QR does not carry a valid key.'**
  String get linkKeyInvalid;

  /// No description provided for @linkKeyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get linkKeyAdd;

  /// No description provided for @keychainActionAddToInbox.
  ///
  /// In en, this message translates to:
  /// **'Add to another inbox'**
  String get keychainActionAddToInbox;

  /// No description provided for @keychainActionAddToInboxSub.
  ///
  /// In en, this message translates to:
  /// **'Show this key as a QR, to scan with your other phone and add it to an inbox there.'**
  String get keychainActionAddToInboxSub;

  /// No description provided for @keyQrWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'THIS QR IS YOUR KEY'**
  String get keyQrWarningTitle;

  /// No description provided for @keyQrWarningBody.
  ///
  /// In en, this message translates to:
  /// **'The QR carries this key itself. Anyone who scans it, or sees a photo of it, gets your key.\n\nDo not let anyone else see it. Do not take a photo or a screenshot of it, and do not share it. Scan it only with your own phone.\n\nIf this key is linked to another inbox, adding it to a new one moves it: the old inbox loses this key and the conversations it reached through it.'**
  String get keyQrWarningBody;

  /// No description provided for @keyQrTitle.
  ///
  /// In en, this message translates to:
  /// **'ADD {label} TO ANOTHER INBOX'**
  String keyQrTitle(String label);

  /// No description provided for @keyQrInstructions.
  ///
  /// In en, this message translates to:
  /// **'Scan this with your other phone\'s camera. PublicOS opens there and asks which inbox to add the key to. Then tap Refresh in this keychain.'**
  String get keyQrInstructions;

  /// No description provided for @keyQrNeverShare.
  ///
  /// In en, this message translates to:
  /// **'Never let anyone else see this QR.'**
  String get keyQrNeverShare;

  /// No description provided for @keychainRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh keys'**
  String get keychainRefresh;

  /// No description provided for @keychainRefreshDone.
  ///
  /// In en, this message translates to:
  /// **'Keys refreshed'**
  String get keychainRefreshDone;

  /// No description provided for @keychainRefreshMoved.
  ///
  /// In en, this message translates to:
  /// **'{labels} moved to another inbox'**
  String keychainRefreshMoved(String labels);

  /// No description provided for @inboxIdsImportKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'IMPORT KEY'**
  String get inboxIdsImportKeyTitle;

  /// No description provided for @inboxIdsMethodMnemonicPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Mnemonic phrase'**
  String get inboxIdsMethodMnemonicPhraseTitle;

  /// No description provided for @inboxIdsMethodPrivateKeyOptTitle.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get inboxIdsMethodPrivateKeyOptTitle;

  /// No description provided for @inboxIdsActionRegisterToProfile.
  ///
  /// In en, this message translates to:
  /// **'Register to profile'**
  String get inboxIdsActionRegisterToProfile;

  /// No description provided for @inboxIdsActionRenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Rename label'**
  String get inboxIdsActionRenameLabel;

  /// No description provided for @inboxIdsActionAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get inboxIdsActionAddAccount;

  /// No description provided for @inboxIdsActionSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get inboxIdsActionSyncing;

  /// No description provided for @inboxIdsActionSyncConsent.
  ///
  /// In en, this message translates to:
  /// **'Sync consent'**
  String get inboxIdsActionSyncConsent;

  /// No description provided for @inboxIdsActionRequesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting…'**
  String get inboxIdsActionRequesting;

  /// No description provided for @inboxIdsActionRequestHistory.
  ///
  /// In en, this message translates to:
  /// **'Request history'**
  String get inboxIdsActionRequestHistory;

  /// No description provided for @inboxIdsActionRevokeAllOthers.
  ///
  /// In en, this message translates to:
  /// **'Revoke all others'**
  String get inboxIdsActionRevokeAllOthers;

  /// No description provided for @inboxIdsActionRevoking.
  ///
  /// In en, this message translates to:
  /// **'Revoking…'**
  String get inboxIdsActionRevoking;

  /// No description provided for @inboxIdsInboxIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID copied'**
  String get inboxIdsInboxIdCopied;

  /// No description provided for @inboxIdsAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get inboxIdsAddressCopied;

  /// No description provided for @inboxIdsInstallationIdCopied.
  ///
  /// In en, this message translates to:
  /// **'Installation ID copied'**
  String get inboxIdsInstallationIdCopied;

  /// No description provided for @inboxIdsNoMatchingKeys.
  ///
  /// In en, this message translates to:
  /// **'No matching keys found in keychain'**
  String get inboxIdsNoMatchingKeys;

  /// No description provided for @inboxIdsRegistered.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID registered'**
  String get inboxIdsRegistered;

  /// No description provided for @inboxIdsRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to register inbox ID'**
  String get inboxIdsRegisterFailed;

  /// No description provided for @inboxIdsLabelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Label updated'**
  String get inboxIdsLabelUpdated;

  /// No description provided for @inboxIdsLabelUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update label'**
  String get inboxIdsLabelUpdateFailed;

  /// No description provided for @inboxIdsRemoved.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID removed'**
  String get inboxIdsRemoved;

  /// No description provided for @inboxIdsRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove inbox ID'**
  String get inboxIdsRemoveFailed;

  /// No description provided for @inboxIdsConsentSynced.
  ///
  /// In en, this message translates to:
  /// **'Consent preferences synced'**
  String get inboxIdsConsentSynced;

  /// No description provided for @inboxIdsConsentSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync consent preferences'**
  String get inboxIdsConsentSyncFailed;

  /// No description provided for @inboxIdsHistorySyncRequested.
  ///
  /// In en, this message translates to:
  /// **'History sync requested — other devices must be online to respond'**
  String get inboxIdsHistorySyncRequested;

  /// No description provided for @inboxIdsHistorySyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send history sync request'**
  String get inboxIdsHistorySyncFailed;

  /// No description provided for @inboxIdsNoSigningKey.
  ///
  /// In en, this message translates to:
  /// **'No signing key found for this inbox'**
  String get inboxIdsNoSigningKey;

  /// No description provided for @inboxIdsInstallationRevoked.
  ///
  /// In en, this message translates to:
  /// **'Installation revoked'**
  String get inboxIdsInstallationRevoked;

  /// No description provided for @inboxIdsInstallationRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke installation'**
  String get inboxIdsInstallationRevokeFailed;

  /// No description provided for @inboxIdsAllOthersRevoked.
  ///
  /// In en, this message translates to:
  /// **'All other installations revoked'**
  String get inboxIdsAllOthersRevoked;

  /// No description provided for @inboxIdsRevokeInstallationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to revoke installations'**
  String get inboxIdsRevokeInstallationsFailed;

  /// No description provided for @inboxIdsRecoveryKeyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recovery key not found in keychain'**
  String get inboxIdsRecoveryKeyNotFound;

  /// No description provided for @inboxIdsAccountRemoved.
  ///
  /// In en, this message translates to:
  /// **'Account removed'**
  String get inboxIdsAccountRemoved;

  /// No description provided for @inboxIdsAccountRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove account'**
  String get inboxIdsAccountRemoveFailed;

  /// No description provided for @inboxIdsNoKeysInKeychain.
  ///
  /// In en, this message translates to:
  /// **'No keys in keychain'**
  String get inboxIdsNoKeysInKeychain;

  /// No description provided for @inboxIdsInvalidKeyFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid key format'**
  String get inboxIdsInvalidKeyFormat;

  /// No description provided for @inboxIdsQueryingInboxState.
  ///
  /// In en, this message translates to:
  /// **'Querying inbox state…'**
  String get inboxIdsQueryingInboxState;

  /// No description provided for @inboxIdsInboxNotFound.
  ///
  /// In en, this message translates to:
  /// **'Inbox not found'**
  String get inboxIdsInboxNotFound;

  /// No description provided for @inboxIdsNoInstallationsToRevoke.
  ///
  /// In en, this message translates to:
  /// **'No installations to revoke'**
  String get inboxIdsNoInstallationsToRevoke;

  /// No description provided for @inboxIdsUserAddressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'User address not available'**
  String get inboxIdsUserAddressUnavailable;

  /// No description provided for @inboxIdsNoAvailableKeys.
  ///
  /// In en, this message translates to:
  /// **'No available keys in keychain'**
  String get inboxIdsNoAvailableKeys;

  /// No description provided for @inboxIdsAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Key added'**
  String get inboxIdsAccountAdded;

  /// No description provided for @inboxIdsAccountAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add key'**
  String get inboxIdsAccountAddFailed;

  /// No description provided for @inboxIdsErrorInvalidKeyFormat.
  ///
  /// In en, this message translates to:
  /// **'Error: invalid key format'**
  String get inboxIdsErrorInvalidKeyFormat;

  /// No description provided for @postCardTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get postCardTranslating;

  /// No description provided for @postCardWaitingForWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi…'**
  String get postCardWaitingForWifi;

  /// No description provided for @postCardDownloadingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Downloading language…'**
  String get postCardDownloadingLanguage;

  /// No description provided for @postCardDownloadLangPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Download language pack?'**
  String get postCardDownloadLangPackTitle;

  /// No description provided for @postCardDownloadLangPackBody.
  ///
  /// In en, this message translates to:
  /// **'Translating {from} → {to} needs an offline language pack (~30 MB each, downloaded once, then fully on-device).'**
  String postCardDownloadLangPackBody(String from, String to);

  /// No description provided for @postCardDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get postCardDownload;

  /// No description provided for @postCardTranslateFrom.
  ///
  /// In en, this message translates to:
  /// **'Translate from {lang}'**
  String postCardTranslateFrom(String lang);

  /// No description provided for @postCardTranslatedFromShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Translated from {lang} · Show original'**
  String postCardTranslatedFromShowOriginal(String lang);

  /// No description provided for @postCardShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation ({lang})'**
  String postCardShowTranslation(String lang);

  /// No description provided for @postCardOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get postCardOpenLink;

  /// No description provided for @postCardEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get postCardEdited;

  /// No description provided for @postCardVia.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get postCardVia;

  /// No description provided for @postCardEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get postCardEditPost;

  /// No description provided for @postCardRemoveFromChannel.
  ///
  /// In en, this message translates to:
  /// **'Remove from channel'**
  String get postCardRemoveFromChannel;

  /// No description provided for @postCardDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get postCardDeletePost;

  /// No description provided for @postCardUnlockComments.
  ///
  /// In en, this message translates to:
  /// **'Unlock comments'**
  String get postCardUnlockComments;

  /// No description provided for @postCardLockComments.
  ///
  /// In en, this message translates to:
  /// **'Lock comments'**
  String get postCardLockComments;

  /// No description provided for @postCardCommentRules.
  ///
  /// In en, this message translates to:
  /// **'Comment rules'**
  String get postCardCommentRules;

  /// No description provided for @postCardCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get postCardCopyLink;

  /// No description provided for @postCardRefreshPost.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get postCardRefreshPost;

  /// No description provided for @postsListPostRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Post refreshed'**
  String get postsListPostRefreshed;

  /// No description provided for @postsListPostRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh this post'**
  String get postsListPostRefreshFailed;

  /// No description provided for @postCardNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available on the server — your saved copy may be the only one left'**
  String get postCardNoLongerAvailable;

  /// No description provided for @postCardRemoveFeedFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove feed from list'**
  String get postCardRemoveFeedFromList;

  /// No description provided for @postCardMuteChannel.
  ///
  /// In en, this message translates to:
  /// **'Mute channel'**
  String get postCardMuteChannel;

  /// No description provided for @postCardViewSource.
  ///
  /// In en, this message translates to:
  /// **'View source'**
  String get postCardViewSource;

  /// No description provided for @postCardNoShareLink.
  ///
  /// In en, this message translates to:
  /// **'No share link available for this post yet'**
  String get postCardNoShareLink;

  /// No description provided for @postCardLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get postCardLinkCopied;

  /// No description provided for @postCardCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link: {link}'**
  String postCardCouldNotOpenLink(String link);

  /// No description provided for @postCardCannotLockMissingSlug.
  ///
  /// In en, this message translates to:
  /// **'Cannot lock comments: missing channel slug'**
  String get postCardCannotLockMissingSlug;

  /// No description provided for @postCardCommentsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Comments unlocked'**
  String get postCardCommentsUnlocked;

  /// No description provided for @postCardCommentsLocked.
  ///
  /// In en, this message translates to:
  /// **'Comments locked'**
  String get postCardCommentsLocked;

  /// No description provided for @postCardUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {message}'**
  String postCardUpdateFailed(String message);

  /// No description provided for @postCardUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get postCardUnknownError;

  /// No description provided for @postCardMissingChannelInfo.
  ///
  /// In en, this message translates to:
  /// **'This post is missing channel info'**
  String get postCardMissingChannelInfo;

  /// No description provided for @postCardThisFeed.
  ///
  /// In en, this message translates to:
  /// **'this feed'**
  String get postCardThisFeed;

  /// No description provided for @postCardRemoveFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Feed from List'**
  String get postCardRemoveFeedTitle;

  /// No description provided for @postCardRemoveFeedBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{feedTitle}\" from this list?\n\nAll posts from this feed will be removed from the list view.'**
  String postCardRemoveFeedBody(String feedTitle);

  /// No description provided for @postCardRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get postCardRemove;

  /// No description provided for @postCardRemoveFromChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from channel?'**
  String get postCardRemoveFromChannelTitle;

  /// No description provided for @postCardDeletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get postCardDeletePostTitle;

  /// No description provided for @postCardDeleteBodyModeration.
  ///
  /// In en, this message translates to:
  /// **'This removes the post and all comments under it from #{channel}. The author will lose their post. Cannot be undone.'**
  String postCardDeleteBodyModeration(String channel);

  /// No description provided for @postCardDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the post and all comments under it. Cannot be undone.'**
  String get postCardDeleteBody;

  /// No description provided for @postCardThisChannel.
  ///
  /// In en, this message translates to:
  /// **'this channel'**
  String get postCardThisChannel;

  /// No description provided for @postCardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get postCardDelete;

  /// No description provided for @postCardCannotDeleteMissingSlug.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete post: missing channel slug'**
  String get postCardCannotDeleteMissingSlug;

  /// No description provided for @postCardPostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted successfully'**
  String get postCardPostDeleted;

  /// No description provided for @postCardDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete post: {message}'**
  String postCardDeleteFailed(String message);

  /// No description provided for @accountCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountCenterTitle;

  /// No description provided for @accountCenterSessionRemoved.
  ///
  /// In en, this message translates to:
  /// **'Session removed'**
  String get accountCenterSessionRemoved;

  /// No description provided for @accountCenterAddNewSession.
  ///
  /// In en, this message translates to:
  /// **'Add New Session'**
  String get accountCenterAddNewSession;

  /// No description provided for @accountCenterLinkNewDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a session'**
  String get accountCenterLinkNewDeviceTitle;

  /// No description provided for @accountCenterLinkNewDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'On the other phone or computer, open PublicOS, tap the QR button on the new key\'s card, choose ADD SESSION and sign. Then scan that QR with this camera; the confirm sheet opens by itself.'**
  String get accountCenterLinkNewDeviceBody;

  /// No description provided for @accountCenterWhyQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Why a QR?'**
  String get accountCenterWhyQrTitle;

  /// No description provided for @accountCenterWhyQrBody.
  ///
  /// In en, this message translates to:
  /// **'The new session proves it agreed to be added by signing an EIP-712 consent with its own key. The QR carries that signature here, so you can submit it from a session you already have.'**
  String get accountCenterWhyQrBody;

  /// No description provided for @accountCenterRemoveSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Session'**
  String get accountCenterRemoveSessionTitle;

  /// No description provided for @accountCenterRemoveSessionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this session?'**
  String get accountCenterRemoveSessionConfirm;

  /// No description provided for @accountCenterRemoveSessionWarning.
  ///
  /// In en, this message translates to:
  /// **'This session will no longer be able to act as your account.'**
  String get accountCenterRemoveSessionWarning;

  /// No description provided for @accountCenterRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get accountCenterRemove;

  /// No description provided for @accountCenterNoAccountAddress.
  ///
  /// In en, this message translates to:
  /// **'No account address found'**
  String get accountCenterNoAccountAddress;

  /// No description provided for @accountCenterRecoveryStatusError.
  ///
  /// In en, this message translates to:
  /// **'Could not check recovery status'**
  String get accountCenterRecoveryStatusError;

  /// No description provided for @accountCenterStartRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Recovery'**
  String get accountCenterStartRecoveryTitle;

  /// No description provided for @accountCenterScanRecoveryQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan their recovery QR'**
  String get accountCenterScanRecoveryQrTitle;

  /// No description provided for @accountCenterScanRecoveryQrBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the person to open PublicOS on their new phone or computer and show the QR of a new key (the same code used to add a session). Scan it with your camera. If you are one of their recovery contacts, you can start the vote that gives their account that new session.'**
  String get accountCenterScanRecoveryQrBody;

  /// No description provided for @accountCenterRecoveryVoteStarted.
  ///
  /// In en, this message translates to:
  /// **'Recovery vote started'**
  String get accountCenterRecoveryVoteStarted;

  /// No description provided for @accountCenterVotedApprove.
  ///
  /// In en, this message translates to:
  /// **'Voted to approve recovery'**
  String get accountCenterVotedApprove;

  /// No description provided for @accountCenterVotedReject.
  ///
  /// In en, this message translates to:
  /// **'Voted to reject recovery'**
  String get accountCenterVotedReject;

  /// No description provided for @accountCenterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get accountCenterExpired;

  /// No description provided for @accountCenterRemainingDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d {hours}h remaining'**
  String accountCenterRemainingDays(int days, int hours);

  /// No description provided for @accountCenterRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m remaining'**
  String accountCenterRemainingHours(int hours, int minutes);

  /// No description provided for @accountCenterRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m remaining'**
  String accountCenterRemainingMinutes(int minutes);

  /// No description provided for @accountCenterUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get accountCenterUnknown;

  /// No description provided for @accountCenterStatusLifetime.
  ///
  /// In en, this message translates to:
  /// **'LIFETIME'**
  String get accountCenterStatusLifetime;

  /// No description provided for @accountCenterStatusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get accountCenterStatusActive;

  /// No description provided for @accountCenterStatusNotSet.
  ///
  /// In en, this message translates to:
  /// **'NOT SET'**
  String get accountCenterStatusNotSet;

  /// No description provided for @accountCenterStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get accountCenterStatusOverdue;

  /// No description provided for @accountCenterNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get accountCenterNever;

  /// No description provided for @accountCenterNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get accountCenterNone;

  /// No description provided for @accountCenterDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get accountCenterDomain;

  /// No description provided for @accountCenterAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get accountCenterAddressCopied;

  /// No description provided for @accountCenterCitizen.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get accountCenterCitizen;

  /// No description provided for @citizenClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re eligible for citizenship!'**
  String get citizenClaimTitle;

  /// No description provided for @citizenClaimLead.
  ///
  /// In en, this message translates to:
  /// **'Enough citizens vouched for you. Read the citizen agreement to the end; accepting it is what makes you a citizen.'**
  String get citizenClaimLead;

  /// No description provided for @citizenClaimVersion.
  ///
  /// In en, this message translates to:
  /// **'Citizen agreement · version {version}'**
  String citizenClaimVersion(String version);

  /// No description provided for @citizenClaimScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the end to accept'**
  String get citizenClaimScrollHint;

  /// No description provided for @citizenClaimAccept.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT AND CLAIM'**
  String get citizenClaimAccept;

  /// No description provided for @citizenClaimClaiming.
  ///
  /// In en, this message translates to:
  /// **'CLAIMING'**
  String get citizenClaimClaiming;

  /// No description provided for @citizenClaimDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'You are a citizen'**
  String get citizenClaimDoneTitle;

  /// No description provided for @citizenClaimDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Your domain name is free for life, you have a seat and a vote in the PublicOS org, and you can vouch for people you know in person.'**
  String get citizenClaimDoneBody;

  /// No description provided for @citizenClaimContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get citizenClaimContinue;

  /// No description provided for @citizenClaimFailed.
  ///
  /// In en, this message translates to:
  /// **'The claim did not go through.'**
  String get citizenClaimFailed;

  /// No description provided for @citizenClaimRetry.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get citizenClaimRetry;

  /// No description provided for @citizenClaimNeedsPermanentKey.
  ///
  /// In en, this message translates to:
  /// **'Claiming needs a permanent key. This session expires; open PublicOS with your main key and claim there.'**
  String get citizenClaimNeedsPermanentKey;

  /// No description provided for @citizenClaimLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The agreement could not be loaded. Check your connection and try again.'**
  String get citizenClaimLoadFailed;

  /// No description provided for @citizenClaimNothingPublished.
  ///
  /// In en, this message translates to:
  /// **'No citizen agreement is published yet. Try again later.'**
  String get citizenClaimNothingPublished;

  /// No description provided for @protocolAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'The PublicOS agreement'**
  String get protocolAgreementTitle;

  /// No description provided for @protocolAgreementLead.
  ///
  /// In en, this message translates to:
  /// **'Your new account accepts this agreement: your new key signs it when the account is made. Read it to the end.'**
  String get protocolAgreementLead;

  /// No description provided for @protocolAgreementVersion.
  ///
  /// In en, this message translates to:
  /// **'Protocol agreement · version {version}'**
  String protocolAgreementVersion(String version);

  /// No description provided for @protocolAgreementScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the end to accept'**
  String get protocolAgreementScrollHint;

  /// No description provided for @protocolAgreementAccept.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT AND CONTINUE'**
  String get protocolAgreementAccept;

  /// No description provided for @protocolAgreementAgeCheck.
  ///
  /// In en, this message translates to:
  /// **'I am 16 or older, and old enough where I live to accept this on my own.'**
  String get protocolAgreementAgeCheck;

  /// No description provided for @protocolAgreementLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The agreement could not be loaded. Check your connection and try again.'**
  String get protocolAgreementLoadFailed;

  /// No description provided for @noticeServicesRow.
  ///
  /// In en, this message translates to:
  /// **'Send SSP notice'**
  String get noticeServicesRow;

  /// No description provided for @noticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Send SSP notice'**
  String get noticeTitle;

  /// No description provided for @noticeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search an SSP by name or address'**
  String get noticeSearchHint;

  /// No description provided for @noticeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No SSP matches.'**
  String get noticeNoResults;

  /// No description provided for @noticeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The SSP list could not be loaded.'**
  String get noticeLoadFailed;

  /// No description provided for @noticeNoKey.
  ///
  /// In en, this message translates to:
  /// **'This SSP does not take notices yet.'**
  String get noticeNoKey;

  /// No description provided for @noticeChange.
  ///
  /// In en, this message translates to:
  /// **'CHANGE'**
  String get noticeChange;

  /// No description provided for @noticeTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'What is it about?'**
  String get noticeTypeLabel;

  /// No description provided for @noticeTypeTakedown.
  ///
  /// In en, this message translates to:
  /// **'Takedown'**
  String get noticeTypeTakedown;

  /// No description provided for @noticeTypeLawfulOrder.
  ///
  /// In en, this message translates to:
  /// **'Lawful order'**
  String get noticeTypeLawfulOrder;

  /// No description provided for @noticeTypeIpClaim.
  ///
  /// In en, this message translates to:
  /// **'IP claim'**
  String get noticeTypeIpClaim;

  /// No description provided for @noticeTypeAppeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get noticeTypeAppeal;

  /// No description provided for @noticeTypeAbuseReport.
  ///
  /// In en, this message translates to:
  /// **'Abuse report'**
  String get noticeTypeAbuseReport;

  /// No description provided for @noticeTypePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get noticeTypePrivacy;

  /// No description provided for @noticeTypeIntimateImage.
  ///
  /// In en, this message translates to:
  /// **'Intimate image'**
  String get noticeTypeIntimateImage;

  /// No description provided for @noticeTypeChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get noticeTypeChildSafety;

  /// No description provided for @noticeAboutHint.
  ///
  /// In en, this message translates to:
  /// **'Link to the post or page (optional)'**
  String get noticeAboutHint;

  /// No description provided for @noticeTextHint.
  ///
  /// In en, this message translates to:
  /// **'Write your notice'**
  String get noticeTextHint;

  /// No description provided for @noticeOnChainNote.
  ///
  /// In en, this message translates to:
  /// **'Filed on chain as public evidence: your address will be visible. The letter itself stays encrypted.'**
  String get noticeOnChainNote;

  /// No description provided for @noticeOffChainNote.
  ///
  /// In en, this message translates to:
  /// **'Kept off chain: only the SSP operator can read it.'**
  String get noticeOffChainNote;

  /// No description provided for @noticeSend.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get noticeSend;

  /// No description provided for @noticeSending.
  ///
  /// In en, this message translates to:
  /// **'SENDING'**
  String get noticeSending;

  /// No description provided for @noticeSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Notice sent'**
  String get noticeSentTitle;

  /// No description provided for @noticeSentBody.
  ///
  /// In en, this message translates to:
  /// **'{ssp} received it.'**
  String noticeSentBody(String ssp);

  /// No description provided for @noticeSentOnChain.
  ///
  /// In en, this message translates to:
  /// **'Filed on chain as notice #{id}.'**
  String noticeSentOnChain(String id);

  /// No description provided for @noticeFailed.
  ///
  /// In en, this message translates to:
  /// **'The notice could not be sent.'**
  String get noticeFailed;

  /// No description provided for @noticeDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get noticeDone;

  /// No description provided for @chsSubOtherChannels.
  ///
  /// In en, this message translates to:
  /// **'From other channels'**
  String get chsSubOtherChannels;

  /// No description provided for @chsAllowQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get chsAllowQuotes;

  /// No description provided for @chsAllowQuotesSub.
  ///
  /// In en, this message translates to:
  /// **'Others can quote these posts in their own channels.'**
  String get chsAllowQuotesSub;

  /// No description provided for @chsAllowReposts.
  ///
  /// In en, this message translates to:
  /// **'Reposts'**
  String get chsAllowReposts;

  /// No description provided for @chsAllowRepostsSub.
  ///
  /// In en, this message translates to:
  /// **'Others can repost them to their channels.'**
  String get chsAllowRepostsSub;

  /// No description provided for @chsAllowReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get chsAllowReplies;

  /// No description provided for @chsAllowRepliesSub.
  ///
  /// In en, this message translates to:
  /// **'Others can answer with a post in their own channel.'**
  String get chsAllowRepliesSub;

  /// No description provided for @accountCenterClaimCitizenship.
  ///
  /// In en, this message translates to:
  /// **'CLAIM CITIZENSHIP'**
  String get accountCenterClaimCitizenship;

  /// No description provided for @accountCenterRenounceSection.
  ///
  /// In en, this message translates to:
  /// **'Leave citizenship'**
  String get accountCenterRenounceSection;

  /// No description provided for @accountCenterRenounceBody.
  ///
  /// In en, this message translates to:
  /// **'You can give up citizenship at any time. It is immediate and cannot be undone. The vouches you gave, and your word for those people, stay.'**
  String get accountCenterRenounceBody;

  /// No description provided for @accountCenterRenounceButton.
  ///
  /// In en, this message translates to:
  /// **'RENOUNCE CITIZENSHIP'**
  String get accountCenterRenounceButton;

  /// No description provided for @renounceDlg1Title.
  ///
  /// In en, this message translates to:
  /// **'Renounce citizenship?'**
  String get renounceDlg1Title;

  /// No description provided for @renounceDlg1Lead.
  ///
  /// In en, this message translates to:
  /// **'Read this first. All of it happens in one step, the moment it lands:'**
  String get renounceDlg1Lead;

  /// No description provided for @renounceCostName.
  ///
  /// In en, this message translates to:
  /// **'Your domain name stops being free now. Pay it to keep using the account.'**
  String get renounceCostName;

  /// No description provided for @renounceCostShare.
  ///
  /// In en, this message translates to:
  /// **'Your unclaimed share is forfeited. Claim it first, in Services.'**
  String get renounceCostShare;

  /// No description provided for @renounceCostSubs.
  ///
  /// In en, this message translates to:
  /// **'Unsettled subscriptions bill you as a private. Settle them first.'**
  String get renounceCostSubs;

  /// No description provided for @renounceCostGraph.
  ///
  /// In en, this message translates to:
  /// **'You leave the social graph: the vouches you received are cleared. Coming back needs new vouches.'**
  String get renounceCostGraph;

  /// No description provided for @renounceCostSeat.
  ///
  /// In en, this message translates to:
  /// **'Your seat and vote in the PublicOS org end.'**
  String get renounceCostSeat;

  /// No description provided for @renounceCostVouches.
  ///
  /// In en, this message translates to:
  /// **'The vouches you gave stay, and so does your word for those people.'**
  String get renounceCostVouches;

  /// No description provided for @renounceWait.
  ///
  /// In en, this message translates to:
  /// **'RENOUNCE · {seconds}'**
  String renounceWait(String seconds);

  /// No description provided for @renounceDlg1Confirm.
  ///
  /// In en, this message translates to:
  /// **'RENOUNCE'**
  String get renounceDlg1Confirm;

  /// No description provided for @renounceKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP CITIZENSHIP'**
  String get renounceKeep;

  /// No description provided for @renounceDlg2Title.
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get renounceDlg2Title;

  /// No description provided for @renounceDlg2Body.
  ///
  /// In en, this message translates to:
  /// **'This is the one that does it. There is no undo and no grace.'**
  String get renounceDlg2Body;

  /// No description provided for @renounceDlg2Confirm.
  ///
  /// In en, this message translates to:
  /// **'RENOUNCE CITIZENSHIP NOW'**
  String get renounceDlg2Confirm;

  /// No description provided for @vouchDlg1Title.
  ///
  /// In en, this message translates to:
  /// **'Vouch for {name}?'**
  String vouchDlg1Title(String name);

  /// No description provided for @vouchDlg1Lead.
  ///
  /// In en, this message translates to:
  /// **'This is the most important thing you do on PublicOS. Read all of it:'**
  String get vouchDlg1Lead;

  /// No description provided for @vouchPointInPerson.
  ///
  /// In en, this message translates to:
  /// **'You declare that you know {name} in person: a real, living person of legal age whose name you can say.'**
  String vouchPointInPerson(String name);

  /// No description provided for @vouchPointOneAccount.
  ///
  /// In en, this message translates to:
  /// **'To your knowledge, they hold no other citizen account.'**
  String get vouchPointOneAccount;

  /// No description provided for @vouchPointTrust.
  ///
  /// In en, this message translates to:
  /// **'Your rights as a citizen rest on the trust of the people who vouched for you. This vouch passes that trust on.'**
  String get vouchPointTrust;

  /// No description provided for @vouchPointFinal.
  ///
  /// In en, this message translates to:
  /// **'A vouch can\'t be taken back.'**
  String get vouchPointFinal;

  /// No description provided for @vouchPointCharacter.
  ///
  /// In en, this message translates to:
  /// **'It says nothing about their character, and you are not responsible for what they do.'**
  String get vouchPointCharacter;

  /// No description provided for @vouchPointIdentify.
  ///
  /// In en, this message translates to:
  /// **'If a lawful order requires it, you will say what you know about who they are.'**
  String get vouchPointIdentify;

  /// No description provided for @vouchPointConsequence.
  ///
  /// In en, this message translates to:
  /// **'A false vouch costs your citizenship, and root may suspend your account. It is recorded on chain, where anyone can see it.'**
  String get vouchPointConsequence;

  /// No description provided for @vouchWait.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE · {seconds}'**
  String vouchWait(String seconds);

  /// No description provided for @vouchDlg1Confirm.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get vouchDlg1Confirm;

  /// No description provided for @vouchCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get vouchCancel;

  /// No description provided for @vouchDlg2Title.
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get vouchDlg2Title;

  /// No description provided for @vouchDlg2Body.
  ///
  /// In en, this message translates to:
  /// **'You are giving your word that {name} is a real person you know. There is no undo.'**
  String vouchDlg2Body(String name);

  /// No description provided for @vouchDlg2Cancel.
  ///
  /// In en, this message translates to:
  /// **'DON\'T VOUCH'**
  String get vouchDlg2Cancel;

  /// No description provided for @vouchDlg2Confirm.
  ///
  /// In en, this message translates to:
  /// **'VOUCH NOW'**
  String get vouchDlg2Confirm;

  /// No description provided for @renounceWorking.
  ///
  /// In en, this message translates to:
  /// **'Renouncing citizenship…'**
  String get renounceWorking;

  /// No description provided for @renounceDone.
  ///
  /// In en, this message translates to:
  /// **'You are no longer a citizen.'**
  String get renounceDone;

  /// No description provided for @renounceFailed.
  ///
  /// In en, this message translates to:
  /// **'The renounce did not go through.'**
  String get renounceFailed;

  /// No description provided for @renounceNeedsPermanentKey.
  ///
  /// In en, this message translates to:
  /// **'Renouncing needs a permanent key. This session expires; use your main key.'**
  String get renounceNeedsPermanentKey;

  /// No description provided for @accountCenterDomainStatus.
  ///
  /// In en, this message translates to:
  /// **'Domain status'**
  String get accountCenterDomainStatus;

  /// No description provided for @accountCenterPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get accountCenterPaidUntil;

  /// No description provided for @accountCenterFreeNameChanges.
  ///
  /// In en, this message translates to:
  /// **'Free Name Changes'**
  String get accountCenterFreeNameChanges;

  /// No description provided for @accountCenterManageDomain.
  ///
  /// In en, this message translates to:
  /// **'MANAGE DOMAIN'**
  String get accountCenterManageDomain;

  /// No description provided for @accountCenterDevices.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get accountCenterDevices;

  /// No description provided for @accountCenterSessionsInfo.
  ///
  /// In en, this message translates to:
  /// **'Sessions are wallet addresses that can act on behalf of your account.'**
  String get accountCenterSessionsInfo;

  /// No description provided for @accountCenterCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get accountCenterCurrent;

  /// No description provided for @accountCenterAdding.
  ///
  /// In en, this message translates to:
  /// **'ADDING...'**
  String get accountCenterAdding;

  /// No description provided for @accountCenterAddSession.
  ///
  /// In en, this message translates to:
  /// **'ADD SESSION'**
  String get accountCenterAddSession;

  /// No description provided for @accountCenterHelpFriendRecover.
  ///
  /// In en, this message translates to:
  /// **'Help a Friend Recover'**
  String get accountCenterHelpFriendRecover;

  /// No description provided for @accountCenterRecoveryInfo.
  ///
  /// In en, this message translates to:
  /// **'If a friend loses access to their account and you\'re one of their recovery contacts, you can help them regain control.'**
  String get accountCenterRecoveryInfo;

  /// No description provided for @accountCenterSelectFriend.
  ///
  /// In en, this message translates to:
  /// **'SELECT FRIEND'**
  String get accountCenterSelectFriend;

  /// No description provided for @accountCenterCheckingRecoveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking recovery status...'**
  String get accountCenterCheckingRecoveryStatus;

  /// No description provided for @accountCenterRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get accountCenterRetry;

  /// No description provided for @accountCenterChange.
  ///
  /// In en, this message translates to:
  /// **'CHANGE'**
  String get accountCenterChange;

  /// No description provided for @accountCenterNotRecoveryContact.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a recovery contact for this account'**
  String get accountCenterNotRecoveryContact;

  /// No description provided for @accountCenterChangeFriend.
  ///
  /// In en, this message translates to:
  /// **'CHANGE FRIEND'**
  String get accountCenterChangeFriend;

  /// No description provided for @accountCenterActiveVote.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE VOTE'**
  String get accountCenterActiveVote;

  /// No description provided for @accountCenterProposed.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get accountCenterProposed;

  /// No description provided for @accountCenterVotes.
  ///
  /// In en, this message translates to:
  /// **'Votes'**
  String get accountCenterVotes;

  /// No description provided for @accountCenterVotesValue.
  ///
  /// In en, this message translates to:
  /// **'{add} approve / {cancel} reject (need {threshold})'**
  String accountCenterVotesValue(int add, int cancel, int threshold);

  /// No description provided for @accountCenterExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get accountCenterExpires;

  /// No description provided for @accountCenterSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'This session has expired'**
  String get accountCenterSessionExpired;

  /// No description provided for @accountCenterVoting.
  ///
  /// In en, this message translates to:
  /// **'VOTING...'**
  String get accountCenterVoting;

  /// No description provided for @accountCenterApprove.
  ///
  /// In en, this message translates to:
  /// **'APPROVE'**
  String get accountCenterApprove;

  /// No description provided for @accountCenterReject.
  ///
  /// In en, this message translates to:
  /// **'REJECT'**
  String get accountCenterReject;

  /// No description provided for @accountCenterTrusted.
  ///
  /// In en, this message translates to:
  /// **'TRUSTED'**
  String get accountCenterTrusted;

  /// No description provided for @accountCenterThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get accountCenterThreshold;

  /// No description provided for @accountCenterThresholdValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 vote needed} other{{count} votes needed}}'**
  String accountCenterThresholdValue(int count);

  /// No description provided for @accountCenterNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active recovery session'**
  String get accountCenterNoActiveSession;

  /// No description provided for @accountCenterStarting.
  ///
  /// In en, this message translates to:
  /// **'STARTING...'**
  String get accountCenterStarting;

  /// No description provided for @accountCenterStartRecoveryAction.
  ///
  /// In en, this message translates to:
  /// **'START RECOVERY'**
  String get accountCenterStartRecoveryAction;

  /// No description provided for @accountCenterCreateAccountInvite.
  ///
  /// In en, this message translates to:
  /// **'Create Account with Invite'**
  String get accountCenterCreateAccountInvite;

  /// No description provided for @accountCenterInviteSeasonHave.
  ///
  /// In en, this message translates to:
  /// **'Invite season is on. Scan a friend\'s \"New Account\" QR code with your camera to onboard them — it spends one invite.'**
  String get accountCenterInviteSeasonHave;

  /// No description provided for @accountCenterInviteSeasonNone.
  ///
  /// In en, this message translates to:
  /// **'Invite season is on. You have no invites left. Wait for the next wave to onboard new accounts.'**
  String get accountCenterInviteSeasonNone;

  /// No description provided for @accountCenterInvitesLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{invite left} other{invites left}}'**
  String accountCenterInvitesLeftLabel(int count);

  /// No description provided for @accountCenterCreateNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get accountCenterCreateNewAccount;

  /// No description provided for @accountCenterCreateAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'To create an account, scan your friend\'s QR code for \"New Account\" with your camera. PublicOS opens the confirm sheet automatically.'**
  String get accountCenterCreateAccountInfo;

  /// No description provided for @accountCenterSelectFriendTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Friend'**
  String get accountCenterSelectFriendTitle;

  /// No description provided for @accountCenterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, username or address'**
  String get accountCenterSearchHint;

  /// No description provided for @accountCenterSearchingOnChain.
  ///
  /// In en, this message translates to:
  /// **'Searching on chain…'**
  String get accountCenterSearchingOnChain;

  /// No description provided for @accountCenterNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No contacts with a PublicOS address'**
  String get accountCenterNoContacts;

  /// No description provided for @addSessionDialogWrongKind.
  ///
  /// In en, this message translates to:
  /// **'This claim is for creating an account, not adding a session.'**
  String get addSessionDialogWrongKind;

  /// No description provided for @addSessionDialogMalformedPayload.
  ///
  /// In en, this message translates to:
  /// **'Malformed claim payload.'**
  String get addSessionDialogMalformedPayload;

  /// No description provided for @addSessionDialogForeignAccount.
  ///
  /// In en, this message translates to:
  /// **'This claim was signed for a different account.'**
  String get addSessionDialogForeignAccount;

  /// No description provided for @addSessionDialogNotRecoveryContact.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a recovery contact for this account, so you can\'t help recover it. Only the contacts they chose in advance can.'**
  String get addSessionDialogNotRecoveryContact;

  /// No description provided for @addSessionDialogRecoveryCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check recovery status.'**
  String get addSessionDialogRecoveryCheckFailed;

  /// No description provided for @addSessionDialogRecoveryVoteStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery vote started'**
  String get addSessionDialogRecoveryVoteStartedTitle;

  /// No description provided for @addSessionDialogDeviceAuthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Session added'**
  String get addSessionDialogDeviceAuthorizedTitle;

  /// No description provided for @addSessionDialogRecoverySuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The other recovery contacts can now add their votes. Once enough approve, the new session becomes the account\'s only one.'**
  String get addSessionDialogRecoverySuccessBody;

  /// No description provided for @addSessionDialogAuthorizedSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The new session can now act as your account.'**
  String get addSessionDialogAuthorizedSuccessBody;

  /// No description provided for @addSessionDialogInvalidClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get addSessionDialogInvalidClaimTitle;

  /// No description provided for @addSessionDialogClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get addSessionDialogClose;

  /// No description provided for @addSessionDialogHelpRecoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Help recover an account'**
  String get addSessionDialogHelpRecoverTitle;

  /// No description provided for @addSessionDialogAuthorizeSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a session'**
  String get addSessionDialogAuthorizeSessionTitle;

  /// No description provided for @addSessionDialogRecoveryBody.
  ///
  /// In en, this message translates to:
  /// **'Start a recovery vote that gives {target} a new session ({address}). If enough of their recovery contacts approve, every other session on the account is removed and this one stays.'**
  String addSessionDialogRecoveryBody(Object target, Object address);

  /// No description provided for @addSessionDialogAuthorizeBody.
  ///
  /// In en, this message translates to:
  /// **'Add {address} as a session of your account. It will be able to send messages, manage your profile and transact as you.'**
  String addSessionDialogAuthorizeBody(Object address);

  /// No description provided for @addSessionDialogThisAccount.
  ///
  /// In en, this message translates to:
  /// **'this account'**
  String get addSessionDialogThisAccount;

  /// No description provided for @addSessionDialogAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get addSessionDialogAddressCopied;

  /// No description provided for @addSessionDialogRecoveryWarning.
  ///
  /// In en, this message translates to:
  /// **'Only do this if {target} asked you to help them recover. It removes all their current sessions.'**
  String addSessionDialogRecoveryWarning(Object target);

  /// No description provided for @addSessionDialogAuthorizeWarning.
  ///
  /// In en, this message translates to:
  /// **'Only approve a session you started yourself. If you didn\'t, cancel.'**
  String get addSessionDialogAuthorizeWarning;

  /// No description provided for @addSessionDialogClaimExpired.
  ///
  /// In en, this message translates to:
  /// **'This request expired. Make a new QR where you started it.'**
  String get addSessionDialogClaimExpired;

  /// No description provided for @addSessionDialogStartVoteButton.
  ///
  /// In en, this message translates to:
  /// **'START VOTE'**
  String get addSessionDialogStartVoteButton;

  /// No description provided for @addSessionDialogAuthorizeButton.
  ///
  /// In en, this message translates to:
  /// **'ADD SESSION'**
  String get addSessionDialogAuthorizeButton;

  /// No description provided for @addSessionDialogDeadlineExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get addSessionDialogDeadlineExpired;

  /// No description provided for @addSessionDialogDeadlineExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String addSessionDialogDeadlineExpiresIn(Object time);

  /// No description provided for @appProfileBottomSheetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get appProfileBottomSheetEdit;

  /// No description provided for @appProfileBottomSheetByPrefix.
  ///
  /// In en, this message translates to:
  /// **'by '**
  String get appProfileBottomSheetByPrefix;

  /// No description provided for @appProfileBottomSheetAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get appProfileBottomSheetAbout;

  /// No description provided for @appProfileBottomSheetOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open App'**
  String get appProfileBottomSheetOpenApp;

  /// No description provided for @appProfileBottomSheetOpenWebApp.
  ///
  /// In en, this message translates to:
  /// **'Open Web App'**
  String get appProfileBottomSheetOpenWebApp;

  /// No description provided for @appProfileBottomSheetDownloadApk.
  ///
  /// In en, this message translates to:
  /// **'Download APK'**
  String get appProfileBottomSheetDownloadApk;

  /// No description provided for @appProfileBottomSheetDownloadIpa.
  ///
  /// In en, this message translates to:
  /// **'Download IPA'**
  String get appProfileBottomSheetDownloadIpa;

  /// No description provided for @appProfileBottomSheetPlatformWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get appProfileBottomSheetPlatformWeb;

  /// No description provided for @registerAppBottomSheetTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit App'**
  String get registerAppBottomSheetTitleEdit;

  /// No description provided for @registerAppBottomSheetTitleRegister.
  ///
  /// In en, this message translates to:
  /// **'Register App'**
  String get registerAppBottomSheetTitleRegister;

  /// No description provided for @registerAppBottomSheetBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get registerAppBottomSheetBack;

  /// No description provided for @registerAppBottomSheetUpdateApp.
  ///
  /// In en, this message translates to:
  /// **'Update App'**
  String get registerAppBottomSheetUpdateApp;

  /// No description provided for @registerAppBottomSheetNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get registerAppBottomSheetNext;

  /// No description provided for @registerAppBottomSheetStepBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get registerAppBottomSheetStepBasicInfo;

  /// No description provided for @registerAppBottomSheetStepMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get registerAppBottomSheetStepMetadata;

  /// No description provided for @registerAppBottomSheetStepLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get registerAppBottomSheetStepLinks;

  /// No description provided for @registerAppBottomSheetBasicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get registerAppBottomSheetBasicInfoTitle;

  /// No description provided for @registerAppBottomSheetAppNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App Name (unique key)'**
  String get registerAppBottomSheetAppNameLabel;

  /// No description provided for @registerAppBottomSheetAppNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., my-awesome-app'**
  String get registerAppBottomSheetAppNameHint;

  /// No description provided for @registerAppBottomSheetAppNameHelperEdit.
  ///
  /// In en, this message translates to:
  /// **'App name cannot be changed after registration.'**
  String get registerAppBottomSheetAppNameHelperEdit;

  /// No description provided for @registerAppBottomSheetAppNameHelperCreate.
  ///
  /// In en, this message translates to:
  /// **'Lowercase, no spaces. This is your app identifier.'**
  String get registerAppBottomSheetAppNameHelperCreate;

  /// No description provided for @registerAppBottomSheetAppNameRequired.
  ///
  /// In en, this message translates to:
  /// **'App name is required'**
  String get registerAppBottomSheetAppNameRequired;

  /// No description provided for @registerAppBottomSheetAppNameMinLength.
  ///
  /// In en, this message translates to:
  /// **'App name must be at least 3 characters'**
  String get registerAppBottomSheetAppNameMinLength;

  /// No description provided for @registerAppBottomSheetDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get registerAppBottomSheetDisplayNameLabel;

  /// No description provided for @registerAppBottomSheetDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Awesome App'**
  String get registerAppBottomSheetDisplayNameHint;

  /// No description provided for @registerAppBottomSheetDisplayNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Human-readable name shown to users.'**
  String get registerAppBottomSheetDisplayNameHelper;

  /// No description provided for @registerAppBottomSheetDisplayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get registerAppBottomSheetDisplayNameRequired;

  /// No description provided for @registerAppBottomSheetIconUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon URL (optional)'**
  String get registerAppBottomSheetIconUrlLabel;

  /// No description provided for @registerAppBottomSheetIconUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'URL to your app icon image.'**
  String get registerAppBottomSheetIconUrlHelper;

  /// No description provided for @registerAppBottomSheetAppDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Details'**
  String get registerAppBottomSheetAppDetailsTitle;

  /// No description provided for @registerAppBottomSheetDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get registerAppBottomSheetDescriptionLabel;

  /// No description provided for @registerAppBottomSheetDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what your app does...'**
  String get registerAppBottomSheetDescriptionHint;

  /// No description provided for @registerAppBottomSheetWarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Warnings (optional)'**
  String get registerAppBottomSheetWarningsLabel;

  /// No description provided for @registerAppBottomSheetWarningsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Contains mature content, gambling, etc.'**
  String get registerAppBottomSheetWarningsHint;

  /// No description provided for @registerAppBottomSheetWarningsHelper.
  ///
  /// In en, this message translates to:
  /// **'Any content warnings users should know about.'**
  String get registerAppBottomSheetWarningsHelper;

  /// No description provided for @registerAppBottomSheetCategoryOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Category 1'**
  String get registerAppBottomSheetCategoryOneLabel;

  /// No description provided for @registerAppBottomSheetCategoryOneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Social'**
  String get registerAppBottomSheetCategoryOneHint;

  /// No description provided for @registerAppBottomSheetCategoryTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'Category 2'**
  String get registerAppBottomSheetCategoryTwoLabel;

  /// No description provided for @registerAppBottomSheetCategoryTwoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Finance'**
  String get registerAppBottomSheetCategoryTwoHint;

  /// No description provided for @registerAppBottomSheetAppLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'App Links'**
  String get registerAppBottomSheetAppLinksTitle;

  /// No description provided for @registerAppBottomSheetAppLinksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add at least one link where users can access your app.'**
  String get registerAppBottomSheetAppLinksSubtitle;

  /// No description provided for @registerAppBottomSheetWebUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Web App URL'**
  String get registerAppBottomSheetWebUrlLabel;

  /// No description provided for @registerAppBottomSheetWebUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'URL to your web app (can be launched in PublicOS browser).'**
  String get registerAppBottomSheetWebUrlHelper;

  /// No description provided for @registerAppBottomSheetAppStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'App Store Link (iOS)'**
  String get registerAppBottomSheetAppStoreLabel;

  /// No description provided for @registerAppBottomSheetPlayStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Play Store Link (Android)'**
  String get registerAppBottomSheetPlayStoreLabel;

  /// No description provided for @registerAppBottomSheetApkLabel.
  ///
  /// In en, this message translates to:
  /// **'APK Download URL'**
  String get registerAppBottomSheetApkLabel;

  /// No description provided for @registerAppBottomSheetApkHint.
  ///
  /// In en, this message translates to:
  /// **'Direct link to APK file'**
  String get registerAppBottomSheetApkHint;

  /// No description provided for @registerAppBottomSheetIpaLabel.
  ///
  /// In en, this message translates to:
  /// **'IPA Download URL'**
  String get registerAppBottomSheetIpaLabel;

  /// No description provided for @registerAppBottomSheetIpaHint.
  ///
  /// In en, this message translates to:
  /// **'Direct link to IPA file'**
  String get registerAppBottomSheetIpaHint;

  /// No description provided for @registerAppBottomSheetSnackUpdated.
  ///
  /// In en, this message translates to:
  /// **'App \"{name}\" updated with {count, plural, =1{1 pointer} other{{count} pointers}}!'**
  String registerAppBottomSheetSnackUpdated(Object name, int count);

  /// No description provided for @registerAppBottomSheetSnackRegistered.
  ///
  /// In en, this message translates to:
  /// **'App \"{name}\" registered with {count, plural, =1{1 pointer} other{{count} pointers}}!'**
  String registerAppBottomSheetSnackRegistered(Object name, int count);

  /// No description provided for @registerAppBottomSheetRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to register app'**
  String get registerAppBottomSheetRegisterFailed;

  /// No description provided for @appProfileSheetEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get appProfileSheetEdit;

  /// No description provided for @appProfileSheetByPrefix.
  ///
  /// In en, this message translates to:
  /// **'by '**
  String get appProfileSheetByPrefix;

  /// No description provided for @appProfileSheetAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get appProfileSheetAbout;

  /// No description provided for @appProfileSheetOpenAppHeader.
  ///
  /// In en, this message translates to:
  /// **'Open App'**
  String get appProfileSheetOpenAppHeader;

  /// No description provided for @appProfileSheetOpenWebApp.
  ///
  /// In en, this message translates to:
  /// **'Open Web App'**
  String get appProfileSheetOpenWebApp;

  /// No description provided for @appProfileSheetDownloadApk.
  ///
  /// In en, this message translates to:
  /// **'Download APK'**
  String get appProfileSheetDownloadApk;

  /// No description provided for @appProfileSheetDownloadIpa.
  ///
  /// In en, this message translates to:
  /// **'Download IPA'**
  String get appProfileSheetDownloadIpa;

  /// No description provided for @registerAppSheetBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get registerAppSheetBasicInfo;

  /// No description provided for @registerAppSheetAppNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App Name (unique key)'**
  String get registerAppSheetAppNameLabel;

  /// No description provided for @registerAppSheetAppNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., my-awesome-app'**
  String get registerAppSheetAppNameHint;

  /// No description provided for @registerAppSheetAppNameHelperLocked.
  ///
  /// In en, this message translates to:
  /// **'App name cannot be changed after registration.'**
  String get registerAppSheetAppNameHelperLocked;

  /// No description provided for @registerAppSheetAppNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Lowercase, no spaces. This is your app identifier.'**
  String get registerAppSheetAppNameHelper;

  /// No description provided for @registerAppSheetAppNameRequired.
  ///
  /// In en, this message translates to:
  /// **'App name is required'**
  String get registerAppSheetAppNameRequired;

  /// No description provided for @registerAppSheetAppNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'App name must be at least 3 characters'**
  String get registerAppSheetAppNameTooShort;

  /// No description provided for @registerAppSheetDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get registerAppSheetDisplayNameLabel;

  /// No description provided for @registerAppSheetDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., My Awesome App'**
  String get registerAppSheetDisplayNameHint;

  /// No description provided for @registerAppSheetDisplayNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Human-readable name shown to users.'**
  String get registerAppSheetDisplayNameHelper;

  /// No description provided for @registerAppSheetDisplayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get registerAppSheetDisplayNameRequired;

  /// No description provided for @registerAppSheetIconUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon URL (optional)'**
  String get registerAppSheetIconUrlLabel;

  /// No description provided for @registerAppSheetIconUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'URL to your app icon image.'**
  String get registerAppSheetIconUrlHelper;

  /// No description provided for @registerAppSheetAppDetails.
  ///
  /// In en, this message translates to:
  /// **'App Details'**
  String get registerAppSheetAppDetails;

  /// No description provided for @registerAppSheetDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get registerAppSheetDescriptionLabel;

  /// No description provided for @registerAppSheetDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what your app does...'**
  String get registerAppSheetDescriptionHint;

  /// No description provided for @registerAppSheetWarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Warnings (optional)'**
  String get registerAppSheetWarningsLabel;

  /// No description provided for @registerAppSheetWarningsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Contains mature content, gambling, etc.'**
  String get registerAppSheetWarningsHint;

  /// No description provided for @registerAppSheetWarningsHelper.
  ///
  /// In en, this message translates to:
  /// **'Any content warnings users should know about.'**
  String get registerAppSheetWarningsHelper;

  /// No description provided for @registerAppSheetCategoryOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Category 1'**
  String get registerAppSheetCategoryOneLabel;

  /// No description provided for @registerAppSheetCategoryOneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Social'**
  String get registerAppSheetCategoryOneHint;

  /// No description provided for @registerAppSheetCategoryTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'Category 2'**
  String get registerAppSheetCategoryTwoLabel;

  /// No description provided for @registerAppSheetCategoryTwoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Finance'**
  String get registerAppSheetCategoryTwoHint;

  /// No description provided for @registerAppSheetAppLinks.
  ///
  /// In en, this message translates to:
  /// **'App Links'**
  String get registerAppSheetAppLinks;

  /// No description provided for @registerAppSheetLinksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add at least one link where users can access your app.'**
  String get registerAppSheetLinksSubtitle;

  /// No description provided for @registerAppSheetWebUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Web App URL'**
  String get registerAppSheetWebUrlLabel;

  /// No description provided for @registerAppSheetWebUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'URL to your web app (launchable in PublicOS browser).'**
  String get registerAppSheetWebUrlHelper;

  /// No description provided for @registerAppSheetAppStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'App Store Link (iOS)'**
  String get registerAppSheetAppStoreLabel;

  /// No description provided for @registerAppSheetPlayStoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Play Store Link (Android)'**
  String get registerAppSheetPlayStoreLabel;

  /// No description provided for @registerAppSheetApkUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'APK Download URL'**
  String get registerAppSheetApkUrlLabel;

  /// No description provided for @registerAppSheetApkUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Direct link to APK file'**
  String get registerAppSheetApkUrlHint;

  /// No description provided for @registerAppSheetIpaUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'IPA Download URL'**
  String get registerAppSheetIpaUrlLabel;

  /// No description provided for @registerAppSheetIpaUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Direct link to IPA file'**
  String get registerAppSheetIpaUrlHint;

  /// No description provided for @registerAppSheetEditApp.
  ///
  /// In en, this message translates to:
  /// **'Edit App'**
  String get registerAppSheetEditApp;

  /// No description provided for @registerAppSheetRegisterApp.
  ///
  /// In en, this message translates to:
  /// **'Register App'**
  String get registerAppSheetRegisterApp;

  /// No description provided for @registerAppSheetStepBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get registerAppSheetStepBasic;

  /// No description provided for @registerAppSheetStepMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get registerAppSheetStepMetadata;

  /// No description provided for @registerAppSheetStepLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get registerAppSheetStepLinks;

  /// No description provided for @registerAppSheetBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get registerAppSheetBack;

  /// No description provided for @registerAppSheetUpdateApp.
  ///
  /// In en, this message translates to:
  /// **'Update App'**
  String get registerAppSheetUpdateApp;

  /// No description provided for @registerAppSheetNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get registerAppSheetNext;

  /// No description provided for @registerAppSheetUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'App \"{name}\" updated with {count, plural, =1{1 pointer} other{{count} pointers}}!'**
  String registerAppSheetUpdatedSnack(Object name, int count);

  /// No description provided for @registerAppSheetRegisteredSnack.
  ///
  /// In en, this message translates to:
  /// **'App \"{name}\" registered with {count, plural, =1{1 pointer} other{{count} pointers}}!'**
  String registerAppSheetRegisteredSnack(Object name, int count);

  /// No description provided for @registerAppSheetUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update app: {error}'**
  String registerAppSheetUpdateFailed(Object error);

  /// No description provided for @registerAppSheetRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to register app: {error}'**
  String registerAppSheetRegisterFailed(Object error);

  /// No description provided for @signatureRequestSheetSignWith.
  ///
  /// In en, this message translates to:
  /// **'Sign with'**
  String get signatureRequestSheetSignWith;

  /// No description provided for @signatureRequestSheetMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get signatureRequestSheetMyAccount;

  /// No description provided for @signatureRequestSheetKeyFallback.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get signatureRequestSheetKeyFallback;

  /// No description provided for @signatureRequestSheetTitleSignMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign Message'**
  String get signatureRequestSheetTitleSignMessage;

  /// No description provided for @signatureRequestSheetTitleSignData.
  ///
  /// In en, this message translates to:
  /// **'Sign Data'**
  String get signatureRequestSheetTitleSignData;

  /// No description provided for @signatureRequestSheetTitleSignTypedData.
  ///
  /// In en, this message translates to:
  /// **'Sign Typed Data'**
  String get signatureRequestSheetTitleSignTypedData;

  /// No description provided for @signatureRequestSheetTitleSendTransaction.
  ///
  /// In en, this message translates to:
  /// **'Send Transaction'**
  String get signatureRequestSheetTitleSendTransaction;

  /// No description provided for @signatureRequestSheetTitleSignTransaction.
  ///
  /// In en, this message translates to:
  /// **'Sign Transaction'**
  String get signatureRequestSheetTitleSignTransaction;

  /// No description provided for @signatureRequestSheetActionSignMessage.
  ///
  /// In en, this message translates to:
  /// **'SIGN MESSAGE'**
  String get signatureRequestSheetActionSignMessage;

  /// No description provided for @signatureRequestSheetActionSignData.
  ///
  /// In en, this message translates to:
  /// **'SIGN DATA'**
  String get signatureRequestSheetActionSignData;

  /// No description provided for @signatureRequestSheetActionSend.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get signatureRequestSheetActionSend;

  /// No description provided for @signatureRequestSheetActionSign.
  ///
  /// In en, this message translates to:
  /// **'SIGN'**
  String get signatureRequestSheetActionSign;

  /// No description provided for @signatureRequestSheetChainUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get signatureRequestSheetChainUnknown;

  /// No description provided for @signatureRequestSheetChainNamed.
  ///
  /// In en, this message translates to:
  /// **'Chain {id}'**
  String signatureRequestSheetChainNamed(Object id);

  /// No description provided for @signatureRequestSheetInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'About Signing'**
  String get signatureRequestSheetInfoTitle;

  /// No description provided for @signatureRequestSheetInfoBody1.
  ///
  /// In en, this message translates to:
  /// **'This signs a digital message with the selected key.'**
  String get signatureRequestSheetInfoBody1;

  /// No description provided for @signatureRequestSheetInfoBody2.
  ///
  /// In en, this message translates to:
  /// **'A signature can authorize actions, prove ownership, or agree to terms. It may or may not touch the chain.'**
  String get signatureRequestSheetInfoBody2;

  /// No description provided for @signatureRequestSheetInfoWarning.
  ///
  /// In en, this message translates to:
  /// **'Always be careful what you sign — a malicious signature can lead to loss of funds or unauthorized access.'**
  String get signatureRequestSheetInfoWarning;

  /// No description provided for @signatureRequestSheetInfoGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get signatureRequestSheetInfoGotIt;

  /// No description provided for @signatureRequestSheetCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get signatureRequestSheetCopiedToClipboard;

  /// No description provided for @signatureRequestSheetInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'What is signing?'**
  String get signatureRequestSheetInfoTooltip;

  /// No description provided for @signatureRequestSheetKeyBadge.
  ///
  /// In en, this message translates to:
  /// **'key'**
  String get signatureRequestSheetKeyBadge;

  /// No description provided for @signatureRequestSheetNoData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get signatureRequestSheetNoData;

  /// No description provided for @signatureRequestSheetSigningWith.
  ///
  /// In en, this message translates to:
  /// **'SIGNING WITH'**
  String get signatureRequestSheetSigningWith;

  /// No description provided for @signatureRequestSheetSectionMessage.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE'**
  String get signatureRequestSheetSectionMessage;

  /// No description provided for @signatureRequestSheetSectionRawHex.
  ///
  /// In en, this message translates to:
  /// **'RAW HEX'**
  String get signatureRequestSheetSectionRawHex;

  /// No description provided for @signatureRequestSheetRawData.
  ///
  /// In en, this message translates to:
  /// **'RAW DATA'**
  String get signatureRequestSheetRawData;

  /// No description provided for @signatureRequestSheetCopy.
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get signatureRequestSheetCopy;

  /// No description provided for @signatureRequestSheetNotReadableText.
  ///
  /// In en, this message translates to:
  /// **'This message is not readable text. You can inspect it under Raw data.'**
  String get signatureRequestSheetNotReadableText;

  /// No description provided for @signatureRequestSheetSectionTypedData.
  ///
  /// In en, this message translates to:
  /// **'TYPED DATA (EIP-712)'**
  String get signatureRequestSheetSectionTypedData;

  /// No description provided for @signatureRequestSheetSectionTransaction.
  ///
  /// In en, this message translates to:
  /// **'TRANSACTION'**
  String get signatureRequestSheetSectionTransaction;

  /// No description provided for @signatureRequestSheetSectionContractData.
  ///
  /// In en, this message translates to:
  /// **'CONTRACT DATA'**
  String get signatureRequestSheetSectionContractData;

  /// No description provided for @signatureRequestSheetLabelSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get signatureRequestSheetLabelSending;

  /// No description provided for @signatureRequestSheetLabelRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get signatureRequestSheetLabelRecipient;

  /// No description provided for @signatureRequestSheetLabelToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get signatureRequestSheetLabelToken;

  /// No description provided for @signatureRequestSheetLabelTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get signatureRequestSheetLabelTo;

  /// No description provided for @signatureRequestSheetLabelValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get signatureRequestSheetLabelValue;

  /// No description provided for @signatureRequestSheetLabelNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get signatureRequestSheetLabelNetwork;

  /// No description provided for @signatureRequestSheetLabelGasLimit.
  ///
  /// In en, this message translates to:
  /// **'Gas Limit'**
  String get signatureRequestSheetLabelGasLimit;

  /// No description provided for @signatureRequestSheetActionReject.
  ///
  /// In en, this message translates to:
  /// **'REJECT'**
  String get signatureRequestSheetActionReject;

  /// No description provided for @connectRequestSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to this site?'**
  String get connectRequestSheetTitle;

  /// No description provided for @connectRequestSheetOrigin.
  ///
  /// In en, this message translates to:
  /// **'ORIGIN'**
  String get connectRequestSheetOrigin;

  /// No description provided for @connectRequestSheetNetwork.
  ///
  /// In en, this message translates to:
  /// **'NETWORK'**
  String get connectRequestSheetNetwork;

  /// No description provided for @browserChainPickerNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to this tab only, and reloads the page.'**
  String get browserChainPickerNote;

  /// No description provided for @connectRequestSheetSharing.
  ///
  /// In en, this message translates to:
  /// **'SHARING'**
  String get connectRequestSheetSharing;

  /// No description provided for @connectRequestSheetSessionKey.
  ///
  /// In en, this message translates to:
  /// **'Session Key'**
  String get connectRequestSheetSessionKey;

  /// No description provided for @connectRequestSheetScope.
  ///
  /// In en, this message translates to:
  /// **'This site will be able to see the keys you turn on and ask you to sign with them. The green key is the one it sees first. It can\'t sign or move funds without asking you every time.'**
  String get connectRequestSheetScope;

  /// No description provided for @connectRequestSheetActionCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get connectRequestSheetActionCancel;

  /// No description provided for @connectRequestSheetActionConnect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get connectRequestSheetActionConnect;

  /// No description provided for @siteKeysSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected keys'**
  String get siteKeysSheetTitle;

  /// No description provided for @siteKeysSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visible keys are the ones this site can see and ask you to sign with. The green key is the active key: the one at the top of the list, which most sites use to sign you in. It\'s a choice for this site only. Sites without one use your preferred key.'**
  String get siteKeysSheetSubtitle;

  /// Site keys sheet: tooltip on the key glyph (per-site active key).
  ///
  /// In en, this message translates to:
  /// **'Active key on this site'**
  String get siteKeysSheetActive;

  /// Site keys sheet: tooltip on the eye glyph (per-site visibility).
  ///
  /// In en, this message translates to:
  /// **'Visible to this site'**
  String get siteKeysSheetVisible;

  /// No description provided for @siteKeysSheetRequested.
  ///
  /// In en, this message translates to:
  /// **'This site asked for this key'**
  String get siteKeysSheetRequested;

  /// No description provided for @siteKeysSheetDisconnectHint.
  ///
  /// In en, this message translates to:
  /// **'Turn every key off to disconnect this site.'**
  String get siteKeysSheetDisconnectHint;

  /// Connected-keys sheet bottom legend: what the eye glyph on a key row means.
  ///
  /// In en, this message translates to:
  /// **'Site can see'**
  String get siteKeysSheetLegendVisible;

  /// Connected-keys sheet bottom legend: what the filled key glyph on a key row means.
  ///
  /// In en, this message translates to:
  /// **'Signs first'**
  String get siteKeysSheetLegendActive;

  /// Connected-keys sheet bottom legend: turning every key off revokes the site.
  ///
  /// In en, this message translates to:
  /// **'All off = disconnect'**
  String get siteKeysSheetLegendDisconnect;

  /// No description provided for @siteKeysSheetActionSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get siteKeysSheetActionSave;

  /// No description provided for @siteKeysSheetActionDisconnect.
  ///
  /// In en, this message translates to:
  /// **'DISCONNECT'**
  String get siteKeysSheetActionDisconnect;

  /// No description provided for @siteKeysSheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No keys available.'**
  String get siteKeysSheetEmpty;

  /// publicos_desktop browser deck: how many keys the current site can see, shown beside the active key name.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 visible} other{{count} visible}}'**
  String desktopWebKeyVisibleCount(int count);

  /// publicos_desktop browser: the waving label beside the loader while a web page is opening.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get desktopWebviewLoading;

  /// No description provided for @webKeyIndicatorTooltip.
  ///
  /// In en, this message translates to:
  /// **'Keys for this site'**
  String get webKeyIndicatorTooltip;

  /// No description provided for @signatureRequestSheetRawTokenAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} (token {addr})'**
  String signatureRequestSheetRawTokenAmount(Object amount, Object addr);

  /// No description provided for @domainStoreSheetOverdueRenewFirst.
  ///
  /// In en, this message translates to:
  /// **'Your domain is overdue — renew it first. A lapsed account can only pay its own domain until it\'s current again.'**
  String get domainStoreSheetOverdueRenewFirst;

  /// No description provided for @editInboxIdLabelSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Inbox ID Label'**
  String get editInboxIdLabelSheetTitle;

  /// No description provided for @editInboxIdLabelSheetIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String editInboxIdLabelSheetIdLabel(Object id);

  /// No description provided for @editInboxIdLabelSheetNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New Label'**
  String get editInboxIdLabelSheetNewLabel;

  /// No description provided for @editInboxIdLabelSheetLabelRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a label'**
  String get editInboxIdLabelSheetLabelRequired;

  /// No description provided for @editInboxIdLabelSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editInboxIdLabelSheetSave;

  /// No description provided for @feedsSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'RSS View Settings'**
  String get feedsSettingsSheetTitle;

  /// No description provided for @feedsSettingsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize how posts are displayed'**
  String get feedsSettingsSheetSubtitle;

  /// No description provided for @feedsSettingsSheetTitleTextSize.
  ///
  /// In en, this message translates to:
  /// **'Title Text Size'**
  String get feedsSettingsSheetTitleTextSize;

  /// No description provided for @feedsSettingsSheetDescriptionTextSize.
  ///
  /// In en, this message translates to:
  /// **'Description Text Size'**
  String get feedsSettingsSheetDescriptionTextSize;

  /// No description provided for @feedsSettingsSheetPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get feedsSettingsSheetPreview;

  /// No description provided for @feedsSettingsSheetSamplePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample Post Title'**
  String get feedsSettingsSheetSamplePostTitle;

  /// No description provided for @feedsSettingsSheetSampleDescription.
  ///
  /// In en, this message translates to:
  /// **'This is a sample description to show how your RSS feed posts will appear with the current text size settings.'**
  String get feedsSettingsSheetSampleDescription;

  /// No description provided for @feedsSettingsSheetResetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get feedsSettingsSheetResetToDefaults;

  /// No description provided for @feedsSettingsSheetPointSize.
  ///
  /// In en, this message translates to:
  /// **'{value}pt'**
  String feedsSettingsSheetPointSize(Object value);

  /// No description provided for @xmtpSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'XMTP Settings'**
  String get xmtpSettingsSheetTitle;

  /// No description provided for @xmtpSettingsSheetReadReceiptsHeader.
  ///
  /// In en, this message translates to:
  /// **'Read Receipts'**
  String get xmtpSettingsSheetReadReceiptsHeader;

  /// No description provided for @xmtpSettingsSheetReadReceiptsDescription.
  ///
  /// In en, this message translates to:
  /// **'Control whether you send and display read receipts. Note: The XMTP network is open - you can choose to see receipts others send without sending your own.'**
  String get xmtpSettingsSheetReadReceiptsDescription;

  /// No description provided for @xmtpSettingsSheetSendReadReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send read receipts'**
  String get xmtpSettingsSheetSendReadReceiptsTitle;

  /// No description provided for @xmtpSettingsSheetSendReadReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let others know when you\'ve read their messages'**
  String get xmtpSettingsSheetSendReadReceiptsSubtitle;

  /// No description provided for @xmtpSettingsSheetDisplayReadReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Display read receipts'**
  String get xmtpSettingsSheetDisplayReadReceiptsTitle;

  /// No description provided for @xmtpSettingsSheetDisplayReadReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show when others have read your messages'**
  String get xmtpSettingsSheetDisplayReadReceiptsSubtitle;

  /// No description provided for @xmtpSettingsSheetDeniedConvosButton.
  ///
  /// In en, this message translates to:
  /// **'Denied Convos'**
  String get xmtpSettingsSheetDeniedConvosButton;

  /// No description provided for @addCustomFeedSheetTitleList.
  ///
  /// In en, this message translates to:
  /// **'Add a feed to this list'**
  String get addCustomFeedSheetTitleList;

  /// No description provided for @addCustomFeedSheetTitleFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow a feed'**
  String get addCustomFeedSheetTitleFollow;

  /// No description provided for @addCustomFeedSheetUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/feed.xml'**
  String get addCustomFeedSheetUrlHint;

  /// No description provided for @addCustomFeedSheetCheckButton.
  ///
  /// In en, this message translates to:
  /// **'Check feed'**
  String get addCustomFeedSheetCheckButton;

  /// No description provided for @addCustomFeedSheetNoPostsError.
  ///
  /// In en, this message translates to:
  /// **'We reached that URL but it had no posts. Double-check it is a feed URL, not the website it belongs to.'**
  String get addCustomFeedSheetNoPostsError;

  /// No description provided for @addCustomFeedSheetHttpError.
  ///
  /// In en, this message translates to:
  /// **'The server returned HTTP {code}. Check the URL and try again.'**
  String addCustomFeedSheetHttpError(Object code);

  /// No description provided for @addCustomFeedSheetNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach that URL. Check your connection and the address, then try again.'**
  String get addCustomFeedSheetNetworkError;

  /// No description provided for @addCustomFeedSheetReadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that as a feed. Make sure it is a direct RSS, Atom, or JSON Feed URL (not the website it belongs to).'**
  String get addCustomFeedSheetReadError;

  /// No description provided for @addCustomFeedSheetSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save the feed. Please try again.'**
  String get addCustomFeedSheetSaveError;

  /// No description provided for @addCustomFeedSheetUntitledFeed.
  ///
  /// In en, this message translates to:
  /// **'Untitled feed'**
  String get addCustomFeedSheetUntitledFeed;

  /// No description provided for @addCustomFeedSheetUntitledPost.
  ///
  /// In en, this message translates to:
  /// **'(untitled post)'**
  String get addCustomFeedSheetUntitledPost;

  /// No description provided for @addCustomFeedSheetLocalOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'This feed is added to this client only — it is not published on-chain and will not appear for anyone else.'**
  String get addCustomFeedSheetLocalOnlyNote;

  /// No description provided for @addCustomFeedSheetAddToListButton.
  ///
  /// In en, this message translates to:
  /// **'Add to list'**
  String get addCustomFeedSheetAddToListButton;

  /// No description provided for @addCustomFeedSheetFollowFeedButton.
  ///
  /// In en, this message translates to:
  /// **'Follow feed'**
  String get addCustomFeedSheetFollowFeedButton;

  /// No description provided for @addToListBottomSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage RSS Lists'**
  String get addToListBottomSheetTitle;

  /// No description provided for @addToListBottomSheetDefaultFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'RSS Feed'**
  String get addToListBottomSheetDefaultFeedTitle;

  /// No description provided for @addToListBottomSheetSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get addToListBottomSheetSaveChanges;

  /// No description provided for @addToListBottomSheetCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new list'**
  String get addToListBottomSheetCreateNew;

  /// No description provided for @addToListBottomSheetCreateNewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add this feed to a dedicated list'**
  String get addToListBottomSheetCreateNewSubtitle;

  /// No description provided for @addToListBottomSheetCreatedList.
  ///
  /// In en, this message translates to:
  /// **'Created list \"{name}\"'**
  String addToListBottomSheetCreatedList(Object name);

  /// No description provided for @addToListBottomSheetFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create list'**
  String get addToListBottomSheetFailedCreate;

  /// No description provided for @addToListBottomSheetNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes made'**
  String get addToListBottomSheetNoChanges;

  /// No description provided for @addToListBottomSheetAddedToLists.
  ///
  /// In en, this message translates to:
  /// **'Added to {addedCount, plural, =1{1 list} other{{addedCount} lists}}'**
  String addToListBottomSheetAddedToLists(int addedCount);

  /// No description provided for @addToListBottomSheetRemovedFromLists.
  ///
  /// In en, this message translates to:
  /// **'Removed from {removedCount, plural, =1{1 list} other{{removedCount} lists}}'**
  String addToListBottomSheetRemovedFromLists(int removedCount);

  /// No description provided for @addToListBottomSheetAddedAndRemoved.
  ///
  /// In en, this message translates to:
  /// **'Added to {addedCount}, removed from {removedCount, plural, =1{1 list} other{{removedCount} lists}}'**
  String addToListBottomSheetAddedAndRemoved(
      Object addedCount, int removedCount);

  /// No description provided for @addToListBottomSheetErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load lists'**
  String get addToListBottomSheetErrorLoading;

  /// No description provided for @addToListBottomSheetErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save changes'**
  String get addToListBottomSheetErrorSaving;

  /// No description provided for @addToListBottomSheetErrorCreating.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create list'**
  String get addToListBottomSheetErrorCreating;

  /// No description provided for @addToListsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to lists'**
  String get addToListsSheetTitle;

  /// No description provided for @addToListsSheetSectionSingleFollow.
  ///
  /// In en, this message translates to:
  /// **'SINGLE FOLLOW'**
  String get addToListsSheetSectionSingleFollow;

  /// No description provided for @addToListsSheetSectionFollowAsSingle.
  ///
  /// In en, this message translates to:
  /// **'FOLLOW AS SINGLE'**
  String get addToListsSheetSectionFollowAsSingle;

  /// No description provided for @addToListsSheetSectionLists.
  ///
  /// In en, this message translates to:
  /// **'LISTS'**
  String get addToListsSheetSectionLists;

  /// No description provided for @addToListsSheetVia.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get addToListsSheetVia;

  /// No description provided for @addToListsSheetFeedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 feed} other{{count} feeds}}'**
  String addToListsSheetFeedCount(int count);

  /// No description provided for @addToListsSheetCreateNewList.
  ///
  /// In en, this message translates to:
  /// **'Create a new list'**
  String get addToListsSheetCreateNewList;

  /// No description provided for @addToListsSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get addToListsSheetSave;

  /// No description provided for @addToListsSheetUnfollowTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfollow {feed}?'**
  String addToListsSheetUnfollowTitle(Object feed);

  /// No description provided for @addToListsSheetUnfollowBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the single follow. The feed stays in any other lists you\'ve added it to.'**
  String get addToListsSheetUnfollowBody;

  /// No description provided for @addToListsSheetUnfollowAction.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get addToListsSheetUnfollowAction;

  /// No description provided for @addToListsSheetAddedToLists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added to 1 list} other{Added to {count} lists}}'**
  String addToListsSheetAddedToLists(int count);

  /// No description provided for @addToListsSheetRemovedFromLists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed from 1 list} other{Removed from {count} lists}}'**
  String addToListsSheetRemovedFromLists(int count);

  /// No description provided for @addToListsSheetFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 failed} other{{count} failed}}'**
  String addToListsSheetFailedCount(int count);

  /// No description provided for @addToListsSheetNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get addToListsSheetNoChanges;

  /// No description provided for @addToListsSheetCreatedButFailedToAdd.
  ///
  /// In en, this message translates to:
  /// **'Created list but failed to add feed'**
  String get addToListsSheetCreatedButFailedToAdd;

  /// No description provided for @addToListsSheetFailedToCreateSingle.
  ///
  /// In en, this message translates to:
  /// **'Failed to create single follow'**
  String get addToListsSheetFailedToCreateSingle;

  /// No description provided for @addToListsSheetFailedToUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Failed to unfollow'**
  String get addToListsSheetFailedToUnfollow;

  /// No description provided for @commentCardTranslating.
  ///
  /// In en, this message translates to:
  /// **'Translating…'**
  String get commentCardTranslating;

  /// No description provided for @commentCardTranslateWaitingWifi.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Wi-Fi…'**
  String get commentCardTranslateWaitingWifi;

  /// No description provided for @commentCardTranslateDownloadingLang.
  ///
  /// In en, this message translates to:
  /// **'Downloading language…'**
  String get commentCardTranslateDownloadingLang;

  /// No description provided for @commentCardDownloadLangPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Download language pack?'**
  String get commentCardDownloadLangPackTitle;

  /// No description provided for @commentCardDownloadLangPackBody.
  ///
  /// In en, this message translates to:
  /// **'Translating {from} → {to} needs an offline language pack (~30 MB each, downloaded once, then fully on-device).'**
  String commentCardDownloadLangPackBody(Object from, Object to);

  /// No description provided for @commentCardDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commentCardDownload;

  /// No description provided for @commentCardTranslateFailed.
  ///
  /// In en, this message translates to:
  /// **'Translate failed'**
  String get commentCardTranslateFailed;

  /// No description provided for @commentCardTranslateFrom.
  ///
  /// In en, this message translates to:
  /// **'Translate from {lang}'**
  String commentCardTranslateFrom(Object lang);

  /// No description provided for @commentCardTranslatedFrom.
  ///
  /// In en, this message translates to:
  /// **'Translated from {lang} · Show original'**
  String commentCardTranslatedFrom(Object lang);

  /// No description provided for @commentCardShowTranslation.
  ///
  /// In en, this message translates to:
  /// **'Show translation ({lang})'**
  String commentCardShowTranslation(Object lang);

  /// No description provided for @commentCardDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get commentCardDeleteTitle;

  /// No description provided for @commentCardDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the comment and any replies under it. Cannot be undone.'**
  String get commentCardDeleteBody;

  /// No description provided for @commentCardDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commentCardDelete;

  /// No description provided for @commentCardDeleted.
  ///
  /// In en, this message translates to:
  /// **'[deleted]'**
  String get commentCardDeleted;

  /// No description provided for @commentCardLoadMoreReplies.
  ///
  /// In en, this message translates to:
  /// **'Load more replies'**
  String get commentCardLoadMoreReplies;

  /// No description provided for @commentCardEdited.
  ///
  /// In en, this message translates to:
  /// **'(edited)'**
  String get commentCardEdited;

  /// No description provided for @commentCardCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get commentCardCopyText;

  /// No description provided for @commentCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commentCardEdit;

  /// No description provided for @commentCardBlockFromCommenting.
  ///
  /// In en, this message translates to:
  /// **'Block from commenting'**
  String get commentCardBlockFromCommenting;

  /// No description provided for @commentCardCommentCopied.
  ///
  /// In en, this message translates to:
  /// **'Comment copied'**
  String get commentCardCommentCopied;

  /// No description provided for @commentCardBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block from commenting?'**
  String get commentCardBlockTitle;

  /// No description provided for @commentCardBlockBody.
  ///
  /// In en, this message translates to:
  /// **'Add a permanent deny rule for {addr} on this post. They will not be able to comment here. You can adjust or remove the rule from the post menu → Comment rules.'**
  String commentCardBlockBody(Object addr);

  /// No description provided for @commentCardBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get commentCardBlock;

  /// No description provided for @commentCardSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commentCardSave;

  /// No description provided for @commentCardVote.
  ///
  /// In en, this message translates to:
  /// **'Vote'**
  String get commentCardVote;

  /// No description provided for @commentCardReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get commentCardReply;

  /// No description provided for @commentCardReplyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply} other{{count} replies}}'**
  String commentCardReplyCount(int count);

  /// No description provided for @commentRulesSheetLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comment rules'**
  String get commentRulesSheetLoadFailed;

  /// No description provided for @commentRulesSheetAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add rule'**
  String get commentRulesSheetAddFailed;

  /// No description provided for @commentRulesSheetRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove rule'**
  String get commentRulesSheetRemoveFailed;

  /// No description provided for @commentRulesSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Comment rules'**
  String get commentRulesSheetTitle;

  /// No description provided for @commentRulesSheetDescription.
  ///
  /// In en, this message translates to:
  /// **'Override who can comment on this single post. Allow lets the address bypass channel restrictions; Deny blocks them even if the channel is open. Each rule is permanent unless you set a date for it to lift.'**
  String get commentRulesSheetDescription;

  /// No description provided for @commentRulesSheetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rules yet'**
  String get commentRulesSheetEmptyTitle;

  /// No description provided for @commentRulesSheetEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The channel-level commenting policy applies.'**
  String get commentRulesSheetEmptyBody;

  /// No description provided for @commentRulesSheetDenyUntil.
  ///
  /// In en, this message translates to:
  /// **'DENY UNTIL'**
  String get commentRulesSheetDenyUntil;

  /// No description provided for @commentRulesSheetAllowUntil.
  ///
  /// In en, this message translates to:
  /// **'ALLOW UNTIL'**
  String get commentRulesSheetAllowUntil;

  /// No description provided for @commentRulesSheetDenyForever.
  ///
  /// In en, this message translates to:
  /// **'Deny forever — no end date'**
  String get commentRulesSheetDenyForever;

  /// No description provided for @commentRulesSheetAllowForever.
  ///
  /// In en, this message translates to:
  /// **'Allow forever — no end date'**
  String get commentRulesSheetAllowForever;

  /// No description provided for @commentRulesSheetAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get commentRulesSheetAllow;

  /// No description provided for @commentRulesSheetDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get commentRulesSheetDeny;

  /// No description provided for @commentRulesSheetAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commentRulesSheetAddButton;

  /// No description provided for @commentRulesSheetJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get commentRulesSheetJustNow;

  /// No description provided for @commentRulesSheetMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String commentRulesSheetMinutesAgo(Object minutes);

  /// No description provided for @commentRulesSheetHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String commentRulesSheetHoursAgo(Object hours);

  /// No description provided for @commentRulesSheetDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String commentRulesSheetDaysAgo(Object days);

  /// No description provided for @commentRulesSheetChipDeny.
  ///
  /// In en, this message translates to:
  /// **'DENY'**
  String get commentRulesSheetChipDeny;

  /// No description provided for @commentRulesSheetChipAllow.
  ///
  /// In en, this message translates to:
  /// **'ALLOW'**
  String get commentRulesSheetChipAllow;

  /// No description provided for @createListBottomSheetNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a list name'**
  String get createListBottomSheetNameRequired;

  /// No description provided for @createListBottomSheetUpdatedList.
  ///
  /// In en, this message translates to:
  /// **'Updated list \"{name}\"'**
  String createListBottomSheetUpdatedList(Object name);

  /// No description provided for @createListBottomSheetCreatedList.
  ///
  /// In en, this message translates to:
  /// **'Created list \"{name}\"'**
  String createListBottomSheetCreatedList(Object name);

  /// No description provided for @createListBottomSheetUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update list'**
  String get createListBottomSheetUpdateFailed;

  /// No description provided for @createListBottomSheetCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create list'**
  String get createListBottomSheetCreateFailed;

  /// No description provided for @createListBottomSheetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit RSS List'**
  String get createListBottomSheetEditTitle;

  /// No description provided for @createListBottomSheetCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create RSS List'**
  String get createListBottomSheetCreateTitle;

  /// No description provided for @createListBottomSheetEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update the list name and icon'**
  String get createListBottomSheetEditSubtitle;

  /// No description provided for @createListBottomSheetCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new list to organize RSS feeds'**
  String get createListBottomSheetCreateSubtitle;

  /// No description provided for @createListBottomSheetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'List Name'**
  String get createListBottomSheetNameLabel;

  /// No description provided for @createListBottomSheetNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for your RSS list'**
  String get createListBottomSheetNameHint;

  /// No description provided for @createListBottomSheetUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get createListBottomSheetUpdateButton;

  /// No description provided for @createListBottomSheetCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createListBottomSheetCreateButton;

  /// No description provided for @discoverContactRowRssTooltip.
  ///
  /// In en, this message translates to:
  /// **'RSS'**
  String get discoverContactRowRssTooltip;

  /// No description provided for @discoverContactRowWebsiteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get discoverContactRowWebsiteTooltip;

  /// No description provided for @editListBottomSheetRemovedFromList.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{name}\" from list'**
  String editListBottomSheetRemovedFromList(Object name);

  /// No description provided for @editListBottomSheetRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove feed from list'**
  String get editListBottomSheetRemoveFailed;

  /// No description provided for @editListBottomSheetRemoveFeedError.
  ///
  /// In en, this message translates to:
  /// **'Error removing feed'**
  String get editListBottomSheetRemoveFeedError;

  /// No description provided for @editListBottomSheetRemoveFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Feed'**
  String get editListBottomSheetRemoveFeedTitle;

  /// No description provided for @editListBottomSheetRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\" from this list?'**
  String editListBottomSheetRemoveConfirm(Object name);

  /// No description provided for @editListBottomSheetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get editListBottomSheetRemove;

  /// No description provided for @editListBottomSheetFeedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 feed} other{{count} feeds}}'**
  String editListBottomSheetFeedCount(int count);

  /// No description provided for @editListBottomSheetNoFeeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds in this list'**
  String get editListBottomSheetNoFeeds;

  /// No description provided for @editListBottomSheetEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add feeds to this list by browsing RSS feeds and using the \"Add to List\" button.'**
  String get editListBottomSheetEmptyHint;

  /// No description provided for @editListBottomSheetRssFeed.
  ///
  /// In en, this message translates to:
  /// **'RSS Feed'**
  String get editListBottomSheetRssFeed;

  /// No description provided for @editListBottomSheetRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get editListBottomSheetRemoveTooltip;

  /// No description provided for @editListBottomSheetDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get editListBottomSheetDone;

  /// No description provided for @editListSheetTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get editListSheetTitleEdit;

  /// No description provided for @editListSheetTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get editListSheetTitleNew;

  /// No description provided for @editListSheetNameHint.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get editListSheetNameHint;

  /// No description provided for @editListSheetIconHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the icon to change it.'**
  String get editListSheetIconHint;

  /// No description provided for @editListSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editListSheetSave;

  /// No description provided for @editListSheetCreate.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get editListSheetCreate;

  /// No description provided for @editListSheetFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update list'**
  String get editListSheetFailedUpdate;

  /// No description provided for @editListSheetFailedCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create list'**
  String get editListSheetFailedCreate;

  /// No description provided for @editPostBottomSheetErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get editPostBottomSheetErrorTitle;

  /// No description provided for @editPostBottomSheetOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get editPostBottomSheetOk;

  /// No description provided for @editPostBottomSheetErrorMissingChannel.
  ///
  /// In en, this message translates to:
  /// **'Cannot update post: missing channel slug'**
  String get editPostBottomSheetErrorMissingChannel;

  /// No description provided for @editPostBottomSheetUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Post updated successfully'**
  String get editPostBottomSheetUpdateSuccess;

  /// No description provided for @editPostBottomSheetUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update post: {error}'**
  String editPostBottomSheetUpdateFailed(Object error);

  /// No description provided for @editPostBottomSheetUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get editPostBottomSheetUnknownError;

  /// No description provided for @editPostBottomSheetHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPostBottomSheetHeaderTitle;

  /// No description provided for @editPostBottomSheetHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your post content'**
  String get editPostBottomSheetHeaderSubtitle;

  /// No description provided for @editPostBottomSheetTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get editPostBottomSheetTitleLabel;

  /// No description provided for @editPostBottomSheetTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Add a title (optional)'**
  String get editPostBottomSheetTitleHint;

  /// No description provided for @editPostBottomSheetContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get editPostBottomSheetContentLabel;

  /// No description provided for @editPostBottomSheetContentHint.
  ///
  /// In en, this message translates to:
  /// **'Write your post content here...'**
  String get editPostBottomSheetContentHint;

  /// No description provided for @editPostBottomSheetContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get editPostBottomSheetContentRequired;

  /// No description provided for @editPostBottomSheetMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get editPostBottomSheetMediaLabel;

  /// No description provided for @editPostBottomSheetMediaHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional featured image'**
  String get editPostBottomSheetMediaHelper;

  /// No description provided for @editPostBottomSheetInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get editPostBottomSheetInvalidUrl;

  /// No description provided for @editPostBottomSheetSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get editPostBottomSheetSummaryLabel;

  /// No description provided for @editPostBottomSheetSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description for previews...'**
  String get editPostBottomSheetSummaryHint;

  /// No description provided for @editPostBottomSheetSummaryHelper.
  ///
  /// In en, this message translates to:
  /// **'Short summary shown in feed previews'**
  String get editPostBottomSheetSummaryHelper;

  /// No description provided for @editPostBottomSheetExternalLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'External Link'**
  String get editPostBottomSheetExternalLinkLabel;

  /// No description provided for @editPostBottomSheetExternalLinkHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional link to external content'**
  String get editPostBottomSheetExternalLinkHelper;

  /// No description provided for @editPostBottomSheetTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get editPostBottomSheetTagsLabel;

  /// No description provided for @editPostBottomSheetTagsHint.
  ///
  /// In en, this message translates to:
  /// **'tech, news, tutorial'**
  String get editPostBottomSheetTagsHint;

  /// No description provided for @editPostBottomSheetTagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated tags'**
  String get editPostBottomSheetTagsHelper;

  /// No description provided for @editPostBottomSheetSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get editPostBottomSheetSaving;

  /// No description provided for @editPostBottomSheetSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editPostBottomSheetSaveChanges;

  /// No description provided for @emojiPickerDialogSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search emoji...'**
  String get emojiPickerDialogSearchHint;

  /// No description provided for @emojiPickerDialogNoResults.
  ///
  /// In en, this message translates to:
  /// **'No emoji found'**
  String get emojiPickerDialogNoResults;

  /// No description provided for @emojiPickerDialogCategorySmileys.
  ///
  /// In en, this message translates to:
  /// **'Smileys'**
  String get emojiPickerDialogCategorySmileys;

  /// No description provided for @emojiPickerDialogCategoryPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get emojiPickerDialogCategoryPeople;

  /// No description provided for @emojiPickerDialogCategoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get emojiPickerDialogCategoryNature;

  /// No description provided for @emojiPickerDialogCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get emojiPickerDialogCategoryFood;

  /// No description provided for @emojiPickerDialogCategoryActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get emojiPickerDialogCategoryActivities;

  /// No description provided for @emojiPickerDialogCategoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get emojiPickerDialogCategoryTravel;

  /// No description provided for @emojiPickerDialogCategoryObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get emojiPickerDialogCategoryObjects;

  /// No description provided for @emojiPickerDialogCategorySymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get emojiPickerDialogCategorySymbols;

  /// No description provided for @emojiPickerDialogCategoryFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get emojiPickerDialogCategoryFlags;

  /// No description provided for @emojiPickerDialogCategoryMostUsed.
  ///
  /// In en, this message translates to:
  /// **'Most used'**
  String get emojiPickerDialogCategoryMostUsed;

  /// No description provided for @feedsNavigationDrawerSectionLists.
  ///
  /// In en, this message translates to:
  /// **'LISTS'**
  String get feedsNavigationDrawerSectionLists;

  /// No description provided for @feedsNavigationDrawerManageListsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Manage lists'**
  String get feedsNavigationDrawerManageListsTooltip;

  /// No description provided for @feedsNavigationDrawerNoListsYet.
  ///
  /// In en, this message translates to:
  /// **'No lists yet. Tap the icon above to create one.'**
  String get feedsNavigationDrawerNoListsYet;

  /// No description provided for @feedsNavigationDrawerSectionMyChannels.
  ///
  /// In en, this message translates to:
  /// **'MY CHANNELS'**
  String get feedsNavigationDrawerSectionMyChannels;

  /// No description provided for @feedsNavigationDrawerCreateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get feedsNavigationDrawerCreateChannel;

  /// No description provided for @feedsNavigationDrawerBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get feedsNavigationDrawerBookmarks;

  /// No description provided for @feedsNavigationDrawerManageServer.
  ///
  /// In en, this message translates to:
  /// **'Manage server'**
  String get feedsNavigationDrawerManageServer;

  /// No description provided for @feedsNavigationDrawerReadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader settings'**
  String get feedsNavigationDrawerReadingSettings;

  /// No description provided for @feedsNavigationDrawerHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'FEEDS'**
  String get feedsNavigationDrawerHeaderTitle;

  /// No description provided for @feedsNavigationDrawerVia.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get feedsNavigationDrawerVia;

  /// No description provided for @feedsSettingsSheetTitleSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'TITLE SIZE'**
  String get feedsSettingsSheetTitleSizeLabel;

  /// No description provided for @feedsSettingsSheetBodySizeLabel.
  ///
  /// In en, this message translates to:
  /// **'BODY SIZE'**
  String get feedsSettingsSheetBodySizeLabel;

  /// No description provided for @feedsSettingsSheetTrimAtLabel.
  ///
  /// In en, this message translates to:
  /// **'TRIM AT'**
  String get feedsSettingsSheetTrimAtLabel;

  /// No description provided for @feedsSettingsSheetTrimUnit.
  ///
  /// In en, this message translates to:
  /// **'chars'**
  String get feedsSettingsSheetTrimUnit;

  /// No description provided for @feedsSettingsSheetSwipeSnapLabel.
  ///
  /// In en, this message translates to:
  /// **'SWIPE TO NEXT POST WITHIN'**
  String get feedsSettingsSheetSwipeSnapLabel;

  /// No description provided for @feedsSettingsSheetSwipeSnapOnLabel.
  ///
  /// In en, this message translates to:
  /// **'SWIPE TO SNAP'**
  String get feedsSettingsSheetSwipeSnapOnLabel;

  /// No description provided for @feedsSettingsSheetSwipeSnapOnOn.
  ///
  /// In en, this message translates to:
  /// **'A quick swipe moves one post'**
  String get feedsSettingsSheetSwipeSnapOnOn;

  /// No description provided for @feedsSettingsSheetSwipeSnapOnOff.
  ///
  /// In en, this message translates to:
  /// **'Regular scrolling'**
  String get feedsSettingsSheetSwipeSnapOnOff;

  /// No description provided for @feedsSettingsSheetPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get feedsSettingsSheetPreviewLabel;

  /// No description provided for @feedsSettingsSheetJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get feedsSettingsSheetJustNow;

  /// No description provided for @feedsSettingsSheetVia.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get feedsSettingsSheetVia;

  /// No description provided for @feedsSettingsSheetLayoutLabel.
  ///
  /// In en, this message translates to:
  /// **'LAYOUT'**
  String get feedsSettingsSheetLayoutLabel;

  /// No description provided for @feedsSettingsSheetLayoutCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get feedsSettingsSheetLayoutCompact;

  /// No description provided for @feedsSettingsSheetLayoutWide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get feedsSettingsSheetLayoutWide;

  /// No description provided for @feedsSettingsSheetTrimLongPostsLabel.
  ///
  /// In en, this message translates to:
  /// **'TRIM LONG POSTS'**
  String get feedsSettingsSheetTrimLongPostsLabel;

  /// No description provided for @feedsSettingsSheetTrimLongPostsOn.
  ///
  /// In en, this message translates to:
  /// **'Collapse summary + body to a max length'**
  String get feedsSettingsSheetTrimLongPostsOn;

  /// No description provided for @feedsSettingsSheetTrimLongPostsOff.
  ///
  /// In en, this message translates to:
  /// **'Show the full post on every card'**
  String get feedsSettingsSheetTrimLongPostsOff;

  /// No description provided for @feedsSettingsSheetTranslationsLabel.
  ///
  /// In en, this message translates to:
  /// **'ON-DEVICE TRANSLATIONS'**
  String get feedsSettingsSheetTranslationsLabel;

  /// No description provided for @feedsSettingsSheetTranslationsOn.
  ///
  /// In en, this message translates to:
  /// **'Suggest translating posts in other languages'**
  String get feedsSettingsSheetTranslationsOn;

  /// No description provided for @feedsSettingsSheetTranslationsOff.
  ///
  /// In en, this message translates to:
  /// **'No translate hints on posts or comments'**
  String get feedsSettingsSheetTranslationsOff;

  /// No description provided for @feedsSettingsSheetWifiOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD PACKS OVER WI-FI ONLY'**
  String get feedsSettingsSheetWifiOnlyLabel;

  /// No description provided for @feedsSettingsSheetWifiOnlyOn.
  ///
  /// In en, this message translates to:
  /// **'Packs wait for Wi-Fi — won\'t use mobile data'**
  String get feedsSettingsSheetWifiOnlyOn;

  /// No description provided for @feedsSettingsSheetWifiOnlyOff.
  ///
  /// In en, this message translates to:
  /// **'Packs may download over mobile data'**
  String get feedsSettingsSheetWifiOnlyOff;

  /// No description provided for @feedsSettingsSheetSuggestFromLabel.
  ///
  /// In en, this message translates to:
  /// **'SUGGEST TRANSLATING FROM'**
  String get feedsSettingsSheetSuggestFromLabel;

  /// No description provided for @feedsSettingsSheetGroupLayout.
  ///
  /// In en, this message translates to:
  /// **'Layout and text'**
  String get feedsSettingsSheetGroupLayout;

  /// No description provided for @feedsSettingsSheetGroupLanding.
  ///
  /// In en, this message translates to:
  /// **'Landing'**
  String get feedsSettingsSheetGroupLanding;

  /// No description provided for @feedsSettingsSheetLandingHint.
  ///
  /// In en, this message translates to:
  /// **'Where Feeds opens.'**
  String get feedsSettingsSheetLandingHint;

  /// No description provided for @feedsSettingsSheetGroupScrolling.
  ///
  /// In en, this message translates to:
  /// **'Scrolling'**
  String get feedsSettingsSheetGroupScrolling;

  /// No description provided for @feedsSettingsSheetGroupVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get feedsSettingsSheetGroupVideo;

  /// No description provided for @feedsSettingsSheetGroupReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get feedsSettingsSheetGroupReactions;

  /// No description provided for @feedsSettingsSheetDoubleTapLabel.
  ///
  /// In en, this message translates to:
  /// **'DOUBLE TAP ADDS'**
  String get feedsSettingsSheetDoubleTapLabel;

  /// No description provided for @feedsSettingsSheetDoubleTapHint.
  ///
  /// In en, this message translates to:
  /// **'The reaction a double tap on a post adds. Tap to choose.'**
  String get feedsSettingsSheetDoubleTapHint;

  /// No description provided for @feedsSettingsSheetGroupTips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get feedsSettingsSheetGroupTips;

  /// No description provided for @feedsSettingsSheetMyTipLabel.
  ///
  /// In en, this message translates to:
  /// **'MY TIP'**
  String get feedsSettingsSheetMyTipLabel;

  /// No description provided for @feedsSettingsSheetMyTipHint.
  ///
  /// In en, this message translates to:
  /// **'Preselected when you tip a post, and what a long press on the tip button sends.'**
  String get feedsSettingsSheetMyTipHint;

  /// No description provided for @feedsSettingsSheetQuickTipLabel.
  ///
  /// In en, this message translates to:
  /// **'LONG PRESS TO TIP'**
  String get feedsSettingsSheetQuickTipLabel;

  /// No description provided for @feedsSettingsSheetQuickTipOn.
  ///
  /// In en, this message translates to:
  /// **'On: hold the tip button to send your tip to the author from your main wallet. Tap again while the ring fills to cancel.'**
  String get feedsSettingsSheetQuickTipOn;

  /// No description provided for @feedsSettingsSheetQuickTipOff.
  ///
  /// In en, this message translates to:
  /// **'Off: the tip button always opens the tip sheet.'**
  String get feedsSettingsSheetQuickTipOff;

  /// No description provided for @quickTipFailed.
  ///
  /// In en, this message translates to:
  /// **'The tip didn\'t go through.'**
  String get quickTipFailed;

  /// No description provided for @feedsSettingsSheetGroupSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get feedsSettingsSheetGroupSignature;

  /// No description provided for @feedsSettingsSheetSigShimmerLabel.
  ///
  /// In en, this message translates to:
  /// **'SIGNATURE VISUAL CONFIRMATION'**
  String get feedsSettingsSheetSigShimmerLabel;

  /// No description provided for @feedsSettingsSheetSigShimmerOn.
  ///
  /// In en, this message translates to:
  /// **'A verified author\'s name shimmers in rainbow on its own.'**
  String get feedsSettingsSheetSigShimmerOn;

  /// No description provided for @feedsSettingsSheetSigShimmerOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Only the ! marks on unsigned posts remain.'**
  String get feedsSettingsSheetSigShimmerOff;

  /// No description provided for @feedsSettingsSheetSigShimmerEveryLabel.
  ///
  /// In en, this message translates to:
  /// **'SHIMMER EVERY'**
  String get feedsSettingsSheetSigShimmerEveryLabel;

  /// No description provided for @feedsSettingsSheetSigShimmerEveryHint.
  ///
  /// In en, this message translates to:
  /// **'4 to 10 seconds between each pass.'**
  String get feedsSettingsSheetSigShimmerEveryHint;

  /// No description provided for @feedsSettingsSheetGroupTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get feedsSettingsSheetGroupTranslation;

  /// No description provided for @feedsSettingsSheetGroupSignin.
  ///
  /// In en, this message translates to:
  /// **'Channel sign-in'**
  String get feedsSettingsSheetGroupSignin;

  /// No description provided for @feedsSettingsSheetVideoAutoplayLabel.
  ///
  /// In en, this message translates to:
  /// **'AUTOPLAY VIDEOS'**
  String get feedsSettingsSheetVideoAutoplayLabel;

  /// No description provided for @feedsSettingsSheetVideoAutoplayOn.
  ///
  /// In en, this message translates to:
  /// **'Videos play muted as you scroll'**
  String get feedsSettingsSheetVideoAutoplayOn;

  /// No description provided for @feedsSettingsSheetVideoAutoplayOff.
  ///
  /// In en, this message translates to:
  /// **'Every video waits for a tap'**
  String get feedsSettingsSheetVideoAutoplayOff;

  /// No description provided for @feedsSettingsSheetVideoAutoloadLabel.
  ///
  /// In en, this message translates to:
  /// **'AUTOPLAY UP TO'**
  String get feedsSettingsSheetVideoAutoloadLabel;

  /// No description provided for @feedsSettingsSheetVideoAutoloadHint.
  ///
  /// In en, this message translates to:
  /// **'Bigger videos show their size and wait for a tap'**
  String get feedsSettingsSheetVideoAutoloadHint;

  /// No description provided for @feedsSettingsSheetVideoAlwaysAsk.
  ///
  /// In en, this message translates to:
  /// **'Always ask'**
  String get feedsSettingsSheetVideoAlwaysAsk;

  /// No description provided for @feedsSettingsSheetVideoNoLimit.
  ///
  /// In en, this message translates to:
  /// **'No limit'**
  String get feedsSettingsSheetVideoNoLimit;

  /// No description provided for @feedsSettingsSheetReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get feedsSettingsSheetReset;

  /// No description provided for @manageListsBottomSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Lists'**
  String get manageListsBottomSheetTitle;

  /// No description provided for @manageListsBottomSheetListCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 list} other{{count} lists}}'**
  String manageListsBottomSheetListCount(int count);

  /// No description provided for @manageListsBottomSheetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No lists created yet'**
  String get manageListsBottomSheetEmptyTitle;

  /// No description provided for @manageListsBottomSheetEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first list to organize RSS feeds.'**
  String get manageListsBottomSheetEmptySubtitle;

  /// No description provided for @manageListsBottomSheetDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get manageListsBottomSheetDefaultBadge;

  /// No description provided for @manageListsBottomSheetCreatedDate.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String manageListsBottomSheetCreatedDate(Object date);

  /// No description provided for @manageListsBottomSheetCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get manageListsBottomSheetCollapse;

  /// No description provided for @manageListsBottomSheetExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get manageListsBottomSheetExpand;

  /// No description provided for @manageListsBottomSheetEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get manageListsBottomSheetEditTooltip;

  /// No description provided for @manageListsBottomSheetDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get manageListsBottomSheetDeleteTooltip;

  /// No description provided for @manageListsBottomSheetNoFeeds.
  ///
  /// In en, this message translates to:
  /// **'No feeds in this list'**
  String get manageListsBottomSheetNoFeeds;

  /// No description provided for @manageListsBottomSheetRssFeedFallback.
  ///
  /// In en, this message translates to:
  /// **'RSS Feed'**
  String get manageListsBottomSheetRssFeedFallback;

  /// No description provided for @manageListsBottomSheetRemoveFromListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get manageListsBottomSheetRemoveFromListTooltip;

  /// No description provided for @manageListsBottomSheetCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create List'**
  String get manageListsBottomSheetCreateButton;

  /// No description provided for @manageListsBottomSheetRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from list'**
  String manageListsBottomSheetRemovedSnack(Object title);

  /// No description provided for @manageListsBottomSheetRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove feed from list'**
  String get manageListsBottomSheetRemoveFailed;

  /// No description provided for @manageListsBottomSheetDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Deleted list \"{name}\"'**
  String manageListsBottomSheetDeletedSnack(Object name);

  /// No description provided for @manageListsBottomSheetDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete list'**
  String get manageListsBottomSheetDeleteFailed;

  /// No description provided for @manageListsBottomSheetRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Feed'**
  String get manageListsBottomSheetRemoveDialogTitle;

  /// No description provided for @manageListsBottomSheetRemoveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Would you like to remove this feed from \"{name}\"?'**
  String manageListsBottomSheetRemoveDialogBody(Object name);

  /// No description provided for @manageListsBottomSheetRemoveButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageListsBottomSheetRemoveButton;

  /// No description provided for @manageListsBottomSheetDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete List'**
  String get manageListsBottomSheetDeleteDialogTitle;

  /// No description provided for @manageListsBottomSheetDeleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String manageListsBottomSheetDeleteDialogBody(Object name);

  /// No description provided for @manageListsBottomSheetDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: This action cannot be undone. All feeds in this list will be removed from it.'**
  String get manageListsBottomSheetDeleteWarning;

  /// No description provided for @manageListsBottomSheetDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageListsBottomSheetDeleteButton;

  /// No description provided for @manageListsBottomSheetDateToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get manageListsBottomSheetDateToday;

  /// No description provided for @manageListsBottomSheetDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get manageListsBottomSheetDateYesterday;

  /// No description provided for @manageListsBottomSheetDateDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String manageListsBottomSheetDateDaysAgo(int count);

  /// No description provided for @manageListsBottomSheetDateRecently.
  ///
  /// In en, this message translates to:
  /// **'recently'**
  String get manageListsBottomSheetDateRecently;

  /// No description provided for @manageListsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage lists'**
  String get manageListsSheetTitle;

  /// No description provided for @manageListsSheetAddFeed.
  ///
  /// In en, this message translates to:
  /// **'Add a feed'**
  String get manageListsSheetAddFeed;

  /// No description provided for @manageListsSheetDeleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get manageListsSheetDeleteListTitle;

  /// No description provided for @manageListsSheetDeleteListBody.
  ///
  /// In en, this message translates to:
  /// **'Removing \"{name}\" only removes the list — the feeds in it stay subscribed wherever else you have them.'**
  String manageListsSheetDeleteListBody(Object name);

  /// No description provided for @manageListsSheetDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageListsSheetDelete;

  /// No description provided for @manageListsSheetFailedDeleteList.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete list'**
  String get manageListsSheetFailedDeleteList;

  /// No description provided for @manageListsSheetDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get manageListsSheetDefaultBadge;

  /// No description provided for @manageListsSheetFeedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 feed} other{{count} feeds}}'**
  String manageListsSheetFeedCount(int count);

  /// No description provided for @manageListsSheetFollowedAccounts.
  ///
  /// In en, this message translates to:
  /// **'FOLLOWED ACCOUNTS'**
  String get manageListsSheetFollowedAccounts;

  /// No description provided for @manageListsSheetIndividualFeeds.
  ///
  /// In en, this message translates to:
  /// **'INDIVIDUAL FEEDS'**
  String get manageListsSheetIndividualFeeds;

  /// No description provided for @manageListsSheetFollowingEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re not following anyone yet — follow friends from their profile, or add an individual feed URL below.'**
  String get manageListsSheetFollowingEmpty;

  /// No description provided for @manageListsSheetFollowingAccount.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get manageListsSheetFollowingAccount;

  /// No description provided for @manageListsSheetMutedBadge.
  ///
  /// In en, this message translates to:
  /// **'muted'**
  String get manageListsSheetMutedBadge;

  /// No description provided for @manageListsSheetFollowingAllChannels.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{following 1 channel} other{following all {count} channels}}'**
  String manageListsSheetFollowingAllChannels(int count);

  /// No description provided for @manageListsSheetFollowingSomeChannels.
  ///
  /// In en, this message translates to:
  /// **'following {followed}/{total} channels'**
  String manageListsSheetFollowingSomeChannels(int followed, int total);

  /// No description provided for @manageListsSheetEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get manageListsSheetEditTooltip;

  /// No description provided for @manageListsSheetUnfollowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get manageListsSheetUnfollowTooltip;

  /// No description provided for @manageListsSheetCollapseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get manageListsSheetCollapseTooltip;

  /// No description provided for @manageListsSheetExpandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get manageListsSheetExpandTooltip;

  /// No description provided for @manageListsSheetFailedRequestAccess.
  ///
  /// In en, this message translates to:
  /// **'Failed to request access'**
  String get manageListsSheetFailedRequestAccess;

  /// No description provided for @manageListsSheetRemoveFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove feed?'**
  String get manageListsSheetRemoveFeedTitle;

  /// No description provided for @manageListsSheetRemoveFeedBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{feedName}\" from \"{listName}\"?'**
  String manageListsSheetRemoveFeedBody(Object feedName, Object listName);

  /// No description provided for @manageListsSheetRemovePersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove person?'**
  String get manageListsSheetRemovePersonTitle;

  /// No description provided for @manageListsSheetRemovePersonBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from \"{listName}\"? Their channels stop showing in this list.'**
  String manageListsSheetRemovePersonBody(Object name, Object listName);

  /// No description provided for @manageListSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage {listName}'**
  String manageListSheetTitle(Object listName);

  /// No description provided for @postsListNewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new} other{{count} new}}'**
  String postsListNewCount(int count);

  /// No description provided for @listHeaderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Follow someone or add a feed to get started.'**
  String get listHeaderEmpty;

  /// No description provided for @listHeaderPeopleWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{person} other{people}}'**
  String listHeaderPeopleWord(int count);

  /// No description provided for @listHeaderFeedsWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{feed} other{feeds}}'**
  String listHeaderFeedsWord(int count);

  /// No description provided for @manageListsSheetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageListsSheetRemove;

  /// No description provided for @manageListsSheetFailedRemoveFeed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove feed'**
  String get manageListsSheetFailedRemoveFeed;

  /// No description provided for @manageListsSheetNoFeedsYet.
  ///
  /// In en, this message translates to:
  /// **'No feeds in this list yet.'**
  String get manageListsSheetNoFeedsYet;

  /// No description provided for @manageListsSheetNoAccessBadge.
  ///
  /// In en, this message translates to:
  /// **'NO ACCESS'**
  String get manageListsSheetNoAccessBadge;

  /// No description provided for @manageListsSheetPendingBadge.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get manageListsSheetPendingBadge;

  /// No description provided for @manageListsSheetRequestAccessTooltip.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get manageListsSheetRequestAccessTooltip;

  /// No description provided for @manageListsSheetRemoveFromListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from list'**
  String get manageListsSheetRemoveFromListTooltip;

  /// No description provided for @manageListsSheetCreateNewList.
  ///
  /// In en, this message translates to:
  /// **'Create new list'**
  String get manageListsSheetCreateNewList;

  /// No description provided for @manageListsSheetNoListsYet.
  ///
  /// In en, this message translates to:
  /// **'No lists yet'**
  String get manageListsSheetNoListsYet;

  /// No description provided for @manageListsSheetVia.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get manageListsSheetVia;

  /// No description provided for @newPostBottomSheetFailedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create post: {error}'**
  String newPostBottomSheetFailedToCreate(Object error);

  /// No description provided for @newPostBottomSheetUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get newPostBottomSheetUnknownError;

  /// No description provided for @newPostBottomSheetErrorCreating.
  ///
  /// In en, this message translates to:
  /// **'Error creating post'**
  String get newPostBottomSheetErrorCreating;

  /// No description provided for @newPostBottomSheetErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get newPostBottomSheetErrorTitle;

  /// No description provided for @newPostBottomSheetOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get newPostBottomSheetOk;

  /// No description provided for @newPostBottomSheetDestinationChannel.
  ///
  /// In en, this message translates to:
  /// **'Destination Channel'**
  String get newPostBottomSheetDestinationChannel;

  /// No description provided for @newPostBottomSheetSelectChannelHint.
  ///
  /// In en, this message translates to:
  /// **'Select a channel for your post'**
  String get newPostBottomSheetSelectChannelHint;

  /// No description provided for @newPostBottomSheetSelectChannelError.
  ///
  /// In en, this message translates to:
  /// **'Please select a channel'**
  String get newPostBottomSheetSelectChannelError;

  /// No description provided for @newPostBottomSheetModeUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get newPostBottomSheetModeUpdate;

  /// No description provided for @newPostBottomSheetModeArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get newPostBottomSheetModeArticle;

  /// No description provided for @newPostBottomSheetNoChannelsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Channels Available'**
  String get newPostBottomSheetNoChannelsTitle;

  /// No description provided for @newPostBottomSheetNoChannelsBody.
  ///
  /// In en, this message translates to:
  /// **'Create at least one channel before posting.'**
  String get newPostBottomSheetNoChannelsBody;

  /// No description provided for @newPostBottomSheetHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPostBottomSheetHeaderTitle;

  /// No description provided for @newPostBottomSheetPostToChannel.
  ///
  /// In en, this message translates to:
  /// **'Post to {channel}'**
  String newPostBottomSheetPostToChannel(Object channel);

  /// No description provided for @newPostBottomSheetUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick update for your followers'**
  String get newPostBottomSheetUpdateSubtitle;

  /// No description provided for @newPostBottomSheetArticleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full article with all details'**
  String get newPostBottomSheetArticleSubtitle;

  /// No description provided for @newPostBottomSheetTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get newPostBottomSheetTitleLabel;

  /// No description provided for @newPostBottomSheetTitleHintUpdate.
  ///
  /// In en, this message translates to:
  /// **'Add a title (optional)'**
  String get newPostBottomSheetTitleHintUpdate;

  /// No description provided for @newPostBottomSheetTitleHintArticle.
  ///
  /// In en, this message translates to:
  /// **'Enter a compelling title...'**
  String get newPostBottomSheetTitleHintArticle;

  /// No description provided for @newPostBottomSheetContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get newPostBottomSheetContentLabel;

  /// No description provided for @newPostBottomSheetContentHintUpdate.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get newPostBottomSheetContentHintUpdate;

  /// No description provided for @newPostBottomSheetContentHintArticle.
  ///
  /// In en, this message translates to:
  /// **'Write your full post content here...'**
  String get newPostBottomSheetContentHintArticle;

  /// No description provided for @newPostBottomSheetContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get newPostBottomSheetContentRequired;

  /// No description provided for @newPostBottomSheetMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get newPostBottomSheetMediaLabel;

  /// No description provided for @newPostBottomSheetMediaHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional featured image'**
  String get newPostBottomSheetMediaHelper;

  /// No description provided for @newPostBottomSheetInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get newPostBottomSheetInvalidUrl;

  /// No description provided for @newPostBottomSheetSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get newPostBottomSheetSummaryLabel;

  /// No description provided for @newPostBottomSheetSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description for previews...'**
  String get newPostBottomSheetSummaryHint;

  /// No description provided for @newPostBottomSheetSummaryHelper.
  ///
  /// In en, this message translates to:
  /// **'Short summary shown in channel previews'**
  String get newPostBottomSheetSummaryHelper;

  /// No description provided for @newPostBottomSheetExternalLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'External Link'**
  String get newPostBottomSheetExternalLinkLabel;

  /// No description provided for @newPostBottomSheetExternalLinkHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional link to external content'**
  String get newPostBottomSheetExternalLinkHelper;

  /// No description provided for @newPostBottomSheetTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get newPostBottomSheetTagsLabel;

  /// No description provided for @newPostBottomSheetTagsHint.
  ///
  /// In en, this message translates to:
  /// **'tech, news, tutorial'**
  String get newPostBottomSheetTagsHint;

  /// No description provided for @newPostBottomSheetTagsHelper.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated tags'**
  String get newPostBottomSheetTagsHelper;

  /// No description provided for @newPostBottomSheetPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting...'**
  String get newPostBottomSheetPosting;

  /// No description provided for @newPostBottomSheetCreatePost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get newPostBottomSheetCreatePost;

  /// No description provided for @postDetailPagePostFallback.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postDetailPagePostFallback;

  /// No description provided for @postDetailPageCommentsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Comments are not available for this post'**
  String get postDetailPageCommentsUnavailable;

  /// No description provided for @postDetailPageAddReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a reply'**
  String get postDetailPageAddReplyHint;

  /// No description provided for @postDetailPageAddCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get postDetailPageAddCommentHint;

  /// No description provided for @postDetailPageReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to'**
  String get postDetailPageReplyingTo;

  /// No description provided for @postDetailPageCancelReplyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel reply'**
  String get postDetailPageCancelReplyTooltip;

  /// No description provided for @postDetailPageCannotBlockMissingSlug.
  ///
  /// In en, this message translates to:
  /// **'Cannot block: missing channel slug'**
  String get postDetailPageCannotBlockMissingSlug;

  /// No description provided for @postDetailPageBlockedFromCommenting.
  ///
  /// In en, this message translates to:
  /// **'Blocked from commenting on this post'**
  String get postDetailPageBlockedFromCommenting;

  /// No description provided for @postSourceDetailsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Post source'**
  String get postSourceDetailsPageTitle;

  /// No description provided for @postSourceDetailsPageUnknownChannel.
  ///
  /// In en, this message translates to:
  /// **'unknown channel'**
  String get postSourceDetailsPageUnknownChannel;

  /// No description provided for @postSourceDetailsPagePostedIn.
  ///
  /// In en, this message translates to:
  /// **'posted in {channel}'**
  String postSourceDetailsPagePostedIn(Object channel);

  /// No description provided for @postSourceDetailsPageDiscoveredVia.
  ///
  /// In en, this message translates to:
  /// **'DISCOVERED VIA'**
  String get postSourceDetailsPageDiscoveredVia;

  /// No description provided for @postSourceDetailsPageFoundOn.
  ///
  /// In en, this message translates to:
  /// **'Found on'**
  String get postSourceDetailsPageFoundOn;

  /// No description provided for @postSourceDetailsPageFoundOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'the profile whose record tab carries this feed URL'**
  String get postSourceDetailsPageFoundOnSubtitle;

  /// No description provided for @postSourceDetailsPageWho.
  ///
  /// In en, this message translates to:
  /// **'WHO'**
  String get postSourceDetailsPageWho;

  /// No description provided for @postSourceDetailsPageChannelOwner.
  ///
  /// In en, this message translates to:
  /// **'Channel owner'**
  String get postSourceDetailsPageChannelOwner;

  /// No description provided for @postSourceDetailsPageChannelOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'whose channel this post lives in'**
  String get postSourceDetailsPageChannelOwnerSubtitle;

  /// No description provided for @postSourceDetailsPagePostAuthor.
  ///
  /// In en, this message translates to:
  /// **'Post author'**
  String get postSourceDetailsPagePostAuthor;

  /// No description provided for @postSourceDetailsPagePostAuthorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'who created this post'**
  String get postSourceDetailsPagePostAuthorSubtitle;

  /// No description provided for @postSourceDetailsPageSignedBy.
  ///
  /// In en, this message translates to:
  /// **'Signed by'**
  String get postSourceDetailsPageSignedBy;

  /// No description provided for @postSourceDetailsPageSessionOf.
  ///
  /// In en, this message translates to:
  /// **'session of {name}'**
  String postSourceDetailsPageSessionOf(Object name);

  /// No description provided for @postSourceDetailsPageResolvingParent.
  ///
  /// In en, this message translates to:
  /// **'resolving parent account…'**
  String get postSourceDetailsPageResolvingParent;

  /// No description provided for @postSourceDetailsPageWhoHeldKey.
  ///
  /// In en, this message translates to:
  /// **'who held the key when the post was signed'**
  String get postSourceDetailsPageWhoHeldKey;

  /// No description provided for @postSourceDetailsPageTechnicalDetails.
  ///
  /// In en, this message translates to:
  /// **'TECHNICAL DETAILS'**
  String get postSourceDetailsPageTechnicalDetails;

  /// No description provided for @postSourceDetailsPageHide.
  ///
  /// In en, this message translates to:
  /// **'hide'**
  String get postSourceDetailsPageHide;

  /// No description provided for @postSourceDetailsPageShow.
  ///
  /// In en, this message translates to:
  /// **'show'**
  String get postSourceDetailsPageShow;

  /// No description provided for @postSourceDetailsPageSectionIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'IDENTIFIERS'**
  String get postSourceDetailsPageSectionIdentifiers;

  /// No description provided for @postSourceDetailsPageSectionServer.
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get postSourceDetailsPageSectionServer;

  /// No description provided for @postSourceDetailsPageSectionSource.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get postSourceDetailsPageSectionSource;

  /// No description provided for @postSourceDetailsPageSectionContent.
  ///
  /// In en, this message translates to:
  /// **'CONTENT'**
  String get postSourceDetailsPageSectionContent;

  /// No description provided for @postSourceDetailsPageSectionTimestamps.
  ///
  /// In en, this message translates to:
  /// **'TIMESTAMPS'**
  String get postSourceDetailsPageSectionTimestamps;

  /// No description provided for @postSourceDetailsPageSectionEngagement.
  ///
  /// In en, this message translates to:
  /// **'ENGAGEMENT'**
  String get postSourceDetailsPageSectionEngagement;

  /// No description provided for @postSourceDetailsPageSectionSignature.
  ///
  /// In en, this message translates to:
  /// **'SIGNATURE'**
  String get postSourceDetailsPageSectionSignature;

  /// No description provided for @postSourceDetailsPageNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get postSourceDetailsPageNone;

  /// No description provided for @postSourceDetailsPageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get postSourceDetailsPageCopied;

  /// No description provided for @postSourceDetailsPageHeroMedia.
  ///
  /// In en, this message translates to:
  /// **'HERO MEDIA ({count})'**
  String postSourceDetailsPageHeroMedia(Object count);

  /// No description provided for @postSourceDetailsPageSupportMedia.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT MEDIA ({count})'**
  String postSourceDetailsPageSupportMedia(Object count);

  /// No description provided for @postSourceDetailsPageAudio.
  ///
  /// In en, this message translates to:
  /// **'AUDIO'**
  String get postSourceDetailsPageAudio;

  /// No description provided for @postSourceDetailsPageAuthors.
  ///
  /// In en, this message translates to:
  /// **'AUTHORS ({count})'**
  String postSourceDetailsPageAuthors(Object count);

  /// No description provided for @postSourceDetailsPageTags.
  ///
  /// In en, this message translates to:
  /// **'TAGS ({count})'**
  String postSourceDetailsPageTags(Object count);

  /// No description provided for @postSourceDetailsPageSignatureChecked.
  ///
  /// In en, this message translates to:
  /// **'Signature checked'**
  String get postSourceDetailsPageSignatureChecked;

  /// No description provided for @postSourceDetailsPageSignatureChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking signature…'**
  String get postSourceDetailsPageSignatureChecking;

  /// No description provided for @postSourceDetailsPageSignatureUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Signature not checked'**
  String get postSourceDetailsPageSignatureUnchecked;

  /// No description provided for @postSourceDetailsPageBadSignature.
  ///
  /// In en, this message translates to:
  /// **'Bad signature'**
  String get postSourceDetailsPageBadSignature;

  /// No description provided for @postSourceDetailsPageNoSignature.
  ///
  /// In en, this message translates to:
  /// **'No signature'**
  String get postSourceDetailsPageNoSignature;

  /// No description provided for @postSourceDetailsPageRawJson.
  ///
  /// In en, this message translates to:
  /// **'RAW JSON'**
  String get postSourceDetailsPageRawJson;

  /// No description provided for @postSourceDetailsPageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get postSourceDetailsPageCopy;

  /// No description provided for @postSourceDetailsPageShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get postSourceDetailsPageShowLess;

  /// No description provided for @postSourceDetailsPageShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get postSourceDetailsPageShowMore;

  /// No description provided for @postsListBookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get postsListBookmarkRemoved;

  /// No description provided for @postsListPostBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Post bookmarked'**
  String get postsListPostBookmarked;

  /// No description provided for @postsListFeedNotFoundInList.
  ///
  /// In en, this message translates to:
  /// **'Could not find feed in list'**
  String get postsListFeedNotFoundInList;

  /// No description provided for @postsListFeedRemovedFromList.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{feedName}\" from list'**
  String postsListFeedRemovedFromList(Object feedName);

  /// No description provided for @postsListChannelMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted \"{channelName}\"'**
  String postsListChannelMuted(Object channelName);

  /// No description provided for @postsListRemoveFeedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove feed from list'**
  String get postsListRemoveFeedFailed;

  /// No description provided for @postsListFeedPrivate.
  ///
  /// In en, this message translates to:
  /// **'This feed is private.'**
  String get postsListFeedPrivate;

  /// No description provided for @postsListLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Feed'**
  String get postsListLoadFailedTitle;

  /// No description provided for @postsListEmptyBookmarksHeadline.
  ///
  /// In en, this message translates to:
  /// **'No bookmarked posts yet'**
  String get postsListEmptyBookmarksHeadline;

  /// No description provided for @postsListEmptyBookmarksSubline.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on any post to save it here'**
  String get postsListEmptyBookmarksSubline;

  /// No description provided for @postsListEmptyListHeadline.
  ///
  /// In en, this message translates to:
  /// **'No posts in this list yet'**
  String get postsListEmptyListHeadline;

  /// No description provided for @postsListEmptyListSubline.
  ///
  /// In en, this message translates to:
  /// **'Add feeds to this list to see their posts here.'**
  String get postsListEmptyListSubline;

  /// No description provided for @postsListEmptyHeadline.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get postsListEmptyHeadline;

  /// No description provided for @postsListEmptySubline.
  ///
  /// In en, this message translates to:
  /// **'New posts will appear here.'**
  String get postsListEmptySubline;

  /// No description provided for @postsListChannelNotFoundHeadline.
  ///
  /// In en, this message translates to:
  /// **'Channel not found'**
  String get postsListChannelNotFoundHeadline;

  /// No description provided for @postsListChannelNotFoundSubline.
  ///
  /// In en, this message translates to:
  /// **'This channel was deleted or moved by its owner.'**
  String get postsListChannelNotFoundSubline;

  /// No description provided for @postsListChannelNotFoundUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get postsListChannelNotFoundUnfollow;

  /// No description provided for @postCardFeedContextOn.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get postCardFeedContextOn;

  /// No description provided for @postCardFeedContextIn.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get postCardFeedContextIn;

  /// No description provided for @feedReaderPageUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated {ago}'**
  String feedReaderPageUpdated(String ago);

  /// No description provided for @feedReaderPageCopyFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy feed URL'**
  String get feedReaderPageCopyFeedUrl;

  /// No description provided for @feedReaderPageFeedUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Feed URL copied'**
  String get feedReaderPageFeedUrlCopied;

  /// No description provided for @postsListPrivateFeedsBanner.
  ///
  /// In en, this message translates to:
  /// **'Some feeds in this list are private and you don\'t have access.'**
  String get postsListPrivateFeedsBanner;

  /// No description provided for @privateFeedLockedWidgetNoOwnerAddress.
  ///
  /// In en, this message translates to:
  /// **'Channel has no owner address'**
  String get privateFeedLockedWidgetNoOwnerAddress;

  /// No description provided for @privateFeedLockedWidgetCouldNotResolve.
  ///
  /// In en, this message translates to:
  /// **'Could not resolve channel'**
  String get privateFeedLockedWidgetCouldNotResolve;

  /// No description provided for @privateFeedLockedWidgetRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request access'**
  String get privateFeedLockedWidgetRequestFailed;

  /// No description provided for @privateFeedLockedWidgetCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request'**
  String get privateFeedLockedWidgetCancelFailed;

  /// No description provided for @privateFeedLockedWidgetBlurbPending.
  ///
  /// In en, this message translates to:
  /// **'Your request is waiting for the channel owner to approve.'**
  String get privateFeedLockedWidgetBlurbPending;

  /// No description provided for @privateFeedLockedWidgetBlurbBlocked.
  ///
  /// In en, this message translates to:
  /// **'The channel owner has blocked your access. Reach out to them directly if you think this is a mistake.'**
  String get privateFeedLockedWidgetBlurbBlocked;

  /// No description provided for @privateFeedLockedWidgetBlurbDenied.
  ///
  /// In en, this message translates to:
  /// **'Your previous request wasn\'t approved. You can try again.'**
  String get privateFeedLockedWidgetBlurbDenied;

  /// No description provided for @privateFeedLockedWidgetBlurbDefault.
  ///
  /// In en, this message translates to:
  /// **'Only approved followers can read this channel. Send a request to the owner to be added.'**
  String get privateFeedLockedWidgetBlurbDefault;

  /// No description provided for @privateFeedLockedWidgetPrivateBadge.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get privateFeedLockedWidgetPrivateBadge;

  /// No description provided for @privateFeedLockedWidgetPendingChip.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get privateFeedLockedWidgetPendingChip;

  /// No description provided for @privateFeedLockedWidgetCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get privateFeedLockedWidgetCancelRequest;

  /// No description provided for @privateFeedLockedWidgetRequestAccess.
  ///
  /// In en, this message translates to:
  /// **'Request access'**
  String get privateFeedLockedWidgetRequestAccess;

  /// No description provided for @floatingContactMenuShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get floatingContactMenuShare;

  /// No description provided for @floatingContactMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get floatingContactMenuDelete;

  /// No description provided for @floatingContactMenuDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Contact'**
  String get floatingContactMenuDeleteTitle;

  /// No description provided for @floatingContactMenuDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{name}\" from your bookmarks?'**
  String floatingContactMenuDeleteConfirm(Object name);

  /// No description provided for @floatingContactMenuShareContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact: {name}'**
  String floatingContactMenuShareContactLabel(Object name);

  /// No description provided for @floatingContactMenuShareAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address: {address}'**
  String floatingContactMenuShareAddressLabel(Object address);

  /// No description provided for @floatingContactMenuShareInboxLabel.
  ///
  /// In en, this message translates to:
  /// **'XMTP Inbox ID: {inboxId}'**
  String floatingContactMenuShareInboxLabel(Object inboxId);

  /// No description provided for @gridSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Grid settings'**
  String get gridSettingsSheetTitle;

  /// No description provided for @gridSettingsSheetSectionLayout.
  ///
  /// In en, this message translates to:
  /// **'LAYOUT'**
  String get gridSettingsSheetSectionLayout;

  /// No description provided for @gridSettingsSheetSectionGridSize.
  ///
  /// In en, this message translates to:
  /// **'GRID SIZE'**
  String get gridSettingsSheetSectionGridSize;

  /// No description provided for @gridSettingsSheetColumnCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 column} other{{count} columns}}'**
  String gridSettingsSheetColumnCount(int count);

  /// No description provided for @gridSettingsSheetSectionTextSize.
  ///
  /// In en, this message translates to:
  /// **'TEXT SIZE'**
  String get gridSettingsSheetSectionTextSize;

  /// No description provided for @gridSettingsSheetShowBannersLabel.
  ///
  /// In en, this message translates to:
  /// **'Show contact banners'**
  String get gridSettingsSheetShowBannersLabel;

  /// No description provided for @gridSettingsSheetShowBannersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display contact banner images behind contact rows.'**
  String get gridSettingsSheetShowBannersSubtitle;

  /// No description provided for @gridSettingsSheetSectionPreview.
  ///
  /// In en, this message translates to:
  /// **'PREVIEW'**
  String get gridSettingsSheetSectionPreview;

  /// No description provided for @gridSettingsSheetPreviewText.
  ///
  /// In en, this message translates to:
  /// **'Preview text — {label}'**
  String gridSettingsSheetPreviewText(Object label);

  /// No description provided for @gridSettingsSheetLayoutGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get gridSettingsSheetLayoutGrid;

  /// No description provided for @gridSettingsSheetLayoutRows.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get gridSettingsSheetLayoutRows;

  /// No description provided for @linkDeviceDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Link this session'**
  String get linkDeviceDialogTitle;

  /// No description provided for @linkDeviceDialogSubtitleNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Pick a username + sign — show this QR to a citizen to mint your account.'**
  String get linkDeviceDialogSubtitleNewAccount;

  /// No description provided for @linkDeviceDialogSubtitleAddSession.
  ///
  /// In en, this message translates to:
  /// **'Paste your account address and sign. Then scan this QR with the app where your account is already open.'**
  String get linkDeviceDialogSubtitleAddSession;

  /// No description provided for @linkDeviceDialogToggleNewAccount.
  ///
  /// In en, this message translates to:
  /// **'NEW ACCOUNT'**
  String get linkDeviceDialogToggleNewAccount;

  /// No description provided for @linkDeviceDialogToggleAddSession.
  ///
  /// In en, this message translates to:
  /// **'ADD THIS DEVICE'**
  String get linkDeviceDialogToggleAddSession;

  /// No description provided for @linkDeviceDialogErrMinChars.
  ///
  /// In en, this message translates to:
  /// **'Min {min} chars'**
  String linkDeviceDialogErrMinChars(Object min);

  /// No description provided for @linkDeviceDialogErrMaxChars.
  ///
  /// In en, this message translates to:
  /// **'Max {max} chars'**
  String linkDeviceDialogErrMaxChars(Object max);

  /// No description provided for @linkDeviceDialogErrLeadingNonAlpha.
  ///
  /// In en, this message translates to:
  /// **'Must start with a letter'**
  String get linkDeviceDialogErrLeadingNonAlpha;

  /// No description provided for @linkDeviceDialogErrTrailing.
  ///
  /// In en, this message translates to:
  /// **'Cannot end in - or _'**
  String get linkDeviceDialogErrTrailing;

  /// No description provided for @linkDeviceDialogErrIllegalChar.
  ///
  /// In en, this message translates to:
  /// **'Allowed: a-z A-Z 0-9 - _'**
  String get linkDeviceDialogErrIllegalChar;

  /// No description provided for @linkDeviceDialogErrConsecutiveDash.
  ///
  /// In en, this message translates to:
  /// **'No consecutive --'**
  String get linkDeviceDialogErrConsecutiveDash;

  /// No description provided for @linkDeviceDialogErrConsecutiveUnderscore.
  ///
  /// In en, this message translates to:
  /// **'No consecutive __'**
  String get linkDeviceDialogErrConsecutiveUnderscore;

  /// No description provided for @linkDeviceDialogLabelUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get linkDeviceDialogLabelUsername;

  /// No description provided for @linkDeviceDialogLabelAccountAddress.
  ///
  /// In en, this message translates to:
  /// **'Account address'**
  String get linkDeviceDialogLabelAccountAddress;

  /// No description provided for @linkDeviceDialogHintUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose a username'**
  String get linkDeviceDialogHintUsername;

  /// No description provided for @linkDeviceDialogAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get linkDeviceDialogAddressCopied;

  /// No description provided for @linkDeviceDialogClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get linkDeviceDialogClose;

  /// No description provided for @linkDeviceDialogSign.
  ///
  /// In en, this message translates to:
  /// **'SIGN'**
  String get linkDeviceDialogSign;

  /// No description provided for @linkDeviceDialogRefresh.
  ///
  /// In en, this message translates to:
  /// **'REFRESH'**
  String get linkDeviceDialogRefresh;

  /// Countdown on the link-device QR; time is mm:ss.
  ///
  /// In en, this message translates to:
  /// **'QR expires in {time}'**
  String linkDeviceDialogQrExpiresIn(String time);

  /// No description provided for @linkDeviceDialogLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load saved request'**
  String get linkDeviceDialogLoadFailed;

  /// No description provided for @linkDeviceDialogSignFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign failed'**
  String get linkDeviceDialogSignFailed;

  /// No description provided for @mediaUrlFieldImageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get mediaUrlFieldImageUrlLabel;

  /// No description provided for @mediaUrlFieldClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mediaUrlFieldClearTooltip;

  /// No description provided for @mediaUrlFieldUploading.
  ///
  /// In en, this message translates to:
  /// **'UPLOADING…'**
  String get mediaUrlFieldUploading;

  /// No description provided for @mediaUrlFieldUpload.
  ///
  /// In en, this message translates to:
  /// **'UPLOAD'**
  String get mediaUrlFieldUpload;

  /// No description provided for @mediaUrlFieldLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get mediaUrlFieldLow;

  /// No description provided for @mediaUrlFieldHd.
  ///
  /// In en, this message translates to:
  /// **'HD'**
  String get mediaUrlFieldHd;

  /// No description provided for @mediaUrlFieldCheckingQuota.
  ///
  /// In en, this message translates to:
  /// **'Checking quota…'**
  String get mediaUrlFieldCheckingQuota;

  /// No description provided for @mediaUrlFieldQuotaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Quota unavailable'**
  String get mediaUrlFieldQuotaUnavailable;

  /// No description provided for @mediaUrlFieldQuotaUsage.
  ///
  /// In en, this message translates to:
  /// **'Quota: {used} MB / {total} MB'**
  String mediaUrlFieldQuotaUsage(Object used, Object total);

  /// No description provided for @mediaUrlFieldQuotaOver.
  ///
  /// In en, this message translates to:
  /// **'OVER by {amount} MB'**
  String mediaUrlFieldQuotaOver(Object amount);

  /// No description provided for @mediaUrlFieldQuotaAfter.
  ///
  /// In en, this message translates to:
  /// **'After: {amount} MB'**
  String mediaUrlFieldQuotaAfter(Object amount);

  /// No description provided for @mediaUrlFieldUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get mediaUrlFieldUploadFailed;

  /// No description provided for @mediaUrlFieldUploadBlockedSspGate.
  ///
  /// In en, this message translates to:
  /// **'Upload blocked by SSP gate'**
  String get mediaUrlFieldUploadBlockedSspGate;

  /// No description provided for @mediaUrlFieldCouldNotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get mediaUrlFieldCouldNotLoadImage;

  /// No description provided for @messageInputNoRecipientSelected.
  ///
  /// In en, this message translates to:
  /// **'No recipient selected.'**
  String get messageInputNoRecipientSelected;

  /// No description provided for @messageInputFailedStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Failed to start conversation.'**
  String get messageInputFailedStartConversation;

  /// No description provided for @messageInputFailedSendAttachmentRecipient.
  ///
  /// In en, this message translates to:
  /// **'Failed to send attachment: Recipient not available.'**
  String get messageInputFailedSendAttachmentRecipient;

  /// No description provided for @messageInputFailedSendAttachment.
  ///
  /// In en, this message translates to:
  /// **'Failed to send attachment'**
  String get messageInputFailedSendAttachment;

  /// No description provided for @messageInputFailedSendReply.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reply: Recipient not available for this chat.'**
  String get messageInputFailedSendReply;

  /// No description provided for @messageInputFailedSendRecipient.
  ///
  /// In en, this message translates to:
  /// **'Failed to send: Recipient not available for this chat.'**
  String get messageInputFailedSendRecipient;

  /// No description provided for @messageInputFailedSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get messageInputFailedSendMessage;

  /// No description provided for @messageInputNoRecipientAttachment.
  ///
  /// In en, this message translates to:
  /// **'No recipient selected to send attachment.'**
  String get messageInputNoRecipientAttachment;

  /// No description provided for @messageInputImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image too large to send. Add a feed server to send it in HD.'**
  String get messageInputImageTooLarge;

  /// No description provided for @messageInputFailedSelectAttachment.
  ///
  /// In en, this message translates to:
  /// **'Failed to select attachment'**
  String get messageInputFailedSelectAttachment;

  /// No description provided for @messageInputStickerTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Sticker larger than 1 MB'**
  String get messageInputStickerTooLarge;

  /// No description provided for @messageInputSubscribeForHd.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to an SSP or add a custom feed server to send HD images'**
  String get messageInputSubscribeForHd;

  /// No description provided for @messageInputFeedServer.
  ///
  /// In en, this message translates to:
  /// **'Feed Server'**
  String get messageInputFeedServer;

  /// No description provided for @messageInputReplyAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get messageInputReplyAttachment;

  /// No description provided for @messageInputReplyReaction.
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get messageInputReplyReaction;

  /// No description provided for @messageInputReplyReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get messageInputReplyReply;

  /// No description provided for @messageInputReplyMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageInputReplyMessage;

  /// No description provided for @messageInputReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'REPLYING TO'**
  String get messageInputReplyingTo;

  /// No description provided for @messageInputHintSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get messageInputHintSending;

  /// No description provided for @messageInputHintAddDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a description...'**
  String get messageInputHintAddDescription;

  /// No description provided for @messageInputHintTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get messageInputHintTypeMessage;

  /// No description provided for @messageInputAttachImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get messageInputAttachImage;

  /// No description provided for @messageInputAttachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get messageInputAttachDocument;

  /// No description provided for @messageInputAttachSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get messageInputAttachSend;

  /// No description provided for @messageInputAttachContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get messageInputAttachContact;

  /// No description provided for @messageInputAttachLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get messageInputAttachLocation;

  /// No description provided for @messageInputAttachComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get messageInputAttachComingSoon;

  /// No description provided for @messageInputNoRecipientRemote.
  ///
  /// In en, this message translates to:
  /// **'No recipient selected to send remote attachment.'**
  String get messageInputNoRecipientRemote;

  /// No description provided for @messageInputRemoteUrlEmpty.
  ///
  /// In en, this message translates to:
  /// **'Remote attachment URL cannot be empty.'**
  String get messageInputRemoteUrlEmpty;

  /// No description provided for @messageInputFailedSendRemoteRecipient.
  ///
  /// In en, this message translates to:
  /// **'Failed to send remote attachment: Recipient not available.'**
  String get messageInputFailedSendRemoteRecipient;

  /// No description provided for @messageInputFailedSendRemote.
  ///
  /// In en, this message translates to:
  /// **'Failed to send remote attachment'**
  String get messageInputFailedSendRemote;

  /// No description provided for @conversationSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation settings'**
  String get conversationSettingsSheetTitle;

  /// No description provided for @conversationSettingsSheetBlockConversation.
  ///
  /// In en, this message translates to:
  /// **'Block conversation'**
  String get conversationSettingsSheetBlockConversation;

  /// No description provided for @conversationSettingsSheetAllowedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages from this conversation reach your inbox.'**
  String get conversationSettingsSheetAllowedSubtitle;

  /// No description provided for @conversationSettingsSheetBlockedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This conversation is blocked.'**
  String get conversationSettingsSheetBlockedSubtitle;

  /// No description provided for @conversationSettingsSheetTrimMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Trim long messages'**
  String get conversationSettingsSheetTrimMessagesLabel;

  /// No description provided for @conversationSettingsSheetTrimMessagesOn.
  ///
  /// In en, this message translates to:
  /// **'Messages over {count} characters collapse behind a Show more. Applies to all chats.'**
  String conversationSettingsSheetTrimMessagesOn(int count);

  /// No description provided for @conversationSettingsSheetTrimMessagesOff.
  ///
  /// In en, this message translates to:
  /// **'Every message shows in full. Applies to all chats.'**
  String get conversationSettingsSheetTrimMessagesOff;

  /// No description provided for @conversationSettingsSheetTrimAtLabel.
  ///
  /// In en, this message translates to:
  /// **'TRIM AT'**
  String get conversationSettingsSheetTrimAtLabel;

  /// No description provided for @conversationSettingsSheetTrimUnit.
  ///
  /// In en, this message translates to:
  /// **'chars'**
  String get conversationSettingsSheetTrimUnit;

  /// No description provided for @conversationSettingsSheetDebugModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Debug mode'**
  String get conversationSettingsSheetDebugModeLabel;

  /// No description provided for @conversationSettingsSheetDebugModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show raw message metadata.'**
  String get conversationSettingsSheetDebugModeSubtitle;

  /// No description provided for @conversationSettingsSheetExportMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Export messages'**
  String get conversationSettingsSheetExportMessagesLabel;

  /// No description provided for @conversationSettingsSheetExportMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save chat history to a text file.'**
  String get conversationSettingsSheetExportMessagesSubtitle;

  /// No description provided for @conversationSettingsSheetDumpLogLabel.
  ///
  /// In en, this message translates to:
  /// **'Dump log'**
  String get conversationSettingsSheetDumpLogLabel;

  /// No description provided for @conversationSettingsSheetDumpLogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save recent log entries to a file.'**
  String get conversationSettingsSheetDumpLogSubtitle;

  /// No description provided for @conversationSettingsSheetConsentUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update consent state'**
  String get conversationSettingsSheetConsentUpdateFailed;

  /// No description provided for @conversationSettingsSheetLogBufferEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log buffer is empty'**
  String get conversationSettingsSheetLogBufferEmpty;

  /// No description provided for @conversationSettingsSheetDebugLogShareText.
  ///
  /// In en, this message translates to:
  /// **'PublicOS debug log ({ts})'**
  String conversationSettingsSheetDebugLogShareText(Object ts);

  /// No description provided for @conversationSettingsSheetDumpLogFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to dump log'**
  String get conversationSettingsSheetDumpLogFailed;

  /// No description provided for @conversationSettingsSheetNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages in this conversation'**
  String get conversationSettingsSheetNoMessages;

  /// No description provided for @conversationSettingsSheetSelectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range to export'**
  String get conversationSettingsSheetSelectDateRange;

  /// No description provided for @conversationSettingsSheetExportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get conversationSettingsSheetExportAction;

  /// No description provided for @conversationSettingsSheetNoMessagesInRange.
  ///
  /// In en, this message translates to:
  /// **'No messages in selected range'**
  String get conversationSettingsSheetNoMessagesInRange;

  /// No description provided for @conversationSettingsSheetChatExportShareText.
  ///
  /// In en, this message translates to:
  /// **'Chat export ({ts})'**
  String conversationSettingsSheetChatExportShareText(Object ts);

  /// No description provided for @conversationSettingsSheetExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get conversationSettingsSheetExportFailed;

  /// No description provided for @conversationSettingsSheetMediaTab.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get conversationSettingsSheetMediaTab;

  /// No description provided for @conversationSettingsSheetNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media shared in this conversation yet.'**
  String get conversationSettingsSheetNoMedia;

  /// No description provided for @conversationSettingsSheetDocsTab.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get conversationSettingsSheetDocsTab;

  /// No description provided for @conversationSettingsSheetNoDocs.
  ///
  /// In en, this message translates to:
  /// **'No documents shared in this conversation yet.'**
  String get conversationSettingsSheetNoDocs;

  /// No description provided for @debugChatViewTopicCopied.
  ///
  /// In en, this message translates to:
  /// **'Topic copied'**
  String get debugChatViewTopicCopied;

  /// No description provided for @debugChatViewMessageDataCopied.
  ///
  /// In en, this message translates to:
  /// **'Message data copied'**
  String get debugChatViewMessageDataCopied;

  /// No description provided for @messageWidgetShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get messageWidgetShowMore;

  /// No description provided for @messageWidgetShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get messageWidgetShowLess;

  /// No description provided for @messageWidgetUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Unsupported message'**
  String get messageWidgetUnsupportedMessage;

  /// No description provided for @messageWidgetUnsupportedMessageType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported message type: {type}'**
  String messageWidgetUnsupportedMessageType(Object type);

  /// No description provided for @messageWidgetTapped.
  ///
  /// In en, this message translates to:
  /// **'Tapped: {label}'**
  String messageWidgetTapped(Object label);

  /// No description provided for @messageWidgetUnknownChain.
  ///
  /// In en, this message translates to:
  /// **'Unknown chain'**
  String get messageWidgetUnknownChain;

  /// No description provided for @messageWidgetChainNumbered.
  ///
  /// In en, this message translates to:
  /// **'Chain {chainId}'**
  String messageWidgetChainNumbered(Object chainId);

  /// No description provided for @messageWidgetTransactionReceipt.
  ///
  /// In en, this message translates to:
  /// **'Transaction receipt'**
  String get messageWidgetTransactionReceipt;

  /// No description provided for @messageWidgetTxFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get messageWidgetTxFrom;

  /// No description provided for @messageWidgetTxTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get messageWidgetTxTo;

  /// No description provided for @messageWidgetTxRequestedBy.
  ///
  /// In en, this message translates to:
  /// **'Requested by'**
  String get messageWidgetTxRequestedBy;

  /// No description provided for @messageWidgetTxChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get messageWidgetTxChain;

  /// No description provided for @messageWidgetTxToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get messageWidgetTxToken;

  /// No description provided for @messageWidgetTxAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get messageWidgetTxAmount;

  /// No description provided for @messageWidgetViewOnExplorer.
  ///
  /// In en, this message translates to:
  /// **'View on explorer'**
  String get messageWidgetViewOnExplorer;

  /// No description provided for @messageWidgetReceivedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get messageWidgetReceivedPrefix;

  /// No description provided for @messageWidgetTransactionRequest.
  ///
  /// In en, this message translates to:
  /// **'Transaction request'**
  String get messageWidgetTransactionRequest;

  /// No description provided for @messageWidgetChainCalls.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count, plural, =1{1 call} other{{count} calls}}'**
  String messageWidgetChainCalls(Object name, int count);

  /// No description provided for @messageWidgetSendPrefix.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get messageWidgetSendPrefix;

  /// No description provided for @messageWidgetCallTarget.
  ///
  /// In en, this message translates to:
  /// **'Call → {target}'**
  String messageWidgetCallTarget(Object target);

  /// No description provided for @messageWidgetReviewAndPay.
  ///
  /// In en, this message translates to:
  /// **'Review & pay'**
  String get messageWidgetReviewAndPay;

  /// No description provided for @messageWidgetPayRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay request'**
  String get messageWidgetPayRequestTitle;

  /// No description provided for @messageWidgetPayRequestConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get messageWidgetPayRequestConfirm;

  /// No description provided for @messageWidgetXmtpTxRequestOrigin.
  ///
  /// In en, this message translates to:
  /// **'XMTP transaction request'**
  String get messageWidgetXmtpTxRequestOrigin;

  /// No description provided for @messageWidgetFailedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get messageWidgetFailedToLoadImage;

  /// No description provided for @messageWidgetInvalidAttachmentFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid attachment format'**
  String get messageWidgetInvalidAttachmentFormat;

  /// No description provided for @messageWidgetInvalidRemoteAttachmentFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid remote attachment format'**
  String get messageWidgetInvalidRemoteAttachmentFormat;

  /// No description provided for @messageWidgetCouldntLoadAttachment.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load attachment.\nAsk the sender to share it again.'**
  String get messageWidgetCouldntLoadAttachment;

  /// No description provided for @messageWidgetInvalidReplyFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid reply format'**
  String get messageWidgetInvalidReplyFormat;

  /// No description provided for @messageWidgetQuotedAttachment.
  ///
  /// In en, this message translates to:
  /// **'📎 Attachment'**
  String get messageWidgetQuotedAttachment;

  /// No description provided for @messageWidgetGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} attachments'**
  String messageWidgetGalleryTitle(int count);

  /// No description provided for @messageWidgetQuotedReaction.
  ///
  /// In en, this message translates to:
  /// **'❤️ Reaction'**
  String get messageWidgetQuotedReaction;

  /// No description provided for @messageWidgetQuotedReply.
  ///
  /// In en, this message translates to:
  /// **'💬 Reply'**
  String get messageWidgetQuotedReply;

  /// No description provided for @messageWidgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageWidgetMessage;

  /// No description provided for @messageWidgetYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get messageWidgetYou;

  /// No description provided for @messageWidgetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get messageWidgetLoading;

  /// No description provided for @messageWidgetMessageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Message not available'**
  String get messageWidgetMessageNotAvailable;

  /// No description provided for @messageWidgetFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send'**
  String get messageWidgetFailedToSend;

  /// No description provided for @messageWidgetSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get messageWidgetSending;

  /// No description provided for @messageWidgetSeen.
  ///
  /// In en, this message translates to:
  /// **'seen'**
  String get messageWidgetSeen;

  /// No description provided for @messageWidgetClipboardAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get messageWidgetClipboardAttachment;

  /// No description provided for @messageWidgetClipboardRemoteAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remote Attachment'**
  String get messageWidgetClipboardRemoteAttachment;

  /// No description provided for @messageWidgetClipboardReaction.
  ///
  /// In en, this message translates to:
  /// **'Reaction'**
  String get messageWidgetClipboardReaction;

  /// No description provided for @messageWidgetDismissReactions.
  ///
  /// In en, this message translates to:
  /// **'Dismiss reactions'**
  String get messageWidgetDismissReactions;

  /// No description provided for @messageWidgetStickerSaved.
  ///
  /// In en, this message translates to:
  /// **'Sticker saved'**
  String get messageWidgetStickerSaved;

  /// No description provided for @messageWidgetStickerAlreadySaved.
  ///
  /// In en, this message translates to:
  /// **'Already in your stickers'**
  String get messageWidgetStickerAlreadySaved;

  /// No description provided for @messageWidgetStickerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that sticker'**
  String get messageWidgetStickerSaveFailed;

  /// No description provided for @messagesChipBarNoKey.
  ///
  /// In en, this message translates to:
  /// **'Keychain'**
  String get messagesChipBarNoKey;

  /// No description provided for @messagesChipBarRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get messagesChipBarRequests;

  /// No description provided for @messagesChipBar1on1.
  ///
  /// In en, this message translates to:
  /// **'1-1'**
  String get messagesChipBar1on1;

  /// No description provided for @messagesChipBarGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get messagesChipBarGroups;

  /// No description provided for @messagesChipBarNewGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get messagesChipBarNewGroup;

  /// No description provided for @messagesChipBarInboxIds.
  ///
  /// In en, this message translates to:
  /// **'Inbox IDs'**
  String get messagesChipBarInboxIds;

  /// No description provided for @messagesChipBarSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get messagesChipBarSettings;

  /// No description provided for @reactionDetailsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactionDetailsSheetTitle;

  /// No description provided for @reactionDetailsSheetRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove reaction'**
  String get reactionDetailsSheetRemoveFailed;

  /// No description provided for @reactionDetailsSheetAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add reaction'**
  String get reactionDetailsSheetAddFailed;

  /// No description provided for @reactionDetailsSheetNoReactions.
  ///
  /// In en, this message translates to:
  /// **'No reactions yet.'**
  String get reactionDetailsSheetNoReactions;

  /// No description provided for @reactionDetailsSheetLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load who reacted.'**
  String get reactionDetailsSheetLoadFailed;

  /// No description provided for @reactionDetailsSheetAllTab.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reactionDetailsSheetAllTab;

  /// No description provided for @reactionDetailsSheetYouBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get reactionDetailsSheetYouBadge;

  /// No description provided for @reactionDetailsSheetRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove your reaction'**
  String get reactionDetailsSheetRemoveTooltip;

  /// No description provided for @messagesSettingsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Message settings'**
  String get messagesSettingsSheetTitle;

  /// No description provided for @messagesSettingsSheetSendReceiptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Send read receipts'**
  String get messagesSettingsSheetSendReceiptsLabel;

  /// No description provided for @messagesSettingsSheetSendReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Others can see when you\'ve read their messages.'**
  String get messagesSettingsSheetSendReceiptsSubtitle;

  /// No description provided for @messagesSettingsSheetShowReceiptsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show read receipts'**
  String get messagesSettingsSheetShowReceiptsLabel;

  /// No description provided for @messagesSettingsSheetShowReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See when others have read yours.'**
  String get messagesSettingsSheetShowReceiptsSubtitle;

  /// No description provided for @messagesSettingsSheetShowBannersLabel.
  ///
  /// In en, this message translates to:
  /// **'Show contact banners'**
  String get messagesSettingsSheetShowBannersLabel;

  /// No description provided for @messagesSettingsSheetShowBannersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display contact banner images behind conversation rows.'**
  String get messagesSettingsSheetShowBannersSubtitle;

  /// No description provided for @messagesSettingsSheetBlockedConvosLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked conversations'**
  String get messagesSettingsSheetBlockedConvosLabel;

  /// No description provided for @messagesSettingsSheetBlockedConvosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and restore blocked DMs and groups.'**
  String get messagesSettingsSheetBlockedConvosSubtitle;

  /// No description provided for @messagesSettingsSheetDownloadDbLabel.
  ///
  /// In en, this message translates to:
  /// **'Download database backup'**
  String get messagesSettingsSheetDownloadDbLabel;

  /// No description provided for @messagesSettingsSheetDownloadDbSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save this device\'s message database file. With its encryption key it restores on a new device as the SAME device — no device slot used.'**
  String get messagesSettingsSheetDownloadDbSubtitle;

  /// No description provided for @messagesSettingsSheetCopyDbKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy encryption key'**
  String get messagesSettingsSheetCopyDbKeyLabel;

  /// No description provided for @messagesSettingsSheetCopyDbKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy the key that unlocks the database backup. You need both the file and this key to restore.'**
  String get messagesSettingsSheetCopyDbKeySubtitle;

  /// No description provided for @messagesSettingsSheetDownloadDbWarning.
  ///
  /// In en, this message translates to:
  /// **'The database file is useless without its encryption key. Save both, and keep the key secret — anyone with both can read your messages.'**
  String get messagesSettingsSheetDownloadDbWarning;

  /// No description provided for @messagesSettingsSheetCopyDbKeyWarning.
  ///
  /// In en, this message translates to:
  /// **'This key unlocks your message database. Anyone with it and your database file can read your messages. Copy it somewhere safe.'**
  String get messagesSettingsSheetCopyDbKeyWarning;

  /// No description provided for @messagesSettingsSheetPreparingDb.
  ///
  /// In en, this message translates to:
  /// **'Preparing database…\n\nDo not close the app.'**
  String get messagesSettingsSheetPreparingDb;

  /// No description provided for @messagesSettingsSheetNoActiveKey.
  ///
  /// In en, this message translates to:
  /// **'No messaging key is loaded.'**
  String get messagesSettingsSheetNoActiveKey;

  /// No description provided for @messagesSettingsSheetKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Encryption key copied to clipboard.'**
  String get messagesSettingsSheetKeyCopied;

  /// No description provided for @messagesSettingsSheetDownloadBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Download backup'**
  String get messagesSettingsSheetDownloadBackupLabel;

  /// No description provided for @messagesSettingsSheetDownloadBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted archive of this inbox, protected by a password. Restores natively on any device of this account.'**
  String get messagesSettingsSheetDownloadBackupSubtitle;

  /// No description provided for @messagesSettingsSheetRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get messagesSettingsSheetRestoreBackup;

  /// No description provided for @messagesSettingsSheetRestoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import a .xmtpBak file from this account. Needs the password it was created with.'**
  String get messagesSettingsSheetRestoreBackupSubtitle;

  /// No description provided for @messagesSettingsSheetBackupPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get messagesSettingsSheetBackupPasswordTitle;

  /// No description provided for @messagesSettingsSheetBackupPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'This password encrypts your backup. You will need it to restore — there is no way to recover it if lost.'**
  String get messagesSettingsSheetBackupPasswordMessage;

  /// No description provided for @messagesSettingsSheetCreateBackup.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get messagesSettingsSheetCreateBackup;

  /// No description provided for @messagesSettingsSheetEncryptingBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypting backup…\n\nDo not close the app.'**
  String get messagesSettingsSheetEncryptingBackup;

  /// No description provided for @messagesSettingsSheetOpeningShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Opening share sheet…'**
  String get messagesSettingsSheetOpeningShareSheet;

  /// No description provided for @messagesSettingsSheetBackupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'XMTP backup'**
  String get messagesSettingsSheetBackupShareSubject;

  /// No description provided for @messagesSettingsSheetBackupReady.
  ///
  /// In en, this message translates to:
  /// **'Backup ready: {fileName}'**
  String messagesSettingsSheetBackupReady(Object fileName);

  /// No description provided for @messagesSettingsSheetBackupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed.'**
  String get messagesSettingsSheetBackupFailed;

  /// No description provided for @messagesSettingsSheetSspBackupLabel.
  ///
  /// In en, this message translates to:
  /// **'Backup to SSP'**
  String get messagesSettingsSheetSspBackupLabel;

  /// No description provided for @messagesSettingsSheetSspBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A copy on your server for 24 hours, to move your chats to another device'**
  String get messagesSettingsSheetSspBackupSubtitle;

  /// No description provided for @messagesSettingsSheetSspBackupWarning.
  ///
  /// In en, this message translates to:
  /// **'This is a short-lived backup. It is held on your server for 24 hours and deleted after that. Messages after this moment are not part of it.\n\nIf you want a long-lived copy, download the database with the other option.'**
  String get messagesSettingsSheetSspBackupWarning;

  /// No description provided for @messagesSettingsSheetSspBackupWorking.
  ///
  /// In en, this message translates to:
  /// **'Backing up to your SSP…\n\nThis might take 1 to 2 minutes. Do not leave this screen.'**
  String get messagesSettingsSheetSspBackupWorking;

  /// No description provided for @messagesSettingsSheetSspBackupDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup done'**
  String get messagesSettingsSheetSspBackupDoneTitle;

  /// No description provided for @messagesSettingsSheetSspBackupFactInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get messagesSettingsSheetSspBackupFactInbox;

  /// No description provided for @messagesSettingsSheetSspBackupFactKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get messagesSettingsSheetSspBackupFactKey;

  /// No description provided for @messagesSettingsSheetSspBackupFactSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get messagesSettingsSheetSspBackupFactSize;

  /// No description provided for @messagesSettingsSheetSspBackupFactDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted on'**
  String get messagesSettingsSheetSspBackupFactDeleted;

  /// No description provided for @messagesSettingsSheetSspBackupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup made. Your server deletes it in 24 hours.'**
  String get messagesSettingsSheetSspBackupDone;

  /// No description provided for @messagesSettingsSheetSspBackupTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Your chat database is over 100 MB, too large for this backup. Download the database with the other option.'**
  String get messagesSettingsSheetSspBackupTooLarge;

  /// No description provided for @messagesSettingsSheetSspBackupNoSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough space on your server: the backup needs {need} MB and {free} MB are free.'**
  String messagesSettingsSheetSspBackupNoSpace(int need, int free);

  /// No description provided for @keychainSetupRestoreSsp.
  ///
  /// In en, this message translates to:
  /// **'Restore from your SSP'**
  String get keychainSetupRestoreSsp;

  /// No description provided for @keychainSetupRestoreSspDetail.
  ///
  /// In en, this message translates to:
  /// **'Your server holds a backup of this key\'s chats, made {when}. Keeps your message history and does not use a device slot.'**
  String keychainSetupRestoreSspDetail(String when);

  /// No description provided for @keychainRestoreSspWorking.
  ///
  /// In en, this message translates to:
  /// **'Restoring your chats…\n\nDo not close the app.'**
  String get keychainRestoreSspWorking;

  /// No description provided for @keychainRestoreSspWrongKey.
  ///
  /// In en, this message translates to:
  /// **'This key did not make that backup.'**
  String get keychainRestoreSspWrongKey;

  /// No description provided for @keychainDeleteChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chats too?'**
  String get keychainDeleteChatsTitle;

  /// No description provided for @keychainDeleteChatsBody.
  ///
  /// In en, this message translates to:
  /// **'Also delete the chats and XMTP data on this device for this key and inbox \"{inbox}\"?\n\nThe same key under another label will also lose them. Without a backup they cannot be brought back.'**
  String keychainDeleteChatsBody(String inbox);

  /// No description provided for @keychainDeleteChatsKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep chats'**
  String get keychainDeleteChatsKeep;

  /// No description provided for @keychainDeleteChatsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete chats'**
  String get keychainDeleteChatsDelete;

  /// No description provided for @messagesSettingsSheetBackupFileTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'PublicOS XMTP backup'**
  String get messagesSettingsSheetBackupFileTypeLabel;

  /// No description provided for @messagesSettingsSheetCouldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file.'**
  String get messagesSettingsSheetCouldNotOpenFile;

  /// No description provided for @messagesSettingsSheetRestorePasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter the password this backup was created with.'**
  String get messagesSettingsSheetRestorePasswordMessage;

  /// No description provided for @messagesSettingsSheetContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get messagesSettingsSheetContinue;

  /// No description provided for @messagesSettingsSheetReadingBackup.
  ///
  /// In en, this message translates to:
  /// **'Reading backup…'**
  String get messagesSettingsSheetReadingBackup;

  /// No description provided for @messagesSettingsSheetCouldNotOpenBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not open backup'**
  String get messagesSettingsSheetCouldNotOpenBackupTitle;

  /// No description provided for @messagesSettingsSheetCouldNotOpenBackupMessage.
  ///
  /// In en, this message translates to:
  /// **'Wrong password, or this archive belongs to a different account. Nothing was imported.'**
  String get messagesSettingsSheetCouldNotOpenBackupMessage;

  /// No description provided for @messagesSettingsSheetRestoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup…\n\nDo not close the app.'**
  String get messagesSettingsSheetRestoringBackup;

  /// No description provided for @messagesSettingsSheetRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get messagesSettingsSheetRestoreFailed;

  /// No description provided for @messagesSettingsSheetPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get messagesSettingsSheetPasswordLabel;

  /// No description provided for @messagesSettingsSheetConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get messagesSettingsSheetConfirmPasswordLabel;

  /// No description provided for @messagesSettingsSheetEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get messagesSettingsSheetEnterPassword;

  /// No description provided for @messagesSettingsSheetPasswordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get messagesSettingsSheetPasswordsNoMatch;

  /// No description provided for @messagesSettingsSheetRestoreThisBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore this backup?'**
  String get messagesSettingsSheetRestoreThisBackup;

  /// No description provided for @messagesSettingsSheetMetaCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get messagesSettingsSheetMetaCreated;

  /// No description provided for @messagesSettingsSheetMetaContents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get messagesSettingsSheetMetaContents;

  /// No description provided for @messagesSettingsSheetRestoreMergeNote.
  ///
  /// In en, this message translates to:
  /// **'Restored conversations are merged into this inbox. Existing data is kept.'**
  String get messagesSettingsSheetRestoreMergeNote;

  /// No description provided for @messagesSettingsSheetRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get messagesSettingsSheetRestore;

  /// No description provided for @messagesSettingsSheetOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get messagesSettingsSheetOk;

  /// No description provided for @networkAccessSheetsExtendHeader.
  ///
  /// In en, this message translates to:
  /// **'EXTEND {provider}'**
  String networkAccessSheetsExtendHeader(Object provider);

  /// No description provided for @networkAccessSheetsRenewTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend {provider} subscription'**
  String networkAccessSheetsRenewTitle(Object provider);

  /// No description provided for @networkAccessSheetsRenewBody.
  ///
  /// In en, this message translates to:
  /// **'{provider} fee paid from your wallet to your provider.'**
  String networkAccessSheetsRenewBody(Object provider);

  /// No description provided for @networkAccessSheetsPaying.
  ///
  /// In en, this message translates to:
  /// **'PAYING…'**
  String get networkAccessSheetsPaying;

  /// No description provided for @networkAccessSheetsPayProvider.
  ///
  /// In en, this message translates to:
  /// **'PAY {provider}'**
  String networkAccessSheetsPayProvider(Object provider);

  /// No description provided for @networkAccessSheetsExtendTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend {slug}'**
  String networkAccessSheetsExtendTitle(Object slug);

  /// No description provided for @networkAccessSheetsExtendCitizenBody.
  ///
  /// In en, this message translates to:
  /// **'The network mints the {provider} fee for you. You don\'t pay anything.'**
  String networkAccessSheetsExtendCitizenBody(Object provider);

  /// No description provided for @networkAccessSheetsExtending.
  ///
  /// In en, this message translates to:
  /// **'EXTENDING…'**
  String get networkAccessSheetsExtending;

  /// No description provided for @networkAccessSheetsExtend.
  ///
  /// In en, this message translates to:
  /// **'EXTEND'**
  String get networkAccessSheetsExtend;

  /// No description provided for @networkAccessSheetsDomainRenewHeader.
  ///
  /// In en, this message translates to:
  /// **'RENEW DOMAIN'**
  String get networkAccessSheetsDomainRenewHeader;

  /// No description provided for @networkAccessSheetsDomainPay.
  ///
  /// In en, this message translates to:
  /// **'PAY DOMAIN'**
  String get networkAccessSheetsDomainPay;

  /// No description provided for @networkAccessSheetsDomainRenewTitle.
  ///
  /// In en, this message translates to:
  /// **'Renew your name'**
  String get networkAccessSheetsDomainRenewTitle;

  /// No description provided for @networkAccessSheetsDomainPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Hold your name'**
  String get networkAccessSheetsDomainPayTitle;

  /// No description provided for @networkAccessSheetsDomainBody.
  ///
  /// In en, this message translates to:
  /// **'The domain fee keeps your name and your write access to the chain. Priced by name length. 98% is burned, 2% is shared with verified PublicOS Domains.'**
  String get networkAccessSheetsDomainBody;

  /// No description provided for @networkAccessSheetsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get networkAccessSheetsName;

  /// No description provided for @networkAccessSheetsNameChars.
  ///
  /// In en, this message translates to:
  /// **'{name}  ·  {count, plural, =1{1 char} other{{count} chars}}'**
  String networkAccessSheetsNameChars(Object name, int count);

  /// No description provided for @networkAccessSheetsDomainRenewAction.
  ///
  /// In en, this message translates to:
  /// **'RENEW'**
  String get networkAccessSheetsDomainRenewAction;

  /// No description provided for @newAccountDialogErrWrongKind.
  ///
  /// In en, this message translates to:
  /// **'This claim is for adding a session, not creating an account.'**
  String get newAccountDialogErrWrongKind;

  /// No description provided for @newAccountDialogErrMalformed.
  ///
  /// In en, this message translates to:
  /// **'Malformed claim payload.'**
  String get newAccountDialogErrMalformed;

  /// No description provided for @newAccountDialogAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get newAccountDialogAccountCreated;

  /// No description provided for @newAccountDialogSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'The new account is on-chain. The scanned key is its first session.'**
  String get newAccountDialogSuccessBody;

  /// No description provided for @newAccountDialogInvalidClaim.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get newAccountDialogInvalidClaim;

  /// No description provided for @newAccountDialogClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get newAccountDialogClose;

  /// No description provided for @newAccountDialogCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get newAccountDialogCreateTitle;

  /// No description provided for @newAccountDialogSponsorPrompt.
  ///
  /// In en, this message translates to:
  /// **'Someone is asking you to sponsor a new account.'**
  String get newAccountDialogSponsorPrompt;

  /// No description provided for @newAccountDialogSponsorPromptPaused.
  ///
  /// In en, this message translates to:
  /// **'Someone is asking you to sponsor a new account. Creation is paused network-wide, so this will spend one of your invites.'**
  String get newAccountDialogSponsorPromptPaused;

  /// No description provided for @newAccountDialogLabelUsername.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get newAccountDialogLabelUsername;

  /// No description provided for @newAccountDialogLabelSession.
  ///
  /// In en, this message translates to:
  /// **'SESSION'**
  String get newAccountDialogLabelSession;

  /// No description provided for @newAccountDialogLabelExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'EXPIRES IN'**
  String get newAccountDialogLabelExpiresIn;

  /// No description provided for @newAccountDialogExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get newAccountDialogExpired;

  /// No description provided for @newAccountDialogRootInviteFree.
  ///
  /// In en, this message translates to:
  /// **'Root account — creating invite-free'**
  String get newAccountDialogRootInviteFree;

  /// No description provided for @newAccountDialogNoInvitesLeft.
  ///
  /// In en, this message translates to:
  /// **'No invites left — wait for the next wave.'**
  String get newAccountDialogNoInvitesLeft;

  /// No description provided for @newAccountDialogInvitesLeft.
  ///
  /// In en, this message translates to:
  /// **'Invites left: {count}'**
  String newAccountDialogInvitesLeft(Object count);

  /// No description provided for @newAccountDialogClaimExpired.
  ///
  /// In en, this message translates to:
  /// **'This request expired. Make a new QR where you started it.'**
  String get newAccountDialogClaimExpired;

  /// No description provided for @newAccountDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'SIGN'**
  String get newAccountDialogConfirm;

  /// No description provided for @newAccountDialogUseInvite.
  ///
  /// In en, this message translates to:
  /// **'USE INVITE'**
  String get newAccountDialogUseInvite;

  /// No description provided for @newAccountDialogReservedName.
  ///
  /// In en, this message translates to:
  /// **'Reserved name'**
  String get newAccountDialogReservedName;

  /// No description provided for @newAccountDialogNameCooldown.
  ///
  /// In en, this message translates to:
  /// **'Name in cooldown for {days}d'**
  String newAccountDialogNameCooldown(Object days);

  /// No description provided for @newAccountDialogCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get newAccountDialogCopied;

  /// No description provided for @nftInfoDialogVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get nftInfoDialogVerified;

  /// No description provided for @nftInfoDialogOwnsThisNft.
  ///
  /// In en, this message translates to:
  /// **'owns this NFT'**
  String get nftInfoDialogOwnsThisNft;

  /// No description provided for @nftInfoDialogChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get nftInfoDialogChain;

  /// No description provided for @nftInfoDialogMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get nftInfoDialogMint;

  /// No description provided for @nftInfoDialogChainNumber.
  ///
  /// In en, this message translates to:
  /// **'Chain {chain}'**
  String nftInfoDialogChainNumber(Object chain);

  /// No description provided for @nftInfoDialogContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get nftInfoDialogContract;

  /// No description provided for @nftInfoDialogTokenId.
  ///
  /// In en, this message translates to:
  /// **'Token ID'**
  String get nftInfoDialogTokenId;

  /// No description provided for @nftInfoDialogStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get nftInfoDialogStandard;

  /// No description provided for @nftInfoDialogTraits.
  ///
  /// In en, this message translates to:
  /// **'TRAITS'**
  String get nftInfoDialogTraits;

  /// No description provided for @nftInfoDialogExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get nftInfoDialogExplorer;

  /// No description provided for @nftInfoDialogMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get nftInfoDialogMarketplace;

  /// No description provided for @nftInfoDialogUseAsAvatar.
  ///
  /// In en, this message translates to:
  /// **'USE AS AVATAR'**
  String get nftInfoDialogUseAsAvatar;

  /// No description provided for @nftInfoDialogSetAsProfilePictureTitle.
  ///
  /// In en, this message translates to:
  /// **'Set as profile picture?'**
  String get nftInfoDialogSetAsProfilePictureTitle;

  /// No description provided for @nftInfoDialogSetAsProfilePictureBody.
  ///
  /// In en, this message translates to:
  /// **'This sets this NFT as your avatar. You\'ll only appear verified if you own it.'**
  String get nftInfoDialogSetAsProfilePictureBody;

  /// No description provided for @nftInfoDialogSetAsAvatar.
  ///
  /// In en, this message translates to:
  /// **'Set as avatar'**
  String get nftInfoDialogSetAsAvatar;

  /// No description provided for @nftInfoDialogCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String nftInfoDialogCopied(Object label);

  /// No description provided for @childrenSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get childrenSheetTitle;

  /// No description provided for @childrenSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 child org} other{{count} child orgs}}'**
  String childrenSheetSubtitle(int count);

  /// No description provided for @enhancedVoteCardVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{yes}/{threshold} votes'**
  String enhancedVoteCardVotesCount(Object yes, Object threshold);

  /// No description provided for @enhancedVoteCardCastVote.
  ///
  /// In en, this message translates to:
  /// **'CAST VOTE'**
  String get enhancedVoteCardCastVote;

  /// No description provided for @enhancedVoteCardSendValue.
  ///
  /// In en, this message translates to:
  /// **'Send {value}'**
  String enhancedVoteCardSendValue(Object value);

  /// No description provided for @enhancedVoteCardExecuteMethod.
  ///
  /// In en, this message translates to:
  /// **'Execute {method}'**
  String enhancedVoteCardExecuteMethod(Object method);

  /// No description provided for @enhancedVoteCardContractCall.
  ///
  /// In en, this message translates to:
  /// **'Contract Call'**
  String get enhancedVoteCardContractCall;

  /// No description provided for @enhancedVoteCardGroupWallet.
  ///
  /// In en, this message translates to:
  /// **'Group Wallet'**
  String get enhancedVoteCardGroupWallet;

  /// No description provided for @enhancedVoteCardStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get enhancedVoteCardStarted;

  /// No description provided for @enhancedVoteCardExecuted.
  ///
  /// In en, this message translates to:
  /// **'Executed'**
  String get enhancedVoteCardExecuted;

  /// No description provided for @enhancedVoteCardEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get enhancedVoteCardEnded;

  /// No description provided for @enhancedVoteCardTransactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get enhancedVoteCardTransactionDetails;

  /// No description provided for @enhancedVoteCardType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get enhancedVoteCardType;

  /// No description provided for @enhancedVoteCardEthTransfer.
  ///
  /// In en, this message translates to:
  /// **'ETH Transfer'**
  String get enhancedVoteCardEthTransfer;

  /// No description provided for @enhancedVoteCardTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get enhancedVoteCardTo;

  /// No description provided for @enhancedVoteCardAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get enhancedVoteCardAmount;

  /// No description provided for @enhancedVoteCardMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get enhancedVoteCardMethod;

  /// No description provided for @enhancedVoteCardParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get enhancedVoteCardParameters;

  /// No description provided for @enhancedVoteCardInitiatedBy.
  ///
  /// In en, this message translates to:
  /// **'Initiated by'**
  String get enhancedVoteCardInitiatedBy;

  /// No description provided for @enhancedVoteCardVotersCount.
  ///
  /// In en, this message translates to:
  /// **'Voters ({count})'**
  String enhancedVoteCardVotersCount(Object count);

  /// No description provided for @enhancedVoteCardSearchVoters.
  ///
  /// In en, this message translates to:
  /// **'Search voters...'**
  String get enhancedVoteCardSearchVoters;

  /// No description provided for @enhancedVoteCardNoVotersMatch.
  ///
  /// In en, this message translates to:
  /// **'No voters match search'**
  String get enhancedVoteCardNoVotersMatch;

  /// No description provided for @enhancedVoteCardNoVotersYet.
  ///
  /// In en, this message translates to:
  /// **'No voters yet'**
  String get enhancedVoteCardNoVotersYet;

  /// No description provided for @enhancedVoteCardMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String enhancedVoteCardMinutesAgo(Object minutes);

  /// No description provided for @enhancedVoteCardHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String enhancedVoteCardHoursAgo(Object hours);

  /// No description provided for @enhancedVoteCardDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String enhancedVoteCardDaysAgoShort(Object days);

  /// No description provided for @enhancedVoteCardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get enhancedVoteCardToday;

  /// No description provided for @enhancedVoteCardYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get enhancedVoteCardYesterday;

  /// No description provided for @enhancedVoteCardDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String enhancedVoteCardDaysAgo(int count);

  /// No description provided for @enhancedVoteCardWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String enhancedVoteCardWeeksAgo(int count);

  /// No description provided for @enhancedVoteCardTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String enhancedVoteCardTodayAt(Object time);

  /// No description provided for @enhancedVoteCardYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String enhancedVoteCardYesterdayAt(Object time);

  /// No description provided for @enhancedVoteCardWeekdayAt.
  ///
  /// In en, this message translates to:
  /// **'{weekday} {time}'**
  String enhancedVoteCardWeekdayAt(Object weekday, Object time);

  /// No description provided for @enhancedVoteCardWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get enhancedVoteCardWeekdayMon;

  /// No description provided for @enhancedVoteCardWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get enhancedVoteCardWeekdayTue;

  /// No description provided for @enhancedVoteCardWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get enhancedVoteCardWeekdayWed;

  /// No description provided for @enhancedVoteCardWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get enhancedVoteCardWeekdayThu;

  /// No description provided for @enhancedVoteCardWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get enhancedVoteCardWeekdayFri;

  /// No description provided for @enhancedVoteCardWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get enhancedVoteCardWeekdaySat;

  /// No description provided for @enhancedVoteCardWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get enhancedVoteCardWeekdaySun;

  /// No description provided for @groupVotingViewInvalidGroupAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid group address'**
  String get groupVotingViewInvalidGroupAddress;

  /// No description provided for @groupVotingViewLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load management data'**
  String get groupVotingViewLoadFailed;

  /// No description provided for @groupVotingViewVoteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Vote recorded'**
  String get groupVotingViewVoteRecorded;

  /// No description provided for @groupVotingViewUnableToCastVote.
  ///
  /// In en, this message translates to:
  /// **'Unable to cast vote'**
  String get groupVotingViewUnableToCastVote;

  /// No description provided for @groupVotingViewMembersFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} failed — {detail}'**
  String groupVotingViewMembersFailed(Object count, Object detail);

  /// No description provided for @groupVotingViewAlreadyMembers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Already a member.} other{{count} already members.}}'**
  String groupVotingViewAlreadyMembers(int count);

  /// No description provided for @groupVotingViewVotesToAddStarted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Vote to add member started.} other{{count} votes to add members started.}}'**
  String groupVotingViewVotesToAddStarted(int count);

  /// No description provided for @groupVotingViewVoteToRemoveStarted.
  ///
  /// In en, this message translates to:
  /// **'Vote to remove member started.'**
  String get groupVotingViewVoteToRemoveStarted;

  /// No description provided for @groupVotingViewQuorum.
  ///
  /// In en, this message translates to:
  /// **'Quorum'**
  String get groupVotingViewQuorum;

  /// No description provided for @groupVotingViewQuorumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share of weight that must participate'**
  String get groupVotingViewQuorumSubtitle;

  /// No description provided for @groupVotingViewVoteDuration.
  ///
  /// In en, this message translates to:
  /// **'Vote duration'**
  String get groupVotingViewVoteDuration;

  /// No description provided for @groupVotingViewVoteDurationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long a vote stays open'**
  String get groupVotingViewVoteDurationSubtitle;

  /// No description provided for @groupVotingViewDelegate.
  ///
  /// In en, this message translates to:
  /// **'Your delegate'**
  String get groupVotingViewDelegate;

  /// No description provided for @groupVotingViewDelegateNone.
  ///
  /// In en, this message translates to:
  /// **'You vote your own weight'**
  String get groupVotingViewDelegateNone;

  /// No description provided for @groupVotingViewDelegateTo.
  ///
  /// In en, this message translates to:
  /// **'Delegated to {name}'**
  String groupVotingViewDelegateTo(Object name);

  /// No description provided for @groupVotingViewMainSafe.
  ///
  /// In en, this message translates to:
  /// **'Main Safe'**
  String get groupVotingViewMainSafe;

  /// No description provided for @groupVotingViewSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get groupVotingViewSend;

  /// No description provided for @groupVotingViewAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get groupVotingViewAddressCopied;

  /// No description provided for @groupVotingViewVoting.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get groupVotingViewVoting;

  /// No description provided for @groupVotingViewVotingMetaLive.
  ///
  /// In en, this message translates to:
  /// **'1 live · {count} past'**
  String groupVotingViewVotingMetaLive(Object count);

  /// No description provided for @groupVotingViewVotingMetaPast.
  ///
  /// In en, this message translates to:
  /// **'{count} past'**
  String groupVotingViewVotingMetaPast(Object count);

  /// No description provided for @groupVotingViewActionHistory.
  ///
  /// In en, this message translates to:
  /// **'Action history'**
  String get groupVotingViewActionHistory;

  /// No description provided for @groupVotingViewNoPastActions.
  ///
  /// In en, this message translates to:
  /// **'No past actions yet'**
  String get groupVotingViewNoPastActions;

  /// No description provided for @groupVotingViewPastProposals.
  ///
  /// In en, this message translates to:
  /// **'Past proposals · executed, cancelled, expired'**
  String get groupVotingViewPastProposals;

  /// No description provided for @groupVotingViewWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get groupVotingViewWallets;

  /// No description provided for @groupVotingViewNoWallets.
  ///
  /// In en, this message translates to:
  /// **'No wallets'**
  String get groupVotingViewNoWallets;

  /// No description provided for @groupVotingViewNoWalletsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a wallet to make it part of this group'**
  String get groupVotingViewNoWalletsSubtitle;

  /// No description provided for @groupVotingViewAddWallet.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get groupVotingViewAddWallet;

  /// No description provided for @groupVotingViewRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupVotingViewRemove;

  /// No description provided for @groupVotingViewProtocolWallet.
  ///
  /// In en, this message translates to:
  /// **'{protocol} wallet'**
  String groupVotingViewProtocolWallet(Object protocol);

  /// No description provided for @groupVotingViewTagPrimary.
  ///
  /// In en, this message translates to:
  /// **'primary'**
  String get groupVotingViewTagPrimary;

  /// No description provided for @groupVotingViewRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get groupVotingViewRecords;

  /// No description provided for @groupVotingViewNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get groupVotingViewNoRecords;

  /// No description provided for @groupVotingViewNoRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Records appear here once the org sets any'**
  String get groupVotingViewNoRecordsSubtitle;

  /// No description provided for @groupVotingViewValueCopied.
  ///
  /// In en, this message translates to:
  /// **'Value copied'**
  String get groupVotingViewValueCopied;

  /// No description provided for @groupVotingViewInboxIds.
  ///
  /// In en, this message translates to:
  /// **'Inbox IDs'**
  String get groupVotingViewInboxIds;

  /// No description provided for @groupVotingViewManageInboxIds.
  ///
  /// In en, this message translates to:
  /// **'Manage inbox IDs'**
  String get groupVotingViewManageInboxIds;

  /// No description provided for @groupVotingViewManageInboxIdsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add / remove / relabel registered IDs'**
  String get groupVotingViewManageInboxIdsSubtitle;

  /// No description provided for @groupVotingViewRecordTypeProfile.
  ///
  /// In en, this message translates to:
  /// **'profile'**
  String get groupVotingViewRecordTypeProfile;

  /// No description provided for @groupVotingViewRecordTypeSettings.
  ///
  /// In en, this message translates to:
  /// **'settings'**
  String get groupVotingViewRecordTypeSettings;

  /// No description provided for @groupVotingViewRecordTypeRouter.
  ///
  /// In en, this message translates to:
  /// **'router'**
  String get groupVotingViewRecordTypeRouter;

  /// No description provided for @groupVotingViewRecordTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'custom'**
  String get groupVotingViewRecordTypeCustom;

  /// No description provided for @groupVotingViewRecordTypeSystem.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get groupVotingViewRecordTypeSystem;

  /// No description provided for @groupVotingViewExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get groupVotingViewExpired;

  /// No description provided for @groupVotingViewCopy.
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get groupVotingViewCopy;

  /// No description provided for @groupVotingViewMembers.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get groupVotingViewMembers;

  /// No description provided for @groupVotingViewParent.
  ///
  /// In en, this message translates to:
  /// **'parent'**
  String get groupVotingViewParent;

  /// No description provided for @groupVotingViewChildren.
  ///
  /// In en, this message translates to:
  /// **'children'**
  String get groupVotingViewChildren;

  /// No description provided for @groupVotingViewLiveVote.
  ///
  /// In en, this message translates to:
  /// **'LIVE VOTE'**
  String get groupVotingViewLiveVote;

  /// No description provided for @groupVotingViewVoters.
  ///
  /// In en, this message translates to:
  /// **'VOTERS'**
  String get groupVotingViewVoters;

  /// No description provided for @groupVotingViewYesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} yes'**
  String groupVotingViewYesCount(Object count);

  /// No description provided for @groupVotingViewNeededCount.
  ///
  /// In en, this message translates to:
  /// **'{count} needed'**
  String groupVotingViewNeededCount(Object count);

  /// No description provided for @delegateVoteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delegate your vote'**
  String get delegateVoteSheetTitle;

  /// No description provided for @delegateVoteSheetBlurb.
  ///
  /// In en, this message translates to:
  /// **'Pick a member to carry your voting weight. It applies to future votes, never one already open, and you can take it back anytime.'**
  String get delegateVoteSheetBlurb;

  /// No description provided for @delegateVoteSheetCap.
  ///
  /// In en, this message translates to:
  /// **'{used} of {cap} delegations used'**
  String delegateVoteSheetCap(Object used, Object cap);

  /// No description provided for @delegateVoteSheetVoteMyself.
  ///
  /// In en, this message translates to:
  /// **'Vote myself'**
  String get delegateVoteSheetVoteMyself;

  /// No description provided for @delegateVoteSheetVoteMyselfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your own voting weight'**
  String get delegateVoteSheetVoteMyselfSubtitle;

  /// No description provided for @delegateVoteSheetDelegateTo.
  ///
  /// In en, this message translates to:
  /// **'DELEGATE TO A MEMBER'**
  String get delegateVoteSheetDelegateTo;

  /// No description provided for @delegateVoteSheetNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No other members to delegate to yet'**
  String get delegateVoteSheetNoMembers;

  /// No description provided for @delegateVoteSheetConfirm.
  ///
  /// In en, this message translates to:
  /// **'DELEGATE'**
  String get delegateVoteSheetConfirm;

  /// No description provided for @delegateVoteSheetConfirmClear.
  ///
  /// In en, this message translates to:
  /// **'VOTE MYSELF'**
  String get delegateVoteSheetConfirmClear;

  /// No description provided for @delegateVoteSheetErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update delegation'**
  String get delegateVoteSheetErrorFailed;

  /// No description provided for @groupVotingViewCastYesVote.
  ///
  /// In en, this message translates to:
  /// **'CAST YES VOTE'**
  String get groupVotingViewCastYesVote;

  /// No description provided for @groupVotingViewCastFor.
  ///
  /// In en, this message translates to:
  /// **'FOR'**
  String get groupVotingViewCastFor;

  /// No description provided for @groupVotingViewCastAgainst.
  ///
  /// In en, this message translates to:
  /// **'AGAINST'**
  String get groupVotingViewCastAgainst;

  /// No description provided for @groupVotingViewCastAbstain.
  ///
  /// In en, this message translates to:
  /// **'ABSTAIN'**
  String get groupVotingViewCastAbstain;

  /// No description provided for @groupVotingViewTally.
  ///
  /// In en, this message translates to:
  /// **'For {forCount} · Against {againstCount} · Abstain {abstainCount}'**
  String groupVotingViewTally(
      Object forCount, Object againstCount, Object abstainCount);

  /// No description provided for @groupVotingViewQuorumCount.
  ///
  /// In en, this message translates to:
  /// **'{count} to quorum'**
  String groupVotingViewQuorumCount(Object count);

  /// No description provided for @groupVotingViewActionSetRecord.
  ///
  /// In en, this message translates to:
  /// **'SET RECORD'**
  String get groupVotingViewActionSetRecord;

  /// No description provided for @groupVotingViewActionDeleteRecord.
  ///
  /// In en, this message translates to:
  /// **'DELETE RECORD'**
  String get groupVotingViewActionDeleteRecord;

  /// No description provided for @groupVotingViewActionAddMember.
  ///
  /// In en, this message translates to:
  /// **'ADD MEMBER'**
  String get groupVotingViewActionAddMember;

  /// No description provided for @groupVotingViewActionRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'REMOVE MEMBER'**
  String get groupVotingViewActionRemoveMember;

  /// No description provided for @groupVotingViewActionSetThreshold.
  ///
  /// In en, this message translates to:
  /// **'SET THRESHOLD'**
  String get groupVotingViewActionSetThreshold;

  /// No description provided for @groupVotingViewActionExecuteSafeTx.
  ///
  /// In en, this message translates to:
  /// **'EXECUTE SAFE TX'**
  String get groupVotingViewActionExecuteSafeTx;

  /// No description provided for @groupVotingViewVoteEnded.
  ///
  /// In en, this message translates to:
  /// **'ended'**
  String get groupVotingViewVoteEnded;

  /// No description provided for @groupVotingViewIndividualAccount.
  ///
  /// In en, this message translates to:
  /// **'Individual Account'**
  String get groupVotingViewIndividualAccount;

  /// No description provided for @groupVotingViewIndividualAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Group governance features are only available for group accounts.'**
  String get groupVotingViewIndividualAccountBody;

  /// No description provided for @groupVotingViewTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get groupVotingViewTryAgain;

  /// No description provided for @historySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Action history'**
  String get historySheetTitle;

  /// No description provided for @historySheetPastActions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 past action} other{{count} past actions}}'**
  String historySheetPastActions(int count);

  /// No description provided for @historySheetStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get historySheetStatusCancelled;

  /// No description provided for @historySheetStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get historySheetStatusExpired;

  /// No description provided for @historySheetStatusActive.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get historySheetStatusActive;

  /// No description provided for @historySheetStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get historySheetStatusFailed;

  /// No description provided for @historySheetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No past actions'**
  String get historySheetEmptyTitle;

  /// No description provided for @historySheetEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Past proposals will appear here once any are executed, cancelled, or expired.'**
  String get historySheetEmptyBody;

  /// No description provided for @historySheetNoVotesWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{No votes this last week} other{No votes in the last {count} weeks}}'**
  String historySheetNoVotesWeeks(int count);

  /// No description provided for @historySheetWindow.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{last week} other{last {count} weeks}}'**
  String historySheetWindow(int count);

  /// No description provided for @historySheetLoadWeekBefore.
  ///
  /// In en, this message translates to:
  /// **'Load the week before'**
  String get historySheetLoadWeekBefore;

  /// No description provided for @membersSheetRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove member?'**
  String get membersSheetRemoveTitle;

  /// No description provided for @membersSheetRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Start a vote to remove {name} from this group?'**
  String membersSheetRemoveBody(Object name);

  /// No description provided for @membersSheetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get membersSheetRemove;

  /// No description provided for @membersSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersSheetTitle;

  /// No description provided for @membersSheetCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersSheetCount(num count);

  /// No description provided for @membersSheetAddMember.
  ///
  /// In en, this message translates to:
  /// **'ADD MEMBER'**
  String get membersSheetAddMember;

  /// No description provided for @startNewVoteSheetActionSetQuorum.
  ///
  /// In en, this message translates to:
  /// **'Set quorum'**
  String get startNewVoteSheetActionSetQuorum;

  /// No description provided for @startNewVoteSheetActionSetDuration.
  ///
  /// In en, this message translates to:
  /// **'Set vote duration'**
  String get startNewVoteSheetActionSetDuration;

  /// No description provided for @startNewVoteSheetActionAddWallet.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get startNewVoteSheetActionAddWallet;

  /// No description provided for @startNewVoteSheetActionRemoveWallet.
  ///
  /// In en, this message translates to:
  /// **'Remove wallet'**
  String get startNewVoteSheetActionRemoveWallet;

  /// No description provided for @startNewVoteSheetActionAddModule.
  ///
  /// In en, this message translates to:
  /// **'Add module'**
  String get startNewVoteSheetActionAddModule;

  /// No description provided for @startNewVoteSheetActionRemoveModule.
  ///
  /// In en, this message translates to:
  /// **'Remove module'**
  String get startNewVoteSheetActionRemoveModule;

  /// No description provided for @startNewVoteSheetDescSetQuorum.
  ///
  /// In en, this message translates to:
  /// **'Set the share of voting weight that must participate for a vote to pass (For + Abstain). Applies to future votes.'**
  String get startNewVoteSheetDescSetQuorum;

  /// No description provided for @startNewVoteSheetDescSetDuration.
  ///
  /// In en, this message translates to:
  /// **'Set how long a vote stays open before it expires. Applies to future votes.'**
  String get startNewVoteSheetDescSetDuration;

  /// No description provided for @startNewVoteSheetDescAddWallet.
  ///
  /// In en, this message translates to:
  /// **'Register a new wallet address for this group'**
  String get startNewVoteSheetDescAddWallet;

  /// No description provided for @startNewVoteSheetDescRemoveWallet.
  ///
  /// In en, this message translates to:
  /// **'Remove an existing wallet from this group'**
  String get startNewVoteSheetDescRemoveWallet;

  /// No description provided for @startNewVoteSheetDescAddModule.
  ///
  /// In en, this message translates to:
  /// **'Enable a module on the group Safe'**
  String get startNewVoteSheetDescAddModule;

  /// No description provided for @startNewVoteSheetDescRemoveModule.
  ///
  /// In en, this message translates to:
  /// **'Disable a module from the group Safe'**
  String get startNewVoteSheetDescRemoveModule;

  /// No description provided for @startNewVoteSheetQuorumCurrentPrefix.
  ///
  /// In en, this message translates to:
  /// **'Current quorum: '**
  String get startNewVoteSheetQuorumCurrentPrefix;

  /// No description provided for @startNewVoteSheetQuorumLabel.
  ///
  /// In en, this message translates to:
  /// **'New quorum (%)'**
  String get startNewVoteSheetQuorumLabel;

  /// No description provided for @startNewVoteSheetQuorumHint.
  ///
  /// In en, this message translates to:
  /// **'0–100 (0 = simple majority)'**
  String get startNewVoteSheetQuorumHint;

  /// No description provided for @startNewVoteSheetErrorQuorumRange.
  ///
  /// In en, this message translates to:
  /// **'Quorum must be between 0 and 100%'**
  String get startNewVoteSheetErrorQuorumRange;

  /// No description provided for @startNewVoteSheetDurationCurrentPrefix.
  ///
  /// In en, this message translates to:
  /// **'Current duration: '**
  String get startNewVoteSheetDurationCurrentPrefix;

  /// No description provided for @startNewVoteSheetDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'New duration (hours)'**
  String get startNewVoteSheetDurationLabel;

  /// No description provided for @startNewVoteSheetDurationHint.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} hours'**
  String startNewVoteSheetDurationHint(Object min, Object max);

  /// No description provided for @startNewVoteSheetDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{not set} =1{1 hour} other{{count} hours}}'**
  String startNewVoteSheetDurationHours(num count);

  /// No description provided for @startNewVoteSheetErrorDurationRange.
  ///
  /// In en, this message translates to:
  /// **'Duration must be between 1 hour and 30 days'**
  String get startNewVoteSheetErrorDurationRange;

  /// No description provided for @startNewVoteSheetErrorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load group information'**
  String get startNewVoteSheetErrorLoadFailed;

  /// No description provided for @startNewVoteSheetErrorWalletNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Wallet name is required'**
  String get startNewVoteSheetErrorWalletNameRequired;

  /// No description provided for @startNewVoteSheetErrorWalletAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Wallet address is required'**
  String get startNewVoteSheetErrorWalletAddressRequired;

  /// No description provided for @startNewVoteSheetErrorInvalidWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid wallet address format'**
  String get startNewVoteSheetErrorInvalidWalletAddress;

  /// No description provided for @startNewVoteSheetErrorSelectWallet.
  ///
  /// In en, this message translates to:
  /// **'Please select a wallet to remove'**
  String get startNewVoteSheetErrorSelectWallet;

  /// No description provided for @startNewVoteSheetErrorCannotRemoveMain.
  ///
  /// In en, this message translates to:
  /// **'Cannot remove the main wallet'**
  String get startNewVoteSheetErrorCannotRemoveMain;

  /// No description provided for @startNewVoteSheetErrorAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get startNewVoteSheetErrorAddressRequired;

  /// No description provided for @startNewVoteSheetErrorInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid address format'**
  String get startNewVoteSheetErrorInvalidAddress;

  /// No description provided for @startNewVoteSheetErrorStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to start vote. Please try again.'**
  String get startNewVoteSheetErrorStartFailed;

  /// No description provided for @startNewVoteSheetCreateProposal.
  ///
  /// In en, this message translates to:
  /// **'CREATE PROPOSAL'**
  String get startNewVoteSheetCreateProposal;

  /// No description provided for @startNewVoteSheetModuleAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Module address'**
  String get startNewVoteSheetModuleAddressLabel;

  /// No description provided for @startNewVoteSheetWalletNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet name'**
  String get startNewVoteSheetWalletNameLabel;

  /// No description provided for @startNewVoteSheetWalletNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., treasury, operations'**
  String get startNewVoteSheetWalletNameHint;

  /// No description provided for @startNewVoteSheetWalletAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet address'**
  String get startNewVoteSheetWalletAddressLabel;

  /// No description provided for @startNewVoteSheetNoRemovableWallets.
  ///
  /// In en, this message translates to:
  /// **'No additional wallets to remove. Only the main wallet exists.'**
  String get startNewVoteSheetNoRemovableWallets;

  /// No description provided for @startNewVoteSheetSelectWalletHeader.
  ///
  /// In en, this message translates to:
  /// **'SELECT WALLET'**
  String get startNewVoteSheetSelectWalletHeader;

  /// No description provided for @startNewVoteSheetProtocolWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'{protocol} wallet'**
  String startNewVoteSheetProtocolWalletTitle(Object protocol);

  /// No description provided for @startNewVoteSheetLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading group data...'**
  String get startNewVoteSheetLoading;

  /// No description provided for @voteCardCastVote.
  ///
  /// In en, this message translates to:
  /// **'CAST VOTE'**
  String get voteCardCastVote;

  /// No description provided for @voteCardPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get voteCardPending;

  /// No description provided for @voteCardVotesOfThreshold.
  ///
  /// In en, this message translates to:
  /// **' / {threshold} votes'**
  String voteCardVotesOfThreshold(Object threshold);

  /// No description provided for @voteCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get voteCardDetails;

  /// No description provided for @voteCardInitiatedBy.
  ///
  /// In en, this message translates to:
  /// **'INITIATED BY'**
  String get voteCardInitiatedBy;

  /// No description provided for @voteCardStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get voteCardStarted;

  /// No description provided for @voteCardExecuted.
  ///
  /// In en, this message translates to:
  /// **'Executed'**
  String get voteCardExecuted;

  /// No description provided for @voteCardEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get voteCardEnded;

  /// No description provided for @voteCardCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get voteCardCopy;

  /// No description provided for @voteCardCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied {name}'**
  String voteCardCopied(Object name);

  /// No description provided for @voteCardVoters.
  ///
  /// In en, this message translates to:
  /// **'Voters ({count})'**
  String voteCardVoters(Object count);

  /// No description provided for @voteCardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get voteCardSearchHint;

  /// No description provided for @voteCardNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get voteCardNoMatches;

  /// No description provided for @voteCardNoVoters.
  ///
  /// In en, this message translates to:
  /// **'No voters'**
  String get voteCardNoVoters;

  /// No description provided for @voteCardMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String voteCardMinutesAgo(Object minutes);

  /// No description provided for @voteCardHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String voteCardHoursAgo(Object hours);

  /// No description provided for @voteCardDaysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String voteCardDaysAgoShort(Object days);

  /// No description provided for @voteCardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get voteCardToday;

  /// No description provided for @voteCardYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get voteCardYesterday;

  /// No description provided for @voteCardDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day ago} other{{days} days ago}}'**
  String voteCardDaysAgo(int days);

  /// No description provided for @voteCardWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, =1{1 week ago} other{{weeks} weeks ago}}'**
  String voteCardWeeksAgo(int weeks);

  /// No description provided for @voteCardTodayAt.
  ///
  /// In en, this message translates to:
  /// **'Today {time}'**
  String voteCardTodayAt(Object time);

  /// No description provided for @voteCardYesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday {time}'**
  String voteCardYesterdayAt(Object time);

  /// No description provided for @voteCardWeekdayAt.
  ///
  /// In en, this message translates to:
  /// **'{weekday} {time}'**
  String voteCardWeekdayAt(Object weekday, Object time);

  /// No description provided for @voteCardWeekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get voteCardWeekdayMon;

  /// No description provided for @voteCardWeekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get voteCardWeekdayTue;

  /// No description provided for @voteCardWeekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get voteCardWeekdayWed;

  /// No description provided for @voteCardWeekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get voteCardWeekdayThu;

  /// No description provided for @voteCardWeekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get voteCardWeekdayFri;

  /// No description provided for @voteCardWeekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get voteCardWeekdaySat;

  /// No description provided for @voteCardWeekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get voteCardWeekdaySun;

  /// No description provided for @votersSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Voters'**
  String get votersSheetTitle;

  /// No description provided for @votersSheetVoted.
  ///
  /// In en, this message translates to:
  /// **'VOTED · {count}'**
  String votersSheetVoted(Object count);

  /// No description provided for @votersSheetPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING · {count}'**
  String votersSheetPending(Object count);

  /// No description provided for @votersSheetStatFor.
  ///
  /// In en, this message translates to:
  /// **'FOR'**
  String get votersSheetStatFor;

  /// No description provided for @votersSheetStatAgainst.
  ///
  /// In en, this message translates to:
  /// **'AGAINST'**
  String get votersSheetStatAgainst;

  /// No description provided for @votersSheetStatAbstain.
  ///
  /// In en, this message translates to:
  /// **'ABSTAIN'**
  String get votersSheetStatAbstain;

  /// No description provided for @votersSheetQuorum.
  ///
  /// In en, this message translates to:
  /// **'QUORUM'**
  String get votersSheetQuorum;

  /// No description provided for @inboxIdDropdownCopied.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID copied to clipboard'**
  String get inboxIdDropdownCopied;

  /// No description provided for @inboxIdDropdownSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Inbox ID'**
  String get inboxIdDropdownSelectTitle;

  /// No description provided for @inboxIdDropdownDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get inboxIdDropdownDefaultLabel;

  /// No description provided for @inboxIdSelectionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select InboxID for {name}'**
  String inboxIdSelectionDialogTitle(Object name);

  /// No description provided for @inboxIdSelectionDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which inbox ID to add to the group'**
  String get inboxIdSelectionDialogSubtitle;

  /// No description provided for @manageGroupInboxIdsSheetDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get manageGroupInboxIdsSheetDefaultLabel;

  /// No description provided for @manageGroupInboxIdsSheetLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load inbox IDs'**
  String get manageGroupInboxIdsSheetLoadFailed;

  /// No description provided for @manageGroupInboxIdsSheetAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed'**
  String get manageGroupInboxIdsSheetAddFailed;

  /// No description provided for @manageGroupInboxIdsSheetRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get manageGroupInboxIdsSheetRemoveFailed;

  /// No description provided for @manageGroupInboxIdsSheetLabelUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Label update failed'**
  String get manageGroupInboxIdsSheetLabelUpdateFailed;

  /// No description provided for @manageGroupInboxIdsSheetRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from group?'**
  String get manageGroupInboxIdsSheetRemoveTitle;

  /// No description provided for @manageGroupInboxIdsSheetRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\" from {group}. People will no longer be able to reach this group via this inbox ID.'**
  String manageGroupInboxIdsSheetRemoveBody(Object label, Object group);

  /// No description provided for @manageGroupInboxIdsSheetRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageGroupInboxIdsSheetRemoveConfirm;

  /// No description provided for @manageGroupInboxIdsSheetEditLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get manageGroupInboxIdsSheetEditLabelTitle;

  /// No description provided for @manageGroupInboxIdsSheetLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new label'**
  String get manageGroupInboxIdsSheetLabelHint;

  /// No description provided for @manageGroupInboxIdsSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get manageGroupInboxIdsSheetSave;

  /// No description provided for @manageGroupInboxIdsSheetSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox IDs'**
  String get manageGroupInboxIdsSheetSheetTitle;

  /// No description provided for @manageGroupInboxIdsSheetManageKeys.
  ///
  /// In en, this message translates to:
  /// **'MANAGE KEYS'**
  String get manageGroupInboxIdsSheetManageKeys;

  /// No description provided for @manageGroupInboxIdsSheetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No inbox IDs available'**
  String get manageGroupInboxIdsSheetEmptyTitle;

  /// No description provided for @manageGroupInboxIdsSheetEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Generate a key in your keychain to create inbox IDs.'**
  String get manageGroupInboxIdsSheetEmptyBody;

  /// No description provided for @manageGroupInboxIdsSheetRegisteredTo.
  ///
  /// In en, this message translates to:
  /// **'Registered to {address}'**
  String manageGroupInboxIdsSheetRegisteredTo(Object address);

  /// No description provided for @pickOrgMembersSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get pickOrgMembersSheetTitle;

  /// No description provided for @pickOrgMembersSheetSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick contacts to propose'**
  String get pickOrgMembersSheetSubtitleEmpty;

  /// No description provided for @pickOrgMembersSheetSubtitleSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 selected} other{{count} selected}}'**
  String pickOrgMembersSheetSubtitleSelected(int count);

  /// No description provided for @pickOrgMembersSheetAddButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{ADD 1 MEMBER} other{ADD {count} MEMBERS}}'**
  String pickOrgMembersSheetAddButton(int count);

  /// No description provided for @pickOrgMembersSheetNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No contacts match your search.'**
  String get pickOrgMembersSheetNoMatch;

  /// No description provided for @pickOrgMembersSheetNoContacts.
  ///
  /// In en, this message translates to:
  /// **'No PublicOS contacts available.'**
  String get pickOrgMembersSheetNoContacts;

  /// No description provided for @pickOrgMembersSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts'**
  String get pickOrgMembersSheetSearchHint;

  /// No description provided for @createRecordPageSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get createRecordPageSave;

  /// No description provided for @createRecordPageCheckingVote.
  ///
  /// In en, this message translates to:
  /// **'Checking for an open vote…'**
  String get createRecordPageCheckingVote;

  /// No description provided for @createRecordPageVoteInProgress.
  ///
  /// In en, this message translates to:
  /// **'This organization already has its maximum of open votes; save once one ends'**
  String get createRecordPageVoteInProgress;

  /// No description provided for @createRecordPageHeaderEdit.
  ///
  /// In en, this message translates to:
  /// **'EDIT RECORD'**
  String get createRecordPageHeaderEdit;

  /// No description provided for @createRecordPageHeaderAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD RECORD'**
  String get createRecordPageHeaderAdd;

  /// No description provided for @createRecordPageHeaderPickPlatform.
  ///
  /// In en, this message translates to:
  /// **'PICK PLATFORM'**
  String get createRecordPageHeaderPickPlatform;

  /// No description provided for @createRecordPageHeaderSocial.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL'**
  String get createRecordPageHeaderSocial;

  /// No description provided for @createRecordPageHeaderTextCard.
  ///
  /// In en, this message translates to:
  /// **'TEXT CARD'**
  String get createRecordPageHeaderTextCard;

  /// No description provided for @createRecordPageHeaderImage.
  ///
  /// In en, this message translates to:
  /// **'IMAGE'**
  String get createRecordPageHeaderImage;

  /// No description provided for @createRecordPageHeaderNftCard.
  ///
  /// In en, this message translates to:
  /// **'NFT CARD'**
  String get createRecordPageHeaderNftCard;

  /// No description provided for @createRecordPageHeaderAppCard.
  ///
  /// In en, this message translates to:
  /// **'APP CARD'**
  String get createRecordPageHeaderAppCard;

  /// No description provided for @createRecordPageHeaderUnknownCard.
  ///
  /// In en, this message translates to:
  /// **'CARD'**
  String get createRecordPageHeaderUnknownCard;

  /// No description provided for @createRecordPageAppCardSizeLead.
  ///
  /// In en, this message translates to:
  /// **'Published by {app}. Its picture and contents come from the app; you choose how much room it gets on your profile, and the artwork adapts.'**
  String createRecordPageAppCardSizeLead(String app);

  /// No description provided for @createRecordPageAppCardGenericApp.
  ///
  /// In en, this message translates to:
  /// **'an app'**
  String get createRecordPageAppCardGenericApp;

  /// No description provided for @createRecordPageUnknownCardBody.
  ///
  /// In en, this message translates to:
  /// **'This card is a kind this version of the app does not know how to edit, so nothing here can be changed safely.'**
  String get createRecordPageUnknownCardBody;

  /// No description provided for @createRecordPageUnknownCardHint.
  ///
  /// In en, this message translates to:
  /// **'You can still move it around your profile, or remove it.'**
  String get createRecordPageUnknownCardHint;

  /// No description provided for @createRecordPageTypeSocialLabel.
  ///
  /// In en, this message translates to:
  /// **'Social Link'**
  String get createRecordPageTypeSocialLabel;

  /// No description provided for @createRecordPageTypeSocialDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect a platform'**
  String get createRecordPageTypeSocialDesc;

  /// No description provided for @createRecordPageTypeTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Card'**
  String get createRecordPageTypeTextLabel;

  /// No description provided for @createRecordPageTypeTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Title, text, link'**
  String get createRecordPageTypeTextDesc;

  /// No description provided for @createRecordPageTypeImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get createRecordPageTypeImageLabel;

  /// No description provided for @createRecordPageTypeImageDesc.
  ///
  /// In en, this message translates to:
  /// **'Photo or graphic'**
  String get createRecordPageTypeImageDesc;

  /// No description provided for @createRecordPageTypeNftLabel.
  ///
  /// In en, this message translates to:
  /// **'NFT card'**
  String get createRecordPageTypeNftLabel;

  /// No description provided for @createRecordPageTypeNftDesc.
  ///
  /// In en, this message translates to:
  /// **'A verified NFT you own'**
  String get createRecordPageTypeNftDesc;

  /// No description provided for @createRecordPageExampleTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get createRecordPageExampleTitle;

  /// No description provided for @createRecordPageHandleHint.
  ///
  /// In en, this message translates to:
  /// **'handle'**
  String get createRecordPageHandleHint;

  /// No description provided for @createRecordPageLabelHandle.
  ///
  /// In en, this message translates to:
  /// **'HANDLE'**
  String get createRecordPageLabelHandle;

  /// No description provided for @createRecordPageLabelTitle.
  ///
  /// In en, this message translates to:
  /// **'TITLE'**
  String get createRecordPageLabelTitle;

  /// No description provided for @createRecordPageCardTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Card title'**
  String get createRecordPageCardTitleHint;

  /// No description provided for @createRecordPageLabelDescription.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get createRecordPageLabelDescription;

  /// No description provided for @createRecordPageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description text'**
  String get createRecordPageDescriptionHint;

  /// Live size of the card as stored on the chain (the chain takes at most max bytes per record).
  ///
  /// In en, this message translates to:
  /// **'{used} of {max} bytes'**
  String createRecordPageCardSize(int used, int max);

  /// No description provided for @createRecordPageCardTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long to save: {over} bytes over. Shorten the text or the link.'**
  String createRecordPageCardTooLong(int over);

  /// No description provided for @createRecordPageLabelLinkOptional.
  ///
  /// In en, this message translates to:
  /// **'LINK (OPTIONAL)'**
  String get createRecordPageLabelLinkOptional;

  /// No description provided for @createRecordPageLabelColor.
  ///
  /// In en, this message translates to:
  /// **'COLOR'**
  String get createRecordPageLabelColor;

  /// No description provided for @createRecordPageNoServerWarning.
  ///
  /// In en, this message translates to:
  /// **'Set a Social Server (SSP) to upload your own images. You can still paste an image URL below.'**
  String get createRecordPageNoServerWarning;

  /// No description provided for @createRecordPageLabelTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'TITLE (OPTIONAL)'**
  String get createRecordPageLabelTitleOptional;

  /// No description provided for @createRecordPageImageTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no title'**
  String get createRecordPageImageTitleHint;

  /// No description provided for @createRecordPageLabelWidth.
  ///
  /// In en, this message translates to:
  /// **'WIDTH'**
  String get createRecordPageLabelWidth;

  /// No description provided for @createRecordPageLabelHeight.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get createRecordPageLabelHeight;

  /// No description provided for @createRecordPageBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get createRecordPageBack;

  /// No description provided for @createRecordPageClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get createRecordPageClose;

  /// No description provided for @createRecordPageCannotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Cannot load image'**
  String get createRecordPageCannotLoadImage;

  /// No description provided for @createRecordPageNoImageYet.
  ///
  /// In en, this message translates to:
  /// **'No image yet'**
  String get createRecordPageNoImageYet;

  /// No description provided for @createRecordPageHeaderCard.
  ///
  /// In en, this message translates to:
  /// **'CARD'**
  String get createRecordPageHeaderCard;

  /// No description provided for @createRecordPageTypeCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get createRecordPageTypeCardLabel;

  /// No description provided for @createRecordPageTypeCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Image, text, color, link'**
  String get createRecordPageTypeCardDesc;

  /// No description provided for @createRecordPageLabelBackground.
  ///
  /// In en, this message translates to:
  /// **'BACKGROUND'**
  String get createRecordPageLabelBackground;

  /// No description provided for @createRecordPageBackgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get createRecordPageBackgroundColor;

  /// No description provided for @createRecordPageBackgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get createRecordPageBackgroundGradient;

  /// No description provided for @createRecordPageGradientFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get createRecordPageGradientFrom;

  /// No description provided for @createRecordPageGradientTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get createRecordPageGradientTo;

  /// No description provided for @createRecordPageImageNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get createRecordPageImageNone;

  /// No description provided for @createRecordPageImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get createRecordPageImageUpload;

  /// No description provided for @createRecordPageLabelSize.
  ///
  /// In en, this message translates to:
  /// **'SIZE'**
  String get createRecordPageLabelSize;

  /// No description provided for @createRecordPageSizeNote.
  ///
  /// In en, this message translates to:
  /// **'cells on the 4-column profile grid. Tap a square to set the corner.'**
  String get createRecordPageSizeNote;

  /// No description provided for @createRecordPageNoServerWarningCard.
  ///
  /// In en, this message translates to:
  /// **'Set a Social Server (SSP) to upload images and pick from your uploads.'**
  String get createRecordPageNoServerWarningCard;

  /// No description provided for @createTabSheetTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit tab'**
  String get createTabSheetTitleEdit;

  /// No description provided for @createTabSheetTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New tab'**
  String get createTabSheetTitleNew;

  /// No description provided for @createTabSheetKindWeb.
  ///
  /// In en, this message translates to:
  /// **'Web page'**
  String get createTabSheetKindWeb;

  /// No description provided for @createTabSheetKindChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get createTabSheetKindChannel;

  /// No description provided for @createTabSheetFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'LABEL'**
  String get createTabSheetFieldLabel;

  /// No description provided for @createTabSheetLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Tab label (e.g. My Blog)'**
  String get createTabSheetLabelHint;

  /// No description provided for @createTabSheetFieldChannelUrl.
  ///
  /// In en, this message translates to:
  /// **'CHANNEL URL'**
  String get createTabSheetFieldChannelUrl;

  /// No description provided for @createTabSheetFieldWebUrl.
  ///
  /// In en, this message translates to:
  /// **'WEB PAGE URL'**
  String get createTabSheetFieldWebUrl;

  /// No description provided for @createTabSheetFeedFormatsInfo.
  ///
  /// In en, this message translates to:
  /// **'Supports JSON Feed, RSS 2.0, and Atom formats'**
  String get createTabSheetFeedFormatsInfo;

  /// No description provided for @createTabSheetSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get createTabSheetSaving;

  /// No description provided for @createTabSheetEnterLabel.
  ///
  /// In en, this message translates to:
  /// **'ENTER A LABEL'**
  String get createTabSheetEnterLabel;

  /// No description provided for @createTabSheetEnterValidFeedUrl.
  ///
  /// In en, this message translates to:
  /// **'ENTER A VALID FEED URL'**
  String get createTabSheetEnterValidFeedUrl;

  /// No description provided for @createTabSheetEnterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'ENTER A VALID URL'**
  String get createTabSheetEnterValidUrl;

  /// No description provided for @createTabSheetSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get createTabSheetSaveChanges;

  /// No description provided for @createTabSheetCreateTab.
  ///
  /// In en, this message translates to:
  /// **'CREATE TAB'**
  String get createTabSheetCreateTab;

  /// No description provided for @createTabSheetSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save tab'**
  String get createTabSheetSaveFailed;

  /// No description provided for @editBioSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editBioSheetTitle;

  /// No description provided for @editBioSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get editBioSheetClose;

  /// No description provided for @editBioSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Write something about yourself…'**
  String get editBioSheetHint;

  /// No description provided for @editBioSheetCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/{max}'**
  String editBioSheetCharCount(Object count, Object max);

  /// No description provided for @editBioSheetSectionTextColor.
  ///
  /// In en, this message translates to:
  /// **'TEXT COLOR'**
  String get editBioSheetSectionTextColor;

  /// No description provided for @editBioSheetSectionBorder.
  ///
  /// In en, this message translates to:
  /// **'BORDER'**
  String get editBioSheetSectionBorder;

  /// No description provided for @editBioSheetShowBorder.
  ///
  /// In en, this message translates to:
  /// **'Show border'**
  String get editBioSheetShowBorder;

  /// No description provided for @editBioSheetBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Border color'**
  String get editBioSheetBorderColor;

  /// No description provided for @editBioSheetBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Border width'**
  String get editBioSheetBorderWidth;

  /// No description provided for @editBioSheetCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner radius'**
  String get editBioSheetCornerRadius;

  /// No description provided for @editBioSheetSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE BIO'**
  String get editBioSheetSave;

  /// No description provided for @editProfileBackgroundSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Background'**
  String get editProfileBackgroundSheetTitle;

  /// No description provided for @editProfileBackgroundSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get editProfileBackgroundSheetClose;

  /// No description provided for @editProfileBackgroundSheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No background'**
  String get editProfileBackgroundSheetEmpty;

  /// No description provided for @editProfileBackgroundSheetUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load image'**
  String get editProfileBackgroundSheetUnableToLoad;

  /// No description provided for @editProfileBackgroundSheetNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get editProfileBackgroundSheetNone;

  /// No description provided for @editProfileBackgroundSheetUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get editProfileBackgroundSheetUpload;

  /// No description provided for @editProfileBackgroundSheetNoServer.
  ///
  /// In en, this message translates to:
  /// **'Set a Social Server (SSP) to upload images and pick from your uploads. A direct link still works.'**
  String get editProfileBackgroundSheetNoServer;

  /// No description provided for @editProfileBackgroundSheetUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Or paste an image link'**
  String get editProfileBackgroundSheetUrlLabel;

  /// No description provided for @editProfileBackgroundSheetUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/background.jpg'**
  String get editProfileBackgroundSheetUrlHint;

  /// No description provided for @editProfileBackgroundSheetInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL'**
  String get editProfileBackgroundSheetInvalidUrl;

  /// No description provided for @editProfileBackgroundSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save Background'**
  String get editProfileBackgroundSheetSave;

  /// No description provided for @editProfileBackgroundSheetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove Background'**
  String get editProfileBackgroundSheetRemove;

  /// No description provided for @editProfileBackgroundSheetSavingToChain.
  ///
  /// In en, this message translates to:
  /// **'Saving to chain...'**
  String get editProfileBackgroundSheetSavingToChain;

  /// No description provided for @editProfileImageSheetSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get editProfileImageSheetSaving;

  /// No description provided for @editProfileImageSheetUseNft.
  ///
  /// In en, this message translates to:
  /// **'USE NFT'**
  String get editProfileImageSheetUseNft;

  /// No description provided for @editProfileImageSheetSaveNft.
  ///
  /// In en, this message translates to:
  /// **'SAVE NFT'**
  String get editProfileImageSheetSaveNft;

  /// No description provided for @editProfileImageSheetSavePicture.
  ///
  /// In en, this message translates to:
  /// **'SAVE PICTURE'**
  String get editProfileImageSheetSavePicture;

  /// No description provided for @editProfileImageSheetSaveBanner.
  ///
  /// In en, this message translates to:
  /// **'SAVE BANNER'**
  String get editProfileImageSheetSaveBanner;

  /// No description provided for @editProfileImageSheetSavingToChain.
  ///
  /// In en, this message translates to:
  /// **'Saving to chain...'**
  String get editProfileImageSheetSavingToChain;

  /// No description provided for @editProfileImageSheetSaveNftError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save NFT'**
  String get editProfileImageSheetSaveNftError;

  /// No description provided for @editProfileImageSheetSaveImageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save image'**
  String get editProfileImageSheetSaveImageError;

  /// No description provided for @editProfileImageSheetRemoveImageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove image'**
  String get editProfileImageSheetRemoveImageError;

  /// No description provided for @editProfileImageSheetRemoveAvatarConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove profile picture?'**
  String get editProfileImageSheetRemoveAvatarConfirmTitle;

  /// No description provided for @editProfileImageSheetRemoveBannerConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove banner?'**
  String get editProfileImageSheetRemoveBannerConfirmTitle;

  /// No description provided for @editProfileImageSheetRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This clears the on-chain record. The image stays on your social server (you can re-link it later).'**
  String get editProfileImageSheetRemoveConfirmBody;

  /// No description provided for @editProfileImageSheetRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get editProfileImageSheetRemoveAction;

  /// No description provided for @editProfileImageSheetNftLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load that NFT.'**
  String get editProfileImageSheetNftLoadError;

  /// No description provided for @editProfileImageSheetNftResolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving your NFT…'**
  String get editProfileImageSheetNftResolving;

  /// No description provided for @editProfileImageSheetOwnNft.
  ///
  /// In en, this message translates to:
  /// **'You own this NFT'**
  String get editProfileImageSheetOwnNft;

  /// No description provided for @editProfileImageSheetSourceImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get editProfileImageSheetSourceImage;

  /// No description provided for @editProfileImageSheetSourceImageSub.
  ///
  /// In en, this message translates to:
  /// **'Upload, paste a URL, or pick from your uploads'**
  String get editProfileImageSheetSourceImageSub;

  /// No description provided for @editProfileImageSheetSourceEth.
  ///
  /// In en, this message translates to:
  /// **'Ethereum NFT'**
  String get editProfileImageSheetSourceEth;

  /// No description provided for @editProfileImageSheetSourceEthSub.
  ///
  /// In en, this message translates to:
  /// **'Your EVM NFTs, or enter one manually'**
  String get editProfileImageSheetSourceEthSub;

  /// No description provided for @editProfileImageSheetSourceSolana.
  ///
  /// In en, this message translates to:
  /// **'Solana NFT'**
  String get editProfileImageSheetSourceSolana;

  /// No description provided for @editProfileImageSheetSourceSolanaSub.
  ///
  /// In en, this message translates to:
  /// **'Your Solana NFTs, or enter a mint'**
  String get editProfileImageSheetSourceSolanaSub;

  /// No description provided for @editProfileImageSheetSectionSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get editProfileImageSheetSectionSource;

  /// No description provided for @editProfileImageSheetSectionYourUploads.
  ///
  /// In en, this message translates to:
  /// **'Your uploads'**
  String get editProfileImageSheetSectionYourUploads;

  /// No description provided for @editProfileImageSheetSectionNftsEvm.
  ///
  /// In en, this message translates to:
  /// **'Your NFTs · EVM'**
  String get editProfileImageSheetSectionNftsEvm;

  /// No description provided for @editProfileImageSheetSectionNftsSolana.
  ///
  /// In en, this message translates to:
  /// **'Your NFTs · Solana'**
  String get editProfileImageSheetSectionNftsSolana;

  /// No description provided for @editProfileImageSheetUploadsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing uploaded yet — images you upload will appear here.'**
  String get editProfileImageSheetUploadsEmpty;

  /// No description provided for @editProfileImageSheetUploadsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your uploads.'**
  String get editProfileImageSheetUploadsError;

  /// No description provided for @editProfileImageSheetManualPromptEth.
  ///
  /// In en, this message translates to:
  /// **'Know the contract?'**
  String get editProfileImageSheetManualPromptEth;

  /// No description provided for @editProfileImageSheetManualPromptSolana.
  ///
  /// In en, this message translates to:
  /// **'Know the mint?'**
  String get editProfileImageSheetManualPromptSolana;

  /// No description provided for @editProfileImageSheetManualCta.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get editProfileImageSheetManualCta;

  /// No description provided for @editProfileImageSheetPickSourceHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a source to make a change'**
  String get editProfileImageSheetPickSourceHint;

  /// No description provided for @editProfileImageSheetFieldChain.
  ///
  /// In en, this message translates to:
  /// **'CHAIN'**
  String get editProfileImageSheetFieldChain;

  /// No description provided for @editProfileImageSheetFieldContract.
  ///
  /// In en, this message translates to:
  /// **'CONTRACT ADDRESS'**
  String get editProfileImageSheetFieldContract;

  /// No description provided for @editProfileImageSheetFieldTokenId.
  ///
  /// In en, this message translates to:
  /// **'TOKEN ID'**
  String get editProfileImageSheetFieldTokenId;

  /// No description provided for @editProfileImageSheetTokensLoading.
  ///
  /// In en, this message translates to:
  /// **'Checking which tokens you hold…'**
  String get editProfileImageSheetTokensLoading;

  /// No description provided for @editProfileImageSheetTokensOwned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You hold 1 token here — tap to use it} other{You hold {count} tokens here — tap one to use it}}'**
  String editProfileImageSheetTokensOwned(int count);

  /// No description provided for @editProfileImageSheetFieldSolanaMint.
  ///
  /// In en, this message translates to:
  /// **'SOLANA MINT'**
  String get editProfileImageSheetFieldSolanaMint;

  /// No description provided for @editProfileImageSheetFallbackNote.
  ///
  /// In en, this message translates to:
  /// **'Your image stays as a fallback if the NFT can\'t be shown. Ownership is re-checked on-chain when it renders.'**
  String get editProfileImageSheetFallbackNote;

  /// No description provided for @editProfileImageSheetNoServerAvatar.
  ///
  /// In en, this message translates to:
  /// **'Set a Social Server (SSP) to upload your own profile picture. You can still paste an image URL below.'**
  String get editProfileImageSheetNoServerAvatar;

  /// No description provided for @editProfileImageSheetNoServerBanner.
  ///
  /// In en, this message translates to:
  /// **'Set a Social Server (SSP) to upload your own banner. You can still paste an image URL below.'**
  String get editProfileImageSheetNoServerBanner;

  /// No description provided for @editProfileImageSheetTitleAvatar.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get editProfileImageSheetTitleAvatar;

  /// No description provided for @editProfileImageSheetTitleCard.
  ///
  /// In en, this message translates to:
  /// **'NFT card'**
  String get editProfileImageSheetTitleCard;

  /// No description provided for @editProfileImageSheetTitleBanner.
  ///
  /// In en, this message translates to:
  /// **'Banner'**
  String get editProfileImageSheetTitleBanner;

  /// No description provided for @editProfileImageSheetNoActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'No active account.'**
  String get editProfileImageSheetNoActiveAccount;

  /// No description provided for @editProfileImageSheetRemoveNftAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove NFT picture'**
  String get editProfileImageSheetRemoveNftAvatar;

  /// No description provided for @editProfileImageSheetRemoveNftBanner.
  ///
  /// In en, this message translates to:
  /// **'Remove NFT banner'**
  String get editProfileImageSheetRemoveNftBanner;

  /// No description provided for @editProfileImageSheetRemoveFromProfile.
  ///
  /// In en, this message translates to:
  /// **'Remove from profile'**
  String get editProfileImageSheetRemoveFromProfile;

  /// No description provided for @editProfileImageSheetClearsRecord.
  ///
  /// In en, this message translates to:
  /// **'Clears the on-chain record'**
  String get editProfileImageSheetClearsRecord;

  /// No description provided for @editProfileImageSheetClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get editProfileImageSheetClose;

  /// No description provided for @manageProfileTabsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage tabs'**
  String get manageProfileTabsSheetTitle;

  /// No description provided for @manageProfileTabsSheetGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage group tabs'**
  String get manageProfileTabsSheetGroupTitle;

  /// No description provided for @manageProfileTabsSheetLoadingWebFeedTabs.
  ///
  /// In en, this message translates to:
  /// **'Loading web & feed tabs'**
  String get manageProfileTabsSheetLoadingWebFeedTabs;

  /// No description provided for @manageProfileTabsSheetLoadingInboxTabs.
  ///
  /// In en, this message translates to:
  /// **'Loading inbox tabs'**
  String get manageProfileTabsSheetLoadingInboxTabs;

  /// No description provided for @manageProfileTabsSheetUpdatingTabs.
  ///
  /// In en, this message translates to:
  /// **'Updating tabs'**
  String get manageProfileTabsSheetUpdatingTabs;

  /// No description provided for @manageProfileTabsSheetNoAddressError.
  ///
  /// In en, this message translates to:
  /// **'No valid address found for fetching profile tabs'**
  String get manageProfileTabsSheetNoAddressError;

  /// No description provided for @manageProfileTabsSheetChatFallback.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get manageProfileTabsSheetChatFallback;

  /// No description provided for @manageProfileTabsSheetInboxLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load inbox tabs'**
  String get manageProfileTabsSheetInboxLoadError;

  /// No description provided for @manageProfileTabsSheetVoteStarted.
  ///
  /// In en, this message translates to:
  /// **'Vote started — members need to approve'**
  String get manageProfileTabsSheetVoteStarted;

  /// No description provided for @manageProfileTabsSheetTabCreated.
  ///
  /// In en, this message translates to:
  /// **'Tab created successfully.'**
  String get manageProfileTabsSheetTabCreated;

  /// No description provided for @manageProfileTabsSheetTabUpdated.
  ///
  /// In en, this message translates to:
  /// **'Tab updated successfully.'**
  String get manageProfileTabsSheetTabUpdated;

  /// No description provided for @manageProfileTabsSheetTabDeleted.
  ///
  /// In en, this message translates to:
  /// **'Tab deleted successfully.'**
  String get manageProfileTabsSheetTabDeleted;

  /// No description provided for @manageProfileTabsSheetUnnamedTab.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Tab'**
  String get manageProfileTabsSheetUnnamedTab;

  /// No description provided for @manageProfileTabsSheetDeleteTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Tab'**
  String get manageProfileTabsSheetDeleteTabTitle;

  /// No description provided for @manageProfileTabsSheetDeleteTabBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the tab \"{tabName}\"? This action cannot be undone.'**
  String manageProfileTabsSheetDeleteTabBody(Object tabName);

  /// No description provided for @manageProfileTabsSheetInboxRenamed.
  ///
  /// In en, this message translates to:
  /// **'Inbox tab renamed.'**
  String get manageProfileTabsSheetInboxRenamed;

  /// No description provided for @manageProfileTabsSheetInboxRemoved.
  ///
  /// In en, this message translates to:
  /// **'Inbox tab removed.'**
  String get manageProfileTabsSheetInboxRemoved;

  /// No description provided for @manageProfileTabsSheetRemoveInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove inbox tab'**
  String get manageProfileTabsSheetRemoveInboxTitle;

  /// No description provided for @manageProfileTabsSheetRemoveInboxBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\" from the on-chain profile. Other users will no longer see this inbox listed on this account.'**
  String manageProfileTabsSheetRemoveInboxBody(Object label);

  /// No description provided for @manageProfileTabsSheetRenameInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename inbox tab'**
  String get manageProfileTabsSheetRenameInboxTitle;

  /// No description provided for @manageProfileTabsSheetLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get manageProfileTabsSheetLabelHint;

  /// No description provided for @manageProfileTabsSheetSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get manageProfileTabsSheetSave;

  /// No description provided for @manageProfileTabsSheetActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageProfileTabsSheetActionDelete;

  /// No description provided for @manageProfileTabsSheetActionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageProfileTabsSheetActionRemove;

  /// No description provided for @manageProfileTabsSheetInboxTabsHeader.
  ///
  /// In en, this message translates to:
  /// **'INBOX TABS'**
  String get manageProfileTabsSheetInboxTabsHeader;

  /// No description provided for @manageProfileTabsSheetOnlyGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'Only group members can manage tabs'**
  String get manageProfileTabsSheetOnlyGroupMembers;

  /// No description provided for @manageProfileTabsSheetViewOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only view these tabs'**
  String get manageProfileTabsSheetViewOnly;

  /// No description provided for @manageProfileTabsSheetAddNewTab.
  ///
  /// In en, this message translates to:
  /// **'Add new tab'**
  String get manageProfileTabsSheetAddNewTab;

  /// No description provided for @manageProfileTabsSheetActiveKey.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE KEY'**
  String get manageProfileTabsSheetActiveKey;

  /// No description provided for @nftPickerGridAllChains.
  ///
  /// In en, this message translates to:
  /// **'All chains'**
  String get nftPickerGridAllChains;

  /// No description provided for @nftPickerGridChainFallback.
  ///
  /// In en, this message translates to:
  /// **'Chain {id}'**
  String nftPickerGridChainFallback(Object id);

  /// No description provided for @nftPickerGridRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get nftPickerGridRefresh;

  /// No description provided for @nftPickerGridRemoveFromRecents.
  ///
  /// In en, this message translates to:
  /// **'Remove from recents'**
  String get nftPickerGridRemoveFromRecents;

  /// No description provided for @nftPickerGridEmpty.
  ///
  /// In en, this message translates to:
  /// **'No NFTs yet. Pick one with Manual above and it\'ll show here next time. (Link a Solana wallet to see your Solana NFTs live.)'**
  String get nftPickerGridEmpty;

  /// No description provided for @nftPickerGridNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No NFTs match these filters.'**
  String get nftPickerGridNoMatch;

  /// No description provided for @nftPickerGridSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search address, token or mint'**
  String get nftPickerGridSearchHint;

  /// No description provided for @nftPickerGridMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get nftPickerGridMine;

  /// No description provided for @nftPickerGridNotMine.
  ///
  /// In en, this message translates to:
  /// **'Not mine'**
  String get nftPickerGridNotMine;

  /// No description provided for @nftPickerGridRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get nftPickerGridRecent;

  /// No description provided for @nftPickerGridOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get nftPickerGridOldest;

  /// No description provided for @recordButtonDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Record'**
  String get recordButtonDeleteTitle;

  /// No description provided for @recordButtonDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{key}\"?'**
  String recordButtonDeleteConfirm(Object key);

  /// No description provided for @recordButtonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get recordButtonDelete;

  /// No description provided for @recordButtonCouldNotLaunch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {link}'**
  String recordButtonCouldNotLaunch(Object link);

  /// No description provided for @socialStripCouldNotLaunch.
  ///
  /// In en, this message translates to:
  /// **'Could not launch {link}'**
  String socialStripCouldNotLaunch(Object link);

  /// No description provided for @socialStripIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get socialStripIcon;

  /// No description provided for @socialStripRich.
  ///
  /// In en, this message translates to:
  /// **'Rich'**
  String get socialStripRich;

  /// No description provided for @socialStripAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get socialStripAdd;

  /// No description provided for @manageProviderSheetManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage {type}'**
  String manageProviderSheetManageTitle(Object type);

  /// No description provided for @manageProviderSheetTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get manageProviderSheetTitleLabel;

  /// No description provided for @manageProviderSheetSaveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get manageProviderSheetSaveTooltip;

  /// No description provided for @manageProviderSheetEditTitleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit title'**
  String get manageProviderSheetEditTitleTooltip;

  /// No description provided for @manageProviderSheetSubscribers.
  ///
  /// In en, this message translates to:
  /// **'Subscribers: {count}'**
  String manageProviderSheetSubscribers(Object count);

  /// No description provided for @manageProviderSheetPointers.
  ///
  /// In en, this message translates to:
  /// **'Pointers'**
  String get manageProviderSheetPointers;

  /// No description provided for @manageProviderSheetNoPointers.
  ///
  /// In en, this message translates to:
  /// **'No pointers set'**
  String get manageProviderSheetNoPointers;

  /// No description provided for @manageProviderSheetEditPointerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit pointer'**
  String get manageProviderSheetEditPointerTooltip;

  /// No description provided for @manageProviderSheetRemovePointerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove pointer'**
  String get manageProviderSheetRemovePointerTooltip;

  /// No description provided for @manageProviderSheetRemovePointerTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Pointer'**
  String get manageProviderSheetRemovePointerTitle;

  /// No description provided for @manageProviderSheetRemovePointerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove pointer \"{type}\"?'**
  String manageProviderSheetRemovePointerConfirm(Object type);

  /// No description provided for @manageProviderSheetRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageProviderSheetRemove;

  /// No description provided for @manageProviderSheetPointerTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pointer type'**
  String get manageProviderSheetPointerTypeLabel;

  /// No description provided for @manageProviderSheetValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get manageProviderSheetValueLabel;

  /// No description provided for @manageProviderSheetAddPointerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add pointer'**
  String get manageProviderSheetAddPointerTooltip;

  /// No description provided for @manageProviderSheetDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {type}'**
  String manageProviderSheetDeleteTitle(Object type);

  /// No description provided for @manageProviderSheetDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {slug}? This action cannot be undone.'**
  String manageProviderSheetDeleteConfirm(Object slug);

  /// No description provided for @manageProviderSheetDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageProviderSheetDeleteButton;

  /// No description provided for @manageProviderSheetDeleted.
  ///
  /// In en, this message translates to:
  /// **'{type} \"{slug}\" deleted'**
  String manageProviderSheetDeleted(Object type, Object slug);

  /// No description provided for @providerDirectorySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{type} Directory'**
  String providerDirectorySheetTitle(Object type);

  /// No description provided for @providerDirectorySheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title...'**
  String get providerDirectorySheetSearchHint;

  /// No description provided for @providerDirectorySheetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load providers'**
  String get providerDirectorySheetLoadError;

  /// No description provided for @providerDirectorySheetNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get providerDirectorySheetNoResults;

  /// No description provided for @providerDirectorySheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No {type}s registered yet'**
  String providerDirectorySheetEmpty(Object type);

  /// No description provided for @providerDirectorySheetClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get providerDirectorySheetClearSearch;

  /// No description provided for @providerDirectorySheetCurrentChip.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get providerDirectorySheetCurrentChip;

  /// No description provided for @providerDirectorySheetRunBy.
  ///
  /// In en, this message translates to:
  /// **'Run by '**
  String get providerDirectorySheetRunBy;

  /// No description provided for @providerDirectorySheetNoPointers.
  ///
  /// In en, this message translates to:
  /// **'No configuration pointers set'**
  String get providerDirectorySheetNoPointers;

  /// No description provided for @providerDirectorySheetCurrentProvider.
  ///
  /// In en, this message translates to:
  /// **'Current provider'**
  String get providerDirectorySheetCurrentProvider;

  /// No description provided for @providerDirectorySheetChangeToProvider.
  ///
  /// In en, this message translates to:
  /// **'Change to this provider'**
  String get providerDirectorySheetChangeToProvider;

  /// No description provided for @providerDirectorySheetSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get providerDirectorySheetSubscribe;

  /// No description provided for @registerProviderSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Register {type}'**
  String registerProviderSheetTitle(Object type);

  /// No description provided for @registerProviderSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register a new {label} on-chain.'**
  String registerProviderSheetSubtitle(Object label);

  /// No description provided for @registerProviderSheetNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated. Please sign in first.'**
  String get registerProviderSheetNotAuthenticated;

  /// No description provided for @registerProviderSheetRegisteredSuccess.
  ///
  /// In en, this message translates to:
  /// **'{type} \"{slug}\" registered successfully'**
  String registerProviderSheetRegisteredSuccess(Object type, Object slug);

  /// No description provided for @registerProviderSheetSlugLabel.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get registerProviderSheetSlugLabel;

  /// No description provided for @registerProviderSheetSlugHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my-bsp-service'**
  String get registerProviderSheetSlugHint;

  /// No description provided for @registerProviderSheetSlugHelper.
  ///
  /// In en, this message translates to:
  /// **'3-32 chars, lowercase, numbers, dashes, underscores'**
  String get registerProviderSheetSlugHelper;

  /// No description provided for @registerProviderSheetSlugRequired.
  ///
  /// In en, this message translates to:
  /// **'Slug is required'**
  String get registerProviderSheetSlugRequired;

  /// No description provided for @registerProviderSheetSlugInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must be 3-32 chars: lowercase letters, numbers, dashes, underscores'**
  String get registerProviderSheetSlugInvalid;

  /// No description provided for @registerProviderSheetTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get registerProviderSheetTitleLabel;

  /// No description provided for @registerProviderSheetTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My BSP Service'**
  String get registerProviderSheetTitleHint;

  /// No description provided for @registerProviderSheetTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get registerProviderSheetTitleRequired;

  /// No description provided for @registerProviderSheetRequiredPointerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://rpc.example.com'**
  String get registerProviderSheetRequiredPointerHint;

  /// No description provided for @registerProviderSheetRequiredPointerRequired.
  ///
  /// In en, this message translates to:
  /// **'{label} is required'**
  String registerProviderSheetRequiredPointerRequired(Object label);

  /// No description provided for @registerProviderSheetRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get registerProviderSheetRegionLabel;

  /// No description provided for @registerProviderSheetRegionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. us-east, eu-west'**
  String get registerProviderSheetRegionHint;

  /// No description provided for @registerProviderSheetWebsiteLabel.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get registerProviderSheetWebsiteLabel;

  /// No description provided for @registerProviderSheetWebsiteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. https://example.com'**
  String get registerProviderSheetWebsiteHint;

  /// No description provided for @qualityToggleLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get qualityToggleLow;

  /// No description provided for @qualityToggleHd.
  ///
  /// In en, this message translates to:
  /// **'HD'**
  String get qualityToggleHd;

  /// No description provided for @secretDialogsShowSecret.
  ///
  /// In en, this message translates to:
  /// **'SHOW SECRET?'**
  String get secretDialogsShowSecret;

  /// No description provided for @secretDialogsExportWarning.
  ///
  /// In en, this message translates to:
  /// **'Never share your recovery phrase or private key with anyone. Anyone with these can access your account forever and you cannot revoke them.'**
  String get secretDialogsExportWarning;

  /// No description provided for @secretDialogsIUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND'**
  String get secretDialogsIUnderstand;

  /// No description provided for @secretDialogsExportSecret.
  ///
  /// In en, this message translates to:
  /// **'EXPORT SECRET'**
  String get secretDialogsExportSecret;

  /// No description provided for @secretDialogsExportLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPORT {label}'**
  String secretDialogsExportLabel(Object label);

  /// No description provided for @secretDialogsRecoveryPhrase.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase'**
  String get secretDialogsRecoveryPhrase;

  /// No description provided for @secretDialogsPrivateKeyHex.
  ///
  /// In en, this message translates to:
  /// **'Private key (hex)'**
  String get secretDialogsPrivateKeyHex;

  /// No description provided for @secretDialogsMnemonic.
  ///
  /// In en, this message translates to:
  /// **'MNEMONIC'**
  String get secretDialogsMnemonic;

  /// No description provided for @secretDialogsPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE KEY'**
  String get secretDialogsPrivateKey;

  /// No description provided for @secretDialogsCopy.
  ///
  /// In en, this message translates to:
  /// **'COPY'**
  String get secretDialogsCopy;

  /// No description provided for @secretDialogsDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get secretDialogsDone;

  /// No description provided for @secretDialogsKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Key copied'**
  String get secretDialogsKeyCopied;

  /// No description provided for @selectAccountScreenRestoreSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore session'**
  String get selectAccountScreenRestoreSessionFailed;

  /// No description provided for @selectAccountScreenEnterMnemonic.
  ///
  /// In en, this message translates to:
  /// **'Please enter a mnemonic phrase'**
  String get selectAccountScreenEnterMnemonic;

  /// No description provided for @selectAccountScreenKeyImported.
  ///
  /// In en, this message translates to:
  /// **'Key imported successfully'**
  String get selectAccountScreenKeyImported;

  /// No description provided for @selectAccountScreenEnterPrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Please enter a private key'**
  String get selectAccountScreenEnterPrivateKey;

  /// No description provided for @selectAccountScreenKeysActivated.
  ///
  /// In en, this message translates to:
  /// **'Keys activated successfully!'**
  String get selectAccountScreenKeysActivated;

  /// No description provided for @selectAccountScreenKeysNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Keys not linked to any account yet'**
  String get selectAccountScreenKeysNotLinked;

  /// No description provided for @selectAccountScreenAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get selectAccountScreenAddressCopied;

  /// No description provided for @selectAccountScreenAccountRemoved.
  ///
  /// In en, this message translates to:
  /// **'Account removed from this device'**
  String get selectAccountScreenAccountRemoved;

  /// No description provided for @selectAccountScreenDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get selectAccountScreenDeleteAccountFailed;

  /// No description provided for @selectAccountScreenKeyPairDeleted.
  ///
  /// In en, this message translates to:
  /// **'Key pair deleted'**
  String get selectAccountScreenKeyPairDeleted;

  /// No description provided for @selectAccountScreenDeleteKeyPairFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete key pair'**
  String get selectAccountScreenDeleteKeyPairFailed;

  /// No description provided for @selectAccountScreenAppResetComplete.
  ///
  /// In en, this message translates to:
  /// **'App reset complete'**
  String get selectAccountScreenAppResetComplete;

  /// No description provided for @selectAccountScreenRecoveryPhraseTitle.
  ///
  /// In en, this message translates to:
  /// **'RECOVERY PHRASE'**
  String get selectAccountScreenRecoveryPhraseTitle;

  /// No description provided for @selectAccountScreenRecoveryPhraseWarning.
  ///
  /// In en, this message translates to:
  /// **'Write down these 12 words. This is the only way to recover your key. Store it offline. Never share it.'**
  String get selectAccountScreenRecoveryPhraseWarning;

  /// No description provided for @selectAccountScreenImportKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Key'**
  String get selectAccountScreenImportKeyTitle;

  /// No description provided for @selectAccountScreenImportKeySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import using mnemonic or private key'**
  String get selectAccountScreenImportKeySubtitle;

  /// No description provided for @selectAccountScreenDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE ACCOUNT'**
  String get selectAccountScreenDeleteAccountTitle;

  /// No description provided for @selectAccountScreenDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Removes \"{displayName}\" from THIS DEVICE only — its keys, messages, contacts, and settings stored here.'**
  String selectAccountScreenDeleteAccountBody(Object displayName);

  /// No description provided for @selectAccountScreenDeleteAccountNote.
  ///
  /// In en, this message translates to:
  /// **'The on-chain account itself is NOT deleted. You can add it back later with its recovery phrase or private key — without that backup, access from this device is lost.'**
  String get selectAccountScreenDeleteAccountNote;

  /// No description provided for @selectAccountScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get selectAccountScreenDelete;

  /// No description provided for @selectAccountScreenDeleteKeyPairTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE KEY PAIR'**
  String get selectAccountScreenDeleteKeyPairTitle;

  /// No description provided for @selectAccountScreenDeleteKeyPairBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Make sure you have backed up your recovery phrase.'**
  String get selectAccountScreenDeleteKeyPairBody;

  /// No description provided for @selectAccountScreenResetAppTitle.
  ///
  /// In en, this message translates to:
  /// **'RESET APP'**
  String get selectAccountScreenResetAppTitle;

  /// No description provided for @selectAccountScreenResetAppHeading.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete.'**
  String get selectAccountScreenResetAppHeading;

  /// No description provided for @selectAccountScreenResetItemMessages.
  ///
  /// In en, this message translates to:
  /// **'All messages and conversations'**
  String get selectAccountScreenResetItemMessages;

  /// No description provided for @selectAccountScreenResetItemContacts.
  ///
  /// In en, this message translates to:
  /// **'All contacts and groups'**
  String get selectAccountScreenResetItemContacts;

  /// No description provided for @selectAccountScreenResetItemKeys.
  ///
  /// In en, this message translates to:
  /// **'All key pairs and accounts'**
  String get selectAccountScreenResetItemKeys;

  /// No description provided for @selectAccountScreenResetItemFeeds.
  ///
  /// In en, this message translates to:
  /// **'All feeds, bookmarks & settings'**
  String get selectAccountScreenResetItemFeeds;

  /// No description provided for @selectAccountScreenResetItemDatabases.
  ///
  /// In en, this message translates to:
  /// **'Local XMTP message databases'**
  String get selectAccountScreenResetItemDatabases;

  /// No description provided for @selectAccountScreenCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get selectAccountScreenCannotBeUndone;

  /// No description provided for @selectAccountScreenReset.
  ///
  /// In en, this message translates to:
  /// **'RESET'**
  String get selectAccountScreenReset;

  /// No description provided for @selectAccountScreenDeleteFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Delete from device'**
  String get selectAccountScreenDeleteFromDevice;

  /// No description provided for @selectAccountScreenBadgePending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get selectAccountScreenBadgePending;

  /// No description provided for @selectAccountScreenBadgeRecent.
  ///
  /// In en, this message translates to:
  /// **'RECENT'**
  String get selectAccountScreenBadgeRecent;

  /// No description provided for @selectAccountScreenShowQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR'**
  String get selectAccountScreenShowQr;

  /// No description provided for @selectAccountScreenCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get selectAccountScreenCopyAddress;

  /// No description provided for @selectAccountScreenRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get selectAccountScreenRemove;

  /// No description provided for @selectAccountScreenLogin.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get selectAccountScreenLogin;

  /// No description provided for @selectAccountScreenCheckActivation.
  ///
  /// In en, this message translates to:
  /// **'CHECK ACTIVATION'**
  String get selectAccountScreenCheckActivation;

  /// No description provided for @selectAccountScreenNoIdentitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Identities'**
  String get selectAccountScreenNoIdentitiesTitle;

  /// No description provided for @selectAccountScreenNoIdentitiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create or import a key pair to get started'**
  String get selectAccountScreenNoIdentitiesSubtitle;

  /// No description provided for @selectAccountScreenGenerateNewKey.
  ///
  /// In en, this message translates to:
  /// **'GENERATE NEW KEY'**
  String get selectAccountScreenGenerateNewKey;

  /// No description provided for @selectAccountScreenImportKeyButton.
  ///
  /// In en, this message translates to:
  /// **'IMPORT KEY'**
  String get selectAccountScreenImportKeyButton;

  /// No description provided for @selectAccountScreenResetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get selectAccountScreenResetTooltip;

  /// No description provided for @selectAccountScreenIdentities.
  ///
  /// In en, this message translates to:
  /// **'IDENTITIES'**
  String get selectAccountScreenIdentities;

  /// No description provided for @selectAccountScreenSelectToAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Select an account to login.'**
  String get selectAccountScreenSelectToAuthenticate;

  /// No description provided for @selectAccountScreenNoIdentitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No identities found.'**
  String get selectAccountScreenNoIdentitiesFound;

  /// No description provided for @selectAccountScreenNewKeysCardName.
  ///
  /// In en, this message translates to:
  /// **'New Keys'**
  String get selectAccountScreenNewKeysCardName;

  /// No description provided for @selectAccountScreenExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get selectAccountScreenExpired;

  /// No description provided for @selectAccountScreenLinkDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'LINK DEVICE'**
  String get selectAccountScreenLinkDeviceTitle;

  /// No description provided for @selectAccountScreenAddSession.
  ///
  /// In en, this message translates to:
  /// **'ADD SESSION'**
  String get selectAccountScreenAddSession;

  /// No description provided for @selectAccountScreenNewAccount.
  ///
  /// In en, this message translates to:
  /// **'NEW ACCOUNT'**
  String get selectAccountScreenNewAccount;

  /// No description provided for @selectAccountScreenScanAuthorizeKey.
  ///
  /// In en, this message translates to:
  /// **'Scan this from a session of your account to add this key.'**
  String get selectAccountScreenScanAuthorizeKey;

  /// No description provided for @selectAccountScreenScanCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Have a citizen scan this to create a new account with this key.'**
  String get selectAccountScreenScanCreateAccount;

  /// No description provided for @selectAccountScreenDone.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get selectAccountScreenDone;

  /// No description provided for @stickerGifToggleSticker.
  ///
  /// In en, this message translates to:
  /// **'STICKER'**
  String get stickerGifToggleSticker;

  /// No description provided for @stickerPanelEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stickers yet'**
  String get stickerPanelEmptyTitle;

  /// No description provided for @stickerPanelEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Hold any sticker in a chat and tap the save button to keep it here.'**
  String get stickerPanelEmptyBody;

  /// No description provided for @stickerPanelAddDescription.
  ///
  /// In en, this message translates to:
  /// **'Add description'**
  String get stickerPanelAddDescription;

  /// No description provided for @stickerPanelDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get stickerPanelDelete;

  /// No description provided for @stickerPanelDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete sticker?'**
  String get stickerPanelDeleteTitle;

  /// No description provided for @stickerPanelDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your stickers. Messages you already sent are not affected.'**
  String get stickerPanelDeleteBody;

  /// No description provided for @stickerPanelDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get stickerPanelDeleteConfirm;

  /// No description provided for @stickerPanelDismissMenu.
  ///
  /// In en, this message translates to:
  /// **'Dismiss sticker menu'**
  String get stickerPanelDismissMenu;

  /// No description provided for @syncIndicatorSyncFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Tap to retry.'**
  String get syncIndicatorSyncFailedRetry;

  /// No description provided for @unifiedSendSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Send OX'**
  String get unifiedSendSheetTitle;

  /// No description provided for @unifiedSendSheetFailedToLoadWallets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load wallets'**
  String get unifiedSendSheetFailedToLoadWallets;

  /// No description provided for @unifiedSendSheetDirectAddress.
  ///
  /// In en, this message translates to:
  /// **'Direct Address'**
  String get unifiedSendSheetDirectAddress;

  /// No description provided for @unifiedSendSheetAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get unifiedSendSheetAddressCopied;

  /// No description provided for @unifiedSendSheetAmountGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0'**
  String get unifiedSendSheetAmountGreaterThanZero;

  /// No description provided for @unifiedSendSheetAmountExceedsBalance.
  ///
  /// In en, this message translates to:
  /// **'Amount exceeds available balance'**
  String get unifiedSendSheetAmountExceedsBalance;

  /// No description provided for @unifiedSendSheetInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get unifiedSendSheetInvalidAmount;

  /// No description provided for @unifiedSendSheetCannotSendToSameWallet.
  ///
  /// In en, this message translates to:
  /// **'Cannot send to the same wallet'**
  String get unifiedSendSheetCannotSendToSameWallet;

  /// No description provided for @unifiedSendSheetTransactionSent.
  ///
  /// In en, this message translates to:
  /// **'Transaction sent successfully!'**
  String get unifiedSendSheetTransactionSent;

  /// No description provided for @unifiedSendSheetVoteStarted.
  ///
  /// In en, this message translates to:
  /// **'Vote started for group transaction! Other members can now approve.'**
  String get unifiedSendSheetVoteStarted;

  /// No description provided for @unifiedSendSheetTransactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transaction failed'**
  String get unifiedSendSheetTransactionFailed;

  /// No description provided for @unifiedSendSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, username or address…'**
  String get unifiedSendSheetSearchHint;

  /// No description provided for @unifiedSendSheetSearchingOnChain.
  ///
  /// In en, this message translates to:
  /// **'Searching on chain…'**
  String get unifiedSendSheetSearchingOnChain;

  /// No description provided for @unifiedSendSheetSelectContact.
  ///
  /// In en, this message translates to:
  /// **'Select a contact to send OX'**
  String get unifiedSendSheetSelectContact;

  /// No description provided for @unifiedSendSheetNoContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get unifiedSendSheetNoContactsFound;

  /// No description provided for @unifiedSendSheetKeychain.
  ///
  /// In en, this message translates to:
  /// **'Keychain'**
  String get unifiedSendSheetKeychain;

  /// No description provided for @unifiedSendSheetGroupAccount.
  ///
  /// In en, this message translates to:
  /// **'Group Account'**
  String get unifiedSendSheetGroupAccount;

  /// No description provided for @unifiedSendSheetMyAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get unifiedSendSheetMyAccount;

  /// No description provided for @unifiedSendSheetSendingFrom.
  ///
  /// In en, this message translates to:
  /// **'SENDING FROM'**
  String get unifiedSendSheetSendingFrom;

  /// No description provided for @unifiedSendSheetSendingTo.
  ///
  /// In en, this message translates to:
  /// **'SENDING TO'**
  String get unifiedSendSheetSendingTo;

  /// No description provided for @unifiedSendSheetChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get unifiedSendSheetChange;

  /// No description provided for @unifiedSendSheetMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get unifiedSendSheetMax;

  /// No description provided for @unifiedSendSheetSending.
  ///
  /// In en, this message translates to:
  /// **'SENDING…'**
  String get unifiedSendSheetSending;

  /// No description provided for @unifiedSendSheetSendOx.
  ///
  /// In en, this message translates to:
  /// **'SEND OX'**
  String get unifiedSendSheetSendOx;

  /// No description provided for @unifiedSendSheetChainLabel.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get unifiedSendSheetChainLabel;

  /// No description provided for @unifiedSendSheetTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get unifiedSendSheetTokenLabel;

  /// No description provided for @unifiedSendSheetGasLabel.
  ///
  /// In en, this message translates to:
  /// **'gas'**
  String get unifiedSendSheetGasLabel;

  /// No description provided for @unifiedSendSheetSelectChain.
  ///
  /// In en, this message translates to:
  /// **'Select chain'**
  String get unifiedSendSheetSelectChain;

  /// No description provided for @unifiedSendSheetSelectToken.
  ///
  /// In en, this message translates to:
  /// **'Select token'**
  String get unifiedSendSheetSelectToken;

  /// No description provided for @unifiedSendSheetSafeOtherNetwork.
  ///
  /// In en, this message translates to:
  /// **'A PublicOS Safe can\'t receive funds on other networks'**
  String get unifiedSendSheetSafeOtherNetwork;

  /// No description provided for @unifiedSendSheetNeedKeychain.
  ///
  /// In en, this message translates to:
  /// **'You need an external wallet to send on other networks'**
  String get unifiedSendSheetNeedKeychain;

  /// No description provided for @unifiedSendSheetChipRequested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get unifiedSendSheetChipRequested;

  /// No description provided for @tipSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip with OX'**
  String get tipSheetTitle;

  /// No description provided for @tipSheetChooseRecipient.
  ///
  /// In en, this message translates to:
  /// **'Choose who to tip'**
  String get tipSheetChooseRecipient;

  /// No description provided for @tipSheetActorAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get tipSheetActorAuthor;

  /// No description provided for @tipSheetActorFoundVia.
  ///
  /// In en, this message translates to:
  /// **'Found via'**
  String get tipSheetActorFoundVia;

  /// No description provided for @tipSheetActorChannelOwner.
  ///
  /// In en, this message translates to:
  /// **'Channel owner'**
  String get tipSheetActorChannelOwner;

  /// No description provided for @tipSheetSendTip.
  ///
  /// In en, this message translates to:
  /// **'SEND TIP'**
  String get tipSheetSendTip;

  /// No description provided for @tipSheetSending.
  ///
  /// In en, this message translates to:
  /// **'TIPPING…'**
  String get tipSheetSending;

  /// No description provided for @appSettingsPageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appSettingsPageSettingsTitle;

  /// No description provided for @appSettingsPageNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get appSettingsPageNotificationsTitle;

  /// No description provided for @appSettingsPageLiveNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Live notifications'**
  String get appSettingsPageLiveNotificationsTitle;

  /// No description provided for @appSettingsPageLiveNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show while the app is open'**
  String get appSettingsPageLiveNotificationsSubtitle;

  /// No description provided for @appSettingsPagePushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get appSettingsPagePushNotificationsTitle;

  /// No description provided for @appSettingsPagePushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts when the app is closed'**
  String get appSettingsPagePushNotificationsSubtitle;

  /// No description provided for @appSettingsPageChainNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chain notifications'**
  String get appSettingsPageChainNotificationsTitle;

  /// No description provided for @appSettingsPageChainNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications for on-chain events'**
  String get appSettingsPageChainNotificationsSubtitle;

  /// No description provided for @appSettingsPageNotifsNotArrivingDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications not arriving? Android may be stopping the app in the background. In the app\'s system settings, allow background data and set battery use to unrestricted.'**
  String get appSettingsPageNotifsNotArrivingDesc;

  /// No description provided for @appSettingsPageOpenSystemSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'OPEN SYSTEM SETTINGS'**
  String get appSettingsPageOpenSystemSettingsButton;

  /// No description provided for @appSettingsPageSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get appSettingsPageSessionTitle;

  /// No description provided for @appSettingsPageAutoLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-login'**
  String get appSettingsPageAutoLoginTitle;

  /// No description provided for @appSettingsPageAutoLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Skip account selection on launch'**
  String get appSettingsPageAutoLoginSubtitle;

  /// No description provided for @appSettingsPageBlockchainTitle.
  ///
  /// In en, this message translates to:
  /// **'Blockchain'**
  String get appSettingsPageBlockchainTitle;

  /// No description provided for @appSettingsPageChainIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Chain ID'**
  String get appSettingsPageChainIdLabel;

  /// No description provided for @appSettingsPageRpcLabel.
  ///
  /// In en, this message translates to:
  /// **'RPC'**
  String get appSettingsPageRpcLabel;

  /// No description provided for @appSettingsPagePollingRateLabel.
  ///
  /// In en, this message translates to:
  /// **'POLLING RATE'**
  String get appSettingsPagePollingRateLabel;

  /// No description provided for @appSettingsPageReconnectButton.
  ///
  /// In en, this message translates to:
  /// **'RECONNECT'**
  String get appSettingsPageReconnectButton;

  /// No description provided for @appSettingsPageReconnectedRpc.
  ///
  /// In en, this message translates to:
  /// **'Reconnected to RPC'**
  String get appSettingsPageReconnectedRpc;

  /// No description provided for @appSettingsPageVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get appSettingsPageVideoTitle;

  /// No description provided for @appSettingsPageVideoAutoloadThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'AUTO-LOAD THRESHOLD'**
  String get appSettingsPageVideoAutoloadThresholdLabel;

  /// No description provided for @appSettingsPageVideoAutoloadThresholdDesc.
  ///
  /// In en, this message translates to:
  /// **'Videos at or below this size auto-download. Larger videos show a \"Tap to load\" prompt.'**
  String get appSettingsPageVideoAutoloadThresholdDesc;

  /// No description provided for @appSettingsPageVideoThresholdAlwaysAsk.
  ///
  /// In en, this message translates to:
  /// **'Always ask'**
  String get appSettingsPageVideoThresholdAlwaysAsk;

  /// No description provided for @appSettingsPageVideoThresholdAlwaysAutoload.
  ///
  /// In en, this message translates to:
  /// **'Always auto-load'**
  String get appSettingsPageVideoThresholdAlwaysAutoload;

  /// No description provided for @appSettingsPageVideoThresholdMb.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String appSettingsPageVideoThresholdMb(Object mb);

  /// No description provided for @appSettingsPageVideoAutoplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Autoplay in feed'**
  String get appSettingsPageVideoAutoplayTitle;

  /// No description provided for @appSettingsPageVideoAutoplaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Muted, when scrolled into view (coming soon)'**
  String get appSettingsPageVideoAutoplaySubtitle;

  /// No description provided for @appSettingsPageAvatarTitle.
  ///
  /// In en, this message translates to:
  /// **'NFT avatars'**
  String get appSettingsPageAvatarTitle;

  /// No description provided for @appSettingsPageAvatarDesc.
  ///
  /// In en, this message translates to:
  /// **'Verified NFT profile pictures get a subtle treatment. These only affect display — ownership is always re-checked on-chain.'**
  String get appSettingsPageAvatarDesc;

  /// No description provided for @appSettingsPageSparklesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sparkles'**
  String get appSettingsPageSparklesTitle;

  /// No description provided for @appSettingsPageSparklesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Twinkling mark on verified NFT avatars'**
  String get appSettingsPageSparklesSubtitle;

  /// No description provided for @appSettingsPageShimmerTitle.
  ///
  /// In en, this message translates to:
  /// **'Shimmer sweep'**
  String get appSettingsPageShimmerTitle;

  /// No description provided for @appSettingsPageShimmerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A light sweep across verified NFT avatars'**
  String get appSettingsPageShimmerSubtitle;

  /// No description provided for @appSettingsPageHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get appSettingsPageHelpTitle;

  /// No description provided for @appSettingsPageHelpOnboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Replay the welcome tour — what PublicOS is, how the network is built, and the kinds of accounts you will meet.'**
  String get appSettingsPageHelpOnboardingDesc;

  /// No description provided for @appSettingsPageWatchOnboardingButton.
  ///
  /// In en, this message translates to:
  /// **'WATCH ONBOARDING'**
  String get appSettingsPageWatchOnboardingButton;

  /// No description provided for @appSettingsPageReseedDemoDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-save the baked demo contacts to your local store. Useful after an app update with a refreshed snapshot.'**
  String get appSettingsPageReseedDemoDesc;

  /// No description provided for @appSettingsPageReseedingButton.
  ///
  /// In en, this message translates to:
  /// **'RESEEDING…'**
  String get appSettingsPageReseedingButton;

  /// No description provided for @appSettingsPageReseedDemoButton.
  ///
  /// In en, this message translates to:
  /// **'RESEED DEMO CONTACTS'**
  String get appSettingsPageReseedDemoButton;

  /// No description provided for @appSettingsPageDemoContactsReseeded.
  ///
  /// In en, this message translates to:
  /// **'Demo contacts reseeded'**
  String get appSettingsPageDemoContactsReseeded;

  /// No description provided for @appSettingsPageDemoNewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a demo News list from a curated set of live RSS feeds, so you have something to read. Overwrites an existing News list.'**
  String get appSettingsPageDemoNewsDesc;

  /// No description provided for @appSettingsPageDemoFeedsDesc.
  ///
  /// In en, this message translates to:
  /// **'Build demo feeds from your contacts: a bluesky list from Bluesky channels, and bookmarks for every registered app. Lists overwrite same-named ones.'**
  String get appSettingsPageDemoFeedsDesc;

  /// No description provided for @appSettingsPageCreatingButton.
  ///
  /// In en, this message translates to:
  /// **'CREATING…'**
  String get appSettingsPageCreatingButton;

  /// No description provided for @appSettingsPageCreateDemoChannelButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE DEMO CHANNEL LIST'**
  String get appSettingsPageCreateDemoChannelButton;

  /// No description provided for @appSettingsPageCreateDemoBlueskyButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE DEMO BLUESKY LIST'**
  String get appSettingsPageCreateDemoBlueskyButton;

  /// No description provided for @appSettingsPageBookmarkingButton.
  ///
  /// In en, this message translates to:
  /// **'BOOKMARKING…'**
  String get appSettingsPageBookmarkingButton;

  /// No description provided for @appSettingsPageCreateDemoBookmarksButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE DEMO APP BOOKMARKS'**
  String get appSettingsPageCreateDemoBookmarksButton;

  /// No description provided for @appSettingsPageNoChannelsFound.
  ///
  /// In en, this message translates to:
  /// **'No channels found in contacts'**
  String get appSettingsPageNoChannelsFound;

  /// No description provided for @appSettingsPageFailedCreateNewsList.
  ///
  /// In en, this message translates to:
  /// **'Failed to create News list'**
  String get appSettingsPageFailedCreateNewsList;

  /// No description provided for @appSettingsPageCreatedNewsList.
  ///
  /// In en, this message translates to:
  /// **'Created News list with {count, plural, =1{1 channel} other{{count} channels}}'**
  String appSettingsPageCreatedNewsList(int count);

  /// No description provided for @appSettingsPageNoBlueskyFeeds.
  ///
  /// In en, this message translates to:
  /// **'No Bluesky feeds found in contacts'**
  String get appSettingsPageNoBlueskyFeeds;

  /// No description provided for @appSettingsPageFailedCreateBlueskyList.
  ///
  /// In en, this message translates to:
  /// **'Failed to create bluesky list'**
  String get appSettingsPageFailedCreateBlueskyList;

  /// No description provided for @appSettingsPageCreatedBlueskyList.
  ///
  /// In en, this message translates to:
  /// **'Created bluesky list with {count, plural, =1{1 feed} other{{count} feeds}}'**
  String appSettingsPageCreatedBlueskyList(int count);

  /// No description provided for @appSettingsPageBookmarkedApps.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked {count, plural, =1{1 app} other{{count} apps}}'**
  String appSettingsPageBookmarkedApps(int count);

  /// No description provided for @appSettingsPageAlreadyBookmarkedSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({count, plural, =1{1 already bookmarked} other{{count} already bookmarked}})'**
  String appSettingsPageAlreadyBookmarkedSuffix(int count);

  /// No description provided for @appSettingsPageFailedSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({count, plural, =1{1 failed} other{{count} failed}})'**
  String appSettingsPageFailedSuffix(int count);

  /// No description provided for @appSettingsPageRedeployedRecords.
  ///
  /// In en, this message translates to:
  /// **'Redeployed {count, plural, =1{1 record} other{{count} records}}'**
  String appSettingsPageRedeployedRecords(int count);

  /// No description provided for @appSettingsPageRedeployFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to redeploy profile'**
  String get appSettingsPageRedeployFailed;

  /// No description provided for @appSettingsPageDaoRegistered.
  ///
  /// In en, this message translates to:
  /// **'DAO registered: {address}'**
  String appSettingsPageDaoRegistered(Object address);

  /// No description provided for @appSettingsPageRunningSync.
  ///
  /// In en, this message translates to:
  /// **'Running background sync...'**
  String get appSettingsPageRunningSync;

  /// No description provided for @appSettingsPageSyncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed! Check log.'**
  String get appSettingsPageSyncCompleted;

  /// No description provided for @appSettingsPageSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Check log.'**
  String get appSettingsPageSyncFailed;

  /// No description provided for @appSettingsPageSyncLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Sync Log'**
  String get appSettingsPageSyncLogTitle;

  /// No description provided for @appSettingsPageSyncLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No background sync has run yet.\n\nThe first sync will run ~15 minutes after enabling periodic notifications.'**
  String get appSettingsPageSyncLogEmpty;

  /// No description provided for @appSettingsPageClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appSettingsPageClose;

  /// No description provided for @appSettingsPageCompleteResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Reset'**
  String get appSettingsPageCompleteResetTitle;

  /// No description provided for @appSettingsPageCompleteResetBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete ALL data including:\n• All messages\n• All contacts\n• All private keys\n• All secure storage\n• All authentication state\n\nThis action cannot be undone. Are you sure?'**
  String get appSettingsPageCompleteResetBody;

  /// No description provided for @appSettingsPageDeleteAllDataButton.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL DATA'**
  String get appSettingsPageDeleteAllDataButton;

  /// No description provided for @appSettingsPageAllDataDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data has been deleted.'**
  String get appSettingsPageAllDataDeleted;

  /// No description provided for @appSettingsPageResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Reset failed'**
  String get appSettingsPageResetFailed;

  /// No description provided for @appSettingsPageDeleteContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Contacts'**
  String get appSettingsPageDeleteContactsTitle;

  /// No description provided for @appSettingsPageDeleteContactsBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all locally stored contacts.\n\nThis action cannot be undone.'**
  String get appSettingsPageDeleteContactsBody;

  /// No description provided for @appSettingsPageDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get appSettingsPageDeleteAll;

  /// No description provided for @appSettingsPageDeletedContacts.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count, plural, =1{1 contact} other{{count} contacts}}'**
  String appSettingsPageDeletedContacts(int count);

  /// No description provided for @appSettingsPageDeleteMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Messages'**
  String get appSettingsPageDeleteMessagesTitle;

  /// No description provided for @appSettingsPageDeleteMessagesBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all locally stored messages and conversations.\n\nXMTP network state is untouched — conversations will reappear on the next sync, but historical messages will not.\n\nThis action cannot be undone.'**
  String get appSettingsPageDeleteMessagesBody;

  /// No description provided for @appSettingsPageDeletedMessages.
  ///
  /// In en, this message translates to:
  /// **'Deleted all messages and conversations'**
  String get appSettingsPageDeletedMessages;

  /// No description provided for @appSettingsPageDeleteAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Apps'**
  String get appSettingsPageDeleteAppsTitle;

  /// No description provided for @appSettingsPageDeleteAppsBody.
  ///
  /// In en, this message translates to:
  /// **'This will remove all bookmarked apps locally.\n\nThis action cannot be undone.'**
  String get appSettingsPageDeleteAppsBody;

  /// No description provided for @appSettingsPageDeletedApps.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count, plural, =1{1 app} other{{count} apps}}'**
  String appSettingsPageDeletedApps(int count);

  /// No description provided for @appSettingsPageClearChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Chain Notifications'**
  String get appSettingsPageClearChainTitle;

  /// No description provided for @appSettingsPageClearChainBody.
  ///
  /// In en, this message translates to:
  /// **'Wipes all cached on-chain activity (the notifications feed) and resets the sweep cursor so it re-syncs from the current chain.\n\nUse after a redeploy to clear stale old-chain notifications.'**
  String get appSettingsPageClearChainBody;

  /// No description provided for @appSettingsPageClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get appSettingsPageClear;

  /// No description provided for @appSettingsPageClearedNotifs.
  ///
  /// In en, this message translates to:
  /// **'Cleared {count, plural, =1{1 chain notification} other{{count} chain notifications}}'**
  String appSettingsPageClearedNotifs(int count);

  /// No description provided for @appSettingsPageExportDbKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Database Key'**
  String get appSettingsPageExportDbKeyTitle;

  /// No description provided for @appSettingsPageExportDbKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Your database key encrypts your local XMTP message cache. This key is unique to this device — exporting it allows you to import the same cache on another device. Never share it with anyone you don\'t trust.'**
  String get appSettingsPageExportDbKeyBody;

  /// No description provided for @appSettingsPageIUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I UNDERSTAND'**
  String get appSettingsPageIUnderstand;

  /// No description provided for @appSettingsPageDbKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'DB Key'**
  String get appSettingsPageDbKeyTitle;

  /// No description provided for @appSettingsPageActiveXmtpKey.
  ///
  /// In en, this message translates to:
  /// **'Active XMTP key: {label}'**
  String appSettingsPageActiveXmtpKey(Object label);

  /// No description provided for @appSettingsPageNoneLower.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get appSettingsPageNoneLower;

  /// No description provided for @appSettingsPageNoDbKey.
  ///
  /// In en, this message translates to:
  /// **'No DB key available.'**
  String get appSettingsPageNoDbKey;

  /// No description provided for @appSettingsPageCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get appSettingsPageCopy;

  /// No description provided for @appSettingsPageCopyLabelDbKey.
  ///
  /// In en, this message translates to:
  /// **'DB key'**
  String get appSettingsPageCopyLabelDbKey;

  /// No description provided for @appSettingsPageCopyLabelXmtpAddress.
  ///
  /// In en, this message translates to:
  /// **'XMTP address'**
  String get appSettingsPageCopyLabelXmtpAddress;

  /// No description provided for @appSettingsPageCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String appSettingsPageCopiedToClipboard(Object label);

  /// No description provided for @appSettingsPageImportDbKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Import DB Key'**
  String get appSettingsPageImportDbKeyTitle;

  /// No description provided for @appSettingsPageImportDbKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Paste a base64-encoded DB key. This will replace the current key.'**
  String get appSettingsPageImportDbKeyBody;

  /// No description provided for @appSettingsPageBase64KeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Base64 key'**
  String get appSettingsPageBase64KeyLabel;

  /// No description provided for @appSettingsPagePasteKeyError.
  ///
  /// In en, this message translates to:
  /// **'Paste a key'**
  String get appSettingsPagePasteKeyError;

  /// No description provided for @appSettingsPageDbKeyImported.
  ///
  /// In en, this message translates to:
  /// **'DB key imported'**
  String get appSettingsPageDbKeyImported;

  /// No description provided for @appSettingsPageImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get appSettingsPageImportFailed;

  /// No description provided for @appSettingsPageInvalidKey.
  ///
  /// In en, this message translates to:
  /// **'Invalid key'**
  String get appSettingsPageInvalidKey;

  /// No description provided for @appSettingsPageImportingButton.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get appSettingsPageImportingButton;

  /// No description provided for @appSettingsPageImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get appSettingsPageImportButton;

  /// No description provided for @appSettingsPageConnectedBadge.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get appSettingsPageConnectedBadge;

  /// No description provided for @appSettingsPageAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get appSettingsPageAddressLabel;

  /// No description provided for @appSettingsPageNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Not initialized'**
  String get appSettingsPageNotInitialized;

  /// No description provided for @appSettingsPageInboxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID'**
  String get appSettingsPageInboxIdLabel;

  /// No description provided for @appSettingsPageActiveKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Active Key'**
  String get appSettingsPageActiveKeyLabel;

  /// No description provided for @appSettingsPageNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get appSettingsPageNone;

  /// No description provided for @appSettingsPageInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get appSettingsPageInvalidAddress;

  /// No description provided for @appSettingsPageDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get appSettingsPageDeveloperTitle;

  /// No description provided for @appSettingsPageUnlockedBadge.
  ///
  /// In en, this message translates to:
  /// **'UNLOCKED'**
  String get appSettingsPageUnlockedBadge;

  /// No description provided for @appSettingsPageUtilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'UTILITIES'**
  String get appSettingsPageUtilitiesLabel;

  /// No description provided for @appSettingsPageSyncLogChip.
  ///
  /// In en, this message translates to:
  /// **'Sync Log'**
  String get appSettingsPageSyncLogChip;

  /// No description provided for @appSettingsPageTestSyncChip.
  ///
  /// In en, this message translates to:
  /// **'Test Sync'**
  String get appSettingsPageTestSyncChip;

  /// No description provided for @appSettingsPageRedeployChip.
  ///
  /// In en, this message translates to:
  /// **'Redeploy'**
  String get appSettingsPageRedeployChip;

  /// No description provided for @appSettingsPageRegisterDaoChip.
  ///
  /// In en, this message translates to:
  /// **'Register DAO'**
  String get appSettingsPageRegisterDaoChip;

  /// No description provided for @appSettingsPageDestructiveLabel.
  ///
  /// In en, this message translates to:
  /// **'DESTRUCTIVE'**
  String get appSettingsPageDestructiveLabel;

  /// No description provided for @appSettingsPageDeletingButton.
  ///
  /// In en, this message translates to:
  /// **'DELETING...'**
  String get appSettingsPageDeletingButton;

  /// No description provided for @appSettingsPageDeleteAllContactsButton.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL CONTACTS'**
  String get appSettingsPageDeleteAllContactsButton;

  /// No description provided for @appSettingsPageDeleteAllMessagesButton.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL MESSAGES'**
  String get appSettingsPageDeleteAllMessagesButton;

  /// No description provided for @appSettingsPageDeleteAllAppsButton.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL APPS'**
  String get appSettingsPageDeleteAllAppsButton;

  /// No description provided for @appSettingsPageClearingButton.
  ///
  /// In en, this message translates to:
  /// **'CLEARING...'**
  String get appSettingsPageClearingButton;

  /// No description provided for @appSettingsPageClearChainNotificationsButton.
  ///
  /// In en, this message translates to:
  /// **'CLEAR CHAIN NOTIFICATIONS'**
  String get appSettingsPageClearChainNotificationsButton;

  /// No description provided for @appSettingsPageResettingButton.
  ///
  /// In en, this message translates to:
  /// **'RESETTING...'**
  String get appSettingsPageResettingButton;

  /// No description provided for @appSettingsPageResetAllDataButton.
  ///
  /// In en, this message translates to:
  /// **'RESET ALL DATA'**
  String get appSettingsPageResetAllDataButton;

  /// No description provided for @appSettingsPageRegisterDaoTitle.
  ///
  /// In en, this message translates to:
  /// **'Register PublicOS DAO'**
  String get appSettingsPageRegisterDaoTitle;

  /// No description provided for @appSettingsPageDaoAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'A DAO is already registered:'**
  String get appSettingsPageDaoAlreadyRegistered;

  /// No description provided for @appSettingsPageUpdateDaoAddress.
  ///
  /// In en, this message translates to:
  /// **'Update DAO address'**
  String get appSettingsPageUpdateDaoAddress;

  /// No description provided for @appSettingsPageEnterDaoAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the address of the PublicOS root DAO.'**
  String get appSettingsPageEnterDaoAddress;

  /// No description provided for @appSettingsPageDaoAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'DAO Address'**
  String get appSettingsPageDaoAddressLabel;

  /// No description provided for @appSettingsPageRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get appSettingsPageRegisterButton;

  /// No description provided for @appSettingsPageFailedUpdateLive.
  ///
  /// In en, this message translates to:
  /// **'Failed to update live notifications'**
  String get appSettingsPageFailedUpdateLive;

  /// No description provided for @appSettingsPageFailedUpdatePush.
  ///
  /// In en, this message translates to:
  /// **'Failed to update push notifications'**
  String get appSettingsPageFailedUpdatePush;

  /// No description provided for @appSettingsPageFailedUpdateChain.
  ///
  /// In en, this message translates to:
  /// **'Failed to update chain notifications'**
  String get appSettingsPageFailedUpdateChain;

  /// No description provided for @browserContactNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contact not found'**
  String get browserContactNotFound;

  /// No description provided for @browserFollowingViaAccount.
  ///
  /// In en, this message translates to:
  /// **'You already follow this account — its channels are in Following'**
  String get browserFollowingViaAccount;

  /// No description provided for @browserTabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get browserTabChat;

  /// No description provided for @browserAppNotFound.
  ///
  /// In en, this message translates to:
  /// **'App not found'**
  String get browserAppNotFound;

  /// No description provided for @browserTabNotFound.
  ///
  /// In en, this message translates to:
  /// **'Tab not found'**
  String get browserTabNotFound;

  /// No description provided for @browserVoteStartedMembersApprove.
  ///
  /// In en, this message translates to:
  /// **'Vote started — members need to approve'**
  String get browserVoteStartedMembersApprove;

  /// No description provided for @browserProfileImageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated'**
  String get browserProfileImageUpdated;

  /// No description provided for @browserCouldNotStartVote.
  ///
  /// In en, this message translates to:
  /// **'Could not start the vote — please try again'**
  String get browserCouldNotStartVote;

  /// No description provided for @browserSavingToChain.
  ///
  /// In en, this message translates to:
  /// **'Saving to chain...'**
  String get browserSavingToChain;

  /// No description provided for @browserRefreshingProfile.
  ///
  /// In en, this message translates to:
  /// **'Refreshing profile...'**
  String get browserRefreshingProfile;

  /// No description provided for @browserAvatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get browserAvatarUpdated;

  /// No description provided for @browserCouldNotSetAvatar.
  ///
  /// In en, this message translates to:
  /// **'Could not set avatar — please try again'**
  String get browserCouldNotSetAvatar;

  /// No description provided for @browserProfileBackgroundRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile background removed!'**
  String get browserProfileBackgroundRemoved;

  /// No description provided for @browserProfileBackgroundUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile background updated successfully!'**
  String get browserProfileBackgroundUpdated;

  /// No description provided for @browserFailedUpdateBackground.
  ///
  /// In en, this message translates to:
  /// **'Failed to update background: Could not save record.'**
  String get browserFailedUpdateBackground;

  /// No description provided for @browserGroupChat.
  ///
  /// In en, this message translates to:
  /// **'Group chat'**
  String get browserGroupChat;

  /// No description provided for @browserTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get browserTabSettings;

  /// No description provided for @browserTabApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get browserTabApp;

  /// No description provided for @browserTabChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get browserTabChannel;

  /// No description provided for @browserTabWeb.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get browserTabWeb;

  /// No description provided for @browserTabManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get browserTabManagement;

  /// No description provided for @browserSwitchTab.
  ///
  /// In en, this message translates to:
  /// **'Switch tab'**
  String get browserSwitchTab;

  /// No description provided for @browserManageTabs.
  ///
  /// In en, this message translates to:
  /// **'Manage tabs'**
  String get browserManageTabs;

  /// No description provided for @browserSectionChats.
  ///
  /// In en, this message translates to:
  /// **'CHATS'**
  String get browserSectionChats;

  /// No description provided for @browserSectionApps.
  ///
  /// In en, this message translates to:
  /// **'APPS'**
  String get browserSectionApps;

  /// No description provided for @browserSectionTabs.
  ///
  /// In en, this message translates to:
  /// **'TABS'**
  String get browserSectionTabs;

  /// No description provided for @browserTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get browserTabProfile;

  /// No description provided for @browserUnnamedTab.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Tab'**
  String get browserUnnamedTab;

  /// No description provided for @browserTabWebTab.
  ///
  /// In en, this message translates to:
  /// **'Web Tab'**
  String get browserTabWebTab;

  /// No description provided for @browserAppNoUrl.
  ///
  /// In en, this message translates to:
  /// **'The selected app has no URL defined.'**
  String get browserAppNoUrl;

  /// No description provided for @browserTabNoUrl.
  ///
  /// In en, this message translates to:
  /// **'The selected tab has no URL defined.'**
  String get browserTabNoUrl;

  /// No description provided for @browserErrorLoadingContent.
  ///
  /// In en, this message translates to:
  /// **'Error loading content'**
  String get browserErrorLoadingContent;

  /// No description provided for @browserBackToExplorer.
  ///
  /// In en, this message translates to:
  /// **'Back to Explorer'**
  String get browserBackToExplorer;

  /// No description provided for @browserContactNotLoadedChat.
  ///
  /// In en, this message translates to:
  /// **'Contact not loaded for chat.'**
  String get browserContactNotLoadedChat;

  /// No description provided for @browserLoadingApp.
  ///
  /// In en, this message translates to:
  /// **'Loading app...'**
  String get browserLoadingApp;

  /// No description provided for @browserGoToProfile.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile'**
  String get browserGoToProfile;

  /// No description provided for @browserUnknownTab.
  ///
  /// In en, this message translates to:
  /// **'Unknown tab: {tab}'**
  String browserUnknownTab(Object tab);

  /// No description provided for @browserProfileLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied'**
  String get browserProfileLinkCopied;

  /// No description provided for @browserRemovedApp.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String browserRemovedApp(Object name);

  /// No description provided for @browserFailedRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove bookmark'**
  String get browserFailedRemoveBookmark;

  /// No description provided for @browserBookmarkedApp.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked {name}'**
  String browserBookmarkedApp(Object name);

  /// No description provided for @browserFailedBookmarkApp.
  ///
  /// In en, this message translates to:
  /// **'Failed to bookmark app'**
  String get browserFailedBookmarkApp;

  /// No description provided for @bspScreenNoActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'No active account'**
  String get bspScreenNoActiveAccount;

  /// No description provided for @bspScreenNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get bspScreenNoActiveSession;

  /// No description provided for @bspScreenEndpointNoUrl.
  ///
  /// In en, this message translates to:
  /// **'Endpoint has no URL'**
  String get bspScreenEndpointNoUrl;

  /// No description provided for @bspScreenConnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {label}…'**
  String bspScreenConnectingTo(Object label);

  /// No description provided for @bspScreenConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {label}'**
  String bspScreenConnectedTo(Object label);

  /// No description provided for @bspScreenUnreachable.
  ///
  /// In en, this message translates to:
  /// **'{label} is unreachable'**
  String bspScreenUnreachable(Object label);

  /// No description provided for @bspScreenRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {label}'**
  String bspScreenRemoved(Object label);

  /// No description provided for @bspScreenCouldNotRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove {label}'**
  String bspScreenCouldNotRemove(Object label);

  /// No description provided for @bspScreenConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get bspScreenConnection;

  /// No description provided for @bspScreenEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get bspScreenEndpoint;

  /// No description provided for @bspScreenBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get bspScreenBlock;

  /// No description provided for @bspScreenNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get bspScreenNone;

  /// No description provided for @bspScreenRoleCitizen.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get bspScreenRoleCitizen;

  /// No description provided for @bspScreenRolePrivate.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get bspScreenRolePrivate;

  /// No description provided for @bspScreenProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get bspScreenProvider;

  /// No description provided for @bspScreenBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get bspScreenBalance;

  /// No description provided for @bspScreenPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Covered until'**
  String get bspScreenPaidUntil;

  /// No description provided for @bspScreenTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get bspScreenTip;

  /// No description provided for @bspScreenTipCitizen.
  ///
  /// In en, this message translates to:
  /// **'Pick a BSP from Services. Citizens don\'t pay — the network mints fees on your behalf.'**
  String get bspScreenTipCitizen;

  /// No description provided for @bspScreenTipPrivate.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to a BSP from Services — first month pays atomically.'**
  String get bspScreenTipPrivate;

  /// No description provided for @bspScreenSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get bspScreenSubscription;

  /// No description provided for @bspScreenManageInTreasury.
  ///
  /// In en, this message translates to:
  /// **'MANAGE IN SERVICES'**
  String get bspScreenManageInTreasury;

  /// No description provided for @bspScreenProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get bspScreenProviders;

  /// No description provided for @bspScreenRegisterBsp.
  ///
  /// In en, this message translates to:
  /// **'REGISTER BSP'**
  String get bspScreenRegisterBsp;

  /// No description provided for @bspScreenAddCustomRpc.
  ///
  /// In en, this message translates to:
  /// **'ADD CUSTOM RPC'**
  String get bspScreenAddCustomRpc;

  /// No description provided for @bspScreenBadgeMine.
  ///
  /// In en, this message translates to:
  /// **'MINE'**
  String get bspScreenBadgeMine;

  /// No description provided for @bspScreenBadgeSubscribed.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBED'**
  String get bspScreenBadgeSubscribed;

  /// No description provided for @bspScreenEmptyCitizen.
  ///
  /// In en, this message translates to:
  /// **'No provider connected yet. Pick one from Services, register your own, or add a custom RPC below.'**
  String get bspScreenEmptyCitizen;

  /// No description provided for @bspScreenEmptyPrivate.
  ///
  /// In en, this message translates to:
  /// **'No provider connected yet. Subscribe to a BSP from Services, register your own, or add a custom RPC below.'**
  String get bspScreenEmptyPrivate;

  /// No description provided for @bspScreenStatusUnreachableLabel.
  ///
  /// In en, this message translates to:
  /// **'UNREACHABLE'**
  String get bspScreenStatusUnreachableLabel;

  /// No description provided for @bspScreenStatusUnreachableDesc.
  ///
  /// In en, this message translates to:
  /// **'No RPC endpoint is responding. Chain reads and writes are unavailable.'**
  String get bspScreenStatusUnreachableDesc;

  /// No description provided for @bspScreenStatusBspLabel.
  ///
  /// In en, this message translates to:
  /// **'BSP CONNECTED'**
  String get bspScreenStatusBspLabel;

  /// No description provided for @bspScreenStatusBspDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected through your subscribed Blockchain Service Provider.'**
  String get bspScreenStatusBspDesc;

  /// No description provided for @bspScreenStatusCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM RPC'**
  String get bspScreenStatusCustomLabel;

  /// No description provided for @bspScreenStatusCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected through a custom RPC endpoint you configured.'**
  String get bspScreenStatusCustomDesc;

  /// No description provided for @bspScreenStatusPublicLabel.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC FALLBACK'**
  String get bspScreenStatusPublicLabel;

  /// No description provided for @bspScreenStatusPublicDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected to the default public node. Subscribe to a BSP or add a custom RPC for better reliability.'**
  String get bspScreenStatusPublicDesc;

  /// No description provided for @bspScreenLegendNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No RPC connection'**
  String get bspScreenLegendNoConnection;

  /// No description provided for @bspScreenLegendPublicFallback.
  ///
  /// In en, this message translates to:
  /// **'Public fallback node'**
  String get bspScreenLegendPublicFallback;

  /// No description provided for @bspScreenLegendBspOrCustom.
  ///
  /// In en, this message translates to:
  /// **'BSP or custom RPC'**
  String get bspScreenLegendBspOrCustom;

  /// No description provided for @bspScreenEarningsFooter.
  ///
  /// In en, this message translates to:
  /// **'Earnings and claims live in Services.'**
  String get bspScreenEarningsFooter;

  /// No description provided for @bspScreenLabelRpc.
  ///
  /// In en, this message translates to:
  /// **'RPC'**
  String get bspScreenLabelRpc;

  /// No description provided for @bspScreenSubs.
  ///
  /// In en, this message translates to:
  /// **'SUBS'**
  String get bspScreenSubs;

  /// No description provided for @bspScreenSubscriberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subscriber} other{{count} subscribers}}'**
  String bspScreenSubscriberCount(int count);

  /// No description provided for @bspScreenRunBy.
  ///
  /// In en, this message translates to:
  /// **'RUN BY'**
  String get bspScreenRunBy;

  /// No description provided for @bspScreenConnect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get bspScreenConnect;

  /// No description provided for @bspScreenConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get bspScreenConnected;

  /// No description provided for @bspScreenLabelUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get bspScreenLabelUrl;

  /// No description provided for @bspScreenCustomRpcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'custom rpc'**
  String get bspScreenCustomRpcSubtitle;

  /// No description provided for @bspScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get bspScreenDelete;

  /// No description provided for @bspScreenRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'New BSP on-chain'**
  String get bspScreenRegisterTitle;

  /// No description provided for @bspScreenRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register yourself as a Blockchain Service Provider.'**
  String get bspScreenRegisterSubtitle;

  /// No description provided for @bspScreenFieldSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get bspScreenFieldSlug;

  /// No description provided for @bspScreenSlugHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my-bsp-service'**
  String get bspScreenSlugHint;

  /// No description provided for @bspScreenSlugHelper.
  ///
  /// In en, this message translates to:
  /// **'3-32 chars, lowercase, numbers, dashes, underscores'**
  String get bspScreenSlugHelper;

  /// No description provided for @bspScreenSlugRequired.
  ///
  /// In en, this message translates to:
  /// **'Slug is required'**
  String get bspScreenSlugRequired;

  /// No description provided for @bspScreenSlugInvalid.
  ///
  /// In en, this message translates to:
  /// **'3-32 chars: lowercase letters, numbers, - _'**
  String get bspScreenSlugInvalid;

  /// No description provided for @bspScreenFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bspScreenFieldTitle;

  /// No description provided for @bspScreenTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My BSP Service'**
  String get bspScreenTitleHint;

  /// No description provided for @bspScreenTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get bspScreenTitleRequired;

  /// No description provided for @bspScreenFieldRpcUrl.
  ///
  /// In en, this message translates to:
  /// **'RPC URL'**
  String get bspScreenFieldRpcUrl;

  /// No description provided for @bspScreenRpcUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'RPC URL is required'**
  String get bspScreenRpcUrlRequired;

  /// No description provided for @bspScreenFieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get bspScreenFieldRegion;

  /// No description provided for @bspScreenRegionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. us-east, eu-west'**
  String get bspScreenRegionHint;

  /// No description provided for @bspScreenFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get bspScreenFieldWebsite;

  /// No description provided for @bspScreenRegister.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get bspScreenRegister;

  /// No description provided for @bspScreenRegistering.
  ///
  /// In en, this message translates to:
  /// **'REGISTERING…'**
  String get bspScreenRegistering;

  /// No description provided for @bspScreenAddRpcTitle.
  ///
  /// In en, this message translates to:
  /// **'Point at your own node'**
  String get bspScreenAddRpcTitle;

  /// No description provided for @bspScreenAddRpcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connectivity is tested before saving.'**
  String get bspScreenAddRpcSubtitle;

  /// No description provided for @bspScreenFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bspScreenFieldName;

  /// No description provided for @bspScreenNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Node'**
  String get bspScreenNameHint;

  /// No description provided for @bspScreenUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get bspScreenUrlRequired;

  /// No description provided for @bspScreenAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get bspScreenAdd;

  /// No description provided for @bspScreenTesting.
  ///
  /// In en, this message translates to:
  /// **'TESTING…'**
  String get bspScreenTesting;

  /// No description provided for @chatScreenFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'Failed to send'**
  String get chatScreenFailedToSend;

  /// No description provided for @chatScreenFailedToInit.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize chat'**
  String get chatScreenFailedToInit;

  /// No description provided for @chatScreenFailedToUpdateConsent.
  ///
  /// In en, this message translates to:
  /// **'Failed to update consent state'**
  String get chatScreenFailedToUpdateConsent;

  /// No description provided for @chatScreenFailedToLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get chatScreenFailedToLoadMessages;

  /// No description provided for @chatScreenConsentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Allow this conversation? Sending a message auto-allows.'**
  String get chatScreenConsentPrompt;

  /// No description provided for @chatScreenConsentNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get chatScreenConsentNo;

  /// No description provided for @chatScreenConsentYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get chatScreenConsentYes;

  /// No description provided for @chatScreenNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatScreenNoMessages;

  /// No description provided for @chatScreenStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start your conversation below!'**
  String get chatScreenStartConversation;

  /// No description provided for @composePostPageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get composePostPageSave;

  /// No description provided for @composePostPagePost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get composePostPagePost;

  /// No description provided for @composePostPageFailedUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update post'**
  String get composePostPageFailedUpdate;

  /// No description provided for @composePostPageFailedPublish.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish'**
  String get composePostPageFailedPublish;

  /// No description provided for @composePostPageQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'Media quota exceeded: {used} of {quota} MB used on this server. Free up space or raise your quota.'**
  String composePostPageQuotaExceeded(int used, int quota);

  /// No description provided for @composePostPageUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get composePostPageUploadFailed;

  /// No description provided for @composePostPageMediaLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit reached — {count, plural, =1{1 item per post} other{{count} items per post}}'**
  String composePostPageMediaLimit(int count);

  /// No description provided for @composePostPagePickChannel.
  ///
  /// In en, this message translates to:
  /// **'Pick a channel'**
  String get composePostPagePickChannel;

  /// Tooltip of the composer's media-post toggle, left cell (media_post off): the contact row sits above the hero media.
  ///
  /// In en, this message translates to:
  /// **'Header above the media'**
  String get composePostPageHeaderAboveMedia;

  /// Tooltip of the composer's media-post toggle, right cell (media_post on): the contact row is drawn on the first hero item.
  ///
  /// In en, this message translates to:
  /// **'Header on the media'**
  String get composePostPageHeaderOnMedia;

  /// No description provided for @composePostPageBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Share an update'**
  String get composePostPageBodyHint;

  /// No description provided for @composePostPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get composePostPageTitle;

  /// No description provided for @composePostPageSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Add a short summary'**
  String get composePostPageSummaryHint;

  /// No description provided for @composePostPageBadgeVideo.
  ///
  /// In en, this message translates to:
  /// **'VIDEO'**
  String get composePostPageBadgeVideo;

  /// No description provided for @composePostPageBadgeVid.
  ///
  /// In en, this message translates to:
  /// **'VID'**
  String get composePostPageBadgeVid;

  /// No description provided for @composePostPageBadgeCitizen.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get composePostPageBadgeCitizen;

  /// No description provided for @composePostPageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get composePostPageUploading;

  /// No description provided for @composePostPageStatusUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {n} of {total} · {pct}%'**
  String composePostPageStatusUploading(int n, int total, int pct);

  /// No description provided for @composePostPageStatusMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving media…'**
  String get composePostPageStatusMoving;

  /// No description provided for @composePostPageStatusPosting.
  ///
  /// In en, this message translates to:
  /// **'Posting…'**
  String get composePostPageStatusPosting;

  /// No description provided for @composePostPageMoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not move the media'**
  String get composePostPageMoveFailed;

  /// No description provided for @composePostPageTagsHintEmpty.
  ///
  /// In en, this message translates to:
  /// **'type, then space or comma'**
  String get composePostPageTagsHintEmpty;

  /// No description provided for @composePostPageTagsHintMore.
  ///
  /// In en, this message translates to:
  /// **'add another'**
  String get composePostPageTagsHintMore;

  /// No description provided for @composePostPageCommentBarOpen.
  ///
  /// In en, this message translates to:
  /// **'Anyone can reply'**
  String get composePostPageCommentBarOpen;

  /// No description provided for @composePostPageCommentBarApproved.
  ///
  /// In en, this message translates to:
  /// **'Allow-list only'**
  String get composePostPageCommentBarApproved;

  /// No description provided for @composePostPageCommentBarDisabled.
  ///
  /// In en, this message translates to:
  /// **'Replies disabled'**
  String get composePostPageCommentBarDisabled;

  /// No description provided for @composePostPageReactionBarOpen.
  ///
  /// In en, this message translates to:
  /// **'Anyone can react'**
  String get composePostPageReactionBarOpen;

  /// No description provided for @composePostPageReactionBarApproved.
  ///
  /// In en, this message translates to:
  /// **'Reactions allow-list only'**
  String get composePostPageReactionBarApproved;

  /// No description provided for @composePostPageReactionBarDisabled.
  ///
  /// In en, this message translates to:
  /// **'Reactions disabled'**
  String get composePostPageReactionBarDisabled;

  /// No description provided for @composePostPageWhoCanReply.
  ///
  /// In en, this message translates to:
  /// **'Who can reply'**
  String get composePostPageWhoCanReply;

  /// No description provided for @composePostPageWhoCanReact.
  ///
  /// In en, this message translates to:
  /// **'Who can react'**
  String get composePostPageWhoCanReact;

  /// No description provided for @composePostPagePolicyAnyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get composePostPagePolicyAnyone;

  /// No description provided for @composePostPagePolicyAllowList.
  ///
  /// In en, this message translates to:
  /// **'Allow-list only'**
  String get composePostPagePolicyAllowList;

  /// No description provided for @composePostPagePolicyDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get composePostPagePolicyDisabled;

  /// No description provided for @composePostPageCommentSubtitleAnyone.
  ///
  /// In en, this message translates to:
  /// **'Any account with access to the channel can reply.'**
  String get composePostPageCommentSubtitleAnyone;

  /// No description provided for @composePostPageCommentSubtitleAllowList.
  ///
  /// In en, this message translates to:
  /// **'Only addresses you added via the per-post Comment rules can reply.'**
  String get composePostPageCommentSubtitleAllowList;

  /// No description provided for @composePostPageCommentSubtitleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Nobody can reply. Existing comments stay visible.'**
  String get composePostPageCommentSubtitleDisabled;

  /// No description provided for @composePostPageReactionSubtitleAnyone.
  ///
  /// In en, this message translates to:
  /// **'Any account with access to the channel can react.'**
  String get composePostPageReactionSubtitleAnyone;

  /// No description provided for @composePostPageReactionSubtitleAllowList.
  ///
  /// In en, this message translates to:
  /// **'Only addresses you added via the per-post Interaction rules can react. (The same allow-list governs comments and reactions.)'**
  String get composePostPageReactionSubtitleAllowList;

  /// No description provided for @composePostPageReactionSubtitleDisabled.
  ///
  /// In en, this message translates to:
  /// **'Nobody can react. Existing reactions stay visible. Independent of the comment policy.'**
  String get composePostPageReactionSubtitleDisabled;

  /// No description provided for @composePostPageRequireVerifiedCitizen.
  ///
  /// In en, this message translates to:
  /// **'Require verified citizen'**
  String get composePostPageRequireVerifiedCitizen;

  /// No description provided for @composePostPageCommentVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Overrides the channel default for this post. Non-citizens cannot reply.'**
  String get composePostPageCommentVerifiedSubtitle;

  /// No description provided for @composePostPageReactionVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Independent of the comments-side toggle. Non-citizens cannot react to this post.'**
  String get composePostPageReactionVerifiedSubtitle;

  /// No description provided for @composePostPageDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get composePostPageDone;

  /// No description provided for @composePostPageLanguageHeader.
  ///
  /// In en, this message translates to:
  /// **'POST LANGUAGE'**
  String get composePostPageLanguageHeader;

  /// No description provided for @composePostPageChannelHeader.
  ///
  /// In en, this message translates to:
  /// **'POST TO'**
  String get composePostPageChannelHeader;

  /// No description provided for @composePostPageTooltipHero.
  ///
  /// In en, this message translates to:
  /// **'Hero media (images / videos)'**
  String get composePostPageTooltipHero;

  /// No description provided for @composePostPageTooltipMedia.
  ///
  /// In en, this message translates to:
  /// **'Support media (images / videos)'**
  String get composePostPageTooltipMedia;

  /// No description provided for @composePostPageTooltipAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio (the post\'s sound track)'**
  String get composePostPageTooltipAudio;

  /// No description provided for @composePostPageAudioUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Pick an MP3, M4A, WAV or OGG file'**
  String get composePostPageAudioUnsupported;

  /// No description provided for @composePostPageTooltipSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get composePostPageTooltipSummary;

  /// No description provided for @composePostPageTooltipLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get composePostPageTooltipLink;

  /// No description provided for @composePostPageTooltipTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get composePostPageTooltipTags;

  /// No description provided for @contactSettingsScreenNoContactSelected.
  ///
  /// In en, this message translates to:
  /// **'No contact selected'**
  String get contactSettingsScreenNoContactSelected;

  /// No description provided for @createChannelPageEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit channel'**
  String get createChannelPageEditTitle;

  /// No description provided for @createChannelPageNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New channel'**
  String get createChannelPageNewTitle;

  /// No description provided for @createChannelPageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get createChannelPageSave;

  /// No description provided for @createChannelPageCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createChannelPageCreate;

  /// No description provided for @createChannelPageServerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get createChannelPageServerLoading;

  /// No description provided for @createChannelPageNoServerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No server available'**
  String get createChannelPageNoServerAvailable;

  /// No description provided for @createChannelPageChannelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\" updated'**
  String createChannelPageChannelUpdated(Object name);

  /// No description provided for @createChannelPageChannelCreated.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\" created'**
  String createChannelPageChannelCreated(Object name);

  /// No description provided for @createChannelPageUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get createChannelPageUnknownError;

  /// No description provided for @createChannelPageFailedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {msg}'**
  String createChannelPageFailedToUpdate(Object msg);

  /// No description provided for @createChannelPageFailedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create: {msg}'**
  String createChannelPageFailedToCreate(Object msg);

  /// No description provided for @createChannelPageSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get createChannelPageSectionIdentity;

  /// No description provided for @createChannelPageNameHint.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get createChannelPageNameHint;

  /// No description provided for @createChannelPageIconUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'ICON URL'**
  String get createChannelPageIconUrlLabel;

  /// No description provided for @createChannelPageIconUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://…/icon.png'**
  String get createChannelPageIconUrlHint;

  /// No description provided for @createChannelPageSlugLabel.
  ///
  /// In en, this message translates to:
  /// **'SLUG'**
  String get createChannelPageSlugLabel;

  /// No description provided for @createChannelPageSlugHint.
  ///
  /// In en, this message translates to:
  /// **'channel-slug'**
  String get createChannelPageSlugHint;

  /// No description provided for @createChannelPageDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get createChannelPageDescriptionLabel;

  /// No description provided for @createChannelPageLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get createChannelPageLanguageLabel;

  /// No description provided for @createChannelPageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this channel about?'**
  String get createChannelPageDescriptionHint;

  /// No description provided for @createChannelPageSectionServer.
  ///
  /// In en, this message translates to:
  /// **'SERVER'**
  String get createChannelPageSectionServer;

  /// No description provided for @createChannelPageServerLocked.
  ///
  /// In en, this message translates to:
  /// **'Server can\'t be changed after creation'**
  String get createChannelPageServerLocked;

  /// No description provided for @createChannelPageServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where this channel is hosted'**
  String get createChannelPageServerSubtitle;

  /// No description provided for @createChannelPageChooseServer.
  ///
  /// In en, this message translates to:
  /// **'Choose server'**
  String get createChannelPageChooseServer;

  /// No description provided for @createChannelPageSectionPosting.
  ///
  /// In en, this message translates to:
  /// **'POSTING'**
  String get createChannelPageSectionPosting;

  /// No description provided for @createChannelPagePolicyOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner only'**
  String get createChannelPagePolicyOwnerLabel;

  /// No description provided for @createChannelPagePolicyOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nobody but you can submit posts.'**
  String get createChannelPagePolicyOwnerSubtitle;

  /// No description provided for @createChannelPagePolicyOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get createChannelPagePolicyOpenLabel;

  /// No description provided for @createChannelPagePolicyOpenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone who can read the channel may submit posts.'**
  String get createChannelPagePolicyOpenSubtitle;

  /// No description provided for @createChannelPagePolicyApprovedLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get createChannelPagePolicyApprovedLabel;

  /// No description provided for @createChannelPagePolicyApprovedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only people on your posters list may submit posts.'**
  String get createChannelPagePolicyApprovedSubtitle;

  /// No description provided for @createChannelPageRateLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'RATE LIMIT (POSTS / HOUR, 0 = UNLIMITED)'**
  String get createChannelPageRateLimitLabel;

  /// No description provided for @createChannelPageSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'PRIVACY'**
  String get createChannelPageSectionPrivacy;

  /// No description provided for @createChannelPagePrivateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private channel'**
  String get createChannelPagePrivateLabel;

  /// No description provided for @createChannelPagePrivateSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Only approved followers can read posts. Other accounts see a lock screen and can request access.'**
  String get createChannelPagePrivateSubtitleOn;

  /// No description provided for @createChannelPagePrivateSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Anyone with the link can read this channel.'**
  String get createChannelPagePrivateSubtitleOff;

  /// No description provided for @createChannelPagePrivateInboxNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get a follow-request inbox to approve or reject readers.'**
  String get createChannelPagePrivateInboxNote;

  /// No description provided for @createChannelPageSectionCitizenship.
  ///
  /// In en, this message translates to:
  /// **'CITIZENSHIP'**
  String get createChannelPageSectionCitizenship;

  /// No description provided for @createChannelPageCitizenshipNote.
  ///
  /// In en, this message translates to:
  /// **'Restrict actions to verified citizens.'**
  String get createChannelPageCitizenshipNote;

  /// No description provided for @createChannelPageCitizensReadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Citizens only — reading'**
  String get createChannelPageCitizensReadingLabel;

  /// No description provided for @createChannelPageCitizensPostingLabel.
  ///
  /// In en, this message translates to:
  /// **'Citizens only — posting'**
  String get createChannelPageCitizensPostingLabel;

  /// No description provided for @createChannelPageCitizensCommentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Citizens only — comments'**
  String get createChannelPageCitizensCommentsLabel;

  /// No description provided for @createChannelPageSectionRetention.
  ///
  /// In en, this message translates to:
  /// **'RETENTION'**
  String get createChannelPageSectionRetention;

  /// No description provided for @createChannelPageMaxPostsLabel.
  ///
  /// In en, this message translates to:
  /// **'MAX POSTS (LEAVE EMPTY = UNLIMITED)'**
  String get createChannelPageMaxPostsLabel;

  /// No description provided for @createChannelPageMaxDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'MAX DAYS (LEAVE EMPTY = UNLIMITED)'**
  String get createChannelPageMaxDaysLabel;

  /// No description provided for @createGroupPageAddMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get createGroupPageAddMembersTitle;

  /// No description provided for @createGroupPageDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group details'**
  String get createGroupPageDetailsTitle;

  /// No description provided for @createGroupPageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, address, or inbox ID'**
  String get createGroupPageSearchHint;

  /// No description provided for @createGroupPageSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get createGroupPageSortRecent;

  /// No description provided for @commentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentSectionTitle;

  /// No description provided for @commentSectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String commentSectionCount(int count);

  /// No description provided for @commentSectionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first.'**
  String get commentSectionEmpty;

  /// No description provided for @commentSectionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading comments…'**
  String get commentSectionLoading;

  /// No description provided for @commentSectionLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more comments'**
  String get commentSectionLoadMore;

  /// No description provided for @commentSortBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get commentSortBest;

  /// No description provided for @commentSortTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get commentSortTop;

  /// No description provided for @commentSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get commentSortNewest;

  /// No description provided for @commentSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get commentSortOldest;

  /// No description provided for @createGroupPageNoContactsMatch.
  ///
  /// In en, this message translates to:
  /// **'No contacts match'**
  String get createGroupPageNoContactsMatch;

  /// No description provided for @createGroupPageNoContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Try a display name, an 0x-prefixed address, or a 64-char inbox ID.'**
  String get createGroupPageNoContactsHint;

  /// No description provided for @createGroupPageFieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'GROUP NAME'**
  String get createGroupPageFieldNameLabel;

  /// No description provided for @createGroupPageNameHint.
  ///
  /// In en, this message translates to:
  /// **'Builders, HH 2026, …'**
  String get createGroupPageNameHint;

  /// No description provided for @createGroupPageFieldImageLabel.
  ///
  /// In en, this message translates to:
  /// **'GROUP IMAGE'**
  String get createGroupPageFieldImageLabel;

  /// No description provided for @createGroupPageNoSspMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a Social Server (SSP) to upload a group image. You can still paste an image URL below.'**
  String get createGroupPageNoSspMessage;

  /// No description provided for @createGroupPageFieldDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'DESCRIPTION'**
  String get createGroupPageFieldDescriptionLabel;

  /// No description provided for @createGroupPageDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What is this group for?'**
  String get createGroupPageDescriptionHint;

  /// No description provided for @createGroupPageNextButton.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get createGroupPageNextButton;

  /// No description provided for @createGroupPageAddButton.
  ///
  /// In en, this message translates to:
  /// **'ADD MEMBERS'**
  String get createGroupPageAddButton;

  /// No description provided for @createGroupPageCreateButton.
  ///
  /// In en, this message translates to:
  /// **'CREATE GROUP'**
  String get createGroupPageCreateButton;

  /// No description provided for @createGroupPagePickInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'PICK INBOX'**
  String get createGroupPagePickInboxTitle;

  /// No description provided for @createGroupPageMultipleDevices.
  ///
  /// In en, this message translates to:
  /// **'{name} has multiple registered devices.'**
  String createGroupPageMultipleDevices(Object name);

  /// No description provided for @createGroupPageAllDevicesAdded.
  ///
  /// In en, this message translates to:
  /// **'All devices already added for {name}'**
  String createGroupPageAllDevicesAdded(Object name);

  /// No description provided for @createGroupPageNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get createGroupPageNameRequired;

  /// No description provided for @createGroupPageSelectContact.
  ///
  /// In en, this message translates to:
  /// **'Select at least one contact'**
  String get createGroupPageSelectContact;

  /// No description provided for @createGroupPageNoValidInboxIds.
  ///
  /// In en, this message translates to:
  /// **'Selected contacts have no valid inbox IDs'**
  String get createGroupPageNoValidInboxIds;

  /// No description provided for @createGroupPageCreationNoId.
  ///
  /// In en, this message translates to:
  /// **'Group creation returned no id'**
  String get createGroupPageCreationNoId;

  /// No description provided for @explorerBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Back again to exit'**
  String get explorerBackAgainToExit;

  /// No description provided for @explorerTabFeeds.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get explorerTabFeeds;

  /// No description provided for @explorerTabContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get explorerTabContacts;

  /// No description provided for @explorerTabApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get explorerTabApps;

  /// No description provided for @explorerTabMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get explorerTabMessages;

  /// No description provided for @explorerTabWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get explorerTabWallet;

  /// No description provided for @appsViewRemovedSnack.
  ///
  /// In en, this message translates to:
  /// **'Removed {name}'**
  String appsViewRemovedSnack(Object name);

  /// No description provided for @appsViewBookmarkedSnack.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked {name}'**
  String appsViewBookmarkedSnack(Object name);

  /// No description provided for @appsViewAppMisconfigured.
  ///
  /// In en, this message translates to:
  /// **'{label} can\'t open — the app has no address set. That\'s the developer\'s side, not yours.'**
  String appsViewAppMisconfigured(Object label);

  /// No description provided for @appsViewComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{label} coming soon'**
  String appsViewComingSoon(Object label);

  /// No description provided for @appsViewSystemTreasury.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get appsViewSystemTreasury;

  /// No description provided for @appsViewSystemAccountCenter.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get appsViewSystemAccountCenter;

  /// No description provided for @appsViewSystemSocialGraph.
  ///
  /// In en, this message translates to:
  /// **'Social Graph'**
  String get appsViewSystemSocialGraph;

  /// No description provided for @appsViewSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appsViewSystemSettings;

  /// No description provided for @appsViewSystemNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get appsViewSystemNodes;

  /// No description provided for @appsViewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps'**
  String get appsViewSearchHint;

  /// No description provided for @appsViewSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching apps...'**
  String get appsViewSearching;

  /// No description provided for @appsViewChipBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get appsViewChipBookmarked;

  /// No description provided for @appsViewChipMyApps.
  ///
  /// In en, this message translates to:
  /// **'My Apps'**
  String get appsViewChipMyApps;

  /// No description provided for @appsViewChipAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get appsViewChipAll;

  /// No description provided for @appsViewChipRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get appsViewChipRegister;

  /// No description provided for @appsViewChipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get appsViewChipSettings;

  /// No description provided for @appsViewEmptyNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get appsViewEmptyNoMatchesTitle;

  /// No description provided for @appsViewEmptyTryDifferentTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term.'**
  String get appsViewEmptyTryDifferentTerm;

  /// No description provided for @appsViewEmptyNoBookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookmarked apps'**
  String get appsViewEmptyNoBookmarksTitle;

  /// No description provided for @appsViewEmptyNoBookmarksBody.
  ///
  /// In en, this message translates to:
  /// **'Long-press any app in \"All\" to add it to your bookmarks.'**
  String get appsViewEmptyNoBookmarksBody;

  /// No description provided for @appsViewEmptyNoMyAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t registered any apps'**
  String get appsViewEmptyNoMyAppsTitle;

  /// No description provided for @appsViewEmptyNoMyAppsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Register\" in the chip bar to publish your first app.'**
  String get appsViewEmptyNoMyAppsBody;

  /// No description provided for @appsViewEmptyNoAppsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get appsViewEmptyNoAppsFoundTitle;

  /// No description provided for @appsViewSearchPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Search all apps'**
  String get appsViewSearchPromptTitle;

  /// No description provided for @appsViewSearchPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters to search\nfor apps across the network.'**
  String get appsViewSearchPromptBody;

  /// No description provided for @contactsViewShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get contactsViewShare;

  /// No description provided for @contactsViewSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get contactsViewSend;

  /// No description provided for @contactsViewDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get contactsViewDelete;

  /// No description provided for @contactsViewDeleteContactTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE CONTACT'**
  String get contactsViewDeleteContactTitle;

  /// No description provided for @contactsViewDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from your contacts?'**
  String contactsViewDeleteConfirm(Object name);

  /// No description provided for @contactsViewRemovedFromContacts.
  ///
  /// In en, this message translates to:
  /// **'{name} removed from contacts'**
  String contactsViewRemovedFromContacts(Object name);

  /// No description provided for @contactsViewFailedToRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove contact'**
  String get contactsViewFailedToRemove;

  /// No description provided for @contactsViewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, address, or inbox'**
  String get contactsViewSearchHint;

  /// No description provided for @contactsViewFilterStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get contactsViewFilterStarred;

  /// No description provided for @contactsViewStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get contactsViewStar;

  /// No description provided for @contactsViewUnstar.
  ///
  /// In en, this message translates to:
  /// **'Remove star'**
  String get contactsViewUnstar;

  /// No description provided for @contactsViewNoStarred.
  ///
  /// In en, this message translates to:
  /// **'No starred contacts yet. Turn off Starred to see everyone.'**
  String get contactsViewNoStarred;

  /// No description provided for @notificationsScreenStarredNote.
  ///
  /// In en, this message translates to:
  /// **'Only starred contacts raise chain notifications.'**
  String get notificationsScreenStarredNote;

  /// No description provided for @browserEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get browserEditProfile;

  /// No description provided for @browserStopEditing.
  ///
  /// In en, this message translates to:
  /// **'Stop editing'**
  String get browserStopEditing;

  /// No description provided for @browserStarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Star: get chain notifications about this contact'**
  String get browserStarTooltip;

  /// No description provided for @contactsViewFilterPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get contactsViewFilterPersonal;

  /// No description provided for @contactsViewFilterOrgs.
  ///
  /// In en, this message translates to:
  /// **'Orgs'**
  String get contactsViewFilterOrgs;

  /// No description provided for @contactsViewSortAsc.
  ///
  /// In en, this message translates to:
  /// **'A-Z'**
  String get contactsViewSortAsc;

  /// No description provided for @contactsViewSortDesc.
  ///
  /// In en, this message translates to:
  /// **'Z-A'**
  String get contactsViewSortDesc;

  /// No description provided for @contactsViewNewOrg.
  ///
  /// In en, this message translates to:
  /// **'New Org'**
  String get contactsViewNewOrg;

  /// No description provided for @contactsViewSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get contactsViewSettings;

  /// No description provided for @contactsViewFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load contacts'**
  String get contactsViewFailedToLoad;

  /// No description provided for @contactsViewNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get contactsViewNoMatches;

  /// No description provided for @contactsViewNoContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsViewNoContactsYet;

  /// No description provided for @contactsViewNoMatchesHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, address, or inbox ID.'**
  String get contactsViewNoMatchesHint;

  /// No description provided for @contactsViewEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'PublicOS contacts you interact with will appear here.'**
  String get contactsViewEmptyHint;

  /// No description provided for @channelSigninTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel sign-in'**
  String get channelSigninTitle;

  /// No description provided for @channelSigninBodyOptional.
  ///
  /// In en, this message translates to:
  /// **'This channel\'s server accepts PublicOS sign-in. Signed in, every read identifies you to this server: you count as a verified reader and the channel can respond to who you are. Signed out, you read anonymously.'**
  String get channelSigninBodyOptional;

  /// No description provided for @channelSigninBodyRequired.
  ///
  /// In en, this message translates to:
  /// **'This channel requires PublicOS sign-in to read - your reads identify you to its server.'**
  String get channelSigninBodyRequired;

  /// No description provided for @channelSigninStateOn.
  ///
  /// In en, this message translates to:
  /// **'You are currently signed in to this channel.'**
  String get channelSigninStateOn;

  /// No description provided for @channelSigninStateOff.
  ///
  /// In en, this message translates to:
  /// **'You are currently reading anonymously.'**
  String get channelSigninStateOff;

  /// No description provided for @channelSigninEnable.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get channelSigninEnable;

  /// No description provided for @channelSigninDisable.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get channelSigninDisable;

  /// No description provided for @channelSigninAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get channelSigninAllow;

  /// No description provided for @channelSigninDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get channelSigninDeny;

  /// No description provided for @channelSigninForget.
  ///
  /// In en, this message translates to:
  /// **'Forget'**
  String get channelSigninForget;

  /// No description provided for @channelSigninMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in on this channel'**
  String get channelSigninMenuTitle;

  /// No description provided for @signinLockedBadge.
  ///
  /// In en, this message translates to:
  /// **'SIGN-IN REQUIRED'**
  String get signinLockedBadge;

  /// No description provided for @signinLockedBlurbDenied.
  ///
  /// In en, this message translates to:
  /// **'You said no to this channel. Sign in to read it.'**
  String get signinLockedBlurbDenied;

  /// No description provided for @signinLockedBlurbAsk.
  ///
  /// In en, this message translates to:
  /// **'This channel requires sign-in to read. Your reads identify you to its server.'**
  String get signinLockedBlurbAsk;

  /// No description provided for @feedsSettingsSheetAutoSigninLabel.
  ///
  /// In en, this message translates to:
  /// **'AUTO-SIGN-IN TO FEEDS'**
  String get feedsSettingsSheetAutoSigninLabel;

  /// No description provided for @feedsSettingsSheetAutoSigninOn.
  ///
  /// In en, this message translates to:
  /// **'Signing in everywhere you have not said no'**
  String get feedsSettingsSheetAutoSigninOn;

  /// No description provided for @feedsSettingsSheetAutoSigninOff.
  ///
  /// In en, this message translates to:
  /// **'Each channel asks once'**
  String get feedsSettingsSheetAutoSigninOff;

  /// No description provided for @feedsViewDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get feedsViewDiscover;

  /// No description provided for @feedsViewBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get feedsViewBookmarks;

  /// No description provided for @feedsViewVia.
  ///
  /// In en, this message translates to:
  /// **'via'**
  String get feedsViewVia;

  /// No description provided for @feedsViewOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your lists and channels go here'**
  String get feedsViewOnboardingTitle;

  /// No description provided for @feedsViewOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create or follow a channel to start'**
  String get feedsViewOnboardingSubtitle;

  /// No description provided for @messagesViewSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, address, or inbox'**
  String get messagesViewSearchHint;

  /// No description provided for @messagesViewEmptyNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get messagesViewEmptyNoMatchesTitle;

  /// No description provided for @messagesViewEmptyNoMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a different name, address, or inbox ID.'**
  String get messagesViewEmptyNoMatchesSubtitle;

  /// No description provided for @messagesViewEmptyNoRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'No new requests'**
  String get messagesViewEmptyNoRequestsTitle;

  /// No description provided for @messagesViewEmptyNoRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New conversation requests will appear here.'**
  String get messagesViewEmptyNoRequestsSubtitle;

  /// No description provided for @messagesViewEmptyNoConversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesViewEmptyNoConversationsTitle;

  /// No description provided for @messagesViewEmptyNoConversationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation to see it here.'**
  String get messagesViewEmptyNoConversationsSubtitle;

  /// No description provided for @messagesViewNoKeysTitle.
  ///
  /// In en, this message translates to:
  /// **'Get your inbox started'**
  String get messagesViewNoKeysTitle;

  /// No description provided for @messagesViewNoKeysSubtitleBefore.
  ///
  /// In en, this message translates to:
  /// **'Sign in with one of your keys using the '**
  String get messagesViewNoKeysSubtitleBefore;

  /// No description provided for @messagesViewNoKeysSubtitleAfter.
  ///
  /// In en, this message translates to:
  /// **' button in the keychain.'**
  String get messagesViewNoKeysSubtitleAfter;

  /// Chat tab with no XMTP inbox loaded: shown under a sim icon instead of the conversation and its input. Tapping opens the keychain.
  ///
  /// In en, this message translates to:
  /// **'Load a key into XMTP to start messaging'**
  String get chatNoKeyTitle;

  /// No description provided for @manageChannelPageManageLabel.
  ///
  /// In en, this message translates to:
  /// **'manage'**
  String get manageChannelPageManageLabel;

  /// No description provided for @manageChannelPageMissingServerInfo.
  ///
  /// In en, this message translates to:
  /// **'Channel is missing server info — can\'t build URL'**
  String get manageChannelPageMissingServerInfo;

  /// No description provided for @manageChannelPageExportUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} URL copied'**
  String manageChannelPageExportUrlCopied(Object label);

  /// No description provided for @manageChannelPageDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete channel?'**
  String get manageChannelPageDeleteTitle;

  /// No description provided for @manageChannelPageDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes \"{name}\" and every post, comment, vote, reaction, follower, poster, ban, and whitelist entry attached to it. Can\'t be undone.'**
  String manageChannelPageDeleteBody(Object name);

  /// No description provided for @manageChannelPageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageChannelPageDelete;

  /// No description provided for @manageChannelPageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\" deleted'**
  String manageChannelPageDeleted(Object name);

  /// No description provided for @manageChannelPageUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get manageChannelPageUnknownError;

  /// No description provided for @manageChannelPageFailDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {message}'**
  String manageChannelPageFailDelete(Object message);

  /// No description provided for @manageChannelPageTabPosters.
  ///
  /// In en, this message translates to:
  /// **'POSTERS'**
  String get manageChannelPageTabPosters;

  /// No description provided for @manageChannelPageTabBans.
  ///
  /// In en, this message translates to:
  /// **'BANS'**
  String get manageChannelPageTabBans;

  /// No description provided for @manageChannelPageTabReadAccess.
  ///
  /// In en, this message translates to:
  /// **'READ ACCESS'**
  String get manageChannelPageTabReadAccess;

  /// No description provided for @manageChannelPageEditChannel.
  ///
  /// In en, this message translates to:
  /// **'Edit channel'**
  String get manageChannelPageEditChannel;

  /// No description provided for @manageChannelPageMenuCopyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON Feed URL'**
  String get manageChannelPageMenuCopyJson;

  /// No description provided for @manageChannelPageMenuCopyRss.
  ///
  /// In en, this message translates to:
  /// **'Copy RSS URL'**
  String get manageChannelPageMenuCopyRss;

  /// No description provided for @manageChannelPageMenuCopyAtom.
  ///
  /// In en, this message translates to:
  /// **'Copy Atom URL'**
  String get manageChannelPageMenuCopyAtom;

  /// No description provided for @manageChannelPageMenuDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get manageChannelPageMenuDelete;

  /// No description provided for @manageChannelPageReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get manageChannelPageReasonHint;

  /// No description provided for @manageChannelPageRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageChannelPageRemoveTooltip;

  /// No description provided for @manageChannelPageGateCitizensOnly.
  ///
  /// In en, this message translates to:
  /// **'CITIZENS ONLY'**
  String get manageChannelPageGateCitizensOnly;

  /// No description provided for @manageChannelPageWhoCanPost.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN POST'**
  String get manageChannelPageWhoCanPost;

  /// No description provided for @manageChannelPagePostersVerdict.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Only you can post} =1{You + 1 allow-listed account} other{You + {count} allow-listed accounts}}'**
  String manageChannelPagePostersVerdict(int count);

  /// No description provided for @manageChannelPagePostersExplainerApproved.
  ///
  /// In en, this message translates to:
  /// **'Posting is on \"Approved\" — only the channel owner and addresses on this list can create posts.'**
  String get manageChannelPagePostersExplainerApproved;

  /// No description provided for @manageChannelPagePostersVerdictOpen.
  ///
  /// In en, this message translates to:
  /// **'Anyone with access can post'**
  String get manageChannelPagePostersVerdictOpen;

  /// No description provided for @manageChannelPagePostersExplainerOpen.
  ///
  /// In en, this message translates to:
  /// **'Posting is on \"Open\" — this list has no effect right now. Switch the channel\'s posting policy to \"Approved\" in Edit channel to use it.'**
  String get manageChannelPagePostersExplainerOpen;

  /// No description provided for @manageChannelPagePostersVerdictOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only you can post'**
  String get manageChannelPagePostersVerdictOwnerOnly;

  /// No description provided for @manageChannelPagePostersExplainerOwner.
  ///
  /// In en, this message translates to:
  /// **'Posting is on \"Owner only\" — this list has no effect right now. Switch the channel\'s posting policy to \"Approved\" in Edit channel to grant posting rights to specific accounts.'**
  String get manageChannelPagePostersExplainerOwner;

  /// No description provided for @manageChannelPagePostersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No allow-listed posters yet'**
  String get manageChannelPagePostersEmpty;

  /// No description provided for @manageChannelPagePosterAddHint.
  ///
  /// In en, this message translates to:
  /// **'Name or 0x address (allow to post)'**
  String get manageChannelPagePosterAddHint;

  /// No description provided for @manageChannelPagePosterAddButton.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get manageChannelPagePosterAddButton;

  /// No description provided for @manageChannelPageFailAddPoster.
  ///
  /// In en, this message translates to:
  /// **'Failed to add poster'**
  String get manageChannelPageFailAddPoster;

  /// No description provided for @manageChannelPageFailRemovePoster.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove poster'**
  String get manageChannelPageFailRemovePoster;

  /// No description provided for @manageChannelPageWhosBlocked.
  ///
  /// In en, this message translates to:
  /// **'WHO\'S BLOCKED'**
  String get manageChannelPageWhosBlocked;

  /// No description provided for @manageChannelPageBansVerdict.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody is banned from this channel} =1{1 account banned} other{{count} accounts banned}}'**
  String manageChannelPageBansVerdict(int count);

  /// No description provided for @manageChannelPageBansExplainer.
  ///
  /// In en, this message translates to:
  /// **'Banned accounts can\'t read, post, comment, vote, or react in this channel. Bans stick until removed here.'**
  String get manageChannelPageBansExplainer;

  /// No description provided for @manageChannelPageBansEmpty.
  ///
  /// In en, this message translates to:
  /// **'No one banned from this channel'**
  String get manageChannelPageBansEmpty;

  /// No description provided for @manageChannelPageBanAddHint.
  ///
  /// In en, this message translates to:
  /// **'Name or 0x address (ban from channel)'**
  String get manageChannelPageBanAddHint;

  /// No description provided for @manageChannelPageBanAddButton.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get manageChannelPageBanAddButton;

  /// No description provided for @manageChannelPageFailBan.
  ///
  /// In en, this message translates to:
  /// **'Failed to ban'**
  String get manageChannelPageFailBan;

  /// No description provided for @manageChannelPageFailUnban.
  ///
  /// In en, this message translates to:
  /// **'Failed to unban'**
  String get manageChannelPageFailUnban;

  /// No description provided for @manageChannelPageWhoCanRead.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN READ'**
  String get manageChannelPageWhoCanRead;

  /// No description provided for @manageChannelPageReadVerdictPublic.
  ///
  /// In en, this message translates to:
  /// **'Channel is public — anyone can read'**
  String get manageChannelPageReadVerdictPublic;

  /// No description provided for @manageChannelPageReadExplainerPublic.
  ///
  /// In en, this message translates to:
  /// **'The read whitelist only applies to private channels. Toggle \"Private\" in Edit channel to use this list — otherwise entries here are ignored.'**
  String get manageChannelPageReadExplainerPublic;

  /// No description provided for @manageChannelPageReadVerdict.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Only you can read this private channel} =1{You + 1 reader} other{You + {count} readers}}'**
  String manageChannelPageReadVerdict(int count);

  /// No description provided for @manageChannelPageReadExplainerPrivate.
  ///
  /// In en, this message translates to:
  /// **'Channel is private — only you and accounts on the list below can read posts. New requests appear above the list; approving moves them in.'**
  String get manageChannelPageReadExplainerPrivate;

  /// No description provided for @manageChannelPageReadEmpty.
  ///
  /// In en, this message translates to:
  /// **'No accounts on the read list yet'**
  String get manageChannelPageReadEmpty;

  /// No description provided for @manageChannelPageReadAddHint.
  ///
  /// In en, this message translates to:
  /// **'Name or 0x address (grant read access)'**
  String get manageChannelPageReadAddHint;

  /// No description provided for @manageChannelPageReadAddButton.
  ///
  /// In en, this message translates to:
  /// **'Allow read'**
  String get manageChannelPageReadAddButton;

  /// No description provided for @manageChannelPageFailAddWhitelist.
  ///
  /// In en, this message translates to:
  /// **'Failed to add to whitelist'**
  String get manageChannelPageFailAddWhitelist;

  /// No description provided for @manageChannelPageFailRemove.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove'**
  String get manageChannelPageFailRemove;

  /// No description provided for @manageChannelPageFailApprove.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve'**
  String get manageChannelPageFailApprove;

  /// No description provided for @manageChannelPageFailIgnore.
  ///
  /// In en, this message translates to:
  /// **'Failed to ignore'**
  String get manageChannelPageFailIgnore;

  /// No description provided for @manageChannelPageRequestsHeader.
  ///
  /// In en, this message translates to:
  /// **'REQUESTS · LAST 14 DAYS'**
  String get manageChannelPageRequestsHeader;

  /// No description provided for @manageChannelPageFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get manageChannelPageFilterPending;

  /// No description provided for @manageChannelPageFilterIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get manageChannelPageFilterIgnored;

  /// No description provided for @manageChannelPageFilterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get manageChannelPageFilterApproved;

  /// No description provided for @manageChannelPageNoRequestsInWindow.
  ///
  /// In en, this message translates to:
  /// **'No {filter} requests in the last 14 days'**
  String manageChannelPageNoRequestsInWindow(Object filter);

  /// No description provided for @manageChannelPageRequestedAt.
  ///
  /// In en, this message translates to:
  /// **'Requested {when}'**
  String manageChannelPageRequestedAt(Object when);

  /// No description provided for @manageChannelPageRequestApprovedTag.
  ///
  /// In en, this message translates to:
  /// **'approved'**
  String get manageChannelPageRequestApprovedTag;

  /// No description provided for @manageChannelPageActionIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get manageChannelPageActionIgnore;

  /// No description provided for @manageChannelPageActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get manageChannelPageActionApprove;

  /// No description provided for @manageChannelPageJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get manageChannelPageJustNow;

  /// No description provided for @manageChannelPageMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String manageChannelPageMinutesAgo(Object minutes);

  /// No description provided for @manageChannelPageHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String manageChannelPageHoursAgo(Object hours);

  /// No description provided for @manageChannelPageDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String manageChannelPageDaysAgo(Object days);

  /// No description provided for @manageChannelPageMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months}mo ago'**
  String manageChannelPageMonthsAgo(Object months);

  /// No description provided for @manageServerPageNoActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'No active account'**
  String get manageServerPageNoActiveAccount;

  /// No description provided for @manageServerPageAuthorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Author profile updated'**
  String get manageServerPageAuthorUpdated;

  /// No description provided for @manageServerPageAuthorUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update author profile'**
  String get manageServerPageAuthorUpdateFailed;

  /// No description provided for @manageServerPageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied: {url}'**
  String manageServerPageCopied(Object url);

  /// No description provided for @manageServerPageDeleteChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete channel'**
  String get manageServerPageDeleteChannelTitle;

  /// No description provided for @manageServerPageDeleteChannelBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and every post in it? This can\'t be undone.'**
  String manageServerPageDeleteChannelBody(Object name);

  /// No description provided for @manageServerPageDeletedNamed.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String manageServerPageDeletedNamed(Object name);

  /// No description provided for @manageServerPageDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get manageServerPageDeleteFailed;

  /// No description provided for @manageServerPageGalleryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Gallery permission denied'**
  String get manageServerPageGalleryPermissionDenied;

  /// No description provided for @manageServerPageDownloadFailedHttp.
  ///
  /// In en, this message translates to:
  /// **'Download failed (HTTP {code})'**
  String manageServerPageDownloadFailedHttp(Object code);

  /// No description provided for @manageServerPageSavedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get manageServerPageSavedToGallery;

  /// No description provided for @manageServerPageDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get manageServerPageDownloadFailed;

  /// No description provided for @manageServerPageAddressMustBeHex.
  ///
  /// In en, this message translates to:
  /// **'Address must be 0x… (40 hex)'**
  String get manageServerPageAddressMustBeHex;

  /// No description provided for @manageServerPageAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Add failed'**
  String get manageServerPageAddFailed;

  /// No description provided for @manageServerPageRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Remove failed'**
  String get manageServerPageRemoveFailed;

  /// No description provided for @manageServerPageBanFailed.
  ///
  /// In en, this message translates to:
  /// **'Ban failed'**
  String get manageServerPageBanFailed;

  /// No description provided for @manageServerPageUnbanFailed.
  ///
  /// In en, this message translates to:
  /// **'Unban failed'**
  String get manageServerPageUnbanFailed;

  /// No description provided for @manageServerPageCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open'**
  String get manageServerPageCouldNotOpen;

  /// No description provided for @manageServerPageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get manageServerPageDelete;

  /// No description provided for @manageServerPageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get manageServerPageConfirm;

  /// No description provided for @manageServerPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Server'**
  String get manageServerPageTitle;

  /// No description provided for @manageServerPageIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get manageServerPageIdentity;

  /// No description provided for @manageServerPageCustomPill.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM'**
  String get manageServerPageCustomPill;

  /// No description provided for @manageServerPageIdentityDescSsp.
  ///
  /// In en, this message translates to:
  /// **'Your subscribed Social Server. Posts, channels, media and moderation all live here.'**
  String get manageServerPageIdentityDescSsp;

  /// No description provided for @manageServerPageIdentityDescCustom.
  ///
  /// In en, this message translates to:
  /// **'A custom feed server you added directly. Not registered on-chain — only visible to clients you tell about it.'**
  String get manageServerPageIdentityDescCustom;

  /// No description provided for @manageServerPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get manageServerPageLabel;

  /// No description provided for @manageServerPageUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get manageServerPageUrl;

  /// No description provided for @manageServerPageSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get manageServerPageSlug;

  /// No description provided for @manageServerPageAuthorProfile.
  ///
  /// In en, this message translates to:
  /// **'Author Profile'**
  String get manageServerPageAuthorProfile;

  /// No description provided for @manageServerPageAuthorDesc.
  ///
  /// In en, this message translates to:
  /// **'How non-PublicOS RSS readers see you (NetNewsWire, Feedbin, Inoreader, etc). PublicOS-aware clients ignore these fields and always show your on-chain profile instead.'**
  String get manageServerPageAuthorDesc;

  /// No description provided for @manageServerPageHandle.
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get manageServerPageHandle;

  /// No description provided for @manageServerPageNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get manageServerPageNote;

  /// No description provided for @manageServerPageHandleNote.
  ///
  /// In en, this message translates to:
  /// **'Handle is set automatically from your address and can\'t be changed here.'**
  String get manageServerPageHandleNote;

  /// No description provided for @manageServerPageDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get manageServerPageDisplayName;

  /// No description provided for @manageServerPageDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown next to your posts'**
  String get manageServerPageDisplayNameHint;

  /// No description provided for @manageServerPageBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get manageServerPageBio;

  /// No description provided for @manageServerPageBioHint.
  ///
  /// In en, this message translates to:
  /// **'A short line about you'**
  String get manageServerPageBioHint;

  /// No description provided for @manageServerPageAvatarUrl.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL'**
  String get manageServerPageAvatarUrl;

  /// No description provided for @manageServerPageSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get manageServerPageSaving;

  /// No description provided for @manageServerPageSaveAuthorProfile.
  ///
  /// In en, this message translates to:
  /// **'SAVE AUTHOR PROFILE'**
  String get manageServerPageSaveAuthorProfile;

  /// No description provided for @manageServerPageMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get manageServerPageMedia;

  /// No description provided for @manageServerPagePrivateBadge.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get manageServerPagePrivateBadge;

  /// No description provided for @manageServerPageFilesPill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 FILE} other{{count} FILES}}'**
  String manageServerPageFilesPill(int count);

  /// No description provided for @manageServerPageQuotaUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total} MB'**
  String manageServerPageQuotaUsed(Object used, Object total);

  /// No description provided for @manageServerPageQuotaUsedNoTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} MB used'**
  String manageServerPageQuotaUsedNoTotal(Object used);

  /// No description provided for @manageServerPageFileCountWithMax.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} files'**
  String manageServerPageFileCountWithMax(Object count, Object max);

  /// No description provided for @manageServerPageFileCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String manageServerPageFileCount(int count);

  /// No description provided for @manageServerPageQuotaFullBoth.
  ///
  /// In en, this message translates to:
  /// **'Quota full. Delete files to free both size and count.'**
  String get manageServerPageQuotaFullBoth;

  /// No description provided for @manageServerPageFileCountLimit.
  ///
  /// In en, this message translates to:
  /// **'File-count limit reached. Delete files to upload more.'**
  String get manageServerPageFileCountLimit;

  /// No description provided for @manageServerPageStorageQuotaFull.
  ///
  /// In en, this message translates to:
  /// **'Storage quota full. Delete files to free space.'**
  String get manageServerPageStorageQuotaFull;

  /// No description provided for @manageServerPageNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media files. Files uploaded from compose post or avatar/banner pickers will show up here.'**
  String get manageServerPageNoMedia;

  /// No description provided for @manageServerPageUnknownMime.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get manageServerPageUnknownMime;

  /// No description provided for @manageServerPagePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get manageServerPagePreview;

  /// No description provided for @manageServerPageOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get manageServerPageOpenInBrowser;

  /// No description provided for @manageServerPageDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get manageServerPageDownload;

  /// No description provided for @manageServerPageCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get manageServerPageCopyLink;

  /// No description provided for @manageServerPageChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get manageServerPageChannels;

  /// No description provided for @manageServerPageNoChannels.
  ///
  /// In en, this message translates to:
  /// **'No channels yet on this server.'**
  String get manageServerPageNoChannels;

  /// No description provided for @manageServerPageCreateChannel.
  ///
  /// In en, this message translates to:
  /// **'CREATE CHANNEL'**
  String get manageServerPageCreateChannel;

  /// No description provided for @manageServerPageCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get manageServerPageCopyUrl;

  /// No description provided for @manageServerPageRemoveFromTabs.
  ///
  /// In en, this message translates to:
  /// **'Remove from Tabs'**
  String get manageServerPageRemoveFromTabs;

  /// No description provided for @manageServerPageAddAsTab.
  ///
  /// In en, this message translates to:
  /// **'Add as Tab'**
  String get manageServerPageAddAsTab;

  /// No description provided for @manageServerPageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get manageServerPageSettings;

  /// No description provided for @manageServerPageAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Name or 0x address'**
  String get manageServerPageAddressHint;

  /// No description provided for @accountResolveNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No account found for that name — enter a 0x address or pick a contact'**
  String get accountResolveNoMatch;

  /// No description provided for @manageServerPageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get manageServerPageRemove;

  /// No description provided for @manageServerPageBans.
  ///
  /// In en, this message translates to:
  /// **'Bans'**
  String get manageServerPageBans;

  /// No description provided for @manageServerPageBansDesc.
  ///
  /// In en, this message translates to:
  /// **'Account-wide ban: blocked from posting, commenting and reacting on every channel you own here. Always wins over per-channel rules.'**
  String get manageServerPageBansDesc;

  /// No description provided for @manageServerPageReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get manageServerPageReasonHint;

  /// No description provided for @manageServerPageBan.
  ///
  /// In en, this message translates to:
  /// **'Ban'**
  String get manageServerPageBan;

  /// No description provided for @manageServerPageNoBans.
  ///
  /// In en, this message translates to:
  /// **'No accounts banned.'**
  String get manageServerPageNoBans;

  /// No description provided for @manageServerPageUnban.
  ///
  /// In en, this message translates to:
  /// **'Unban'**
  String get manageServerPageUnban;

  /// No description provided for @manageServerPageDeleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get manageServerPageDeleteFileTitle;

  /// No description provided for @manageServerPageDeleteFileBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This frees up your media quota and can\'t be undone.'**
  String manageServerPageDeleteFileBody(Object name);

  /// No description provided for @nodePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get nodePageTitle;

  /// No description provided for @nodePageMyNodes.
  ///
  /// In en, this message translates to:
  /// **'My Nodes'**
  String get nodePageMyNodes;

  /// No description provided for @nodePageNotSigner.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a signer. Signers are admitted through governance, not by sign-up.'**
  String get nodePageNotSigner;

  /// No description provided for @nodePageNodeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Node Directory'**
  String get nodePageNodeDirectory;

  /// No description provided for @nodePageDirectoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Browse the consensus signers currently securing the network.'**
  String get nodePageDirectoryDescription;

  /// No description provided for @nodePageBrowseNodes.
  ///
  /// In en, this message translates to:
  /// **'BROWSE NODES'**
  String get nodePageBrowseNodes;

  /// No description provided for @nodePageNotariesTitle.
  ///
  /// In en, this message translates to:
  /// **'The network\'s notaries'**
  String get nodePageNotariesTitle;

  /// No description provided for @nodePageNotariesBody1.
  ///
  /// In en, this message translates to:
  /// **'Signers run the consensus nodes that notarize every block: the shared public record the whole network is built on.'**
  String get nodePageNotariesBody1;

  /// No description provided for @nodePageNotariesBody2.
  ///
  /// In en, this message translates to:
  /// **'To keep that record trustworthy, the signer set stays small and accountable: new signers are admitted only through governance, never by open sign-up.'**
  String get nodePageNotariesBody2;

  /// No description provided for @nodePageAdmittedByGovernance.
  ///
  /// In en, this message translates to:
  /// **'Admitted by governance'**
  String get nodePageAdmittedByGovernance;

  /// No description provided for @nodePagePoaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'PoA consensus signers'**
  String get nodePagePoaSubtitle;

  /// No description provided for @nodePageFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load nodes'**
  String get nodePageFailedToLoad;

  /// No description provided for @nodePageNoNodes.
  ///
  /// In en, this message translates to:
  /// **'No nodes registered yet'**
  String get nodePageNoNodes;

  /// No description provided for @nodePageRunBy.
  ///
  /// In en, this message translates to:
  /// **'Run by '**
  String get nodePageRunBy;

  /// No description provided for @nodePageRemoveNodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Node'**
  String get nodePageRemoveNodeTitle;

  /// No description provided for @nodePageRemoveNodeBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this node? This action cannot be undone.\n\n{address}'**
  String nodePageRemoveNodeBody(Object address);

  /// No description provided for @nodePageRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get nodePageRemove;

  /// No description provided for @nodePageNodeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Node removed successfully'**
  String get nodePageNodeRemoved;

  /// No description provided for @nodePageManageNode.
  ///
  /// In en, this message translates to:
  /// **'Manage Node'**
  String get nodePageManageNode;

  /// No description provided for @nodePageAddress.
  ///
  /// In en, this message translates to:
  /// **'ADDRESS'**
  String get nodePageAddress;

  /// No description provided for @nodePageRemoveNodeButton.
  ///
  /// In en, this message translates to:
  /// **'REMOVE NODE'**
  String get nodePageRemoveNodeButton;

  /// No description provided for @nodePageLabelField.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get nodePageLabelField;

  /// No description provided for @nodePageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get nodePageSave;

  /// No description provided for @nodePageLabelUpper.
  ///
  /// In en, this message translates to:
  /// **'LABEL'**
  String get nodePageLabelUpper;

  /// No description provided for @nodePageEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit label'**
  String get nodePageEditLabel;

  /// No description provided for @notificationsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsScreenTitle;

  /// No description provided for @notificationsScreenTypesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notification types'**
  String get notificationsScreenTypesTooltip;

  /// No description provided for @notificationsScreenNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get notificationsScreenNoActivity;

  /// No description provided for @notificationsScreenYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get notificationsScreenYou;

  /// No description provided for @notificationsScreenYouUpdatedAvatar.
  ///
  /// In en, this message translates to:
  /// **'You updated your avatar'**
  String get notificationsScreenYouUpdatedAvatar;

  /// No description provided for @notificationsScreenTheyUpdatedAvatar.
  ///
  /// In en, this message translates to:
  /// **' updated their avatar'**
  String get notificationsScreenTheyUpdatedAvatar;

  /// No description provided for @notificationsScreenYouUpdatedBanner.
  ///
  /// In en, this message translates to:
  /// **'You updated your banner'**
  String get notificationsScreenYouUpdatedBanner;

  /// No description provided for @notificationsScreenTheyUpdatedBanner.
  ///
  /// In en, this message translates to:
  /// **' updated their banner'**
  String get notificationsScreenTheyUpdatedBanner;

  /// No description provided for @notificationsScreenYouUpdatedBio.
  ///
  /// In en, this message translates to:
  /// **'You updated your bio'**
  String get notificationsScreenYouUpdatedBio;

  /// No description provided for @notificationsScreenTheyUpdatedBio.
  ///
  /// In en, this message translates to:
  /// **' updated their bio'**
  String get notificationsScreenTheyUpdatedBio;

  /// No description provided for @notificationsScreenYouUpdatedProfile.
  ///
  /// In en, this message translates to:
  /// **'You updated your profile'**
  String get notificationsScreenYouUpdatedProfile;

  /// No description provided for @notificationsScreenTheyUpdatedProfile.
  ///
  /// In en, this message translates to:
  /// **' updated their profile'**
  String get notificationsScreenTheyUpdatedProfile;

  /// No description provided for @notificationsScreenYouUpdatedTabs.
  ///
  /// In en, this message translates to:
  /// **'You updated your tabs'**
  String get notificationsScreenYouUpdatedTabs;

  /// No description provided for @notificationsScreenTheyUpdatedTabs.
  ///
  /// In en, this message translates to:
  /// **' updated their tabs'**
  String get notificationsScreenTheyUpdatedTabs;

  /// No description provided for @notificationsScreenVouchedForYou.
  ///
  /// In en, this message translates to:
  /// **' vouched for you 🎉'**
  String get notificationsScreenVouchedForYou;

  /// No description provided for @notificationsScreenYouVouchedFor.
  ///
  /// In en, this message translates to:
  /// **'You vouched for '**
  String get notificationsScreenYouVouchedFor;

  /// No description provided for @notificationsScreenVouchedFor.
  ///
  /// In en, this message translates to:
  /// **' vouched for '**
  String get notificationsScreenVouchedFor;

  /// No description provided for @notificationsScreenYoureNowA.
  ///
  /// In en, this message translates to:
  /// **'You\'re now a '**
  String get notificationsScreenYoureNowA;

  /// No description provided for @notificationsScreenCitizen.
  ///
  /// In en, this message translates to:
  /// **'citizen'**
  String get notificationsScreenCitizen;

  /// No description provided for @notificationsScreenIsNowCitizen.
  ///
  /// In en, this message translates to:
  /// **' is now a citizen 🎉'**
  String get notificationsScreenIsNowCitizen;

  /// No description provided for @notificationsScreenMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String notificationsScreenMonths(int count);

  /// No description provided for @notificationsScreenYouPaidRent.
  ///
  /// In en, this message translates to:
  /// **'You paid your domain — {label}'**
  String notificationsScreenYouPaidRent(Object label);

  /// No description provided for @notificationsScreenTheyPaidRent.
  ///
  /// In en, this message translates to:
  /// **' paid their domain — {label}'**
  String notificationsScreenTheyPaidRent(Object label);

  /// No description provided for @notificationsScreenYourAccountEvicted.
  ///
  /// In en, this message translates to:
  /// **'Your account was evicted for non-payment'**
  String get notificationsScreenYourAccountEvicted;

  /// No description provided for @notificationsScreenWasEvicted.
  ///
  /// In en, this message translates to:
  /// **' was evicted for non-payment'**
  String get notificationsScreenWasEvicted;

  /// No description provided for @notificationsScreenYouChangedName.
  ///
  /// In en, this message translates to:
  /// **'You changed your name'**
  String get notificationsScreenYouChangedName;

  /// No description provided for @notificationsScreenYoureNowHandle.
  ///
  /// In en, this message translates to:
  /// **'You\'re now @{name}'**
  String notificationsScreenYoureNowHandle(Object name);

  /// No description provided for @notificationsScreenChangedTheirName.
  ///
  /// In en, this message translates to:
  /// **' changed their name'**
  String get notificationsScreenChangedTheirName;

  /// No description provided for @notificationsScreenIsNowHandle.
  ///
  /// In en, this message translates to:
  /// **' is now @{name}'**
  String notificationsScreenIsNowHandle(Object name);

  /// No description provided for @notificationsScreenYouChangedDisplayName.
  ///
  /// In en, this message translates to:
  /// **'You changed your display name'**
  String get notificationsScreenYouChangedDisplayName;

  /// No description provided for @notificationsScreenYouChangedDisplayNameTo.
  ///
  /// In en, this message translates to:
  /// **'You changed your display name to {name}'**
  String notificationsScreenYouChangedDisplayNameTo(Object name);

  /// No description provided for @notificationsScreenChangedDisplayName.
  ///
  /// In en, this message translates to:
  /// **' changed their display name'**
  String get notificationsScreenChangedDisplayName;

  /// No description provided for @notificationsScreenChangedDisplayNameTo.
  ///
  /// In en, this message translates to:
  /// **' changed their display name to {name}'**
  String notificationsScreenChangedDisplayNameTo(Object name);

  /// No description provided for @notificationsScreenRelTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get notificationsScreenRelTimeNow;

  /// No description provided for @profilePageVoteStarted.
  ///
  /// In en, this message translates to:
  /// **'Vote started — members need to approve'**
  String get profilePageVoteStarted;

  /// No description provided for @profilePageBioPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Tell us something about yourself!'**
  String get profilePageBioPlaceholder;

  /// No description provided for @profilePageSavingToChain.
  ///
  /// In en, this message translates to:
  /// **'Saving to chain...'**
  String get profilePageSavingToChain;

  /// No description provided for @profilePageRefreshingProfile.
  ///
  /// In en, this message translates to:
  /// **'Refreshing profile...'**
  String get profilePageRefreshingProfile;

  /// No description provided for @profilePageStartingVote.
  ///
  /// In en, this message translates to:
  /// **'Starting vote...'**
  String get profilePageStartingVote;

  /// No description provided for @profilePageProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profilePageProfileUpdated;

  /// No description provided for @profilePageBlockchainError.
  ///
  /// In en, this message translates to:
  /// **'Blockchain error — please try again'**
  String get profilePageBlockchainError;

  /// No description provided for @profilePageSavingLayout.
  ///
  /// In en, this message translates to:
  /// **'Saving layout...'**
  String get profilePageSavingLayout;

  /// No description provided for @profilePageLayoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Layout saved'**
  String get profilePageLayoutSaved;

  /// No description provided for @profilePageDeletingFromChain.
  ///
  /// In en, this message translates to:
  /// **'Deleting from chain...'**
  String get profilePageDeletingFromChain;

  /// No description provided for @profilePageRecordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get profilePageRecordDeleted;

  /// No description provided for @profilePageMemberCountWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{member} other{members}}'**
  String profilePageMemberCountWord(int count);

  /// No description provided for @profilePageFoundedBy.
  ///
  /// In en, this message translates to:
  /// **'founded by '**
  String get profilePageFoundedBy;

  /// No description provided for @profilePageJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {month} {year}'**
  String profilePageJoined(Object month, Object year);

  /// No description provided for @profilePageMonthJanuary.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get profilePageMonthJanuary;

  /// No description provided for @profilePageMonthFebruary.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get profilePageMonthFebruary;

  /// No description provided for @profilePageMonthMarch.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get profilePageMonthMarch;

  /// No description provided for @profilePageMonthApril.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get profilePageMonthApril;

  /// No description provided for @profilePageMonthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get profilePageMonthMay;

  /// No description provided for @profilePageMonthJune.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get profilePageMonthJune;

  /// No description provided for @profilePageMonthJuly.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get profilePageMonthJuly;

  /// No description provided for @profilePageMonthAugust.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get profilePageMonthAugust;

  /// No description provided for @profilePageMonthSeptember.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get profilePageMonthSeptember;

  /// No description provided for @profilePageMonthOctober.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get profilePageMonthOctober;

  /// No description provided for @profilePageMonthNovember.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get profilePageMonthNovember;

  /// No description provided for @profilePageMonthDecember.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get profilePageMonthDecember;

  /// No description provided for @profileQrPageScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan to open this profile.'**
  String get profileQrPageScanHint;

  /// No description provided for @profileQrPageLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Profile link copied'**
  String get profileQrPageLinkCopied;

  /// No description provided for @profileQrPageCopyLink.
  ///
  /// In en, this message translates to:
  /// **'COPY PROFILE LINK'**
  String get profileQrPageCopyLink;

  /// No description provided for @contactProfileSettingsManageContact.
  ///
  /// In en, this message translates to:
  /// **'Manage Contact'**
  String get contactProfileSettingsManageContact;

  /// No description provided for @contactProfileSettingsContactOSAddress.
  ///
  /// In en, this message translates to:
  /// **'ContactOS Address'**
  String get contactProfileSettingsContactOSAddress;

  /// No description provided for @contactProfileSettingsPrimaryInboxId.
  ///
  /// In en, this message translates to:
  /// **'Primary Inbox ID'**
  String get contactProfileSettingsPrimaryInboxId;

  /// No description provided for @contactProfileSettingsRegisteredInboxIds.
  ///
  /// In en, this message translates to:
  /// **'Registered Inbox IDs'**
  String get contactProfileSettingsRegisteredInboxIds;

  /// No description provided for @contactProfileSettingsDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get contactProfileSettingsDefaultLabel;

  /// No description provided for @contactProfileSettingsInboxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} Inbox ID'**
  String contactProfileSettingsInboxIdLabel(Object label);

  /// No description provided for @contactProfileSettingsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String contactProfileSettingsCopiedToClipboard(Object label);

  /// No description provided for @contactProfileSettingsInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Address'**
  String get contactProfileSettingsInvalidAddress;

  /// No description provided for @contactProfileSettingsBlockContact.
  ///
  /// In en, this message translates to:
  /// **'Block Contact'**
  String get contactProfileSettingsBlockContact;

  /// No description provided for @contactProfileSettingsUnblockContact.
  ///
  /// In en, this message translates to:
  /// **'Unblock Contact'**
  String get contactProfileSettingsUnblockContact;

  /// No description provided for @contactProfileSettingsContactBlocked.
  ///
  /// In en, this message translates to:
  /// **'Contact blocked successfully'**
  String get contactProfileSettingsContactBlocked;

  /// No description provided for @contactProfileSettingsContactUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Contact unblocked successfully'**
  String get contactProfileSettingsContactUnblocked;

  /// No description provided for @groupAccountSettingsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get groupAccountSettingsCopiedToClipboard;

  /// No description provided for @groupAccountSettingsLeaveOrgTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Org'**
  String get groupAccountSettingsLeaveOrgTitle;

  /// No description provided for @groupAccountSettingsLeaveOrgConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave {name}?\n\nYou will lose access to org actions and will need to be re-added by members to rejoin.'**
  String groupAccountSettingsLeaveOrgConfirm(Object name);

  /// No description provided for @groupAccountSettingsLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get groupAccountSettingsLeaveButton;

  /// No description provided for @groupAccountSettingsLeftOrgMessage.
  ///
  /// In en, this message translates to:
  /// **'You have left {name}'**
  String groupAccountSettingsLeftOrgMessage(Object name);

  /// No description provided for @groupAccountSettingsLeaveOrgFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave org'**
  String get groupAccountSettingsLeaveOrgFailed;

  /// No description provided for @groupAccountSettingsOrgIdentity.
  ///
  /// In en, this message translates to:
  /// **'Org Identity'**
  String get groupAccountSettingsOrgIdentity;

  /// No description provided for @groupAccountSettingsNameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get groupAccountSettingsNameLabel;

  /// No description provided for @groupAccountSettingsPublicosAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'PUBLICOS ADDRESS'**
  String get groupAccountSettingsPublicosAddressLabel;

  /// No description provided for @groupAccountSettingsVotingQuorumLabel.
  ///
  /// In en, this message translates to:
  /// **'VOTING QUORUM'**
  String get groupAccountSettingsVotingQuorumLabel;

  /// No description provided for @groupAccountSettingsVotingQuorumValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% participation to pass'**
  String groupAccountSettingsVotingQuorumValue(int percent);

  /// No description provided for @groupAccountSettingsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get groupAccountSettingsNotAvailable;

  /// No description provided for @groupAccountSettingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get groupAccountSettingsDangerZone;

  /// No description provided for @groupAccountSettingsLeaveThisOrg.
  ///
  /// In en, this message translates to:
  /// **'Leave this org'**
  String get groupAccountSettingsLeaveThisOrg;

  /// No description provided for @groupAccountSettingsLeaveThisOrgDescription.
  ///
  /// In en, this message translates to:
  /// **'You will be removed from the member list. This action is immediate and does not require a vote.'**
  String get groupAccountSettingsLeaveThisOrgDescription;

  /// No description provided for @groupAccountSettingsLeaveOrgButton.
  ///
  /// In en, this message translates to:
  /// **'LEAVE ORG'**
  String get groupAccountSettingsLeaveOrgButton;

  /// No description provided for @groupAccountSettingsCannotLeaveLastMember.
  ///
  /// In en, this message translates to:
  /// **'CANNOT LEAVE AS LAST MEMBER'**
  String get groupAccountSettingsCannotLeaveLastMember;

  /// No description provided for @groupAccountSettingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get groupAccountSettingsDataSection;

  /// No description provided for @groupAccountSettingsRefreshOrgData.
  ///
  /// In en, this message translates to:
  /// **'REFRESH ORG DATA'**
  String get groupAccountSettingsRefreshOrgData;

  /// No description provided for @groupChatSettingsNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Group name cannot be empty'**
  String get groupChatSettingsNameEmpty;

  /// No description provided for @groupChatSettingsUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group information updated successfully'**
  String get groupChatSettingsUpdateSuccess;

  /// No description provided for @groupChatSettingsMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed successfully'**
  String get groupChatSettingsMemberRemoved;

  /// No description provided for @groupChatSettingsMembersAdded.
  ///
  /// In en, this message translates to:
  /// **'Members added successfully. Refreshing group data...'**
  String get groupChatSettingsMembersAdded;

  /// No description provided for @groupChatSettingsAdminRemoved.
  ///
  /// In en, this message translates to:
  /// **'Admin role removed successfully'**
  String get groupChatSettingsAdminRemoved;

  /// No description provided for @groupChatSettingsAdminGranted.
  ///
  /// In en, this message translates to:
  /// **'Admin role granted successfully'**
  String get groupChatSettingsAdminGranted;

  /// No description provided for @groupChatSettingsSuperAdminRemoved.
  ///
  /// In en, this message translates to:
  /// **'Super admin role removed successfully'**
  String get groupChatSettingsSuperAdminRemoved;

  /// No description provided for @groupChatSettingsSuperAdminGranted.
  ///
  /// In en, this message translates to:
  /// **'Super admin role granted successfully'**
  String get groupChatSettingsSuperAdminGranted;

  /// No description provided for @groupChatSettingsRoleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'SUPER ADMIN'**
  String get groupChatSettingsRoleSuperAdmin;

  /// No description provided for @groupChatSettingsRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get groupChatSettingsRoleAdmin;

  /// No description provided for @groupChatSettingsRoleMember.
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get groupChatSettingsRoleMember;

  /// No description provided for @groupChatSettingsRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get groupChatSettingsRemoveAdmin;

  /// No description provided for @groupChatSettingsMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get groupChatSettingsMakeAdmin;

  /// No description provided for @groupChatSettingsRemoveSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove super admin'**
  String get groupChatSettingsRemoveSuperAdmin;

  /// No description provided for @groupChatSettingsMakeSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make super admin'**
  String get groupChatSettingsMakeSuperAdmin;

  /// No description provided for @groupChatSettingsRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get groupChatSettingsRemoveMember;

  /// No description provided for @groupChatSettingsNotGroup.
  ///
  /// In en, this message translates to:
  /// **'This conversation is not a group chat'**
  String get groupChatSettingsNotGroup;

  /// No description provided for @groupChatSettingsDefaultGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupChatSettingsDefaultGroupName;

  /// No description provided for @groupChatSettingsSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupChatSettingsSectionDetails;

  /// No description provided for @groupChatSettingsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupChatSettingsFieldName;

  /// No description provided for @groupChatSettingsFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get groupChatSettingsFieldDescription;

  /// No description provided for @groupChatSettingsFieldImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get groupChatSettingsFieldImageUrl;

  /// No description provided for @groupChatSettingsSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get groupChatSettingsSaving;

  /// No description provided for @groupChatSettingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get groupChatSettingsSaveChanges;

  /// No description provided for @groupChatSettingsSectionMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupChatSettingsSectionMembers;

  /// No description provided for @groupChatSettingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search members…'**
  String get groupChatSettingsSearchHint;

  /// No description provided for @groupChatSettingsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get groupChatSettingsFilterAll;

  /// No description provided for @groupChatSettingsFilterSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get groupChatSettingsFilterSuperAdmin;

  /// No description provided for @groupChatSettingsFilterAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupChatSettingsFilterAdmin;

  /// No description provided for @groupChatSettingsFilterMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get groupChatSettingsFilterMember;

  /// No description provided for @groupChatSettingsNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members found'**
  String get groupChatSettingsNoMembers;

  /// No description provided for @groupChatSettingsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No members match \"{query}\"'**
  String groupChatSettingsNoMatch(Object query);

  /// No description provided for @groupChatSettingsChipLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String groupChatSettingsChipLabel(Object label, Object count);

  /// No description provided for @groupChatSettingsAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get groupChatSettingsAdd;

  /// No description provided for @publicosAccountSettingsAccountIdentity.
  ///
  /// In en, this message translates to:
  /// **'Account Identity'**
  String get publicosAccountSettingsAccountIdentity;

  /// No description provided for @publicosAccountSettingsUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'USERNAME'**
  String get publicosAccountSettingsUsernameLabel;

  /// No description provided for @publicosAccountSettingsAccountAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT ADDRESS'**
  String get publicosAccountSettingsAccountAddressLabel;

  /// No description provided for @publicosAccountSettingsRegisteredInboxIds.
  ///
  /// In en, this message translates to:
  /// **'Registered Inbox IDs'**
  String get publicosAccountSettingsRegisteredInboxIds;

  /// No description provided for @publicosAccountSettingsRegisteredInboxIdsHint.
  ///
  /// In en, this message translates to:
  /// **'XMTP inbox IDs registered to this account on-chain'**
  String get publicosAccountSettingsRegisteredInboxIdsHint;

  /// No description provided for @publicosAccountSettingsNoInboxIds.
  ///
  /// In en, this message translates to:
  /// **'No inbox IDs registered'**
  String get publicosAccountSettingsNoInboxIds;

  /// No description provided for @publicosAccountSettingsUnlabeled.
  ///
  /// In en, this message translates to:
  /// **'Unlabeled'**
  String get publicosAccountSettingsUnlabeled;

  /// No description provided for @publicosAccountSettingsInboxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Inbox ID'**
  String get publicosAccountSettingsInboxIdLabel;

  /// No description provided for @publicosAccountSettingsSessionWallets.
  ///
  /// In en, this message translates to:
  /// **'Session Wallets'**
  String get publicosAccountSettingsSessionWallets;

  /// No description provided for @publicosAccountSettingsSessionWalletsHint.
  ///
  /// In en, this message translates to:
  /// **'Wallet addresses authorized to control this account'**
  String get publicosAccountSettingsSessionWalletsHint;

  /// No description provided for @publicosAccountSettingsNoSessions.
  ///
  /// In en, this message translates to:
  /// **'No sessions found'**
  String get publicosAccountSettingsNoSessions;

  /// No description provided for @publicosAccountSettingsPrimaryBadge.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY'**
  String get publicosAccountSettingsPrimaryBadge;

  /// No description provided for @publicosAccountSettingsSessionNumber.
  ///
  /// In en, this message translates to:
  /// **'Session {number}'**
  String publicosAccountSettingsSessionNumber(Object number);

  /// No description provided for @publicosAccountSettingsSessionAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Session address'**
  String get publicosAccountSettingsSessionAddressLabel;

  /// No description provided for @publicosAccountSettingsConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get publicosAccountSettingsConversation;

  /// No description provided for @publicosAccountSettingsConversationHint.
  ///
  /// In en, this message translates to:
  /// **'Your direct message channel with this contact'**
  String get publicosAccountSettingsConversationHint;

  /// No description provided for @publicosAccountSettingsPrimaryInboxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'PRIMARY INBOX ID'**
  String get publicosAccountSettingsPrimaryInboxIdLabel;

  /// No description provided for @publicosAccountSettingsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get publicosAccountSettingsNotAvailable;

  /// No description provided for @publicosAccountSettingsActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get publicosAccountSettingsActions;

  /// No description provided for @publicosAccountSettingsRefreshing.
  ///
  /// In en, this message translates to:
  /// **'REFRESHING…'**
  String get publicosAccountSettingsRefreshing;

  /// No description provided for @publicosAccountSettingsRefreshContactDetails.
  ///
  /// In en, this message translates to:
  /// **'REFRESH CONTACT DETAILS'**
  String get publicosAccountSettingsRefreshContactDetails;

  /// No description provided for @publicosAccountSettingsContactRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Contact details refreshed'**
  String get publicosAccountSettingsContactRefreshed;

  /// No description provided for @publicosAccountSettingsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String publicosAccountSettingsCopiedToClipboard(Object label);

  /// No description provided for @xmtpContactSettingsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String xmtpContactSettingsCopiedToClipboard(Object label);

  /// No description provided for @xmtpContactSettingsInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid Address'**
  String get xmtpContactSettingsInvalidAddress;

  /// No description provided for @xmtpContactSettingsDisplayNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Display name updated successfully'**
  String get xmtpContactSettingsDisplayNameUpdated;

  /// No description provided for @xmtpContactSettingsColorUpdated.
  ///
  /// In en, this message translates to:
  /// **'Contact color updated successfully'**
  String get xmtpContactSettingsColorUpdated;

  /// No description provided for @xmtpContactSettingsDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Contact details updated successfully'**
  String get xmtpContactSettingsDetailsUpdated;

  /// No description provided for @xmtpContactSettingsUnsupportedContact.
  ///
  /// In en, this message translates to:
  /// **'This contact type is not supported by this settings screen'**
  String get xmtpContactSettingsUnsupportedContact;

  /// No description provided for @xmtpContactSettingsContactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get xmtpContactSettingsContactInformation;

  /// No description provided for @xmtpContactSettingsPrimaryInboxId.
  ///
  /// In en, this message translates to:
  /// **'Primary Inbox ID'**
  String get xmtpContactSettingsPrimaryInboxId;

  /// No description provided for @xmtpContactSettingsClientsSection.
  ///
  /// In en, this message translates to:
  /// **'XMTP Clients'**
  String get xmtpContactSettingsClientsSection;

  /// No description provided for @xmtpContactSettingsAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get xmtpContactSettingsAddressLabel;

  /// No description provided for @xmtpContactSettingsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get xmtpContactSettingsDisplayName;

  /// No description provided for @xmtpContactSettingsEnterDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Enter display name'**
  String get xmtpContactSettingsEnterDisplayName;

  /// No description provided for @xmtpContactSettingsChatColor.
  ///
  /// In en, this message translates to:
  /// **'Chat Color'**
  String get xmtpContactSettingsChatColor;

  /// No description provided for @xmtpContactSettingsSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get xmtpContactSettingsSaveChanges;

  /// No description provided for @xmtpContactSettingsUpdating.
  ///
  /// In en, this message translates to:
  /// **'UPDATING…'**
  String get xmtpContactSettingsUpdating;

  /// No description provided for @xmtpContactSettingsUpdateContactDetails.
  ///
  /// In en, this message translates to:
  /// **'UPDATE CONTACT DETAILS'**
  String get xmtpContactSettingsUpdateContactDetails;

  /// No description provided for @sspScreenNoActiveAccount.
  ///
  /// In en, this message translates to:
  /// **'No active account'**
  String get sspScreenNoActiveAccount;

  /// No description provided for @sspScreenNoActiveSession.
  ///
  /// In en, this message translates to:
  /// **'No active session'**
  String get sspScreenNoActiveSession;

  /// No description provided for @sspScreenEndpointNoUrl.
  ///
  /// In en, this message translates to:
  /// **'Endpoint has no URL'**
  String get sspScreenEndpointNoUrl;

  /// No description provided for @sspScreenConnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {label}…'**
  String sspScreenConnectingTo(Object label);

  /// No description provided for @sspScreenConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {label}'**
  String sspScreenConnectedTo(Object label);

  /// No description provided for @sspScreenRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed {label}'**
  String sspScreenRemoved(Object label);

  /// No description provided for @sspScreenCouldNotRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove {label}'**
  String sspScreenCouldNotRemove(Object label);

  /// No description provided for @sspScreenConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get sspScreenConnection;

  /// No description provided for @sspScreenEndpoint.
  ///
  /// In en, this message translates to:
  /// **'Endpoint'**
  String get sspScreenEndpoint;

  /// No description provided for @sspScreenManage.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get sspScreenManage;

  /// No description provided for @sspScreenProviders.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get sspScreenProviders;

  /// No description provided for @sspScreenRegisterSsp.
  ///
  /// In en, this message translates to:
  /// **'REGISTER SSP'**
  String get sspScreenRegisterSsp;

  /// No description provided for @sspScreenAddCustom.
  ///
  /// In en, this message translates to:
  /// **'ADD CUSTOM'**
  String get sspScreenAddCustom;

  /// No description provided for @sspScreenBadgeMine.
  ///
  /// In en, this message translates to:
  /// **'MINE'**
  String get sspScreenBadgeMine;

  /// No description provided for @sspScreenBadgeSubscribed.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBED'**
  String get sspScreenBadgeSubscribed;

  /// No description provided for @sspScreenEmptyCitizen.
  ///
  /// In en, this message translates to:
  /// **'No server connected yet. Pick an SSP from Services, register your own, or add a custom server below.'**
  String get sspScreenEmptyCitizen;

  /// No description provided for @sspScreenEmptyPrivate.
  ///
  /// In en, this message translates to:
  /// **'No server connected yet. Subscribe to an SSP from Services, register your own, or add a custom server below.'**
  String get sspScreenEmptyPrivate;

  /// No description provided for @sspScreenStatusUnreachableLabel.
  ///
  /// In en, this message translates to:
  /// **'UNREACHABLE'**
  String get sspScreenStatusUnreachableLabel;

  /// No description provided for @sspScreenStatusUnreachableDesc.
  ///
  /// In en, this message translates to:
  /// **'No feed server is responding. Social feeds, posts, and media are unavailable.'**
  String get sspScreenStatusUnreachableDesc;

  /// No description provided for @sspScreenStatusSspLabel.
  ///
  /// In en, this message translates to:
  /// **'SSP CONNECTED'**
  String get sspScreenStatusSspLabel;

  /// No description provided for @sspScreenStatusSspDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected through your subscribed Social Service Provider.'**
  String get sspScreenStatusSspDesc;

  /// No description provided for @sspScreenStatusCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM SERVER'**
  String get sspScreenStatusCustomLabel;

  /// No description provided for @sspScreenStatusCustomDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected through a custom feed server you configured.'**
  String get sspScreenStatusCustomDesc;

  /// No description provided for @sspScreenStatusOverrideLabel.
  ///
  /// In en, this message translates to:
  /// **'APP OVERRIDE'**
  String get sspScreenStatusOverrideLabel;

  /// No description provided for @sspScreenStatusOverrideDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected through an override endpoint set by this app.'**
  String get sspScreenStatusOverrideDesc;

  /// No description provided for @sspScreenStatusPublicLabel.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC FALLBACK'**
  String get sspScreenStatusPublicLabel;

  /// No description provided for @sspScreenStatusPublicDesc.
  ///
  /// In en, this message translates to:
  /// **'Connected to the default public feed server. Subscribe to an SSP or add a custom server for better reliability.'**
  String get sspScreenStatusPublicDesc;

  /// No description provided for @sspScreenLegendNoServer.
  ///
  /// In en, this message translates to:
  /// **'No feed server available'**
  String get sspScreenLegendNoServer;

  /// No description provided for @sspScreenLegendPublicFallback.
  ///
  /// In en, this message translates to:
  /// **'Public fallback server'**
  String get sspScreenLegendPublicFallback;

  /// No description provided for @sspScreenLegendSspOrCustom.
  ///
  /// In en, this message translates to:
  /// **'SSP or custom server'**
  String get sspScreenLegendSspOrCustom;

  /// No description provided for @sspScreenLabelUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get sspScreenLabelUrl;

  /// No description provided for @sspScreenLabelSubs.
  ///
  /// In en, this message translates to:
  /// **'SUBS'**
  String get sspScreenLabelSubs;

  /// No description provided for @sspScreenRunBy.
  ///
  /// In en, this message translates to:
  /// **'RUN BY'**
  String get sspScreenRunBy;

  /// No description provided for @sspScreenSubscriberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 subscriber} other{{count} subscribers}}'**
  String sspScreenSubscriberCount(int count);

  /// No description provided for @sspScreenConnect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get sspScreenConnect;

  /// No description provided for @sspScreenConnected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get sspScreenConnected;

  /// No description provided for @sspScreenDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get sspScreenDelete;

  /// No description provided for @sspScreenCustomServerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'custom server'**
  String get sspScreenCustomServerSubtitle;

  /// No description provided for @sspScreenRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'New SSP on-chain'**
  String get sspScreenRegisterTitle;

  /// No description provided for @sspScreenRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register yourself as a Social Service Provider. Citizens only.'**
  String get sspScreenRegisterSubtitle;

  /// No description provided for @sspScreenFieldSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get sspScreenFieldSlug;

  /// No description provided for @sspScreenSlugHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. my-ssp-service'**
  String get sspScreenSlugHint;

  /// No description provided for @sspScreenSlugHelper.
  ///
  /// In en, this message translates to:
  /// **'3-32 chars, lowercase, numbers, dashes, underscores'**
  String get sspScreenSlugHelper;

  /// No description provided for @sspScreenSlugRequired.
  ///
  /// In en, this message translates to:
  /// **'Slug is required'**
  String get sspScreenSlugRequired;

  /// No description provided for @sspScreenSlugInvalid.
  ///
  /// In en, this message translates to:
  /// **'3-32 chars: lowercase letters, numbers, - _'**
  String get sspScreenSlugInvalid;

  /// No description provided for @sspScreenFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sspScreenFieldTitle;

  /// No description provided for @sspScreenTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My SSP Service'**
  String get sspScreenTitleHint;

  /// No description provided for @sspScreenTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get sspScreenTitleRequired;

  /// No description provided for @sspScreenFieldApiUrl.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get sspScreenFieldApiUrl;

  /// No description provided for @sspScreenApiUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'API URL is required'**
  String get sspScreenApiUrlRequired;

  /// No description provided for @sspScreenFieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get sspScreenFieldRegion;

  /// No description provided for @sspScreenRegionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. us-east, eu-west'**
  String get sspScreenRegionHint;

  /// No description provided for @sspScreenFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get sspScreenFieldWebsite;

  /// No description provided for @sspScreenRegistering.
  ///
  /// In en, this message translates to:
  /// **'REGISTERING…'**
  String get sspScreenRegistering;

  /// No description provided for @sspScreenRegister.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get sspScreenRegister;

  /// No description provided for @sspScreenAddCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Point at your own server'**
  String get sspScreenAddCustomTitle;

  /// No description provided for @sspScreenAddCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reachability is verified after connecting.'**
  String get sspScreenAddCustomSubtitle;

  /// No description provided for @sspScreenFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sspScreenFieldName;

  /// No description provided for @sspScreenNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Feed Server'**
  String get sspScreenNameHint;

  /// No description provided for @sspScreenFieldServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get sspScreenFieldServerUrl;

  /// No description provided for @sspScreenUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'URL is required'**
  String get sspScreenUrlRequired;

  /// No description provided for @sspScreenTesting.
  ///
  /// In en, this message translates to:
  /// **'TESTING…'**
  String get sspScreenTesting;

  /// No description provided for @sspScreenAdd.
  ///
  /// In en, this message translates to:
  /// **'ADD'**
  String get sspScreenAdd;

  /// No description provided for @treasuryPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get treasuryPageTitle;

  /// No description provided for @treasuryPageActionFailedToSend.
  ///
  /// In en, this message translates to:
  /// **'{label} failed to send'**
  String treasuryPageActionFailedToSend(Object label);

  /// No description provided for @treasuryPageActionConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{label} confirmed'**
  String treasuryPageActionConfirmed(Object label);

  /// No description provided for @treasuryPageActionFailedOnChain.
  ///
  /// In en, this message translates to:
  /// **'{label} failed on-chain'**
  String treasuryPageActionFailedOnChain(Object label);

  /// No description provided for @treasuryPageClaimedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get treasuryPageClaimedSuccess;

  /// No description provided for @treasuryPageSubscribedTo.
  ///
  /// In en, this message translates to:
  /// **'Subscribed to {provider}'**
  String treasuryPageSubscribedTo(Object provider);

  /// No description provided for @treasuryPageProviderSwitched.
  ///
  /// In en, this message translates to:
  /// **'{provider} switched'**
  String treasuryPageProviderSwitched(Object provider);

  /// No description provided for @treasuryPageProviderExtended.
  ///
  /// In en, this message translates to:
  /// **'{provider} subscription extended'**
  String treasuryPageProviderExtended(Object provider);

  /// No description provided for @treasuryPageProviderOnboardingSoon.
  ///
  /// In en, this message translates to:
  /// **'Working on this — provider onboarding coming soon'**
  String get treasuryPageProviderOnboardingSoon;

  /// No description provided for @treasuryPagePeriodFallback.
  ///
  /// In en, this message translates to:
  /// **'period'**
  String get treasuryPagePeriodFallback;

  /// No description provided for @treasuryPagePeriodDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String treasuryPagePeriodDays(int count);

  /// No description provided for @treasuryPagePeriodHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h'**
  String treasuryPagePeriodHours(Object n);

  /// No description provided for @treasuryPagePeriodMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String treasuryPagePeriodMinutes(Object n);

  /// No description provided for @treasuryPageRelativeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get treasuryPageRelativeNow;

  /// No description provided for @treasuryPageRelativeSeconds.
  ///
  /// In en, this message translates to:
  /// **'in {n} s'**
  String treasuryPageRelativeSeconds(Object n);

  /// No description provided for @treasuryPageRelativeMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {n} min'**
  String treasuryPageRelativeMinutes(Object n);

  /// No description provided for @treasuryPageRelativeHours.
  ///
  /// In en, this message translates to:
  /// **'in {n} h'**
  String treasuryPageRelativeHours(Object n);

  /// No description provided for @treasuryPageRelativeDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String treasuryPageRelativeDays(int count);

  /// No description provided for @treasuryPageRoleCitizen.
  ///
  /// In en, this message translates to:
  /// **'CITIZEN'**
  String get treasuryPageRoleCitizen;

  /// No description provided for @treasuryPageRolePrivate.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE ACCOUNT'**
  String get treasuryPageRolePrivate;

  /// No description provided for @treasuryPageRoleCitizenMeaning.
  ///
  /// In en, this message translates to:
  /// **'You get a share of the economy, vote on governance, create orgs. A 5+ character name is free to hold forever.'**
  String get treasuryPageRoleCitizenMeaning;

  /// No description provided for @treasuryPageRolePrivateMeaning.
  ///
  /// In en, this message translates to:
  /// **'You pay a recurring domain fee to hold your name and keep write access to the chain. You don\'t get a share of the economy or vote.'**
  String get treasuryPageRolePrivateMeaning;

  /// No description provided for @treasuryPageYourRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get treasuryPageYourRole;

  /// Services page summary for a socially verified domain (the old "citizen"). {privateIcon} is replaced in code by the private-account ghost badge; keep it right after the words "private accounts".
  ///
  /// In en, this message translates to:
  /// **'You hold a socially verified PublicOS Domain. You own PublicOS and get a share of its economy, which you can claim any time. Your BSP and SSP are a public service, free for you, while private accounts {privateIcon} pay for theirs. You choose your providers, so check your subscriptions often.'**
  String treasuryPageCitizenSummary(String privateIcon);

  /// No description provided for @treasuryPagePrivateSummary.
  ///
  /// In en, this message translates to:
  /// **'Your PublicOS Domain is private, no verification needed. A BSP is how your app reaches the chain: it reads for you and sends your transactions. You can use a public BSP (rate limited) or subscribe to one. SSP (feed and media hosting) is optional: subscribe to one here, use any server outside PublicOS, or run your own.'**
  String get treasuryPagePrivateSummary;

  /// No description provided for @treasuryPageWhatYouCanClaim.
  ///
  /// In en, this message translates to:
  /// **'What you can claim'**
  String get treasuryPageWhatYouCanClaim;

  /// No description provided for @treasuryPageClaimExplainer.
  ///
  /// In en, this message translates to:
  /// **'One claim pulls everything the economy owes you in a single transaction: your share of the economy and any provider earnings. Outstanding fines are withheld automatically.'**
  String get treasuryPageClaimExplainer;

  /// No description provided for @treasuryPageClaimable.
  ///
  /// In en, this message translates to:
  /// **'Claimable'**
  String get treasuryPageClaimable;

  /// No description provided for @treasuryPageStipend.
  ///
  /// In en, this message translates to:
  /// **'Economy share'**
  String get treasuryPageStipend;

  /// No description provided for @treasuryPageEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get treasuryPageEarnings;

  /// No description provided for @treasuryPageGarnished.
  ///
  /// In en, this message translates to:
  /// **'Withheld for penalties'**
  String get treasuryPageGarnished;

  /// No description provided for @treasuryPageClaiming.
  ///
  /// In en, this message translates to:
  /// **'CLAIMING...'**
  String get treasuryPageClaiming;

  /// No description provided for @treasuryPageClaimAmount.
  ///
  /// In en, this message translates to:
  /// **'CLAIM {amount} OX'**
  String treasuryPageClaimAmount(Object amount);

  /// No description provided for @treasuryPageNothingToClaim.
  ///
  /// In en, this message translates to:
  /// **'NOTHING TO CLAIM'**
  String get treasuryPageNothingToClaim;

  /// No description provided for @treasuryPageRunProviders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You run 1 provider — their earnings are part of this claim.} other{You run {count} providers — their earnings are part of this claim.}}'**
  String treasuryPageRunProviders(int count);

  /// No description provided for @treasuryPageBecomeProvider.
  ///
  /// In en, this message translates to:
  /// **'Become a provider'**
  String get treasuryPageBecomeProvider;

  /// No description provided for @treasuryPageBecomeProviderBlurb.
  ///
  /// In en, this message translates to:
  /// **'Providers work the network and get paid for it. Run a BSP to route private accounts, or an SSP to host their social data — every subscriber adds to your claim.'**
  String get treasuryPageBecomeProviderBlurb;

  /// No description provided for @treasuryPageBecomeProviderButton.
  ///
  /// In en, this message translates to:
  /// **'BECOME A PROVIDER'**
  String get treasuryPageBecomeProviderButton;

  /// No description provided for @treasuryPageBspBlurb.
  ///
  /// In en, this message translates to:
  /// **'An independent subscription that routes you to the chain. Paid by the second, only while it serves you.'**
  String get treasuryPageBspBlurb;

  /// No description provided for @treasuryPageSspBlurb.
  ///
  /// In en, this message translates to:
  /// **'An independent subscription that hosts your social data. Paid by the second, only while it serves you.'**
  String get treasuryPageSspBlurb;

  /// No description provided for @treasuryPageSubNone.
  ///
  /// In en, this message translates to:
  /// **'NONE'**
  String get treasuryPageSubNone;

  /// No description provided for @treasuryPageSubExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get treasuryPageSubExpired;

  /// No description provided for @treasuryPageSubActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get treasuryPageSubActive;

  /// No description provided for @treasuryPageSubSwitchOpen.
  ///
  /// In en, this message translates to:
  /// **'SWITCH OPEN'**
  String get treasuryPageSubSwitchOpen;

  /// No description provided for @treasuryPageSubExtendOpen.
  ///
  /// In en, this message translates to:
  /// **'EXTEND OPEN'**
  String get treasuryPageSubExtendOpen;

  /// No description provided for @treasuryPageProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get treasuryPageProvider;

  /// No description provided for @treasuryPagePaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get treasuryPagePaidUntil;

  /// No description provided for @treasuryPageCycleEnds.
  ///
  /// In en, this message translates to:
  /// **'Cycle ends'**
  String get treasuryPageCycleEnds;

  /// No description provided for @treasuryPageLastProvider.
  ///
  /// In en, this message translates to:
  /// **'Last {provider}'**
  String treasuryPageLastProvider(Object provider);

  /// No description provided for @treasuryPageLapsed.
  ///
  /// In en, this message translates to:
  /// **'Lapsed'**
  String get treasuryPageLapsed;

  /// No description provided for @treasuryPageSubNoneCitizen.
  ///
  /// In en, this message translates to:
  /// **'Pick a {provider} to host your service. Citizens don\'t pay — the network mints the {provider} fee for you.'**
  String treasuryPageSubNoneCitizen(Object provider);

  /// No description provided for @treasuryPageSubNonePrivate.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to a {provider}. The fee accrues by the second and is drawn from your service balance — only once the provider has enough subscribers to be paid.'**
  String treasuryPageSubNonePrivate(Object provider);

  /// No description provided for @treasuryPageSubActivePrivateBody.
  ///
  /// In en, this message translates to:
  /// **'Active. The fee draws from your service balance by the second. Switch any time — the old provider is paid to the second.'**
  String treasuryPageSubActivePrivateBody(Object provider);

  /// No description provided for @treasuryPageSubCitizenLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Active. You can switch {provider} from {fromWhen} (without losing your cycle); the network auto-renews {renewWhen}.'**
  String treasuryPageSubCitizenLockedBody(
      Object provider, Object fromWhen, Object renewWhen);

  /// No description provided for @treasuryPageSubCitizenSwitchOpenBody.
  ///
  /// In en, this message translates to:
  /// **'You can switch {provider} now — your cycle end is kept, nothing extra to pay. Switch closes {closesWhen}, then the network auto-renews.'**
  String treasuryPageSubCitizenSwitchOpenBody(
      Object provider, Object closesWhen);

  /// No description provided for @treasuryPageSubExpiredBody.
  ///
  /// In en, this message translates to:
  /// **'Subscription lapsed. Subscribe again (the same provider or a new one) to restore the service.'**
  String get treasuryPageSubExpiredBody;

  /// No description provided for @treasuryPageSubCitizenExtendOpenBody.
  ///
  /// In en, this message translates to:
  /// **'Extend now to keep {provider} service — the network mints the fee for you.'**
  String treasuryPageSubCitizenExtendOpenBody(Object provider);

  /// No description provided for @treasuryPageOpening.
  ///
  /// In en, this message translates to:
  /// **'OPENING…'**
  String get treasuryPageOpening;

  /// No description provided for @treasuryPagePickProvider.
  ///
  /// In en, this message translates to:
  /// **'PICK A {provider}'**
  String treasuryPagePickProvider(Object provider);

  /// No description provided for @treasuryPageSubscribeAgain.
  ///
  /// In en, this message translates to:
  /// **'SUBSCRIBE AGAIN'**
  String get treasuryPageSubscribeAgain;

  /// No description provided for @treasuryPagePaying.
  ///
  /// In en, this message translates to:
  /// **'PAYING…'**
  String get treasuryPagePaying;

  /// No description provided for @treasuryPagePayInAdvance.
  ///
  /// In en, this message translates to:
  /// **'PAY IN ADVANCE'**
  String get treasuryPagePayInAdvance;

  /// No description provided for @treasuryPageSwitchOpens.
  ///
  /// In en, this message translates to:
  /// **'SWITCH OPENS {when}'**
  String treasuryPageSwitchOpens(Object when);

  /// No description provided for @treasuryPageExtending.
  ///
  /// In en, this message translates to:
  /// **'EXTENDING…'**
  String get treasuryPageExtending;

  /// No description provided for @treasuryPageExtendProvider.
  ///
  /// In en, this message translates to:
  /// **'EXTEND {provider}'**
  String treasuryPageExtendProvider(Object provider);

  /// No description provided for @treasuryPageSwitchProvider.
  ///
  /// In en, this message translates to:
  /// **'SWITCH {provider}'**
  String treasuryPageSwitchProvider(Object provider);

  /// No description provided for @treasuryPageParameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get treasuryPageParameters;

  /// No description provided for @treasuryPageDomainPrice.
  ///
  /// In en, this message translates to:
  /// **'Domain price'**
  String get treasuryPageDomainPrice;

  /// No description provided for @treasuryPageDomainTier3.
  ///
  /// In en, this message translates to:
  /// **'3 chars {price}'**
  String treasuryPageDomainTier3(Object price);

  /// No description provided for @treasuryPageDomainPriceExplain.
  ///
  /// In en, this message translates to:
  /// **'4 chars {tier4} · 5 chars {tier5} · 6+ {tier6plus}. Citizens are free at {minChars}+ chars. 98% of each payment is burned, 2% is shared with verified PublicOS Domains.'**
  String treasuryPageDomainPriceExplain(
      Object tier4, Object tier5, Object tier6plus, Object minChars);

  /// No description provided for @treasuryPageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get treasuryPageLoading;

  /// No description provided for @treasuryPageBspFee.
  ///
  /// In en, this message translates to:
  /// **'BSP fee'**
  String get treasuryPageBspFee;

  /// No description provided for @treasuryPageBspFeeExplain.
  ///
  /// In en, this message translates to:
  /// **'Paid by a private to their BSP each period. Independent of the domain.'**
  String get treasuryPageBspFeeExplain;

  /// No description provided for @treasuryPageSspFee.
  ///
  /// In en, this message translates to:
  /// **'SSP fee'**
  String get treasuryPageSspFee;

  /// No description provided for @treasuryPageSspFeeExplain.
  ///
  /// In en, this message translates to:
  /// **'Paid by a private to their SSP each period. Independent of the domain.'**
  String get treasuryPageSspFeeExplain;

  /// No description provided for @treasuryPageMultiMonthDiscount.
  ///
  /// In en, this message translates to:
  /// **'Multi-month discount'**
  String get treasuryPageMultiMonthDiscount;

  /// No description provided for @treasuryPageDiscountValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% per extra month'**
  String treasuryPageDiscountValue(Object percent);

  /// No description provided for @treasuryPageDiscountExplain.
  ///
  /// In en, this message translates to:
  /// **'Applies to the domain fee when you pay several periods up front.'**
  String get treasuryPageDiscountExplain;

  /// No description provided for @treasuryPageTotalSupply.
  ///
  /// In en, this message translates to:
  /// **'Total supply'**
  String get treasuryPageTotalSupply;

  /// No description provided for @treasuryPageTotalSupplyExplain.
  ///
  /// In en, this message translates to:
  /// **'Shrinks on each domain burn, grows when the network mints provider fees and welcome bonuses.'**
  String get treasuryPageTotalSupplyExplain;

  /// No description provided for @treasuryPageTreasuryBalance.
  ///
  /// In en, this message translates to:
  /// **'Treasury balance'**
  String get treasuryPageTreasuryBalance;

  /// No description provided for @treasuryPageTreasuryBalanceExplain.
  ///
  /// In en, this message translates to:
  /// **'The DAO\'s operating budget. Funds grants and governance-approved spending.'**
  String get treasuryPageTreasuryBalanceExplain;

  /// No description provided for @treasuryPageParamsGovernance.
  ///
  /// In en, this message translates to:
  /// **'Parameters are set by network governance'**
  String get treasuryPageParamsGovernance;

  /// No description provided for @treasuryPageWhenToCheckBack.
  ///
  /// In en, this message translates to:
  /// **'When to check back'**
  String get treasuryPageWhenToCheckBack;

  /// No description provided for @treasuryPageCadenceClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim'**
  String get treasuryPageCadenceClaimTitle;

  /// No description provided for @treasuryPageCadenceClaimBody.
  ///
  /// In en, this message translates to:
  /// **'Your economy share, provider earnings and the welcome bonus accrue continuously. Check monthly and claim when the amount is worth a tx fee.'**
  String get treasuryPageCadenceClaimBody;

  /// No description provided for @treasuryPageCadenceDomainTitle.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get treasuryPageCadenceDomainTitle;

  /// No description provided for @treasuryPageCadenceDomainBody.
  ///
  /// In en, this message translates to:
  /// **'Your paid-until date is on this page. Pay several periods up front to reduce checks and earn the discount.'**
  String get treasuryPageCadenceDomainBody;

  /// No description provided for @treasuryPageCadenceServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Each service expires on its own clock, independent of your domain. Renew before the paid-until date.'**
  String get treasuryPageCadenceServicesBody;

  /// Services page: body of the card that opens the node directory (Nodes moved inside Services, 2026-09-16).
  ///
  /// In en, this message translates to:
  /// **'The public directory of the nodes that run the network: who operates each one.'**
  String get treasuryPageNodesBody;

  /// No description provided for @treasuryPageGrants.
  ///
  /// In en, this message translates to:
  /// **'Grants'**
  String get treasuryPageGrants;

  /// No description provided for @treasuryPageGrantsTitle.
  ///
  /// In en, this message translates to:
  /// **'DAO-funded organizations and projects'**
  String get treasuryPageGrantsTitle;

  /// No description provided for @treasuryPageGrantsBody.
  ///
  /// In en, this message translates to:
  /// **'Governance-approved allocations for public-goods projects. Granted tokens land in your claim.'**
  String get treasuryPageGrantsBody;

  /// No description provided for @treasuryPageGrantsVotingNote.
  ///
  /// In en, this message translates to:
  /// **'Grant proposals go through the governance voting process'**
  String get treasuryPageGrantsVotingNote;

  /// No description provided for @trustTreeScreenAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'SOCIAL GRAPH'**
  String get trustTreeScreenAppBarTitle;

  /// No description provided for @trustTreeScreenAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get trustTreeScreenAccountNotFound;

  /// No description provided for @trustTreeScreenVouchNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Vouch not confirmed. Please retry.'**
  String get trustTreeScreenVouchNotConfirmed;

  /// No description provided for @trustTreeScreenUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get trustTreeScreenUnknown;

  /// No description provided for @trustTreeScreenLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading trust data…'**
  String get trustTreeScreenLoading;

  /// No description provided for @trustTreeScreenSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or address'**
  String get trustTreeScreenSearchHint;

  /// No description provided for @trustTreeScreenCopyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get trustTreeScreenCopyAddress;

  /// No description provided for @trustTreeScreenAddressCopied.
  ///
  /// In en, this message translates to:
  /// **'Address copied'**
  String get trustTreeScreenAddressCopied;

  /// No description provided for @trustTreeScreenCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'BY {creator}'**
  String trustTreeScreenCreatedBy(Object creator);

  /// No description provided for @trustTreeScreenVouched.
  ///
  /// In en, this message translates to:
  /// **'YOU VOUCHED'**
  String get trustTreeScreenVouched;

  /// No description provided for @trustTreeScreenNoVouchers.
  ///
  /// In en, this message translates to:
  /// **'NO VOUCHERS'**
  String get trustTreeScreenNoVouchers;

  /// No description provided for @trustTreeScreenNoVouchees.
  ///
  /// In en, this message translates to:
  /// **'NO VOUCHEES'**
  String get trustTreeScreenNoVouchees;

  /// No description provided for @trustTreeScreenMoreCount.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String trustTreeScreenMoreCount(Object count);

  /// No description provided for @trustTreeScreenMyTree.
  ///
  /// In en, this message translates to:
  /// **'MY TREE'**
  String get trustTreeScreenMyTree;

  /// No description provided for @trustTreeScreenVouching.
  ///
  /// In en, this message translates to:
  /// **'VOUCHING…'**
  String get trustTreeScreenVouching;

  /// No description provided for @trustTreeScreenVouchFor.
  ///
  /// In en, this message translates to:
  /// **'VOUCH FOR {name}'**
  String trustTreeScreenVouchFor(Object name);

  /// No description provided for @mediaOverlayGalleryPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Gallery permission denied'**
  String get mediaOverlayGalleryPermissionDenied;

  /// No description provided for @mediaOverlayVideoSaved.
  ///
  /// In en, this message translates to:
  /// **'Video saved to gallery'**
  String get mediaOverlayVideoSaved;

  /// No description provided for @mediaOverlayImageSaved.
  ///
  /// In en, this message translates to:
  /// **'Image saved to gallery'**
  String get mediaOverlayImageSaved;

  /// No description provided for @mediaOverlaySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get mediaOverlaySaveFailed;

  /// No description provided for @mediaOverlayBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get mediaOverlayBack;

  /// No description provided for @mediaPickerOnlyImagesVideos.
  ///
  /// In en, this message translates to:
  /// **'Only images and videos can be attached here'**
  String get mediaPickerOnlyImagesVideos;

  /// No description provided for @messageInputVideoNeedsServer.
  ///
  /// In en, this message translates to:
  /// **'Sending a video needs a feed server'**
  String get messageInputVideoNeedsServer;

  /// No description provided for @messageInputSendOx.
  ///
  /// In en, this message translates to:
  /// **'Send OX'**
  String get messageInputSendOx;

  /// No description provided for @messageInputRecipientNoAddress.
  ///
  /// In en, this message translates to:
  /// **'This contact can\'t receive OX yet'**
  String get messageInputRecipientNoAddress;

  /// No description provided for @messageInputNoSendableMembers.
  ///
  /// In en, this message translates to:
  /// **'No one in this group can receive OX yet'**
  String get messageInputNoSendableMembers;

  /// No description provided for @messageInputAttachRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get messageInputAttachRequest;

  /// No description provided for @requestPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Request payment'**
  String get requestPaymentTitle;

  /// No description provided for @requestPaymentPayTo.
  ///
  /// In en, this message translates to:
  /// **'Receive at'**
  String get requestPaymentPayTo;

  /// No description provided for @requestPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get requestPaymentAmount;

  /// No description provided for @requestPaymentSend.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get requestPaymentSend;

  /// No description provided for @requestPaymentSending.
  ///
  /// In en, this message translates to:
  /// **'Sending request…'**
  String get requestPaymentSending;

  /// No description provided for @requestPaymentChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get requestPaymentChange;

  /// No description provided for @requestPaymentDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get requestPaymentDone;

  /// No description provided for @requestPaymentSent.
  ///
  /// In en, this message translates to:
  /// **'Payment request sent'**
  String get requestPaymentSent;

  /// No description provided for @requestPaymentCustomAddress.
  ///
  /// In en, this message translates to:
  /// **'Paste an ETH address'**
  String get requestPaymentCustomAddress;

  /// No description provided for @requestPaymentCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom address'**
  String get requestPaymentCustomLabel;

  /// No description provided for @requestPaymentInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'Invalid address'**
  String get requestPaymentInvalidAddress;

  /// No description provided for @documentPickerTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Document too large ({size} MB > {max} MB)'**
  String documentPickerTooLarge(Object size, Object max);

  /// No description provided for @documentReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the selected file'**
  String get documentReadFailed;

  /// No description provided for @documentTooLargeNoServer.
  ///
  /// In en, this message translates to:
  /// **'This document is too large to send without a feed server'**
  String get documentTooLargeNoServer;

  /// No description provided for @documentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'No app available to open this file'**
  String get documentOpenFailed;

  /// No description provided for @documentSave.
  ///
  /// In en, this message translates to:
  /// **'Save file'**
  String get documentSave;

  /// No description provided for @documentSaved.
  ///
  /// In en, this message translates to:
  /// **'File saved'**
  String get documentSaved;

  /// No description provided for @documentSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the file'**
  String get documentSaveFailed;

  /// No description provided for @channelHeaderVerifiedReaders.
  ///
  /// In en, this message translates to:
  /// **'Verified readers'**
  String get channelHeaderVerifiedReaders;

  /// No description provided for @channelHeaderTotalViews.
  ///
  /// In en, this message translates to:
  /// **'Total views'**
  String get channelHeaderTotalViews;

  /// No description provided for @channelHeaderOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get channelHeaderOwner;

  /// No description provided for @channelHeaderBy.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get channelHeaderBy;

  /// No description provided for @channelHeaderHostedBy.
  ///
  /// In en, this message translates to:
  /// **'hosted by'**
  String get channelHeaderHostedBy;

  /// No description provided for @channelHostedByCopy.
  ///
  /// In en, this message translates to:
  /// **'a copy'**
  String get channelHostedByCopy;

  /// No description provided for @channelHostNoSigTitle.
  ///
  /// In en, this message translates to:
  /// **'NO OWNER SIGNATURE'**
  String get channelHostNoSigTitle;

  /// No description provided for @channelHostNoSigExplain.
  ///
  /// In en, this message translates to:
  /// **'There is no owner\'s signature to check, so we cannot confirm who hosts this feed.'**
  String get channelHostNoSigExplain;

  /// No description provided for @channelHostBadSigTitle.
  ///
  /// In en, this message translates to:
  /// **'BAD OWNER SIGNATURE'**
  String get channelHostBadSigTitle;

  /// No description provided for @channelHostBadSigExplain.
  ///
  /// In en, this message translates to:
  /// **'A signature is given for the owner, and it is bad. We cannot confirm the claimed owner ever agreed to host this feed.'**
  String get channelHostBadSigExplain;

  /// No description provided for @signedCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'SIGNED COPY'**
  String get signedCopyTitle;

  /// No description provided for @signedCopyPostExplain.
  ///
  /// In en, this message translates to:
  /// **'A signed copy of the original post. Every field and signature is correct; it is being read here from another address than the one the author signed.'**
  String get signedCopyPostExplain;

  /// No description provided for @signedCopyChannelExplain.
  ///
  /// In en, this message translates to:
  /// **'The owner signed this channel at another address. This is a signed copy of it.'**
  String get signedCopyChannelExplain;

  /// No description provided for @channelHeaderVerifiedReadersWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{verified reader} other{verified readers}}'**
  String channelHeaderVerifiedReadersWord(int count);

  /// No description provided for @channelHeaderViewsWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{view} other{views}}'**
  String channelHeaderViewsWord(int count);

  /// No description provided for @channelHeaderWriters.
  ///
  /// In en, this message translates to:
  /// **'Writers'**
  String get channelHeaderWriters;

  /// No description provided for @channelHeaderWritersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 writer} other{{count} writers}}'**
  String channelHeaderWritersCount(int count);

  /// No description provided for @channelHeaderStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reader activity'**
  String get channelHeaderStatsTitle;

  /// No description provided for @channelHeaderReadersThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Verified readers this week'**
  String get channelHeaderReadersThisWeek;

  /// No description provided for @channelHeaderTodayPartial.
  ///
  /// In en, this message translates to:
  /// **'Today so far'**
  String get channelHeaderTodayPartial;

  /// No description provided for @channelHeaderTotalViewsAllTime.
  ///
  /// In en, this message translates to:
  /// **'Total views (all time)'**
  String get channelHeaderTotalViewsAllTime;

  /// No description provided for @channelHeaderByTypeCitizens.
  ///
  /// In en, this message translates to:
  /// **'Citizens'**
  String get channelHeaderByTypeCitizens;

  /// No description provided for @channelHeaderByTypePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private accounts'**
  String get channelHeaderByTypePrivate;

  /// No description provided for @channelHeaderByTypeSigned.
  ///
  /// In en, this message translates to:
  /// **'Signed, no account'**
  String get channelHeaderByTypeSigned;

  /// No description provided for @channelHeaderByTypeAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get channelHeaderByTypeAnonymous;

  /// No description provided for @channelHeaderToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get channelHeaderToday;

  /// No description provided for @channelHeaderVerifiedNote.
  ///
  /// In en, this message translates to:
  /// **'Verified readers are distinct citizen accounts whose reads carried a valid signature. Each counts once per week.'**
  String get channelHeaderVerifiedNote;

  /// No description provided for @channelHeaderClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get channelHeaderClose;

  /// No description provided for @managePlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get managePlansTitle;

  /// No description provided for @managePlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What readers pay to read this channel.'**
  String get managePlansSubtitle;

  /// No description provided for @managePlansNone.
  ///
  /// In en, this message translates to:
  /// **'This channel is free. Add a plan to charge for it.'**
  String get managePlansNone;

  /// No description provided for @managePlansAdd.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get managePlansAdd;

  /// No description provided for @managePlansPerPeriod.
  ///
  /// In en, this message translates to:
  /// **'per {days} days'**
  String managePlansPerPeriod(Object days);

  /// No description provided for @managePlansOutdated.
  ///
  /// In en, this message translates to:
  /// **'Outdated contract'**
  String get managePlansOutdated;

  /// No description provided for @managePlansOutdatedNote.
  ///
  /// In en, this message translates to:
  /// **'This server has moved to a new contract. Readers who already paid keep their access; new subscriptions should use the current one.'**
  String get managePlansOutdatedNote;

  /// No description provided for @managePlansMoveToCurrent.
  ///
  /// In en, this message translates to:
  /// **'Move to current contract'**
  String get managePlansMoveToCurrent;

  /// No description provided for @managePlansRetired.
  ///
  /// In en, this message translates to:
  /// **'Not for sale'**
  String get managePlansRetired;

  /// No description provided for @managePlansRetiredNote.
  ///
  /// In en, this message translates to:
  /// **'Kept so existing subscribers keep reading. Newer plans on this chain are sold instead.'**
  String get managePlansRetiredNote;

  /// No description provided for @managePlansRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get managePlansRemove;

  /// No description provided for @managePlansRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this plan from the channel? Anyone subscribed through it loses access.'**
  String get managePlansRemoveConfirm;

  /// No description provided for @managePlansChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get managePlansChain;

  /// No description provided for @managePlansPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get managePlansPrice;

  /// No description provided for @managePlansPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Days per period'**
  String get managePlansPeriodDays;

  /// No description provided for @managePlansPayout.
  ///
  /// In en, this message translates to:
  /// **'Paid out to'**
  String get managePlansPayout;

  /// No description provided for @managePlansPayoutHint.
  ///
  /// In en, this message translates to:
  /// **'Your account works — it resolves to your Safe.'**
  String get managePlansPayoutHint;

  /// No description provided for @managePlansPayoutUnreachable.
  ///
  /// In en, this message translates to:
  /// **'This address cannot receive payments on this chain.'**
  String get managePlansPayoutUnreachable;

  /// No description provided for @managePlansCreate.
  ///
  /// In en, this message translates to:
  /// **'Create plan'**
  String get managePlansCreate;

  /// No description provided for @managePlansCreating.
  ///
  /// In en, this message translates to:
  /// **'Registering on chain…'**
  String get managePlansCreating;

  /// No description provided for @managePlansAttaching.
  ///
  /// In en, this message translates to:
  /// **'Attaching to channel…'**
  String get managePlansAttaching;

  /// No description provided for @managePlansNoChains.
  ///
  /// In en, this message translates to:
  /// **'This server does not offer paid feeds.'**
  String get managePlansNoChains;

  /// No description provided for @managePlansUseExisting.
  ///
  /// In en, this message translates to:
  /// **'Use a plan I already have'**
  String get managePlansUseExisting;

  /// No description provided for @managePlansEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter a plan manually'**
  String get managePlansEnterManually;

  /// No description provided for @managePlansPlanId.
  ///
  /// In en, this message translates to:
  /// **'Plan ID'**
  String get managePlansPlanId;

  /// No description provided for @managePlansContractAddress.
  ///
  /// In en, this message translates to:
  /// **'Contract address'**
  String get managePlansContractAddress;

  /// No description provided for @managePlansLookup.
  ///
  /// In en, this message translates to:
  /// **'Look up'**
  String get managePlansLookup;

  /// No description provided for @managePlansNotFound.
  ///
  /// In en, this message translates to:
  /// **'No plan with that ID on that contract.'**
  String get managePlansNotFound;

  /// No description provided for @managePlansForeignOwner.
  ///
  /// In en, this message translates to:
  /// **'This plan belongs to another address. That is fine for a shared plan — payments go to its payout, not yours.'**
  String get managePlansForeignOwner;

  /// No description provided for @managePlansPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a price above zero.'**
  String get managePlansPriceRequired;

  /// No description provided for @managePlansSaved.
  ///
  /// In en, this message translates to:
  /// **'Plans updated'**
  String get managePlansSaved;

  /// No description provided for @managePlansManage.
  ///
  /// In en, this message translates to:
  /// **'Manage plans'**
  String get managePlansManage;

  /// No description provided for @managePlansPaidBadge.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get managePlansPaidBadge;

  /// No description provided for @managePlansFreeBadge.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get managePlansFreeBadge;

  /// No description provided for @createChannelPageSectionMonetization.
  ///
  /// In en, this message translates to:
  /// **'Monetization'**
  String get createChannelPageSectionMonetization;

  /// No description provided for @gateTierAnyoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get gateTierAnyoneLabel;

  /// No description provided for @gateTierAnyoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No sign-in. Works in any feed reader.'**
  String get gateTierAnyoneSubtitle;

  /// No description provided for @gateTierSignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get gateTierSignedLabel;

  /// No description provided for @gateTierSignedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in with a wallet, PublicOS account or not.'**
  String get gateTierSignedSubtitle;

  /// No description provided for @gateTierAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'PublicOS accounts'**
  String get gateTierAccountLabel;

  /// No description provided for @gateTierAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only people with a PublicOS account. Wallet-only visitors are turned away.'**
  String get gateTierAccountSubtitle;

  /// No description provided for @gateTierStandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Accounts in good standing'**
  String get gateTierStandingLabel;

  /// No description provided for @gateTierStandingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Citizens, and anyone whose domain is paid up.'**
  String get gateTierStandingSubtitle;

  /// No description provided for @gateTierCitizenLabel.
  ///
  /// In en, this message translates to:
  /// **'Citizens'**
  String get gateTierCitizenLabel;

  /// No description provided for @gateTierCitizenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only vouched citizens.'**
  String get gateTierCitizenSubtitle;

  /// No description provided for @createChannelPageSectionAudience.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN SEE IT'**
  String get createChannelPageSectionAudience;

  /// No description provided for @createChannelPageAudienceNote.
  ///
  /// In en, this message translates to:
  /// **'The minimum anyone needs to open this channel. Each option includes the ones above it.'**
  String get createChannelPageAudienceNote;

  /// No description provided for @createChannelPageSectionApprovedReaders.
  ///
  /// In en, this message translates to:
  /// **'APPROVED READERS'**
  String get createChannelPageSectionApprovedReaders;

  /// No description provided for @createChannelPageUseFriendsLabel.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get createChannelPageUseFriendsLabel;

  /// No description provided for @createChannelPageUseFriendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The list you keep once and reuse across every channel.'**
  String get createChannelPageUseFriendsSubtitle;

  /// No description provided for @createChannelPageUseChannelListLabel.
  ///
  /// In en, this message translates to:
  /// **'This channel\'s list'**
  String get createChannelPageUseChannelListLabel;

  /// No description provided for @createChannelPageUseChannelListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'People you approve for this channel only.'**
  String get createChannelPageUseChannelListSubtitle;

  /// No description provided for @createChannelPageAudienceOpenNote.
  ///
  /// In en, this message translates to:
  /// **'No list is on, so anyone who clears the setting above can read it.'**
  String get createChannelPageAudienceOpenNote;

  /// No description provided for @createChannelPageAudienceRestrictedNote.
  ///
  /// In en, this message translates to:
  /// **'A list is on, so this channel is private: it stops appearing in listings, and only people on an enabled list can read it. They still have to clear the setting above.'**
  String get createChannelPageAudienceRestrictedNote;

  /// No description provided for @createChannelPageSectionComments.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN COMMENT'**
  String get createChannelPageSectionComments;

  /// No description provided for @createChannelPageInteractionNote.
  ///
  /// In en, this message translates to:
  /// **'Commenting and reacting also require being able to read the channel.'**
  String get createChannelPageInteractionNote;

  /// No description provided for @createChannelPageSectionReactions.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN REACT'**
  String get createChannelPageSectionReactions;

  /// No description provided for @createChannelPageSectionWhoCanPost.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN PUBLISH'**
  String get createChannelPageSectionWhoCanPost;

  /// No description provided for @createChannelPagePostersMustBeLabel.
  ///
  /// In en, this message translates to:
  /// **'Posters must also be'**
  String get createChannelPagePostersMustBeLabel;

  /// No description provided for @chsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get chsAdd;

  /// No description provided for @chsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get chsRemove;

  /// No description provided for @chsTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get chsTitleLabel;

  /// No description provided for @chsDrawerRead.
  ///
  /// In en, this message translates to:
  /// **'Who can read it'**
  String get chsDrawerRead;

  /// No description provided for @chsDrawerPost.
  ///
  /// In en, this message translates to:
  /// **'Who can post'**
  String get chsDrawerPost;

  /// No description provided for @chsDrawerTalk.
  ///
  /// In en, this message translates to:
  /// **'Who can comment and react'**
  String get chsDrawerTalk;

  /// No description provided for @chsDrawerBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get chsDrawerBlocked;

  /// No description provided for @chsDrawerVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get chsDrawerVisibility;

  /// No description provided for @chsDrawerMonetization.
  ///
  /// In en, this message translates to:
  /// **'Monetization'**
  String get chsDrawerMonetization;

  /// No description provided for @chsReadNote.
  ///
  /// In en, this message translates to:
  /// **'The outer gate. Posting, commenting and reacting all require this first.'**
  String get chsReadNote;

  /// No description provided for @chsPostNote.
  ///
  /// In en, this message translates to:
  /// **'Writing a full post to the channel.'**
  String get chsPostNote;

  /// No description provided for @chsTalkNote.
  ///
  /// In en, this message translates to:
  /// **'Comments, reactions and votes. Everyone here must also be able to read it.'**
  String get chsTalkNote;

  /// No description provided for @chsBlockedNote.
  ///
  /// In en, this message translates to:
  /// **'Blocked people cannot read, post, comment or react here. A block beats everything else, including being on one of your lists — and unlike an approval, it never expires.'**
  String get chsBlockedNote;

  /// No description provided for @chsVisibilityNote.
  ///
  /// In en, this message translates to:
  /// **'How much of the channel gets served. Nothing is deleted — older posts stay on the server, they just stop being handed out in the feed.'**
  String get chsVisibilityNote;

  /// No description provided for @chsMonetizationNote.
  ///
  /// In en, this message translates to:
  /// **'Charging is a separate axis: a reader must clear the read gate and have paid. Money never buys past a block or an audience list.'**
  String get chsMonetizationNote;

  /// No description provided for @chsSubAudience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get chsSubAudience;

  /// No description provided for @chsSubFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter the audience by'**
  String get chsSubFilter;

  /// No description provided for @chsSubRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get chsSubRequests;

  /// No description provided for @chsSubReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get chsSubReactions;

  /// No description provided for @chsAudAnyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get chsAudAnyone;

  /// No description provided for @chsAudAnyoneSub.
  ///
  /// In en, this message translates to:
  /// **'No list. The channel is public.'**
  String get chsAudAnyoneSub;

  /// No description provided for @chsAudFriends.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get chsAudFriends;

  /// No description provided for @chsAudFriendsSub.
  ///
  /// In en, this message translates to:
  /// **'One list, reused by every channel.'**
  String get chsAudFriendsSub;

  /// No description provided for @chsAudPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get chsAudPrivate;

  /// No description provided for @chsAudPrivateSub.
  ///
  /// In en, this message translates to:
  /// **'A list just for this channel. People can ask to be let in.'**
  String get chsAudPrivateSub;

  /// No description provided for @chsFilterNone.
  ///
  /// In en, this message translates to:
  /// **'No filter'**
  String get chsFilterNone;

  /// No description provided for @chsFilterNoneSub.
  ///
  /// In en, this message translates to:
  /// **'Anyone at all, not even signed in.'**
  String get chsFilterNoneSub;

  /// No description provided for @chsFilterSigned.
  ///
  /// In en, this message translates to:
  /// **'Signed readers and wallets'**
  String get chsFilterSigned;

  /// No description provided for @chsFilterSignedSub.
  ///
  /// In en, this message translates to:
  /// **'Includes wallets you added by hand, with no PublicOS account.'**
  String get chsFilterSignedSub;

  /// No description provided for @chsFilterStanding.
  ///
  /// In en, this message translates to:
  /// **'All PublicOS Accounts'**
  String get chsFilterStanding;

  /// No description provided for @chsFilterStandingSub.
  ///
  /// In en, this message translates to:
  /// **'Citizens, and privates with an active domain.'**
  String get chsFilterStandingSub;

  /// No description provided for @chsFilterStandingDefaultSub.
  ///
  /// In en, this message translates to:
  /// **'Default.'**
  String get chsFilterStandingDefaultSub;

  /// No description provided for @chsFilterCitizen.
  ///
  /// In en, this message translates to:
  /// **'Citizens'**
  String get chsFilterCitizen;

  /// No description provided for @chsFilterCitizenSub.
  ///
  /// In en, this message translates to:
  /// **'Only vouched citizens.'**
  String get chsFilterCitizenSub;

  /// No description provided for @chsFilterNoteNone.
  ///
  /// In en, this message translates to:
  /// **'No filter is applied.'**
  String get chsFilterNoteNone;

  /// No description provided for @chsFilterNoteListed.
  ///
  /// In en, this message translates to:
  /// **'A list needs to know who you are, so the loosest filter here is Signed readers and wallets.'**
  String get chsFilterNoteListed;

  /// No description provided for @chsPostOwner.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get chsPostOwner;

  /// No description provided for @chsPostOwnerSub.
  ///
  /// In en, this message translates to:
  /// **'Nobody else can submit posts.'**
  String get chsPostOwnerSub;

  /// No description provided for @chsPostOpen.
  ///
  /// In en, this message translates to:
  /// **'Everyone who can read it'**
  String get chsPostOpen;

  /// No description provided for @chsPostOpenSub.
  ///
  /// In en, this message translates to:
  /// **'Open submissions.'**
  String get chsPostOpenSub;

  /// No description provided for @chsPostApproved.
  ///
  /// In en, this message translates to:
  /// **'Only people I approve'**
  String get chsPostApproved;

  /// No description provided for @chsPostApprovedSub.
  ///
  /// In en, this message translates to:
  /// **'A list just for posting.'**
  String get chsPostApprovedSub;

  /// No description provided for @chsSubLayout.
  ///
  /// In en, this message translates to:
  /// **'How it looks'**
  String get chsSubLayout;

  /// No description provided for @chsLayoutFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get chsLayoutFeed;

  /// No description provided for @chsLayoutFeedSub.
  ///
  /// In en, this message translates to:
  /// **'Newest first, no votes.'**
  String get chsLayoutFeedSub;

  /// No description provided for @chsLayoutForum.
  ///
  /// In en, this message translates to:
  /// **'Forum'**
  String get chsLayoutForum;

  /// No description provided for @chsLayoutForumSub.
  ///
  /// In en, this message translates to:
  /// **'Votes, and sorting by New, Top, Hot.'**
  String get chsLayoutForumSub;

  /// No description provided for @chsPostFilterGrp.
  ///
  /// In en, this message translates to:
  /// **'This filter binds accounts. A wallet you added to the posting list skips it — your hand is what vouches for a nameless key.'**
  String get chsPostFilterGrp;

  /// No description provided for @chsPostDailyLimit.
  ///
  /// In en, this message translates to:
  /// **'Daily limit per person'**
  String get chsPostDailyLimit;

  /// No description provided for @chsPostDailyLimitSub.
  ///
  /// In en, this message translates to:
  /// **'0 = no limit'**
  String get chsPostDailyLimitSub;

  /// No description provided for @chsTalkAll.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get chsTalkAll;

  /// No description provided for @chsTalkAllSub.
  ///
  /// In en, this message translates to:
  /// **'Everyone who can read the channel.'**
  String get chsTalkAllSub;

  /// No description provided for @chsTalkFriends.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get chsTalkFriends;

  /// No description provided for @chsTalkFriendsSub.
  ///
  /// In en, this message translates to:
  /// **'Just the switch — manage the list under Who can read it.'**
  String get chsTalkFriendsSub;

  /// No description provided for @chsTalkCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get chsTalkCustom;

  /// No description provided for @chsTalkCustomSub.
  ///
  /// In en, this message translates to:
  /// **'Your commenters list.'**
  String get chsTalkCustomSub;

  /// No description provided for @chsTalkFilterGrp.
  ///
  /// In en, this message translates to:
  /// **'This filter binds accounts. A wallet on one of your lists skips it — your hand is what vouches for a nameless key.'**
  String get chsTalkFilterGrp;

  /// No description provided for @chsTalkSplit.
  ///
  /// In en, this message translates to:
  /// **'Set reactions separately'**
  String get chsTalkSplit;

  /// No description provided for @chsTalkSplitSub.
  ///
  /// In en, this message translates to:
  /// **'Rarely needed — reactions follow comments by default.'**
  String get chsTalkSplitSub;

  /// No description provided for @chsTalkModeGated.
  ///
  /// In en, this message translates to:
  /// **'Your readers. Ticked people can comment.'**
  String get chsTalkModeGated;

  /// No description provided for @chsTalkModePublic.
  ///
  /// In en, this message translates to:
  /// **'Empty until you add someone. Search a name, or paste any wallet address.'**
  String get chsTalkModePublic;

  /// No description provided for @chsTalkSearchGated.
  ///
  /// In en, this message translates to:
  /// **'Search your readers…'**
  String get chsTalkSearchGated;

  /// No description provided for @chsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, or any 0x address…'**
  String get chsSearchHint;

  /// No description provided for @chsListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody yet'**
  String get chsListEmpty;

  /// No description provided for @chsBlockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody is blocked'**
  String get chsBlockedEmpty;

  /// No description provided for @chsVisShowNewest.
  ///
  /// In en, this message translates to:
  /// **'Show the newest'**
  String get chsVisShowNewest;

  /// No description provided for @chsVisHideOlder.
  ///
  /// In en, this message translates to:
  /// **'Hide posts older than'**
  String get chsVisHideOlder;

  /// No description provided for @chsVisPosts.
  ///
  /// In en, this message translates to:
  /// **'{count} posts'**
  String chsVisPosts(int count);

  /// No description provided for @chsVisDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String chsVisDays(int count);

  /// No description provided for @chsVisAll.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get chsVisAll;

  /// No description provided for @chsVisOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get chsVisOff;

  /// No description provided for @chsVisNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest {count}'**
  String chsVisNewest(int count);

  /// No description provided for @chsVisVerdict.
  ///
  /// In en, this message translates to:
  /// **'This channel has {total} posts. The newest {shown} are served; the other {rest} stay stored and are simply not handed out.'**
  String chsVisVerdict(int total, int shown, int rest);

  /// No description provided for @chsMonPlans.
  ///
  /// In en, this message translates to:
  /// **'Payment plans'**
  String get chsMonPlans;

  /// No description provided for @chsMonPlansNone.
  ///
  /// In en, this message translates to:
  /// **'None yet — free to read'**
  String get chsMonPlansNone;

  /// No description provided for @chsMonPlansCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 plan} other{{count} plans}}'**
  String chsMonPlansCount(int count);

  /// No description provided for @chsMonVerdictFree.
  ///
  /// In en, this message translates to:
  /// **'Free to read. There is nothing to switch on here — a channel is paid because plans exist, not because of a toggle.'**
  String get chsMonVerdictFree;

  /// No description provided for @chsMonVerdictPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid. A reader must clear the read gate and have paid one of the plans.'**
  String get chsMonVerdictPaid;

  /// No description provided for @chsH1Anyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get chsH1Anyone;

  /// No description provided for @chsH1Signed.
  ///
  /// In en, this message translates to:
  /// **'Anyone signed in'**
  String get chsH1Signed;

  /// No description provided for @chsH1Standing.
  ///
  /// In en, this message translates to:
  /// **'All PublicOS accounts'**
  String get chsH1Standing;

  /// No description provided for @chsH1Citizen.
  ///
  /// In en, this message translates to:
  /// **'Only citizens'**
  String get chsH1Citizen;

  /// No description provided for @chsH1ListedSignedBoth.
  ///
  /// In en, this message translates to:
  /// **'Friends + approved'**
  String get chsH1ListedSignedBoth;

  /// No description provided for @chsH1ListedSignedFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get chsH1ListedSignedFriends;

  /// No description provided for @chsH1ListedSignedOwn.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get chsH1ListedSignedOwn;

  /// No description provided for @chsH1ListedCitizenBoth.
  ///
  /// In en, this message translates to:
  /// **'Citizens on your lists, and approved wallets'**
  String get chsH1ListedCitizenBoth;

  /// No description provided for @chsH1ListedCitizenFriends.
  ///
  /// In en, this message translates to:
  /// **'Only citizen friends and approved wallets'**
  String get chsH1ListedCitizenFriends;

  /// No description provided for @chsH1ListedCitizenOwn.
  ///
  /// In en, this message translates to:
  /// **'Only approved citizens and wallets'**
  String get chsH1ListedCitizenOwn;

  /// No description provided for @chsH1ListedStandingBoth.
  ///
  /// In en, this message translates to:
  /// **'PublicOS accounts on your lists, and approved wallets'**
  String get chsH1ListedStandingBoth;

  /// No description provided for @chsH1ListedStandingFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends with PublicOS accounts, and approved wallets'**
  String get chsH1ListedStandingFriends;

  /// No description provided for @chsH1ListedStandingOwn.
  ///
  /// In en, this message translates to:
  /// **'Approved PublicOS accounts and wallets'**
  String get chsH1ListedStandingOwn;

  /// No description provided for @chsH2Owner.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get chsH2Owner;

  /// No description provided for @chsH2OpenCitizen.
  ///
  /// In en, this message translates to:
  /// **'Only citizen readers'**
  String get chsH2OpenCitizen;

  /// No description provided for @chsH2OpenStanding.
  ///
  /// In en, this message translates to:
  /// **'Readers with PublicOS accounts'**
  String get chsH2OpenStanding;

  /// No description provided for @chsH2ApprovedCitizen.
  ///
  /// In en, this message translates to:
  /// **'Only approved citizens and wallets'**
  String get chsH2ApprovedCitizen;

  /// No description provided for @chsH2ApprovedStanding.
  ///
  /// In en, this message translates to:
  /// **'Approved PublicOS accounts and wallets'**
  String get chsH2ApprovedStanding;

  /// No description provided for @chsH3CustomCitizen.
  ///
  /// In en, this message translates to:
  /// **'Custom list of citizens and wallets'**
  String get chsH3CustomCitizen;

  /// No description provided for @chsH3CustomStanding.
  ///
  /// In en, this message translates to:
  /// **'Custom list of PublicOS accounts and wallets'**
  String get chsH3CustomStanding;

  /// No description provided for @chsH3FriendsCitizen.
  ///
  /// In en, this message translates to:
  /// **'Only citizen friends and wallets'**
  String get chsH3FriendsCitizen;

  /// No description provided for @chsH3FriendsStanding.
  ///
  /// In en, this message translates to:
  /// **'Friends with PublicOS accounts and wallets'**
  String get chsH3FriendsStanding;

  /// No description provided for @chsH3ReactionsDiffer.
  ///
  /// In en, this message translates to:
  /// **'reactions differ'**
  String get chsH3ReactionsDiffer;

  /// No description provided for @chsH4Nobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get chsH4Nobody;

  /// No description provided for @chsH4Count.
  ///
  /// In en, this message translates to:
  /// **'{count} blocked'**
  String chsH4Count(int count);

  /// No description provided for @chsH6Free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get chsH6Free;

  /// No description provided for @chsH6Paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get chsH6Paid;

  /// No description provided for @chsFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get chsFieldName;

  /// No description provided for @chsFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get chsFieldDescription;

  /// No description provided for @chsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a description…'**
  String get chsDescriptionHint;

  /// No description provided for @chsFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get chsFieldAddress;

  /// No description provided for @chsFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get chsFieldLanguage;

  /// No description provided for @chsFieldSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret'**
  String get chsFieldSecret;

  /// No description provided for @chsFieldServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get chsFieldServer;

  /// No description provided for @chsServerLocked.
  ///
  /// In en, this message translates to:
  /// **'· locked after creation'**
  String get chsServerLocked;

  /// No description provided for @chsIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Icon URL'**
  String get chsIconTitle;

  /// No description provided for @chsAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Channel address'**
  String get chsAddressTitle;

  /// No description provided for @chsFailAdd.
  ///
  /// In en, this message translates to:
  /// **'Could not add to the list'**
  String get chsFailAdd;

  /// No description provided for @chsFailRemove.
  ///
  /// In en, this message translates to:
  /// **'Could not remove from the list'**
  String get chsFailRemove;

  /// No description provided for @chsReqPasses.
  ///
  /// In en, this message translates to:
  /// **'passes'**
  String get chsReqPasses;

  /// No description provided for @chsReqBlocked.
  ///
  /// In en, this message translates to:
  /// **'blocked by filter'**
  String get chsReqBlocked;

  /// No description provided for @chsReqUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get chsReqUnknown;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'A **BSP** connects you to the network. An **SSP** holds your posts and the feeds you read. As a citizen the network covers both for you.'**
  String get onbProvBodyCitizen;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'A **BSP** connects you to the network. An **SSP** holds your posts and the feeds you read. You pay for these as you use them, from a service balance you top up.'**
  String get onbProvBodyPrivate;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'A **BSP** connects you to the network. An **SSP** holds your posts and the feeds you read.'**
  String get onbProvBodyUnknown;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'BSP · network access'**
  String get onbProvBspTitle;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SSP · your feeds'**
  String get onbProvSspTitle;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SET THIS UP FOR ME'**
  String get onbProvAuto;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SET UP MY BSP'**
  String get onbProvAutoBsp;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SET UP MY SSP'**
  String get onbProvAutoSsp;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE BSP'**
  String get onbProvChooseBsp;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE SSP'**
  String get onbProvChooseSsp;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SETTING THIS UP…'**
  String get onbProvWorking;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SET THESE UP FIRST'**
  String get onbProvSetUpFirst;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'not connected'**
  String get onbProvNone;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'could not check right now'**
  String get onbProvUnknownRow;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'covered while you use it'**
  String get onbProvRenewsItself;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'NONE'**
  String get onbProvStateNone;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'PAIRED'**
  String get onbProvStatePaired;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get onbProvStateFailed;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'…'**
  String get onbProvStateWorking;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'What this cost you'**
  String get onbProvCostLabel;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'The network pays your providers for you. **Nothing left your wallet**, and both stay covered while you use the app.'**
  String get onbProvFreeWhy;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Both draw on one **service balance**, by the second, only while a provider has enough subscribers to be paid. Top it up in **Services** before it runs out, and take back what is left whenever you like. **Nothing refills it on its own.**'**
  String get onbProvPaidWhy;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do here'**
  String get onbProvAlreadyLabel;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'You already have both. Changing provider lives in **Services**, switch any time; the old one is paid to the second.'**
  String get onbProvAlreadyWhy;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Why the one-tap option is hidden'**
  String get onbProvUnknownLabel;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Setting this up for you needs to know whether you are a citizen, the two paths are different, so **it does not guess**. Choosing yourself still works.'**
  String get onbProvUnknownWhy;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Why it stopped'**
  String get onbProvFailLabel;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'You can set these up any time in **Services**'**
  String get onbProvTreasuryHint;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'About to deposit'**
  String get onbProvDepositLabel;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'DEPOSIT'**
  String get onbProvDepositGo;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get onbProvSkip;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Skip for now?'**
  String get onbProvSkipTitle;

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'covered to {date}'**
  String onbProvPaidTo(String date);

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'{provider} · ran out'**
  String onbProvLapsed(String provider);

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'We could not set up your {service}. It may have been the connection, nothing was charged.'**
  String onbProvFailGeneric(String service);

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'We could not find a provider for your {service} right now.'**
  String onbProvFailNoProvider(String service);

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'You are missing **{missing}**. Without them you will not get the full experience, you can set both up later in Services.'**
  String onbProvSkipBody(String missing);

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'Moved from your **MainSafe** into your service balance now, one month at today\'s fee, yours to withdraw while unspent. Your balance is {balance}.'**
  String onbProvDepositWhy(String balance);

  /// S6 providers fork.
  ///
  /// In en, this message translates to:
  /// **'We could not set up your {service}. It costs {cost} a month and your MainSafe does not have it.'**
  String onbProvFailFunds(String service, String cost);

  /// Shown in the publish-this-inbox dialog while the chain write is in flight.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get keychainOfferRegPublishing;

  /// publicos_desktop status-bar XMTP chip: no messaging key signed in.
  ///
  /// In en, this message translates to:
  /// **'no key'**
  String get statusBarNoKey;

  /// publicos_desktop status-bar XMTP chip: key loaded but its inbox is not on the on-chain directory.
  ///
  /// In en, this message translates to:
  /// **'unregistered'**
  String get statusBarInboxUnregistered;

  /// publicos_desktop status-bar XMTP chip tooltip.
  ///
  /// In en, this message translates to:
  /// **'Registered as {name}'**
  String statusBarInboxRegisteredAs(String name);

  /// publicos_desktop Settings › Appearance toggle title.
  ///
  /// In en, this message translates to:
  /// **'Status bar at top'**
  String get desktopStatusBarTopTitle;

  /// publicos_desktop Settings › Appearance toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Dock the shell status bar above the panels'**
  String get desktopStatusBarTopSubtitle;

  /// publicos_desktop Settings › Appearance toggle title.
  ///
  /// In en, this message translates to:
  /// **'Autoplay interactive cards'**
  String get desktopAutoplayCardsTitle;

  /// publicos_desktop Settings › Appearance toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Cards start running instead of waiting for a tap. Uses more memory.'**
  String get desktopAutoplayCardsSubtitle;

  /// publicos_desktop Settings › Appearance section title.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get desktopSettingsAppearanceTitle;

  /// publicos_desktop Settings footer button.
  ///
  /// In en, this message translates to:
  /// **'LOG OUT'**
  String get desktopLogOut;

  /// publicos_desktop push toggle subtitle — notes that delivery is mobile-only.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts when the app is closed (mobile)'**
  String get desktopPushSubtitle;

  /// publicos_desktop Settings section header for the demo-data helpers.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get desktopDemoDataTitle;

  /// publicos_desktop Contacts pane footer row (opens the browser settings dialog: content widths).
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get desktopContactSettings;

  /// publicos_desktop Contacts pane chip that opens the grid settings sheet.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get desktopLayoutChip;

  /// publicos_desktop Contacts pane search field hint. Deliberately shorter than the client's contactsViewSearchHint ('Search name, address, or inbox'), which stays on Messages only.
  ///
  /// In en, this message translates to:
  /// **'Search PublicOS'**
  String get desktopContactsSearchHint;

  /// publicos_desktop Orgs pane empty-state title.
  ///
  /// In en, this message translates to:
  /// **'No orgs yet'**
  String get desktopNoOrgsYet;

  /// publicos_desktop Orgs pane empty-state body.
  ///
  /// In en, this message translates to:
  /// **'Organizations you interact with appear here.'**
  String get desktopOrgsEmptyHint;

  /// publicos_desktop Contacts detail pane placeholder title.
  ///
  /// In en, this message translates to:
  /// **'Select a contact'**
  String get desktopSelectContactTitle;

  /// publicos_desktop Contacts detail pane placeholder body.
  ///
  /// In en, this message translates to:
  /// **'Pick someone on the left to see their profile.'**
  String get desktopSelectContactHint;

  /// publicos_desktop login boot: initBSP failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to chain'**
  String get desktopBootChainFailed;

  /// publicos_desktop account picker: mnemonic copied snackbar.
  ///
  /// In en, this message translates to:
  /// **'Recovery phrase copied'**
  String get desktopRecoveryPhraseCopied;

  /// publicos_desktop account picker: reload tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get desktopReload;

  /// publicos_desktop keychain: a site grant was revoked.
  ///
  /// In en, this message translates to:
  /// **'Disconnected {origin}'**
  String desktopGrantRevoked(String origin);

  /// publicos_desktop keychain session-key tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account session key'**
  String get desktopSessionKeySubtitle;

  /// publicos_desktop keychain session-key export warning.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this key controls your account session. Never share it.'**
  String get desktopSessionKeyWarning;

  /// publicos_desktop shell placeholder pane blurb for My Account (rail index 0).
  ///
  /// In en, this message translates to:
  /// **'Your profile, identity records, domains, keychain and recovery.'**
  String get desktopNavBlurbMyAccount;

  /// publicos_desktop shell placeholder blurb — Contacts.
  ///
  /// In en, this message translates to:
  /// **'The people you know, the trust tree, and per-contact settings.'**
  String get desktopNavBlurbContacts;

  /// publicos_desktop shell placeholder blurb — Messages.
  ///
  /// In en, this message translates to:
  /// **'Encrypted XMTP conversations, groups, and message tools.'**
  String get desktopNavBlurbMessages;

  /// publicos_desktop shell placeholder blurb — Feeds.
  ///
  /// In en, this message translates to:
  /// **'Communities, forums, and the posts you follow.'**
  String get desktopNavBlurbFeeds;

  /// publicos_desktop shell placeholder blurb — Wallets.
  ///
  /// In en, this message translates to:
  /// **'Balances and token transfers.'**
  String get desktopNavBlurbWallets;

  /// publicos_desktop shell placeholder blurb — Treasury.
  ///
  /// In en, this message translates to:
  /// **'Your economy share, subscriptions, and the network\'s nodes.'**
  String get desktopNavBlurbTreasury;

  /// publicos_desktop shell placeholder blurb — BSP.
  ///
  /// In en, this message translates to:
  /// **'Blockchain Service Providers — directory and management.'**
  String get desktopNavBlurbBsp;

  /// publicos_desktop shell placeholder blurb — SSP.
  ///
  /// In en, this message translates to:
  /// **'Storage Service Providers — subscriptions and your server.'**
  String get desktopNavBlurbSsp;

  /// publicos_desktop shell placeholder blurb — Nodes.
  ///
  /// In en, this message translates to:
  /// **'Consensus nodes and validator registration.'**
  String get desktopNavBlurbNodes;

  /// publicos_desktop shell placeholder blurb — Settings.
  ///
  /// In en, this message translates to:
  /// **'App preferences, notifications, and account session.'**
  String get desktopNavBlurbSettings;

  /// publicos_desktop shell placeholder blurb — Orgs.
  ///
  /// In en, this message translates to:
  /// **'Organizations — profiles, membership, and governance.'**
  String get desktopNavBlurbOrgs;

  /// publicos_desktop shell placeholder blurb — Social Graph.
  ///
  /// In en, this message translates to:
  /// **'The vouch graph — who vouched for whom, citizenship at a glance.'**
  String get desktopNavBlurbSocialGraph;

  /// publicos_desktop shell placeholder blurb — Account.
  ///
  /// In en, this message translates to:
  /// **'Identity, vouch status, domain, sessions, and recovery contacts.'**
  String get desktopNavBlurbAccount;

  /// publicos_desktop rail: right-click menu on a recent app.
  ///
  /// In en, this message translates to:
  /// **'Remove from history'**
  String get desktopRemoveFromHistory;

  /// publicos_desktop browser deck button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Reload profile'**
  String get desktopReloadProfile;

  /// publicos_desktop browser deck: edit-mode toggle tooltip (on).
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get desktopDoneEditing;

  /// publicos_desktop browser deck: edit-mode toggle tooltip (off).
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get desktopEditProfile;

  /// publicos_desktop browser deck button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Page background'**
  String get desktopPageBackground;

  /// publicos_desktop browser deck button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile QR'**
  String get desktopProfileQr;

  /// publicos_desktop browser deck button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy profile link'**
  String get desktopCopyProfileLink;

  /// publicos_desktop browser deck: channel follow button tooltip (following).
  ///
  /// In en, this message translates to:
  /// **'Followed — manage lists'**
  String get desktopFollowedManageLists;

  /// publicos_desktop browser deck: channel follow button tooltip (not following).
  ///
  /// In en, this message translates to:
  /// **'Follow — add to a list'**
  String get desktopFollowAddToList;

  /// publicos_desktop browser deck: app bookmark button tooltip (bookmarked).
  ///
  /// In en, this message translates to:
  /// **'Bookmarked — remove'**
  String get desktopBookmarkedRemove;

  /// publicos_desktop browser deck: app bookmark button tooltip (not bookmarked).
  ///
  /// In en, this message translates to:
  /// **'Bookmark this app'**
  String get desktopBookmarkThisApp;

  /// publicos_desktop browser tab tooltip for a chat tab.
  ///
  /// In en, this message translates to:
  /// **'{label} — chat'**
  String desktopTabTooltipChat(String label);

  /// publicos_desktop browser tab tooltip for a channel tab.
  ///
  /// In en, this message translates to:
  /// **'{label} — channel'**
  String desktopTabTooltipChannel(String label);

  /// publicos_desktop browser tab tooltip: web tab with nothing renderable in-app.
  ///
  /// In en, this message translates to:
  /// **'{label} — opens in your browser'**
  String desktopTabTooltipOpensExternal(String label);

  /// publicos_desktop browser tab tooltip: app tab with one external link.
  ///
  /// In en, this message translates to:
  /// **'{label} — {url} (opens in your browser)'**
  String desktopTabTooltipOpensExternalUrl(String label, String url);

  /// publicos_desktop browser tab tooltip: app tab with several external links.
  ///
  /// In en, this message translates to:
  /// **'{label} — {count} links (open in your browser)'**
  String desktopTabTooltipOpensExternalLinks(String label, int count);

  /// publicos_desktop browser profile banner pencil tooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit banner'**
  String get desktopEditBanner;

  /// publicos_desktop browser profile avatar pencil tooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit avatar'**
  String get desktopEditAvatar;

  /// publicos_desktop browser tab strip overflow button tooltip.
  ///
  /// In en, this message translates to:
  /// **'More tabs'**
  String get desktopMoreTabs;

  /// publicos_desktop Messages pane: chat settings entry label.
  ///
  /// In en, this message translates to:
  /// **'Chat settings'**
  String get desktopChatSettings;

  /// publicos_desktop chat appearance dialog header (upper-case).
  ///
  /// In en, this message translates to:
  /// **'CHAT SETTINGS'**
  String get desktopChatSettingsHeader;

  /// publicos_desktop chat appearance dialog section label (upper-case).
  ///
  /// In en, this message translates to:
  /// **'BUBBLE COLOR'**
  String get desktopBubbleColorSection;

  /// publicos_desktop chat settings dialog: small note under the BUBBLE COLOR label explaining the Identity default chip.
  ///
  /// In en, this message translates to:
  /// **'\"Identity\" uses each account\'s Color record, the same color as its domain address bar. Set yours in the Account app, or override it here.'**
  String get desktopBubbleColorIdentityNote;

  /// publicos_desktop chat appearance: default text color option.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get desktopAutoLabel;

  /// publicos_desktop chat appearance preview bubble (peer side).
  ///
  /// In en, this message translates to:
  /// **'This is how their messages look'**
  String get desktopPreviewTheirMessages;

  /// publicos_desktop chat appearance preview bubble (own side).
  ///
  /// In en, this message translates to:
  /// **'And this is how yours look'**
  String get desktopPreviewYourMessages;

  /// publicos_desktop chat appearance dialog footnote.
  ///
  /// In en, this message translates to:
  /// **'These changes are for you only — nobody else sees them.'**
  String get desktopChatAppearanceLocalNote;

  /// publicos_desktop chat settings: chime toggle title.
  ///
  /// In en, this message translates to:
  /// **'Message chime'**
  String get desktopMessageChimeTitle;

  /// publicos_desktop chat settings: chime toggle subtitle.
  ///
  /// In en, this message translates to:
  /// **'Bell on every incoming message'**
  String get desktopMessageChimeSubtitle;

  /// publicos_desktop chat appearance: side selector chip (own).
  ///
  /// In en, this message translates to:
  /// **'My messages'**
  String get desktopChipMyMessages;

  /// publicos_desktop chat appearance: side selector chip (peer).
  ///
  /// In en, this message translates to:
  /// **'Their messages'**
  String get desktopChipTheirMessages;

  /// publicos_desktop chat appearance dialog section label (upper-case).
  ///
  /// In en, this message translates to:
  /// **'FONT'**
  String get desktopFontSection;

  /// publicos_desktop chat appearance dialog section label (upper-case).
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get desktopWeightSection;

  /// publicos_desktop chat appearance: font weight option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get desktopFontWeightLight;

  /// publicos_desktop chat appearance: font weight option.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get desktopFontWeightNormal;

  /// publicos_desktop chat appearance: font weight option.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get desktopFontWeightMedium;

  /// publicos_desktop chat appearance: font weight option.
  ///
  /// In en, this message translates to:
  /// **'SemiBold'**
  String get desktopFontWeightSemiBold;

  /// publicos_desktop chat appearance: font weight option.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get desktopFontWeightBold;

  /// publicos_desktop status bar: identity chip tooltip.
  ///
  /// In en, this message translates to:
  /// **'Keychain — signing keys'**
  String get desktopStatusBarKeychainTooltip;

  /// publicos_desktop status bar: notifications chip tooltip with unread count.
  ///
  /// In en, this message translates to:
  /// **'{count} unread on-chain notifications'**
  String desktopStatusBarUnreadChain(int count);

  /// publicos_desktop status bar: notifications chip tooltip (none unread).
  ///
  /// In en, this message translates to:
  /// **'On-chain notifications'**
  String get desktopStatusBarChainNotifications;

  /// publicos_desktop status bar: BSP chip name when on the public fallback.
  ///
  /// In en, this message translates to:
  /// **'Public node'**
  String get desktopStatusBarPublicNode;

  /// publicos_desktop status bar: SSP chip name when on the public fallback.
  ///
  /// In en, this message translates to:
  /// **'Public server'**
  String get desktopStatusBarPublicServer;

  /// publicos_desktop status bar: SSP chip tooltip prefix.
  ///
  /// In en, this message translates to:
  /// **'Feed server'**
  String get desktopStatusBarFeedServer;

  /// publicos_desktop profile pane: follow button tooltip (following).
  ///
  /// In en, this message translates to:
  /// **'Manage which lists'**
  String get desktopFollowTooltipManageLists;

  /// publicos_desktop profile pane: follow button tooltip (not following).
  ///
  /// In en, this message translates to:
  /// **'Follow this account'**
  String get desktopFollowTooltipFollow;

  /// publicos_desktop profile pane: follow snackbar on error.
  ///
  /// In en, this message translates to:
  /// **'Follow failed: {error}'**
  String desktopFollowFailed(Object error);

  /// publicos_desktop Messages pane empty-state title.
  ///
  /// In en, this message translates to:
  /// **'Select a conversation'**
  String get desktopSelectConversationTitle;

  /// publicos_desktop Messages pane empty-state body.
  ///
  /// In en, this message translates to:
  /// **'Pick a chat on the left — or start one from a profile.'**
  String get desktopSelectConversationHint;

  /// publicos_desktop contact settings dialog header (upper-case).
  ///
  /// In en, this message translates to:
  /// **'CONTACT SETTINGS'**
  String get desktopContactSettingsHeader;

  /// publicos_desktop contact settings dialog section label (upper-case).
  ///
  /// In en, this message translates to:
  /// **'CONTENT WIDTH'**
  String get desktopContentWidthSection;

  /// publicos_desktop browser settings dialog: content width hint.
  ///
  /// In en, this message translates to:
  /// **'Caps how wide each kind of tab spreads on a large window. Web tabs always fill.'**
  String get desktopContentWidthHint;

  /// publicos_desktop browser settings dialog header (upper-case).
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get desktopBrowserSettingsHeader;

  /// publicos_desktop browser settings dialog: width group covering the profile, management and settings tabs.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get desktopContentWidthProfile;

  /// publicos_desktop browser settings dialog: width group covering chat tabs.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get desktopContentWidthChat;

  /// publicos_desktop browser settings dialog: width group covering feed tabs.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get desktopContentWidthFeeds;

  /// publicos_desktop browser settings dialog: note that the feed width is the same setting as the Feeds destination reading width.
  ///
  /// In en, this message translates to:
  /// **'Shared with the Feeds page.'**
  String get desktopContentWidthFeedsHint;

  /// publicos_desktop Social Graph pane fallback when no session address.
  ///
  /// In en, this message translates to:
  /// **'No account loaded'**
  String get desktopNoAccountLoaded;

  /// publicos_desktop browser: app-links table label (web pointer).
  ///
  /// In en, this message translates to:
  /// **'Web app'**
  String get desktopAppLinkWebApp;

  /// publicos_desktop browser: app-links table label (iOS store pointer).
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get desktopAppLinkAppStore;

  /// publicos_desktop browser: app-links table label (Android store pointer).
  ///
  /// In en, this message translates to:
  /// **'Play Store'**
  String get desktopAppLinkPlayStore;

  /// No description provided for @paywallLockedWidgetBadge.
  ///
  /// In en, this message translates to:
  /// **'PAID CHANNEL'**
  String get paywallLockedWidgetBadge;

  /// No description provided for @paywallLockedWidgetBlurbSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Reading this channel takes a subscription. You pay from your account, and every device you sign in with can read it.'**
  String get paywallLockedWidgetBlurbSubscribe;

  /// No description provided for @paywallLockedWidgetBlurbRenew.
  ///
  /// In en, this message translates to:
  /// **'Your subscription ended on {date}. Renew to keep reading.'**
  String paywallLockedWidgetBlurbRenew(String date);

  /// No description provided for @paywallLockedWidgetBlurbConfirming.
  ///
  /// In en, this message translates to:
  /// **'Your payment is on its way. The channel unlocks as soon as it\'s confirmed — usually a few seconds.'**
  String get paywallLockedWidgetBlurbConfirming;

  /// No description provided for @paywallLockedWidgetNoPlan.
  ///
  /// In en, this message translates to:
  /// **'This channel\'s plan isn\'t available right now.'**
  String get paywallLockedWidgetNoPlan;

  /// No description provided for @paywallLockedWidgetSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get paywallLockedWidgetSubscribe;

  /// No description provided for @paywallLockedWidgetRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get paywallLockedWidgetRenew;

  /// No description provided for @paywallLockedWidgetRetry.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get paywallLockedWidgetRetry;

  /// No description provided for @tierLockedWidgetVerifiedOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'CITIZENS ONLY'**
  String get tierLockedWidgetVerifiedOnlyBadge;

  /// No description provided for @tierLockedWidgetVerifiedOnlyBlurb.
  ///
  /// In en, this message translates to:
  /// **'The owner limited this channel to verified citizens. Get vouched in to read it.'**
  String get tierLockedWidgetVerifiedOnlyBlurb;

  /// No description provided for @tierLockedWidgetAccountOnlyBadge.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNTS ONLY'**
  String get tierLockedWidgetAccountOnlyBadge;

  /// No description provided for @tierLockedWidgetAccountOnlyBlurb.
  ///
  /// In en, this message translates to:
  /// **'This channel is for PublicOS accounts. Sign in with your account key to read it.'**
  String get tierLockedWidgetAccountOnlyBlurb;

  /// No description provided for @tierLockedWidgetStandingBadge.
  ///
  /// In en, this message translates to:
  /// **'STANDING REQUIRED'**
  String get tierLockedWidgetStandingBadge;

  /// No description provided for @tierLockedWidgetStandingBlurb.
  ///
  /// In en, this message translates to:
  /// **'This channel is for citizens and accounts with a paid-up domain.'**
  String get tierLockedWidgetStandingBlurb;

  /// No description provided for @tierLockedWidgetRetry.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get tierLockedWidgetRetry;

  /// No description provided for @subscribeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeSheetTitle;

  /// No description provided for @subscribeSheetTitleRenew.
  ///
  /// In en, this message translates to:
  /// **'Renew subscription'**
  String get subscribeSheetTitleRenew;

  /// No description provided for @subscribeSheetPayingFrom.
  ///
  /// In en, this message translates to:
  /// **'PAYING FROM'**
  String get subscribeSheetPayingFrom;

  /// No description provided for @subscribeSheetMainSafe.
  ///
  /// In en, this message translates to:
  /// **'Main wallet'**
  String get subscribeSheetMainSafe;

  /// No description provided for @subscribeSheetNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get subscribeSheetNetwork;

  /// No description provided for @subscribeSheetPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get subscribeSheetPrice;

  /// No description provided for @subscribeSheetPeriods.
  ///
  /// In en, this message translates to:
  /// **'PERIODS'**
  String get subscribeSheetPeriods;

  /// No description provided for @subscribeSheetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get subscribeSheetTotal;

  /// No description provided for @subscribeSheetAccessUntil.
  ///
  /// In en, this message translates to:
  /// **'Access until'**
  String get subscribeSheetAccessUntil;

  /// No description provided for @subscribeSheetLapsedOn.
  ///
  /// In en, this message translates to:
  /// **'Lapsed on'**
  String get subscribeSheetLapsedOn;

  /// No description provided for @subscribeSheetPeriodDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String subscribeSheetPeriodDays(int days);

  /// No description provided for @subscribeSheetPeriodHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String subscribeSheetPeriodHours(int hours);

  /// No description provided for @subscribeSheetApproveNote.
  ///
  /// In en, this message translates to:
  /// **'This takes two transactions from your wallet: first you approve the exact amount, then it\'s sent. One tap does both.'**
  String get subscribeSheetApproveNote;

  /// No description provided for @subscribeSheetConfirmApproveAndSend.
  ///
  /// In en, this message translates to:
  /// **'Approve and send {amount}'**
  String subscribeSheetConfirmApproveAndSend(String amount);

  /// No description provided for @subscribeSheetConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Send {amount}'**
  String subscribeSheetConfirmSend(String amount);

  /// No description provided for @subscribeSheetStepApproving.
  ///
  /// In en, this message translates to:
  /// **'Approving… ({n} of {total})'**
  String subscribeSheetStepApproving(int n, int total);

  /// No description provided for @subscribeSheetStepSending.
  ///
  /// In en, this message translates to:
  /// **'Sending… ({n} of {total})'**
  String subscribeSheetStepSending(int n, int total);

  /// No description provided for @subscribeSheetNoSource.
  ///
  /// In en, this message translates to:
  /// **'None of your wallets can pay on {chain}.'**
  String subscribeSheetNoSource(String chain);

  /// No description provided for @subscribeSheetInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough {symbol} in this wallet.'**
  String subscribeSheetInsufficient(String symbol);

  /// No description provided for @subscribeSheetQuoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t fetch the plan\'s terms. Pull to retry.'**
  String get subscribeSheetQuoteFailed;

  /// No description provided for @subscribeSheetDone.
  ///
  /// In en, this message translates to:
  /// **'Subscribed — access until {date}'**
  String subscribeSheetDone(String date);

  /// No description provided for @subscribeSheetFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get subscribeSheetFailed;

  /// No description provided for @createRecordPageLabelWhenTapped.
  ///
  /// In en, this message translates to:
  /// **'WHEN TAPPED'**
  String get createRecordPageLabelWhenTapped;

  /// No description provided for @createRecordPageTapNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get createRecordPageTapNothing;

  /// No description provided for @createRecordPageTapLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get createRecordPageTapLink;

  /// No description provided for @createRecordPageTapTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get createRecordPageTapTip;

  /// No description provided for @createRecordPageLabelTipPayTo.
  ///
  /// In en, this message translates to:
  /// **'PAY TO'**
  String get createRecordPageLabelTipPayTo;

  /// No description provided for @createRecordPageTipAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste an address (0x…)'**
  String get createRecordPageTipAddressHint;

  /// No description provided for @createRecordPageTipInvalidAddress.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a valid address'**
  String get createRecordPageTipInvalidAddress;

  /// No description provided for @createRecordPageLabelTipNetwork.
  ///
  /// In en, this message translates to:
  /// **'NETWORK AND TOKEN'**
  String get createRecordPageLabelTipNetwork;

  /// No description provided for @createRecordPageTipChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the address…'**
  String get createRecordPageTipChecking;

  /// No description provided for @createRecordPageTipCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check this address. Try again.'**
  String get createRecordPageTipCheckFailed;

  /// No description provided for @createRecordPageTipNoAmount.
  ///
  /// In en, this message translates to:
  /// **'Visitors choose the amount. The card never suggests one.'**
  String get createRecordPageTipNoAmount;

  /// No description provided for @tipCardSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a tip'**
  String get tipCardSheetTitle;

  /// No description provided for @tipCardOwnerMainSafe.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Main Safe'**
  String tipCardOwnerMainSafe(String name);

  /// No description provided for @tipCardOwnerWallet.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s wallet'**
  String tipCardOwnerWallet(String name);

  /// No description provided for @tipCardOwnerUnknown.
  ///
  /// In en, this message translates to:
  /// **'An address set by {name}'**
  String tipCardOwnerUnknown(String name);

  /// No description provided for @tipCardBroken.
  ///
  /// In en, this message translates to:
  /// **'This tip card can\'t be paid from this app'**
  String get tipCardBroken;

  /// No description provided for @recordButtonMenuTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get recordButtonMenuTip;

  /// No description provided for @recordButtonMenuOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Open link'**
  String get recordButtonMenuOpenLink;

  /// No description provided for @recordButtonMenuSeeImage.
  ///
  /// In en, this message translates to:
  /// **'See image'**
  String get recordButtonMenuSeeImage;

  /// No description provided for @createRecordPageImageChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get createRecordPageImageChange;

  /// No description provided for @createRecordPageHeaderPostCard.
  ///
  /// In en, this message translates to:
  /// **'PINNED POST'**
  String get createRecordPageHeaderPostCard;

  /// No description provided for @createRecordPagePostCardSizeLead.
  ///
  /// In en, this message translates to:
  /// **'A post you pinned. It shows the post as it is now, so edits, comments and a removal all show up here. It always takes the full width and grows with the post; you choose its background.'**
  String get createRecordPagePostCardSizeLead;

  /// No description provided for @createRecordPagePinPlacement.
  ///
  /// In en, this message translates to:
  /// **'Where it goes'**
  String get createRecordPagePinPlacement;

  /// No description provided for @createRecordPagePinTop.
  ///
  /// In en, this message translates to:
  /// **'Pin to top'**
  String get createRecordPagePinTop;

  /// No description provided for @createRecordPagePinBottom.
  ///
  /// In en, this message translates to:
  /// **'Pin to bottom'**
  String get createRecordPagePinBottom;

  /// No description provided for @createRecordPagePinAction.
  ///
  /// In en, this message translates to:
  /// **'PIN TO PROFILE'**
  String get createRecordPagePinAction;

  /// No description provided for @postCardMenuPinToProfile.
  ///
  /// In en, this message translates to:
  /// **'Pin to profile'**
  String get postCardMenuPinToProfile;

  /// No description provided for @postCardMenuGoToFeed.
  ///
  /// In en, this message translates to:
  /// **'Go to feed'**
  String get postCardMenuGoToFeed;

  /// No description provided for @feedReaderPageFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedReaderPageFallbackTitle;

  /// No description provided for @postCardPinSaving.
  ///
  /// In en, this message translates to:
  /// **'Pinning to your profile…'**
  String get postCardPinSaving;

  /// No description provided for @postCardPinDone.
  ///
  /// In en, this message translates to:
  /// **'Pinned to your profile'**
  String get postCardPinDone;

  /// No description provided for @postCardPinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pin the post'**
  String get postCardPinFailed;

  /// No description provided for @postCardPinnedGone.
  ///
  /// In en, this message translates to:
  /// **'Could not find this post'**
  String get postCardPinnedGone;

  /// No description provided for @postCardPinnedLocked.
  ///
  /// In en, this message translates to:
  /// **'This post is private'**
  String get postCardPinnedLocked;

  /// No description provided for @postCardPinnedFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the post. Tap to retry'**
  String get postCardPinnedFailed;

  /// No description provided for @createRecordPagePostCardLink.
  ///
  /// In en, this message translates to:
  /// **'POST LINK'**
  String get createRecordPagePostCardLink;

  /// No description provided for @createRecordPagePostCardLinkCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get createRecordPagePostCardLinkCopy;

  /// No description provided for @createRecordPagePostCardLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get createRecordPagePostCardLinkCopied;

  /// No description provided for @createRecordPageBackgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get createRecordPageBackgroundImage;

  /// No description provided for @createRecordPagePostMedia.
  ///
  /// In en, this message translates to:
  /// **'Post media as background'**
  String get createRecordPagePostMedia;

  /// No description provided for @createRecordPagePostMediaHint.
  ///
  /// In en, this message translates to:
  /// **'Shows the post\'s banner, image or video in front of the background.'**
  String get createRecordPagePostMediaHint;

  /// No description provided for @netDepositMonths.
  ///
  /// In en, this message translates to:
  /// **'Deposit (months)'**
  String get netDepositMonths;

  /// No description provided for @netDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get netDeposit;

  /// No description provided for @networkAccessSheetsTopUpHeader.
  ///
  /// In en, this message translates to:
  /// **'TOP UP'**
  String get networkAccessSheetsTopUpHeader;

  /// No description provided for @networkAccessSheetsTopUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Top up your service balance'**
  String get networkAccessSheetsTopUpTitle;

  /// No description provided for @networkAccessSheetsTopUpBody.
  ///
  /// In en, this message translates to:
  /// **'Moved from your wallet into the balance both your providers draw from. What they have not earned is yours to withdraw.'**
  String get networkAccessSheetsTopUpBody;

  /// No description provided for @networkAccessSheetsMonthsOfCover.
  ///
  /// In en, this message translates to:
  /// **'Months of cover'**
  String get networkAccessSheetsMonthsOfCover;

  /// No description provided for @networkAccessSheetsRatePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Both services / month'**
  String get networkAccessSheetsRatePerMonth;

  /// No description provided for @networkAccessSheetsDepositing.
  ///
  /// In en, this message translates to:
  /// **'DEPOSITING…'**
  String get networkAccessSheetsDepositing;

  /// No description provided for @networkAccessSheetsDeposit.
  ///
  /// In en, this message translates to:
  /// **'DEPOSIT'**
  String get networkAccessSheetsDeposit;

  /// No description provided for @networkAccessSheetsWithdrawHeader.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW'**
  String get networkAccessSheetsWithdrawHeader;

  /// No description provided for @networkAccessSheetsWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Take your balance back'**
  String get networkAccessSheetsWithdrawTitle;

  /// No description provided for @networkAccessSheetsWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'What your providers have accrued up to this second is paid first; the rest returns to your wallet.'**
  String get networkAccessSheetsWithdrawBody;

  /// No description provided for @networkAccessSheetsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get networkAccessSheetsAvailable;

  /// No description provided for @networkAccessSheetsAccrued.
  ///
  /// In en, this message translates to:
  /// **'Accrued to providers'**
  String get networkAccessSheetsAccrued;

  /// Withdraw sheet row: the part of the service balance a third party funded (SubsMemory.sponsored). Kept back by the contract on withdraw; shown only when > 0. Never say 'sponsored balance' to the user.
  ///
  /// In en, this message translates to:
  /// **'Added for you'**
  String get networkAccessSheetsAddedForYou;

  /// No description provided for @networkAccessSheetsAddedForYouNote.
  ///
  /// In en, this message translates to:
  /// **'Part of this balance was added for you by someone else. It pays your providers first and never returns to your wallet.'**
  String get networkAccessSheetsAddedForYouNote;

  /// No description provided for @networkAccessSheetsWithdrawing.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWING…'**
  String get networkAccessSheetsWithdrawing;

  /// No description provided for @networkAccessSheetsWithdraw.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW'**
  String get networkAccessSheetsWithdraw;

  /// No description provided for @networkAccessSheetsNothingToWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Nothing to withdraw.'**
  String get networkAccessSheetsNothingToWithdraw;

  /// No description provided for @networkAccessSheetsLeaveHeader.
  ///
  /// In en, this message translates to:
  /// **'LEAVE {provider}'**
  String networkAccessSheetsLeaveHeader(Object provider);

  /// No description provided for @networkAccessSheetsLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {slug}'**
  String networkAccessSheetsLeaveTitle(Object slug);

  /// No description provided for @networkAccessSheetsLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'Stops this service now. What accrued up to this second is paid; your balance stays yours.'**
  String get networkAccessSheetsLeaveBody;

  /// No description provided for @networkAccessSheetsLeaving.
  ///
  /// In en, this message translates to:
  /// **'LEAVING…'**
  String get networkAccessSheetsLeaving;

  /// No description provided for @networkAccessSheetsLeave.
  ///
  /// In en, this message translates to:
  /// **'LEAVE'**
  String get networkAccessSheetsLeave;

  /// No description provided for @treasuryPageSubInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get treasuryPageSubInactive;

  /// No description provided for @treasuryPageCoveredUntil.
  ///
  /// In en, this message translates to:
  /// **'Covered until'**
  String get treasuryPageCoveredUntil;

  /// No description provided for @treasuryPageCoveredWhileUsed.
  ///
  /// In en, this message translates to:
  /// **'while you use the app'**
  String get treasuryPageCoveredWhileUsed;

  /// No description provided for @treasuryPageSubActiveCitizenBody.
  ///
  /// In en, this message translates to:
  /// **'Active. The network mints your {provider}\'s fee while you use the app. Switch any time.'**
  String treasuryPageSubActiveCitizenBody(Object provider);

  /// No description provided for @treasuryPageSubInactiveBody.
  ///
  /// In en, this message translates to:
  /// **'Not served right now — the account went quiet too long, or the balance ran out. Open the app, top up, or subscribe again to resume.'**
  String get treasuryPageSubInactiveBody;

  /// No description provided for @treasuryPageServiceBalance.
  ///
  /// In en, this message translates to:
  /// **'Service balance'**
  String get treasuryPageServiceBalance;

  /// No description provided for @treasuryPageServiceBalanceBlurb.
  ///
  /// In en, this message translates to:
  /// **'One balance pays both your BSP and your SSP, by the second, only while a provider has enough subscribers to be paid. Top it up or take it back whenever you like.'**
  String get treasuryPageServiceBalanceBlurb;

  /// No description provided for @treasuryPageBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get treasuryPageBalance;

  /// No description provided for @treasuryPageAccrued.
  ///
  /// In en, this message translates to:
  /// **'Accrued, unpaid'**
  String get treasuryPageAccrued;

  /// No description provided for @treasuryPageAddedForYou.
  ///
  /// In en, this message translates to:
  /// **'Added for you'**
  String get treasuryPageAddedForYou;

  /// No description provided for @treasuryPageAddedForYouNote.
  ///
  /// In en, this message translates to:
  /// **'{amount} OX of this was added for you and pays your providers; it can\'t be withdrawn.'**
  String treasuryPageAddedForYouNote(Object amount);

  /// No description provided for @treasuryPageRunsOut.
  ///
  /// In en, this message translates to:
  /// **'Runs out'**
  String get treasuryPageRunsOut;

  /// No description provided for @treasuryPageNeverSubscribed.
  ///
  /// In en, this message translates to:
  /// **'Nothing deposited yet — subscribe to a provider below.'**
  String get treasuryPageNeverSubscribed;

  /// No description provided for @treasuryPageTopUp.
  ///
  /// In en, this message translates to:
  /// **'TOP UP'**
  String get treasuryPageTopUp;

  /// No description provided for @treasuryPageWithdraw.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW'**
  String get treasuryPageWithdraw;

  /// No description provided for @treasuryPageLeaveProvider.
  ///
  /// In en, this message translates to:
  /// **'LEAVE {provider}'**
  String treasuryPageLeaveProvider(Object provider);

  /// No description provided for @treasuryPageToppedUp.
  ///
  /// In en, this message translates to:
  /// **'Service balance topped up'**
  String get treasuryPageToppedUp;

  /// No description provided for @treasuryPageWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Service balance withdrawn'**
  String get treasuryPageWithdrawn;

  /// No description provided for @treasuryPageProviderLeft.
  ///
  /// In en, this message translates to:
  /// **'{provider} left'**
  String treasuryPageProviderLeft(Object provider);

  /// No description provided for @treasuryPageResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get treasuryPageResume;

  /// No description provided for @treasuryPageResumed.
  ///
  /// In en, this message translates to:
  /// **'Service resumed'**
  String get treasuryPageResumed;

  /// No description provided for @accountCenterOrgsSection.
  ///
  /// In en, this message translates to:
  /// **'Org membership'**
  String get accountCenterOrgsSection;

  /// No description provided for @orgAddAnyoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone can add me'**
  String get orgAddAnyoneTitle;

  /// No description provided for @orgAddAnyoneOnSub.
  ///
  /// In en, this message translates to:
  /// **'Anyone can add you to an org.'**
  String get orgAddAnyoneOnSub;

  /// No description provided for @orgAddAnyoneOffSub.
  ///
  /// In en, this message translates to:
  /// **'Only the people on your list can add you.'**
  String get orgAddAnyoneOffSub;

  /// No description provided for @orgAddListLabel.
  ///
  /// In en, this message translates to:
  /// **'WHO CAN ADD ME'**
  String get orgAddListLabel;

  /// No description provided for @orgAddListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get orgAddListEmpty;

  /// No description provided for @orgAddListOnHint.
  ///
  /// In en, this message translates to:
  /// **'Your list counts when the switch is off.'**
  String get orgAddListOnHint;

  /// No description provided for @orgAddLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String orgAddLeft(int count);

  /// No description provided for @orgAddAllowFriend.
  ///
  /// In en, this message translates to:
  /// **'ALLOW A FRIEND TO ADD ME'**
  String get orgAddAllowFriend;

  /// No description provided for @orgAddSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow a friend to add me'**
  String get orgAddSheetTitle;

  /// No description provided for @orgAddSheetHeading.
  ///
  /// In en, this message translates to:
  /// **'Who can add you to orgs'**
  String get orgAddSheetHeading;

  /// No description provided for @orgAddSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Your friend can add you to 5 orgs, by creating one with you or by proposing you in one. After 5 they leave your list, and you can add them again.'**
  String get orgAddSheetBody;

  /// No description provided for @orgAddRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from your list?'**
  String get orgAddRemoveTitle;

  /// No description provided for @orgAddRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{name} won\'t be able to add you to orgs anymore.'**
  String orgAddRemoveBody(String name);

  /// No description provided for @orgAddSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING & CONFIRMING…'**
  String get orgAddSaving;

  /// No description provided for @orgAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the change.'**
  String get orgAddFailed;

  /// No description provided for @orgAddPillAnyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get orgAddPillAnyone;

  /// No description provided for @orgAddPillFriends.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend} other{{count} friends}}'**
  String orgAddPillFriends(int count);

  /// No description provided for @networkAccessSheetsAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get networkAccessSheetsAmount;

  /// No description provided for @networkAccessSheetsCoversBoth.
  ///
  /// In en, this message translates to:
  /// **'Covers about {months} months of BSP and SSP at today\'s fees.'**
  String networkAccessSheetsCoversBoth(Object months);

  /// No description provided for @networkAccessSheetsCoversOne.
  ///
  /// In en, this message translates to:
  /// **'Covers about {months} months of {provider} at today\'s fees.'**
  String networkAccessSheetsCoversOne(Object months, Object provider);

  /// No description provided for @networkAccessSheetsCoversNone.
  ///
  /// In en, this message translates to:
  /// **'You are not subscribed to a provider yet; the deposit waits in your balance.'**
  String get networkAccessSheetsCoversNone;

  /// No description provided for @networkAccessSheetsGateNote.
  ///
  /// In en, this message translates to:
  /// **'Your providers are still below their minimum subscribers, so nothing is drawn yet.'**
  String get networkAccessSheetsGateNote;

  /// No description provided for @networkAccessSheetsMax.
  ///
  /// In en, this message translates to:
  /// **'MAX'**
  String get networkAccessSheetsMax;

  /// No description provided for @networkAccessSheetsAmountTooHigh.
  ///
  /// In en, this message translates to:
  /// **'That is more than you can withdraw right now.'**
  String get networkAccessSheetsAmountTooHigh;

  /// No description provided for @operatorAgreementSection.
  ///
  /// In en, this message translates to:
  /// **'Operator agreement'**
  String get operatorAgreementSection;

  /// No description provided for @operatorAgreementSignedPill.
  ///
  /// In en, this message translates to:
  /// **'SIGNED'**
  String get operatorAgreementSignedPill;

  /// No description provided for @operatorAgreementUnsignedPill.
  ///
  /// In en, this message translates to:
  /// **'NOT SIGNED'**
  String get operatorAgreementUnsignedPill;

  /// No description provided for @operatorAgreementSignedBody.
  ///
  /// In en, this message translates to:
  /// **'You accepted the current operator agreement. You can register a provider.'**
  String get operatorAgreementSignedBody;

  /// No description provided for @providerRegistrationInviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Registering a provider is by invitation for now, and your account is not on the list yet.'**
  String get providerRegistrationInviteOnly;

  /// No description provided for @operatorAgreementUnsignedBody.
  ///
  /// In en, this message translates to:
  /// **'Running a BSP or SSP starts with the operator agreement. Read it and sign it to register a provider.'**
  String get operatorAgreementUnsignedBody;

  /// No description provided for @operatorAgreementSign.
  ///
  /// In en, this message translates to:
  /// **'SIGN AGREEMENT'**
  String get operatorAgreementSign;

  /// No description provided for @operatorAgreementTitle.
  ///
  /// In en, this message translates to:
  /// **'Operator agreement'**
  String get operatorAgreementTitle;

  /// No description provided for @operatorAgreementLead.
  ///
  /// In en, this message translates to:
  /// **'Read the operator agreement to the end. Signing it lets you register BSPs and SSPs; every registration checks it.'**
  String get operatorAgreementLead;

  /// No description provided for @operatorAgreementVersion.
  ///
  /// In en, this message translates to:
  /// **'Operator agreement · version {version}'**
  String operatorAgreementVersion(Object version);

  /// No description provided for @operatorAgreementScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the end to sign'**
  String get operatorAgreementScrollHint;

  /// No description provided for @operatorAgreementAccept.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT AND SIGN'**
  String get operatorAgreementAccept;

  /// No description provided for @operatorAgreementSigning.
  ///
  /// In en, this message translates to:
  /// **'SIGNING'**
  String get operatorAgreementSigning;

  /// No description provided for @operatorAgreementDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Agreement signed'**
  String get operatorAgreementDoneTitle;

  /// No description provided for @operatorAgreementDoneBody.
  ///
  /// In en, this message translates to:
  /// **'You can now register a BSP or an SSP from this page.'**
  String get operatorAgreementDoneBody;

  /// No description provided for @operatorAgreementContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get operatorAgreementContinue;

  /// No description provided for @operatorAgreementFailed.
  ///
  /// In en, this message translates to:
  /// **'The signature did not go through.'**
  String get operatorAgreementFailed;

  /// No description provided for @operatorAgreementRetry.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get operatorAgreementRetry;

  /// No description provided for @operatorAgreementNeedsPermanentKey.
  ///
  /// In en, this message translates to:
  /// **'Signing needs a permanent key. This session expires; open PublicOS with your main key and sign there.'**
  String get operatorAgreementNeedsPermanentKey;

  /// No description provided for @operatorAgreementLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The agreement could not be loaded. Check your connection and try again.'**
  String get operatorAgreementLoadFailed;

  /// No description provided for @operatorAgreementNothingPublished.
  ///
  /// In en, this message translates to:
  /// **'No operator agreement is published yet. Try again later.'**
  String get operatorAgreementNothingPublished;

  /// No description provided for @groupVotingViewMaxOpen.
  ///
  /// In en, this message translates to:
  /// **'Open votes at once'**
  String get groupVotingViewMaxOpen;

  /// No description provided for @groupVotingViewMaxOpenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How many proposals can run in parallel (1–5)'**
  String get groupVotingViewMaxOpenSubtitle;

  /// No description provided for @groupVotingViewWaitFull.
  ///
  /// In en, this message translates to:
  /// **'Wait the full period'**
  String get groupVotingViewWaitFull;

  /// No description provided for @groupVotingViewWaitFullSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Passed votes run only after their period ends; any member runs them'**
  String get groupVotingViewWaitFullSubtitle;

  /// No description provided for @groupVotingViewProposerCap.
  ///
  /// In en, this message translates to:
  /// **'One open proposal per member'**
  String get groupVotingViewProposerCap;

  /// No description provided for @groupVotingViewProposerCapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A member\'s proposal must pass before they start another'**
  String get groupVotingViewProposerCapSubtitle;

  /// No description provided for @groupVotingViewOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get groupVotingViewOn;

  /// No description provided for @groupVotingViewOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get groupVotingViewOff;

  /// No description provided for @groupVotingViewSettingVoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a vote'**
  String get groupVotingViewSettingVoteTitle;

  /// No description provided for @groupVotingViewSettingVoteBody.
  ///
  /// In en, this message translates to:
  /// **'{setting} → {value}. It changes once the vote passes, and only for new proposals.'**
  String groupVotingViewSettingVoteBody(Object setting, Object value);

  /// No description provided for @groupVotingViewStartVote.
  ///
  /// In en, this message translates to:
  /// **'START VOTE'**
  String get groupVotingViewStartVote;

  /// No description provided for @groupVotingViewSettingVoteStarted.
  ///
  /// In en, this message translates to:
  /// **'Vote started'**
  String get groupVotingViewSettingVoteStarted;

  /// No description provided for @groupVotingViewExecute.
  ///
  /// In en, this message translates to:
  /// **'EXECUTE NOW'**
  String get groupVotingViewExecute;

  /// No description provided for @groupVotingViewExecuted.
  ///
  /// In en, this message translates to:
  /// **'Proposal ran'**
  String get groupVotingViewExecuted;

  /// No description provided for @groupVotingViewExecuteFailed.
  ///
  /// In en, this message translates to:
  /// **'The run failed; it stays open to try again'**
  String get groupVotingViewExecuteFailed;

  /// No description provided for @groupVotingViewWaitMode.
  ///
  /// In en, this message translates to:
  /// **'Wait mode · runs after the voting period'**
  String get groupVotingViewWaitMode;

  /// No description provided for @groupVotingViewWaitingToRun.
  ///
  /// In en, this message translates to:
  /// **'Passed · runs after the voting period'**
  String get groupVotingViewWaitingToRun;

  /// No description provided for @groupVotingViewReadyToRun.
  ///
  /// In en, this message translates to:
  /// **'Passed · ready to run'**
  String get groupVotingViewReadyToRun;

  /// No description provided for @groupVotingViewRunFailed.
  ///
  /// In en, this message translates to:
  /// **'Passed · the last run failed, run it again'**
  String get groupVotingViewRunFailed;

  /// No description provided for @groupVotingViewPayment.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT'**
  String get groupVotingViewPayment;

  /// No description provided for @groupVotingViewPayTo.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount} to'**
  String groupVotingViewPayTo(Object amount);

  /// No description provided for @groupVotingViewFromOrgSafe.
  ///
  /// In en, this message translates to:
  /// **'from the group\'s Safe'**
  String get groupVotingViewFromOrgSafe;

  /// No description provided for @groupVotingViewOpenPill.
  ///
  /// In en, this message translates to:
  /// **'{count} OPEN'**
  String groupVotingViewOpenPill(int count);

  /// No description provided for @groupVotingViewSplitterActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate split'**
  String get groupVotingViewSplitterActivate;

  /// No description provided for @groupVotingViewSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get groupVotingViewSplit;

  /// No description provided for @groupVotingViewSplitterActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate splitting?'**
  String get groupVotingViewSplitterActivateTitle;

  /// No description provided for @groupVotingViewSplitterActivateBody.
  ///
  /// In en, this message translates to:
  /// **'Starts a vote. Once it passes, this group can split OX from its Safe equally among its members, one vote per split. You only do this once.'**
  String get groupVotingViewSplitterActivateBody;

  /// No description provided for @groupVotingViewSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split OX'**
  String get groupVotingViewSplitTitle;

  /// No description provided for @groupVotingViewSplitBody.
  ///
  /// In en, this message translates to:
  /// **'Starts a vote to split an amount equally among the {count} members. The group has {balance} OX.'**
  String groupVotingViewSplitBody(int count, Object balance);

  /// No description provided for @groupVotingViewSplitAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get groupVotingViewSplitAmountHint;

  /// No description provided for @groupVotingViewSplitEach.
  ///
  /// In en, this message translates to:
  /// **'Each member gets {share} OX'**
  String groupVotingViewSplitEach(Object share);

  /// No description provided for @groupVotingViewSplitTooMuch.
  ///
  /// In en, this message translates to:
  /// **'That\'s more than the group has'**
  String get groupVotingViewSplitTooMuch;

  /// No description provided for @groupVotingViewSplitLabel.
  ///
  /// In en, this message translates to:
  /// **'SPLIT'**
  String get groupVotingViewSplitLabel;

  /// No description provided for @groupVotingViewSplitterActivateVote.
  ///
  /// In en, this message translates to:
  /// **'Activate splitting OX among the members'**
  String get groupVotingViewSplitterActivateVote;

  /// No description provided for @groupVotingViewSplitVote.
  ///
  /// In en, this message translates to:
  /// **'Split {amount} among {count} members'**
  String groupVotingViewSplitVote(Object amount, int count);

  /// No description provided for @groupVotingViewProposedBy.
  ///
  /// In en, this message translates to:
  /// **'proposed by {name}'**
  String groupVotingViewProposedBy(Object name);

  /// No description provided for @groupVotingViewSafeShort.
  ///
  /// In en, this message translates to:
  /// **'The Safe holds {balance}. If this passes, the payment will fail.'**
  String groupVotingViewSafeShort(Object balance);

  /// No description provided for @groupVotingViewRunCall.
  ///
  /// In en, this message translates to:
  /// **'Run {method} on {address}'**
  String groupVotingViewRunCall(Object method, Object address);

  /// No description provided for @groupVotingViewProviderRegRestricted.
  ///
  /// In en, this message translates to:
  /// **'{registry} registration: invite-only'**
  String groupVotingViewProviderRegRestricted(Object registry);

  /// No description provided for @groupVotingViewProviderRegOpen.
  ///
  /// In en, this message translates to:
  /// **'{registry} registration: open to everyone'**
  String groupVotingViewProviderRegOpen(Object registry);

  /// No description provided for @groupVotingViewProviderRegAllow.
  ///
  /// In en, this message translates to:
  /// **'{registry} registration list: add'**
  String groupVotingViewProviderRegAllow(Object registry);

  /// No description provided for @groupVotingViewProviderRegDisallow.
  ///
  /// In en, this message translates to:
  /// **'{registry} registration list: remove'**
  String groupVotingViewProviderRegDisallow(Object registry);

  /// No description provided for @groupVotingViewNativeUnit.
  ///
  /// In en, this message translates to:
  /// **'native coin'**
  String get groupVotingViewNativeUnit;

  /// No description provided for @groupVotingViewNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'Needs {count} more For or Abstain to reach the quorum of {floor}'**
  String groupVotingViewNeedsMore(Object count, Object floor);

  /// No description provided for @groupVotingViewForMustLead.
  ///
  /// In en, this message translates to:
  /// **'Quorum reached, but For must outnumber Against to pass'**
  String get groupVotingViewForMustLead;

  /// No description provided for @groupVotingViewTechDetails.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get groupVotingViewTechDetails;

  /// No description provided for @groupVotingViewTechTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get groupVotingViewTechTarget;

  /// No description provided for @groupVotingViewTechValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get groupVotingViewTechValue;

  /// No description provided for @groupVotingViewTechMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get groupVotingViewTechMethod;

  /// No description provided for @groupVotingViewTechData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get groupVotingViewTechData;

  /// No description provided for @groupVotingViewDescAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get groupVotingViewDescAdd;

  /// No description provided for @groupVotingViewDescRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get groupVotingViewDescRemove;

  /// No description provided for @groupVotingViewDescSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get groupVotingViewDescSuspend;

  /// No description provided for @groupVotingViewDescUnsuspend.
  ///
  /// In en, this message translates to:
  /// **'Lift the suspension of'**
  String get groupVotingViewDescUnsuspend;

  /// No description provided for @groupVotingViewDescClearVouches.
  ///
  /// In en, this message translates to:
  /// **'Clear the vouches of'**
  String get groupVotingViewDescClearVouches;

  /// No description provided for @groupVotingViewDescRequestParent.
  ///
  /// In en, this message translates to:
  /// **'Join as a child of'**
  String get groupVotingViewDescRequestParent;

  /// No description provided for @groupVotingViewDescCancelParent.
  ///
  /// In en, this message translates to:
  /// **'Withdraw the request to'**
  String get groupVotingViewDescCancelParent;

  /// No description provided for @groupVotingViewDescAcceptChild.
  ///
  /// In en, this message translates to:
  /// **'Accept as a child'**
  String get groupVotingViewDescAcceptChild;

  /// No description provided for @groupVotingViewDescReleaseChild.
  ///
  /// In en, this message translates to:
  /// **'Release the child'**
  String get groupVotingViewDescReleaseChild;

  /// No description provided for @groupVotingViewDescChildLock.
  ///
  /// In en, this message translates to:
  /// **'Child lock'**
  String get groupVotingViewDescChildLock;

  /// No description provided for @groupVotingViewDescAddCard.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get groupVotingViewDescAddCard;

  /// No description provided for @groupVotingViewDescUpdateCard.
  ///
  /// In en, this message translates to:
  /// **'Update a card'**
  String get groupVotingViewDescUpdateCard;

  /// No description provided for @groupVotingViewDescDeleteCard.
  ///
  /// In en, this message translates to:
  /// **'Delete a card'**
  String get groupVotingViewDescDeleteCard;

  /// No description provided for @groupVotingViewDescSetSocial.
  ///
  /// In en, this message translates to:
  /// **'Set {name}'**
  String groupVotingViewDescSetSocial(Object name);

  /// No description provided for @groupVotingViewDescRemoveSocial.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String groupVotingViewDescRemoveSocial(Object name);

  /// No description provided for @groupVotingViewDescAddTab.
  ///
  /// In en, this message translates to:
  /// **'Add the tab “{name}”'**
  String groupVotingViewDescAddTab(Object name);

  /// No description provided for @groupVotingViewDescUpdateTab.
  ///
  /// In en, this message translates to:
  /// **'Update the tab “{name}”'**
  String groupVotingViewDescUpdateTab(Object name);

  /// No description provided for @groupVotingViewDescRemoveTab.
  ///
  /// In en, this message translates to:
  /// **'Remove the tab “{name}”'**
  String groupVotingViewDescRemoveTab(Object name);

  /// No description provided for @groupVotingViewDescChangeBio.
  ///
  /// In en, this message translates to:
  /// **'Change the bio'**
  String get groupVotingViewDescChangeBio;

  /// No description provided for @groupVotingViewDescChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change the profile picture'**
  String get groupVotingViewDescChangeAvatar;

  /// No description provided for @groupVotingViewDescChangeBanner.
  ///
  /// In en, this message translates to:
  /// **'Change the banner'**
  String get groupVotingViewDescChangeBanner;

  /// No description provided for @groupVotingViewDescChangeBackground.
  ///
  /// In en, this message translates to:
  /// **'Change the background'**
  String get groupVotingViewDescChangeBackground;

  /// No description provided for @groupVotingViewDescChangeColor.
  ///
  /// In en, this message translates to:
  /// **'Change the profile color'**
  String get groupVotingViewDescChangeColor;

  /// No description provided for @groupVotingViewDescSetRecord.
  ///
  /// In en, this message translates to:
  /// **'Set “{name}”'**
  String groupVotingViewDescSetRecord(Object name);

  /// No description provided for @groupVotingViewDescDeleteRecord.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”'**
  String groupVotingViewDescDeleteRecord(Object name);

  /// No description provided for @groupVotingViewDescNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get groupVotingViewDescNone;

  /// No description provided for @groupVotingViewDescBatch.
  ///
  /// In en, this message translates to:
  /// **'Update {count} records'**
  String groupVotingViewDescBatch(Object count);

  /// No description provided for @groupVotingViewDescDeleteBatch.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} records'**
  String groupVotingViewDescDeleteBatch(Object count);

  /// No description provided for @groupVotingViewDescAddWallet.
  ///
  /// In en, this message translates to:
  /// **'Add the wallet “{label}”'**
  String groupVotingViewDescAddWallet(Object label);

  /// No description provided for @groupVotingViewDescRemoveWallet.
  ///
  /// In en, this message translates to:
  /// **'Remove a wallet'**
  String get groupVotingViewDescRemoveWallet;

  /// No description provided for @groupVotingViewDescAddInbox.
  ///
  /// In en, this message translates to:
  /// **'Add the chat inbox “{label}”'**
  String groupVotingViewDescAddInbox(Object label);

  /// No description provided for @groupVotingViewDescRemoveInbox.
  ///
  /// In en, this message translates to:
  /// **'Remove a chat inbox'**
  String get groupVotingViewDescRemoveInbox;

  /// No description provided for @groupVotingViewDescRegisterApp.
  ///
  /// In en, this message translates to:
  /// **'Register the app {slug}'**
  String groupVotingViewDescRegisterApp(Object slug);

  /// No description provided for @groupVotingViewDescRemoveApp.
  ///
  /// In en, this message translates to:
  /// **'Remove the app {slug}'**
  String groupVotingViewDescRemoveApp(Object slug);

  /// No description provided for @groupVotingViewDescRenameApp.
  ///
  /// In en, this message translates to:
  /// **'Rename the app {slug}'**
  String groupVotingViewDescRenameApp(Object slug);

  /// No description provided for @groupVotingViewDescSetAppPointer.
  ///
  /// In en, this message translates to:
  /// **'Set {pointer} of {slug}'**
  String groupVotingViewDescSetAppPointer(Object slug, Object pointer);

  /// No description provided for @groupVotingViewDescRemoveAppPointer.
  ///
  /// In en, this message translates to:
  /// **'Remove {pointer} of {slug}'**
  String groupVotingViewDescRemoveAppPointer(Object slug, Object pointer);

  /// No description provided for @groupVotingViewDescSetValue.
  ///
  /// In en, this message translates to:
  /// **'Set {name}: “{value}”'**
  String groupVotingViewDescSetValue(Object name, Object value);

  /// No description provided for @groupVotingViewDescWas.
  ///
  /// In en, this message translates to:
  /// **'was “{value}”'**
  String groupVotingViewDescWas(Object value);

  /// No description provided for @groupVotingViewDescBio.
  ///
  /// In en, this message translates to:
  /// **'bio'**
  String get groupVotingViewDescBio;

  /// No description provided for @groupVotingViewDescColor.
  ///
  /// In en, this message translates to:
  /// **'profile color'**
  String get groupVotingViewDescColor;

  /// No description provided for @groupVotingViewOutcomeExecuted.
  ///
  /// In en, this message translates to:
  /// **'PASSED · EXECUTED'**
  String get groupVotingViewOutcomeExecuted;

  /// No description provided for @groupVotingViewOutcomeDefeated.
  ///
  /// In en, this message translates to:
  /// **'DEFEATED'**
  String get groupVotingViewOutcomeDefeated;

  /// No description provided for @groupVotingViewOutcomeExpired.
  ///
  /// In en, this message translates to:
  /// **'EXPIRED'**
  String get groupVotingViewOutcomeExpired;

  /// No description provided for @groupVotingViewOutcomeRunFailed.
  ///
  /// In en, this message translates to:
  /// **'PASSED · RUN FAILED'**
  String get groupVotingViewOutcomeRunFailed;

  /// No description provided for @groupVotingViewOutcomeCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get groupVotingViewOutcomeCancelled;

  /// No description provided for @groupVotingViewRecent.
  ///
  /// In en, this message translates to:
  /// **'LAST 24 HOURS'**
  String get groupVotingViewRecent;

  /// No description provided for @groupVotingViewSending.
  ///
  /// In en, this message translates to:
  /// **'Sending to the chain…'**
  String get groupVotingViewSending;

  /// No description provided for @keyLifetimeTitle.
  ///
  /// In en, this message translates to:
  /// **'KEY LIFETIME'**
  String get keyLifetimeTitle;

  /// No description provided for @keyLifetime24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get keyLifetime24h;

  /// No description provided for @keyLifetimeWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get keyLifetimeWeek;

  /// No description provided for @keyLifetimeMonth.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get keyLifetimeMonth;

  /// No description provided for @keyLifetimePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get keyLifetimePermanent;

  /// No description provided for @keyLifetimePermanentHint.
  ///
  /// In en, this message translates to:
  /// **'A permanent key can do everything, including recovery and citizenship.'**
  String get keyLifetimePermanentHint;

  /// No description provided for @keyLifetimeExpiringHint.
  ///
  /// In en, this message translates to:
  /// **'An expiring key stops working on its own. It can\'t add keys, change recovery or claim citizenship.'**
  String get keyLifetimeExpiringHint;

  /// No description provided for @keyLifetimeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'expires in {time}'**
  String keyLifetimeExpiresIn(Object time);

  /// No description provided for @keyLifetimeExpired.
  ///
  /// In en, this message translates to:
  /// **'key expired'**
  String get keyLifetimeExpired;

  /// No description provided for @addSessionDialogLifetimePermanent.
  ///
  /// In en, this message translates to:
  /// **'This key will be permanent.'**
  String get addSessionDialogLifetimePermanent;

  /// No description provided for @addSessionDialogLifetimeExpiring.
  ///
  /// In en, this message translates to:
  /// **'This key expires {lifetime} after you approve it.'**
  String addSessionDialogLifetimeExpiring(Object lifetime);

  /// No description provided for @addSessionDialogRecoveryNeedsPermanent.
  ///
  /// In en, this message translates to:
  /// **'Recovery always installs a permanent key. Ask them to make a new code with the Permanent lifetime.'**
  String get addSessionDialogRecoveryNeedsPermanent;

  /// No description provided for @keyLifetimePermanentKey.
  ///
  /// In en, this message translates to:
  /// **'permanent key'**
  String get keyLifetimePermanentKey;

  /// No description provided for @addSessionDialogNewSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW SESSION'**
  String get addSessionDialogNewSessionLabel;

  /// No description provided for @childrenSheetLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock this child?'**
  String get childrenSheetLockTitle;

  /// No description provided for @childrenSheetUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock this child?'**
  String get childrenSheetUnlockTitle;

  /// No description provided for @childrenSheetLockBody.
  ///
  /// In en, this message translates to:
  /// **'Start a vote so {name} can\'t take new child groups. The ones it has stay.'**
  String childrenSheetLockBody(Object name);

  /// No description provided for @childrenSheetUnlockBody.
  ///
  /// In en, this message translates to:
  /// **'Start a vote so {name} can take new child groups again.'**
  String childrenSheetUnlockBody(Object name);

  /// No description provided for @childrenSheetLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked: takes no new children'**
  String get childrenSheetLocked;

  /// No description provided for @groupVotingViewDescLockChild.
  ///
  /// In en, this message translates to:
  /// **'Stop new children under'**
  String get groupVotingViewDescLockChild;

  /// No description provided for @groupVotingViewDescUnlockChild.
  ///
  /// In en, this message translates to:
  /// **'Allow new children under'**
  String get groupVotingViewDescUnlockChild;

  /// No description provided for @accountCenterClearRecordsSection.
  ///
  /// In en, this message translates to:
  /// **'Delete all records'**
  String get accountCenterClearRecordsSection;

  /// No description provided for @accountCenterClearRecordsBody.
  ///
  /// In en, this message translates to:
  /// **'Erase everything on your profile: picture, banner, background, bio, social links, cards and tabs. Your account, name, citizenship and money stay.'**
  String get accountCenterClearRecordsBody;

  /// No description provided for @accountCenterClearRecordsButton.
  ///
  /// In en, this message translates to:
  /// **'DELETE ALL RECORDS'**
  String get accountCenterClearRecordsButton;

  /// No description provided for @clearRecordsDlg1Title.
  ///
  /// In en, this message translates to:
  /// **'Delete every record?'**
  String get clearRecordsDlg1Title;

  /// No description provided for @clearRecordsDlg1Lead.
  ///
  /// In en, this message translates to:
  /// **'This erases, in one go:'**
  String get clearRecordsDlg1Lead;

  /// No description provided for @clearRecordsCostIdentity.
  ///
  /// In en, this message translates to:
  /// **'Your profile picture, banner, background and colour'**
  String get clearRecordsCostIdentity;

  /// No description provided for @clearRecordsCostBio.
  ///
  /// In en, this message translates to:
  /// **'Your bio and status'**
  String get clearRecordsCostBio;

  /// No description provided for @clearRecordsCostLinks.
  ///
  /// In en, this message translates to:
  /// **'Every social link'**
  String get clearRecordsCostLinks;

  /// No description provided for @clearRecordsCostCards.
  ///
  /// In en, this message translates to:
  /// **'Every card, pinned post and tab'**
  String get clearRecordsCostCards;

  /// No description provided for @clearRecordsCostForever.
  ///
  /// In en, this message translates to:
  /// **'It can\'t be undone: the records are erased on chain, not hidden'**
  String get clearRecordsCostForever;

  /// No description provided for @clearRecordsDlg1Stays.
  ///
  /// In en, this message translates to:
  /// **'Your account, name, citizenship, money, keys and messages stay.'**
  String get clearRecordsDlg1Stays;

  /// No description provided for @clearRecordsDlg1Confirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get clearRecordsDlg1Confirm;

  /// No description provided for @clearRecordsWait.
  ///
  /// In en, this message translates to:
  /// **'DELETE · {seconds}'**
  String clearRecordsWait(Object seconds);

  /// No description provided for @clearRecordsKeep.
  ///
  /// In en, this message translates to:
  /// **'KEEP MY PROFILE'**
  String get clearRecordsKeep;

  /// No description provided for @clearRecordsDlg2Title.
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get clearRecordsDlg2Title;

  /// No description provided for @clearRecordsDlg2Body.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be empty. Anything you want back has to be added again.'**
  String get clearRecordsDlg2Body;

  /// No description provided for @clearRecordsDlg2Confirm.
  ///
  /// In en, this message translates to:
  /// **'DELETE EVERYTHING NOW'**
  String get clearRecordsDlg2Confirm;

  /// No description provided for @clearRecordsWorking.
  ///
  /// In en, this message translates to:
  /// **'Deleting records… {removed} removed, {left} left'**
  String clearRecordsWorking(Object removed, Object left);

  /// No description provided for @clearRecordsDone.
  ///
  /// In en, this message translates to:
  /// **'{count} records deleted'**
  String clearRecordsDone(Object count);

  /// No description provided for @clearRecordsFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the records'**
  String get clearRecordsFailed;

  /// No description provided for @startNewVoteSheetWalletTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'WALLET TYPE'**
  String get startNewVoteSheetWalletTypeLabel;

  /// No description provided for @startNewVoteSheetWalletTypeKey.
  ///
  /// In en, this message translates to:
  /// **'Key account'**
  String get startNewVoteSheetWalletTypeKey;

  /// No description provided for @startNewVoteSheetWalletTypeSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe on PublicOS'**
  String get startNewVoteSheetWalletTypeSafe;

  /// No description provided for @startNewVoteSheetWalletTypeHint.
  ///
  /// In en, this message translates to:
  /// **'A key account works on every chain. A Safe is a smart wallet on the PublicOS chain.'**
  String get startNewVoteSheetWalletTypeHint;

  /// No description provided for @accountCenterPenaltiesSection.
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get accountCenterPenaltiesSection;

  /// No description provided for @penaltiesOwedPill.
  ///
  /// In en, this message translates to:
  /// **'{amount} OX owed'**
  String penaltiesOwedPill(Object amount);

  /// No description provided for @penaltiesBody.
  ///
  /// In en, this message translates to:
  /// **'A penalty is a debt the court puts on an account, with a reason and a deadline. While anything is owed, BSP and SSP subscriptions are blocked. Anything you claim pays it first.'**
  String get penaltiesBody;

  /// No description provided for @penaltiesNothingOwed.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed.'**
  String get penaltiesNothingOwed;

  /// No description provided for @penaltiesOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get penaltiesOpenLabel;

  /// No description provided for @penaltiesHistoryLabel.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get penaltiesHistoryLabel;

  /// No description provided for @penaltyPaidOf.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {amount} OX paid'**
  String penaltyPaidOf(Object paid, Object amount);

  /// No description provided for @penaltyPayBy.
  ///
  /// In en, this message translates to:
  /// **'Pay by {date}'**
  String penaltyPayBy(Object date);

  /// No description provided for @penaltyOverdueSince.
  ///
  /// In en, this message translates to:
  /// **'Overdue since {date}'**
  String penaltyOverdueSince(Object date);

  /// No description provided for @penaltyStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get penaltyStatusPaid;

  /// No description provided for @penaltyStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get penaltyStatusCancelled;

  /// No description provided for @penaltyStatusPromoted.
  ///
  /// In en, this message translates to:
  /// **'Sent to suspension'**
  String get penaltyStatusPromoted;

  /// No description provided for @penaltiesOverdueWarning.
  ///
  /// In en, this message translates to:
  /// **'A penalty unpaid past its deadline can be sent by anyone to a 10-day suspension notice.'**
  String get penaltiesOverdueWarning;

  /// No description provided for @penaltiesPayButton.
  ///
  /// In en, this message translates to:
  /// **'PAY PENALTIES'**
  String get penaltiesPayButton;

  /// No description provided for @penaltiesPaid.
  ///
  /// In en, this message translates to:
  /// **'Penalties paid.'**
  String get penaltiesPaid;

  /// No description provided for @penaltiesPayFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed.'**
  String get penaltiesPayFailed;

  /// No description provided for @standingOwedAlert.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount} OX in penalties. BSP and SSP subscriptions are blocked until it is paid.'**
  String standingOwedAlert(Object amount);

  /// No description provided for @standingBlacklistedAlert.
  ///
  /// In en, this message translates to:
  /// **'Your account is on the court\'s blacklist. BSP and SSP subscriptions are blocked.'**
  String get standingBlacklistedAlert;

  /// No description provided for @standingNoticeAlert.
  ///
  /// In en, this message translates to:
  /// **'Your account will be suspended on {date}. It keeps working until then; you can move your funds out.'**
  String standingNoticeAlert(Object date);

  /// No description provided for @standingSuspendedAlert.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended since {date}.'**
  String standingSuspendedAlert(Object date);

  /// No description provided for @payPenaltiesHeader.
  ///
  /// In en, this message translates to:
  /// **'PAY PENALTIES'**
  String get payPenaltiesHeader;

  /// No description provided for @payPenaltiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay what you owe'**
  String get payPenaltiesTitle;

  /// No description provided for @payPenaltiesBody.
  ///
  /// In en, this message translates to:
  /// **'Paid from your main wallet and burned. The oldest penalty is paid first, and you can pay part of it.'**
  String get payPenaltiesBody;

  /// No description provided for @payPenaltiesOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get payPenaltiesOwed;

  /// No description provided for @payPenaltiesAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get payPenaltiesAll;

  /// No description provided for @payPenaltiesPay.
  ///
  /// In en, this message translates to:
  /// **'PAY'**
  String get payPenaltiesPay;

  /// No description provided for @payPenaltiesPaying.
  ///
  /// In en, this message translates to:
  /// **'PAYING…'**
  String get payPenaltiesPaying;

  /// No description provided for @payPenaltiesAboveOwed.
  ///
  /// In en, this message translates to:
  /// **'Only what is owed is taken.'**
  String get payPenaltiesAboveOwed;

  /// No description provided for @treasuryPageServicesBlocked.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are blocked: you owe penalties or your account is on the court\'s blacklist. See Account › Penalties.'**
  String get treasuryPageServicesBlocked;

  /// No description provided for @flagAction.
  ///
  /// In en, this message translates to:
  /// **'Flag'**
  String get flagAction;

  /// No description provided for @flagSheetTitlePost.
  ///
  /// In en, this message translates to:
  /// **'Flag this post'**
  String get flagSheetTitlePost;

  /// No description provided for @flagSheetTitleComment.
  ///
  /// In en, this message translates to:
  /// **'Flag this comment'**
  String get flagSheetTitleComment;

  /// No description provided for @flagSheetTitleChannel.
  ///
  /// In en, this message translates to:
  /// **'Flag this channel'**
  String get flagSheetTitleChannel;

  /// No description provided for @flagSheetTitleProfile.
  ///
  /// In en, this message translates to:
  /// **'Flag this profile'**
  String get flagSheetTitleProfile;

  /// No description provided for @flagSheetLead.
  ///
  /// In en, this message translates to:
  /// **'Pick the rule it breaks. Your flag is public on the chain and the owner can see it. You can have one open flag on each thing.'**
  String get flagSheetLead;

  /// No description provided for @flagCategory0.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get flagCategory0;

  /// No description provided for @flagCategory1.
  ///
  /// In en, this message translates to:
  /// **'Scam or fraud'**
  String get flagCategory1;

  /// No description provided for @flagCategory2.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get flagCategory2;

  /// No description provided for @flagCategory3.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get flagCategory3;

  /// No description provided for @flagCategory4.
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get flagCategory4;

  /// No description provided for @flagCategory5.
  ///
  /// In en, this message translates to:
  /// **'Violence or threats'**
  String get flagCategory5;

  /// No description provided for @flagCategory6.
  ///
  /// In en, this message translates to:
  /// **'Terrorism or extremism'**
  String get flagCategory6;

  /// No description provided for @flagCategory7.
  ///
  /// In en, this message translates to:
  /// **'Self-harm'**
  String get flagCategory7;

  /// No description provided for @flagCategory8.
  ///
  /// In en, this message translates to:
  /// **'Sexual content without an adult label'**
  String get flagCategory8;

  /// No description provided for @flagCategory9.
  ///
  /// In en, this message translates to:
  /// **'Election or civic misinformation'**
  String get flagCategory9;

  /// No description provided for @flagCategory10.
  ///
  /// In en, this message translates to:
  /// **'Copyright or trademark'**
  String get flagCategory10;

  /// No description provided for @flagCategory11.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get flagCategory11;

  /// No description provided for @flagCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Rule {id}'**
  String flagCategoryUnknown(Object id);

  /// No description provided for @flagPrivateHeader.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE REPORTS'**
  String get flagPrivateHeader;

  /// No description provided for @flagPrivacy.
  ///
  /// In en, this message translates to:
  /// **'My privacy or personal data'**
  String get flagPrivacy;

  /// No description provided for @flagIntimate.
  ///
  /// In en, this message translates to:
  /// **'Intimate images shared without consent'**
  String get flagIntimate;

  /// No description provided for @flagChildSafety.
  ///
  /// In en, this message translates to:
  /// **'Child safety'**
  String get flagChildSafety;

  /// No description provided for @flagPrivateBody.
  ///
  /// In en, this message translates to:
  /// **'These are never public flags. They go privately to the server\'s operator as a notice, and notices are not open yet.'**
  String get flagPrivateBody;

  /// No description provided for @flagNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get flagNoteHint;

  /// No description provided for @flagSubmit.
  ///
  /// In en, this message translates to:
  /// **'FLAG'**
  String get flagSubmit;

  /// No description provided for @flagSending.
  ///
  /// In en, this message translates to:
  /// **'FLAGGING…'**
  String get flagSending;

  /// No description provided for @flagFailed.
  ///
  /// In en, this message translates to:
  /// **'The flag didn\'t go through.'**
  String get flagFailed;

  /// No description provided for @flagDone.
  ///
  /// In en, this message translates to:
  /// **'Flagged. The owner and the server can see it.'**
  String get flagDone;

  /// No description provided for @flagAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You flagged this'**
  String get flagAlreadyTitle;

  /// No description provided for @flagFiledOn.
  ///
  /// In en, this message translates to:
  /// **'{category} · {date}'**
  String flagFiledOn(Object category, Object date);

  /// No description provided for @flagStatusOpenUntil.
  ///
  /// In en, this message translates to:
  /// **'Open until {date}'**
  String flagStatusOpenUntil(Object date);

  /// No description provided for @flagStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get flagStatusExpired;

  /// No description provided for @flagStatusWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get flagStatusWithdrawn;

  /// No description provided for @flagStatusRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed by the court'**
  String get flagStatusRemoved;

  /// No description provided for @flagStatusCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared by the court'**
  String get flagStatusCleared;

  /// No description provided for @flagWithdraw.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW FLAG'**
  String get flagWithdraw;

  /// No description provided for @flagWithdrawing.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAWING…'**
  String get flagWithdrawing;

  /// No description provided for @flagWithdrawNote.
  ///
  /// In en, this message translates to:
  /// **'Once withdrawn, you can flag this again from {date}.'**
  String flagWithdrawNote(Object date);

  /// No description provided for @flagAgainOn.
  ///
  /// In en, this message translates to:
  /// **'You can flag this again on {date}.'**
  String flagAgainOn(Object date);

  /// No description provided for @flagWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Flag withdrawn.'**
  String get flagWithdrawn;

  /// No description provided for @flagKindPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get flagKindPost;

  /// No description provided for @flagKindComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get flagKindComment;

  /// No description provided for @flagKindChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get flagKindChannel;

  /// No description provided for @flagKindProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get flagKindProfile;

  /// No description provided for @accountCenterFlagsSection.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get accountCenterFlagsSection;

  /// No description provided for @flagsMineLabel.
  ///
  /// In en, this message translates to:
  /// **'MY FLAGS'**
  String get flagsMineLabel;

  /// No description provided for @flagsOnMeLabel.
  ///
  /// In en, this message translates to:
  /// **'ON MY CONTENT'**
  String get flagsOnMeLabel;

  /// No description provided for @flagsOnMeBody.
  ///
  /// In en, this message translates to:
  /// **'Only you and the server hosting it see these.'**
  String get flagsOnMeBody;

  /// No description provided for @flagsNoneMine.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t flagged anything.'**
  String get flagsNoneMine;

  /// No description provided for @flagsNoneOnMe.
  ///
  /// In en, this message translates to:
  /// **'Nothing of yours has been flagged.'**
  String get flagsNoneOnMe;

  /// No description provided for @flagsPillOpen.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String flagsPillOpen(Object count);

  /// No description provided for @feedsNavigationDrawerExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get feedsNavigationDrawerExplore;

  /// No description provided for @feedsViewExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get feedsViewExplore;

  /// No description provided for @exploreWindowNow.
  ///
  /// In en, this message translates to:
  /// **'10 min'**
  String get exploreWindowNow;

  /// No description provided for @exploreWindowHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get exploreWindowHour;

  /// No description provided for @exploreWindow12h.
  ///
  /// In en, this message translates to:
  /// **'12 h'**
  String get exploreWindow12h;

  /// No description provided for @exploreWindow24h.
  ///
  /// In en, this message translates to:
  /// **'24 h'**
  String get exploreWindow24h;

  /// No description provided for @exploreTabPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get exploreTabPosts;

  /// No description provided for @exploreTabFeeds.
  ///
  /// In en, this message translates to:
  /// **'Feeds'**
  String get exploreTabFeeds;

  /// No description provided for @exploreReaders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reader} other{{count} readers}}'**
  String exploreReaders(int count);

  /// No description provided for @exploreEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing trending yet'**
  String get exploreEmptyTitle;

  /// No description provided for @exploreEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every 10 minutes the servers on the network agree on what is being read most. Pull down to check again.'**
  String get exploreEmptySubtitle;

  /// No description provided for @feedsNavigationDrawerSectionExplore.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE'**
  String get feedsNavigationDrawerSectionExplore;

  /// No description provided for @exploreHotPosts.
  ///
  /// In en, this message translates to:
  /// **'Hot posts'**
  String get exploreHotPosts;

  /// No description provided for @exploreHotFeeds.
  ///
  /// In en, this message translates to:
  /// **'Hot feeds'**
  String get exploreHotFeeds;

  /// No description provided for @exploreLatestPosts.
  ///
  /// In en, this message translates to:
  /// **'Latest posts'**
  String get exploreLatestPosts;

  /// No description provided for @exploreLatestEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing new yet'**
  String get exploreLatestEmptyTitle;

  /// No description provided for @exploreLatestEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'The newest public posts from across the network show here, refreshed every 10 minutes. Pull down to check again.'**
  String get exploreLatestEmptySubtitle;

  /// Title of the dialog shown before opening a profile whose owner marked it as mature content.
  ///
  /// In en, this message translates to:
  /// **'Mature content'**
  String get matureGateTitle;

  /// No description provided for @matureGateBody.
  ///
  /// In en, this message translates to:
  /// **'This profile contains mature content. Are you 18 or older and want to go on?'**
  String get matureGateBody;

  /// No description provided for @matureGateContinue.
  ///
  /// In en, this message translates to:
  /// **'I\'m 18+, go on'**
  String get matureGateContinue;

  /// No description provided for @matureGateBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get matureGateBack;

  /// iOS only: shown instead of the 18+ question when opening a mature profile; the profile cannot be opened on iOS for now.
  ///
  /// In en, this message translates to:
  /// **'This profile contains mature content, which isn\'t available on iPhone yet.'**
  String get matureGateIosBody;

  /// No description provided for @accountTagsSection.
  ///
  /// In en, this message translates to:
  /// **'Account tags'**
  String get accountTagsSection;

  /// No description provided for @accountTagMature.
  ///
  /// In en, this message translates to:
  /// **'Mature content'**
  String get accountTagMature;

  /// No description provided for @accountTagMatureSub.
  ///
  /// In en, this message translates to:
  /// **'People confirm they are 18+ before they see your profile.'**
  String get accountTagMatureSub;

  /// No description provided for @accountTagAutomated.
  ///
  /// In en, this message translates to:
  /// **'Automated account'**
  String get accountTagAutomated;

  /// No description provided for @accountTagAutomatedSub.
  ///
  /// In en, this message translates to:
  /// **'Software runs this account, not a person. A robot shows on your avatar.'**
  String get accountTagAutomatedSub;

  /// No description provided for @accountTagSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving tag…'**
  String get accountTagSaving;

  /// No description provided for @errAccountTagFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the tag.'**
  String get errAccountTagFailed;

  /// No description provided for @settingsMatureProfilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Mature profiles'**
  String get settingsMatureProfilesTitle;

  /// No description provided for @settingsMatureProfilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Profiles you said yes to (18+) show here. Remove one and it asks again next time.'**
  String get settingsMatureProfilesEmpty;

  /// No description provided for @settingsMatureProfilesRemove.
  ///
  /// In en, this message translates to:
  /// **'Ask again for this profile'**
  String get settingsMatureProfilesRemove;

  /// No description provided for @linkTargetNotFound.
  ///
  /// In en, this message translates to:
  /// **'Link target not found'**
  String get linkTargetNotFound;

  /// No description provided for @postSigMarkUnsigned.
  ///
  /// In en, this message translates to:
  /// **'Not signed'**
  String get postSigMarkUnsigned;

  /// No description provided for @postSigMarkBad.
  ///
  /// In en, this message translates to:
  /// **'Bad signature'**
  String get postSigMarkBad;

  /// No description provided for @postSigMarkUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Signature not checked'**
  String get postSigMarkUnchecked;

  /// No description provided for @postSigTitleChecked.
  ///
  /// In en, this message translates to:
  /// **'SIGNED'**
  String get postSigTitleChecked;

  /// No description provided for @postSigTitleUnsigned.
  ///
  /// In en, this message translates to:
  /// **'NOT SIGNED'**
  String get postSigTitleUnsigned;

  /// No description provided for @postSigTitleBad.
  ///
  /// In en, this message translates to:
  /// **'BAD SIGNATURE'**
  String get postSigTitleBad;

  /// No description provided for @postSigTitleUnchecked.
  ///
  /// In en, this message translates to:
  /// **'NOT CHECKED'**
  String get postSigTitleUnchecked;

  /// No description provided for @postSigThisPost.
  ///
  /// In en, this message translates to:
  /// **'(this post)'**
  String get postSigThisPost;

  /// No description provided for @postSigExplainChecked.
  ///
  /// In en, this message translates to:
  /// **'Signed. The author signed the text and media with their key, and this device checked that nothing changed since.'**
  String get postSigExplainChecked;

  /// No description provided for @postSigExplainUnsigned.
  ///
  /// In en, this message translates to:
  /// **'Not signed. There is no signature to check, so we cannot confirm who wrote this.'**
  String get postSigExplainUnsigned;

  /// No description provided for @postSigExplainBad.
  ///
  /// In en, this message translates to:
  /// **'Bad signature. A signature is given, and it does not match this post.'**
  String get postSigExplainBad;

  /// No description provided for @postSigExplainUnchecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked. The signature matches the content on this device, but the chain could not be reached to confirm whose key signed it. Try again later.'**
  String get postSigExplainUnchecked;

  /// No description provided for @postSigEncourage.
  ///
  /// In en, this message translates to:
  /// **'Signed posts are the norm here: sign yours so readers can check them anywhere.'**
  String get postSigEncourage;

  /// No description provided for @postSigDialogClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get postSigDialogClose;

  /// No description provided for @postSrvMark.
  ///
  /// In en, this message translates to:
  /// **'Served from outside the PublicOS network'**
  String get postSrvMark;

  /// No description provided for @postSrvTitle.
  ///
  /// In en, this message translates to:
  /// **'FROM THE OPEN INTERNET'**
  String get postSrvTitle;

  /// No description provided for @postSrvExplainServer.
  ///
  /// In en, this message translates to:
  /// **'This post comes from a server that follows the PublicOS feed protocol on its own, out on the open internet. It is not a registered provider within the PublicOS network, so it cannot send you notifications.'**
  String get postSrvExplainServer;

  /// No description provided for @postSrvExplainUnsigned.
  ///
  /// In en, this message translates to:
  /// **'Not signed: the author is a simple user, not a PublicOS account.'**
  String get postSrvExplainUnsigned;

  /// No description provided for @newKeyFlowAddDevice.
  ///
  /// In en, this message translates to:
  /// **'ADD THIS DEVICE'**
  String get newKeyFlowAddDevice;

  /// No description provided for @newKeyFlowNewAccount.
  ///
  /// In en, this message translates to:
  /// **'NEW ACCOUNT'**
  String get newKeyFlowNewAccount;

  /// No description provided for @newKeyFlowAddDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Add this device'**
  String get newKeyFlowAddDeviceTitle;

  /// No description provided for @newKeyFlowAddDeviceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which account should this device join? Type its name or its account address.'**
  String get newKeyFlowAddDeviceSubtitle;

  /// No description provided for @newKeyFlowAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name or address'**
  String get newKeyFlowAccountLabel;

  /// No description provided for @newKeyFlowAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with that name.'**
  String get newKeyFlowAccountNotFound;

  /// No description provided for @newKeyFlowIsThisYou.
  ///
  /// In en, this message translates to:
  /// **'Is this your account?'**
  String get newKeyFlowIsThisYou;

  /// No description provided for @newKeyFlowNewAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get newKeyFlowNewAccountTitle;

  /// No description provided for @newKeyFlowNewAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the username for your new account.'**
  String get newKeyFlowNewAccountSubtitle;

  /// No description provided for @newKeyFlowRuleLength.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max} characters'**
  String newKeyFlowRuleLength(int min, int max);

  /// No description provided for @newKeyFlowRuleStart.
  ///
  /// In en, this message translates to:
  /// **'Starts with a letter'**
  String get newKeyFlowRuleStart;

  /// No description provided for @newKeyFlowRuleEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends with a letter or a number'**
  String get newKeyFlowRuleEnd;

  /// No description provided for @newKeyFlowRuleChars.
  ///
  /// In en, this message translates to:
  /// **'Only letters, numbers, - and _'**
  String get newKeyFlowRuleChars;

  /// No description provided for @newKeyFlowRuleNoDoubles.
  ///
  /// In en, this message translates to:
  /// **'No -- or __'**
  String get newKeyFlowRuleNoDoubles;

  /// No description provided for @newKeyFlowRuleAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not taken'**
  String get newKeyFlowRuleAvailable;

  /// No description provided for @newKeyFlowFreeNote.
  ///
  /// In en, this message translates to:
  /// **'Citizens get names of 5 or more characters free.'**
  String get newKeyFlowFreeNote;

  /// No description provided for @newKeyFlowContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get newKeyFlowContinue;

  /// No description provided for @newKeyFlowCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get newKeyFlowCancel;

  /// No description provided for @newKeyFlowWordsWarning.
  ///
  /// In en, this message translates to:
  /// **'Once added or created, these words will help you recover this account. Write them down, keep them offline, and never share them.'**
  String get newKeyFlowWordsWarning;

  /// No description provided for @newKeyFlowActivated.
  ///
  /// In en, this message translates to:
  /// **'Your key was activated.'**
  String get newKeyFlowActivated;

  /// No description provided for @groupVotingViewWithdraw.
  ///
  /// In en, this message translates to:
  /// **'WITHDRAW'**
  String get groupVotingViewWithdraw;

  /// No description provided for @groupVotingViewVeto.
  ///
  /// In en, this message translates to:
  /// **'VETO'**
  String get groupVotingViewVeto;

  /// No description provided for @groupVotingViewWithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw your proposal'**
  String get groupVotingViewWithdrawTitle;

  /// No description provided for @groupVotingViewWithdrawBody.
  ///
  /// In en, this message translates to:
  /// **'It ends now, with your reason on record.'**
  String get groupVotingViewWithdrawBody;

  /// No description provided for @groupVotingViewWithdrawCooldown.
  ///
  /// In en, this message translates to:
  /// **'Afterwards you can\'t propose in this org for {time}.'**
  String groupVotingViewWithdrawCooldown(Object time);

  /// No description provided for @groupVotingViewVetoTitle.
  ///
  /// In en, this message translates to:
  /// **'Veto this vote'**
  String get groupVotingViewVetoTitle;

  /// No description provided for @groupVotingViewVetoBody.
  ///
  /// In en, this message translates to:
  /// **'As the org\'s vetoer you end this vote now. Your reason goes on record.'**
  String get groupVotingViewVetoBody;

  /// No description provided for @groupVotingViewCancelVoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Propose cancelling this vote'**
  String get groupVotingViewCancelVoteTitle;

  /// No description provided for @groupVotingViewCancelVoteBody.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s vote #{id}. The org votes on it; if it passes, that vote ends at once, even in an org that waits the full period.'**
  String groupVotingViewCancelVoteBody(Object name, Object id);

  /// No description provided for @groupVotingViewCancelReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (required)'**
  String get groupVotingViewCancelReasonHint;

  /// No description provided for @groupVotingViewWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get groupVotingViewWithdrawn;

  /// No description provided for @groupVotingViewVetoed.
  ///
  /// In en, this message translates to:
  /// **'Vetoed'**
  String get groupVotingViewVetoed;

  /// No description provided for @groupVotingViewCancelledBy.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by {who}: “{reason}”'**
  String groupVotingViewCancelledBy(Object who, Object reason);

  /// No description provided for @groupVotingViewCancelKindProposer.
  ///
  /// In en, this message translates to:
  /// **'the proposer'**
  String get groupVotingViewCancelKindProposer;

  /// No description provided for @groupVotingViewCancelKindVetoer.
  ///
  /// In en, this message translates to:
  /// **'the vetoer'**
  String get groupVotingViewCancelKindVetoer;

  /// No description provided for @groupVotingViewCancelKindOrg.
  ///
  /// In en, this message translates to:
  /// **'this org, by vote'**
  String get groupVotingViewCancelKindOrg;

  /// No description provided for @groupVotingViewCancelKindAncestor.
  ///
  /// In en, this message translates to:
  /// **'a parent org, by vote'**
  String get groupVotingViewCancelKindAncestor;

  /// No description provided for @groupVotingViewVetoer.
  ///
  /// In en, this message translates to:
  /// **'Vetoer'**
  String get groupVotingViewVetoer;

  /// No description provided for @groupVotingViewVetoerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One member who can cancel the org\'s votes alone'**
  String get groupVotingViewVetoerSubtitle;

  /// No description provided for @groupVotingViewVetoerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get groupVotingViewVetoerNone;

  /// No description provided for @groupVotingViewVetoerAutoRun.
  ///
  /// In en, this message translates to:
  /// **'This org runs a vote the moment it passes, so a vetoer will rarely have time to act. Turn on “wait the full period” to give them a window.'**
  String get groupVotingViewVetoerAutoRun;

  /// No description provided for @groupVotingViewCooldown.
  ///
  /// In en, this message translates to:
  /// **'Withdraw cooldown'**
  String get groupVotingViewCooldown;

  /// No description provided for @groupVotingViewCooldownSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long a member waits to propose again after withdrawing their own vote'**
  String get groupVotingViewCooldownSubtitle;

  /// No description provided for @groupVotingViewCooldownNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get groupVotingViewCooldownNone;

  /// No description provided for @groupVotingViewVetoerBody.
  ///
  /// In en, this message translates to:
  /// **'The vetoer is one member who can end any open vote of this org on their own, right away, with a reason on record. A vote that changes the vetoer can\'t be vetoed. Picking here starts a vote.'**
  String get groupVotingViewVetoerBody;

  /// No description provided for @groupVotingViewCooldownBody.
  ///
  /// In en, this message translates to:
  /// **'After a member withdraws their own open vote, they can\'t propose in this org for this long. A veto, or a cancel by vote, doesn\'t count. Picking here starts a vote.'**
  String get groupVotingViewCooldownBody;

  /// No description provided for @groupVotingViewMaxOpenBody.
  ///
  /// In en, this message translates to:
  /// **'How many proposals this org can have open at the same time. Each member can still have only one of their own open. Picking here starts a vote.'**
  String get groupVotingViewMaxOpenBody;

  /// No description provided for @groupVotingViewInCooldown.
  ///
  /// In en, this message translates to:
  /// **'You withdrew a vote here. You can propose again {when}.'**
  String groupVotingViewInCooldown(Object when);

  /// No description provided for @groupVotingViewCancelAVote.
  ///
  /// In en, this message translates to:
  /// **'Cancel a vote'**
  String get groupVotingViewCancelAVote;

  /// No description provided for @groupVotingViewCancelAVoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Propose ending an open vote here or in a child org'**
  String get groupVotingViewCancelAVoteSubtitle;

  /// No description provided for @groupVotingViewDescSetVetoer.
  ///
  /// In en, this message translates to:
  /// **'Give the veto to'**
  String get groupVotingViewDescSetVetoer;

  /// No description provided for @groupVotingViewDescClearVetoer.
  ///
  /// In en, this message translates to:
  /// **'Remove the vetoer'**
  String get groupVotingViewDescClearVetoer;

  /// No description provided for @groupVotingViewDescCancelVote.
  ///
  /// In en, this message translates to:
  /// **'Cancel vote #{id}'**
  String groupVotingViewDescCancelVote(Object id);

  /// No description provided for @cancelVoteSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel a vote'**
  String get cancelVoteSheetTitle;

  /// No description provided for @cancelVoteSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open votes in this org and the orgs under it'**
  String get cancelVoteSheetSubtitle;

  /// No description provided for @cancelVoteSheetSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Find an org by name'**
  String get cancelVoteSheetSearchHint;

  /// No description provided for @cancelVoteSheetChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get cancelVoteSheetChecking;

  /// No description provided for @cancelVoteSheetNotFound.
  ///
  /// In en, this message translates to:
  /// **'No org named {name}'**
  String cancelVoteSheetNotFound(Object name);

  /// No description provided for @cancelVoteSheetNotInTree.
  ///
  /// In en, this message translates to:
  /// **'Not in this org\'s tree'**
  String get cancelVoteSheetNotInTree;

  /// No description provided for @cancelVoteSheetOpenVotes.
  ///
  /// In en, this message translates to:
  /// **'OPEN VOTES'**
  String get cancelVoteSheetOpenVotes;

  /// No description provided for @cancelVoteSheetChildren.
  ///
  /// In en, this message translates to:
  /// **'CHILD ORGS'**
  String get cancelVoteSheetChildren;

  /// No description provided for @cancelVoteSheetNoVotes.
  ///
  /// In en, this message translates to:
  /// **'No open votes'**
  String get cancelVoteSheetNoVotes;

  /// No description provided for @cancelVoteSheetNoChildren.
  ///
  /// In en, this message translates to:
  /// **'No child orgs'**
  String get cancelVoteSheetNoChildren;

  /// No description provided for @cancelVoteSheetShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get cancelVoteSheetShowMore;

  /// No description provided for @manageServerPageManageFiles.
  ///
  /// In en, this message translates to:
  /// **'MANAGE FILES'**
  String get manageServerPageManageFiles;

  /// No description provided for @manageFilesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Files'**
  String get manageFilesPageTitle;

  /// No description provided for @manageFilesPageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by file name'**
  String get manageFilesPageSearchHint;

  /// No description provided for @manageFilesPageFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get manageFilesPageFilterAll;

  /// No description provided for @manageFilesPageFilterImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get manageFilesPageFilterImages;

  /// No description provided for @manageFilesPageFilterVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get manageFilesPageFilterVideos;

  /// No description provided for @manageFilesPageFilterAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get manageFilesPageFilterAudio;

  /// No description provided for @manageFilesPageFilterOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get manageFilesPageFilterOther;

  /// No description provided for @manageFilesPageFilterPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get manageFilesPageFilterPublic;

  /// No description provided for @manageFilesPageFilterPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get manageFilesPageFilterPrivate;

  /// No description provided for @manageFilesPageSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get manageFilesPageSortNewest;

  /// No description provided for @manageFilesPageSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get manageFilesPageSortOldest;

  /// No description provided for @manageFilesPageSortLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get manageFilesPageSortLargest;

  /// No description provided for @manageFilesPageSortSmallest.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get manageFilesPageSortSmallest;

  /// No description provided for @manageFilesPageSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get manageFilesPageSortName;

  /// Manage Files: how many files the current search and filters show, and their total size.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}} · {size}'**
  String manageFilesPageShowing(int count, String size);

  /// No description provided for @manageFilesPageNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No files match.'**
  String get manageFilesPageNoMatches;

  /// No description provided for @manageFilesPageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load your files.'**
  String get manageFilesPageLoadFailed;

  /// No description provided for @manageFilesPageSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get manageFilesPageSelect;

  /// No description provided for @manageFilesPageSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get manageFilesPageSelectAll;

  /// No description provided for @manageFilesPageSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String manageFilesPageSelectedCount(int count);

  /// No description provided for @manageFilesPageDeleteManyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete files'**
  String get manageFilesPageDeleteManyTitle;

  /// No description provided for @manageFilesPageDeleteManyBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 file?} other{Delete {count} files?}} This frees up your media quota and can\'t be undone.'**
  String manageFilesPageDeleteManyBody(int count);

  /// No description provided for @manageFilesPageDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting {done} of {total}'**
  String manageFilesPageDeleting(int done, int total);

  /// No description provided for @manageFilesPageDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file deleted} other{{count} files deleted}}'**
  String manageFilesPageDeletedCount(int count);

  /// No description provided for @manageFilesPageDeletedPartial.
  ///
  /// In en, this message translates to:
  /// **'{deleted} deleted, {failed} failed'**
  String manageFilesPageDeletedPartial(int deleted, int failed);

  /// No description provided for @newAccountAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts are created by citizens, one at a time'**
  String get newAccountAskTitle;

  /// No description provided for @newAccountAskBody.
  ///
  /// In en, this message translates to:
  /// **'A citizen can create yours by scanning your code. If you do not know one, we can help you out.'**
  String get newAccountAskBody;

  /// No description provided for @newAccountAskFriend.
  ///
  /// In en, this message translates to:
  /// **'I HAVE A CITIZEN FRIEND'**
  String get newAccountAskFriend;

  /// No description provided for @newAccountAskHelp.
  ///
  /// In en, this message translates to:
  /// **'I DON\'T HAVE A FRIEND ON PUBLICOS'**
  String get newAccountAskHelp;

  /// No description provided for @newAccountAskOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the page.'**
  String get newAccountAskOpenFailed;

  /// No description provided for @importKeyLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'IMPORT ACCOUNT'**
  String get importKeyLinkTitle;

  /// No description provided for @importKeyLinkBody.
  ///
  /// In en, this message translates to:
  /// **'You are importing the keys for {name}.'**
  String importKeyLinkBody(String name);

  /// No description provided for @importKeyLinkBodyNoName.
  ///
  /// In en, this message translates to:
  /// **'You are importing the keys for an account.'**
  String get importKeyLinkBodyNoName;

  /// No description provided for @importKeyLinkAccept.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get importKeyLinkAccept;

  /// No description provided for @importKeyLinkPendingExists.
  ///
  /// In en, this message translates to:
  /// **'Finish or remove the pending key first.'**
  String get importKeyLinkPendingExists;

  /// No description provided for @importKeyLinkSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign out to import an account.'**
  String get importKeyLinkSignedIn;

  /// publicos_desktop status bar: chip shown when a newer build is on offer.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get desktopUpdateChip;

  /// publicos_desktop update dialog: title.
  ///
  /// In en, this message translates to:
  /// **'Update PublicOS'**
  String get desktopUpdateTitle;

  /// publicos_desktop update dialog: what the update is and what happens.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready ({sizeMb} MB). The app closes, updates and opens again. Your account and your data stay on this PC.'**
  String desktopUpdateBody(String version, int sizeMb);

  /// publicos_desktop update dialog: one line saying the build was verified.
  ///
  /// In en, this message translates to:
  /// **'Its signature was checked on the chain.'**
  String get desktopUpdateChecked;

  /// publicos_desktop update dialog: the confirm button.
  ///
  /// In en, this message translates to:
  /// **'UPDATE AND RESTART'**
  String get desktopUpdateNow;

  /// publicos_desktop update dialog: the dismiss button.
  ///
  /// In en, this message translates to:
  /// **'LATER'**
  String get desktopUpdateLater;

  /// publicos_desktop update dialog: download progress.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String desktopUpdateDownloading(int percent);

  /// publicos_desktop update dialog: shown right before the app closes to update.
  ///
  /// In en, this message translates to:
  /// **'Installing. The app will close now.'**
  String get desktopUpdateInstalling;

  /// publicos_desktop update dialog: the download or its check failed.
  ///
  /// In en, this message translates to:
  /// **'The update could not be installed. Nothing was changed.'**
  String get desktopUpdateFailed;

  /// publicos_desktop update dialog: the app folder is not writable.
  ///
  /// In en, this message translates to:
  /// **'This copy of the app cannot update itself where it is installed. Download the new version instead.'**
  String get desktopUpdateNotHere;

  /// publicos_desktop update dialog: opens the releases page in the browser.
  ///
  /// In en, this message translates to:
  /// **'OPEN THE DOWNLOAD PAGE'**
  String get desktopUpdateOpenPage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
