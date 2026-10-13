// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kazakh (`kk`).
class AppLocalizationsKk extends AppLocalizations {
  AppLocalizationsKk([String locale = 'kk']) : super(locale);

  @override
  String get appTitle => 'Explora';

  @override
  String get settingsTitle => 'Баптаулар';

  @override
  String get settingsProfile => 'Профиль';

  @override
  String get settingsPersonalData => 'Жеке деректер';

  @override
  String get settingsNotSpecified => 'Көрсетілмеген';

  @override
  String get settingsSecurity => 'Қауіпсіздік';

  @override
  String get settingsSosContacts => 'SOS контактілері';

  @override
  String get settingsEmergencyAlerts => 'Шұғыл хабарламалар';

  @override
  String settingsContactsCount(int count) {
    return '$count контакт';
  }

  @override
  String get settingsApp => 'Қосымша';

  @override
  String get settingsLanguage => 'Тіл';

  @override
  String get settingsTheme => 'Тақырып';

  @override
  String get settingsAbout => 'Қосымша туралы';

  @override
  String get settingsVersion => 'Нұсқа';

  @override
  String get settingsPrivacyLog => 'Құпиялық саясаты';

  @override
  String get settingsLogout => 'Шығу';

  @override
  String get settingsDeleteAccount => 'Аккаунтты жою';

  @override
  String get settingsThemeDark => 'Қараңғы тақырып';

  @override
  String get settingsThemeLight => 'Жарық тақырып';

  @override
  String get settingsThemeAuto => 'Авто';

  @override
  String get settingsSelectLanguage => 'Қосымша тілі';

  @override
  String get settingsApply => 'Қолдану';

  @override
  String get settingsThemeTitle => 'Безендіру тақырыбы';

  @override
  String get settingsThemeDarkDesc =>
      'Түнгі жорықтарға арналған қараңғы тақырып';

  @override
  String get settingsThemeLightDesc =>
      'Күндізгі пайдалануға арналған ашық тақырып';

  @override
  String get settingsThemeAutoDesc => 'Автоматты ауысу';

  @override
  String get settingsSosDeleteDesc =>
      'Төтенше жағдай сигналы іске қосылғанда осы контактілерге хабарланады';

  @override
  String get settingsAddContact => 'Контакт қосу';

  @override
  String get settingsDeleteAccountTitle => 'Аккаунтты жою';

  @override
  String get settingsDeleteAccountDesc =>
      'Аккаунтыңызды жойғыңыз келетініне сенімдісіз бе? Бұл әрекетті қайтару мүмкін емес, барлық деректеріңіз біржолата жойылады.';

  @override
  String get settingsCancel => 'Болдырмау';

  @override
  String get homeSearchHint => 'Қайда барамыз?';

  @override
  String get homeActiveTrips => 'Менің белсенді жорықтарым';

  @override
  String get homeActiveTripsTap => 'Маршрутты ашу үшін басыңыз';

  @override
  String get homeCreateRoute => 'Маршрут құру';

  @override
  String get homeCreateRouteDesc => 'ЖИ конструкторы арқылы';

  @override
  String get homeWhereTo => 'Кез келген жерге!';

  @override
  String get homeSmartSelection => 'Ақылды маршрут таңдау';

  @override
  String get homePopularRoutes => 'Танымал маршруттар';

  @override
  String get homeAll => 'Барлығы';

  @override
  String get homeProfileHintTitle => 'Профиль суреті және Альбом';

  @override
  String get homeProfileHintDesc =>
      'Сіз профиліңізге немесе альбомыңызға сурет қосу арқылы стиліңізді жаңартып, қымбат естеліктеріңізді сақтай аласыз.';

  @override
  String get homeProfileHintGotIt => 'Түсінікті';

  @override
  String homeDaysAbbr(int count) {
    return '$count к.';
  }

  @override
  String get authEnterPhone => 'Телефон нөмірін енгізіңіз';

  @override
  String get authEnterSmsCode => 'SMS кодын енгізіңіз';

  @override
  String get authFillEmailPassword => 'Email мен құпиясөзді енгізіңіз';

  @override
  String get authUnknownError => 'Белгісіз қате';

