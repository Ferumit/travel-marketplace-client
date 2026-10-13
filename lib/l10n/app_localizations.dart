import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Explora'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get settingsProfile;

  /// No description provided for @settingsPersonalData.
  ///
  /// In ru, this message translates to:
  /// **'Личные данные'**
  String get settingsPersonalData;

  /// No description provided for @settingsNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Не указано'**
  String get settingsNotSpecified;

  /// No description provided for @settingsSecurity.
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get settingsSecurity;

  /// No description provided for @settingsSosContacts.
  ///
  /// In ru, this message translates to:
  /// **'SOS контакты'**
  String get settingsSosContacts;

  /// No description provided for @settingsEmergencyAlerts.
  ///
  /// In ru, this message translates to:
  /// **'Экстренные уведомления'**
  String get settingsEmergencyAlerts;

  /// No description provided for @settingsContactsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} контакта'**
  String settingsContactsCount(int count);

  /// No description provided for @settingsApp.
  ///
  /// In ru, this message translates to:
  /// **'Приложение'**
  String get settingsApp;

  /// No description provided for @settingsLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settingsTheme;

  /// No description provided for @settingsAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyLog.
  ///
  /// In ru, this message translates to:
  /// **'Политика конфиденциальности'**
  String get settingsPrivacyLog;

  /// No description provided for @settingsLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get settingsLogout;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая тема'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get settingsThemeAuto;

  /// No description provided for @settingsSelectLanguage.
  ///
  /// In ru, this message translates to:
  /// **'Язык приложения'**
  String get settingsSelectLanguage;

  /// No description provided for @settingsApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get settingsApply;

  /// No description provided for @settingsThemeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тема оформления'**
  String get settingsThemeTitle;

  /// No description provided for @settingsThemeDarkDesc.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная тема для ночных походов'**
  String get settingsThemeDarkDesc;

  /// No description provided for @settingsThemeLightDesc.
  ///
  /// In ru, this message translates to:
  /// **'Светлая тема для дневного использования'**
  String get settingsThemeLightDesc;

  /// No description provided for @settingsThemeAutoDesc.
  ///
  /// In ru, this message translates to:
  /// **'Автоматическое переключение'**
  String get settingsThemeAutoDesc;

  /// No description provided for @settingsSosDeleteDesc.
  ///
  /// In ru, this message translates to:
  /// **'Эти контакты будут уведомлены при активации экстренного сигнала'**
  String get settingsSosDeleteDesc;

  /// No description provided for @settingsAddContact.
  ///
  /// In ru, this message translates to:
  /// **'Добавить контакт'**
  String get settingsAddContact;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить аккаунт'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите удалить свой аккаунт? Это действие необратимо, и все ваши данные будут потеряны навсегда.'**
  String get settingsDeleteAccountDesc;

  /// No description provided for @settingsCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get settingsCancel;

  /// No description provided for @homeSearchHint.
  ///
  /// In ru, this message translates to:
  /// **'Куда отправимся?'**
  String get homeSearchHint;

  /// No description provided for @homeActiveTrips.
  ///
  /// In ru, this message translates to:
  /// **'Мои Активные Походы'**
  String get homeActiveTrips;

  /// No description provided for @homeActiveTripsTap.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите чтобы открыть маршрут'**
  String get homeActiveTripsTap;

  /// No description provided for @homeCreateRoute.
  ///
  /// In ru, this message translates to:
  /// **'Создать Маршрут'**
  String get homeCreateRoute;

  /// No description provided for @homeCreateRouteDesc.
  ///
  /// In ru, this message translates to:
  /// **'Через ИИ Конструктор'**
  String get homeCreateRouteDesc;

  /// No description provided for @homeWhereTo.
  ///
  /// In ru, this message translates to:
  /// **'Куда угодно!'**
  String get homeWhereTo;

  /// No description provided for @homeSmartSelection.
  ///
  /// In ru, this message translates to:
  /// **'Умный подбор маршрута'**
  String get homeSmartSelection;

  /// No description provided for @homePopularRoutes.
  ///
  /// In ru, this message translates to:
  /// **'Популярные Маршруты'**
  String get homePopularRoutes;

  /// No description provided for @homeAll.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get homeAll;

  /// No description provided for @homeProfileHintTitle.
  ///
  /// In ru, this message translates to:
  /// **'Фото профиля и Альбом'**
  String get homeProfileHintTitle;

  /// No description provided for @homeProfileHintDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы можете обновить свой стиль и сохранить дорогие вам воспоминания добавив фото в альбом или на фото профиля.'**
  String get homeProfileHintDesc;

  /// No description provided for @homeProfileHintGotIt.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get homeProfileHintGotIt;

  /// No description provided for @homeDaysAbbr.
  ///
  /// In ru, this message translates to:
  /// **'{count} д.'**
  String homeDaysAbbr(int count);

  /// No description provided for @authEnterPhone.
  ///
  /// In ru, this message translates to:
  /// **'Введите номер телефона'**
  String get authEnterPhone;

  /// No description provided for @authEnterSmsCode.
  ///
  /// In ru, this message translates to:
  /// **'Введите код из SMS'**
  String get authEnterSmsCode;

  /// No description provided for @authFillEmailPassword.
  ///
  /// In ru, this message translates to:
  /// **'Заполните email и пароль'**
  String get authFillEmailPassword;

  /// No description provided for @authUnknownError.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестная ошибка'**
  String get authUnknownError;

  /// No description provided for @authGoogleError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка авторизации Google'**
  String get authGoogleError;

  /// No description provided for @authLoginTab.
  ///
  /// In ru, this message translates to:
  /// **'Вход'**
  String get authLoginTab;

  /// No description provided for @authRegisterTab.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get authRegisterTab;

  /// No description provided for @authPhoneTab.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get authPhoneTab;

  /// No description provided for @authPhoneHint.
  ///
  /// In ru, this message translates to:
  /// **'Номер (+7...)'**
  String get authPhoneHint;

  /// No description provided for @authSmsCodeHint.
  ///
  /// In ru, this message translates to:
  /// **'Код из SMS'**
  String get authSmsCodeHint;

  /// No description provided for @authChangePhone.
  ///
  /// In ru, this message translates to:
  /// **'Изменить номер'**
  String get authChangePhone;

  /// No description provided for @authEmailHint.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get authEmailHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get authPasswordHint;

  /// No description provided for @authLoginButton.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In ru, this message translates to:
  /// **'Создать аккаунт'**
  String get authRegisterButton;

  /// No description provided for @authConfirmButton.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get authConfirmButton;

  /// No description provided for @authGetSmsButton.
  ///
  /// In ru, this message translates to:
  /// **'Получить SMS-код'**
  String get authGetSmsButton;

  /// No description provided for @authForgotPassword.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get authForgotPassword;

  /// No description provided for @authOrWith.
  ///
  /// In ru, this message translates to:
  /// **'Или с помощью'**
  String get authOrWith;

  /// No description provided for @authInDevelopment.
  ///
  /// In ru, this message translates to:
  /// **'В разработке'**
  String get authInDevelopment;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordDesc.
  ///
  /// In ru, this message translates to:
  /// **'Введите ваш email — мы отправим ссылку для сброса пароля.'**
  String get authResetPasswordDesc;

  /// No description provided for @authCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get authCancel;

  /// No description provided for @authSend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get authSend;

  /// No description provided for @authEmailSent.
  ///
  /// In ru, this message translates to:
  /// **'Письмо отправлено — проверьте почту'**
  String get authEmailSent;

  /// No description provided for @authSendError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка отправки'**
  String get authSendError;

  /// No description provided for @onboardingSlide1Title.
  ///
  /// In ru, this message translates to:
  /// **'Ваш проводник'**
  String get onboardingSlide1Title;

  /// No description provided for @onboardingSlide1Desc.
  ///
  /// In ru, this message translates to:
  /// **'Исследуйте дикие места с уверенностью. Наши карты работают там, где нет сети.'**
  String get onboardingSlide1Desc;

  /// No description provided for @onboardingSlide2Title.
  ///
  /// In ru, this message translates to:
  /// **'Уникальные маршруты'**
  String get onboardingSlide2Title;

  /// No description provided for @onboardingSlide2Desc.
  ///
  /// In ru, this message translates to:
  /// **'Тысячи проверенных троп от профессиональных гидов и сообщества.'**
  String get onboardingSlide2Desc;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In ru, this message translates to:
  /// **'Полная поддержка'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Desc.
  ///
  /// In ru, this message translates to:
  /// **'Бронируйте транспорт, гидов и страховку в одном приложении.'**
  String get onboardingSlide3Desc;

  /// No description provided for @onboardingStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать путешествие'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get onboardingNext;

  /// No description provided for @profileUpdatePhoto.
  ///
  /// In ru, this message translates to:
  /// **'Обновить фото профиля'**
  String get profileUpdatePhoto;

  /// No description provided for @profileAddPhotoToAlbum.
  ///
  /// In ru, this message translates to:
  /// **'Добавить фото в альбом'**
  String get profileAddPhotoToAlbum;

  /// No description provided for @profileUserNotAuthorized.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь не авторизован'**
  String get profileUserNotAuthorized;

  /// No description provided for @profileWalletBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс кошелька'**
  String get profileWalletBalance;

  /// No description provided for @profileMyOrders.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы и чаты'**
  String get profileMyOrders;

  /// No description provided for @profileFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Избранное'**
  String get profileFavorites;

  /// No description provided for @profileDocuments.
  ///
  /// In ru, this message translates to:
  /// **'Документы'**
  String get profileDocuments;

  /// No description provided for @profileMyAlbum.
  ///
  /// In ru, this message translates to:
  /// **'Мой альбом'**
  String get profileMyAlbum;

  /// No description provided for @profileNoPhotosYet.
  ///
  /// In ru, this message translates to:
  /// **'Здесь пока нет фотографий'**
  String get profileNoPhotosYet;

  /// No description provided for @profileAddMemories.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте воспоминания нажав на +'**
  String get profileAddMemories;

  /// No description provided for @profileLogout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get profileLogout;

  /// No description provided for @docsInsurancePolicy.
  ///
  /// In ru, this message translates to:
  /// **'Страховой полис'**
  String get docsInsurancePolicy;

  /// No description provided for @docsInsurancePolicyDesc.
  ///
  /// In ru, this message translates to:
  /// **'№ 89320-YDX • Активен до 25.09'**
  String get docsInsurancePolicyDesc;

  /// No description provided for @docsPassport.
  ///
  /// In ru, this message translates to:
  /// **'Удостоверение личности / Паспорт'**
  String get docsPassport;

  /// No description provided for @docsPassportDesc.
  ///
  /// In ru, this message translates to:
  /// **'**** 4512 • Иванов Д.А.'**
  String get docsPassportDesc;

  /// No description provided for @docsTourVoucher.
  ///
  /// In ru, this message translates to:
  /// **'Ваучер на тур'**
  String get docsTourVoucher;

  /// No description provided for @docsTourVoucherDesc.
  ///
  /// In ru, this message translates to:
  /// **'Алтай • 24 Сентября'**
  String get docsTourVoucherDesc;

  /// No description provided for @favoritesTabRoutes.
  ///
  /// In ru, this message translates to:
  /// **'Маршруты'**
  String get favoritesTabRoutes;

  /// No description provided for @favoritesTabGuides.
  ///
  /// In ru, this message translates to:
  /// **'Гиды'**
  String get favoritesTabGuides;

  /// No description provided for @favoritesTabCars.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get favoritesTabCars;

  /// No description provided for @authRequired.
  ///
  /// In ru, this message translates to:
  /// **'Требуется авторизация'**
  String get authRequired;

  /// No description provided for @userLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки пользователя'**
  String get userLoadError;

  /// No description provided for @favoritesNoRoutes.
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных маршрутов'**
  String get favoritesNoRoutes;

  /// No description provided for @favoritesNoGuides.
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных гидов'**
  String get favoritesNoGuides;

  /// No description provided for @favoritesNoCars.
  ///
  /// In ru, this message translates to:
  /// **'Нет избранных авто'**
  String get favoritesNoCars;

  /// No description provided for @difficultyEasy.
  ///
  /// In ru, this message translates to:
  /// **'Лёгкий'**
  String get difficultyEasy;

  /// No description provided for @difficultyModerate.
  ///
  /// In ru, this message translates to:
  /// **'Средний'**
  String get difficultyModerate;

  /// No description provided for @difficultyHard.
  ///
  /// In ru, this message translates to:
  /// **'Сложный'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In ru, this message translates to:
  /// **'Экспертный'**
  String get difficultyExpert;

  /// No description provided for @activeTripMessenger.
  ///
  /// In ru, this message translates to:
  /// **'Мессенджер'**
  String get activeTripMessenger;

  /// No description provided for @homeRouteConstructor.
  ///
  /// In ru, this message translates to:
  /// **'Конструктор маршрута'**
  String get homeRouteConstructor;

  /// No description provided for @homeCurrentTrip.
  ///
  /// In ru, this message translates to:
  /// **'Текущий маршрут'**
  String get homeCurrentTrip;

  /// No description provided for @homeStatusInProgress.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get homeStatusInProgress;

  /// No description provided for @homeStatusWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Ждём водителя'**
  String get homeStatusWaiting;

  /// No description provided for @homeStatusBooked.
  ///
  /// In ru, this message translates to:
  /// **'Забронировано'**
  String get homeStatusBooked;

  /// No description provided for @homeArrivalPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Прибытие: '**
  String get homeArrivalPrefix;

  /// No description provided for @homeChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get homeChat;

  /// No description provided for @homeMessenger.
  ///
  /// In ru, this message translates to:
  /// **'Мессенджер'**
  String get homeMessenger;

  /// No description provided for @homeErrorPrefix.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: '**
  String get homeErrorPrefix;

  /// No description provided for @homeNoRoutesAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных маршрутов'**
  String get homeNoRoutesAvailable;

  /// No description provided for @homeUnderstand.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get homeUnderstand;

  /// No description provided for @activeTripsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Текущие маршруты'**
  String get activeTripsTitle;

  /// No description provided for @errorMessage.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: {message}'**
  String errorMessage(String message);

  /// No description provided for @noActiveTrips.
  ///
  /// In ru, this message translates to:
  /// **'У вас нет активных поездок'**
  String get noActiveTrips;

  /// No description provided for @routeNumLabel.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут {num}'**
  String routeNumLabel(String num);

  /// No description provided for @statusWaitingDriver.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание водителя'**
  String get statusWaitingDriver;

  /// No description provided for @statusOnWay.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get statusOnWay;

  /// No description provided for @actionRename.
  ///
  /// In ru, this message translates to:
  /// **'Изменить название'**
  String get actionRename;

  /// No description provided for @actionMoreInfo.
  ///
  /// In ru, this message translates to:
  /// **'Доп. информация'**
  String get actionMoreInfo;

  /// No description provided for @actionCancelRoute.
  ///
  /// In ru, this message translates to:
  /// **'Отменить маршрут'**
  String get actionCancelRoute;

  /// No description provided for @hintRenameRoute.
  ///
  /// In ru, this message translates to:
  /// **'Например: Поездка в горы'**
  String get hintRenameRoute;

  /// No description provided for @errorEnterName.
  ///
  /// In ru, this message translates to:
  /// **'Введите название'**
  String get errorEnterName;

  /// No description provided for @actionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get actionSave;

  /// No description provided for @dialogCancelRouteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отмена маршрута'**
  String get dialogCancelRouteTitle;

  /// No description provided for @dialogCancelRouteDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вы уверены, что хотите отменить этот маршрут? Возврат средств будет произведен согласно правилам отмены.'**
  String get dialogCancelRouteDesc;

  /// No description provided for @actionDoNotCancel.
  ///
  /// In ru, this message translates to:
  /// **'Не отменять'**
  String get actionDoNotCancel;

  /// No description provided for @actionYesCancel.
  ///
  /// In ru, this message translates to:
  /// **'Да, отменить'**
  String get actionYesCancel;

  /// No description provided for @msgRouteCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут отменен'**
  String get msgRouteCancelled;

  /// No description provided for @errorCancelRoute.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при отмене: {message}'**
  String errorCancelRoute(String message);

  /// No description provided for @waypointStart.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get waypointStart;

  /// No description provided for @waypointEnd.
  ///
  /// In ru, this message translates to:
  /// **'Конец'**
  String get waypointEnd;

  /// No description provided for @reviewsCount.
  ///
  /// In ru, this message translates to:
  /// **'отзывов'**
  String get reviewsCount;

  /// No description provided for @bookTourAction.
  ///
  /// In ru, this message translates to:
  /// **'Забронировать тур'**
  String get bookTourAction;

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Детали поездки'**
  String get bookingDetailsTitle;

  /// No description provided for @routeNameLabelOptional.
  ///
  /// In ru, this message translates to:
  /// **'Название маршрута (необязательно)'**
  String get routeNameLabelOptional;

  /// No description provided for @routeDatesLabel.
  ///
  /// In ru, this message translates to:
  /// **'Даты маршрута'**
  String get routeDatesLabel;

  /// No description provided for @peopleCountLabel.
  ///
  /// In ru, this message translates to:
  /// **'Кол-во человек'**
  String get peopleCountLabel;

  /// No description provided for @transportOptionalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Транспорт'**
  String get transportOptionalLabel;

  /// No description provided for @selectTransportLabel.
  ///
  /// In ru, this message translates to:
  /// **'Выберите транспорт'**
  String get selectTransportLabel;

  /// No description provided for @roadTypeConditionsLabel.
  ///
  /// In ru, this message translates to:
  /// **'Тип дороги и условия'**
  String get roadTypeConditionsLabel;

  /// No description provided for @guideOptionalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Гид'**
  String get guideOptionalLabel;

  /// No description provided for @selectGuideLabel.
  ///
  /// In ru, this message translates to:
  /// **'Выберите гида'**
  String get selectGuideLabel;

  /// No description provided for @additionalLabel.
  ///
  /// In ru, this message translates to:
  /// **'Дополнительно'**
  String get additionalLabel;

  /// No description provided for @bookAction.
  ///
  /// In ru, this message translates to:
  /// **'Забронировать'**
  String get bookAction;

  /// No description provided for @calculationDetailsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Детализация расчёта'**
  String get calculationDetailsTitle;

  /// No description provided for @errorUserNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка: пользователь не найден.'**
  String get errorUserNotFound;

  /// No description provided for @errorActiveTripExists.
  ///
  /// In ru, this message translates to:
  /// **'У вас уже есть активный маршрут. Завершите его перед созданием нового.'**
  String get errorActiveTripExists;

  /// No description provided for @errorSelectVehicle.
  ///
  /// In ru, this message translates to:
  /// **'Пожалуйста, выберите автомобиль (водителя).'**
  String get errorSelectVehicle;

  /// No description provided for @roadTypeAsphalt.
  ///
  /// In ru, this message translates to:
  /// **'Асфальт'**
  String get roadTypeAsphalt;

  /// No description provided for @roadTypeGravel.
  ///
  /// In ru, this message translates to:
  /// **'Гравий/Грунт'**
  String get roadTypeGravel;

  /// No description provided for @roadTypeOffroad.
  ///
  /// In ru, this message translates to:
  /// **'Жесткий Offroad'**
  String get roadTypeOffroad;

  /// No description provided for @nightTripLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ночная поездка'**
  String get nightTripLabel;

  /// No description provided for @nightTripDesc.
  ///
  /// In ru, this message translates to:
  /// **'Поездка захватывает темное время суток'**
  String get nightTripDesc;

  /// No description provided for @hintRouteNameExample.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте название (например: Поездка в горы)'**
  String get hintRouteNameExample;

  /// No description provided for @waypointStop.
  ///
  /// In ru, this message translates to:
  /// **'Остановка {index}'**
  String waypointStop(int index);

  /// No description provided for @actionChange.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get actionChange;

  /// No description provided for @maxPeopleLimit.
  ///
  /// In ru, this message translates to:
  /// **'Максимум для этого авто/гида: {limit} чел.'**
  String maxPeopleLimit(int limit);

  /// No description provided for @guideServiceDesc.
  ///
  /// In ru, this message translates to:
  /// **'Для интересных фактов'**
  String get guideServiceDesc;

  /// No description provided for @driverServiceDesc.
  ///
  /// In ru, this message translates to:
  /// **'Вместе с водителем'**
  String get driverServiceDesc;

  /// No description provided for @noDriversAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных водителей для выбранного типа авто.'**
  String get noDriversAvailable;

  /// No description provided for @noGuidesAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных гидов для выбранного типа.'**
  String get noGuidesAvailable;

  /// No description provided for @seatsAvailable.
  ///
  /// In ru, this message translates to:
  /// **'Мест: {total} ({tourists} для туристов)'**
  String seatsAvailable(int total, int tourists);

  /// No description provided for @currencyPerKm.
  ///
  /// In ru, this message translates to:
  /// **'₸/км'**
  String get currencyPerKm;

  /// No description provided for @currencyPerDay.
  ///
  /// In ru, this message translates to:
  /// **'₸/день'**
  String get currencyPerDay;

  /// No description provided for @receiptVehicle.
  ///
  /// In ru, this message translates to:
  /// **'🚙 {vType}, {days} дн.'**
  String receiptVehicle(String vType, int days);

  /// No description provided for @receiptGuide.
  ///
  /// In ru, this message translates to:
  /// **'🗣 Услуги гида, {days} дн.'**
  String receiptGuide(int days);

  /// No description provided for @receiptEcoTax.
  ///
  /// In ru, this message translates to:
  /// **'🌲 Экосборы ({people} чел. + авто)'**
  String receiptEcoTax(int people);

  /// No description provided for @receiptInsurance.
  ///
  /// In ru, this message translates to:
  /// **'🛡 Горная страховка ({people} чел.)'**
  String receiptInsurance(int people);

  /// No description provided for @receiptTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get receiptTotal;

  /// No description provided for @priceIncludesServiceFee.
  ///
  /// In ru, this message translates to:
  /// **'*Цена указана с учетом сервисного сбора платформы'**
  String get priceIncludesServiceFee;

  /// No description provided for @insuranceTitle.
  ///
  /// In ru, this message translates to:
  /// **'Горная / Offroad страховка'**
  String get insuranceTitle;

  /// No description provided for @insuranceDesc.
  ///
  /// In ru, this message translates to:
  /// **'Покрытие рисков для активного туризма'**
  String get insuranceDesc;

  /// No description provided for @vehicleSuv.
  ///
  /// In ru, this message translates to:
  /// **'Внедорожник'**
  String get vehicleSuv;

  /// No description provided for @vehicleBus.
  ///
  /// In ru, this message translates to:
  /// **'Автобус'**
  String get vehicleBus;

  /// No description provided for @vehicleMinibus.
  ///
  /// In ru, this message translates to:
  /// **'Микроавтобус'**
  String get vehicleMinibus;

  /// No description provided for @vehicleMinivan.
  ///
  /// In ru, this message translates to:
  /// **'Минивэн'**
  String get vehicleMinivan;

  /// No description provided for @vehicleDefault.
  ///
  /// In ru, this message translates to:
  /// **'Транспорт'**
  String get vehicleDefault;

  /// No description provided for @month1.
  ///
  /// In ru, this message translates to:
  /// **'Января'**
  String get month1;

  /// No description provided for @month2.
  ///
  /// In ru, this message translates to:
  /// **'Февраля'**
  String get month2;

  /// No description provided for @month3.
  ///
  /// In ru, this message translates to:
  /// **'Марта'**
  String get month3;

  /// No description provided for @month4.
  ///
  /// In ru, this message translates to:
  /// **'Апреля'**
  String get month4;

  /// No description provided for @month5.
  ///
  /// In ru, this message translates to:
  /// **'Мая'**
  String get month5;

  /// No description provided for @month6.
  ///
  /// In ru, this message translates to:
  /// **'Июня'**
  String get month6;

  /// No description provided for @month7.
  ///
  /// In ru, this message translates to:
  /// **'Июля'**
  String get month7;

  /// No description provided for @month8.
  ///
  /// In ru, this message translates to:
  /// **'Августа'**
  String get month8;

  /// No description provided for @month9.
  ///
  /// In ru, this message translates to:
  /// **'Сентября'**
  String get month9;

  /// No description provided for @month10.
  ///
  /// In ru, this message translates to:
  /// **'Октября'**
  String get month10;

  /// No description provided for @month11.
  ///
  /// In ru, this message translates to:
  /// **'Ноября'**
  String get month11;

  /// No description provided for @month12.
  ///
  /// In ru, this message translates to:
  /// **'Декабря'**
  String get month12;

  /// No description provided for @weekday1.
  ///
  /// In ru, this message translates to:
  /// **'Понедельник'**
  String get weekday1;

  /// No description provided for @weekday2.
  ///
  /// In ru, this message translates to:
  /// **'Вторник'**
  String get weekday2;

  /// No description provided for @weekday3.
  ///
  /// In ru, this message translates to:
  /// **'Среда'**
  String get weekday3;

  /// No description provided for @weekday4.
  ///
  /// In ru, this message translates to:
  /// **'Четверг'**
  String get weekday4;

  /// No description provided for @weekday5.
  ///
  /// In ru, this message translates to:
  /// **'Пятница'**
  String get weekday5;

  /// No description provided for @weekday6.
  ///
  /// In ru, this message translates to:
  /// **'Суббота'**
  String get weekday6;

  /// No description provided for @weekday7.
  ///
  /// In ru, this message translates to:
  /// **'Воскресенье'**
  String get weekday7;

  /// No description provided for @sosEmergencyMode.
  ///
  /// In ru, this message translates to:
  /// **'ЭКСТРЕННЫЙ РЕЖИМ'**
  String get sosEmergencyMode;

  /// No description provided for @sosGuideToggle.
  ///
  /// In ru, this message translates to:
  /// **'Гиду группы'**
  String get sosGuideToggle;

  /// No description provided for @sosDriverToggle.
  ///
  /// In ru, this message translates to:
  /// **'Водителю'**
  String get sosDriverToggle;

  /// No description provided for @sosRescueServiceToggle.
  ///
  /// In ru, this message translates to:
  /// **'Служба спасения'**
  String get sosRescueServiceToggle;

  /// No description provided for @sosCurrentCoordinates.
  ///
  /// In ru, this message translates to:
  /// **'ТЕКУЩИЕ КООРДИНАТЫ'**
  String get sosCurrentCoordinates;

  /// No description provided for @sosSignalSent.
  ///
  /// In ru, this message translates to:
  /// **'Сигнал отправлен'**
  String get sosSignalSent;

  /// No description provided for @sosCoordinatesTransmitted.
  ///
  /// In ru, this message translates to:
  /// **'Координаты переданы спасателям'**
  String get sosCoordinatesTransmitted;

  /// No description provided for @sosButtonText.
  ///
  /// In ru, this message translates to:
  /// **'SOS'**
  String get sosButtonText;

  /// No description provided for @sosHoldAction.
  ///
  /// In ru, this message translates to:
  /// **'УДЕРЖИВАТЬ'**
  String get sosHoldAction;

  /// No description provided for @sosHoldInstruction.
  ///
  /// In ru, this message translates to:
  /// **'Удерживайте кнопку 3 секунды\nдля отправки сигнала'**
  String get sosHoldInstruction;

  /// No description provided for @walkieNameTourist.
  ///
  /// In ru, this message translates to:
  /// **'Турист'**
  String get walkieNameTourist;

  /// No description provided for @walkieNameParticipant.
  ///
  /// In ru, this message translates to:
  /// **'Участник'**
  String get walkieNameParticipant;

  /// No description provided for @walkieErrorStartWave.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка запуска WAVE: {error}'**
  String walkieErrorStartWave(String error);

  /// No description provided for @walkiePingSent.
  ///
  /// In ru, this message translates to:
  /// **'Пинг отправлен! Участники поделятся геолокацией.'**
  String get walkiePingSent;

  /// No description provided for @walkieSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Offline Mesh Network'**
  String get walkieSubtitle;

  /// No description provided for @walkieInvitePrompt.
  ///
  /// In ru, this message translates to:
  /// **'Пригласите туристов в ту же поездку.'**
  String get walkieInvitePrompt;

  /// No description provided for @walkiePingButton.
  ///
  /// In ru, this message translates to:
  /// **'Пинг'**
  String get walkiePingButton;

  /// No description provided for @walkieNetworkActive.
  ///
  /// In ru, this message translates to:
  /// **'● Сеть WAVE активна · {count} участников'**
  String walkieNetworkActive(int count);

  /// No description provided for @walkieNetworkActiveBT.
  ///
  /// In ru, this message translates to:
  /// **' · 🔵 BT'**
  String get walkieNetworkActiveBT;

  /// No description provided for @walkieNetworkActiveFirebase.
  ///
  /// In ru, this message translates to:
  /// **' · ☁️ Firebase'**
  String get walkieNetworkActiveFirebase;

  /// No description provided for @walkieNetworkInactive.
  ///
  /// In ru, this message translates to:
  /// **'⚠ Сеть WAVE не активна'**
  String get walkieNetworkInactive;

  /// No description provided for @walkieTabChat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get walkieTabChat;

  /// No description provided for @walkieTabMembers.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get walkieTabMembers;

  /// No description provided for @walkieTabMap.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get walkieTabMap;

  /// No description provided for @walkieEmptyChatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет сообщений'**
  String get walkieEmptyChatTitle;

  /// No description provided for @walkieEmptyChatDesc.
  ///
  /// In ru, this message translates to:
  /// **'Отправьте первое offline-сообщение группе'**
  String get walkieEmptyChatDesc;

  /// No description provided for @walkieSharedLocation.
  ///
  /// In ru, this message translates to:
  /// **'📍 {userName} поделился(ась) геолокацией'**
  String walkieSharedLocation(String userName);

  /// No description provided for @walkieMessageHint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение (offline)'**
  String get walkieMessageHint;

  /// No description provided for @walkieEmptyMembersTitle.
  ///
  /// In ru, this message translates to:
  /// **'Нет участников'**
  String get walkieEmptyMembersTitle;

  /// No description provided for @walkieEmptyMembersDesc.
  ///
  /// In ru, this message translates to:
  /// **'Когда другие туристы откроют WAVE, они появятся здесь'**
  String get walkieEmptyMembersDesc;

  /// No description provided for @walkieUnknownUser.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный'**
  String get walkieUnknownUser;

  /// No description provided for @walkieStatusOnline.
  ///
  /// In ru, this message translates to:
  /// **'онлайн'**
  String get walkieStatusOnline;

  /// No description provided for @myOrdersAndChats.
  ///
  /// In ru, this message translates to:
  /// **'Мои заказы и чаты'**
  String get myOrdersAndChats;

  /// No description provided for @myOrdersLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки: {error}'**
  String myOrdersLoadError(String error);

  /// No description provided for @myOrdersNoSavedChats.
  ///
  /// In ru, this message translates to:
  /// **'Нет сохранённых чатов'**
  String get myOrdersNoSavedChats;

  /// No description provided for @myOrdersNoSavedChatsDesc.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появятся ваши активные переписки'**
  String get myOrdersNoSavedChatsDesc;

  /// No description provided for @myOrdersChatUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Чат недоступен или маршрут завершён давно'**
  String get myOrdersChatUnavailable;

  /// No description provided for @myOrdersDeleteChatTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить чат?'**
  String get myOrdersDeleteChatTitle;

  /// No description provided for @myOrdersDeleteChatDesc.
  ///
  /// In ru, this message translates to:
  /// **'Этот чат пропадёт из ваших сохранённых, но останется у других участников поездки.'**
  String get myOrdersDeleteChatDesc;

  /// No description provided for @myOrdersDeleteChatCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get myOrdersDeleteChatCancel;

  /// No description provided for @myOrdersDeleteChatConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get myOrdersDeleteChatConfirm;

  /// No description provided for @myOrdersNoOrders.
  ///
  /// In ru, this message translates to:
  /// **'Заказов пока нет'**
  String get myOrdersNoOrders;

  /// No description provided for @myOrdersNoOrdersDesc.
  ///
  /// In ru, this message translates to:
  /// **'Забронируйте маршрут из конструктора'**
  String get myOrdersNoOrdersDesc;

  /// No description provided for @myOrdersCreateRoute.
  ///
  /// In ru, this message translates to:
  /// **'Создать маршрут'**
  String get myOrdersCreateRoute;

  /// No description provided for @myOrdersTabUpcoming.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие'**
  String get myOrdersTabUpcoming;

  /// No description provided for @myOrdersTabPast.
  ///
  /// In ru, this message translates to:
  /// **'Завершенные'**
  String get myOrdersTabPast;

  /// No description provided for @myOrdersTabChats.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get myOrdersTabChats;

  /// No description provided for @bookingStatusPending.
  ///
  /// In ru, this message translates to:
  /// **'На рассмотрении'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждён'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusInProgress.
  ///
  /// In ru, this message translates to:
  /// **'В процессе'**
  String get bookingStatusInProgress;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменён'**
  String get bookingStatusCancelled;

  /// No description provided for @myOrdersRepeatRoute.
  ///
  /// In ru, this message translates to:
  /// **'Повторить маршрут'**
  String get myOrdersRepeatRoute;

  /// No description provided for @myOrdersDetailStartDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата начала'**
  String get myOrdersDetailStartDate;

  /// No description provided for @myOrdersDetailParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Участников'**
  String get myOrdersDetailParticipants;

  /// No description provided for @myOrdersDetailParticipantsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} чел.'**
  String myOrdersDetailParticipantsCount(int count);

  /// No description provided for @myOrdersDetailPrice.
  ///
  /// In ru, this message translates to:
  /// **'Стоимость'**
  String get myOrdersDetailPrice;

  /// No description provided for @myOrdersDetailGuide.
  ///
  /// In ru, this message translates to:
  /// **'Гид'**
  String get myOrdersDetailGuide;

  /// No description provided for @myOrdersDetailDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get myOrdersDetailDriver;

  /// No description provided for @myOrdersDetailAssigned.
  ///
  /// In ru, this message translates to:
  /// **'Назначен'**
  String get myOrdersDetailAssigned;

  /// No description provided for @myOrdersOpenRoute.
  ///
  /// In ru, this message translates to:
  /// **'Открыть маршрут'**
  String get myOrdersOpenRoute;

  /// No description provided for @tripCompletedShareSuccess.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут теперь доступен в популярных!'**
  String get tripCompletedShareSuccess;

  /// No description provided for @tripCompletedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут завершён!'**
  String get tripCompletedTitle;

  /// No description provided for @tripCompletedSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Поздравляем с успешным походом!'**
  String get tripCompletedSubtitle;

  /// No description provided for @tripCompletedStatsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Статистика маршрута'**
  String get tripCompletedStatsTitle;

  /// No description provided for @tripCompletedStatDistance.
  ///
  /// In ru, this message translates to:
  /// **'Дистанция'**
  String get tripCompletedStatDistance;

  /// No description provided for @tripCompletedStatTime.
  ///
  /// In ru, this message translates to:
  /// **'Время в пути'**
  String get tripCompletedStatTime;

  /// No description provided for @tripCompletedStatMaxHeight.
  ///
  /// In ru, this message translates to:
  /// **'Макс. высота'**
  String get tripCompletedStatMaxHeight;

  /// No description provided for @tripCompletedStatAvgSpeed.
  ///
  /// In ru, this message translates to:
  /// **'Средняя скорость'**
  String get tripCompletedStatAvgSpeed;

  /// No description provided for @tripCompletedAddToFavorites.
  ///
  /// In ru, this message translates to:
  /// **'Добавить в избранное'**
  String get tripCompletedAddToFavorites;

  /// No description provided for @tripCompletedFavRoute.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут'**
  String get tripCompletedFavRoute;

  /// No description provided for @tripCompletedFavGuide.
  ///
  /// In ru, this message translates to:
  /// **'Гид'**
  String get tripCompletedFavGuide;

  /// No description provided for @tripCompletedFavDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get tripCompletedFavDriver;

  /// No description provided for @tripCompletedShareAction.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться маршрутом'**
  String get tripCompletedShareAction;

  /// No description provided for @tripCompletedViewOrdersAction.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть в заказах'**
  String get tripCompletedViewOrdersAction;

  /// No description provided for @tripCompletedHomeAction.
  ///
  /// In ru, this message translates to:
  /// **'На главную'**
  String get tripCompletedHomeAction;

  /// No description provided for @messengerSendError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка отправки: {error}'**
  String messengerSendError(String error);

  /// No description provided for @messengerNoActiveRoute.
  ///
  /// In ru, this message translates to:
  /// **'Нет активного маршрута'**
  String get messengerNoActiveRoute;

  /// No description provided for @messengerNoActiveRouteDesc.
  ///
  /// In ru, this message translates to:
  /// **'Чат доступен только во время\nактивной поездки'**
  String get messengerNoActiveRouteDesc;

  /// No description provided for @messengerLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки чата'**
  String get messengerLoadError;

  /// No description provided for @messengerNoMessages.
  ///
  /// In ru, this message translates to:
  /// **'Нет сообщений. Напишите первым!'**
  String get messengerNoMessages;

  /// No description provided for @messengerRouteNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут не найден'**
  String get messengerRouteNotFound;

  /// No description provided for @messengerBookingNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Бронирование не найдено'**
  String get messengerBookingNotFound;

  /// No description provided for @messengerParticipantsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get messengerParticipantsTitle;

  /// No description provided for @messengerRoleOrganizer.
  ///
  /// In ru, this message translates to:
  /// **'Организатор'**
  String get messengerRoleOrganizer;

  /// No description provided for @messengerRoleGuide.
  ///
  /// In ru, this message translates to:
  /// **'Горный гид'**
  String get messengerRoleGuide;

  /// No description provided for @messengerRoleDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get messengerRoleDriver;

  /// No description provided for @messengerParticipantsLoadError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки участников: {error}'**
  String messengerParticipantsLoadError(String error);

  /// No description provided for @messengerChatSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Чат по маршруту'**
  String get messengerChatSubtitle;

  /// No description provided for @messengerDeleteChatUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'Удаление чата пока недоступно'**
  String get messengerDeleteChatUnavailable;

  /// No description provided for @messengerViewParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть участников'**
  String get messengerViewParticipants;

  /// No description provided for @messengerDeleteChat.
  ///
  /// In ru, this message translates to:
  /// **'Удалить чат'**
  String get messengerDeleteChat;

  /// No description provided for @messengerInputHint.
  ///
  /// In ru, this message translates to:
  /// **'Введите сообщение...'**
  String get messengerInputHint;

  /// No description provided for @activeTripStageScheduled.
  ///
  /// In ru, this message translates to:
  /// **'Забронировано'**
  String get activeTripStageScheduled;

  /// No description provided for @activeTripStageWaiting.
  ///
  /// In ru, this message translates to:
  /// **'Водитель едет'**
  String get activeTripStageWaiting;

  /// No description provided for @activeTripStageInProgress.
  ///
  /// In ru, this message translates to:
  /// **'В пути'**
  String get activeTripStageInProgress;

  /// No description provided for @activeTripStageCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Завершён'**
  String get activeTripStageCompleted;

  /// No description provided for @activeTripLocationPermError.
  ///
  /// In ru, this message translates to:
  /// **'Нет разрешения на геолокацию. Разрешите доступ в настройках.'**
  String get activeTripLocationPermError;

  /// No description provided for @activeTripProximityError.
  ///
  /// In ru, this message translates to:
  /// **'Вы в {dist} м от точки сбора. Нужно подойти ближе 100 м чтобы начать маршрут.'**
  String activeTripProximityError(String dist);

  /// No description provided for @activeTripDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель'**
  String get activeTripDriver;

  /// No description provided for @activeTripGuide.
  ///
  /// In ru, this message translates to:
  /// **'Гид'**
  String get activeTripGuide;

  /// No description provided for @activeTripWaitingForOthers.
  ///
  /// In ru, this message translates to:
  /// **'Ожидание готовности: {missing} ещё не на месте сбора (≤ 100 м).'**
  String activeTripWaitingForOthers(String missing);

  /// No description provided for @activeTripSaveErrorQuota.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сохранения — превышена квота Firestore.\nПодождите немного и попробуйте снова.'**
  String get activeTripSaveErrorQuota;

  /// No description provided for @activeTripNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут не найден'**
  String get activeTripNotFound;

  /// No description provided for @activeTripDefaultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут'**
  String get activeTripDefaultTitle;

  /// No description provided for @activeTripEta.
  ///
  /// In ru, this message translates to:
  /// **'Прибытие: {time}'**
  String activeTripEta(String time);

  /// No description provided for @activeTripDriverCompleted.
  ///
  /// In ru, this message translates to:
  /// **'Водитель завершил маршрут'**
  String get activeTripDriverCompleted;

  /// No description provided for @activeTripConfirmCompletionDesc.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердите, чтобы завершить поездку и разблокировать оплату'**
  String get activeTripConfirmCompletionDesc;

  /// No description provided for @activeTripConfirming.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждаем…'**
  String get activeTripConfirming;

  /// No description provided for @activeTripConfirmCompletionBtn.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить завершение'**
  String get activeTripConfirmCompletionBtn;

  /// No description provided for @activeTripChatDefaultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get activeTripChatDefaultTitle;

  /// No description provided for @activeTripGoToChat.
  ///
  /// In ru, this message translates to:
  /// **'Перейти в чат'**
  String get activeTripGoToChat;

  /// No description provided for @activeTripConfirmError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка подтверждения: {error}'**
  String activeTripConfirmError(String error);

  /// No description provided for @activeTripCancelTitle.
  ///
  /// In ru, this message translates to:
  /// **'Отменить маршрут?'**
  String get activeTripCancelTitle;

  /// No description provided for @activeTripCancelDesc.
  ///
  /// In ru, this message translates to:
  /// **'Дата маршрута прошла. Вы хотите отменить бронирование?'**
  String get activeTripCancelDesc;

  /// No description provided for @activeTripCancelNo.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get activeTripCancelNo;

  /// No description provided for @activeTripCancelYes.
  ///
  /// In ru, this message translates to:
  /// **'Да, отменить'**
  String get activeTripCancelYes;

  /// No description provided for @activeTripBookingDetails.
  ///
  /// In ru, this message translates to:
  /// **'Детали бронирования'**
  String get activeTripBookingDetails;

  /// No description provided for @activeTripBookingDates.
  ///
  /// In ru, this message translates to:
  /// **'Даты'**
  String get activeTripBookingDates;

  /// No description provided for @activeTripBookingParticipants.
  ///
  /// In ru, this message translates to:
  /// **'Участников'**
  String get activeTripBookingParticipants;

  /// No description provided for @activeTripBookingParticipantsCount.
  ///
  /// In ru, this message translates to:
  /// **'{count} чел.'**
  String activeTripBookingParticipantsCount(int count);

  /// No description provided for @activeTripBookingTotal.
  ///
  /// In ru, this message translates to:
  /// **'К оплате'**
  String get activeTripBookingTotal;

  /// No description provided for @activeTripDatePassed.
  ///
  /// In ru, this message translates to:
  /// **'Дата маршрута прошла'**
  String get activeTripDatePassed;

  /// No description provided for @activeTripCancelAction.
  ///
  /// In ru, this message translates to:
  /// **'Отменить маршрут'**
  String get activeTripCancelAction;

  /// No description provided for @activeTripTimeLeftDaysHours.
  ///
  /// In ru, this message translates to:
  /// **'Осталось {days} д. {hours} ч.'**
  String activeTripTimeLeftDaysHours(int days, int hours);

  /// No description provided for @activeTripTimeLeftHours.
  ///
  /// In ru, this message translates to:
  /// **'Осталось {hours} ч.'**
  String activeTripTimeLeftHours(int hours);

  /// No description provided for @activeTripStartingSoon.
  ///
  /// In ru, this message translates to:
  /// **'Начинается скоро!'**
  String get activeTripStartingSoon;

  /// No description provided for @activeTripGroupGathering.
  ///
  /// In ru, this message translates to:
  /// **'Водитель и группа собираются'**
  String get activeTripGroupGathering;

  /// No description provided for @activeTripActionReady.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить готовность'**
  String get activeTripActionReady;

  /// No description provided for @activeTripActionStart.
  ///
  /// In ru, this message translates to:
  /// **'Начать маршрут'**
  String get activeTripActionStart;

  /// No description provided for @activeTripActionEnd.
  ///
  /// In ru, this message translates to:
  /// **'Завершить маршрут'**
  String get activeTripActionEnd;

  /// No description provided for @rbStepPoints.
  ///
  /// In ru, this message translates to:
  /// **'Точки'**
  String get rbStepPoints;

  /// No description provided for @rbStepRoute.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут'**
  String get rbStepRoute;

  /// No description provided for @rbStepDetails.
  ///
  /// In ru, this message translates to:
  /// **'Детали'**
  String get rbStepDetails;

  /// No description provided for @rbTooltipBack.
  ///
  /// In ru, this message translates to:
  /// **'Отменить создание маршрута'**
  String get rbTooltipBack;

  /// No description provided for @rbTooltipMyLocation.
  ///
  /// In ru, this message translates to:
  /// **'Моё местоположение'**
  String get rbTooltipMyLocation;

  /// No description provided for @rbPanelWaypointsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Точки маршрута'**
  String get rbPanelWaypointsTitle;

  /// No description provided for @rbPanelTapHint.
  ///
  /// In ru, this message translates to:
  /// **'Тапните на карту, чтобы добавить точку'**
  String get rbPanelTapHint;

  /// No description provided for @rbPanelMyLocationStart.
  ///
  /// In ru, this message translates to:
  /// **'Моё местоположение как старт'**
  String get rbPanelMyLocationStart;

  /// No description provided for @rbPanelMaxPoints.
  ///
  /// In ru, this message translates to:
  /// **'Максимум 10 точек'**
  String get rbPanelMaxPoints;

  /// No description provided for @rbTooltipUndo.
  ///
  /// In ru, this message translates to:
  /// **'Удалить последнюю точку'**
  String get rbTooltipUndo;

  /// No description provided for @rbTooltipClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить все точки'**
  String get rbTooltipClear;

  /// No description provided for @rbBuildRoute.
  ///
  /// In ru, this message translates to:
  /// **'Построить маршрут'**
  String get rbBuildRoute;

  /// No description provided for @rbLoadingTitle.
  ///
  /// In ru, this message translates to:
  /// **'Строим маршрут…'**
  String get rbLoadingTitle;

  /// No description provided for @rbLoadingSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Запрашиваем данные Яндекс Карт'**
  String get rbLoadingSubtitle;

  /// No description provided for @rbStatDistance.
  ///
  /// In ru, this message translates to:
  /// **'Расстояние'**
  String get rbStatDistance;

  /// No description provided for @rbStatDistanceKm.
  ///
  /// In ru, this message translates to:
  /// **'{km} км'**
  String rbStatDistanceKm(Object km);

  /// No description provided for @rbStatTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get rbStatTime;

  /// No description provided for @rbStatTimeLessHour.
  ///
  /// In ru, this message translates to:
  /// **'< 1 ч'**
  String get rbStatTimeLessHour;

  /// No description provided for @rbStatTimeHours.
  ///
  /// In ru, this message translates to:
  /// **'{h} ч'**
  String rbStatTimeHours(Object h);

  /// No description provided for @rbStatByRoad.
  ///
  /// In ru, this message translates to:
  /// **'По дорогам'**
  String get rbStatByRoad;

  /// No description provided for @rbStatStraightLine.
  ///
  /// In ru, this message translates to:
  /// **'По прямой'**
  String get rbStatStraightLine;

  /// No description provided for @rbStatYandex.
  ///
  /// In ru, this message translates to:
  /// **'Яндекс'**
  String get rbStatYandex;

  /// No description provided for @rbStatEstimate.
  ///
  /// In ru, this message translates to:
  /// **'Оценка'**
  String get rbStatEstimate;

  /// No description provided for @rbReset.
  ///
  /// In ru, this message translates to:
  /// **'Заново'**
  String get rbReset;

  /// No description provided for @rbContinue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get rbContinue;

  /// No description provided for @rbWaypointStart.
  ///
  /// In ru, this message translates to:
  /// **'Старт'**
  String get rbWaypointStart;

  /// No description provided for @rbWaypointFinish.
  ///
  /// In ru, this message translates to:
  /// **'Финиш'**
  String get rbWaypointFinish;

  /// No description provided for @rbWaypointMid.
  ///
  /// In ru, this message translates to:
  /// **'Остановка {n}'**
  String rbWaypointMid(int n);

  /// No description provided for @rbMyLocationLabel.
  ///
  /// In ru, this message translates to:
  /// **'Моё местоположение'**
  String get rbMyLocationLabel;

  /// No description provided for @rbDefaultRouteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Свой маршрут'**
  String get rbDefaultRouteTitle;

  /// No description provided for @rbErrorFallback.
  ///
  /// In ru, this message translates to:
  /// **'Маршрут по дорогам недоступен — показано прямое расстояние'**
  String get rbErrorFallback;

  /// No description provided for @rbErrorBuild.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка при построении маршрута'**
  String get rbErrorBuild;

  /// No description provided for @settingsLoading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка...'**
  String get settingsLoading;

  /// No description provided for @settingsFieldFirstName.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get settingsFieldFirstName;

  /// No description provided for @settingsFieldLastName.
  ///
  /// In ru, this message translates to:
  /// **'Фамилия'**
  String get settingsFieldLastName;

  /// No description provided for @settingsFieldEmail.
  ///
  /// In ru, this message translates to:
  /// **'Email'**
  String get settingsFieldEmail;

  /// No description provided for @settingsFieldPhone.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get settingsFieldPhone;

  /// No description provided for @settingsFieldBirthDate.
  ///
  /// In ru, this message translates to:
  /// **'Дата рождения'**
  String get settingsFieldBirthDate;

  /// No description provided for @settingsSaveChanges.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get settingsSaveChanges;

  /// No description provided for @settingsDataSaved.
  ///
  /// In ru, this message translates to:
  /// **'Данные сохранены'**
  String get settingsDataSaved;

  /// No description provided for @settingsApplyButton.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get settingsApplyButton;

  /// No description provided for @settingsDeleteButton.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get settingsDeleteButton;

  /// No description provided for @roleMountainGuide.
  ///
  /// In ru, this message translates to:
  /// **'Горный гид'**
  String get roleMountainGuide;

  /// No description provided for @roleCityGuide.
  ///
  /// In ru, this message translates to:
  /// **'Городской обзорный гид'**
  String get roleCityGuide;

  /// No description provided for @roleSuvDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель внедорожника'**
  String get roleSuvDriver;

  /// No description provided for @roleBusDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель автобуса'**
  String get roleBusDriver;

  /// No description provided for @roleMinibusDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель микроавтобуса'**
  String get roleMinibusDriver;

  /// No description provided for @roleMinivanDriver.
  ///
  /// In ru, this message translates to:
  /// **'Водитель минивена'**
  String get roleMinivanDriver;

  /// No description provided for @partnerProfileReviews.
  ///
  /// In ru, this message translates to:
  /// **'({count} отзывов)'**
  String partnerProfileReviews(int count);

  /// No description provided for @partnerProfileAboutMe.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get partnerProfileAboutMe;

  /// No description provided for @partnerProfileCarDetails.
  ///
  /// In ru, this message translates to:
  /// **'Детали автомобиля'**
  String get partnerProfileCarDetails;

  /// No description provided for @partnerProfileVehicleModel.
  ///
  /// In ru, this message translates to:
  /// **'Модель'**
  String get partnerProfileVehicleModel;

  /// No description provided for @partnerProfileVehicleClass.
  ///
  /// In ru, this message translates to:
  /// **'Класс'**
  String get partnerProfileVehicleClass;

  /// No description provided for @partnerProfileVehicleCapacity.
  ///
  /// In ru, this message translates to:
  /// **'Вместимость'**
  String get partnerProfileVehicleCapacity;

  /// No description provided for @partnerProfileVehicleCapacityValue.
  ///
  /// In ru, this message translates to:
  /// **'{count} чел. (вкл. водителя)'**
  String partnerProfileVehicleCapacityValue(int count);

  /// No description provided for @partnerProfileRate.
  ///
  /// In ru, this message translates to:
  /// **'Ставка'**
  String get partnerProfileRate;

  /// No description provided for @partnerProfileRatePerKm.
  ///
  /// In ru, this message translates to:
  /// **'{amount} ₸ / км'**
  String partnerProfileRatePerKm(int amount);

  /// No description provided for @partnerProfileRatePerDay.
  ///
  /// In ru, this message translates to:
  /// **'{amount} ₸ / день'**
  String partnerProfileRatePerDay(int amount);

  /// No description provided for @partnerProfileSpecialization.
  ///
  /// In ru, this message translates to:
  /// **'Специализация'**
  String get partnerProfileSpecialization;

  /// No description provided for @partnerProfileExperience.
  ///
  /// In ru, this message translates to:
  /// **'Опыт работы'**
  String get partnerProfileExperience;

  /// No description provided for @partnerProfileExperienceYears.
  ///
  /// In ru, this message translates to:
  /// **'{count} лет'**
  String partnerProfileExperienceYears(int count);

  /// No description provided for @partnerProfileLanguages.
  ///
  /// In ru, this message translates to:
  /// **'Языки'**
  String get partnerProfileLanguages;

  /// No description provided for @partnerProfileDestinations.
  ///
  /// In ru, this message translates to:
  /// **'Направления'**
  String get partnerProfileDestinations;

  /// No description provided for @settingsRelationWife.
  ///
  /// In ru, this message translates to:
  /// **'Супруга'**
  String get settingsRelationWife;

  /// No description provided for @settingsRelationHusband.
  ///
  /// In ru, this message translates to:
  /// **'Супруг'**
  String get settingsRelationHusband;

  /// No description provided for @settingsRelationFriend.
  ///
  /// In ru, this message translates to:
  /// **'Друг'**
  String get settingsRelationFriend;

  /// No description provided for @settingsRelationEmergency.
  ///
  /// In ru, this message translates to:
  /// **'Служба спасения'**
  String get settingsRelationEmergency;
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
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
