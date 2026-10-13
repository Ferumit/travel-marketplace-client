// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Explora';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsProfile => 'Профиль';

  @override
  String get settingsPersonalData => 'Личные данные';

  @override
  String get settingsNotSpecified => 'Не указано';

  @override
  String get settingsSecurity => 'Безопасность';

  @override
  String get settingsSosContacts => 'SOS контакты';

  @override
  String get settingsEmergencyAlerts => 'Экстренные уведомления';

  @override
  String settingsContactsCount(int count) {
    return '$count контакта';
  }

  @override
  String get settingsApp => 'Приложение';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsVersion => 'Версия';

  @override
  String get settingsPrivacyLog => 'Политика конфиденциальности';

  @override
  String get settingsLogout => 'Выйти из аккаунта';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get settingsThemeDark => 'Тёмная тема';

  @override
  String get settingsThemeLight => 'Светлая тема';

  @override
  String get settingsThemeAuto => 'Авто';

  @override
  String get settingsSelectLanguage => 'Язык приложения';

  @override
  String get settingsApply => 'Применить';

  @override
  String get settingsThemeTitle => 'Тема оформления';

  @override
  String get settingsThemeDarkDesc => 'Тёмная тема для ночных походов';

  @override
  String get settingsThemeLightDesc =>
      'Светлая тема для дневного использования';

  @override
  String get settingsThemeAutoDesc => 'Автоматическое переключение';

  @override
  String get settingsSosDeleteDesc =>
      'Эти контакты будут уведомлены при активации экстренного сигнала';

  @override
  String get settingsAddContact => 'Добавить контакт';

  @override
  String get settingsDeleteAccountTitle => 'Удалить аккаунт';

  @override
  String get settingsDeleteAccountDesc =>
      'Вы уверены, что хотите удалить свой аккаунт? Это действие необратимо, и все ваши данные будут потеряны навсегда.';

  @override
  String get settingsCancel => 'Отмена';

  @override
  String get homeSearchHint => 'Куда отправимся?';

  @override
  String get homeActiveTrips => 'Мои Активные Походы';

  @override
  String get homeActiveTripsTap => 'Нажмите чтобы открыть маршрут';

  @override
  String get homeCreateRoute => 'Создать Маршрут';

  @override
  String get homeCreateRouteDesc => 'Через ИИ Конструктор';

  @override
  String get homeWhereTo => 'Куда угодно!';

  @override
  String get homeSmartSelection => 'Умный подбор маршрута';

  @override
  String get homePopularRoutes => 'Популярные Маршруты';

  @override
  String get homeAll => 'Все';

  @override
  String get homeProfileHintTitle => 'Фото профиля и Альбом';

  @override
  String get homeProfileHintDesc =>
      'Вы можете обновить свой стиль и сохранить дорогие вам воспоминания добавив фото в альбом или на фото профиля.';

  @override
  String get homeProfileHintGotIt => 'Понятно';

  @override
  String homeDaysAbbr(int count) {
    return '$count д.';
  }

  @override
  String get authEnterPhone => 'Введите номер телефона';

  @override
  String get authEnterSmsCode => 'Введите код из SMS';

  @override
  String get authFillEmailPassword => 'Заполните email и пароль';

  @override
  String get authUnknownError => 'Неизвестная ошибка';

  @override
  String get authGoogleError => 'Ошибка авторизации Google';

  @override
  String get authLoginTab => 'Вход';

  @override
  String get authRegisterTab => 'Регистрация';

  @override
  String get authPhoneTab => 'Телефон';

  @override
  String get authPhoneHint => 'Номер (+7...)';

  @override
  String get authSmsCodeHint => 'Код из SMS';

  @override
  String get authChangePhone => 'Изменить номер';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Пароль';

  @override
  String get authLoginButton => 'Войти';

  @override
  String get authRegisterButton => 'Создать аккаунт';

  @override
  String get authConfirmButton => 'Подтвердить';

  @override
  String get authGetSmsButton => 'Получить SMS-код';

  @override
  String get authForgotPassword => 'Забыли пароль?';

  @override
  String get authOrWith => 'Или с помощью';

  @override
  String get authInDevelopment => 'В разработке';

  @override
  String get authResetPasswordTitle => 'Сброс пароля';

  @override
  String get authResetPasswordDesc =>
      'Введите ваш email — мы отправим ссылку для сброса пароля.';

  @override
  String get authCancel => 'Отмена';

  @override
  String get authSend => 'Отправить';

  @override
  String get authEmailSent => 'Письмо отправлено — проверьте почту';

  @override
  String get authSendError => 'Ошибка отправки';

  @override
  String get onboardingSlide1Title => 'Ваш проводник';

  @override
  String get onboardingSlide1Desc =>
      'Исследуйте дикие места с уверенностью. Наши карты работают там, где нет сети.';

  @override
  String get onboardingSlide2Title => 'Уникальные маршруты';

  @override
  String get onboardingSlide2Desc =>
      'Тысячи проверенных троп от профессиональных гидов и сообщества.';

  @override
  String get onboardingSlide3Title => 'Полная поддержка';

  @override
  String get onboardingSlide3Desc =>
      'Бронируйте транспорт, гидов и страховку в одном приложении.';

  @override
  String get onboardingStart => 'Начать путешествие';

  @override
  String get onboardingNext => 'Далее';

  @override
  String get profileUpdatePhoto => 'Обновить фото профиля';

  @override
  String get profileAddPhotoToAlbum => 'Добавить фото в альбом';

  @override
  String get profileUserNotAuthorized => 'Пользователь не авторизован';

  @override
  String get profileWalletBalance => 'Баланс кошелька';

  @override
  String get profileMyOrders => 'Мои заказы и чаты';

  @override
  String get profileFavorites => 'Избранное';

  @override
  String get profileDocuments => 'Документы';

  @override
  String get profileMyAlbum => 'Мой альбом';

  @override
  String get profileNoPhotosYet => 'Здесь пока нет фотографий';

  @override
  String get profileAddMemories => 'Добавьте воспоминания нажав на +';

  @override
  String get profileLogout => 'Выйти';

  @override
  String get docsInsurancePolicy => 'Страховой полис';

  @override
  String get docsInsurancePolicyDesc => '№ 89320-YDX • Активен до 25.09';

  @override
  String get docsPassport => 'Удостоверение личности / Паспорт';

  @override
  String get docsPassportDesc => '**** 4512 • Иванов Д.А.';

  @override
  String get docsTourVoucher => 'Ваучер на тур';

  @override
  String get docsTourVoucherDesc => 'Алтай • 24 Сентября';

  @override
  String get favoritesTabRoutes => 'Маршруты';

  @override
  String get favoritesTabGuides => 'Гиды';

  @override
  String get favoritesTabCars => 'Авто';

  @override
  String get authRequired => 'Требуется авторизация';

  @override
  String get userLoadError => 'Ошибка загрузки пользователя';

  @override
  String get favoritesNoRoutes => 'Нет избранных маршрутов';

  @override
  String get favoritesNoGuides => 'Нет избранных гидов';

  @override
  String get favoritesNoCars => 'Нет избранных авто';

  @override
  String get difficultyEasy => 'Лёгкий';

  @override
  String get difficultyModerate => 'Средний';

  @override
  String get difficultyHard => 'Сложный';

  @override
  String get difficultyExpert => 'Экспертный';

  @override
  String get activeTripMessenger => 'Мессенджер';

  @override
  String get homeRouteConstructor => 'Конструктор маршрута';

  @override
  String get homeCurrentTrip => 'Текущий маршрут';

  @override
  String get homeStatusInProgress => 'В пути';

  @override
  String get homeStatusWaiting => 'Ждём водителя';

  @override
  String get homeStatusBooked => 'Забронировано';

  @override
  String get homeArrivalPrefix => 'Прибытие: ';

  @override
  String get homeChat => 'Чат';

  @override
  String get homeMessenger => 'Мессенджер';

  @override
  String get homeErrorPrefix => 'Ошибка: ';

  @override
  String get homeNoRoutesAvailable => 'Нет доступных маршрутов';

  @override
  String get homeUnderstand => 'Понятно';

  @override
  String get activeTripsTitle => 'Текущие маршруты';

  @override
  String errorMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get noActiveTrips => 'У вас нет активных поездок';

  @override
  String routeNumLabel(String num) {
    return 'Маршрут $num';
  }

  @override
  String get statusWaitingDriver => 'Ожидание водителя';

  @override
  String get statusOnWay => 'В пути';

  @override
  String get actionRename => 'Изменить название';

  @override
  String get actionMoreInfo => 'Доп. информация';

  @override
  String get actionCancelRoute => 'Отменить маршрут';

  @override
  String get hintRenameRoute => 'Например: Поездка в горы';

  @override
  String get errorEnterName => 'Введите название';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get dialogCancelRouteTitle => 'Отмена маршрута';

  @override
  String get dialogCancelRouteDesc =>
      'Вы уверены, что хотите отменить этот маршрут? Возврат средств будет произведен согласно правилам отмены.';

  @override
  String get actionDoNotCancel => 'Не отменять';

  @override
  String get actionYesCancel => 'Да, отменить';

  @override
  String get msgRouteCancelled => 'Маршрут отменен';

  @override
  String errorCancelRoute(String message) {
    return 'Ошибка при отмене: $message';
  }

  @override
  String get waypointStart => 'Начало';

  @override
  String get waypointEnd => 'Конец';

  @override
  String get reviewsCount => 'отзывов';

  @override
  String get bookTourAction => 'Забронировать тур';

  @override
  String get bookingDetailsTitle => 'Детали поездки';

  @override
  String get routeNameLabelOptional => 'Название маршрута (необязательно)';

  @override
  String get routeDatesLabel => 'Даты маршрута';

  @override
  String get peopleCountLabel => 'Кол-во человек';

  @override
  String get transportOptionalLabel => 'Транспорт';

  @override
  String get selectTransportLabel => 'Выберите транспорт';

  @override
  String get roadTypeConditionsLabel => 'Тип дороги и условия';

  @override
  String get guideOptionalLabel => 'Гид';

  @override
  String get selectGuideLabel => 'Выберите гида';

  @override
  String get additionalLabel => 'Дополнительно';

  @override
  String get bookAction => 'Забронировать';

  @override
  String get calculationDetailsTitle => 'Детализация расчёта';

  @override
  String get errorUserNotFound => 'Ошибка: пользователь не найден.';

  @override
  String get errorActiveTripExists =>
      'У вас уже есть активный маршрут. Завершите его перед созданием нового.';

  @override
  String get errorSelectVehicle =>
      'Пожалуйста, выберите автомобиль (водителя).';

  @override
  String get roadTypeAsphalt => 'Асфальт';

  @override
  String get roadTypeGravel => 'Гравий/Грунт';

  @override
  String get roadTypeOffroad => 'Жесткий Offroad';

  @override
  String get nightTripLabel => 'Ночная поездка';

  @override
  String get nightTripDesc => 'Поездка захватывает темное время суток';

  @override
  String get hintRouteNameExample =>
      'Придумайте название (например: Поездка в горы)';

  @override
  String waypointStop(int index) {
    return 'Остановка $index';
  }

  @override
  String get actionChange => 'Изменить';

  @override
  String maxPeopleLimit(int limit) {
    return 'Максимум для этого авто/гида: $limit чел.';
  }

  @override
  String get guideServiceDesc => 'Для интересных фактов';

  @override
  String get driverServiceDesc => 'Вместе с водителем';

  @override
  String get noDriversAvailable =>
      'Нет доступных водителей для выбранного типа авто.';

  @override
  String get noGuidesAvailable => 'Нет доступных гидов для выбранного типа.';

  @override
  String seatsAvailable(int total, int tourists) {
    return 'Мест: $total ($tourists для туристов)';
  }

  @override
  String get currencyPerKm => '₸/км';

  @override
  String get currencyPerDay => '₸/день';

  @override
  String receiptVehicle(String vType, int days) {
    return '🚙 $vType, $days дн.';
  }

  @override
  String receiptGuide(int days) {
    return '🗣 Услуги гида, $days дн.';
  }

  @override
  String receiptEcoTax(int people) {
    return '🌲 Экосборы ($people чел. + авто)';
  }

  @override
  String receiptInsurance(int people) {
    return '🛡 Горная страховка ($people чел.)';
  }

  @override
  String get receiptTotal => 'Итого';

  @override
  String get priceIncludesServiceFee =>
      '*Цена указана с учетом сервисного сбора платформы';

  @override
  String get insuranceTitle => 'Горная / Offroad страховка';

  @override
  String get insuranceDesc => 'Покрытие рисков для активного туризма';

  @override
  String get vehicleSuv => 'Внедорожник';

  @override
  String get vehicleBus => 'Автобус';

  @override
  String get vehicleMinibus => 'Микроавтобус';

  @override
  String get vehicleMinivan => 'Минивэн';

  @override
  String get vehicleDefault => 'Транспорт';

  @override
  String get month1 => 'Января';

  @override
  String get month2 => 'Февраля';

  @override
  String get month3 => 'Марта';

  @override
  String get month4 => 'Апреля';

  @override
  String get month5 => 'Мая';

  @override
  String get month6 => 'Июня';

  @override
  String get month7 => 'Июля';

  @override
  String get month8 => 'Августа';

  @override
  String get month9 => 'Сентября';

  @override
  String get month10 => 'Октября';

  @override
  String get month11 => 'Ноября';

  @override
  String get month12 => 'Декабря';

  @override
  String get weekday1 => 'Понедельник';

  @override
  String get weekday2 => 'Вторник';

  @override
  String get weekday3 => 'Среда';

  @override
  String get weekday4 => 'Четверг';

  @override
  String get weekday5 => 'Пятница';

  @override
  String get weekday6 => 'Суббота';

  @override
  String get weekday7 => 'Воскресенье';

  @override
  String get sosEmergencyMode => 'ЭКСТРЕННЫЙ РЕЖИМ';

  @override
  String get sosGuideToggle => 'Гиду группы';

  @override
  String get sosDriverToggle => 'Водителю';

  @override
  String get sosRescueServiceToggle => 'Служба спасения';

  @override
  String get sosCurrentCoordinates => 'ТЕКУЩИЕ КООРДИНАТЫ';

  @override
  String get sosSignalSent => 'Сигнал отправлен';

  @override
  String get sosCoordinatesTransmitted => 'Координаты переданы спасателям';

  @override
  String get sosButtonText => 'SOS';

  @override
  String get sosHoldAction => 'УДЕРЖИВАТЬ';

  @override
  String get sosHoldInstruction =>
      'Удерживайте кнопку 3 секунды\nдля отправки сигнала';

  @override
  String get walkieNameTourist => 'Турист';

  @override
  String get walkieNameParticipant => 'Участник';

  @override
  String walkieErrorStartWave(String error) {
    return 'Ошибка запуска WAVE: $error';
  }

  @override
  String get walkiePingSent =>
      'Пинг отправлен! Участники поделятся геолокацией.';

  @override
  String get walkieSubtitle => 'Offline Mesh Network';

  @override
  String get walkieInvitePrompt => 'Пригласите туристов в ту же поездку.';

  @override
  String get walkiePingButton => 'Пинг';

  @override
  String walkieNetworkActive(int count) {
    return '● Сеть WAVE активна · $count участников';
  }

  @override
  String get walkieNetworkActiveBT => ' · 🔵 BT';

  @override
  String get walkieNetworkActiveFirebase => ' · ☁️ Firebase';

  @override
  String get walkieNetworkInactive => '⚠ Сеть WAVE не активна';

  @override
  String get walkieTabChat => 'Чат';

  @override
  String get walkieTabMembers => 'Участники';

  @override
  String get walkieTabMap => 'Карта';

  @override
  String get walkieEmptyChatTitle => 'Нет сообщений';

  @override
  String get walkieEmptyChatDesc => 'Отправьте первое offline-сообщение группе';

  @override
  String walkieSharedLocation(String userName) {
    return '📍 $userName поделился(ась) геолокацией';
  }

  @override
  String get walkieMessageHint => 'Сообщение (offline)';

  @override
  String get walkieEmptyMembersTitle => 'Нет участников';

  @override
  String get walkieEmptyMembersDesc =>
      'Когда другие туристы откроют WAVE, они появятся здесь';

  @override
  String get walkieUnknownUser => 'Неизвестный';

  @override
  String get walkieStatusOnline => 'онлайн';

  @override
  String get myOrdersAndChats => 'Мои заказы и чаты';

  @override
  String myOrdersLoadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get myOrdersNoSavedChats => 'Нет сохранённых чатов';

  @override
  String get myOrdersNoSavedChatsDesc =>
      'Здесь появятся ваши активные переписки';

  @override
  String get myOrdersChatUnavailable =>
      'Чат недоступен или маршрут завершён давно';

  @override
  String get myOrdersDeleteChatTitle => 'Удалить чат?';

  @override
  String get myOrdersDeleteChatDesc =>
      'Этот чат пропадёт из ваших сохранённых, но останется у других участников поездки.';

  @override
  String get myOrdersDeleteChatCancel => 'Отмена';

  @override
  String get myOrdersDeleteChatConfirm => 'Удалить';

  @override
  String get myOrdersNoOrders => 'Заказов пока нет';

  @override
  String get myOrdersNoOrdersDesc => 'Забронируйте маршрут из конструктора';

  @override
  String get myOrdersCreateRoute => 'Создать маршрут';

  @override
  String get myOrdersTabUpcoming => 'Предстоящие';

  @override
  String get myOrdersTabPast => 'Завершенные';

  @override
  String get myOrdersTabChats => 'Чаты';

  @override
  String get bookingStatusPending => 'На рассмотрении';

  @override
  String get bookingStatusConfirmed => 'Подтверждён';

  @override
  String get bookingStatusInProgress => 'В процессе';

  @override
  String get bookingStatusCompleted => 'Завершён';

  @override
  String get bookingStatusCancelled => 'Отменён';

  @override
  String get myOrdersRepeatRoute => 'Повторить маршрут';

  @override
  String get myOrdersDetailStartDate => 'Дата начала';

  @override
  String get myOrdersDetailParticipants => 'Участников';

  @override
  String myOrdersDetailParticipantsCount(int count) {
    return '$count чел.';
  }

  @override
  String get myOrdersDetailPrice => 'Стоимость';

  @override
  String get myOrdersDetailGuide => 'Гид';

  @override
  String get myOrdersDetailDriver => 'Водитель';

  @override
  String get myOrdersDetailAssigned => 'Назначен';

  @override
  String get myOrdersOpenRoute => 'Открыть маршрут';

  @override
  String get tripCompletedShareSuccess =>
      'Маршрут теперь доступен в популярных!';

  @override
  String get tripCompletedTitle => 'Маршрут завершён!';

  @override
  String get tripCompletedSubtitle => 'Поздравляем с успешным походом!';

  @override
  String get tripCompletedStatsTitle => 'Статистика маршрута';

  @override
  String get tripCompletedStatDistance => 'Дистанция';

  @override
  String get tripCompletedStatTime => 'Время в пути';

  @override
  String get tripCompletedStatMaxHeight => 'Макс. высота';

  @override
  String get tripCompletedStatAvgSpeed => 'Средняя скорость';

  @override
  String get tripCompletedAddToFavorites => 'Добавить в избранное';

  @override
  String get tripCompletedFavRoute => 'Маршрут';

  @override
  String get tripCompletedFavGuide => 'Гид';

  @override
  String get tripCompletedFavDriver => 'Водитель';

  @override
  String get tripCompletedShareAction => 'Поделиться маршрутом';

  @override
  String get tripCompletedViewOrdersAction => 'Посмотреть в заказах';

  @override
  String get tripCompletedHomeAction => 'На главную';

  @override
  String messengerSendError(String error) {
    return 'Ошибка отправки: $error';
  }

  @override
  String get messengerNoActiveRoute => 'Нет активного маршрута';

  @override
  String get messengerNoActiveRouteDesc =>
      'Чат доступен только во время\nактивной поездки';

  @override
  String get messengerLoadError => 'Ошибка загрузки чата';

  @override
  String get messengerNoMessages => 'Нет сообщений. Напишите первым!';

  @override
  String get messengerRouteNotFound => 'Маршрут не найден';

  @override
  String get messengerBookingNotFound => 'Бронирование не найдено';

  @override
  String get messengerParticipantsTitle => 'Участники';

  @override
  String get messengerRoleOrganizer => 'Организатор';

  @override
  String get messengerRoleGuide => 'Горный гид';

  @override
  String get messengerRoleDriver => 'Водитель';

  @override
  String messengerParticipantsLoadError(String error) {
    return 'Ошибка загрузки участников: $error';
  }

  @override
  String get messengerChatSubtitle => 'Чат по маршруту';

  @override
  String get messengerDeleteChatUnavailable => 'Удаление чата пока недоступно';

  @override
  String get messengerViewParticipants => 'Посмотреть участников';

  @override
  String get messengerDeleteChat => 'Удалить чат';

  @override
  String get messengerInputHint => 'Введите сообщение...';

  @override
  String get activeTripStageScheduled => 'Забронировано';

  @override
  String get activeTripStageWaiting => 'Водитель едет';

  @override
  String get activeTripStageInProgress => 'В пути';

  @override
  String get activeTripStageCompleted => 'Завершён';

  @override
  String get activeTripLocationPermError =>
      'Нет разрешения на геолокацию. Разрешите доступ в настройках.';

  @override
  String activeTripProximityError(String dist) {
    return 'Вы в $dist м от точки сбора. Нужно подойти ближе 100 м чтобы начать маршрут.';
  }

  @override
  String get activeTripDriver => 'Водитель';

  @override
  String get activeTripGuide => 'Гид';

  @override
  String activeTripWaitingForOthers(String missing) {
    return 'Ожидание готовности: $missing ещё не на месте сбора (≤ 100 м).';
  }

  @override
  String get activeTripSaveErrorQuota =>
      'Ошибка сохранения — превышена квота Firestore.\nПодождите немного и попробуйте снова.';

  @override
  String get activeTripNotFound => 'Маршрут не найден';

  @override
  String get activeTripDefaultTitle => 'Маршрут';

  @override
  String activeTripEta(String time) {
    return 'Прибытие: $time';
  }

  @override
  String get activeTripDriverCompleted => 'Водитель завершил маршрут';

  @override
  String get activeTripConfirmCompletionDesc =>
      'Подтвердите, чтобы завершить поездку и разблокировать оплату';

  @override
  String get activeTripConfirming => 'Подтверждаем…';

  @override
  String get activeTripConfirmCompletionBtn => 'Подтвердить завершение';

  @override
  String get activeTripChatDefaultTitle => 'Чат';

  @override
  String get activeTripGoToChat => 'Перейти в чат';

  @override
  String activeTripConfirmError(String error) {
    return 'Ошибка подтверждения: $error';
  }

  @override
  String get activeTripCancelTitle => 'Отменить маршрут?';

  @override
  String get activeTripCancelDesc =>
      'Дата маршрута прошла. Вы хотите отменить бронирование?';

  @override
  String get activeTripCancelNo => 'Нет';

  @override
  String get activeTripCancelYes => 'Да, отменить';

  @override
  String get activeTripBookingDetails => 'Детали бронирования';

  @override
  String get activeTripBookingDates => 'Даты';

  @override
  String get activeTripBookingParticipants => 'Участников';

  @override
  String activeTripBookingParticipantsCount(int count) {
    return '$count чел.';
  }

  @override
  String get activeTripBookingTotal => 'К оплате';

  @override
  String get activeTripDatePassed => 'Дата маршрута прошла';

  @override
  String get activeTripCancelAction => 'Отменить маршрут';

  @override
  String activeTripTimeLeftDaysHours(int days, int hours) {
    return 'Осталось $days д. $hours ч.';
  }

  @override
  String activeTripTimeLeftHours(int hours) {
    return 'Осталось $hours ч.';
  }

  @override
  String get activeTripStartingSoon => 'Начинается скоро!';

  @override
  String get activeTripGroupGathering => 'Водитель и группа собираются';

  @override
  String get activeTripActionReady => 'Подтвердить готовность';

  @override
  String get activeTripActionStart => 'Начать маршрут';

  @override
  String get activeTripActionEnd => 'Завершить маршрут';

  @override
  String get rbStepPoints => 'Точки';

  @override
  String get rbStepRoute => 'Маршрут';

  @override
  String get rbStepDetails => 'Детали';

  @override
  String get rbTooltipBack => 'Отменить создание маршрута';

  @override
  String get rbTooltipMyLocation => 'Моё местоположение';

  @override
  String get rbPanelWaypointsTitle => 'Точки маршрута';

  @override
  String get rbPanelTapHint => 'Тапните на карту, чтобы добавить точку';

  @override
  String get rbPanelMyLocationStart => 'Моё местоположение как старт';

  @override
  String get rbPanelMaxPoints => 'Максимум 10 точек';

  @override
  String get rbTooltipUndo => 'Удалить последнюю точку';

  @override
  String get rbTooltipClear => 'Очистить все точки';

  @override
  String get rbBuildRoute => 'Построить маршрут';

  @override
  String get rbLoadingTitle => 'Строим маршрут…';

  @override
  String get rbLoadingSubtitle => 'Запрашиваем данные Яндекс Карт';

  @override
  String get rbStatDistance => 'Расстояние';

  @override
  String rbStatDistanceKm(Object km) {
    return '$km км';
  }

  @override
  String get rbStatTime => 'Время';

  @override
  String get rbStatTimeLessHour => '< 1 ч';

  @override
  String rbStatTimeHours(Object h) {
    return '$h ч';
  }

  @override
  String get rbStatByRoad => 'По дорогам';

  @override
  String get rbStatStraightLine => 'По прямой';

  @override
  String get rbStatYandex => 'Яндекс';

  @override
  String get rbStatEstimate => 'Оценка';

  @override
  String get rbReset => 'Заново';

  @override
  String get rbContinue => 'Продолжить';

  @override
  String get rbWaypointStart => 'Старт';

  @override
  String get rbWaypointFinish => 'Финиш';

  @override
  String rbWaypointMid(int n) {
    return 'Остановка $n';
  }

  @override
  String get rbMyLocationLabel => 'Моё местоположение';

  @override
  String get rbDefaultRouteTitle => 'Свой маршрут';

  @override
  String get rbErrorFallback =>
      'Маршрут по дорогам недоступен — показано прямое расстояние';

  @override
  String get rbErrorBuild => 'Ошибка при построении маршрута';

  @override
  String get settingsLoading => 'Загрузка...';

  @override
  String get settingsFieldFirstName => 'Имя';

  @override
  String get settingsFieldLastName => 'Фамилия';

  @override
  String get settingsFieldEmail => 'Email';

  @override
  String get settingsFieldPhone => 'Телефон';

  @override
  String get settingsFieldBirthDate => 'Дата рождения';

  @override
  String get settingsSaveChanges => 'Сохранить изменения';

  @override
  String get settingsDataSaved => 'Данные сохранены';

  @override
  String get settingsApplyButton => 'Применить';

  @override
  String get settingsDeleteButton => 'Удалить';

  @override
  String get roleMountainGuide => 'Горный гид';

  @override
  String get roleCityGuide => 'Городской обзорный гид';

  @override
  String get roleSuvDriver => 'Водитель внедорожника';

  @override
  String get roleBusDriver => 'Водитель автобуса';

  @override
  String get roleMinibusDriver => 'Водитель микроавтобуса';

  @override
  String get roleMinivanDriver => 'Водитель минивена';

  @override
  String partnerProfileReviews(int count) {
    return '($count отзывов)';
  }

  @override
  String get partnerProfileAboutMe => 'О себе';

  @override
  String get partnerProfileCarDetails => 'Детали автомобиля';

  @override
  String get partnerProfileVehicleModel => 'Модель';

  @override
  String get partnerProfileVehicleClass => 'Класс';

  @override
  String get partnerProfileVehicleCapacity => 'Вместимость';

  @override
  String partnerProfileVehicleCapacityValue(int count) {
    return '$count чел. (вкл. водителя)';
  }

  @override
  String get partnerProfileRate => 'Ставка';

  @override
  String partnerProfileRatePerKm(int amount) {
    return '$amount ₸ / км';
  }

  @override
  String partnerProfileRatePerDay(int amount) {
    return '$amount ₸ / день';
  }

  @override
  String get partnerProfileSpecialization => 'Специализация';

  @override
  String get partnerProfileExperience => 'Опыт работы';

  @override
  String partnerProfileExperienceYears(int count) {
    return '$count лет';
  }

  @override
  String get partnerProfileLanguages => 'Языки';

  @override
  String get partnerProfileDestinations => 'Направления';

  @override
  String get settingsRelationWife => 'Супруга';

  @override
  String get settingsRelationHusband => 'Супруг';

  @override
  String get settingsRelationFriend => 'Друг';

  @override
  String get settingsRelationEmergency => 'Служба спасения';
}