  @override
  String get authGoogleError => 'Google авторизациясының қатесі';

  @override
  String get authLoginTab => 'Кіру';

  @override
  String get authRegisterTab => 'Тіркелу';

  @override
  String get authPhoneTab => 'Телефон';

  @override
  String get authPhoneHint => 'Нөмір (+7...)';

  @override
  String get authSmsCodeHint => 'SMS код';

  @override
  String get authChangePhone => 'Нөмірді өзгерту';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Құпиясөз';

  @override
  String get authLoginButton => 'Кіру';

  @override
  String get authRegisterButton => 'Тіркелгі жасау';

  @override
  String get authConfirmButton => 'Растау';

  @override
  String get authGetSmsButton => 'SMS код алу';

  @override
  String get authForgotPassword => 'Құпиясөзді ұмыттыңыз ба?';

  @override
  String get authOrWith => 'Немесе келесі арқылы';

  @override
  String get authInDevelopment => 'Әзірлеу үстінде';

  @override
  String get authResetPasswordTitle => 'Құпиясөзді қалпына келтіру';

  @override
  String get authResetPasswordDesc =>
      'Email-ді енгізіңіз — біз құпиясөзді қалпына келтіру сілтемесін жібереміз.';

  @override
  String get authCancel => 'Болдырмау';

  @override
  String get authSend => 'Жіберу';

  @override
  String get authEmailSent => 'Хат жіберілді — поштаңызды тексеріңіз';

  @override
  String get authSendError => 'Жіберу қатесі';

  @override
  String get onboardingSlide1Title => 'Сіздің жолсерігіңіз';

  @override
  String get onboardingSlide1Desc =>
      'Жабайы жерлерді сеніммен зерттеңіз. Карталарымыз желісіз де жұмыс істейді.';

  @override
  String get onboardingSlide2Title => 'Бірегей маршруттар';

  @override
  String get onboardingSlide2Desc =>
      'Кәсіби гидтер мен қауымдастықтан мыңдаған тексерілген соқпақтар.';

  @override
  String get onboardingSlide3Title => 'Толық қолдау';

  @override
  String get onboardingSlide3Desc =>
      'Көлік, гидтер және сақтандыруды бір қолданбада брондаңыз.';

  @override
  String get onboardingStart => 'Саяхатты бастау';

  @override
  String get onboardingNext => 'Келесі';

  @override
  String get profileUpdatePhoto => 'Профиль суретін жаңарту';

  @override
  String get profileAddPhotoToAlbum => 'Альбомға сурет қосу';

  @override
  String get profileUserNotAuthorized => 'Пайдаланушы авторизациядан өтпеген';

  @override
  String get profileWalletBalance => 'Әмиян теңгерімі';

  @override
  String get profileMyOrders => 'Менің тапсырыстарым мен чаттарым';

  @override
  String get profileFavorites => 'Таңдаулылар';

  @override
  String get profileDocuments => 'Құжаттар';

  @override
  String get profileMyAlbum => 'Менің альбомым';

  @override
  String get profileNoPhotosYet => 'Әзірге мұнда суреттер жоқ';

  @override
  String get profileAddMemories => '+ түймесін басып естеліктер қосыңыз';

  @override
  String get profileLogout => 'Шығу';

  @override
  String get docsInsurancePolicy => 'Сақтандыру полисі';

  @override
  String get docsInsurancePolicyDesc => '№ 89320-YDX • 25.09 дейін белсенді';

  @override
  String get docsPassport => 'Паспорт';

  @override
  String get docsPassportDesc => '**** 4512 • Иванов Д.А.';

  @override
  String get docsTourVoucher => 'Тур ваучері';

  @override
  String get docsTourVoucherDesc => 'Алтай • 24 Қыркүйек';

  @override
  String get favoritesTabRoutes => 'Маршруттар';

  @override
  String get favoritesTabGuides => 'Гидтер';

  @override
  String get favoritesTabCars => 'Көліктер';

  @override
  String get authRequired => 'Авторизация қажет';

  @override
  String get userLoadError => 'Пайдаланушыны жүктеу қатесі';

