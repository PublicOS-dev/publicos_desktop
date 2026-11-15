// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageName => 'English';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Choose the language used across the app. Content stays in its original language.';

  @override
  String get settingsLanguageSystemDefault => 'System default';

  @override
  String get revertGeneric => 'The chain rejected the transaction.';

  @override
  String get revertAuthorizeFailed => 'Authorize failed.';

  @override
  String get revertRecoveryFailed => 'Could not start recovery.';

  @override
  String get revertAccountCreationFailed => 'Account creation failed.';

  @override
  String get revertCreateOrgFailed => 'Could not create the organization.';

  @override
  String get revertCreationPaused => 'Account creation is paused right now.';

  @override
  String get revertNameEmpty => 'Username can\'t be empty.';

  @override
  String get revertMinterNotCitizen =>
      'Only citizens can create new accounts. Get vouched in first.';

  @override
  String get revertNameCharsetTier =>
      'That username doesn\'t fit the rules (length, charset, or leading character).';

  @override
  String get revertNameTaken => 'That username is already taken.';

  @override
  String get revertNameReservedCooldown =>
      'That username is reserved or in cooldown — try another.';

  @override
  String get revertNameCooldown =>
      'That username is in cooldown — try another.';

  @override
  String get revertRenameQuota =>
      'You\'ve used your free name change for this year and have no bonus left.';

  @override
  String get revertNotRegisteredSender =>
      'This wallet isn\'t registered as a session of any account.';

  @override
  String get revertOrgRateLimited =>
      'You created an org recently — there\'s a cooldown before you can create another.';

  @override
  String get revertOrgNeedsMembers => 'An org needs at least one member.';

  @override
  String get revertThresholdPositive =>
      'The voting threshold must be at least 1.';

  @override
  String get revertThresholdExceedsMembers =>
      'The voting threshold can\'t be higher than the number of members.';

  @override
  String get revertMemberNotIndividual =>
      'One of the members isn\'t a valid individual account.';

  @override
  String get revertPublicOrgCreatorCitizen =>
      'Only citizens can create a public org.';

  @override
  String get revertPublicOrgMembersCitizens =>
      'Every member of a public org must be a citizen.';

  @override
  String get revertNotRegisteredSession =>
      'Your wallet isn\'t a registered session of any account.';

  @override
  String get revertNotOrgMember =>
      'You\'re not a member of this org — only members can start a vote.';

  @override
  String get revertNotOrgAccount => 'That address isn\'t an org account.';

  @override
  String get revertVoteAlreadyActive =>
      'There\'s already an active vote on this org — wait for it to resolve before starting another.';

  @override
  String get revertInvalidMemberAddress =>
      'The selected member address is invalid.';

  @override
  String get revertAlreadyMember => 'That account is already a member.';

  @override
  String get revertMemberMustBeIndividual =>
      'You can only add an individual account as a member, not an org account.';

  @override
  String get revertOracleUnavailable =>
      'Citizenship check unavailable right now — try again later.';

  @override
  String get revertPublicOrgAddCitizen =>
      'This is a public org — every new member must be a citizen.';

  @override
  String get revertNotMember => 'That account isn\'t a member.';

  @override
  String get revertCannotRemoveLastMember =>
      'You can\'t remove the last member of an org.';

  @override
  String get revertRemovalViolatesThreshold =>
      'Removing them would leave fewer members than the voting threshold — lower the threshold first.';

  @override
  String get revertOrgNotInitialized => 'This org isn\'t initialized.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get sendRecipientLookupFailed =>
      'Couldn\'t look up where to send this. Nothing was sent.';

  @override
  String get sendRecipientRetry => 'RETRY';

  @override
  String get errTxRefusedByNetwork =>
      'The network refused this transaction. Usually that means your domain is overdue: renew it in Account › Domain, then try again.';

  @override
  String get errKeyLabelExists => 'A key with this label already exists.';

  @override
  String get errInvalidMnemonic => 'Invalid recovery phrase.';

  @override
  String get errInvalidBase64 => 'Invalid base64 format.';

  @override
  String get errDbKeyEmpty => 'Database key can\'t be empty.';

  @override
  String get errKeyMetadataNotFound => 'Key metadata not found.';

  @override
  String get errKeyNotFound => 'Key not found.';

  @override
  String get errInvalidKeyLength => 'Invalid key length (expected 32 bytes).';

  @override
  String get errNoUserAddress => 'No current user address available.';

  @override
  String get errNoXmtpIdentity => 'No messaging identity selected.';

  @override
  String get errNotAuthenticated => 'You need to be signed in for that.';

  @override
  String get errNoServer => 'No server available right now. Try again later.';

  @override
  String get errCommentsNotSupported => 'This post doesn\'t allow comments.';

  @override
  String get errReactionsNotSupported => 'This post doesn\'t allow reactions.';

  @override
  String get errLoadContent => 'Couldn\'t load this. Try again.';

  @override
  String get signInToReact => 'Please sign in to react.';

  @override
  String sspNotSubscribed(String slug) {
    return 'Subscribe to $slug to write here.';
  }

  @override
  String sspWrong(String slug) {
    return 'You\'re on $slug. Switch to write here.';
  }

  @override
  String sspExpired(String slug) {
    return 'Your subscription to $slug expired.';
  }

  @override
  String get sspGateFailed =>
      'Can\'t verify your subscription right now. Try again.';

  @override
  String get sspThisServer => 'this server';

  @override
  String get sspAnotherServer => 'another server';

  @override
  String get sspActionSubscribe => 'SUBSCRIBE';

  @override
  String get sspActionSwitch => 'SWITCH';

  @override
  String get sspActionRenew => 'RENEW';

  @override
  String get errNotInitialized =>
      'The app isn\'t ready yet. Try again in a moment.';

  @override
  String get errCannotDeleteActiveAccount =>
      'You can\'t delete the account you\'re currently using.';

  @override
  String get errUpdateColorFailed => 'Couldn\'t update the color.';

  @override
  String get errRemoveSessionFailed => 'Couldn\'t remove the session.';

  @override
  String get errAddRecoveryFailed => 'Couldn\'t add the recovery contact.';

  @override
  String get errRemoveRecoveryFailed =>
      'Couldn\'t remove the recovery contact.';

  @override
  String get errSelectAccountFailed => 'Couldn\'t select that account.';

  @override
  String get errCreateKeysFailed => 'Couldn\'t create the keys.';

  @override
  String get errImportFailed =>
      'Couldn\'t import that. Check the value and try again.';

  @override
  String get errCheckActivationFailed => 'Couldn\'t check activation.';

  @override
  String get errDeleteAccountFailed => 'Couldn\'t delete the account.';

  @override
  String get errDeleteKeyPairFailed => 'Couldn\'t delete the key pair.';

  @override
  String get errResetAppFailed => 'Couldn\'t reset the app.';

  @override
  String get errAddWalletFailed => 'Couldn\'t link the wallet.';

  @override
  String get errCastVoteFailed => 'Couldn\'t cast your vote.';

  @override
  String get errTranslateFailed => 'Couldn\'t translate this.';

  @override
  String notifComment(String name) {
    return '$name commented on your post';
  }

  @override
  String notifReply(String name) {
    return '$name replied to your comment';
  }

  @override
  String notifMention(String name) {
    return '$name mentioned you';
  }

  @override
  String notifReactionPost(String name) {
    return '$name reacted to your post';
  }

  @override
  String notifReactionComment(String name) {
    return '$name reacted to your comment';
  }

  @override
  String notifFollowRequest(String name) {
    return '$name asked to follow your channel';
  }

  @override
  String notifFollowApproved(String name) {
    return '$name let you into their channel';
  }

  @override
  String get notificationsScreenPostUnavailable => 'Couldn\'t open this post';

  @override
  String get notificationsScreenChannelUnavailable =>
      'Couldn\'t open this channel';

  @override
  String get notificationsScreenCommented => ' commented on your post';

  @override
  String get notificationsScreenReplied => ' replied to your comment';

  @override
  String get notificationsScreenMentioned => ' mentioned you';

  @override
  String get notificationsScreenReactedPost => ' reacted to your post';

  @override
  String get notificationsScreenReactedComment => ' reacted to your comment';

  @override
  String get notificationsScreenFollowRequested =>
      ' asked to follow your channel';

  @override
  String get notificationsScreenFollowApproved => ' let you into their channel';

  @override
  String get notifAvatarYou => 'You updated your avatar';

  @override
  String notifAvatarThey(String name) {
    return '$name updated their avatar';
  }

  @override
  String get notifBannerYou => 'You updated your banner';

  @override
  String notifBannerThey(String name) {
    return '$name updated their banner';
  }

  @override
  String get notifBioYou => 'You updated your bio';

  @override
  String notifBioThey(String name) {
    return '$name updated their bio';
  }

  @override
  String get notifProfileYou => 'You updated your profile';

  @override
  String notifProfileThey(String name) {
    return '$name updated their profile';
  }

  @override
  String get notifTabsYou => 'You updated your tabs';

  @override
  String notifTabsThey(String name) {
    return '$name updated their tabs';
  }

  @override
  String notifVouchedYou(String name) {
    return '$name vouched for you 🎉';
  }

  @override
  String notifVouchedByYou(String name) {
    return 'You vouched for $name';
  }

  @override
  String notifVouchedOther(String actor, String target) {
    return '$actor vouched for $target';
  }

  @override
  String get notifCitizenYou => 'You\'re now a citizen 🎉';

  @override
  String notifCitizenThey(String name) {
    return '$name is now a citizen 🎉';
  }

  @override
  String notifRentYou(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return 'You paid your domain — $_temp0';
  }

  @override
  String notifRentThey(String name, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$name paid their domain — $_temp0';
  }

  @override
  String get notifEvictedYou => 'Your account was evicted for non-payment';

  @override
  String notifEvictedThey(String name) {
    return '$name was evicted for non-payment';
  }

  @override
  String get notifNameChangedYou => 'You changed your name';

  @override
  String notifNameNowYou(String name) {
    return 'You\'re now @$name';
  }

  @override
  String notifNameChangedThey(String actor) {
    return '$actor changed their name';
  }

  @override
  String notifNameNowThey(String actor, String name) {
    return '$actor is now @$name';
  }

  @override
  String get notifDisplayChangedYou => 'You changed your display name';

  @override
  String notifDisplayToYou(String name) {
    return 'You changed your display name to $name';
  }

  @override
  String notifDisplayChangedThey(String actor) {
    return '$actor changed their display name';
  }

  @override
  String notifDisplayToThey(String actor, String name) {
    return '$actor changed their display name to $name';
  }

  @override
  String notifTransferIn(String amount, String wallet) {
    return 'Received $amount in $wallet';
  }

  @override
  String notifTransferInFrom(String actor, String amount, String wallet) {
    return '$actor sent $amount to $wallet';
  }

  @override
  String notifTransferOut(String amount, String wallet) {
    return 'Sent $amount from $wallet';
  }

  @override
  String notifTransferOutTo(String amount, String wallet, String target) {
    return 'Sent $amount from $wallet to $target';
  }

  @override
  String notifTransferSelf(String amount, String wallet, String target) {
    return 'Moved $amount from $wallet to $target';
  }

  @override
  String get notifWalletGroup => 'Wallet activity';

  @override
  String get notifKindTransferIn => 'Money received';

  @override
  String get notifKindTransferOut => 'Money sent';

  @override
  String get notifKindTransferSelf => 'Between your wallets';

  @override
  String get bootInitializing => 'Initializing core systems...';

  @override
  String get bootCheckingAuth => 'Checking authentication...';

  @override
  String get bootCheckingLogin => 'Checking login...';

  @override
  String get bootRestoringSession => 'Restoring session...';

  @override
  String get bootConnectingChain => 'Connecting to chain...';

  @override
  String get bootLoadingKeys => 'Loading keys...';

  @override
  String get bootConnectingFeed => 'Connecting to feed server...';

  @override
  String get bootLoadingMessages => 'Loading messages...';

  @override
  String get bootSettingUpNotifs => 'Setting up notifications...';

  @override
  String get bootOpening => 'Opening...';

  @override
  String get bootLoading => 'Loading...';

  @override
  String get bootRetry => 'CONNECT';

  @override
  String get bootErrCoreInit => 'Failed to initialize core systems';

  @override
  String get bootErrAuthNeeded => 'Authentication needed to continue';

  @override
  String get bootErrUnexpected =>
      'An unexpected error occurred during initialization. Please try again.';

  @override
  String get onbPublicosTitle => 'PublicOS';

  @override
  String get onbPublicosSubtitle => 'Own your self';

  @override
  String get onbPublicosBody =>
      'PublicOS is a social platform with its own infrastructure, governance, and economy: a public institution on the internet, owned by the people who use it.\n\nYou get a full domain of your own, a place to post, organize, and monetize any way you want.\n\nEverything runs in the open and is decided by liquid democracy: every rule, every vote, every token, verifiable by anyone.\n\n';

  @override
  String get onbInfraTitle => 'How does it work?';

  @override
  String get onbInfraSubtitle => 'Two networks, one place';

  @override
  String get onbInfraBody =>
      'PublicOS economy takes common internet mechanics and runs them as public services democratically managed on a blockchain, no enterprise owns your stuff:\n\n- Account data and business logic are run and stored transparently on a blockchain\n\n- Your posts, photos and files live on an email like network, where independent providers all connect to each other\n';

  @override
  String get onbAccountsTitle => 'Accounts';

  @override
  String get onbAccountsSubtitle =>
      'The four account types you\'ll interact with in PublicOS';

  @override
  String get onbAccountsSelfPrefix => 'You\'re currently a ';

  @override
  String get onbCitizenWord => 'citizen';

  @override
  String get onbPrivateWord => 'private';

  @override
  String get onbCitizenLabel => 'CITIZEN';

  @override
  String get onbCitizenDesc =>
      'Humans vouched on a social graph, free public services, one vote.';

  @override
  String get onbPublicOrgLabel => 'PUBLIC ORG';

  @override
  String get onbPublicOrgDesc => 'Citizen collectives of any type and size.';

  @override
  String get onbPrivateLabel => 'PRIVATE';

  @override
  String get onbPrivateDesc => 'Anonymous accounts, no vouching needed.';

  @override
  String get onbPrivateOrgLabel => 'PRIVATE ORG';

  @override
  String get onbPrivateOrgDesc =>
      'Citizen and private mixed collectives for groups and businesses.';

  @override
  String get onbMorphAccountTitle => 'Your Account';

  @override
  String get onbMorphAccountSubtitle => 'Smart';

  @override
  String get onbMorphAccountBody =>
      'Everything you do on PublicOS runs through one smart account. \n\nIt\'s your name and address, it keeps your records, assets and a public record of keys you authorize to sign with.\n\nLet\'s see how it comes together.';

  @override
  String get onbMorphDomainTitle => 'Your Domain';

  @override
  String get onbMorphDomainSubtitle => 'The name people use to find you';

  @override
  String get onbMorphDomainBody =>
      'Your **domain** is your readable name, the handle others type to reach you.';

  @override
  String get onbDomainBodyCitizen =>
      'Your **domain** is your readable name, the handle others type to reach you.\n\nYou hold **citizenship**, so yours is free for life.';

  @override
  String get onbDomainBodyPaid =>
      'Your **domain** is your readable name, the handle others type to reach you.\n\nYour account is **private**, and your domain is **already paid for**.';

  @override
  String get onbDomainBodyRent =>
      'Your **domain** is your readable name, the handle others type to reach you.\n\nPrivate accounts pay a **domain fee** to keep theirs. Set yours up below and you\'re ready.';

  @override
  String get onbMorphAddressTitle => 'Your Account Address';

  @override
  String get onbMorphAddressSubtitle => 'What the domain points at';

  @override
  String get onbMorphAddressBody =>
      'Your domain may change, but it always resolves to the same address on the chain.\n\nIt\'s your account\'s smart contract address, it runs by PublicOS rules, and holds your account\'s data.';

  @override
  String get onbMorphRecordsTitle => 'Your Records';

  @override
  String get onbMorphRecordsSubtitle => 'What your account holds';

  @override
  String get onbMorphRecordsBody =>
      'Records are pieces of information you choose to make public like your avatar and banner, the tabs that point out to your chats, your websites, your feeds.\n\n Take a look, open the tabs sheet.';

  @override
  String get onbMorphSafeTitle => 'Your Safe';

  @override
  String get onbMorphSafeSubtitle => 'Where your assets are kept';

  @override
  String get onbMorphSafeBody =>
      'Linked to your account sits a federated safe: a smart vault that holds your tokens and assets.\n\nIt\'s programmable, you can set rules and modules to manage as you like.';

  @override
  String get onbBspTitle => 'Blockchain Provider';

  @override
  String get onbBspSubtitle => 'Your gateway to the chain';

  @override
  String get onbBspBody =>
      'BSPs are public notaries. They verify every transaction is valid and signed by you, record it and share with other BSPs threading a ledger anyone can audit.\n\nIt is one transparent spreadsheet of balances and smart contracts. BSPs keep it running and connect you to it.';

  @override
  String get onbBspPrivateNote =>
      'As a private, you can connect via the Public RPC or subscribe to a BSP (each sets its own fair-use policy).';

  @override
  String get onbSspTitle => 'Social Provider';

  @override
  String get onbSspSubtitle => 'Where your feeds live';

  @override
  String get onbSspBody =>
      'An SSP hosts what any social media app would: your feeds, media, and social content.\n\nPick one to get started, or bring your own. You can always explore PublicOS first and add one later.';

  @override
  String get onbSspPrivateNote =>
      'As a private account this is an optional subscription, paid directly to your provider.';

  @override
  String get onbProviderCitizenNote =>
      'Free for you, the network covers provider fees for citizens.';

  @override
  String get onbEconomyTitle => 'Economy';

  @override
  String get onbEconomySubtitle => 'Sovereign';

  @override
  String get onbEconomyBody =>
      'PublicOS runs its own currency, **ox ¤**, managed like a national economy.\n\n**Contractors** (BSPs and SSPs) run the services. PublicOS mints ox to cover citizens\' use of them.\n\n**Domains** are a second market: citizens get one as a public right, while the rest trade on the open market.\n\nThe idea: **you are the platform\'s value**, so you earn a little ox whenever services are paid. Check the Treasury often.';

  @override
  String get onbContractTitle => 'The social contract';

  @override
  String get onbContractSubtitle => 'Our constitution';

  @override
  String get onbContractBody =>
      'Citizenship is a public right. In return, you honor one pledge:\n\n**Vouched accounts are humans.** If it ever mattered, you could point to a real person behind anyone you vouch for.\n\nYou vouch for **humanity, not morality**. You are never responsible for what others do, only for the truth of your vouch.';

  @override
  String get onbKeysTitle => 'Keys';

  @override
  String get onbKeysSubtitle => 'The ink behind your signature';

  @override
  String get onbKeysBody =>
      'Everything you do on chain is \"signed\" with your keys, the way a pen signs in ink.\n\n**Private key**: your secret. A signature made with it proves it\'s you, and only you can make one. Never share it.\n\n**Public address**: your shareable identifier. It lets anyone confirm a signature is really yours.\n\nCreate your first key, and keep its recovery phrase somewhere safe.';

  @override
  String get onbXmtpTitle => 'XMTP';

  @override
  String get onbXmtpSubtitle => 'Private messaging, no middleman';

  @override
  String get onbXmtpBody =>
      'PublicOS messages run on XMTP\'s decentralized network.\n\n**Many inboxes.** Make as many separate ones as you want.\n\n**No middleman.** End to end encrypted.\n\nAny key can create or join an Inbox ID.';

  @override
  String get onbInboxTitle => 'Inbox IDs';

  @override
  String get onbInboxSubtitle => 'Your messaging address';

  @override
  String get onbInboxBody =>
      'Treat inbox IDs as emails, some are to be kept off chain and private, some are public and shareable.\n\nPublish it to your profile with the \"tab\" button so people can reach you, it links your account to your messaging inbox on-chain.';

  @override
  String get onbGetAroundTitle => 'Get around PublicOS';

  @override
  String get onbGetAroundSubtitle => 'Three things worth knowing';

  @override
  String get onbManualTitle => 'Manual';

  @override
  String get onbManualBody =>
      'Everything about PublicOS, at your own pace, what the words mean, how the money works, what you can do. In your **Apps**.';

  @override
  String get onbLibraryTitle => 'Library';

  @override
  String get onbLibraryBody =>
      'How PublicOS works, in depth: what things cost, the rules, every contract. In your **Apps**.';

  @override
  String get onbSupportTitle => 'Support';

  @override
  String get onbSupportBody =>
      'An assistant lives on the **publicos** profile, under **support**. Ask it anything, in **any language**.';

  @override
  String get onbDone => 'DONE';

  @override
  String get onbEnter => 'ENTER PUBLICOS';

  @override
  String get onbContinue => 'CONTINUE';

  @override
  String get onbClaimCitizenship => 'CLAIM CITIZENSHIP';

  @override
  String get onbChooseBsp => 'CHOOSE A BSP';

  @override
  String get onbChooseSsp => 'CHOOSE AN SSP';

  @override
  String get onbOpenTabsFirst => 'OPEN MY TABS FIRST';

  @override
  String get onbSkipForNow => 'SKIP FOR NOW';

  @override
  String get onbSkip => 'SKIP';

  @override
  String get onbRedoHintTitle => 'You\'re all set';

  @override
  String get onbRedoHintBody =>
      'Want to keep learning? Open the Users Manual app, it\'s already in your Apps. You can pick or change your providers any time from the Settings app, and redo this whole intro from there too.';

  @override
  String get onbYoursCreateInboxFirst => 'CREATE YOUR INBOX FIRST';

  @override
  String get onbYoursTitle => 'A WAY IN';

  @override
  String get onbYoursSubtitle => 'A profile, but no door.';

  @override
  String get onbYoursBody =>
      'You have an account, but there\'s still no way to reach you.\n\nPublish an **inbox** as a tab and people can find you under your name.';

  @override
  String get onbYoursAddInbox => 'ADD MY FIRST INBOX';

  @override
  String get onbYoursHaveBody =>
      'You already have an **inbox**, people can reach you under your name.\n\nWant to see how another one gets published?';

  @override
  String get onbYoursUnknownBody =>
      'Your **inbox** may already be published, we couldn\'t check just now.\n\nCarry on, or walk through publishing one.';

  @override
  String get onbYoursShowMeHow => 'SHOW ME HOW';

  @override
  String get onbTabsBody =>
      'Your name can hold more than one **tab**. You published an inbox, that is one.\n\nEverything below is added later from your account page. Nothing else is needed today.';

  @override
  String get onbTabsAdded => 'ADDED';

  @override
  String get onbTabsInboxTitle => 'Inbox';

  @override
  String get onbTabsInboxSub => 'the one you just published';

  @override
  String get onbTabsWebSub => 'your site, under your name';

  @override
  String get onbTabsChannelSub => 'a feed people can follow';

  @override
  String get onbTabsAnotherTitle => 'Another inbox';

  @override
  String get onbTabsAnotherSub => 'work, public, as many as you like';

  @override
  String get onbCoachKeychain => 'Your keys live in the **keychain**. Open it.';

  @override
  String get onbCoachGenerate =>
      '**Generate** a key. It is made on this device and stored nowhere else.';

  @override
  String get onbCoachSim =>
      'Now switch it on for messaging, tap the **SIM**. That is what gives the key an inbox, and how you swap keys later.';

  @override
  String get onbProfileTitle => 'YOUR ACCOUNT';

  @override
  String get onbProfileSubtitle => 'Same parts. Already yours.';

  @override
  String get onbProfileBody => 'Let\'s fill in your **bio**.';

  @override
  String get onbProfileChooseBioFirst => 'CHOOSE A BIO FIRST';

  @override
  String get onbBioSaveChanges => 'SAVE CHANGES';

  @override
  String get onbBioSaving => 'SAVING';

  @override
  String get onbBioUndo => 'UNDO CHANGES';

  @override
  String get onbProfileBioEmpty => 'Your bio is still empty.';

  @override
  String get onbProfileNextCards => 'CONTINUE WITH MY CARDS';

  @override
  String get onbCardsTitle => 'YOUR CARDS';

  @override
  String get onbCardsSubtitle => 'Already on your profile.';

  @override
  String get onbCardsBody =>
      'Select a **theme** and some **cards** for your profile.';

  @override
  String get onbCardsRandomize => 'RANDOMIZE';

  @override
  String get onbCardsUndo => 'UNDO CHANGES';

  @override
  String get onbCardsSaving => 'SAVING';

  @override
  String get onbGiftBody =>
      '🎁 A **gift for citizens**, a collectible theme kit for your profile.';

  @override
  String get onbGiftOpen => 'OPEN GIFT';

  @override
  String get onbGiftMinting => 'OPENING';

  @override
  String get onbThemeSoulbound => 'STARTER';

  @override
  String get onbThemeCitizen => 'CITIZEN';

  @override
  String get onbProfileBioPrompt => 'Say something about yourself.';

  @override
  String get onbProfileBioWriteOwn => 'Write your own…';

  @override
  String get onbProfileBioPreset1 =>
      'Citizen of PublicOS. Building in the open.';

  @override
  String get onbProfileBioPreset2 =>
      'Here for the feeds, the forums, and the friends.';

  @override
  String get onbProfileBioPreset3 =>
      'Ask me anything, my inbox is on my profile.';

  @override
  String get onbAccountTitle => 'AN ACCOUNT';

  @override
  String get onbAccountSubtitle => 'This one belongs to PublicOS.';

  @override
  String get onbAccountBody =>
      'Every **account** is built the same way: a readable name, its address, and whatever it chooses to publish.\n\nPublished **tabs** are the account\'s menu. Open PublicOS\'s tabs and take a look.';

  @override
  String get onbAccountOpenTabsFirst => 'OPEN THE TABS FIRST';

  @override
  String get onbDomainManageFirst => 'MANAGE YOUR DOMAIN FIRST';

  @override
  String onbTabsSheetTitle(String account) {
    return '$account · tabs';
  }

  @override
  String get onbTabApp => 'App';

  @override
  String get onbTabManagement => 'Management';

  @override
  String get onbTabOrg => 'Org';

  @override
  String get onbTabProfile => 'Profile';

  @override
  String get onbTabChat => 'Chat';

  @override
  String get onbTabFeed => 'Feed';

  @override
  String get onbTabWebsite => 'Website';

  @override
  String get onbTabFallback => 'Tab';

  @override
  String get onbTabAdd => 'Add tab';

  @override
  String get onbTabExampleTitle => 'Example tabs';

  @override
  String get onbInboxRegisterTitle => 'REGISTER INBOX ID';

  @override
  String get onbInboxRegisterSubtitle =>
      'Register this inbox to your on-chain profile.';

  @override
  String get onbInboxHint => 'main, work, …';

  @override
  String get onbInboxRegister => 'REGISTER';

  @override
  String get actionCancel => 'CANCEL';

  @override
  String get domainStoreTitle => 'Domain Store';

  @override
  String get domainChecking => 'Checking…';

  @override
  String get domainLifetimeStatus => 'Lifetime — your domain never expires';

  @override
  String get domainNotSet => 'Not set yet';

  @override
  String get domainWasDue => 'Was due';

  @override
  String get domainPaidUntilLabel => 'Paid until';

  @override
  String get domainYourDomain => 'YOUR DOMAIN';

  @override
  String get domainGraceNote =>
      'Renew to keep your name and your write access. You\'re in the grace window, so it\'s still yours for now.';

  @override
  String get domainBadgeLifetime => 'LIFETIME';

  @override
  String get domainBadgeOverdue => 'OVERDUE';

  @override
  String get domainBadgeActive => 'ACTIVE';

  @override
  String get domainSearchHint => 'Search a name…';

  @override
  String get domainStatusAvailable => 'Available to claim';

  @override
  String get domainStatusLapsed => 'Holder lapsed — claimable';

  @override
  String get domainStatusTaken => 'Taken';

  @override
  String get domainStatusCooldown => 'On cooldown';

  @override
  String get domainStatusYours => 'This is your name';

  @override
  String get domainFreeForYou => 'Free for you';

  @override
  String get domainCalculating => 'Calculating…';

  @override
  String get domainLifetimeNeverExpires => 'Lifetime — never expires';

  @override
  String get domainName => 'Name';

  @override
  String domainChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chars',
      one: '1 char',
    );
    return '$_temp0';
  }

  @override
  String get domainSubtotal => 'Subtotal';

  @override
  String get domainDiscount => 'Discount *';

  @override
  String get domainTotal => 'Total';

  @override
  String get domainBalance => 'Balance';

  @override
  String get domainBalanceAfter => 'Balance after';

  @override
  String get domainNotEnoughPosNote => 'Not enough OX in your wallet for this.';

  @override
  String domainNameTooShort(int min) {
    return 'At least $min characters';
  }

  @override
  String domainNameTooLong(int max) {
    return 'Up to $max characters';
  }

  @override
  String get domainNameStartLetter => 'Must start with a letter';

  @override
  String get domainNameEndDashUnderscore => 'Can\'t end in - or _';

  @override
  String get domainNameAllowed => 'Allowed: a–z 0–9 - _';

  @override
  String get domainNameNoConsecDash => 'No consecutive --';

  @override
  String get domainNameNoConsecUnderscore => 'No consecutive __';

  @override
  String get domainMonths => 'Months';

  @override
  String get domainRenewed => 'Domain renewed';

  @override
  String get domainClaimed => 'Name claimed';

  @override
  String get domainEnterValidName => 'ENTER A VALID NAME';

  @override
  String get domainBtnChecking => 'CHECKING…';

  @override
  String get domainBtnYourName => 'THIS IS YOUR NAME';

  @override
  String get domainBtnNotEnoughPos => 'NOT ENOUGH OX';

  @override
  String get domainBtnRenew => 'RENEW';

  @override
  String get domainBtnNameTaken => 'NAME TAKEN';

  @override
  String get domainBtnOnCooldown => 'ON COOLDOWN';

  @override
  String get domainBtnRenewFirst => 'RENEW YOUR DOMAIN FIRST';

  @override
  String get domainBtnNoFreeChange => 'NO FREE CHANGE LEFT';

  @override
  String get domainBtnClaim => 'CLAIM';

  @override
  String get domainBtnSaving => 'SAVING TO CHAIN…';

  @override
  String get domainBtnCancel => 'CANCEL';

  @override
  String get domainBtnClaimIt => 'CLAIM IT';

  @override
  String get domainNoteLifetime =>
      'Lifetime — your domain never expires, so there\'s nothing to renew and no months to pick.';

  @override
  String domainNoteFreeCitizenChar(int min) {
    return 'Free for you as a citizen on a $min+ character name.';
  }

  @override
  String get domainNoteFreeCitizen => 'Free for you as a citizen.';

  @override
  String get domainNoteFreeAnnual =>
      'This change is free — it uses your once-a-year free name change.';

  @override
  String domainNoteFreeBonus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bonus name-change tickets',
      one: '1 bonus name-change ticket',
    );
    return 'This change is free — it spends 1 of your $_temp0.';
  }

  @override
  String domainNoteNoFreeUntil(String date) {
    return 'You\'ve used your yearly free change and hold no bonus tickets, so this free change isn\'t available until $date. You earn a ticket each time you gain citizenship.';
  }

  @override
  String get domainNoteFlatFee =>
      'One-time fee — as a citizen this name is yours for life, no renewals. 98% of what you pay is burned, 2% is shared with verified PublicOS Domains.';

  @override
  String domainNoteFlatFeeNextFree(String date) {
    return 'One-time fee — as a citizen this name is yours for life, no renewals. Your next free change opens $date.';
  }

  @override
  String domainNoteDiscount(String pct) {
    return '* Prepay more months for a bigger discount — about $pct% off each extra month, up to a cap. 98% of what you pay is burned, 2% is shared with verified PublicOS Domains.';
  }

  @override
  String domainConfirmBecomes(String name) {
    return 'Your account becomes \"$name\". ';
  }

  @override
  String domainConfirmCurrentFreed(String name) {
    return 'Your current name \"$name\" is freed (30-day cooldown if you\'re a citizen).';
  }

  @override
  String get domainConfirmOldFreed =>
      'Your old name is freed (30-day cooldown if you\'re a citizen).';

  @override
  String get domainConfirmEvicts =>
      'The current holder\'s domain has lapsed, so claiming evicts them onto a junk name.';

  @override
  String get domainConfirmFree => 'Free for you.';

  @override
  String domainConfirmCost(String cost) {
    return 'Cost: $cost  ·  98% burned, 2% shared with verified PublicOS Domains.';
  }

  @override
  String domainConfirmTitle(String name) {
    return 'Claim \"$name\"';
  }

  @override
  String get dlgCancel => 'Cancel';

  @override
  String get dlgOk => 'OK';

  @override
  String get actionRetry => 'Retry';

  @override
  String get keychainTitle => 'Keychain';

  @override
  String get keychainGroupTitle => 'Group Keychain';

  @override
  String get keychainSubtitle => 'Manage your messaging and wallet keys';

  @override
  String keychainGroupSubtitle(String name) {
    return 'Managing keys for $name';
  }

  @override
  String get keychainGenTitle => 'Generate New Key';

  @override
  String get keychainGenGroupTitle => 'Generate New Group Key';

  @override
  String get keychainKeyLabel => 'Key Label';

  @override
  String get keychainKeyLabelHint => 'Enter a label for this key';

  @override
  String get keychainGenExplain =>
      'You\'re about to generate a new key. It is stored on this device only. This does not register it as a session or turn on messaging.';

  @override
  String get keychainGenEmojiHint => 'Tap to pick an emoji';

  @override
  String get keychainGenerate => 'Generate';

  @override
  String get keychainImport => 'Import';

  @override
  String get keychainKeyCreated => 'Key created';

  @override
  String get keychainRecoveryTitle => 'RECOVERY PHRASE';

  @override
  String get keychainRecoveryWarning =>
      'Write down these 12 words. This is the only way to recover your key. Store it offline. Never share it.';

  @override
  String get keychainDeleteTitle => 'Delete Key';

  @override
  String keychainDeleteConfirm(String label) {
    return 'Are you sure you want to delete the key \"$label\"? This action cannot be undone.';
  }

  @override
  String get keychainDelete => 'Delete';

  @override
  String get keychainKeyDeleted => 'Key deleted successfully';

  @override
  String get keychainDeleteLoadedTitle => 'Key loaded on XMTP';

  @override
  String keychainDeleteLoadedBody(Object label) {
    return '\"$label\" is the key your messages run on right now. Deleting it signs messaging out on this device. Sure to delete it?';
  }

  @override
  String get keychainDeleteContinue => 'CONTINUE';

  @override
  String get keychainDeleteLoadedPhraseTitle =>
      'Did you store the recovery phrase?';

  @override
  String get keychainDeleteLoadedPhraseBody =>
      'Without the phrase or the private key, this key and the messages tied to it cannot be recovered. This cannot be undone.';

  @override
  String get keychainKeyDeletedUnloaded =>
      'Key deleted. Messaging is off until you pick a key.';

  @override
  String get keychainAddressCopied => 'Address copied to clipboard';

  @override
  String get keychainPrivKeyNotFound => 'Private key not found';

  @override
  String get keychainImportTitle => 'Import Key';

  @override
  String get keychainImportGroupTitle => 'Import Group Key';

  @override
  String get keychainImportSubtitle => 'Import using mnemonic or private key';

  @override
  String get keychainEnterLabelTitle => 'Enter Key Label';

  @override
  String get keychainImportLabelHint => 'Enter a label for this imported key';

  @override
  String get keychainDbMismatchTitle => 'Local Messages Exist';

  @override
  String keychainDbMismatchBody(String wallet) {
    return 'This device has cached messages for wallet $wallet... from a previous session, but the encryption key no longer matches.\n\nTo continue importing, local messages for this key will be erased. Messages on the XMTP network are not affected.';
  }

  @override
  String get keychainEraseContinue => 'Erase & Continue';

  @override
  String get keychainInstallCapTitle => 'Device Limit Reached';

  @override
  String keychainInstallCapBody(String wallet) {
    return 'This key already has 10 registered XMTP devices — the protocol maximum. To use it here, older device registrations must be revoked first.\n\nWallet: $wallet...';
  }

  @override
  String get keychainInstallCapRevokeAll => 'Revoke all other devices';

  @override
  String get keychainInstallCapRevokeAllDetail =>
      'Quick recovery: ALL existing registrations of this key are revoked and the import retries. Every other device or app using this key stops sending and receiving until you sign in there again.';

  @override
  String get keychainInstallCapSelective =>
      'Revoke selectively on another device';

  @override
  String get keychainInstallCapSelectiveDetail =>
      'Open the app on another device where this key still works, go to Manage Inbox IDs, and revoke individual devices there. Then retry the import here.';

  @override
  String get keychainInstallCapConfirmTitle => 'Revoke all other devices?';

  @override
  String get keychainInstallCapConfirmBody =>
      'This signs a revocation for every other registration of this key and cannot be undone. Continue?';

  @override
  String keychainInstallCapRevokeFailed(String error) {
    return 'Could not revoke the other devices: $error';
  }

  @override
  String get keychainSetupHint =>
      'Loading a key you already used on another device, and you have its message backup? Restore it here. If this key is new, there is nothing to restore — start fresh.';

  @override
  String get keychainOfferRegTitle => 'PUBLISH THIS INBOX?';

  @override
  String keychainOfferRegBody(String id) {
    return 'This key is active and has an inbox ID ($id). Publish it as a tab on your profile so people can message you.';
  }

  @override
  String get keychainOfferRegLabel => 'Tab name';

  @override
  String get keychainOfferRegDontAsk => 'Don\'t ask again';

  @override
  String get keychainOfferRegPublish => 'PUBLISH';

  @override
  String get keychainOfferRegLater => 'NOT NOW';

  @override
  String get appSettingsPageInboxPromptTitle => 'Offer to publish new inboxes';

  @override
  String get appSettingsPageInboxPromptSubtitle =>
      'After a key is activated, ask whether to publish its inbox ID as a profile tab.';

  @override
  String get keychainSetupTitle => 'Set up messaging on this device';

  @override
  String get keychainSetupBody =>
      'This key has no message database on this device yet. Choose how to set it up:';

  @override
  String get keychainSetupCreateFresh => 'Start fresh';

  @override
  String get keychainSetupCreateFreshDetail =>
      'Register this device with the key and start a new, empty message history. Uses one of the key\'s 10 device slots.';

  @override
  String get keychainSetupRestore => 'Restore a backup';

  @override
  String get keychainSetupRestoreDetail =>
      'Load a database file you downloaded from another device, together with its encryption key. Keeps your message history and does not use a device slot.';

  @override
  String get keychainRestoreTitle => 'Restore database backup';

  @override
  String get keychainRestoreFileTypeLabel => 'XMTP database';

  @override
  String get keychainRestoreKeyPrompt =>
      'Paste the database encryption key from the device you made the backup on.';

  @override
  String get keychainRestoreKeyHint => 'Encryption key';

  @override
  String get keychainRestoreFailedTitle => 'Restore failed';

  @override
  String keychainClientReloaded(String label) {
    return 'Client reloaded with key \"$label\"';
  }

  @override
  String get keychainInboxAlreadyReg => 'This Inbox ID is already registered';

  @override
  String get keychainRegInboxTitle => 'Register Current Inbox ID';

  @override
  String keychainRegInboxPrompt(String id) {
    return 'Enter a label for this Inbox ID: $id';
  }

  @override
  String get keychainLabelField => 'Label';

  @override
  String get keychainEnterLabelPlease => 'Please enter a label';

  @override
  String get keychainRegister => 'Register';

  @override
  String get keychainInboxRegOther =>
      'This inbox ID is already registered to another account';

  @override
  String get keychainInboxRegOk => 'Inbox ID registered successfully';

  @override
  String get keychainInboxRegFail => 'Failed to register inbox ID';

  @override
  String get keychainEditTitle => 'Edit Key Label';

  @override
  String get keychainEditHint => 'Enter a new label for this key';

  @override
  String get keychainSave => 'Save';

  @override
  String get keychainLabelUpdated => 'Key label updated successfully';

  @override
  String keychainWalletEnabled(String label) {
    return 'Wallet enabled for \"$label\"';
  }

  @override
  String keychainWalletDisabled(String label) {
    return 'Wallet disabled for \"$label\"';
  }

  @override
  String keychainWebKeySet(String name) {
    return 'Preferred key set to \"$name\"';
  }

  @override
  String get keychainSessionKey => 'Session Key';

  @override
  String keychainEmojiUpdated(String label) {
    return 'Emoji updated for \"$label\"';
  }

  @override
  String keychainCopyTooltip(String label) {
    return 'Copy $label';
  }

  @override
  String get keychainNoKeys => 'No additional keys';

  @override
  String get keychainActivateHint =>
      'Tap the SIM icon on a key to use it for messaging.';

  @override
  String get keychainMyAccount => 'My Account';

  @override
  String get keychainSessionBadge => 'SESSION';

  @override
  String get keychainSessionKeyUnavail => 'Session key not available';

  @override
  String get keychainUnnamedKey => 'Unnamed Key';

  @override
  String get keychainUnknownAddr => 'Unknown';

  @override
  String get keychainToggleXmtpKey => 'Current XMTP key';

  @override
  String get keychainToggleXmtpSub =>
      'Use this key to send and receive encrypted messages. Only one key at a time can be active for messaging.';

  @override
  String get keychainToggleWebKey => 'Preferred key';

  @override
  String get keychainToggleWebSub =>
      'Sites that have no active key of their own see this one first — the account most dApps treat as you. It does not give any site access on its own; that is decided per site, where you can also pick a different active key.';

  @override
  String get keychainToggleWallet => 'Show in wallet list';

  @override
  String get keychainToggleWalletSub =>
      'Include this key in the Keychain filter of the Wallet tab, so you can send from it directly.';

  @override
  String get keychainActionEmoji => 'Change emoji';

  @override
  String get keychainActionEmojiSub =>
      'Pick a new icon to recognize this key at a glance.';

  @override
  String get keychainActionRename => 'Rename label';

  @override
  String get keychainActionRenameSub =>
      'The label is just a local nickname — the key and address stay the same.';

  @override
  String get keychainActionExport => 'Export private key';

  @override
  String get keychainActionExportSub =>
      'Reveal the raw hex so you can import this key in another client. Treat it like a password.';

  @override
  String get keychainActionDelete => 'Delete key';

  @override
  String get keychainActionDeleteSub =>
      'Permanently remove this key from this device. Make sure you have it backed up first.';

  @override
  String get importModePhrase => 'PHRASE';

  @override
  String get importModePrivateKey => 'PRIVATE KEY';

  @override
  String get importHintMnemonic => 'word1 word2 word3 word4 ...';

  @override
  String get importLabelMnemonic => 'Enter your 12 or 24-word recovery phrase';

  @override
  String get importLabelPrivateKey => 'Enter private key as hex string';

  @override
  String get importEnterMnemonic => 'Please enter a mnemonic phrase';

  @override
  String get importEnterPrivateKey => 'Please enter a private key';

  @override
  String get importImporting => 'IMPORTING...';

  @override
  String netPickHeader(String provider) {
    return 'PICK A $provider';
  }

  @override
  String get netPickBspTitle => 'Choose a Blockchain Service Provider';

  @override
  String get netPickSspTitle => 'Choose a Social Service Provider';

  @override
  String get netPickBspBody =>
      'Tap one. The next sheet confirms the subscription; as a private you can deposit your first months into your service balance in the same transaction.';

  @override
  String get netPickSspBody =>
      'Tap one. The next sheet confirms the subscription; as a private you can deposit your first months into your service balance in the same transaction.';

  @override
  String netNoProviders(String provider) {
    return 'No ${provider}s available in the registry.';
  }

  @override
  String netSwitchHeader(String provider) {
    return 'SWITCH $provider';
  }

  @override
  String netSubscribeHeader(String provider) {
    return 'SUBSCRIBE TO $provider';
  }

  @override
  String get netSwitching => 'SWITCHING…';

  @override
  String get netSubscribing => 'SUBSCRIBING…';

  @override
  String get netSwitch => 'SWITCH';

  @override
  String get netSubscribe => 'SUBSCRIBE';

  @override
  String get netProviderNotFound => 'Provider not found';

  @override
  String netSlugUnresolved(String slug, String provider) {
    return 'The slug \"$slug\" did not resolve to a registered $provider.';
  }

  @override
  String netProviderFee(String provider) {
    return '$provider fee';
  }

  @override
  String get netTotal => 'Total';

  @override
  String get netCalculating => 'Calculating…';

  @override
  String get netBalance => 'Balance';

  @override
  String get netFromWallet => 'From wallet';

  @override
  String netMainWallet(String addr) {
    return 'main · $addr';
  }

  @override
  String get netInsufficientPos => 'Insufficient OX balance for this deposit.';

  @override
  String get netGateWaived =>
      'This provider is still below its minimum subscribers, so nothing is drawn from your balance until it gets there. What you deposit stays yours — withdraw it any time from Services.';

  @override
  String get netServerRulesTitle => 'This server\'s rules';

  @override
  String get netServerPrivacyTitle => 'Privacy';

  @override
  String netServerRulesVersion(Object version, Object date) {
    return 'Version $version · from $date';
  }

  @override
  String get netServerRulesAccept =>
      'Subscribing means you read and accept the protocol agreement and this server\'s rules.';

  @override
  String get netServerRulesMissing =>
      'This server has not published its rules. You can still subscribe.';

  @override
  String get netServerRulesUnreachable =>
      'This server\'s rules could not be loaded right now. You can still subscribe.';

  @override
  String get netServerRulesAcceptButton => 'Accept and subscribe';

  @override
  String get netServerRulesSubscribeAnyway => 'Subscribe anyway';

  @override
  String get netNoSession => 'No active session';

  @override
  String get netRunBy => 'Run by';

  @override
  String get netMonths => 'Months';

  @override
  String get netCardUrl => 'URL';

  @override
  String get netCardRunBy => 'RUN BY';

  @override
  String get netCardSubs => 'SUBS';

  @override
  String netSubsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscribers',
      one: '1 subscriber',
    );
    return '$_temp0';
  }

  @override
  String netExplainCitizenSwitch(String provider) {
    return 'This switches your assigned $provider, effective now. You don\'t pay anything — the network mints the $provider fee on your behalf while you use the app.';
  }

  @override
  String netExplainCitizenSubscribe(String provider) {
    return 'This sets your assigned $provider. Citizens don\'t pay; the network mints the $provider fee on your behalf while you use the app.';
  }

  @override
  String netExplainPrivateSwitch(String provider) {
    return 'This switches you to a new $provider, effective now — the old one is paid to the second, nothing is stranded. The fee keeps drawing from your one service balance; the months below are an optional top-up.';
  }

  @override
  String netExplainPrivateSubscribe(String provider) {
    return 'This subscribes you to this $provider. The fee accrues by the second and is drawn from your service balance only while the provider has enough subscribers to be paid; the months below are deposited into that balance now and are yours to withdraw while unspent.';
  }

  @override
  String get walletAddressCopied => 'Address copied to clipboard';

  @override
  String get walletSettingsTitle => 'Wallet settings';

  @override
  String get walletManagerLabel => 'WALLET MANAGER';

  @override
  String get walletSelectManagerTitle => 'Select wallet manager';

  @override
  String get walletNoManagerApps =>
      'No wallet manager apps bookmarked.\nBookmark an app with the \"wallet_manager\" category to use it here.';

  @override
  String get walletEditLabel => 'Edit label';

  @override
  String get walletEditIcon => 'Edit icon';

  @override
  String get walletActivityTitle => 'Activity';

  @override
  String get walletActivityEmpty =>
      'No transactions yet.\nRecent OX transfers will appear here.';

  @override
  String get walletActivityTxCopied => 'Transaction hash copied';

  @override
  String get walletActivitySentTo => 'Sent to';

  @override
  String get walletActivityReceivedFrom => 'Received from';

  @override
  String get walletRemoveWallet => 'Remove wallet';

  @override
  String get walletLabelHint => 'Wallet label';

  @override
  String get walletSave => 'Save';

  @override
  String get walletLabelUpdateFailed => 'Failed to update label';

  @override
  String get walletLabelUpdateSubmitted => 'Label update submitted';

  @override
  String get walletRemoveWalletConfirmTitle => 'Remove wallet?';

  @override
  String get walletRemoveWalletBodyNoLabel =>
      'This wallet will be removed from your directory.';

  @override
  String walletRemoveWalletBody(String label) {
    return '\"$label\" will be removed from your directory.';
  }

  @override
  String get walletRemove => 'Remove';

  @override
  String get walletRemoveFailed => 'Failed to remove wallet';

  @override
  String get walletRemoved => 'Wallet removed';

  @override
  String get walletChipLinked => 'Linked';

  @override
  String get walletChipGroup => 'Group';

  @override
  String get walletChipManageKeys => 'Manage Keys';

  @override
  String get walletChipSettings => 'Settings';

  @override
  String get walletEmptyTitle => 'No Wallets Found';

  @override
  String get walletEmptySubtitle => 'Your wallets will appear here.';

  @override
  String get walletLinkNewWallet => 'Link new wallet';

  @override
  String get walletBadgePrimary => 'PRIMARY';

  @override
  String get walletBadgeGroup => 'GROUP';

  @override
  String get walletBadgeKey => 'KEY';

  @override
  String get walletBadgeLinked => 'LINKED';

  @override
  String get walletUnlink => 'Unlink';

  @override
  String get walletActionSend => 'Send';

  @override
  String get walletActionCopy => 'Copy';

  @override
  String get walletActionManage => 'Manage';

  @override
  String get walletOwnerUnknown => 'Unknown';

  @override
  String get walletNoManagerSelected => 'No wallet manager selected';

  @override
  String get walletSelect => 'Select';

  @override
  String get walletChange => 'Change';

  @override
  String walletChainLinkingComingSoon(String chain) {
    return '$chain linking is coming soon.';
  }

  @override
  String get walletConnectHeader => 'Connect';

  @override
  String get walletLabelRequired => 'Label · required';

  @override
  String walletChainDetected(String chain) {
    return '$chain detected';
  }

  @override
  String get walletPickKeyError => 'Pick a wallet key to link.';

  @override
  String get walletNoActiveAccount => 'No active account.';

  @override
  String get walletLinked => 'Wallet linked';

  @override
  String get walletPasteProofError => 'Paste the proof from the signing page.';

  @override
  String get walletInvalidProofError =>
      'That doesn\'t look like a valid proof. Copy the whole “proof for PublicOS” from the signing page.';

  @override
  String get walletProofMissingWalletSig =>
      'Proof is missing the wallet or signature.';

  @override
  String get walletProofWrongAccount =>
      'This proof was signed for a different account. Re-sign for this account.';

  @override
  String get walletProofBadBase58 => 'Signature is not valid base58.';

  @override
  String get walletProofVerifyFailed =>
      'This proof didn\'t verify for your account. Make sure you signed for this account on the linking page.';

  @override
  String get walletSolanaLinked => 'Solana wallet linked';

  @override
  String get walletProofMissingFields =>
      'Proof is missing the wallet, signature, or deadline.';

  @override
  String get walletProofMalformed => 'Proof is malformed.';

  @override
  String get walletInvalidProofBundle =>
      'That doesn\'t look like a valid proof bundle.';

  @override
  String get walletProofNotEthereum =>
      'That proof is not an Ethereum wallet proof.';

  @override
  String get walletLinkWithoutLabelTitle => 'Link wallet without label?';

  @override
  String get walletLinkWithoutLabelBody =>
      'A label helps you tell this wallet apart from your others. You can still add one later.';

  @override
  String get walletLink => 'Link';

  @override
  String get walletLinkWalletTitle => 'Link Wallet';

  @override
  String get walletLinkExplainer =>
      'Linking publishes an on-chain pointer saying a wallet is yours. Others can then pick one of your accounts to send you funds, and what you hold can show on your profile: tokens, and the NFTs that are how the chain records property. It stays a pointer. The protocol never gains access to the wallet.';

  @override
  String get walletLabelOptional => 'LABEL (optional)';

  @override
  String get walletLabelExampleHint => 'e.g. Coinbase, Cold storage';

  @override
  String get walletLinkingAction => 'LINKING…';

  @override
  String get walletLinkWalletAction => 'LINK WALLET';

  @override
  String get walletSignOnBrowser => 'Sign on browser';

  @override
  String get walletHidePaste => 'Hide paste';

  @override
  String get walletPasteProof => 'Paste proof';

  @override
  String get walletPasteBundleHint =>
      'Paste the proof bundle from the signing page';

  @override
  String get walletLinking => 'Linking...';

  @override
  String get walletLinkPastedProof => 'Link pasted proof';

  @override
  String get walletNoKeychainKeys =>
      'No keychain keys to link here. Use \"Link with MetaMask\" above to link an external wallet, or add a key to your keychain first.';

  @override
  String get walletKeyLabel => 'WALLET KEY';

  @override
  String get walletKeyDefault => 'Key';

  @override
  String get walletPasteProofLabel => 'PASTE PROOF';

  @override
  String get walletPasteProofBundleHint =>
      'Paste the “proof for PublicOS” bundle';

  @override
  String get walletOpenPhantom => 'Open Phantom';

  @override
  String get walletLinkMetaMask => 'Link with MetaMask';

  @override
  String get walletOr => 'or';

  @override
  String get walletCouldNotOpenPhantom =>
      'Could not open Phantom. Is it installed?';

  @override
  String get walletDirectoryNotReady =>
      'Wallet directory not ready, try again.';

  @override
  String get walletCouldNotOpenLinkingPage => 'Could not open the linking page';

  @override
  String get walletCouldNotOpenMetaMask =>
      'Could not open MetaMask. Is it installed?';

  @override
  String walletChainComingSoonLong(String chain) {
    return '$chain linking is coming soon. The directory already supports it on chain — the in-app signing flow lands after EVM.';
  }

  @override
  String get acctSettingsSavingColor => 'Saving color...';

  @override
  String get acctSettingsRefreshingProfile => 'Refreshing profile...';

  @override
  String get acctSettingsSessionAddressLabel => 'Session address';

  @override
  String acctSettingsCopiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get acctSettingsRecoveryContacts => 'Recovery Contacts';

  @override
  String get acctSettingsDevices => 'Sessions';

  @override
  String get acctSettingsAccentColor => 'Accent Color';

  @override
  String get accentColorRecordNotice =>
      'Your accent color is a public profile record, kept on-chain. It tints your message bubbles and fills your profile cards, so anyone who can see your profile can see it.';

  @override
  String get accentColorBubbleNotice =>
      'Your message bubbles are painted in it exactly as you pick it. Text switches between black and white to stay readable.';

  @override
  String get accentColorPreviewSample => 'This is how your messages will look.';

  @override
  String get accentColorPreviewTime => '12:45';

  @override
  String get accentColorSave => 'SAVE COLOR';

  @override
  String get accentColorDiscard => 'DISCARD';

  @override
  String get accentColorSaved => 'Accent color saved';

  @override
  String get accentColorUnsaved => 'Unsaved';

  @override
  String get acctSettingsNoAccountSelected => 'No account selected';

  @override
  String get acctSettingsNoRecoveryContacts =>
      'No recovery contacts configured';

  @override
  String get acctSettingsAddTrustedContactsHint =>
      'Add trusted contacts who can help recover your account';

  @override
  String acctSettingsRecoveryThreshold(int threshold, int total) {
    return 'Recovery threshold: $threshold/$total contacts needed to approve recovery';
  }

  @override
  String get acctSettingsNoSessionsFound => 'No sessions found';

  @override
  String get acctSettingsSessionsDescShort =>
      'Sessions are wallet addresses authorized to control your account';

  @override
  String get acctSettingsSessionsInfoBanner =>
      'Sessions are keys that can act as your account. Each phone, computer or wallet you use holds its own.';

  @override
  String get acctSettingsCurrentBadge => 'CURRENT';

  @override
  String get acctSettingsThisDevice => 'This session';

  @override
  String get acctSettingsAuthorizedDevice => 'Session';

  @override
  String get acctSettingsCannotRemoveSession =>
      'Cannot remove - at least one session required';

  @override
  String get acctSettingsAddingConfirming => 'ADDING & CONFIRMING…';

  @override
  String get acctSettingsAddSession => 'ADD SESSION';

  @override
  String get acctSettingsAddNewSession => 'Add New Session';

  @override
  String get acctSettingsLinkNewDeviceTitle => 'Add a session';

  @override
  String get acctSettingsLinkNewDeviceBody =>
      'On the other phone or computer, open PublicOS, tap the QR button on the new key\'s card, choose ADD SESSION and sign. Then scan that QR with this camera; the confirm sheet opens by itself.';

  @override
  String get acctSettingsWhyQrTitle => 'Why a QR?';

  @override
  String get acctSettingsWhyQrBody =>
      'The new session proves it agreed to be added by signing an EIP-712 consent with its own key. The QR carries that signature here, so you can submit it from a session you already have.';

  @override
  String get acctSettingsRemoveSessionTitle => 'Remove Session';

  @override
  String get acctSettingsRemoveSessionConfirm =>
      'Are you sure you want to remove this session?';

  @override
  String get acctSettingsRemoveSessionWarning =>
      'This session will no longer be able to act as your account.';

  @override
  String get acctSettingsRemove => 'Remove';

  @override
  String get acctSettingsSessionRemoved =>
      'Session removed and confirmed on blockchain!';

  @override
  String get acctSettingsAddRecoveryContact => 'ADD RECOVERY CONTACT';

  @override
  String get acctSettingsRecoveryContactAdded =>
      'Recovery contact added and confirmed on blockchain!';

  @override
  String get acctSettingsRemoveRecoveryTitle => 'Remove Recovery Contact';

  @override
  String acctSettingsRemoveRecoveryConfirm(String address) {
    return 'Are you sure you want to remove this recovery contact?\n\nAddress: $address\n\nThey will no longer be able to help recover your account.';
  }

  @override
  String get acctSettingsRecoveryContactRemoved =>
      'Recovery contact removed and confirmed on blockchain!';

  @override
  String get acctSettingsAddRecoveryContactTitle => 'Add Recovery Contact';

  @override
  String get acctSettingsAddRecoveryIntro =>
      'You are about to add this contact as a recovery contact for your account:';

  @override
  String get acctSettingsRecoveryPermissionsTitle =>
      'Recovery Contact Permissions';

  @override
  String get acctSettingsRecoveryPermissionsBody =>
      'This contact will be able to:\nVote to add new session addresses to your account\nHelp you recover access if you lose your device\nCannot access your funds or messages directly';

  @override
  String get acctSettingsSelectRecoveryContact => 'Select Recovery Contact';

  @override
  String get acctSettingsChooseRecoveryContact => 'Choose a Recovery Contact';

  @override
  String get acctSettingsChooseRecoveryDesc =>
      'Select a trusted contact who can help you recover your account if you lose access. They will be able to vote on adding new session addresses to your account.';

  @override
  String get acctSettingsSearchContacts => 'Search contacts…';

  @override
  String get acctSettingsNoContactsAvailable => 'No contacts available';

  @override
  String get acctSettingsNoContactsFound => 'No contacts found';

  @override
  String get acctSettingsAddContactsFirst =>
      'Add some contacts first to set them as recovery contacts';

  @override
  String get acctSettingsErrorEnterAddress => 'Please enter an address';

  @override
  String get acctSettingsErrorInvalidAddress =>
      'Invalid Ethereum address format';

  @override
  String get acctSettingsErrorAddressAlreadySession =>
      'This address is already a session';

  @override
  String get acctSettingsWhatIsSessionTitle => 'What is a Session?';

  @override
  String get acctSettingsWhatIsSessionBody =>
      'A session is a wallet address authorized to control your account. Add a new session to use your account from another device or wallet.';

  @override
  String get acctSettingsEthereumAddressLabel => 'Ethereum Address';

  @override
  String get inboxIdsTitle => 'Inbox IDs';

  @override
  String get inboxIdsInboxesHeader => 'Inboxes';

  @override
  String get inboxIdsLoadError => 'Couldn\'t load inbox IDs';

  @override
  String get inboxIdsRetry => 'RETRY';

  @override
  String get inboxIdsEmptyTitle => 'No inbox IDs yet';

  @override
  String get inboxIdsEmptySubtitle =>
      'Create an XMTP key from the keychain to get started.';

  @override
  String get inboxIdsNoLocalKeyTitle => 'No local key on this device';

  @override
  String get inboxIdsNoLocalKeyBody =>
      'This inbox is registered on your account but no private key for it lives on this device, so we can\'t load identities or installations. Import the key from another device (keychain or mnemonic) to manage it here.';

  @override
  String get inboxIdsLinkedAccounts => 'Linked accounts';

  @override
  String get inboxIdsInstallations => 'Installations';

  @override
  String get inboxIdsQuickActions => 'Quick actions';

  @override
  String get inboxIdsRecoveryBadge => 'RECOVERY';

  @override
  String get inboxIdsThisDeviceBadge => 'THIS DEVICE';

  @override
  String get inboxIdsEthereumWallet => 'Ethereum wallet';

  @override
  String get inboxIdsPasskey => 'Passkey';

  @override
  String get inboxIdsUnknown => 'Unknown';

  @override
  String inboxIdsDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String inboxIdsHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String inboxIdsMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String inboxIdsCreatedAgo(String time) {
    return 'Created $time';
  }

  @override
  String get inboxIdsRegisterTitle => 'Register Inbox ID';

  @override
  String get inboxIdsRegisterSubtitle =>
      'Register this inbox to your on-chain profile.';

  @override
  String get inboxIdsEditLabelTitle => 'Edit label';

  @override
  String get inboxIdsEditLabelSubtitle =>
      'Rename this inbox in your on-chain profile.';

  @override
  String get inboxTabNoneYet => 'No public inbox yet';

  @override
  String get inboxTabOtherOwner =>
      'This inbox is already registered to another account.';

  @override
  String get inboxTabSaveFailed =>
      'Could not save. Nothing was written to the chain.';

  @override
  String inboxTabDuplicate(String name) {
    return 'You already have a tab named $name';
  }

  @override
  String inboxTabMore(int count) {
    return '+$count more';
  }

  @override
  String get inboxIdsRemoveTooltip => 'Remove tab';

  @override
  String get inboxIdsAddTooltip => 'Add tab';

  @override
  String get inboxIdsLabelHint => 'main, work, …';

  @override
  String get inboxIdsSave => 'SAVE';

  @override
  String get inboxIdsContinue => 'CONTINUE';

  @override
  String get inboxIdsRemoveTitle => 'Remove inbox ID?';

  @override
  String inboxIdsRemoveBody(String name) {
    return 'Remove \"$name\" from your on-chain profile. Other users will no longer see this inbox listed on your account.';
  }

  @override
  String get inboxIdsRemoveAction => 'REMOVE';

  @override
  String get inboxIdsRevokeInstallationTitle => 'Revoke this installation?';

  @override
  String inboxIdsRevokeInstallationBody(String id) {
    return 'This device will lose access to messages under this inbox.\n\n$id';
  }

  @override
  String get inboxIdsRevokeAction => 'REVOKE';

  @override
  String get inboxIdsRevokeAllTitle => 'Revoke all other installations?';

  @override
  String inboxIdsRevokeAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will revoke access for $count other devices. Those devices will need to re-authenticate to regain access.',
      one:
          'This will revoke access for 1 other device. Those devices will need to re-authenticate to regain access.',
    );
    return '$_temp0';
  }

  @override
  String get inboxIdsRevokeAllAction => 'REVOKE ALL';

  @override
  String get inboxIdsRemoveAccountTitle => 'Remove account from inbox?';

  @override
  String inboxIdsRemoveAccountBody(String id) {
    return 'This removes the account from your inbox.\n\n$id';
  }

  @override
  String get inboxIdsOfflineRecovery => 'Offline recovery';

  @override
  String get inboxIdsOfflineRecoveryBody =>
      'This revokes ALL installations for this inbox without needing an active XMTP client. Use when you\'re locked out due to too many installations (limit: 10).\n\nYou\'ll need to provide your recovery key.';

  @override
  String get inboxIdsConfirmRecoveryTitle => 'Confirm recovery';

  @override
  String inboxIdsConfirmRecoveryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Found $count installations. All installations will be revoked. You will need to re-authenticate on any device you want to use.',
      one:
          'Found 1 installation. All installations will be revoked. You will need to re-authenticate on any device you want to use.',
    );
    return '$_temp0';
  }

  @override
  String inboxIdsRevokingInstallations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revoking $count installations…',
      one: 'Revoking 1 installation…',
    );
    return '$_temp0';
  }

  @override
  String inboxIdsRevokedInstallations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revoked $count installations',
      one: 'Revoked 1 installation',
    );
    return '$_temp0';
  }

  @override
  String get inboxIdsKeyAlreadyLinkedTitle => 'Key already linked';

  @override
  String get inboxIdsKeyAlreadyLinkedBodyKeychain =>
      'This key is already linked to another XMTP inbox. If you proceed, it will be moved to your current inbox and you may lose access to the previous inbox unless you have another key linked to it.';

  @override
  String get inboxIdsProceedAnyway => 'PROCEED ANYWAY';

  @override
  String get inboxIdsKeyAlreadyLinkedBodyImport =>
      'This key is already linked to another XMTP inbox. Proceeding will move it to your current inbox and you may lose access to the previous inbox.';

  @override
  String get inboxIdsProceed => 'PROCEED';

  @override
  String get inboxIdsSelectRecoveryKey => 'SELECT RECOVERY KEY';

  @override
  String get inboxIdsSelectKeyToLink => 'SELECT KEY TO LINK';

  @override
  String get inboxIdsSelectKey => 'SELECT KEY';

  @override
  String inboxIdsKeyPickerSubtitle(String purpose) {
    return 'Multiple keys found. Select one to use for $purpose.';
  }

  @override
  String get inboxIdsPurposeRevokeInstallation => 'revoking installation';

  @override
  String get inboxIdsPurposeRevokeAllOthers =>
      'revoking all other installations';

  @override
  String get inboxIdsRecoveryKeyDialogTitle => 'RECOVERY KEY';

  @override
  String get inboxIdsRecoveryKeyDialogSubtitle =>
      'How would you like to provide the recovery key?';

  @override
  String get inboxIdsMethodPickKeychainTitle => 'Pick from keychain';

  @override
  String get inboxIdsMethodPickKeychainSubtitleShort =>
      'Select an existing key';

  @override
  String get inboxIdsMethodPickKeychainSubtitleLong =>
      'Select an existing key from your keychain';

  @override
  String get inboxIdsEnterPrivateKey => 'Enter private key';

  @override
  String get inboxIdsEnterMnemonic => 'Enter mnemonic';

  @override
  String get inboxIdsHintPrivateKey => '0x…';

  @override
  String get inboxIdsHintMnemonic => 'word1 word2 word3 …';

  @override
  String get inboxIdsMethodPrivateKeySubtitle => 'Hex-encoded private key';

  @override
  String get inboxIdsMethodMnemonicSubtitle => '12 or 24 word recovery phrase';

  @override
  String get inboxIdsAddAccountTitle => 'ADD ACCOUNT';

  @override
  String get inboxIdsAddAccountSubtitle =>
      'Link an additional wallet to this inbox.';

  @override
  String get inboxIdsMethodImportKeyTitle => 'Import key';

  @override
  String get inboxIdsMethodImportKeySubtitle =>
      'Import from mnemonic or private key';

  @override
  String get inboxIdsImportKeyTitle => 'IMPORT KEY';

  @override
  String get inboxIdsMethodMnemonicPhraseTitle => 'Mnemonic phrase';

  @override
  String get inboxIdsMethodPrivateKeyOptTitle => 'Private key';

  @override
  String get inboxIdsActionRegisterToProfile => 'Register to profile';

  @override
  String get inboxIdsActionRenameLabel => 'Rename label';

  @override
  String get inboxIdsActionAddAccount => 'Add account';

  @override
  String get inboxIdsActionSyncing => 'Syncing…';

  @override
  String get inboxIdsActionSyncConsent => 'Sync consent';

  @override
  String get inboxIdsActionRequesting => 'Requesting…';

  @override
  String get inboxIdsActionRequestHistory => 'Request history';

  @override
  String get inboxIdsActionRevokeAllOthers => 'Revoke all others';

  @override
  String get inboxIdsActionRevoking => 'Revoking…';

  @override
  String get inboxIdsInboxIdCopied => 'Inbox ID copied';

  @override
  String get inboxIdsAddressCopied => 'Address copied';

  @override
  String get inboxIdsInstallationIdCopied => 'Installation ID copied';

  @override
  String get inboxIdsNoMatchingKeys => 'No matching keys found in keychain';

  @override
  String get inboxIdsRegistered => 'Inbox ID registered';

  @override
  String get inboxIdsRegisterFailed => 'Failed to register inbox ID';

  @override
  String get inboxIdsLabelUpdated => 'Label updated';

  @override
  String get inboxIdsLabelUpdateFailed => 'Failed to update label';

  @override
  String get inboxIdsRemoved => 'Inbox ID removed';

  @override
  String get inboxIdsRemoveFailed => 'Failed to remove inbox ID';

  @override
  String get inboxIdsConsentSynced => 'Consent preferences synced';

  @override
  String get inboxIdsConsentSyncFailed => 'Failed to sync consent preferences';

  @override
  String get inboxIdsHistorySyncRequested =>
      'History sync requested — other devices must be online to respond';

  @override
  String get inboxIdsHistorySyncFailed => 'Failed to send history sync request';

  @override
  String get inboxIdsNoSigningKey => 'No signing key found for this inbox';

  @override
  String get inboxIdsInstallationRevoked => 'Installation revoked';

  @override
  String get inboxIdsInstallationRevokeFailed =>
      'Failed to revoke installation';

  @override
  String get inboxIdsAllOthersRevoked => 'All other installations revoked';

  @override
  String get inboxIdsRevokeInstallationsFailed =>
      'Failed to revoke installations';

  @override
  String get inboxIdsRecoveryKeyNotFound =>
      'Recovery key not found in keychain';

  @override
  String get inboxIdsAccountRemoved => 'Account removed';

  @override
  String get inboxIdsAccountRemoveFailed => 'Failed to remove account';

  @override
  String get inboxIdsNoKeysInKeychain => 'No keys in keychain';

  @override
  String get inboxIdsInvalidKeyFormat => 'Invalid key format';

  @override
  String get inboxIdsQueryingInboxState => 'Querying inbox state…';

  @override
  String get inboxIdsInboxNotFound => 'Inbox not found';

  @override
  String get inboxIdsNoInstallationsToRevoke => 'No installations to revoke';

  @override
  String get inboxIdsUserAddressUnavailable => 'User address not available';

  @override
  String get inboxIdsNoAvailableKeys => 'No available keys in keychain';

  @override
  String get inboxIdsAccountAdded => 'Account added';

  @override
  String get inboxIdsAccountAddFailed => 'Failed to add account';

  @override
  String get inboxIdsErrorInvalidKeyFormat => 'Error: invalid key format';

  @override
  String get postCardTranslating => 'Translating…';

  @override
  String get postCardWaitingForWifi => 'Waiting for Wi-Fi…';

  @override
  String get postCardDownloadingLanguage => 'Downloading language…';

  @override
  String get postCardDownloadLangPackTitle => 'Download language pack?';

  @override
  String postCardDownloadLangPackBody(String from, String to) {
    return 'Translating $from → $to needs an offline language pack (~30 MB each, downloaded once, then fully on-device).';
  }

  @override
  String get postCardDownload => 'Download';

  @override
  String postCardTranslateFrom(String lang) {
    return 'Translate from $lang';
  }

  @override
  String postCardTranslatedFromShowOriginal(String lang) {
    return 'Translated from $lang · Show original';
  }

  @override
  String postCardShowTranslation(String lang) {
    return 'Show translation ($lang)';
  }

  @override
  String get postCardOpenLink => 'Open link';

  @override
  String get postCardEdited => 'edited';

  @override
  String get postCardVia => 'via';

  @override
  String get postCardEditPost => 'Edit post';

  @override
  String get postCardRemoveFromChannel => 'Remove from channel';

  @override
  String get postCardDeletePost => 'Delete post';

  @override
  String get postCardUnlockComments => 'Unlock comments';

  @override
  String get postCardLockComments => 'Lock comments';

  @override
  String get postCardCommentRules => 'Comment rules';

  @override
  String get postCardCopyLink => 'Copy link';

  @override
  String get postCardRefreshPost => 'Refresh';

  @override
  String get postsListPostRefreshed => 'Post refreshed';

  @override
  String get postsListPostRefreshFailed => 'Couldn\'t refresh this post';

  @override
  String get postCardNoLongerAvailable =>
      'No longer available on the server — your saved copy may be the only one left';

  @override
  String get postCardRemoveFeedFromList => 'Remove feed from list';

  @override
  String get postCardMuteChannel => 'Mute channel';

  @override
  String get postCardViewSource => 'View source';

  @override
  String get postCardNoShareLink => 'No share link available for this post yet';

  @override
  String get postCardLinkCopied => 'Link copied';

  @override
  String postCardCouldNotOpenLink(String link) {
    return 'Could not open link: $link';
  }

  @override
  String get postCardCannotLockMissingSlug =>
      'Cannot lock comments: missing channel slug';

  @override
  String get postCardCommentsUnlocked => 'Comments unlocked';

  @override
  String get postCardCommentsLocked => 'Comments locked';

  @override
  String postCardUpdateFailed(String message) {
    return 'Failed: $message';
  }

  @override
  String get postCardUnknownError => 'Unknown error';

  @override
  String get postCardMissingChannelInfo => 'This post is missing channel info';

  @override
  String get postCardThisFeed => 'this feed';

  @override
  String get postCardRemoveFeedTitle => 'Remove Feed from List';

  @override
  String postCardRemoveFeedBody(String feedTitle) {
    return 'Remove \"$feedTitle\" from this list?\n\nAll posts from this feed will be removed from the list view.';
  }

  @override
  String get postCardRemove => 'Remove';

  @override
  String get postCardRemoveFromChannelTitle => 'Remove from channel?';

  @override
  String get postCardDeletePostTitle => 'Delete post?';

  @override
  String postCardDeleteBodyModeration(String channel) {
    return 'This removes the post and all comments under it from #$channel. The author will lose their post. Cannot be undone.';
  }

  @override
  String get postCardDeleteBody =>
      'This removes the post and all comments under it. Cannot be undone.';

  @override
  String get postCardThisChannel => 'this channel';

  @override
  String get postCardDelete => 'Delete';

  @override
  String get postCardCannotDeleteMissingSlug =>
      'Cannot delete post: missing channel slug';

  @override
  String get postCardPostDeleted => 'Post deleted successfully';

  @override
  String postCardDeleteFailed(String message) {
    return 'Failed to delete post: $message';
  }

  @override
  String get accountCenterTitle => 'Account';

  @override
  String get accountCenterSessionRemoved => 'Session removed';

  @override
  String get accountCenterAddNewSession => 'Add New Session';

  @override
  String get accountCenterLinkNewDeviceTitle => 'Add a session';

  @override
  String get accountCenterLinkNewDeviceBody =>
      'On the other phone or computer, open PublicOS, tap the QR button on the new key\'s card, choose ADD SESSION and sign. Then scan that QR with this camera; the confirm sheet opens by itself.';

  @override
  String get accountCenterWhyQrTitle => 'Why a QR?';

  @override
  String get accountCenterWhyQrBody =>
      'The new session proves it agreed to be added by signing an EIP-712 consent with its own key. The QR carries that signature here, so you can submit it from a session you already have.';

  @override
  String get accountCenterRemoveSessionTitle => 'Remove Session';

  @override
  String get accountCenterRemoveSessionConfirm =>
      'Are you sure you want to remove this session?';

  @override
  String get accountCenterRemoveSessionWarning =>
      'This session will no longer be able to act as your account.';

  @override
  String get accountCenterRemove => 'Remove';

  @override
  String get accountCenterNoAccountAddress => 'No account address found';

  @override
  String get accountCenterRecoveryStatusError =>
      'Could not check recovery status';

  @override
  String get accountCenterStartRecoveryTitle => 'Start Recovery';

  @override
  String get accountCenterScanRecoveryQrTitle => 'Scan their recovery QR';

  @override
  String get accountCenterScanRecoveryQrBody =>
      'Ask the person to open PublicOS on their new phone or computer and show the QR of a new key (the same code used to add a session). Scan it with your camera. If you are one of their recovery contacts, you can start the vote that gives their account that new session.';

  @override
  String get accountCenterRecoveryVoteStarted => 'Recovery vote started';

  @override
  String get accountCenterVotedApprove => 'Voted to approve recovery';

  @override
  String get accountCenterVotedReject => 'Voted to reject recovery';

  @override
  String get accountCenterExpired => 'Expired';

  @override
  String accountCenterRemainingDays(int days, int hours) {
    return '${days}d ${hours}h remaining';
  }

  @override
  String accountCenterRemainingHours(int hours, int minutes) {
    return '${hours}h ${minutes}m remaining';
  }

  @override
  String accountCenterRemainingMinutes(int minutes) {
    return '${minutes}m remaining';
  }

  @override
  String get accountCenterUnknown => 'Unknown';

  @override
  String get accountCenterStatusLifetime => 'LIFETIME';

  @override
  String get accountCenterStatusActive => 'ACTIVE';

  @override
  String get accountCenterStatusNotSet => 'NOT SET';

  @override
  String get accountCenterStatusOverdue => 'OVERDUE';

  @override
  String get accountCenterNever => 'Never';

  @override
  String get accountCenterNone => 'None';

  @override
  String get accountCenterDomain => 'Domain';

  @override
  String get accountCenterAddressCopied => 'Address copied';

  @override
  String get accountCenterCitizen => 'CITIZEN';

  @override
  String get citizenClaimTitle => 'You\'re eligible for citizenship!';

  @override
  String get citizenClaimLead =>
      'Enough citizens vouched for you. Read the citizen agreement to the end; accepting it is what makes you a citizen.';

  @override
  String citizenClaimVersion(String version) {
    return 'Citizen agreement · version $version';
  }

  @override
  String get citizenClaimScrollHint => 'Scroll to the end to accept';

  @override
  String get citizenClaimAccept => 'ACCEPT AND CLAIM';

  @override
  String get citizenClaimClaiming => 'CLAIMING';

  @override
  String get citizenClaimDoneTitle => 'You are a citizen';

  @override
  String get citizenClaimDoneBody =>
      'Your domain name is free for life, you have a seat and a vote in the PublicOS org, and you can vouch for people you know in person.';

  @override
  String get citizenClaimContinue => 'CONTINUE';

  @override
  String get citizenClaimFailed => 'The claim did not go through.';

  @override
  String get citizenClaimRetry => 'TRY AGAIN';

  @override
  String get citizenClaimNeedsPermanentKey =>
      'Claiming needs a permanent key. This session expires; open PublicOS with your main key and claim there.';

  @override
  String get citizenClaimLoadFailed =>
      'The agreement could not be loaded. Check your connection and try again.';

  @override
  String get citizenClaimNothingPublished =>
      'No citizen agreement is published yet. Try again later.';

  @override
  String get protocolAgreementTitle => 'The PublicOS agreement';

  @override
  String get protocolAgreementLead =>
      'Your new account accepts this agreement: your new key signs it when the account is made. Read it to the end.';

  @override
  String protocolAgreementVersion(String version) {
    return 'Protocol agreement · version $version';
  }

  @override
  String get protocolAgreementScrollHint => 'Scroll to the end to accept';

  @override
  String get protocolAgreementAccept => 'ACCEPT AND CONTINUE';

  @override
  String get protocolAgreementLoadFailed =>
      'The agreement could not be loaded. Check your connection and try again.';

  @override
  String get noticeServicesRow => 'Send SSP notice';

  @override
  String get noticeTitle => 'Send SSP notice';

  @override
  String get noticeSearchHint => 'Search an SSP by name or address';

  @override
  String get noticeNoResults => 'No SSP matches.';

  @override
  String get noticeLoadFailed => 'The SSP list could not be loaded.';

  @override
  String get noticeNoKey => 'This SSP does not take notices yet.';

  @override
  String get noticeChange => 'CHANGE';

  @override
  String get noticeTypeLabel => 'What is it about?';

  @override
  String get noticeTypeTakedown => 'Takedown';

  @override
  String get noticeTypeLawfulOrder => 'Lawful order';

  @override
  String get noticeTypeIpClaim => 'IP claim';

  @override
  String get noticeTypeAppeal => 'Appeal';

  @override
  String get noticeTypeAbuseReport => 'Abuse report';

  @override
  String get noticeTypePrivacy => 'Privacy';

  @override
  String get noticeTypeIntimateImage => 'Intimate image';

  @override
  String get noticeTypeChildSafety => 'Child safety';

  @override
  String get noticeAboutHint => 'Link to the post or page (optional)';

  @override
  String get noticeTextHint => 'Write your notice';

  @override
  String get noticeOnChainNote =>
      'Filed on chain as public evidence: your address will be visible. The letter itself stays encrypted.';

  @override
  String get noticeOffChainNote =>
      'Kept off chain: only the SSP operator can read it.';

  @override
  String get noticeSend => 'SEND';

  @override
  String get noticeSending => 'SENDING';

  @override
  String get noticeSentTitle => 'Notice sent';

  @override
  String noticeSentBody(String ssp) {
    return '$ssp received it.';
  }

  @override
  String noticeSentOnChain(String id) {
    return 'Filed on chain as notice #$id.';
  }

  @override
  String get noticeFailed => 'The notice could not be sent.';

  @override
  String get noticeDone => 'DONE';

  @override
  String get chsSubOtherChannels => 'From other channels';

  @override
  String get chsAllowQuotes => 'Quotes';

  @override
  String get chsAllowQuotesSub =>
      'Others can quote these posts in their own channels.';

  @override
  String get chsAllowReposts => 'Reposts';

  @override
  String get chsAllowRepostsSub => 'Others can repost them to their channels.';

  @override
  String get chsAllowReplies => 'Replies';

  @override
  String get chsAllowRepliesSub =>
      'Others can answer with a post in their own channel.';

  @override
  String get accountCenterClaimCitizenship => 'CLAIM CITIZENSHIP';

  @override
  String get accountCenterRenounceSection => 'Leave citizenship';

  @override
  String get accountCenterRenounceBody =>
      'You can give up citizenship at any time. It is immediate and cannot be undone. The vouches you gave, and your word for those people, stay.';

  @override
  String get accountCenterRenounceButton => 'RENOUNCE CITIZENSHIP';

  @override
  String get renounceDlg1Title => 'Renounce citizenship?';

  @override
  String get renounceDlg1Lead =>
      'Read this first. All of it happens in one step, the moment it lands:';

  @override
  String get renounceCostName =>
      'Your domain name stops being free now. Pay it to keep using the account.';

  @override
  String get renounceCostShare =>
      'Your unclaimed share is forfeited. Claim it first, in Services.';

  @override
  String get renounceCostSubs =>
      'Unsettled subscriptions bill you as a private. Settle them first.';

  @override
  String get renounceCostGraph =>
      'You leave the social graph: the vouches you received are cleared. Coming back needs new vouches.';

  @override
  String get renounceCostSeat => 'Your seat and vote in the PublicOS org end.';

  @override
  String get renounceCostVouches =>
      'The vouches you gave stay, and so does your word for those people.';

  @override
  String renounceWait(String seconds) {
    return 'RENOUNCE · $seconds';
  }

  @override
  String get renounceDlg1Confirm => 'RENOUNCE';

  @override
  String get renounceKeep => 'KEEP CITIZENSHIP';

  @override
  String get renounceDlg2Title => 'Last step';

  @override
  String get renounceDlg2Body =>
      'This is the one that does it. There is no undo and no grace.';

  @override
  String get renounceDlg2Confirm => 'RENOUNCE CITIZENSHIP NOW';

  @override
  String vouchDlg1Title(String name) {
    return 'Vouch for $name?';
  }

  @override
  String get vouchDlg1Lead =>
      'This is the most important thing you do on PublicOS. Read all of it:';

  @override
  String vouchPointInPerson(String name) {
    return 'You declare that you know $name in person: a real, living person of legal age whose name you can say.';
  }

  @override
  String get vouchPointOneAccount =>
      'To your knowledge, they hold no other citizen account.';

  @override
  String get vouchPointTrust =>
      'Your rights as a citizen rest on the trust of the people who vouched for you. This vouch passes that trust on.';

  @override
  String get vouchPointFinal => 'A vouch can\'t be taken back.';

  @override
  String get vouchPointCharacter =>
      'It says nothing about their character, and you are not responsible for what they do.';

  @override
  String get vouchPointIdentify =>
      'If a lawful order requires it, you will say what you know about who they are.';

  @override
  String get vouchPointConsequence =>
      'A false vouch costs your citizenship, and root may suspend your account. It is recorded on chain, where anyone can see it.';

  @override
  String vouchWait(String seconds) {
    return 'CONTINUE · $seconds';
  }

  @override
  String get vouchDlg1Confirm => 'CONTINUE';

  @override
  String get vouchCancel => 'CANCEL';

  @override
  String get vouchDlg2Title => 'Last step';

  @override
  String vouchDlg2Body(String name) {
    return 'You are giving your word that $name is a real person you know. There is no undo.';
  }

  @override
  String get vouchDlg2Cancel => 'DON\'T VOUCH';

  @override
  String get vouchDlg2Confirm => 'VOUCH NOW';

  @override
  String get renounceWorking => 'Renouncing citizenship…';

  @override
  String get renounceDone => 'You are no longer a citizen.';

  @override
  String get renounceFailed => 'The renounce did not go through.';

  @override
  String get renounceNeedsPermanentKey =>
      'Renouncing needs a permanent key. This session expires; use your main key.';

  @override
  String get accountCenterDomainStatus => 'Domain status';

  @override
  String get accountCenterPaidUntil => 'Paid until';

  @override
  String get accountCenterFreeNameChanges => 'Free Name Changes';

  @override
  String get accountCenterManageDomain => 'MANAGE DOMAIN';

  @override
  String get accountCenterDevices => 'Sessions';

  @override
  String get accountCenterSessionsInfo =>
      'Sessions are wallet addresses that can act on behalf of your account.';

  @override
  String get accountCenterCurrent => 'CURRENT';

  @override
  String get accountCenterAdding => 'ADDING...';

  @override
  String get accountCenterAddSession => 'ADD SESSION';

  @override
  String get accountCenterHelpFriendRecover => 'Help a Friend Recover';

  @override
  String get accountCenterRecoveryInfo =>
      'If a friend loses access to their account and you\'re one of their recovery contacts, you can help them regain control.';

  @override
  String get accountCenterSelectFriend => 'SELECT FRIEND';

  @override
  String get accountCenterCheckingRecoveryStatus =>
      'Checking recovery status...';

  @override
  String get accountCenterRetry => 'RETRY';

  @override
  String get accountCenterChange => 'CHANGE';

  @override
  String get accountCenterNotRecoveryContact =>
      'You\'re not a recovery contact for this account';

  @override
  String get accountCenterChangeFriend => 'CHANGE FRIEND';

  @override
  String get accountCenterActiveVote => 'ACTIVE VOTE';

  @override
  String get accountCenterProposed => 'Proposed';

  @override
  String get accountCenterVotes => 'Votes';

  @override
  String accountCenterVotesValue(int add, int cancel, int threshold) {
    return '$add approve / $cancel reject (need $threshold)';
  }

  @override
  String get accountCenterExpires => 'Expires';

  @override
  String get accountCenterSessionExpired => 'This session has expired';

  @override
  String get accountCenterVoting => 'VOTING...';

  @override
  String get accountCenterApprove => 'APPROVE';

  @override
  String get accountCenterReject => 'REJECT';

  @override
  String get accountCenterTrusted => 'TRUSTED';

  @override
  String get accountCenterThreshold => 'Threshold';

  @override
  String accountCenterThresholdValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes needed',
      one: '1 vote needed',
    );
    return '$_temp0';
  }

  @override
  String get accountCenterNoActiveSession => 'No active recovery session';

  @override
  String get accountCenterStarting => 'STARTING...';

  @override
  String get accountCenterStartRecoveryAction => 'START RECOVERY';

  @override
  String get accountCenterCreateAccountInvite => 'Create Account with Invite';

  @override
  String get accountCenterInviteSeasonHave =>
      'Invite season is on. Scan a friend\'s \"New Account\" QR code with your camera to onboard them — it spends one invite.';

  @override
  String get accountCenterInviteSeasonNone =>
      'Invite season is on. You have no invites left. Wait for the next wave to onboard new accounts.';

  @override
  String accountCenterInvitesLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'invites left',
      one: 'invite left',
    );
    return '$_temp0';
  }

  @override
  String get accountCenterCreateNewAccount => 'Create New Account';

  @override
  String get accountCenterCreateAccountInfo =>
      'To create an account, scan your friend\'s QR code for \"New Account\" with your camera. PublicOS opens the confirm sheet automatically.';

  @override
  String get accountCenterSelectFriendTitle => 'Select Friend';

  @override
  String get accountCenterSearchHint => 'Search by name, username or address';

  @override
  String get accountCenterSearchingOnChain => 'Searching on chain…';

  @override
  String get accountCenterNoContacts => 'No contacts with a PublicOS address';

  @override
  String get addSessionDialogWrongKind =>
      'This claim is for creating an account, not adding a session.';

  @override
  String get addSessionDialogMalformedPayload => 'Malformed claim payload.';

  @override
  String get addSessionDialogForeignAccount =>
      'This claim was signed for a different account.';

  @override
  String get addSessionDialogNotRecoveryContact =>
      'You\'re not a recovery contact for this account, so you can\'t help recover it. Only the contacts they chose in advance can.';

  @override
  String get addSessionDialogRecoveryCheckFailed =>
      'Could not check recovery status.';

  @override
  String get addSessionDialogRecoveryVoteStartedTitle =>
      'Recovery vote started';

  @override
  String get addSessionDialogDeviceAuthorizedTitle => 'Session added';

  @override
  String get addSessionDialogRecoverySuccessBody =>
      'The other recovery contacts can now add their votes. Once enough approve, the new session becomes the account\'s only one.';

  @override
  String get addSessionDialogAuthorizedSuccessBody =>
      'The new session can now act as your account.';

  @override
  String get addSessionDialogInvalidClaimTitle => 'Invalid code';

  @override
  String get addSessionDialogClose => 'CLOSE';

  @override
  String get addSessionDialogHelpRecoverTitle => 'Help recover an account';

  @override
  String get addSessionDialogAuthorizeSessionTitle => 'Add a session';

  @override
  String addSessionDialogRecoveryBody(Object target, Object address) {
    return 'Start a recovery vote that gives $target a new session ($address). If enough of their recovery contacts approve, every other session on the account is removed and this one stays.';
  }

  @override
  String addSessionDialogAuthorizeBody(Object address) {
    return 'Add $address as a session of your account. It will be able to send messages, manage your profile and transact as you.';
  }

  @override
  String get addSessionDialogThisAccount => 'this account';

  @override
  String get addSessionDialogAddressCopied => 'Address copied';

  @override
  String addSessionDialogRecoveryWarning(Object target) {
    return 'Only do this if $target asked you to help them recover. It removes all their current sessions.';
  }

  @override
  String get addSessionDialogAuthorizeWarning =>
      'Only approve a session you started yourself. If you didn\'t, cancel.';

  @override
  String get addSessionDialogClaimExpired =>
      'This request expired. Make a new QR where you started it.';

  @override
  String get addSessionDialogStartVoteButton => 'START VOTE';

  @override
  String get addSessionDialogAuthorizeButton => 'ADD SESSION';

  @override
  String get addSessionDialogDeadlineExpired => 'expired';

  @override
  String addSessionDialogDeadlineExpiresIn(Object time) {
    return 'Expires in $time';
  }

  @override
  String get appProfileBottomSheetEdit => 'Edit';

  @override
  String get appProfileBottomSheetByPrefix => 'by ';

  @override
  String get appProfileBottomSheetAbout => 'About';

  @override
  String get appProfileBottomSheetOpenApp => 'Open App';

  @override
  String get appProfileBottomSheetOpenWebApp => 'Open Web App';

  @override
  String get appProfileBottomSheetDownloadApk => 'Download APK';

  @override
  String get appProfileBottomSheetDownloadIpa => 'Download IPA';

  @override
  String get appProfileBottomSheetPlatformWeb => 'Web';

  @override
  String get registerAppBottomSheetTitleEdit => 'Edit App';

  @override
  String get registerAppBottomSheetTitleRegister => 'Register App';

  @override
  String get registerAppBottomSheetBack => 'Back';

  @override
  String get registerAppBottomSheetUpdateApp => 'Update App';

  @override
  String get registerAppBottomSheetNext => 'Next';

  @override
  String get registerAppBottomSheetStepBasicInfo => 'Basic Info';

  @override
  String get registerAppBottomSheetStepMetadata => 'Metadata';

  @override
  String get registerAppBottomSheetStepLinks => 'Links';

  @override
  String get registerAppBottomSheetBasicInfoTitle => 'Basic Information';

  @override
  String get registerAppBottomSheetAppNameLabel => 'App Name (unique key)';

  @override
  String get registerAppBottomSheetAppNameHint => 'e.g., my-awesome-app';

  @override
  String get registerAppBottomSheetAppNameHelperEdit =>
      'App name cannot be changed after registration.';

  @override
  String get registerAppBottomSheetAppNameHelperCreate =>
      'Lowercase, no spaces. This is your app identifier.';

  @override
  String get registerAppBottomSheetAppNameRequired => 'App name is required';

  @override
  String get registerAppBottomSheetAppNameMinLength =>
      'App name must be at least 3 characters';

  @override
  String get registerAppBottomSheetDisplayNameLabel => 'Display Name';

  @override
  String get registerAppBottomSheetDisplayNameHint => 'e.g., My Awesome App';

  @override
  String get registerAppBottomSheetDisplayNameHelper =>
      'Human-readable name shown to users.';

  @override
  String get registerAppBottomSheetDisplayNameRequired =>
      'Display name is required';

  @override
  String get registerAppBottomSheetIconUrlLabel => 'Icon URL (optional)';

  @override
  String get registerAppBottomSheetIconUrlHelper =>
      'URL to your app icon image.';

  @override
  String get registerAppBottomSheetAppDetailsTitle => 'App Details';

  @override
  String get registerAppBottomSheetDescriptionLabel => 'Description';

  @override
  String get registerAppBottomSheetDescriptionHint =>
      'Describe what your app does...';

  @override
  String get registerAppBottomSheetWarningsLabel => 'Warnings (optional)';

  @override
  String get registerAppBottomSheetWarningsHint =>
      'e.g., Contains mature content, gambling, etc.';

  @override
  String get registerAppBottomSheetWarningsHelper =>
      'Any content warnings users should know about.';

  @override
  String get registerAppBottomSheetCategoryOneLabel => 'Category 1';

  @override
  String get registerAppBottomSheetCategoryOneHint => 'e.g., Social';

  @override
  String get registerAppBottomSheetCategoryTwoLabel => 'Category 2';

  @override
  String get registerAppBottomSheetCategoryTwoHint => 'e.g., Finance';

  @override
  String get registerAppBottomSheetAppLinksTitle => 'App Links';

  @override
  String get registerAppBottomSheetAppLinksSubtitle =>
      'Add at least one link where users can access your app.';

  @override
  String get registerAppBottomSheetWebUrlLabel => 'Web App URL';

  @override
  String get registerAppBottomSheetWebUrlHelper =>
      'URL to your web app (can be launched in PublicOS browser).';

  @override
  String get registerAppBottomSheetAppStoreLabel => 'App Store Link (iOS)';

  @override
  String get registerAppBottomSheetPlayStoreLabel =>
      'Play Store Link (Android)';

  @override
  String get registerAppBottomSheetApkLabel => 'APK Download URL';

  @override
  String get registerAppBottomSheetApkHint => 'Direct link to APK file';

  @override
  String get registerAppBottomSheetIpaLabel => 'IPA Download URL';

  @override
  String get registerAppBottomSheetIpaHint => 'Direct link to IPA file';

  @override
  String registerAppBottomSheetSnackUpdated(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pointers',
      one: '1 pointer',
    );
    return 'App \"$name\" updated with $_temp0!';
  }

  @override
  String registerAppBottomSheetSnackRegistered(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pointers',
      one: '1 pointer',
    );
    return 'App \"$name\" registered with $_temp0!';
  }

  @override
  String get registerAppBottomSheetRegisterFailed => 'Failed to register app';

  @override
  String get appProfileSheetEdit => 'Edit';

  @override
  String get appProfileSheetByPrefix => 'by ';

  @override
  String get appProfileSheetAbout => 'About';

  @override
  String get appProfileSheetOpenAppHeader => 'Open App';

  @override
  String get appProfileSheetOpenWebApp => 'Open Web App';

  @override
  String get appProfileSheetDownloadApk => 'Download APK';

  @override
  String get appProfileSheetDownloadIpa => 'Download IPA';

  @override
  String get registerAppSheetBasicInfo => 'Basic Information';

  @override
  String get registerAppSheetAppNameLabel => 'App Name (unique key)';

  @override
  String get registerAppSheetAppNameHint => 'e.g., my-awesome-app';

  @override
  String get registerAppSheetAppNameHelperLocked =>
      'App name cannot be changed after registration.';

  @override
  String get registerAppSheetAppNameHelper =>
      'Lowercase, no spaces. This is your app identifier.';

  @override
  String get registerAppSheetAppNameRequired => 'App name is required';

  @override
  String get registerAppSheetAppNameTooShort =>
      'App name must be at least 3 characters';

  @override
  String get registerAppSheetDisplayNameLabel => 'Display Name';

  @override
  String get registerAppSheetDisplayNameHint => 'e.g., My Awesome App';

  @override
  String get registerAppSheetDisplayNameHelper =>
      'Human-readable name shown to users.';

  @override
  String get registerAppSheetDisplayNameRequired => 'Display name is required';

  @override
  String get registerAppSheetIconUrlLabel => 'Icon URL (optional)';

  @override
  String get registerAppSheetIconUrlHelper => 'URL to your app icon image.';

  @override
  String get registerAppSheetAppDetails => 'App Details';

  @override
  String get registerAppSheetDescriptionLabel => 'Description';

  @override
  String get registerAppSheetDescriptionHint =>
      'Describe what your app does...';

  @override
  String get registerAppSheetWarningsLabel => 'Warnings (optional)';

  @override
  String get registerAppSheetWarningsHint =>
      'e.g., Contains mature content, gambling, etc.';

  @override
  String get registerAppSheetWarningsHelper =>
      'Any content warnings users should know about.';

  @override
  String get registerAppSheetCategoryOneLabel => 'Category 1';

  @override
  String get registerAppSheetCategoryOneHint => 'e.g., Social';

  @override
  String get registerAppSheetCategoryTwoLabel => 'Category 2';

  @override
  String get registerAppSheetCategoryTwoHint => 'e.g., Finance';

  @override
  String get registerAppSheetAppLinks => 'App Links';

  @override
  String get registerAppSheetLinksSubtitle =>
      'Add at least one link where users can access your app.';

  @override
  String get registerAppSheetWebUrlLabel => 'Web App URL';

  @override
  String get registerAppSheetWebUrlHelper =>
      'URL to your web app (launchable in PublicOS browser).';

  @override
  String get registerAppSheetAppStoreLabel => 'App Store Link (iOS)';

  @override
  String get registerAppSheetPlayStoreLabel => 'Play Store Link (Android)';

  @override
  String get registerAppSheetApkUrlLabel => 'APK Download URL';

  @override
  String get registerAppSheetApkUrlHint => 'Direct link to APK file';

  @override
  String get registerAppSheetIpaUrlLabel => 'IPA Download URL';

  @override
  String get registerAppSheetIpaUrlHint => 'Direct link to IPA file';

  @override
  String get registerAppSheetEditApp => 'Edit App';

  @override
  String get registerAppSheetRegisterApp => 'Register App';

  @override
  String get registerAppSheetStepBasic => 'Basic';

  @override
  String get registerAppSheetStepMetadata => 'Metadata';

  @override
  String get registerAppSheetStepLinks => 'Links';

  @override
  String get registerAppSheetBack => 'Back';

  @override
  String get registerAppSheetUpdateApp => 'Update App';

  @override
  String get registerAppSheetNext => 'Next';

  @override
  String registerAppSheetUpdatedSnack(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pointers',
      one: '1 pointer',
    );
    return 'App \"$name\" updated with $_temp0!';
  }

  @override
  String registerAppSheetRegisteredSnack(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pointers',
      one: '1 pointer',
    );
    return 'App \"$name\" registered with $_temp0!';
  }

  @override
  String registerAppSheetUpdateFailed(Object error) {
    return 'Failed to update app: $error';
  }

  @override
  String registerAppSheetRegisterFailed(Object error) {
    return 'Failed to register app: $error';
  }

  @override
  String get signatureRequestSheetSignWith => 'Sign with';

  @override
  String get signatureRequestSheetMyAccount => 'My Account';

  @override
  String get signatureRequestSheetKeyFallback => 'Key';

  @override
  String get signatureRequestSheetTitleSignMessage => 'Sign Message';

  @override
  String get signatureRequestSheetTitleSignData => 'Sign Data';

  @override
  String get signatureRequestSheetTitleSignTypedData => 'Sign Typed Data';

  @override
  String get signatureRequestSheetTitleSendTransaction => 'Send Transaction';

  @override
  String get signatureRequestSheetTitleSignTransaction => 'Sign Transaction';

  @override
  String get signatureRequestSheetActionSignMessage => 'SIGN MESSAGE';

  @override
  String get signatureRequestSheetActionSignData => 'SIGN DATA';

  @override
  String get signatureRequestSheetActionSend => 'SEND';

  @override
  String get signatureRequestSheetActionSign => 'SIGN';

  @override
  String get signatureRequestSheetChainUnknown => 'Unknown';

  @override
  String signatureRequestSheetChainNamed(Object id) {
    return 'Chain $id';
  }

  @override
  String get signatureRequestSheetInfoTitle => 'About Signing';

  @override
  String get signatureRequestSheetInfoBody1 =>
      'This signs a digital message with the selected key.';

  @override
  String get signatureRequestSheetInfoBody2 =>
      'A signature can authorize actions, prove ownership, or agree to terms. It may or may not touch the chain.';

  @override
  String get signatureRequestSheetInfoWarning =>
      'Always be careful what you sign — a malicious signature can lead to loss of funds or unauthorized access.';

  @override
  String get signatureRequestSheetInfoGotIt => 'Got it';

  @override
  String get signatureRequestSheetCopiedToClipboard => 'Copied to clipboard';

  @override
  String get signatureRequestSheetInfoTooltip => 'What is signing?';

  @override
  String get signatureRequestSheetKeyBadge => 'key';

  @override
  String get signatureRequestSheetNoData => 'No data';

  @override
  String get signatureRequestSheetSigningWith => 'SIGNING WITH';

  @override
  String get signatureRequestSheetSectionMessage => 'MESSAGE';

  @override
  String get signatureRequestSheetSectionRawHex => 'RAW HEX';

  @override
  String get signatureRequestSheetRawData => 'RAW DATA';

  @override
  String get signatureRequestSheetCopy => 'COPY';

  @override
  String get signatureRequestSheetNotReadableText =>
      'This message is not readable text. You can inspect it under Raw data.';

  @override
  String get signatureRequestSheetSectionTypedData => 'TYPED DATA (EIP-712)';

  @override
  String get signatureRequestSheetSectionTransaction => 'TRANSACTION';

  @override
  String get signatureRequestSheetSectionContractData => 'CONTRACT DATA';

  @override
  String get signatureRequestSheetLabelSending => 'Sending';

  @override
  String get signatureRequestSheetLabelRecipient => 'Recipient';

  @override
  String get signatureRequestSheetLabelToken => 'Token';

  @override
  String get signatureRequestSheetLabelTo => 'To';

  @override
  String get signatureRequestSheetLabelValue => 'Value';

  @override
  String get signatureRequestSheetLabelNetwork => 'Network';

  @override
  String get signatureRequestSheetLabelGasLimit => 'Gas Limit';

  @override
  String get signatureRequestSheetActionReject => 'REJECT';

  @override
  String get connectRequestSheetTitle => 'Connect to this site?';

  @override
  String get connectRequestSheetOrigin => 'ORIGIN';

  @override
  String get connectRequestSheetNetwork => 'NETWORK';

  @override
  String get browserChainPickerNote =>
      'Applies to this tab only, and reloads the page.';

  @override
  String get connectRequestSheetSharing => 'SHARING';

  @override
  String get connectRequestSheetSessionKey => 'Session Key';

  @override
  String get connectRequestSheetScope =>
      'This site will be able to see the keys you turn on and ask you to sign with them. The green key is the one it sees first. It can\'t sign or move funds without asking you every time.';

  @override
  String get connectRequestSheetActionCancel => 'CANCEL';

  @override
  String get connectRequestSheetActionConnect => 'CONNECT';

  @override
  String get siteKeysSheetTitle => 'Connected keys';

  @override
  String get siteKeysSheetSubtitle =>
      'Visible keys are the ones this site can see and ask you to sign with. The green key is the active key: the one at the top of the list, which most sites use to sign you in. It\'s a choice for this site only. Sites without one use your preferred key.';

  @override
  String get siteKeysSheetActive => 'Active key on this site';

  @override
  String get siteKeysSheetVisible => 'Visible to this site';

  @override
  String get siteKeysSheetRequested => 'This site asked for this key';

  @override
  String get siteKeysSheetDisconnectHint =>
      'Turn every key off to disconnect this site.';

  @override
  String get siteKeysSheetLegendVisible => 'Site can see';

  @override
  String get siteKeysSheetLegendActive => 'Signs first';

  @override
  String get siteKeysSheetLegendDisconnect => 'All off = disconnect';

  @override
  String get siteKeysSheetActionSave => 'SAVE';

  @override
  String get siteKeysSheetActionDisconnect => 'DISCONNECT';

  @override
  String get siteKeysSheetEmpty => 'No keys available.';

  @override
  String desktopWebKeyVisibleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visible',
      one: '1 visible',
    );
    return '$_temp0';
  }

  @override
  String get desktopWebviewLoading => 'Loading...';

  @override
  String get webKeyIndicatorTooltip => 'Keys for this site';

  @override
  String signatureRequestSheetRawTokenAmount(Object amount, Object addr) {
    return '$amount (token $addr)';
  }

  @override
  String get domainStoreSheetOverdueRenewFirst =>
      'Your domain is overdue — renew it first. A lapsed account can only pay its own domain until it\'s current again.';

  @override
  String get editInboxIdLabelSheetTitle => 'Edit Inbox ID Label';

  @override
  String editInboxIdLabelSheetIdLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get editInboxIdLabelSheetNewLabel => 'New Label';

  @override
  String get editInboxIdLabelSheetLabelRequired => 'Please enter a label';

  @override
  String get editInboxIdLabelSheetSave => 'Save Changes';

  @override
  String get feedsSettingsSheetTitle => 'RSS View Settings';

  @override
  String get feedsSettingsSheetSubtitle => 'Customize how posts are displayed';

  @override
  String get feedsSettingsSheetTitleTextSize => 'Title Text Size';

  @override
  String get feedsSettingsSheetDescriptionTextSize => 'Description Text Size';

  @override
  String get feedsSettingsSheetPreview => 'Preview';

  @override
  String get feedsSettingsSheetSamplePostTitle => 'Sample Post Title';

  @override
  String get feedsSettingsSheetSampleDescription =>
      'This is a sample description to show how your RSS feed posts will appear with the current text size settings.';

  @override
  String get feedsSettingsSheetResetToDefaults => 'Reset to Defaults';

  @override
  String feedsSettingsSheetPointSize(Object value) {
    return '${value}pt';
  }

  @override
  String get xmtpSettingsSheetTitle => 'XMTP Settings';

  @override
  String get xmtpSettingsSheetReadReceiptsHeader => 'Read Receipts';

  @override
  String get xmtpSettingsSheetReadReceiptsDescription =>
      'Control whether you send and display read receipts. Note: The XMTP network is open - you can choose to see receipts others send without sending your own.';

  @override
  String get xmtpSettingsSheetSendReadReceiptsTitle => 'Send read receipts';

  @override
  String get xmtpSettingsSheetSendReadReceiptsSubtitle =>
      'Let others know when you\'ve read their messages';

  @override
  String get xmtpSettingsSheetDisplayReadReceiptsTitle =>
      'Display read receipts';

  @override
  String get xmtpSettingsSheetDisplayReadReceiptsSubtitle =>
      'Show when others have read your messages';

  @override
  String get xmtpSettingsSheetDeniedConvosButton => 'Denied Convos';

  @override
  String get addCustomFeedSheetTitleList => 'Add a feed to this list';

  @override
  String get addCustomFeedSheetTitleFollow => 'Follow a feed';

  @override
  String get addCustomFeedSheetUrlHint => 'https://example.com/feed.xml';

  @override
  String get addCustomFeedSheetCheckButton => 'Check feed';

  @override
  String get addCustomFeedSheetNoPostsError =>
      'We reached that URL but it had no posts. Double-check it is a feed URL, not the website it belongs to.';

  @override
  String addCustomFeedSheetHttpError(Object code) {
    return 'The server returned HTTP $code. Check the URL and try again.';
  }

  @override
  String get addCustomFeedSheetNetworkError =>
      'Couldn\'t reach that URL. Check your connection and the address, then try again.';

  @override
  String get addCustomFeedSheetReadError =>
      'Couldn\'t read that as a feed. Make sure it is a direct RSS, Atom, or JSON Feed URL (not the website it belongs to).';

  @override
  String get addCustomFeedSheetSaveError =>
      'Failed to save the feed. Please try again.';

  @override
  String get addCustomFeedSheetUntitledFeed => 'Untitled feed';

  @override
  String get addCustomFeedSheetUntitledPost => '(untitled post)';

  @override
  String get addCustomFeedSheetLocalOnlyNote =>
      'This feed is added to this client only — it is not published on-chain and will not appear for anyone else.';

  @override
  String get addCustomFeedSheetAddToListButton => 'Add to list';

  @override
  String get addCustomFeedSheetFollowFeedButton => 'Follow feed';

  @override
  String get addToListBottomSheetTitle => 'Manage RSS Lists';

  @override
  String get addToListBottomSheetDefaultFeedTitle => 'RSS Feed';

  @override
  String get addToListBottomSheetSaveChanges => 'Save Changes';

  @override
  String get addToListBottomSheetCreateNew => 'Create new list';

  @override
  String get addToListBottomSheetCreateNewSubtitle =>
      'Add this feed to a dedicated list';

  @override
  String addToListBottomSheetCreatedList(Object name) {
    return 'Created list \"$name\"';
  }

  @override
  String get addToListBottomSheetFailedCreate => 'Failed to create list';

  @override
  String get addToListBottomSheetNoChanges => 'No changes made';

  @override
  String addToListBottomSheetAddedToLists(int addedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      addedCount,
      locale: localeName,
      other: '$addedCount lists',
      one: '1 list',
    );
    return 'Added to $_temp0';
  }

  @override
  String addToListBottomSheetRemovedFromLists(int removedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '$removedCount lists',
      one: '1 list',
    );
    return 'Removed from $_temp0';
  }

  @override
  String addToListBottomSheetAddedAndRemoved(
      Object addedCount, int removedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '$removedCount lists',
      one: '1 list',
    );
    return 'Added to $addedCount, removed from $_temp0';
  }

  @override
  String get addToListBottomSheetErrorLoading => 'Couldn\'t load lists';

  @override
  String get addToListBottomSheetErrorSaving => 'Couldn\'t save changes';

  @override
  String get addToListBottomSheetErrorCreating => 'Couldn\'t create list';

  @override
  String get addToListsSheetTitle => 'Add to lists';

  @override
  String get addToListsSheetSectionSingleFollow => 'SINGLE FOLLOW';

  @override
  String get addToListsSheetSectionFollowAsSingle => 'FOLLOW AS SINGLE';

  @override
  String get addToListsSheetSectionLists => 'LISTS';

  @override
  String get addToListsSheetVia => 'via';

  @override
  String addToListsSheetFeedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return '$_temp0';
  }

  @override
  String get addToListsSheetCreateNewList => 'Create a new list';

  @override
  String get addToListsSheetSave => 'Save';

  @override
  String addToListsSheetUnfollowTitle(Object feed) {
    return 'Unfollow $feed?';
  }

  @override
  String get addToListsSheetUnfollowBody =>
      'This removes the single follow. The feed stays in any other lists you\'ve added it to.';

  @override
  String get addToListsSheetUnfollowAction => 'Unfollow';

  @override
  String addToListsSheetAddedToLists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added to $count lists',
      one: 'Added to 1 list',
    );
    return '$_temp0';
  }

  @override
  String addToListsSheetRemovedFromLists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed from $count lists',
      one: 'Removed from 1 list',
    );
    return '$_temp0';
  }

  @override
  String addToListsSheetFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return '$_temp0';
  }

  @override
  String get addToListsSheetNoChanges => 'No changes';

  @override
  String get addToListsSheetCreatedButFailedToAdd =>
      'Created list but failed to add feed';

  @override
  String get addToListsSheetFailedToCreateSingle =>
      'Failed to create single follow';

  @override
  String get addToListsSheetFailedToUnfollow => 'Failed to unfollow';

  @override
  String get commentCardTranslating => 'Translating…';

  @override
  String get commentCardTranslateWaitingWifi => 'Waiting for Wi-Fi…';

  @override
  String get commentCardTranslateDownloadingLang => 'Downloading language…';

  @override
  String get commentCardDownloadLangPackTitle => 'Download language pack?';

  @override
  String commentCardDownloadLangPackBody(Object from, Object to) {
    return 'Translating $from → $to needs an offline language pack (~30 MB each, downloaded once, then fully on-device).';
  }

  @override
  String get commentCardDownload => 'Download';

  @override
  String get commentCardTranslateFailed => 'Translate failed';

  @override
  String commentCardTranslateFrom(Object lang) {
    return 'Translate from $lang';
  }

  @override
  String commentCardTranslatedFrom(Object lang) {
    return 'Translated from $lang · Show original';
  }

  @override
  String commentCardShowTranslation(Object lang) {
    return 'Show translation ($lang)';
  }

  @override
  String get commentCardDeleteTitle => 'Delete comment?';

  @override
  String get commentCardDeleteBody =>
      'This removes the comment and any replies under it. Cannot be undone.';

  @override
  String get commentCardDelete => 'Delete';

  @override
  String get commentCardDeleted => '[deleted]';

  @override
  String get commentCardLoadMoreReplies => 'Load more replies';

  @override
  String get commentCardEdited => '(edited)';

  @override
  String get commentCardCopyText => 'Copy text';

  @override
  String get commentCardEdit => 'Edit';

  @override
  String get commentCardBlockFromCommenting => 'Block from commenting';

  @override
  String get commentCardCommentCopied => 'Comment copied';

  @override
  String get commentCardBlockTitle => 'Block from commenting?';

  @override
  String commentCardBlockBody(Object addr) {
    return 'Add a permanent deny rule for $addr on this post. They will not be able to comment here. You can adjust or remove the rule from the post menu → Comment rules.';
  }

  @override
  String get commentCardBlock => 'Block';

  @override
  String get commentCardSave => 'Save';

  @override
  String get commentCardVote => 'Vote';

  @override
  String get commentCardReply => 'Reply';

  @override
  String commentCardReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String get commentRulesSheetLoadFailed => 'Failed to load comment rules';

  @override
  String get commentRulesSheetAddFailed => 'Failed to add rule';

  @override
  String get commentRulesSheetRemoveFailed => 'Failed to remove rule';

  @override
  String get commentRulesSheetTitle => 'Comment rules';

  @override
  String get commentRulesSheetDescription =>
      'Override who can comment on this single post. Allow lets the address bypass channel restrictions; Deny blocks them even if the channel is open. Each rule is permanent unless you set a date for it to lift.';

  @override
  String get commentRulesSheetEmptyTitle => 'No rules yet';

  @override
  String get commentRulesSheetEmptyBody =>
      'The channel-level commenting policy applies.';

  @override
  String get commentRulesSheetDenyUntil => 'DENY UNTIL';

  @override
  String get commentRulesSheetAllowUntil => 'ALLOW UNTIL';

  @override
  String get commentRulesSheetDenyForever => 'Deny forever — no end date';

  @override
  String get commentRulesSheetAllowForever => 'Allow forever — no end date';

  @override
  String get commentRulesSheetAllow => 'Allow';

  @override
  String get commentRulesSheetDeny => 'Deny';

  @override
  String get commentRulesSheetAddButton => 'Add';

  @override
  String get commentRulesSheetJustNow => 'just now';

  @override
  String commentRulesSheetMinutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String commentRulesSheetHoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String commentRulesSheetDaysAgo(Object days) {
    return '${days}d ago';
  }

  @override
  String get commentRulesSheetChipDeny => 'DENY';

  @override
  String get commentRulesSheetChipAllow => 'ALLOW';

  @override
  String get createListBottomSheetNameRequired => 'Please enter a list name';

  @override
  String createListBottomSheetUpdatedList(Object name) {
    return 'Updated list \"$name\"';
  }

  @override
  String createListBottomSheetCreatedList(Object name) {
    return 'Created list \"$name\"';
  }

  @override
  String get createListBottomSheetUpdateFailed => 'Failed to update list';

  @override
  String get createListBottomSheetCreateFailed => 'Failed to create list';

  @override
  String get createListBottomSheetEditTitle => 'Edit RSS List';

  @override
  String get createListBottomSheetCreateTitle => 'Create RSS List';

  @override
  String get createListBottomSheetEditSubtitle =>
      'Update the list name and icon';

  @override
  String get createListBottomSheetCreateSubtitle =>
      'Create a new list to organize RSS feeds';

  @override
  String get createListBottomSheetNameLabel => 'List Name';

  @override
  String get createListBottomSheetNameHint => 'Enter a name for your RSS list';

  @override
  String get createListBottomSheetUpdateButton => 'Update';

  @override
  String get createListBottomSheetCreateButton => 'Create';

  @override
  String get discoverContactRowRssTooltip => 'RSS';

  @override
  String get discoverContactRowWebsiteTooltip => 'Website';

  @override
  String editListBottomSheetRemovedFromList(Object name) {
    return 'Removed \"$name\" from list';
  }

  @override
  String get editListBottomSheetRemoveFailed =>
      'Failed to remove feed from list';

  @override
  String get editListBottomSheetRemoveFeedError => 'Error removing feed';

  @override
  String get editListBottomSheetRemoveFeedTitle => 'Remove Feed';

  @override
  String editListBottomSheetRemoveConfirm(Object name) {
    return 'Are you sure you want to remove \"$name\" from this list?';
  }

  @override
  String get editListBottomSheetRemove => 'Remove';

  @override
  String editListBottomSheetFeedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return '$_temp0';
  }

  @override
  String get editListBottomSheetNoFeeds => 'No feeds in this list';

  @override
  String get editListBottomSheetEmptyHint =>
      'Add feeds to this list by browsing RSS feeds and using the \"Add to List\" button.';

  @override
  String get editListBottomSheetRssFeed => 'RSS Feed';

  @override
  String get editListBottomSheetRemoveTooltip => 'Remove from list';

  @override
  String get editListBottomSheetDone => 'Done';

  @override
  String get editListSheetTitleEdit => 'Edit list';

  @override
  String get editListSheetTitleNew => 'New list';

  @override
  String get editListSheetNameHint => 'List name';

  @override
  String get editListSheetIconHint => 'Tap the icon to change it.';

  @override
  String get editListSheetSave => 'Save';

  @override
  String get editListSheetCreate => 'Create list';

  @override
  String get editListSheetFailedUpdate => 'Failed to update list';

  @override
  String get editListSheetFailedCreate => 'Failed to create list';

  @override
  String get editPostBottomSheetErrorTitle => 'Error';

  @override
  String get editPostBottomSheetOk => 'OK';

  @override
  String get editPostBottomSheetErrorMissingChannel =>
      'Cannot update post: missing channel slug';

  @override
  String get editPostBottomSheetUpdateSuccess => 'Post updated successfully';

  @override
  String editPostBottomSheetUpdateFailed(Object error) {
    return 'Failed to update post: $error';
  }

  @override
  String get editPostBottomSheetUnknownError => 'Unknown error';

  @override
  String get editPostBottomSheetHeaderTitle => 'Edit Post';

  @override
  String get editPostBottomSheetHeaderSubtitle => 'Update your post content';

  @override
  String get editPostBottomSheetTitleLabel => 'Title';

  @override
  String get editPostBottomSheetTitleHint => 'Add a title (optional)';

  @override
  String get editPostBottomSheetContentLabel => 'Content';

  @override
  String get editPostBottomSheetContentHint =>
      'Write your post content here...';

  @override
  String get editPostBottomSheetContentRequired => 'Content is required';

  @override
  String get editPostBottomSheetMediaLabel => 'Media';

  @override
  String get editPostBottomSheetMediaHelper => 'Optional featured image';

  @override
  String get editPostBottomSheetInvalidUrl => 'Please enter a valid URL';

  @override
  String get editPostBottomSheetSummaryLabel => 'Summary';

  @override
  String get editPostBottomSheetSummaryHint =>
      'Brief description for previews...';

  @override
  String get editPostBottomSheetSummaryHelper =>
      'Short summary shown in feed previews';

  @override
  String get editPostBottomSheetExternalLinkLabel => 'External Link';

  @override
  String get editPostBottomSheetExternalLinkHelper =>
      'Optional link to external content';

  @override
  String get editPostBottomSheetTagsLabel => 'Tags';

  @override
  String get editPostBottomSheetTagsHint => 'tech, news, tutorial';

  @override
  String get editPostBottomSheetTagsHelper => 'Comma-separated tags';

  @override
  String get editPostBottomSheetSaving => 'Saving...';

  @override
  String get editPostBottomSheetSaveChanges => 'Save Changes';

  @override
  String get emojiPickerDialogSearchHint => 'Search emoji...';

  @override
  String get emojiPickerDialogNoResults => 'No emoji found';

  @override
  String get emojiPickerDialogCategorySmileys => 'Smileys';

  @override
  String get emojiPickerDialogCategoryPeople => 'People';

  @override
  String get emojiPickerDialogCategoryNature => 'Nature';

  @override
  String get emojiPickerDialogCategoryFood => 'Food';

  @override
  String get emojiPickerDialogCategoryActivities => 'Activities';

  @override
  String get emojiPickerDialogCategoryTravel => 'Travel';

  @override
  String get emojiPickerDialogCategoryObjects => 'Objects';

  @override
  String get emojiPickerDialogCategorySymbols => 'Symbols';

  @override
  String get emojiPickerDialogCategoryFlags => 'Flags';

  @override
  String get emojiPickerDialogCategoryMostUsed => 'Most used';

  @override
  String get feedsNavigationDrawerSectionLists => 'LISTS';

  @override
  String get feedsNavigationDrawerManageListsTooltip => 'Manage lists';

  @override
  String get feedsNavigationDrawerNoListsYet =>
      'No lists yet. Tap the icon above to create one.';

  @override
  String get feedsNavigationDrawerSectionMyChannels => 'MY CHANNELS';

  @override
  String get feedsNavigationDrawerCreateChannel => 'Create channel';

  @override
  String get feedsNavigationDrawerBookmarks => 'Bookmarks';

  @override
  String get feedsNavigationDrawerManageServer => 'Manage server';

  @override
  String get feedsNavigationDrawerReadingSettings => 'Reader settings';

  @override
  String get feedsNavigationDrawerHeaderTitle => 'FEEDS';

  @override
  String get feedsNavigationDrawerVia => 'via';

  @override
  String get feedsSettingsSheetTitleSizeLabel => 'TITLE SIZE';

  @override
  String get feedsSettingsSheetBodySizeLabel => 'BODY SIZE';

  @override
  String get feedsSettingsSheetTrimAtLabel => 'TRIM AT';

  @override
  String get feedsSettingsSheetTrimUnit => 'chars';

  @override
  String get feedsSettingsSheetSwipeSnapLabel => 'SWIPE TO NEXT POST WITHIN';

  @override
  String get feedsSettingsSheetSwipeSnapOnLabel => 'SWIPE TO SNAP';

  @override
  String get feedsSettingsSheetSwipeSnapOnOn => 'A quick swipe moves one post';

  @override
  String get feedsSettingsSheetSwipeSnapOnOff => 'Regular scrolling';

  @override
  String get feedsSettingsSheetPreviewLabel => 'Preview';

  @override
  String get feedsSettingsSheetJustNow => 'just now';

  @override
  String get feedsSettingsSheetVia => 'via';

  @override
  String get feedsSettingsSheetLayoutLabel => 'LAYOUT';

  @override
  String get feedsSettingsSheetLayoutCompact => 'Compact';

  @override
  String get feedsSettingsSheetLayoutWide => 'Wide';

  @override
  String get feedsSettingsSheetTrimLongPostsLabel => 'TRIM LONG POSTS';

  @override
  String get feedsSettingsSheetTrimLongPostsOn =>
      'Collapse summary + body to a max length';

  @override
  String get feedsSettingsSheetTrimLongPostsOff =>
      'Show the full post on every card';

  @override
  String get feedsSettingsSheetTranslationsLabel => 'ON-DEVICE TRANSLATIONS';

  @override
  String get feedsSettingsSheetTranslationsOn =>
      'Suggest translating posts in other languages';

  @override
  String get feedsSettingsSheetTranslationsOff =>
      'No translate hints on posts or comments';

  @override
  String get feedsSettingsSheetWifiOnlyLabel =>
      'DOWNLOAD PACKS OVER WI-FI ONLY';

  @override
  String get feedsSettingsSheetWifiOnlyOn =>
      'Packs wait for Wi-Fi — won\'t use mobile data';

  @override
  String get feedsSettingsSheetWifiOnlyOff =>
      'Packs may download over mobile data';

  @override
  String get feedsSettingsSheetSuggestFromLabel => 'SUGGEST TRANSLATING FROM';

  @override
  String get feedsSettingsSheetGroupLayout => 'Layout and text';

  @override
  String get feedsSettingsSheetGroupScrolling => 'Scrolling';

  @override
  String get feedsSettingsSheetGroupVideo => 'Video';

  @override
  String get feedsSettingsSheetGroupReactions => 'Reactions';

  @override
  String get feedsSettingsSheetDoubleTapLabel => 'DOUBLE TAP ADDS';

  @override
  String get feedsSettingsSheetDoubleTapHint =>
      'The reaction a double tap on a post adds. Tap to choose.';

  @override
  String get feedsSettingsSheetGroupSignature => 'Signature';

  @override
  String get feedsSettingsSheetSigShimmerLabel =>
      'SIGNATURE VISUAL CONFIRMATION';

  @override
  String get feedsSettingsSheetSigShimmerOn =>
      'A verified author\'s name shimmers in rainbow on its own.';

  @override
  String get feedsSettingsSheetSigShimmerOff =>
      'Off. Only the ! marks on unsigned posts remain.';

  @override
  String get feedsSettingsSheetSigShimmerEveryLabel => 'SHIMMER EVERY';

  @override
  String get feedsSettingsSheetSigShimmerEveryHint =>
      '4 to 10 seconds between each pass.';

  @override
  String get feedsSettingsSheetGroupTranslation => 'Translation';

  @override
  String get feedsSettingsSheetGroupSignin => 'Channel sign-in';

  @override
  String get feedsSettingsSheetVideoAutoplayLabel => 'AUTOPLAY VIDEOS';

  @override
  String get feedsSettingsSheetVideoAutoplayOn =>
      'Videos play muted as you scroll';

  @override
  String get feedsSettingsSheetVideoAutoplayOff =>
      'Every video waits for a tap';

  @override
  String get feedsSettingsSheetVideoAutoloadLabel => 'AUTOPLAY UP TO';

  @override
  String get feedsSettingsSheetVideoAutoloadHint =>
      'Bigger videos show their size and wait for a tap';

  @override
  String get feedsSettingsSheetVideoAlwaysAsk => 'Always ask';

  @override
  String get feedsSettingsSheetVideoNoLimit => 'No limit';

  @override
  String get feedsSettingsSheetReset => 'Reset to defaults';

  @override
  String get manageListsBottomSheetTitle => 'Manage Lists';

  @override
  String manageListsBottomSheetListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lists',
      one: '1 list',
    );
    return '$_temp0';
  }

  @override
  String get manageListsBottomSheetEmptyTitle => 'No lists created yet';

  @override
  String get manageListsBottomSheetEmptySubtitle =>
      'Create your first list to organize RSS feeds.';

  @override
  String get manageListsBottomSheetDefaultBadge => 'DEFAULT';

  @override
  String manageListsBottomSheetCreatedDate(Object date) {
    return 'Created $date';
  }

  @override
  String get manageListsBottomSheetCollapse => 'Collapse';

  @override
  String get manageListsBottomSheetExpand => 'Expand';

  @override
  String get manageListsBottomSheetEditTooltip => 'Edit list';

  @override
  String get manageListsBottomSheetDeleteTooltip => 'Delete list';

  @override
  String get manageListsBottomSheetNoFeeds => 'No feeds in this list';

  @override
  String get manageListsBottomSheetRssFeedFallback => 'RSS Feed';

  @override
  String get manageListsBottomSheetRemoveFromListTooltip => 'Remove from list';

  @override
  String get manageListsBottomSheetCreateButton => 'Create List';

  @override
  String manageListsBottomSheetRemovedSnack(Object title) {
    return 'Removed \"$title\" from list';
  }

  @override
  String get manageListsBottomSheetRemoveFailed =>
      'Failed to remove feed from list';

  @override
  String manageListsBottomSheetDeletedSnack(Object name) {
    return 'Deleted list \"$name\"';
  }

  @override
  String get manageListsBottomSheetDeleteFailed => 'Failed to delete list';

  @override
  String get manageListsBottomSheetRemoveDialogTitle => 'Remove Feed';

  @override
  String manageListsBottomSheetRemoveDialogBody(Object name) {
    return 'Would you like to remove this feed from \"$name\"?';
  }

  @override
  String get manageListsBottomSheetRemoveButton => 'Remove';

  @override
  String get manageListsBottomSheetDeleteDialogTitle => 'Delete List';

  @override
  String manageListsBottomSheetDeleteDialogBody(Object name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get manageListsBottomSheetDeleteWarning =>
      'Warning: This action cannot be undone. All feeds in this list will be removed from it.';

  @override
  String get manageListsBottomSheetDeleteButton => 'Delete';

  @override
  String get manageListsBottomSheetDateToday => 'today';

  @override
  String get manageListsBottomSheetDateYesterday => 'yesterday';

  @override
  String manageListsBottomSheetDateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get manageListsBottomSheetDateRecently => 'recently';

  @override
  String get manageListsSheetTitle => 'Manage lists';

  @override
  String get manageListsSheetAddFeed => 'Add a feed';

  @override
  String get manageListsSheetDeleteListTitle => 'Delete list?';

  @override
  String manageListsSheetDeleteListBody(Object name) {
    return 'Removing \"$name\" only removes the list — the feeds in it stay subscribed wherever else you have them.';
  }

  @override
  String get manageListsSheetDelete => 'Delete';

  @override
  String get manageListsSheetFailedDeleteList => 'Failed to delete list';

  @override
  String get manageListsSheetDefaultBadge => 'DEFAULT';

  @override
  String manageListsSheetFeedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return '$_temp0';
  }

  @override
  String get manageListsSheetFollowedAccounts => 'FOLLOWED ACCOUNTS';

  @override
  String get manageListsSheetIndividualFeeds => 'INDIVIDUAL FEEDS';

  @override
  String get manageListsSheetFollowingEmpty =>
      'You\'re not following anyone yet — follow friends from their profile, or add an individual feed URL below.';

  @override
  String get manageListsSheetFollowingAccount => 'Following';

  @override
  String get manageListsSheetMutedBadge => 'muted';

  @override
  String manageListsSheetFollowingAllChannels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'following all $count channels',
      one: 'following 1 channel',
    );
    return '$_temp0';
  }

  @override
  String manageListsSheetFollowingSomeChannels(int followed, int total) {
    return 'following $followed/$total channels';
  }

  @override
  String get manageListsSheetEditTooltip => 'Edit';

  @override
  String get manageListsSheetUnfollowTooltip => 'Unfollow';

  @override
  String get manageListsSheetCollapseTooltip => 'Collapse';

  @override
  String get manageListsSheetExpandTooltip => 'Expand';

  @override
  String get manageListsSheetFailedRequestAccess => 'Failed to request access';

  @override
  String get manageListsSheetRemoveFeedTitle => 'Remove feed?';

  @override
  String manageListsSheetRemoveFeedBody(Object feedName, Object listName) {
    return 'Remove \"$feedName\" from \"$listName\"?';
  }

  @override
  String get manageListsSheetRemovePersonTitle => 'Remove person?';

  @override
  String manageListsSheetRemovePersonBody(Object name, Object listName) {
    return 'Remove $name from \"$listName\"? Their channels stop showing in this list.';
  }

  @override
  String manageListSheetTitle(Object listName) {
    return 'Manage $listName';
  }

  @override
  String postsListNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new',
      one: '1 new',
    );
    return '$_temp0';
  }

  @override
  String get listHeaderEmpty => 'Follow someone or add a feed to get started.';

  @override
  String listHeaderPeopleWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'people',
      one: 'person',
    );
    return '$_temp0';
  }

  @override
  String listHeaderFeedsWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'feeds',
      one: 'feed',
    );
    return '$_temp0';
  }

  @override
  String get manageListsSheetRemove => 'Remove';

  @override
  String get manageListsSheetFailedRemoveFeed => 'Failed to remove feed';

  @override
  String get manageListsSheetNoFeedsYet => 'No feeds in this list yet.';

  @override
  String get manageListsSheetNoAccessBadge => 'NO ACCESS';

  @override
  String get manageListsSheetPendingBadge => 'PENDING';

  @override
  String get manageListsSheetRequestAccessTooltip => 'Request access';

  @override
  String get manageListsSheetRemoveFromListTooltip => 'Remove from list';

  @override
  String get manageListsSheetCreateNewList => 'Create new list';

  @override
  String get manageListsSheetNoListsYet => 'No lists yet';

  @override
  String get manageListsSheetVia => 'via';

  @override
  String newPostBottomSheetFailedToCreate(Object error) {
    return 'Failed to create post: $error';
  }

  @override
  String get newPostBottomSheetUnknownError => 'Unknown error';

  @override
  String get newPostBottomSheetErrorCreating => 'Error creating post';

  @override
  String get newPostBottomSheetErrorTitle => 'Error';

  @override
  String get newPostBottomSheetOk => 'OK';

  @override
  String get newPostBottomSheetDestinationChannel => 'Destination Channel';

  @override
  String get newPostBottomSheetSelectChannelHint =>
      'Select a channel for your post';

  @override
  String get newPostBottomSheetSelectChannelError => 'Please select a channel';

  @override
  String get newPostBottomSheetModeUpdate => 'Update';

  @override
  String get newPostBottomSheetModeArticle => 'Article';

  @override
  String get newPostBottomSheetNoChannelsTitle => 'No Channels Available';

  @override
  String get newPostBottomSheetNoChannelsBody =>
      'Create at least one channel before posting.';

  @override
  String get newPostBottomSheetHeaderTitle => 'New Post';

  @override
  String newPostBottomSheetPostToChannel(Object channel) {
    return 'Post to $channel';
  }

  @override
  String get newPostBottomSheetUpdateSubtitle =>
      'Quick update for your followers';

  @override
  String get newPostBottomSheetArticleSubtitle =>
      'Full article with all details';

  @override
  String get newPostBottomSheetTitleLabel => 'Title';

  @override
  String get newPostBottomSheetTitleHintUpdate => 'Add a title (optional)';

  @override
  String get newPostBottomSheetTitleHintArticle =>
      'Enter a compelling title...';

  @override
  String get newPostBottomSheetContentLabel => 'Content';

  @override
  String get newPostBottomSheetContentHintUpdate => 'Share your thoughts...';

  @override
  String get newPostBottomSheetContentHintArticle =>
      'Write your full post content here...';

  @override
  String get newPostBottomSheetContentRequired => 'Content is required';

  @override
  String get newPostBottomSheetMediaLabel => 'Media';

  @override
  String get newPostBottomSheetMediaHelper => 'Optional featured image';

  @override
  String get newPostBottomSheetInvalidUrl => 'Please enter a valid URL';

  @override
  String get newPostBottomSheetSummaryLabel => 'Summary';

  @override
  String get newPostBottomSheetSummaryHint =>
      'Brief description for previews...';

  @override
  String get newPostBottomSheetSummaryHelper =>
      'Short summary shown in channel previews';

  @override
  String get newPostBottomSheetExternalLinkLabel => 'External Link';

  @override
  String get newPostBottomSheetExternalLinkHelper =>
      'Optional link to external content';

  @override
  String get newPostBottomSheetTagsLabel => 'Tags';

  @override
  String get newPostBottomSheetTagsHint => 'tech, news, tutorial';

  @override
  String get newPostBottomSheetTagsHelper => 'Comma-separated tags';

  @override
  String get newPostBottomSheetPosting => 'Posting...';

  @override
  String get newPostBottomSheetCreatePost => 'Create Post';

  @override
  String get postDetailPagePostFallback => 'Post';

  @override
  String get postDetailPageCommentsUnavailable =>
      'Comments are not available for this post';

  @override
  String get postDetailPageAddReplyHint => 'Add a reply';

  @override
  String get postDetailPageAddCommentHint => 'Add a comment';

  @override
  String get postDetailPageReplyingTo => 'Replying to';

  @override
  String get postDetailPageCancelReplyTooltip => 'Cancel reply';

  @override
  String get postDetailPageCannotBlockMissingSlug =>
      'Cannot block: missing channel slug';

  @override
  String get postDetailPageBlockedFromCommenting =>
      'Blocked from commenting on this post';

  @override
  String get postSourceDetailsPageTitle => 'Post source';

  @override
  String get postSourceDetailsPageUnknownChannel => 'unknown channel';

  @override
  String postSourceDetailsPagePostedIn(Object channel) {
    return 'posted in $channel';
  }

  @override
  String get postSourceDetailsPageDiscoveredVia => 'DISCOVERED VIA';

  @override
  String get postSourceDetailsPageFoundOn => 'Found on';

  @override
  String get postSourceDetailsPageFoundOnSubtitle =>
      'the profile whose record tab carries this feed URL';

  @override
  String get postSourceDetailsPageWho => 'WHO';

  @override
  String get postSourceDetailsPageChannelOwner => 'Channel owner';

  @override
  String get postSourceDetailsPageChannelOwnerSubtitle =>
      'whose channel this post lives in';

  @override
  String get postSourceDetailsPagePostAuthor => 'Post author';

  @override
  String get postSourceDetailsPagePostAuthorSubtitle => 'who created this post';

  @override
  String get postSourceDetailsPageSignedBy => 'Signed by';

  @override
  String postSourceDetailsPageSessionOf(Object name) {
    return 'session of $name';
  }

  @override
  String get postSourceDetailsPageResolvingParent =>
      'resolving parent account…';

  @override
  String get postSourceDetailsPageWhoHeldKey =>
      'who held the key when the post was signed';

  @override
  String get postSourceDetailsPageTechnicalDetails => 'TECHNICAL DETAILS';

  @override
  String get postSourceDetailsPageHide => 'hide';

  @override
  String get postSourceDetailsPageShow => 'show';

  @override
  String get postSourceDetailsPageSectionIdentifiers => 'IDENTIFIERS';

  @override
  String get postSourceDetailsPageSectionServer => 'SERVER';

  @override
  String get postSourceDetailsPageSectionSource => 'SOURCE';

  @override
  String get postSourceDetailsPageSectionContent => 'CONTENT';

  @override
  String get postSourceDetailsPageSectionTimestamps => 'TIMESTAMPS';

  @override
  String get postSourceDetailsPageSectionEngagement => 'ENGAGEMENT';

  @override
  String get postSourceDetailsPageSectionSignature => 'SIGNATURE';

  @override
  String get postSourceDetailsPageNone => 'None';

  @override
  String get postSourceDetailsPageCopied => 'Copied';

  @override
  String postSourceDetailsPageHeroMedia(Object count) {
    return 'HERO MEDIA ($count)';
  }

  @override
  String postSourceDetailsPageSupportMedia(Object count) {
    return 'SUPPORT MEDIA ($count)';
  }

  @override
  String get postSourceDetailsPageAudio => 'AUDIO';

  @override
  String postSourceDetailsPageAuthors(Object count) {
    return 'AUTHORS ($count)';
  }

  @override
  String postSourceDetailsPageTags(Object count) {
    return 'TAGS ($count)';
  }

  @override
  String get postSourceDetailsPageSignatureChecked => 'Signature checked';

  @override
  String get postSourceDetailsPageSignatureChecking => 'Checking signature…';

  @override
  String get postSourceDetailsPageSignatureUnchecked => 'Signature not checked';

  @override
  String get postSourceDetailsPageBadSignature => 'Bad signature';

  @override
  String get postSourceDetailsPageNoSignature => 'No signature';

  @override
  String get postSourceDetailsPageRawJson => 'RAW JSON';

  @override
  String get postSourceDetailsPageCopy => 'Copy';

  @override
  String get postSourceDetailsPageShowLess => 'Show less';

  @override
  String get postSourceDetailsPageShowMore => 'Show more';

  @override
  String get postsListBookmarkRemoved => 'Bookmark removed';

  @override
  String get postsListPostBookmarked => 'Post bookmarked';

  @override
  String get postsListFeedNotFoundInList => 'Could not find feed in list';

  @override
  String postsListFeedRemovedFromList(Object feedName) {
    return 'Removed \"$feedName\" from list';
  }

  @override
  String postsListChannelMuted(Object channelName) {
    return 'Muted \"$channelName\"';
  }

  @override
  String get postsListRemoveFeedFailed => 'Failed to remove feed from list';

  @override
  String get postsListFeedPrivate => 'This feed is private.';

  @override
  String get postsListLoadFailedTitle => 'Failed to Load Feed';

  @override
  String get postsListEmptyBookmarksHeadline => 'No bookmarked posts yet';

  @override
  String get postsListEmptyBookmarksSubline =>
      'Tap the bookmark icon on any post to save it here';

  @override
  String get postsListEmptyListHeadline => 'No posts in this list yet';

  @override
  String get postsListEmptyListSubline =>
      'Add feeds to this list to see their posts here.';

  @override
  String get postsListEmptyHeadline => 'No posts yet';

  @override
  String get postsListEmptySubline => 'New posts will appear here.';

  @override
  String get postsListChannelNotFoundHeadline => 'Channel not found';

  @override
  String get postsListChannelNotFoundSubline =>
      'This channel was deleted or moved by its owner.';

  @override
  String get postsListChannelNotFoundUnfollow => 'Unfollow';

  @override
  String get postCardFeedContextOn => 'on';

  @override
  String feedReaderPageUpdated(String ago) {
    return 'updated $ago';
  }

  @override
  String get feedReaderPageCopyFeedUrl => 'Copy feed URL';

  @override
  String get feedReaderPageFeedUrlCopied => 'Feed URL copied';

  @override
  String get postsListPrivateFeedsBanner =>
      'Some feeds in this list are private and you don\'t have access.';

  @override
  String get privateFeedLockedWidgetNoOwnerAddress =>
      'Channel has no owner address';

  @override
  String get privateFeedLockedWidgetCouldNotResolve =>
      'Could not resolve channel';

  @override
  String get privateFeedLockedWidgetRequestFailed => 'Failed to request access';

  @override
  String get privateFeedLockedWidgetCancelFailed => 'Failed to cancel request';

  @override
  String get privateFeedLockedWidgetBlurbPending =>
      'Your request is waiting for the channel owner to approve.';

  @override
  String get privateFeedLockedWidgetBlurbBlocked =>
      'The channel owner has blocked your access. Reach out to them directly if you think this is a mistake.';

  @override
  String get privateFeedLockedWidgetBlurbDenied =>
      'Your previous request wasn\'t approved. You can try again.';

  @override
  String get privateFeedLockedWidgetBlurbDefault =>
      'Only approved followers can read this channel. Send a request to the owner to be added.';

  @override
  String get privateFeedLockedWidgetPrivateBadge => 'PRIVATE';

  @override
  String get privateFeedLockedWidgetPendingChip => 'Pending approval';

  @override
  String get privateFeedLockedWidgetCancelRequest => 'Cancel request';

  @override
  String get privateFeedLockedWidgetRequestAccess => 'Request access';

  @override
  String get floatingContactMenuShare => 'Share';

  @override
  String get floatingContactMenuDelete => 'Delete';

  @override
  String get floatingContactMenuDeleteTitle => 'Delete Contact';

  @override
  String floatingContactMenuDeleteConfirm(Object name) {
    return 'Are you sure you want to remove \"$name\" from your bookmarks?';
  }

  @override
  String floatingContactMenuShareContactLabel(Object name) {
    return 'Contact: $name';
  }

  @override
  String floatingContactMenuShareAddressLabel(Object address) {
    return 'Address: $address';
  }

  @override
  String floatingContactMenuShareInboxLabel(Object inboxId) {
    return 'XMTP Inbox ID: $inboxId';
  }

  @override
  String get gridSettingsSheetTitle => 'Grid settings';

  @override
  String get gridSettingsSheetSectionLayout => 'LAYOUT';

  @override
  String get gridSettingsSheetSectionGridSize => 'GRID SIZE';

  @override
  String gridSettingsSheetColumnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count columns',
      one: '1 column',
    );
    return '$_temp0';
  }

  @override
  String get gridSettingsSheetSectionTextSize => 'TEXT SIZE';

  @override
  String get gridSettingsSheetShowBannersLabel => 'Show contact banners';

  @override
  String get gridSettingsSheetShowBannersSubtitle =>
      'Display contact banner images behind contact rows.';

  @override
  String get gridSettingsSheetSectionPreview => 'PREVIEW';

  @override
  String gridSettingsSheetPreviewText(Object label) {
    return 'Preview text — $label';
  }

  @override
  String get gridSettingsSheetLayoutGrid => 'Grid';

  @override
  String get gridSettingsSheetLayoutRows => 'Rows';

  @override
  String get linkDeviceDialogTitle => 'Link this session';

  @override
  String get linkDeviceDialogSubtitleNewAccount =>
      'Pick a username + sign — show this QR to a citizen to mint your account.';

  @override
  String get linkDeviceDialogSubtitleAddSession =>
      'Paste your account address and sign. Then scan this QR with the app where your account is already open.';

  @override
  String get linkDeviceDialogToggleNewAccount => 'NEW ACCOUNT';

  @override
  String get linkDeviceDialogToggleAddSession => 'ADD THIS DEVICE';

  @override
  String linkDeviceDialogErrMinChars(Object min) {
    return 'Min $min chars';
  }

  @override
  String linkDeviceDialogErrMaxChars(Object max) {
    return 'Max $max chars';
  }

  @override
  String get linkDeviceDialogErrLeadingNonAlpha => 'Must start with a letter';

  @override
  String get linkDeviceDialogErrTrailing => 'Cannot end in - or _';

  @override
  String get linkDeviceDialogErrIllegalChar => 'Allowed: a-z A-Z 0-9 - _';

  @override
  String get linkDeviceDialogErrConsecutiveDash => 'No consecutive --';

  @override
  String get linkDeviceDialogErrConsecutiveUnderscore => 'No consecutive __';

  @override
  String get linkDeviceDialogLabelUsername => 'Username';

  @override
  String get linkDeviceDialogLabelAccountAddress => 'Account address';

  @override
  String get linkDeviceDialogHintUsername => 'Choose a username';

  @override
  String get linkDeviceDialogAddressCopied => 'Address copied';

  @override
  String get linkDeviceDialogClose => 'CLOSE';

  @override
  String get linkDeviceDialogSign => 'SIGN';

  @override
  String get linkDeviceDialogRefresh => 'REFRESH';

  @override
  String linkDeviceDialogQrExpiresIn(String time) {
    return 'QR expires in $time';
  }

  @override
  String get linkDeviceDialogLoadFailed => 'Failed to load saved request';

  @override
  String get linkDeviceDialogSignFailed => 'Sign failed';

  @override
  String get mediaUrlFieldImageUrlLabel => 'Image URL';

  @override
  String get mediaUrlFieldClearTooltip => 'Clear';

  @override
  String get mediaUrlFieldUploading => 'UPLOADING…';

  @override
  String get mediaUrlFieldUpload => 'UPLOAD';

  @override
  String get mediaUrlFieldLow => 'LOW';

  @override
  String get mediaUrlFieldHd => 'HD';

  @override
  String get mediaUrlFieldCheckingQuota => 'Checking quota…';

  @override
  String get mediaUrlFieldQuotaUnavailable => 'Quota unavailable';

  @override
  String mediaUrlFieldQuotaUsage(Object used, Object total) {
    return 'Quota: $used MB / $total MB';
  }

  @override
  String mediaUrlFieldQuotaOver(Object amount) {
    return 'OVER by $amount MB';
  }

  @override
  String mediaUrlFieldQuotaAfter(Object amount) {
    return 'After: $amount MB';
  }

  @override
  String get mediaUrlFieldUploadFailed => 'Upload failed';

  @override
  String get mediaUrlFieldUploadBlockedSspGate => 'Upload blocked by SSP gate';

  @override
  String get mediaUrlFieldCouldNotLoadImage => 'Could not load image';

  @override
  String get messageInputNoRecipientSelected => 'No recipient selected.';

  @override
  String get messageInputFailedStartConversation =>
      'Failed to start conversation.';

  @override
  String get messageInputFailedSendAttachmentRecipient =>
      'Failed to send attachment: Recipient not available.';

  @override
  String get messageInputFailedSendAttachment => 'Failed to send attachment';

  @override
  String get messageInputFailedSendReply =>
      'Failed to send reply: Recipient not available for this chat.';

  @override
  String get messageInputFailedSendRecipient =>
      'Failed to send: Recipient not available for this chat.';

  @override
  String get messageInputFailedSendMessage => 'Failed to send message';

  @override
  String get messageInputNoRecipientAttachment =>
      'No recipient selected to send attachment.';

  @override
  String get messageInputImageTooLarge =>
      'Image too large to send. Add a feed server to send it in HD.';

  @override
  String get messageInputFailedSelectAttachment =>
      'Failed to select attachment';

  @override
  String get messageInputStickerTooLarge => 'Sticker larger than 1 MB';

  @override
  String get messageInputSubscribeForHd =>
      'Subscribe to an SSP or add a custom feed server to send HD images';

  @override
  String get messageInputFeedServer => 'Feed Server';

  @override
  String get messageInputReplyAttachment => 'Attachment';

  @override
  String get messageInputReplyReaction => 'Reaction';

  @override
  String get messageInputReplyReply => 'Reply';

  @override
  String get messageInputReplyMessage => 'Message';

  @override
  String get messageInputReplyingTo => 'REPLYING TO';

  @override
  String get messageInputHintSending => 'Sending...';

  @override
  String get messageInputHintAddDescription => 'Add a description...';

  @override
  String get messageInputHintTypeMessage => 'Type a message...';

  @override
  String get messageInputAttachImage => 'Image';

  @override
  String get messageInputAttachDocument => 'Document';

  @override
  String get messageInputAttachSend => 'Send';

  @override
  String get messageInputAttachContact => 'Contact';

  @override
  String get messageInputAttachLocation => 'Location';

  @override
  String get messageInputAttachComingSoon => 'Coming soon';

  @override
  String get messageInputNoRecipientRemote =>
      'No recipient selected to send remote attachment.';

  @override
  String get messageInputRemoteUrlEmpty =>
      'Remote attachment URL cannot be empty.';

  @override
  String get messageInputFailedSendRemoteRecipient =>
      'Failed to send remote attachment: Recipient not available.';

  @override
  String get messageInputFailedSendRemote => 'Failed to send remote attachment';

  @override
  String get conversationSettingsSheetTitle => 'Conversation settings';

  @override
  String get conversationSettingsSheetBlockConversation => 'Block conversation';

  @override
  String get conversationSettingsSheetAllowedSubtitle =>
      'Messages from this conversation reach your inbox.';

  @override
  String get conversationSettingsSheetBlockedSubtitle =>
      'This conversation is blocked.';

  @override
  String get conversationSettingsSheetTrimMessagesLabel => 'Trim long messages';

  @override
  String conversationSettingsSheetTrimMessagesOn(int count) {
    return 'Messages over $count characters collapse behind a Show more. Applies to all chats.';
  }

  @override
  String get conversationSettingsSheetTrimMessagesOff =>
      'Every message shows in full. Applies to all chats.';

  @override
  String get conversationSettingsSheetTrimAtLabel => 'TRIM AT';

  @override
  String get conversationSettingsSheetTrimUnit => 'chars';

  @override
  String get conversationSettingsSheetDebugModeLabel => 'Debug mode';

  @override
  String get conversationSettingsSheetDebugModeSubtitle =>
      'Show raw message metadata.';

  @override
  String get conversationSettingsSheetExportMessagesLabel => 'Export messages';

  @override
  String get conversationSettingsSheetExportMessagesSubtitle =>
      'Save chat history to a text file.';

  @override
  String get conversationSettingsSheetDumpLogLabel => 'Dump log';

  @override
  String get conversationSettingsSheetDumpLogSubtitle =>
      'Save recent log entries to a file.';

  @override
  String get conversationSettingsSheetConsentUpdateFailed =>
      'Failed to update consent state';

  @override
  String get conversationSettingsSheetLogBufferEmpty => 'Log buffer is empty';

  @override
  String conversationSettingsSheetDebugLogShareText(Object ts) {
    return 'PublicOS debug log ($ts)';
  }

  @override
  String get conversationSettingsSheetDumpLogFailed => 'Failed to dump log';

  @override
  String get conversationSettingsSheetNoMessages =>
      'No messages in this conversation';

  @override
  String get conversationSettingsSheetSelectDateRange =>
      'Select date range to export';

  @override
  String get conversationSettingsSheetExportAction => 'Export';

  @override
  String get conversationSettingsSheetNoMessagesInRange =>
      'No messages in selected range';

  @override
  String conversationSettingsSheetChatExportShareText(Object ts) {
    return 'Chat export ($ts)';
  }

  @override
  String get conversationSettingsSheetExportFailed => 'Export failed';

  @override
  String get conversationSettingsSheetMediaTab => 'Media';

  @override
  String get conversationSettingsSheetNoMedia =>
      'No media shared in this conversation yet.';

  @override
  String get conversationSettingsSheetDocsTab => 'Docs';

  @override
  String get conversationSettingsSheetNoDocs =>
      'No documents shared in this conversation yet.';

  @override
  String get debugChatViewTopicCopied => 'Topic copied';

  @override
  String get debugChatViewMessageDataCopied => 'Message data copied';

  @override
  String get messageWidgetShowMore => 'Show more';

  @override
  String get messageWidgetShowLess => 'Show less';

  @override
  String get messageWidgetUnsupportedMessage => 'Unsupported message';

  @override
  String messageWidgetUnsupportedMessageType(Object type) {
    return 'Unsupported message type: $type';
  }

  @override
  String messageWidgetTapped(Object label) {
    return 'Tapped: $label';
  }

  @override
  String get messageWidgetUnknownChain => 'Unknown chain';

  @override
  String messageWidgetChainNumbered(Object chainId) {
    return 'Chain $chainId';
  }

  @override
  String get messageWidgetTransactionReceipt => 'Transaction receipt';

  @override
  String get messageWidgetTxFrom => 'From';

  @override
  String get messageWidgetTxTo => 'To';

  @override
  String get messageWidgetTxRequestedBy => 'Requested by';

  @override
  String get messageWidgetTxChain => 'Chain';

  @override
  String get messageWidgetTxToken => 'Token';

  @override
  String get messageWidgetTxAmount => 'Amount';

  @override
  String get messageWidgetViewOnExplorer => 'View on explorer';

  @override
  String get messageWidgetReceivedPrefix => 'Received';

  @override
  String get messageWidgetTransactionRequest => 'Transaction request';

  @override
  String messageWidgetChainCalls(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calls',
      one: '1 call',
    );
    return '$name · $_temp0';
  }

  @override
  String get messageWidgetSendPrefix => 'Send';

  @override
  String messageWidgetCallTarget(Object target) {
    return 'Call → $target';
  }

  @override
  String get messageWidgetReviewAndPay => 'Review & pay';

  @override
  String get messageWidgetPayRequestTitle => 'Pay request';

  @override
  String get messageWidgetPayRequestConfirm => 'Pay';

  @override
  String get messageWidgetXmtpTxRequestOrigin => 'XMTP transaction request';

  @override
  String get messageWidgetFailedToLoadImage => 'Failed to load image';

  @override
  String get messageWidgetInvalidAttachmentFormat =>
      'Invalid attachment format';

  @override
  String get messageWidgetInvalidRemoteAttachmentFormat =>
      'Invalid remote attachment format';

  @override
  String get messageWidgetCouldntLoadAttachment =>
      'Couldn\'t load attachment.\nAsk the sender to share it again.';

  @override
  String get messageWidgetInvalidReplyFormat => 'Invalid reply format';

  @override
  String get messageWidgetQuotedAttachment => '📎 Attachment';

  @override
  String messageWidgetGalleryTitle(int count) {
    return '$count attachments';
  }

  @override
  String get messageWidgetQuotedReaction => '❤️ Reaction';

  @override
  String get messageWidgetQuotedReply => '💬 Reply';

  @override
  String get messageWidgetMessage => 'Message';

  @override
  String get messageWidgetYou => 'You';

  @override
  String get messageWidgetLoading => 'Loading...';

  @override
  String get messageWidgetMessageNotAvailable => 'Message not available';

  @override
  String get messageWidgetFailedToSend => 'Failed to send';

  @override
  String get messageWidgetSending => 'Sending...';

  @override
  String get messageWidgetSeen => 'seen';

  @override
  String get messageWidgetClipboardAttachment => 'Attachment';

  @override
  String get messageWidgetClipboardRemoteAttachment => 'Remote Attachment';

  @override
  String get messageWidgetClipboardReaction => 'Reaction';

  @override
  String get messageWidgetDismissReactions => 'Dismiss reactions';

  @override
  String get messageWidgetStickerSaved => 'Sticker saved';

  @override
  String get messageWidgetStickerAlreadySaved => 'Already in your stickers';

  @override
  String get messageWidgetStickerSaveFailed => 'Couldn\'t save that sticker';

  @override
  String get messagesChipBarNoKey => 'Keychain';

  @override
  String get messagesChipBarRequests => 'Requests';

  @override
  String get messagesChipBar1on1 => '1-1';

  @override
  String get messagesChipBarGroups => 'Groups';

  @override
  String get messagesChipBarNewGroup => 'New Group';

  @override
  String get messagesChipBarInboxIds => 'Inbox IDs';

  @override
  String get messagesChipBarSettings => 'Settings';

  @override
  String get reactionDetailsSheetTitle => 'Reactions';

  @override
  String get reactionDetailsSheetRemoveFailed => 'Failed to remove reaction';

  @override
  String get reactionDetailsSheetNoReactions => 'No reactions yet.';

  @override
  String get reactionDetailsSheetLoadFailed => 'Couldn\'t load who reacted.';

  @override
  String get reactionDetailsSheetAllTab => 'All';

  @override
  String get reactionDetailsSheetYouBadge => 'You';

  @override
  String get reactionDetailsSheetRemoveTooltip => 'Remove your reaction';

  @override
  String get messagesSettingsSheetTitle => 'Message settings';

  @override
  String get messagesSettingsSheetSendReceiptsLabel => 'Send read receipts';

  @override
  String get messagesSettingsSheetSendReceiptsSubtitle =>
      'Others can see when you\'ve read their messages.';

  @override
  String get messagesSettingsSheetShowReceiptsLabel => 'Show read receipts';

  @override
  String get messagesSettingsSheetShowReceiptsSubtitle =>
      'See when others have read yours.';

  @override
  String get messagesSettingsSheetShowBannersLabel => 'Show contact banners';

  @override
  String get messagesSettingsSheetShowBannersSubtitle =>
      'Display contact banner images behind conversation rows.';

  @override
  String get messagesSettingsSheetBlockedConvosLabel => 'Blocked conversations';

  @override
  String get messagesSettingsSheetBlockedConvosSubtitle =>
      'Review and restore blocked DMs and groups.';

  @override
  String get messagesSettingsSheetDownloadDbLabel => 'Download database backup';

  @override
  String get messagesSettingsSheetDownloadDbSubtitle =>
      'Save this device\'s message database file. With its encryption key it restores on a new device as the SAME device — no device slot used.';

  @override
  String get messagesSettingsSheetCopyDbKeyLabel => 'Copy encryption key';

  @override
  String get messagesSettingsSheetCopyDbKeySubtitle =>
      'Copy the key that unlocks the database backup. You need both the file and this key to restore.';

  @override
  String get messagesSettingsSheetDownloadDbWarning =>
      'The database file is useless without its encryption key. Save both, and keep the key secret — anyone with both can read your messages.';

  @override
  String get messagesSettingsSheetCopyDbKeyWarning =>
      'This key unlocks your message database. Anyone with it and your database file can read your messages. Copy it somewhere safe.';

  @override
  String get messagesSettingsSheetPreparingDb =>
      'Preparing database…\n\nDo not close the app.';

  @override
  String get messagesSettingsSheetNoActiveKey => 'No messaging key is loaded.';

  @override
  String get messagesSettingsSheetKeyCopied =>
      'Encryption key copied to clipboard.';

  @override
  String get messagesSettingsSheetDownloadBackupLabel => 'Download backup';

  @override
  String get messagesSettingsSheetDownloadBackupSubtitle =>
      'Encrypted archive of this inbox, protected by a password. Restores natively on any device of this account.';

  @override
  String get messagesSettingsSheetRestoreBackup => 'Restore backup';

  @override
  String get messagesSettingsSheetRestoreBackupSubtitle =>
      'Import a .xmtpBak file from this account. Needs the password it was created with.';

  @override
  String get messagesSettingsSheetBackupPasswordTitle => 'Backup password';

  @override
  String get messagesSettingsSheetBackupPasswordMessage =>
      'This password encrypts your backup. You will need it to restore — there is no way to recover it if lost.';

  @override
  String get messagesSettingsSheetCreateBackup => 'Create backup';

  @override
  String get messagesSettingsSheetEncryptingBackup =>
      'Encrypting backup…\n\nDo not close the app.';

  @override
  String get messagesSettingsSheetOpeningShareSheet => 'Opening share sheet…';

  @override
  String get messagesSettingsSheetBackupShareSubject => 'XMTP backup';

  @override
  String messagesSettingsSheetBackupReady(Object fileName) {
    return 'Backup ready: $fileName';
  }

  @override
  String get messagesSettingsSheetBackupFailed => 'Backup failed.';

  @override
  String get messagesSettingsSheetBackupFileTypeLabel => 'PublicOS XMTP backup';

  @override
  String get messagesSettingsSheetCouldNotOpenFile => 'Could not open file.';

  @override
  String get messagesSettingsSheetRestorePasswordMessage =>
      'Enter the password this backup was created with.';

  @override
  String get messagesSettingsSheetContinue => 'Continue';

  @override
  String get messagesSettingsSheetReadingBackup => 'Reading backup…';

  @override
  String get messagesSettingsSheetCouldNotOpenBackupTitle =>
      'Could not open backup';

  @override
  String get messagesSettingsSheetCouldNotOpenBackupMessage =>
      'Wrong password, or this archive belongs to a different account. Nothing was imported.';

  @override
  String get messagesSettingsSheetRestoringBackup =>
      'Restoring backup…\n\nDo not close the app.';

  @override
  String get messagesSettingsSheetRestoreFailed => 'Restore failed';

  @override
  String get messagesSettingsSheetPasswordLabel => 'Password';

  @override
  String get messagesSettingsSheetConfirmPasswordLabel => 'Confirm password';

  @override
  String get messagesSettingsSheetEnterPassword => 'Enter a password.';

  @override
  String get messagesSettingsSheetPasswordsNoMatch => 'Passwords do not match.';

  @override
  String get messagesSettingsSheetRestoreThisBackup => 'Restore this backup?';

  @override
  String get messagesSettingsSheetMetaCreated => 'Created';

  @override
  String get messagesSettingsSheetMetaContents => 'Contents';

  @override
  String get messagesSettingsSheetRestoreMergeNote =>
      'Restored conversations are merged into this inbox. Existing data is kept.';

  @override
  String get messagesSettingsSheetRestore => 'Restore';

  @override
  String get messagesSettingsSheetOk => 'OK';

  @override
  String networkAccessSheetsExtendHeader(Object provider) {
    return 'EXTEND $provider';
  }

  @override
  String networkAccessSheetsRenewTitle(Object provider) {
    return 'Extend $provider subscription';
  }

  @override
  String networkAccessSheetsRenewBody(Object provider) {
    return '$provider fee paid from your wallet to your provider.';
  }

  @override
  String get networkAccessSheetsPaying => 'PAYING…';

  @override
  String networkAccessSheetsPayProvider(Object provider) {
    return 'PAY $provider';
  }

  @override
  String networkAccessSheetsExtendTitle(Object slug) {
    return 'Extend $slug';
  }

  @override
  String networkAccessSheetsExtendCitizenBody(Object provider) {
    return 'The network mints the $provider fee for you. You don\'t pay anything.';
  }

  @override
  String get networkAccessSheetsExtending => 'EXTENDING…';

  @override
  String get networkAccessSheetsExtend => 'EXTEND';

  @override
  String get networkAccessSheetsDomainRenewHeader => 'RENEW DOMAIN';

  @override
  String get networkAccessSheetsDomainPay => 'PAY DOMAIN';

  @override
  String get networkAccessSheetsDomainRenewTitle => 'Renew your name';

  @override
  String get networkAccessSheetsDomainPayTitle => 'Hold your name';

  @override
  String get networkAccessSheetsDomainBody =>
      'The domain fee keeps your name and your write access to the chain. Priced by name length. 98% is burned, 2% is shared with verified PublicOS Domains.';

  @override
  String get networkAccessSheetsName => 'Name';

  @override
  String networkAccessSheetsNameChars(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chars',
      one: '1 char',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String get networkAccessSheetsDomainRenewAction => 'RENEW';

  @override
  String get newAccountDialogErrWrongKind =>
      'This claim is for adding a session, not creating an account.';

  @override
  String get newAccountDialogErrMalformed => 'Malformed claim payload.';

  @override
  String get newAccountDialogAccountCreated => 'Account created';

  @override
  String get newAccountDialogSuccessBody =>
      'The new account is on-chain. The scanned key is its first session.';

  @override
  String get newAccountDialogInvalidClaim => 'Invalid code';

  @override
  String get newAccountDialogClose => 'CLOSE';

  @override
  String get newAccountDialogCreateTitle => 'Create account';

  @override
  String get newAccountDialogSponsorPrompt =>
      'Someone is asking you to sponsor a new account.';

  @override
  String get newAccountDialogSponsorPromptPaused =>
      'Someone is asking you to sponsor a new account. Creation is paused network-wide, so this will spend one of your invites.';

  @override
  String get newAccountDialogLabelUsername => 'USERNAME';

  @override
  String get newAccountDialogLabelSession => 'SESSION';

  @override
  String get newAccountDialogLabelExpiresIn => 'EXPIRES IN';

  @override
  String get newAccountDialogExpired => 'expired';

  @override
  String get newAccountDialogRootInviteFree =>
      'Root account — creating invite-free';

  @override
  String get newAccountDialogNoInvitesLeft =>
      'No invites left — wait for the next wave.';

  @override
  String newAccountDialogInvitesLeft(Object count) {
    return 'Invites left: $count';
  }

  @override
  String get newAccountDialogClaimExpired =>
      'This request expired. Make a new QR where you started it.';

  @override
  String get newAccountDialogConfirm => 'SIGN';

  @override
  String get newAccountDialogUseInvite => 'USE INVITE';

  @override
  String get newAccountDialogReservedName => 'Reserved name';

  @override
  String newAccountDialogNameCooldown(Object days) {
    return 'Name in cooldown for ${days}d';
  }

  @override
  String get newAccountDialogCopied => 'Copied';

  @override
  String get nftInfoDialogVerified => 'Verified';

  @override
  String get nftInfoDialogOwnsThisNft => 'owns this NFT';

  @override
  String get nftInfoDialogChain => 'Chain';

  @override
  String get nftInfoDialogMint => 'Mint';

  @override
  String nftInfoDialogChainNumber(Object chain) {
    return 'Chain $chain';
  }

  @override
  String get nftInfoDialogContract => 'Contract';

  @override
  String get nftInfoDialogTokenId => 'Token ID';

  @override
  String get nftInfoDialogStandard => 'Standard';

  @override
  String get nftInfoDialogTraits => 'TRAITS';

  @override
  String get nftInfoDialogExplorer => 'Explorer';

  @override
  String get nftInfoDialogMarketplace => 'Marketplace';

  @override
  String get nftInfoDialogUseAsAvatar => 'USE AS AVATAR';

  @override
  String get nftInfoDialogSetAsProfilePictureTitle => 'Set as profile picture?';

  @override
  String get nftInfoDialogSetAsProfilePictureBody =>
      'This sets this NFT as your avatar. You\'ll only appear verified if you own it.';

  @override
  String get nftInfoDialogSetAsAvatar => 'Set as avatar';

  @override
  String nftInfoDialogCopied(Object label) {
    return '$label copied';
  }

  @override
  String get childrenSheetTitle => 'Children';

  @override
  String childrenSheetSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count child orgs',
      one: '1 child org',
    );
    return '$_temp0';
  }

  @override
  String enhancedVoteCardVotesCount(Object yes, Object threshold) {
    return '$yes/$threshold votes';
  }

  @override
  String get enhancedVoteCardCastVote => 'CAST VOTE';

  @override
  String enhancedVoteCardSendValue(Object value) {
    return 'Send $value';
  }

  @override
  String enhancedVoteCardExecuteMethod(Object method) {
    return 'Execute $method';
  }

  @override
  String get enhancedVoteCardContractCall => 'Contract Call';

  @override
  String get enhancedVoteCardGroupWallet => 'Group Wallet';

  @override
  String get enhancedVoteCardStarted => 'Started';

  @override
  String get enhancedVoteCardExecuted => 'Executed';

  @override
  String get enhancedVoteCardEnded => 'Ended';

  @override
  String get enhancedVoteCardTransactionDetails => 'Transaction Details';

  @override
  String get enhancedVoteCardType => 'Type';

  @override
  String get enhancedVoteCardEthTransfer => 'ETH Transfer';

  @override
  String get enhancedVoteCardTo => 'To';

  @override
  String get enhancedVoteCardAmount => 'Amount';

  @override
  String get enhancedVoteCardMethod => 'Method';

  @override
  String get enhancedVoteCardParameters => 'Parameters';

  @override
  String get enhancedVoteCardInitiatedBy => 'Initiated by';

  @override
  String enhancedVoteCardVotersCount(Object count) {
    return 'Voters ($count)';
  }

  @override
  String get enhancedVoteCardSearchVoters => 'Search voters...';

  @override
  String get enhancedVoteCardNoVotersMatch => 'No voters match search';

  @override
  String get enhancedVoteCardNoVotersYet => 'No voters yet';

  @override
  String enhancedVoteCardMinutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String enhancedVoteCardHoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String enhancedVoteCardDaysAgoShort(Object days) {
    return '${days}d ago';
  }

  @override
  String get enhancedVoteCardToday => 'Today';

  @override
  String get enhancedVoteCardYesterday => 'Yesterday';

  @override
  String enhancedVoteCardDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String enhancedVoteCardWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String enhancedVoteCardTodayAt(Object time) {
    return 'Today $time';
  }

  @override
  String enhancedVoteCardYesterdayAt(Object time) {
    return 'Yesterday $time';
  }

  @override
  String enhancedVoteCardWeekdayAt(Object weekday, Object time) {
    return '$weekday $time';
  }

  @override
  String get enhancedVoteCardWeekdayMon => 'Mon';

  @override
  String get enhancedVoteCardWeekdayTue => 'Tue';

  @override
  String get enhancedVoteCardWeekdayWed => 'Wed';

  @override
  String get enhancedVoteCardWeekdayThu => 'Thu';

  @override
  String get enhancedVoteCardWeekdayFri => 'Fri';

  @override
  String get enhancedVoteCardWeekdaySat => 'Sat';

  @override
  String get enhancedVoteCardWeekdaySun => 'Sun';

  @override
  String get groupVotingViewInvalidGroupAddress => 'Invalid group address';

  @override
  String get groupVotingViewLoadFailed => 'Failed to load management data';

  @override
  String get groupVotingViewVoteRecorded => 'Vote recorded';

  @override
  String get groupVotingViewUnableToCastVote => 'Unable to cast vote';

  @override
  String groupVotingViewMembersFailed(Object count, Object detail) {
    return '$count failed — $detail';
  }

  @override
  String groupVotingViewAlreadyMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already members.',
      one: 'Already a member.',
    );
    return '$_temp0';
  }

  @override
  String groupVotingViewVotesToAddStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes to add members started.',
      one: 'Vote to add member started.',
    );
    return '$_temp0';
  }

  @override
  String get groupVotingViewVoteToRemoveStarted =>
      'Vote to remove member started.';

  @override
  String get groupVotingViewQuorum => 'Quorum';

  @override
  String get groupVotingViewQuorumSubtitle =>
      'Share of weight that must participate';

  @override
  String get groupVotingViewVoteDuration => 'Vote duration';

  @override
  String get groupVotingViewVoteDurationSubtitle =>
      'How long a vote stays open';

  @override
  String get groupVotingViewDelegate => 'Your delegate';

  @override
  String get groupVotingViewDelegateNone => 'You vote your own weight';

  @override
  String groupVotingViewDelegateTo(Object name) {
    return 'Delegated to $name';
  }

  @override
  String get groupVotingViewMainSafe => 'Main Safe';

  @override
  String get groupVotingViewSend => 'Send';

  @override
  String get groupVotingViewAddressCopied => 'Address copied';

  @override
  String get groupVotingViewVoting => 'Voting';

  @override
  String groupVotingViewVotingMetaLive(Object count) {
    return '1 live · $count past';
  }

  @override
  String groupVotingViewVotingMetaPast(Object count) {
    return '$count past';
  }

  @override
  String get groupVotingViewActionHistory => 'Action history';

  @override
  String get groupVotingViewNoPastActions => 'No past actions yet';

  @override
  String get groupVotingViewPastProposals =>
      'Past proposals · executed, cancelled, expired';

  @override
  String get groupVotingViewWallets => 'Wallets';

  @override
  String get groupVotingViewNoWallets => 'No wallets';

  @override
  String get groupVotingViewNoWalletsSubtitle =>
      'Add a wallet to make it part of this group';

  @override
  String get groupVotingViewAddWallet => 'Add wallet';

  @override
  String get groupVotingViewRemove => 'Remove';

  @override
  String groupVotingViewProtocolWallet(Object protocol) {
    return '$protocol wallet';
  }

  @override
  String get groupVotingViewTagPrimary => 'primary';

  @override
  String get groupVotingViewRecords => 'Records';

  @override
  String get groupVotingViewNoRecords => 'No records';

  @override
  String get groupVotingViewNoRecordsSubtitle =>
      'Records appear here once the org sets any';

  @override
  String get groupVotingViewValueCopied => 'Value copied';

  @override
  String get groupVotingViewInboxIds => 'Inbox IDs';

  @override
  String get groupVotingViewManageInboxIds => 'Manage inbox IDs';

  @override
  String get groupVotingViewManageInboxIdsSubtitle =>
      'Add / remove / relabel registered IDs';

  @override
  String get groupVotingViewRecordTypeProfile => 'profile';

  @override
  String get groupVotingViewRecordTypeSettings => 'settings';

  @override
  String get groupVotingViewRecordTypeRouter => 'router';

  @override
  String get groupVotingViewRecordTypeCustom => 'custom';

  @override
  String get groupVotingViewRecordTypeSystem => 'system';

  @override
  String get groupVotingViewExpired => 'expired';

  @override
  String get groupVotingViewCopy => 'COPY';

  @override
  String get groupVotingViewMembers => 'members';

  @override
  String get groupVotingViewParent => 'parent';

  @override
  String get groupVotingViewChildren => 'children';

  @override
  String get groupVotingViewLiveVote => 'LIVE VOTE';

  @override
  String get groupVotingViewVoters => 'VOTERS';

  @override
  String groupVotingViewYesCount(Object count) {
    return '$count yes';
  }

  @override
  String groupVotingViewNeededCount(Object count) {
    return '$count needed';
  }

  @override
  String get delegateVoteSheetTitle => 'Delegate your vote';

  @override
  String get delegateVoteSheetBlurb =>
      'Pick a member to carry your voting weight. It applies to future votes, never one already open, and you can take it back anytime.';

  @override
  String delegateVoteSheetCap(Object used, Object cap) {
    return '$used of $cap delegations used';
  }

  @override
  String get delegateVoteSheetVoteMyself => 'Vote myself';

  @override
  String get delegateVoteSheetVoteMyselfSubtitle =>
      'Keep your own voting weight';

  @override
  String get delegateVoteSheetDelegateTo => 'DELEGATE TO A MEMBER';

  @override
  String get delegateVoteSheetNoMembers =>
      'No other members to delegate to yet';

  @override
  String get delegateVoteSheetConfirm => 'DELEGATE';

  @override
  String get delegateVoteSheetConfirmClear => 'VOTE MYSELF';

  @override
  String get delegateVoteSheetErrorFailed => 'Could not update delegation';

  @override
  String get groupVotingViewCastYesVote => 'CAST YES VOTE';

  @override
  String get groupVotingViewCastFor => 'FOR';

  @override
  String get groupVotingViewCastAgainst => 'AGAINST';

  @override
  String get groupVotingViewCastAbstain => 'ABSTAIN';

  @override
  String groupVotingViewTally(
      Object forCount, Object againstCount, Object abstainCount) {
    return 'For $forCount · Against $againstCount · Abstain $abstainCount';
  }

  @override
  String groupVotingViewQuorumCount(Object count) {
    return '$count to quorum';
  }

  @override
  String get groupVotingViewActionSetRecord => 'SET RECORD';

  @override
  String get groupVotingViewActionDeleteRecord => 'DELETE RECORD';

  @override
  String get groupVotingViewActionAddMember => 'ADD MEMBER';

  @override
  String get groupVotingViewActionRemoveMember => 'REMOVE MEMBER';

  @override
  String get groupVotingViewActionSetThreshold => 'SET THRESHOLD';

  @override
  String get groupVotingViewActionExecuteSafeTx => 'EXECUTE SAFE TX';

  @override
  String get groupVotingViewVoteEnded => 'ended';

  @override
  String get groupVotingViewIndividualAccount => 'Individual Account';

  @override
  String get groupVotingViewIndividualAccountBody =>
      'Group governance features are only available for group accounts.';

  @override
  String get groupVotingViewTryAgain => 'Try Again';

  @override
  String get historySheetTitle => 'Action history';

  @override
  String historySheetPastActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count past actions',
      one: '1 past action',
    );
    return '$_temp0';
  }

  @override
  String get historySheetStatusCancelled => 'cancelled';

  @override
  String get historySheetStatusExpired => 'expired';

  @override
  String get historySheetStatusActive => 'active';

  @override
  String get historySheetStatusFailed => 'failed';

  @override
  String get historySheetEmptyTitle => 'No past actions';

  @override
  String get historySheetEmptyBody =>
      'Past proposals will appear here once any are executed, cancelled, or expired.';

  @override
  String get membersSheetRemoveTitle => 'Remove member?';

  @override
  String membersSheetRemoveBody(Object name) {
    return 'Start a vote to remove $name from this group?';
  }

  @override
  String get membersSheetRemove => 'Remove';

  @override
  String get membersSheetTitle => 'Members';

  @override
  String membersSheetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get membersSheetAddMember => 'ADD MEMBER';

  @override
  String get startNewVoteSheetActionSetQuorum => 'Set quorum';

  @override
  String get startNewVoteSheetActionSetDuration => 'Set vote duration';

  @override
  String get startNewVoteSheetActionAddWallet => 'Add wallet';

  @override
  String get startNewVoteSheetActionRemoveWallet => 'Remove wallet';

  @override
  String get startNewVoteSheetActionAddModule => 'Add module';

  @override
  String get startNewVoteSheetActionRemoveModule => 'Remove module';

  @override
  String get startNewVoteSheetDescSetQuorum =>
      'Set the share of voting weight that must participate for a vote to pass (For + Abstain). Applies to future votes.';

  @override
  String get startNewVoteSheetDescSetDuration =>
      'Set how long a vote stays open before it expires. Applies to future votes.';

  @override
  String get startNewVoteSheetDescAddWallet =>
      'Register a new wallet address for this group';

  @override
  String get startNewVoteSheetDescRemoveWallet =>
      'Remove an existing wallet from this group';

  @override
  String get startNewVoteSheetDescAddModule =>
      'Enable a module on the group Safe';

  @override
  String get startNewVoteSheetDescRemoveModule =>
      'Disable a module from the group Safe';

  @override
  String get startNewVoteSheetQuorumCurrentPrefix => 'Current quorum: ';

  @override
  String get startNewVoteSheetQuorumLabel => 'New quorum (%)';

  @override
  String get startNewVoteSheetQuorumHint => '0–100 (0 = simple majority)';

  @override
  String get startNewVoteSheetErrorQuorumRange =>
      'Quorum must be between 0 and 100%';

  @override
  String get startNewVoteSheetDurationCurrentPrefix => 'Current duration: ';

  @override
  String get startNewVoteSheetDurationLabel => 'New duration (hours)';

  @override
  String startNewVoteSheetDurationHint(Object min, Object max) {
    return '$min–$max hours';
  }

  @override
  String startNewVoteSheetDurationHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
      zero: 'not set',
    );
    return '$_temp0';
  }

  @override
  String get startNewVoteSheetErrorDurationRange =>
      'Duration must be between 1 hour and 30 days';

  @override
  String get startNewVoteSheetErrorLoadFailed =>
      'Failed to load group information';

  @override
  String get startNewVoteSheetErrorWalletNameRequired =>
      'Wallet name is required';

  @override
  String get startNewVoteSheetErrorWalletAddressRequired =>
      'Wallet address is required';

  @override
  String get startNewVoteSheetErrorInvalidWalletAddress =>
      'Invalid wallet address format';

  @override
  String get startNewVoteSheetErrorSelectWallet =>
      'Please select a wallet to remove';

  @override
  String get startNewVoteSheetErrorCannotRemoveMain =>
      'Cannot remove the main wallet';

  @override
  String get startNewVoteSheetErrorAddressRequired => 'Address is required';

  @override
  String get startNewVoteSheetErrorInvalidAddress => 'Invalid address format';

  @override
  String get startNewVoteSheetErrorStartFailed =>
      'Failed to start vote. Please try again.';

  @override
  String get startNewVoteSheetCreateProposal => 'CREATE PROPOSAL';

  @override
  String get startNewVoteSheetModuleAddressLabel => 'Module address';

  @override
  String get startNewVoteSheetWalletNameLabel => 'Wallet name';

  @override
  String get startNewVoteSheetWalletNameHint => 'e.g., treasury, operations';

  @override
  String get startNewVoteSheetWalletAddressLabel => 'Wallet address';

  @override
  String get startNewVoteSheetNoRemovableWallets =>
      'No additional wallets to remove. Only the main wallet exists.';

  @override
  String get startNewVoteSheetSelectWalletHeader => 'SELECT WALLET';

  @override
  String startNewVoteSheetProtocolWalletTitle(Object protocol) {
    return '$protocol wallet';
  }

  @override
  String get startNewVoteSheetLoading => 'Loading group data...';

  @override
  String get voteCardCastVote => 'CAST VOTE';

  @override
  String get voteCardPending => 'Pending';

  @override
  String voteCardVotesOfThreshold(Object threshold) {
    return ' / $threshold votes';
  }

  @override
  String get voteCardDetails => 'Details';

  @override
  String get voteCardInitiatedBy => 'INITIATED BY';

  @override
  String get voteCardStarted => 'Started';

  @override
  String get voteCardExecuted => 'Executed';

  @override
  String get voteCardEnded => 'Ended';

  @override
  String get voteCardCopy => 'Copy';

  @override
  String voteCardCopied(Object name) {
    return 'Copied $name';
  }

  @override
  String voteCardVoters(Object count) {
    return 'Voters ($count)';
  }

  @override
  String get voteCardSearchHint => 'Search...';

  @override
  String get voteCardNoMatches => 'No matches';

  @override
  String get voteCardNoVoters => 'No voters';

  @override
  String voteCardMinutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String voteCardHoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String voteCardDaysAgoShort(Object days) {
    return '${days}d ago';
  }

  @override
  String get voteCardToday => 'Today';

  @override
  String get voteCardYesterday => 'Yesterday';

  @override
  String voteCardDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String voteCardWeeksAgo(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String voteCardTodayAt(Object time) {
    return 'Today $time';
  }

  @override
  String voteCardYesterdayAt(Object time) {
    return 'Yesterday $time';
  }

  @override
  String voteCardWeekdayAt(Object weekday, Object time) {
    return '$weekday $time';
  }

  @override
  String get voteCardWeekdayMon => 'Mon';

  @override
  String get voteCardWeekdayTue => 'Tue';

  @override
  String get voteCardWeekdayWed => 'Wed';

  @override
  String get voteCardWeekdayThu => 'Thu';

  @override
  String get voteCardWeekdayFri => 'Fri';

  @override
  String get voteCardWeekdaySat => 'Sat';

  @override
  String get voteCardWeekdaySun => 'Sun';

  @override
  String get votersSheetTitle => 'Voters';

  @override
  String votersSheetVoted(Object count) {
    return 'VOTED · $count';
  }

  @override
  String votersSheetPending(Object count) {
    return 'PENDING · $count';
  }

  @override
  String get votersSheetStatFor => 'FOR';

  @override
  String get votersSheetStatAgainst => 'AGAINST';

  @override
  String get votersSheetStatAbstain => 'ABSTAIN';

  @override
  String get votersSheetQuorum => 'QUORUM';

  @override
  String get inboxIdDropdownCopied => 'Inbox ID copied to clipboard';

  @override
  String get inboxIdDropdownSelectTitle => 'Select Inbox ID';

  @override
  String get inboxIdDropdownDefaultLabel => 'Default';

  @override
  String inboxIdSelectionDialogTitle(Object name) {
    return 'Select InboxID for $name';
  }

  @override
  String get inboxIdSelectionDialogSubtitle =>
      'Choose which inbox ID to add to the group';

  @override
  String get manageGroupInboxIdsSheetDefaultLabel => 'Inbox';

  @override
  String get manageGroupInboxIdsSheetLoadFailed => 'Failed to load inbox IDs';

  @override
  String get manageGroupInboxIdsSheetAddFailed => 'Add failed';

  @override
  String get manageGroupInboxIdsSheetRemoveFailed => 'Remove failed';

  @override
  String get manageGroupInboxIdsSheetLabelUpdateFailed => 'Label update failed';

  @override
  String get manageGroupInboxIdsSheetRemoveTitle => 'Remove from group?';

  @override
  String manageGroupInboxIdsSheetRemoveBody(Object label, Object group) {
    return 'Remove \"$label\" from $group. People will no longer be able to reach this group via this inbox ID.';
  }

  @override
  String get manageGroupInboxIdsSheetRemoveConfirm => 'Remove';

  @override
  String get manageGroupInboxIdsSheetEditLabelTitle => 'Edit label';

  @override
  String get manageGroupInboxIdsSheetLabelHint => 'Enter a new label';

  @override
  String get manageGroupInboxIdsSheetSave => 'Save';

  @override
  String get manageGroupInboxIdsSheetSheetTitle => 'Inbox IDs';

  @override
  String get manageGroupInboxIdsSheetManageKeys => 'MANAGE KEYS';

  @override
  String get manageGroupInboxIdsSheetEmptyTitle => 'No inbox IDs available';

  @override
  String get manageGroupInboxIdsSheetEmptyBody =>
      'Generate a key in your keychain to create inbox IDs.';

  @override
  String manageGroupInboxIdsSheetRegisteredTo(Object address) {
    return 'Registered to $address';
  }

  @override
  String get pickOrgMembersSheetTitle => 'Add members';

  @override
  String get pickOrgMembersSheetSubtitleEmpty => 'Pick contacts to propose';

  @override
  String pickOrgMembersSheetSubtitleSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String pickOrgMembersSheetAddButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ADD $count MEMBERS',
      one: 'ADD 1 MEMBER',
    );
    return '$_temp0';
  }

  @override
  String get pickOrgMembersSheetNoMatch => 'No contacts match your search.';

  @override
  String get pickOrgMembersSheetNoContacts => 'No PublicOS contacts available.';

  @override
  String get pickOrgMembersSheetSearchHint => 'Search contacts';

  @override
  String get createRecordPageSave => 'SAVE';

  @override
  String get createRecordPageCheckingVote => 'Checking for an open vote…';

  @override
  String get createRecordPageVoteInProgress =>
      'This organization already has its maximum of open votes; save once one ends';

  @override
  String get createRecordPageHeaderEdit => 'EDIT RECORD';

  @override
  String get createRecordPageHeaderAdd => 'ADD RECORD';

  @override
  String get createRecordPageHeaderPickPlatform => 'PICK PLATFORM';

  @override
  String get createRecordPageHeaderSocial => 'SOCIAL';

  @override
  String get createRecordPageHeaderTextCard => 'TEXT CARD';

  @override
  String get createRecordPageHeaderImage => 'IMAGE';

  @override
  String get createRecordPageHeaderNftCard => 'NFT CARD';

  @override
  String get createRecordPageHeaderAppCard => 'APP CARD';

  @override
  String get createRecordPageHeaderUnknownCard => 'CARD';

  @override
  String createRecordPageAppCardSizeLead(String app) {
    return 'Published by $app. Its picture and contents come from the app; you choose how much room it gets on your profile, and the artwork adapts.';
  }

  @override
  String get createRecordPageAppCardGenericApp => 'an app';

  @override
  String get createRecordPageUnknownCardBody =>
      'This card is a kind this version of the app does not know how to edit, so nothing here can be changed safely.';

  @override
  String get createRecordPageUnknownCardHint =>
      'You can still move it around your profile, or remove it.';

  @override
  String get createRecordPageTypeSocialLabel => 'Social Link';

  @override
  String get createRecordPageTypeSocialDesc => 'Connect a platform';

  @override
  String get createRecordPageTypeTextLabel => 'Text Card';

  @override
  String get createRecordPageTypeTextDesc => 'Title, text, link';

  @override
  String get createRecordPageTypeImageLabel => 'Image';

  @override
  String get createRecordPageTypeImageDesc => 'Photo or graphic';

  @override
  String get createRecordPageTypeNftLabel => 'NFT card';

  @override
  String get createRecordPageTypeNftDesc => 'A verified NFT you own';

  @override
  String get createRecordPageExampleTitle => 'Title';

  @override
  String get createRecordPageHandleHint => 'handle';

  @override
  String get createRecordPageLabelHandle => 'HANDLE';

  @override
  String get createRecordPageLabelTitle => 'TITLE';

  @override
  String get createRecordPageCardTitleHint => 'Card title';

  @override
  String get createRecordPageLabelDescription => 'DESCRIPTION';

  @override
  String get createRecordPageDescriptionHint => 'Description text';

  @override
  String createRecordPageCardSize(int used, int max) {
    return '$used of $max bytes';
  }

  @override
  String createRecordPageCardTooLong(int over) {
    return 'Too long to save: $over bytes over. Shorten the text or the link.';
  }

  @override
  String get createRecordPageLabelLinkOptional => 'LINK (OPTIONAL)';

  @override
  String get createRecordPageLabelColor => 'COLOR';

  @override
  String get createRecordPageNoServerWarning =>
      'Set a Social Server (SSP) to upload your own images. You can still paste an image URL below.';

  @override
  String get createRecordPageLabelTitleOptional => 'TITLE (OPTIONAL)';

  @override
  String get createRecordPageImageTitleHint => 'Leave empty for no title';

  @override
  String get createRecordPageLabelWidth => 'WIDTH';

  @override
  String get createRecordPageLabelHeight => 'HEIGHT';

  @override
  String get createRecordPageBack => 'Back';

  @override
  String get createRecordPageClose => 'Close';

  @override
  String get createRecordPageCannotLoadImage => 'Cannot load image';

  @override
  String get createRecordPageNoImageYet => 'No image yet';

  @override
  String get createRecordPageHeaderCard => 'CARD';

  @override
  String get createRecordPageTypeCardLabel => 'Card';

  @override
  String get createRecordPageTypeCardDesc => 'Image, text, color, link';

  @override
  String get createRecordPageLabelBackground => 'BACKGROUND';

  @override
  String get createRecordPageBackgroundColor => 'Color';

  @override
  String get createRecordPageBackgroundGradient => 'Gradient';

  @override
  String get createRecordPageGradientFrom => 'From';

  @override
  String get createRecordPageGradientTo => 'To';

  @override
  String get createRecordPageImageNone => 'None';

  @override
  String get createRecordPageImageUpload => 'Upload';

  @override
  String get createRecordPageLabelSize => 'SIZE';

  @override
  String get createRecordPageSizeNote =>
      'cells on the 4-column profile grid. Tap a square to set the corner.';

  @override
  String get createRecordPageNoServerWarningCard =>
      'Set a Social Server (SSP) to upload images and pick from your uploads.';

  @override
  String get createTabSheetTitleEdit => 'Edit tab';

  @override
  String get createTabSheetTitleNew => 'New tab';

  @override
  String get createTabSheetKindWeb => 'Web page';

  @override
  String get createTabSheetKindChannel => 'Channel';

  @override
  String get createTabSheetFieldLabel => 'LABEL';

  @override
  String get createTabSheetLabelHint => 'Tab label (e.g. My Blog)';

  @override
  String get createTabSheetFieldChannelUrl => 'CHANNEL URL';

  @override
  String get createTabSheetFieldWebUrl => 'WEB PAGE URL';

  @override
  String get createTabSheetFeedFormatsInfo =>
      'Supports JSON Feed, RSS 2.0, and Atom formats';

  @override
  String get createTabSheetSaving => 'SAVING…';

  @override
  String get createTabSheetEnterLabel => 'ENTER A LABEL';

  @override
  String get createTabSheetEnterValidFeedUrl => 'ENTER A VALID FEED URL';

  @override
  String get createTabSheetEnterValidUrl => 'ENTER A VALID URL';

  @override
  String get createTabSheetSaveChanges => 'SAVE CHANGES';

  @override
  String get createTabSheetCreateTab => 'CREATE TAB';

  @override
  String get createTabSheetSaveFailed => 'Failed to save tab';

  @override
  String get editBioSheetTitle => 'Bio';

  @override
  String get editBioSheetClose => 'Close';

  @override
  String get editBioSheetHint => 'Write something about yourself…';

  @override
  String editBioSheetCharCount(Object count, Object max) {
    return '$count/$max';
  }

  @override
  String get editBioSheetSectionTextColor => 'TEXT COLOR';

  @override
  String get editBioSheetSectionBorder => 'BORDER';

  @override
  String get editBioSheetShowBorder => 'Show border';

  @override
  String get editBioSheetBorderColor => 'Border color';

  @override
  String get editBioSheetBorderWidth => 'Border width';

  @override
  String get editBioSheetCornerRadius => 'Corner radius';

  @override
  String get editBioSheetSave => 'SAVE BIO';

  @override
  String get editProfileBackgroundSheetTitle => 'Profile Background';

  @override
  String get editProfileBackgroundSheetClose => 'Close';

  @override
  String get editProfileBackgroundSheetEmpty => 'No background';

  @override
  String get editProfileBackgroundSheetUnableToLoad => 'Unable to load image';

  @override
  String get editProfileBackgroundSheetNone => 'None';

  @override
  String get editProfileBackgroundSheetUpload => 'Upload';

  @override
  String get editProfileBackgroundSheetNoServer =>
      'Set a Social Server (SSP) to upload images and pick from your uploads. A direct link still works.';

  @override
  String get editProfileBackgroundSheetUrlLabel => 'Or paste an image link';

  @override
  String get editProfileBackgroundSheetUrlHint =>
      'https://example.com/background.jpg';

  @override
  String get editProfileBackgroundSheetInvalidUrl => 'Please enter a valid URL';

  @override
  String get editProfileBackgroundSheetSave => 'Save Background';

  @override
  String get editProfileBackgroundSheetRemove => 'Remove Background';

  @override
  String get editProfileBackgroundSheetSavingToChain => 'Saving to chain...';

  @override
  String get editProfileImageSheetSaving => 'SAVING…';

  @override
  String get editProfileImageSheetUseNft => 'USE NFT';

  @override
  String get editProfileImageSheetSaveNft => 'SAVE NFT';

  @override
  String get editProfileImageSheetSavePicture => 'SAVE PICTURE';

  @override
  String get editProfileImageSheetSaveBanner => 'SAVE BANNER';

  @override
  String get editProfileImageSheetSavingToChain => 'Saving to chain...';

  @override
  String get editProfileImageSheetSaveNftError => 'Failed to save NFT';

  @override
  String get editProfileImageSheetSaveImageError => 'Failed to save image';

  @override
  String get editProfileImageSheetRemoveImageError => 'Failed to remove image';

  @override
  String get editProfileImageSheetRemoveAvatarConfirmTitle =>
      'Remove profile picture?';

  @override
  String get editProfileImageSheetRemoveBannerConfirmTitle => 'Remove banner?';

  @override
  String get editProfileImageSheetRemoveConfirmBody =>
      'This clears the on-chain record. The image stays on your social server (you can re-link it later).';

  @override
  String get editProfileImageSheetRemoveAction => 'Remove';

  @override
  String get editProfileImageSheetNftLoadError => 'Couldn\'t load that NFT.';

  @override
  String get editProfileImageSheetNftResolving => 'Resolving your NFT…';

  @override
  String get editProfileImageSheetOwnNft => 'You own this NFT';

  @override
  String get editProfileImageSheetSourceImage => 'Image';

  @override
  String get editProfileImageSheetSourceImageSub =>
      'Upload, paste a URL, or pick from your uploads';

  @override
  String get editProfileImageSheetSourceEth => 'Ethereum NFT';

  @override
  String get editProfileImageSheetSourceEthSub =>
      'Your EVM NFTs, or enter one manually';

  @override
  String get editProfileImageSheetSourceSolana => 'Solana NFT';

  @override
  String get editProfileImageSheetSourceSolanaSub =>
      'Your Solana NFTs, or enter a mint';

  @override
  String get editProfileImageSheetSectionSource => 'Source';

  @override
  String get editProfileImageSheetSectionYourUploads => 'Your uploads';

  @override
  String get editProfileImageSheetSectionNftsEvm => 'Your NFTs · EVM';

  @override
  String get editProfileImageSheetSectionNftsSolana => 'Your NFTs · Solana';

  @override
  String get editProfileImageSheetUploadsEmpty =>
      'Nothing uploaded yet — images you upload will appear here.';

  @override
  String get editProfileImageSheetUploadsError =>
      'Couldn\'t load your uploads.';

  @override
  String get editProfileImageSheetManualPromptEth => 'Know the contract?';

  @override
  String get editProfileImageSheetManualPromptSolana => 'Know the mint?';

  @override
  String get editProfileImageSheetManualCta => 'Enter manually';

  @override
  String get editProfileImageSheetPickSourceHint =>
      'Pick a source to make a change';

  @override
  String get editProfileImageSheetFieldChain => 'CHAIN';

  @override
  String get editProfileImageSheetFieldContract => 'CONTRACT ADDRESS';

  @override
  String get editProfileImageSheetFieldTokenId => 'TOKEN ID';

  @override
  String get editProfileImageSheetTokensLoading =>
      'Checking which tokens you hold…';

  @override
  String editProfileImageSheetTokensOwned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You hold $count tokens here — tap one to use it',
      one: 'You hold 1 token here — tap to use it',
    );
    return '$_temp0';
  }

  @override
  String get editProfileImageSheetFieldSolanaMint => 'SOLANA MINT';

  @override
  String get editProfileImageSheetFallbackNote =>
      'Your image stays as a fallback if the NFT can\'t be shown. Ownership is re-checked on-chain when it renders.';

  @override
  String get editProfileImageSheetNoServerAvatar =>
      'Set a Social Server (SSP) to upload your own profile picture. You can still paste an image URL below.';

  @override
  String get editProfileImageSheetNoServerBanner =>
      'Set a Social Server (SSP) to upload your own banner. You can still paste an image URL below.';

  @override
  String get editProfileImageSheetTitleAvatar => 'Profile picture';

  @override
  String get editProfileImageSheetTitleCard => 'NFT card';

  @override
  String get editProfileImageSheetTitleBanner => 'Banner';

  @override
  String get editProfileImageSheetNoActiveAccount => 'No active account.';

  @override
  String get editProfileImageSheetRemoveNftAvatar => 'Remove NFT picture';

  @override
  String get editProfileImageSheetRemoveNftBanner => 'Remove NFT banner';

  @override
  String get editProfileImageSheetRemoveFromProfile => 'Remove from profile';

  @override
  String get editProfileImageSheetClearsRecord => 'Clears the on-chain record';

  @override
  String get editProfileImageSheetClose => 'Close';

  @override
  String get manageProfileTabsSheetTitle => 'Manage tabs';

  @override
  String get manageProfileTabsSheetGroupTitle => 'Manage group tabs';

  @override
  String get manageProfileTabsSheetLoadingWebFeedTabs =>
      'Loading web & feed tabs';

  @override
  String get manageProfileTabsSheetLoadingInboxTabs => 'Loading inbox tabs';

  @override
  String get manageProfileTabsSheetUpdatingTabs => 'Updating tabs';

  @override
  String get manageProfileTabsSheetNoAddressError =>
      'No valid address found for fetching profile tabs';

  @override
  String get manageProfileTabsSheetChatFallback => 'Chat';

  @override
  String get manageProfileTabsSheetInboxLoadError =>
      'Couldn\'t load inbox tabs';

  @override
  String get manageProfileTabsSheetVoteStarted =>
      'Vote started — members need to approve';

  @override
  String get manageProfileTabsSheetTabCreated => 'Tab created successfully.';

  @override
  String get manageProfileTabsSheetTabUpdated => 'Tab updated successfully.';

  @override
  String get manageProfileTabsSheetTabDeleted => 'Tab deleted successfully.';

  @override
  String get manageProfileTabsSheetUnnamedTab => 'Unnamed Tab';

  @override
  String get manageProfileTabsSheetDeleteTabTitle => 'Delete Tab';

  @override
  String manageProfileTabsSheetDeleteTabBody(Object tabName) {
    return 'Are you sure you want to delete the tab \"$tabName\"? This action cannot be undone.';
  }

  @override
  String get manageProfileTabsSheetInboxRenamed => 'Inbox tab renamed.';

  @override
  String get manageProfileTabsSheetInboxRemoved => 'Inbox tab removed.';

  @override
  String get manageProfileTabsSheetRemoveInboxTitle => 'Remove inbox tab';

  @override
  String manageProfileTabsSheetRemoveInboxBody(Object label) {
    return 'Remove \"$label\" from the on-chain profile. Other users will no longer see this inbox listed on this account.';
  }

  @override
  String get manageProfileTabsSheetRenameInboxTitle => 'Rename inbox tab';

  @override
  String get manageProfileTabsSheetLabelHint => 'Label';

  @override
  String get manageProfileTabsSheetSave => 'Save';

  @override
  String get manageProfileTabsSheetActionDelete => 'Delete';

  @override
  String get manageProfileTabsSheetActionRemove => 'Remove';

  @override
  String get manageProfileTabsSheetInboxTabsHeader => 'INBOX TABS';

  @override
  String get manageProfileTabsSheetOnlyGroupMembers =>
      'Only group members can manage tabs';

  @override
  String get manageProfileTabsSheetViewOnly => 'You can only view these tabs';

  @override
  String get manageProfileTabsSheetAddNewTab => 'Add new tab';

  @override
  String get manageProfileTabsSheetActiveKey => 'ACTIVE KEY';

  @override
  String get nftPickerGridAllChains => 'All chains';

  @override
  String nftPickerGridChainFallback(Object id) {
    return 'Chain $id';
  }

  @override
  String get nftPickerGridRefresh => 'Refresh';

  @override
  String get nftPickerGridRemoveFromRecents => 'Remove from recents';

  @override
  String get nftPickerGridEmpty =>
      'No NFTs yet. Pick one with Manual above and it\'ll show here next time. (Link a Solana wallet to see your Solana NFTs live.)';

  @override
  String get nftPickerGridNoMatch => 'No NFTs match these filters.';

  @override
  String get nftPickerGridSearchHint => 'Search address, token or mint';

  @override
  String get nftPickerGridMine => 'Mine';

  @override
  String get nftPickerGridNotMine => 'Not mine';

  @override
  String get nftPickerGridRecent => 'Recent';

  @override
  String get nftPickerGridOldest => 'Oldest';

  @override
  String get recordButtonDeleteTitle => 'Delete Record';

  @override
  String recordButtonDeleteConfirm(Object key) {
    return 'Are you sure you want to delete \"$key\"?';
  }

  @override
  String get recordButtonDelete => 'Delete';

  @override
  String recordButtonCouldNotLaunch(Object link) {
    return 'Could not launch $link';
  }

  @override
  String socialStripCouldNotLaunch(Object link) {
    return 'Could not launch $link';
  }

  @override
  String get socialStripIcon => 'Icon';

  @override
  String get socialStripRich => 'Rich';

  @override
  String get socialStripAdd => 'Add';

  @override
  String manageProviderSheetManageTitle(Object type) {
    return 'Manage $type';
  }

  @override
  String get manageProviderSheetTitleLabel => 'Title';

  @override
  String get manageProviderSheetSaveTooltip => 'Save';

  @override
  String get manageProviderSheetEditTitleTooltip => 'Edit title';

  @override
  String manageProviderSheetSubscribers(Object count) {
    return 'Subscribers: $count';
  }

  @override
  String get manageProviderSheetPointers => 'Pointers';

  @override
  String get manageProviderSheetNoPointers => 'No pointers set';

  @override
  String get manageProviderSheetEditPointerTooltip => 'Edit pointer';

  @override
  String get manageProviderSheetRemovePointerTooltip => 'Remove pointer';

  @override
  String get manageProviderSheetRemovePointerTitle => 'Remove Pointer';

  @override
  String manageProviderSheetRemovePointerConfirm(Object type) {
    return 'Remove pointer \"$type\"?';
  }

  @override
  String get manageProviderSheetRemove => 'Remove';

  @override
  String get manageProviderSheetPointerTypeLabel => 'Pointer type';

  @override
  String get manageProviderSheetValueLabel => 'Value';

  @override
  String get manageProviderSheetAddPointerTooltip => 'Add pointer';

  @override
  String manageProviderSheetDeleteTitle(Object type) {
    return 'Delete $type';
  }

  @override
  String manageProviderSheetDeleteConfirm(Object slug) {
    return 'Are you sure you want to delete $slug? This action cannot be undone.';
  }

  @override
  String get manageProviderSheetDeleteButton => 'Delete';

  @override
  String manageProviderSheetDeleted(Object type, Object slug) {
    return '$type \"$slug\" deleted';
  }

  @override
  String providerDirectorySheetTitle(Object type) {
    return '$type Directory';
  }

  @override
  String get providerDirectorySheetSearchHint => 'Search by title...';

  @override
  String get providerDirectorySheetLoadError => 'Failed to load providers';

  @override
  String get providerDirectorySheetNoResults => 'No results found';

  @override
  String providerDirectorySheetEmpty(Object type) {
    return 'No ${type}s registered yet';
  }

  @override
  String get providerDirectorySheetClearSearch => 'Clear search';

  @override
  String get providerDirectorySheetCurrentChip => 'Current';

  @override
  String get providerDirectorySheetRunBy => 'Run by ';

  @override
  String get providerDirectorySheetNoPointers =>
      'No configuration pointers set';

  @override
  String get providerDirectorySheetCurrentProvider => 'Current provider';

  @override
  String get providerDirectorySheetChangeToProvider =>
      'Change to this provider';

  @override
  String get providerDirectorySheetSubscribe => 'Subscribe';

  @override
  String registerProviderSheetTitle(Object type) {
    return 'Register $type';
  }

  @override
  String registerProviderSheetSubtitle(Object label) {
    return 'Register a new $label on-chain.';
  }

  @override
  String get registerProviderSheetNotAuthenticated =>
      'Not authenticated. Please sign in first.';

  @override
  String registerProviderSheetRegisteredSuccess(Object type, Object slug) {
    return '$type \"$slug\" registered successfully';
  }

  @override
  String get registerProviderSheetSlugLabel => 'Slug';

  @override
  String get registerProviderSheetSlugHint => 'e.g. my-bsp-service';

  @override
  String get registerProviderSheetSlugHelper =>
      '3-32 chars, lowercase, numbers, dashes, underscores';

  @override
  String get registerProviderSheetSlugRequired => 'Slug is required';

  @override
  String get registerProviderSheetSlugInvalid =>
      'Must be 3-32 chars: lowercase letters, numbers, dashes, underscores';

  @override
  String get registerProviderSheetTitleLabel => 'Title';

  @override
  String get registerProviderSheetTitleHint => 'e.g. My BSP Service';

  @override
  String get registerProviderSheetTitleRequired => 'Title is required';

  @override
  String get registerProviderSheetRequiredPointerHint =>
      'e.g. https://rpc.example.com';

  @override
  String registerProviderSheetRequiredPointerRequired(Object label) {
    return '$label is required';
  }

  @override
  String get registerProviderSheetRegionLabel => 'Region';

  @override
  String get registerProviderSheetRegionHint => 'e.g. us-east, eu-west';

  @override
  String get registerProviderSheetWebsiteLabel => 'Website';

  @override
  String get registerProviderSheetWebsiteHint => 'e.g. https://example.com';

  @override
  String get qualityToggleLow => 'Low';

  @override
  String get qualityToggleHd => 'HD';

  @override
  String get secretDialogsShowSecret => 'SHOW SECRET?';

  @override
  String get secretDialogsExportWarning =>
      'Never share your recovery phrase or private key with anyone. Anyone with these can access your account forever and you cannot revoke them.';

  @override
  String get secretDialogsIUnderstand => 'I UNDERSTAND';

  @override
  String get secretDialogsExportSecret => 'EXPORT SECRET';

  @override
  String secretDialogsExportLabel(Object label) {
    return 'EXPORT $label';
  }

  @override
  String get secretDialogsRecoveryPhrase => 'Recovery phrase';

  @override
  String get secretDialogsPrivateKeyHex => 'Private key (hex)';

  @override
  String get secretDialogsMnemonic => 'MNEMONIC';

  @override
  String get secretDialogsPrivateKey => 'PRIVATE KEY';

  @override
  String get secretDialogsCopy => 'COPY';

  @override
  String get secretDialogsDone => 'DONE';

  @override
  String get secretDialogsKeyCopied => 'Key copied';

  @override
  String get selectAccountScreenRestoreSessionFailed =>
      'Failed to restore session';

  @override
  String get selectAccountScreenEnterMnemonic =>
      'Please enter a mnemonic phrase';

  @override
  String get selectAccountScreenKeyImported => 'Key imported successfully';

  @override
  String get selectAccountScreenEnterPrivateKey => 'Please enter a private key';

  @override
  String get selectAccountScreenKeysActivated => 'Keys activated successfully!';

  @override
  String get selectAccountScreenKeysNotLinked =>
      'Keys not linked to any account yet';

  @override
  String get selectAccountScreenAddressCopied => 'Address copied';

  @override
  String get selectAccountScreenAccountRemoved =>
      'Account removed from this device';

  @override
  String get selectAccountScreenDeleteAccountFailed =>
      'Failed to delete account';

  @override
  String get selectAccountScreenKeyPairDeleted => 'Key pair deleted';

  @override
  String get selectAccountScreenDeleteKeyPairFailed =>
      'Failed to delete key pair';

  @override
  String get selectAccountScreenAppResetComplete => 'App reset complete';

  @override
  String get selectAccountScreenRecoveryPhraseTitle => 'RECOVERY PHRASE';

  @override
  String get selectAccountScreenRecoveryPhraseWarning =>
      'Write down these 12 words. This is the only way to recover your key. Store it offline. Never share it.';

  @override
  String get selectAccountScreenImportKeyTitle => 'Import Key';

  @override
  String get selectAccountScreenImportKeySubtitle =>
      'Import using mnemonic or private key';

  @override
  String get selectAccountScreenDeleteAccountTitle => 'DELETE ACCOUNT';

  @override
  String selectAccountScreenDeleteAccountBody(Object displayName) {
    return 'Removes \"$displayName\" from THIS DEVICE only — its keys, messages, contacts, and settings stored here.';
  }

  @override
  String get selectAccountScreenDeleteAccountNote =>
      'The on-chain account itself is NOT deleted. You can add it back later with its recovery phrase or private key — without that backup, access from this device is lost.';

  @override
  String get selectAccountScreenDelete => 'DELETE';

  @override
  String get selectAccountScreenDeleteKeyPairTitle => 'DELETE KEY PAIR';

  @override
  String get selectAccountScreenDeleteKeyPairBody =>
      'This action cannot be undone. Make sure you have backed up your recovery phrase.';

  @override
  String get selectAccountScreenResetAppTitle => 'RESET APP';

  @override
  String get selectAccountScreenResetAppHeading =>
      'This will permanently delete.';

  @override
  String get selectAccountScreenResetItemMessages =>
      'All messages and conversations';

  @override
  String get selectAccountScreenResetItemContacts => 'All contacts and groups';

  @override
  String get selectAccountScreenResetItemKeys => 'All key pairs and accounts';

  @override
  String get selectAccountScreenResetItemFeeds =>
      'All feeds, bookmarks & settings';

  @override
  String get selectAccountScreenResetItemDatabases =>
      'Local XMTP message databases';

  @override
  String get selectAccountScreenCannotBeUndone => 'This cannot be undone.';

  @override
  String get selectAccountScreenReset => 'RESET';

  @override
  String get selectAccountScreenDeleteFromDevice => 'Delete from device';

  @override
  String get selectAccountScreenBadgePending => 'PENDING';

  @override
  String get selectAccountScreenBadgeRecent => 'RECENT';

  @override
  String get selectAccountScreenShowQr => 'Show QR';

  @override
  String get selectAccountScreenCopyAddress => 'Copy address';

  @override
  String get selectAccountScreenRemove => 'Remove';

  @override
  String get selectAccountScreenLogin => 'LOGIN';

  @override
  String get selectAccountScreenCheckActivation => 'CHECK ACTIVATION';

  @override
  String get selectAccountScreenNoIdentitiesTitle => 'No Identities';

  @override
  String get selectAccountScreenNoIdentitiesSubtitle =>
      'Create or import a key pair to get started';

  @override
  String get selectAccountScreenGenerateNewKey => 'GENERATE NEW KEY';

  @override
  String get selectAccountScreenImportKeyButton => 'IMPORT KEY';

  @override
  String get selectAccountScreenResetTooltip => 'Reset app';

  @override
  String get selectAccountScreenIdentities => 'IDENTITIES';

  @override
  String get selectAccountScreenSelectToAuthenticate =>
      'Select an account to login.';

  @override
  String get selectAccountScreenNoIdentitiesFound => 'No identities found.';

  @override
  String get selectAccountScreenNewKeysCardName => 'New Keys';

  @override
  String get selectAccountScreenExpired => 'EXPIRED';

  @override
  String get selectAccountScreenLinkDeviceTitle => 'LINK DEVICE';

  @override
  String get selectAccountScreenAddSession => 'ADD SESSION';

  @override
  String get selectAccountScreenNewAccount => 'NEW ACCOUNT';

  @override
  String get selectAccountScreenScanAuthorizeKey =>
      'Scan this from a session of your account to add this key.';

  @override
  String get selectAccountScreenScanCreateAccount =>
      'Have a citizen scan this to create a new account with this key.';

  @override
  String get selectAccountScreenDone => 'DONE';

  @override
  String get stickerGifToggleSticker => 'STICKER';

  @override
  String get stickerPanelEmptyTitle => 'No stickers yet';

  @override
  String get stickerPanelEmptyBody =>
      'Hold any sticker in a chat and tap the save button to keep it here.';

  @override
  String get stickerPanelAddDescription => 'Add description';

  @override
  String get stickerPanelDelete => 'Delete';

  @override
  String get stickerPanelDeleteTitle => 'Delete sticker?';

  @override
  String get stickerPanelDeleteBody =>
      'It will be removed from your stickers. Messages you already sent are not affected.';

  @override
  String get stickerPanelDeleteConfirm => 'Delete';

  @override
  String get stickerPanelDismissMenu => 'Dismiss sticker menu';

  @override
  String get syncIndicatorSyncFailedRetry => 'Sync failed. Tap to retry.';

  @override
  String get unifiedSendSheetTitle => 'Send OX';

  @override
  String get unifiedSendSheetFailedToLoadWallets => 'Failed to load wallets';

  @override
  String get unifiedSendSheetDirectAddress => 'Direct Address';

  @override
  String get unifiedSendSheetAddressCopied => 'Address copied to clipboard';

  @override
  String get unifiedSendSheetAmountGreaterThanZero =>
      'Amount must be greater than 0';

  @override
  String get unifiedSendSheetAmountExceedsBalance =>
      'Amount exceeds available balance';

  @override
  String get unifiedSendSheetInvalidAmount => 'Invalid amount';

  @override
  String get unifiedSendSheetCannotSendToSameWallet =>
      'Cannot send to the same wallet';

  @override
  String get unifiedSendSheetTransactionSent =>
      'Transaction sent successfully!';

  @override
  String get unifiedSendSheetVoteStarted =>
      'Vote started for group transaction! Other members can now approve.';

  @override
  String get unifiedSendSheetTransactionFailed => 'Transaction failed';

  @override
  String get unifiedSendSheetSearchHint =>
      'Search by name, username or address…';

  @override
  String get unifiedSendSheetSearchingOnChain => 'Searching on chain…';

  @override
  String get unifiedSendSheetSelectContact => 'Select a contact to send OX';

  @override
  String get unifiedSendSheetNoContactsFound => 'No contacts found';

  @override
  String get unifiedSendSheetKeychain => 'Keychain';

  @override
  String get unifiedSendSheetGroupAccount => 'Group Account';

  @override
  String get unifiedSendSheetMyAccount => 'My Account';

  @override
  String get unifiedSendSheetSendingFrom => 'SENDING FROM';

  @override
  String get unifiedSendSheetSendingTo => 'SENDING TO';

  @override
  String get unifiedSendSheetChange => 'Change';

  @override
  String get unifiedSendSheetMax => 'Max';

  @override
  String get unifiedSendSheetSending => 'SENDING…';

  @override
  String get unifiedSendSheetSendOx => 'SEND OX';

  @override
  String get unifiedSendSheetChainLabel => 'Chain';

  @override
  String get unifiedSendSheetTokenLabel => 'Token';

  @override
  String get unifiedSendSheetGasLabel => 'gas';

  @override
  String get unifiedSendSheetSelectChain => 'Select chain';

  @override
  String get unifiedSendSheetSelectToken => 'Select token';

  @override
  String get unifiedSendSheetSafeOtherNetwork =>
      'A PublicOS Safe can\'t receive funds on other networks';

  @override
  String get unifiedSendSheetNeedKeychain =>
      'You need an external wallet to send on other networks';

  @override
  String get unifiedSendSheetChipRequested => 'Requested';

  @override
  String get tipSheetTitle => 'Tip with OX';

  @override
  String get tipSheetChooseRecipient => 'Choose who to tip';

  @override
  String get tipSheetActorAuthor => 'Author';

  @override
  String get tipSheetActorFoundVia => 'Found via';

  @override
  String get tipSheetActorChannelOwner => 'Channel owner';

  @override
  String get tipSheetSendTip => 'SEND TIP';

  @override
  String get tipSheetSending => 'TIPPING…';

  @override
  String get appSettingsPageSettingsTitle => 'Settings';

  @override
  String get appSettingsPageNotificationsTitle => 'Notifications';

  @override
  String get appSettingsPageLiveNotificationsTitle => 'Live notifications';

  @override
  String get appSettingsPageLiveNotificationsSubtitle =>
      'Show while the app is open';

  @override
  String get appSettingsPagePushNotificationsTitle => 'Push notifications';

  @override
  String get appSettingsPagePushNotificationsSubtitle =>
      'Receive alerts when the app is closed';

  @override
  String get appSettingsPageChainNotificationsTitle => 'Chain notifications';

  @override
  String get appSettingsPageChainNotificationsSubtitle =>
      'Notifications for on-chain events';

  @override
  String get appSettingsPageSessionTitle => 'Session';

  @override
  String get appSettingsPageAutoLoginTitle => 'Auto-login';

  @override
  String get appSettingsPageAutoLoginSubtitle =>
      'Skip account selection on launch';

  @override
  String get appSettingsPageBlockchainTitle => 'Blockchain';

  @override
  String get appSettingsPageChainIdLabel => 'Chain ID';

  @override
  String get appSettingsPageRpcLabel => 'RPC';

  @override
  String get appSettingsPagePollingRateLabel => 'POLLING RATE';

  @override
  String get appSettingsPageReconnectButton => 'RECONNECT';

  @override
  String get appSettingsPageReconnectedRpc => 'Reconnected to RPC';

  @override
  String get appSettingsPageVideoTitle => 'Video';

  @override
  String get appSettingsPageVideoAutoloadThresholdLabel =>
      'AUTO-LOAD THRESHOLD';

  @override
  String get appSettingsPageVideoAutoloadThresholdDesc =>
      'Videos at or below this size auto-download. Larger videos show a \"Tap to load\" prompt.';

  @override
  String get appSettingsPageVideoThresholdAlwaysAsk => 'Always ask';

  @override
  String get appSettingsPageVideoThresholdAlwaysAutoload => 'Always auto-load';

  @override
  String appSettingsPageVideoThresholdMb(Object mb) {
    return '$mb MB';
  }

  @override
  String get appSettingsPageVideoAutoplayTitle => 'Autoplay in feed';

  @override
  String get appSettingsPageVideoAutoplaySubtitle =>
      'Muted, when scrolled into view (coming soon)';

  @override
  String get appSettingsPageAvatarTitle => 'NFT avatars';

  @override
  String get appSettingsPageAvatarDesc =>
      'Verified NFT profile pictures get a subtle treatment. These only affect display — ownership is always re-checked on-chain.';

  @override
  String get appSettingsPageSparklesTitle => 'Sparkles';

  @override
  String get appSettingsPageSparklesSubtitle =>
      'Twinkling mark on verified NFT avatars';

  @override
  String get appSettingsPageShimmerTitle => 'Shimmer sweep';

  @override
  String get appSettingsPageShimmerSubtitle =>
      'A light sweep across verified NFT avatars';

  @override
  String get appSettingsPageHelpTitle => 'Help';

  @override
  String get appSettingsPageHelpOnboardingDesc =>
      'Replay the welcome tour — what PublicOS is, how the network is built, and the kinds of accounts you will meet.';

  @override
  String get appSettingsPageWatchOnboardingButton => 'WATCH ONBOARDING';

  @override
  String get appSettingsPageReseedDemoDesc =>
      'Re-save the baked demo contacts to your local store. Useful after an app update with a refreshed snapshot.';

  @override
  String get appSettingsPageReseedingButton => 'RESEEDING…';

  @override
  String get appSettingsPageReseedDemoButton => 'RESEED DEMO CONTACTS';

  @override
  String get appSettingsPageDemoContactsReseeded => 'Demo contacts reseeded';

  @override
  String get appSettingsPageDemoNewsDesc =>
      'Create a demo News list from a curated set of live RSS feeds, so you have something to read. Overwrites an existing News list.';

  @override
  String get appSettingsPageDemoFeedsDesc =>
      'Build demo feeds from your contacts: a bluesky list from Bluesky channels, and bookmarks for every registered app. Lists overwrite same-named ones.';

  @override
  String get appSettingsPageCreatingButton => 'CREATING…';

  @override
  String get appSettingsPageCreateDemoChannelButton =>
      'CREATE DEMO CHANNEL LIST';

  @override
  String get appSettingsPageCreateDemoBlueskyButton =>
      'CREATE DEMO BLUESKY LIST';

  @override
  String get appSettingsPageBookmarkingButton => 'BOOKMARKING…';

  @override
  String get appSettingsPageCreateDemoBookmarksButton =>
      'CREATE DEMO APP BOOKMARKS';

  @override
  String get appSettingsPageNoChannelsFound => 'No channels found in contacts';

  @override
  String get appSettingsPageFailedCreateNewsList =>
      'Failed to create News list';

  @override
  String appSettingsPageCreatedNewsList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels',
      one: '1 channel',
    );
    return 'Created News list with $_temp0';
  }

  @override
  String get appSettingsPageNoBlueskyFeeds =>
      'No Bluesky feeds found in contacts';

  @override
  String get appSettingsPageFailedCreateBlueskyList =>
      'Failed to create bluesky list';

  @override
  String appSettingsPageCreatedBlueskyList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return 'Created bluesky list with $_temp0';
  }

  @override
  String appSettingsPageBookmarkedApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return 'Bookmarked $_temp0';
  }

  @override
  String appSettingsPageAlreadyBookmarkedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already bookmarked',
      one: '1 already bookmarked',
    );
    return ' ($_temp0)';
  }

  @override
  String appSettingsPageFailedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count failed',
      one: '1 failed',
    );
    return ' ($_temp0)';
  }

  @override
  String appSettingsPageRedeployedRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
    );
    return 'Redeployed $_temp0';
  }

  @override
  String get appSettingsPageRedeployFailed => 'Failed to redeploy profile';

  @override
  String appSettingsPageDaoRegistered(Object address) {
    return 'DAO registered: $address';
  }

  @override
  String get appSettingsPageRunningSync => 'Running background sync...';

  @override
  String get appSettingsPageSyncCompleted => 'Sync completed! Check log.';

  @override
  String get appSettingsPageSyncFailed => 'Sync failed. Check log.';

  @override
  String get appSettingsPageSyncLogTitle => 'Background Sync Log';

  @override
  String get appSettingsPageSyncLogEmpty =>
      'No background sync has run yet.\n\nThe first sync will run ~15 minutes after enabling periodic notifications.';

  @override
  String get appSettingsPageClose => 'Close';

  @override
  String get appSettingsPageCompleteResetTitle => 'Complete Reset';

  @override
  String get appSettingsPageCompleteResetBody =>
      'This will permanently delete ALL data including:\n• All messages\n• All contacts\n• All private keys\n• All secure storage\n• All authentication state\n\nThis action cannot be undone. Are you sure?';

  @override
  String get appSettingsPageDeleteAllDataButton => 'DELETE ALL DATA';

  @override
  String get appSettingsPageAllDataDeleted => 'All data has been deleted.';

  @override
  String get appSettingsPageResetFailed => 'Reset failed';

  @override
  String get appSettingsPageDeleteContactsTitle => 'Delete All Contacts';

  @override
  String get appSettingsPageDeleteContactsBody =>
      'This will delete all locally stored contacts.\n\nThis action cannot be undone.';

  @override
  String get appSettingsPageDeleteAll => 'Delete All';

  @override
  String appSettingsPageDeletedContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
    );
    return 'Deleted $_temp0';
  }

  @override
  String get appSettingsPageDeleteMessagesTitle => 'Delete All Messages';

  @override
  String get appSettingsPageDeleteMessagesBody =>
      'This will delete all locally stored messages and conversations.\n\nXMTP network state is untouched — conversations will reappear on the next sync, but historical messages will not.\n\nThis action cannot be undone.';

  @override
  String get appSettingsPageDeletedMessages =>
      'Deleted all messages and conversations';

  @override
  String get appSettingsPageDeleteAppsTitle => 'Delete All Apps';

  @override
  String get appSettingsPageDeleteAppsBody =>
      'This will remove all bookmarked apps locally.\n\nThis action cannot be undone.';

  @override
  String appSettingsPageDeletedApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return 'Deleted $_temp0';
  }

  @override
  String get appSettingsPageClearChainTitle => 'Clear Chain Notifications';

  @override
  String get appSettingsPageClearChainBody =>
      'Wipes all cached on-chain activity (the notifications feed) and resets the sweep cursor so it re-syncs from the current chain.\n\nUse after a redeploy to clear stale old-chain notifications.';

  @override
  String get appSettingsPageClear => 'Clear';

  @override
  String appSettingsPageClearedNotifs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chain notifications',
      one: '1 chain notification',
    );
    return 'Cleared $_temp0';
  }

  @override
  String get appSettingsPageExportDbKeyTitle => 'Export Database Key';

  @override
  String get appSettingsPageExportDbKeyBody =>
      'Your database key encrypts your local XMTP message cache. This key is unique to this device — exporting it allows you to import the same cache on another device. Never share it with anyone you don\'t trust.';

  @override
  String get appSettingsPageIUnderstand => 'I UNDERSTAND';

  @override
  String get appSettingsPageDbKeyTitle => 'DB Key';

  @override
  String appSettingsPageActiveXmtpKey(Object label) {
    return 'Active XMTP key: $label';
  }

  @override
  String get appSettingsPageNoneLower => 'none';

  @override
  String get appSettingsPageNoDbKey => 'No DB key available.';

  @override
  String get appSettingsPageCopy => 'Copy';

  @override
  String get appSettingsPageCopyLabelDbKey => 'DB key';

  @override
  String get appSettingsPageCopyLabelXmtpAddress => 'XMTP address';

  @override
  String appSettingsPageCopiedToClipboard(Object label) {
    return '$label copied to clipboard';
  }

  @override
  String get appSettingsPageImportDbKeyTitle => 'Import DB Key';

  @override
  String get appSettingsPageImportDbKeyBody =>
      'Paste a base64-encoded DB key. This will replace the current key.';

  @override
  String get appSettingsPageBase64KeyLabel => 'Base64 key';

  @override
  String get appSettingsPagePasteKeyError => 'Paste a key';

  @override
  String get appSettingsPageDbKeyImported => 'DB key imported';

  @override
  String get appSettingsPageImportFailed => 'Import failed';

  @override
  String get appSettingsPageInvalidKey => 'Invalid key';

  @override
  String get appSettingsPageImportingButton => 'Importing...';

  @override
  String get appSettingsPageImportButton => 'Import';

  @override
  String get appSettingsPageConnectedBadge => 'CONNECTED';

  @override
  String get appSettingsPageAddressLabel => 'Address';

  @override
  String get appSettingsPageNotInitialized => 'Not initialized';

  @override
  String get appSettingsPageInboxIdLabel => 'Inbox ID';

  @override
  String get appSettingsPageActiveKeyLabel => 'Active Key';

  @override
  String get appSettingsPageNone => 'None';

  @override
  String get appSettingsPageInvalidAddress => 'Invalid';

  @override
  String get appSettingsPageDeveloperTitle => 'Developer';

  @override
  String get appSettingsPageUnlockedBadge => 'UNLOCKED';

  @override
  String get appSettingsPageUtilitiesLabel => 'UTILITIES';

  @override
  String get appSettingsPageSyncLogChip => 'Sync Log';

  @override
  String get appSettingsPageTestSyncChip => 'Test Sync';

  @override
  String get appSettingsPageRedeployChip => 'Redeploy';

  @override
  String get appSettingsPageRegisterDaoChip => 'Register DAO';

  @override
  String get appSettingsPageDestructiveLabel => 'DESTRUCTIVE';

  @override
  String get appSettingsPageDeletingButton => 'DELETING...';

  @override
  String get appSettingsPageDeleteAllContactsButton => 'DELETE ALL CONTACTS';

  @override
  String get appSettingsPageDeleteAllMessagesButton => 'DELETE ALL MESSAGES';

  @override
  String get appSettingsPageDeleteAllAppsButton => 'DELETE ALL APPS';

  @override
  String get appSettingsPageClearingButton => 'CLEARING...';

  @override
  String get appSettingsPageClearChainNotificationsButton =>
      'CLEAR CHAIN NOTIFICATIONS';

  @override
  String get appSettingsPageResettingButton => 'RESETTING...';

  @override
  String get appSettingsPageResetAllDataButton => 'RESET ALL DATA';

  @override
  String get appSettingsPageRegisterDaoTitle => 'Register PublicOS DAO';

  @override
  String get appSettingsPageDaoAlreadyRegistered =>
      'A DAO is already registered:';

  @override
  String get appSettingsPageUpdateDaoAddress => 'Update DAO address';

  @override
  String get appSettingsPageEnterDaoAddress =>
      'Enter the address of the PublicOS root DAO.';

  @override
  String get appSettingsPageDaoAddressLabel => 'DAO Address';

  @override
  String get appSettingsPageRegisterButton => 'Register';

  @override
  String get appSettingsPageFailedUpdateLive =>
      'Failed to update live notifications';

  @override
  String get appSettingsPageFailedUpdatePush =>
      'Failed to update push notifications';

  @override
  String get appSettingsPageFailedUpdateChain =>
      'Failed to update chain notifications';

  @override
  String get browserContactNotFound => 'Contact not found';

  @override
  String get browserFollowingViaAccount =>
      'You already follow this account — its channels are in Following';

  @override
  String get browserTabChat => 'Chat';

  @override
  String get browserAppNotFound => 'App not found';

  @override
  String get browserTabNotFound => 'Tab not found';

  @override
  String get browserVoteStartedMembersApprove =>
      'Vote started — members need to approve';

  @override
  String get browserProfileImageUpdated => 'Profile image updated';

  @override
  String get browserCouldNotStartVote =>
      'Could not start the vote — please try again';

  @override
  String get browserSavingToChain => 'Saving to chain...';

  @override
  String get browserRefreshingProfile => 'Refreshing profile...';

  @override
  String get browserAvatarUpdated => 'Avatar updated';

  @override
  String get browserCouldNotSetAvatar =>
      'Could not set avatar — please try again';

  @override
  String get browserProfileBackgroundRemoved => 'Profile background removed!';

  @override
  String get browserProfileBackgroundUpdated =>
      'Profile background updated successfully!';

  @override
  String get browserFailedUpdateBackground =>
      'Failed to update background: Could not save record.';

  @override
  String get browserGroupChat => 'Group chat';

  @override
  String get browserTabSettings => 'Settings';

  @override
  String get browserTabApp => 'App';

  @override
  String get browserTabChannel => 'Channel';

  @override
  String get browserTabWeb => 'Web';

  @override
  String get browserTabManagement => 'Management';

  @override
  String get browserSwitchTab => 'Switch tab';

  @override
  String get browserManageTabs => 'Manage tabs';

  @override
  String get browserSectionChats => 'CHATS';

  @override
  String get browserSectionApps => 'APPS';

  @override
  String get browserSectionTabs => 'TABS';

  @override
  String get browserTabProfile => 'Profile';

  @override
  String get browserUnnamedTab => 'Unnamed Tab';

  @override
  String get browserTabWebTab => 'Web Tab';

  @override
  String get browserAppNoUrl => 'The selected app has no URL defined.';

  @override
  String get browserTabNoUrl => 'The selected tab has no URL defined.';

  @override
  String get browserErrorLoadingContent => 'Error loading content';

  @override
  String get browserBackToExplorer => 'Back to Explorer';

  @override
  String get browserContactNotLoadedChat => 'Contact not loaded for chat.';

  @override
  String get browserLoadingApp => 'Loading app...';

  @override
  String get browserGoToProfile => 'Go to Profile';

  @override
  String browserUnknownTab(Object tab) {
    return 'Unknown tab: $tab';
  }

  @override
  String get browserProfileLinkCopied => 'Profile link copied';

  @override
  String browserRemovedApp(Object name) {
    return 'Removed $name';
  }

  @override
  String get browserFailedRemoveBookmark => 'Failed to remove bookmark';

  @override
  String browserBookmarkedApp(Object name) {
    return 'Bookmarked $name';
  }

  @override
  String get browserFailedBookmarkApp => 'Failed to bookmark app';

  @override
  String get bspScreenNoActiveAccount => 'No active account';

  @override
  String get bspScreenNoActiveSession => 'No active session';

  @override
  String get bspScreenEndpointNoUrl => 'Endpoint has no URL';

  @override
  String bspScreenConnectingTo(Object label) {
    return 'Connecting to $label…';
  }

  @override
  String bspScreenConnectedTo(Object label) {
    return 'Connected to $label';
  }

  @override
  String bspScreenUnreachable(Object label) {
    return '$label is unreachable';
  }

  @override
  String bspScreenRemoved(Object label) {
    return 'Removed $label';
  }

  @override
  String bspScreenCouldNotRemove(Object label) {
    return 'Could not remove $label';
  }

  @override
  String get bspScreenConnection => 'Connection';

  @override
  String get bspScreenEndpoint => 'Endpoint';

  @override
  String get bspScreenBlock => 'Block';

  @override
  String get bspScreenNone => 'None';

  @override
  String get bspScreenRoleCitizen => 'CITIZEN';

  @override
  String get bspScreenRolePrivate => 'PRIVATE';

  @override
  String get bspScreenProvider => 'Provider';

  @override
  String get bspScreenBalance => 'Balance';

  @override
  String get bspScreenPaidUntil => 'Covered until';

  @override
  String get bspScreenTip => 'Tip';

  @override
  String get bspScreenTipCitizen =>
      'Pick a BSP from Services. Citizens don\'t pay — the network mints fees on your behalf.';

  @override
  String get bspScreenTipPrivate =>
      'Subscribe to a BSP from Services — first month pays atomically.';

  @override
  String get bspScreenSubscription => 'Subscription';

  @override
  String get bspScreenManageInTreasury => 'MANAGE IN SERVICES';

  @override
  String get bspScreenProviders => 'Providers';

  @override
  String get bspScreenRegisterBsp => 'REGISTER BSP';

  @override
  String get bspScreenAddCustomRpc => 'ADD CUSTOM RPC';

  @override
  String get bspScreenBadgeMine => 'MINE';

  @override
  String get bspScreenBadgeSubscribed => 'SUBSCRIBED';

  @override
  String get bspScreenEmptyCitizen =>
      'No provider connected yet. Pick one from Services, register your own, or add a custom RPC below.';

  @override
  String get bspScreenEmptyPrivate =>
      'No provider connected yet. Subscribe to a BSP from Services, register your own, or add a custom RPC below.';

  @override
  String get bspScreenStatusUnreachableLabel => 'UNREACHABLE';

  @override
  String get bspScreenStatusUnreachableDesc =>
      'No RPC endpoint is responding. Chain reads and writes are unavailable.';

  @override
  String get bspScreenStatusBspLabel => 'BSP CONNECTED';

  @override
  String get bspScreenStatusBspDesc =>
      'Connected through your subscribed Blockchain Service Provider.';

  @override
  String get bspScreenStatusCustomLabel => 'CUSTOM RPC';

  @override
  String get bspScreenStatusCustomDesc =>
      'Connected through a custom RPC endpoint you configured.';

  @override
  String get bspScreenStatusPublicLabel => 'PUBLIC FALLBACK';

  @override
  String get bspScreenStatusPublicDesc =>
      'Connected to the default public node. Subscribe to a BSP or add a custom RPC for better reliability.';

  @override
  String get bspScreenLegendNoConnection => 'No RPC connection';

  @override
  String get bspScreenLegendPublicFallback => 'Public fallback node';

  @override
  String get bspScreenLegendBspOrCustom => 'BSP or custom RPC';

  @override
  String get bspScreenEarningsFooter => 'Earnings and claims live in Services.';

  @override
  String get bspScreenLabelRpc => 'RPC';

  @override
  String get bspScreenSubs => 'SUBS';

  @override
  String bspScreenSubscriberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscribers',
      one: '1 subscriber',
    );
    return '$_temp0';
  }

  @override
  String get bspScreenRunBy => 'RUN BY';

  @override
  String get bspScreenConnect => 'CONNECT';

  @override
  String get bspScreenConnected => 'CONNECTED';

  @override
  String get bspScreenLabelUrl => 'URL';

  @override
  String get bspScreenCustomRpcSubtitle => 'custom rpc';

  @override
  String get bspScreenDelete => 'DELETE';

  @override
  String get bspScreenRegisterTitle => 'New BSP on-chain';

  @override
  String get bspScreenRegisterSubtitle =>
      'Register yourself as a Blockchain Service Provider.';

  @override
  String get bspScreenFieldSlug => 'Slug';

  @override
  String get bspScreenSlugHint => 'e.g. my-bsp-service';

  @override
  String get bspScreenSlugHelper =>
      '3-32 chars, lowercase, numbers, dashes, underscores';

  @override
  String get bspScreenSlugRequired => 'Slug is required';

  @override
  String get bspScreenSlugInvalid =>
      '3-32 chars: lowercase letters, numbers, - _';

  @override
  String get bspScreenFieldTitle => 'Title';

  @override
  String get bspScreenTitleHint => 'e.g. My BSP Service';

  @override
  String get bspScreenTitleRequired => 'Title is required';

  @override
  String get bspScreenFieldRpcUrl => 'RPC URL';

  @override
  String get bspScreenRpcUrlRequired => 'RPC URL is required';

  @override
  String get bspScreenFieldRegion => 'Region';

  @override
  String get bspScreenRegionHint => 'e.g. us-east, eu-west';

  @override
  String get bspScreenFieldWebsite => 'Website';

  @override
  String get bspScreenRegister => 'REGISTER';

  @override
  String get bspScreenRegistering => 'REGISTERING…';

  @override
  String get bspScreenAddRpcTitle => 'Point at your own node';

  @override
  String get bspScreenAddRpcSubtitle => 'Connectivity is tested before saving.';

  @override
  String get bspScreenFieldName => 'Name';

  @override
  String get bspScreenNameHint => 'e.g. My Node';

  @override
  String get bspScreenUrlRequired => 'URL is required';

  @override
  String get bspScreenAdd => 'ADD';

  @override
  String get bspScreenTesting => 'TESTING…';

  @override
  String get chatScreenFailedToSend => 'Failed to send';

  @override
  String get chatScreenFailedToInit => 'Failed to initialize chat';

  @override
  String get chatScreenFailedToUpdateConsent =>
      'Failed to update consent state';

  @override
  String get chatScreenFailedToLoadMessages => 'Failed to load messages';

  @override
  String get chatScreenConsentPrompt =>
      'Allow this conversation? Sending a message auto-allows.';

  @override
  String get chatScreenConsentNo => 'No';

  @override
  String get chatScreenConsentYes => 'Yes';

  @override
  String get chatScreenNoMessages => 'No messages yet';

  @override
  String get chatScreenStartConversation => 'Start your conversation below!';

  @override
  String get composePostPageSave => 'Save';

  @override
  String get composePostPagePost => 'Post';

  @override
  String get composePostPageFailedUpdate => 'Failed to update post';

  @override
  String get composePostPageFailedPublish => 'Failed to publish';

  @override
  String composePostPageQuotaExceeded(int used, int quota) {
    return 'Media quota exceeded: $used of $quota MB used on this server. Free up space or raise your quota.';
  }

  @override
  String get composePostPageUploadFailed => 'Upload failed';

  @override
  String composePostPageMediaLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items per post',
      one: '1 item per post',
    );
    return 'Limit reached — $_temp0';
  }

  @override
  String get composePostPagePickChannel => 'Pick a channel';

  @override
  String get composePostPageHeaderAboveMedia => 'Header above the media';

  @override
  String get composePostPageHeaderOnMedia => 'Header on the media';

  @override
  String get composePostPageBodyHint => 'Share an update';

  @override
  String get composePostPageTitle => 'Title';

  @override
  String get composePostPageSummaryHint => 'Add a short summary';

  @override
  String get composePostPageBadgeVideo => 'VIDEO';

  @override
  String get composePostPageBadgeVid => 'VID';

  @override
  String get composePostPageBadgeCitizen => 'CITIZEN';

  @override
  String get composePostPageUploading => 'Uploading…';

  @override
  String composePostPageStatusUploading(int n, int total, int pct) {
    return 'Uploading $n of $total · $pct%';
  }

  @override
  String get composePostPageStatusMoving => 'Moving media…';

  @override
  String get composePostPageStatusPosting => 'Posting…';

  @override
  String get composePostPageMoveFailed => 'Could not move the media';

  @override
  String get composePostPageTagsHintEmpty => 'type, then space or comma';

  @override
  String get composePostPageTagsHintMore => 'add another';

  @override
  String get composePostPageCommentBarOpen => 'Anyone can reply';

  @override
  String get composePostPageCommentBarApproved => 'Allow-list only';

  @override
  String get composePostPageCommentBarDisabled => 'Replies disabled';

  @override
  String get composePostPageReactionBarOpen => 'Anyone can react';

  @override
  String get composePostPageReactionBarApproved => 'Reactions allow-list only';

  @override
  String get composePostPageReactionBarDisabled => 'Reactions disabled';

  @override
  String get composePostPageWhoCanReply => 'Who can reply';

  @override
  String get composePostPageWhoCanReact => 'Who can react';

  @override
  String get composePostPagePolicyAnyone => 'Anyone';

  @override
  String get composePostPagePolicyAllowList => 'Allow-list only';

  @override
  String get composePostPagePolicyDisabled => 'Disabled';

  @override
  String get composePostPageCommentSubtitleAnyone =>
      'Any account with access to the channel can reply.';

  @override
  String get composePostPageCommentSubtitleAllowList =>
      'Only addresses you added via the per-post Comment rules can reply.';

  @override
  String get composePostPageCommentSubtitleDisabled =>
      'Nobody can reply. Existing comments stay visible.';

  @override
  String get composePostPageReactionSubtitleAnyone =>
      'Any account with access to the channel can react.';

  @override
  String get composePostPageReactionSubtitleAllowList =>
      'Only addresses you added via the per-post Interaction rules can react. (The same allow-list governs comments and reactions.)';

  @override
  String get composePostPageReactionSubtitleDisabled =>
      'Nobody can react. Existing reactions stay visible. Independent of the comment policy.';

  @override
  String get composePostPageRequireVerifiedCitizen =>
      'Require verified citizen';

  @override
  String get composePostPageCommentVerifiedSubtitle =>
      'Overrides the channel default for this post. Non-citizens cannot reply.';

  @override
  String get composePostPageReactionVerifiedSubtitle =>
      'Independent of the comments-side toggle. Non-citizens cannot react to this post.';

  @override
  String get composePostPageDone => 'Done';

  @override
  String get composePostPageLanguageHeader => 'POST LANGUAGE';

  @override
  String get composePostPageChannelHeader => 'POST TO';

  @override
  String get composePostPageTooltipHero => 'Hero media (images / videos)';

  @override
  String get composePostPageTooltipMedia => 'Support media (images / videos)';

  @override
  String get composePostPageTooltipAudio => 'Audio (the post\'s sound track)';

  @override
  String get composePostPageAudioUnsupported =>
      'Pick an MP3, M4A, WAV or OGG file';

  @override
  String get composePostPageTooltipSummary => 'Summary';

  @override
  String get composePostPageTooltipLink => 'Link';

  @override
  String get composePostPageTooltipTags => 'Tags';

  @override
  String get contactSettingsScreenNoContactSelected => 'No contact selected';

  @override
  String get createChannelPageEditTitle => 'Edit channel';

  @override
  String get createChannelPageNewTitle => 'New channel';

  @override
  String get createChannelPageSave => 'Save';

  @override
  String get createChannelPageCreate => 'Create';

  @override
  String get createChannelPageServerLoading => 'Loading…';

  @override
  String get createChannelPageNoServerAvailable => 'No server available';

  @override
  String createChannelPageChannelUpdated(Object name) {
    return 'Channel \"$name\" updated';
  }

  @override
  String createChannelPageChannelCreated(Object name) {
    return 'Channel \"$name\" created';
  }

  @override
  String get createChannelPageUnknownError => 'Unknown error';

  @override
  String createChannelPageFailedToUpdate(Object msg) {
    return 'Failed to update: $msg';
  }

  @override
  String createChannelPageFailedToCreate(Object msg) {
    return 'Failed to create: $msg';
  }

  @override
  String get createChannelPageSectionIdentity => 'IDENTITY';

  @override
  String get createChannelPageNameHint => 'Channel name';

  @override
  String get createChannelPageIconUrlLabel => 'ICON URL';

  @override
  String get createChannelPageIconUrlHint => 'https://…/icon.png';

  @override
  String get createChannelPageSlugLabel => 'SLUG';

  @override
  String get createChannelPageSlugHint => 'channel-slug';

  @override
  String get createChannelPageDescriptionLabel => 'DESCRIPTION';

  @override
  String get createChannelPageLanguageLabel => 'LANGUAGE';

  @override
  String get createChannelPageDescriptionHint => 'What is this channel about?';

  @override
  String get createChannelPageSectionServer => 'SERVER';

  @override
  String get createChannelPageServerLocked =>
      'Server can\'t be changed after creation';

  @override
  String get createChannelPageServerSubtitle => 'Where this channel is hosted';

  @override
  String get createChannelPageChooseServer => 'Choose server';

  @override
  String get createChannelPageSectionPosting => 'POSTING';

  @override
  String get createChannelPagePolicyOwnerLabel => 'Owner only';

  @override
  String get createChannelPagePolicyOwnerSubtitle =>
      'Nobody but you can submit posts.';

  @override
  String get createChannelPagePolicyOpenLabel => 'Open';

  @override
  String get createChannelPagePolicyOpenSubtitle =>
      'Anyone who can read the channel may submit posts.';

  @override
  String get createChannelPagePolicyApprovedLabel => 'Approved';

  @override
  String get createChannelPagePolicyApprovedSubtitle =>
      'Only people on your posters list may submit posts.';

  @override
  String get createChannelPageRateLimitLabel =>
      'RATE LIMIT (POSTS / HOUR, 0 = UNLIMITED)';

  @override
  String get createChannelPageSectionPrivacy => 'PRIVACY';

  @override
  String get createChannelPagePrivateLabel => 'Private channel';

  @override
  String get createChannelPagePrivateSubtitleOn =>
      'Only approved followers can read posts. Other accounts see a lock screen and can request access.';

  @override
  String get createChannelPagePrivateSubtitleOff =>
      'Anyone with the link can read this channel.';

  @override
  String get createChannelPagePrivateInboxNote =>
      'You\'ll get a follow-request inbox to approve or reject readers.';

  @override
  String get createChannelPageSectionCitizenship => 'CITIZENSHIP';

  @override
  String get createChannelPageCitizenshipNote =>
      'Restrict actions to verified citizens.';

  @override
  String get createChannelPageCitizensReadingLabel => 'Citizens only — reading';

  @override
  String get createChannelPageCitizensPostingLabel => 'Citizens only — posting';

  @override
  String get createChannelPageCitizensCommentsLabel =>
      'Citizens only — comments';

  @override
  String get createChannelPageSectionRetention => 'RETENTION';

  @override
  String get createChannelPageMaxPostsLabel =>
      'MAX POSTS (LEAVE EMPTY = UNLIMITED)';

  @override
  String get createChannelPageMaxDaysLabel =>
      'MAX DAYS (LEAVE EMPTY = UNLIMITED)';

  @override
  String get createGroupPageAddMembersTitle => 'Add members';

  @override
  String get createGroupPageDetailsTitle => 'Group details';

  @override
  String get createGroupPageSearchHint =>
      'Search by name, address, or inbox ID';

  @override
  String get createGroupPageSortRecent => 'Recent';

  @override
  String get commentSectionTitle => 'Comments';

  @override
  String commentSectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get commentSectionEmpty => 'No comments yet. Be the first.';

  @override
  String get commentSectionLoading => 'Loading comments…';

  @override
  String get commentSectionLoadMore => 'Load more comments';

  @override
  String get commentSortBest => 'Best';

  @override
  String get commentSortTop => 'Top';

  @override
  String get commentSortNewest => 'Newest';

  @override
  String get commentSortOldest => 'Oldest';

  @override
  String get createGroupPageNoContactsMatch => 'No contacts match';

  @override
  String get createGroupPageNoContactsHint =>
      'Try a display name, an 0x-prefixed address, or a 64-char inbox ID.';

  @override
  String get createGroupPageFieldNameLabel => 'GROUP NAME';

  @override
  String get createGroupPageNameHint => 'Builders, HH 2026, …';

  @override
  String get createGroupPageFieldImageLabel => 'GROUP IMAGE';

  @override
  String get createGroupPageNoSspMessage =>
      'Set a Social Server (SSP) to upload a group image. You can still paste an image URL below.';

  @override
  String get createGroupPageFieldDescriptionLabel => 'DESCRIPTION';

  @override
  String get createGroupPageDescriptionHint => 'What is this group for?';

  @override
  String get createGroupPageNextButton => 'NEXT';

  @override
  String get createGroupPageAddButton => 'ADD MEMBERS';

  @override
  String get createGroupPageCreateButton => 'CREATE GROUP';

  @override
  String get createGroupPagePickInboxTitle => 'PICK INBOX';

  @override
  String createGroupPageMultipleDevices(Object name) {
    return '$name has multiple registered devices.';
  }

  @override
  String createGroupPageAllDevicesAdded(Object name) {
    return 'All devices already added for $name';
  }

  @override
  String get createGroupPageNameRequired => 'Group name is required';

  @override
  String get createGroupPageSelectContact => 'Select at least one contact';

  @override
  String get createGroupPageNoValidInboxIds =>
      'Selected contacts have no valid inbox IDs';

  @override
  String get createGroupPageCreationNoId => 'Group creation returned no id';

  @override
  String get explorerBackAgainToExit => 'Back again to exit';

  @override
  String get explorerTabFeeds => 'Feeds';

  @override
  String get explorerTabContacts => 'Contacts';

  @override
  String get explorerTabApps => 'Apps';

  @override
  String get explorerTabMessages => 'Messages';

  @override
  String get explorerTabWallet => 'Wallet';

  @override
  String appsViewRemovedSnack(Object name) {
    return 'Removed $name';
  }

  @override
  String appsViewBookmarkedSnack(Object name) {
    return 'Bookmarked $name';
  }

  @override
  String appsViewAppMisconfigured(Object label) {
    return '$label can\'t open — the app has no address set. That\'s the developer\'s side, not yours.';
  }

  @override
  String appsViewComingSoon(Object label) {
    return '$label coming soon';
  }

  @override
  String get appsViewSystemTreasury => 'Services';

  @override
  String get appsViewSystemAccountCenter => 'Account';

  @override
  String get appsViewSystemSocialGraph => 'Social Graph';

  @override
  String get appsViewSystemSettings => 'Settings';

  @override
  String get appsViewSystemNodes => 'Nodes';

  @override
  String get appsViewSearchHint => 'Search apps';

  @override
  String get appsViewSearching => 'Searching apps...';

  @override
  String get appsViewChipBookmarked => 'Bookmarked';

  @override
  String get appsViewChipMyApps => 'My Apps';

  @override
  String get appsViewChipAll => 'All';

  @override
  String get appsViewChipRegister => 'Register';

  @override
  String get appsViewChipSettings => 'Settings';

  @override
  String get appsViewEmptyNoMatchesTitle => 'No matches';

  @override
  String get appsViewEmptyTryDifferentTerm => 'Try a different search term.';

  @override
  String get appsViewEmptyNoBookmarksTitle => 'No bookmarked apps';

  @override
  String get appsViewEmptyNoBookmarksBody =>
      'Long-press any app in \"All\" to add it to your bookmarks.';

  @override
  String get appsViewEmptyNoMyAppsTitle => 'You haven\'t registered any apps';

  @override
  String get appsViewEmptyNoMyAppsBody =>
      'Tap \"Register\" in the chip bar to publish your first app.';

  @override
  String get appsViewEmptyNoAppsFoundTitle => 'No apps found';

  @override
  String get appsViewSearchPromptTitle => 'Search all apps';

  @override
  String get appsViewSearchPromptBody =>
      'Enter at least 2 characters to search\nfor apps across the network.';

  @override
  String get contactsViewShare => 'Share';

  @override
  String get contactsViewSend => 'Send';

  @override
  String get contactsViewDelete => 'Delete';

  @override
  String get contactsViewDeleteContactTitle => 'DELETE CONTACT';

  @override
  String contactsViewDeleteConfirm(Object name) {
    return 'Remove \"$name\" from your contacts?';
  }

  @override
  String contactsViewRemovedFromContacts(Object name) {
    return '$name removed from contacts';
  }

  @override
  String get contactsViewFailedToRemove => 'Failed to remove contact';

  @override
  String get contactsViewSearchHint => 'Search name, address, or inbox';

  @override
  String get contactsViewFilterPersonal => 'Personal';

  @override
  String get contactsViewFilterOrgs => 'Orgs';

  @override
  String get contactsViewSortAsc => 'A-Z';

  @override
  String get contactsViewSortDesc => 'Z-A';

  @override
  String get contactsViewNewOrg => 'New Org';

  @override
  String get contactsViewSettings => 'Settings';

  @override
  String get contactsViewFailedToLoad => 'Failed to load contacts';

  @override
  String get contactsViewNoMatches => 'No matches';

  @override
  String get contactsViewNoContactsYet => 'No contacts yet';

  @override
  String get contactsViewNoMatchesHint =>
      'Try a different name, address, or inbox ID.';

  @override
  String get contactsViewEmptyHint =>
      'PublicOS contacts you interact with will appear here.';

  @override
  String get channelSigninTitle => 'Channel sign-in';

  @override
  String get channelSigninBodyOptional =>
      'This channel\'s server accepts PublicOS sign-in. Signed in, every read identifies you to this server: you count as a verified reader and the channel can respond to who you are. Signed out, you read anonymously.';

  @override
  String get channelSigninBodyRequired =>
      'This channel requires PublicOS sign-in to read - your reads identify you to its server.';

  @override
  String get channelSigninStateOn =>
      'You are currently signed in to this channel.';

  @override
  String get channelSigninStateOff => 'You are currently reading anonymously.';

  @override
  String get channelSigninEnable => 'Sign in';

  @override
  String get channelSigninDisable => 'Sign out';

  @override
  String get channelSigninAllow => 'Allow';

  @override
  String get channelSigninDeny => 'Deny';

  @override
  String get channelSigninForget => 'Forget';

  @override
  String get channelSigninMenuTitle => 'Sign-in on this channel';

  @override
  String get signinLockedBadge => 'SIGN-IN REQUIRED';

  @override
  String get signinLockedBlurbDenied =>
      'You said no to this channel. Sign in to read it.';

  @override
  String get signinLockedBlurbAsk =>
      'This channel requires sign-in to read. Your reads identify you to its server.';

  @override
  String get feedsSettingsSheetAutoSigninLabel => 'AUTO-SIGN-IN TO FEEDS';

  @override
  String get feedsSettingsSheetAutoSigninOn =>
      'Signing in everywhere you have not said no';

  @override
  String get feedsSettingsSheetAutoSigninOff => 'Each channel asks once';

  @override
  String get feedsViewDiscover => 'Discover';

  @override
  String get feedsViewBookmarks => 'Bookmarks';

  @override
  String get feedsViewVia => 'via';

  @override
  String get feedsViewOnboardingTitle => 'Your lists and channels go here';

  @override
  String get feedsViewOnboardingSubtitle =>
      'Create or follow a channel to start';

  @override
  String get messagesViewSearchHint => 'Search name, address, or inbox';

  @override
  String get messagesViewEmptyNoMatchesTitle => 'No matches';

  @override
  String get messagesViewEmptyNoMatchesSubtitle =>
      'Try a different name, address, or inbox ID.';

  @override
  String get messagesViewEmptyNoRequestsTitle => 'No new requests';

  @override
  String get messagesViewEmptyNoRequestsSubtitle =>
      'New conversation requests will appear here.';

  @override
  String get messagesViewEmptyNoConversationsTitle => 'No conversations yet';

  @override
  String get messagesViewEmptyNoConversationsSubtitle =>
      'Start a new conversation to see it here.';

  @override
  String get messagesViewNoKeysTitle => 'Get your inbox started';

  @override
  String get messagesViewNoKeysSubtitleBefore =>
      'Sign in with one of your keys using the ';

  @override
  String get messagesViewNoKeysSubtitleAfter => ' button in the keychain.';

  @override
  String get manageChannelPageManageLabel => 'manage';

  @override
  String get manageChannelPageMissingServerInfo =>
      'Channel is missing server info — can\'t build URL';

  @override
  String manageChannelPageExportUrlCopied(Object label) {
    return '$label URL copied';
  }

  @override
  String get manageChannelPageDeleteTitle => 'Delete channel?';

  @override
  String manageChannelPageDeleteBody(Object name) {
    return 'This removes \"$name\" and every post, comment, vote, reaction, follower, poster, ban, and whitelist entry attached to it. Can\'t be undone.';
  }

  @override
  String get manageChannelPageDelete => 'Delete';

  @override
  String manageChannelPageDeleted(Object name) {
    return 'Channel \"$name\" deleted';
  }

  @override
  String get manageChannelPageUnknownError => 'Unknown error';

  @override
  String manageChannelPageFailDelete(Object message) {
    return 'Failed to delete: $message';
  }

  @override
  String get manageChannelPageTabPosters => 'POSTERS';

  @override
  String get manageChannelPageTabBans => 'BANS';

  @override
  String get manageChannelPageTabReadAccess => 'READ ACCESS';

  @override
  String get manageChannelPageEditChannel => 'Edit channel';

  @override
  String get manageChannelPageMenuCopyJson => 'Copy JSON Feed URL';

  @override
  String get manageChannelPageMenuCopyRss => 'Copy RSS URL';

  @override
  String get manageChannelPageMenuCopyAtom => 'Copy Atom URL';

  @override
  String get manageChannelPageMenuDelete => 'Delete channel';

  @override
  String get manageChannelPageReasonHint => 'Reason (optional)';

  @override
  String get manageChannelPageRemoveTooltip => 'Remove';

  @override
  String get manageChannelPageGateCitizensOnly => 'CITIZENS ONLY';

  @override
  String get manageChannelPageWhoCanPost => 'WHO CAN POST';

  @override
  String manageChannelPagePostersVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You + $count allow-listed accounts',
      one: 'You + 1 allow-listed account',
      zero: 'Only you can post',
    );
    return '$_temp0';
  }

  @override
  String get manageChannelPagePostersExplainerApproved =>
      'Posting is on \"Approved\" — only the channel owner and addresses on this list can create posts.';

  @override
  String get manageChannelPagePostersVerdictOpen =>
      'Anyone with access can post';

  @override
  String get manageChannelPagePostersExplainerOpen =>
      'Posting is on \"Open\" — this list has no effect right now. Switch the channel\'s posting policy to \"Approved\" in Edit channel to use it.';

  @override
  String get manageChannelPagePostersVerdictOwnerOnly => 'Only you can post';

  @override
  String get manageChannelPagePostersExplainerOwner =>
      'Posting is on \"Owner only\" — this list has no effect right now. Switch the channel\'s posting policy to \"Approved\" in Edit channel to grant posting rights to specific accounts.';

  @override
  String get manageChannelPagePostersEmpty => 'No allow-listed posters yet';

  @override
  String get manageChannelPagePosterAddHint =>
      'Name or 0x address (allow to post)';

  @override
  String get manageChannelPagePosterAddButton => 'Allow';

  @override
  String get manageChannelPageFailAddPoster => 'Failed to add poster';

  @override
  String get manageChannelPageFailRemovePoster => 'Failed to remove poster';

  @override
  String get manageChannelPageWhosBlocked => 'WHO\'S BLOCKED';

  @override
  String manageChannelPageBansVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts banned',
      one: '1 account banned',
      zero: 'Nobody is banned from this channel',
    );
    return '$_temp0';
  }

  @override
  String get manageChannelPageBansExplainer =>
      'Banned accounts can\'t read, post, comment, vote, or react in this channel. Bans stick until removed here.';

  @override
  String get manageChannelPageBansEmpty => 'No one banned from this channel';

  @override
  String get manageChannelPageBanAddHint =>
      'Name or 0x address (ban from channel)';

  @override
  String get manageChannelPageBanAddButton => 'Ban';

  @override
  String get manageChannelPageFailBan => 'Failed to ban';

  @override
  String get manageChannelPageFailUnban => 'Failed to unban';

  @override
  String get manageChannelPageWhoCanRead => 'WHO CAN READ';

  @override
  String get manageChannelPageReadVerdictPublic =>
      'Channel is public — anyone can read';

  @override
  String get manageChannelPageReadExplainerPublic =>
      'The read whitelist only applies to private channels. Toggle \"Private\" in Edit channel to use this list — otherwise entries here are ignored.';

  @override
  String manageChannelPageReadVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You + $count readers',
      one: 'You + 1 reader',
      zero: 'Only you can read this private channel',
    );
    return '$_temp0';
  }

  @override
  String get manageChannelPageReadExplainerPrivate =>
      'Channel is private — only you and accounts on the list below can read posts. New requests appear above the list; approving moves them in.';

  @override
  String get manageChannelPageReadEmpty => 'No accounts on the read list yet';

  @override
  String get manageChannelPageReadAddHint =>
      'Name or 0x address (grant read access)';

  @override
  String get manageChannelPageReadAddButton => 'Allow read';

  @override
  String get manageChannelPageFailAddWhitelist => 'Failed to add to whitelist';

  @override
  String get manageChannelPageFailRemove => 'Failed to remove';

  @override
  String get manageChannelPageFailApprove => 'Failed to approve';

  @override
  String get manageChannelPageFailIgnore => 'Failed to ignore';

  @override
  String get manageChannelPageRequestsHeader => 'REQUESTS · LAST 14 DAYS';

  @override
  String get manageChannelPageFilterPending => 'Pending';

  @override
  String get manageChannelPageFilterIgnored => 'Ignored';

  @override
  String get manageChannelPageFilterApproved => 'Approved';

  @override
  String manageChannelPageNoRequestsInWindow(Object filter) {
    return 'No $filter requests in the last 14 days';
  }

  @override
  String manageChannelPageRequestedAt(Object when) {
    return 'Requested $when';
  }

  @override
  String get manageChannelPageRequestApprovedTag => 'approved';

  @override
  String get manageChannelPageActionIgnore => 'Ignore';

  @override
  String get manageChannelPageActionApprove => 'Approve';

  @override
  String get manageChannelPageJustNow => 'just now';

  @override
  String manageChannelPageMinutesAgo(Object minutes) {
    return '${minutes}m ago';
  }

  @override
  String manageChannelPageHoursAgo(Object hours) {
    return '${hours}h ago';
  }

  @override
  String manageChannelPageDaysAgo(Object days) {
    return '${days}d ago';
  }

  @override
  String manageChannelPageMonthsAgo(Object months) {
    return '${months}mo ago';
  }

  @override
  String get manageServerPageNoActiveAccount => 'No active account';

  @override
  String get manageServerPageAuthorUpdated => 'Author profile updated';

  @override
  String get manageServerPageAuthorUpdateFailed =>
      'Failed to update author profile';

  @override
  String manageServerPageCopied(Object url) {
    return 'Copied: $url';
  }

  @override
  String get manageServerPageDeleteChannelTitle => 'Delete channel';

  @override
  String manageServerPageDeleteChannelBody(Object name) {
    return 'Delete \"$name\" and every post in it? This can\'t be undone.';
  }

  @override
  String manageServerPageDeletedNamed(Object name) {
    return 'Deleted $name';
  }

  @override
  String get manageServerPageDeleteFailed => 'Delete failed';

  @override
  String get manageServerPageGalleryPermissionDenied =>
      'Gallery permission denied';

  @override
  String manageServerPageDownloadFailedHttp(Object code) {
    return 'Download failed (HTTP $code)';
  }

  @override
  String get manageServerPageSavedToGallery => 'Saved to gallery';

  @override
  String get manageServerPageDownloadFailed => 'Download failed';

  @override
  String get manageServerPageAddressMustBeHex => 'Address must be 0x… (40 hex)';

  @override
  String get manageServerPageAddFailed => 'Add failed';

  @override
  String get manageServerPageRemoveFailed => 'Remove failed';

  @override
  String get manageServerPageBanFailed => 'Ban failed';

  @override
  String get manageServerPageUnbanFailed => 'Unban failed';

  @override
  String get manageServerPageCouldNotOpen => 'Could not open';

  @override
  String get manageServerPageDelete => 'Delete';

  @override
  String get manageServerPageConfirm => 'Confirm';

  @override
  String get manageServerPageTitle => 'Manage Server';

  @override
  String get manageServerPageIdentity => 'Identity';

  @override
  String get manageServerPageCustomPill => 'CUSTOM';

  @override
  String get manageServerPageIdentityDescSsp =>
      'Your subscribed Social Server. Posts, channels, media and moderation all live here.';

  @override
  String get manageServerPageIdentityDescCustom =>
      'A custom feed server you added directly. Not registered on-chain — only visible to clients you tell about it.';

  @override
  String get manageServerPageLabel => 'Label';

  @override
  String get manageServerPageUrl => 'URL';

  @override
  String get manageServerPageSlug => 'Slug';

  @override
  String get manageServerPageAuthorProfile => 'Author Profile';

  @override
  String get manageServerPageAuthorDesc =>
      'How non-PublicOS RSS readers see you (NetNewsWire, Feedbin, Inoreader, etc). PublicOS-aware clients ignore these fields and always show your on-chain profile instead.';

  @override
  String get manageServerPageHandle => 'Handle';

  @override
  String get manageServerPageNote => 'Note';

  @override
  String get manageServerPageHandleNote =>
      'Handle is set automatically from your address and can\'t be changed here.';

  @override
  String get manageServerPageDisplayName => 'Display name';

  @override
  String get manageServerPageDisplayNameHint => 'Shown next to your posts';

  @override
  String get manageServerPageBio => 'Bio';

  @override
  String get manageServerPageBioHint => 'A short line about you';

  @override
  String get manageServerPageAvatarUrl => 'Avatar URL';

  @override
  String get manageServerPageSaving => 'SAVING…';

  @override
  String get manageServerPageSaveAuthorProfile => 'SAVE AUTHOR PROFILE';

  @override
  String get manageServerPageMedia => 'Media';

  @override
  String get manageServerPagePrivateBadge => 'PRIVATE';

  @override
  String manageServerPageFilesPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count FILES',
      one: '1 FILE',
    );
    return '$_temp0';
  }

  @override
  String manageServerPageQuotaUsed(Object used, Object total) {
    return '$used / $total MB';
  }

  @override
  String manageServerPageQuotaUsedNoTotal(Object used) {
    return '$used MB used';
  }

  @override
  String manageServerPageFileCountWithMax(Object count, Object max) {
    return '$count / $max files';
  }

  @override
  String manageServerPageFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String get manageServerPageQuotaFullBoth =>
      'Quota full. Delete files to free both size and count.';

  @override
  String get manageServerPageFileCountLimit =>
      'File-count limit reached. Delete files to upload more.';

  @override
  String get manageServerPageStorageQuotaFull =>
      'Storage quota full. Delete files to free space.';

  @override
  String get manageServerPageNoMedia =>
      'No media files. Files uploaded from compose post or avatar/banner pickers will show up here.';

  @override
  String get manageServerPageUnknownMime => 'unknown';

  @override
  String get manageServerPagePreview => 'Preview';

  @override
  String get manageServerPageOpenInBrowser => 'Open in browser';

  @override
  String get manageServerPageDownload => 'Download';

  @override
  String get manageServerPageCopyLink => 'Copy link';

  @override
  String get manageServerPageChannels => 'Channels';

  @override
  String get manageServerPageNoChannels => 'No channels yet on this server.';

  @override
  String get manageServerPageCreateChannel => 'CREATE CHANNEL';

  @override
  String get manageServerPageCopyUrl => 'Copy URL';

  @override
  String get manageServerPageRemoveFromTabs => 'Remove from Tabs';

  @override
  String get manageServerPageAddAsTab => 'Add as Tab';

  @override
  String get manageServerPageSettings => 'Settings';

  @override
  String get manageServerPageAddressHint => 'Name or 0x address';

  @override
  String get accountResolveNoMatch =>
      'No account found for that name — enter a 0x address or pick a contact';

  @override
  String get manageServerPageRemove => 'Remove';

  @override
  String get manageServerPageBans => 'Bans';

  @override
  String get manageServerPageBansDesc =>
      'Account-wide ban: blocked from posting, commenting and reacting on every channel you own here. Always wins over per-channel rules.';

  @override
  String get manageServerPageReasonHint => 'Reason (optional)';

  @override
  String get manageServerPageBan => 'Ban';

  @override
  String get manageServerPageNoBans => 'No accounts banned.';

  @override
  String get manageServerPageUnban => 'Unban';

  @override
  String get manageServerPageDeleteFileTitle => 'Delete file';

  @override
  String manageServerPageDeleteFileBody(Object name) {
    return 'Delete \"$name\"? This frees up your media quota and can\'t be undone.';
  }

  @override
  String get nodePageTitle => 'Nodes';

  @override
  String get nodePageMyNodes => 'My Nodes';

  @override
  String get nodePageNotSigner =>
      'You\'re not a signer. Signers are admitted through governance, not by sign-up.';

  @override
  String get nodePageNodeDirectory => 'Node Directory';

  @override
  String get nodePageDirectoryDescription =>
      'Browse the consensus signers currently securing the network.';

  @override
  String get nodePageBrowseNodes => 'BROWSE NODES';

  @override
  String get nodePageNotariesTitle => 'The network\'s notaries';

  @override
  String get nodePageNotariesBody1 =>
      'Signers run the consensus nodes that notarize every block: the shared public record the whole network is built on.';

  @override
  String get nodePageNotariesBody2 =>
      'To keep that record trustworthy, the signer set stays small and accountable: new signers are admitted only through governance, never by open sign-up.';

  @override
  String get nodePageAdmittedByGovernance => 'Admitted by governance';

  @override
  String get nodePagePoaSubtitle => 'PoA consensus signers';

  @override
  String get nodePageFailedToLoad => 'Failed to load nodes';

  @override
  String get nodePageNoNodes => 'No nodes registered yet';

  @override
  String get nodePageRunBy => 'Run by ';

  @override
  String get nodePageRemoveNodeTitle => 'Remove Node';

  @override
  String nodePageRemoveNodeBody(Object address) {
    return 'Are you sure you want to remove this node? This action cannot be undone.\n\n$address';
  }

  @override
  String get nodePageRemove => 'Remove';

  @override
  String get nodePageNodeRemoved => 'Node removed successfully';

  @override
  String get nodePageManageNode => 'Manage Node';

  @override
  String get nodePageAddress => 'ADDRESS';

  @override
  String get nodePageRemoveNodeButton => 'REMOVE NODE';

  @override
  String get nodePageLabelField => 'Label';

  @override
  String get nodePageSave => 'Save';

  @override
  String get nodePageLabelUpper => 'LABEL';

  @override
  String get nodePageEditLabel => 'Edit label';

  @override
  String get notificationsScreenTitle => 'Notifications';

  @override
  String get notificationsScreenTypesTooltip => 'Notification types';

  @override
  String get notificationsScreenNoActivity => 'No activity yet.';

  @override
  String get notificationsScreenYou => 'You';

  @override
  String get notificationsScreenYouUpdatedAvatar => 'You updated your avatar';

  @override
  String get notificationsScreenTheyUpdatedAvatar => ' updated their avatar';

  @override
  String get notificationsScreenYouUpdatedBanner => 'You updated your banner';

  @override
  String get notificationsScreenTheyUpdatedBanner => ' updated their banner';

  @override
  String get notificationsScreenYouUpdatedBio => 'You updated your bio';

  @override
  String get notificationsScreenTheyUpdatedBio => ' updated their bio';

  @override
  String get notificationsScreenYouUpdatedProfile => 'You updated your profile';

  @override
  String get notificationsScreenTheyUpdatedProfile => ' updated their profile';

  @override
  String get notificationsScreenYouUpdatedTabs => 'You updated your tabs';

  @override
  String get notificationsScreenTheyUpdatedTabs => ' updated their tabs';

  @override
  String get notificationsScreenVouchedForYou => ' vouched for you 🎉';

  @override
  String get notificationsScreenYouVouchedFor => 'You vouched for ';

  @override
  String get notificationsScreenVouchedFor => ' vouched for ';

  @override
  String get notificationsScreenYoureNowA => 'You\'re now a ';

  @override
  String get notificationsScreenCitizen => 'citizen';

  @override
  String get notificationsScreenIsNowCitizen => ' is now a citizen 🎉';

  @override
  String notificationsScreenMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String notificationsScreenYouPaidRent(Object label) {
    return 'You paid your domain — $label';
  }

  @override
  String notificationsScreenTheyPaidRent(Object label) {
    return ' paid their domain — $label';
  }

  @override
  String get notificationsScreenYourAccountEvicted =>
      'Your account was evicted for non-payment';

  @override
  String get notificationsScreenWasEvicted => ' was evicted for non-payment';

  @override
  String get notificationsScreenYouChangedName => 'You changed your name';

  @override
  String notificationsScreenYoureNowHandle(Object name) {
    return 'You\'re now @$name';
  }

  @override
  String get notificationsScreenChangedTheirName => ' changed their name';

  @override
  String notificationsScreenIsNowHandle(Object name) {
    return ' is now @$name';
  }

  @override
  String get notificationsScreenYouChangedDisplayName =>
      'You changed your display name';

  @override
  String notificationsScreenYouChangedDisplayNameTo(Object name) {
    return 'You changed your display name to $name';
  }

  @override
  String get notificationsScreenChangedDisplayName =>
      ' changed their display name';

  @override
  String notificationsScreenChangedDisplayNameTo(Object name) {
    return ' changed their display name to $name';
  }

  @override
  String get notificationsScreenRelTimeNow => 'now';

  @override
  String get profilePageVoteStarted => 'Vote started — members need to approve';

  @override
  String get profilePageBioPlaceholder => 'Tell us something about yourself!';

  @override
  String get profilePageSavingToChain => 'Saving to chain...';

  @override
  String get profilePageRefreshingProfile => 'Refreshing profile...';

  @override
  String get profilePageStartingVote => 'Starting vote...';

  @override
  String get profilePageProfileUpdated => 'Profile updated';

  @override
  String get profilePageBlockchainError =>
      'Blockchain error — please try again';

  @override
  String get profilePageSavingLayout => 'Saving layout...';

  @override
  String get profilePageLayoutSaved => 'Layout saved';

  @override
  String get profilePageDeletingFromChain => 'Deleting from chain...';

  @override
  String get profilePageRecordDeleted => 'Record deleted';

  @override
  String profilePageMemberCountWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'members',
      one: 'member',
    );
    return '$_temp0';
  }

  @override
  String get profilePageFoundedBy => 'founded by ';

  @override
  String profilePageJoined(Object month, Object year) {
    return 'Joined $month $year';
  }

  @override
  String get profilePageMonthJanuary => 'January';

  @override
  String get profilePageMonthFebruary => 'February';

  @override
  String get profilePageMonthMarch => 'March';

  @override
  String get profilePageMonthApril => 'April';

  @override
  String get profilePageMonthMay => 'May';

  @override
  String get profilePageMonthJune => 'June';

  @override
  String get profilePageMonthJuly => 'July';

  @override
  String get profilePageMonthAugust => 'August';

  @override
  String get profilePageMonthSeptember => 'September';

  @override
  String get profilePageMonthOctober => 'October';

  @override
  String get profilePageMonthNovember => 'November';

  @override
  String get profilePageMonthDecember => 'December';

  @override
  String get profileQrPageScanHint => 'Scan to open this profile.';

  @override
  String get profileQrPageLinkCopied => 'Profile link copied';

  @override
  String get profileQrPageCopyLink => 'COPY PROFILE LINK';

  @override
  String get contactProfileSettingsManageContact => 'Manage Contact';

  @override
  String get contactProfileSettingsContactOSAddress => 'ContactOS Address';

  @override
  String get contactProfileSettingsPrimaryInboxId => 'Primary Inbox ID';

  @override
  String get contactProfileSettingsRegisteredInboxIds => 'Registered Inbox IDs';

  @override
  String get contactProfileSettingsDefaultLabel => 'Default';

  @override
  String contactProfileSettingsInboxIdLabel(Object label) {
    return '$label Inbox ID';
  }

  @override
  String contactProfileSettingsCopiedToClipboard(Object label) {
    return '$label copied to clipboard';
  }

  @override
  String get contactProfileSettingsInvalidAddress => 'Invalid Address';

  @override
  String get contactProfileSettingsBlockContact => 'Block Contact';

  @override
  String get contactProfileSettingsUnblockContact => 'Unblock Contact';

  @override
  String get contactProfileSettingsContactBlocked =>
      'Contact blocked successfully';

  @override
  String get contactProfileSettingsContactUnblocked =>
      'Contact unblocked successfully';

  @override
  String get groupAccountSettingsCopiedToClipboard => 'Copied to clipboard';

  @override
  String get groupAccountSettingsLeaveOrgTitle => 'Leave Org';

  @override
  String groupAccountSettingsLeaveOrgConfirm(Object name) {
    return 'Are you sure you want to leave $name?\n\nYou will lose access to org actions and will need to be re-added by members to rejoin.';
  }

  @override
  String get groupAccountSettingsLeaveButton => 'Leave';

  @override
  String groupAccountSettingsLeftOrgMessage(Object name) {
    return 'You have left $name';
  }

  @override
  String get groupAccountSettingsLeaveOrgFailed => 'Failed to leave org';

  @override
  String get groupAccountSettingsOrgIdentity => 'Org Identity';

  @override
  String get groupAccountSettingsNameLabel => 'NAME';

  @override
  String get groupAccountSettingsPublicosAddressLabel => 'PUBLICOS ADDRESS';

  @override
  String get groupAccountSettingsVotingQuorumLabel => 'VOTING QUORUM';

  @override
  String groupAccountSettingsVotingQuorumValue(int percent) {
    return '$percent% participation to pass';
  }

  @override
  String get groupAccountSettingsNotAvailable => 'N/A';

  @override
  String get groupAccountSettingsDangerZone => 'Danger Zone';

  @override
  String get groupAccountSettingsLeaveThisOrg => 'Leave this org';

  @override
  String get groupAccountSettingsLeaveThisOrgDescription =>
      'You will be removed from the member list. This action is immediate and does not require a vote.';

  @override
  String get groupAccountSettingsLeaveOrgButton => 'LEAVE ORG';

  @override
  String get groupAccountSettingsCannotLeaveLastMember =>
      'CANNOT LEAVE AS LAST MEMBER';

  @override
  String get groupAccountSettingsDataSection => 'Data';

  @override
  String get groupAccountSettingsRefreshOrgData => 'REFRESH ORG DATA';

  @override
  String get groupChatSettingsNameEmpty => 'Group name cannot be empty';

  @override
  String get groupChatSettingsUpdateSuccess =>
      'Group information updated successfully';

  @override
  String get groupChatSettingsMemberRemoved => 'Member removed successfully';

  @override
  String get groupChatSettingsMembersAdded =>
      'Members added successfully. Refreshing group data...';

  @override
  String get groupChatSettingsAdminRemoved => 'Admin role removed successfully';

  @override
  String get groupChatSettingsAdminGranted => 'Admin role granted successfully';

  @override
  String get groupChatSettingsSuperAdminRemoved =>
      'Super admin role removed successfully';

  @override
  String get groupChatSettingsSuperAdminGranted =>
      'Super admin role granted successfully';

  @override
  String get groupChatSettingsRoleSuperAdmin => 'SUPER ADMIN';

  @override
  String get groupChatSettingsRoleAdmin => 'ADMIN';

  @override
  String get groupChatSettingsRoleMember => 'MEMBER';

  @override
  String get groupChatSettingsRemoveAdmin => 'Remove admin';

  @override
  String get groupChatSettingsMakeAdmin => 'Make admin';

  @override
  String get groupChatSettingsRemoveSuperAdmin => 'Remove super admin';

  @override
  String get groupChatSettingsMakeSuperAdmin => 'Make super admin';

  @override
  String get groupChatSettingsRemoveMember => 'Remove member';

  @override
  String get groupChatSettingsNotGroup =>
      'This conversation is not a group chat';

  @override
  String get groupChatSettingsDefaultGroupName => 'Group';

  @override
  String get groupChatSettingsSectionDetails => 'Group Details';

  @override
  String get groupChatSettingsFieldName => 'Group Name';

  @override
  String get groupChatSettingsFieldDescription => 'Description';

  @override
  String get groupChatSettingsFieldImageUrl => 'Image URL';

  @override
  String get groupChatSettingsSaving => 'SAVING…';

  @override
  String get groupChatSettingsSaveChanges => 'SAVE CHANGES';

  @override
  String get groupChatSettingsSectionMembers => 'Members';

  @override
  String get groupChatSettingsSearchHint => 'Search members…';

  @override
  String get groupChatSettingsFilterAll => 'All';

  @override
  String get groupChatSettingsFilterSuperAdmin => 'Super Admin';

  @override
  String get groupChatSettingsFilterAdmin => 'Admin';

  @override
  String get groupChatSettingsFilterMember => 'Member';

  @override
  String get groupChatSettingsNoMembers => 'No members found';

  @override
  String groupChatSettingsNoMatch(Object query) {
    return 'No members match \"$query\"';
  }

  @override
  String groupChatSettingsChipLabel(Object label, Object count) {
    return '$label ($count)';
  }

  @override
  String get groupChatSettingsAdd => 'ADD';

  @override
  String get publicosAccountSettingsAccountIdentity => 'Account Identity';

  @override
  String get publicosAccountSettingsUsernameLabel => 'USERNAME';

  @override
  String get publicosAccountSettingsAccountAddressLabel => 'ACCOUNT ADDRESS';

  @override
  String get publicosAccountSettingsRegisteredInboxIds =>
      'Registered Inbox IDs';

  @override
  String get publicosAccountSettingsRegisteredInboxIdsHint =>
      'XMTP inbox IDs registered to this account on-chain';

  @override
  String get publicosAccountSettingsNoInboxIds => 'No inbox IDs registered';

  @override
  String get publicosAccountSettingsUnlabeled => 'Unlabeled';

  @override
  String get publicosAccountSettingsInboxIdLabel => 'Inbox ID';

  @override
  String get publicosAccountSettingsSessionWallets => 'Session Wallets';

  @override
  String get publicosAccountSettingsSessionWalletsHint =>
      'Wallet addresses authorized to control this account';

  @override
  String get publicosAccountSettingsNoSessions => 'No sessions found';

  @override
  String get publicosAccountSettingsPrimaryBadge => 'PRIMARY';

  @override
  String publicosAccountSettingsSessionNumber(Object number) {
    return 'Session $number';
  }

  @override
  String get publicosAccountSettingsSessionAddressLabel => 'Session address';

  @override
  String get publicosAccountSettingsConversation => 'Conversation';

  @override
  String get publicosAccountSettingsConversationHint =>
      'Your direct message channel with this contact';

  @override
  String get publicosAccountSettingsPrimaryInboxIdLabel => 'PRIMARY INBOX ID';

  @override
  String get publicosAccountSettingsNotAvailable => 'N/A';

  @override
  String get publicosAccountSettingsActions => 'Actions';

  @override
  String get publicosAccountSettingsRefreshing => 'REFRESHING…';

  @override
  String get publicosAccountSettingsRefreshContactDetails =>
      'REFRESH CONTACT DETAILS';

  @override
  String get publicosAccountSettingsContactRefreshed =>
      'Contact details refreshed';

  @override
  String publicosAccountSettingsCopiedToClipboard(Object label) {
    return '$label copied to clipboard';
  }

  @override
  String xmtpContactSettingsCopiedToClipboard(Object label) {
    return '$label copied to clipboard';
  }

  @override
  String get xmtpContactSettingsInvalidAddress => 'Invalid Address';

  @override
  String get xmtpContactSettingsDisplayNameUpdated =>
      'Display name updated successfully';

  @override
  String get xmtpContactSettingsColorUpdated =>
      'Contact color updated successfully';

  @override
  String get xmtpContactSettingsDetailsUpdated =>
      'Contact details updated successfully';

  @override
  String get xmtpContactSettingsUnsupportedContact =>
      'This contact type is not supported by this settings screen';

  @override
  String get xmtpContactSettingsContactInformation => 'Contact Information';

  @override
  String get xmtpContactSettingsPrimaryInboxId => 'Primary Inbox ID';

  @override
  String get xmtpContactSettingsClientsSection => 'XMTP Clients';

  @override
  String get xmtpContactSettingsAddressLabel => 'Address';

  @override
  String get xmtpContactSettingsDisplayName => 'Display Name';

  @override
  String get xmtpContactSettingsEnterDisplayName => 'Enter display name';

  @override
  String get xmtpContactSettingsChatColor => 'Chat Color';

  @override
  String get xmtpContactSettingsSaveChanges => 'SAVE CHANGES';

  @override
  String get xmtpContactSettingsUpdating => 'UPDATING…';

  @override
  String get xmtpContactSettingsUpdateContactDetails =>
      'UPDATE CONTACT DETAILS';

  @override
  String get sspScreenNoActiveAccount => 'No active account';

  @override
  String get sspScreenNoActiveSession => 'No active session';

  @override
  String get sspScreenEndpointNoUrl => 'Endpoint has no URL';

  @override
  String sspScreenConnectingTo(Object label) {
    return 'Connecting to $label…';
  }

  @override
  String sspScreenConnectedTo(Object label) {
    return 'Connected to $label';
  }

  @override
  String sspScreenRemoved(Object label) {
    return 'Removed $label';
  }

  @override
  String sspScreenCouldNotRemove(Object label) {
    return 'Could not remove $label';
  }

  @override
  String get sspScreenConnection => 'Connection';

  @override
  String get sspScreenEndpoint => 'Endpoint';

  @override
  String get sspScreenManage => 'MANAGE';

  @override
  String get sspScreenProviders => 'Providers';

  @override
  String get sspScreenRegisterSsp => 'REGISTER SSP';

  @override
  String get sspScreenAddCustom => 'ADD CUSTOM';

  @override
  String get sspScreenBadgeMine => 'MINE';

  @override
  String get sspScreenBadgeSubscribed => 'SUBSCRIBED';

  @override
  String get sspScreenEmptyCitizen =>
      'No server connected yet. Pick an SSP from Services, register your own, or add a custom server below.';

  @override
  String get sspScreenEmptyPrivate =>
      'No server connected yet. Subscribe to an SSP from Services, register your own, or add a custom server below.';

  @override
  String get sspScreenStatusUnreachableLabel => 'UNREACHABLE';

  @override
  String get sspScreenStatusUnreachableDesc =>
      'No feed server is responding. Social feeds, posts, and media are unavailable.';

  @override
  String get sspScreenStatusSspLabel => 'SSP CONNECTED';

  @override
  String get sspScreenStatusSspDesc =>
      'Connected through your subscribed Social Service Provider.';

  @override
  String get sspScreenStatusCustomLabel => 'CUSTOM SERVER';

  @override
  String get sspScreenStatusCustomDesc =>
      'Connected through a custom feed server you configured.';

  @override
  String get sspScreenStatusOverrideLabel => 'APP OVERRIDE';

  @override
  String get sspScreenStatusOverrideDesc =>
      'Connected through an override endpoint set by this app.';

  @override
  String get sspScreenStatusPublicLabel => 'PUBLIC FALLBACK';

  @override
  String get sspScreenStatusPublicDesc =>
      'Connected to the default public feed server. Subscribe to an SSP or add a custom server for better reliability.';

  @override
  String get sspScreenLegendNoServer => 'No feed server available';

  @override
  String get sspScreenLegendPublicFallback => 'Public fallback server';

  @override
  String get sspScreenLegendSspOrCustom => 'SSP or custom server';

  @override
  String get sspScreenLabelUrl => 'URL';

  @override
  String get sspScreenLabelSubs => 'SUBS';

  @override
  String get sspScreenRunBy => 'RUN BY';

  @override
  String sspScreenSubscriberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscribers',
      one: '1 subscriber',
    );
    return '$_temp0';
  }

  @override
  String get sspScreenConnect => 'CONNECT';

  @override
  String get sspScreenConnected => 'CONNECTED';

  @override
  String get sspScreenDelete => 'DELETE';

  @override
  String get sspScreenCustomServerSubtitle => 'custom server';

  @override
  String get sspScreenRegisterTitle => 'New SSP on-chain';

  @override
  String get sspScreenRegisterSubtitle =>
      'Register yourself as a Social Service Provider. Citizens only.';

  @override
  String get sspScreenFieldSlug => 'Slug';

  @override
  String get sspScreenSlugHint => 'e.g. my-ssp-service';

  @override
  String get sspScreenSlugHelper =>
      '3-32 chars, lowercase, numbers, dashes, underscores';

  @override
  String get sspScreenSlugRequired => 'Slug is required';

  @override
  String get sspScreenSlugInvalid =>
      '3-32 chars: lowercase letters, numbers, - _';

  @override
  String get sspScreenFieldTitle => 'Title';

  @override
  String get sspScreenTitleHint => 'e.g. My SSP Service';

  @override
  String get sspScreenTitleRequired => 'Title is required';

  @override
  String get sspScreenFieldApiUrl => 'API URL';

  @override
  String get sspScreenApiUrlRequired => 'API URL is required';

  @override
  String get sspScreenFieldRegion => 'Region';

  @override
  String get sspScreenRegionHint => 'e.g. us-east, eu-west';

  @override
  String get sspScreenFieldWebsite => 'Website';

  @override
  String get sspScreenRegistering => 'REGISTERING…';

  @override
  String get sspScreenRegister => 'REGISTER';

  @override
  String get sspScreenAddCustomTitle => 'Point at your own server';

  @override
  String get sspScreenAddCustomSubtitle =>
      'Reachability is verified after connecting.';

  @override
  String get sspScreenFieldName => 'Name';

  @override
  String get sspScreenNameHint => 'e.g. My Feed Server';

  @override
  String get sspScreenFieldServerUrl => 'Server URL';

  @override
  String get sspScreenUrlRequired => 'URL is required';

  @override
  String get sspScreenTesting => 'TESTING…';

  @override
  String get sspScreenAdd => 'ADD';

  @override
  String get treasuryPageTitle => 'Services';

  @override
  String treasuryPageActionFailedToSend(Object label) {
    return '$label failed to send';
  }

  @override
  String treasuryPageActionConfirmed(Object label) {
    return '$label confirmed';
  }

  @override
  String treasuryPageActionFailedOnChain(Object label) {
    return '$label failed on-chain';
  }

  @override
  String get treasuryPageClaimedSuccess => 'Claimed';

  @override
  String treasuryPageSubscribedTo(Object provider) {
    return 'Subscribed to $provider';
  }

  @override
  String treasuryPageProviderSwitched(Object provider) {
    return '$provider switched';
  }

  @override
  String treasuryPageProviderExtended(Object provider) {
    return '$provider subscription extended';
  }

  @override
  String get treasuryPageProviderOnboardingSoon =>
      'Working on this — provider onboarding coming soon';

  @override
  String get treasuryPagePeriodFallback => 'period';

  @override
  String treasuryPagePeriodDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String treasuryPagePeriodHours(Object n) {
    return '$n h';
  }

  @override
  String treasuryPagePeriodMinutes(Object n) {
    return '$n min';
  }

  @override
  String get treasuryPageRelativeNow => 'now';

  @override
  String treasuryPageRelativeSeconds(Object n) {
    return 'in $n s';
  }

  @override
  String treasuryPageRelativeMinutes(Object n) {
    return 'in $n min';
  }

  @override
  String treasuryPageRelativeHours(Object n) {
    return 'in $n h';
  }

  @override
  String treasuryPageRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get treasuryPageRoleCitizen => 'CITIZEN';

  @override
  String get treasuryPageRolePrivate => 'PRIVATE ACCOUNT';

  @override
  String get treasuryPageRoleCitizenMeaning =>
      'You get a share of the economy, vote on governance, create orgs. A 5+ character name is free to hold forever.';

  @override
  String get treasuryPageRolePrivateMeaning =>
      'You pay a recurring domain fee to hold your name and keep write access to the chain. You don\'t get a share of the economy or vote.';

  @override
  String get treasuryPageYourRole => 'Your role';

  @override
  String treasuryPageCitizenSummary(String privateIcon) {
    return 'You hold a socially verified PublicOS Domain. You own PublicOS and get a share of its economy, which you can claim any time. Your BSP and SSP are a public service, free for you, while private accounts $privateIcon pay for theirs. You choose your providers, so check your subscriptions often.';
  }

  @override
  String get treasuryPagePrivateSummary =>
      'Your PublicOS Domain is private, no verification needed. A BSP is how your app reaches the chain: it reads for you and sends your transactions. You can use a public BSP (rate limited) or subscribe to one. SSP (feed and media hosting) is optional: subscribe to one here, use any server outside PublicOS, or run your own.';

  @override
  String get treasuryPageWhatYouCanClaim => 'What you can claim';

  @override
  String get treasuryPageClaimExplainer =>
      'One claim pulls everything the economy owes you in a single transaction: your share of the economy and any provider earnings. Outstanding fines are withheld automatically.';

  @override
  String get treasuryPageClaimable => 'Claimable';

  @override
  String get treasuryPageStipend => 'Economy share';

  @override
  String get treasuryPageEarnings => 'Earnings';

  @override
  String get treasuryPageGarnished => 'Withheld for penalties';

  @override
  String get treasuryPageClaiming => 'CLAIMING...';

  @override
  String treasuryPageClaimAmount(Object amount) {
    return 'CLAIM $amount OX';
  }

  @override
  String get treasuryPageNothingToClaim => 'NOTHING TO CLAIM';

  @override
  String treasuryPageRunProviders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You run $count providers — their earnings are part of this claim.',
      one: 'You run 1 provider — their earnings are part of this claim.',
    );
    return '$_temp0';
  }

  @override
  String get treasuryPageBecomeProvider => 'Become a provider';

  @override
  String get treasuryPageBecomeProviderBlurb =>
      'Providers work the network and get paid for it. Run a BSP to route private accounts, or an SSP to host their social data — every subscriber adds to your claim.';

  @override
  String get treasuryPageBecomeProviderButton => 'BECOME A PROVIDER';

  @override
  String get treasuryPageBspBlurb =>
      'An independent subscription that routes you to the chain. Paid by the second, only while it serves you.';

  @override
  String get treasuryPageSspBlurb =>
      'An independent subscription that hosts your social data. Paid by the second, only while it serves you.';

  @override
  String get treasuryPageSubNone => 'NONE';

  @override
  String get treasuryPageSubExpired => 'EXPIRED';

  @override
  String get treasuryPageSubActive => 'ACTIVE';

  @override
  String get treasuryPageSubSwitchOpen => 'SWITCH OPEN';

  @override
  String get treasuryPageSubExtendOpen => 'EXTEND OPEN';

  @override
  String get treasuryPageProvider => 'Provider';

  @override
  String get treasuryPagePaidUntil => 'Paid until';

  @override
  String get treasuryPageCycleEnds => 'Cycle ends';

  @override
  String treasuryPageLastProvider(Object provider) {
    return 'Last $provider';
  }

  @override
  String get treasuryPageLapsed => 'Lapsed';

  @override
  String treasuryPageSubNoneCitizen(Object provider) {
    return 'Pick a $provider to host your service. Citizens don\'t pay — the network mints the $provider fee for you.';
  }

  @override
  String treasuryPageSubNonePrivate(Object provider) {
    return 'Subscribe to a $provider. The fee accrues by the second and is drawn from your service balance — only once the provider has enough subscribers to be paid.';
  }

  @override
  String treasuryPageSubActivePrivateBody(Object provider) {
    return 'Active. The fee draws from your service balance by the second. Switch any time — the old provider is paid to the second.';
  }

  @override
  String treasuryPageSubCitizenLockedBody(
      Object provider, Object fromWhen, Object renewWhen) {
    return 'Active. You can switch $provider from $fromWhen (without losing your cycle); the network auto-renews $renewWhen.';
  }

  @override
  String treasuryPageSubCitizenSwitchOpenBody(
      Object provider, Object closesWhen) {
    return 'You can switch $provider now — your cycle end is kept, nothing extra to pay. Switch closes $closesWhen, then the network auto-renews.';
  }

  @override
  String get treasuryPageSubExpiredBody =>
      'Subscription lapsed. Subscribe again (the same provider or a new one) to restore the service.';

  @override
  String treasuryPageSubCitizenExtendOpenBody(Object provider) {
    return 'Extend now to keep $provider service — the network mints the fee for you.';
  }

  @override
  String get treasuryPageOpening => 'OPENING…';

  @override
  String treasuryPagePickProvider(Object provider) {
    return 'PICK A $provider';
  }

  @override
  String get treasuryPageSubscribeAgain => 'SUBSCRIBE AGAIN';

  @override
  String get treasuryPagePaying => 'PAYING…';

  @override
  String get treasuryPagePayInAdvance => 'PAY IN ADVANCE';

  @override
  String treasuryPageSwitchOpens(Object when) {
    return 'SWITCH OPENS $when';
  }

  @override
  String get treasuryPageExtending => 'EXTENDING…';

  @override
  String treasuryPageExtendProvider(Object provider) {
    return 'EXTEND $provider';
  }

  @override
  String treasuryPageSwitchProvider(Object provider) {
    return 'SWITCH $provider';
  }

  @override
  String get treasuryPageParameters => 'Parameters';

  @override
  String get treasuryPageDomainPrice => 'Domain price';

  @override
  String treasuryPageDomainTier3(Object price) {
    return '3 chars $price';
  }

  @override
  String treasuryPageDomainPriceExplain(
      Object tier4, Object tier5, Object tier6plus, Object minChars) {
    return '4 chars $tier4 · 5 chars $tier5 · 6+ $tier6plus. Citizens are free at $minChars+ chars. 98% of each payment is burned, 2% is shared with verified PublicOS Domains.';
  }

  @override
  String get treasuryPageLoading => 'Loading…';

  @override
  String get treasuryPageBspFee => 'BSP fee';

  @override
  String get treasuryPageBspFeeExplain =>
      'Paid by a private to their BSP each period. Independent of the domain.';

  @override
  String get treasuryPageSspFee => 'SSP fee';

  @override
  String get treasuryPageSspFeeExplain =>
      'Paid by a private to their SSP each period. Independent of the domain.';

  @override
  String get treasuryPageMultiMonthDiscount => 'Multi-month discount';

  @override
  String treasuryPageDiscountValue(Object percent) {
    return '$percent% per extra month';
  }

  @override
  String get treasuryPageDiscountExplain =>
      'Applies to the domain fee when you pay several periods up front.';

  @override
  String get treasuryPageTotalSupply => 'Total supply';

  @override
  String get treasuryPageTotalSupplyExplain =>
      'Shrinks on each domain burn, grows when the network mints provider fees and welcome bonuses.';

  @override
  String get treasuryPageTreasuryBalance => 'Treasury balance';

  @override
  String get treasuryPageTreasuryBalanceExplain =>
      'The DAO\'s operating budget. Funds grants and governance-approved spending.';

  @override
  String get treasuryPageParamsGovernance =>
      'Parameters are set by network governance';

  @override
  String get treasuryPageWhenToCheckBack => 'When to check back';

  @override
  String get treasuryPageCadenceClaimTitle => 'Claim';

  @override
  String get treasuryPageCadenceClaimBody =>
      'Your economy share, provider earnings and the welcome bonus accrue continuously. Check monthly and claim when the amount is worth a tx fee.';

  @override
  String get treasuryPageCadenceDomainTitle => 'Domain';

  @override
  String get treasuryPageCadenceDomainBody =>
      'Your paid-until date is on this page. Pay several periods up front to reduce checks and earn the discount.';

  @override
  String get treasuryPageCadenceServicesBody =>
      'Each service expires on its own clock, independent of your domain. Renew before the paid-until date.';

  @override
  String get treasuryPageNodesBody =>
      'The public directory of the nodes that run the network: who operates each one.';

  @override
  String get treasuryPageGrants => 'Grants';

  @override
  String get treasuryPageGrantsTitle => 'DAO-funded organizations and projects';

  @override
  String get treasuryPageGrantsBody =>
      'Governance-approved allocations for public-goods projects. Granted tokens land in your claim.';

  @override
  String get treasuryPageGrantsVotingNote =>
      'Grant proposals go through the governance voting process';

  @override
  String get trustTreeScreenAppBarTitle => 'SOCIAL GRAPH';

  @override
  String get trustTreeScreenAccountNotFound => 'Account not found';

  @override
  String get trustTreeScreenVouchNotConfirmed =>
      'Vouch not confirmed. Please retry.';

  @override
  String get trustTreeScreenUnknown => 'Unknown';

  @override
  String get trustTreeScreenLoading => 'Loading trust data…';

  @override
  String get trustTreeScreenSearchHint => 'Search by name or address';

  @override
  String get trustTreeScreenCopyAddress => 'Copy address';

  @override
  String get trustTreeScreenAddressCopied => 'Address copied';

  @override
  String trustTreeScreenCreatedBy(Object creator) {
    return 'BY $creator';
  }

  @override
  String get trustTreeScreenVouched => 'YOU VOUCHED';

  @override
  String get trustTreeScreenNoVouchers => 'NO VOUCHERS';

  @override
  String get trustTreeScreenNoVouchees => 'NO VOUCHEES';

  @override
  String trustTreeScreenMoreCount(Object count) {
    return '$count more';
  }

  @override
  String get trustTreeScreenMyTree => 'MY TREE';

  @override
  String get trustTreeScreenVouching => 'VOUCHING…';

  @override
  String trustTreeScreenVouchFor(Object name) {
    return 'VOUCH FOR $name';
  }

  @override
  String get mediaOverlayGalleryPermissionDenied => 'Gallery permission denied';

  @override
  String get mediaOverlayVideoSaved => 'Video saved to gallery';

  @override
  String get mediaOverlayImageSaved => 'Image saved to gallery';

  @override
  String get mediaOverlaySaveFailed => 'Failed to save';

  @override
  String get mediaOverlayBack => 'Back';

  @override
  String get mediaPickerOnlyImagesVideos =>
      'Only images and videos can be attached here';

  @override
  String get messageInputVideoNeedsServer =>
      'Sending a video needs a feed server';

  @override
  String get messageInputSendOx => 'Send OX';

  @override
  String get messageInputRecipientNoAddress =>
      'This contact can\'t receive OX yet';

  @override
  String get messageInputNoSendableMembers =>
      'No one in this group can receive OX yet';

  @override
  String get messageInputAttachRequest => 'Request';

  @override
  String get requestPaymentTitle => 'Request payment';

  @override
  String get requestPaymentPayTo => 'Receive at';

  @override
  String get requestPaymentAmount => 'Amount';

  @override
  String get requestPaymentSend => 'Send request';

  @override
  String get requestPaymentSending => 'Sending request…';

  @override
  String get requestPaymentChange => 'Change';

  @override
  String get requestPaymentDone => 'Done';

  @override
  String get requestPaymentSent => 'Payment request sent';

  @override
  String get requestPaymentCustomAddress => 'Paste an ETH address';

  @override
  String get requestPaymentCustomLabel => 'Custom address';

  @override
  String get requestPaymentInvalidAddress => 'Invalid address';

  @override
  String documentPickerTooLarge(Object size, Object max) {
    return 'Document too large ($size MB > $max MB)';
  }

  @override
  String get documentReadFailed => 'Couldn\'t read the selected file';

  @override
  String get documentTooLargeNoServer =>
      'This document is too large to send without a feed server';

  @override
  String get documentOpenFailed => 'No app available to open this file';

  @override
  String get documentSave => 'Save file';

  @override
  String get documentSaved => 'File saved';

  @override
  String get documentSaveFailed => 'Couldn\'t save the file';

  @override
  String get channelHeaderVerifiedReaders => 'Verified readers';

  @override
  String get channelHeaderTotalViews => 'Total views';

  @override
  String get channelHeaderOwner => 'Owner';

  @override
  String get channelHeaderBy => 'by';

  @override
  String get channelHeaderHostedBy => 'hosted by';

  @override
  String channelHeaderVerifiedReadersWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'verified readers',
      one: 'verified reader',
    );
    return '$_temp0';
  }

  @override
  String channelHeaderViewsWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'views',
      one: 'view',
    );
    return '$_temp0';
  }

  @override
  String get channelHeaderWriters => 'Writers';

  @override
  String channelHeaderWritersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count writers',
      one: '1 writer',
    );
    return '$_temp0';
  }

  @override
  String get channelHeaderStatsTitle => 'Reader activity';

  @override
  String get channelHeaderReadersThisWeek => 'Verified readers this week';

  @override
  String get channelHeaderTodayPartial => 'Today so far';

  @override
  String get channelHeaderTotalViewsAllTime => 'Total views (all time)';

  @override
  String get channelHeaderByTypeCitizens => 'Citizens';

  @override
  String get channelHeaderByTypePrivate => 'Private accounts';

  @override
  String get channelHeaderByTypeSigned => 'Signed, no account';

  @override
  String get channelHeaderByTypeAnonymous => 'Anonymous';

  @override
  String get channelHeaderToday => 'Today';

  @override
  String get channelHeaderVerifiedNote =>
      'Verified readers are distinct citizen accounts whose reads carried a valid signature. Each counts once per week.';

  @override
  String get channelHeaderClose => 'Close';

  @override
  String get managePlansTitle => 'Plans';

  @override
  String get managePlansSubtitle => 'What readers pay to read this channel.';

  @override
  String get managePlansNone =>
      'This channel is free. Add a plan to charge for it.';

  @override
  String get managePlansAdd => 'Add plan';

  @override
  String managePlansPerPeriod(Object days) {
    return 'per $days days';
  }

  @override
  String get managePlansOutdated => 'Outdated contract';

  @override
  String get managePlansOutdatedNote =>
      'This server has moved to a new contract. Readers who already paid keep their access; new subscriptions should use the current one.';

  @override
  String get managePlansMoveToCurrent => 'Move to current contract';

  @override
  String get managePlansRetired => 'Not for sale';

  @override
  String get managePlansRetiredNote =>
      'Kept so existing subscribers keep reading. Newer plans on this chain are sold instead.';

  @override
  String get managePlansRemove => 'Remove';

  @override
  String get managePlansRemoveConfirm =>
      'Remove this plan from the channel? Anyone subscribed through it loses access.';

  @override
  String get managePlansChain => 'Chain';

  @override
  String get managePlansPrice => 'Price';

  @override
  String get managePlansPeriodDays => 'Days per period';

  @override
  String get managePlansPayout => 'Paid out to';

  @override
  String get managePlansPayoutHint =>
      'Your account works — it resolves to your Safe.';

  @override
  String get managePlansPayoutUnreachable =>
      'This address cannot receive payments on this chain.';

  @override
  String get managePlansCreate => 'Create plan';

  @override
  String get managePlansCreating => 'Registering on chain…';

  @override
  String get managePlansAttaching => 'Attaching to channel…';

  @override
  String get managePlansNoChains => 'This server does not offer paid feeds.';

  @override
  String get managePlansUseExisting => 'Use a plan I already have';

  @override
  String get managePlansEnterManually => 'Enter a plan manually';

  @override
  String get managePlansPlanId => 'Plan ID';

  @override
  String get managePlansContractAddress => 'Contract address';

  @override
  String get managePlansLookup => 'Look up';

  @override
  String get managePlansNotFound => 'No plan with that ID on that contract.';

  @override
  String get managePlansForeignOwner =>
      'This plan belongs to another address. That is fine for a shared plan — payments go to its payout, not yours.';

  @override
  String get managePlansPriceRequired => 'Enter a price above zero.';

  @override
  String get managePlansSaved => 'Plans updated';

  @override
  String get managePlansManage => 'Manage plans';

  @override
  String get managePlansPaidBadge => 'Paid';

  @override
  String get managePlansFreeBadge => 'Free';

  @override
  String get createChannelPageSectionMonetization => 'Monetization';

  @override
  String get gateTierAnyoneLabel => 'Anyone';

  @override
  String get gateTierAnyoneSubtitle => 'No sign-in. Works in any feed reader.';

  @override
  String get gateTierSignedLabel => 'Signed in';

  @override
  String get gateTierSignedSubtitle =>
      'Anyone signed in with a wallet, PublicOS account or not.';

  @override
  String get gateTierAccountLabel => 'PublicOS accounts';

  @override
  String get gateTierAccountSubtitle =>
      'Only people with a PublicOS account. Wallet-only visitors are turned away.';

  @override
  String get gateTierStandingLabel => 'Accounts in good standing';

  @override
  String get gateTierStandingSubtitle =>
      'Citizens, and anyone whose domain is paid up.';

  @override
  String get gateTierCitizenLabel => 'Citizens';

  @override
  String get gateTierCitizenSubtitle => 'Only vouched citizens.';

  @override
  String get createChannelPageSectionAudience => 'WHO CAN SEE IT';

  @override
  String get createChannelPageAudienceNote =>
      'The minimum anyone needs to open this channel. Each option includes the ones above it.';

  @override
  String get createChannelPageSectionApprovedReaders => 'APPROVED READERS';

  @override
  String get createChannelPageUseFriendsLabel => 'My friends';

  @override
  String get createChannelPageUseFriendsSubtitle =>
      'The list you keep once and reuse across every channel.';

  @override
  String get createChannelPageUseChannelListLabel => 'This channel\'s list';

  @override
  String get createChannelPageUseChannelListSubtitle =>
      'People you approve for this channel only.';

  @override
  String get createChannelPageAudienceOpenNote =>
      'No list is on, so anyone who clears the setting above can read it.';

  @override
  String get createChannelPageAudienceRestrictedNote =>
      'A list is on, so this channel is private: it stops appearing in listings, and only people on an enabled list can read it. They still have to clear the setting above.';

  @override
  String get createChannelPageSectionComments => 'WHO CAN COMMENT';

  @override
  String get createChannelPageInteractionNote =>
      'Commenting and reacting also require being able to read the channel.';

  @override
  String get createChannelPageSectionReactions => 'WHO CAN REACT';

  @override
  String get createChannelPageSectionWhoCanPost => 'WHO CAN PUBLISH';

  @override
  String get createChannelPagePostersMustBeLabel => 'Posters must also be';

  @override
  String get chsAdd => 'Add';

  @override
  String get chsRemove => 'Remove';

  @override
  String get chsTitleLabel => 'SETTINGS';

  @override
  String get chsDrawerRead => 'Who can read it';

  @override
  String get chsDrawerPost => 'Who can post';

  @override
  String get chsDrawerTalk => 'Who can comment and react';

  @override
  String get chsDrawerBlocked => 'Blocked';

  @override
  String get chsDrawerVisibility => 'Visibility';

  @override
  String get chsDrawerMonetization => 'Monetization';

  @override
  String get chsReadNote =>
      'The outer gate. Posting, commenting and reacting all require this first.';

  @override
  String get chsPostNote => 'Writing a full post to the channel.';

  @override
  String get chsTalkNote =>
      'Comments, reactions and votes. Everyone here must also be able to read it.';

  @override
  String get chsBlockedNote =>
      'Blocked people cannot read, post, comment or react here. A block beats everything else, including being on one of your lists — and unlike an approval, it never expires.';

  @override
  String get chsVisibilityNote =>
      'How much of the channel gets served. Nothing is deleted — older posts stay on the server, they just stop being handed out in the feed.';

  @override
  String get chsMonetizationNote =>
      'Charging is a separate axis: a reader must clear the read gate and have paid. Money never buys past a block or an audience list.';

  @override
  String get chsSubAudience => 'Audience';

  @override
  String get chsSubFilter => 'Filter the audience by';

  @override
  String get chsSubRequests => 'Requests';

  @override
  String get chsSubReactions => 'Reactions';

  @override
  String get chsAudAnyone => 'Anyone';

  @override
  String get chsAudAnyoneSub => 'No list. The channel is public.';

  @override
  String get chsAudFriends => 'My friends';

  @override
  String get chsAudFriendsSub => 'One list, reused by every channel.';

  @override
  String get chsAudPrivate => 'Private';

  @override
  String get chsAudPrivateSub =>
      'A list just for this channel. People can ask to be let in.';

  @override
  String get chsFilterNone => 'No filter';

  @override
  String get chsFilterNoneSub => 'Anyone at all, not even signed in.';

  @override
  String get chsFilterSigned => 'Signed readers and wallets';

  @override
  String get chsFilterSignedSub =>
      'Includes wallets you added by hand, with no PublicOS account.';

  @override
  String get chsFilterStanding => 'All PublicOS Accounts';

  @override
  String get chsFilterStandingSub =>
      'Citizens, and privates with an active domain.';

  @override
  String get chsFilterStandingDefaultSub => 'Default.';

  @override
  String get chsFilterCitizen => 'Citizens';

  @override
  String get chsFilterCitizenSub => 'Only vouched citizens.';

  @override
  String get chsFilterNoteNone => 'No filter is applied.';

  @override
  String get chsFilterNoteListed =>
      'A list needs to know who you are, so the loosest filter here is Signed readers and wallets.';

  @override
  String get chsPostOwner => 'Only me';

  @override
  String get chsPostOwnerSub => 'Nobody else can submit posts.';

  @override
  String get chsPostOpen => 'Everyone who can read it';

  @override
  String get chsPostOpenSub => 'Open submissions.';

  @override
  String get chsPostApproved => 'Only people I approve';

  @override
  String get chsPostApprovedSub => 'A list just for posting.';

  @override
  String get chsPostFilterGrp =>
      'This filter binds accounts. A wallet you added to the posting list skips it — your hand is what vouches for a nameless key.';

  @override
  String get chsPostDailyLimit => 'Daily limit per person';

  @override
  String get chsPostDailyLimitSub => '0 = no limit';

  @override
  String get chsTalkAll => 'Anyone';

  @override
  String get chsTalkAllSub => 'Everyone who can read the channel.';

  @override
  String get chsTalkFriends => 'My friends';

  @override
  String get chsTalkFriendsSub =>
      'Just the switch — manage the list under Who can read it.';

  @override
  String get chsTalkCustom => 'Custom';

  @override
  String get chsTalkCustomSub => 'Your commenters list.';

  @override
  String get chsTalkFilterGrp =>
      'This filter binds accounts. A wallet on one of your lists skips it — your hand is what vouches for a nameless key.';

  @override
  String get chsTalkSplit => 'Set reactions separately';

  @override
  String get chsTalkSplitSub =>
      'Rarely needed — reactions follow comments by default.';

  @override
  String get chsTalkModeGated => 'Your readers. Ticked people can comment.';

  @override
  String get chsTalkModePublic =>
      'Empty until you add someone. Search a name, or paste any wallet address.';

  @override
  String get chsTalkSearchGated => 'Search your readers…';

  @override
  String get chsSearchHint => 'Name, or any 0x address…';

  @override
  String get chsListEmpty => 'Nobody yet';

  @override
  String get chsBlockedEmpty => 'Nobody is blocked';

  @override
  String get chsVisShowNewest => 'Show the newest';

  @override
  String get chsVisHideOlder => 'Hide posts older than';

  @override
  String chsVisPosts(int count) {
    return '$count posts';
  }

  @override
  String chsVisDays(int count) {
    return '$count days';
  }

  @override
  String get chsVisAll => 'Everything';

  @override
  String get chsVisOff => 'Off';

  @override
  String chsVisNewest(int count) {
    return 'Newest $count';
  }

  @override
  String chsVisVerdict(int total, int shown, int rest) {
    return 'This channel has $total posts. The newest $shown are served; the other $rest stay stored and are simply not handed out.';
  }

  @override
  String get chsMonPlans => 'Payment plans';

  @override
  String get chsMonPlansNone => 'None yet — free to read';

  @override
  String chsMonPlansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plans',
      one: '1 plan',
    );
    return '$_temp0';
  }

  @override
  String get chsMonVerdictFree =>
      'Free to read. There is nothing to switch on here — a channel is paid because plans exist, not because of a toggle.';

  @override
  String get chsMonVerdictPaid =>
      'Paid. A reader must clear the read gate and have paid one of the plans.';

  @override
  String get chsH1Anyone => 'Anyone';

  @override
  String get chsH1Signed => 'Anyone signed in';

  @override
  String get chsH1Standing => 'All PublicOS accounts';

  @override
  String get chsH1Citizen => 'Only citizens';

  @override
  String get chsH1ListedSignedBoth => 'Friends + approved';

  @override
  String get chsH1ListedSignedFriends => 'Friends';

  @override
  String get chsH1ListedSignedOwn => 'Approved';

  @override
  String get chsH1ListedCitizenBoth =>
      'Citizens on your lists, and approved wallets';

  @override
  String get chsH1ListedCitizenFriends =>
      'Only citizen friends and approved wallets';

  @override
  String get chsH1ListedCitizenOwn => 'Only approved citizens and wallets';

  @override
  String get chsH1ListedStandingBoth =>
      'PublicOS accounts on your lists, and approved wallets';

  @override
  String get chsH1ListedStandingFriends =>
      'Friends with PublicOS accounts, and approved wallets';

  @override
  String get chsH1ListedStandingOwn => 'Approved PublicOS accounts and wallets';

  @override
  String get chsH2Owner => 'Only me';

  @override
  String get chsH2OpenCitizen => 'Only citizen readers';

  @override
  String get chsH2OpenStanding => 'Readers with PublicOS accounts';

  @override
  String get chsH2ApprovedCitizen => 'Only approved citizens and wallets';

  @override
  String get chsH2ApprovedStanding => 'Approved PublicOS accounts and wallets';

  @override
  String get chsH3CustomCitizen => 'Custom list of citizens and wallets';

  @override
  String get chsH3CustomStanding =>
      'Custom list of PublicOS accounts and wallets';

  @override
  String get chsH3FriendsCitizen => 'Only citizen friends and wallets';

  @override
  String get chsH3FriendsStanding =>
      'Friends with PublicOS accounts and wallets';

  @override
  String get chsH3ReactionsDiffer => 'reactions differ';

  @override
  String get chsH4Nobody => 'Nobody';

  @override
  String chsH4Count(int count) {
    return '$count blocked';
  }

  @override
  String get chsH6Free => 'Free';

  @override
  String get chsH6Paid => 'Paid';

  @override
  String get chsFieldName => 'Name';

  @override
  String get chsFieldDescription => 'Description';

  @override
  String get chsDescriptionHint => 'Add a description…';

  @override
  String get chsFieldAddress => 'Address';

  @override
  String get chsFieldLanguage => 'Language';

  @override
  String get chsFieldSecret => 'Secret';

  @override
  String get chsFieldServer => 'Server';

  @override
  String get chsServerLocked => '· locked after creation';

  @override
  String get chsIconTitle => 'Icon URL';

  @override
  String get chsAddressTitle => 'Channel address';

  @override
  String get chsFailAdd => 'Could not add to the list';

  @override
  String get chsFailRemove => 'Could not remove from the list';

  @override
  String get chsReqPasses => 'passes';

  @override
  String get chsReqBlocked => 'blocked by filter';

  @override
  String get chsReqUnknown => 'unknown';

  @override
  String get onbProvBodyCitizen =>
      'A **BSP** connects you to the network. An **SSP** holds your posts and the feeds you read. As a citizen the network covers both for you.';

  @override
  String get onbProvBodyPrivate =>
      'A **BSP** connects you to the network. An **SSP** holds your posts and the feeds you read. You pay for these as you use them, from a service balance you top up.';

  @override
  String get onbProvBodyUnknown =>
      'A **BSP** connects you to the network. An **SSP** holds your posts and the feeds you read.';

  @override
  String get onbProvBspTitle => 'BSP · network access';

  @override
  String get onbProvSspTitle => 'SSP · your feeds';

  @override
  String get onbProvAuto => 'SET THIS UP FOR ME';

  @override
  String get onbProvAutoBsp => 'SET UP MY BSP';

  @override
  String get onbProvAutoSsp => 'SET UP MY SSP';

  @override
  String get onbProvChooseBsp => 'CHOOSE BSP';

  @override
  String get onbProvChooseSsp => 'CHOOSE SSP';

  @override
  String get onbProvWorking => 'SETTING THIS UP…';

  @override
  String get onbProvSetUpFirst => 'SET THESE UP FIRST';

  @override
  String get onbProvNone => 'not connected';

  @override
  String get onbProvUnknownRow => 'could not check right now';

  @override
  String get onbProvRenewsItself => 'covered while you use it';

  @override
  String get onbProvStateNone => 'NONE';

  @override
  String get onbProvStatePaired => 'PAIRED';

  @override
  String get onbProvStateFailed => 'FAILED';

  @override
  String get onbProvStateWorking => '…';

  @override
  String get onbProvCostLabel => 'What this cost you';

  @override
  String get onbProvFreeWhy =>
      'The network pays your providers for you. **Nothing left your wallet**, and both stay covered while you use the app.';

  @override
  String get onbProvPaidWhy =>
      'Both draw on one **service balance**, by the second, only while a provider has enough subscribers to be paid. Top it up in **Services** before it runs out, and take back what is left whenever you like. **Nothing refills it on its own.**';

  @override
  String get onbProvAlreadyLabel => 'Nothing to do here';

  @override
  String get onbProvAlreadyWhy =>
      'You already have both. Changing provider lives in **Services**, switch any time; the old one is paid to the second.';

  @override
  String get onbProvUnknownLabel => 'Why the one-tap option is hidden';

  @override
  String get onbProvUnknownWhy =>
      'Setting this up for you needs to know whether you are a citizen, the two paths are different, so **it does not guess**. Choosing yourself still works.';

  @override
  String get onbProvFailLabel => 'Why it stopped';

  @override
  String get onbProvTreasuryHint =>
      'You can set these up any time in **Services**';

  @override
  String get onbProvDepositLabel => 'About to deposit';

  @override
  String get onbProvDepositGo => 'DEPOSIT';

  @override
  String get onbProvSkip => 'SKIP';

  @override
  String get onbProvSkipTitle => 'Skip for now?';

  @override
  String onbProvPaidTo(String date) {
    return 'covered to $date';
  }

  @override
  String onbProvLapsed(String provider) {
    return '$provider · ran out';
  }

  @override
  String onbProvFailGeneric(String service) {
    return 'We could not set up your $service. It may have been the connection, nothing was charged.';
  }

  @override
  String onbProvFailNoProvider(String service) {
    return 'We could not find a provider for your $service right now.';
  }

  @override
  String onbProvSkipBody(String missing) {
    return 'You are missing **$missing**. Without them you will not get the full experience, you can set both up later in Services.';
  }

  @override
  String onbProvDepositWhy(String balance) {
    return 'Moved from your **MainSafe** into your service balance now, one month at today\'s fee, yours to withdraw while unspent. Your balance is $balance.';
  }

  @override
  String onbProvFailFunds(String service, String cost) {
    return 'We could not set up your $service. It costs $cost a month and your MainSafe does not have it.';
  }

  @override
  String get keychainOfferRegPublishing => 'Publishing…';

  @override
  String get statusBarNoKey => 'no key';

  @override
  String get statusBarInboxUnregistered => 'unregistered';

  @override
  String statusBarInboxRegisteredAs(String name) {
    return 'Registered as $name';
  }

  @override
  String get desktopStatusBarTopTitle => 'Status bar at top';

  @override
  String get desktopStatusBarTopSubtitle =>
      'Dock the shell status bar above the panels';

  @override
  String get desktopAutoplayCardsTitle => 'Autoplay interactive cards';

  @override
  String get desktopAutoplayCardsSubtitle =>
      'Cards start running instead of waiting for a tap. Uses more memory.';

  @override
  String get desktopLogOut => 'LOG OUT';

  @override
  String get desktopPushSubtitle =>
      'Receive alerts when the app is closed (mobile)';

  @override
  String get desktopDemoDataTitle => 'Demo data';

  @override
  String get desktopContactSettings => 'Settings';

  @override
  String get desktopLayoutChip => 'Layout';

  @override
  String get desktopContactsSearchHint => 'Search PublicOS';

  @override
  String get desktopNoOrgsYet => 'No orgs yet';

  @override
  String get desktopOrgsEmptyHint =>
      'Organizations you interact with appear here.';

  @override
  String get desktopSelectContactTitle => 'Select a contact';

  @override
  String get desktopSelectContactHint =>
      'Pick someone on the left to see their profile.';

  @override
  String get desktopBootChainFailed => 'Failed to connect to chain';

  @override
  String get desktopRecoveryPhraseCopied => 'Recovery phrase copied';

  @override
  String get desktopReload => 'Reload';

  @override
  String desktopGrantRevoked(String origin) {
    return 'Disconnected $origin';
  }

  @override
  String get desktopSessionKeySubtitle => 'Your account session key';

  @override
  String get desktopSessionKeyWarning =>
      'Anyone with this key controls your account session. Never share it.';

  @override
  String get desktopNavBlurbMyAccount =>
      'Your profile, identity records, domains, keychain and recovery.';

  @override
  String get desktopNavBlurbContacts =>
      'The people you know, the trust tree, and per-contact settings.';

  @override
  String get desktopNavBlurbMessages =>
      'Encrypted XMTP conversations, groups, and message tools.';

  @override
  String get desktopNavBlurbFeeds =>
      'Communities, forums, and the posts you follow.';

  @override
  String get desktopNavBlurbWallets => 'Balances and token transfers.';

  @override
  String get desktopNavBlurbTreasury =>
      'Your economy share, subscriptions, and the network\'s nodes.';

  @override
  String get desktopNavBlurbBsp =>
      'Blockchain Service Providers — directory and management.';

  @override
  String get desktopNavBlurbSsp =>
      'Storage Service Providers — subscriptions and your server.';

  @override
  String get desktopNavBlurbNodes =>
      'Consensus nodes and validator registration.';

  @override
  String get desktopNavBlurbSettings =>
      'App preferences, notifications, and account session.';

  @override
  String get desktopNavBlurbOrgs =>
      'Organizations — profiles, membership, and governance.';

  @override
  String get desktopNavBlurbSocialGraph =>
      'The vouch graph — who vouched for whom, citizenship at a glance.';

  @override
  String get desktopNavBlurbAccount =>
      'Identity, vouch status, domain, sessions, and recovery contacts.';

  @override
  String get desktopRemoveFromHistory => 'Remove from history';

  @override
  String get desktopReloadProfile => 'Reload profile';

  @override
  String get desktopDoneEditing => 'Done editing';

  @override
  String get desktopEditProfile => 'Edit profile';

  @override
  String get desktopPageBackground => 'Page background';

  @override
  String get desktopProfileQr => 'Profile QR';

  @override
  String get desktopCopyProfileLink => 'Copy profile link';

  @override
  String get desktopFollowedManageLists => 'Followed — manage lists';

  @override
  String get desktopFollowAddToList => 'Follow — add to a list';

  @override
  String get desktopBookmarkedRemove => 'Bookmarked — remove';

  @override
  String get desktopBookmarkThisApp => 'Bookmark this app';

  @override
  String desktopTabTooltipChat(String label) {
    return '$label — chat';
  }

  @override
  String desktopTabTooltipChannel(String label) {
    return '$label — channel';
  }

  @override
  String desktopTabTooltipOpensExternal(String label) {
    return '$label — opens in your browser';
  }

  @override
  String desktopTabTooltipOpensExternalUrl(String label, String url) {
    return '$label — $url (opens in your browser)';
  }

  @override
  String desktopTabTooltipOpensExternalLinks(String label, int count) {
    return '$label — $count links (open in your browser)';
  }

  @override
  String get desktopEditBanner => 'Edit banner';

  @override
  String get desktopEditAvatar => 'Edit avatar';

  @override
  String get desktopMoreTabs => 'More tabs';

  @override
  String get desktopChatSettings => 'Chat settings';

  @override
  String get desktopChatSettingsHeader => 'CHAT SETTINGS';

  @override
  String get desktopBubbleColorSection => 'BUBBLE COLOR';

  @override
  String get desktopAutoLabel => 'Auto';

  @override
  String get desktopPreviewTheirMessages => 'This is how their messages look';

  @override
  String get desktopPreviewYourMessages => 'And this is how yours look';

  @override
  String get desktopChatAppearanceLocalNote =>
      'These changes are for you only — nobody else sees them.';

  @override
  String get desktopMessageChimeTitle => 'Message chime';

  @override
  String get desktopMessageChimeSubtitle => 'Bell on every incoming message';

  @override
  String get desktopChipMyMessages => 'My messages';

  @override
  String get desktopChipTheirMessages => 'Their messages';

  @override
  String get desktopFontSection => 'FONT';

  @override
  String get desktopWeightSection => 'WEIGHT';

  @override
  String get desktopFontWeightLight => 'Light';

  @override
  String get desktopFontWeightNormal => 'Normal';

  @override
  String get desktopFontWeightMedium => 'Medium';

  @override
  String get desktopFontWeightSemiBold => 'SemiBold';

  @override
  String get desktopFontWeightBold => 'Bold';

  @override
  String get desktopStatusBarKeychainTooltip => 'Keychain — signing keys';

  @override
  String desktopStatusBarUnreadChain(int count) {
    return '$count unread on-chain notifications';
  }

  @override
  String get desktopStatusBarChainNotifications => 'On-chain notifications';

  @override
  String get desktopStatusBarPublicNode => 'Public node';

  @override
  String get desktopStatusBarPublicServer => 'Public server';

  @override
  String get desktopStatusBarFeedServer => 'Feed server';

  @override
  String get desktopFollowTooltipManageLists => 'Manage which lists';

  @override
  String get desktopFollowTooltipFollow => 'Follow this account';

  @override
  String desktopFollowFailed(Object error) {
    return 'Follow failed: $error';
  }

  @override
  String get desktopSelectConversationTitle => 'Select a conversation';

  @override
  String get desktopSelectConversationHint =>
      'Pick a chat on the left — or start one from a profile.';

  @override
  String get desktopContactSettingsHeader => 'CONTACT SETTINGS';

  @override
  String get desktopContentWidthSection => 'CONTENT WIDTH';

  @override
  String get desktopContentWidthHint =>
      'Caps how wide each kind of tab spreads on a large window. Web tabs always fill.';

  @override
  String get desktopBrowserSettingsHeader => 'SETTINGS';

  @override
  String get desktopContentWidthProfile => 'Profile';

  @override
  String get desktopContentWidthChat => 'Chat';

  @override
  String get desktopContentWidthFeeds => 'Feeds';

  @override
  String get desktopContentWidthFeedsHint => 'Shared with the Feeds page.';

  @override
  String get desktopNoAccountLoaded => 'No account loaded';

  @override
  String get desktopAppLinkWebApp => 'Web app';

  @override
  String get desktopAppLinkAppStore => 'App Store';

  @override
  String get desktopAppLinkPlayStore => 'Play Store';

  @override
  String get paywallLockedWidgetBadge => 'PAID CHANNEL';

  @override
  String get paywallLockedWidgetBlurbSubscribe =>
      'Reading this channel takes a subscription. You pay from your account, and every device you sign in with can read it.';

  @override
  String paywallLockedWidgetBlurbRenew(String date) {
    return 'Your subscription ended on $date. Renew to keep reading.';
  }

  @override
  String get paywallLockedWidgetBlurbConfirming =>
      'Your payment is on its way. The channel unlocks as soon as it\'s confirmed — usually a few seconds.';

  @override
  String get paywallLockedWidgetNoPlan =>
      'This channel\'s plan isn\'t available right now.';

  @override
  String get paywallLockedWidgetSubscribe => 'Subscribe';

  @override
  String get paywallLockedWidgetRenew => 'Renew';

  @override
  String get paywallLockedWidgetRetry => 'Check again';

  @override
  String get tierLockedWidgetVerifiedOnlyBadge => 'CITIZENS ONLY';

  @override
  String get tierLockedWidgetVerifiedOnlyBlurb =>
      'The owner limited this channel to verified citizens. Get vouched in to read it.';

  @override
  String get tierLockedWidgetAccountOnlyBadge => 'ACCOUNTS ONLY';

  @override
  String get tierLockedWidgetAccountOnlyBlurb =>
      'This channel is for PublicOS accounts. Sign in with your account key to read it.';

  @override
  String get tierLockedWidgetStandingBadge => 'STANDING REQUIRED';

  @override
  String get tierLockedWidgetStandingBlurb =>
      'This channel is for citizens and accounts with a paid-up domain.';

  @override
  String get tierLockedWidgetRetry => 'Check again';

  @override
  String get subscribeSheetTitle => 'Subscribe';

  @override
  String get subscribeSheetTitleRenew => 'Renew subscription';

  @override
  String get subscribeSheetPayingFrom => 'PAYING FROM';

  @override
  String get subscribeSheetMainSafe => 'Main wallet';

  @override
  String get subscribeSheetNetwork => 'Network';

  @override
  String get subscribeSheetPrice => 'Price';

  @override
  String get subscribeSheetPeriods => 'PERIODS';

  @override
  String get subscribeSheetTotal => 'Total';

  @override
  String get subscribeSheetAccessUntil => 'Access until';

  @override
  String get subscribeSheetLapsedOn => 'Lapsed on';

  @override
  String subscribeSheetPeriodDays(int days) {
    return '$days days';
  }

  @override
  String subscribeSheetPeriodHours(int hours) {
    return '$hours hours';
  }

  @override
  String get subscribeSheetApproveNote =>
      'This takes two transactions from your wallet: first you approve the exact amount, then it\'s sent. One tap does both.';

  @override
  String subscribeSheetConfirmApproveAndSend(String amount) {
    return 'Approve and send $amount';
  }

  @override
  String subscribeSheetConfirmSend(String amount) {
    return 'Send $amount';
  }

  @override
  String subscribeSheetStepApproving(int n, int total) {
    return 'Approving… ($n of $total)';
  }

  @override
  String subscribeSheetStepSending(int n, int total) {
    return 'Sending… ($n of $total)';
  }

  @override
  String subscribeSheetNoSource(String chain) {
    return 'None of your wallets can pay on $chain.';
  }

  @override
  String subscribeSheetInsufficient(String symbol) {
    return 'Not enough $symbol in this wallet.';
  }

  @override
  String get subscribeSheetQuoteFailed =>
      'Couldn\'t fetch the plan\'s terms. Pull to retry.';

  @override
  String subscribeSheetDone(String date) {
    return 'Subscribed — access until $date';
  }

  @override
  String get subscribeSheetFailed => 'Payment failed';

  @override
  String get createRecordPageLabelWhenTapped => 'WHEN TAPPED';

  @override
  String get createRecordPageTapNothing => 'Nothing';

  @override
  String get createRecordPageTapLink => 'Link';

  @override
  String get createRecordPageTapTip => 'Tip';

  @override
  String get createRecordPageLabelTipPayTo => 'PAY TO';

  @override
  String get createRecordPageTipAddressHint => 'Or paste an address (0x…)';

  @override
  String get createRecordPageTipInvalidAddress => 'That isn\'t a valid address';

  @override
  String get createRecordPageLabelTipNetwork => 'NETWORK AND TOKEN';

  @override
  String get createRecordPageTipChecking => 'Checking the address…';

  @override
  String get createRecordPageTipCheckFailed =>
      'Couldn\'t check this address. Try again.';

  @override
  String get createRecordPageTipNoAmount =>
      'Visitors choose the amount. The card never suggests one.';

  @override
  String get tipCardSheetTitle => 'Send a tip';

  @override
  String tipCardOwnerMainSafe(String name) {
    return '$name\'s Main Safe';
  }

  @override
  String tipCardOwnerWallet(String name) {
    return '$name\'s wallet';
  }

  @override
  String tipCardOwnerUnknown(String name) {
    return 'An address set by $name';
  }

  @override
  String get tipCardBroken => 'This tip card can\'t be paid from this app';

  @override
  String get recordButtonMenuTip => 'Tip';

  @override
  String get recordButtonMenuOpenLink => 'Open link';

  @override
  String get recordButtonMenuSeeImage => 'See image';

  @override
  String get createRecordPageImageChange => 'Change';

  @override
  String get createRecordPageHeaderPostCard => 'PINNED POST';

  @override
  String get createRecordPagePostCardSizeLead =>
      'A post you pinned. It shows the post as it is now, so edits, comments and a removal all show up here. It always takes the full width and grows with the post; you choose its background.';

  @override
  String get createRecordPagePinPlacement => 'Where it goes';

  @override
  String get createRecordPagePinTop => 'Pin to top';

  @override
  String get createRecordPagePinBottom => 'Pin to bottom';

  @override
  String get createRecordPagePinAction => 'PIN TO PROFILE';

  @override
  String get postCardMenuPinToProfile => 'Pin to profile';

  @override
  String get postCardMenuGoToFeed => 'Go to feed';

  @override
  String get feedReaderPageFallbackTitle => 'Feed';

  @override
  String get postCardPinSaving => 'Pinning to your profile…';

  @override
  String get postCardPinDone => 'Pinned to your profile';

  @override
  String get postCardPinFailed => 'Could not pin the post';

  @override
  String get postCardPinnedGone => 'Could not find this post';

  @override
  String get postCardPinnedLocked => 'This post is private';

  @override
  String get postCardPinnedFailed => 'Could not load the post. Tap to retry';

  @override
  String get createRecordPagePostCardLink => 'POST LINK';

  @override
  String get createRecordPagePostCardLinkCopy => 'Copy link';

  @override
  String get createRecordPagePostCardLinkCopied => 'Link copied';

  @override
  String get createRecordPageBackgroundImage => 'Image';

  @override
  String get createRecordPagePostMedia => 'Post media as background';

  @override
  String get createRecordPagePostMediaHint =>
      'Shows the post\'s banner, image or video in front of the background.';

  @override
  String get netDepositMonths => 'Deposit (months)';

  @override
  String get netDeposit => 'Deposit';

  @override
  String get networkAccessSheetsTopUpHeader => 'TOP UP';

  @override
  String get networkAccessSheetsTopUpTitle => 'Top up your service balance';

  @override
  String get networkAccessSheetsTopUpBody =>
      'Moved from your wallet into the balance both your providers draw from. What they have not earned is yours to withdraw.';

  @override
  String get networkAccessSheetsMonthsOfCover => 'Months of cover';

  @override
  String get networkAccessSheetsRatePerMonth => 'Both services / month';

  @override
  String get networkAccessSheetsDepositing => 'DEPOSITING…';

  @override
  String get networkAccessSheetsDeposit => 'DEPOSIT';

  @override
  String get networkAccessSheetsWithdrawHeader => 'WITHDRAW';

  @override
  String get networkAccessSheetsWithdrawTitle => 'Take your balance back';

  @override
  String get networkAccessSheetsWithdrawBody =>
      'What your providers have accrued up to this second is paid first; the rest returns to your wallet.';

  @override
  String get networkAccessSheetsAvailable => 'Available';

  @override
  String get networkAccessSheetsAccrued => 'Accrued to providers';

  @override
  String get networkAccessSheetsAddedForYou => 'Added for you';

  @override
  String get networkAccessSheetsAddedForYouNote =>
      'Part of this balance was added for you by someone else. It pays your providers first and never returns to your wallet.';

  @override
  String get networkAccessSheetsWithdrawing => 'WITHDRAWING…';

  @override
  String get networkAccessSheetsWithdraw => 'WITHDRAW';

  @override
  String get networkAccessSheetsNothingToWithdraw => 'Nothing to withdraw.';

  @override
  String networkAccessSheetsLeaveHeader(Object provider) {
    return 'LEAVE $provider';
  }

  @override
  String networkAccessSheetsLeaveTitle(Object slug) {
    return 'Leave $slug';
  }

  @override
  String get networkAccessSheetsLeaveBody =>
      'Stops this service now. What accrued up to this second is paid; your balance stays yours.';

  @override
  String get networkAccessSheetsLeaving => 'LEAVING…';

  @override
  String get networkAccessSheetsLeave => 'LEAVE';

  @override
  String get treasuryPageSubInactive => 'INACTIVE';

  @override
  String get treasuryPageCoveredUntil => 'Covered until';

  @override
  String get treasuryPageCoveredWhileUsed => 'while you use the app';

  @override
  String treasuryPageSubActiveCitizenBody(Object provider) {
    return 'Active. The network mints your $provider\'s fee while you use the app. Switch any time.';
  }

  @override
  String get treasuryPageSubInactiveBody =>
      'Not served right now — the account went quiet too long, or the balance ran out. Open the app, top up, or subscribe again to resume.';

  @override
  String get treasuryPageServiceBalance => 'Service balance';

  @override
  String get treasuryPageServiceBalanceBlurb =>
      'One balance pays both your BSP and your SSP, by the second, only while a provider has enough subscribers to be paid. Top it up or take it back whenever you like.';

  @override
  String get treasuryPageBalance => 'Balance';

  @override
  String get treasuryPageAccrued => 'Accrued, unpaid';

  @override
  String get treasuryPageAddedForYou => 'Added for you';

  @override
  String treasuryPageAddedForYouNote(Object amount) {
    return '$amount OX of this was added for you and pays your providers; it can\'t be withdrawn.';
  }

  @override
  String get treasuryPageRunsOut => 'Runs out';

  @override
  String get treasuryPageNeverSubscribed =>
      'Nothing deposited yet — subscribe to a provider below.';

  @override
  String get treasuryPageTopUp => 'TOP UP';

  @override
  String get treasuryPageWithdraw => 'WITHDRAW';

  @override
  String treasuryPageLeaveProvider(Object provider) {
    return 'LEAVE $provider';
  }

  @override
  String get treasuryPageToppedUp => 'Service balance topped up';

  @override
  String get treasuryPageWithdrawn => 'Service balance withdrawn';

  @override
  String treasuryPageProviderLeft(Object provider) {
    return '$provider left';
  }

  @override
  String get treasuryPageResume => 'RESUME';

  @override
  String get treasuryPageResumed => 'Service resumed';

  @override
  String get accountCenterOrgsSection => 'Org membership';

  @override
  String get orgAddAnyoneTitle => 'Anyone can add me';

  @override
  String get orgAddAnyoneOnSub => 'Anyone can add you to an org.';

  @override
  String get orgAddAnyoneOffSub => 'Only the people on your list can add you.';

  @override
  String get orgAddListLabel => 'WHO CAN ADD ME';

  @override
  String get orgAddListEmpty => 'Empty';

  @override
  String get orgAddListOnHint => 'Your list counts when the switch is off.';

  @override
  String orgAddLeft(int count) {
    return '$count left';
  }

  @override
  String get orgAddAllowFriend => 'ALLOW A FRIEND TO ADD ME';

  @override
  String get orgAddSheetTitle => 'Allow a friend to add me';

  @override
  String get orgAddSheetHeading => 'Who can add you to orgs';

  @override
  String get orgAddSheetBody =>
      'Your friend can add you to 5 orgs, by creating one with you or by proposing you in one. After 5 they leave your list, and you can add them again.';

  @override
  String get orgAddRemoveTitle => 'Remove from your list?';

  @override
  String orgAddRemoveBody(String name) {
    return '$name won\'t be able to add you to orgs anymore.';
  }

  @override
  String get orgAddSaving => 'SAVING & CONFIRMING…';

  @override
  String get orgAddFailed => 'Could not save the change.';

  @override
  String get orgAddPillAnyone => 'Anyone';

  @override
  String orgAddPillFriends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friends',
      one: '1 friend',
    );
    return '$_temp0';
  }

  @override
  String get networkAccessSheetsAmount => 'Amount';

  @override
  String networkAccessSheetsCoversBoth(Object months) {
    return 'Covers about $months months of BSP and SSP at today\'s fees.';
  }

  @override
  String networkAccessSheetsCoversOne(Object months, Object provider) {
    return 'Covers about $months months of $provider at today\'s fees.';
  }

  @override
  String get networkAccessSheetsCoversNone =>
      'You are not subscribed to a provider yet; the deposit waits in your balance.';

  @override
  String get networkAccessSheetsGateNote =>
      'Your providers are still below their minimum subscribers, so nothing is drawn yet.';

  @override
  String get networkAccessSheetsMax => 'MAX';

  @override
  String get networkAccessSheetsAmountTooHigh =>
      'That is more than you can withdraw right now.';

  @override
  String get operatorAgreementSection => 'Operator agreement';

  @override
  String get operatorAgreementSignedPill => 'SIGNED';

  @override
  String get operatorAgreementUnsignedPill => 'NOT SIGNED';

  @override
  String get operatorAgreementSignedBody =>
      'You accepted the current operator agreement. You can register a provider.';

  @override
  String get providerRegistrationInviteOnly =>
      'Registering a provider is by invitation for now, and your account is not on the list yet.';

  @override
  String get operatorAgreementUnsignedBody =>
      'Running a BSP or SSP starts with the operator agreement. Read it and sign it to register a provider.';

  @override
  String get operatorAgreementSign => 'SIGN AGREEMENT';

  @override
  String get operatorAgreementTitle => 'Operator agreement';

  @override
  String get operatorAgreementLead =>
      'Read the operator agreement to the end. Signing it lets you register BSPs and SSPs; every registration checks it.';

  @override
  String operatorAgreementVersion(Object version) {
    return 'Operator agreement · version $version';
  }

  @override
  String get operatorAgreementScrollHint => 'Scroll to the end to sign';

  @override
  String get operatorAgreementAccept => 'ACCEPT AND SIGN';

  @override
  String get operatorAgreementSigning => 'SIGNING';

  @override
  String get operatorAgreementDoneTitle => 'Agreement signed';

  @override
  String get operatorAgreementDoneBody =>
      'You can now register a BSP or an SSP from this page.';

  @override
  String get operatorAgreementContinue => 'CONTINUE';

  @override
  String get operatorAgreementFailed => 'The signature did not go through.';

  @override
  String get operatorAgreementRetry => 'TRY AGAIN';

  @override
  String get operatorAgreementNeedsPermanentKey =>
      'Signing needs a permanent key. This session expires; open PublicOS with your main key and sign there.';

  @override
  String get operatorAgreementLoadFailed =>
      'The agreement could not be loaded. Check your connection and try again.';

  @override
  String get operatorAgreementNothingPublished =>
      'No operator agreement is published yet. Try again later.';

  @override
  String get groupVotingViewMaxOpen => 'Open votes at once';

  @override
  String get groupVotingViewMaxOpenSubtitle =>
      'How many proposals can run in parallel (1–5)';

  @override
  String get groupVotingViewWaitFull => 'Wait the full period';

  @override
  String get groupVotingViewWaitFullSubtitle =>
      'Passed votes run only after their period ends; any member runs them';

  @override
  String get groupVotingViewProposerCap => 'One open proposal per member';

  @override
  String get groupVotingViewProposerCapSubtitle =>
      'A member\'s proposal must pass before they start another';

  @override
  String get groupVotingViewOn => 'ON';

  @override
  String get groupVotingViewOff => 'OFF';

  @override
  String get groupVotingViewSettingVoteTitle => 'Start a vote';

  @override
  String groupVotingViewSettingVoteBody(Object setting, Object value) {
    return '$setting → $value. It changes once the vote passes, and only for new proposals.';
  }

  @override
  String get groupVotingViewStartVote => 'START VOTE';

  @override
  String get groupVotingViewSettingVoteStarted => 'Vote started';

  @override
  String get groupVotingViewExecute => 'EXECUTE NOW';

  @override
  String get groupVotingViewExecuted => 'Proposal ran';

  @override
  String get groupVotingViewExecuteFailed =>
      'The run failed; it stays open to try again';

  @override
  String get groupVotingViewWaitMode =>
      'Wait mode · runs after the voting period';

  @override
  String get groupVotingViewWaitingToRun =>
      'Passed · runs after the voting period';

  @override
  String get groupVotingViewReadyToRun => 'Passed · ready to run';

  @override
  String get groupVotingViewRunFailed =>
      'Passed · the last run failed, run it again';

  @override
  String get groupVotingViewPayment => 'PAYMENT';

  @override
  String groupVotingViewPayTo(Object amount) {
    return 'Pay $amount to';
  }

  @override
  String get groupVotingViewFromOrgSafe => 'from the group\'s Safe';

  @override
  String groupVotingViewOpenPill(int count) {
    return '$count OPEN';
  }

  @override
  String get groupVotingViewSplitterActivate => 'Activate split';

  @override
  String get groupVotingViewSplit => 'Split';

  @override
  String get groupVotingViewSplitterActivateTitle => 'Activate splitting?';

  @override
  String get groupVotingViewSplitterActivateBody =>
      'Starts a vote. Once it passes, this group can split OX from its Safe equally among its members, one vote per split. You only do this once.';

  @override
  String get groupVotingViewSplitTitle => 'Split OX';

  @override
  String groupVotingViewSplitBody(int count, Object balance) {
    return 'Starts a vote to split an amount equally among the $count members. The group has $balance OX.';
  }

  @override
  String get groupVotingViewSplitAmountHint => 'Amount';

  @override
  String groupVotingViewSplitEach(Object share) {
    return 'Each member gets $share OX';
  }

  @override
  String get groupVotingViewSplitTooMuch => 'That\'s more than the group has';

  @override
  String get groupVotingViewSplitLabel => 'SPLIT';

  @override
  String get groupVotingViewSplitterActivateVote =>
      'Activate splitting OX among the members';

  @override
  String groupVotingViewSplitVote(Object amount, int count) {
    return 'Split $amount among $count members';
  }

  @override
  String groupVotingViewProposedBy(Object name) {
    return 'proposed by $name';
  }

  @override
  String groupVotingViewSafeShort(Object balance) {
    return 'The Safe holds $balance. If this passes, the payment will fail.';
  }

  @override
  String groupVotingViewRunCall(Object method, Object address) {
    return 'Run $method on $address';
  }

  @override
  String groupVotingViewProviderRegRestricted(Object registry) {
    return '$registry registration: invite-only';
  }

  @override
  String groupVotingViewProviderRegOpen(Object registry) {
    return '$registry registration: open to everyone';
  }

  @override
  String groupVotingViewProviderRegAllow(Object registry) {
    return '$registry registration list: add';
  }

  @override
  String groupVotingViewProviderRegDisallow(Object registry) {
    return '$registry registration list: remove';
  }

  @override
  String get groupVotingViewNativeUnit => 'native coin';

  @override
  String groupVotingViewNeedsMore(Object count, Object floor) {
    return 'Needs $count more For or Abstain to reach the quorum of $floor';
  }

  @override
  String get groupVotingViewForMustLead =>
      'Quorum reached, but For must outnumber Against to pass';

  @override
  String get groupVotingViewTechDetails => 'Technical details';

  @override
  String get groupVotingViewTechTarget => 'Target';

  @override
  String get groupVotingViewTechValue => 'Value';

  @override
  String get groupVotingViewTechMethod => 'Method';

  @override
  String get groupVotingViewTechData => 'Data';

  @override
  String get groupVotingViewDescAdd => 'Add';

  @override
  String get groupVotingViewDescRemove => 'Remove';

  @override
  String get groupVotingViewDescSuspend => 'Suspend';

  @override
  String get groupVotingViewDescUnsuspend => 'Lift the suspension of';

  @override
  String get groupVotingViewDescClearVouches => 'Clear the vouches of';

  @override
  String get groupVotingViewDescRequestParent => 'Join as a child of';

  @override
  String get groupVotingViewDescCancelParent => 'Withdraw the request to';

  @override
  String get groupVotingViewDescAcceptChild => 'Accept as a child';

  @override
  String get groupVotingViewDescReleaseChild => 'Release the child';

  @override
  String get groupVotingViewDescChildLock => 'Child lock';

  @override
  String get groupVotingViewDescAddCard => 'Add a card';

  @override
  String get groupVotingViewDescUpdateCard => 'Update a card';

  @override
  String get groupVotingViewDescDeleteCard => 'Delete a card';

  @override
  String groupVotingViewDescSetSocial(Object name) {
    return 'Set $name';
  }

  @override
  String groupVotingViewDescRemoveSocial(Object name) {
    return 'Remove $name';
  }

  @override
  String groupVotingViewDescAddTab(Object name) {
    return 'Add the tab “$name”';
  }

  @override
  String groupVotingViewDescUpdateTab(Object name) {
    return 'Update the tab “$name”';
  }

  @override
  String groupVotingViewDescRemoveTab(Object name) {
    return 'Remove the tab “$name”';
  }

  @override
  String get groupVotingViewDescChangeBio => 'Change the bio';

  @override
  String get groupVotingViewDescChangeAvatar => 'Change the profile picture';

  @override
  String get groupVotingViewDescChangeBanner => 'Change the banner';

  @override
  String get groupVotingViewDescChangeBackground => 'Change the background';

  @override
  String get groupVotingViewDescChangeColor => 'Change the profile color';

  @override
  String groupVotingViewDescSetRecord(Object name) {
    return 'Set “$name”';
  }

  @override
  String groupVotingViewDescDeleteRecord(Object name) {
    return 'Delete “$name”';
  }

  @override
  String get groupVotingViewDescNone => 'none';

  @override
  String groupVotingViewDescBatch(Object count) {
    return 'Update $count records';
  }

  @override
  String groupVotingViewDescDeleteBatch(Object count) {
    return 'Delete $count records';
  }

  @override
  String groupVotingViewDescAddWallet(Object label) {
    return 'Add the wallet “$label”';
  }

  @override
  String get groupVotingViewDescRemoveWallet => 'Remove a wallet';

  @override
  String groupVotingViewDescAddInbox(Object label) {
    return 'Add the chat inbox “$label”';
  }

  @override
  String get groupVotingViewDescRemoveInbox => 'Remove a chat inbox';

  @override
  String groupVotingViewDescRegisterApp(Object slug) {
    return 'Register the app $slug';
  }

  @override
  String groupVotingViewDescRemoveApp(Object slug) {
    return 'Remove the app $slug';
  }

  @override
  String groupVotingViewDescRenameApp(Object slug) {
    return 'Rename the app $slug';
  }

  @override
  String groupVotingViewDescSetAppPointer(Object slug, Object pointer) {
    return 'Set $pointer of $slug';
  }

  @override
  String groupVotingViewDescRemoveAppPointer(Object slug, Object pointer) {
    return 'Remove $pointer of $slug';
  }

  @override
  String groupVotingViewDescSetValue(Object name, Object value) {
    return 'Set $name: “$value”';
  }

  @override
  String groupVotingViewDescWas(Object value) {
    return 'was “$value”';
  }

  @override
  String get groupVotingViewDescBio => 'bio';

  @override
  String get groupVotingViewDescColor => 'profile color';

  @override
  String get groupVotingViewOutcomeExecuted => 'PASSED · EXECUTED';

  @override
  String get groupVotingViewOutcomeDefeated => 'DEFEATED';

  @override
  String get groupVotingViewOutcomeExpired => 'EXPIRED';

  @override
  String get groupVotingViewOutcomeRunFailed => 'PASSED · RUN FAILED';

  @override
  String get groupVotingViewOutcomeCancelled => 'CANCELLED';

  @override
  String get groupVotingViewRecent => 'LAST 24 HOURS';

  @override
  String get groupVotingViewSending => 'Sending to the chain…';

  @override
  String get keyLifetimeTitle => 'KEY LIFETIME';

  @override
  String get keyLifetime24h => '24 hours';

  @override
  String get keyLifetimeWeek => '1 week';

  @override
  String get keyLifetimeMonth => '1 month';

  @override
  String get keyLifetimePermanent => 'Permanent';

  @override
  String get keyLifetimePermanentHint =>
      'A permanent key can do everything, including recovery and citizenship.';

  @override
  String get keyLifetimeExpiringHint =>
      'An expiring key stops working on its own. It can\'t add keys, change recovery or claim citizenship.';

  @override
  String keyLifetimeExpiresIn(Object time) {
    return 'expires in $time';
  }

  @override
  String get keyLifetimeExpired => 'key expired';

  @override
  String get addSessionDialogLifetimePermanent => 'This key will be permanent.';

  @override
  String addSessionDialogLifetimeExpiring(Object lifetime) {
    return 'This key expires $lifetime after you approve it.';
  }

  @override
  String get addSessionDialogRecoveryNeedsPermanent =>
      'Recovery always installs a permanent key. Ask them to make a new code with the Permanent lifetime.';

  @override
  String get keyLifetimePermanentKey => 'permanent key';

  @override
  String get addSessionDialogNewSessionLabel => 'NEW SESSION';

  @override
  String get childrenSheetLockTitle => 'Lock this child?';

  @override
  String get childrenSheetUnlockTitle => 'Unlock this child?';

  @override
  String childrenSheetLockBody(Object name) {
    return 'Start a vote so $name can\'t take new child groups. The ones it has stay.';
  }

  @override
  String childrenSheetUnlockBody(Object name) {
    return 'Start a vote so $name can take new child groups again.';
  }

  @override
  String get childrenSheetLocked => 'Locked: takes no new children';

  @override
  String get groupVotingViewDescLockChild => 'Stop new children under';

  @override
  String get groupVotingViewDescUnlockChild => 'Allow new children under';

  @override
  String get accountCenterClearRecordsSection => 'Delete all records';

  @override
  String get accountCenterClearRecordsBody =>
      'Erase everything on your profile: picture, banner, background, bio, social links, cards and tabs. Your account, name, citizenship and money stay.';

  @override
  String get accountCenterClearRecordsButton => 'DELETE ALL RECORDS';

  @override
  String get clearRecordsDlg1Title => 'Delete every record?';

  @override
  String get clearRecordsDlg1Lead => 'This erases, in one go:';

  @override
  String get clearRecordsCostIdentity =>
      'Your profile picture, banner, background and colour';

  @override
  String get clearRecordsCostBio => 'Your bio and status';

  @override
  String get clearRecordsCostLinks => 'Every social link';

  @override
  String get clearRecordsCostCards => 'Every card, pinned post and tab';

  @override
  String get clearRecordsCostForever =>
      'It can\'t be undone: the records are erased on chain, not hidden';

  @override
  String get clearRecordsDlg1Stays =>
      'Your account, name, citizenship, money, keys and messages stay.';

  @override
  String get clearRecordsDlg1Confirm => 'DELETE';

  @override
  String clearRecordsWait(Object seconds) {
    return 'DELETE · $seconds';
  }

  @override
  String get clearRecordsKeep => 'KEEP MY PROFILE';

  @override
  String get clearRecordsDlg2Title => 'Last step';

  @override
  String get clearRecordsDlg2Body =>
      'Your profile will be empty. Anything you want back has to be added again.';

  @override
  String get clearRecordsDlg2Confirm => 'DELETE EVERYTHING NOW';

  @override
  String clearRecordsWorking(Object removed, Object left) {
    return 'Deleting records… $removed removed, $left left';
  }

  @override
  String clearRecordsDone(Object count) {
    return '$count records deleted';
  }

  @override
  String get clearRecordsFailed => 'Couldn\'t delete the records';

  @override
  String get startNewVoteSheetWalletTypeLabel => 'WALLET TYPE';

  @override
  String get startNewVoteSheetWalletTypeKey => 'Key account';

  @override
  String get startNewVoteSheetWalletTypeSafe => 'Safe on PublicOS';

  @override
  String get startNewVoteSheetWalletTypeHint =>
      'A key account works on every chain. A Safe is a smart wallet on the PublicOS chain.';

  @override
  String get accountCenterPenaltiesSection => 'Penalties';

  @override
  String penaltiesOwedPill(Object amount) {
    return '$amount OX owed';
  }

  @override
  String get penaltiesBody =>
      'A penalty is a debt the court puts on an account, with a reason and a deadline. While anything is owed, BSP and SSP subscriptions are blocked. Anything you claim pays it first.';

  @override
  String get penaltiesNothingOwed => 'Nothing owed.';

  @override
  String get penaltiesOpenLabel => 'OPEN';

  @override
  String get penaltiesHistoryLabel => 'HISTORY';

  @override
  String penaltyPaidOf(Object paid, Object amount) {
    return '$paid of $amount OX paid';
  }

  @override
  String penaltyPayBy(Object date) {
    return 'Pay by $date';
  }

  @override
  String penaltyOverdueSince(Object date) {
    return 'Overdue since $date';
  }

  @override
  String get penaltyStatusPaid => 'Paid';

  @override
  String get penaltyStatusCancelled => 'Cancelled';

  @override
  String get penaltyStatusPromoted => 'Sent to suspension';

  @override
  String get penaltiesOverdueWarning =>
      'A penalty unpaid past its deadline can be sent by anyone to a 10-day suspension notice.';

  @override
  String get penaltiesPayButton => 'PAY PENALTIES';

  @override
  String get penaltiesPaid => 'Penalties paid.';

  @override
  String get penaltiesPayFailed => 'Payment failed.';

  @override
  String standingOwedAlert(Object amount) {
    return 'You owe $amount OX in penalties. BSP and SSP subscriptions are blocked until it is paid.';
  }

  @override
  String get standingBlacklistedAlert =>
      'Your account is on the court\'s blacklist. BSP and SSP subscriptions are blocked.';

  @override
  String standingNoticeAlert(Object date) {
    return 'Your account will be suspended on $date. It keeps working until then; you can move your funds out.';
  }

  @override
  String standingSuspendedAlert(Object date) {
    return 'Your account has been suspended since $date.';
  }

  @override
  String get payPenaltiesHeader => 'PAY PENALTIES';

  @override
  String get payPenaltiesTitle => 'Pay what you owe';

  @override
  String get payPenaltiesBody =>
      'Paid from your main wallet and burned. The oldest penalty is paid first, and you can pay part of it.';

  @override
  String get payPenaltiesOwed => 'Owed';

  @override
  String get payPenaltiesAll => 'ALL';

  @override
  String get payPenaltiesPay => 'PAY';

  @override
  String get payPenaltiesPaying => 'PAYING…';

  @override
  String get payPenaltiesAboveOwed => 'Only what is owed is taken.';

  @override
  String get treasuryPageServicesBlocked =>
      'Subscriptions are blocked: you owe penalties or your account is on the court\'s blacklist. See Account › Penalties.';

  @override
  String get flagAction => 'Flag';

  @override
  String get flagSheetTitlePost => 'Flag this post';

  @override
  String get flagSheetTitleComment => 'Flag this comment';

  @override
  String get flagSheetTitleChannel => 'Flag this channel';

  @override
  String get flagSheetTitleProfile => 'Flag this profile';

  @override
  String get flagSheetLead =>
      'Pick the rule it breaks. Your flag is public on the chain and the owner can see it. You can have one open flag on each thing.';

  @override
  String get flagCategory0 => 'Spam';

  @override
  String get flagCategory1 => 'Scam or fraud';

  @override
  String get flagCategory2 => 'Impersonation';

  @override
  String get flagCategory3 => 'Harassment';

  @override
  String get flagCategory4 => 'Hate speech';

  @override
  String get flagCategory5 => 'Violence or threats';

  @override
  String get flagCategory6 => 'Terrorism or extremism';

  @override
  String get flagCategory7 => 'Self-harm';

  @override
  String get flagCategory8 => 'Sexual content without an adult label';

  @override
  String get flagCategory9 => 'Election or civic misinformation';

  @override
  String get flagCategory10 => 'Copyright or trademark';

  @override
  String get flagCategory11 => 'Something else';

  @override
  String flagCategoryUnknown(Object id) {
    return 'Rule $id';
  }

  @override
  String get flagPrivateHeader => 'PRIVATE REPORTS';

  @override
  String get flagPrivacy => 'My privacy or personal data';

  @override
  String get flagIntimate => 'Intimate images shared without consent';

  @override
  String get flagChildSafety => 'Child safety';

  @override
  String get flagPrivateBody =>
      'These are never public flags. They go privately to the server\'s operator as a notice, and notices are not open yet.';

  @override
  String get flagNoteHint => 'Add a note (optional)';

  @override
  String get flagSubmit => 'FLAG';

  @override
  String get flagSending => 'FLAGGING…';

  @override
  String get flagFailed => 'The flag didn\'t go through.';

  @override
  String get flagDone => 'Flagged. The owner and the server can see it.';

  @override
  String get flagAlreadyTitle => 'You flagged this';

  @override
  String flagFiledOn(Object category, Object date) {
    return '$category · $date';
  }

  @override
  String flagStatusOpenUntil(Object date) {
    return 'Open until $date';
  }

  @override
  String get flagStatusExpired => 'Expired';

  @override
  String get flagStatusWithdrawn => 'Withdrawn';

  @override
  String get flagStatusRemoved => 'Removed by the court';

  @override
  String get flagStatusCleared => 'Cleared by the court';

  @override
  String get flagWithdraw => 'WITHDRAW FLAG';

  @override
  String get flagWithdrawing => 'WITHDRAWING…';

  @override
  String flagWithdrawNote(Object date) {
    return 'Once withdrawn, you can flag this again from $date.';
  }

  @override
  String flagAgainOn(Object date) {
    return 'You can flag this again on $date.';
  }

  @override
  String get flagWithdrawn => 'Flag withdrawn.';

  @override
  String get flagKindPost => 'Post';

  @override
  String get flagKindComment => 'Comment';

  @override
  String get flagKindChannel => 'Channel';

  @override
  String get flagKindProfile => 'Profile';

  @override
  String get accountCenterFlagsSection => 'Flags';

  @override
  String get flagsMineLabel => 'MY FLAGS';

  @override
  String get flagsOnMeLabel => 'ON MY CONTENT';

  @override
  String get flagsOnMeBody => 'Only you and the server hosting it see these.';

  @override
  String get flagsNoneMine => 'You haven\'t flagged anything.';

  @override
  String get flagsNoneOnMe => 'Nothing of yours has been flagged.';

  @override
  String flagsPillOpen(Object count) {
    return '$count open';
  }

  @override
  String get feedsNavigationDrawerExplore => 'Explore';

  @override
  String get feedsViewExplore => 'Explore';

  @override
  String get exploreWindowNow => '10 min';

  @override
  String get exploreWindowHour => 'Hour';

  @override
  String get exploreWindow12h => '12 h';

  @override
  String get exploreWindow24h => '24 h';

  @override
  String get exploreTabPosts => 'Posts';

  @override
  String get exploreTabFeeds => 'Feeds';

  @override
  String exploreReaders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count readers',
      one: '1 reader',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyTitle => 'Nothing trending yet';

  @override
  String get exploreEmptySubtitle =>
      'Every 10 minutes the servers on the network agree on what is being read most. Pull down to check again.';

  @override
  String get matureGateTitle => 'Mature content';

  @override
  String get matureGateBody =>
      'This profile contains mature content. Are you 18 or older and want to go on?';

  @override
  String get matureGateContinue => 'I\'m 18+, go on';

  @override
  String get matureGateBack => 'Go back';

  @override
  String get accountTagsSection => 'Account tags';

  @override
  String get accountTagMature => 'Mature content';

  @override
  String get accountTagMatureSub =>
      'People confirm they are 18+ before they see your profile.';

  @override
  String get accountTagAutomated => 'Automated account';

  @override
  String get accountTagAutomatedSub =>
      'Software runs this account, not a person. A robot shows on your avatar.';

  @override
  String get accountTagSaving => 'Saving tag…';

  @override
  String get errAccountTagFailed => 'Couldn\'t save the tag.';

  @override
  String get settingsMatureProfilesTitle => 'Mature profiles';

  @override
  String get settingsMatureProfilesEmpty =>
      'Profiles you said yes to (18+) show here. Remove one and it asks again next time.';

  @override
  String get settingsMatureProfilesRemove => 'Ask again for this profile';

  @override
  String get linkTargetNotFound => 'Link target not found';

  @override
  String get postSigMarkUnsigned => 'Not signed';

  @override
  String get postSigMarkBad => 'Bad signature';

  @override
  String get postSigMarkUnchecked => 'Signature not checked';

  @override
  String get postSigTitleChecked => 'SIGNED';

  @override
  String get postSigTitleUnsigned => 'NOT SIGNED';

  @override
  String get postSigTitleBad => 'BAD SIGNATURE';

  @override
  String get postSigTitleUnchecked => 'NOT CHECKED';

  @override
  String get postSigThisPost => '(this post)';

  @override
  String get postSigExplainChecked =>
      'Signed. The author signed the text and media with their key, and this device checked that nothing changed since.';

  @override
  String get postSigExplainUnsigned =>
      'Not signed. The author chose not to sign, so only the server vouches for who wrote it and what it said.';

  @override
  String get postSigExplainBad =>
      'Bad signature. The signature does not match the content or the signer. The post may have been altered after signing.';

  @override
  String get postSigExplainUnchecked =>
      'Not checked. The signature matches the content on this device, but the chain could not be reached to confirm whose key signed it. Try again later.';

  @override
  String get postSigEncourage =>
      'Signed posts are the norm here: sign yours so readers can check them anywhere.';

  @override
  String get postSigDialogClose => 'Got it';

  @override
  String get postSrvMark => 'Served from outside the PublicOS network';

  @override
  String get postSrvTitle => 'FROM THE OPEN INTERNET';

  @override
  String get postSrvExplainServer =>
      'This post comes from a server that follows the PublicOS feed protocol on its own, out on the open internet. It is not a registered provider within the PublicOS network, so it cannot send you notifications.';

  @override
  String get postSrvExplainUnsigned =>
      'Not signed: the author is a simple user, not a PublicOS account.';

  @override
  String get newKeyFlowAddDevice => 'ADD THIS DEVICE';

  @override
  String get newKeyFlowNewAccount => 'NEW ACCOUNT';

  @override
  String get newKeyFlowAddDeviceTitle => 'Add this device';

  @override
  String get newKeyFlowAddDeviceSubtitle =>
      'Which account should this device join? Type its name or its account address.';

  @override
  String get newKeyFlowAccountLabel => 'Account name or address';

  @override
  String get newKeyFlowAccountNotFound => 'No account found with that name.';

  @override
  String get newKeyFlowIsThisYou => 'Is this your account?';

  @override
  String get newKeyFlowNewAccountTitle => 'New account';

  @override
  String get newKeyFlowNewAccountSubtitle =>
      'Choose the username for your new account.';

  @override
  String newKeyFlowRuleLength(int min, int max) {
    return '$min to $max characters';
  }

  @override
  String get newKeyFlowRuleStart => 'Starts with a letter';

  @override
  String get newKeyFlowRuleEnd => 'Ends with a letter or a number';

  @override
  String get newKeyFlowRuleChars => 'Only letters, numbers, - and _';

  @override
  String get newKeyFlowRuleNoDoubles => 'No -- or __';

  @override
  String get newKeyFlowRuleAvailable => 'Not taken';

  @override
  String get newKeyFlowFreeNote =>
      'Citizens get names of 5 or more characters free.';

  @override
  String get newKeyFlowContinue => 'CONTINUE';

  @override
  String get newKeyFlowCancel => 'CANCEL';

  @override
  String get newKeyFlowWordsWarning =>
      'Once added or created, these words will help you recover this account. Write them down, keep them offline, and never share them.';

  @override
  String get newKeyFlowActivated => 'Your key was activated.';

  @override
  String get groupVotingViewWithdraw => 'WITHDRAW';

  @override
  String get groupVotingViewVeto => 'VETO';

  @override
  String get groupVotingViewWithdrawTitle => 'Withdraw your proposal';

  @override
  String get groupVotingViewWithdrawBody =>
      'It ends now, with your reason on record.';

  @override
  String groupVotingViewWithdrawCooldown(Object time) {
    return 'Afterwards you can\'t propose in this org for $time.';
  }

  @override
  String get groupVotingViewVetoTitle => 'Veto this vote';

  @override
  String get groupVotingViewVetoBody =>
      'As the org\'s vetoer you end this vote now. Your reason goes on record.';

  @override
  String get groupVotingViewCancelVoteTitle => 'Propose cancelling this vote';

  @override
  String groupVotingViewCancelVoteBody(Object name, Object id) {
    return '$name\'s vote #$id. The org votes on it; if it passes, that vote ends at once, even in an org that waits the full period.';
  }

  @override
  String get groupVotingViewCancelReasonHint => 'Reason (required)';

  @override
  String get groupVotingViewWithdrawn => 'Withdrawn';

  @override
  String get groupVotingViewVetoed => 'Vetoed';

  @override
  String groupVotingViewCancelledBy(Object who, Object reason) {
    return 'Cancelled by $who: “$reason”';
  }

  @override
  String get groupVotingViewCancelKindProposer => 'the proposer';

  @override
  String get groupVotingViewCancelKindVetoer => 'the vetoer';

  @override
  String get groupVotingViewCancelKindOrg => 'this org, by vote';

  @override
  String get groupVotingViewCancelKindAncestor => 'a parent org, by vote';

  @override
  String get groupVotingViewVetoer => 'Vetoer';

  @override
  String get groupVotingViewVetoerSubtitle =>
      'One member who can cancel the org\'s votes alone';

  @override
  String get groupVotingViewVetoerNone => 'None';

  @override
  String get groupVotingViewVetoerAutoRun =>
      'This org runs a vote the moment it passes, so a vetoer will rarely have time to act. Turn on “wait the full period” to give them a window.';

  @override
  String get groupVotingViewCooldown => 'Withdraw cooldown';

  @override
  String get groupVotingViewCooldownSubtitle =>
      'How long a member waits to propose again after withdrawing their own vote';

  @override
  String get groupVotingViewCooldownNone => 'None';

  @override
  String get groupVotingViewVetoerBody =>
      'The vetoer is one member who can end any open vote of this org on their own, right away, with a reason on record. A vote that changes the vetoer can\'t be vetoed. Picking here starts a vote.';

  @override
  String get groupVotingViewCooldownBody =>
      'After a member withdraws their own open vote, they can\'t propose in this org for this long. A veto, or a cancel by vote, doesn\'t count. Picking here starts a vote.';

  @override
  String get groupVotingViewMaxOpenBody =>
      'How many proposals this org can have open at the same time. Each member can still have only one of their own open. Picking here starts a vote.';

  @override
  String groupVotingViewInCooldown(Object when) {
    return 'You withdrew a vote here. You can propose again $when.';
  }

  @override
  String get groupVotingViewCancelAVote => 'Cancel a vote';

  @override
  String get groupVotingViewCancelAVoteSubtitle =>
      'Propose ending an open vote here or in a child org';

  @override
  String get groupVotingViewDescSetVetoer => 'Give the veto to';

  @override
  String get groupVotingViewDescClearVetoer => 'Remove the vetoer';

  @override
  String groupVotingViewDescCancelVote(Object id) {
    return 'Cancel vote #$id';
  }

  @override
  String get cancelVoteSheetTitle => 'Cancel a vote';

  @override
  String get cancelVoteSheetSubtitle =>
      'Open votes in this org and the orgs under it';

  @override
  String get cancelVoteSheetSearchHint => 'Find an org by name';

  @override
  String get cancelVoteSheetChecking => 'Checking…';

  @override
  String cancelVoteSheetNotFound(Object name) {
    return 'No org named $name';
  }

  @override
  String get cancelVoteSheetNotInTree => 'Not in this org\'s tree';

  @override
  String get cancelVoteSheetOpenVotes => 'OPEN VOTES';

  @override
  String get cancelVoteSheetChildren => 'CHILD ORGS';

  @override
  String get cancelVoteSheetNoVotes => 'No open votes';

  @override
  String get cancelVoteSheetNoChildren => 'No child orgs';

  @override
  String get cancelVoteSheetShowMore => 'Show more';

  @override
  String get manageServerPageManageFiles => 'MANAGE FILES';

  @override
  String get manageFilesPageTitle => 'Manage Files';

  @override
  String get manageFilesPageSearchHint => 'Search by file name';

  @override
  String get manageFilesPageFilterAll => 'All';

  @override
  String get manageFilesPageFilterImages => 'Images';

  @override
  String get manageFilesPageFilterVideos => 'Videos';

  @override
  String get manageFilesPageFilterAudio => 'Audio';

  @override
  String get manageFilesPageFilterOther => 'Other';

  @override
  String get manageFilesPageFilterPublic => 'Public';

  @override
  String get manageFilesPageFilterPrivate => 'Private';

  @override
  String get manageFilesPageSortNewest => 'Newest';

  @override
  String get manageFilesPageSortOldest => 'Oldest';

  @override
  String get manageFilesPageSortLargest => 'Largest';

  @override
  String get manageFilesPageSortSmallest => 'Smallest';

  @override
  String get manageFilesPageSortName => 'Name';

  @override
  String manageFilesPageShowing(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0 · $size';
  }

  @override
  String get manageFilesPageNoMatches => 'No files match.';

  @override
  String get manageFilesPageLoadFailed => 'Could not load your files.';

  @override
  String get manageFilesPageSelect => 'Select';

  @override
  String get manageFilesPageSelectAll => 'Select all';

  @override
  String manageFilesPageSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get manageFilesPageDeleteManyTitle => 'Delete files';

  @override
  String manageFilesPageDeleteManyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count files?',
      one: 'Delete 1 file?',
    );
    return '$_temp0 This frees up your media quota and can\'t be undone.';
  }

  @override
  String manageFilesPageDeleting(int done, int total) {
    return 'Deleting $done of $total';
  }

  @override
  String manageFilesPageDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files deleted',
      one: '1 file deleted',
    );
    return '$_temp0';
  }

  @override
  String manageFilesPageDeletedPartial(int deleted, int failed) {
    return '$deleted deleted, $failed failed';
  }

  @override
  String get newAccountAskTitle =>
      'Accounts are created by citizens, one at a time';

  @override
  String get newAccountAskBody =>
      'A citizen can create yours by scanning your code. If you do not know one, we can help you out.';

  @override
  String get newAccountAskFriend => 'I HAVE A CITIZEN FRIEND';

  @override
  String get newAccountAskHelp => 'I DON\'T HAVE A FRIEND ON PUBLICOS';

  @override
  String get newAccountAskOpenFailed => 'Could not open the page.';

  @override
  String get importKeyLinkTitle => 'IMPORT ACCOUNT';

  @override
  String importKeyLinkBody(String name) {
    return 'You are importing the keys for $name.';
  }

  @override
  String get importKeyLinkBodyNoName =>
      'You are importing the keys for an account.';

  @override
  String get importKeyLinkAccept => 'IMPORT';

  @override
  String get importKeyLinkPendingExists =>
      'Finish or remove the pending key first.';

  @override
  String get importKeyLinkSignedIn => 'Sign out to import an account.';

  @override
  String get desktopUpdateChip => 'Update available';

  @override
  String get desktopUpdateTitle => 'Update PublicOS';

  @override
  String desktopUpdateBody(String version, int sizeMb) {
    return 'Version $version is ready ($sizeMb MB). The app closes, updates and opens again. Your account and your data stay on this PC.';
  }

  @override
  String get desktopUpdateChecked => 'Its signature was checked on the chain.';

  @override
  String get desktopUpdateNow => 'UPDATE AND RESTART';

  @override
  String get desktopUpdateLater => 'LATER';

  @override
  String desktopUpdateDownloading(int percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get desktopUpdateInstalling => 'Installing. The app will close now.';

  @override
  String get desktopUpdateFailed =>
      'The update could not be installed. Nothing was changed.';

  @override
  String get desktopUpdateNotHere =>
      'This copy of the app cannot update itself where it is installed. Download the new version instead.';

  @override
  String get desktopUpdateOpenPage => 'OPEN THE DOWNLOAD PAGE';
}
