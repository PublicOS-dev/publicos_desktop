// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get languageName => 'Español';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSubtitle =>
      'Elige el idioma de la aplicación. El contenido permanece en su idioma original.';

  @override
  String get settingsLanguageSystemDefault => 'Predeterminado del sistema';

  @override
  String get revertGeneric => 'La cadena rechazó la transacción.';

  @override
  String get revertAuthorizeFailed => 'Falló la autorización.';

  @override
  String get revertRecoveryFailed => 'No se pudo iniciar la recuperación.';

  @override
  String get revertAccountCreationFailed => 'Falló la creación de la cuenta.';

  @override
  String get revertCreateOrgFailed => 'No se pudo crear la organización.';

  @override
  String get revertCreationPaused =>
      'La creación de cuentas está pausada por ahora.';

  @override
  String get revertNameEmpty => 'El nombre de usuario no puede estar vacío.';

  @override
  String get revertMinterNotCitizen =>
      'Solo los ciudadanos pueden crear cuentas nuevas. Consigue avales primero.';

  @override
  String get revertNameCharsetTier =>
      'Ese nombre de usuario no cumple las reglas (longitud, caracteres o carácter inicial).';

  @override
  String get revertNameTaken => 'Ese nombre de usuario ya está en uso.';

  @override
  String get revertNameReservedCooldown =>
      'Ese nombre está reservado o en espera; prueba otro.';

  @override
  String get revertNameCooldown => 'Ese nombre está en espera; prueba otro.';

  @override
  String get revertRenameQuota =>
      'Ya usaste tu cambio de nombre gratuito de este año y no te quedan bonos.';

  @override
  String get revertNotRegisteredSender =>
      'Esta billetera no está registrada como sesión de ninguna cuenta.';

  @override
  String get revertOrgRateLimited =>
      'Creaste una organización hace poco; hay un tiempo de espera antes de crear otra.';

  @override
  String get revertOrgNeedsMembers =>
      'Una organización necesita al menos un miembro.';

  @override
  String get revertThresholdPositive =>
      'El umbral de votación debe ser al menos 1.';

  @override
  String get revertThresholdExceedsMembers =>
      'El umbral de votación no puede ser mayor que el número de miembros.';

  @override
  String get revertMemberNotIndividual =>
      'Uno de los miembros no es una cuenta individual válida.';

  @override
  String get revertPublicOrgCreatorCitizen =>
      'Solo los ciudadanos pueden crear una organización pública.';

  @override
  String get revertPublicOrgMembersCitizens =>
      'Cada miembro de una organización pública debe ser ciudadano.';

  @override
  String get revertNotRegisteredSession =>
      'Tu billetera no es una sesión registrada de ninguna cuenta.';

  @override
  String get revertNotOrgMember =>
      'No eres miembro de esta organización; solo los miembros pueden iniciar una votación.';

  @override
  String get revertNotOrgAccount =>
      'Esa dirección no es una cuenta de organización.';

  @override
  String get revertVoteAlreadyActive =>
      'Ya hay una votación activa en esta organización; espera a que termine antes de iniciar otra.';

  @override
  String get revertInvalidMemberAddress =>
      'La dirección del miembro seleccionado no es válida.';

  @override
  String get revertAlreadyMember => 'Esa cuenta ya es miembro.';

  @override
  String get revertMemberMustBeIndividual =>
      'Solo puedes agregar una cuenta individual como miembro, no una cuenta de organización.';

  @override
  String get revertOracleUnavailable =>
      'La verificación de ciudadanía no está disponible ahora; inténtalo más tarde.';

  @override
  String get revertPublicOrgAddCitizen =>
      'Esta es una organización pública; cada nuevo miembro debe ser ciudadano.';

  @override
  String get revertNotMember => 'Esa cuenta no es miembro.';

  @override
  String get revertCannotRemoveLastMember =>
      'No puedes eliminar al último miembro de una organización.';

  @override
  String get revertRemovalViolatesThreshold =>
      'Eliminarlos dejaría menos miembros que el umbral de votación; baja el umbral primero.';

  @override
  String get revertOrgNotInitialized =>
      'Esta organización no está inicializada.';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get sendRecipientLookupFailed =>
      'No se pudo averiguar a dónde enviar esto. No se envió nada.';

  @override
  String get sendRecipientRetry => 'REINTENTAR';

  @override
  String get errTxRefusedByNetwork =>
      'La red rechazó esta transacción. Casi siempre significa que tu dominio está vencido: renuévalo en Cuenta › Dominio y vuelve a intentarlo.';

  @override
  String get errKeyLabelExists => 'Ya existe una llave con esta etiqueta.';

  @override
  String get errInvalidMnemonic => 'Frase de recuperación no válida.';

  @override
  String get errInvalidBase64 => 'Formato base64 no válido.';

  @override
  String get errDbKeyEmpty =>
      'La llave de la base de datos no puede estar vacía.';

  @override
  String get errKeyMetadataNotFound =>
      'No se encontraron los metadatos de la llave.';

  @override
  String get errKeyNotFound => 'No se encontró la llave.';

  @override
  String get errInvalidKeyLength =>
      'Longitud de llave no válida (se esperaban 32 bytes).';

  @override
  String get errNoUserAddress => 'No hay una dirección de usuario disponible.';

  @override
  String get errNoXmtpIdentity =>
      'No se seleccionó una identidad de mensajería.';

  @override
  String get errNotAuthenticated => 'Debes iniciar sesión para eso.';

  @override
  String get errNoServer =>
      'No hay un servidor disponible ahora. Inténtalo más tarde.';

  @override
  String get errCommentsNotSupported =>
      'Esta publicación no permite comentarios.';

  @override
  String get errReactionsNotSupported =>
      'Esta publicación no permite reacciones.';

  @override
  String get errLoadContent => 'No se pudo cargar esto. Inténtalo de nuevo.';

  @override
  String get signInToReact => 'Inicia sesión para reaccionar.';

  @override
  String sspNotSubscribed(String slug) {
    return 'Suscríbete a $slug para escribir aquí.';
  }

  @override
  String sspWrong(String slug) {
    return 'Estás en $slug. Cambia para escribir aquí.';
  }

  @override
  String sspExpired(String slug) {
    return 'Tu suscripción a $slug expiró.';
  }

  @override
  String get sspGateFailed =>
      'No se puede verificar tu suscripción ahora. Inténtalo de nuevo.';

  @override
  String get sspThisServer => 'este servidor';

  @override
  String get sspAnotherServer => 'otro servidor';

  @override
  String get sspActionSubscribe => 'SUSCRIBIRSE';

  @override
  String get sspActionSwitch => 'CAMBIAR';

  @override
  String get sspActionRenew => 'RENOVAR';

  @override
  String get errNotInitialized =>
      'La aplicación aún no está lista. Inténtalo en un momento.';

  @override
  String get errCannotDeleteActiveAccount =>
      'No puedes eliminar la cuenta que estás usando.';

  @override
  String get errUpdateColorFailed => 'No se pudo actualizar el color.';

  @override
  String get errRemoveSessionFailed => 'No se pudo eliminar la sesión.';

  @override
  String get errAddRecoveryFailed =>
      'No se pudo agregar el contacto de recuperación.';

  @override
  String get errRemoveRecoveryFailed =>
      'No se pudo eliminar el contacto de recuperación.';

  @override
  String get errSelectAccountFailed => 'No se pudo seleccionar esa cuenta.';

  @override
  String get errCreateKeysFailed => 'No se pudieron crear las llaves.';

  @override
  String get errImportFailed =>
      'No se pudo importar. Revisa el valor e inténtalo de nuevo.';

  @override
  String get errCheckActivationFailed => 'No se pudo verificar la activación.';

  @override
  String get errDeleteAccountFailed => 'No se pudo eliminar la cuenta.';

  @override
  String get errDeleteKeyPairFailed => 'No se pudo eliminar el par de llaves.';

  @override
  String get errResetAppFailed => 'No se pudo restablecer la aplicación.';

  @override
  String get errAddWalletFailed => 'No se pudo vincular la billetera.';

  @override
  String get errCastVoteFailed => 'No se pudo emitir tu voto.';

  @override
  String get errTranslateFailed => 'No se pudo traducir esto.';

  @override
  String notifComment(String name) {
    return '$name comentó tu publicación';
  }

  @override
  String notifReply(String name) {
    return '$name respondió a tu comentario';
  }

  @override
  String notifMention(String name) {
    return '$name te mencionó';
  }

  @override
  String notifReactionPost(String name) {
    return '$name reaccionó a tu publicación';
  }

  @override
  String notifReactionComment(String name) {
    return '$name reaccionó a tu comentario';
  }

  @override
  String notifFollowRequest(String name) {
    return '$name pidió seguir tu canal';
  }

  @override
  String notifFollowApproved(String name) {
    return '$name te aceptó en su canal';
  }

  @override
  String get notificationsScreenPostUnavailable =>
      'No se pudo abrir esta publicación';

  @override
  String get notificationsScreenChannelUnavailable =>
      'No se pudo abrir este canal';

  @override
  String get notificationsScreenCommented => ' comentó tu publicación';

  @override
  String get notificationsScreenReplied => ' respondió a tu comentario';

  @override
  String get notificationsScreenMentioned => ' te mencionó';

  @override
  String get notificationsScreenReactedPost => ' reaccionó a tu publicación';

  @override
  String get notificationsScreenReactedComment => ' reaccionó a tu comentario';

  @override
  String get notificationsScreenFollowRequested => ' pidió seguir tu canal';

  @override
  String get notificationsScreenFollowApproved => ' te aceptó en su canal';

  @override
  String get notifAvatarYou => 'Actualizaste tu avatar';

  @override
  String notifAvatarThey(String name) {
    return '$name actualizó su avatar';
  }

  @override
  String get notifBannerYou => 'Actualizaste tu portada';

  @override
  String notifBannerThey(String name) {
    return '$name actualizó su portada';
  }

  @override
  String get notifBioYou => 'Actualizaste tu biografía';

  @override
  String notifBioThey(String name) {
    return '$name actualizó su biografía';
  }

  @override
  String get notifProfileYou => 'Actualizaste tu perfil';

  @override
  String notifProfileThey(String name) {
    return '$name actualizó su perfil';
  }

  @override
  String get notifTabsYou => 'Actualizaste tus pestañas';

  @override
  String notifTabsThey(String name) {
    return '$name actualizó sus pestañas';
  }

  @override
  String notifVouchedYou(String name) {
    return '$name te hizo vouch 🎉';
  }

  @override
  String notifVouchedByYou(String name) {
    return 'Le hiciste vouch a $name';
  }

  @override
  String notifVouchedOther(String actor, String target) {
    return '$actor le hizo vouch a $target';
  }

  @override
  String get notifCitizenYou => 'Ya eres ciudadano 🎉';

  @override
  String notifCitizenThey(String name) {
    return '$name ya es ciudadano 🎉';
  }

  @override
  String notifRentYou(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses',
      one: '1 mes',
    );
    return 'Pagaste tu dominio — $_temp0';
  }

  @override
  String notifRentThey(String name, int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months meses',
      one: '1 mes',
    );
    return '$name pagó su dominio — $_temp0';
  }

  @override
  String get notifEvictedYou => 'Tu cuenta fue desalojada por falta de pago';

  @override
  String notifEvictedThey(String name) {
    return '$name fue desalojado por falta de pago';
  }

  @override
  String get notifNameChangedYou => 'Cambiaste tu nombre';

  @override
  String notifNameNowYou(String name) {
    return 'Ahora eres @$name';
  }

  @override
  String notifNameChangedThey(String actor) {
    return '$actor cambió su nombre';
  }

  @override
  String notifNameNowThey(String actor, String name) {
    return '$actor ahora es @$name';
  }

  @override
  String get notifDisplayChangedYou => 'Cambiaste tu nombre visible';

  @override
  String notifDisplayToYou(String name) {
    return 'Cambiaste tu nombre visible a $name';
  }

  @override
  String notifDisplayChangedThey(String actor) {
    return '$actor cambió su nombre visible';
  }

  @override
  String notifDisplayToThey(String actor, String name) {
    return '$actor cambió su nombre visible a $name';
  }

  @override
  String notifTransferIn(String amount, String wallet) {
    return 'Recibiste $amount en $wallet';
  }

  @override
  String notifTransferInFrom(String actor, String amount, String wallet) {
    return '$actor envió $amount a $wallet';
  }

  @override
  String notifTransferOut(String amount, String wallet) {
    return 'Enviaste $amount desde $wallet';
  }

  @override
  String notifTransferOutTo(String amount, String wallet, String target) {
    return 'Enviaste $amount desde $wallet a $target';
  }

  @override
  String notifTransferSelf(String amount, String wallet, String target) {
    return 'Moviste $amount de $wallet a $target';
  }

  @override
  String get notifWalletGroup => 'Actividad de billetera';

  @override
  String get notifKindTransferIn => 'Dinero recibido';

  @override
  String get notifKindTransferOut => 'Dinero enviado';

  @override
  String get notifKindTransferSelf => 'Entre tus billeteras';

  @override
  String get bootInitializing => 'Iniciando sistemas...';

  @override
  String get bootCheckingAuth => 'Verificando autenticación...';

  @override
  String get bootCheckingLogin => 'Verificando inicio de sesión...';

  @override
  String get bootRestoringSession => 'Restaurando sesión...';

  @override
  String get bootConnectingChain => 'Conectando a la cadena...';

  @override
  String get bootLoadingKeys => 'Cargando llaves...';

  @override
  String get bootConnectingFeed => 'Conectando al servidor de feeds...';

  @override
  String get bootLoadingMessages => 'Cargando mensajes...';

  @override
  String get bootSettingUpNotifs => 'Configurando notificaciones...';

  @override
  String get bootOpening => 'Abriendo...';

  @override
  String get bootLoading => 'Cargando...';

  @override
  String get bootRetry => 'CONECTAR';

  @override
  String get bootErrCoreInit => 'No se pudieron iniciar los sistemas';

  @override
  String get bootErrAuthNeeded => 'Se requiere autenticación para continuar';

  @override
  String get bootErrUnexpected =>
      'Ocurrió un error inesperado durante el inicio. Inténtalo de nuevo.';

  @override
  String get onbPublicosTitle => 'PublicOS';

  @override
  String get onbPublicosSubtitle => 'Hazlo tuyo';

  @override
  String get onbPublicosBody =>
      'PublicOS es una plataforma social con su propia infraestructura, gobernanza y economía: una institución pública en internet, propiedad de las personas que la usan.\n\nObtienes un dominio completo para ti, un lugar para publicar, organizar y monetizar como quieras.\n\nTodo funciona a la vista y se decide mediante democracia líquida: cada regla, cada voto, cada token, verificable por cualquiera.\n\n';

  @override
  String get onbInfraTitle => '¿Cómo funciona?';

  @override
  String get onbInfraSubtitle => 'Dos redes, un lugar';

  @override
  String get onbInfraBody =>
      'La economía de PublicOS toma mecánicas comunes de internet y las ejecuta como servicios públicos gestionados democráticamente, ninguna empresa es dueña de tus cosas:\n\n- Los datos de tu cuenta y las reglas que escribamos se ejecutan y almacenan de forma transparente en una blockchain\n\n- Tus publicaciones, fotos y archivos viven en una red tipo correo electrónico, donde proveedores independientes se conectan entre sí\n';

  @override
  String get onbAccountsTitle => 'Cuentas';

  @override
  String get onbAccountsSubtitle =>
      'Los cuatro tipos de cuenta que encontrarás en PublicOS';

  @override
  String get onbAccountsSelfPrefix => 'Actualmente eres ';

  @override
  String get onbCitizenWord => 'ciudadano';

  @override
  String get onbPrivateWord => 'privado';

  @override
  String get onbCitizenLabel => 'CIUDADANO';

  @override
  String get onbCitizenDesc =>
      'Humanos reconocidos en un gráfico social, servicios públicos gratiutos, un voto.';

  @override
  String get onbPublicOrgLabel => 'ORG PÚBLICA';

  @override
  String get onbPublicOrgDesc =>
      'Colectivos de ciudadanos de cualquier tipo y tamaño.';

  @override
  String get onbPrivateLabel => 'PRIVADA';

  @override
  String get onbPrivateDesc => 'Cuentas anónimas, sin necesidad de humanidad.';

  @override
  String get onbPrivateOrgLabel => 'ORG PRIVADA';

  @override
  String get onbPrivateOrgDesc =>
      'Colectivos mixtos de ciudadanos y privados para grupos y negocios.';

  @override
  String get onbMorphAccountTitle => 'Tu cuenta';

  @override
  String get onbMorphAccountSubtitle => 'Inteligente';

  @override
  String get onbMorphAccountBody =>
      'Todo lo que haces en PublicOS pasa por una sola cuenta inteligente. \n\nEs tu nombre y tu dirección; guarda tus registros, tus activos y un registro público de las llaves que autorizas para firmar.\n\nVeamos cómo se arma.';

  @override
  String get onbMorphDomainTitle => 'Tu dominio';

  @override
  String get onbMorphDomainSubtitle =>
      'El nombre que la gente usa para encontrarte';

  @override
  String get onbMorphDomainBody =>
      'Tu **dominio** es tu nombre en la red, el identificador que otros usan para buscarte.';

  @override
  String get onbDomainBodyCitizen =>
      'Tu **dominio** es tu nombre en la red, el identificador que otros usan para buscarte.\n\nTienes **ciudadanía**, así que el tuyo es gratis de por vida.';

  @override
  String get onbDomainBodyPaid =>
      'Tu **dominio** es tu nombre en la red, el identificador que otros usan para buscarte.\n\nTu cuenta es **privada**, y tu dominio **ya está pagado**.';

  @override
  String get onbDomainBodyRent =>
      'Tu **dominio** es tu nombre en la red, el identificador que otros usan para buscarte.\n\nLas cuentas **privadas** pagan una **tarifa de dominio** para conservar el suyo. Configura el tuyo abajo y listo.';

  @override
  String get onbMorphAddressTitle => 'La dirección de tu cuenta';

  @override
  String get onbMorphAddressSubtitle => 'A lo que apunta el dominio';

  @override
  String get onbMorphAddressBody =>
      'Tu dominio puede cambiar, pero siempre resuelve a la misma dirección en la cadena.\n\nEs la dirección del contrato inteligente de tu cuenta; funciona según las reglas de PublicOS y guarda los datos de tu cuenta.';

  @override
  String get onbMorphRecordsTitle => 'Tus registros';

  @override
  String get onbMorphRecordsSubtitle => 'Lo que guarda tu cuenta';

  @override
  String get onbMorphRecordsBody =>
      'Los registros son piezas de información que eliges hacer públicas, como tu avatar y tu portada, las pestañas que apuntan a tus chats, tus sitios web, tus feeds.\n\n Échale un vistazo: abre la hoja de pestañas.';

  @override
  String get onbMorphSafeTitle => 'Tu Safe';

  @override
  String get onbMorphSafeSubtitle => 'Donde se guardan tus activos';

  @override
  String get onbMorphSafeBody =>
      'Vinculado a tu cuenta hay un Safe federado: una bóveda inteligente que guarda tus tokens y activos.\n\nEs programable: puedes establecer reglas y módulos para administrarla como quieras.';

  @override
  String get onbBspTitle => 'Proveedor de blockchain';

  @override
  String get onbBspSubtitle => 'Tu puerta de entrada a la cadena';

  @override
  String get onbBspBody =>
      'Los BSP son notarios públicos. Verifican que cada transacción sea válida y esté firmada por ti, la registran y la comparten con otros BSP, tejiendo un libro contable que cualquiera puede auditar.\n\nEs una sola hoja de cálculo transparente de saldos y contratos inteligentes. Los BSP la mantienen funcionando y te conectan a ella.';

  @override
  String get onbBspPrivateNote =>
      'Como privado, puedes conectarte mediante el RPC público o suscribirte a un BSP (cada uno define su propia política de uso justo).';

  @override
  String get onbSspTitle => 'Proveedor social';

  @override
  String get onbSspSubtitle => 'Donde viven tus feeds';

  @override
  String get onbSspBody =>
      'Un SSP aloja lo que alojaría cualquier app de redes sociales: tus feeds, tu contenido multimedia y tu contenido social.\n\nElige uno para empezar, o trae el tuyo. Siempre puedes explorar PublicOS primero y agregar uno después.';

  @override
  String get onbSspPrivateNote =>
      'Como cuenta privada, esta es una suscripción opcional, pagada directamente a tu proveedor.';

  @override
  String get onbProviderCitizenNote =>
      'Gratis para ti: la red cubre las tarifas de proveedor para los ciudadanos.';

  @override
  String get onbEconomyTitle => 'Economía';

  @override
  String get onbEconomySubtitle => 'Soveranía';

  @override
  String get onbEconomyBody =>
      'PublicOS tiene su propia moneda, **ox (¤)**, gestionada como una economía nacional.\n\n**Los contratistas** (BSP y SSP) operan los servicios. PublicOS imprime ox para cubrir el uso de los ciudadanos.\n\n**Los dominios** son un segundo mercado: los ciudadanos obtienen uno como derecho público, mientras que los nombres restantes se comercializan en el mercado abierto.\n\nLa idea: **tú eres el valor de la plataforma**, así que ganas un poco de ox cada vez que se pagan servicios. Revisa la Tesorería con frecuencia.';

  @override
  String get onbContractTitle => 'El contrato social';

  @override
  String get onbContractSubtitle => 'Nuestra constitución';

  @override
  String get onbContractBody =>
      'La ciudadanía es un derecho público. A cambio, honras una promesa:\n\n**Las cuentas con vouch son humanos.** Si alguna vez importara, podrías señalar a una persona real detrás de cualquiera a quien le hagas vouch.\n\nHaces vouch por la **humanidad, no por la moralidad**. Nunca eres responsable de lo que hagan los demás, solo de la verdad de tu vouch.';

  @override
  String get onbKeysTitle => 'Llaves';

  @override
  String get onbKeysSubtitle => 'La tinta detrás de tu firma';

  @override
  String get onbKeysBody =>
      'Todo lo que haces en la cadena se \"firma\" con tus llaves, como una pluma firma con tinta.\n\n**Llave privada**: tu secreto. Una firma hecha con ella prueba que eres tú, y solo tú puedes crear una. Nunca la compartas.\n\n**Dirección pública**: tu identificador para compartir. Permite que cualquiera confirme que una firma es realmente tuya.\n\nCrea tu primera llave y guarda su frase de recuperación en un lugar seguro.';

  @override
  String get onbXmtpTitle => 'XMTP';

  @override
  String get onbXmtpSubtitle => 'Mensajería privada, sin intermediarios';

  @override
  String get onbXmtpBody =>
      'Los mensajes de PublicOS funcionan en la red descentralizada de XMTP.\n\n**Muchas bandejas.** Crea tantas bandejas separadas como quieras.\n\n**Sin intermediarios.** Cifrado de extremo a extremo.\n\nCualquier llave puede crear o unirse a un Inbox ID.';

  @override
  String get onbInboxTitle => 'Inbox IDs';

  @override
  String get onbInboxSubtitle => 'Tu dirección de mensajería';

  @override
  String get onbInboxBody =>
      'Trata los inbox IDs como correos electrónicos: algunos se mantienen fuera de la cadena y privados, otros son públicos y compartibles.\n\nPublícalo en tu perfil con el botón \"pestaña\" para que la gente pueda contactarte; vincula tu cuenta con tu bandeja de mensajería en la cadena.';

  @override
  String get onbGetAroundTitle => 'Muévete en PublicOS';

  @override
  String get onbGetAroundSubtitle => 'Tres cosas que conviene saber';

  @override
  String get onbManualTitle => 'Manual';

  @override
  String get onbManualBody =>
      'Todo sobre PublicOS, a tu ritmo, qué significan las palabras, cómo funciona el dinero, qué puedes hacer. En tus **Apps**.';

  @override
  String get onbLibraryTitle => 'Biblioteca';

  @override
  String get onbLibraryBody =>
      'Cómo funciona PublicOS, a fondo: qué cuesta cada cosa, las reglas, cada contrato. En tus **Apps**.';

  @override
  String get onbSupportTitle => 'Soporte';

  @override
  String get onbSupportBody =>
      'Un asistente vive en el perfil de **publicos**, bajo **support**. Pregúntale lo que sea, en **cualquier idioma**.';

  @override
  String get onbDone => 'LISTO';

  @override
  String get onbEnter => 'ENTRAR A PUBLICOS';

  @override
  String get onbContinue => 'CONTINUAR';

  @override
  String get onbClaimCitizenship => 'RECLAMAR CIUDADANÍA';

  @override
  String get onbChooseBsp => 'ELEGIR UN BSP';

  @override
  String get onbChooseSsp => 'ELEGIR UN SSP';

  @override
  String get onbOpenTabsFirst => 'ABRE MIS PESTAÑAS PRIMERO';

  @override
  String get onbSkipForNow => 'OMITIR POR AHORA';

  @override
  String get onbSkip => 'OMITIR';

  @override
  String get onbRedoHintTitle => 'Todo listo';

  @override
  String get onbRedoHintBody =>
      '¿Quieres seguir aprendiendo? Abre la app Users Manual, ya está en tus Apps. Puedes elegir o cambiar tus proveedores en cualquier momento desde la app de Ajustes, y rehacer toda esta introducción desde ahí también.';

  @override
  String get onbYoursCreateInboxFirst => 'CREA TU BANDEJA PRIMERO';

  @override
  String get onbYoursTitle => 'UNA PUERTA';

  @override
  String get onbYoursSubtitle => 'Un perfil, pero sin puerta.';

  @override
  String get onbYoursBody =>
      'Ya tienes una cuenta, pero todavía no hay forma de contactarte.\n\nPublica una **bandeja** como pestaña y la gente podrá encontrarte con tu nombre.';

  @override
  String get onbYoursAddInbox => 'AÑADIR MI PRIMERA BANDEJA';

  @override
  String get onbYoursHaveBody =>
      'Ya tienes una **bandeja**, la gente puede encontrarte con tu nombre.\n\n¿Quieres ver cómo se publica otra?';

  @override
  String get onbYoursUnknownBody =>
      'Puede que tu **bandeja** ya esté publicada, no pudimos comprobarlo ahora.\n\nContinúa, o recorre cómo publicar una.';

  @override
  String get onbYoursShowMeHow => 'MUÉSTRAME CÓMO';

  @override
  String get onbTabsBody =>
      'Tu nombre puede tener más de una **pestaña**. Ya publicaste una bandeja, esa es una.\n\nTodo lo de abajo se agrega después desde tu página de cuenta. Hoy no hace falta nada más.';

  @override
  String get onbTabsAdded => 'AGREGADA';

  @override
  String get onbTabsInboxTitle => 'Bandeja';

  @override
  String get onbTabsInboxSub => 'la que acabas de publicar';

  @override
  String get onbTabsWebSub => 'tu sitio, bajo tu nombre';

  @override
  String get onbTabsChannelSub => 'un feed que la gente puede seguir';

  @override
  String get onbTabsAnotherTitle => 'Otra bandeja';

  @override
  String get onbTabsAnotherSub => 'trabajo, pública, las que quieras';

  @override
  String get onbCoachKeychain => 'Tus llaves viven en el **llavero**. Ábrelo.';

  @override
  String get onbCoachGenerate =>
      '**Genera** una llave. Se crea en este dispositivo y no se guarda en ningún otro lado.';

  @override
  String get onbCoachSim =>
      'Ahora enciéndela para mensajería, toca el **SIM**. Eso le da una bandeja a la llave, y así cambias de llave más adelante.';

  @override
  String get onbProfileTitle => 'TU CUENTA';

  @override
  String get onbProfileSubtitle => 'Las mismas partes. Ya son tuyas.';

  @override
  String get onbProfileBody => 'Vamos a llenar tu **bio**.';

  @override
  String get onbProfileChooseBioFirst => 'ELIGE UNA BIO PRIMERO';

  @override
  String get onbBioSaveChanges => 'GUARDAR CAMBIOS';

  @override
  String get onbBioSaving => 'GUARDANDO';

  @override
  String get onbBioUndo => 'DESHACER CAMBIOS';

  @override
  String get onbProfileBioEmpty => 'Tu bio todavía está vacía.';

  @override
  String get onbProfileNextCards => 'SEGUIR CON MIS TARJETAS';

  @override
  String get onbCardsTitle => 'TUS TARJETAS';

  @override
  String get onbCardsSubtitle => 'Ya están en tu perfil.';

  @override
  String get onbCardsBody =>
      'Elige un **tema** y algunas **tarjetas** para tu perfil.';

  @override
  String get onbCardsRandomize => 'MEZCLAR';

  @override
  String get onbCardsUndo => 'DESHACER CAMBIOS';

  @override
  String get onbCardsSaving => 'GUARDANDO';

  @override
  String get onbGiftBody =>
      '🎁 Un **regalo para ciudadanos**, un kit temático de colección para tu perfil.';

  @override
  String get onbGiftOpen => 'ABRIR REGALO';

  @override
  String get onbGiftMinting => 'ABRIENDO';

  @override
  String get onbThemeSoulbound => 'INICIAL';

  @override
  String get onbThemeCitizen => 'CIUDADANO';

  @override
  String get onbProfileBioPrompt => 'Di algo sobre ti.';

  @override
  String get onbProfileBioWriteOwn => 'Escribe la tuya…';

  @override
  String get onbProfileBioPreset1 =>
      'Ciudadana de PublicOS. Construyendo en abierto.';

  @override
  String get onbProfileBioPreset2 =>
      'Aquí por los feeds, los foros y los amigos.';

  @override
  String get onbProfileBioPreset3 =>
      'Pregúntame lo que sea, mi bandeja está en mi perfil.';

  @override
  String get onbAccountTitle => 'UNA CUENTA';

  @override
  String get onbAccountSubtitle => 'Esta es la de PublicOS.';

  @override
  String get onbAccountBody =>
      'Cada **cuenta** se construye igual: un dominio, su dirección, y lo que decida publicar.\n\nLas **pestañas** publicadas son el menú de la cuenta. Abre las pestañas de PublicOS y échale un ojo.';

  @override
  String get onbAccountOpenTabsFirst => 'ABRE LAS PESTAÑAS PRIMERO';

  @override
  String get onbDomainManageFirst => 'GESTIONA TU DOMINIO PRIMERO';

  @override
  String onbTabsSheetTitle(String account) {
    return '$account · pestañas';
  }

  @override
  String get onbTabApp => 'App';

  @override
  String get onbTabManagement => 'Gestión';

  @override
  String get onbTabOrg => 'Org';

  @override
  String get onbTabProfile => 'Perfil';

  @override
  String get onbTabChat => 'Chat';

  @override
  String get onbTabFeed => 'Feed';

  @override
  String get onbTabWebsite => 'Sitio web';

  @override
  String get onbTabFallback => 'Pestaña';

  @override
  String get onbTabAdd => 'Agregar pestaña';

  @override
  String get onbTabExampleTitle => 'Pestañas de ejemplo';

  @override
  String get onbInboxRegisterTitle => 'REGISTRAR INBOX ID';

  @override
  String get onbInboxRegisterSubtitle =>
      'Registra esta bandeja en tu perfil en la cadena.';

  @override
  String get onbInboxHint => 'principal, trabajo, …';

  @override
  String get onbInboxRegister => 'REGISTRAR';

  @override
  String get actionCancel => 'CANCELAR';

  @override
  String get domainStoreTitle => 'Tienda de dominios';

  @override
  String get domainChecking => 'Comprobando…';

  @override
  String get domainLifetimeStatus => 'De por vida: tu dominio nunca caduca';

  @override
  String get domainNotSet => 'Aún sin configurar';

  @override
  String get domainWasDue => 'Venció';

  @override
  String get domainPaidUntilLabel => 'Pagado hasta';

  @override
  String get domainYourDomain => 'TU DOMINIO';

  @override
  String get domainGraceNote =>
      'Renueva para conservar tu nombre y tu acceso de escritura. Estás en el periodo de gracia, así que sigue siendo tuyo por ahora.';

  @override
  String get domainBadgeLifetime => 'DE POR VIDA';

  @override
  String get domainBadgeOverdue => 'VENCIDO';

  @override
  String get domainBadgeActive => 'ACTIVO';

  @override
  String get domainSearchHint => 'Busca un nombre…';

  @override
  String get domainStatusAvailable => 'Disponible para reclamar';

  @override
  String get domainStatusLapsed => 'El titular caducó: reclamable';

  @override
  String get domainStatusTaken => 'Ocupado';

  @override
  String get domainStatusCooldown => 'En espera';

  @override
  String get domainStatusYours => 'Este es tu nombre';

  @override
  String get domainFreeForYou => 'Gratis para ti';

  @override
  String get domainCalculating => 'Calculando…';

  @override
  String get domainLifetimeNeverExpires => 'De por vida: nunca caduca';

  @override
  String get domainName => 'Nombre';

  @override
  String domainChars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres',
      one: '1 carácter',
    );
    return '$_temp0';
  }

  @override
  String get domainSubtotal => 'Subtotal';

  @override
  String get domainDiscount => 'Descuento *';

  @override
  String get domainTotal => 'Total';

  @override
  String get domainBalance => 'Saldo';

  @override
  String get domainBalanceAfter => 'Saldo después';

  @override
  String get domainNotEnoughPosNote =>
      'No tienes suficientes OX en tu billetera para esto.';

  @override
  String domainNameTooShort(int min) {
    return 'Al menos $min caracteres';
  }

  @override
  String domainNameTooLong(int max) {
    return 'Hasta $max caracteres';
  }

  @override
  String get domainNameStartLetter => 'Debe empezar con una letra';

  @override
  String get domainNameEndDashUnderscore => 'No puede terminar en - o _';

  @override
  String get domainNameAllowed => 'Permitido: a–z 0–9 - _';

  @override
  String get domainNameNoConsecDash => 'Sin -- consecutivos';

  @override
  String get domainNameNoConsecUnderscore => 'Sin __ consecutivos';

  @override
  String get domainMonths => 'Meses';

  @override
  String get domainRenewed => 'Dominio renovado';

  @override
  String get domainClaimed => 'Nombre reclamado';

  @override
  String get domainEnterValidName => 'INGRESA UN NOMBRE VÁLIDO';

  @override
  String get domainBtnChecking => 'COMPROBANDO…';

  @override
  String get domainBtnYourName => 'ESTE ES TU NOMBRE';

  @override
  String get domainBtnNotEnoughPos => 'OX INSUFICIENTES';

  @override
  String get domainBtnRenew => 'RENOVAR';

  @override
  String get domainBtnNameTaken => 'NOMBRE OCUPADO';

  @override
  String get domainBtnOnCooldown => 'EN ESPERA';

  @override
  String get domainBtnRenewFirst => 'RENUEVA TU DOMINIO PRIMERO';

  @override
  String get domainBtnNoFreeChange => 'SIN CAMBIOS GRATIS';

  @override
  String get domainBtnClaim => 'RECLAMAR';

  @override
  String get domainBtnSaving => 'GUARDANDO EN LA CADENA…';

  @override
  String get domainBtnCancel => 'CANCELAR';

  @override
  String get domainBtnClaimIt => 'RECLAMARLO';

  @override
  String get domainNoteLifetime =>
      'De por vida: tu dominio nunca caduca, así que no hay nada que renovar ni meses que elegir.';

  @override
  String domainNoteFreeCitizenChar(int min) {
    return 'Gratis para ti como ciudadano en un nombre de $min+ caracteres.';
  }

  @override
  String get domainNoteFreeCitizen => 'Gratis para ti como ciudadano.';

  @override
  String get domainNoteFreeAnnual =>
      'Este cambio es gratis: usa tu cambio de nombre gratuito anual.';

  @override
  String domainNoteFreeBonus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boletos de cambio de nombre',
      one: '1 boleto de cambio de nombre',
    );
    return 'Este cambio es gratis: gasta 1 de tus $_temp0.';
  }

  @override
  String domainNoteNoFreeUntil(String date) {
    return 'Ya usaste tu cambio gratuito anual y no tienes boletos de bono, así que este cambio gratis no estará disponible hasta $date. Ganas un boleto cada vez que obtienes la ciudadanía.';
  }

  @override
  String get domainNoteFlatFee =>
      'Pago único: como ciudadano este nombre es tuyo de por vida, sin renovaciones. El 98% de lo que pagas se quema y el 2% financia las Utilidades.';

  @override
  String domainNoteFlatFeeNextFree(String date) {
    return 'Pago único: como ciudadano este nombre es tuyo de por vida, sin renovaciones. Tu próximo cambio gratis se abre el $date.';
  }

  @override
  String domainNoteDiscount(String pct) {
    return '* Paga por adelantado más meses para un mayor descuento: alrededor de $pct% menos por cada mes extra, hasta un tope. El 98% de lo que pagas se quema y el 2% financia las Utilidades.';
  }

  @override
  String domainConfirmBecomes(String name) {
    return 'Tu cuenta se convierte en \"$name\". ';
  }

  @override
  String domainConfirmCurrentFreed(String name) {
    return 'Tu nombre actual \"$name\" queda libre (30 días de espera si eres ciudadano).';
  }

  @override
  String get domainConfirmOldFreed =>
      'Tu nombre anterior queda libre (30 días de espera si eres ciudadano).';

  @override
  String get domainConfirmEvicts =>
      'El dominio del titular actual caducó, así que reclamarlo lo desaloja a un nombre basura.';

  @override
  String get domainConfirmFree => 'Gratis para ti.';

  @override
  String domainConfirmCost(String cost) {
    return 'Costo: $cost  ·  98% quemado, 2% a las Utilidades.';
  }

  @override
  String domainConfirmTitle(String name) {
    return 'Reclamar \"$name\"';
  }

  @override
  String get dlgCancel => 'Cancelar';

  @override
  String get dlgOk => 'OK';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get keychainTitle => 'Llavero';

  @override
  String get keychainGroupTitle => 'Llavero del grupo';

  @override
  String get keychainSubtitle =>
      'Administra tus llaves de mensajería y de la billetera';

  @override
  String keychainGroupSubtitle(String name) {
    return 'Administrando las llaves de $name';
  }

  @override
  String get keychainGenTitle => 'Generar nueva llave';

  @override
  String get keychainGenGroupTitle => 'Generar nueva llave de grupo';

  @override
  String get keychainKeyLabel => 'Etiqueta de la llave';

  @override
  String get keychainKeyLabelHint => 'Escribe una etiqueta para esta llave';

  @override
  String get keychainGenExplain =>
      'Vas a generar una llave nueva. Se guarda solo en este dispositivo. Esto no la registra como sesión ni activa los mensajes.';

  @override
  String get keychainGenEmojiHint => 'Toca para elegir un emoji';

  @override
  String get keychainGenerate => 'Generar';

  @override
  String get keychainImport => 'Importar';

  @override
  String get keychainKeyCreated => 'Llave creada';

  @override
  String get keychainRecoveryTitle => 'FRASE DE RECUPERACIÓN';

  @override
  String get keychainRecoveryWarning =>
      'Anota estas 12 palabras. Es la única forma de recuperar tu llave. Guárdalas sin conexión. Nunca las compartas.';

  @override
  String get keychainDeleteTitle => 'Eliminar llave';

  @override
  String keychainDeleteConfirm(String label) {
    return '¿Seguro que quieres eliminar la llave \"$label\"? Esta acción no se puede deshacer.';
  }

  @override
  String get keychainDelete => 'Eliminar';

  @override
  String get keychainKeyDeleted => 'Llave eliminada correctamente';

  @override
  String get keychainDeleteLoadedTitle => 'Llave cargada en XMTP';

  @override
  String keychainDeleteLoadedBody(Object label) {
    return '\"$label\" es la llave con la que funcionan tus mensajes ahora mismo. Eliminarla cierra la mensajería en este dispositivo. ¿Seguro que quieres eliminarla?';
  }

  @override
  String get keychainDeleteContinue => 'CONTINUAR';

  @override
  String get keychainDeleteLoadedPhraseTitle =>
      '¿Guardaste la frase de recuperación?';

  @override
  String get keychainDeleteLoadedPhraseBody =>
      'Sin la frase o la llave privada, esta llave y los mensajes ligados a ella no se pueden recuperar. Esto no se puede deshacer.';

  @override
  String get keychainKeyDeletedUnloaded =>
      'Llave eliminada. La mensajería queda apagada hasta que elijas una llave.';

  @override
  String get keychainAddressCopied => 'Dirección copiada al portapapeles';

  @override
  String get keychainPrivKeyNotFound => 'No se encontró la llave privada';

  @override
  String get keychainImportTitle => 'Importar llave';

  @override
  String get keychainImportGroupTitle => 'Importar llave de grupo';

  @override
  String get keychainImportSubtitle =>
      'Importa con la frase mnemónica o la llave privada';

  @override
  String get keychainEnterLabelTitle => 'Escribe la etiqueta de la llave';

  @override
  String get keychainImportLabelHint =>
      'Escribe una etiqueta para esta llave importada';

  @override
  String get keychainDbMismatchTitle => 'Existen mensajes locales';

  @override
  String keychainDbMismatchBody(String wallet) {
    return 'Este dispositivo tiene mensajes en caché para la billetera $wallet... de una sesión anterior, pero la llave de cifrado ya no coincide.\n\nPara continuar con la importación, se borrarán los mensajes locales de esta llave. Los mensajes en la red XMTP no se ven afectados.';
  }

  @override
  String get keychainEraseContinue => 'Borrar y continuar';

  @override
  String get keychainInstallCapTitle => 'Límite de dispositivos alcanzado';

  @override
  String keychainInstallCapBody(String wallet) {
    return 'Esta llave ya tiene 10 dispositivos XMTP registrados: el máximo del protocolo. Para usarla aquí, primero hay que revocar registros de dispositivos anteriores.\n\nBilletera: $wallet...';
  }

  @override
  String get keychainInstallCapRevokeAll =>
      'Revocar todos los demás dispositivos';

  @override
  String get keychainInstallCapRevokeAllDetail =>
      'Recuperación rápida: se revocan TODOS los registros existentes de esta llave y se reintenta la importación. Cualquier otro dispositivo o app que use esta llave dejará de enviar y recibir hasta que vuelvas a iniciar sesión ahí.';

  @override
  String get keychainInstallCapSelective =>
      'Revocar selectivamente en otro dispositivo';

  @override
  String get keychainInstallCapSelectiveDetail =>
      'Abre la app en otro dispositivo donde esta llave aún funcione, ve a Administrar Inbox IDs y revoca dispositivos individuales ahí. Después reintenta la importación aquí.';

  @override
  String get keychainInstallCapConfirmTitle =>
      '¿Revocar todos los demás dispositivos?';

  @override
  String get keychainInstallCapConfirmBody =>
      'Esto firma una revocación para todos los demás registros de esta llave y no se puede deshacer. ¿Continuar?';

  @override
  String keychainInstallCapRevokeFailed(String error) {
    return 'No se pudieron revocar los demás dispositivos: $error';
  }

  @override
  String get keychainSetupHint =>
      '¿Estás cargando una llave que ya usaste en otro dispositivo y tienes su respaldo de mensajes? Restauráralo aquí. Si esta llave es nueva, no hay nada que restaurar — empieza de cero.';

  @override
  String get keychainOfferRegTitle => '¿PUBLICAR ESTA BANDEJA?';

  @override
  String keychainOfferRegBody(String id) {
    return 'Esta llave está activa y tiene un Inbox ID ($id). Publicalo como pestaña en tu perfil para que la gente pueda escribirte.';
  }

  @override
  String get keychainOfferRegLabel => 'Nombre de la pestaña';

  @override
  String get keychainOfferRegDontAsk => 'No volver a preguntar';

  @override
  String get keychainOfferRegPublish => 'PUBLICAR';

  @override
  String get keychainOfferRegLater => 'AHORA NO';

  @override
  String get appSettingsPageInboxPromptTitle =>
      'Ofrecer publicar bandejas nuevas';

  @override
  String get appSettingsPageInboxPromptSubtitle =>
      'Después de activar una llave, preguntar si se publica su Inbox ID como pestaña del perfil.';

  @override
  String get keychainSetupTitle => 'Configurar mensajería en este dispositivo';

  @override
  String get keychainSetupBody =>
      'Esta llave aún no tiene base de datos de mensajes en este dispositivo. Elige cómo configurarla:';

  @override
  String get keychainSetupCreateFresh => 'Empezar de cero';

  @override
  String get keychainSetupCreateFreshDetail =>
      'Registra este dispositivo con la llave e inicia un historial de mensajes nuevo y vacío. Usa uno de los 10 espacios de dispositivo de la llave.';

  @override
  String get keychainSetupRestore => 'Restaurar una copia';

  @override
  String get keychainSetupRestoreDetail =>
      'Carga un archivo de base de datos que descargaste de otro dispositivo, junto con su llave de cifrado. Conserva tu historial de mensajes y no usa un espacio de dispositivo.';

  @override
  String get keychainRestoreTitle => 'Restaurar copia de la base de datos';

  @override
  String get keychainRestoreFileTypeLabel => 'Base de datos XMTP';

  @override
  String get keychainRestoreKeyPrompt =>
      'Pega la llave de cifrado de la base de datos del dispositivo donde hiciste la copia.';

  @override
  String get keychainRestoreKeyHint => 'Llave de cifrado';

  @override
  String get keychainRestoreFailedTitle => 'Falló la restauración';

  @override
  String keychainClientReloaded(String label) {
    return 'Cliente recargado con la llave \"$label\"';
  }

  @override
  String get keychainInboxAlreadyReg => 'Este Inbox ID ya está registrado';

  @override
  String get keychainRegInboxTitle => 'Registrar el Inbox ID actual';

  @override
  String keychainRegInboxPrompt(String id) {
    return 'Escribe una etiqueta para este Inbox ID: $id';
  }

  @override
  String get keychainLabelField => 'Etiqueta';

  @override
  String get keychainEnterLabelPlease => 'Escribe una etiqueta';

  @override
  String get keychainRegister => 'Registrar';

  @override
  String get keychainInboxRegOther =>
      'Este Inbox ID ya está registrado en otra cuenta';

  @override
  String get keychainInboxRegOk => 'Inbox ID registrado correctamente';

  @override
  String get keychainInboxRegFail => 'No se pudo registrar el Inbox ID';

  @override
  String get keychainEditTitle => 'Editar la etiqueta de la llave';

  @override
  String get keychainEditHint => 'Escribe una nueva etiqueta para esta llave';

  @override
  String get keychainSave => 'Guardar';

  @override
  String get keychainLabelUpdated =>
      'Etiqueta de la llave actualizada correctamente';

  @override
  String keychainWalletEnabled(String label) {
    return 'Billetera activada para \"$label\"';
  }

  @override
  String keychainWalletDisabled(String label) {
    return 'Billetera desactivada para \"$label\"';
  }

  @override
  String keychainWebKeySet(String name) {
    return 'Llave preferida establecida en \"$name\"';
  }

  @override
  String get keychainSessionKey => 'Llave de la sesión';

  @override
  String keychainEmojiUpdated(String label) {
    return 'Emoji actualizado para \"$label\"';
  }

  @override
  String keychainCopyTooltip(String label) {
    return 'Copiar $label';
  }

  @override
  String get keychainNoKeys => 'No hay llaves adicionales';

  @override
  String get keychainActivateHint =>
      'Toca el ícono SIM de una llave para usarla en la mensajería.';

  @override
  String get keychainMyAccount => 'Mi cuenta';

  @override
  String get keychainSessionBadge => 'SESIÓN';

  @override
  String get keychainSessionKeyUnavail =>
      'La llave de la sesión no está disponible';

  @override
  String get keychainUnnamedKey => 'Llave sin nombre';

  @override
  String get keychainUnknownAddr => 'Desconocida';

  @override
  String get keychainToggleXmtpKey => 'Llave XMTP actual';

  @override
  String get keychainToggleXmtpSub =>
      'Usa esta llave para enviar y recibir mensajes cifrados. Solo una llave a la vez puede estar activa para la mensajería.';

  @override
  String get keychainToggleWebKey => 'Llave preferida';

  @override
  String get keychainToggleWebSub =>
      'Los sitios que no tienen una llave activa propia ven esta primero — la cuenta que la mayoría de las dApps toman como tú. No le da acceso a ningún sitio por sí sola; eso se decide sitio por sitio, donde también puedes elegir otra llave activa.';

  @override
  String get keychainToggleWallet => 'Mostrar en la lista de la billetera';

  @override
  String get keychainToggleWalletSub =>
      'Incluye esta llave en el filtro Llavero de la pestaña Billetera, para que puedas enviar directamente desde ella.';

  @override
  String get keychainActionEmoji => 'Cambiar emoji';

  @override
  String get keychainActionEmojiSub =>
      'Elige un nuevo ícono para reconocer esta llave de un vistazo.';

  @override
  String get keychainActionRename => 'Cambiar la etiqueta';

  @override
  String get keychainActionRenameSub =>
      'La etiqueta es solo un apodo local; la llave y la dirección no cambian.';

  @override
  String get keychainActionExport => 'Exportar la llave privada';

  @override
  String get keychainActionExportSub =>
      'Muestra el hex en bruto para que puedas importar esta llave en otro cliente. Trátalo como una contraseña.';

  @override
  String get keychainActionDelete => 'Eliminar llave';

  @override
  String get keychainActionDeleteSub =>
      'Elimina esta llave de este dispositivo de forma permanente. Asegúrate de tener un respaldo primero.';

  @override
  String get importModePhrase => 'FRASE';

  @override
  String get importModePrivateKey => 'LLAVE PRIVADA';

  @override
  String get importHintMnemonic => 'palabra1 palabra2 palabra3 palabra4 ...';

  @override
  String get importLabelMnemonic =>
      'Escribe tu frase de recuperación de 12 o 24 palabras';

  @override
  String get importLabelPrivateKey =>
      'Escribe la llave privada como cadena hexadecimal';

  @override
  String get importEnterMnemonic => 'Escribe una frase mnemónica';

  @override
  String get importEnterPrivateKey => 'Escribe una llave privada';

  @override
  String get importImporting => 'IMPORTANDO...';

  @override
  String netPickHeader(String provider) {
    return 'ELIGE UN $provider';
  }

  @override
  String get netPickBspTitle => 'Elige un Proveedor de Servicios de Blockchain';

  @override
  String get netPickSspTitle => 'Elige un Proveedor de Servicios Sociales';

  @override
  String get netPickBspBody =>
      'Toca uno. La siguiente hoja confirma la suscripción; como privado puedes depositar tus primeros meses en tu saldo de servicios en la misma transacción.';

  @override
  String get netPickSspBody =>
      'Toca uno. La siguiente hoja confirma la suscripción; como privado puedes depositar tus primeros meses en tu saldo de servicios en la misma transacción.';

  @override
  String netNoProviders(String provider) {
    return 'No hay $provider disponibles en el registro.';
  }

  @override
  String netSwitchHeader(String provider) {
    return 'CAMBIAR $provider';
  }

  @override
  String netSubscribeHeader(String provider) {
    return 'SUSCRIBIRSE A $provider';
  }

  @override
  String get netSwitching => 'CAMBIANDO…';

  @override
  String get netSubscribing => 'SUSCRIBIENDO…';

  @override
  String get netSwitch => 'CAMBIAR';

  @override
  String get netSubscribe => 'SUSCRIBIRSE';

  @override
  String get netProviderNotFound => 'Proveedor no encontrado';

  @override
  String netSlugUnresolved(String slug, String provider) {
    return 'El slug \"$slug\" no corresponde a ningún $provider registrado.';
  }

  @override
  String netProviderFee(String provider) {
    return 'Tarifa $provider';
  }

  @override
  String get netTotal => 'Total';

  @override
  String get netCalculating => 'Calculando…';

  @override
  String get netBalance => 'Saldo';

  @override
  String get netFromWallet => 'Desde la billetera';

  @override
  String netMainWallet(String addr) {
    return 'principal · $addr';
  }

  @override
  String get netInsufficientPos =>
      'Saldo de OX insuficiente para este depósito.';

  @override
  String get netGateWaived =>
      'Este proveedor aún no llega a su mínimo de suscriptores, así que no se toma nada de tu saldo hasta que lo alcance. Lo que depositas sigue siendo tuyo — retíralo cuando quieras desde Servicios.';

  @override
  String get netServerRulesTitle => 'Reglas de este servidor';

  @override
  String get netServerPrivacyTitle => 'Privacidad';

  @override
  String netServerRulesVersion(Object version, Object date) {
    return 'Versión $version · desde $date';
  }

  @override
  String get netServerRulesAccept =>
      'Suscribirte significa que leíste y aceptas el acuerdo del protocolo y las reglas de este servidor.';

  @override
  String get netServerRulesMissing =>
      'Este servidor no ha publicado sus reglas. Aun así puedes suscribirte.';

  @override
  String get netServerRulesUnreachable =>
      'No se pudieron cargar las reglas de este servidor en este momento. Aun así puedes suscribirte.';

  @override
  String get netServerRulesAcceptButton => 'Aceptar y suscribirme';

  @override
  String get netServerRulesSubscribeAnyway => 'Suscribirme de todos modos';

  @override
  String get netNoSession => 'No hay una sesión activa';

  @override
  String get netRunBy => 'Operado por';

  @override
  String get netMonths => 'Meses';

  @override
  String get netCardUrl => 'URL';

  @override
  String get netCardRunBy => 'OPERADO POR';

  @override
  String get netCardSubs => 'SUSCR.';

  @override
  String netSubsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suscriptores',
      one: '1 suscriptor',
    );
    return '$_temp0';
  }

  @override
  String netExplainCitizenSwitch(String provider) {
    return 'Esto cambia tu $provider asignado, con efecto inmediato. No pagas nada — la red acuña la tarifa del $provider por ti mientras uses la app.';
  }

  @override
  String netExplainCitizenSubscribe(String provider) {
    return 'Esto fija tu $provider asignado. Los ciudadanos no pagan; la red acuña la tarifa del $provider por ti mientras uses la app.';
  }

  @override
  String netExplainPrivateSwitch(String provider) {
    return 'Esto te cambia a un nuevo $provider, con efecto inmediato — al anterior se le paga hasta el segundo, nada se queda atrapado. La tarifa sigue tomándose de tu único saldo de servicios; los meses de abajo son una recarga opcional.';
  }

  @override
  String netExplainPrivateSubscribe(String provider) {
    return 'Esto te suscribe a este $provider. La tarifa corre segundo a segundo y se toma de tu saldo de servicios solo mientras el proveedor tenga suficientes suscriptores para cobrar; los meses de abajo se depositan en ese saldo ahora y son tuyos para retirar mientras no se gasten.';
  }

  @override
  String get walletAddressCopied => 'Dirección copiada al portapapeles';

  @override
  String get walletSettingsTitle => 'Ajustes de billetera';

  @override
  String get walletManagerLabel => 'GESTOR DE BILLETERA';

  @override
  String get walletSelectManagerTitle => 'Elige gestor de billetera';

  @override
  String get walletNoManagerApps =>
      'No tienes apps de gestor de billetera guardadas.\nGuarda una app con la categoría \"wallet_manager\" para usarla aquí.';

  @override
  String get walletEditLabel => 'Editar etiqueta';

  @override
  String get walletEditIcon => 'Editar ícono';

  @override
  String get walletActivityTitle => 'Actividad';

  @override
  String get walletActivityEmpty =>
      'Aún no hay transacciones.\nLas transferencias recientes de OX aparecerán aquí.';

  @override
  String get walletActivityTxCopied => 'Hash de transacción copiado';

  @override
  String get walletActivitySentTo => 'Enviado a';

  @override
  String get walletActivityReceivedFrom => 'Recibido de';

  @override
  String get walletRemoveWallet => 'Quitar billetera';

  @override
  String get walletLabelHint => 'Etiqueta de la billetera';

  @override
  String get walletSave => 'Guardar';

  @override
  String get walletLabelUpdateFailed => 'No se pudo actualizar la etiqueta';

  @override
  String get walletLabelUpdateSubmitted => 'Actualización de etiqueta enviada';

  @override
  String get walletRemoveWalletConfirmTitle => '¿Quitar billetera?';

  @override
  String get walletRemoveWalletBodyNoLabel =>
      'Esta billetera se quitará de tu directorio.';

  @override
  String walletRemoveWalletBody(String label) {
    return '\"$label\" se quitará de tu directorio.';
  }

  @override
  String get walletRemove => 'Quitar';

  @override
  String get walletRemoveFailed => 'No se pudo quitar la billetera';

  @override
  String get walletRemoved => 'Billetera quitada';

  @override
  String get walletChipLinked => 'Vinculadas';

  @override
  String get walletChipGroup => 'Grupo';

  @override
  String get walletChipManageKeys => 'Gestionar llaves';

  @override
  String get walletChipSettings => 'Ajustes';

  @override
  String get walletEmptyTitle => 'No se encontraron billeteras';

  @override
  String get walletEmptySubtitle => 'Tus billeteras aparecerán aquí.';

  @override
  String get walletLinkNewWallet => 'Vincular nueva billetera';

  @override
  String get walletBadgePrimary => 'PRINCIPAL';

  @override
  String get walletBadgeGroup => 'GRUPO';

  @override
  String get walletBadgeKey => 'LLAVE';

  @override
  String get walletBadgeLinked => 'VINCULADA';

  @override
  String get walletUnlink => 'Desvincular';

  @override
  String get walletActionSend => 'Enviar';

  @override
  String get walletActionCopy => 'Copiar';

  @override
  String get walletActionManage => 'Gestionar';

  @override
  String get walletOwnerUnknown => 'Desconocido';

  @override
  String get walletNoManagerSelected => 'Sin gestor de billetera seleccionado';

  @override
  String get walletSelect => 'Elegir';

  @override
  String get walletChange => 'Cambiar';

  @override
  String walletChainLinkingComingSoon(String chain) {
    return 'Vincular $chain llegará pronto.';
  }

  @override
  String get walletConnectHeader => 'Conectar';

  @override
  String get walletLabelRequired => 'Etiqueta · obligatoria';

  @override
  String walletChainDetected(String chain) {
    return '$chain detectado';
  }

  @override
  String get walletPickKeyError =>
      'Elige una llave de billetera para vincular.';

  @override
  String get walletNoActiveAccount => 'No hay cuenta activa.';

  @override
  String get walletLinked => 'Billetera vinculada';

  @override
  String get walletPasteProofError =>
      'Pega la prueba desde la página de firma.';

  @override
  String get walletInvalidProofError =>
      'Eso no parece una prueba válida. Copia toda la “prueba para PublicOS” desde la página de firma.';

  @override
  String get walletProofMissingWalletSig =>
      'A la prueba le falta la billetera o la firma.';

  @override
  String get walletProofWrongAccount =>
      'Esta prueba se firmó para otra cuenta. Vuelve a firmar para esta cuenta.';

  @override
  String get walletProofBadBase58 => 'La firma no es base58 válido.';

  @override
  String get walletProofVerifyFailed =>
      'Esta prueba no se verificó para tu cuenta. Asegúrate de haber firmado para esta cuenta en la página de vinculación.';

  @override
  String get walletSolanaLinked => 'Billetera Solana vinculada';

  @override
  String get walletProofMissingFields =>
      'A la prueba le falta la billetera, la firma o la fecha límite.';

  @override
  String get walletProofMalformed => 'La prueba está mal formada.';

  @override
  String get walletInvalidProofBundle =>
      'Eso no parece un paquete de prueba válido.';

  @override
  String get walletProofNotEthereum =>
      'Esa prueba no es de una billetera Ethereum.';

  @override
  String get walletLinkWithoutLabelTitle => '¿Vincular billetera sin etiqueta?';

  @override
  String get walletLinkWithoutLabelBody =>
      'Una etiqueta te ayuda a distinguir esta billetera de las demás. Puedes añadir una más tarde.';

  @override
  String get walletLink => 'Vincular';

  @override
  String get walletLinkWalletTitle => 'Vincular billetera';

  @override
  String get walletLinkExplainer =>
      'Vincular publica on-chain un puntero que declara que una billetera es tuya. Así otros pueden elegir una de tus cuentas para enviarte fondos, y lo que posees puede aparecer en tu perfil: tokens, y los NFTs con los que la cadena registra la propiedad. Sigue siendo solo un puntero. El protocolo nunca obtiene acceso a la billetera.';

  @override
  String get walletLabelOptional => 'ETIQUETA (opcional)';

  @override
  String get walletLabelExampleHint =>
      'p. ej. Coinbase, Almacenamiento en frío';

  @override
  String get walletLinkingAction => 'VINCULANDO…';

  @override
  String get walletLinkWalletAction => 'VINCULAR BILLETERA';

  @override
  String get walletSignOnBrowser => 'Firmar en el navegador';

  @override
  String get walletHidePaste => 'Ocultar pegado';

  @override
  String get walletPasteProof => 'Pegar prueba';

  @override
  String get walletPasteBundleHint =>
      'Pega el paquete de prueba desde la página de firma';

  @override
  String get walletLinking => 'Vinculando...';

  @override
  String get walletLinkPastedProof => 'Vincular prueba pegada';

  @override
  String get walletNoKeychainKeys =>
      'No hay llaves del llavero para vincular aquí. Usa \"Vincular con MetaMask\" arriba para vincular una billetera externa, o añade una llave a tu llavero primero.';

  @override
  String get walletKeyLabel => 'LLAVE DE BILLETERA';

  @override
  String get walletKeyDefault => 'Llave';

  @override
  String get walletPasteProofLabel => 'PEGAR PRUEBA';

  @override
  String get walletPasteProofBundleHint =>
      'Pega el paquete de la “prueba para PublicOS”';

  @override
  String get walletOpenPhantom => 'Abrir Phantom';

  @override
  String get walletLinkMetaMask => 'Vincular con MetaMask';

  @override
  String get walletOr => 'o';

  @override
  String get walletCouldNotOpenPhantom =>
      'No se pudo abrir Phantom. ¿Está instalada?';

  @override
  String get walletDirectoryNotReady =>
      'El directorio de billeteras no está listo, inténtalo de nuevo.';

  @override
  String get walletCouldNotOpenLinkingPage =>
      'No se pudo abrir la página de vinculación';

  @override
  String get walletCouldNotOpenMetaMask =>
      'No se pudo abrir MetaMask. ¿Está instalada?';

  @override
  String walletChainComingSoonLong(String chain) {
    return 'Vincular $chain llegará pronto. El directorio ya lo admite on-chain — el flujo de firma en la app llega después de EVM.';
  }

  @override
  String get acctSettingsSavingColor => 'Guardando color...';

  @override
  String get acctSettingsRefreshingProfile => 'Actualizando perfil...';

  @override
  String get acctSettingsSessionAddressLabel => 'Dirección de la sesión';

  @override
  String acctSettingsCopiedToClipboard(String label) {
    return 'Se copió $label al portapapeles';
  }

  @override
  String get acctSettingsRecoveryContacts => 'Contactos de recuperación';

  @override
  String get acctSettingsDevices => 'Sesiones';

  @override
  String get acctSettingsAccentColor => 'Color de acento';

  @override
  String get accentColorRecordNotice =>
      'Tu color de acento es un registro público de tu perfil, guardado en la cadena. Tiñe las burbujas de tus mensajes y rellena las tarjetas de tu perfil, así que cualquiera que vea tu perfil puede verlo.';

  @override
  String get accentColorBubbleNotice =>
      'Tus burbujas de mensaje se pintan con él exactamente como lo eliges. El texto alterna entre negro y blanco para seguir siendo legible.';

  @override
  String get accentColorPreviewSample => 'Así se verán tus mensajes.';

  @override
  String get accentColorPreviewTime => '12:45';

  @override
  String get accentColorSave => 'GUARDAR COLOR';

  @override
  String get accentColorDiscard => 'DESCARTAR';

  @override
  String get accentColorSaved => 'Color de acento guardado';

  @override
  String get accentColorUnsaved => 'Sin guardar';

  @override
  String get acctSettingsNoAccountSelected => 'Ninguna cuenta seleccionada';

  @override
  String get acctSettingsNoRecoveryContacts =>
      'No hay contactos de recuperación configurados';

  @override
  String get acctSettingsAddTrustedContactsHint =>
      'Agrega contactos de confianza que puedan ayudarte a recuperar tu cuenta';

  @override
  String acctSettingsRecoveryThreshold(int threshold, int total) {
    return 'Umbral de recuperación: $threshold/$total contactos necesarios para aprobar la recuperación';
  }

  @override
  String get acctSettingsNoSessionsFound => 'No se encontraron sesiones';

  @override
  String get acctSettingsSessionsDescShort =>
      'Las sesiones son direcciones de billetera autorizadas para controlar tu cuenta';

  @override
  String get acctSettingsSessionsInfoBanner =>
      'Las sesiones son llaves que pueden actuar como tu cuenta. Cada teléfono, computadora o billetera que usas tiene la suya.';

  @override
  String get acctSettingsCurrentBadge => 'ACTUAL';

  @override
  String get acctSettingsThisDevice => 'Esta sesión';

  @override
  String get acctSettingsAuthorizedDevice => 'Sesión';

  @override
  String get acctSettingsCannotRemoveSession =>
      'No se puede eliminar: se requiere al menos una sesión';

  @override
  String get acctSettingsAddingConfirming => 'AGREGANDO Y CONFIRMANDO…';

  @override
  String get acctSettingsAddSession => 'AGREGAR SESIÓN';

  @override
  String get acctSettingsAddNewSession => 'Agregar nueva sesión';

  @override
  String get acctSettingsLinkNewDeviceTitle => 'Agregar una sesión';

  @override
  String get acctSettingsLinkNewDeviceBody =>
      'En el otro teléfono o computadora, abre PublicOS, toca el botón QR en la tarjeta de la llave nueva, elige AGREGAR SESIÓN y firma. Luego escanea ese QR con esta cámara; la hoja de confirmación se abre sola.';

  @override
  String get acctSettingsWhyQrTitle => '¿Por qué un QR?';

  @override
  String get acctSettingsWhyQrBody =>
      'La nueva sesión demuestra que aceptó ser agregada firmando un consentimiento EIP-712 con su propia llave. El QR trae esa firma hasta aquí para que la envíes desde una sesión que ya tienes.';

  @override
  String get acctSettingsRemoveSessionTitle => 'Eliminar sesión';

  @override
  String get acctSettingsRemoveSessionConfirm =>
      '¿Seguro que quieres eliminar esta sesión?';

  @override
  String get acctSettingsRemoveSessionWarning =>
      'Esta sesión ya no podrá actuar como tu cuenta.';

  @override
  String get acctSettingsRemove => 'Eliminar';

  @override
  String get acctSettingsSessionRemoved =>
      '¡Sesión eliminada y confirmada en la blockchain!';

  @override
  String get acctSettingsAddRecoveryContact =>
      'AGREGAR CONTACTO DE RECUPERACIÓN';

  @override
  String get acctSettingsRecoveryContactAdded =>
      '¡Contacto de recuperación agregado y confirmado en la blockchain!';

  @override
  String get acctSettingsRemoveRecoveryTitle =>
      'Eliminar contacto de recuperación';

  @override
  String acctSettingsRemoveRecoveryConfirm(String address) {
    return '¿Seguro que quieres eliminar este contacto de recuperación?\n\nDirección: $address\n\nYa no podrá ayudarte a recuperar tu cuenta.';
  }

  @override
  String get acctSettingsRecoveryContactRemoved =>
      '¡Contacto de recuperación eliminado y confirmado en la blockchain!';

  @override
  String get acctSettingsAddRecoveryContactTitle =>
      'Agregar contacto de recuperación';

  @override
  String get acctSettingsAddRecoveryIntro =>
      'Estás a punto de agregar este contacto como contacto de recuperación de tu cuenta:';

  @override
  String get acctSettingsRecoveryPermissionsTitle =>
      'Permisos del contacto de recuperación';

  @override
  String get acctSettingsRecoveryPermissionsBody =>
      'Este contacto podrá:\nVotar para agregar nuevas direcciones de sesión a tu cuenta\nAyudarte a recuperar el acceso si pierdes tu dispositivo\nNo puede acceder a tus fondos ni mensajes directamente';

  @override
  String get acctSettingsSelectRecoveryContact =>
      'Seleccionar contacto de recuperación';

  @override
  String get acctSettingsChooseRecoveryContact =>
      'Elige un contacto de recuperación';

  @override
  String get acctSettingsChooseRecoveryDesc =>
      'Selecciona un contacto de confianza que pueda ayudarte a recuperar tu cuenta si pierdes el acceso. Podrá votar para agregar nuevas direcciones de sesión a tu cuenta.';

  @override
  String get acctSettingsSearchContacts => 'Buscar contactos…';

  @override
  String get acctSettingsNoContactsAvailable => 'No hay contactos disponibles';

  @override
  String get acctSettingsNoContactsFound => 'No se encontraron contactos';

  @override
  String get acctSettingsAddContactsFirst =>
      'Agrega algunos contactos primero para configurarlos como contactos de recuperación';

  @override
  String get acctSettingsErrorEnterAddress => 'Ingresa una dirección';

  @override
  String get acctSettingsErrorInvalidAddress =>
      'Formato de dirección Ethereum no válido';

  @override
  String get acctSettingsErrorAddressAlreadySession =>
      'Esta dirección ya es una sesión';

  @override
  String get acctSettingsWhatIsSessionTitle => '¿Qué es una sesión?';

  @override
  String get acctSettingsWhatIsSessionBody =>
      'Una sesión es una dirección de billetera autorizada para controlar tu cuenta. Agrega una nueva sesión para usar tu cuenta desde otro dispositivo o billetera.';

  @override
  String get acctSettingsEthereumAddressLabel => 'Dirección Ethereum';

  @override
  String get inboxIdsTitle => 'Inbox IDs';

  @override
  String get inboxIdsInboxesHeader => 'Inboxes';

  @override
  String get inboxIdsLoadError => 'No se pudieron cargar los Inbox IDs';

  @override
  String get inboxIdsRetry => 'REINTENTAR';

  @override
  String get inboxIdsEmptyTitle => 'Aún no hay Inbox IDs';

  @override
  String get inboxIdsEmptySubtitle =>
      'Crea una llave XMTP desde el llavero para comenzar.';

  @override
  String get inboxIdsNoLocalKeyTitle =>
      'No hay llave local en este dispositivo';

  @override
  String get inboxIdsNoLocalKeyBody =>
      'Este inbox está registrado en tu cuenta pero ninguna llave privada para él vive en este dispositivo, así que no podemos cargar identidades ni instalaciones. Importa la llave desde otro dispositivo (llavero o mnemónico) para gestionarlo aquí.';

  @override
  String get inboxIdsNotSetUpTitle => 'Sin configurar en este dispositivo';

  @override
  String get inboxIdsNotSetUpBody =>
      'Esta llave está en este dispositivo, pero no está configurada para mensajes aquí, así que su inbox no se puede mostrar. Selecciona la llave en el llavero para configurarla.';

  @override
  String get inboxIdsLinkedAccounts => 'Llaves vinculadas';

  @override
  String get inboxIdsInstallations => 'Instalaciones';

  @override
  String get inboxIdsQuickActions => 'Acciones rápidas';

  @override
  String get inboxIdsRecoveryBadge => 'RECUPERACIÓN';

  @override
  String get inboxIdsThisDeviceBadge => 'ESTE DISPOSITIVO';

  @override
  String get inboxIdsEthereumWallet => 'Billetera Ethereum';

  @override
  String get inboxIdsPasskey => 'Passkey';

  @override
  String get inboxIdsUnknown => 'Desconocido';

  @override
  String inboxIdsDaysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String inboxIdsHoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String inboxIdsMinutesAgo(int count) {
    return 'hace ${count}m';
  }

  @override
  String inboxIdsCreatedAgo(String time) {
    return 'Creado $time';
  }

  @override
  String get inboxIdsRegisterTitle => 'Registrar Inbox ID';

  @override
  String get inboxIdsRegisterSubtitle =>
      'Registra este inbox en tu perfil on-chain.';

  @override
  String get inboxIdsEditLabelTitle => 'Editar etiqueta';

  @override
  String get inboxIdsEditLabelSubtitle =>
      'Renombra este inbox en tu perfil on-chain.';

  @override
  String get inboxTabNoneYet => 'Aún no hay bandeja pública';

  @override
  String get inboxTabOtherOwner =>
      'Esta bandeja ya está registrada en otra cuenta.';

  @override
  String get inboxTabSaveFailed =>
      'No se pudo guardar. No se escribió nada en la cadena.';

  @override
  String inboxTabDuplicate(String name) {
    return 'Ya tienes una pestaña llamada $name';
  }

  @override
  String inboxTabMore(int count) {
    return '+$count más';
  }

  @override
  String get inboxIdsRemoveTooltip => 'Quitar pestaña';

  @override
  String get inboxIdsAddTooltip => 'Agregar pestaña';

  @override
  String get inboxIdsLabelHint => 'principal, trabajo, …';

  @override
  String get inboxIdsSave => 'GUARDAR';

  @override
  String get inboxIdsContinue => 'CONTINUAR';

  @override
  String get inboxIdsRemoveTitle => '¿Quitar Inbox ID?';

  @override
  String inboxIdsRemoveBody(String name) {
    return 'Quitar \"$name\" de tu perfil on-chain. Otros usuarios ya no verán este inbox listado en tu cuenta.';
  }

  @override
  String get inboxIdsRemoveAction => 'QUITAR';

  @override
  String get inboxIdsRevokeInstallationTitle => '¿Revocar esta instalación?';

  @override
  String inboxIdsRevokeInstallationBody(String id) {
    return 'Este dispositivo perderá acceso a los mensajes de este inbox.\n\n$id';
  }

  @override
  String get inboxIdsRevokeAction => 'REVOCAR';

  @override
  String get inboxIdsRevokeAllTitle =>
      '¿Revocar todas las demás instalaciones?';

  @override
  String inboxIdsRevokeAllBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Esto revocará el acceso de $count dispositivos más. Esos dispositivos deberán volver a autenticarse para recuperar el acceso.',
      one:
          'Esto revocará el acceso de otro dispositivo. Esos dispositivos deberán volver a autenticarse para recuperar el acceso.',
    );
    return '$_temp0';
  }

  @override
  String get inboxIdsRevokeAllAction => 'REVOCAR TODAS';

  @override
  String get inboxIdsRemoveAccountTitle => '¿Quitar cuenta del inbox?';

  @override
  String inboxIdsRemoveAccountBody(String id) {
    return 'Esto quita la cuenta de tu inbox.\n\n$id';
  }

  @override
  String get inboxIdsOfflineRecovery => 'Recuperación sin conexión';

  @override
  String get inboxIdsOfflineRecoveryBody =>
      'Esto revoca TODAS las instalaciones de este inbox sin necesitar un cliente XMTP activo. Úsalo cuando estés bloqueado por demasiadas instalaciones (límite: 10).\n\nNecesitarás proporcionar tu llave de recuperación.';

  @override
  String get inboxIdsConfirmRecoveryTitle => 'Confirmar recuperación';

  @override
  String inboxIdsConfirmRecoveryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Se encontraron $count instalaciones. Todas las instalaciones serán revocadas. Necesitarás volver a autenticarte en cualquier dispositivo que quieras usar.',
      one:
          'Se encontró 1 instalación. Todas las instalaciones serán revocadas. Necesitarás volver a autenticarte en cualquier dispositivo que quieras usar.',
    );
    return '$_temp0';
  }

  @override
  String inboxIdsRevokingInstallations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Revocando $count instalaciones…',
      one: 'Revocando 1 instalación…',
    );
    return '$_temp0';
  }

  @override
  String inboxIdsRevokedInstallations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se revocaron $count instalaciones',
      one: 'Se revocó 1 instalación',
    );
    return '$_temp0';
  }

  @override
  String get inboxIdsKeyAlreadyLinkedTitle => 'Llave ya vinculada';

  @override
  String get inboxIdsKeyAlreadyLinkedBodyKeychain =>
      'Esta llave ya está vinculada a otro inbox de XMTP. Si continúas, se moverá a tu inbox actual y podrías perder acceso al inbox anterior, a menos que tengas otra llave vinculada a él.';

  @override
  String get inboxIdsProceedAnyway => 'CONTINUAR DE TODOS MODOS';

  @override
  String get inboxIdsKeyAlreadyLinkedBodyImport =>
      'Esta llave ya está vinculada a otro inbox de XMTP. Continuar la moverá a tu inbox actual y podrías perder acceso al inbox anterior.';

  @override
  String get inboxIdsProceed => 'CONTINUAR';

  @override
  String get inboxIdsSelectRecoveryKey => 'SELECCIONAR LLAVE DE RECUPERACIÓN';

  @override
  String get inboxIdsSelectKeyToLink => 'SELECCIONAR LLAVE A VINCULAR';

  @override
  String get inboxIdsSelectKey => 'SELECCIONAR LLAVE';

  @override
  String inboxIdsKeyPickerSubtitle(String purpose) {
    return 'Se encontraron varias llaves. Selecciona una para $purpose.';
  }

  @override
  String get inboxIdsPurposeRevokeInstallation => 'revocar la instalación';

  @override
  String get inboxIdsPurposeRevokeAllOthers =>
      'revocar todas las demás instalaciones';

  @override
  String get inboxIdsRecoveryKeyDialogTitle => 'LLAVE DE RECUPERACIÓN';

  @override
  String get inboxIdsRecoveryKeyDialogSubtitle =>
      '¿Cómo te gustaría proporcionar la llave de recuperación?';

  @override
  String get inboxIdsMethodPickKeychainTitle => 'Elegir del llavero';

  @override
  String get inboxIdsMethodPickKeychainSubtitleShort =>
      'Selecciona una llave existente';

  @override
  String get inboxIdsMethodPickKeychainSubtitleLong =>
      'Selecciona una llave existente de tu llavero';

  @override
  String get inboxIdsEnterPrivateKey => 'Introduce la llave privada';

  @override
  String get inboxIdsEnterMnemonic => 'Introduce el mnemónico';

  @override
  String get inboxIdsHintPrivateKey => '0x…';

  @override
  String get inboxIdsHintMnemonic => 'palabra1 palabra2 palabra3 …';

  @override
  String get inboxIdsMethodPrivateKeySubtitle =>
      'Llave privada codificada en hex';

  @override
  String get inboxIdsMethodMnemonicSubtitle =>
      'Frase de recuperación de 12 o 24 palabras';

  @override
  String get inboxIdsAddAccountTitle => 'AGREGAR LLAVE';

  @override
  String get inboxIdsAddAccountSubtitle => 'Vincula otra llave a este inbox.';

  @override
  String get inboxIdsMethodImportKeyTitle => 'Importar llave';

  @override
  String get inboxIdsMethodImportKeySubtitle =>
      'Importar desde mnemónico o llave privada';

  @override
  String get inboxIdsMethodQrTitle => 'QR desde otro teléfono';

  @override
  String get inboxIdsMethodQrSubtitle =>
      'En el teléfono que tiene la llave: Llavero, abre la llave, Agregar a otro inbox. Luego escanea su QR con la cámara de este teléfono.';

  @override
  String linkKeyPickInboxTitle(String address) {
    return '¿A QUÉ INBOX AGREGAR $address?';
  }

  @override
  String get linkKeyNoInboxes =>
      'Este teléfono no tiene un inbox al que agregar la llave.';

  @override
  String get linkKeyConfirmTitle => 'AGREGAR LLAVE';

  @override
  String linkKeyConfirmBody(String address, String inbox) {
    return '¿Seguro que quieres agregar $address al inbox $inbox?';
  }

  @override
  String get linkKeyAddedTitle => 'LLAVE AGREGADA';

  @override
  String linkKeyAddedBody(String address, String inbox) {
    return '$address ahora es parte del inbox $inbox. Este teléfono no guardó la llave.\n\nEn el teléfono que mostró el QR, abre el llavero y toca Actualizar.';
  }

  @override
  String get linkKeyInvalid => 'Este QR no contiene una llave válida.';

  @override
  String get linkKeyAdd => 'Agregar';

  @override
  String get keychainActionAddToInbox => 'Agregar a otro inbox';

  @override
  String get keychainActionAddToInboxSub =>
      'Muestra esta llave como un QR, para escanearlo con tu otro teléfono y agregarla a un inbox ahí.';

  @override
  String get keyQrWarningTitle => 'ESTE QR ES TU LLAVE';

  @override
  String get keyQrWarningBody =>
      'El QR contiene la llave misma. Quien lo escanee, o vea una foto de él, obtiene tu llave.\n\nNo dejes que nadie más lo vea. No le tomes foto ni captura de pantalla, y no lo compartas. Escanéalo solo con tu propio teléfono.\n\nSi esta llave está vinculada a otro inbox, agregarla a uno nuevo la mueve: el inbox anterior pierde esta llave y las conversaciones a las que llegaba con ella.';

  @override
  String keyQrTitle(String label) {
    return 'AGREGAR $label A OTRO INBOX';
  }

  @override
  String get keyQrInstructions =>
      'Escanéalo con la cámara de tu otro teléfono. PublicOS se abre ahí y pregunta a qué inbox agregar la llave. Luego toca Actualizar en este llavero.';

  @override
  String get keyQrNeverShare => 'Nunca dejes que nadie más vea este QR.';

  @override
  String get keychainRefresh => 'Actualizar llaves';

  @override
  String get keychainRefreshDone => 'Llaves actualizadas';

  @override
  String keychainRefreshMoved(String labels) {
    return '$labels se movió a otro inbox';
  }

  @override
  String get inboxIdsImportKeyTitle => 'IMPORTAR LLAVE';

  @override
  String get inboxIdsMethodMnemonicPhraseTitle => 'Frase mnemónica';

  @override
  String get inboxIdsMethodPrivateKeyOptTitle => 'Llave privada';

  @override
  String get inboxIdsActionRegisterToProfile => 'Registrar en el perfil';

  @override
  String get inboxIdsActionRenameLabel => 'Renombrar etiqueta';

  @override
  String get inboxIdsActionAddAccount => 'Agregar llave';

  @override
  String get inboxIdsActionSyncing => 'Sincronizando…';

  @override
  String get inboxIdsActionSyncConsent => 'Sincronizar consentimiento';

  @override
  String get inboxIdsActionRequesting => 'Solicitando…';

  @override
  String get inboxIdsActionRequestHistory => 'Solicitar historial';

  @override
  String get inboxIdsActionRevokeAllOthers => 'Revocar todas las demás';

  @override
  String get inboxIdsActionRevoking => 'Revocando…';

  @override
  String get inboxIdsInboxIdCopied => 'Inbox ID copiado';

  @override
  String get inboxIdsAddressCopied => 'Dirección copiada';

  @override
  String get inboxIdsInstallationIdCopied => 'ID de instalación copiado';

  @override
  String get inboxIdsNoMatchingKeys =>
      'No se encontraron llaves coincidentes en el llavero';

  @override
  String get inboxIdsRegistered => 'Inbox ID registrado';

  @override
  String get inboxIdsRegisterFailed => 'No se pudo registrar el Inbox ID';

  @override
  String get inboxIdsLabelUpdated => 'Etiqueta actualizada';

  @override
  String get inboxIdsLabelUpdateFailed => 'No se pudo actualizar la etiqueta';

  @override
  String get inboxIdsRemoved => 'Inbox ID eliminado';

  @override
  String get inboxIdsRemoveFailed => 'No se pudo eliminar el Inbox ID';

  @override
  String get inboxIdsConsentSynced =>
      'Preferencias de consentimiento sincronizadas';

  @override
  String get inboxIdsConsentSyncFailed =>
      'No se pudieron sincronizar las preferencias de consentimiento';

  @override
  String get inboxIdsHistorySyncRequested =>
      'Sincronización de historial solicitada — otros dispositivos deben estar en línea para responder';

  @override
  String get inboxIdsHistorySyncFailed =>
      'No se pudo enviar la solicitud de sincronización de historial';

  @override
  String get inboxIdsNoSigningKey =>
      'No se encontró llave de firma para este inbox';

  @override
  String get inboxIdsInstallationRevoked => 'Instalación revocada';

  @override
  String get inboxIdsInstallationRevokeFailed =>
      'No se pudo revocar la instalación';

  @override
  String get inboxIdsAllOthersRevoked =>
      'Todas las demás instalaciones revocadas';

  @override
  String get inboxIdsRevokeInstallationsFailed =>
      'No se pudieron revocar las instalaciones';

  @override
  String get inboxIdsRecoveryKeyNotFound =>
      'Llave de recuperación no encontrada en el llavero';

  @override
  String get inboxIdsAccountRemoved => 'Cuenta eliminada';

  @override
  String get inboxIdsAccountRemoveFailed => 'No se pudo eliminar la cuenta';

  @override
  String get inboxIdsNoKeysInKeychain => 'No hay llaves en el llavero';

  @override
  String get inboxIdsInvalidKeyFormat => 'Formato de llave inválido';

  @override
  String get inboxIdsQueryingInboxState => 'Consultando el estado del inbox…';

  @override
  String get inboxIdsInboxNotFound => 'Inbox no encontrado';

  @override
  String get inboxIdsNoInstallationsToRevoke =>
      'No hay instalaciones que revocar';

  @override
  String get inboxIdsUserAddressUnavailable =>
      'Dirección de usuario no disponible';

  @override
  String get inboxIdsNoAvailableKeys =>
      'No hay llaves disponibles en el llavero';

  @override
  String get inboxIdsAccountAdded => 'Llave agregada';

  @override
  String get inboxIdsAccountAddFailed => 'No se pudo agregar la llave';

  @override
  String get inboxIdsErrorInvalidKeyFormat =>
      'Error: formato de llave inválido';

  @override
  String get postCardTranslating => 'Traduciendo…';

  @override
  String get postCardWaitingForWifi => 'Esperando Wi-Fi…';

  @override
  String get postCardDownloadingLanguage => 'Descargando idioma…';

  @override
  String get postCardDownloadLangPackTitle => '¿Descargar paquete de idioma?';

  @override
  String postCardDownloadLangPackBody(String from, String to) {
    return 'Para traducir $from → $to se necesita un paquete de idioma sin conexión (~30 MB cada uno, se descarga una vez y luego funciona totalmente en el dispositivo).';
  }

  @override
  String get postCardDownload => 'Descargar';

  @override
  String postCardTranslateFrom(String lang) {
    return 'Traducir de $lang';
  }

  @override
  String postCardTranslatedFromShowOriginal(String lang) {
    return 'Traducido de $lang · Ver original';
  }

  @override
  String postCardShowTranslation(String lang) {
    return 'Ver traducción ($lang)';
  }

  @override
  String get postCardOpenLink => 'Abrir enlace';

  @override
  String get postCardEdited => 'editado';

  @override
  String get postCardVia => 'vía';

  @override
  String get postCardEditPost => 'Editar publicación';

  @override
  String get postCardRemoveFromChannel => 'Quitar del canal';

  @override
  String get postCardDeletePost => 'Eliminar publicación';

  @override
  String get postCardUnlockComments => 'Desbloquear comentarios';

  @override
  String get postCardLockComments => 'Bloquear comentarios';

  @override
  String get postCardCommentRules => 'Reglas de comentarios';

  @override
  String get postCardCopyLink => 'Copiar enlace';

  @override
  String get postCardRefreshPost => 'Actualizar';

  @override
  String get postsListPostRefreshed => 'Publicación actualizada';

  @override
  String get postsListPostRefreshFailed =>
      'No se pudo actualizar la publicación';

  @override
  String get postCardNoLongerAvailable =>
      'Ya no está disponible en el servidor — tu copia guardada puede ser la única que quede';

  @override
  String get postCardRemoveFeedFromList => 'Quitar feed de la lista';

  @override
  String get postCardMuteChannel => 'Silenciar canal';

  @override
  String get postCardViewSource => 'Ver fuente';

  @override
  String get postCardNoShareLink =>
      'Aún no hay un enlace para compartir esta publicación';

  @override
  String get postCardLinkCopied => 'Enlace copiado';

  @override
  String postCardCouldNotOpenLink(String link) {
    return 'No se pudo abrir el enlace: $link';
  }

  @override
  String get postCardCannotLockMissingSlug =>
      'No se pueden bloquear los comentarios: falta el identificador del canal';

  @override
  String get postCardCommentsUnlocked => 'Comentarios desbloqueados';

  @override
  String get postCardCommentsLocked => 'Comentarios bloqueados';

  @override
  String postCardUpdateFailed(String message) {
    return 'Error: $message';
  }

  @override
  String get postCardUnknownError => 'Error desconocido';

  @override
  String get postCardMissingChannelInfo =>
      'A esta publicación le falta la información del canal';

  @override
  String get postCardThisFeed => 'este feed';

  @override
  String get postCardRemoveFeedTitle => 'Quitar feed de la lista';

  @override
  String postCardRemoveFeedBody(String feedTitle) {
    return '¿Quitar \"$feedTitle\" de esta lista?\n\nTodas las publicaciones de este feed se quitarán de la vista de lista.';
  }

  @override
  String get postCardRemove => 'Quitar';

  @override
  String get postCardRemoveFromChannelTitle => '¿Quitar del canal?';

  @override
  String get postCardDeletePostTitle => '¿Eliminar publicación?';

  @override
  String postCardDeleteBodyModeration(String channel) {
    return 'Esto quita la publicación y todos sus comentarios de #$channel. El autor perderá su publicación. No se puede deshacer.';
  }

  @override
  String get postCardDeleteBody =>
      'Esto quita la publicación y todos sus comentarios. No se puede deshacer.';

  @override
  String get postCardThisChannel => 'este canal';

  @override
  String get postCardDelete => 'Eliminar';

  @override
  String get postCardCannotDeleteMissingSlug =>
      'No se puede eliminar la publicación: falta el identificador del canal';

  @override
  String get postCardPostDeleted => 'Publicación eliminada';

  @override
  String postCardDeleteFailed(String message) {
    return 'No se pudo eliminar la publicación: $message';
  }

  @override
  String get accountCenterTitle => 'Cuenta';

  @override
  String get accountCenterSessionRemoved => 'Sesión eliminada';

  @override
  String get accountCenterAddNewSession => 'Agregar nueva sesión';

  @override
  String get accountCenterLinkNewDeviceTitle => 'Agregar una sesión';

  @override
  String get accountCenterLinkNewDeviceBody =>
      'En el otro teléfono o computadora, abre PublicOS, toca el botón QR en la tarjeta de la llave nueva, elige AGREGAR SESIÓN y firma. Luego escanea ese QR con esta cámara; la hoja de confirmación se abre sola.';

  @override
  String get accountCenterWhyQrTitle => '¿Por qué un QR?';

  @override
  String get accountCenterWhyQrBody =>
      'La nueva sesión demuestra que aceptó ser agregada firmando un consentimiento EIP-712 con su propia llave. El QR trae esa firma hasta aquí para que la envíes desde una sesión que ya tienes.';

  @override
  String get accountCenterRemoveSessionTitle => 'Eliminar sesión';

  @override
  String get accountCenterRemoveSessionConfirm =>
      '¿Seguro que quieres eliminar esta sesión?';

  @override
  String get accountCenterRemoveSessionWarning =>
      'Esta sesión ya no podrá actuar como tu cuenta.';

  @override
  String get accountCenterRemove => 'Eliminar';

  @override
  String get accountCenterNoAccountAddress =>
      'No se encontró dirección de cuenta';

  @override
  String get accountCenterRecoveryStatusError =>
      'No se pudo verificar el estado de recuperación';

  @override
  String get accountCenterStartRecoveryTitle => 'Iniciar recuperación';

  @override
  String get accountCenterScanRecoveryQrTitle =>
      'Escanea su QR de recuperación';

  @override
  String get accountCenterScanRecoveryQrBody =>
      'Pide a la persona que abra PublicOS en su nuevo teléfono o computadora y muestre el QR de una llave nueva (el mismo código para agregar una sesión). Escanéalo con tu cámara. Si eres uno de sus contactos de recuperación, puedes iniciar la votación que le da a su cuenta esa nueva sesión.';

  @override
  String get accountCenterRecoveryVoteStarted =>
      'Votación de recuperación iniciada';

  @override
  String get accountCenterVotedApprove =>
      'Votaste para aprobar la recuperación';

  @override
  String get accountCenterVotedReject =>
      'Votaste para rechazar la recuperación';

  @override
  String get accountCenterExpired => 'Expirado';

  @override
  String accountCenterRemainingDays(int days, int hours) {
    return '${days}d ${hours}h restantes';
  }

  @override
  String accountCenterRemainingHours(int hours, int minutes) {
    return '${hours}h ${minutes}m restantes';
  }

  @override
  String accountCenterRemainingMinutes(int minutes) {
    return '${minutes}m restantes';
  }

  @override
  String get accountCenterUnknown => 'Desconocido';

  @override
  String get accountCenterStatusLifetime => 'PERMANENTE';

  @override
  String get accountCenterStatusActive => 'ACTIVO';

  @override
  String get accountCenterStatusNotSet => 'SIN CONFIGURAR';

  @override
  String get accountCenterStatusOverdue => 'VENCIDO';

  @override
  String get accountCenterNever => 'Nunca';

  @override
  String get accountCenterNone => 'Ninguno';

  @override
  String get accountCenterDomain => 'Dominio';

  @override
  String get accountCenterAddressCopied => 'Dirección copiada';

  @override
  String get accountCenterCitizen => 'CIUDADANO';

  @override
  String get citizenClaimTitle => '¡Eres elegible para la ciudadanía!';

  @override
  String get citizenClaimLead =>
      'Suficientes ciudadanos hicieron vouch por ti. Lee el acuerdo ciudadano hasta el final; aceptarlo es lo que te hace ciudadano.';

  @override
  String citizenClaimVersion(String version) {
    return 'Acuerdo ciudadano · versión $version';
  }

  @override
  String get citizenClaimScrollHint => 'Desplázate hasta el final para aceptar';

  @override
  String get citizenClaimAccept => 'ACEPTAR Y RECLAMAR';

  @override
  String get citizenClaimClaiming => 'RECLAMANDO';

  @override
  String get citizenClaimDoneTitle => 'Eres ciudadano';

  @override
  String get citizenClaimDoneBody =>
      'Tu nombre de dominio es gratis de por vida, tienes un asiento y un voto en la org PublicOS, y puedes hacer vouch por personas que conoces en persona.';

  @override
  String get citizenClaimContinue => 'CONTINUAR';

  @override
  String get citizenClaimFailed => 'El reclamo no se completó.';

  @override
  String get citizenClaimRetry => 'INTENTAR DE NUEVO';

  @override
  String get citizenClaimNeedsPermanentKey =>
      'Reclamar necesita una llave permanente. Esta sesión expira; abre PublicOS con tu llave principal y reclama ahí.';

  @override
  String get citizenClaimLoadFailed =>
      'No se pudo cargar el acuerdo. Revisa tu conexión e intenta de nuevo.';

  @override
  String get citizenClaimNothingPublished =>
      'Todavía no hay un acuerdo ciudadano publicado. Intenta más tarde.';

  @override
  String get protocolAgreementTitle => 'El acuerdo de PublicOS';

  @override
  String get protocolAgreementLead =>
      'Tu cuenta nueva acepta este acuerdo: tu llave nueva lo firma cuando se crea la cuenta. Léelo hasta el final.';

  @override
  String protocolAgreementVersion(String version) {
    return 'Acuerdo del protocolo · versión $version';
  }

  @override
  String get protocolAgreementScrollHint =>
      'Desplázate hasta el final para aceptar';

  @override
  String get protocolAgreementAccept => 'ACEPTAR Y CONTINUAR';

  @override
  String get protocolAgreementAgeCheck =>
      'Tengo 16 años o más, y edad suficiente donde vivo para aceptar esto por mi cuenta.';

  @override
  String get protocolAgreementLoadFailed =>
      'No se pudo cargar el acuerdo. Revisa tu conexión e intenta de nuevo.';

  @override
  String get noticeServicesRow => 'Enviar aviso a un SSP';

  @override
  String get noticeTitle => 'Enviar aviso a un SSP';

  @override
  String get noticeSearchHint => 'Busca un SSP por nombre o dirección';

  @override
  String get noticeNoResults => 'Ningún SSP coincide.';

  @override
  String get noticeLoadFailed => 'No se pudo cargar la lista de SSPs.';

  @override
  String get noticeNoKey => 'Este SSP todavía no recibe avisos.';

  @override
  String get noticeChange => 'CAMBIAR';

  @override
  String get noticeTypeLabel => '¿De qué se trata?';

  @override
  String get noticeTypeTakedown => 'Retiro de contenido';

  @override
  String get noticeTypeLawfulOrder => 'Orden legal';

  @override
  String get noticeTypeIpClaim => 'Propiedad intelectual';

  @override
  String get noticeTypeAppeal => 'Apelación';

  @override
  String get noticeTypeAbuseReport => 'Reporte de abuso';

  @override
  String get noticeTypePrivacy => 'Privacidad';

  @override
  String get noticeTypeIntimateImage => 'Imagen íntima';

  @override
  String get noticeTypeChildSafety => 'Seguridad infantil';

  @override
  String get noticeAboutHint => 'Enlace a la publicación o página (opcional)';

  @override
  String get noticeTextHint => 'Escribe tu aviso';

  @override
  String get noticeOnChainNote =>
      'Se registra en la cadena como evidencia pública: tu dirección será visible. La carta sigue cifrada.';

  @override
  String get noticeOffChainNote =>
      'Fuera de la cadena: solo el operador del SSP puede leerlo.';

  @override
  String get noticeSend => 'ENVIAR';

  @override
  String get noticeSending => 'ENVIANDO';

  @override
  String get noticeSentTitle => 'Aviso enviado';

  @override
  String noticeSentBody(String ssp) {
    return '$ssp lo recibió.';
  }

  @override
  String noticeSentOnChain(String id) {
    return 'Registrado en la cadena como aviso #$id.';
  }

  @override
  String get noticeFailed => 'No se pudo enviar el aviso.';

  @override
  String get noticeDone => 'LISTO';

  @override
  String get chsSubOtherChannels => 'Desde otros canales';

  @override
  String get chsAllowQuotes => 'Citas';

  @override
  String get chsAllowQuotesSub =>
      'Otros pueden citar estas publicaciones en sus canales.';

  @override
  String get chsAllowReposts => 'Republicaciones';

  @override
  String get chsAllowRepostsSub => 'Otros pueden republicarlas en sus canales.';

  @override
  String get chsAllowReplies => 'Respuestas';

  @override
  String get chsAllowRepliesSub =>
      'Otros pueden responder con una publicación en su propio canal.';

  @override
  String get accountCenterClaimCitizenship => 'RECLAMAR CIUDADANÍA';

  @override
  String get accountCenterRenounceSection => 'Dejar la ciudadanía';

  @override
  String get accountCenterRenounceBody =>
      'Puedes renunciar a la ciudadanía cuando quieras. Es inmediato y no se deshace. Los vouch que diste, y tu palabra por esas personas, se quedan.';

  @override
  String get accountCenterRenounceButton => 'RENUNCIAR A LA CIUDADANÍA';

  @override
  String get renounceDlg1Title => '¿Renunciar a la ciudadanía?';

  @override
  String get renounceDlg1Lead =>
      'Lee esto primero. Todo pasa en un solo paso, en cuanto se confirma:';

  @override
  String get renounceCostName =>
      'Tu nombre de dominio deja de ser gratis desde ahora. Págalo para seguir usando la cuenta.';

  @override
  String get renounceCostShare =>
      'Tu parte sin reclamar se pierde. Reclámala antes, en Servicios.';

  @override
  String get renounceCostSubs =>
      'Las suscripciones sin liquidar se cobran como privado. Liquídalas antes.';

  @override
  String get renounceCostGraph =>
      'Sales del grafo social: los vouch que recibiste se borran. Volver necesita vouch nuevos.';

  @override
  String get renounceCostSeat =>
      'Tu asiento y tu voto en la org PublicOS terminan.';

  @override
  String get renounceCostVouches =>
      'Los vouch que diste se quedan, y también tu palabra por esas personas.';

  @override
  String renounceWait(String seconds) {
    return 'RENUNCIAR · $seconds';
  }

  @override
  String get renounceDlg1Confirm => 'RENUNCIAR';

  @override
  String get renounceKeep => 'CONSERVAR LA CIUDADANÍA';

  @override
  String get renounceDlg2Title => 'Último paso';

  @override
  String get renounceDlg2Body =>
      'Este es el que lo hace. No hay vuelta atrás ni periodo de gracia.';

  @override
  String get renounceDlg2Confirm => 'RENUNCIAR A LA CIUDADANÍA AHORA';

  @override
  String vouchDlg1Title(String name) {
    return '¿Dar tu vouch a $name?';
  }

  @override
  String get vouchDlg1Lead =>
      'Esto es lo más importante que haces en PublicOS. Léelo completo:';

  @override
  String vouchPointInPerson(String name) {
    return 'Declaras que conoces a $name en persona: una persona real, viva, mayor de edad, cuyo nombre puedes decir.';
  }

  @override
  String get vouchPointOneAccount =>
      'Hasta donde sabes, no tiene otra cuenta de ciudadano.';

  @override
  String get vouchPointTrust =>
      'Tus derechos como ciudadano descansan en la confianza de quienes te dieron su vouch. Este vouch pasa esa confianza.';

  @override
  String get vouchPointFinal => 'Un vouch no se puede retirar.';

  @override
  String get vouchPointCharacter =>
      'No dice nada de su carácter, y no eres responsable de lo que haga.';

  @override
  String get vouchPointIdentify =>
      'Si una orden legal lo requiere, dirás lo que sabes sobre quién es.';

  @override
  String get vouchPointConsequence =>
      'Un vouch falso te cuesta la ciudadanía, y root puede suspender tu cuenta. Queda registrado en la cadena, donde cualquiera lo puede ver.';

  @override
  String vouchWait(String seconds) {
    return 'CONTINUAR · $seconds';
  }

  @override
  String get vouchDlg1Confirm => 'CONTINUAR';

  @override
  String get vouchCancel => 'CANCELAR';

  @override
  String get vouchDlg2Title => 'Último paso';

  @override
  String vouchDlg2Body(String name) {
    return 'Estás dando tu palabra de que $name es una persona real que conoces. No hay vuelta atrás.';
  }

  @override
  String get vouchDlg2Cancel => 'NO DAR VOUCH';

  @override
  String get vouchDlg2Confirm => 'DAR VOUCH AHORA';

  @override
  String get renounceWorking => 'Renunciando a la ciudadanía…';

  @override
  String get renounceDone => 'Ya no eres ciudadano.';

  @override
  String get renounceFailed => 'La renuncia no se completó.';

  @override
  String get renounceNeedsPermanentKey =>
      'Renunciar necesita una llave permanente. Esta sesión expira; usa tu llave principal.';

  @override
  String get accountCenterDomainStatus => 'Estado del dominio';

  @override
  String get accountCenterPaidUntil => 'Pagado hasta';

  @override
  String get accountCenterFreeNameChanges => 'Cambios de nombre gratis';

  @override
  String get accountCenterManageDomain => 'GESTIONAR DOMINIO';

  @override
  String get accountCenterDevices => 'Sesiones';

  @override
  String get accountCenterSessionsInfo =>
      'Las sesiones son direcciones de billetera que pueden actuar en nombre de tu cuenta.';

  @override
  String get accountCenterCurrent => 'ACTUAL';

  @override
  String get accountCenterAdding => 'AGREGANDO...';

  @override
  String get accountCenterAddSession => 'AGREGAR SESIÓN';

  @override
  String get accountCenterHelpFriendRecover => 'Ayuda a un amigo a recuperar';

  @override
  String get accountCenterRecoveryInfo =>
      'Si un amigo pierde el acceso a su cuenta y eres uno de sus contactos de recuperación, puedes ayudarlo a recuperar el control.';

  @override
  String get accountCenterSelectFriend => 'SELECCIONAR AMIGO';

  @override
  String get accountCenterCheckingRecoveryStatus =>
      'Verificando estado de recuperación...';

  @override
  String get accountCenterRetry => 'REINTENTAR';

  @override
  String get accountCenterChange => 'CAMBIAR';

  @override
  String get accountCenterNotRecoveryContact =>
      'No eres un contacto de recuperación de esta cuenta';

  @override
  String get accountCenterChangeFriend => 'CAMBIAR AMIGO';

  @override
  String get accountCenterActiveVote => 'VOTO ACTIVO';

  @override
  String get accountCenterProposed => 'Propuesto';

  @override
  String get accountCenterVotes => 'Votos';

  @override
  String accountCenterVotesValue(int add, int cancel, int threshold) {
    return '$add a favor / $cancel en contra (faltan $threshold)';
  }

  @override
  String get accountCenterExpires => 'Vence';

  @override
  String get accountCenterSessionExpired => 'Esta sesión ha expirado';

  @override
  String get accountCenterVoting => 'VOTANDO...';

  @override
  String get accountCenterApprove => 'APROBAR';

  @override
  String get accountCenterReject => 'RECHAZAR';

  @override
  String get accountCenterTrusted => 'DE CONFIANZA';

  @override
  String get accountCenterThreshold => 'Umbral';

  @override
  String accountCenterThresholdValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votos necesarios',
      one: '1 voto necesario',
    );
    return '$_temp0';
  }

  @override
  String get accountCenterNoActiveSession =>
      'No hay sesión de recuperación activa';

  @override
  String get accountCenterStarting => 'INICIANDO...';

  @override
  String get accountCenterStartRecoveryAction => 'INICIAR RECUPERACIÓN';

  @override
  String get accountCenterCreateAccountInvite => 'Crear cuenta con invitación';

  @override
  String get accountCenterInviteSeasonHave =>
      'La temporada de invitaciones está activa. Escanea el código QR \"Nueva cuenta\" de un amigo con tu cámara para darlo de alta — gasta una invitación.';

  @override
  String get accountCenterInviteSeasonNone =>
      'La temporada de invitaciones está activa. No te quedan invitaciones. Espera la próxima ola para dar de alta nuevas cuentas.';

  @override
  String accountCenterInvitesLeftLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'invitaciones restantes',
      one: 'invitación restante',
    );
    return '$_temp0';
  }

  @override
  String get accountCenterCreateNewAccount => 'Crear nueva cuenta';

  @override
  String get accountCenterCreateAccountInfo =>
      'Para crear una cuenta, escanea el código QR de tu amigo para \"Nueva cuenta\" con tu cámara. PublicOS abre la hoja de confirmación automáticamente.';

  @override
  String get accountCenterSelectFriendTitle => 'Seleccionar amigo';

  @override
  String get accountCenterSearchHint => 'Busca por nombre, usuario o dirección';

  @override
  String get accountCenterSearchingOnChain => 'Buscando en la cadena…';

  @override
  String get accountCenterNoContacts =>
      'No hay contactos con dirección de PublicOS';

  @override
  String get addSessionDialogWrongKind =>
      'Esta solicitud es para crear una cuenta, no para agregar una sesión.';

  @override
  String get addSessionDialogMalformedPayload =>
      'Solicitud con formato inválido.';

  @override
  String get addSessionDialogForeignAccount =>
      'Esta solicitud fue firmada para una cuenta diferente.';

  @override
  String get addSessionDialogNotRecoveryContact =>
      'No eres un contacto de recuperación de esta cuenta, así que no puedes ayudar a recuperarla. Solo pueden los contactos que eligieron con antelación.';

  @override
  String get addSessionDialogRecoveryCheckFailed =>
      'No se pudo verificar el estado de recuperación.';

  @override
  String get addSessionDialogRecoveryVoteStartedTitle =>
      'Votación de recuperación iniciada';

  @override
  String get addSessionDialogDeviceAuthorizedTitle => 'Sesión agregada';

  @override
  String get addSessionDialogRecoverySuccessBody =>
      'Los demás contactos de recuperación ya pueden votar. Cuando suficientes aprueben, la nueva sesión queda como la única de la cuenta.';

  @override
  String get addSessionDialogAuthorizedSuccessBody =>
      'La nueva sesión ya puede actuar como tu cuenta.';

  @override
  String get addSessionDialogInvalidClaimTitle => 'Código no válido';

  @override
  String get addSessionDialogClose => 'CERRAR';

  @override
  String get addSessionDialogHelpRecoverTitle =>
      'Ayudar a recuperar una cuenta';

  @override
  String get addSessionDialogAuthorizeSessionTitle => 'Agregar una sesión';

  @override
  String addSessionDialogRecoveryBody(Object target, Object address) {
    return 'Inicia una votación de recuperación que le da a $target una nueva sesión ($address). Si suficientes de sus contactos de recuperación aprueban, se eliminan las demás sesiones de la cuenta y queda solo esta.';
  }

  @override
  String addSessionDialogAuthorizeBody(Object address) {
    return 'Agrega $address como sesión de tu cuenta. Podrá enviar mensajes, administrar tu perfil y hacer transacciones como tú.';
  }

  @override
  String get addSessionDialogThisAccount => 'esta cuenta';

  @override
  String get addSessionDialogAddressCopied => 'Dirección copiada';

  @override
  String addSessionDialogRecoveryWarning(Object target) {
    return 'Haz esto solo si $target te pidió ayuda para recuperar su cuenta. Elimina todas sus sesiones actuales.';
  }

  @override
  String get addSessionDialogAuthorizeWarning =>
      'Aprueba solo una sesión que tú mismo iniciaste. Si no fuiste tú, cancela.';

  @override
  String get addSessionDialogClaimExpired =>
      'Esta solicitud venció. Genera un QR nuevo donde la iniciaste.';

  @override
  String get addSessionDialogStartVoteButton => 'INICIAR VOTACIÓN';

  @override
  String get addSessionDialogAuthorizeButton => 'AGREGAR SESIÓN';

  @override
  String get addSessionDialogDeadlineExpired => 'expirada';

  @override
  String addSessionDialogDeadlineExpiresIn(Object time) {
    return 'Expira en $time';
  }

  @override
  String get appProfileBottomSheetEdit => 'Editar';

  @override
  String get appProfileBottomSheetByPrefix => 'de ';

  @override
  String get appProfileBottomSheetAbout => 'Acerca de';

  @override
  String get appProfileBottomSheetOpenApp => 'Abrir app';

  @override
  String get appProfileBottomSheetOpenWebApp => 'Abrir app web';

  @override
  String get appProfileBottomSheetDownloadApk => 'Descargar APK';

  @override
  String get appProfileBottomSheetDownloadIpa => 'Descargar IPA';

  @override
  String get appProfileBottomSheetPlatformWeb => 'Web';

  @override
  String get registerAppBottomSheetTitleEdit => 'Editar App';

  @override
  String get registerAppBottomSheetTitleRegister => 'Registrar App';

  @override
  String get registerAppBottomSheetBack => 'Atrás';

  @override
  String get registerAppBottomSheetUpdateApp => 'Actualizar App';

  @override
  String get registerAppBottomSheetNext => 'Siguiente';

  @override
  String get registerAppBottomSheetStepBasicInfo => 'Info básica';

  @override
  String get registerAppBottomSheetStepMetadata => 'Metadatos';

  @override
  String get registerAppBottomSheetStepLinks => 'Enlaces';

  @override
  String get registerAppBottomSheetBasicInfoTitle => 'Información básica';

  @override
  String get registerAppBottomSheetAppNameLabel =>
      'Nombre de la App (llave única)';

  @override
  String get registerAppBottomSheetAppNameHint => 'p. ej., mi-app-genial';

  @override
  String get registerAppBottomSheetAppNameHelperEdit =>
      'El nombre de la App no se puede cambiar después de registrarla.';

  @override
  String get registerAppBottomSheetAppNameHelperCreate =>
      'Minúsculas, sin espacios. Es el identificador de tu app.';

  @override
  String get registerAppBottomSheetAppNameRequired =>
      'El nombre de la App es obligatorio';

  @override
  String get registerAppBottomSheetAppNameMinLength =>
      'El nombre de la App debe tener al menos 3 caracteres';

  @override
  String get registerAppBottomSheetDisplayNameLabel => 'Nombre visible';

  @override
  String get registerAppBottomSheetDisplayNameHint => 'p. ej., Mi App Genial';

  @override
  String get registerAppBottomSheetDisplayNameHelper =>
      'Nombre legible que se muestra a los usuarios.';

  @override
  String get registerAppBottomSheetDisplayNameRequired =>
      'El nombre visible es obligatorio';

  @override
  String get registerAppBottomSheetIconUrlLabel => 'URL del ícono (opcional)';

  @override
  String get registerAppBottomSheetIconUrlHelper =>
      'URL de la imagen del ícono de tu app.';

  @override
  String get registerAppBottomSheetAppDetailsTitle => 'Detalles de la App';

  @override
  String get registerAppBottomSheetDescriptionLabel => 'Descripción';

  @override
  String get registerAppBottomSheetDescriptionHint =>
      'Describe qué hace tu app...';

  @override
  String get registerAppBottomSheetWarningsLabel => 'Advertencias (opcional)';

  @override
  String get registerAppBottomSheetWarningsHint =>
      'p. ej., Contiene contenido para adultos, apuestas, etc.';

  @override
  String get registerAppBottomSheetWarningsHelper =>
      'Cualquier advertencia de contenido que los usuarios deban conocer.';

  @override
  String get registerAppBottomSheetCategoryOneLabel => 'Categoría 1';

  @override
  String get registerAppBottomSheetCategoryOneHint => 'p. ej., Social';

  @override
  String get registerAppBottomSheetCategoryTwoLabel => 'Categoría 2';

  @override
  String get registerAppBottomSheetCategoryTwoHint => 'p. ej., Finanzas';

  @override
  String get registerAppBottomSheetAppLinksTitle => 'Enlaces de la App';

  @override
  String get registerAppBottomSheetAppLinksSubtitle =>
      'Agrega al menos un enlace donde los usuarios puedan acceder a tu app.';

  @override
  String get registerAppBottomSheetWebUrlLabel => 'URL de la app web';

  @override
  String get registerAppBottomSheetWebUrlHelper =>
      'URL de tu app web (se puede abrir en el navegador de PublicOS).';

  @override
  String get registerAppBottomSheetAppStoreLabel => 'Enlace de App Store (iOS)';

  @override
  String get registerAppBottomSheetPlayStoreLabel =>
      'Enlace de Play Store (Android)';

  @override
  String get registerAppBottomSheetApkLabel => 'URL de descarga del APK';

  @override
  String get registerAppBottomSheetApkHint => 'Enlace directo al archivo APK';

  @override
  String get registerAppBottomSheetIpaLabel => 'URL de descarga del IPA';

  @override
  String get registerAppBottomSheetIpaHint => 'Enlace directo al archivo IPA';

  @override
  String registerAppBottomSheetSnackUpdated(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicadores',
      one: '1 indicador',
    );
    return '¡App \"$name\" actualizada con $_temp0!';
  }

  @override
  String registerAppBottomSheetSnackRegistered(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicadores',
      one: '1 indicador',
    );
    return '¡App \"$name\" registrada con $_temp0!';
  }

  @override
  String get registerAppBottomSheetRegisterFailed =>
      'No se pudo registrar la app';

  @override
  String get appProfileSheetEdit => 'Editar';

  @override
  String get appProfileSheetByPrefix => 'de ';

  @override
  String get appProfileSheetAbout => 'Acerca de';

  @override
  String get appProfileSheetOpenAppHeader => 'Abrir app';

  @override
  String get appProfileSheetOpenWebApp => 'Abrir app web';

  @override
  String get appProfileSheetDownloadApk => 'Descargar APK';

  @override
  String get appProfileSheetDownloadIpa => 'Descargar IPA';

  @override
  String get registerAppSheetBasicInfo => 'Información básica';

  @override
  String get registerAppSheetAppNameLabel => 'Nombre de la app (llave única)';

  @override
  String get registerAppSheetAppNameHint => 'p. ej., mi-app-genial';

  @override
  String get registerAppSheetAppNameHelperLocked =>
      'El nombre de la app no se puede cambiar después de registrarla.';

  @override
  String get registerAppSheetAppNameHelper =>
      'Minúsculas, sin espacios. Este es el identificador de tu app.';

  @override
  String get registerAppSheetAppNameRequired =>
      'El nombre de la app es obligatorio';

  @override
  String get registerAppSheetAppNameTooShort =>
      'El nombre de la app debe tener al menos 3 caracteres';

  @override
  String get registerAppSheetDisplayNameLabel => 'Nombre visible';

  @override
  String get registerAppSheetDisplayNameHint => 'p. ej., Mi App Genial';

  @override
  String get registerAppSheetDisplayNameHelper =>
      'Nombre legible que se muestra a los usuarios.';

  @override
  String get registerAppSheetDisplayNameRequired =>
      'El nombre visible es obligatorio';

  @override
  String get registerAppSheetIconUrlLabel => 'URL del icono (opcional)';

  @override
  String get registerAppSheetIconUrlHelper =>
      'URL de la imagen del icono de tu app.';

  @override
  String get registerAppSheetAppDetails => 'Detalles de la app';

  @override
  String get registerAppSheetDescriptionLabel => 'Descripción';

  @override
  String get registerAppSheetDescriptionHint => 'Describe qué hace tu app...';

  @override
  String get registerAppSheetWarningsLabel => 'Advertencias (opcional)';

  @override
  String get registerAppSheetWarningsHint =>
      'p. ej., Contiene contenido para adultos, apuestas, etc.';

  @override
  String get registerAppSheetWarningsHelper =>
      'Advertencias de contenido que los usuarios deberían conocer.';

  @override
  String get registerAppSheetCategoryOneLabel => 'Categoría 1';

  @override
  String get registerAppSheetCategoryOneHint => 'p. ej., Social';

  @override
  String get registerAppSheetCategoryTwoLabel => 'Categoría 2';

  @override
  String get registerAppSheetCategoryTwoHint => 'p. ej., Finanzas';

  @override
  String get registerAppSheetAppLinks => 'Enlaces de la app';

  @override
  String get registerAppSheetLinksSubtitle =>
      'Agrega al menos un enlace donde los usuarios puedan acceder a tu app.';

  @override
  String get registerAppSheetWebUrlLabel => 'URL de la app web';

  @override
  String get registerAppSheetWebUrlHelper =>
      'URL de tu app web (se puede abrir en el navegador de PublicOS).';

  @override
  String get registerAppSheetAppStoreLabel => 'Enlace de App Store (iOS)';

  @override
  String get registerAppSheetPlayStoreLabel => 'Enlace de Play Store (Android)';

  @override
  String get registerAppSheetApkUrlLabel => 'URL de descarga del APK';

  @override
  String get registerAppSheetApkUrlHint => 'Enlace directo al archivo APK';

  @override
  String get registerAppSheetIpaUrlLabel => 'URL de descarga del IPA';

  @override
  String get registerAppSheetIpaUrlHint => 'Enlace directo al archivo IPA';

  @override
  String get registerAppSheetEditApp => 'Editar app';

  @override
  String get registerAppSheetRegisterApp => 'Registrar app';

  @override
  String get registerAppSheetStepBasic => 'Básico';

  @override
  String get registerAppSheetStepMetadata => 'Metadatos';

  @override
  String get registerAppSheetStepLinks => 'Enlaces';

  @override
  String get registerAppSheetBack => 'Atrás';

  @override
  String get registerAppSheetUpdateApp => 'Actualizar app';

  @override
  String get registerAppSheetNext => 'Siguiente';

  @override
  String registerAppSheetUpdatedSnack(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicadores',
      one: '1 indicador',
    );
    return 'App \"$name\" actualizada con $_temp0!';
  }

  @override
  String registerAppSheetRegisteredSnack(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count indicadores',
      one: '1 indicador',
    );
    return 'App \"$name\" registrada con $_temp0!';
  }

  @override
  String registerAppSheetUpdateFailed(Object error) {
    return 'No se pudo actualizar la app: $error';
  }

  @override
  String registerAppSheetRegisterFailed(Object error) {
    return 'No se pudo registrar la app: $error';
  }

  @override
  String get signatureRequestSheetSignWith => 'Firmar con';

  @override
  String get signatureRequestSheetMyAccount => 'Mi cuenta';

  @override
  String get signatureRequestSheetKeyFallback => 'Llave';

  @override
  String get signatureRequestSheetTitleSignMessage => 'Firmar mensaje';

  @override
  String get signatureRequestSheetTitleSignData => 'Firmar datos';

  @override
  String get signatureRequestSheetTitleSignTypedData => 'Firmar typed data';

  @override
  String get signatureRequestSheetTitleSendTransaction => 'Enviar transacción';

  @override
  String get signatureRequestSheetTitleSignTransaction => 'Firmar transacción';

  @override
  String get signatureRequestSheetActionSignMessage => 'FIRMAR MENSAJE';

  @override
  String get signatureRequestSheetActionSignData => 'FIRMAR DATOS';

  @override
  String get signatureRequestSheetActionSend => 'ENVIAR';

  @override
  String get signatureRequestSheetActionSign => 'FIRMAR';

  @override
  String get signatureRequestSheetChainUnknown => 'Desconocida';

  @override
  String signatureRequestSheetChainNamed(Object id) {
    return 'Cadena $id';
  }

  @override
  String get signatureRequestSheetInfoTitle => 'Sobre la firma';

  @override
  String get signatureRequestSheetInfoBody1 =>
      'Esto firma un mensaje digital con la llave seleccionada.';

  @override
  String get signatureRequestSheetInfoBody2 =>
      'Una firma puede autorizar acciones, probar propiedad o aceptar términos. Puede o no tocar la cadena.';

  @override
  String get signatureRequestSheetInfoWarning =>
      'Siempre ten cuidado con lo que firmas — una firma maliciosa puede llevar a pérdida de fondos o acceso no autorizado.';

  @override
  String get signatureRequestSheetInfoGotIt => 'Entendido';

  @override
  String get signatureRequestSheetCopiedToClipboard =>
      'Copiado al portapapeles';

  @override
  String get signatureRequestSheetInfoTooltip => '¿Qué es firmar?';

  @override
  String get signatureRequestSheetKeyBadge => 'llave';

  @override
  String get signatureRequestSheetNoData => 'Sin datos';

  @override
  String get signatureRequestSheetSigningWith => 'FIRMANDO CON';

  @override
  String get signatureRequestSheetSectionMessage => 'MENSAJE';

  @override
  String get signatureRequestSheetSectionRawHex => 'HEX CRUDO';

  @override
  String get signatureRequestSheetRawData => 'DATOS CRUDOS';

  @override
  String get signatureRequestSheetCopy => 'COPIAR';

  @override
  String get signatureRequestSheetNotReadableText =>
      'Este mensaje no es texto legible. Puedes revisarlo en Datos crudos.';

  @override
  String get signatureRequestSheetSectionTypedData => 'TYPED DATA (EIP-712)';

  @override
  String get signatureRequestSheetSectionTransaction => 'TRANSACCIÓN';

  @override
  String get signatureRequestSheetSectionContractData => 'DATOS DEL CONTRATO';

  @override
  String get signatureRequestSheetLabelSending => 'Enviando';

  @override
  String get signatureRequestSheetLabelRecipient => 'Destinatario';

  @override
  String get signatureRequestSheetLabelToken => 'Token';

  @override
  String get signatureRequestSheetLabelTo => 'Para';

  @override
  String get signatureRequestSheetLabelValue => 'Valor';

  @override
  String get signatureRequestSheetLabelNetwork => 'Red';

  @override
  String get signatureRequestSheetLabelGasLimit => 'Límite de gas';

  @override
  String get signatureRequestSheetActionReject => 'RECHAZAR';

  @override
  String get connectRequestSheetTitle => '¿Conectar con este sitio?';

  @override
  String get connectRequestSheetOrigin => 'ORIGEN';

  @override
  String get connectRequestSheetNetwork => 'RED';

  @override
  String get browserChainPickerNote =>
      'Solo para esta pestaña; recarga la página.';

  @override
  String get connectRequestSheetSharing => 'COMPARTIENDO';

  @override
  String get connectRequestSheetSessionKey => 'Llave de sesión';

  @override
  String get connectRequestSheetScope =>
      'Este sitio podrá ver las llaves que enciendas y pedirte que firmes con ellas. La llave verde es la que ve primero. No puede firmar ni mover fondos sin preguntarte cada vez.';

  @override
  String get connectRequestSheetActionCancel => 'CANCELAR';

  @override
  String get connectRequestSheetActionConnect => 'CONECTAR';

  @override
  String get siteKeysSheetTitle => 'Llaves conectadas';

  @override
  String get siteKeysSheetSubtitle =>
      'Las llaves visibles son las que este sitio puede ver y con las que puede pedirte firmar. La llave verde es la llave activa: la primera de la lista, la que la mayoría de los sitios usa para iniciar tu sesión. Es una elección solo para este sitio. Los sitios que no tienen una usan tu llave preferida.';

  @override
  String get siteKeysSheetActive => 'Llave activa en este sitio';

  @override
  String get siteKeysSheetVisible => 'Visible para este sitio';

  @override
  String get siteKeysSheetRequested => 'Este sitio pidió esta llave';

  @override
  String get siteKeysSheetDisconnectHint =>
      'Apaga todas las llaves para desconectar este sitio.';

  @override
  String get siteKeysSheetLegendVisible => 'El sitio la ve';

  @override
  String get siteKeysSheetLegendActive => 'Firma primero';

  @override
  String get siteKeysSheetLegendDisconnect => 'Todas apagadas = desconectar';

  @override
  String get siteKeysSheetActionSave => 'GUARDAR';

  @override
  String get siteKeysSheetActionDisconnect => 'DESCONECTAR';

  @override
  String get siteKeysSheetEmpty => 'No hay llaves disponibles.';

  @override
  String desktopWebKeyVisibleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count visibles',
      one: '1 visible',
    );
    return '$_temp0';
  }

  @override
  String get desktopWebviewLoading => 'Cargando...';

  @override
  String get webKeyIndicatorTooltip => 'Llaves para este sitio';

  @override
  String signatureRequestSheetRawTokenAmount(Object amount, Object addr) {
    return '$amount (token $addr)';
  }

  @override
  String get domainStoreSheetOverdueRenewFirst =>
      'Tu dominio está vencido — renuévalo primero. Una cuenta vencida solo puede pagar su propio dominio hasta que vuelva a estar al corriente.';

  @override
  String get editInboxIdLabelSheetTitle => 'Editar etiqueta de Inbox ID';

  @override
  String editInboxIdLabelSheetIdLabel(Object id) {
    return 'ID: $id';
  }

  @override
  String get editInboxIdLabelSheetNewLabel => 'Nueva etiqueta';

  @override
  String get editInboxIdLabelSheetLabelRequired => 'Ingresa una etiqueta';

  @override
  String get editInboxIdLabelSheetSave => 'Guardar cambios';

  @override
  String get feedsSettingsSheetTitle => 'Ajustes de vista RSS';

  @override
  String get feedsSettingsSheetSubtitle =>
      'Personaliza cómo se muestran las publicaciones';

  @override
  String get feedsSettingsSheetTitleTextSize => 'Tamaño del texto del título';

  @override
  String get feedsSettingsSheetDescriptionTextSize =>
      'Tamaño del texto de la descripción';

  @override
  String get feedsSettingsSheetPreview => 'Vista previa';

  @override
  String get feedsSettingsSheetSamplePostTitle =>
      'Título de publicación de ejemplo';

  @override
  String get feedsSettingsSheetSampleDescription =>
      'Esta es una descripción de ejemplo para mostrar cómo aparecerán tus publicaciones de feeds RSS con los ajustes de tamaño de texto actuales.';

  @override
  String get feedsSettingsSheetResetToDefaults =>
      'Restablecer valores predeterminados';

  @override
  String feedsSettingsSheetPointSize(Object value) {
    return '${value}pt';
  }

  @override
  String get xmtpSettingsSheetTitle => 'Configuración de XMTP';

  @override
  String get xmtpSettingsSheetReadReceiptsHeader => 'Confirmaciones de lectura';

  @override
  String get xmtpSettingsSheetReadReceiptsDescription =>
      'Controla si envías y muestras confirmaciones de lectura. Nota: la red XMTP es abierta, puedes elegir ver las confirmaciones que otros envían sin enviar las tuyas.';

  @override
  String get xmtpSettingsSheetSendReadReceiptsTitle =>
      'Enviar confirmaciones de lectura';

  @override
  String get xmtpSettingsSheetSendReadReceiptsSubtitle =>
      'Avisa a otros cuando hayas leído sus mensajes';

  @override
  String get xmtpSettingsSheetDisplayReadReceiptsTitle =>
      'Mostrar confirmaciones de lectura';

  @override
  String get xmtpSettingsSheetDisplayReadReceiptsSubtitle =>
      'Muestra cuándo otros han leído tus mensajes';

  @override
  String get xmtpSettingsSheetDeniedConvosButton => 'Conversaciones bloqueadas';

  @override
  String get addCustomFeedSheetTitleList => 'Agrega un feed a esta lista';

  @override
  String get addCustomFeedSheetTitleFollow => 'Sigue un feed';

  @override
  String get addCustomFeedSheetUrlHint => 'https://example.com/feed.xml';

  @override
  String get addCustomFeedSheetCheckButton => 'Revisar feed';

  @override
  String get addCustomFeedSheetNoPostsError =>
      'Llegamos a esa URL pero no tenía posts. Verifica que sea la URL de un feed, no el sitio web al que pertenece.';

  @override
  String addCustomFeedSheetHttpError(Object code) {
    return 'El servidor devolvió HTTP $code. Revisa la URL e intenta de nuevo.';
  }

  @override
  String get addCustomFeedSheetNetworkError =>
      'No pudimos llegar a esa URL. Revisa tu conexión y la dirección, luego intenta de nuevo.';

  @override
  String get addCustomFeedSheetReadError =>
      'No pudimos leer eso como un feed. Asegúrate de que sea una URL directa de RSS, Atom o JSON Feed (no el sitio web al que pertenece).';

  @override
  String get addCustomFeedSheetSaveError =>
      'No se pudo guardar el feed. Por favor intenta de nuevo.';

  @override
  String get addCustomFeedSheetUntitledFeed => 'Feed sin título';

  @override
  String get addCustomFeedSheetUntitledPost => '(post sin título)';

  @override
  String get addCustomFeedSheetLocalOnlyNote =>
      'Este feed se agrega solo a este cliente — no se publica en la cadena y no aparecerá para nadie más.';

  @override
  String get addCustomFeedSheetAddToListButton => 'Agregar a la lista';

  @override
  String get addCustomFeedSheetFollowFeedButton => 'Seguir feed';

  @override
  String get addToListBottomSheetTitle => 'Administrar listas RSS';

  @override
  String get addToListBottomSheetDefaultFeedTitle => 'RSS Feed';

  @override
  String get addToListBottomSheetSaveChanges => 'Guardar cambios';

  @override
  String get addToListBottomSheetCreateNew => 'Crear nueva lista';

  @override
  String get addToListBottomSheetCreateNewSubtitle =>
      'Agrega este feed a una lista dedicada';

  @override
  String addToListBottomSheetCreatedList(Object name) {
    return 'Lista \"$name\" creada';
  }

  @override
  String get addToListBottomSheetFailedCreate => 'No se pudo crear la lista';

  @override
  String get addToListBottomSheetNoChanges => 'Sin cambios';

  @override
  String addToListBottomSheetAddedToLists(int addedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      addedCount,
      locale: localeName,
      other: '$addedCount listas',
      one: '1 lista',
    );
    return 'Agregado a $_temp0';
  }

  @override
  String addToListBottomSheetRemovedFromLists(int removedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '$removedCount listas',
      one: '1 lista',
    );
    return 'Eliminado de $_temp0';
  }

  @override
  String addToListBottomSheetAddedAndRemoved(
      Object addedCount, int removedCount) {
    String _temp0 = intl.Intl.pluralLogic(
      removedCount,
      locale: localeName,
      other: '$removedCount listas',
      one: '1 lista',
    );
    return 'Agregado a $addedCount, eliminado de $_temp0';
  }

  @override
  String get addToListBottomSheetErrorLoading =>
      'No se pudieron cargar las listas';

  @override
  String get addToListBottomSheetErrorSaving =>
      'No se pudieron guardar los cambios';

  @override
  String get addToListBottomSheetErrorCreating => 'No se pudo crear la lista';

  @override
  String get addToListsSheetTitle => 'Agregar a listas';

  @override
  String get addToListsSheetSectionSingleFollow => 'SEGUIR';

  @override
  String get addToListsSheetSectionFollowAsSingle => 'SEGUIR';

  @override
  String get addToListsSheetSectionLists => 'LISTAS';

  @override
  String get addToListsSheetVia => 'vía';

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
  String get addToListsSheetCreateNewList => 'Crear una nueva lista';

  @override
  String get addToListsSheetSave => 'Guardar';

  @override
  String addToListsSheetUnfollowTitle(Object feed) {
    return '¿Dejar de seguir $feed?';
  }

  @override
  String get addToListsSheetUnfollowBody =>
      'Esto elimina el seguimiento. El feed permanece en cualquier otra lista a la que lo hayas agregado.';

  @override
  String get addToListsSheetUnfollowAction => 'Dejar de seguir';

  @override
  String addToListsSheetAddedToLists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Agregado a $count listas',
      one: 'Agregado a 1 lista',
    );
    return '$_temp0';
  }

  @override
  String addToListsSheetRemovedFromLists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eliminado de $count listas',
      one: 'Eliminado de 1 lista',
    );
    return '$_temp0';
  }

  @override
  String addToListsSheetFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fallaron',
      one: '1 falló',
    );
    return '$_temp0';
  }

  @override
  String get addToListsSheetNoChanges => 'Sin cambios';

  @override
  String get addToListsSheetCreatedButFailedToAdd =>
      'Lista creada pero no se pudo agregar el feed';

  @override
  String get addToListsSheetFailedToCreateSingle =>
      'No se pudo crear el seguimiento';

  @override
  String get addToListsSheetFailedToUnfollow => 'No se pudo dejar de seguir';

  @override
  String get commentCardTranslating => 'Traduciendo…';

  @override
  String get commentCardTranslateWaitingWifi => 'Esperando Wi-Fi…';

  @override
  String get commentCardTranslateDownloadingLang => 'Descargando idioma…';

  @override
  String get commentCardDownloadLangPackTitle =>
      '¿Descargar paquete de idioma?';

  @override
  String commentCardDownloadLangPackBody(Object from, Object to) {
    return 'Traducir $from → $to necesita un paquete de idioma sin conexión (~30 MB cada uno, se descarga una vez y luego funciona totalmente en el dispositivo).';
  }

  @override
  String get commentCardDownload => 'Descargar';

  @override
  String get commentCardTranslateFailed => 'Falló la traducción';

  @override
  String commentCardTranslateFrom(Object lang) {
    return 'Traducir de $lang';
  }

  @override
  String commentCardTranslatedFrom(Object lang) {
    return 'Traducido de $lang · Ver original';
  }

  @override
  String commentCardShowTranslation(Object lang) {
    return 'Ver traducción ($lang)';
  }

  @override
  String get commentCardDeleteTitle => '¿Eliminar comentario?';

  @override
  String get commentCardDeleteBody =>
      'Esto elimina el comentario y todas las respuestas debajo. No se puede deshacer.';

  @override
  String get commentCardDelete => 'Eliminar';

  @override
  String get commentCardDeleted => '[eliminado]';

  @override
  String get commentCardLoadMoreReplies => 'Cargar más respuestas';

  @override
  String get commentCardEdited => '(editado)';

  @override
  String get commentCardCopyText => 'Copiar texto';

  @override
  String get commentCardEdit => 'Editar';

  @override
  String get commentCardBlockFromCommenting => 'Bloquear comentarios';

  @override
  String get commentCardCommentCopied => 'Comentario copiado';

  @override
  String get commentCardBlockTitle => '¿Bloquear comentarios?';

  @override
  String commentCardBlockBody(Object addr) {
    return 'Agrega una regla de bloqueo permanente para $addr en esta publicación. No podrá comentar aquí. Puedes ajustar o quitar la regla desde el menú de la publicación → Reglas de comentarios.';
  }

  @override
  String get commentCardBlock => 'Bloquear';

  @override
  String get commentCardSave => 'Guardar';

  @override
  String get commentCardVote => 'Votar';

  @override
  String get commentCardReply => 'Responder';

  @override
  String commentCardReplyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count respuestas',
      one: '1 respuesta',
    );
    return '$_temp0';
  }

  @override
  String get commentRulesSheetLoadFailed =>
      'No se pudieron cargar las reglas de comentarios';

  @override
  String get commentRulesSheetAddFailed => 'No se pudo agregar la regla';

  @override
  String get commentRulesSheetRemoveFailed => 'No se pudo quitar la regla';

  @override
  String get commentRulesSheetTitle => 'Reglas de comentarios';

  @override
  String get commentRulesSheetDescription =>
      'Anula quién puede comentar en esta publicación. Permitir deja que la dirección se salte las restricciones del canal; Denegar la bloquea aunque el canal esté abierto. Cada regla es permanente a menos que fijes una fecha para que se levante.';

  @override
  String get commentRulesSheetEmptyTitle => 'Aún no hay reglas';

  @override
  String get commentRulesSheetEmptyBody =>
      'Se aplica la política de comentarios del canal.';

  @override
  String get commentRulesSheetDenyUntil => 'DENEGAR HASTA';

  @override
  String get commentRulesSheetAllowUntil => 'PERMITIR HASTA';

  @override
  String get commentRulesSheetDenyForever =>
      'Denegar siempre — sin fecha de fin';

  @override
  String get commentRulesSheetAllowForever =>
      'Permitir siempre — sin fecha de fin';

  @override
  String get commentRulesSheetAllow => 'Permitir';

  @override
  String get commentRulesSheetDeny => 'Denegar';

  @override
  String get commentRulesSheetAddButton => 'Agregar';

  @override
  String get commentRulesSheetJustNow => 'ahora mismo';

  @override
  String commentRulesSheetMinutesAgo(Object minutes) {
    return 'hace $minutes min';
  }

  @override
  String commentRulesSheetHoursAgo(Object hours) {
    return 'hace $hours h';
  }

  @override
  String commentRulesSheetDaysAgo(Object days) {
    return 'hace $days d';
  }

  @override
  String get commentRulesSheetChipDeny => 'DENEGAR';

  @override
  String get commentRulesSheetChipAllow => 'PERMITIR';

  @override
  String get createListBottomSheetNameRequired =>
      'Escribe un nombre para la lista';

  @override
  String createListBottomSheetUpdatedList(Object name) {
    return 'Lista \"$name\" actualizada';
  }

  @override
  String createListBottomSheetCreatedList(Object name) {
    return 'Lista \"$name\" creada';
  }

  @override
  String get createListBottomSheetUpdateFailed =>
      'No se pudo actualizar la lista';

  @override
  String get createListBottomSheetCreateFailed => 'No se pudo crear la lista';

  @override
  String get createListBottomSheetEditTitle => 'Editar lista RSS';

  @override
  String get createListBottomSheetCreateTitle => 'Crear lista RSS';

  @override
  String get createListBottomSheetEditSubtitle =>
      'Actualiza el nombre y el icono de la lista';

  @override
  String get createListBottomSheetCreateSubtitle =>
      'Crea una nueva lista para organizar feeds RSS';

  @override
  String get createListBottomSheetNameLabel => 'Nombre de la lista';

  @override
  String get createListBottomSheetNameHint =>
      'Escribe un nombre para tu lista RSS';

  @override
  String get createListBottomSheetUpdateButton => 'Actualizar';

  @override
  String get createListBottomSheetCreateButton => 'Crear';

  @override
  String get discoverContactRowRssTooltip => 'RSS';

  @override
  String get discoverContactRowWebsiteTooltip => 'Sitio web';

  @override
  String editListBottomSheetRemovedFromList(Object name) {
    return 'Quitaste \"$name\" de la lista';
  }

  @override
  String get editListBottomSheetRemoveFailed =>
      'No se pudo quitar el feed de la lista';

  @override
  String get editListBottomSheetRemoveFeedError => 'Error al quitar el feed';

  @override
  String get editListBottomSheetRemoveFeedTitle => 'Quitar feed';

  @override
  String editListBottomSheetRemoveConfirm(Object name) {
    return '¿Seguro que quieres quitar \"$name\" de esta lista?';
  }

  @override
  String get editListBottomSheetRemove => 'Quitar';

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
  String get editListBottomSheetNoFeeds => 'No hay feeds en esta lista';

  @override
  String get editListBottomSheetEmptyHint =>
      'Agrega feeds a esta lista explorando feeds RSS y usando el botón \"Agregar a lista\".';

  @override
  String get editListBottomSheetRssFeed => 'Feed RSS';

  @override
  String get editListBottomSheetRemoveTooltip => 'Quitar de la lista';

  @override
  String get editListBottomSheetDone => 'Listo';

  @override
  String get editListSheetTitleEdit => 'Editar lista';

  @override
  String get editListSheetTitleNew => 'Nueva lista';

  @override
  String get editListSheetNameHint => 'Nombre de la lista';

  @override
  String get editListSheetIconHint => 'Toca el icono para cambiarlo.';

  @override
  String get editListSheetSave => 'Guardar';

  @override
  String get editListSheetCreate => 'Crear lista';

  @override
  String get editListSheetFailedUpdate => 'No se pudo actualizar la lista';

  @override
  String get editListSheetFailedCreate => 'No se pudo crear la lista';

  @override
  String get editPostBottomSheetErrorTitle => 'Error';

  @override
  String get editPostBottomSheetOk => 'OK';

  @override
  String get editPostBottomSheetErrorMissingChannel =>
      'No se puede actualizar el post: falta el slug del canal';

  @override
  String get editPostBottomSheetUpdateSuccess =>
      'Post actualizado correctamente';

  @override
  String editPostBottomSheetUpdateFailed(Object error) {
    return 'No se pudo actualizar el post: $error';
  }

  @override
  String get editPostBottomSheetUnknownError => 'Error desconocido';

  @override
  String get editPostBottomSheetHeaderTitle => 'Editar post';

  @override
  String get editPostBottomSheetHeaderSubtitle =>
      'Actualiza el contenido de tu post';

  @override
  String get editPostBottomSheetTitleLabel => 'Titulo';

  @override
  String get editPostBottomSheetTitleHint => 'Agrega un titulo (opcional)';

  @override
  String get editPostBottomSheetContentLabel => 'Contenido';

  @override
  String get editPostBottomSheetContentHint =>
      'Escribe el contenido de tu post aqui...';

  @override
  String get editPostBottomSheetContentRequired =>
      'El contenido es obligatorio';

  @override
  String get editPostBottomSheetMediaLabel => 'Medios';

  @override
  String get editPostBottomSheetMediaHelper => 'Imagen destacada opcional';

  @override
  String get editPostBottomSheetInvalidUrl => 'Ingresa una URL valida';

  @override
  String get editPostBottomSheetSummaryLabel => 'Resumen';

  @override
  String get editPostBottomSheetSummaryHint =>
      'Descripcion breve para vistas previas...';

  @override
  String get editPostBottomSheetSummaryHelper =>
      'Resumen corto que se muestra en las vistas previas de los feeds';

  @override
  String get editPostBottomSheetExternalLinkLabel => 'Enlace externo';

  @override
  String get editPostBottomSheetExternalLinkHelper =>
      'Enlace opcional a contenido externo';

  @override
  String get editPostBottomSheetTagsLabel => 'Etiquetas';

  @override
  String get editPostBottomSheetTagsHint => 'tecnologia, noticias, tutorial';

  @override
  String get editPostBottomSheetTagsHelper => 'Etiquetas separadas por comas';

  @override
  String get editPostBottomSheetSaving => 'Guardando...';

  @override
  String get editPostBottomSheetSaveChanges => 'Guardar cambios';

  @override
  String get emojiPickerDialogSearchHint => 'Buscar emoji...';

  @override
  String get emojiPickerDialogNoResults => 'No se encontró ningún emoji';

  @override
  String get emojiPickerDialogCategorySmileys => 'Caritas';

  @override
  String get emojiPickerDialogCategoryPeople => 'Personas';

  @override
  String get emojiPickerDialogCategoryNature => 'Naturaleza';

  @override
  String get emojiPickerDialogCategoryFood => 'Comida';

  @override
  String get emojiPickerDialogCategoryActivities => 'Actividades';

  @override
  String get emojiPickerDialogCategoryTravel => 'Viajes';

  @override
  String get emojiPickerDialogCategoryObjects => 'Objetos';

  @override
  String get emojiPickerDialogCategorySymbols => 'Símbolos';

  @override
  String get emojiPickerDialogCategoryFlags => 'Banderas';

  @override
  String get emojiPickerDialogCategoryMostUsed => 'Más usados';

  @override
  String get feedsNavigationDrawerSectionLists => 'LISTAS';

  @override
  String get feedsNavigationDrawerManageListsTooltip => 'Gestionar listas';

  @override
  String get feedsNavigationDrawerNoListsYet =>
      'Aún no hay listas. Toca el icono de arriba para crear una.';

  @override
  String get feedsNavigationDrawerSectionMyChannels => 'MIS CANALES';

  @override
  String get feedsNavigationDrawerCreateChannel => 'Crear canal';

  @override
  String get feedsNavigationDrawerBookmarks => 'Guardados';

  @override
  String get feedsNavigationDrawerManageServer => 'Gestionar servidor';

  @override
  String get feedsNavigationDrawerReadingSettings => 'Ajustes del lector';

  @override
  String get feedsNavigationDrawerHeaderTitle => 'FEEDS';

  @override
  String get feedsNavigationDrawerVia => 'vía';

  @override
  String get feedsSettingsSheetTitleSizeLabel => 'TAMAÑO DEL TÍTULO';

  @override
  String get feedsSettingsSheetBodySizeLabel => 'TAMAÑO DEL CUERPO';

  @override
  String get feedsSettingsSheetTrimAtLabel => 'RECORTAR EN';

  @override
  String get feedsSettingsSheetTrimUnit => 'caracteres';

  @override
  String get feedsSettingsSheetSwipeSnapLabel =>
      'DESLIZAR AL SIGUIENTE EN MENOS DE';

  @override
  String get feedsSettingsSheetSwipeSnapOnLabel => 'DESLIZAR Y AJUSTAR';

  @override
  String get feedsSettingsSheetSwipeSnapOnOn =>
      'Un deslizamiento rápido avanza un post';

  @override
  String get feedsSettingsSheetSwipeSnapOnOff => 'Desplazamiento normal';

  @override
  String get feedsSettingsSheetPreviewLabel => 'Vista previa';

  @override
  String get feedsSettingsSheetJustNow => 'ahora mismo';

  @override
  String get feedsSettingsSheetVia => 'vía';

  @override
  String get feedsSettingsSheetLayoutLabel => 'DISEÑO';

  @override
  String get feedsSettingsSheetLayoutCompact => 'Compacto';

  @override
  String get feedsSettingsSheetLayoutWide => 'Amplio';

  @override
  String get feedsSettingsSheetTrimLongPostsLabel =>
      'RECORTAR PUBLICACIONES LARGAS';

  @override
  String get feedsSettingsSheetTrimLongPostsOn =>
      'Colapsa resumen + cuerpo a un largo máximo';

  @override
  String get feedsSettingsSheetTrimLongPostsOff =>
      'Muestra la publicación completa en cada tarjeta';

  @override
  String get feedsSettingsSheetTranslationsLabel =>
      'TRADUCCIONES EN EL DISPOSITIVO';

  @override
  String get feedsSettingsSheetTranslationsOn =>
      'Sugiere traducir publicaciones en otros idiomas';

  @override
  String get feedsSettingsSheetTranslationsOff =>
      'Sin sugerencias de traducción en publicaciones ni comentarios';

  @override
  String get feedsSettingsSheetWifiOnlyLabel =>
      'DESCARGAR PAQUETES SOLO POR WI-FI';

  @override
  String get feedsSettingsSheetWifiOnlyOn =>
      'Los paquetes esperan Wi-Fi — no usan datos móviles';

  @override
  String get feedsSettingsSheetWifiOnlyOff =>
      'Los paquetes pueden descargarse con datos móviles';

  @override
  String get feedsSettingsSheetSuggestFromLabel => 'SUGERIR TRADUCIR DESDE';

  @override
  String get feedsSettingsSheetGroupLayout => 'Diseño y texto';

  @override
  String get feedsSettingsSheetGroupLanding => 'Al abrir';

  @override
  String get feedsSettingsSheetLandingHint => 'Lo que ves al abrir Feeds.';

  @override
  String get feedsSettingsSheetGroupScrolling => 'Desplazamiento';

  @override
  String get feedsSettingsSheetGroupVideo => 'Video';

  @override
  String get feedsSettingsSheetGroupReactions => 'Reacciones';

  @override
  String get feedsSettingsSheetDoubleTapLabel => 'EL DOBLE TOQUE AGREGA';

  @override
  String get feedsSettingsSheetDoubleTapHint =>
      'La reacción que agrega un doble toque en una publicación. Toca para elegir.';

  @override
  String get feedsSettingsSheetGroupSignature => 'Firma';

  @override
  String get feedsSettingsSheetSigShimmerLabel =>
      'CONFIRMACIÓN VISUAL DE FIRMA';

  @override
  String get feedsSettingsSheetSigShimmerOn =>
      'El nombre de un autor verificado brilla en arcoíris por sí solo.';

  @override
  String get feedsSettingsSheetSigShimmerOff =>
      'Apagado. Solo quedan las marcas ! de las publicaciones sin firmar.';

  @override
  String get feedsSettingsSheetSigShimmerEveryLabel => 'BRILLAR CADA';

  @override
  String get feedsSettingsSheetSigShimmerEveryHint =>
      'De 4 a 10 segundos entre cada pasada.';

  @override
  String get feedsSettingsSheetGroupTranslation => 'Traducción';

  @override
  String get feedsSettingsSheetGroupSignin => 'Inicio de sesión en canales';

  @override
  String get feedsSettingsSheetVideoAutoplayLabel => 'REPRODUCIR VIDEOS SOLOS';

  @override
  String get feedsSettingsSheetVideoAutoplayOn =>
      'Los videos se reproducen sin sonido al pasar';

  @override
  String get feedsSettingsSheetVideoAutoplayOff => 'Cada video espera un toque';

  @override
  String get feedsSettingsSheetVideoAutoloadLabel => 'REPRODUCIR SOLOS HASTA';

  @override
  String get feedsSettingsSheetVideoAutoloadHint =>
      'Los videos más grandes muestran su tamaño y esperan un toque';

  @override
  String get feedsSettingsSheetVideoAlwaysAsk => 'Preguntar siempre';

  @override
  String get feedsSettingsSheetVideoNoLimit => 'Sin límite';

  @override
  String get feedsSettingsSheetReset => 'Restablecer valores predeterminados';

  @override
  String get manageListsBottomSheetTitle => 'Gestionar listas';

  @override
  String manageListsBottomSheetListCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listas',
      one: '1 lista',
    );
    return '$_temp0';
  }

  @override
  String get manageListsBottomSheetEmptyTitle => 'Aún no hay listas';

  @override
  String get manageListsBottomSheetEmptySubtitle =>
      'Crea tu primera lista para organizar feeds RSS.';

  @override
  String get manageListsBottomSheetDefaultBadge => 'PREDETERMINADA';

  @override
  String manageListsBottomSheetCreatedDate(Object date) {
    return 'Creada $date';
  }

  @override
  String get manageListsBottomSheetCollapse => 'Contraer';

  @override
  String get manageListsBottomSheetExpand => 'Expandir';

  @override
  String get manageListsBottomSheetEditTooltip => 'Editar lista';

  @override
  String get manageListsBottomSheetDeleteTooltip => 'Eliminar lista';

  @override
  String get manageListsBottomSheetNoFeeds => 'No hay feeds en esta lista';

  @override
  String get manageListsBottomSheetRssFeedFallback => 'Feed RSS';

  @override
  String get manageListsBottomSheetRemoveFromListTooltip =>
      'Quitar de la lista';

  @override
  String get manageListsBottomSheetCreateButton => 'Crear lista';

  @override
  String manageListsBottomSheetRemovedSnack(Object title) {
    return 'Se quitó \"$title\" de la lista';
  }

  @override
  String get manageListsBottomSheetRemoveFailed =>
      'No se pudo quitar el feed de la lista';

  @override
  String manageListsBottomSheetDeletedSnack(Object name) {
    return 'Lista \"$name\" eliminada';
  }

  @override
  String get manageListsBottomSheetDeleteFailed =>
      'No se pudo eliminar la lista';

  @override
  String get manageListsBottomSheetRemoveDialogTitle => 'Quitar feed';

  @override
  String manageListsBottomSheetRemoveDialogBody(Object name) {
    return '¿Quieres quitar este feed de \"$name\"?';
  }

  @override
  String get manageListsBottomSheetRemoveButton => 'Quitar';

  @override
  String get manageListsBottomSheetDeleteDialogTitle => 'Eliminar lista';

  @override
  String manageListsBottomSheetDeleteDialogBody(Object name) {
    return '¿Seguro que quieres eliminar \"$name\"?';
  }

  @override
  String get manageListsBottomSheetDeleteWarning =>
      'Advertencia: esta acción no se puede deshacer. Todos los feeds de esta lista se quitarán de ella.';

  @override
  String get manageListsBottomSheetDeleteButton => 'Eliminar';

  @override
  String get manageListsBottomSheetDateToday => 'hoy';

  @override
  String get manageListsBottomSheetDateYesterday => 'ayer';

  @override
  String manageListsBottomSheetDateDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get manageListsBottomSheetDateRecently => 'recientemente';

  @override
  String get manageListsSheetTitle => 'Gestionar listas';

  @override
  String get manageListsSheetAddFeed => 'Agregar un feed';

  @override
  String get manageListsSheetDeleteListTitle => '¿Eliminar lista?';

  @override
  String manageListsSheetDeleteListBody(Object name) {
    return 'Eliminar \"$name\" solo quita la lista; los feeds que contiene siguen suscritos en cualquier otro lugar donde los tengas.';
  }

  @override
  String get manageListsSheetDelete => 'Eliminar';

  @override
  String get manageListsSheetFailedDeleteList => 'No se pudo eliminar la lista';

  @override
  String get manageListsSheetDefaultBadge => 'PREDETERMINADA';

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
  String get manageListsSheetFollowedAccounts => 'CUENTAS SEGUIDAS';

  @override
  String get manageListsSheetIndividualFeeds => 'FEEDS INDIVIDUALES';

  @override
  String get manageListsSheetFollowingEmpty =>
      'Aún no sigues a nadie: sigue a tus amigos desde su perfil o agrega la URL de un feed abajo.';

  @override
  String get manageListsSheetFollowingAccount => 'Siguiendo';

  @override
  String get manageListsSheetMutedBadge => 'silenciado';

  @override
  String manageListsSheetFollowingAllChannels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'siguiendo los $count canales',
      one: 'siguiendo 1 canal',
    );
    return '$_temp0';
  }

  @override
  String manageListsSheetFollowingSomeChannels(int followed, int total) {
    return 'siguiendo $followed/$total canales';
  }

  @override
  String get manageListsSheetEditTooltip => 'Editar';

  @override
  String get manageListsSheetUnfollowTooltip => 'Dejar de seguir';

  @override
  String get manageListsSheetCollapseTooltip => 'Contraer';

  @override
  String get manageListsSheetExpandTooltip => 'Expandir';

  @override
  String get manageListsSheetFailedRequestAccess =>
      'No se pudo solicitar acceso';

  @override
  String get manageListsSheetRemoveFeedTitle => '¿Quitar feed?';

  @override
  String manageListsSheetRemoveFeedBody(Object feedName, Object listName) {
    return '¿Quitar \"$feedName\" de \"$listName\"?';
  }

  @override
  String get manageListsSheetRemovePersonTitle => '¿Quitar persona?';

  @override
  String manageListsSheetRemovePersonBody(Object name, Object listName) {
    return '¿Quitar a $name de \"$listName\"? Sus canales dejan de aparecer en esta lista.';
  }

  @override
  String manageListSheetTitle(Object listName) {
    return 'Gestionar $listName';
  }

  @override
  String postsListNewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nuevos',
      one: '1 nuevo',
    );
    return '$_temp0';
  }

  @override
  String get listHeaderEmpty =>
      'Sigue a alguien o agrega un feed para empezar.';

  @override
  String listHeaderPeopleWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'personas',
      one: 'persona',
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
  String get manageListsSheetRemove => 'Quitar';

  @override
  String get manageListsSheetFailedRemoveFeed => 'No se pudo quitar el feed';

  @override
  String get manageListsSheetNoFeedsYet => 'Aún no hay feeds en esta lista.';

  @override
  String get manageListsSheetNoAccessBadge => 'SIN ACCESO';

  @override
  String get manageListsSheetPendingBadge => 'PENDIENTE';

  @override
  String get manageListsSheetRequestAccessTooltip => 'Solicitar acceso';

  @override
  String get manageListsSheetRemoveFromListTooltip => 'Quitar de la lista';

  @override
  String get manageListsSheetCreateNewList => 'Crear nueva lista';

  @override
  String get manageListsSheetNoListsYet => 'Aún no hay listas';

  @override
  String get manageListsSheetVia => 'vía';

  @override
  String newPostBottomSheetFailedToCreate(Object error) {
    return 'No se pudo crear la publicación: $error';
  }

  @override
  String get newPostBottomSheetUnknownError => 'Error desconocido';

  @override
  String get newPostBottomSheetErrorCreating => 'Error al crear la publicación';

  @override
  String get newPostBottomSheetErrorTitle => 'Error';

  @override
  String get newPostBottomSheetOk => 'OK';

  @override
  String get newPostBottomSheetDestinationChannel => 'Canal de destino';

  @override
  String get newPostBottomSheetSelectChannelHint =>
      'Elige un canal para tu publicación';

  @override
  String get newPostBottomSheetSelectChannelError => 'Elige un canal';

  @override
  String get newPostBottomSheetModeUpdate => 'Novedad';

  @override
  String get newPostBottomSheetModeArticle => 'Artículo';

  @override
  String get newPostBottomSheetNoChannelsTitle => 'No hay canales disponibles';

  @override
  String get newPostBottomSheetNoChannelsBody =>
      'Crea al menos un canal antes de publicar.';

  @override
  String get newPostBottomSheetHeaderTitle => 'Nueva publicación';

  @override
  String newPostBottomSheetPostToChannel(Object channel) {
    return 'Publicar en $channel';
  }

  @override
  String get newPostBottomSheetUpdateSubtitle =>
      'Una novedad rápida para tus seguidores';

  @override
  String get newPostBottomSheetArticleSubtitle =>
      'Artículo completo con todos los detalles';

  @override
  String get newPostBottomSheetTitleLabel => 'Título';

  @override
  String get newPostBottomSheetTitleHintUpdate => 'Agrega un título (opcional)';

  @override
  String get newPostBottomSheetTitleHintArticle =>
      'Escribe un título atractivo...';

  @override
  String get newPostBottomSheetContentLabel => 'Contenido';

  @override
  String get newPostBottomSheetContentHintUpdate =>
      'Comparte lo que piensas...';

  @override
  String get newPostBottomSheetContentHintArticle =>
      'Escribe aquí el contenido completo de tu publicación...';

  @override
  String get newPostBottomSheetContentRequired => 'El contenido es obligatorio';

  @override
  String get newPostBottomSheetMediaLabel => 'Multimedia';

  @override
  String get newPostBottomSheetMediaHelper => 'Imagen destacada opcional';

  @override
  String get newPostBottomSheetInvalidUrl => 'Ingresa una URL válida';

  @override
  String get newPostBottomSheetSummaryLabel => 'Resumen';

  @override
  String get newPostBottomSheetSummaryHint =>
      'Descripción breve para las vistas previas...';

  @override
  String get newPostBottomSheetSummaryHelper =>
      'Resumen breve que se muestra en las vistas previas del canal';

  @override
  String get newPostBottomSheetExternalLinkLabel => 'Enlace externo';

  @override
  String get newPostBottomSheetExternalLinkHelper =>
      'Enlace opcional a contenido externo';

  @override
  String get newPostBottomSheetTagsLabel => 'Etiquetas';

  @override
  String get newPostBottomSheetTagsHint => 'tecnología, noticias, tutorial';

  @override
  String get newPostBottomSheetTagsHelper => 'Etiquetas separadas por comas';

  @override
  String get newPostBottomSheetPosting => 'Publicando...';

  @override
  String get newPostBottomSheetCreatePost => 'Crear publicación';

  @override
  String get postDetailPagePostFallback => 'Publicación';

  @override
  String get postDetailPageCommentsUnavailable =>
      'Los comentarios no están disponibles para esta publicación';

  @override
  String get postDetailPageAddReplyHint => 'Agrega una respuesta';

  @override
  String get postDetailPageAddCommentHint => 'Agrega un comentario';

  @override
  String get postDetailPageReplyingTo => 'Respondiendo a';

  @override
  String get postDetailPageCancelReplyTooltip => 'Cancelar respuesta';

  @override
  String get postDetailPageCannotBlockMissingSlug =>
      'No se puede bloquear: falta el slug del canal';

  @override
  String get postDetailPageBlockedFromCommenting =>
      'Bloqueado para comentar en esta publicación';

  @override
  String get postSourceDetailsPageTitle => 'Fuente del post';

  @override
  String get postSourceDetailsPageUnknownChannel => 'canal desconocido';

  @override
  String postSourceDetailsPagePostedIn(Object channel) {
    return 'publicado en $channel';
  }

  @override
  String get postSourceDetailsPageDiscoveredVia => 'DESCUBIERTO VÍA';

  @override
  String get postSourceDetailsPageFoundOn => 'Encontrado en';

  @override
  String get postSourceDetailsPageFoundOnSubtitle =>
      'el perfil cuya pestaña de registros lleva esta URL de feed';

  @override
  String get postSourceDetailsPageWho => 'QUIÉN';

  @override
  String get postSourceDetailsPageChannelOwner => 'Dueño del canal';

  @override
  String get postSourceDetailsPageChannelOwnerSubtitle =>
      'en cuyo canal vive este post';

  @override
  String get postSourceDetailsPagePostAuthor => 'Autor del post';

  @override
  String get postSourceDetailsPagePostAuthorSubtitle => 'quién creó este post';

  @override
  String get postSourceDetailsPageSignedBy => 'Firmado por';

  @override
  String postSourceDetailsPageSessionOf(Object name) {
    return 'sesión de $name';
  }

  @override
  String get postSourceDetailsPageResolvingParent =>
      'resolviendo cuenta principal…';

  @override
  String get postSourceDetailsPageWhoHeldKey =>
      'quién tenía la llave cuando se firmó el post';

  @override
  String get postSourceDetailsPageTechnicalDetails => 'DETALLES TÉCNICOS';

  @override
  String get postSourceDetailsPageHide => 'ocultar';

  @override
  String get postSourceDetailsPageShow => 'mostrar';

  @override
  String get postSourceDetailsPageSectionIdentifiers => 'IDENTIFICADORES';

  @override
  String get postSourceDetailsPageSectionServer => 'SERVIDOR';

  @override
  String get postSourceDetailsPageSectionSource => 'FUENTE';

  @override
  String get postSourceDetailsPageSectionContent => 'CONTENIDO';

  @override
  String get postSourceDetailsPageSectionTimestamps => 'MARCAS DE TIEMPO';

  @override
  String get postSourceDetailsPageSectionEngagement => 'INTERACCIÓN';

  @override
  String get postSourceDetailsPageSectionSignature => 'FIRMA';

  @override
  String get postSourceDetailsPageNone => 'Ninguno';

  @override
  String get postSourceDetailsPageCopied => 'Copiado';

  @override
  String postSourceDetailsPageHeroMedia(Object count) {
    return 'MEDIOS PRINCIPALES ($count)';
  }

  @override
  String postSourceDetailsPageSupportMedia(Object count) {
    return 'MEDIOS DE APOYO ($count)';
  }

  @override
  String get postSourceDetailsPageAudio => 'AUDIO';

  @override
  String postSourceDetailsPageAuthors(Object count) {
    return 'AUTORES ($count)';
  }

  @override
  String postSourceDetailsPageTags(Object count) {
    return 'ETIQUETAS ($count)';
  }

  @override
  String get postSourceDetailsPageSignatureChecked => 'Firma verificada';

  @override
  String get postSourceDetailsPageSignatureChecking => 'Comprobando la firma…';

  @override
  String get postSourceDetailsPageSignatureUnchecked => 'Firma sin comprobar';

  @override
  String get postSourceDetailsPageBadSignature => 'Firma inválida';

  @override
  String get postSourceDetailsPageNoSignature => 'Sin firma';

  @override
  String get postSourceDetailsPageRawJson => 'JSON CRUDO';

  @override
  String get postSourceDetailsPageCopy => 'Copiar';

  @override
  String get postSourceDetailsPageShowLess => 'Mostrar menos';

  @override
  String get postSourceDetailsPageShowMore => 'Mostrar más';

  @override
  String get postsListBookmarkRemoved => 'Marcador eliminado';

  @override
  String get postsListPostBookmarked => 'Publicación guardada en marcadores';

  @override
  String get postsListFeedNotFoundInList =>
      'No se encontró el feed en la lista';

  @override
  String postsListFeedRemovedFromList(Object feedName) {
    return 'Se eliminó \"$feedName\" de la lista';
  }

  @override
  String postsListChannelMuted(Object channelName) {
    return 'Se silenció \"$channelName\"';
  }

  @override
  String get postsListRemoveFeedFailed =>
      'No se pudo eliminar el feed de la lista';

  @override
  String get postsListFeedPrivate => 'Este feed es privado.';

  @override
  String get postsListLoadFailedTitle => 'No se pudo cargar el feed';

  @override
  String get postsListEmptyBookmarksHeadline =>
      'Aún no hay publicaciones en marcadores';

  @override
  String get postsListEmptyBookmarksSubline =>
      'Toca el ícono de marcador en cualquier publicación para guardarla aquí';

  @override
  String get postsListEmptyListHeadline =>
      'Aún no hay publicaciones en esta lista';

  @override
  String get postsListEmptyListSubline =>
      'Agrega feeds a esta lista para ver sus publicaciones aquí.';

  @override
  String get postsListEmptyHeadline => 'Aún no hay publicaciones';

  @override
  String get postsListEmptySubline =>
      'Las nuevas publicaciones aparecerán aquí.';

  @override
  String get postsListChannelNotFoundHeadline => 'Canal no encontrado';

  @override
  String get postsListChannelNotFoundSubline =>
      'Su dueño eliminó o movió este canal.';

  @override
  String get postsListChannelNotFoundUnfollow => 'Dejar de seguir';

  @override
  String get postCardFeedContextOn => 'en';

  @override
  String feedReaderPageUpdated(String ago) {
    return 'actualizado $ago';
  }

  @override
  String get feedReaderPageCopyFeedUrl => 'Copiar URL del feed';

  @override
  String get feedReaderPageFeedUrlCopied => 'URL del feed copiada';

  @override
  String get postsListPrivateFeedsBanner =>
      'Algunos feeds en esta lista son privados y no tienes acceso.';

  @override
  String get privateFeedLockedWidgetNoOwnerAddress =>
      'El canal no tiene dirección de propietario';

  @override
  String get privateFeedLockedWidgetCouldNotResolve =>
      'No se pudo resolver el canal';

  @override
  String get privateFeedLockedWidgetRequestFailed =>
      'No se pudo solicitar acceso';

  @override
  String get privateFeedLockedWidgetCancelFailed =>
      'No se pudo cancelar la solicitud';

  @override
  String get privateFeedLockedWidgetBlurbPending =>
      'Tu solicitud espera a que el propietario del canal la apruebe.';

  @override
  String get privateFeedLockedWidgetBlurbBlocked =>
      'El propietario del canal bloqueó tu acceso. Contáctalo directamente si crees que es un error.';

  @override
  String get privateFeedLockedWidgetBlurbDenied =>
      'Tu solicitud anterior no fue aprobada. Puedes intentar de nuevo.';

  @override
  String get privateFeedLockedWidgetBlurbDefault =>
      'Solo los seguidores aprobados pueden leer este canal. Envía una solicitud al propietario para que te agregue.';

  @override
  String get privateFeedLockedWidgetPrivateBadge => 'PRIVADO';

  @override
  String get privateFeedLockedWidgetPendingChip => 'Pendiente de aprobación';

  @override
  String get privateFeedLockedWidgetCancelRequest => 'Cancelar solicitud';

  @override
  String get privateFeedLockedWidgetRequestAccess => 'Solicitar acceso';

  @override
  String get floatingContactMenuShare => 'Compartir';

  @override
  String get floatingContactMenuDelete => 'Eliminar';

  @override
  String get floatingContactMenuDeleteTitle => 'Eliminar contacto';

  @override
  String floatingContactMenuDeleteConfirm(Object name) {
    return '¿Seguro que quieres quitar \"$name\" de tus marcadores?';
  }

  @override
  String floatingContactMenuShareContactLabel(Object name) {
    return 'Contacto: $name';
  }

  @override
  String floatingContactMenuShareAddressLabel(Object address) {
    return 'Dirección: $address';
  }

  @override
  String floatingContactMenuShareInboxLabel(Object inboxId) {
    return 'ID de Inbox XMTP: $inboxId';
  }

  @override
  String get gridSettingsSheetTitle => 'Ajustes de cuadrícula';

  @override
  String get gridSettingsSheetSectionLayout => 'DISEÑO';

  @override
  String get gridSettingsSheetSectionGridSize => 'TAMAÑO DE CUADRÍCULA';

  @override
  String gridSettingsSheetColumnCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count columnas',
      one: '1 columna',
    );
    return '$_temp0';
  }

  @override
  String get gridSettingsSheetSectionTextSize => 'TAMAÑO DE TEXTO';

  @override
  String get gridSettingsSheetShowBannersLabel =>
      'Mostrar banners de contactos';

  @override
  String get gridSettingsSheetShowBannersSubtitle =>
      'Muestra las imágenes de banner de los contactos detrás de las filas.';

  @override
  String get gridSettingsSheetSectionPreview => 'VISTA PREVIA';

  @override
  String gridSettingsSheetPreviewText(Object label) {
    return 'Texto de muestra — $label';
  }

  @override
  String get gridSettingsSheetLayoutGrid => 'Cuadrícula';

  @override
  String get gridSettingsSheetLayoutRows => 'Filas';

  @override
  String get linkDeviceDialogTitle => 'Vincular esta sesión';

  @override
  String get linkDeviceDialogSubtitleNewAccount =>
      'Elige un nombre de usuario y firma — muéstrale este QR a un ciudadano para acuñar tu cuenta.';

  @override
  String get linkDeviceDialogSubtitleAddSession =>
      'Pega la dirección de tu cuenta y firma. Luego escanea este QR con la app donde tu cuenta ya está abierta.';

  @override
  String get linkDeviceDialogToggleNewAccount => 'CUENTA NUEVA';

  @override
  String get linkDeviceDialogToggleAddSession => 'AGREGAR ESTE DISPOSITIVO';

  @override
  String linkDeviceDialogErrMinChars(Object min) {
    return 'Mín $min caracteres';
  }

  @override
  String linkDeviceDialogErrMaxChars(Object max) {
    return 'Máx $max caracteres';
  }

  @override
  String get linkDeviceDialogErrLeadingNonAlpha => 'Debe empezar con una letra';

  @override
  String get linkDeviceDialogErrTrailing => 'No puede terminar en - o _';

  @override
  String get linkDeviceDialogErrIllegalChar => 'Permitido: a-z A-Z 0-9 - _';

  @override
  String get linkDeviceDialogErrConsecutiveDash => 'Sin -- consecutivos';

  @override
  String get linkDeviceDialogErrConsecutiveUnderscore => 'Sin __ consecutivos';

  @override
  String get linkDeviceDialogLabelUsername => 'Nombre de usuario';

  @override
  String get linkDeviceDialogLabelAccountAddress => 'Dirección de cuenta';

  @override
  String get linkDeviceDialogHintUsername => 'Elige un nombre de usuario';

  @override
  String get linkDeviceDialogAddressCopied => 'Dirección copiada';

  @override
  String get linkDeviceDialogClose => 'CERRAR';

  @override
  String get linkDeviceDialogSign => 'FIRMAR';

  @override
  String get linkDeviceDialogRefresh => 'ACTUALIZAR';

  @override
  String linkDeviceDialogQrExpiresIn(String time) {
    return 'El QR vence en $time';
  }

  @override
  String get linkDeviceDialogLoadFailed =>
      'No se pudo cargar la solicitud guardada';

  @override
  String get linkDeviceDialogSignFailed => 'No se pudo firmar';

  @override
  String get mediaUrlFieldImageUrlLabel => 'URL de imagen';

  @override
  String get mediaUrlFieldClearTooltip => 'Borrar';

  @override
  String get mediaUrlFieldUploading => 'SUBIENDO…';

  @override
  String get mediaUrlFieldUpload => 'SUBIR';

  @override
  String get mediaUrlFieldLow => 'BAJA';

  @override
  String get mediaUrlFieldHd => 'HD';

  @override
  String get mediaUrlFieldCheckingQuota => 'Verificando cuota…';

  @override
  String get mediaUrlFieldQuotaUnavailable => 'Cuota no disponible';

  @override
  String mediaUrlFieldQuotaUsage(Object used, Object total) {
    return 'Cuota: $used MB / $total MB';
  }

  @override
  String mediaUrlFieldQuotaOver(Object amount) {
    return 'EXCEDE por $amount MB';
  }

  @override
  String mediaUrlFieldQuotaAfter(Object amount) {
    return 'Después: $amount MB';
  }

  @override
  String get mediaUrlFieldUploadFailed => 'Falló la subida';

  @override
  String get mediaUrlFieldUploadBlockedSspGate =>
      'Subida bloqueada por la puerta SSP';

  @override
  String get mediaUrlFieldCouldNotLoadImage => 'No se pudo cargar la imagen';

  @override
  String get messageInputNoRecipientSelected =>
      'Ningún destinatario seleccionado.';

  @override
  String get messageInputFailedStartConversation =>
      'No se pudo iniciar la conversación.';

  @override
  String get messageInputFailedSendAttachmentRecipient =>
      'No se pudo enviar el adjunto: destinatario no disponible.';

  @override
  String get messageInputFailedSendAttachment => 'No se pudo enviar el adjunto';

  @override
  String get messageInputFailedSendReply =>
      'No se pudo enviar la respuesta: destinatario no disponible para este chat.';

  @override
  String get messageInputFailedSendRecipient =>
      'No se pudo enviar: destinatario no disponible para este chat.';

  @override
  String get messageInputFailedSendMessage => 'No se pudo enviar el mensaje';

  @override
  String get messageInputNoRecipientAttachment =>
      'Ningún destinatario seleccionado para enviar el adjunto.';

  @override
  String get messageInputImageTooLarge =>
      'Imagen demasiado grande para enviar. Agrega un servidor de feed para enviarla en HD.';

  @override
  String get messageInputFailedSelectAttachment =>
      'No se pudo seleccionar el adjunto';

  @override
  String get messageInputStickerTooLarge => 'Sticker mayor de 1 MB';

  @override
  String get messageInputSubscribeForHd =>
      'Suscríbete a un SSP o agrega un servidor de feed personalizado para enviar imágenes en HD';

  @override
  String get messageInputFeedServer => 'Servidor de feed';

  @override
  String get messageInputReplyAttachment => 'Adjunto';

  @override
  String get messageInputReplyReaction => 'Reacción';

  @override
  String get messageInputReplyReply => 'Respuesta';

  @override
  String get messageInputReplyMessage => 'Mensaje';

  @override
  String get messageInputReplyingTo => 'RESPONDIENDO A';

  @override
  String get messageInputHintSending => 'Enviando...';

  @override
  String get messageInputHintAddDescription => 'Agrega una descripción...';

  @override
  String get messageInputHintTypeMessage => 'Escribe un mensaje...';

  @override
  String get messageInputAttachImage => 'Imagen';

  @override
  String get messageInputAttachDocument => 'Documento';

  @override
  String get messageInputAttachSend => 'Enviar';

  @override
  String get messageInputAttachContact => 'Contacto';

  @override
  String get messageInputAttachLocation => 'Ubicación';

  @override
  String get messageInputAttachComingSoon => 'Próximamente';

  @override
  String get messageInputNoRecipientRemote =>
      'Ningún destinatario seleccionado para enviar el adjunto remoto.';

  @override
  String get messageInputRemoteUrlEmpty =>
      'La URL del adjunto remoto no puede estar vacía.';

  @override
  String get messageInputFailedSendRemoteRecipient =>
      'No se pudo enviar el adjunto remoto: destinatario no disponible.';

  @override
  String get messageInputFailedSendRemote =>
      'No se pudo enviar el adjunto remoto';

  @override
  String get conversationSettingsSheetTitle =>
      'Configuración de la conversación';

  @override
  String get conversationSettingsSheetBlockConversation =>
      'Bloquear conversación';

  @override
  String get conversationSettingsSheetAllowedSubtitle =>
      'Los mensajes de esta conversación llegan a tu bandeja.';

  @override
  String get conversationSettingsSheetBlockedSubtitle =>
      'Esta conversación está bloqueada.';

  @override
  String get conversationSettingsSheetTrimMessagesLabel =>
      'Recortar mensajes largos';

  @override
  String conversationSettingsSheetTrimMessagesOn(int count) {
    return 'Los mensajes de más de $count caracteres se colapsan tras un Ver más. Aplica a todos los chats.';
  }

  @override
  String get conversationSettingsSheetTrimMessagesOff =>
      'Cada mensaje se muestra completo. Aplica a todos los chats.';

  @override
  String get conversationSettingsSheetTrimAtLabel => 'RECORTAR EN';

  @override
  String get conversationSettingsSheetTrimUnit => 'caracteres';

  @override
  String get conversationSettingsSheetDebugModeLabel => 'Modo depuración';

  @override
  String get conversationSettingsSheetDebugModeSubtitle =>
      'Muestra los metadatos en bruto del mensaje.';

  @override
  String get conversationSettingsSheetExportMessagesLabel =>
      'Exportar mensajes';

  @override
  String get conversationSettingsSheetExportMessagesSubtitle =>
      'Guarda el historial del chat en un archivo de texto.';

  @override
  String get conversationSettingsSheetDumpLogLabel => 'Volcar log';

  @override
  String get conversationSettingsSheetDumpLogSubtitle =>
      'Guarda las entradas de log recientes en un archivo.';

  @override
  String get conversationSettingsSheetConsentUpdateFailed =>
      'No se pudo actualizar el estado de consentimiento';

  @override
  String get conversationSettingsSheetLogBufferEmpty =>
      'El búfer de log está vacío';

  @override
  String conversationSettingsSheetDebugLogShareText(Object ts) {
    return 'Registro de depuración de PublicOS ($ts)';
  }

  @override
  String get conversationSettingsSheetDumpLogFailed =>
      'No se pudo volcar el log';

  @override
  String get conversationSettingsSheetNoMessages =>
      'No hay mensajes en esta conversación';

  @override
  String get conversationSettingsSheetSelectDateRange =>
      'Selecciona el rango de fechas para exportar';

  @override
  String get conversationSettingsSheetExportAction => 'Exportar';

  @override
  String get conversationSettingsSheetNoMessagesInRange =>
      'No hay mensajes en el rango seleccionado';

  @override
  String conversationSettingsSheetChatExportShareText(Object ts) {
    return 'Exportación del chat ($ts)';
  }

  @override
  String get conversationSettingsSheetExportFailed => 'Error al exportar';

  @override
  String get conversationSettingsSheetMediaTab => 'Multimedia';

  @override
  String get conversationSettingsSheetNoMedia =>
      'Aún no se ha compartido multimedia en esta conversación.';

  @override
  String get conversationSettingsSheetDocsTab => 'Docs';

  @override
  String get conversationSettingsSheetNoDocs =>
      'Aún no se han compartido documentos en esta conversación.';

  @override
  String get debugChatViewTopicCopied => 'Topic copiado';

  @override
  String get debugChatViewMessageDataCopied => 'Datos del mensaje copiados';

  @override
  String get messageWidgetShowMore => 'Ver más';

  @override
  String get messageWidgetShowLess => 'Ver menos';

  @override
  String get messageWidgetUnsupportedMessage => 'Mensaje no compatible';

  @override
  String messageWidgetUnsupportedMessageType(Object type) {
    return 'Tipo de mensaje no compatible: $type';
  }

  @override
  String messageWidgetTapped(Object label) {
    return 'Tocaste: $label';
  }

  @override
  String get messageWidgetUnknownChain => 'Cadena desconocida';

  @override
  String messageWidgetChainNumbered(Object chainId) {
    return 'Cadena $chainId';
  }

  @override
  String get messageWidgetTransactionReceipt => 'Recibo de transacción';

  @override
  String get messageWidgetTxFrom => 'De';

  @override
  String get messageWidgetTxTo => 'Para';

  @override
  String get messageWidgetTxRequestedBy => 'Solicitado por';

  @override
  String get messageWidgetTxChain => 'Cadena';

  @override
  String get messageWidgetTxToken => 'Token';

  @override
  String get messageWidgetTxAmount => 'Cantidad';

  @override
  String get messageWidgetViewOnExplorer => 'Ver en el explorador';

  @override
  String get messageWidgetReceivedPrefix => 'Recibido';

  @override
  String get messageWidgetTransactionRequest => 'Solicitud de transacción';

  @override
  String messageWidgetChainCalls(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count llamadas',
      one: '1 llamada',
    );
    return '$name · $_temp0';
  }

  @override
  String get messageWidgetSendPrefix => 'Enviar';

  @override
  String messageWidgetCallTarget(Object target) {
    return 'Llamada → $target';
  }

  @override
  String get messageWidgetReviewAndPay => 'Revisar y pagar';

  @override
  String get messageWidgetPayRequestTitle => 'Pagar solicitud';

  @override
  String get messageWidgetPayRequestConfirm => 'Pagar';

  @override
  String get messageWidgetXmtpTxRequestOrigin =>
      'Solicitud de transacción XMTP';

  @override
  String get messageWidgetFailedToLoadImage => 'No se pudo cargar la imagen';

  @override
  String get messageWidgetInvalidAttachmentFormat =>
      'Formato de adjunto no válido';

  @override
  String get messageWidgetInvalidRemoteAttachmentFormat =>
      'Formato de adjunto remoto no válido';

  @override
  String get messageWidgetCouldntLoadAttachment =>
      'No se pudo cargar el adjunto.\nPídele a quien lo envió que lo comparta de nuevo.';

  @override
  String get messageWidgetInvalidReplyFormat =>
      'Formato de respuesta no válido';

  @override
  String get messageWidgetQuotedAttachment => '📎 Archivo adjunto';

  @override
  String messageWidgetGalleryTitle(int count) {
    return '$count adjuntos';
  }

  @override
  String get messageWidgetQuotedReaction => '❤️ Reacción';

  @override
  String get messageWidgetQuotedReply => '💬 Respuesta';

  @override
  String get messageWidgetMessage => 'Mensaje';

  @override
  String get messageWidgetYou => 'Tú';

  @override
  String get messageWidgetLoading => 'Cargando...';

  @override
  String get messageWidgetMessageNotAvailable => 'Mensaje no disponible';

  @override
  String get messageWidgetFailedToSend => 'No se pudo enviar';

  @override
  String get messageWidgetSending => 'Enviando...';

  @override
  String get messageWidgetSeen => 'visto';

  @override
  String get messageWidgetClipboardAttachment => 'Archivo adjunto';

  @override
  String get messageWidgetClipboardRemoteAttachment => 'Archivo adjunto remoto';

  @override
  String get messageWidgetClipboardReaction => 'Reacción';

  @override
  String get messageWidgetDismissReactions => 'Descartar reacciones';

  @override
  String get messageWidgetStickerSaved => 'Sticker guardado';

  @override
  String get messageWidgetStickerAlreadySaved => 'Ya está en tus stickers';

  @override
  String get messageWidgetStickerSaveFailed => 'No se pudo guardar el sticker';

  @override
  String get messagesChipBarNoKey => 'Llavero';

  @override
  String get messagesChipBarRequests => 'Solicitudes';

  @override
  String get messagesChipBar1on1 => '1-1';

  @override
  String get messagesChipBarGroups => 'Grupos';

  @override
  String get messagesChipBarNewGroup => 'Nuevo grupo';

  @override
  String get messagesChipBarInboxIds => 'Inbox IDs';

  @override
  String get messagesChipBarSettings => 'Ajustes';

  @override
  String get reactionDetailsSheetTitle => 'Reacciones';

  @override
  String get reactionDetailsSheetRemoveFailed =>
      'No se pudo quitar la reacción';

  @override
  String get reactionDetailsSheetAddFailed => 'No se pudo agregar la reacción';

  @override
  String get reactionDetailsSheetNoReactions => 'Aún no hay reacciones.';

  @override
  String get reactionDetailsSheetLoadFailed =>
      'No se pudo cargar quién reaccionó.';

  @override
  String get reactionDetailsSheetAllTab => 'Todas';

  @override
  String get reactionDetailsSheetYouBadge => 'Tú';

  @override
  String get reactionDetailsSheetRemoveTooltip => 'Quita tu reacción';

  @override
  String get messagesSettingsSheetTitle => 'Configuración de mensajes';

  @override
  String get messagesSettingsSheetSendReceiptsLabel =>
      'Enviar confirmaciones de lectura';

  @override
  String get messagesSettingsSheetSendReceiptsSubtitle =>
      'Otros pueden ver cuándo leíste sus mensajes.';

  @override
  String get messagesSettingsSheetShowReceiptsLabel =>
      'Mostrar confirmaciones de lectura';

  @override
  String get messagesSettingsSheetShowReceiptsSubtitle =>
      'Mira cuándo otros leyeron los tuyos.';

  @override
  String get messagesSettingsSheetShowBannersLabel =>
      'Mostrar banners de contacto';

  @override
  String get messagesSettingsSheetShowBannersSubtitle =>
      'Muestra las imágenes de banner de contacto detrás de las filas de conversación.';

  @override
  String get messagesSettingsSheetBlockedConvosLabel =>
      'Conversaciones bloqueadas';

  @override
  String get messagesSettingsSheetBlockedConvosSubtitle =>
      'Revisa y restaura DMs y grupos bloqueados.';

  @override
  String get messagesSettingsSheetDownloadDbLabel =>
      'Descargar respaldo de la base de datos';

  @override
  String get messagesSettingsSheetDownloadDbSubtitle =>
      'Guarda el archivo de base de datos de mensajes de este dispositivo. Con su llave de cifrado se restaura en un dispositivo nuevo como el MISMO dispositivo — sin usar un espacio de dispositivo.';

  @override
  String get messagesSettingsSheetCopyDbKeyLabel => 'Copiar llave de cifrado';

  @override
  String get messagesSettingsSheetCopyDbKeySubtitle =>
      'Copia la llave que abre el respaldo de la base de datos. Necesitas el archivo y esta llave para restaurar.';

  @override
  String get messagesSettingsSheetDownloadDbWarning =>
      'El archivo de base de datos es inútil sin su llave de cifrado. Guarda ambos y mantén la llave en secreto: cualquiera que tenga ambos puede leer tus mensajes.';

  @override
  String get messagesSettingsSheetCopyDbKeyWarning =>
      'Esta llave abre tu base de datos de mensajes. Cualquiera que la tenga junto con tu archivo de base de datos puede leer tus mensajes. Cópiala en un lugar seguro.';

  @override
  String get messagesSettingsSheetPreparingDb =>
      'Preparando la base de datos…\n\nNo cierres la app.';

  @override
  String get messagesSettingsSheetNoActiveKey =>
      'No hay una llave de mensajería cargada.';

  @override
  String get messagesSettingsSheetKeyCopied =>
      'Llave de cifrado copiada al portapapeles.';

  @override
  String get messagesSettingsSheetDownloadBackupLabel => 'Descargar respaldo';

  @override
  String get messagesSettingsSheetDownloadBackupSubtitle =>
      'Archivo cifrado de esta bandeja, protegido por una contraseña. Se restaura de forma nativa en cualquier dispositivo de esta cuenta.';

  @override
  String get messagesSettingsSheetRestoreBackup => 'Restaurar respaldo';

  @override
  String get messagesSettingsSheetRestoreBackupSubtitle =>
      'Importa un archivo .xmtpBak de esta cuenta. Necesita la contraseña con la que se creó.';

  @override
  String get messagesSettingsSheetBackupPasswordTitle =>
      'Contraseña del respaldo';

  @override
  String get messagesSettingsSheetBackupPasswordMessage =>
      'Esta contraseña cifra tu respaldo. La necesitarás para restaurar; no hay forma de recuperarla si la pierdes.';

  @override
  String get messagesSettingsSheetCreateBackup => 'Crear respaldo';

  @override
  String get messagesSettingsSheetEncryptingBackup =>
      'Cifrando respaldo…\n\nNo cierres la app.';

  @override
  String get messagesSettingsSheetOpeningShareSheet =>
      'Abriendo el panel de compartir…';

  @override
  String get messagesSettingsSheetBackupShareSubject => 'Respaldo XMTP';

  @override
  String messagesSettingsSheetBackupReady(Object fileName) {
    return 'Respaldo listo: $fileName';
  }

  @override
  String get messagesSettingsSheetBackupFailed => 'Falló el respaldo.';

  @override
  String get messagesSettingsSheetBackupFileTypeLabel =>
      'Respaldo XMTP de PublicOS';

  @override
  String get messagesSettingsSheetCouldNotOpenFile =>
      'No se pudo abrir el archivo.';

  @override
  String get messagesSettingsSheetRestorePasswordMessage =>
      'Ingresa la contraseña con la que se creó este respaldo.';

  @override
  String get messagesSettingsSheetContinue => 'Continuar';

  @override
  String get messagesSettingsSheetReadingBackup => 'Leyendo respaldo…';

  @override
  String get messagesSettingsSheetCouldNotOpenBackupTitle =>
      'No se pudo abrir el respaldo';

  @override
  String get messagesSettingsSheetCouldNotOpenBackupMessage =>
      'Contraseña incorrecta, o este archivo pertenece a otra cuenta. No se importó nada.';

  @override
  String get messagesSettingsSheetRestoringBackup =>
      'Restaurando respaldo…\n\nNo cierres la app.';

  @override
  String get messagesSettingsSheetRestoreFailed => 'Falló la restauración';

  @override
  String get messagesSettingsSheetPasswordLabel => 'Contraseña';

  @override
  String get messagesSettingsSheetConfirmPasswordLabel =>
      'Confirmar contraseña';

  @override
  String get messagesSettingsSheetEnterPassword => 'Ingresa una contraseña.';

  @override
  String get messagesSettingsSheetPasswordsNoMatch =>
      'Las contraseñas no coinciden.';

  @override
  String get messagesSettingsSheetRestoreThisBackup =>
      '¿Restaurar este respaldo?';

  @override
  String get messagesSettingsSheetMetaCreated => 'Creado';

  @override
  String get messagesSettingsSheetMetaContents => 'Contenido';

  @override
  String get messagesSettingsSheetRestoreMergeNote =>
      'Las conversaciones restauradas se fusionan en esta bandeja. Los datos existentes se conservan.';

  @override
  String get messagesSettingsSheetRestore => 'Restaurar';

  @override
  String get messagesSettingsSheetOk => 'OK';

  @override
  String networkAccessSheetsExtendHeader(Object provider) {
    return 'EXTENDER $provider';
  }

  @override
  String networkAccessSheetsRenewTitle(Object provider) {
    return 'Extiende tu suscripción $provider';
  }

  @override
  String networkAccessSheetsRenewBody(Object provider) {
    return 'La tarifa $provider se paga desde tu billetera a tu proveedor.';
  }

  @override
  String get networkAccessSheetsPaying => 'PAGANDO…';

  @override
  String networkAccessSheetsPayProvider(Object provider) {
    return 'PAGAR $provider';
  }

  @override
  String networkAccessSheetsExtendTitle(Object slug) {
    return 'Extiende $slug';
  }

  @override
  String networkAccessSheetsExtendCitizenBody(Object provider) {
    return 'La red acuña la tarifa $provider por ti. No pagas nada.';
  }

  @override
  String get networkAccessSheetsExtending => 'EXTENDIENDO…';

  @override
  String get networkAccessSheetsExtend => 'EXTENDER';

  @override
  String get networkAccessSheetsDomainRenewHeader => 'RENOVAR DOMINIO';

  @override
  String get networkAccessSheetsDomainPay => 'PAGAR DOMINIO';

  @override
  String get networkAccessSheetsDomainRenewTitle => 'Renueva tu nombre';

  @override
  String get networkAccessSheetsDomainPayTitle => 'Conserva tu nombre';

  @override
  String get networkAccessSheetsDomainBody =>
      'La tarifa de dominio mantiene tu nombre y tu acceso de escritura a la cadena. Su precio depende del largo del nombre. El 98% se quema, el 2% financia las Utilidades.';

  @override
  String get networkAccessSheetsName => 'Nombre';

  @override
  String networkAccessSheetsNameChars(Object name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count caracteres',
      one: '1 carácter',
    );
    return '$name  ·  $_temp0';
  }

  @override
  String get networkAccessSheetsDomainRenewAction => 'RENOVAR';

  @override
  String get newAccountDialogErrWrongKind =>
      'Este claim es para agregar una sesión, no para crear una cuenta.';

  @override
  String get newAccountDialogErrMalformed => 'Claim mal formado.';

  @override
  String get newAccountDialogAccountCreated => 'Cuenta creada';

  @override
  String get newAccountDialogSuccessBody =>
      'La cuenta nueva ya está en la cadena. La llave escaneada es su primera sesión.';

  @override
  String get newAccountDialogInvalidClaim => 'Código no válido';

  @override
  String get newAccountDialogClose => 'CERRAR';

  @override
  String get newAccountDialogCreateTitle => 'Crear cuenta';

  @override
  String get newAccountDialogSponsorPrompt =>
      'Alguien te pide patrocinar una cuenta nueva.';

  @override
  String get newAccountDialogSponsorPromptPaused =>
      'Alguien te pide patrocinar una cuenta nueva. La creación está pausada en toda la red, así que esto usará una de tus invitaciones.';

  @override
  String get newAccountDialogLabelUsername => 'USUARIO';

  @override
  String get newAccountDialogLabelSession => 'SESIÓN';

  @override
  String get newAccountDialogLabelExpiresIn => 'EXPIRA EN';

  @override
  String get newAccountDialogExpired => 'vencido';

  @override
  String get newAccountDialogRootInviteFree =>
      'Cuenta root, creando sin invitación';

  @override
  String get newAccountDialogNoInvitesLeft =>
      'No quedan invitaciones, espera la próxima oleada.';

  @override
  String newAccountDialogInvitesLeft(Object count) {
    return 'Invitaciones restantes: $count';
  }

  @override
  String get newAccountDialogClaimExpired =>
      'Esta solicitud venció. Genera un QR nuevo donde la iniciaste.';

  @override
  String get newAccountDialogConfirm => 'FIRMAR';

  @override
  String get newAccountDialogUseInvite => 'USAR INVITACIÓN';

  @override
  String get newAccountDialogReservedName => 'Nombre reservado';

  @override
  String newAccountDialogNameCooldown(Object days) {
    return 'Nombre en enfriamiento por ${days}d';
  }

  @override
  String get newAccountDialogCopied => 'Copiado';

  @override
  String get nftInfoDialogVerified => 'Verificado';

  @override
  String get nftInfoDialogOwnsThisNft => 'posee este NFT';

  @override
  String get nftInfoDialogChain => 'Cadena';

  @override
  String get nftInfoDialogMint => 'Mint';

  @override
  String nftInfoDialogChainNumber(Object chain) {
    return 'Cadena $chain';
  }

  @override
  String get nftInfoDialogContract => 'Contrato';

  @override
  String get nftInfoDialogTokenId => 'Token ID';

  @override
  String get nftInfoDialogStandard => 'Estándar';

  @override
  String get nftInfoDialogTraits => 'RASGOS';

  @override
  String get nftInfoDialogExplorer => 'Explorador';

  @override
  String get nftInfoDialogMarketplace => 'Mercado';

  @override
  String get nftInfoDialogUseAsAvatar => 'USAR COMO AVATAR';

  @override
  String get nftInfoDialogSetAsProfilePictureTitle =>
      '¿Usar como foto de perfil?';

  @override
  String get nftInfoDialogSetAsProfilePictureBody =>
      'Esto pone este NFT como tu avatar. Solo aparecerás como verificado si eres su dueño.';

  @override
  String get nftInfoDialogSetAsAvatar => 'Usar como avatar';

  @override
  String nftInfoDialogCopied(Object label) {
    return '$label copiado';
  }

  @override
  String get childrenSheetTitle => 'Subs';

  @override
  String childrenSheetSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subs',
      one: '1 sub',
    );
    return '$_temp0';
  }

  @override
  String enhancedVoteCardVotesCount(Object yes, Object threshold) {
    return '$yes/$threshold votos';
  }

  @override
  String get enhancedVoteCardCastVote => 'VOTAR';

  @override
  String enhancedVoteCardSendValue(Object value) {
    return 'Enviar $value';
  }

  @override
  String enhancedVoteCardExecuteMethod(Object method) {
    return 'Ejecutar $method';
  }

  @override
  String get enhancedVoteCardContractCall => 'Llamada a contrato';

  @override
  String get enhancedVoteCardGroupWallet => 'Billetera grupal';

  @override
  String get enhancedVoteCardStarted => 'Iniciada';

  @override
  String get enhancedVoteCardExecuted => 'Ejecutada';

  @override
  String get enhancedVoteCardEnded => 'Finalizada';

  @override
  String get enhancedVoteCardTransactionDetails => 'Detalles de la transacción';

  @override
  String get enhancedVoteCardType => 'Tipo';

  @override
  String get enhancedVoteCardEthTransfer => 'Transferencia ETH';

  @override
  String get enhancedVoteCardTo => 'Para';

  @override
  String get enhancedVoteCardAmount => 'Monto';

  @override
  String get enhancedVoteCardMethod => 'Método';

  @override
  String get enhancedVoteCardParameters => 'Parámetros';

  @override
  String get enhancedVoteCardInitiatedBy => 'Iniciada por';

  @override
  String enhancedVoteCardVotersCount(Object count) {
    return 'Votantes ($count)';
  }

  @override
  String get enhancedVoteCardSearchVoters => 'Buscar votantes...';

  @override
  String get enhancedVoteCardNoVotersMatch =>
      'Ningún votante coincide con la búsqueda';

  @override
  String get enhancedVoteCardNoVotersYet => 'Aún no hay votantes';

  @override
  String enhancedVoteCardMinutesAgo(Object minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String enhancedVoteCardHoursAgo(Object hours) {
    return 'hace ${hours}h';
  }

  @override
  String enhancedVoteCardDaysAgoShort(Object days) {
    return 'hace ${days}d';
  }

  @override
  String get enhancedVoteCardToday => 'Hoy';

  @override
  String get enhancedVoteCardYesterday => 'Ayer';

  @override
  String enhancedVoteCardDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String enhancedVoteCardWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count semanas',
      one: 'hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String enhancedVoteCardTodayAt(Object time) {
    return 'Hoy $time';
  }

  @override
  String enhancedVoteCardYesterdayAt(Object time) {
    return 'Ayer $time';
  }

  @override
  String enhancedVoteCardWeekdayAt(Object weekday, Object time) {
    return '$weekday $time';
  }

  @override
  String get enhancedVoteCardWeekdayMon => 'Lun';

  @override
  String get enhancedVoteCardWeekdayTue => 'Mar';

  @override
  String get enhancedVoteCardWeekdayWed => 'Mié';

  @override
  String get enhancedVoteCardWeekdayThu => 'Jue';

  @override
  String get enhancedVoteCardWeekdayFri => 'Vie';

  @override
  String get enhancedVoteCardWeekdaySat => 'Sáb';

  @override
  String get enhancedVoteCardWeekdaySun => 'Dom';

  @override
  String get groupVotingViewInvalidGroupAddress =>
      'Dirección de grupo inválida';

  @override
  String get groupVotingViewLoadFailed =>
      'No se pudieron cargar los datos de gestión';

  @override
  String get groupVotingViewVoteRecorded => 'Voto registrado';

  @override
  String get groupVotingViewUnableToCastVote => 'No se pudo emitir el voto';

  @override
  String groupVotingViewMembersFailed(Object count, Object detail) {
    return '$count fallaron — $detail';
  }

  @override
  String groupVotingViewAlreadyMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ya son miembros.',
      one: 'Ya es miembro.',
    );
    return '$_temp0';
  }

  @override
  String groupVotingViewVotesToAddStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votaciones para agregar miembros iniciadas.',
      one: 'Votación para agregar miembro iniciada.',
    );
    return '$_temp0';
  }

  @override
  String get groupVotingViewVoteToRemoveStarted =>
      'Votación para quitar miembro iniciada.';

  @override
  String get groupVotingViewQuorum => 'Quórum';

  @override
  String get groupVotingViewQuorumSubtitle =>
      'Parte del peso que debe participar';

  @override
  String get groupVotingViewVoteDuration => 'Duración del voto';

  @override
  String get groupVotingViewVoteDurationSubtitle =>
      'Cuánto tiempo permanece abierta una votación';

  @override
  String get groupVotingViewDelegate => 'Tu delegado';

  @override
  String get groupVotingViewDelegateNone => 'Votas con tu propio peso';

  @override
  String groupVotingViewDelegateTo(Object name) {
    return 'Delegado a $name';
  }

  @override
  String get groupVotingViewMainSafe => 'Safe principal';

  @override
  String get groupVotingViewSend => 'Enviar';

  @override
  String get groupVotingViewAddressCopied => 'Dirección copiada';

  @override
  String get groupVotingViewVoting => 'Votaciones';

  @override
  String groupVotingViewVotingMetaLive(Object count) {
    return '1 en vivo · $count pasadas';
  }

  @override
  String groupVotingViewVotingMetaPast(Object count) {
    return '$count pasadas';
  }

  @override
  String get groupVotingViewActionHistory => 'Historial de acciones';

  @override
  String get groupVotingViewNoPastActions => 'Aún no hay acciones pasadas';

  @override
  String get groupVotingViewPastProposals =>
      'Propuestas pasadas · ejecutadas, canceladas, caducadas';

  @override
  String get groupVotingViewWallets => 'Billeteras';

  @override
  String get groupVotingViewNoWallets => 'Sin billeteras';

  @override
  String get groupVotingViewNoWalletsSubtitle =>
      'Agrega una billetera para que forme parte de este grupo';

  @override
  String get groupVotingViewAddWallet => 'Agregar billetera';

  @override
  String get groupVotingViewRemove => 'Quitar';

  @override
  String groupVotingViewProtocolWallet(Object protocol) {
    return 'billetera $protocol';
  }

  @override
  String get groupVotingViewTagPrimary => 'principal';

  @override
  String get groupVotingViewRecords => 'Registros';

  @override
  String get groupVotingViewNoRecords => 'Sin registros';

  @override
  String get groupVotingViewNoRecordsSubtitle =>
      'Los registros aparecen aquí cuando la org establece alguno';

  @override
  String get groupVotingViewValueCopied => 'Valor copiado';

  @override
  String get groupVotingViewInboxIds => 'Inbox IDs';

  @override
  String get groupVotingViewManageInboxIds => 'Gestionar inbox IDs';

  @override
  String get groupVotingViewManageInboxIdsSubtitle =>
      'Agregar / quitar / reetiquetar IDs registrados';

  @override
  String get groupVotingViewRecordTypeProfile => 'perfil';

  @override
  String get groupVotingViewRecordTypeSettings => 'ajustes';

  @override
  String get groupVotingViewRecordTypeRouter => 'router';

  @override
  String get groupVotingViewRecordTypeCustom => 'personalizado';

  @override
  String get groupVotingViewRecordTypeSystem => 'sistema';

  @override
  String get groupVotingViewExpired => 'caducado';

  @override
  String get groupVotingViewCopy => 'COPIAR';

  @override
  String get groupVotingViewMembers => 'miembros';

  @override
  String get groupVotingViewParent => 'super';

  @override
  String get groupVotingViewChildren => 'subs';

  @override
  String get groupVotingViewLiveVote => 'VOTO EN VIVO';

  @override
  String get groupVotingViewVoters => 'VOTANTES';

  @override
  String groupVotingViewYesCount(Object count) {
    return '$count sí';
  }

  @override
  String groupVotingViewNeededCount(Object count) {
    return '$count requeridos';
  }

  @override
  String get delegateVoteSheetTitle => 'Delega tu voto';

  @override
  String get delegateVoteSheetBlurb =>
      'Elige a un miembro para que lleve tu peso de voto. Aplica a votaciones futuras, nunca a una ya abierta, y puedes revertirlo cuando quieras.';

  @override
  String delegateVoteSheetCap(Object used, Object cap) {
    return '$used de $cap delegaciones usadas';
  }

  @override
  String get delegateVoteSheetVoteMyself => 'Votar yo mismo';

  @override
  String get delegateVoteSheetVoteMyselfSubtitle =>
      'Conserva tu propio peso de voto';

  @override
  String get delegateVoteSheetDelegateTo => 'DELEGAR A UN MIEMBRO';

  @override
  String get delegateVoteSheetNoMembers =>
      'Aún no hay otros miembros a quienes delegar';

  @override
  String get delegateVoteSheetConfirm => 'DELEGAR';

  @override
  String get delegateVoteSheetConfirmClear => 'VOTAR YO MISMO';

  @override
  String get delegateVoteSheetErrorFailed =>
      'No se pudo actualizar la delegación';

  @override
  String get groupVotingViewCastYesVote => 'VOTAR SÍ';

  @override
  String get groupVotingViewCastFor => 'A FAVOR';

  @override
  String get groupVotingViewCastAgainst => 'EN CONTRA';

  @override
  String get groupVotingViewCastAbstain => 'ABSTENERSE';

  @override
  String groupVotingViewTally(
      Object forCount, Object againstCount, Object abstainCount) {
    return 'A favor $forCount · En contra $againstCount · Abstención $abstainCount';
  }

  @override
  String groupVotingViewQuorumCount(Object count) {
    return '$count para quórum';
  }

  @override
  String get groupVotingViewActionSetRecord => 'FIJAR REGISTRO';

  @override
  String get groupVotingViewActionDeleteRecord => 'ELIMINAR REGISTRO';

  @override
  String get groupVotingViewActionAddMember => 'AGREGAR MIEMBRO';

  @override
  String get groupVotingViewActionRemoveMember => 'QUITAR MIEMBRO';

  @override
  String get groupVotingViewActionSetThreshold => 'FIJAR UMBRAL';

  @override
  String get groupVotingViewActionExecuteSafeTx => 'EJECUTAR TX SAFE';

  @override
  String get groupVotingViewVoteEnded => 'terminó';

  @override
  String get groupVotingViewIndividualAccount => 'Cuenta individual';

  @override
  String get groupVotingViewIndividualAccountBody =>
      'Las funciones de gobernanza grupal solo están disponibles para cuentas grupales.';

  @override
  String get groupVotingViewTryAgain => 'Reintentar';

  @override
  String get historySheetTitle => 'Historial de acciones';

  @override
  String historySheetPastActions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count acciones pasadas',
      one: '1 acción pasada',
    );
    return '$_temp0';
  }

  @override
  String get historySheetStatusCancelled => 'cancelada';

  @override
  String get historySheetStatusExpired => 'expirada';

  @override
  String get historySheetStatusActive => 'activa';

  @override
  String get historySheetStatusFailed => 'rechazada';

  @override
  String get historySheetEmptyTitle => 'Sin acciones pasadas';

  @override
  String get historySheetEmptyBody =>
      'Las propuestas pasadas aparecerán aquí cuando alguna se ejecute, cancele o expire.';

  @override
  String historySheetNoVotesWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sin votaciones en las últimas $count semanas',
      one: 'Sin votaciones esta última semana',
    );
    return '$_temp0';
  }

  @override
  String historySheetWindow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'últimas $count semanas',
      one: 'última semana',
    );
    return '$_temp0';
  }

  @override
  String get historySheetLoadWeekBefore => 'Cargar la semana anterior';

  @override
  String get membersSheetRemoveTitle => '¿Sacar miembro?';

  @override
  String membersSheetRemoveBody(Object name) {
    return '¿Iniciar una votación para sacar a $name de este grupo?';
  }

  @override
  String get membersSheetRemove => 'Quitar';

  @override
  String get membersSheetTitle => 'Miembros';

  @override
  String membersSheetCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String get membersSheetAddMember => 'AGREGAR MIEMBRO';

  @override
  String get startNewVoteSheetActionSetQuorum => 'Definir quórum';

  @override
  String get startNewVoteSheetActionSetDuration => 'Definir duración del voto';

  @override
  String get startNewVoteSheetActionAddWallet => 'Agregar billetera';

  @override
  String get startNewVoteSheetActionRemoveWallet => 'Quitar billetera';

  @override
  String get startNewVoteSheetActionAddModule => 'Agregar módulo';

  @override
  String get startNewVoteSheetActionRemoveModule => 'Quitar módulo';

  @override
  String get startNewVoteSheetDescSetQuorum =>
      'Define qué parte del peso de voto debe participar para que una votación pase (A favor + Abstención). Aplica a votaciones futuras.';

  @override
  String get startNewVoteSheetDescSetDuration =>
      'Define cuánto tiempo permanece abierta una votación antes de expirar. Aplica a votaciones futuras.';

  @override
  String get startNewVoteSheetDescAddWallet =>
      'Registra una nueva dirección de billetera para este grupo';

  @override
  String get startNewVoteSheetDescRemoveWallet =>
      'Quita una billetera existente de este grupo';

  @override
  String get startNewVoteSheetDescAddModule =>
      'Habilita un módulo en el Safe del grupo';

  @override
  String get startNewVoteSheetDescRemoveModule =>
      'Deshabilita un módulo del Safe del grupo';

  @override
  String get startNewVoteSheetQuorumCurrentPrefix => 'Quórum actual: ';

  @override
  String get startNewVoteSheetQuorumLabel => 'Nuevo quórum (%)';

  @override
  String get startNewVoteSheetQuorumHint => '0–100 (0 = mayoría simple)';

  @override
  String get startNewVoteSheetErrorQuorumRange =>
      'El quórum debe estar entre 0 y 100%';

  @override
  String get startNewVoteSheetDurationCurrentPrefix => 'Duración actual: ';

  @override
  String get startNewVoteSheetDurationLabel => 'Nueva duración (horas)';

  @override
  String startNewVoteSheetDurationHint(Object min, Object max) {
    return '$min–$max horas';
  }

  @override
  String startNewVoteSheetDurationHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
      zero: 'sin definir',
    );
    return '$_temp0';
  }

  @override
  String get startNewVoteSheetErrorDurationRange =>
      'La duración debe estar entre 1 hora y 30 días';

  @override
  String get startNewVoteSheetErrorLoadFailed =>
      'No se pudo cargar la información del grupo';

  @override
  String get startNewVoteSheetErrorWalletNameRequired =>
      'El nombre de la billetera es obligatorio';

  @override
  String get startNewVoteSheetErrorWalletAddressRequired =>
      'La dirección de la billetera es obligatoria';

  @override
  String get startNewVoteSheetErrorInvalidWalletAddress =>
      'Formato de dirección de billetera inválido';

  @override
  String get startNewVoteSheetErrorSelectWallet =>
      'Selecciona una billetera para quitar';

  @override
  String get startNewVoteSheetErrorCannotRemoveMain =>
      'No puedes quitar la billetera principal';

  @override
  String get startNewVoteSheetErrorAddressRequired =>
      'La dirección es obligatoria';

  @override
  String get startNewVoteSheetErrorInvalidAddress =>
      'Formato de dirección inválido';

  @override
  String get startNewVoteSheetErrorStartFailed =>
      'No se pudo iniciar la votación. Inténtalo de nuevo.';

  @override
  String get startNewVoteSheetCreateProposal => 'CREAR PROPUESTA';

  @override
  String get startNewVoteSheetModuleAddressLabel => 'Dirección del módulo';

  @override
  String get startNewVoteSheetWalletNameLabel => 'Nombre de la billetera';

  @override
  String get startNewVoteSheetWalletNameHint => 'ej., tesorería, operaciones';

  @override
  String get startNewVoteSheetWalletAddressLabel => 'Dirección de la billetera';

  @override
  String get startNewVoteSheetNoRemovableWallets =>
      'No hay billeteras adicionales para quitar. Solo existe la billetera principal.';

  @override
  String get startNewVoteSheetSelectWalletHeader => 'SELECCIONA BILLETERA';

  @override
  String startNewVoteSheetProtocolWalletTitle(Object protocol) {
    return 'billetera $protocol';
  }

  @override
  String get startNewVoteSheetLoading => 'Cargando datos del grupo...';

  @override
  String get voteCardCastVote => 'EMITIR VOTO';

  @override
  String get voteCardPending => 'Pendiente';

  @override
  String voteCardVotesOfThreshold(Object threshold) {
    return ' / $threshold votos';
  }

  @override
  String get voteCardDetails => 'Detalles';

  @override
  String get voteCardInitiatedBy => 'INICIADO POR';

  @override
  String get voteCardStarted => 'Iniciada';

  @override
  String get voteCardExecuted => 'Ejecutada';

  @override
  String get voteCardEnded => 'Finalizada';

  @override
  String get voteCardCopy => 'Copiar';

  @override
  String voteCardCopied(Object name) {
    return 'Copiado $name';
  }

  @override
  String voteCardVoters(Object count) {
    return 'Votantes ($count)';
  }

  @override
  String get voteCardSearchHint => 'Buscar...';

  @override
  String get voteCardNoMatches => 'Sin coincidencias';

  @override
  String get voteCardNoVoters => 'Sin votantes';

  @override
  String voteCardMinutesAgo(Object minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String voteCardHoursAgo(Object hours) {
    return 'hace ${hours}h';
  }

  @override
  String voteCardDaysAgoShort(Object days) {
    return 'hace ${days}d';
  }

  @override
  String get voteCardToday => 'Hoy';

  @override
  String get voteCardYesterday => 'Ayer';

  @override
  String voteCardDaysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'hace $days días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String voteCardWeeksAgo(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: 'hace $weeks semanas',
      one: 'hace 1 semana',
    );
    return '$_temp0';
  }

  @override
  String voteCardTodayAt(Object time) {
    return 'Hoy $time';
  }

  @override
  String voteCardYesterdayAt(Object time) {
    return 'Ayer $time';
  }

  @override
  String voteCardWeekdayAt(Object weekday, Object time) {
    return '$weekday $time';
  }

  @override
  String get voteCardWeekdayMon => 'Lun';

  @override
  String get voteCardWeekdayTue => 'Mar';

  @override
  String get voteCardWeekdayWed => 'Mié';

  @override
  String get voteCardWeekdayThu => 'Jue';

  @override
  String get voteCardWeekdayFri => 'Vie';

  @override
  String get voteCardWeekdaySat => 'Sáb';

  @override
  String get voteCardWeekdaySun => 'Dom';

  @override
  String get votersSheetTitle => 'Votantes';

  @override
  String votersSheetVoted(Object count) {
    return 'VOTARON · $count';
  }

  @override
  String votersSheetPending(Object count) {
    return 'PENDIENTE · $count';
  }

  @override
  String get votersSheetStatFor => 'A FAVOR';

  @override
  String get votersSheetStatAgainst => 'EN CONTRA';

  @override
  String get votersSheetStatAbstain => 'ABSTENCIÓN';

  @override
  String get votersSheetQuorum => 'QUÓRUM';

  @override
  String get inboxIdDropdownCopied => 'Inbox ID copiado al portapapeles';

  @override
  String get inboxIdDropdownSelectTitle => 'Selecciona Inbox ID';

  @override
  String get inboxIdDropdownDefaultLabel => 'Predeterminado';

  @override
  String inboxIdSelectionDialogTitle(Object name) {
    return 'Selecciona InboxID para $name';
  }

  @override
  String get inboxIdSelectionDialogSubtitle =>
      'Elige cual inbox ID agregar al grupo';

  @override
  String get manageGroupInboxIdsSheetDefaultLabel => 'Inbox';

  @override
  String get manageGroupInboxIdsSheetLoadFailed =>
      'No se pudieron cargar los inbox IDs';

  @override
  String get manageGroupInboxIdsSheetAddFailed => 'Fallo al agregar';

  @override
  String get manageGroupInboxIdsSheetRemoveFailed => 'Fallo al quitar';

  @override
  String get manageGroupInboxIdsSheetLabelUpdateFailed =>
      'Fallo al actualizar la etiqueta';

  @override
  String get manageGroupInboxIdsSheetRemoveTitle => '¿Quitar del grupo?';

  @override
  String manageGroupInboxIdsSheetRemoveBody(Object label, Object group) {
    return 'Quita \"$label\" de $group. La gente ya no podrá contactar a este grupo por este inbox ID.';
  }

  @override
  String get manageGroupInboxIdsSheetRemoveConfirm => 'Quitar';

  @override
  String get manageGroupInboxIdsSheetEditLabelTitle => 'Editar etiqueta';

  @override
  String get manageGroupInboxIdsSheetLabelHint => 'Escribe una nueva etiqueta';

  @override
  String get manageGroupInboxIdsSheetSave => 'Guardar';

  @override
  String get manageGroupInboxIdsSheetSheetTitle => 'Inbox IDs';

  @override
  String get manageGroupInboxIdsSheetManageKeys => 'GESTIONAR LLAVES';

  @override
  String get manageGroupInboxIdsSheetEmptyTitle =>
      'No hay inbox IDs disponibles';

  @override
  String get manageGroupInboxIdsSheetEmptyBody =>
      'Genera una llave en tu llavero para crear inbox IDs.';

  @override
  String manageGroupInboxIdsSheetRegisteredTo(Object address) {
    return 'Registrado a $address';
  }

  @override
  String get pickOrgMembersSheetTitle => 'Agregar miembros';

  @override
  String get pickOrgMembersSheetSubtitleEmpty =>
      'Elige contactos para proponer';

  @override
  String pickOrgMembersSheetSubtitleSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String pickOrgMembersSheetAddButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'AGREGAR $count MIEMBROS',
      one: 'AGREGAR 1 MIEMBRO',
    );
    return '$_temp0';
  }

  @override
  String get pickOrgMembersSheetNoMatch =>
      'Ningún contacto coincide con tu búsqueda.';

  @override
  String get pickOrgMembersSheetNoContacts =>
      'No hay contactos de PublicOS disponibles.';

  @override
  String get pickOrgMembersSheetSearchHint => 'Buscar contactos';

  @override
  String get createRecordPageSave => 'GUARDAR';

  @override
  String get createRecordPageCheckingVote => 'Buscando una votación abierta…';

  @override
  String get createRecordPageVoteInProgress =>
      'Esta organización ya tiene su máximo de votaciones abiertas; guarda cuando termine una';

  @override
  String get createRecordPageHeaderEdit => 'EDITAR REGISTRO';

  @override
  String get createRecordPageHeaderAdd => 'AGREGAR REGISTRO';

  @override
  String get createRecordPageHeaderPickPlatform => 'ELIGE PLATAFORMA';

  @override
  String get createRecordPageHeaderSocial => 'SOCIAL';

  @override
  String get createRecordPageHeaderTextCard => 'TARJETA DE TEXTO';

  @override
  String get createRecordPageHeaderImage => 'IMAGEN';

  @override
  String get createRecordPageHeaderNftCard => 'TARJETA NFT';

  @override
  String get createRecordPageHeaderAppCard => 'TARJETA DE APP';

  @override
  String get createRecordPageHeaderUnknownCard => 'TARJETA';

  @override
  String createRecordPageAppCardSizeLead(String app) {
    return 'Publicada por $app. Su imagen y contenido vienen de la app; tú eliges cuánto espacio ocupa en tu perfil y el arte se adapta.';
  }

  @override
  String get createRecordPageAppCardGenericApp => 'una app';

  @override
  String get createRecordPageUnknownCardBody =>
      'Esta tarjeta es de un tipo que esta versión de la app no sabe editar, así que nada aquí puede cambiarse con seguridad.';

  @override
  String get createRecordPageUnknownCardHint =>
      'Aún puedes moverla por tu perfil o quitarla.';

  @override
  String get createRecordPageTypeSocialLabel => 'Enlace social';

  @override
  String get createRecordPageTypeSocialDesc => 'Conecta una plataforma';

  @override
  String get createRecordPageTypeTextLabel => 'Tarjeta de texto';

  @override
  String get createRecordPageTypeTextDesc => 'Título, texto, enlace';

  @override
  String get createRecordPageTypeImageLabel => 'Imagen';

  @override
  String get createRecordPageTypeImageDesc => 'Foto o gráfico';

  @override
  String get createRecordPageTypeNftLabel => 'Tarjeta NFT';

  @override
  String get createRecordPageTypeNftDesc => 'Un NFT verificado que posees';

  @override
  String get createRecordPageExampleTitle => 'Título';

  @override
  String get createRecordPageHandleHint => 'usuario';

  @override
  String get createRecordPageLabelHandle => 'USUARIO';

  @override
  String get createRecordPageLabelTitle => 'TÍTULO';

  @override
  String get createRecordPageCardTitleHint => 'Título de la tarjeta';

  @override
  String get createRecordPageLabelDescription => 'DESCRIPCIÓN';

  @override
  String get createRecordPageDescriptionHint => 'Texto de descripción';

  @override
  String createRecordPageCardSize(int used, int max) {
    return '$used de $max bytes';
  }

  @override
  String createRecordPageCardTooLong(int over) {
    return 'Demasiado largo para guardar: $over bytes de más. Acorta el texto o el enlace.';
  }

  @override
  String get createRecordPageLabelLinkOptional => 'ENLACE (OPCIONAL)';

  @override
  String get createRecordPageLabelColor => 'COLOR';

  @override
  String get createRecordPageNoServerWarning =>
      'Configura un Servidor Social (SSP) para subir tus propias imágenes. Aún puedes pegar la URL de una imagen abajo.';

  @override
  String get createRecordPageLabelTitleOptional => 'TÍTULO (OPCIONAL)';

  @override
  String get createRecordPageImageTitleHint =>
      'Déjalo vacío para no poner título';

  @override
  String get createRecordPageLabelWidth => 'ANCHO';

  @override
  String get createRecordPageLabelHeight => 'ALTO';

  @override
  String get createRecordPageBack => 'Atrás';

  @override
  String get createRecordPageClose => 'Cerrar';

  @override
  String get createRecordPageCannotLoadImage => 'No se puede cargar la imagen';

  @override
  String get createRecordPageNoImageYet => 'Aún no hay imagen';

  @override
  String get createRecordPageHeaderCard => 'TARJETA';

  @override
  String get createRecordPageTypeCardLabel => 'Tarjeta';

  @override
  String get createRecordPageTypeCardDesc => 'Imagen, texto, color, enlace';

  @override
  String get createRecordPageLabelBackground => 'FONDO';

  @override
  String get createRecordPageBackgroundColor => 'Color';

  @override
  String get createRecordPageBackgroundGradient => 'Degradado';

  @override
  String get createRecordPageGradientFrom => 'Desde';

  @override
  String get createRecordPageGradientTo => 'Hasta';

  @override
  String get createRecordPageImageNone => 'Ninguna';

  @override
  String get createRecordPageImageUpload => 'Subir';

  @override
  String get createRecordPageLabelSize => 'TAMAÑO';

  @override
  String get createRecordPageSizeNote =>
      'celdas en la cuadrícula de 4 columnas. Toca un cuadro para fijar la esquina.';

  @override
  String get createRecordPageNoServerWarningCard =>
      'Configura un Servidor Social (SSP) para subir imágenes y elegir entre tus subidas.';

  @override
  String get createTabSheetTitleEdit => 'Editar pestaña';

  @override
  String get createTabSheetTitleNew => 'Nueva pestaña';

  @override
  String get createTabSheetKindWeb => 'Página web';

  @override
  String get createTabSheetKindChannel => 'Canal';

  @override
  String get createTabSheetFieldLabel => 'ETIQUETA';

  @override
  String get createTabSheetLabelHint =>
      'Etiqueta de la pestaña (p. ej. Mi Blog)';

  @override
  String get createTabSheetFieldChannelUrl => 'URL DEL CANAL';

  @override
  String get createTabSheetFieldWebUrl => 'URL DE LA PÁGINA WEB';

  @override
  String get createTabSheetFeedFormatsInfo =>
      'Admite los formatos JSON Feed, RSS 2.0 y Atom';

  @override
  String get createTabSheetSaving => 'GUARDANDO…';

  @override
  String get createTabSheetEnterLabel => 'INGRESA UNA ETIQUETA';

  @override
  String get createTabSheetEnterValidFeedUrl =>
      'INGRESA UNA URL DE FEED VÁLIDA';

  @override
  String get createTabSheetEnterValidUrl => 'INGRESA UNA URL VÁLIDA';

  @override
  String get createTabSheetSaveChanges => 'GUARDAR CAMBIOS';

  @override
  String get createTabSheetCreateTab => 'CREAR PESTAÑA';

  @override
  String get createTabSheetSaveFailed => 'No se pudo guardar la pestaña';

  @override
  String get editBioSheetTitle => 'Bio';

  @override
  String get editBioSheetClose => 'Cerrar';

  @override
  String get editBioSheetHint => 'Escribe algo sobre ti…';

  @override
  String editBioSheetCharCount(Object count, Object max) {
    return '$count/$max';
  }

  @override
  String get editBioSheetSectionTextColor => 'COLOR DE TEXTO';

  @override
  String get editBioSheetSectionBorder => 'BORDE';

  @override
  String get editBioSheetShowBorder => 'Mostrar borde';

  @override
  String get editBioSheetBorderColor => 'Color del borde';

  @override
  String get editBioSheetBorderWidth => 'Grosor del borde';

  @override
  String get editBioSheetCornerRadius => 'Radio de esquina';

  @override
  String get editBioSheetSave => 'GUARDAR BIO';

  @override
  String get editProfileBackgroundSheetTitle => 'Fondo de perfil';

  @override
  String get editProfileBackgroundSheetClose => 'Cerrar';

  @override
  String get editProfileBackgroundSheetEmpty => 'Sin fondo';

  @override
  String get editProfileBackgroundSheetUnableToLoad =>
      'No se pudo cargar la imagen';

  @override
  String get editProfileBackgroundSheetNone => 'Ninguno';

  @override
  String get editProfileBackgroundSheetUpload => 'Subir';

  @override
  String get editProfileBackgroundSheetNoServer =>
      'Configura un Servidor Social (SSP) para subir imágenes y elegir entre tus subidas. Un enlace directo sigue funcionando.';

  @override
  String get editProfileBackgroundSheetUrlLabel =>
      'O pega el enlace de una imagen';

  @override
  String get editProfileBackgroundSheetUrlHint =>
      'https://example.com/background.jpg';

  @override
  String get editProfileBackgroundSheetInvalidUrl => 'Escribe una URL válida';

  @override
  String get editProfileBackgroundSheetSave => 'Guardar fondo';

  @override
  String get editProfileBackgroundSheetRemove => 'Quitar fondo';

  @override
  String get editProfileBackgroundSheetSavingToChain =>
      'Guardando en la cadena...';

  @override
  String get editProfileImageSheetSaving => 'GUARDANDO…';

  @override
  String get editProfileImageSheetUseNft => 'USAR NFT';

  @override
  String get editProfileImageSheetSaveNft => 'GUARDAR NFT';

  @override
  String get editProfileImageSheetSavePicture => 'GUARDAR FOTO';

  @override
  String get editProfileImageSheetSaveBanner => 'GUARDAR BANNER';

  @override
  String get editProfileImageSheetSavingToChain => 'Guardando en la cadena...';

  @override
  String get editProfileImageSheetSaveNftError => 'No se pudo guardar el NFT';

  @override
  String get editProfileImageSheetSaveImageError =>
      'No se pudo guardar la imagen';

  @override
  String get editProfileImageSheetRemoveImageError =>
      'No se pudo quitar la imagen';

  @override
  String get editProfileImageSheetRemoveAvatarConfirmTitle =>
      '¿Quitar foto de perfil?';

  @override
  String get editProfileImageSheetRemoveBannerConfirmTitle => '¿Quitar banner?';

  @override
  String get editProfileImageSheetRemoveConfirmBody =>
      'Esto borra el registro en cadena. La imagen sigue en tu servidor social (puedes volver a vincularla después).';

  @override
  String get editProfileImageSheetRemoveAction => 'Quitar';

  @override
  String get editProfileImageSheetNftLoadError => 'No se pudo cargar ese NFT.';

  @override
  String get editProfileImageSheetNftResolving => 'Resolviendo tu NFT…';

  @override
  String get editProfileImageSheetOwnNft => 'Posees este NFT';

  @override
  String get editProfileImageSheetSourceImage => 'Imagen';

  @override
  String get editProfileImageSheetSourceImageSub =>
      'Sube, pega una URL o elige de tus archivos';

  @override
  String get editProfileImageSheetSourceEth => 'NFT de Ethereum';

  @override
  String get editProfileImageSheetSourceEthSub =>
      'Tus NFTs EVM, o ingresa uno manualmente';

  @override
  String get editProfileImageSheetSourceSolana => 'NFT de Solana';

  @override
  String get editProfileImageSheetSourceSolanaSub =>
      'Tus NFTs de Solana, o ingresa un mint';

  @override
  String get editProfileImageSheetSectionSource => 'Fuente';

  @override
  String get editProfileImageSheetSectionYourUploads => 'Tus archivos';

  @override
  String get editProfileImageSheetSectionNftsEvm => 'Tus NFTs · EVM';

  @override
  String get editProfileImageSheetSectionNftsSolana => 'Tus NFTs · Solana';

  @override
  String get editProfileImageSheetUploadsEmpty =>
      'Aún no has subido nada. Las imágenes que subas aparecerán aquí.';

  @override
  String get editProfileImageSheetUploadsError =>
      'No se pudieron cargar tus archivos.';

  @override
  String get editProfileImageSheetManualPromptEth => '¿Conoces el contrato?';

  @override
  String get editProfileImageSheetManualPromptSolana => '¿Conoces el mint?';

  @override
  String get editProfileImageSheetManualCta => 'Ingresar manualmente';

  @override
  String get editProfileImageSheetPickSourceHint =>
      'Elige una fuente para hacer un cambio';

  @override
  String get editProfileImageSheetFieldChain => 'CADENA';

  @override
  String get editProfileImageSheetFieldContract => 'DIRECCIÓN DEL CONTRATO';

  @override
  String get editProfileImageSheetFieldTokenId => 'ID DEL TOKEN';

  @override
  String get editProfileImageSheetTokensLoading =>
      'Buscando qué tokens tienes…';

  @override
  String editProfileImageSheetTokensOwned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tienes $count tokens aquí — toca uno para usarlo',
      one: 'Tienes 1 token aquí — tócalo para usarlo',
    );
    return '$_temp0';
  }

  @override
  String get editProfileImageSheetFieldSolanaMint => 'MINT DE SOLANA';

  @override
  String get editProfileImageSheetFallbackNote =>
      'Tu imagen queda como respaldo si el NFT no se puede mostrar. La propiedad se vuelve a verificar en cadena cuando se renderiza.';

  @override
  String get editProfileImageSheetNoServerAvatar =>
      'Configura un Servidor Social (SSP) para subir tu propia foto de perfil. Aún puedes pegar una URL de imagen abajo.';

  @override
  String get editProfileImageSheetNoServerBanner =>
      'Configura un Servidor Social (SSP) para subir tu propio banner. Aún puedes pegar una URL de imagen abajo.';

  @override
  String get editProfileImageSheetTitleAvatar => 'Foto de perfil';

  @override
  String get editProfileImageSheetTitleCard => 'Tarjeta NFT';

  @override
  String get editProfileImageSheetTitleBanner => 'Banner';

  @override
  String get editProfileImageSheetNoActiveAccount => 'Sin cuenta activa.';

  @override
  String get editProfileImageSheetRemoveNftAvatar => 'Quitar foto NFT';

  @override
  String get editProfileImageSheetRemoveNftBanner => 'Quitar banner NFT';

  @override
  String get editProfileImageSheetRemoveFromProfile => 'Quitar del perfil';

  @override
  String get editProfileImageSheetClearsRecord => 'Borra el registro en cadena';

  @override
  String get editProfileImageSheetClose => 'Cerrar';

  @override
  String get manageProfileTabsSheetTitle => 'Gestionar pestañas';

  @override
  String get manageProfileTabsSheetGroupTitle => 'Gestionar pestañas del grupo';

  @override
  String get manageProfileTabsSheetLoadingWebFeedTabs =>
      'Cargando pestañas web y de feeds';

  @override
  String get manageProfileTabsSheetLoadingInboxTabs =>
      'Cargando pestañas de inbox';

  @override
  String get manageProfileTabsSheetUpdatingTabs => 'Actualizando pestañas';

  @override
  String get manageProfileTabsSheetNoAddressError =>
      'No se encontró una dirección válida para cargar las pestañas del perfil';

  @override
  String get manageProfileTabsSheetChatFallback => 'Chat';

  @override
  String get manageProfileTabsSheetInboxLoadError =>
      'No se pudieron cargar las pestañas de inbox';

  @override
  String get manageProfileTabsSheetVoteStarted =>
      'Votación iniciada — los miembros deben aprobar';

  @override
  String get manageProfileTabsSheetTabCreated => 'Pestaña creada con éxito.';

  @override
  String get manageProfileTabsSheetTabUpdated =>
      'Pestaña actualizada con éxito.';

  @override
  String get manageProfileTabsSheetTabDeleted => 'Pestaña eliminada con éxito.';

  @override
  String get manageProfileTabsSheetUnnamedTab => 'Pestaña sin nombre';

  @override
  String get manageProfileTabsSheetDeleteTabTitle => 'Eliminar pestaña';

  @override
  String manageProfileTabsSheetDeleteTabBody(Object tabName) {
    return 'Seguro que quieres eliminar la pestaña \"$tabName\"? Esta acción no se puede deshacer.';
  }

  @override
  String get manageProfileTabsSheetInboxRenamed =>
      'Pestaña de inbox renombrada.';

  @override
  String get manageProfileTabsSheetInboxRemoved => 'Pestaña de inbox quitada.';

  @override
  String get manageProfileTabsSheetRemoveInboxTitle =>
      'Quitar pestaña de inbox';

  @override
  String manageProfileTabsSheetRemoveInboxBody(Object label) {
    return 'Quita \"$label\" del perfil on-chain. Otros usuarios ya no verán este inbox listado en esta cuenta.';
  }

  @override
  String get manageProfileTabsSheetRenameInboxTitle =>
      'Renombrar pestaña de inbox';

  @override
  String get manageProfileTabsSheetLabelHint => 'Etiqueta';

  @override
  String get manageProfileTabsSheetSave => 'Guardar';

  @override
  String get manageProfileTabsSheetActionDelete => 'Eliminar';

  @override
  String get manageProfileTabsSheetActionRemove => 'Quitar';

  @override
  String get manageProfileTabsSheetInboxTabsHeader => 'PESTAÑAS DE INBOX';

  @override
  String get manageProfileTabsSheetOnlyGroupMembers =>
      'Solo los miembros del grupo pueden gestionar pestañas';

  @override
  String get manageProfileTabsSheetViewOnly => 'Solo puedes ver estas pestañas';

  @override
  String get manageProfileTabsSheetAddNewTab => 'Agregar nueva pestaña';

  @override
  String get manageProfileTabsSheetActiveKey => 'LLAVE ACTIVA';

  @override
  String get nftPickerGridAllChains => 'Todas las cadenas';

  @override
  String nftPickerGridChainFallback(Object id) {
    return 'Cadena $id';
  }

  @override
  String get nftPickerGridRefresh => 'Actualizar';

  @override
  String get nftPickerGridRemoveFromRecents => 'Quitar de recientes';

  @override
  String get nftPickerGridEmpty =>
      'Aún no hay NFTs. Elige uno con Manual arriba y aparecerá aquí la próxima vez. (Vincula una billetera Solana para ver tus NFTs de Solana en vivo.)';

  @override
  String get nftPickerGridNoMatch => 'Ningún NFT coincide con estos filtros.';

  @override
  String get nftPickerGridSearchHint => 'Busca dirección, token o mint';

  @override
  String get nftPickerGridMine => 'Míos';

  @override
  String get nftPickerGridNotMine => 'No míos';

  @override
  String get nftPickerGridRecent => 'Recientes';

  @override
  String get nftPickerGridOldest => 'Antiguos';

  @override
  String get recordButtonDeleteTitle => 'Eliminar registro';

  @override
  String recordButtonDeleteConfirm(Object key) {
    return '¿Seguro que quieres eliminar \"$key\"?';
  }

  @override
  String get recordButtonDelete => 'Eliminar';

  @override
  String recordButtonCouldNotLaunch(Object link) {
    return 'No se pudo abrir $link';
  }

  @override
  String socialStripCouldNotLaunch(Object link) {
    return 'No se pudo abrir $link';
  }

  @override
  String get socialStripIcon => 'Icono';

  @override
  String get socialStripRich => 'Detallado';

  @override
  String get socialStripAdd => 'Anadir';

  @override
  String manageProviderSheetManageTitle(Object type) {
    return 'Administrar $type';
  }

  @override
  String get manageProviderSheetTitleLabel => 'Título';

  @override
  String get manageProviderSheetSaveTooltip => 'Guardar';

  @override
  String get manageProviderSheetEditTitleTooltip => 'Editar título';

  @override
  String manageProviderSheetSubscribers(Object count) {
    return 'Suscriptores: $count';
  }

  @override
  String get manageProviderSheetPointers => 'Indicadores';

  @override
  String get manageProviderSheetNoPointers => 'Sin indicadores definidos';

  @override
  String get manageProviderSheetEditPointerTooltip => 'Editar indicador';

  @override
  String get manageProviderSheetRemovePointerTooltip => 'Quitar indicador';

  @override
  String get manageProviderSheetRemovePointerTitle => 'Quitar indicador';

  @override
  String manageProviderSheetRemovePointerConfirm(Object type) {
    return '¿Quitar el indicador \"$type\"?';
  }

  @override
  String get manageProviderSheetRemove => 'Quitar';

  @override
  String get manageProviderSheetPointerTypeLabel => 'Tipo de indicador';

  @override
  String get manageProviderSheetValueLabel => 'Valor';

  @override
  String get manageProviderSheetAddPointerTooltip => 'Agregar indicador';

  @override
  String manageProviderSheetDeleteTitle(Object type) {
    return 'Eliminar $type';
  }

  @override
  String manageProviderSheetDeleteConfirm(Object slug) {
    return '¿Seguro que quieres eliminar $slug? Esta acción no se puede deshacer.';
  }

  @override
  String get manageProviderSheetDeleteButton => 'Eliminar';

  @override
  String manageProviderSheetDeleted(Object type, Object slug) {
    return '$type \"$slug\" eliminado';
  }

  @override
  String providerDirectorySheetTitle(Object type) {
    return 'Directorio $type';
  }

  @override
  String get providerDirectorySheetSearchHint => 'Buscar por título...';

  @override
  String get providerDirectorySheetLoadError =>
      'No se pudieron cargar los proveedores';

  @override
  String get providerDirectorySheetNoResults => 'Sin resultados';

  @override
  String providerDirectorySheetEmpty(Object type) {
    return 'Aún no hay ${type}s registrados';
  }

  @override
  String get providerDirectorySheetClearSearch => 'Limpiar búsqueda';

  @override
  String get providerDirectorySheetCurrentChip => 'Actual';

  @override
  String get providerDirectorySheetRunBy => 'Operado por ';

  @override
  String get providerDirectorySheetNoPointers =>
      'No hay indicadores de configuración';

  @override
  String get providerDirectorySheetCurrentProvider => 'Proveedor actual';

  @override
  String get providerDirectorySheetChangeToProvider =>
      'Cambiar a este proveedor';

  @override
  String get providerDirectorySheetSubscribe => 'Suscribirse';

  @override
  String registerProviderSheetTitle(Object type) {
    return 'Registrar $type';
  }

  @override
  String registerProviderSheetSubtitle(Object label) {
    return 'Registra un nuevo $label on-chain.';
  }

  @override
  String get registerProviderSheetNotAuthenticated =>
      'No autenticado. Inicia sesión primero.';

  @override
  String registerProviderSheetRegisteredSuccess(Object type, Object slug) {
    return '$type \"$slug\" registrado con éxito';
  }

  @override
  String get registerProviderSheetSlugLabel => 'Slug';

  @override
  String get registerProviderSheetSlugHint => 'ej. my-bsp-service';

  @override
  String get registerProviderSheetSlugHelper =>
      '3-32 caracteres, minúsculas, números, guiones, guiones bajos';

  @override
  String get registerProviderSheetSlugRequired => 'El slug es obligatorio';

  @override
  String get registerProviderSheetSlugInvalid =>
      'Debe tener 3-32 caracteres: minúsculas, números, guiones, guiones bajos';

  @override
  String get registerProviderSheetTitleLabel => 'Título';

  @override
  String get registerProviderSheetTitleHint => 'ej. Mi servicio BSP';

  @override
  String get registerProviderSheetTitleRequired => 'El título es obligatorio';

  @override
  String get registerProviderSheetRequiredPointerHint =>
      'ej. https://rpc.example.com';

  @override
  String registerProviderSheetRequiredPointerRequired(Object label) {
    return '$label es obligatorio';
  }

  @override
  String get registerProviderSheetRegionLabel => 'Región';

  @override
  String get registerProviderSheetRegionHint => 'ej. us-east, eu-west';

  @override
  String get registerProviderSheetWebsiteLabel => 'Sitio web';

  @override
  String get registerProviderSheetWebsiteHint => 'ej. https://example.com';

  @override
  String get qualityToggleLow => 'Baja';

  @override
  String get qualityToggleHd => 'HD';

  @override
  String get secretDialogsShowSecret => '¿MOSTRAR SECRETO?';

  @override
  String get secretDialogsExportWarning =>
      'Nunca compartas tu frase de recuperación o llave privada con nadie. Cualquiera que las tenga puede acceder a tu cuenta para siempre y no puedes revocarlas.';

  @override
  String get secretDialogsIUnderstand => 'ENTIENDO';

  @override
  String get secretDialogsExportSecret => 'EXPORTAR SECRETO';

  @override
  String secretDialogsExportLabel(Object label) {
    return 'EXPORTAR $label';
  }

  @override
  String get secretDialogsRecoveryPhrase => 'Frase de recuperación';

  @override
  String get secretDialogsPrivateKeyHex => 'Llave privada (hex)';

  @override
  String get secretDialogsMnemonic => 'MNEMÓNICO';

  @override
  String get secretDialogsPrivateKey => 'LLAVE PRIVADA';

  @override
  String get secretDialogsCopy => 'COPIAR';

  @override
  String get secretDialogsDone => 'LISTO';

  @override
  String get secretDialogsKeyCopied => 'Llave copiada';

  @override
  String get selectAccountScreenRestoreSessionFailed =>
      'No se pudo restaurar la sesión';

  @override
  String get selectAccountScreenEnterMnemonic => 'Ingresa una frase mnemónica';

  @override
  String get selectAccountScreenKeyImported => 'Llave importada con éxito';

  @override
  String get selectAccountScreenEnterPrivateKey => 'Ingresa una llave privada';

  @override
  String get selectAccountScreenKeysActivated => '¡Llaves activadas con éxito!';

  @override
  String get selectAccountScreenKeysNotLinked =>
      'Las llaves aún no están vinculadas a ninguna cuenta';

  @override
  String get selectAccountScreenAddressCopied => 'Dirección copiada';

  @override
  String get selectAccountScreenAccountRemoved =>
      'Cuenta eliminada de este dispositivo';

  @override
  String get selectAccountScreenDeleteAccountFailed =>
      'No se pudo eliminar la cuenta';

  @override
  String get selectAccountScreenKeyPairDeleted => 'Par de llaves eliminado';

  @override
  String get selectAccountScreenDeleteKeyPairFailed =>
      'No se pudo eliminar el par de llaves';

  @override
  String get selectAccountScreenAppResetComplete =>
      'Reinicio de la app completado';

  @override
  String get selectAccountScreenRecoveryPhraseTitle => 'FRASE DE RECUPERACIÓN';

  @override
  String get selectAccountScreenRecoveryPhraseWarning =>
      'Anota estas 12 palabras. Es la única forma de recuperar tu llave. Guárdalas sin conexión. Nunca las compartas.';

  @override
  String get selectAccountScreenImportKeyTitle => 'Importar llave';

  @override
  String get selectAccountScreenImportKeySubtitle =>
      'Importa con frase mnemónica o llave privada';

  @override
  String get selectAccountScreenDeleteAccountTitle => 'ELIMINAR CUENTA';

  @override
  String selectAccountScreenDeleteAccountBody(Object displayName) {
    return 'Elimina \"$displayName\" solo de ESTE DISPOSITIVO: sus llaves, mensajes, contactos y ajustes guardados aquí.';
  }

  @override
  String get selectAccountScreenDeleteAccountNote =>
      'La cuenta on-chain en sí NO se elimina. Puedes volver a agregarla luego con su frase de recuperación o llave privada: sin ese respaldo, pierdes el acceso desde este dispositivo.';

  @override
  String get selectAccountScreenDelete => 'ELIMINAR';

  @override
  String get selectAccountScreenDeleteKeyPairTitle => 'ELIMINAR PAR DE LLAVES';

  @override
  String get selectAccountScreenDeleteKeyPairBody =>
      'Esta acción no se puede deshacer. Asegúrate de haber respaldado tu frase de recuperación.';

  @override
  String get selectAccountScreenResetAppTitle => 'REINICIAR APP';

  @override
  String get selectAccountScreenResetAppHeading =>
      'Esto eliminará de forma permanente.';

  @override
  String get selectAccountScreenResetItemMessages =>
      'Todos los mensajes y conversaciones';

  @override
  String get selectAccountScreenResetItemContacts =>
      'Todos los contactos y grupos';

  @override
  String get selectAccountScreenResetItemKeys =>
      'Todos los pares de llaves y cuentas';

  @override
  String get selectAccountScreenResetItemFeeds =>
      'Todos los feeds, marcadores y ajustes';

  @override
  String get selectAccountScreenResetItemDatabases =>
      'Bases de datos locales de mensajes XMTP';

  @override
  String get selectAccountScreenCannotBeUndone => 'Esto no se puede deshacer.';

  @override
  String get selectAccountScreenReset => 'REINICIAR';

  @override
  String get selectAccountScreenDeleteFromDevice => 'Eliminar del dispositivo';

  @override
  String get selectAccountScreenBadgePending => 'PENDIENTE';

  @override
  String get selectAccountScreenBadgeRecent => 'RECIENTE';

  @override
  String get selectAccountScreenShowQr => 'Mostrar QR';

  @override
  String get selectAccountScreenCopyAddress => 'Copiar dirección';

  @override
  String get selectAccountScreenRemove => 'Quitar';

  @override
  String get selectAccountScreenLogin => 'INICIAR SESIÓN';

  @override
  String get selectAccountScreenCheckActivation => 'VERIFICAR ACTIVACIÓN';

  @override
  String get selectAccountScreenNoIdentitiesTitle => 'Sin identidades';

  @override
  String get selectAccountScreenNoIdentitiesSubtitle =>
      'Crea o importa un par de llaves para empezar';

  @override
  String get selectAccountScreenGenerateNewKey => 'GENERAR LLAVE NUEVA';

  @override
  String get selectAccountScreenImportKeyButton => 'IMPORTAR LLAVE';

  @override
  String get selectAccountScreenResetTooltip => 'Reiniciar app';

  @override
  String get selectAccountScreenIdentities => 'IDENTIDADES';

  @override
  String get selectAccountScreenSelectToAuthenticate =>
      'Selecciona una cuenta para iniciar sesión.';

  @override
  String get selectAccountScreenNoIdentitiesFound =>
      'No se encontraron identidades.';

  @override
  String get selectAccountScreenNewKeysCardName => 'Llaves nuevas';

  @override
  String get selectAccountScreenExpired => 'EXPIRADO';

  @override
  String get selectAccountScreenLinkDeviceTitle => 'VINCULAR DISPOSITIVO';

  @override
  String get selectAccountScreenAddSession => 'AGREGAR SESIÓN';

  @override
  String get selectAccountScreenNewAccount => 'CUENTA NUEVA';

  @override
  String get selectAccountScreenScanAuthorizeKey =>
      'Escanéalo desde una sesión de tu cuenta para agregar esta llave.';

  @override
  String get selectAccountScreenScanCreateAccount =>
      'Pide a un ciudadano que lo escanee para crear una cuenta nueva con esta llave.';

  @override
  String get selectAccountScreenDone => 'LISTO';

  @override
  String get stickerGifToggleSticker => 'STICKER';

  @override
  String get stickerPanelEmptyTitle => 'Aún no tienes stickers';

  @override
  String get stickerPanelEmptyBody =>
      'Mantén presionado cualquier sticker en un chat y toca el botón de guardar para tenerlo aquí.';

  @override
  String get stickerPanelAddDescription => 'Agregar descripción';

  @override
  String get stickerPanelDelete => 'Eliminar';

  @override
  String get stickerPanelDeleteTitle => '¿Eliminar sticker?';

  @override
  String get stickerPanelDeleteBody =>
      'Se quitará de tus stickers. Los mensajes que ya enviaste no se ven afectados.';

  @override
  String get stickerPanelDeleteConfirm => 'Eliminar';

  @override
  String get stickerPanelDismissMenu => 'Descartar menú de sticker';

  @override
  String get syncIndicatorSyncFailedRetry =>
      'Fallo la sincronizacion. Toca para reintentar.';

  @override
  String get unifiedSendSheetTitle => 'Enviar OX';

  @override
  String get unifiedSendSheetFailedToLoadWallets =>
      'No se pudieron cargar las billeteras';

  @override
  String get unifiedSendSheetDirectAddress => 'Dirección directa';

  @override
  String get unifiedSendSheetAddressCopied =>
      'Dirección copiada al portapapeles';

  @override
  String get unifiedSendSheetAmountGreaterThanZero =>
      'El monto debe ser mayor que 0';

  @override
  String get unifiedSendSheetAmountExceedsBalance =>
      'El monto supera el saldo disponible';

  @override
  String get unifiedSendSheetInvalidAmount => 'Monto inválido';

  @override
  String get unifiedSendSheetCannotSendToSameWallet =>
      'No puedes enviar a la misma billetera';

  @override
  String get unifiedSendSheetTransactionSent =>
      '¡Transacción enviada con éxito!';

  @override
  String get unifiedSendSheetVoteStarted =>
      '¡Votación iniciada para la transacción del grupo! Otros miembros ya pueden aprobar.';

  @override
  String get unifiedSendSheetTransactionFailed => 'La transacción falló';

  @override
  String get unifiedSendSheetSearchHint =>
      'Busca por nombre, usuario o dirección…';

  @override
  String get unifiedSendSheetSearchingOnChain => 'Buscando en la cadena…';

  @override
  String get unifiedSendSheetSelectContact =>
      'Selecciona un contacto para enviar OX';

  @override
  String get unifiedSendSheetNoContactsFound => 'No se encontraron contactos';

  @override
  String get unifiedSendSheetKeychain => 'Llavero';

  @override
  String get unifiedSendSheetGroupAccount => 'Cuenta de grupo';

  @override
  String get unifiedSendSheetMyAccount => 'Mi cuenta';

  @override
  String get unifiedSendSheetSendingFrom => 'ENVIANDO DESDE';

  @override
  String get unifiedSendSheetSendingTo => 'ENVIANDO A';

  @override
  String get unifiedSendSheetChange => 'Cambiar';

  @override
  String get unifiedSendSheetMax => 'Máx';

  @override
  String get unifiedSendSheetSending => 'ENVIANDO…';

  @override
  String get unifiedSendSheetSendOx => 'ENVIAR OX';

  @override
  String get unifiedSendSheetChainLabel => 'Red';

  @override
  String get unifiedSendSheetTokenLabel => 'Token';

  @override
  String get unifiedSendSheetGasLabel => 'gas';

  @override
  String get unifiedSendSheetSelectChain => 'Selecciona red';

  @override
  String get unifiedSendSheetSelectToken => 'Selecciona token';

  @override
  String get unifiedSendSheetSafeOtherNetwork =>
      'Una cuenta Safe de PublicOS no puede recibir fondos en otras redes';

  @override
  String get unifiedSendSheetNeedKeychain =>
      'Necesitas una billetera externa para enviar en otras redes';

  @override
  String get unifiedSendSheetChipRequested => 'Solicitado';

  @override
  String get tipSheetTitle => 'Propina con OX';

  @override
  String get tipSheetChooseRecipient => 'Elige a quién dar propina';

  @override
  String get tipSheetActorAuthor => 'Autor';

  @override
  String get tipSheetActorFoundVia => 'Encontrado vía';

  @override
  String get tipSheetActorChannelOwner => 'Dueño del canal';

  @override
  String get tipSheetSendTip => 'ENVIAR PROPINA';

  @override
  String get tipSheetSending => 'ENVIANDO…';

  @override
  String get appSettingsPageSettingsTitle => 'Ajustes';

  @override
  String get appSettingsPageNotificationsTitle => 'Notificaciones';

  @override
  String get appSettingsPageLiveNotificationsTitle => 'Notificaciones en vivo';

  @override
  String get appSettingsPageLiveNotificationsSubtitle =>
      'Muéstralas con la app abierta';

  @override
  String get appSettingsPagePushNotificationsTitle => 'Notificaciones push';

  @override
  String get appSettingsPagePushNotificationsSubtitle =>
      'Recibe alertas con la app cerrada';

  @override
  String get appSettingsPageChainNotificationsTitle =>
      'Notificaciones de la cadena';

  @override
  String get appSettingsPageChainNotificationsSubtitle =>
      'Notificaciones de eventos on-chain';

  @override
  String get appSettingsPageSessionTitle => 'Sesión';

  @override
  String get appSettingsPageAutoLoginTitle => 'Inicio automático';

  @override
  String get appSettingsPageAutoLoginSubtitle =>
      'Omite la selección de cuenta al abrir';

  @override
  String get appSettingsPageBlockchainTitle => 'Blockchain';

  @override
  String get appSettingsPageChainIdLabel => 'Chain ID';

  @override
  String get appSettingsPageRpcLabel => 'RPC';

  @override
  String get appSettingsPagePollingRateLabel => 'FRECUENCIA DE SONDEO';

  @override
  String get appSettingsPageReconnectButton => 'RECONECTAR';

  @override
  String get appSettingsPageReconnectedRpc => 'Reconectado al RPC';

  @override
  String get appSettingsPageVideoTitle => 'Video';

  @override
  String get appSettingsPageVideoAutoloadThresholdLabel =>
      'UMBRAL DE CARGA AUTOMÁTICA';

  @override
  String get appSettingsPageVideoAutoloadThresholdDesc =>
      'Los videos de este tamaño o menos se descargan solos. Los más grandes muestran un aviso \"Toca para cargar\".';

  @override
  String get appSettingsPageVideoThresholdAlwaysAsk => 'Preguntar siempre';

  @override
  String get appSettingsPageVideoThresholdAlwaysAutoload => 'Cargar siempre';

  @override
  String appSettingsPageVideoThresholdMb(Object mb) {
    return '$mb MB';
  }

  @override
  String get appSettingsPageVideoAutoplayTitle =>
      'Reproducción automática en el feed';

  @override
  String get appSettingsPageVideoAutoplaySubtitle =>
      'Silenciado, al aparecer en pantalla (próximamente)';

  @override
  String get appSettingsPageAvatarTitle => 'Avatares NFT';

  @override
  String get appSettingsPageAvatarDesc =>
      'Las fotos de perfil NFT verificadas reciben un toque sutil. Solo afectan la visualización; la propiedad siempre se revalida on-chain.';

  @override
  String get appSettingsPageSparklesTitle => 'Destellos';

  @override
  String get appSettingsPageSparklesSubtitle =>
      'Brillo titilante en avatares NFT verificados';

  @override
  String get appSettingsPageShimmerTitle => 'Barrido brillante';

  @override
  String get appSettingsPageShimmerSubtitle =>
      'Un barrido de luz sobre los avatares NFT verificados';

  @override
  String get appSettingsPageHelpTitle => 'Ayuda';

  @override
  String get appSettingsPageHelpOnboardingDesc =>
      'Vuelve a ver el recorrido de bienvenida: qué es PublicOS, cómo se construye la red y los tipos de cuentas que encontrarás.';

  @override
  String get appSettingsPageWatchOnboardingButton => 'VER INTRODUCCIÓN';

  @override
  String get appSettingsPageReseedDemoDesc =>
      'Vuelve a guardar los contactos de demostración en tu almacenamiento local. Útil tras una actualización con una nueva instantánea.';

  @override
  String get appSettingsPageReseedingButton => 'RECARGANDO…';

  @override
  String get appSettingsPageReseedDemoButton => 'RECARGAR CONTACTOS DEMO';

  @override
  String get appSettingsPageDemoContactsReseeded => 'Contactos demo recargados';

  @override
  String get appSettingsPageDemoNewsDesc =>
      'Crea una lista de Noticias de demostración a partir de un conjunto de feeds RSS en vivo, para que tengas algo que leer. Sobrescribe una lista de Noticias existente.';

  @override
  String get appSettingsPageDemoFeedsDesc =>
      'Crea feeds de demostración desde tus contactos: una lista bluesky desde canales de Bluesky y marcadores para cada app registrada. Las listas sobrescriben a las del mismo nombre.';

  @override
  String get appSettingsPageCreatingButton => 'CREANDO…';

  @override
  String get appSettingsPageCreateDemoChannelButton =>
      'CREAR LISTA DE CANALES DEMO';

  @override
  String get appSettingsPageCreateDemoBlueskyButton =>
      'CREAR LISTA BLUESKY DEMO';

  @override
  String get appSettingsPageBookmarkingButton => 'GUARDANDO…';

  @override
  String get appSettingsPageCreateDemoBookmarksButton =>
      'CREAR MARCADORES DE APPS DEMO';

  @override
  String get appSettingsPageNoChannelsFound =>
      'No se encontraron canales en los contactos';

  @override
  String get appSettingsPageFailedCreateNewsList =>
      'No se pudo crear la lista News';

  @override
  String appSettingsPageCreatedNewsList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canales',
      one: '1 canal',
    );
    return 'Lista News creada con $_temp0';
  }

  @override
  String get appSettingsPageNoBlueskyFeeds =>
      'No se encontraron feeds de Bluesky en los contactos';

  @override
  String get appSettingsPageFailedCreateBlueskyList =>
      'No se pudo crear la lista bluesky';

  @override
  String appSettingsPageCreatedBlueskyList(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count feeds',
      one: '1 feed',
    );
    return 'Lista bluesky creada con $_temp0';
  }

  @override
  String appSettingsPageBookmarkedApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps guardadas',
      one: '1 app guardada',
    );
    return '$_temp0';
  }

  @override
  String appSettingsPageAlreadyBookmarkedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ya guardadas',
      one: '1 ya guardada',
    );
    return ' ($_temp0)';
  }

  @override
  String appSettingsPageFailedSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fallidas',
      one: '1 fallida',
    );
    return ' ($_temp0)';
  }

  @override
  String appSettingsPageRedeployedRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count registros redesplegados',
      one: '1 registro redesplegado',
    );
    return '$_temp0';
  }

  @override
  String get appSettingsPageRedeployFailed =>
      'No se pudo redesplegar el perfil';

  @override
  String appSettingsPageDaoRegistered(Object address) {
    return 'DAO registrada: $address';
  }

  @override
  String get appSettingsPageRunningSync =>
      'Ejecutando sincronización en segundo plano...';

  @override
  String get appSettingsPageSyncCompleted =>
      '¡Sincronización completa! Revisa el registro.';

  @override
  String get appSettingsPageSyncFailed =>
      'Falló la sincronización. Revisa el registro.';

  @override
  String get appSettingsPageSyncLogTitle =>
      'Registro de sincronización en segundo plano';

  @override
  String get appSettingsPageSyncLogEmpty =>
      'Aún no se ha ejecutado ninguna sincronización en segundo plano.\n\nLa primera se ejecutará ~15 minutos después de activar las notificaciones periódicas.';

  @override
  String get appSettingsPageClose => 'Cerrar';

  @override
  String get appSettingsPageCompleteResetTitle => 'Reinicio completo';

  @override
  String get appSettingsPageCompleteResetBody =>
      'Esto borrará permanentemente TODOS los datos, incluyendo:\n• Todos los mensajes\n• Todos los contactos\n• Todas las llaves privadas\n• Todo el almacenamiento seguro\n• Todo el estado de autenticación\n\nEsta acción no se puede deshacer. ¿Seguro?';

  @override
  String get appSettingsPageDeleteAllDataButton => 'BORRAR TODOS LOS DATOS';

  @override
  String get appSettingsPageAllDataDeleted => 'Se han borrado todos los datos.';

  @override
  String get appSettingsPageResetFailed => 'Falló el reinicio';

  @override
  String get appSettingsPageDeleteContactsTitle => 'Borrar todos los contactos';

  @override
  String get appSettingsPageDeleteContactsBody =>
      'Esto borrará todos los contactos guardados localmente.\n\nEsta acción no se puede deshacer.';

  @override
  String get appSettingsPageDeleteAll => 'Borrar todo';

  @override
  String appSettingsPageDeletedContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contactos borrados',
      one: '1 contacto borrado',
    );
    return '$_temp0';
  }

  @override
  String get appSettingsPageDeleteMessagesTitle => 'Borrar todos los mensajes';

  @override
  String get appSettingsPageDeleteMessagesBody =>
      'Esto borrará todos los mensajes y conversaciones guardados localmente.\n\nEl estado de la red XMTP queda intacto; las conversaciones reaparecerán en la próxima sincronización, pero los mensajes históricos no.\n\nEsta acción no se puede deshacer.';

  @override
  String get appSettingsPageDeletedMessages =>
      'Se borraron todos los mensajes y conversaciones';

  @override
  String get appSettingsPageDeleteAppsTitle => 'Borrar todas las apps';

  @override
  String get appSettingsPageDeleteAppsBody =>
      'Esto quitará todas las apps guardadas localmente.\n\nEsta acción no se puede deshacer.';

  @override
  String appSettingsPageDeletedApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps borradas',
      one: '1 app borrada',
    );
    return '$_temp0';
  }

  @override
  String get appSettingsPageClearChainTitle =>
      'Limpiar notificaciones de la cadena';

  @override
  String get appSettingsPageClearChainBody =>
      'Borra toda la actividad on-chain en caché (el feed de notificaciones) y reinicia el cursor de barrido para que se resincronice desde la cadena actual.\n\nÚsalo tras un redespliegue para limpiar notificaciones obsoletas de la cadena anterior.';

  @override
  String get appSettingsPageClear => 'Limpiar';

  @override
  String appSettingsPageClearedNotifs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notificaciones de la cadena limpiadas',
      one: '1 notificación de la cadena limpiada',
    );
    return '$_temp0';
  }

  @override
  String get appSettingsPageExportDbKeyTitle =>
      'Exportar llave de base de datos';

  @override
  String get appSettingsPageExportDbKeyBody =>
      'Tu llave de base de datos cifra la caché local de mensajes XMTP. Esta llave es única de este dispositivo; exportarla te permite importar la misma caché en otro dispositivo. Nunca la compartas con alguien en quien no confíes.';

  @override
  String get appSettingsPageIUnderstand => 'ENTIENDO';

  @override
  String get appSettingsPageDbKeyTitle => 'Llave de BD';

  @override
  String appSettingsPageActiveXmtpKey(Object label) {
    return 'Llave XMTP activa: $label';
  }

  @override
  String get appSettingsPageNoneLower => 'ninguna';

  @override
  String get appSettingsPageNoDbKey => 'No hay llave de BD disponible.';

  @override
  String get appSettingsPageCopy => 'Copiar';

  @override
  String get appSettingsPageCopyLabelDbKey => 'Llave de BD';

  @override
  String get appSettingsPageCopyLabelXmtpAddress => 'Dirección XMTP';

  @override
  String appSettingsPageCopiedToClipboard(Object label) {
    return '$label copiado al portapapeles';
  }

  @override
  String get appSettingsPageImportDbKeyTitle => 'Importar llave de BD';

  @override
  String get appSettingsPageImportDbKeyBody =>
      'Pega una llave de BD en base64. Esto reemplazará la llave actual.';

  @override
  String get appSettingsPageBase64KeyLabel => 'Llave base64';

  @override
  String get appSettingsPagePasteKeyError => 'Pega una llave';

  @override
  String get appSettingsPageDbKeyImported => 'Llave de BD importada';

  @override
  String get appSettingsPageImportFailed => 'Falló la importación';

  @override
  String get appSettingsPageInvalidKey => 'Llave inválida';

  @override
  String get appSettingsPageImportingButton => 'Importando...';

  @override
  String get appSettingsPageImportButton => 'Importar';

  @override
  String get appSettingsPageConnectedBadge => 'CONECTADO';

  @override
  String get appSettingsPageAddressLabel => 'Dirección';

  @override
  String get appSettingsPageNotInitialized => 'Sin inicializar';

  @override
  String get appSettingsPageInboxIdLabel => 'Inbox ID';

  @override
  String get appSettingsPageActiveKeyLabel => 'Llave activa';

  @override
  String get appSettingsPageNone => 'Ninguna';

  @override
  String get appSettingsPageInvalidAddress => 'Inválida';

  @override
  String get appSettingsPageDeveloperTitle => 'Desarrollador';

  @override
  String get appSettingsPageUnlockedBadge => 'DESBLOQUEADO';

  @override
  String get appSettingsPageUtilitiesLabel => 'UTILIDADES';

  @override
  String get appSettingsPageSyncLogChip => 'Registro de sync';

  @override
  String get appSettingsPageTestSyncChip => 'Probar sync';

  @override
  String get appSettingsPageRedeployChip => 'Redesplegar';

  @override
  String get appSettingsPageRegisterDaoChip => 'Registrar DAO';

  @override
  String get appSettingsPageDestructiveLabel => 'DESTRUCTIVO';

  @override
  String get appSettingsPageDeletingButton => 'BORRANDO...';

  @override
  String get appSettingsPageDeleteAllContactsButton =>
      'BORRAR TODOS LOS CONTACTOS';

  @override
  String get appSettingsPageDeleteAllMessagesButton =>
      'BORRAR TODOS LOS MENSAJES';

  @override
  String get appSettingsPageDeleteAllAppsButton => 'BORRAR TODAS LAS APPS';

  @override
  String get appSettingsPageClearingButton => 'LIMPIANDO...';

  @override
  String get appSettingsPageClearChainNotificationsButton =>
      'LIMPIAR NOTIFICACIONES DE LA CADENA';

  @override
  String get appSettingsPageResettingButton => 'REINICIANDO...';

  @override
  String get appSettingsPageResetAllDataButton => 'REINICIAR TODOS LOS DATOS';

  @override
  String get appSettingsPageRegisterDaoTitle => 'Registrar DAO de PublicOS';

  @override
  String get appSettingsPageDaoAlreadyRegistered =>
      'Ya hay una DAO registrada:';

  @override
  String get appSettingsPageUpdateDaoAddress =>
      'Actualizar dirección de la DAO';

  @override
  String get appSettingsPageEnterDaoAddress =>
      'Ingresa la dirección de la DAO raíz de PublicOS.';

  @override
  String get appSettingsPageDaoAddressLabel => 'Dirección de la DAO';

  @override
  String get appSettingsPageRegisterButton => 'Registrar';

  @override
  String get appSettingsPageFailedUpdateLive =>
      'No se pudieron actualizar las notificaciones en vivo';

  @override
  String get appSettingsPageFailedUpdatePush =>
      'No se pudieron actualizar las notificaciones push';

  @override
  String get appSettingsPageFailedUpdateChain =>
      'No se pudieron actualizar las notificaciones de la cadena';

  @override
  String get browserContactNotFound => 'Contacto no encontrado';

  @override
  String get browserFollowingViaAccount =>
      'Ya sigues esta cuenta — sus canales están en Seguidos';

  @override
  String get browserTabChat => 'Chat';

  @override
  String get browserAppNotFound => 'App no encontrada';

  @override
  String get browserTabNotFound => 'Pestaña no encontrada';

  @override
  String get browserVoteStartedMembersApprove =>
      'Votación iniciada — los miembros deben aprobar';

  @override
  String get browserProfileImageUpdated => 'Imagen de perfil actualizada';

  @override
  String get browserCouldNotStartVote =>
      'No se pudo iniciar la votación — inténtalo de nuevo';

  @override
  String get browserSavingToChain => 'Guardando en la cadena...';

  @override
  String get browserRefreshingProfile => 'Actualizando perfil...';

  @override
  String get browserAvatarUpdated => 'Avatar actualizado';

  @override
  String get browserCouldNotSetAvatar =>
      'No se pudo establecer el avatar — inténtalo de nuevo';

  @override
  String get browserProfileBackgroundRemoved => '¡Fondo de perfil eliminado!';

  @override
  String get browserProfileBackgroundUpdated => '¡Fondo de perfil actualizado!';

  @override
  String get browserFailedUpdateBackground =>
      'No se pudo actualizar el fondo: no se pudo guardar el registro.';

  @override
  String get browserGroupChat => 'Chat grupal';

  @override
  String get browserTabSettings => 'Ajustes';

  @override
  String get browserTabApp => 'App';

  @override
  String get browserTabChannel => 'Canal';

  @override
  String get browserTabWeb => 'Web';

  @override
  String get browserTabManagement => 'Gestión';

  @override
  String get browserSwitchTab => 'Cambiar pestaña';

  @override
  String get browserManageTabs => 'Gestionar pestañas';

  @override
  String get browserSectionChats => 'CHATS';

  @override
  String get browserSectionApps => 'APPS';

  @override
  String get browserSectionTabs => 'PESTAÑAS';

  @override
  String get browserTabProfile => 'Perfil';

  @override
  String get browserUnnamedTab => 'Pestaña sin nombre';

  @override
  String get browserTabWebTab => 'Pestaña web';

  @override
  String get browserAppNoUrl =>
      'La app seleccionada no tiene una URL definida.';

  @override
  String get browserTabNoUrl =>
      'La pestaña seleccionada no tiene una URL definida.';

  @override
  String get browserErrorLoadingContent => 'Error al cargar el contenido';

  @override
  String get browserBackToExplorer => 'Volver al explorador';

  @override
  String get browserContactNotLoadedChat => 'Contacto no cargado para el chat.';

  @override
  String get browserLoadingApp => 'Cargando app...';

  @override
  String get browserGoToProfile => 'Ir al perfil';

  @override
  String browserUnknownTab(Object tab) {
    return 'Pestaña desconocida: $tab';
  }

  @override
  String get browserProfileLinkCopied => 'Enlace del perfil copiado';

  @override
  String browserRemovedApp(Object name) {
    return '$name eliminada';
  }

  @override
  String get browserFailedRemoveBookmark => 'No se pudo quitar el marcador';

  @override
  String browserBookmarkedApp(Object name) {
    return '$name guardada en marcadores';
  }

  @override
  String get browserFailedBookmarkApp =>
      'No se pudo guardar la app en marcadores';

  @override
  String get bspScreenNoActiveAccount => 'No hay cuenta activa';

  @override
  String get bspScreenNoActiveSession => 'No hay sesión activa';

  @override
  String get bspScreenEndpointNoUrl => 'El endpoint no tiene URL';

  @override
  String bspScreenConnectingTo(Object label) {
    return 'Conectando a $label…';
  }

  @override
  String bspScreenConnectedTo(Object label) {
    return 'Conectado a $label';
  }

  @override
  String bspScreenUnreachable(Object label) {
    return '$label no responde';
  }

  @override
  String bspScreenRemoved(Object label) {
    return 'Eliminado $label';
  }

  @override
  String bspScreenCouldNotRemove(Object label) {
    return 'No se pudo eliminar $label';
  }

  @override
  String get bspScreenConnection => 'Conexión';

  @override
  String get bspScreenEndpoint => 'Endpoint';

  @override
  String get bspScreenBlock => 'Bloque';

  @override
  String get bspScreenNone => 'Ninguno';

  @override
  String get bspScreenRoleCitizen => 'CIUDADANO';

  @override
  String get bspScreenRolePrivate => 'PRIVADA';

  @override
  String get bspScreenProvider => 'Proveedor';

  @override
  String get bspScreenBalance => 'Saldo';

  @override
  String get bspScreenPaidUntil => 'Cubierto hasta';

  @override
  String get bspScreenTip => 'Consejo';

  @override
  String get bspScreenTipCitizen =>
      'Elige un BSP en Servicios. Los ciudadanos no pagan: la red acuña las tarifas por ti.';

  @override
  String get bspScreenTipPrivate =>
      'Suscríbete a un BSP en Servicios: el primer mes se paga de forma atómica.';

  @override
  String get bspScreenSubscription => 'Suscripción';

  @override
  String get bspScreenManageInTreasury => 'GESTIONAR EN SERVICIOS';

  @override
  String get bspScreenProviders => 'Proveedores';

  @override
  String get bspScreenRegisterBsp => 'REGISTRAR BSP';

  @override
  String get bspScreenAddCustomRpc => 'AGREGAR RPC PERSONALIZADO';

  @override
  String get bspScreenBadgeMine => 'MÍA';

  @override
  String get bspScreenBadgeSubscribed => 'SUSCRITO';

  @override
  String get bspScreenEmptyCitizen =>
      'Aún no hay proveedor conectado. Elige uno en Servicios, registra el tuyo o agrega un RPC personalizado abajo.';

  @override
  String get bspScreenEmptyPrivate =>
      'Aún no hay proveedor conectado. Suscríbete a un BSP en Servicios, registra el tuyo o agrega un RPC personalizado abajo.';

  @override
  String get bspScreenStatusUnreachableLabel => 'SIN CONEXIÓN';

  @override
  String get bspScreenStatusUnreachableDesc =>
      'Ningún endpoint RPC responde. No se pueden leer ni escribir datos en la cadena.';

  @override
  String get bspScreenStatusBspLabel => 'BSP CONECTADO';

  @override
  String get bspScreenStatusBspDesc =>
      'Conectado a través de tu Blockchain Service Provider suscrito.';

  @override
  String get bspScreenStatusCustomLabel => 'RPC PERSONALIZADO';

  @override
  String get bspScreenStatusCustomDesc =>
      'Conectado a través de un endpoint RPC personalizado que configuraste.';

  @override
  String get bspScreenStatusPublicLabel => 'RESPALDO PÚBLICO';

  @override
  String get bspScreenStatusPublicDesc =>
      'Conectado al nodo público por defecto. Suscríbete a un BSP o agrega un RPC personalizado para mayor fiabilidad.';

  @override
  String get bspScreenLegendNoConnection => 'Sin conexión RPC';

  @override
  String get bspScreenLegendPublicFallback => 'Nodo público de respaldo';

  @override
  String get bspScreenLegendBspOrCustom => 'BSP o RPC personalizado';

  @override
  String get bspScreenEarningsFooter =>
      'Las ganancias y los reclamos están en Servicios.';

  @override
  String get bspScreenLabelRpc => 'RPC';

  @override
  String get bspScreenSubs => 'SUBS';

  @override
  String bspScreenSubscriberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suscriptores',
      one: '1 suscriptor',
    );
    return '$_temp0';
  }

  @override
  String get bspScreenRunBy => 'OPERADO POR';

  @override
  String get bspScreenConnect => 'CONECTAR';

  @override
  String get bspScreenConnected => 'CONECTADO';

  @override
  String get bspScreenLabelUrl => 'URL';

  @override
  String get bspScreenCustomRpcSubtitle => 'rpc personalizado';

  @override
  String get bspScreenDelete => 'ELIMINAR';

  @override
  String get bspScreenRegisterTitle => 'Nuevo BSP en cadena';

  @override
  String get bspScreenRegisterSubtitle =>
      'Regístrate como Blockchain Service Provider.';

  @override
  String get bspScreenFieldSlug => 'Slug';

  @override
  String get bspScreenSlugHint => 'p. ej. my-bsp-service';

  @override
  String get bspScreenSlugHelper =>
      '3-32 caracteres: minúsculas, números, guiones y guiones bajos';

  @override
  String get bspScreenSlugRequired => 'El slug es obligatorio';

  @override
  String get bspScreenSlugInvalid =>
      '3-32 caracteres: minúsculas, números, - _';

  @override
  String get bspScreenFieldTitle => 'Título';

  @override
  String get bspScreenTitleHint => 'p. ej. Mi Servicio BSP';

  @override
  String get bspScreenTitleRequired => 'El título es obligatorio';

  @override
  String get bspScreenFieldRpcUrl => 'URL RPC';

  @override
  String get bspScreenRpcUrlRequired => 'La URL RPC es obligatoria';

  @override
  String get bspScreenFieldRegion => 'Región';

  @override
  String get bspScreenRegionHint => 'p. ej. us-east, eu-west';

  @override
  String get bspScreenFieldWebsite => 'Sitio web';

  @override
  String get bspScreenRegister => 'REGISTRAR';

  @override
  String get bspScreenRegistering => 'REGISTRANDO…';

  @override
  String get bspScreenAddRpcTitle => 'Apunta a tu propio nodo';

  @override
  String get bspScreenAddRpcSubtitle =>
      'Se prueba la conectividad antes de guardar.';

  @override
  String get bspScreenFieldName => 'Nombre';

  @override
  String get bspScreenNameHint => 'p. ej. Mi Nodo';

  @override
  String get bspScreenUrlRequired => 'La URL es obligatoria';

  @override
  String get bspScreenAdd => 'AGREGAR';

  @override
  String get bspScreenTesting => 'PROBANDO…';

  @override
  String get chatScreenFailedToSend => 'No se pudo enviar';

  @override
  String get chatScreenFailedToInit => 'No se pudo iniciar el chat';

  @override
  String get chatScreenFailedToUpdateConsent =>
      'No se pudo actualizar el consentimiento de la conversación';

  @override
  String get chatScreenFailedToLoadMessages =>
      'No se pudieron cargar los mensajes';

  @override
  String get chatScreenConsentPrompt =>
      '¿Permitir esta conversación? Enviar un mensaje la permite automáticamente.';

  @override
  String get chatScreenConsentNo => 'No';

  @override
  String get chatScreenConsentYes => 'Sí';

  @override
  String get chatScreenNoMessages => 'Aún no hay mensajes';

  @override
  String get chatScreenStartConversation => '¡Empieza tu conversación abajo!';

  @override
  String get composePostPageSave => 'Guardar';

  @override
  String get composePostPagePost => 'Publicar';

  @override
  String get composePostPageFailedUpdate =>
      'No se pudo actualizar la publicación';

  @override
  String get composePostPageFailedPublish => 'No se pudo publicar';

  @override
  String composePostPageQuotaExceeded(int used, int quota) {
    return 'Cuota de medios excedida: $used de $quota MB usados en este servidor. Libera espacio o sube tu cuota.';
  }

  @override
  String get composePostPageUploadFailed => 'Falló la subida';

  @override
  String composePostPageMediaLimit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos por publicación',
      one: '1 elemento por publicación',
    );
    return 'Límite alcanzado — $_temp0';
  }

  @override
  String get composePostPagePickChannel => 'Elige un canal';

  @override
  String get composePostPageHeaderAboveMedia => 'Encabezado sobre el medio';

  @override
  String get composePostPageHeaderOnMedia => 'Encabezado dentro del medio';

  @override
  String get composePostPageBodyHint => 'Comparte una novedad';

  @override
  String get composePostPageTitle => 'Título';

  @override
  String get composePostPageSummaryHint => 'Agrega un resumen corto';

  @override
  String get composePostPageBadgeVideo => 'VIDEO';

  @override
  String get composePostPageBadgeVid => 'VID';

  @override
  String get composePostPageBadgeCitizen => 'CIUDADANO';

  @override
  String get composePostPageUploading => 'Subiendo…';

  @override
  String composePostPageStatusUploading(int n, int total, int pct) {
    return 'Subiendo $n de $total · $pct%';
  }

  @override
  String get composePostPageStatusMoving => 'Moviendo archivos…';

  @override
  String get composePostPageStatusPosting => 'Publicando…';

  @override
  String get composePostPageMoveFailed => 'No se pudo mover el archivo';

  @override
  String get composePostPageTagsHintEmpty => 'escribe y luego espacio o coma';

  @override
  String get composePostPageTagsHintMore => 'agrega otra';

  @override
  String get composePostPageCommentBarOpen => 'Cualquiera puede responder';

  @override
  String get composePostPageCommentBarApproved => 'Solo lista de permitidos';

  @override
  String get composePostPageCommentBarDisabled => 'Respuestas desactivadas';

  @override
  String get composePostPageReactionBarOpen => 'Cualquiera puede reaccionar';

  @override
  String get composePostPageReactionBarApproved =>
      'Reacciones solo lista de permitidos';

  @override
  String get composePostPageReactionBarDisabled => 'Reacciones desactivadas';

  @override
  String get composePostPageWhoCanReply => 'Quién puede responder';

  @override
  String get composePostPageWhoCanReact => 'Quién puede reaccionar';

  @override
  String get composePostPagePolicyAnyone => 'Cualquiera';

  @override
  String get composePostPagePolicyAllowList => 'Solo lista de permitidos';

  @override
  String get composePostPagePolicyDisabled => 'Desactivado';

  @override
  String get composePostPageCommentSubtitleAnyone =>
      'Cualquier cuenta con acceso al canal puede responder.';

  @override
  String get composePostPageCommentSubtitleAllowList =>
      'Solo las direcciones que agregaste en las reglas de comentarios de esta publicación pueden responder.';

  @override
  String get composePostPageCommentSubtitleDisabled =>
      'Nadie puede responder. Los comentarios existentes siguen visibles.';

  @override
  String get composePostPageReactionSubtitleAnyone =>
      'Cualquier cuenta con acceso al canal puede reaccionar.';

  @override
  String get composePostPageReactionSubtitleAllowList =>
      'Solo las direcciones que agregaste en las reglas de interacción de esta publicación pueden reaccionar. (La misma lista de permitidos rige comentarios y reacciones.)';

  @override
  String get composePostPageReactionSubtitleDisabled =>
      'Nadie puede reaccionar. Las reacciones existentes siguen visibles. Independiente de la política de comentarios.';

  @override
  String get composePostPageRequireVerifiedCitizen =>
      'Requerir ciudadano verificado';

  @override
  String get composePostPageCommentVerifiedSubtitle =>
      'Anula el valor predeterminado del canal para esta publicación. Quienes no son ciudadanos no pueden responder.';

  @override
  String get composePostPageReactionVerifiedSubtitle =>
      'Independiente del interruptor del lado de comentarios. Quienes no son ciudadanos no pueden reaccionar a esta publicación.';

  @override
  String get composePostPageDone => 'Listo';

  @override
  String get composePostPageLanguageHeader => 'IDIOMA DE LA PUBLICACIÓN';

  @override
  String get composePostPageChannelHeader => 'PUBLICAR EN';

  @override
  String get composePostPageTooltipHero => 'Portada (imágenes / videos)';

  @override
  String get composePostPageTooltipMedia =>
      'Medios de apoyo (imágenes / videos)';

  @override
  String get composePostPageTooltipAudio =>
      'Audio (la pista de sonido del post)';

  @override
  String get composePostPageAudioUnsupported =>
      'Elige un archivo MP3, M4A, WAV u OGG';

  @override
  String get composePostPageTooltipSummary => 'Resumen';

  @override
  String get composePostPageTooltipLink => 'Enlace';

  @override
  String get composePostPageTooltipTags => 'Etiquetas';

  @override
  String get contactSettingsScreenNoContactSelected =>
      'Ningún contacto seleccionado';

  @override
  String get createChannelPageEditTitle => 'Editar canal';

  @override
  String get createChannelPageNewTitle => 'Nuevo canal';

  @override
  String get createChannelPageSave => 'Guardar';

  @override
  String get createChannelPageCreate => 'Crear';

  @override
  String get createChannelPageServerLoading => 'Cargando…';

  @override
  String get createChannelPageNoServerAvailable => 'No hay servidor disponible';

  @override
  String createChannelPageChannelUpdated(Object name) {
    return 'Canal \"$name\" actualizado';
  }

  @override
  String createChannelPageChannelCreated(Object name) {
    return 'Canal \"$name\" creado';
  }

  @override
  String get createChannelPageUnknownError => 'Error desconocido';

  @override
  String createChannelPageFailedToUpdate(Object msg) {
    return 'No se pudo actualizar: $msg';
  }

  @override
  String createChannelPageFailedToCreate(Object msg) {
    return 'No se pudo crear: $msg';
  }

  @override
  String get createChannelPageSectionIdentity => 'IDENTIDAD';

  @override
  String get createChannelPageNameHint => 'Nombre del canal';

  @override
  String get createChannelPageIconUrlLabel => 'URL DEL ICONO';

  @override
  String get createChannelPageIconUrlHint => 'https://…/icon.png';

  @override
  String get createChannelPageSlugLabel => 'SLUG';

  @override
  String get createChannelPageSlugHint => 'canal-slug';

  @override
  String get createChannelPageDescriptionLabel => 'DESCRIPCIÓN';

  @override
  String get createChannelPageLanguageLabel => 'IDIOMA';

  @override
  String get createChannelPageDescriptionHint => '¿De qué trata este canal?';

  @override
  String get createChannelPageSectionServer => 'SERVIDOR';

  @override
  String get createChannelPageServerLocked =>
      'El servidor no se puede cambiar después de crearlo';

  @override
  String get createChannelPageServerSubtitle => 'Dónde se aloja este canal';

  @override
  String get createChannelPageChooseServer => 'Elige servidor';

  @override
  String get createChannelPageSectionPosting => 'PUBLICACIÓN';

  @override
  String get createChannelPagePolicyOwnerLabel => 'Solo el dueño';

  @override
  String get createChannelPagePolicyOwnerSubtitle =>
      'Nadie mas que tu puede enviar publicaciones.';

  @override
  String get createChannelPagePolicyOpenLabel => 'Abierto';

  @override
  String get createChannelPagePolicyOpenSubtitle =>
      'Cualquiera que pueda leer el canal puede enviar publicaciones.';

  @override
  String get createChannelPagePolicyApprovedLabel => 'Aprobados';

  @override
  String get createChannelPagePolicyApprovedSubtitle =>
      'Solo las personas en tu lista de autores pueden enviar publicaciones.';

  @override
  String get createChannelPageRateLimitLabel =>
      'LÍMITE DE FRECUENCIA (POSTS / HORA, 0 = ILIMITADO)';

  @override
  String get createChannelPageSectionPrivacy => 'PRIVACIDAD';

  @override
  String get createChannelPagePrivateLabel => 'Canal privado';

  @override
  String get createChannelPagePrivateSubtitleOn =>
      'Solo los seguidores aprobados pueden leer los posts. Las demás cuentas ven una pantalla de bloqueo y pueden solicitar acceso.';

  @override
  String get createChannelPagePrivateSubtitleOff =>
      'Cualquiera con el enlace puede leer este canal.';

  @override
  String get createChannelPagePrivateInboxNote =>
      'Tendrás una bandeja de solicitudes de seguimiento para aprobar o rechazar lectores.';

  @override
  String get createChannelPageSectionCitizenship => 'CIUDADANÍA';

  @override
  String get createChannelPageCitizenshipNote =>
      'Restringe acciones a ciudadanos verificados.';

  @override
  String get createChannelPageCitizensReadingLabel =>
      'Solo ciudadanos — lectura';

  @override
  String get createChannelPageCitizensPostingLabel =>
      'Solo ciudadanos — publicación';

  @override
  String get createChannelPageCitizensCommentsLabel =>
      'Solo ciudadanos — comentarios';

  @override
  String get createChannelPageSectionRetention => 'RETENCIÓN';

  @override
  String get createChannelPageMaxPostsLabel => 'POSTS MÁX (VACÍO = ILIMITADO)';

  @override
  String get createChannelPageMaxDaysLabel => 'DÍAS MÁX (VACÍO = ILIMITADO)';

  @override
  String get createGroupPageAddMembersTitle => 'Agregar miembros';

  @override
  String get createGroupPageDetailsTitle => 'Detalles del grupo';

  @override
  String get createGroupPageSearchHint =>
      'Busca por nombre, direccion o inbox ID';

  @override
  String get createGroupPageSortRecent => 'Recientes';

  @override
  String get commentSectionTitle => 'Comentarios';

  @override
  String commentSectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comentarios',
      one: '1 comentario',
    );
    return '$_temp0';
  }

  @override
  String get commentSectionEmpty => 'Aún no hay comentarios. Sé el primero.';

  @override
  String get commentSectionLoading => 'Cargando comentarios…';

  @override
  String get commentSectionLoadMore => 'Cargar más comentarios';

  @override
  String get commentSortBest => 'Mejores';

  @override
  String get commentSortTop => 'Más votados';

  @override
  String get commentSortNewest => 'Más recientes';

  @override
  String get commentSortOldest => 'Más antiguos';

  @override
  String get createGroupPageNoContactsMatch => 'Ningun contacto coincide';

  @override
  String get createGroupPageNoContactsHint =>
      'Prueba con un nombre, una direccion con prefijo 0x o un inbox ID de 64 caracteres.';

  @override
  String get createGroupPageFieldNameLabel => 'NOMBRE DEL GRUPO';

  @override
  String get createGroupPageNameHint => 'Builders, HH 2026, …';

  @override
  String get createGroupPageFieldImageLabel => 'IMAGEN DEL GRUPO';

  @override
  String get createGroupPageNoSspMessage =>
      'Configura un Servidor Social (SSP) para subir una imagen de grupo. Aun puedes pegar una URL de imagen abajo.';

  @override
  String get createGroupPageFieldDescriptionLabel => 'DESCRIPCION';

  @override
  String get createGroupPageDescriptionHint => '¿Para que es este grupo?';

  @override
  String get createGroupPageNextButton => 'SIGUIENTE';

  @override
  String get createGroupPageAddButton => 'AGREGAR MIEMBROS';

  @override
  String get createGroupPageCreateButton => 'CREAR GRUPO';

  @override
  String get createGroupPagePickInboxTitle => 'ELIGE INBOX';

  @override
  String createGroupPageMultipleDevices(Object name) {
    return '$name tiene varios dispositivos registrados.';
  }

  @override
  String createGroupPageAllDevicesAdded(Object name) {
    return 'Ya agregaste todos los dispositivos de $name';
  }

  @override
  String get createGroupPageNameRequired =>
      'El nombre del grupo es obligatorio';

  @override
  String get createGroupPageSelectContact => 'Selecciona al menos un contacto';

  @override
  String get createGroupPageNoValidInboxIds =>
      'Los contactos seleccionados no tienen inbox IDs validos';

  @override
  String get createGroupPageCreationNoId =>
      'La creacion del grupo no devolvio un id';

  @override
  String get explorerBackAgainToExit => 'Atrás de nuevo para salir';

  @override
  String get explorerTabFeeds => 'Feeds';

  @override
  String get explorerTabContacts => 'Contactos';

  @override
  String get explorerTabApps => 'Apps';

  @override
  String get explorerTabMessages => 'Mensajes';

  @override
  String get explorerTabWallet => 'Billetera';

  @override
  String appsViewRemovedSnack(Object name) {
    return 'Eliminada $name';
  }

  @override
  String appsViewBookmarkedSnack(Object name) {
    return 'Guardada $name';
  }

  @override
  String appsViewAppMisconfigured(Object label) {
    return '$label no se puede abrir: la app no tiene dirección configurada. Es cosa de quien la publicó, no tuya.';
  }

  @override
  String appsViewComingSoon(Object label) {
    return '$label muy pronto';
  }

  @override
  String get appsViewSystemTreasury => 'Servicios';

  @override
  String get appsViewSystemAccountCenter => 'Cuenta';

  @override
  String get appsViewSystemSocialGraph => 'Grafo social';

  @override
  String get appsViewSystemSettings => 'Ajustes';

  @override
  String get appsViewSystemNodes => 'Nodos';

  @override
  String get appsViewSearchHint => 'Buscar apps';

  @override
  String get appsViewSearching => 'Buscando apps...';

  @override
  String get appsViewChipBookmarked => 'Guardadas';

  @override
  String get appsViewChipMyApps => 'Mis apps';

  @override
  String get appsViewChipAll => 'Todas';

  @override
  String get appsViewChipRegister => 'Registrar';

  @override
  String get appsViewChipSettings => 'Ajustes';

  @override
  String get appsViewEmptyNoMatchesTitle => 'Sin coincidencias';

  @override
  String get appsViewEmptyTryDifferentTerm =>
      'Prueba con otro término de búsqueda.';

  @override
  String get appsViewEmptyNoBookmarksTitle => 'No tienes apps guardadas';

  @override
  String get appsViewEmptyNoBookmarksBody =>
      'Mantén pulsada cualquier app en \"Todas\" para guardarla en tus marcadores.';

  @override
  String get appsViewEmptyNoMyAppsTitle => 'Aún no has registrado ninguna app';

  @override
  String get appsViewEmptyNoMyAppsBody =>
      'Toca \"Registrar\" en la barra para publicar tu primera app.';

  @override
  String get appsViewEmptyNoAppsFoundTitle => 'No se encontraron apps';

  @override
  String get appsViewSearchPromptTitle => 'Busca en todas las apps';

  @override
  String get appsViewSearchPromptBody =>
      'Escribe al menos 2 caracteres para buscar\napps en toda la red.';

  @override
  String get contactsViewShare => 'Compartir';

  @override
  String get contactsViewSend => 'Enviar';

  @override
  String get contactsViewDelete => 'Eliminar';

  @override
  String get contactsViewDeleteContactTitle => 'ELIMINAR CONTACTO';

  @override
  String contactsViewDeleteConfirm(Object name) {
    return '¿Eliminar \"$name\" de tus contactos?';
  }

  @override
  String contactsViewRemovedFromContacts(Object name) {
    return '$name eliminado de contactos';
  }

  @override
  String get contactsViewFailedToRemove => 'No se pudo eliminar el contacto';

  @override
  String get contactsViewSearchHint => 'Busca por nombre, dirección o inbox';

  @override
  String get contactsViewFilterPersonal => 'Personal';

  @override
  String get contactsViewFilterOrgs => 'Orgs';

  @override
  String get contactsViewSortAsc => 'A-Z';

  @override
  String get contactsViewSortDesc => 'Z-A';

  @override
  String get contactsViewNewOrg => 'Nueva Org';

  @override
  String get contactsViewSettings => 'Ajustes';

  @override
  String get contactsViewFailedToLoad => 'No se pudieron cargar los contactos';

  @override
  String get contactsViewNoMatches => 'Sin coincidencias';

  @override
  String get contactsViewNoContactsYet => 'Aún no hay contactos';

  @override
  String get contactsViewNoMatchesHint =>
      'Prueba con otro nombre, dirección o ID de inbox.';

  @override
  String get contactsViewEmptyHint =>
      'Los contactos de PublicOS con los que interactúas aparecerán aquí.';

  @override
  String get channelSigninTitle => 'Iniciar sesión en el canal';

  @override
  String get channelSigninBodyOptional =>
      'El servidor de este canal acepta inicio de sesión de PublicOS. Con la sesión iniciada, cada lectura te identifica ante este servidor: cuentas como lector verificado y el canal puede responder a quién eres. Sin sesión, lees de forma anónima.';

  @override
  String get channelSigninBodyRequired =>
      'Este canal requiere inicio de sesión de PublicOS para leerse - tus lecturas te identifican ante su servidor.';

  @override
  String get channelSigninStateOn =>
      'Actualmente tienes la sesión iniciada en este canal.';

  @override
  String get channelSigninStateOff => 'Actualmente lees de forma anónima.';

  @override
  String get channelSigninEnable => 'Iniciar sesión';

  @override
  String get channelSigninDisable => 'Cerrar sesión';

  @override
  String get channelSigninAllow => 'Permitir';

  @override
  String get channelSigninDeny => 'Denegar';

  @override
  String get channelSigninForget => 'Olvidar';

  @override
  String get channelSigninMenuTitle => 'Inicio de sesión en este canal';

  @override
  String get signinLockedBadge => 'REQUIERE INICIO DE SESIÓN';

  @override
  String get signinLockedBlurbDenied =>
      'Dijiste que no a este canal. Inicia sesión para leerlo.';

  @override
  String get signinLockedBlurbAsk =>
      'Este canal requiere inicio de sesión para leerse. Tus lecturas te identifican ante su servidor.';

  @override
  String get feedsSettingsSheetAutoSigninLabel =>
      'INICIO DE SESIÓN AUTOMÁTICO EN FEEDS';

  @override
  String get feedsSettingsSheetAutoSigninOn =>
      'Con sesión iniciada en todos los canales a los que no dijiste que no';

  @override
  String get feedsSettingsSheetAutoSigninOff => 'Cada canal pregunta una vez';

  @override
  String get feedsViewDiscover => 'Descubrir';

  @override
  String get feedsViewBookmarks => 'Guardados';

  @override
  String get feedsViewVia => 'vía';

  @override
  String get feedsViewOnboardingTitle => 'Aquí van tus listas y canales';

  @override
  String get feedsViewOnboardingSubtitle =>
      'Crea o sigue un canal para empezar';

  @override
  String get messagesViewSearchHint => 'Busca por nombre, dirección o inbox';

  @override
  String get messagesViewEmptyNoMatchesTitle => 'Sin resultados';

  @override
  String get messagesViewEmptyNoMatchesSubtitle =>
      'Prueba con otro nombre, dirección o inbox ID.';

  @override
  String get messagesViewEmptyNoRequestsTitle => 'Sin solicitudes nuevas';

  @override
  String get messagesViewEmptyNoRequestsSubtitle =>
      'Las solicitudes de conversación nuevas aparecerán aquí.';

  @override
  String get messagesViewEmptyNoConversationsTitle =>
      'Aún no hay conversaciones';

  @override
  String get messagesViewEmptyNoConversationsSubtitle =>
      'Inicia una conversación nueva para verla aquí.';

  @override
  String get messagesViewNoKeysTitle => 'Pon en marcha tu inbox';

  @override
  String get messagesViewNoKeysSubtitleBefore =>
      'Inicia sesión con una de tus llaves usando el botón ';

  @override
  String get messagesViewNoKeysSubtitleAfter => ' en el llavero.';

  @override
  String get manageChannelPageManageLabel => 'gestionar';

  @override
  String get manageChannelPageMissingServerInfo =>
      'Al canal le falta info del servidor — no se puede construir la URL';

  @override
  String manageChannelPageExportUrlCopied(Object label) {
    return 'URL de $label copiada';
  }

  @override
  String get manageChannelPageDeleteTitle => '¿Eliminar canal?';

  @override
  String manageChannelPageDeleteBody(Object name) {
    return 'Esto elimina \"$name\" y cada publicación, comentario, voto, reacción, seguidor, publicador, veto y entrada de lista blanca asociada. No se puede deshacer.';
  }

  @override
  String get manageChannelPageDelete => 'Eliminar';

  @override
  String manageChannelPageDeleted(Object name) {
    return 'Canal \"$name\" eliminado';
  }

  @override
  String get manageChannelPageUnknownError => 'Error desconocido';

  @override
  String manageChannelPageFailDelete(Object message) {
    return 'No se pudo eliminar: $message';
  }

  @override
  String get manageChannelPageTabPosters => 'PUBLICADORES';

  @override
  String get manageChannelPageTabBans => 'VETOS';

  @override
  String get manageChannelPageTabReadAccess => 'ACCESO DE LECTURA';

  @override
  String get manageChannelPageEditChannel => 'Editar canal';

  @override
  String get manageChannelPageMenuCopyJson => 'Copiar URL de JSON Feed';

  @override
  String get manageChannelPageMenuCopyRss => 'Copiar URL de RSS';

  @override
  String get manageChannelPageMenuCopyAtom => 'Copiar URL de Atom';

  @override
  String get manageChannelPageMenuDelete => 'Eliminar canal';

  @override
  String get manageChannelPageReasonHint => 'Motivo (opcional)';

  @override
  String get manageChannelPageRemoveTooltip => 'Quitar';

  @override
  String get manageChannelPageGateCitizensOnly => 'SOLO CIUDADANOS';

  @override
  String get manageChannelPageWhoCanPost => 'QUIÉN PUEDE PUBLICAR';

  @override
  String manageChannelPagePostersVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tú + $count cuentas autorizadas',
      one: 'Tú + 1 cuenta autorizada',
      zero: 'Solo tú puedes publicar',
    );
    return '$_temp0';
  }

  @override
  String get manageChannelPagePostersExplainerApproved =>
      'La publicación está en \"Aprobado\" — solo el dueño del canal y las direcciones de esta lista pueden crear publicaciones.';

  @override
  String get manageChannelPagePostersVerdictOpen =>
      'Cualquiera con acceso puede publicar';

  @override
  String get manageChannelPagePostersExplainerOpen =>
      'La publicación está en \"Abierto\" — esta lista no tiene efecto ahora mismo. Cambia la política de publicación del canal a \"Aprobado\" en Editar canal para usarla.';

  @override
  String get manageChannelPagePostersVerdictOwnerOnly =>
      'Solo tú puedes publicar';

  @override
  String get manageChannelPagePostersExplainerOwner =>
      'La publicación está en \"Solo dueño\" — esta lista no tiene efecto ahora mismo. Cambia la política de publicación del canal a \"Aprobado\" en Editar canal para otorgar permisos de publicación a cuentas específicas.';

  @override
  String get manageChannelPagePostersEmpty =>
      'Aún no hay publicadores autorizados';

  @override
  String get manageChannelPagePosterAddHint =>
      'Nombre o dirección 0x (permitir publicar)';

  @override
  String get manageChannelPagePosterAddButton => 'Permitir';

  @override
  String get manageChannelPageFailAddPoster =>
      'No se pudo añadir el publicador';

  @override
  String get manageChannelPageFailRemovePoster =>
      'No se pudo quitar el publicador';

  @override
  String get manageChannelPageWhosBlocked => 'QUIÉN ESTÁ VETADO';

  @override
  String manageChannelPageBansVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuentas vetadas',
      one: '1 cuenta vetada',
      zero: 'Nadie está vetado en este canal',
    );
    return '$_temp0';
  }

  @override
  String get manageChannelPageBansExplainer =>
      'Las cuentas vetadas no pueden leer, publicar, comentar, votar ni reaccionar en este canal. Los vetos se mantienen hasta que los quites aquí.';

  @override
  String get manageChannelPageBansEmpty => 'Nadie vetado en este canal';

  @override
  String get manageChannelPageBanAddHint =>
      'Nombre o dirección 0x (vetar del canal)';

  @override
  String get manageChannelPageBanAddButton => 'Vetar';

  @override
  String get manageChannelPageFailBan => 'No se pudo vetar';

  @override
  String get manageChannelPageFailUnban => 'No se pudo quitar el veto';

  @override
  String get manageChannelPageWhoCanRead => 'QUIÉN PUEDE LEER';

  @override
  String get manageChannelPageReadVerdictPublic =>
      'El canal es público — cualquiera puede leer';

  @override
  String get manageChannelPageReadExplainerPublic =>
      'La lista blanca de lectura solo aplica a canales privados. Activa \"Privado\" en Editar canal para usar esta lista — de lo contrario las entradas aquí se ignoran.';

  @override
  String manageChannelPageReadVerdict(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tú + $count lectores',
      one: 'Tú + 1 lector',
      zero: 'Solo tú puedes leer este canal privado',
    );
    return '$_temp0';
  }

  @override
  String get manageChannelPageReadExplainerPrivate =>
      'El canal es privado — solo tú y las cuentas de la lista de abajo pueden leer publicaciones. Las nuevas solicitudes aparecen arriba de la lista; al aprobarlas se mueven a ella.';

  @override
  String get manageChannelPageReadEmpty =>
      'Aún no hay cuentas en la lista de lectura';

  @override
  String get manageChannelPageReadAddHint =>
      'Nombre o dirección 0x (otorgar acceso de lectura)';

  @override
  String get manageChannelPageReadAddButton => 'Permitir lectura';

  @override
  String get manageChannelPageFailAddWhitelist =>
      'No se pudo añadir a la lista blanca';

  @override
  String get manageChannelPageFailRemove => 'No se pudo quitar';

  @override
  String get manageChannelPageFailApprove => 'No se pudo aprobar';

  @override
  String get manageChannelPageFailIgnore => 'No se pudo ignorar';

  @override
  String get manageChannelPageRequestsHeader => 'SOLICITUDES · ÚLTIMOS 14 DÍAS';

  @override
  String get manageChannelPageFilterPending => 'Pendientes';

  @override
  String get manageChannelPageFilterIgnored => 'Ignoradas';

  @override
  String get manageChannelPageFilterApproved => 'Aprobadas';

  @override
  String manageChannelPageNoRequestsInWindow(Object filter) {
    return 'No hay solicitudes $filter en los últimos 14 días';
  }

  @override
  String manageChannelPageRequestedAt(Object when) {
    return 'Solicitado $when';
  }

  @override
  String get manageChannelPageRequestApprovedTag => 'aprobada';

  @override
  String get manageChannelPageActionIgnore => 'Ignorar';

  @override
  String get manageChannelPageActionApprove => 'Aprobar';

  @override
  String get manageChannelPageJustNow => 'ahora mismo';

  @override
  String manageChannelPageMinutesAgo(Object minutes) {
    return 'hace ${minutes}m';
  }

  @override
  String manageChannelPageHoursAgo(Object hours) {
    return 'hace ${hours}h';
  }

  @override
  String manageChannelPageDaysAgo(Object days) {
    return 'hace ${days}d';
  }

  @override
  String manageChannelPageMonthsAgo(Object months) {
    return 'hace ${months}mes';
  }

  @override
  String get manageServerPageNoActiveAccount => 'No hay cuenta activa';

  @override
  String get manageServerPageAuthorUpdated => 'Perfil de autor actualizado';

  @override
  String get manageServerPageAuthorUpdateFailed =>
      'No se pudo actualizar el perfil de autor';

  @override
  String manageServerPageCopied(Object url) {
    return 'Copiado: $url';
  }

  @override
  String get manageServerPageDeleteChannelTitle => 'Eliminar canal';

  @override
  String manageServerPageDeleteChannelBody(Object name) {
    return '¿Eliminar \"$name\" y todas sus publicaciones? Esto no se puede deshacer.';
  }

  @override
  String manageServerPageDeletedNamed(Object name) {
    return 'Eliminado $name';
  }

  @override
  String get manageServerPageDeleteFailed => 'Error al eliminar';

  @override
  String get manageServerPageGalleryPermissionDenied =>
      'Permiso de galería denegado';

  @override
  String manageServerPageDownloadFailedHttp(Object code) {
    return 'Error al descargar (HTTP $code)';
  }

  @override
  String get manageServerPageSavedToGallery => 'Guardado en la galería';

  @override
  String get manageServerPageDownloadFailed => 'Error al descargar';

  @override
  String get manageServerPageAddressMustBeHex =>
      'La dirección debe ser 0x… (40 hex)';

  @override
  String get manageServerPageAddFailed => 'Error al agregar';

  @override
  String get manageServerPageRemoveFailed => 'Error al quitar';

  @override
  String get manageServerPageBanFailed => 'Error al banear';

  @override
  String get manageServerPageUnbanFailed => 'Error al desbanear';

  @override
  String get manageServerPageCouldNotOpen => 'No se pudo abrir';

  @override
  String get manageServerPageDelete => 'Eliminar';

  @override
  String get manageServerPageConfirm => 'Confirmar';

  @override
  String get manageServerPageTitle => 'Administrar servidor';

  @override
  String get manageServerPageIdentity => 'Identidad';

  @override
  String get manageServerPageCustomPill => 'PERSONALIZADA';

  @override
  String get manageServerPageIdentityDescSsp =>
      'Tu Servidor Social suscrito. Las publicaciones, canales, medios y moderación viven todos aquí.';

  @override
  String get manageServerPageIdentityDescCustom =>
      'Un servidor de feeds personalizado que agregaste directamente. No registrado on-chain — solo visible para los clientes a los que se lo digas.';

  @override
  String get manageServerPageLabel => 'Etiqueta';

  @override
  String get manageServerPageUrl => 'URL';

  @override
  String get manageServerPageSlug => 'Slug';

  @override
  String get manageServerPageAuthorProfile => 'Perfil de autor';

  @override
  String get manageServerPageAuthorDesc =>
      'Cómo te ven los lectores RSS que no son de PublicOS (NetNewsWire, Feedbin, Inoreader, etc). Los clientes compatibles con PublicOS ignoran estos campos y siempre muestran tu perfil on-chain.';

  @override
  String get manageServerPageHandle => 'Handle';

  @override
  String get manageServerPageNote => 'Nota';

  @override
  String get manageServerPageHandleNote =>
      'El handle se establece automáticamente desde tu dirección y no se puede cambiar aquí.';

  @override
  String get manageServerPageDisplayName => 'Nombre visible';

  @override
  String get manageServerPageDisplayNameHint =>
      'Se muestra junto a tus publicaciones';

  @override
  String get manageServerPageBio => 'Bio';

  @override
  String get manageServerPageBioHint => 'Una línea corta sobre ti';

  @override
  String get manageServerPageAvatarUrl => 'URL del avatar';

  @override
  String get manageServerPageSaving => 'GUARDANDO…';

  @override
  String get manageServerPageSaveAuthorProfile => 'GUARDAR PERFIL DE AUTOR';

  @override
  String get manageServerPageMedia => 'Medios';

  @override
  String get manageServerPagePrivateBadge => 'PRIVADO';

  @override
  String manageServerPageFilesPill(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ARCHIVOS',
      one: '1 ARCHIVO',
    );
    return '$_temp0';
  }

  @override
  String manageServerPageQuotaUsed(Object used, Object total) {
    return '$used / $total MB';
  }

  @override
  String manageServerPageQuotaUsedNoTotal(Object used) {
    return '$used MB usados';
  }

  @override
  String manageServerPageFileCountWithMax(Object count, Object max) {
    return '$count / $max archivos';
  }

  @override
  String manageServerPageFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0';
  }

  @override
  String get manageServerPageQuotaFullBoth =>
      'Cuota llena. Elimina archivos para liberar tamaño y cantidad.';

  @override
  String get manageServerPageFileCountLimit =>
      'Límite de cantidad de archivos alcanzado. Elimina archivos para subir más.';

  @override
  String get manageServerPageStorageQuotaFull =>
      'Cuota de almacenamiento llena. Elimina archivos para liberar espacio.';

  @override
  String get manageServerPageNoMedia =>
      'No hay archivos de medios. Los archivos subidos desde redactar publicación o desde los selectores de avatar/banner aparecerán aquí.';

  @override
  String get manageServerPageUnknownMime => 'desconocido';

  @override
  String get manageServerPagePreview => 'Vista previa';

  @override
  String get manageServerPageOpenInBrowser => 'Abrir en el navegador';

  @override
  String get manageServerPageDownload => 'Descargar';

  @override
  String get manageServerPageCopyLink => 'Copiar enlace';

  @override
  String get manageServerPageChannels => 'Canales';

  @override
  String get manageServerPageNoChannels =>
      'Aún no hay canales en este servidor.';

  @override
  String get manageServerPageCreateChannel => 'CREAR CANAL';

  @override
  String get manageServerPageCopyUrl => 'Copiar URL';

  @override
  String get manageServerPageRemoveFromTabs => 'Quitar de pestañas';

  @override
  String get manageServerPageAddAsTab => 'Agregar como pestaña';

  @override
  String get manageServerPageSettings => 'Configuración';

  @override
  String get manageServerPageAddressHint => 'Nombre o dirección 0x';

  @override
  String get accountResolveNoMatch =>
      'No se encontró ninguna cuenta con ese nombre — ingresa una dirección 0x o elige un contacto';

  @override
  String get manageServerPageRemove => 'Quitar';

  @override
  String get manageServerPageBans => 'Baneos';

  @override
  String get manageServerPageBansDesc =>
      'Baneo a nivel de cuenta: bloqueado para publicar, comentar y reaccionar en cada canal que poseas aquí. Siempre prevalece sobre las reglas por canal.';

  @override
  String get manageServerPageReasonHint => 'Motivo (opcional)';

  @override
  String get manageServerPageBan => 'Banear';

  @override
  String get manageServerPageNoBans => 'No hay cuentas baneadas.';

  @override
  String get manageServerPageUnban => 'Desbanear';

  @override
  String get manageServerPageDeleteFileTitle => 'Eliminar archivo';

  @override
  String manageServerPageDeleteFileBody(Object name) {
    return '¿Eliminar \"$name\"? Esto libera tu cuota de medios y no se puede deshacer.';
  }

  @override
  String get nodePageTitle => 'Nodos';

  @override
  String get nodePageMyNodes => 'Mis Nodos';

  @override
  String get nodePageNotSigner =>
      'No eres firmante. Los firmantes se admiten por gobernanza, no por registro.';

  @override
  String get nodePageNodeDirectory => 'Directorio de Nodos';

  @override
  String get nodePageDirectoryDescription =>
      'Explora los firmantes de consenso que aseguran la red actualmente.';

  @override
  String get nodePageBrowseNodes => 'EXPLORAR NODOS';

  @override
  String get nodePageNotariesTitle => 'Los notarios de la red';

  @override
  String get nodePageNotariesBody1 =>
      'Los firmantes operan los nodos de consenso que notarizan cada bloque: el registro publico compartido sobre el que se construye toda la red.';

  @override
  String get nodePageNotariesBody2 =>
      'Para mantener ese registro confiable, el conjunto de firmantes se mantiene pequeno y responsable: los nuevos firmantes se admiten solo por gobernanza, nunca por registro abierto.';

  @override
  String get nodePageAdmittedByGovernance => 'Admitidos por gobernanza';

  @override
  String get nodePagePoaSubtitle => 'Firmantes de consenso PoA';

  @override
  String get nodePageFailedToLoad => 'No se pudieron cargar los nodos';

  @override
  String get nodePageNoNodes => 'Aun no hay nodos registrados';

  @override
  String get nodePageRunBy => 'Operado por ';

  @override
  String get nodePageRemoveNodeTitle => 'Eliminar Nodo';

  @override
  String nodePageRemoveNodeBody(Object address) {
    return '¿Seguro que quieres eliminar este nodo? Esta accion no se puede deshacer.\n\n$address';
  }

  @override
  String get nodePageRemove => 'Eliminar';

  @override
  String get nodePageNodeRemoved => 'Nodo eliminado correctamente';

  @override
  String get nodePageManageNode => 'Gestionar Nodo';

  @override
  String get nodePageAddress => 'DIRECCION';

  @override
  String get nodePageRemoveNodeButton => 'ELIMINAR NODO';

  @override
  String get nodePageLabelField => 'Etiqueta';

  @override
  String get nodePageSave => 'Guardar';

  @override
  String get nodePageLabelUpper => 'ETIQUETA';

  @override
  String get nodePageEditLabel => 'Editar etiqueta';

  @override
  String get notificationsScreenTitle => 'Notificaciones';

  @override
  String get notificationsScreenTypesTooltip => 'Tipos de notificaciones';

  @override
  String get notificationsScreenNoActivity => 'Aún no hay actividad.';

  @override
  String get notificationsScreenYou => 'Tú';

  @override
  String get notificationsScreenYouUpdatedAvatar => 'Actualizaste tu avatar';

  @override
  String get notificationsScreenTheyUpdatedAvatar => ' actualizó su avatar';

  @override
  String get notificationsScreenYouUpdatedBanner => 'Actualizaste tu banner';

  @override
  String get notificationsScreenTheyUpdatedBanner => ' actualizó su banner';

  @override
  String get notificationsScreenYouUpdatedBio => 'Actualizaste tu bio';

  @override
  String get notificationsScreenTheyUpdatedBio => ' actualizó su bio';

  @override
  String get notificationsScreenYouUpdatedProfile => 'Actualizaste tu perfil';

  @override
  String get notificationsScreenTheyUpdatedProfile => ' actualizó su perfil';

  @override
  String get notificationsScreenYouUpdatedTabs => 'Actualizaste tus pestañas';

  @override
  String get notificationsScreenTheyUpdatedTabs => ' actualizó sus pestañas';

  @override
  String get notificationsScreenVouchedForYou => ' hizo vouch por ti 🎉';

  @override
  String get notificationsScreenYouVouchedFor => 'Hiciste vouch por ';

  @override
  String get notificationsScreenVouchedFor => ' hizo vouch por ';

  @override
  String get notificationsScreenYoureNowA => 'Ahora eres ';

  @override
  String get notificationsScreenCitizen => 'ciudadano';

  @override
  String get notificationsScreenIsNowCitizen => ' ahora es ciudadano 🎉';

  @override
  String notificationsScreenMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meses',
      one: '1 mes',
    );
    return '$_temp0';
  }

  @override
  String notificationsScreenYouPaidRent(Object label) {
    return 'Pagaste tu dominio — $label';
  }

  @override
  String notificationsScreenTheyPaidRent(Object label) {
    return ' pagó su dominio — $label';
  }

  @override
  String get notificationsScreenYourAccountEvicted =>
      'Tu cuenta fue desalojada por falta de pago';

  @override
  String get notificationsScreenWasEvicted =>
      ' fue desalojada por falta de pago';

  @override
  String get notificationsScreenYouChangedName => 'Cambiaste tu nombre';

  @override
  String notificationsScreenYoureNowHandle(Object name) {
    return 'Ahora eres @$name';
  }

  @override
  String get notificationsScreenChangedTheirName => ' cambió su nombre';

  @override
  String notificationsScreenIsNowHandle(Object name) {
    return ' ahora es @$name';
  }

  @override
  String get notificationsScreenYouChangedDisplayName =>
      'Cambiaste tu nombre visible';

  @override
  String notificationsScreenYouChangedDisplayNameTo(Object name) {
    return 'Cambiaste tu nombre visible a $name';
  }

  @override
  String get notificationsScreenChangedDisplayName =>
      ' cambió su nombre visible';

  @override
  String notificationsScreenChangedDisplayNameTo(Object name) {
    return ' cambió su nombre visible a $name';
  }

  @override
  String get notificationsScreenRelTimeNow => 'ahora';

  @override
  String get profilePageVoteStarted =>
      'Votación iniciada — los miembros deben aprobar';

  @override
  String get profilePageBioPlaceholder => '¡Cuéntanos algo sobre ti!';

  @override
  String get profilePageSavingToChain => 'Guardando en la cadena...';

  @override
  String get profilePageRefreshingProfile => 'Actualizando perfil...';

  @override
  String get profilePageStartingVote => 'Iniciando votación...';

  @override
  String get profilePageProfileUpdated => 'Perfil actualizado';

  @override
  String get profilePageBlockchainError =>
      'Error de blockchain — inténtalo de nuevo';

  @override
  String get profilePageSavingLayout => 'Guardando diseño...';

  @override
  String get profilePageLayoutSaved => 'Diseño guardado';

  @override
  String get profilePageDeletingFromChain => 'Eliminando de la cadena...';

  @override
  String get profilePageRecordDeleted => 'Registro eliminado';

  @override
  String profilePageMemberCountWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'miembros',
      one: 'miembro',
    );
    return '$_temp0';
  }

  @override
  String get profilePageFoundedBy => 'fundada por ';

  @override
  String profilePageJoined(Object month, Object year) {
    return 'Se unió en $month de $year';
  }

  @override
  String get profilePageMonthJanuary => 'enero';

  @override
  String get profilePageMonthFebruary => 'febrero';

  @override
  String get profilePageMonthMarch => 'marzo';

  @override
  String get profilePageMonthApril => 'abril';

  @override
  String get profilePageMonthMay => 'mayo';

  @override
  String get profilePageMonthJune => 'junio';

  @override
  String get profilePageMonthJuly => 'julio';

  @override
  String get profilePageMonthAugust => 'agosto';

  @override
  String get profilePageMonthSeptember => 'septiembre';

  @override
  String get profilePageMonthOctober => 'octubre';

  @override
  String get profilePageMonthNovember => 'noviembre';

  @override
  String get profilePageMonthDecember => 'diciembre';

  @override
  String get profileQrPageScanHint => 'Escanea para abrir este perfil.';

  @override
  String get profileQrPageLinkCopied => 'Enlace del perfil copiado';

  @override
  String get profileQrPageCopyLink => 'COPIAR ENLACE DEL PERFIL';

  @override
  String get contactProfileSettingsManageContact => 'Administrar contacto';

  @override
  String get contactProfileSettingsContactOSAddress => 'Dirección ContactOS';

  @override
  String get contactProfileSettingsPrimaryInboxId => 'Inbox ID principal';

  @override
  String get contactProfileSettingsRegisteredInboxIds =>
      'Inbox IDs registrados';

  @override
  String get contactProfileSettingsDefaultLabel => 'Predeterminado';

  @override
  String contactProfileSettingsInboxIdLabel(Object label) {
    return 'Inbox ID de $label';
  }

  @override
  String contactProfileSettingsCopiedToClipboard(Object label) {
    return '$label copiado al portapapeles';
  }

  @override
  String get contactProfileSettingsInvalidAddress => 'Dirección inválida';

  @override
  String get contactProfileSettingsBlockContact => 'Bloquear contacto';

  @override
  String get contactProfileSettingsUnblockContact => 'Desbloquear contacto';

  @override
  String get contactProfileSettingsContactBlocked =>
      'Contacto bloqueado correctamente';

  @override
  String get contactProfileSettingsContactUnblocked =>
      'Contacto desbloqueado correctamente';

  @override
  String get groupAccountSettingsCopiedToClipboard => 'Copiado al portapapeles';

  @override
  String get groupAccountSettingsLeaveOrgTitle => 'Salir de la org';

  @override
  String groupAccountSettingsLeaveOrgConfirm(Object name) {
    return '¿Seguro que quieres salir de $name?\n\nPerderás acceso a las acciones de la org y los miembros tendrán que volver a agregarte para reingresar.';
  }

  @override
  String get groupAccountSettingsLeaveButton => 'Salir';

  @override
  String groupAccountSettingsLeftOrgMessage(Object name) {
    return 'Saliste de $name';
  }

  @override
  String get groupAccountSettingsLeaveOrgFailed => 'No se pudo salir de la org';

  @override
  String get groupAccountSettingsOrgIdentity => 'Identidad de la org';

  @override
  String get groupAccountSettingsNameLabel => 'NOMBRE';

  @override
  String get groupAccountSettingsPublicosAddressLabel => 'DIRECCIÓN PUBLICOS';

  @override
  String get groupAccountSettingsVotingQuorumLabel => 'QUÓRUM DE VOTACIÓN';

  @override
  String groupAccountSettingsVotingQuorumValue(int percent) {
    return '$percent% de participación para aprobar';
  }

  @override
  String get groupAccountSettingsNotAvailable => 'N/D';

  @override
  String get groupAccountSettingsDangerZone => 'Zona de peligro';

  @override
  String get groupAccountSettingsLeaveThisOrg => 'Salir de esta org';

  @override
  String get groupAccountSettingsLeaveThisOrgDescription =>
      'Se te quitará de la lista de miembros. Esta acción es inmediata y no requiere votación.';

  @override
  String get groupAccountSettingsLeaveOrgButton => 'SALIR DE LA ORG';

  @override
  String get groupAccountSettingsCannotLeaveLastMember =>
      'NO PUEDES SALIR SIENDO EL ÚLTIMO MIEMBRO';

  @override
  String get groupAccountSettingsDataSection => 'Datos';

  @override
  String get groupAccountSettingsRefreshOrgData => 'ACTUALIZAR DATOS DE LA ORG';

  @override
  String get groupChatSettingsNameEmpty =>
      'El nombre del grupo no puede estar vacío';

  @override
  String get groupChatSettingsUpdateSuccess =>
      'Información del grupo actualizada con éxito';

  @override
  String get groupChatSettingsMemberRemoved => 'Miembro eliminado con éxito';

  @override
  String get groupChatSettingsMembersAdded =>
      'Miembros agregados con éxito. Actualizando datos del grupo...';

  @override
  String get groupChatSettingsAdminRemoved =>
      'Rol de admin eliminado con éxito';

  @override
  String get groupChatSettingsAdminGranted => 'Rol de admin otorgado con éxito';

  @override
  String get groupChatSettingsSuperAdminRemoved =>
      'Rol de súper admin eliminado con éxito';

  @override
  String get groupChatSettingsSuperAdminGranted =>
      'Rol de súper admin otorgado con éxito';

  @override
  String get groupChatSettingsRoleSuperAdmin => 'SÚPER ADMIN';

  @override
  String get groupChatSettingsRoleAdmin => 'ADMIN';

  @override
  String get groupChatSettingsRoleMember => 'MIEMBRO';

  @override
  String get groupChatSettingsRemoveAdmin => 'Quitar admin';

  @override
  String get groupChatSettingsMakeAdmin => 'Hacer admin';

  @override
  String get groupChatSettingsRemoveSuperAdmin => 'Quitar súper admin';

  @override
  String get groupChatSettingsMakeSuperAdmin => 'Hacer súper admin';

  @override
  String get groupChatSettingsRemoveMember => 'Quitar miembro';

  @override
  String get groupChatSettingsNotGroup =>
      'Esta conversación no es un chat grupal';

  @override
  String get groupChatSettingsDefaultGroupName => 'Grupo';

  @override
  String get groupChatSettingsSectionDetails => 'Detalles del grupo';

  @override
  String get groupChatSettingsFieldName => 'Nombre del grupo';

  @override
  String get groupChatSettingsFieldDescription => 'Descripción';

  @override
  String get groupChatSettingsFieldImageUrl => 'URL de imagen';

  @override
  String get groupChatSettingsSaving => 'GUARDANDO…';

  @override
  String get groupChatSettingsSaveChanges => 'GUARDAR CAMBIOS';

  @override
  String get groupChatSettingsSectionMembers => 'Miembros';

  @override
  String get groupChatSettingsSearchHint => 'Buscar miembros…';

  @override
  String get groupChatSettingsFilterAll => 'Todos';

  @override
  String get groupChatSettingsFilterSuperAdmin => 'Súper Admin';

  @override
  String get groupChatSettingsFilterAdmin => 'Admin';

  @override
  String get groupChatSettingsFilterMember => 'Miembro';

  @override
  String get groupChatSettingsNoMembers => 'No se encontraron miembros';

  @override
  String groupChatSettingsNoMatch(Object query) {
    return 'Ningún miembro coincide con \"$query\"';
  }

  @override
  String groupChatSettingsChipLabel(Object label, Object count) {
    return '$label ($count)';
  }

  @override
  String get groupChatSettingsAdd => 'AGREGAR';

  @override
  String get publicosAccountSettingsAccountIdentity => 'Identidad de la cuenta';

  @override
  String get publicosAccountSettingsUsernameLabel => 'USUARIO';

  @override
  String get publicosAccountSettingsAccountAddressLabel =>
      'DIRECCIÓN DE CUENTA';

  @override
  String get publicosAccountSettingsRegisteredInboxIds =>
      'Inbox IDs registrados';

  @override
  String get publicosAccountSettingsRegisteredInboxIdsHint =>
      'Inbox IDs de XMTP registrados on-chain en esta cuenta';

  @override
  String get publicosAccountSettingsNoInboxIds =>
      'No hay inbox IDs registrados';

  @override
  String get publicosAccountSettingsUnlabeled => 'Sin etiqueta';

  @override
  String get publicosAccountSettingsInboxIdLabel => 'Inbox ID';

  @override
  String get publicosAccountSettingsSessionWallets => 'Billeteras de sesión';

  @override
  String get publicosAccountSettingsSessionWalletsHint =>
      'Direcciones de billetera autorizadas para controlar esta cuenta';

  @override
  String get publicosAccountSettingsNoSessions => 'No se encontraron sesiones';

  @override
  String get publicosAccountSettingsPrimaryBadge => 'PRINCIPAL';

  @override
  String publicosAccountSettingsSessionNumber(Object number) {
    return 'Sesión $number';
  }

  @override
  String get publicosAccountSettingsSessionAddressLabel =>
      'Dirección de sesión';

  @override
  String get publicosAccountSettingsConversation => 'Conversación';

  @override
  String get publicosAccountSettingsConversationHint =>
      'Tu canal de mensajes directos con este contacto';

  @override
  String get publicosAccountSettingsPrimaryInboxIdLabel => 'INBOX ID PRINCIPAL';

  @override
  String get publicosAccountSettingsNotAvailable => 'N/D';

  @override
  String get publicosAccountSettingsActions => 'Acciones';

  @override
  String get publicosAccountSettingsRefreshing => 'ACTUALIZANDO…';

  @override
  String get publicosAccountSettingsRefreshContactDetails =>
      'ACTUALIZAR DATOS DEL CONTACTO';

  @override
  String get publicosAccountSettingsContactRefreshed =>
      'Datos del contacto actualizados';

  @override
  String publicosAccountSettingsCopiedToClipboard(Object label) {
    return '$label copiado al portapapeles';
  }

  @override
  String xmtpContactSettingsCopiedToClipboard(Object label) {
    return '$label copiado al portapapeles';
  }

  @override
  String get xmtpContactSettingsInvalidAddress => 'Dirección inválida';

  @override
  String get xmtpContactSettingsDisplayNameUpdated => 'Nombre actualizado';

  @override
  String get xmtpContactSettingsColorUpdated =>
      'Color del contacto actualizado';

  @override
  String get xmtpContactSettingsDetailsUpdated =>
      'Detalles del contacto actualizados';

  @override
  String get xmtpContactSettingsUnsupportedContact =>
      'Este tipo de contacto no es compatible con esta pantalla de ajustes';

  @override
  String get xmtpContactSettingsContactInformation =>
      'Información del contacto';

  @override
  String get xmtpContactSettingsPrimaryInboxId => 'Inbox ID principal';

  @override
  String get xmtpContactSettingsClientsSection => 'Clientes XMTP';

  @override
  String get xmtpContactSettingsAddressLabel => 'Dirección';

  @override
  String get xmtpContactSettingsDisplayName => 'Nombre';

  @override
  String get xmtpContactSettingsEnterDisplayName => 'Escribe el nombre';

  @override
  String get xmtpContactSettingsChatColor => 'Color del chat';

  @override
  String get xmtpContactSettingsSaveChanges => 'GUARDAR CAMBIOS';

  @override
  String get xmtpContactSettingsUpdating => 'ACTUALIZANDO…';

  @override
  String get xmtpContactSettingsUpdateContactDetails => 'ACTUALIZAR DETALLES';

  @override
  String get sspScreenNoActiveAccount => 'Sin cuenta activa';

  @override
  String get sspScreenNoActiveSession => 'Sin sesión activa';

  @override
  String get sspScreenEndpointNoUrl => 'El endpoint no tiene URL';

  @override
  String sspScreenConnectingTo(Object label) {
    return 'Conectando a $label…';
  }

  @override
  String sspScreenConnectedTo(Object label) {
    return 'Conectado a $label';
  }

  @override
  String sspScreenRemoved(Object label) {
    return 'Se eliminó $label';
  }

  @override
  String sspScreenCouldNotRemove(Object label) {
    return 'No se pudo eliminar $label';
  }

  @override
  String get sspScreenConnection => 'Conexión';

  @override
  String get sspScreenEndpoint => 'Endpoint';

  @override
  String get sspScreenManage => 'GESTIONAR';

  @override
  String get sspScreenProviders => 'Proveedores';

  @override
  String get sspScreenRegisterSsp => 'REGISTRAR SSP';

  @override
  String get sspScreenAddCustom => 'AGREGAR';

  @override
  String get sspScreenBadgeMine => 'MÍO';

  @override
  String get sspScreenBadgeSubscribed => 'SUSCRITO';

  @override
  String get sspScreenEmptyCitizen =>
      'Aún no hay servidor conectado. Elige un SSP desde Servicios, registra el tuyo o agrega un servidor personalizado abajo.';

  @override
  String get sspScreenEmptyPrivate =>
      'Aún no hay servidor conectado. Suscríbete a un SSP desde Servicios, registra el tuyo o agrega un servidor personalizado abajo.';

  @override
  String get sspScreenStatusUnreachableLabel => 'INALCANZABLE';

  @override
  String get sspScreenStatusUnreachableDesc =>
      'Ningún servidor de feeds responde. Los feeds sociales, las publicaciones y el contenido multimedia no están disponibles.';

  @override
  String get sspScreenStatusSspLabel => 'SSP CONECTADO';

  @override
  String get sspScreenStatusSspDesc =>
      'Conectado a través de tu Social Service Provider suscrito.';

  @override
  String get sspScreenStatusCustomLabel => 'SERVIDOR PERSONALIZADO';

  @override
  String get sspScreenStatusCustomDesc =>
      'Conectado a través de un servidor de feeds personalizado que configuraste.';

  @override
  String get sspScreenStatusOverrideLabel => 'ANULACIÓN DE LA APP';

  @override
  String get sspScreenStatusOverrideDesc =>
      'Conectado a través de un endpoint de anulación definido por esta app.';

  @override
  String get sspScreenStatusPublicLabel => 'RESPALDO PÚBLICO';

  @override
  String get sspScreenStatusPublicDesc =>
      'Conectado al servidor de feeds público predeterminado. Suscríbete a un SSP o agrega un servidor personalizado para mayor fiabilidad.';

  @override
  String get sspScreenLegendNoServer => 'Servidor de feeds no disponible';

  @override
  String get sspScreenLegendPublicFallback => 'Servidor de respaldo público';

  @override
  String get sspScreenLegendSspOrCustom => 'SSP o servidor personalizado';

  @override
  String get sspScreenLabelUrl => 'URL';

  @override
  String get sspScreenLabelSubs => 'SUBS';

  @override
  String get sspScreenRunBy => 'OPERADO POR';

  @override
  String sspScreenSubscriberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count suscriptores',
      one: '1 suscriptor',
    );
    return '$_temp0';
  }

  @override
  String get sspScreenConnect => 'CONECTAR';

  @override
  String get sspScreenConnected => 'CONECTADO';

  @override
  String get sspScreenDelete => 'ELIMINAR';

  @override
  String get sspScreenCustomServerSubtitle => 'servidor personalizado';

  @override
  String get sspScreenRegisterTitle => 'Nuevo SSP en la cadena';

  @override
  String get sspScreenRegisterSubtitle =>
      'Regístrate como Social Service Provider. Solo ciudadanos.';

  @override
  String get sspScreenFieldSlug => 'Slug';

  @override
  String get sspScreenSlugHint => 'ej. mi-servicio-ssp';

  @override
  String get sspScreenSlugHelper =>
      '3-32 caracteres, minúsculas, números, guiones y guiones bajos';

  @override
  String get sspScreenSlugRequired => 'El slug es obligatorio';

  @override
  String get sspScreenSlugInvalid =>
      '3-32 caracteres: minúsculas, números, - _';

  @override
  String get sspScreenFieldTitle => 'Título';

  @override
  String get sspScreenTitleHint => 'ej. Mi Servicio SSP';

  @override
  String get sspScreenTitleRequired => 'El título es obligatorio';

  @override
  String get sspScreenFieldApiUrl => 'URL de API';

  @override
  String get sspScreenApiUrlRequired => 'La URL de API es obligatoria';

  @override
  String get sspScreenFieldRegion => 'Región';

  @override
  String get sspScreenRegionHint => 'ej. us-east, eu-west';

  @override
  String get sspScreenFieldWebsite => 'Sitio web';

  @override
  String get sspScreenRegistering => 'REGISTRANDO…';

  @override
  String get sspScreenRegister => 'REGISTRAR';

  @override
  String get sspScreenAddCustomTitle => 'Apunta a tu propio servidor';

  @override
  String get sspScreenAddCustomSubtitle =>
      'La accesibilidad se verifica después de conectar.';

  @override
  String get sspScreenFieldName => 'Nombre';

  @override
  String get sspScreenNameHint => 'ej. Mi Servidor de Feeds';

  @override
  String get sspScreenFieldServerUrl => 'URL del servidor';

  @override
  String get sspScreenUrlRequired => 'La URL es obligatoria';

  @override
  String get sspScreenTesting => 'PROBANDO…';

  @override
  String get sspScreenAdd => 'AGREGAR';

  @override
  String get treasuryPageTitle => 'Servicios';

  @override
  String treasuryPageActionFailedToSend(Object label) {
    return '$label falló al enviar';
  }

  @override
  String treasuryPageActionConfirmed(Object label) {
    return '$label confirmado';
  }

  @override
  String treasuryPageActionFailedOnChain(Object label) {
    return '$label falló en la cadena';
  }

  @override
  String get treasuryPageClaimedSuccess => 'Reclamado';

  @override
  String treasuryPageSubscribedTo(Object provider) {
    return 'Suscrito a $provider';
  }

  @override
  String treasuryPageProviderSwitched(Object provider) {
    return '$provider cambiado';
  }

  @override
  String treasuryPageProviderExtended(Object provider) {
    return 'Suscripción $provider extendida';
  }

  @override
  String get treasuryPageProviderOnboardingSoon =>
      'Trabajando en esto — el alta de proveedores llega pronto';

  @override
  String get treasuryPagePeriodFallback => 'periodo';

  @override
  String treasuryPagePeriodDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
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
  String get treasuryPageRelativeNow => 'ahora';

  @override
  String treasuryPageRelativeSeconds(Object n) {
    return 'en $n s';
  }

  @override
  String treasuryPageRelativeMinutes(Object n) {
    return 'en $n min';
  }

  @override
  String treasuryPageRelativeHours(Object n) {
    return 'en $n h';
  }

  @override
  String treasuryPageRelativeDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count días',
      one: 'en 1 día',
    );
    return '$_temp0';
  }

  @override
  String get treasuryPageRoleCitizen => 'CIUDADANO';

  @override
  String get treasuryPageRolePrivate => 'PRIVADA';

  @override
  String get treasuryPageRoleCitizenMeaning =>
      'Ganas las Utilidades, votas en la gobernanza, creas orgs. Un nombre de 5+ caracteres es gratis para siempre.';

  @override
  String get treasuryPageRolePrivateMeaning =>
      'Pagas una tarifa de dominio recurrente para conservar tu nombre y mantener el acceso de escritura a la cadena. No recibes Utilidades ni votas.';

  @override
  String get treasuryPageYourRole => 'Tu rol';

  @override
  String treasuryPageCitizenSummary(String privateIcon) {
    return 'Tienes un Dominio PublicOS verificado socialmente. Eres dueño de PublicOS y recibes una parte de su economía, que puedes reclamar cuando quieras. Tu BSP y tu SSP son un servicio público, gratis para ti, mientras las cuentas privadas $privateIcon pagan los suyos. Tú eliges tus proveedores, así que revisa seguido tus suscripciones.';
  }

  @override
  String get treasuryPagePrivateSummary =>
      'Tu Dominio PublicOS es privado, sin verificación. Un BSP es cómo tu app llega a la cadena: lee por ti y envía tus transacciones. Puedes usar un BSP público (con límite de uso) o suscribirte a uno. El SSP (alojamiento de feeds y multimedia) es opcional: suscríbete a uno aquí, usa cualquier servidor fuera de PublicOS o corre el tuyo.';

  @override
  String get treasuryPageWhatYouCanClaim => 'Lo que puedes reclamar';

  @override
  String get treasuryPageClaimExplainer =>
      'Un solo reclamo trae todo lo que la economía te debe en una sola transacción: tus Utilidades y cualquier ganancia de proveedor. Las multas pendientes se retienen automáticamente.';

  @override
  String get treasuryPageClaimable => 'Reclamable';

  @override
  String get treasuryPageStipend => 'Utilidades';

  @override
  String get treasuryPageEarnings => 'Ganancias';

  @override
  String get treasuryPageGarnished => 'Retenido por penalizaciones';

  @override
  String get treasuryPageClaiming => 'RECLAMANDO...';

  @override
  String treasuryPageClaimAmount(Object amount) {
    return 'RECLAMAR $amount OX';
  }

  @override
  String get treasuryPageNothingToClaim => 'NADA QUE RECLAMAR';

  @override
  String treasuryPageRunProviders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Operas $count proveedores — sus ganancias son parte de este reclamo.',
      one: 'Operas 1 proveedor — sus ganancias son parte de este reclamo.',
    );
    return '$_temp0';
  }

  @override
  String get treasuryPageBecomeProvider => 'Conviértete en proveedor';

  @override
  String get treasuryPageBecomeProviderBlurb =>
      'Los proveedores hacen funcionar la red y cobran por ello. Opera un BSP para enrutar cuentas privadas, o un SSP para alojar sus datos sociales — cada suscriptor suma a tu reclamo.';

  @override
  String get treasuryPageBecomeProviderButton => 'CONVIÉRTETE EN PROVEEDOR';

  @override
  String get treasuryPageBspBlurb =>
      'Una suscripción independiente que te enruta a la cadena. Se paga segundo a segundo, solo mientras te sirve.';

  @override
  String get treasuryPageSspBlurb =>
      'Una suscripción independiente que aloja tus datos sociales. Se paga segundo a segundo, solo mientras te sirve.';

  @override
  String get treasuryPageSubNone => 'NINGUNA';

  @override
  String get treasuryPageSubExpired => 'VENCIDA';

  @override
  String get treasuryPageSubActive => 'ACTIVA';

  @override
  String get treasuryPageSubSwitchOpen => 'CAMBIO ABIERTO';

  @override
  String get treasuryPageSubExtendOpen => 'EXTENSIÓN ABIERTA';

  @override
  String get treasuryPageProvider => 'Proveedor';

  @override
  String get treasuryPagePaidUntil => 'Pagado hasta';

  @override
  String get treasuryPageCycleEnds => 'Fin del ciclo';

  @override
  String treasuryPageLastProvider(Object provider) {
    return 'Último $provider';
  }

  @override
  String get treasuryPageLapsed => 'Vencida';

  @override
  String treasuryPageSubNoneCitizen(Object provider) {
    return 'Elige un $provider para alojar tu servicio. Los ciudadanos no pagan — la red acuña la tarifa del $provider por ti.';
  }

  @override
  String treasuryPageSubNonePrivate(Object provider) {
    return 'Suscríbete a un $provider. La tarifa corre segundo a segundo y se toma de tu saldo de servicios — solo cuando el proveedor tiene suficientes suscriptores para cobrar.';
  }

  @override
  String treasuryPageSubActivePrivateBody(Object provider) {
    return 'Activa. La tarifa se toma de tu saldo de servicios segundo a segundo. Cambia cuando quieras — al proveedor anterior se le paga hasta el segundo.';
  }

  @override
  String treasuryPageSubCitizenLockedBody(
      Object provider, Object fromWhen, Object renewWhen) {
    return 'Activa. Puedes cambiar de $provider desde $fromWhen (sin perder tu ciclo); la red renueva automáticamente $renewWhen.';
  }

  @override
  String treasuryPageSubCitizenSwitchOpenBody(
      Object provider, Object closesWhen) {
    return 'Puedes cambiar de $provider ahora — tu fin de ciclo se mantiene, nada extra que pagar. El cambio cierra $closesWhen, luego la red renueva automáticamente.';
  }

  @override
  String get treasuryPageSubExpiredBody =>
      'Suscripción vencida. Suscríbete de nuevo (el mismo proveedor u otro) para restaurar el servicio.';

  @override
  String treasuryPageSubCitizenExtendOpenBody(Object provider) {
    return 'Extiende ahora para mantener el servicio $provider — la red acuña la tarifa por ti.';
  }

  @override
  String get treasuryPageOpening => 'ABRIENDO…';

  @override
  String treasuryPagePickProvider(Object provider) {
    return 'ELIGE UN $provider';
  }

  @override
  String get treasuryPageSubscribeAgain => 'SUSCRÍBETE DE NUEVO';

  @override
  String get treasuryPagePaying => 'PAGANDO…';

  @override
  String get treasuryPagePayInAdvance => 'PAGAR POR ADELANTADO';

  @override
  String treasuryPageSwitchOpens(Object when) {
    return 'EL CAMBIO ABRE $when';
  }

  @override
  String get treasuryPageExtending => 'EXTENDIENDO…';

  @override
  String treasuryPageExtendProvider(Object provider) {
    return 'EXTENDER $provider';
  }

  @override
  String treasuryPageSwitchProvider(Object provider) {
    return 'CAMBIAR $provider';
  }

  @override
  String get treasuryPageParameters => 'Parámetros';

  @override
  String get treasuryPageDomainPrice => 'Precio del dominio';

  @override
  String treasuryPageDomainTier3(Object price) {
    return '3 caracteres $price';
  }

  @override
  String treasuryPageDomainPriceExplain(
      Object tier4, Object tier5, Object tier6plus, Object minChars) {
    return '4 caracteres $tier4 · 5 caracteres $tier5 · 6+ $tier6plus. Los ciudadanos son gratis con $minChars+ caracteres. El 98% de cada pago se quema, el 2% financia las Utilidades.';
  }

  @override
  String get treasuryPageLoading => 'Cargando…';

  @override
  String get treasuryPageBspFee => 'Tarifa BSP';

  @override
  String get treasuryPageBspFeeExplain =>
      'Pagada por una cuenta privada a su BSP cada periodo. Independiente del dominio.';

  @override
  String get treasuryPageSspFee => 'Tarifa SSP';

  @override
  String get treasuryPageSspFeeExplain =>
      'Pagada por una cuenta privada a su SSP cada periodo. Independiente del dominio.';

  @override
  String get treasuryPageMultiMonthDiscount => 'Descuento multi-mes';

  @override
  String treasuryPageDiscountValue(Object percent) {
    return '$percent% por mes adicional';
  }

  @override
  String get treasuryPageDiscountExplain =>
      'Se aplica a la tarifa del dominio cuando pagas varios periodos por adelantado.';

  @override
  String get treasuryPageTotalSupply => 'Suministro total';

  @override
  String get treasuryPageTotalSupplyExplain =>
      'Se reduce con cada quema de dominio, crece cuando la red acuña tarifas de proveedor y bonos de bienvenida.';

  @override
  String get treasuryPageTreasuryBalance => 'Saldo de la tesorería';

  @override
  String get treasuryPageTreasuryBalanceExplain =>
      'El presupuesto operativo de la DAO. Financia subvenciones y gastos aprobados por la gobernanza.';

  @override
  String get treasuryPageParamsGovernance =>
      'Los parámetros los establece la gobernanza de la red';

  @override
  String get treasuryPageWhenToCheckBack => 'Cuándo volver a revisar';

  @override
  String get treasuryPageCadenceClaimTitle => 'Reclamo';

  @override
  String get treasuryPageCadenceClaimBody =>
      'Las Utilidades, las ganancias de proveedor y el bono de bienvenida se acumulan continuamente. Revisa cada mes y reclama cuando el monto valga la tarifa de la tx.';

  @override
  String get treasuryPageCadenceDomainTitle => 'Dominio';

  @override
  String get treasuryPageCadenceDomainBody =>
      'Tu fecha de vencimiento está en esta página. Paga varios periodos por adelantado para reducir revisiones y ganar el descuento.';

  @override
  String get treasuryPageCadenceServicesBody =>
      'Cada servicio vence en su propio reloj, independiente de tu dominio. Renueva antes de la fecha de vencimiento.';

  @override
  String get treasuryPageNodesBody =>
      'El directorio público de los nodos que operan la red: quién opera cada uno.';

  @override
  String get treasuryPageGrants => 'Subvenciones';

  @override
  String get treasuryPageGrantsTitle =>
      'Organizaciones y proyectos financiados por la DAO';

  @override
  String get treasuryPageGrantsBody =>
      'Asignaciones aprobadas por la gobernanza para proyectos de bienes públicos. Los tokens otorgados llegan a tu reclamo.';

  @override
  String get treasuryPageGrantsVotingNote =>
      'Las propuestas de subvención pasan por el proceso de votación de la gobernanza';

  @override
  String get trustTreeScreenAppBarTitle => 'GRAFO SOCIAL';

  @override
  String get trustTreeScreenAccountNotFound => 'Cuenta no encontrada';

  @override
  String get trustTreeScreenVouchNotConfirmed =>
      'Vouch no confirmado. Intenta de nuevo.';

  @override
  String get trustTreeScreenUnknown => 'Desconocido';

  @override
  String get trustTreeScreenLoading => 'Cargando datos de confianza…';

  @override
  String get trustTreeScreenSearchHint => 'Busca por nombre o direccion';

  @override
  String get trustTreeScreenCopyAddress => 'Copiar direccion';

  @override
  String get trustTreeScreenAddressCopied => 'Direccion copiada';

  @override
  String trustTreeScreenCreatedBy(Object creator) {
    return 'POR $creator';
  }

  @override
  String get trustTreeScreenVouched => 'HICISTE VOUCH';

  @override
  String get trustTreeScreenNoVouchers => 'SIN VOUCHERS';

  @override
  String get trustTreeScreenNoVouchees => 'SIN VOUCHEES';

  @override
  String trustTreeScreenMoreCount(Object count) {
    return '$count mas';
  }

  @override
  String get trustTreeScreenMyTree => 'MI ARBOL';

  @override
  String get trustTreeScreenVouching => 'HACIENDO VOUCH…';

  @override
  String trustTreeScreenVouchFor(Object name) {
    return 'VOUCH POR $name';
  }

  @override
  String get mediaOverlayGalleryPermissionDenied =>
      'Permiso de galería denegado';

  @override
  String get mediaOverlayVideoSaved => 'Video guardado en la galería';

  @override
  String get mediaOverlayImageSaved => 'Imagen guardada en la galería';

  @override
  String get mediaOverlaySaveFailed => 'No se pudo guardar';

  @override
  String get mediaOverlayBack => 'Atrás';

  @override
  String get mediaPickerOnlyImagesVideos =>
      'Aquí solo se pueden adjuntar imágenes y videos';

  @override
  String get messageInputVideoNeedsServer =>
      'Enviar un video requiere un servidor de feeds';

  @override
  String get messageInputSendOx => 'Enviar OX';

  @override
  String get messageInputRecipientNoAddress =>
      'Este contacto aún no puede recibir OX';

  @override
  String get messageInputNoSendableMembers =>
      'Nadie en este grupo puede recibir OX aún';

  @override
  String get messageInputAttachRequest => 'Solicitar';

  @override
  String get requestPaymentTitle => 'Solicitar pago';

  @override
  String get requestPaymentPayTo => 'Recibir en';

  @override
  String get requestPaymentAmount => 'Cantidad';

  @override
  String get requestPaymentSend => 'Enviar solicitud';

  @override
  String get requestPaymentSending => 'Enviando solicitud…';

  @override
  String get requestPaymentChange => 'Cambiar';

  @override
  String get requestPaymentDone => 'Listo';

  @override
  String get requestPaymentSent => 'Solicitud de pago enviada';

  @override
  String get requestPaymentCustomAddress => 'Pega una dirección ETH';

  @override
  String get requestPaymentCustomLabel => 'Dirección personalizada';

  @override
  String get requestPaymentInvalidAddress => 'Dirección inválida';

  @override
  String documentPickerTooLarge(Object size, Object max) {
    return 'Documento demasiado grande ($size MB > $max MB)';
  }

  @override
  String get documentReadFailed => 'No se pudo leer el archivo seleccionado';

  @override
  String get documentTooLargeNoServer =>
      'Este documento es demasiado grande para enviarse sin un servidor de feeds';

  @override
  String get documentOpenFailed =>
      'No hay ninguna app disponible para abrir este archivo';

  @override
  String get documentSave => 'Guardar archivo';

  @override
  String get documentSaved => 'Archivo guardado';

  @override
  String get documentSaveFailed => 'No se pudo guardar el archivo';

  @override
  String get channelHeaderVerifiedReaders => 'Lectores verificados';

  @override
  String get channelHeaderTotalViews => 'Vistas totales';

  @override
  String get channelHeaderOwner => 'Dueño';

  @override
  String get channelHeaderBy => 'por';

  @override
  String get channelHeaderHostedBy => 'alojado por';

  @override
  String channelHeaderVerifiedReadersWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lectores verificados',
      one: 'lector verificado',
    );
    return '$_temp0';
  }

  @override
  String channelHeaderViewsWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vistas',
      one: 'vista',
    );
    return '$_temp0';
  }

  @override
  String get channelHeaderWriters => 'Autores';

  @override
  String channelHeaderWritersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autores',
      one: '1 autor',
    );
    return '$_temp0';
  }

  @override
  String get channelHeaderStatsTitle => 'Actividad de lectores';

  @override
  String get channelHeaderReadersThisWeek => 'Lectores verificados esta semana';

  @override
  String get channelHeaderTodayPartial => 'Hoy hasta ahora';

  @override
  String get channelHeaderTotalViewsAllTime => 'Vistas totales (histórico)';

  @override
  String get channelHeaderByTypeCitizens => 'Ciudadanos';

  @override
  String get channelHeaderByTypePrivate => 'Cuentas privadas';

  @override
  String get channelHeaderByTypeSigned => 'Firmadas, sin cuenta';

  @override
  String get channelHeaderByTypeAnonymous => 'Anónimas';

  @override
  String get channelHeaderToday => 'Hoy';

  @override
  String get channelHeaderVerifiedNote =>
      'Los lectores verificados son cuentas ciudadanas distintas cuyas lecturas llevan una firma válida. Cada una cuenta una vez por semana.';

  @override
  String get channelHeaderClose => 'Cerrar';

  @override
  String get managePlansTitle => 'Planes';

  @override
  String get managePlansSubtitle =>
      'Lo que los lectores pagan para leer este canal.';

  @override
  String get managePlansNone =>
      'Este canal es gratuito. Agrega un plan para cobrar por él.';

  @override
  String get managePlansAdd => 'Agregar plan';

  @override
  String managePlansPerPeriod(Object days) {
    return 'cada $days días';
  }

  @override
  String get managePlansOutdated => 'Contrato desactualizado';

  @override
  String get managePlansOutdatedNote =>
      'Este servidor cambió de contrato. Quienes ya pagaron conservan su acceso; las nuevas suscripciones deberían usar el actual.';

  @override
  String get managePlansMoveToCurrent => 'Mover al contrato actual';

  @override
  String get managePlansRetired => 'No está a la venta';

  @override
  String get managePlansRetiredNote =>
      'Se conserva para que los suscriptores actuales sigan leyendo. En su lugar se venden los planes más nuevos de esta cadena.';

  @override
  String get managePlansRemove => 'Quitar';

  @override
  String get managePlansRemoveConfirm =>
      '¿Quitar este plan del canal? Quien esté suscrito por esta vía perderá el acceso.';

  @override
  String get managePlansChain => 'Cadena';

  @override
  String get managePlansPrice => 'Precio';

  @override
  String get managePlansPeriodDays => 'Días por periodo';

  @override
  String get managePlansPayout => 'Se paga a';

  @override
  String get managePlansPayoutHint =>
      'Tu cuenta funciona: se resuelve a tu Safe.';

  @override
  String get managePlansPayoutUnreachable =>
      'Esta dirección no puede recibir pagos en esta cadena.';

  @override
  String get managePlansCreate => 'Crear plan';

  @override
  String get managePlansCreating => 'Registrando en la cadena…';

  @override
  String get managePlansAttaching => 'Vinculando al canal…';

  @override
  String get managePlansNoChains => 'Este servidor no ofrece feeds de pago.';

  @override
  String get managePlansUseExisting => 'Usar un plan que ya tengo';

  @override
  String get managePlansEnterManually => 'Ingresar un plan manualmente';

  @override
  String get managePlansPlanId => 'ID del plan';

  @override
  String get managePlansContractAddress => 'Dirección del contrato';

  @override
  String get managePlansLookup => 'Buscar';

  @override
  String get managePlansNotFound =>
      'No hay ningún plan con ese ID en ese contrato.';

  @override
  String get managePlansForeignOwner =>
      'Este plan pertenece a otra dirección. Está bien si es un plan compartido: los pagos van a su destinatario, no al tuyo.';

  @override
  String get managePlansPriceRequired => 'Ingresa un precio mayor a cero.';

  @override
  String get managePlansSaved => 'Planes actualizados';

  @override
  String get managePlansManage => 'Administrar planes';

  @override
  String get managePlansPaidBadge => 'De pago';

  @override
  String get managePlansFreeBadge => 'Gratis';

  @override
  String get createChannelPageSectionMonetization => 'Monetización';

  @override
  String get gateTierAnyoneLabel => 'Cualquiera';

  @override
  String get gateTierAnyoneSubtitle =>
      'Sin iniciar sesion. Funciona en cualquier lector de feeds.';

  @override
  String get gateTierSignedLabel => 'Con sesion iniciada';

  @override
  String get gateTierSignedSubtitle =>
      'Cualquiera con una billetera, tenga cuenta PublicOS o no.';

  @override
  String get gateTierAccountLabel => 'Cuentas PublicOS';

  @override
  String get gateTierAccountSubtitle =>
      'Solo quienes tienen cuenta PublicOS. Las billeteras sueltas quedan fuera.';

  @override
  String get gateTierStandingLabel => 'Cuentas al corriente';

  @override
  String get gateTierStandingSubtitle =>
      'Ciudadanos, y quien tenga su dominio pagado.';

  @override
  String get gateTierCitizenLabel => 'Ciudadanos';

  @override
  String get gateTierCitizenSubtitle => 'Solo ciudadanos avalados.';

  @override
  String get createChannelPageSectionAudience => 'QUIEN PUEDE VERLO';

  @override
  String get createChannelPageAudienceNote =>
      'Lo minimo que alguien necesita para abrir este canal. Cada opcion incluye las de arriba.';

  @override
  String get createChannelPageSectionApprovedReaders => 'LECTORES APROBADOS';

  @override
  String get createChannelPageUseFriendsLabel => 'Mis amigos';

  @override
  String get createChannelPageUseFriendsSubtitle =>
      'La lista que armas una vez y reutilizas en todos tus canales.';

  @override
  String get createChannelPageUseChannelListLabel => 'La lista de este canal';

  @override
  String get createChannelPageUseChannelListSubtitle =>
      'Personas que apruebas solo para este canal.';

  @override
  String get createChannelPageAudienceOpenNote =>
      'No hay ninguna lista activa, asi que puede leerlo cualquiera que cumpla lo de arriba.';

  @override
  String get createChannelPageAudienceRestrictedNote =>
      'Hay una lista activa, asi que este canal es privado: deja de aparecer en los listados y solo pueden leerlo las personas de una lista activa. Ademas tienen que cumplir lo de arriba.';

  @override
  String get createChannelPageSectionComments => 'QUIEN PUEDE COMENTAR';

  @override
  String get createChannelPageInteractionNote =>
      'Comentar y reaccionar tambien requieren poder leer el canal.';

  @override
  String get createChannelPageSectionReactions => 'QUIEN PUEDE REACCIONAR';

  @override
  String get createChannelPageSectionWhoCanPost => 'QUIEN PUEDE PUBLICAR';

  @override
  String get createChannelPagePostersMustBeLabel =>
      'Ademas, quien publique debe ser';

  @override
  String get chsAdd => 'Agregar';

  @override
  String get chsRemove => 'Quitar';

  @override
  String get chsTitleLabel => 'AJUSTES';

  @override
  String get chsDrawerRead => 'Quién puede leerlo';

  @override
  String get chsDrawerPost => 'Quién puede publicar';

  @override
  String get chsDrawerTalk => 'Quién puede comentar y reaccionar';

  @override
  String get chsDrawerBlocked => 'Bloqueados';

  @override
  String get chsDrawerVisibility => 'Visibilidad';

  @override
  String get chsDrawerMonetization => 'Monetización';

  @override
  String get chsReadNote =>
      'La puerta exterior. Publicar, comentar y reaccionar la requieren primero.';

  @override
  String get chsPostNote => 'Escribir una publicación completa en el canal.';

  @override
  String get chsTalkNote =>
      'Comentarios, reacciones y votos. Todos aquí también deben poder leer el canal.';

  @override
  String get chsBlockedNote =>
      'Una persona bloqueada no puede leer, publicar, comentar ni reaccionar aquí. Un bloqueo gana sobre todo lo demás, incluso estar en una de tus listas — y a diferencia de una aprobación, nunca expira.';

  @override
  String get chsVisibilityNote =>
      'Cuánto del canal se sirve. Nada se borra — las publicaciones viejas siguen en el servidor, solo dejan de entregarse en el feed.';

  @override
  String get chsMonetizationNote =>
      'Cobrar es un eje aparte: quien lee debe pasar la puerta de lectura y haber pagado. El dinero nunca compra el paso sobre un bloqueo ni sobre una lista.';

  @override
  String get chsSubAudience => 'Audiencia';

  @override
  String get chsSubFilter => 'Filtrar la audiencia por';

  @override
  String get chsSubRequests => 'Solicitudes';

  @override
  String get chsSubReactions => 'Reacciones';

  @override
  String get chsAudAnyone => 'Cualquiera';

  @override
  String get chsAudAnyoneSub => 'Sin lista. El canal es público.';

  @override
  String get chsAudFriends => 'Mis amigos';

  @override
  String get chsAudFriendsSub =>
      'Una lista, reutilizada por todos tus canales.';

  @override
  String get chsAudPrivate => 'Privado';

  @override
  String get chsAudPrivateSub =>
      'Una lista solo para este canal. La gente puede pedir entrar.';

  @override
  String get chsFilterNone => 'Sin filtro';

  @override
  String get chsFilterNoneSub => 'Cualquiera, incluso sin firmar.';

  @override
  String get chsFilterSigned => 'Lectores firmados y wallets';

  @override
  String get chsFilterSignedSub =>
      'Incluye wallets que agregaste a mano, sin cuenta PublicOS.';

  @override
  String get chsFilterStanding => 'Todas las cuentas PublicOS';

  @override
  String get chsFilterStandingSub =>
      'Ciudadanos, y privados con dominio activo.';

  @override
  String get chsFilterStandingDefaultSub => 'Predeterminado.';

  @override
  String get chsFilterCitizen => 'Ciudadanos';

  @override
  String get chsFilterCitizenSub => 'Solo ciudadanos avalados.';

  @override
  String get chsFilterNoteNone => 'No se aplica ningún filtro.';

  @override
  String get chsFilterNoteListed =>
      'Una lista necesita saber quién eres, así que el filtro más laxo aquí es Lectores firmados y wallets.';

  @override
  String get chsPostOwner => 'Solo yo';

  @override
  String get chsPostOwnerSub => 'Nadie más puede enviar publicaciones.';

  @override
  String get chsPostOpen => 'Todos los que pueden leerlo';

  @override
  String get chsPostOpenSub => 'Publicación abierta.';

  @override
  String get chsPostApproved => 'Solo gente que yo apruebo';

  @override
  String get chsPostApprovedSub => 'Una lista solo para publicar.';

  @override
  String get chsPostFilterGrp =>
      'Este filtro aplica a cuentas. Una wallet que agregaste a la lista de publicación lo salta — tu mano es lo que avala una llave sin nombre.';

  @override
  String get chsPostDailyLimit => 'Límite diario por persona';

  @override
  String get chsPostDailyLimitSub => '0 = sin límite';

  @override
  String get chsTalkAll => 'Cualquiera';

  @override
  String get chsTalkAllSub => 'Todos los que pueden leer el canal.';

  @override
  String get chsTalkFriends => 'Mis amigos';

  @override
  String get chsTalkFriendsSub =>
      'Solo el interruptor — la lista se maneja en Quién puede leerlo.';

  @override
  String get chsTalkCustom => 'Personalizada';

  @override
  String get chsTalkCustomSub => 'Tu lista de comentaristas.';

  @override
  String get chsTalkFilterGrp =>
      'Este filtro aplica a cuentas. Una wallet en una de tus listas lo salta — tu mano es lo que avala una llave sin nombre.';

  @override
  String get chsTalkSplit => 'Configurar reacciones por separado';

  @override
  String get chsTalkSplitSub =>
      'Rara vez necesario — las reacciones siguen a los comentarios por defecto.';

  @override
  String get chsTalkModeGated => 'Tus lectores. Los marcados pueden comentar.';

  @override
  String get chsTalkModePublic =>
      'Vacía hasta que agregues a alguien. Busca un nombre o pega cualquier dirección de wallet.';

  @override
  String get chsTalkSearchGated => 'Busca entre tus lectores…';

  @override
  String get chsSearchHint => 'Nombre, o cualquier dirección 0x…';

  @override
  String get chsListEmpty => 'Nadie aún';

  @override
  String get chsBlockedEmpty => 'Nadie está bloqueado';

  @override
  String get chsVisShowNewest => 'Mostrar los más recientes';

  @override
  String get chsVisHideOlder => 'Ocultar publicaciones anteriores a';

  @override
  String chsVisPosts(int count) {
    return '$count publicaciones';
  }

  @override
  String chsVisDays(int count) {
    return '$count días';
  }

  @override
  String get chsVisAll => 'Todo';

  @override
  String get chsVisOff => 'Apagado';

  @override
  String chsVisNewest(int count) {
    return '$count más recientes';
  }

  @override
  String chsVisVerdict(int total, int shown, int rest) {
    return 'Este canal tiene $total publicaciones. Se sirven las $shown más recientes; las otras $rest siguen guardadas, solo no se entregan.';
  }

  @override
  String get chsMonPlans => 'Planes de pago';

  @override
  String get chsMonPlansNone => 'Ninguno aún — gratis para leer';

  @override
  String chsMonPlansCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count planes',
      one: '1 plan',
    );
    return '$_temp0';
  }

  @override
  String get chsMonVerdictFree =>
      'Gratis para leer. No hay nada que encender aquí — un canal es de pago porque existen planes, no por un interruptor.';

  @override
  String get chsMonVerdictPaid =>
      'De pago. Quien lee debe pasar la puerta de lectura y haber pagado uno de los planes.';

  @override
  String get chsH1Anyone => 'Cualquiera';

  @override
  String get chsH1Signed => 'Cualquiera con firma';

  @override
  String get chsH1Standing => 'Todas las cuentas PublicOS';

  @override
  String get chsH1Citizen => 'Solo ciudadanos';

  @override
  String get chsH1ListedSignedBoth => 'Amigos + aprobados';

  @override
  String get chsH1ListedSignedFriends => 'Amigos';

  @override
  String get chsH1ListedSignedOwn => 'Aprobados';

  @override
  String get chsH1ListedCitizenBoth =>
      'Ciudadanos en tus listas, y wallets aprobadas';

  @override
  String get chsH1ListedCitizenFriends =>
      'Solo amigos ciudadanos y wallets aprobadas';

  @override
  String get chsH1ListedCitizenOwn => 'Solo ciudadanos aprobados y wallets';

  @override
  String get chsH1ListedStandingBoth =>
      'Cuentas PublicOS en tus listas, y wallets aprobadas';

  @override
  String get chsH1ListedStandingFriends =>
      'Amigos con cuenta PublicOS, y wallets aprobadas';

  @override
  String get chsH1ListedStandingOwn => 'Cuentas PublicOS aprobadas y wallets';

  @override
  String get chsH2Owner => 'Solo yo';

  @override
  String get chsH2OpenCitizen => 'Solo lectores ciudadanos';

  @override
  String get chsH2OpenStanding => 'Lectores con cuenta PublicOS';

  @override
  String get chsH2ApprovedCitizen => 'Solo ciudadanos aprobados y wallets';

  @override
  String get chsH2ApprovedStanding => 'Cuentas PublicOS aprobadas y wallets';

  @override
  String get chsH3CustomCitizen =>
      'Lista personalizada de ciudadanos y wallets';

  @override
  String get chsH3CustomStanding =>
      'Lista personalizada de cuentas PublicOS y wallets';

  @override
  String get chsH3FriendsCitizen => 'Solo amigos ciudadanos y wallets';

  @override
  String get chsH3FriendsStanding => 'Amigos con cuenta PublicOS y wallets';

  @override
  String get chsH3ReactionsDiffer => 'reacciones distintas';

  @override
  String get chsH4Nobody => 'Nadie';

  @override
  String chsH4Count(int count) {
    return '$count bloqueados';
  }

  @override
  String get chsH6Free => 'Gratis';

  @override
  String get chsH6Paid => 'De pago';

  @override
  String get chsFieldName => 'Nombre';

  @override
  String get chsFieldDescription => 'Descripción';

  @override
  String get chsDescriptionHint => 'Agrega una descripción…';

  @override
  String get chsFieldAddress => 'Dirección';

  @override
  String get chsFieldLanguage => 'Idioma';

  @override
  String get chsFieldSecret => 'Secreto';

  @override
  String get chsFieldServer => 'Servidor';

  @override
  String get chsServerLocked => '· fijo tras la creación';

  @override
  String get chsIconTitle => 'URL del ícono';

  @override
  String get chsAddressTitle => 'Dirección del canal';

  @override
  String get chsFailAdd => 'No se pudo agregar a la lista';

  @override
  String get chsFailRemove => 'No se pudo quitar de la lista';

  @override
  String get chsReqPasses => 'pasa';

  @override
  String get chsReqBlocked => 'bloqueado por el filtro';

  @override
  String get chsReqUnknown => 'desconocido';

  @override
  String get onbProvBodyCitizen =>
      'Un **BSP** te conecta a la red. Un **SSP** guarda tus publicaciones y los feeds que lees. Como ciudadano la red cubre ambos por ti.';

  @override
  String get onbProvBodyPrivate =>
      'Un **BSP** te conecta a la red. Un **SSP** guarda tus publicaciones y los feeds que lees. Los pagas conforme los usas, desde un saldo de servicios que recargas.';

  @override
  String get onbProvBodyUnknown =>
      'Un **BSP** te conecta a la red. Un **SSP** guarda tus publicaciones y los feeds que lees.';

  @override
  String get onbProvBspTitle => 'BSP · acceso a la red';

  @override
  String get onbProvSspTitle => 'SSP · tus feeds';

  @override
  String get onbProvAuto => 'HAZLO POR MÍ';

  @override
  String get onbProvAutoBsp => 'CONFIGURA MI BSP';

  @override
  String get onbProvAutoSsp => 'CONFIGURA MI SSP';

  @override
  String get onbProvChooseBsp => 'ELEGIR BSP';

  @override
  String get onbProvChooseSsp => 'ELEGIR SSP';

  @override
  String get onbProvWorking => 'CONFIGURANDO…';

  @override
  String get onbProvSetUpFirst => 'CONFIGURA ESTOS PRIMERO';

  @override
  String get onbProvNone => 'sin conectar';

  @override
  String get onbProvUnknownRow => 'no se pudo verificar ahora';

  @override
  String get onbProvRenewsItself => 'cubierto mientras la uses';

  @override
  String get onbProvStateNone => 'NINGUNO';

  @override
  String get onbProvStatePaired => 'ACTIVO';

  @override
  String get onbProvStateFailed => 'FALLÓ';

  @override
  String get onbProvStateWorking => '…';

  @override
  String get onbProvCostLabel => 'Lo que te costó';

  @override
  String get onbProvFreeWhy =>
      'La red paga a tus proveedores por ti. **Nada salió de tu cartera**, y ambos siguen cubiertos mientras uses la app.';

  @override
  String get onbProvPaidWhy =>
      'Ambos toman de un solo **saldo de servicios**, segundo a segundo, solo mientras el proveedor tenga suficientes suscriptores para cobrar. Recárgalo en **Servicios** antes de que se agote, y retira lo que sobre cuando quieras. **Nada lo recarga solo.**';

  @override
  String get onbProvAlreadyLabel => 'Aquí no hay nada que hacer';

  @override
  String get onbProvAlreadyWhy =>
      'Ya tienes ambos. Cambiar de proveedor está en **Servicios**, cambia cuando quieras; al anterior se le paga hasta el segundo.';

  @override
  String get onbProvUnknownLabel => 'Por qué se ocultó la opción de un toque';

  @override
  String get onbProvUnknownWhy =>
      'Para configurarlo por ti hay que saber si eres ciudadano, los dos caminos son distintos, así que **no lo adivina**. Elegirlo tú mismo sigue funcionando.';

  @override
  String get onbProvFailLabel => 'Por qué se detuvo';

  @override
  String get onbProvTreasuryHint =>
      'Puedes configurarlos cuando quieras en **Servicios**';

  @override
  String get onbProvDepositLabel => 'A punto de depositar';

  @override
  String get onbProvDepositGo => 'DEPOSITAR';

  @override
  String get onbProvSkip => 'OMITIR';

  @override
  String get onbProvSkipTitle => '¿Omitir por ahora?';

  @override
  String onbProvPaidTo(String date) {
    return 'cubierto hasta $date';
  }

  @override
  String onbProvLapsed(String provider) {
    return '$provider · se terminó';
  }

  @override
  String onbProvFailGeneric(String service) {
    return 'No pudimos configurar tu $service. Pudo ser la conexión, no se cobró nada.';
  }

  @override
  String onbProvFailNoProvider(String service) {
    return 'No encontramos un proveedor para tu $service en este momento.';
  }

  @override
  String onbProvSkipBody(String missing) {
    return 'Te faltan **$missing**. Sin ellos no tendrás la experiencia completa, puedes configurar ambos después en Servicios.';
  }

  @override
  String onbProvDepositWhy(String balance) {
    return 'Pasa de tu **MainSafe** a tu saldo de servicios ahora, un mes a la tarifa de hoy, tuyo para retirar mientras no se gaste. Tu saldo es $balance.';
  }

  @override
  String onbProvFailFunds(String service, String cost) {
    return 'No pudimos configurar tu $service. Cuesta $cost al mes y tu MainSafe no lo tiene.';
  }

  @override
  String get keychainOfferRegPublishing => 'Publicando…';

  @override
  String get statusBarNoKey => 'sin llave';

  @override
  String get statusBarInboxUnregistered => 'sin registrar';

  @override
  String statusBarInboxRegisteredAs(String name) {
    return 'Registrada como $name';
  }

  @override
  String get desktopStatusBarTopTitle => 'Barra de estado arriba';

  @override
  String get desktopStatusBarTopSubtitle =>
      'Ancla la barra de estado encima de los paneles';

  @override
  String get desktopAutoplayCardsTitle =>
      'Reproducir tarjetas interactivas automáticamente';

  @override
  String get desktopAutoplayCardsSubtitle =>
      'Las tarjetas arrancan solas en vez de esperar un toque. Usa más memoria.';

  @override
  String get desktopLogOut => 'CERRAR SESIÓN';

  @override
  String get desktopPushSubtitle =>
      'Recibe alertas cuando la app está cerrada (móvil)';

  @override
  String get desktopDemoDataTitle => 'Datos de demostración';

  @override
  String get desktopContactSettings => 'Ajustes';

  @override
  String get desktopLayoutChip => 'Diseño';

  @override
  String get desktopContactsSearchHint => 'Buscar PublicOS';

  @override
  String get desktopNoOrgsYet => 'Aún no hay organizaciones';

  @override
  String get desktopOrgsEmptyHint =>
      'Las organizaciones con las que interactúas aparecen aquí.';

  @override
  String get desktopSelectContactTitle => 'Selecciona un contacto';

  @override
  String get desktopSelectContactHint =>
      'Elige a alguien a la izquierda para ver su perfil.';

  @override
  String get desktopBootChainFailed => 'No se pudo conectar a la cadena';

  @override
  String get desktopRecoveryPhraseCopied => 'Frase de recuperación copiada';

  @override
  String get desktopReload => 'Recargar';

  @override
  String desktopGrantRevoked(String origin) {
    return 'Desconectado $origin';
  }

  @override
  String get desktopSessionKeySubtitle => 'La clave de sesión de tu cuenta';

  @override
  String get desktopSessionKeyWarning =>
      'Quien tenga esta clave controla la sesión de tu cuenta. Nunca la compartas.';

  @override
  String get desktopNavBlurbMyAccount =>
      'Tu perfil, registros de identidad, dominios, llavero y recuperación.';

  @override
  String get desktopNavBlurbContacts =>
      'La gente que conoces, el árbol de confianza y los ajustes por contacto.';

  @override
  String get desktopNavBlurbMessages =>
      'Conversaciones XMTP cifradas, grupos y herramientas de mensajes.';

  @override
  String get desktopNavBlurbFeeds =>
      'Comunidades, foros y las publicaciones que sigues.';

  @override
  String get desktopNavBlurbWallets => 'Saldos y transferencias de tokens.';

  @override
  String get desktopNavBlurbTreasury =>
      'Tus Utilidades, tus suscripciones y los nodos de la red.';

  @override
  String get desktopNavBlurbBsp =>
      'Proveedores de Servicio Blockchain — directorio y gestión.';

  @override
  String get desktopNavBlurbSsp =>
      'Proveedores de Servicio de Almacenamiento — suscripciones y tu servidor.';

  @override
  String get desktopNavBlurbNodes =>
      'Nodos de consenso y registro de validadores.';

  @override
  String get desktopNavBlurbSettings =>
      'Preferencias de la app, notificaciones y sesión de la cuenta.';

  @override
  String get desktopNavBlurbOrgs =>
      'Organizaciones — perfiles, membresía y gobernanza.';

  @override
  String get desktopNavBlurbSocialGraph =>
      'El grafo de avales — quién avaló a quién, la ciudadanía de un vistazo.';

  @override
  String get desktopNavBlurbAccount =>
      'Identidad, avales, dominio, sesiones y contactos de recuperación.';

  @override
  String get desktopRemoveFromHistory => 'Quitar del historial';

  @override
  String get desktopReloadProfile => 'Recargar perfil';

  @override
  String get desktopDoneEditing => 'Terminar de editar';

  @override
  String get desktopEditProfile => 'Editar perfil';

  @override
  String get desktopPageBackground => 'Fondo de la página';

  @override
  String get desktopProfileQr => 'QR del perfil';

  @override
  String get desktopCopyProfileLink => 'Copiar enlace del perfil';

  @override
  String get desktopFollowedManageLists => 'Siguiendo — gestionar listas';

  @override
  String get desktopFollowAddToList => 'Seguir — añadir a una lista';

  @override
  String get desktopBookmarkedRemove => 'Guardada — quitar';

  @override
  String get desktopBookmarkThisApp => 'Guardar esta app';

  @override
  String desktopTabTooltipChat(String label) {
    return '$label — chat';
  }

  @override
  String desktopTabTooltipChannel(String label) {
    return '$label — canal';
  }

  @override
  String desktopTabTooltipOpensExternal(String label) {
    return '$label — se abre en tu navegador';
  }

  @override
  String desktopTabTooltipOpensExternalUrl(String label, String url) {
    return '$label — $url (se abre en tu navegador)';
  }

  @override
  String desktopTabTooltipOpensExternalLinks(String label, int count) {
    return '$label — $count enlaces (se abren en tu navegador)';
  }

  @override
  String get desktopEditBanner => 'Editar portada';

  @override
  String get desktopEditAvatar => 'Editar avatar';

  @override
  String get desktopMoreTabs => 'Más pestañas';

  @override
  String get desktopChatSettings => 'Ajustes del chat';

  @override
  String get desktopChatSettingsHeader => 'AJUSTES DEL CHAT';

  @override
  String get desktopBubbleColorSection => 'COLOR DE BURBUJA';

  @override
  String get desktopAutoLabel => 'Auto';

  @override
  String get desktopPreviewTheirMessages => 'Así se ven sus mensajes';

  @override
  String get desktopPreviewYourMessages => 'Y así se ven los tuyos';

  @override
  String get desktopChatAppearanceLocalNote =>
      'Estos cambios son solo para ti — nadie más los ve.';

  @override
  String get desktopMessageChimeTitle => 'Sonido de mensaje';

  @override
  String get desktopMessageChimeSubtitle =>
      'Una campanita con cada mensaje que llega';

  @override
  String get desktopChipMyMessages => 'Mis mensajes';

  @override
  String get desktopChipTheirMessages => 'Sus mensajes';

  @override
  String get desktopFontSection => 'FUENTE';

  @override
  String get desktopWeightSection => 'GROSOR';

  @override
  String get desktopFontWeightLight => 'Fina';

  @override
  String get desktopFontWeightNormal => 'Normal';

  @override
  String get desktopFontWeightMedium => 'Media';

  @override
  String get desktopFontWeightSemiBold => 'Seminegrita';

  @override
  String get desktopFontWeightBold => 'Negrita';

  @override
  String get desktopStatusBarKeychainTooltip => 'Llavero — llaves de firma';

  @override
  String desktopStatusBarUnreadChain(int count) {
    return '$count notificaciones de la cadena sin leer';
  }

  @override
  String get desktopStatusBarChainNotifications =>
      'Notificaciones de la cadena';

  @override
  String get desktopStatusBarPublicNode => 'Nodo público';

  @override
  String get desktopStatusBarPublicServer => 'Servidor público';

  @override
  String get desktopStatusBarFeedServer => 'Servidor de feeds';

  @override
  String get desktopFollowTooltipManageLists => 'Elegir en qué listas';

  @override
  String get desktopFollowTooltipFollow => 'Seguir esta cuenta';

  @override
  String desktopFollowFailed(Object error) {
    return 'No se pudo seguir: $error';
  }

  @override
  String get desktopSelectConversationTitle => 'Selecciona una conversación';

  @override
  String get desktopSelectConversationHint =>
      'Elige un chat a la izquierda — o empieza uno desde un perfil.';

  @override
  String get desktopContactSettingsHeader => 'AJUSTES DE CONTACTOS';

  @override
  String get desktopContentWidthSection => 'ANCHO DEL CONTENIDO';

  @override
  String get desktopContentWidthHint =>
      'Limita cuánto se extiende cada tipo de pestaña en una ventana grande. Las pestañas web siempre se expanden.';

  @override
  String get desktopBrowserSettingsHeader => 'AJUSTES';

  @override
  String get desktopContentWidthProfile => 'Perfil';

  @override
  String get desktopContentWidthChat => 'Chat';

  @override
  String get desktopContentWidthFeeds => 'Feeds';

  @override
  String get desktopContentWidthFeedsHint =>
      'Compartido con la página de Feeds.';

  @override
  String get desktopNoAccountLoaded => 'No hay cuenta cargada';

  @override
  String get desktopAppLinkWebApp => 'Web app';

  @override
  String get desktopAppLinkAppStore => 'App Store';

  @override
  String get desktopAppLinkPlayStore => 'Play Store';

  @override
  String get paywallLockedWidgetBadge => 'CANAL DE PAGO';

  @override
  String get paywallLockedWidgetBlurbSubscribe =>
      'Leer este canal requiere una suscripción. Pagas desde tu cuenta y cualquier dispositivo donde inicies sesión podrá leerlo.';

  @override
  String paywallLockedWidgetBlurbRenew(String date) {
    return 'Tu suscripción terminó el $date. Renuévala para seguir leyendo.';
  }

  @override
  String get paywallLockedWidgetBlurbConfirming =>
      'Tu pago va en camino. El canal se abre en cuanto se confirme; normalmente toma unos segundos.';

  @override
  String get paywallLockedWidgetNoPlan =>
      'El plan de este canal no está disponible por ahora.';

  @override
  String get paywallLockedWidgetSubscribe => 'Suscribirme';

  @override
  String get paywallLockedWidgetRenew => 'Renovar';

  @override
  String get paywallLockedWidgetRetry => 'Revisar de nuevo';

  @override
  String get tierLockedWidgetVerifiedOnlyBadge => 'SOLO CIUDADANOS';

  @override
  String get tierLockedWidgetVerifiedOnlyBlurb =>
      'El propietario limitó este canal a ciudadanos verificados. Consigue un aval para leerlo.';

  @override
  String get tierLockedWidgetAccountOnlyBadge => 'SOLO CUENTAS';

  @override
  String get tierLockedWidgetAccountOnlyBlurb =>
      'Este canal es para cuentas de PublicOS. Inicia sesión con la llave de tu cuenta para leerlo.';

  @override
  String get tierLockedWidgetStandingBadge => 'REQUIERE ESTATUS';

  @override
  String get tierLockedWidgetStandingBlurb =>
      'Este canal es para ciudadanos y cuentas con dominio al corriente.';

  @override
  String get tierLockedWidgetRetry => 'Revisar de nuevo';

  @override
  String get subscribeSheetTitle => 'Suscribirme';

  @override
  String get subscribeSheetTitleRenew => 'Renovar suscripción';

  @override
  String get subscribeSheetPayingFrom => 'PAGAR DESDE';

  @override
  String get subscribeSheetMainSafe => 'Cartera principal';

  @override
  String get subscribeSheetNetwork => 'Red';

  @override
  String get subscribeSheetPrice => 'Precio';

  @override
  String get subscribeSheetPeriods => 'PERIODOS';

  @override
  String get subscribeSheetTotal => 'Total';

  @override
  String get subscribeSheetAccessUntil => 'Acceso hasta';

  @override
  String get subscribeSheetLapsedOn => 'Venció el';

  @override
  String subscribeSheetPeriodDays(int days) {
    return '$days días';
  }

  @override
  String subscribeSheetPeriodHours(int hours) {
    return '$hours horas';
  }

  @override
  String get subscribeSheetApproveNote =>
      'Esto toma dos transacciones desde tu cartera: primero apruebas el monto exacto y luego se envía. Un solo toque hace ambas.';

  @override
  String subscribeSheetConfirmApproveAndSend(String amount) {
    return 'Aprobar y enviar $amount';
  }

  @override
  String subscribeSheetConfirmSend(String amount) {
    return 'Enviar $amount';
  }

  @override
  String subscribeSheetStepApproving(int n, int total) {
    return 'Aprobando… ($n de $total)';
  }

  @override
  String subscribeSheetStepSending(int n, int total) {
    return 'Enviando… ($n de $total)';
  }

  @override
  String subscribeSheetNoSource(String chain) {
    return 'Ninguna de tus carteras puede pagar en $chain.';
  }

  @override
  String subscribeSheetInsufficient(String symbol) {
    return 'No hay suficiente $symbol en esta cartera.';
  }

  @override
  String get subscribeSheetQuoteFailed =>
      'No se pudieron obtener los términos del plan. Desliza para reintentar.';

  @override
  String subscribeSheetDone(String date) {
    return 'Suscripción lista: acceso hasta $date';
  }

  @override
  String get subscribeSheetFailed => 'El pago falló';

  @override
  String get createRecordPageLabelWhenTapped => 'AL TOCARLA';

  @override
  String get createRecordPageTapNothing => 'Nada';

  @override
  String get createRecordPageTapLink => 'Enlace';

  @override
  String get createRecordPageTapTip => 'Propina';

  @override
  String get createRecordPageLabelTipPayTo => 'PAGAR A';

  @override
  String get createRecordPageTipAddressHint => 'O pega una dirección (0x…)';

  @override
  String get createRecordPageTipInvalidAddress => 'No es una dirección válida';

  @override
  String get createRecordPageLabelTipNetwork => 'RED Y TOKEN';

  @override
  String get createRecordPageTipChecking => 'Revisando la dirección…';

  @override
  String get createRecordPageTipCheckFailed =>
      'No se pudo revisar esta dirección. Intenta de nuevo.';

  @override
  String get createRecordPageTipNoAmount =>
      'Quien visita elige la cantidad. La tarjeta nunca sugiere una.';

  @override
  String get tipCardSheetTitle => 'Enviar propina';

  @override
  String tipCardOwnerMainSafe(String name) {
    return 'Main Safe de $name';
  }

  @override
  String tipCardOwnerWallet(String name) {
    return 'Wallet de $name';
  }

  @override
  String tipCardOwnerUnknown(String name) {
    return 'Una dirección elegida por $name';
  }

  @override
  String get tipCardBroken =>
      'Esta tarjeta de propina no se puede pagar desde esta app';

  @override
  String get recordButtonMenuTip => 'Dar propina';

  @override
  String get recordButtonMenuOpenLink => 'Abrir enlace';

  @override
  String get recordButtonMenuSeeImage => 'Ver imagen';

  @override
  String get createRecordPageImageChange => 'Cambiar';

  @override
  String get createRecordPageHeaderPostCard => 'PUBLICACIÓN FIJADA';

  @override
  String get createRecordPagePostCardSizeLead =>
      'Una publicación que fijaste. Muestra la publicación tal como está ahora: sus ediciones, comentarios o si la borran se ven aquí. Siempre ocupa todo el ancho y crece con la publicación; tú eliges su fondo.';

  @override
  String get createRecordPagePinPlacement => 'Dónde va';

  @override
  String get createRecordPagePinTop => 'Fijar arriba';

  @override
  String get createRecordPagePinBottom => 'Fijar abajo';

  @override
  String get createRecordPagePinAction => 'FIJAR EN EL PERFIL';

  @override
  String get postCardMenuPinToProfile => 'Fijar en el perfil';

  @override
  String get postCardMenuGoToFeed => 'Ir al feed';

  @override
  String get feedReaderPageFallbackTitle => 'Feed';

  @override
  String get postCardPinSaving => 'Fijando en tu perfil…';

  @override
  String get postCardPinDone => 'Fijada en tu perfil';

  @override
  String get postCardPinFailed => 'No se pudo fijar la publicación';

  @override
  String get postCardPinnedGone => 'No se encontró esta publicación';

  @override
  String get postCardPinnedLocked => 'Esta publicación es privada';

  @override
  String get postCardPinnedFailed => 'No se pudo cargar. Toca para reintentar';

  @override
  String get createRecordPagePostCardLink => 'ENLACE DE LA PUBLICACIÓN';

  @override
  String get createRecordPagePostCardLinkCopy => 'Copiar enlace';

  @override
  String get createRecordPagePostCardLinkCopied => 'Enlace copiado';

  @override
  String get createRecordPageBackgroundImage => 'Imagen';

  @override
  String get createRecordPagePostMedia =>
      'Multimedia de la publicación como fondo';

  @override
  String get createRecordPagePostMediaHint =>
      'Muestra el banner, la imagen o el video de la publicación delante del fondo.';

  @override
  String get netDepositMonths => 'Depósito (meses)';

  @override
  String get netDeposit => 'Depósito';

  @override
  String get networkAccessSheetsTopUpHeader => 'RECARGAR';

  @override
  String get networkAccessSheetsTopUpTitle => 'Recarga tu saldo de servicios';

  @override
  String get networkAccessSheetsTopUpBody =>
      'Pasa de tu cartera al saldo del que toman tus dos proveedores. Lo que no hayan ganado es tuyo para retirar.';

  @override
  String get networkAccessSheetsMonthsOfCover => 'Meses de cobertura';

  @override
  String get networkAccessSheetsRatePerMonth => 'Ambos servicios / mes';

  @override
  String get networkAccessSheetsDepositing => 'DEPOSITANDO…';

  @override
  String get networkAccessSheetsDeposit => 'DEPOSITAR';

  @override
  String get networkAccessSheetsWithdrawHeader => 'RETIRAR';

  @override
  String get networkAccessSheetsWithdrawTitle => 'Recupera tu saldo';

  @override
  String get networkAccessSheetsWithdrawBody =>
      'Primero se paga lo que tus proveedores han acumulado hasta este segundo; el resto vuelve a tu cartera.';

  @override
  String get networkAccessSheetsAvailable => 'Disponible';

  @override
  String get networkAccessSheetsAccrued => 'Acumulado para proveedores';

  @override
  String get networkAccessSheetsAddedForYou => 'Agregado para ti';

  @override
  String get networkAccessSheetsAddedForYouNote =>
      'Parte de este saldo lo agregó alguien más para ti. Paga primero a tus proveedores y nunca vuelve a tu cartera.';

  @override
  String get networkAccessSheetsWithdrawing => 'RETIRANDO…';

  @override
  String get networkAccessSheetsWithdraw => 'RETIRAR';

  @override
  String get networkAccessSheetsNothingToWithdraw => 'Nada que retirar.';

  @override
  String networkAccessSheetsLeaveHeader(Object provider) {
    return 'DEJAR $provider';
  }

  @override
  String networkAccessSheetsLeaveTitle(Object slug) {
    return 'Dejar $slug';
  }

  @override
  String get networkAccessSheetsLeaveBody =>
      'Detiene este servicio ahora. Se paga lo acumulado hasta este segundo; tu saldo sigue siendo tuyo.';

  @override
  String get networkAccessSheetsLeaving => 'DEJANDO…';

  @override
  String get networkAccessSheetsLeave => 'DEJAR';

  @override
  String get treasuryPageSubInactive => 'INACTIVA';

  @override
  String get treasuryPageCoveredUntil => 'Cubierto hasta';

  @override
  String get treasuryPageCoveredWhileUsed => 'mientras uses la app';

  @override
  String treasuryPageSubActiveCitizenBody(Object provider) {
    return 'Activa. La red acuña la tarifa de tu $provider mientras uses la app. Cambia cuando quieras.';
  }

  @override
  String get treasuryPageSubInactiveBody =>
      'Sin servicio ahora mismo — la cuenta estuvo inactiva demasiado tiempo, o el saldo se agotó. Abre la app, recarga o suscríbete de nuevo para reanudar.';

  @override
  String get treasuryPageServiceBalance => 'Saldo de servicios';

  @override
  String get treasuryPageServiceBalanceBlurb =>
      'Un solo saldo paga tu BSP y tu SSP, segundo a segundo, solo mientras el proveedor tenga suficientes suscriptores para cobrar. Recárgalo o recupéralo cuando quieras.';

  @override
  String get treasuryPageBalance => 'Saldo';

  @override
  String get treasuryPageAccrued => 'Acumulado, sin pagar';

  @override
  String get treasuryPageAddedForYou => 'Agregado para ti';

  @override
  String treasuryPageAddedForYouNote(Object amount) {
    return '$amount OX de este saldo se agregaron para ti y pagan a tus proveedores; no se pueden retirar.';
  }

  @override
  String get treasuryPageRunsOut => 'Se agota';

  @override
  String get treasuryPageNeverSubscribed =>
      'Aún no hay depósitos — suscríbete a un proveedor abajo.';

  @override
  String get treasuryPageTopUp => 'RECARGAR';

  @override
  String get treasuryPageWithdraw => 'RETIRAR';

  @override
  String treasuryPageLeaveProvider(Object provider) {
    return 'DEJAR $provider';
  }

  @override
  String get treasuryPageToppedUp => 'Saldo de servicios recargado';

  @override
  String get treasuryPageWithdrawn => 'Saldo de servicios retirado';

  @override
  String treasuryPageProviderLeft(Object provider) {
    return '$provider dejado';
  }

  @override
  String get treasuryPageResume => 'REANUDAR';

  @override
  String get treasuryPageResumed => 'Servicio reanudado';

  @override
  String get accountCenterOrgsSection => 'Membresía en organizaciones';

  @override
  String get orgAddAnyoneTitle => 'Cualquiera puede agregarme';

  @override
  String get orgAddAnyoneOnSub =>
      'Cualquiera puede agregarte a una organización.';

  @override
  String get orgAddAnyoneOffSub =>
      'Solo las personas de tu lista pueden agregarte.';

  @override
  String get orgAddListLabel => 'QUIÉN PUEDE AGREGARME';

  @override
  String get orgAddListEmpty => 'Vacía';

  @override
  String get orgAddListOnHint =>
      'Tu lista cuenta cuando el interruptor está apagado.';

  @override
  String orgAddLeft(int count) {
    return 'quedan $count';
  }

  @override
  String get orgAddAllowFriend => 'PERMITIR QUE UN AMIGO ME AGREGUE';

  @override
  String get orgAddSheetTitle => 'Permitir que un amigo me agregue';

  @override
  String get orgAddSheetHeading => 'Quién puede agregarte a organizaciones';

  @override
  String get orgAddSheetBody =>
      'Tu amigo puede agregarte a 5 organizaciones, creando una contigo o proponiéndote en una. Después de 5 sale de tu lista, y puedes volver a agregarlo.';

  @override
  String get orgAddRemoveTitle => '¿Quitar de tu lista?';

  @override
  String orgAddRemoveBody(String name) {
    return '$name ya no podrá agregarte a organizaciones.';
  }

  @override
  String get orgAddSaving => 'GUARDANDO Y CONFIRMANDO…';

  @override
  String get orgAddFailed => 'No se pudo guardar el cambio.';

  @override
  String get orgAddPillAnyone => 'Cualquiera';

  @override
  String orgAddPillFriends(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amigos',
      one: '1 amigo',
    );
    return '$_temp0';
  }

  @override
  String get networkAccessSheetsAmount => 'Monto';

  @override
  String networkAccessSheetsCoversBoth(Object months) {
    return 'Cubre cerca de $months meses de BSP y SSP a las tarifas de hoy.';
  }

  @override
  String networkAccessSheetsCoversOne(Object months, Object provider) {
    return 'Cubre cerca de $months meses de $provider a las tarifas de hoy.';
  }

  @override
  String get networkAccessSheetsCoversNone =>
      'Aún no tienes suscripción a un proveedor; el depósito espera en tu saldo.';

  @override
  String get networkAccessSheetsGateNote =>
      'Tus proveedores aún no llegan a su mínimo de suscriptores, así que todavía no se toma nada.';

  @override
  String get networkAccessSheetsMax => 'MÁX';

  @override
  String get networkAccessSheetsAmountTooHigh =>
      'Es más de lo que puedes retirar ahora.';

  @override
  String get operatorAgreementSection => 'Acuerdo de operador';

  @override
  String get operatorAgreementSignedPill => 'FIRMADO';

  @override
  String get operatorAgreementUnsignedPill => 'SIN FIRMAR';

  @override
  String get operatorAgreementSignedBody =>
      'Aceptaste el acuerdo de operador vigente. Puedes registrar un proveedor.';

  @override
  String get providerRegistrationInviteOnly =>
      'Por ahora, registrar un proveedor es por invitación, y tu cuenta aún no está en la lista.';

  @override
  String get operatorAgreementUnsignedBody =>
      'Operar un BSP o SSP empieza con el acuerdo de operador. Léelo y fírmalo para registrar un proveedor.';

  @override
  String get operatorAgreementSign => 'FIRMAR ACUERDO';

  @override
  String get operatorAgreementTitle => 'Acuerdo de operador';

  @override
  String get operatorAgreementLead =>
      'Lee el acuerdo de operador hasta el final. Firmarlo te permite registrar BSPs y SSPs; cada registro lo verifica.';

  @override
  String operatorAgreementVersion(Object version) {
    return 'Acuerdo de operador · versión $version';
  }

  @override
  String get operatorAgreementScrollHint =>
      'Desliza hasta el final para firmar';

  @override
  String get operatorAgreementAccept => 'ACEPTAR Y FIRMAR';

  @override
  String get operatorAgreementSigning => 'FIRMANDO';

  @override
  String get operatorAgreementDoneTitle => 'Acuerdo firmado';

  @override
  String get operatorAgreementDoneBody =>
      'Ya puedes registrar un BSP o un SSP desde esta página.';

  @override
  String get operatorAgreementContinue => 'CONTINUAR';

  @override
  String get operatorAgreementFailed => 'La firma no se completó.';

  @override
  String get operatorAgreementRetry => 'INTENTAR DE NUEVO';

  @override
  String get operatorAgreementNeedsPermanentKey =>
      'Firmar requiere una llave permanente. Esta sesión expira; abre PublicOS con tu llave principal y firma ahí.';

  @override
  String get operatorAgreementLoadFailed =>
      'No se pudo cargar el acuerdo. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get operatorAgreementNothingPublished =>
      'Aún no hay un acuerdo de operador publicado. Inténtalo más tarde.';

  @override
  String get groupVotingViewMaxOpen => 'Votaciones abiertas a la vez';

  @override
  String get groupVotingViewMaxOpenSubtitle =>
      'Cuántas propuestas pueden correr en paralelo (1–5)';

  @override
  String get groupVotingViewWaitFull => 'Esperar el periodo completo';

  @override
  String get groupVotingViewWaitFullSubtitle =>
      'Las votaciones aprobadas se ejecutan solo al terminar su periodo; cualquier miembro las ejecuta';

  @override
  String get groupVotingViewProposerCap => 'Una propuesta abierta por miembro';

  @override
  String get groupVotingViewProposerCapSubtitle =>
      'La propuesta de un miembro debe aprobarse antes de que inicie otra';

  @override
  String get groupVotingViewOn => 'SÍ';

  @override
  String get groupVotingViewOff => 'NO';

  @override
  String get groupVotingViewSettingVoteTitle => 'Iniciar una votación';

  @override
  String groupVotingViewSettingVoteBody(Object setting, Object value) {
    return '$setting → $value. Cambia cuando la votación se aprueba, y solo para propuestas nuevas.';
  }

  @override
  String get groupVotingViewStartVote => 'INICIAR VOTACIÓN';

  @override
  String get groupVotingViewSettingVoteStarted => 'Votación iniciada';

  @override
  String get groupVotingViewExecute => 'EJECUTAR AHORA';

  @override
  String get groupVotingViewExecuted => 'La propuesta se ejecutó';

  @override
  String get groupVotingViewExecuteFailed =>
      'La ejecución falló; sigue abierta para intentarlo de nuevo';

  @override
  String get groupVotingViewWaitMode =>
      'Modo espera · se ejecuta al terminar el periodo';

  @override
  String get groupVotingViewWaitingToRun =>
      'Aprobada · se ejecuta al terminar el periodo';

  @override
  String get groupVotingViewReadyToRun => 'Aprobada · lista para ejecutar';

  @override
  String get groupVotingViewRunFailed =>
      'Aprobada · la última ejecución falló, ejecútala de nuevo';

  @override
  String get groupVotingViewPayment => 'PAGO';

  @override
  String groupVotingViewPayTo(Object amount) {
    return 'Pagar $amount a';
  }

  @override
  String get groupVotingViewFromOrgSafe => 'desde el Safe del grupo';

  @override
  String groupVotingViewOpenPill(int count) {
    return '$count ABIERTAS';
  }

  @override
  String get groupVotingViewSplitterActivate => 'Activar reparto';

  @override
  String get groupVotingViewSplit => 'Repartir';

  @override
  String get groupVotingViewSplitterActivateTitle => '¿Activar el reparto?';

  @override
  String get groupVotingViewSplitterActivateBody =>
      'Inicia una votación. Cuando se apruebe, este grupo podrá repartir OX de su Safe en partes iguales entre sus miembros, con una votación por reparto. Solo se hace una vez.';

  @override
  String get groupVotingViewSplitTitle => 'Repartir OX';

  @override
  String groupVotingViewSplitBody(int count, Object balance) {
    return 'Inicia una votación para repartir una cantidad en partes iguales entre los $count miembros. El grupo tiene $balance OX.';
  }

  @override
  String get groupVotingViewSplitAmountHint => 'Cantidad';

  @override
  String groupVotingViewSplitEach(Object share) {
    return 'Cada miembro recibe $share OX';
  }

  @override
  String get groupVotingViewSplitTooMuch => 'Es más de lo que tiene el grupo';

  @override
  String get groupVotingViewSplitLabel => 'REPARTO';

  @override
  String get groupVotingViewSplitterActivateVote =>
      'Activar el reparto de OX entre los miembros';

  @override
  String groupVotingViewSplitVote(Object amount, int count) {
    return 'Repartir $amount entre $count miembros';
  }

  @override
  String groupVotingViewProposedBy(Object name) {
    return 'propuesta de $name';
  }

  @override
  String groupVotingViewSafeShort(Object balance) {
    return 'El Safe tiene $balance. Si se aprueba, el pago fallará.';
  }

  @override
  String groupVotingViewRunCall(Object method, Object address) {
    return 'Ejecutar $method en $address';
  }

  @override
  String groupVotingViewProviderRegRestricted(Object registry) {
    return 'Registro de $registry: solo por invitación';
  }

  @override
  String groupVotingViewProviderRegOpen(Object registry) {
    return 'Registro de $registry: abierto a todos';
  }

  @override
  String groupVotingViewProviderRegAllow(Object registry) {
    return 'Lista de registro de $registry: agregar a';
  }

  @override
  String groupVotingViewProviderRegDisallow(Object registry) {
    return 'Lista de registro de $registry: quitar a';
  }

  @override
  String get groupVotingViewNativeUnit => 'moneda nativa';

  @override
  String groupVotingViewNeedsMore(Object count, Object floor) {
    return 'Faltan $count votos a favor o abstenciones para el quórum de $floor';
  }

  @override
  String get groupVotingViewForMustLead =>
      'Hay quórum, pero A favor debe superar a En contra para aprobarse';

  @override
  String get groupVotingViewTechDetails => 'Detalles técnicos';

  @override
  String get groupVotingViewTechTarget => 'Destino';

  @override
  String get groupVotingViewTechValue => 'Valor';

  @override
  String get groupVotingViewTechMethod => 'Método';

  @override
  String get groupVotingViewTechData => 'Datos';

  @override
  String get groupVotingViewDescAdd => 'Agregar a';

  @override
  String get groupVotingViewDescRemove => 'Quitar a';

  @override
  String get groupVotingViewDescSuspend => 'Suspender a';

  @override
  String get groupVotingViewDescUnsuspend => 'Levantar la suspensión de';

  @override
  String get groupVotingViewDescClearVouches => 'Borrar los avales de';

  @override
  String get groupVotingViewDescRequestParent => 'Unirse como hijo de';

  @override
  String get groupVotingViewDescCancelParent => 'Retirar la solicitud a';

  @override
  String get groupVotingViewDescAcceptChild => 'Aceptar como hijo a';

  @override
  String get groupVotingViewDescReleaseChild => 'Liberar al hijo';

  @override
  String get groupVotingViewDescChildLock => 'Bloqueo de hijos';

  @override
  String get groupVotingViewDescAddCard => 'Agregar una tarjeta';

  @override
  String get groupVotingViewDescUpdateCard => 'Actualizar una tarjeta';

  @override
  String get groupVotingViewDescDeleteCard => 'Eliminar una tarjeta';

  @override
  String groupVotingViewDescSetSocial(Object name) {
    return 'Definir $name';
  }

  @override
  String groupVotingViewDescRemoveSocial(Object name) {
    return 'Quitar $name';
  }

  @override
  String groupVotingViewDescAddTab(Object name) {
    return 'Agregar la pestaña “$name”';
  }

  @override
  String groupVotingViewDescUpdateTab(Object name) {
    return 'Actualizar la pestaña “$name”';
  }

  @override
  String groupVotingViewDescRemoveTab(Object name) {
    return 'Quitar la pestaña “$name”';
  }

  @override
  String get groupVotingViewDescChangeBio => 'Cambiar la biografía';

  @override
  String get groupVotingViewDescChangeAvatar => 'Cambiar la foto de perfil';

  @override
  String get groupVotingViewDescChangeBanner => 'Cambiar el banner';

  @override
  String get groupVotingViewDescChangeBackground => 'Cambiar el fondo';

  @override
  String get groupVotingViewDescChangeColor => 'Cambiar el color del perfil';

  @override
  String groupVotingViewDescSetRecord(Object name) {
    return 'Definir “$name”';
  }

  @override
  String groupVotingViewDescDeleteRecord(Object name) {
    return 'Eliminar “$name”';
  }

  @override
  String get groupVotingViewDescNone => 'nada';

  @override
  String groupVotingViewDescBatch(Object count) {
    return 'Actualizar $count registros';
  }

  @override
  String groupVotingViewDescDeleteBatch(Object count) {
    return 'Eliminar $count registros';
  }

  @override
  String groupVotingViewDescAddWallet(Object label) {
    return 'Agregar la cartera “$label”';
  }

  @override
  String get groupVotingViewDescRemoveWallet => 'Quitar una cartera';

  @override
  String groupVotingViewDescAddInbox(Object label) {
    return 'Agregar el buzón de chat “$label”';
  }

  @override
  String get groupVotingViewDescRemoveInbox => 'Quitar un buzón de chat';

  @override
  String groupVotingViewDescRegisterApp(Object slug) {
    return 'Registrar la app $slug';
  }

  @override
  String groupVotingViewDescRemoveApp(Object slug) {
    return 'Quitar la app $slug';
  }

  @override
  String groupVotingViewDescRenameApp(Object slug) {
    return 'Renombrar la app $slug';
  }

  @override
  String groupVotingViewDescSetAppPointer(Object slug, Object pointer) {
    return 'Definir $pointer de $slug';
  }

  @override
  String groupVotingViewDescRemoveAppPointer(Object slug, Object pointer) {
    return 'Quitar $pointer de $slug';
  }

  @override
  String groupVotingViewDescSetValue(Object name, Object value) {
    return 'Definir $name: “$value”';
  }

  @override
  String groupVotingViewDescWas(Object value) {
    return 'antes: “$value”';
  }

  @override
  String get groupVotingViewDescBio => 'biografía';

  @override
  String get groupVotingViewDescColor => 'color del perfil';

  @override
  String get groupVotingViewOutcomeExecuted => 'APROBADA · EJECUTADA';

  @override
  String get groupVotingViewOutcomeDefeated => 'RECHAZADA';

  @override
  String get groupVotingViewOutcomeExpired => 'VENCIDA';

  @override
  String get groupVotingViewOutcomeRunFailed => 'APROBADA · FALLÓ AL EJECUTAR';

  @override
  String get groupVotingViewOutcomeCancelled => 'CANCELADA';

  @override
  String get groupVotingViewRecent => 'ÚLTIMAS 24 HORAS';

  @override
  String get groupVotingViewSending => 'Enviando a la cadena…';

  @override
  String get keyLifetimeTitle => 'DURACIÓN DE LA LLAVE';

  @override
  String get keyLifetime24h => '24 horas';

  @override
  String get keyLifetimeWeek => '1 semana';

  @override
  String get keyLifetimeMonth => '1 mes';

  @override
  String get keyLifetimePermanent => 'Permanente';

  @override
  String get keyLifetimePermanentHint =>
      'Una llave permanente puede hacer todo, incluida la recuperación y la ciudadanía.';

  @override
  String get keyLifetimeExpiringHint =>
      'Una llave temporal deja de funcionar sola. No puede agregar llaves, cambiar la recuperación ni reclamar la ciudadanía.';

  @override
  String keyLifetimeExpiresIn(Object time) {
    return 'vence en $time';
  }

  @override
  String get keyLifetimeExpired => 'llave vencida';

  @override
  String get addSessionDialogLifetimePermanent => 'Esta llave será permanente.';

  @override
  String addSessionDialogLifetimeExpiring(Object lifetime) {
    return 'Esta llave vence $lifetime después de que la apruebes.';
  }

  @override
  String get addSessionDialogRecoveryNeedsPermanent =>
      'La recuperación siempre instala una llave permanente. Pide un código nuevo con la duración Permanente.';

  @override
  String get keyLifetimePermanentKey => 'llave permanente';

  @override
  String get addSessionDialogNewSessionLabel => 'NUEVA SESIÓN';

  @override
  String get childrenSheetLockTitle => '¿Bloquear este grupo hijo?';

  @override
  String get childrenSheetUnlockTitle => '¿Desbloquear este grupo hijo?';

  @override
  String childrenSheetLockBody(Object name) {
    return 'Inicia una votación para que $name no pueda tener nuevos grupos hijos. Los que ya tiene se quedan.';
  }

  @override
  String childrenSheetUnlockBody(Object name) {
    return 'Inicia una votación para que $name pueda volver a tener nuevos grupos hijos.';
  }

  @override
  String get childrenSheetLocked => 'Bloqueado: no acepta nuevos hijos';

  @override
  String get groupVotingViewDescLockChild => 'Bloquear nuevos hijos bajo';

  @override
  String get groupVotingViewDescUnlockChild => 'Permitir nuevos hijos bajo';

  @override
  String get accountCenterClearRecordsSection => 'Borrar todos los registros';

  @override
  String get accountCenterClearRecordsBody =>
      'Borra todo lo de tu perfil: foto, banner, fondo, biografía, redes, tarjetas y pestañas. Tu cuenta, tu nombre, tu ciudadanía y tu dinero se quedan.';

  @override
  String get accountCenterClearRecordsButton => 'BORRAR TODOS LOS REGISTROS';

  @override
  String get clearRecordsDlg1Title => '¿Borrar todos los registros?';

  @override
  String get clearRecordsDlg1Lead => 'Esto borra, de una vez:';

  @override
  String get clearRecordsCostIdentity =>
      'Tu foto de perfil, banner, fondo y color';

  @override
  String get clearRecordsCostBio => 'Tu biografía y tu estado';

  @override
  String get clearRecordsCostLinks => 'Todas tus redes';

  @override
  String get clearRecordsCostCards =>
      'Todas tus tarjetas, publicaciones fijadas y pestañas';

  @override
  String get clearRecordsCostForever =>
      'No se puede deshacer: los registros se borran en la cadena, no se ocultan';

  @override
  String get clearRecordsDlg1Stays =>
      'Tu cuenta, tu nombre, tu ciudadanía, tu dinero, tus llaves y tus mensajes se quedan.';

  @override
  String get clearRecordsDlg1Confirm => 'BORRAR';

  @override
  String clearRecordsWait(Object seconds) {
    return 'BORRAR · $seconds';
  }

  @override
  String get clearRecordsKeep => 'CONSERVAR MI PERFIL';

  @override
  String get clearRecordsDlg2Title => 'Último paso';

  @override
  String get clearRecordsDlg2Body =>
      'Tu perfil quedará vacío. Lo que quieras de vuelta tendrás que agregarlo otra vez.';

  @override
  String get clearRecordsDlg2Confirm => 'BORRAR TODO AHORA';

  @override
  String clearRecordsWorking(Object removed, Object left) {
    return 'Borrando registros… $removed borrados, faltan $left';
  }

  @override
  String clearRecordsDone(Object count) {
    return '$count registros borrados';
  }

  @override
  String get clearRecordsFailed => 'No se pudieron borrar los registros';

  @override
  String get startNewVoteSheetWalletTypeLabel => 'TIPO DE CARTERA';

  @override
  String get startNewVoteSheetWalletTypeKey => 'Cuenta con llave';

  @override
  String get startNewVoteSheetWalletTypeSafe => 'Safe en PublicOS';

  @override
  String get startNewVoteSheetWalletTypeHint =>
      'Una cuenta con llave funciona en todas las cadenas. Un Safe es una cartera inteligente en la cadena de PublicOS.';

  @override
  String get accountCenterPenaltiesSection => 'Penalizaciones';

  @override
  String penaltiesOwedPill(Object amount) {
    return 'Debes $amount OX';
  }

  @override
  String get penaltiesBody =>
      'Una penalización es una deuda que el tribunal pone a una cuenta, con un motivo y una fecha límite. Mientras debas algo, las suscripciones a BSP y SSP quedan bloqueadas. Lo que cobres paga primero la deuda.';

  @override
  String get penaltiesNothingOwed => 'No debes nada.';

  @override
  String get penaltiesOpenLabel => 'ABIERTAS';

  @override
  String get penaltiesHistoryLabel => 'HISTORIAL';

  @override
  String penaltyPaidOf(Object paid, Object amount) {
    return '$paid de $amount OX pagados';
  }

  @override
  String penaltyPayBy(Object date) {
    return 'Pagar antes del $date';
  }

  @override
  String penaltyOverdueSince(Object date) {
    return 'Vencida desde el $date';
  }

  @override
  String get penaltyStatusPaid => 'Pagada';

  @override
  String get penaltyStatusCancelled => 'Cancelada';

  @override
  String get penaltyStatusPromoted => 'Pasó a suspensión';

  @override
  String get penaltiesOverdueWarning =>
      'Si una penalización no se paga a tiempo, cualquiera puede convertirla en un aviso de suspensión de 10 días.';

  @override
  String get penaltiesPayButton => 'PAGAR PENALIZACIONES';

  @override
  String get penaltiesPaid => 'Penalizaciones pagadas.';

  @override
  String get penaltiesPayFailed => 'El pago falló.';

  @override
  String standingOwedAlert(Object amount) {
    return 'Debes $amount OX en penalizaciones. Las suscripciones a BSP y SSP están bloqueadas hasta que pagues.';
  }

  @override
  String get standingBlacklistedAlert =>
      'Tu cuenta está en la lista negra del tribunal. Las suscripciones a BSP y SSP están bloqueadas.';

  @override
  String standingNoticeAlert(Object date) {
    return 'Tu cuenta será suspendida el $date. Sigue funcionando hasta entonces; puedes sacar tus fondos.';
  }

  @override
  String standingSuspendedAlert(Object date) {
    return 'Tu cuenta está suspendida desde el $date.';
  }

  @override
  String get payPenaltiesHeader => 'PAGAR PENALIZACIONES';

  @override
  String get payPenaltiesTitle => 'Paga lo que debes';

  @override
  String get payPenaltiesBody =>
      'Se paga desde tu cartera principal y se quema. Primero se paga la penalización más antigua, y puedes pagar una parte.';

  @override
  String get payPenaltiesOwed => 'Debes';

  @override
  String get payPenaltiesAll => 'TODO';

  @override
  String get payPenaltiesPay => 'PAGAR';

  @override
  String get payPenaltiesPaying => 'PAGANDO…';

  @override
  String get payPenaltiesAboveOwed => 'Solo se toma lo que se debe.';

  @override
  String get treasuryPageServicesBlocked =>
      'Las suscripciones están bloqueadas: debes penalizaciones o tu cuenta está en la lista negra del tribunal. Ve a Cuenta › Penalizaciones.';

  @override
  String get flagAction => 'Reportar';

  @override
  String get flagSheetTitlePost => 'Reportar esta publicación';

  @override
  String get flagSheetTitleComment => 'Reportar este comentario';

  @override
  String get flagSheetTitleChannel => 'Reportar este canal';

  @override
  String get flagSheetTitleProfile => 'Reportar este perfil';

  @override
  String get flagSheetLead =>
      'Elige la regla que rompe. Tu reporte es público en la cadena y el dueño puede verlo. Puedes tener un reporte abierto por cada cosa.';

  @override
  String get flagCategory0 => 'Spam';

  @override
  String get flagCategory1 => 'Estafa o fraude';

  @override
  String get flagCategory2 => 'Suplantación de identidad';

  @override
  String get flagCategory3 => 'Acoso';

  @override
  String get flagCategory4 => 'Discurso de odio';

  @override
  String get flagCategory5 => 'Violencia o amenazas';

  @override
  String get flagCategory6 => 'Terrorismo o extremismo';

  @override
  String get flagCategory7 => 'Autolesión';

  @override
  String get flagCategory8 => 'Contenido sexual sin etiqueta para adultos';

  @override
  String get flagCategory9 => 'Desinformación electoral o cívica';

  @override
  String get flagCategory10 => 'Derechos de autor o marca';

  @override
  String get flagCategory11 => 'Otra cosa';

  @override
  String flagCategoryUnknown(Object id) {
    return 'Regla $id';
  }

  @override
  String get flagPrivateHeader => 'REPORTES PRIVADOS';

  @override
  String get flagPrivacy => 'Mi privacidad o datos personales';

  @override
  String get flagIntimate => 'Imágenes íntimas compartidas sin consentimiento';

  @override
  String get flagChildSafety => 'Seguridad infantil';

  @override
  String get flagPrivateBody =>
      'Estos nunca son reportes públicos. Van en privado al operador del servidor como un aviso, y los avisos aún no están abiertos.';

  @override
  String get flagNoteHint => 'Agrega una nota (opcional)';

  @override
  String get flagSubmit => 'REPORTAR';

  @override
  String get flagSending => 'REPORTANDO…';

  @override
  String get flagFailed => 'El reporte no se envió.';

  @override
  String get flagDone => 'Reportado. El dueño y el servidor pueden verlo.';

  @override
  String get flagAlreadyTitle => 'Ya reportaste esto';

  @override
  String flagFiledOn(Object category, Object date) {
    return '$category · $date';
  }

  @override
  String flagStatusOpenUntil(Object date) {
    return 'Abierto hasta el $date';
  }

  @override
  String get flagStatusExpired => 'Expirado';

  @override
  String get flagStatusWithdrawn => 'Retirado';

  @override
  String get flagStatusRemoved => 'Quitado por el tribunal';

  @override
  String get flagStatusCleared => 'Despejado por el tribunal';

  @override
  String get flagWithdraw => 'RETIRAR REPORTE';

  @override
  String get flagWithdrawing => 'RETIRANDO…';

  @override
  String flagWithdrawNote(Object date) {
    return 'Si lo retiras, podrás reportar esto otra vez a partir del $date.';
  }

  @override
  String flagAgainOn(Object date) {
    return 'Podrás reportar esto otra vez el $date.';
  }

  @override
  String get flagWithdrawn => 'Reporte retirado.';

  @override
  String get flagKindPost => 'Publicación';

  @override
  String get flagKindComment => 'Comentario';

  @override
  String get flagKindChannel => 'Canal';

  @override
  String get flagKindProfile => 'Perfil';

  @override
  String get accountCenterFlagsSection => 'Reportes';

  @override
  String get flagsMineLabel => 'MIS REPORTES';

  @override
  String get flagsOnMeLabel => 'SOBRE MI CONTENIDO';

  @override
  String get flagsOnMeBody => 'Solo tú y el servidor que lo aloja ven estos.';

  @override
  String get flagsNoneMine => 'No has reportado nada.';

  @override
  String get flagsNoneOnMe => 'Nada tuyo ha sido reportado.';

  @override
  String flagsPillOpen(Object count) {
    return '$count abiertos';
  }

  @override
  String get feedsNavigationDrawerExplore => 'Explorar';

  @override
  String get feedsViewExplore => 'Explorar';

  @override
  String get exploreWindowNow => '10 min';

  @override
  String get exploreWindowHour => 'Hora';

  @override
  String get exploreWindow12h => '12 h';

  @override
  String get exploreWindow24h => '24 h';

  @override
  String get exploreTabPosts => 'Publicaciones';

  @override
  String get exploreTabFeeds => 'Canales';

  @override
  String exploreReaders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lectores',
      one: '1 lector',
    );
    return '$_temp0';
  }

  @override
  String get exploreEmptyTitle => 'Todavía no hay tendencias';

  @override
  String get exploreEmptySubtitle =>
      'Cada 10 minutos los servidores de la red acuerdan qué es lo más leído. Desliza hacia abajo para volver a revisar.';

  @override
  String get feedsNavigationDrawerSectionExplore => 'EXPLORAR';

  @override
  String get exploreHotPosts => 'Publicaciones populares';

  @override
  String get exploreHotFeeds => 'Canales populares';

  @override
  String get exploreLatestPosts => 'Publicaciones recientes';

  @override
  String get exploreLatestEmptyTitle => 'Todavía no hay nada nuevo';

  @override
  String get exploreLatestEmptySubtitle =>
      'Aquí aparecen las publicaciones públicas más recientes de toda la red, actualizadas cada 10 minutos. Desliza hacia abajo para volver a revisar.';

  @override
  String get matureGateTitle => 'Contenido para adultos';

  @override
  String get matureGateBody =>
      'Este perfil tiene contenido para adultos. ¿Tienes 18 años o más y quieres continuar?';

  @override
  String get matureGateContinue => 'Tengo 18+, continuar';

  @override
  String get matureGateBack => 'Regresar';

  @override
  String get accountTagsSection => 'Etiquetas de la cuenta';

  @override
  String get accountTagMature => 'Contenido para adultos';

  @override
  String get accountTagMatureSub =>
      'Quien visite tu perfil confirma que tiene 18 años o más.';

  @override
  String get accountTagAutomated => 'Cuenta automatizada';

  @override
  String get accountTagAutomatedSub =>
      'Un programa maneja esta cuenta, no una persona. Tu avatar muestra un robot.';

  @override
  String get accountTagSaving => 'Guardando etiqueta…';

  @override
  String get errAccountTagFailed => 'No se pudo guardar la etiqueta.';

  @override
  String get settingsMatureProfilesTitle => 'Perfiles para adultos';

  @override
  String get settingsMatureProfilesEmpty =>
      'Aquí aparecen los perfiles a los que dijiste que sí (18+). Si quitas uno, te vuelve a preguntar la próxima vez.';

  @override
  String get settingsMatureProfilesRemove =>
      'Volver a preguntar en este perfil';

  @override
  String get linkTargetNotFound => 'No se encontró el destino del enlace';

  @override
  String get postSigMarkUnsigned => 'Sin firma';

  @override
  String get postSigMarkBad => 'Firma inválida';

  @override
  String get postSigMarkUnchecked => 'Firma sin comprobar';

  @override
  String get postSigTitleChecked => 'FIRMADA';

  @override
  String get postSigTitleUnsigned => 'SIN FIRMA';

  @override
  String get postSigTitleBad => 'FIRMA INVÁLIDA';

  @override
  String get postSigTitleUnchecked => 'SIN COMPROBAR';

  @override
  String get postSigThisPost => '(esta publicación)';

  @override
  String get postSigExplainChecked =>
      'Firmada. El autor firmó el texto y los medios con su llave, y este dispositivo comprobó que nada cambió desde entonces.';

  @override
  String get postSigExplainUnsigned =>
      'Sin firma. El autor decidió no firmar, así que solo el servidor responde por quién la escribió y qué decía.';

  @override
  String get postSigExplainBad =>
      'Firma inválida. La firma no coincide con el contenido o con quien firma. La publicación pudo alterarse después de firmarse.';

  @override
  String get postSigExplainUnchecked =>
      'Sin comprobar. La firma coincide con el contenido en este dispositivo, pero no se pudo consultar la cadena para confirmar de quién es la llave que firmó. Inténtalo más tarde.';

  @override
  String get postSigEncourage =>
      'Aquí lo normal es firmar: firma las tuyas para que cualquiera pueda comprobarlas.';

  @override
  String get postSigDialogClose => 'Entendido';

  @override
  String get postSrvMark => 'Servido desde fuera de la red PublicOS';

  @override
  String get postSrvTitle => 'DESDE EL INTERNET ABIERTO';

  @override
  String get postSrvExplainServer =>
      'Esta publicación viene de un servidor que sigue el protocolo de PublicOS por su cuenta, en el internet abierto. No es un proveedor registrado dentro de la red PublicOS, así que no puede enviarte notificaciones.';

  @override
  String get postSrvExplainUnsigned =>
      'Sin firma: quien la escribió es un usuario simple, no una cuenta PublicOS.';

  @override
  String get newKeyFlowAddDevice => 'AGREGAR ESTE DISPOSITIVO';

  @override
  String get newKeyFlowNewAccount => 'CUENTA NUEVA';

  @override
  String get newKeyFlowAddDeviceTitle => 'Agregar este dispositivo';

  @override
  String get newKeyFlowAddDeviceSubtitle =>
      '¿A qué cuenta se une este dispositivo? Escribe su nombre o la dirección de la cuenta.';

  @override
  String get newKeyFlowAccountLabel => 'Nombre o dirección de la cuenta';

  @override
  String get newKeyFlowAccountNotFound =>
      'No encontramos una cuenta con ese nombre.';

  @override
  String get newKeyFlowIsThisYou => '¿Es tu cuenta?';

  @override
  String get newKeyFlowNewAccountTitle => 'Cuenta nueva';

  @override
  String get newKeyFlowNewAccountSubtitle =>
      'Elige el nombre de usuario de tu nueva cuenta.';

  @override
  String newKeyFlowRuleLength(int min, int max) {
    return 'De $min a $max caracteres';
  }

  @override
  String get newKeyFlowRuleStart => 'Empieza con una letra';

  @override
  String get newKeyFlowRuleEnd => 'Termina con una letra o un número';

  @override
  String get newKeyFlowRuleChars => 'Solo letras, números, - y _';

  @override
  String get newKeyFlowRuleNoDoubles => 'Sin -- ni __';

  @override
  String get newKeyFlowRuleAvailable => 'Disponible';

  @override
  String get newKeyFlowFreeNote =>
      'Los ciudadanos tienen gratis los nombres de 5 caracteres o más.';

  @override
  String get newKeyFlowContinue => 'CONTINUAR';

  @override
  String get newKeyFlowCancel => 'CANCELAR';

  @override
  String get newKeyFlowWordsWarning =>
      'Una vez agregada o creada la cuenta, estas palabras te ayudarán a recuperarla. Escríbelas, guárdalas sin conexión y nunca las compartas.';

  @override
  String get newKeyFlowActivated => 'Tu llave quedó activada.';

  @override
  String get groupVotingViewWithdraw => 'RETIRAR';

  @override
  String get groupVotingViewVeto => 'VETAR';

  @override
  String get groupVotingViewWithdrawTitle => 'Retirar tu propuesta';

  @override
  String get groupVotingViewWithdrawBody =>
      'Termina ahora, con tu motivo en el registro.';

  @override
  String groupVotingViewWithdrawCooldown(Object time) {
    return 'Después no podrás proponer en esta organización durante $time.';
  }

  @override
  String get groupVotingViewVetoTitle => 'Vetar esta votación';

  @override
  String get groupVotingViewVetoBody =>
      'Como quien tiene el veto de la organización, terminas esta votación ahora. Tu motivo queda en el registro.';

  @override
  String get groupVotingViewCancelVoteTitle =>
      'Proponer cancelar esta votación';

  @override
  String groupVotingViewCancelVoteBody(Object name, Object id) {
    return 'Votación #$id de $name. La organización lo vota; si se aprueba, esa votación termina en ese momento, aunque la organización espere el periodo completo.';
  }

  @override
  String get groupVotingViewCancelReasonHint => 'Motivo (obligatorio)';

  @override
  String get groupVotingViewWithdrawn => 'Retirada';

  @override
  String get groupVotingViewVetoed => 'Vetada';

  @override
  String groupVotingViewCancelledBy(Object who, Object reason) {
    return 'Cancelada por $who: “$reason”';
  }

  @override
  String get groupVotingViewCancelKindProposer => 'quien la propuso';

  @override
  String get groupVotingViewCancelKindVetoer => 'quien tiene el veto';

  @override
  String get groupVotingViewCancelKindOrg => 'esta organización, por votación';

  @override
  String get groupVotingViewCancelKindAncestor =>
      'una organización superior, por votación';

  @override
  String get groupVotingViewVetoer => 'Veto';

  @override
  String get groupVotingViewVetoerSubtitle =>
      'Un miembro que puede cancelar por su cuenta las votaciones de la organización';

  @override
  String get groupVotingViewVetoerNone => 'Nadie';

  @override
  String get groupVotingViewVetoerAutoRun =>
      'Esta organización ejecuta una votación en cuanto se aprueba, así que quien tenga el veto casi nunca tendrá tiempo de actuar. Activa “esperar el periodo completo” para darle margen.';

  @override
  String get groupVotingViewCooldown => 'Espera tras retirar';

  @override
  String get groupVotingViewCooldownSubtitle =>
      'Cuánto espera un miembro para proponer de nuevo después de retirar su propia votación';

  @override
  String get groupVotingViewCooldownNone => 'Ninguna';

  @override
  String get groupVotingViewVetoerBody =>
      'Quien tiene el veto es un miembro que puede terminar por su cuenta, al momento, cualquier votación abierta de esta organización, dejando su motivo en el registro. Una votación que cambia quién tiene el veto no se puede vetar. Elegir aquí inicia una votación.';

  @override
  String get groupVotingViewCooldownBody =>
      'Cuando un miembro retira su propia votación abierta, no puede proponer en esta organización durante este tiempo. Un veto, o una cancelación por votación, no cuenta. Elegir aquí inicia una votación.';

  @override
  String get groupVotingViewMaxOpenBody =>
      'Cuántas propuestas puede tener abiertas esta organización al mismo tiempo. Cada miembro sigue pudiendo tener solo una propia abierta. Elegir aquí inicia una votación.';

  @override
  String groupVotingViewInCooldown(Object when) {
    return 'Retiraste una votación aquí. Podrás proponer de nuevo $when.';
  }

  @override
  String get groupVotingViewCancelAVote => 'Cancelar una votación';

  @override
  String get groupVotingViewCancelAVoteSubtitle =>
      'Proponer terminar una votación abierta aquí o en una organización hija';

  @override
  String get groupVotingViewDescSetVetoer => 'Dar el veto a';

  @override
  String get groupVotingViewDescClearVetoer => 'Quitar el veto';

  @override
  String groupVotingViewDescCancelVote(Object id) {
    return 'Cancelar la votación #$id';
  }

  @override
  String get cancelVoteSheetTitle => 'Cancelar una votación';

  @override
  String get cancelVoteSheetSubtitle =>
      'Votaciones abiertas en esta organización y en las que están debajo';

  @override
  String get cancelVoteSheetSearchHint => 'Buscar una organización por nombre';

  @override
  String get cancelVoteSheetChecking => 'Comprobando…';

  @override
  String cancelVoteSheetNotFound(Object name) {
    return 'No hay ninguna organización llamada $name';
  }

  @override
  String get cancelVoteSheetNotInTree =>
      'No está en el árbol de esta organización';

  @override
  String get cancelVoteSheetOpenVotes => 'VOTACIONES ABIERTAS';

  @override
  String get cancelVoteSheetChildren => 'ORGANIZACIONES HIJAS';

  @override
  String get cancelVoteSheetNoVotes => 'Sin votaciones abiertas';

  @override
  String get cancelVoteSheetNoChildren => 'Sin organizaciones hijas';

  @override
  String get cancelVoteSheetShowMore => 'Mostrar más';

  @override
  String get manageServerPageManageFiles => 'ADMINISTRAR ARCHIVOS';

  @override
  String get manageFilesPageTitle => 'Administrar archivos';

  @override
  String get manageFilesPageSearchHint => 'Buscar por nombre de archivo';

  @override
  String get manageFilesPageFilterAll => 'Todos';

  @override
  String get manageFilesPageFilterImages => 'Imágenes';

  @override
  String get manageFilesPageFilterVideos => 'Videos';

  @override
  String get manageFilesPageFilterAudio => 'Audio';

  @override
  String get manageFilesPageFilterOther => 'Otros';

  @override
  String get manageFilesPageFilterPublic => 'Públicos';

  @override
  String get manageFilesPageFilterPrivate => 'Privados';

  @override
  String get manageFilesPageSortNewest => 'Más recientes';

  @override
  String get manageFilesPageSortOldest => 'Más antiguos';

  @override
  String get manageFilesPageSortLargest => 'Más grandes';

  @override
  String get manageFilesPageSortSmallest => 'Más pequeños';

  @override
  String get manageFilesPageSortName => 'Nombre';

  @override
  String manageFilesPageShowing(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos',
      one: '1 archivo',
    );
    return '$_temp0 · $size';
  }

  @override
  String get manageFilesPageNoMatches => 'Ningún archivo coincide.';

  @override
  String get manageFilesPageLoadFailed => 'No se pudieron cargar tus archivos.';

  @override
  String get manageFilesPageSelect => 'Seleccionar';

  @override
  String get manageFilesPageSelectAll => 'Seleccionar todo';

  @override
  String manageFilesPageSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seleccionados',
      one: '1 seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get manageFilesPageDeleteManyTitle => 'Eliminar archivos';

  @override
  String manageFilesPageDeleteManyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Eliminar $count archivos?',
      one: '¿Eliminar 1 archivo?',
    );
    return '$_temp0 Esto libera tu cuota de medios y no se puede deshacer.';
  }

  @override
  String manageFilesPageDeleting(int done, int total) {
    return 'Eliminando $done de $total';
  }

  @override
  String manageFilesPageDeletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count archivos eliminados',
      one: '1 archivo eliminado',
    );
    return '$_temp0';
  }

  @override
  String manageFilesPageDeletedPartial(int deleted, int failed) {
    return '$deleted eliminados, $failed con error';
  }

  @override
  String get newAccountAskTitle =>
      'Las cuentas las crean ciudadanos, una a la vez';

  @override
  String get newAccountAskBody =>
      'Un ciudadano puede crear la tuya escaneando tu código. Si no conoces a ninguno, te ayudamos.';

  @override
  String get newAccountAskFriend => 'TENGO UN AMIGO CIUDADANO';

  @override
  String get newAccountAskHelp => 'NO TENGO UN AMIGO EN PUBLICOS';

  @override
  String get newAccountAskOpenFailed => 'No se pudo abrir la página.';

  @override
  String get importKeyLinkTitle => 'IMPORTAR CUENTA';

  @override
  String importKeyLinkBody(String name) {
    return 'Estás importando las llaves de $name.';
  }

  @override
  String get importKeyLinkBodyNoName =>
      'Estás importando las llaves de una cuenta.';

  @override
  String get importKeyLinkAccept => 'IMPORTAR';

  @override
  String get importKeyLinkPendingExists =>
      'Termina o elimina la llave pendiente primero.';

  @override
  String get importKeyLinkSignedIn => 'Cierra sesión para importar una cuenta.';

  @override
  String get desktopUpdateChip => 'Actualización disponible';

  @override
  String get desktopUpdateTitle => 'Actualizar PublicOS';

  @override
  String desktopUpdateBody(String version, int sizeMb) {
    return 'La versión $version está lista ($sizeMb MB). La app se cierra, se actualiza y se abre de nuevo. Tu cuenta y tus datos se quedan en esta PC.';
  }

  @override
  String get desktopUpdateChecked => 'Su firma se verificó en la cadena.';

  @override
  String get desktopUpdateNow => 'ACTUALIZAR Y REINICIAR';

  @override
  String get desktopUpdateLater => 'DESPUÉS';

  @override
  String desktopUpdateDownloading(int percent) {
    return 'Descargando… $percent%';
  }

  @override
  String get desktopUpdateInstalling => 'Instalando. La app se cerrará ahora.';

  @override
  String get desktopUpdateFailed =>
      'No se pudo instalar la actualización. No se cambió nada.';

  @override
  String get desktopUpdateNotHere =>
      'Esta copia de la app no puede actualizarse donde está instalada. Descarga la nueva versión.';

  @override
  String get desktopUpdateOpenPage => 'ABRIR LA PÁGINA DE DESCARGA';
}