  @override
  String get favoritesNoRoutes => 'Таңдаулы маршруттар жоқ';

  @override
  String get favoritesNoGuides => 'Таңдаулы гидтер жоқ';

  @override
  String get favoritesNoCars => 'Таңдаулы көліктер жоқ';

  @override
  String get difficultyEasy => 'Оңай';

  @override
  String get difficultyModerate => 'Орташа';

  @override
  String get difficultyHard => 'Қиын';

  @override
  String get difficultyExpert => 'Сарапшы';

  @override
  String get activeTripMessenger => 'Мессенджер';

  @override
  String get homeRouteConstructor => 'Маршрут конструкторы';

  @override
  String get homeCurrentTrip => 'Ағымдағы маршрут';

  @override
  String get homeStatusInProgress => 'Жолда';

  @override
  String get homeStatusWaiting => 'Жүргізушіні күтуде';

  @override
  String get homeStatusBooked => 'Брондалған';

  @override
  String get homeArrivalPrefix => 'Келу уақыты: ';

  @override
  String get homeChat => 'Чат';

  @override
  String get homeMessenger => 'Мессенджер';

  @override
  String get homeErrorPrefix => 'Қате: ';

  @override
  String get homeNoRoutesAvailable => 'Қолжетімді маршруттар жоқ';

  @override
  String get homeUnderstand => 'Түсінікті';

  @override
  String get activeTripsTitle => 'Ағымдағы маршруттар';

  @override
  String errorMessage(String message) {
    return 'Қате: $message';
  }

  @override
  String get noActiveTrips => 'Сізде белсенді сапарлар жоқ';

  @override
  String routeNumLabel(String num) {
    return 'Маршрут $num';
  }

  @override
  String get statusWaitingDriver => 'Жүргізушіні күту';

  @override
  String get statusOnWay => 'Жолда';

  @override
  String get actionRename => 'Атауын өзгерту';

  @override
  String get actionMoreInfo => 'Қосымша ақпарат';

  @override
  String get actionCancelRoute => 'Маршрутты болдырмау';

  @override
  String get hintRenameRoute => 'Мысалы: Тауға сапар';

  @override
  String get errorEnterName => 'Атауды енгізіңіз';

  @override
  String get actionCancel => 'Болдырмау';

  @override
  String get actionSave => 'Сақтау';

  @override
  String get dialogCancelRouteTitle => 'Маршрутты болдырмау';

  @override
  String get dialogCancelRouteDesc =>
      'Бұл маршрутты болдырмауға сенімдісіз бе? Ақшаны қайтару болдырмау ережелеріне сәйкес жасалады.';

  @override
  String get actionDoNotCancel => 'Болдырмау емес';

  @override
  String get actionYesCancel => 'Иә, болдырмау';

  @override
  String get msgRouteCancelled => 'Маршрут болдырмай тасталды';

  @override
  String errorCancelRoute(String message) {
    return 'Болдырмау қатесі: $message';
  }

  @override
  String get waypointStart => 'Бастау';

  @override
  String get waypointEnd => 'Аяқтау';

  @override
  String get reviewsCount => 'пікір';

  @override
  String get bookTourAction => 'Турға тапсырыс беру';

  @override
  String get bookingDetailsTitle => 'Сапар туралы мәліметтер';

  @override
  String get routeNameLabelOptional => 'Бағыт атауы (міндетті емес)';

  @override
  String get routeDatesLabel => 'Бағыт күндері';

  @override
  String get peopleCountLabel => 'Адам саны';

  @override
  String get transportOptionalLabel => 'Көлік';

  @override
  String get selectTransportLabel => 'Көлікті таңдаңыз';

  @override
  String get roadTypeConditionsLabel => 'Жол түрі және шарттары';

  @override
  String get guideOptionalLabel => 'Гид';

  @override
  String get selectGuideLabel => 'Гидті таңдаңыз';

  @override
  String get additionalLabel => 'Қосымша';

  @override
  String get bookAction => 'Брондау';

  @override
  String get calculationDetailsTitle => 'Есептеу мәліметтері';

  @override
  String get errorUserNotFound => 'Қате: пайдаланушы табылмады.';

  @override
  String get errorActiveTripExists =>
      'Сізде белсенді бағыт бар. Жаңасын жасамас бұрын оны аяқтаңыз.';

  @override
  String get errorSelectVehicle => 'Көлікті (жүргізушіні) таңдаңыз.';

  @override
  String get roadTypeAsphalt => 'Асфальт';

  @override
  String get roadTypeGravel => 'Қиыршық тас/Топырақ';

  @override
  String get roadTypeOffroad => 'Қатты Offroad';

  @override
  String get nightTripLabel => 'Түнгі сапар';

  @override
  String get nightTripDesc => 'Сапар тәуліктің қараңғы уақытын қамтиды';

  @override
  String get hintRouteNameExample =>
      'Атауын ойлап табыңыз (мысалы: Тауға сапар)';

  @override
  String waypointStop(int index) {
    return 'Аялдама $index';
  }

  @override
  String get actionChange => 'Өзгерту';

  @override
  String maxPeopleLimit(int limit) {
    return 'Осы көлік/гид үшін ең көбі: $limit адам';
  }

  @override
  String get guideServiceDesc => 'Қызықты фактілер үшін';

  @override
  String get driverServiceDesc => 'Жүргізушімен бірге';

  @override
  String get noDriversAvailable =>
      'Таңдалған көлік түрі үшін жүргізушілер жоқ.';

  @override
  String get noGuidesAvailable => 'Таңдалған түр үшін гидтер жоқ.';

  @override
  String seatsAvailable(int total, int tourists) {
    return 'Орындар: $total (туристер үшін $tourists)';
  }

  @override
  String get currencyPerKm => '₸/км';

  @override
  String get currencyPerDay => '₸/күн';

  @override
  String receiptVehicle(String vType, int days) {
    return '🚙 $vType, $days күн';
  }

  @override
  String receiptGuide(int days) {
    return '🗣 Гид қызметтері, $days күн';
  }

  @override
  String receiptEcoTax(int people) {
    return '🌲 Эко жинақтар ($people адам + авто)';
  }

  @override
  String receiptInsurance(int people) {
    return '🛡 Тау сақтандыруы ($people адам)';
  }

  @override
  String get receiptTotal => 'Барлығы';

  @override
  String get priceIncludesServiceFee =>
      '*Бағаға платформаның қызмет ақысы кіреді';

  @override
  String get insuranceTitle => 'Таулы / Offroad сақтандыру';

  @override
  String get insuranceDesc => 'Белсенді туризм үшін тәуекелдерді жабу';

  @override
  String get vehicleSuv => 'Жол талғамайтын көлік';

  @override
  String get vehicleBus => 'Автобус';

  @override
  String get vehicleMinibus => 'Микроавтобус';

  @override
  String get vehicleMinivan => 'Минивэн';

  @override
  String get vehicleDefault => 'Көлік';

  @override
  String get month1 => 'Қаңтар';

  @override
  String get month2 => 'Ақпан';

  @override
  String get month3 => 'Наурыз';

  @override
  String get month4 => 'Сәуір';

  @override
  String get month5 => 'Мамыр';

  @override
  String get month6 => 'Маусым';

  @override
  String get month7 => 'Шілде';

  @override
  String get month8 => 'Тамыз';

  @override
  String get month9 => 'Қыркүйек';

  @override
  String get month10 => 'Қазан';

  @override
  String get month11 => 'Қараша';

  @override
  String get month12 => 'Желтоқсан';

  @override
  String get weekday1 => 'Дүйсенбі';

  @override
  String get weekday2 => 'Сейсенбі';

  @override
  String get weekday3 => 'Сәрсенбі';

  @override
  String get weekday4 => 'Бейсенбі';

  @override
  String get weekday5 => 'Жұма';

  @override
  String get weekday6 => 'Сенбі';

  @override
  String get weekday7 => 'Жексенбі';

  @override
  String get sosEmergencyMode => 'ТӨТЕНШЕ ЖАҒДАЙ';

  @override
  String get sosGuideToggle => 'Топ гидіне';

  @override
  String get sosDriverToggle => 'Жүргізушіге';

  @override
  String get sosRescueServiceToggle => 'Құтқару қызметі';

  @override
  String get sosCurrentCoordinates => 'АҒЫМДАҒЫ КООРДИНАТАЛАР';

  @override
  String get sosSignalSent => 'Сигнал жіберілді';

  @override
  String get sosCoordinatesTransmitted =>
      'Координаталар құтқарушыларға берілді';

  @override
  String get sosButtonText => 'SOS';

  @override
  String get sosHoldAction => 'ҰСТАП ТҰРУ';

  @override
  String get sosHoldInstruction =>
      'Сигнал жіберу үшін түймені\n3 секунд ұстап тұрыңыз';

  @override
  String get walkieNameTourist => 'Турист';

  @override
  String get walkieNameParticipant => 'Қатысушы';

  @override
  String walkieErrorStartWave(String error) {
    return 'WAVE іске қосу қатесі: $error';
  }

  @override
  String get walkiePingSent =>
      'Пинг жіберілді! Қатысушылар орналасуымен бөліседі.';

  @override
  String get walkieSubtitle => 'Дербес желі';

  @override
  String get walkieInvitePrompt => 'Туристерді сол сапарға шақырыңыз.';

  @override
  String get walkiePingButton => 'Пинг';

  @override
  String walkieNetworkActive(int count) {
    return '● WAVE желісі белсенді · $count қатысушы';
  }

  @override
  String get walkieNetworkActiveBT => ' · 🔵 BT';

  @override
  String get walkieNetworkActiveFirebase => ' · ☁️ Firebase';

  @override
  String get walkieNetworkInactive => '⚠ WAVE желісі белсенді емес';

  @override
  String get walkieTabChat => 'Чат';

  @override
  String get walkieTabMembers => 'Қатысушылар';

  @override
  String get walkieTabMap => 'Карта';

  @override
  String get walkieEmptyChatTitle => 'Хабарламалар жоқ';

  @override
  String get walkieEmptyChatDesc => 'Топқа алғашқы дербес хабарлама жіберіңіз';

  @override
  String walkieSharedLocation(String userName) {
    return '📍 $userName орналасуымен бөлісті';
  }

  @override
  String get walkieMessageHint => 'Хабарлама (дербес)';

  @override
  String get walkieEmptyMembersTitle => 'Қатысушылар жоқ';

  @override
  String get walkieEmptyMembersDesc =>
      'Басқа туристер WAVE ашқанда, олар осында пайда болады';

  @override
  String get walkieUnknownUser => 'Белгісіз';

  @override
  String get walkieStatusOnline => 'желіде';

  @override
  String get myOrdersAndChats => 'Менің тапсырыстарым мен чаттарым';

  @override
  String myOrdersLoadError(String error) {
    return 'Жүктеу қатесі: $error';
  }

  @override
  String get myOrdersNoSavedChats => 'Сақталған чаттар жоқ';

  @override
  String get myOrdersNoSavedChatsDesc =>
      'Мұнда сіздің белсенді хат-хабарларыңыз пайда болады';

  @override
  String get myOrdersChatUnavailable =>
      'Чат қолжетімсіз немесе маршрут баяғыда аяқталған';

  @override
  String get myOrdersDeleteChatTitle => 'Чатты жою керек пе?';

  @override
  String get myOrdersDeleteChatDesc =>
      'Бұл чат сақталғандардан жоғалады, бірақ басқа қатысушыларда қалады.';

  @override
  String get myOrdersDeleteChatCancel => 'Болдырмау';

  @override
  String get myOrdersDeleteChatConfirm => 'Жою';

  @override
  String get myOrdersNoOrders => 'Әзірге тапсырыстар жоқ';

  @override
  String get myOrdersNoOrdersDesc =>
      'Конструктордан маршрутқа тапсырыс беріңіз';

  @override
  String get myOrdersCreateRoute => 'Маршрут құру';

  @override
  String get myOrdersTabUpcoming => 'Алдағы';

  @override
  String get myOrdersTabPast => 'Аяқталған';

  @override
  String get myOrdersTabChats => 'Чаттар';

  @override
  String get bookingStatusPending => 'Қаралуда';

  @override
  String get bookingStatusConfirmed => 'Расталды';

  @override
  String get bookingStatusInProgress => 'Орындалуда';

  @override
  String get bookingStatusCompleted => 'Аяқталды';

  @override
  String get bookingStatusCancelled => 'Болдырмай тасталды';

  @override
  String get myOrdersRepeatRoute => 'Маршрутты қайталау';

  @override
  String get myOrdersDetailStartDate => 'Басталу күні';

  @override
  String get myOrdersDetailParticipants => 'Қатысушылар';

  @override
  String myOrdersDetailParticipantsCount(int count) {
    return '$count адам';
  }

  @override
  String get myOrdersDetailPrice => 'Бағасы';

  @override
  String get myOrdersDetailGuide => 'Гид';

  @override
  String get myOrdersDetailDriver => 'Жүргізуші';

  @override
  String get myOrdersDetailAssigned => 'Тағайындалды';

  @override
  String get myOrdersOpenRoute => 'Маршрутты ашу';

  @override
  String get tripCompletedShareSuccess => 'Маршрут енді танымалдар қатарында!';

  @override
  String get tripCompletedTitle => 'Маршрут аяқталды!';

  @override
  String get tripCompletedSubtitle => 'Сәтті жорықпен құттықтаймыз!';

  @override
  String get tripCompletedStatsTitle => 'Маршрут статистикасы';

  @override
  String get tripCompletedStatDistance => 'Қашықтық';

  @override
  String get tripCompletedStatTime => 'Жолдағы уақыт';

  @override
  String get tripCompletedStatMaxHeight => 'Макс. биіктік';

  @override
  String get tripCompletedStatAvgSpeed => 'Орташа жылдамдық';

  @override
  String get tripCompletedAddToFavorites => 'Таңдаулыға қосу';

  @override
  String get tripCompletedFavRoute => 'Маршрут';

  @override
  String get tripCompletedFavGuide => 'Гид';

  @override
  String get tripCompletedFavDriver => 'Жүргізуші';

  @override
  String get tripCompletedShareAction => 'Маршрутпен бөлісу';

  @override
  String get tripCompletedViewOrdersAction => 'Тапсырыстардан көру';

  @override
  String get tripCompletedHomeAction => 'Басты бетке';

  @override
  String messengerSendError(String error) {
    return 'Жіберу қатесі: $error';
  }

  @override
  String get messengerNoActiveRoute => 'Белсенді маршрут жоқ';

  @override
  String get messengerNoActiveRouteDesc =>
      'Чат тек белсенді сапар\nкезінде ғана қолжетімді';

  @override
  String get messengerLoadError => 'Чатты жүктеу қатесі';

  @override
  String get messengerNoMessages => 'Хабарламалар жоқ. Бірінші болып жазыңыз!';

  @override
  String get messengerRouteNotFound => 'Маршрут табылмады';

  @override
  String get messengerBookingNotFound => 'Брондау табылмады';

  @override
  String get messengerParticipantsTitle => 'Қатысушылар';

  @override
  String get messengerRoleOrganizer => 'Ұйымдастырушы';

  @override
  String get messengerRoleGuide => 'Тау гиді';

  @override
  String get messengerRoleDriver => 'Жүргізуші';

  @override
  String messengerParticipantsLoadError(String error) {
    return 'Қатысушыларды жүктеу қатесі: $error';
  }

  @override
  String get messengerChatSubtitle => 'Маршрут бойынша чат';

  @override
  String get messengerDeleteChatUnavailable => 'Чатты өшіру әзірге қолжетімсіз';

  @override
  String get messengerViewParticipants => 'Қатысушыларды көру';

  @override
  String get messengerDeleteChat => 'Чатты өшіру';

  @override
  String get messengerInputHint => 'Хабарлама енгізіңіз...';

  @override
  String get activeTripStageScheduled => 'Брондалған';

  @override
  String get activeTripStageWaiting => 'Жүргізуші келе жатыр';

  @override
  String get activeTripStageInProgress => 'Жолда';

  @override
  String get activeTripStageCompleted => 'Аяқталды';

  @override
  String get activeTripLocationPermError =>
      'Геолокацияға рұқсат жоқ. Параметрлерде рұқсат беріңіз.';

  @override
  String activeTripProximityError(String dist) {
    return 'Сіз жиналу нүктесінен $dist м қашықтықтасыз. Маршрутты бастау үшін 100 м жақындау қажет.';
  }

  @override
  String get activeTripDriver => 'Жүргізуші';

  @override
  String get activeTripGuide => 'Гид';

  @override
  String activeTripWaitingForOthers(String missing) {
    return 'Күтуде: $missing жиналу нүктесінде емес (≤ 100 м).';
  }

  @override
  String get activeTripSaveErrorQuota =>
      'Сақтау қатесі — Firestore квотасы асып кетті.\nСәл күте тұрыңыз да, қайта көріңіз.';

  @override
  String get activeTripNotFound => 'Маршрут табылмады';

  @override
  String get activeTripDefaultTitle => 'Маршрут';

  @override
  String activeTripEta(String time) {
    return 'Келуі: $time';
  }

  @override
  String get activeTripDriverCompleted => 'Жүргізуші маршрутты аяқтады';

  @override
  String get activeTripConfirmCompletionDesc =>
      'Сапарды аяқтап, төлемді растау үшін растаңыз';

  @override
  String get activeTripConfirming => 'Растаудамыз...';

  @override
  String get activeTripConfirmCompletionBtn => 'Аяқтауды растау';

  @override
  String get activeTripChatDefaultTitle => 'Чат';

  @override
  String get activeTripGoToChat => 'Чатқа өту';

  @override
  String activeTripConfirmError(String error) {
    return 'Растау қатесі: $error';
  }

  @override
  String get activeTripCancelTitle => 'Маршрутты болдырмау?';

  @override
  String get activeTripCancelDesc =>
      'Маршрут күні өтті. Брондауды болдырмағыңыз келе ме?';

  @override
  String get activeTripCancelNo => 'Жоқ';

  @override
  String get activeTripCancelYes => 'Иә, болдырмау';

  @override
  String get activeTripBookingDetails => 'Брондау бөлшектері';

  @override
  String get activeTripBookingDates => 'Күндері';

  @override
  String get activeTripBookingParticipants => 'Қатысушылар';

  @override
  String activeTripBookingParticipantsCount(int count) {
    return '$count адам';
  }

  @override
  String get activeTripBookingTotal => 'Төленуі тиіс';

  @override
  String get activeTripDatePassed => 'Маршрут күні өтті';

  @override
  String get activeTripCancelAction => 'Маршрутты болдырмау';

  @override
  String activeTripTimeLeftDaysHours(int days, int hours) {
    return '$days к. $hours с. қалды';
  }

  @override
  String activeTripTimeLeftHours(int hours) {
    return '$hours с. қалды';
  }

  @override
  String get activeTripStartingSoon => 'Жақында басталады!';

  @override
  String get activeTripGroupGathering => 'Жүргізуші мен топ жиналуда';

  @override
  String get activeTripActionReady => 'Дайындықты растау';

  @override
  String get activeTripActionStart => 'Маршрутты бастау';

  @override
  String get activeTripActionEnd => 'Маршрутты аяқтау';

  @override
  String get rbStepPoints => 'Нүктелер';

  @override
  String get rbStepRoute => 'Маршрут';

  @override
  String get rbStepDetails => 'Мәліметтер';

  @override
  String get rbTooltipBack => 'Маршрут жасауды болдырмау';

  @override
  String get rbTooltipMyLocation => 'Менің орналасқан жерім';

  @override
  String get rbPanelWaypointsTitle => 'Маршрут нүктелері';

  @override
  String get rbPanelTapHint => 'Нүкте қосу үшін картаға басыңыз';

  @override
  String get rbPanelMyLocationStart => 'Менің орным бастапқы нүкте ретінде';

  @override
  String get rbPanelMaxPoints => 'Максимум 10 нүкте';

  @override
  String get rbTooltipUndo => 'Соңғы нүктені жою';

  @override
  String get rbTooltipClear => 'Барлық нүктелерді тазалау';

  @override
  String get rbBuildRoute => 'Маршрут құру';

  @override
  String get rbLoadingTitle => 'Маршрут құрылуда…';

  @override
  String get rbLoadingSubtitle => 'Яндекс Карта деректері сұралуда';

  @override
  String get rbStatDistance => 'Қашықтық';

  @override
  String rbStatDistanceKm(Object km) {
    return '$km км';
  }

  @override
  String get rbStatTime => 'Уақыт';

  @override
  String get rbStatTimeLessHour => '< 1 с';

  @override
  String rbStatTimeHours(Object h) {
    return '$h с';
  }

  @override
  String get rbStatByRoad => 'Жол бойынша';

  @override
  String get rbStatStraightLine => 'Тік сызықпен';

  @override
  String get rbStatYandex => 'Яндекс';

  @override
  String get rbStatEstimate => 'Бағалау';

  @override
  String get rbReset => 'Қайта бастау';

  @override
  String get rbContinue => 'Жалғастыру';

  @override
  String get rbWaypointStart => 'Басы';

  @override
  String get rbWaypointFinish => 'Соңы';

  @override
  String rbWaypointMid(int n) {
    return 'Аялдама $n';
  }

  @override
  String get rbMyLocationLabel => 'Менің орным';

  @override
  String get rbDefaultRouteTitle => 'Менің маршрутым';

  @override
  String get rbErrorFallback =>
      'Жол маршруты қолжетімді емес — тіке қашықтық көрсетілуде';

  @override
  String get rbErrorBuild => 'Маршрут құру кезінде қате';

  @override
  String get settingsLoading => 'Жүктелуде...';

  @override
  String get settingsFieldFirstName => 'Аты';

  @override
  String get settingsFieldLastName => 'Тегі';

  @override
  String get settingsFieldEmail => 'Email';

  @override
  String get settingsFieldPhone => 'Телефон';

  @override
  String get settingsFieldBirthDate => 'Туған күн';

  @override
  String get settingsSaveChanges => 'Өзгерістерді сақтау';

  @override
  String get settingsDataSaved => 'Деректер сақталды';

  @override
  String get settingsApplyButton => 'Қолдану';

  @override
  String get settingsDeleteButton => 'Жою';

  @override
  String get roleMountainGuide => 'Тау гиді';

  @override
  String get roleCityGuide => 'Қалалық экскурсовод';

  @override
  String get roleSuvDriver => 'Жол талғамайтын көлік жүргізушісі';

  @override
  String get roleBusDriver => 'Автобус жүргізушісі';

  @override
  String get roleMinibusDriver => 'Микроавтобус жүргізушісі';

  @override
  String get roleMinivanDriver => 'Минивэн жүргізушісі';

  @override
  String partnerProfileReviews(int count) {
    return '($count пікір)';
  }

  @override
  String get partnerProfileAboutMe => 'Өзім туралы';

  @override
  String get partnerProfileCarDetails => 'Көлік мәліметтері';

  @override
  String get partnerProfileVehicleModel => 'Үлгісі';

  @override
  String get partnerProfileVehicleClass => 'Класы';

  @override
  String get partnerProfileVehicleCapacity => 'Сыйымдылығы';

  @override
  String partnerProfileVehicleCapacityValue(int count) {
    return '$count адам (жүргізушіні қоса)';
  }

  @override
  String get partnerProfileRate => 'Ставка';

  @override
  String partnerProfileRatePerKm(int amount) {
    return '$amount ₸ / км';
  }

  @override
  String partnerProfileRatePerDay(int amount) {
    return '$amount ₸ / күн';
  }

  @override
  String get partnerProfileSpecialization => 'Мамандануы';

  @override
  String get partnerProfileExperience => 'Жұмыс тәжірибесі';

  @override
  String partnerProfileExperienceYears(int count) {
    return '$count жыл';
  }

  @override
  String get partnerProfileLanguages => 'Тілдер';

  @override
  String get partnerProfileDestinations => 'Бағыттар';

  @override
  String get settingsRelationWife => 'Жұбайы';

  @override
  String get settingsRelationHusband => 'Күйеуі';

  @override
  String get settingsRelationFriend => 'Дос';

  @override
  String get settingsRelationEmergency => 'Құтқару қызметі';
}
