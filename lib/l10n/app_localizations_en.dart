// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Explora';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfile => 'Profile';

  @override
  String get settingsPersonalData => 'Personal Data';

  @override
  String get settingsNotSpecified => 'Not specified';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsSosContacts => 'SOS Contacts';

  @override
  String get settingsEmergencyAlerts => 'Emergency Alerts';

  @override
  String settingsContactsCount(int count) {
    return '$count contacts';
  }

  @override
  String get settingsApp => 'Application';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsPrivacyLog => 'Privacy Policy';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get settingsThemeDark => 'Dark Mode';

  @override
  String get settingsThemeLight => 'Light Mode';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsSelectLanguage => 'App Language';

  @override
  String get settingsApply => 'Apply';

  @override
  String get settingsThemeTitle => 'App Theme';

  @override
  String get settingsThemeDarkDesc => 'Dark theme for night trips';

  @override
  String get settingsThemeLightDesc => 'Light theme for daytime use';

  @override
  String get settingsThemeAutoDesc => 'Switch automatically';

  @override
  String get settingsSosDeleteDesc =>
      'These contacts will be notified upon emergency signal activation';

  @override
  String get settingsAddContact => 'Add Contact';

  @override
  String get settingsDeleteAccountTitle => 'Delete Account';

  @override
  String get settingsDeleteAccountDesc =>
      'Are you sure you want to delete your account? This action is irreversible, and all your data will be permanently lost.';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get homeSearchHint => 'Where to?';

  @override
  String get homeActiveTrips => 'My Active Trips';

  @override
  String get homeActiveTripsTap => 'Tap to open route';

  @override
  String get homeCreateRoute => 'Create Route';

  @override
  String get homeCreateRouteDesc => 'Via AI Builder';

  @override
  String get homeWhereTo => 'Anywhere!';

  @override
  String get homeSmartSelection => 'Smart route selection';

  @override
  String get homePopularRoutes => 'Popular Routes';

  @override
  String get homeAll => 'All';

  @override
  String get homeProfileHintTitle => 'Profile Photo and Album';

  @override
  String get homeProfileHintDesc =>
      'You can update your style and save precious memories by adding a photo to your album or profile.';

  @override
  String get homeProfileHintGotIt => 'Got it';

  @override
  String homeDaysAbbr(int count) {
    return '$count d.';
  }

  @override
  String get authEnterPhone => 'Enter phone number';

  @override
  String get authEnterSmsCode => 'Enter SMS code';

  @override
  String get authFillEmailPassword => 'Enter email and password';

  @override
  String get authUnknownError => 'Unknown error';

  @override
  String get authGoogleError => 'Google authorization error';

  @override
  String get authLoginTab => 'Log In';

  @override
  String get authRegisterTab => 'Register';

  @override
  String get authPhoneTab => 'Phone';

  @override
  String get authPhoneHint => 'Number (+1...)';

  @override
  String get authSmsCodeHint => 'SMS code';

  @override
  String get authChangePhone => 'Change number';

  @override
  String get authEmailHint => 'Email';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authLoginButton => 'Log In';

  @override
  String get authRegisterButton => 'Create an account';

  @override
  String get authConfirmButton => 'Confirm';

  @override
  String get authGetSmsButton => 'Get SMS code';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authOrWith => 'Or continue with';

  @override
  String get authInDevelopment => 'In development';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetPasswordDesc =>
      'Enter your email — we will send a password reset link.';

  @override
  String get authCancel => 'Cancel';

  @override
  String get authSend => 'Send';

  @override
  String get authEmailSent => 'Email sent — check your inbox';

  @override
  String get authSendError => 'Sending error';

  @override
  String get onboardingSlide1Title => 'Your guide';

  @override
  String get onboardingSlide1Desc =>
      'Explore wild places with confidence. Our maps work offline.';

  @override
  String get onboardingSlide2Title => 'Unique routes';

  @override
  String get onboardingSlide2Desc =>
      'Thousands of verified trails from professional guides and the community.';

  @override
  String get onboardingSlide3Title => 'Full support';

  @override
  String get onboardingSlide3Desc =>
      'Book transport, guides, and insurance in one app.';

  @override
  String get onboardingStart => 'Start exploring';

  @override
  String get onboardingNext => 'Next';

  @override
  String get profileUpdatePhoto => 'Update profile photo';

  @override
  String get profileAddPhotoToAlbum => 'Add photo to album';

  @override
  String get profileUserNotAuthorized => 'User not authorized';

  @override
  String get profileWalletBalance => 'Wallet balance';

  @override
  String get profileMyOrders => 'My orders and chats';

  @override
  String get profileFavorites => 'Favorites';

  @override
  String get profileDocuments => 'Documents';

  @override
  String get profileMyAlbum => 'My album';

  @override
  String get profileNoPhotosYet => 'No photos here yet';

  @override
  String get profileAddMemories => 'Add memories by tapping +';

  @override
  String get profileLogout => 'Log out';

  @override
  String get docsInsurancePolicy => 'Insurance policy';

  @override
  String get docsInsurancePolicyDesc => 'No. 89320-YDX • Active until Sep 25';

  @override
  String get docsPassport => 'Passport';

  @override
  String get docsPassportDesc => '**** 4512 • Ivanov D.A.';

  @override
  String get docsTourVoucher => 'Tour voucher';

  @override
  String get docsTourVoucherDesc => 'Altai • September 24';

  @override
  String get favoritesTabRoutes => 'Routes';

  @override
  String get favoritesTabGuides => 'Guides';

  @override
  String get favoritesTabCars => 'Cars';

  @override
  String get authRequired => 'Authorization required';

  @override
  String get userLoadError => 'Error loading user';

  @override
  String get favoritesNoRoutes => 'No favorite routes';

  @override
  String get favoritesNoGuides => 'No favorite guides';

  @override
  String get favoritesNoCars => 'No favorite cars';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyModerate => 'Moderate';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get activeTripMessenger => 'Messenger';

  @override
  String get homeRouteConstructor => 'Route Constructor';

  @override
  String get homeCurrentTrip => 'Current Trip';

  @override
  String get homeStatusInProgress => 'In progress';

  @override
  String get homeStatusWaiting => 'Waiting for driver';

  @override
  String get homeStatusBooked => 'Booked';

  @override
  String get homeArrivalPrefix => 'Arrival: ';

  @override
  String get homeChat => 'Chat';

  @override
  String get homeMessenger => 'Messenger';

  @override
  String get homeErrorPrefix => 'Error: ';

  @override
  String get homeNoRoutesAvailable => 'No routes available';

  @override
  String get homeUnderstand => 'Got it';

  @override
  String get activeTripsTitle => 'Active trips';

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get noActiveTrips => 'You have no active trips';

  @override
  String routeNumLabel(String num) {
    return 'Route $num';
  }

  @override
  String get statusWaitingDriver => 'Waiting for driver';

  @override
  String get statusOnWay => 'On the way';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionMoreInfo => 'More info';

  @override
  String get actionCancelRoute => 'Cancel route';

  @override
  String get hintRenameRoute => 'Example: Trip to mountains';

  @override
  String get errorEnterName => 'Enter a name';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get dialogCancelRouteTitle => 'Cancel route';

  @override
  String get dialogCancelRouteDesc =>
      'Are you sure you want to cancel this route? Refunds will be processed according to cancellation rules.';

  @override
  String get actionDoNotCancel => 'Do not cancel';

  @override
  String get actionYesCancel => 'Yes, cancel';

  @override
  String get msgRouteCancelled => 'Route cancelled';

  @override
  String errorCancelRoute(String message) {
    return 'Error cancelling: $message';
  }

  @override
  String get waypointStart => 'Start';

  @override
  String get waypointEnd => 'End';

  @override
  String get reviewsCount => 'reviews';

  @override
  String get bookTourAction => 'Book tour';

  @override
  String get bookingDetailsTitle => 'Trip details';

  @override
  String get routeNameLabelOptional => 'Route name (optional)';

  @override
  String get routeDatesLabel => 'Route dates';

  @override
  String get peopleCountLabel => 'Number of people';

  @override
  String get transportOptionalLabel => 'Transport';

  @override
  String get selectTransportLabel => 'Select transport';

  @override
  String get roadTypeConditionsLabel => 'Road type & conditions';

  @override
  String get guideOptionalLabel => 'Guide';

  @override
  String get selectGuideLabel => 'Select guide';

  @override
  String get additionalLabel => 'Additional';

  @override
  String get bookAction => 'Book now';

  @override
  String get calculationDetailsTitle => 'Calculation details';

  @override
  String get errorUserNotFound => 'Error: user not found.';

  @override
  String get errorActiveTripExists =>
      'You already have an active route. Please complete it before creating a new one.';

  @override
  String get errorSelectVehicle => 'Please select a vehicle (driver).';

  @override
  String get roadTypeAsphalt => 'Asphalt';

  @override
  String get roadTypeGravel => 'Gravel/Dirt';

  @override
  String get roadTypeOffroad => 'Hard Offroad';

  @override
  String get nightTripLabel => 'Night trip';

  @override
  String get nightTripDesc => 'Trip includes night time';

  @override
  String get hintRouteNameExample => 'Enter a name (e.g. Mountain trip)';

  @override
  String waypointStop(int index) {
    return 'Stop $index';
  }

  @override
  String get actionChange => 'Change';

  @override
  String maxPeopleLimit(int limit) {
    return 'Maximum for this vehicle/guide: $limit pers.';
  }

  @override
  String get guideServiceDesc => 'For interesting facts';

  @override
  String get driverServiceDesc => 'With a driver';

  @override
  String get noDriversAvailable =>
      'No drivers available for selected vehicle type.';

  @override
  String get noGuidesAvailable => 'No guides available for selected type.';

  @override
  String seatsAvailable(int total, int tourists) {
    return 'Seats: $total ($tourists for tourists)';
  }

  @override
  String get currencyPerKm => 'KZT/km';

  @override
  String get currencyPerDay => 'KZT/day';

  @override
  String receiptVehicle(String vType, int days) {
    return '🚙 $vType, $days days';
  }

  @override
  String receiptGuide(int days) {
    return '🗣 Guide services, $days days';
  }

  @override
  String receiptEcoTax(int people) {
    return '🌲 Eco tax ($people pers. + auto)';
  }

  @override
  String receiptInsurance(int people) {
    return '🛡 Mountain insurance ($people pers.)';
  }

  @override
  String get receiptTotal => 'Total';

  @override
  String get priceIncludesServiceFee => '*Price includes platform service fee';

  @override
  String get insuranceTitle => 'Mountain / Offroad insurance';

  @override
  String get insuranceDesc => 'Risk coverage for active tourism';

  @override
  String get vehicleSuv => 'SUV';

  @override
  String get vehicleBus => 'Bus';

  @override
  String get vehicleMinibus => 'Minibus';

  @override
  String get vehicleMinivan => 'Minivan';

  @override
  String get vehicleDefault => 'Transport';

  @override
  String get month1 => 'January';

  @override
  String get month2 => 'February';

  @override
  String get month3 => 'March';

  @override
  String get month4 => 'April';

  @override
  String get month5 => 'May';

  @override
  String get month6 => 'June';

  @override
  String get month7 => 'July';

  @override
  String get month8 => 'August';

  @override
  String get month9 => 'September';

  @override
  String get month10 => 'October';

  @override
  String get month11 => 'November';

  @override
  String get month12 => 'December';

  @override
  String get weekday1 => 'Monday';

  @override
  String get weekday2 => 'Tuesday';

  @override
  String get weekday3 => 'Wednesday';

  @override
  String get weekday4 => 'Thursday';

  @override
  String get weekday5 => 'Friday';

  @override
  String get weekday6 => 'Saturday';

  @override
  String get weekday7 => 'Sunday';

  @override
  String get sosEmergencyMode => 'EMERGENCY MODE';

  @override
  String get sosGuideToggle => 'To group guide';

  @override
  String get sosDriverToggle => 'To driver';

  @override
  String get sosRescueServiceToggle => 'Rescue service';

  @override
  String get sosCurrentCoordinates => 'CURRENT COORDINATES';

  @override
  String get sosSignalSent => 'Signal sent';

  @override
  String get sosCoordinatesTransmitted => 'Coordinates transmitted to rescuers';

  @override
  String get sosButtonText => 'SOS';

  @override
  String get sosHoldAction => 'HOLD';

  @override
  String get sosHoldInstruction => 'Hold button for 3 seconds\nto send signal';

  @override
  String get walkieNameTourist => 'Tourist';

  @override
  String get walkieNameParticipant => 'Participant';

  @override
  String walkieErrorStartWave(String error) {
    return 'WAVE startup error: $error';
  }

  @override
  String get walkiePingSent =>
      'Ping sent! Participants will share their location.';

  @override
  String get walkieSubtitle => 'Offline Mesh Network';

  @override
  String get walkieInvitePrompt => 'Invite tourists to the same trip.';

  @override
  String get walkiePingButton => 'Ping';

  @override
  String walkieNetworkActive(int count) {
    return '● WAVE Network active · $count participant(s)';
  }

  @override
  String get walkieNetworkActiveBT => ' · 🔵 BT';

  @override
  String get walkieNetworkActiveFirebase => ' · ☁️ Firebase';

  @override
  String get walkieNetworkInactive => '⚠ WAVE Network inactive';

  @override
  String get walkieTabChat => 'Chat';

  @override
  String get walkieTabMembers => 'Members';

  @override
  String get walkieTabMap => 'Map';

  @override
  String get walkieEmptyChatTitle => 'No messages';

  @override
  String get walkieEmptyChatDesc =>
      'Send the first offline message to the group';

  @override
  String walkieSharedLocation(String userName) {
    return '📍 $userName shared their location';
  }

  @override
  String get walkieMessageHint => 'Message (offline)';

  @override
  String get walkieEmptyMembersTitle => 'No members';

  @override
  String get walkieEmptyMembersDesc =>
      'When other tourists open WAVE, they will appear here';

  @override
  String get walkieUnknownUser => 'Unknown';

  @override
  String get walkieStatusOnline => 'online';

  @override
  String get myOrdersAndChats => 'My orders and chats';

  @override
  String myOrdersLoadError(String error) {
    return 'Loading error: $error';
  }

  @override
  String get myOrdersNoSavedChats => 'No saved chats';

  @override
  String get myOrdersNoSavedChatsDesc =>
      'Your active conversations will appear here';

  @override
  String get myOrdersChatUnavailable =>
      'Chat unavailable or route finished long ago';

  @override
  String get myOrdersDeleteChatTitle => 'Delete chat?';

  @override
  String get myOrdersDeleteChatDesc =>
      'This chat will disappear from your saved ones, but will remain with other participants.';

  @override
  String get myOrdersDeleteChatCancel => 'Cancel';

  @override
  String get myOrdersDeleteChatConfirm => 'Delete';

  @override
  String get myOrdersNoOrders => 'No orders yet';

  @override
  String get myOrdersNoOrdersDesc => 'Book a route from the constructor';

  @override
  String get myOrdersCreateRoute => 'Create Route';

  @override
  String get myOrdersTabUpcoming => 'Upcoming';

  @override
  String get myOrdersTabPast => 'Past';

  @override
  String get myOrdersTabChats => 'Chats';

  @override
  String get bookingStatusPending => 'Pending';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusInProgress => 'In progress';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get myOrdersRepeatRoute => 'Repeat route';

  @override
  String get myOrdersDetailStartDate => 'Start date';

  @override
  String get myOrdersDetailParticipants => 'Participants';

  @override
  String myOrdersDetailParticipantsCount(int count) {
    return '$count ppl';
  }

  @override
  String get myOrdersDetailPrice => 'Price';

  @override
  String get myOrdersDetailGuide => 'Guide';

  @override
  String get myOrdersDetailDriver => 'Driver';

  @override
  String get myOrdersDetailAssigned => 'Assigned';

  @override
  String get myOrdersOpenRoute => 'Open route';

  @override
  String get tripCompletedShareSuccess =>
      'Route is now available in popular trips!';

  @override
  String get tripCompletedTitle => 'Trip Completed!';

  @override
  String get tripCompletedSubtitle => 'Congratulations on a successful hike!';

  @override
  String get tripCompletedStatsTitle => 'Trip Statistics';

  @override
  String get tripCompletedStatDistance => 'Distance';

  @override
  String get tripCompletedStatTime => 'Time en route';

  @override
  String get tripCompletedStatMaxHeight => 'Max altitude';

  @override
  String get tripCompletedStatAvgSpeed => 'Avg speed';

  @override
  String get tripCompletedAddToFavorites => 'Add to Favorites';

  @override
  String get tripCompletedFavRoute => 'Route';

  @override
  String get tripCompletedFavGuide => 'Guide';

  @override
  String get tripCompletedFavDriver => 'Driver';

  @override
  String get tripCompletedShareAction => 'Share trip';

  @override
  String get tripCompletedViewOrdersAction => 'View in Orders';

  @override
  String get tripCompletedHomeAction => 'Back to Home';

  @override
  String messengerSendError(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get messengerNoActiveRoute => 'No active route';

  @override
  String get messengerNoActiveRouteDesc =>
      'Chat is only available during\nan active trip';

  @override
  String get messengerLoadError => 'Failed to load chat';

  @override
  String get messengerNoMessages => 'No messages yet. Be the first to write!';

  @override
  String get messengerRouteNotFound => 'Route not found';

  @override
  String get messengerBookingNotFound => 'Booking not found';

  @override
  String get messengerParticipantsTitle => 'Participants';

  @override
  String get messengerRoleOrganizer => 'Organizer';

  @override
  String get messengerRoleGuide => 'Mountain Guide';

  @override
  String get messengerRoleDriver => 'Driver';

  @override
  String messengerParticipantsLoadError(String error) {
    return 'Failed to load participants: $error';
  }

  @override
  String get messengerChatSubtitle => 'Trip chat';

  @override
  String get messengerDeleteChatUnavailable =>
      'Deleting chat is currently unavailable';

  @override
  String get messengerViewParticipants => 'View participants';

  @override
  String get messengerDeleteChat => 'Delete chat';

  @override
  String get messengerInputHint => 'Type a message...';

  @override
  String get activeTripStageScheduled => 'Scheduled';

  @override
  String get activeTripStageWaiting => 'Driver is arriving';

  @override
  String get activeTripStageInProgress => 'In progress';

  @override
  String get activeTripStageCompleted => 'Completed';

  @override
  String get activeTripLocationPermError =>
      'No location permission. Please allow access in settings.';

  @override
  String activeTripProximityError(String dist) {
    return 'You are $dist m away from the meeting point. You must be within 100 m to start.';
  }

  @override
  String get activeTripDriver => 'Driver';

  @override
  String get activeTripGuide => 'Guide';

  @override
  String activeTripWaitingForOthers(String missing) {
    return 'Waiting: $missing not yet at the meeting point (≤ 100 m).';
  }

  @override
  String get activeTripSaveErrorQuota =>
      'Failed to save — Firestore quota exceeded.\nPlease wait and try again.';

  @override
  String get activeTripNotFound => 'Trip not found';

  @override
  String get activeTripDefaultTitle => 'Trip';

  @override
  String activeTripEta(String time) {
    return 'Arrival: $time';
  }

  @override
  String get activeTripDriverCompleted => 'Driver completed the trip';

  @override
  String get activeTripConfirmCompletionDesc =>
      'Please confirm to complete the trip and unlock payment';

  @override
  String get activeTripConfirming => 'Confirming...';

  @override
  String get activeTripConfirmCompletionBtn => 'Confirm completion';

  @override
  String get activeTripChatDefaultTitle => 'Chat';

  @override
  String get activeTripGoToChat => 'Go to chat';

  @override
  String activeTripConfirmError(String error) {
    return 'Failed to confirm: $error';
  }

  @override
  String get activeTripCancelTitle => 'Cancel trip?';

  @override
  String get activeTripCancelDesc =>
      'The trip date has passed. Do you want to cancel the booking?';

  @override
  String get activeTripCancelNo => 'No';

  @override
  String get activeTripCancelYes => 'Yes, cancel';

  @override
  String get activeTripBookingDetails => 'Booking details';

  @override
  String get activeTripBookingDates => 'Dates';

  @override
  String get activeTripBookingParticipants => 'Participants';

  @override
  String activeTripBookingParticipantsCount(int count) {
    return '$count guests';
  }

  @override
  String get activeTripBookingTotal => 'Total to pay';

  @override
  String get activeTripDatePassed => 'Trip date has passed';

  @override
  String get activeTripCancelAction => 'Cancel trip';

  @override
  String activeTripTimeLeftDaysHours(int days, int hours) {
    return '$days d $hours h left';
  }

  @override
  String activeTripTimeLeftHours(int hours) {
    return '$hours h left';
  }

  @override
  String get activeTripStartingSoon => 'Starting soon!';

  @override
  String get activeTripGroupGathering => 'Driver and group gathering';

  @override
  String get activeTripActionReady => 'Confirm readiness';

  @override
  String get activeTripActionStart => 'Start trip';

  @override
  String get activeTripActionEnd => 'Complete trip';

  @override
  String get rbStepPoints => 'Points';

  @override
  String get rbStepRoute => 'Route';

  @override
  String get rbStepDetails => 'Details';

  @override
  String get rbTooltipBack => 'Cancel route creation';

  @override
  String get rbTooltipMyLocation => 'My location';

  @override
  String get rbPanelWaypointsTitle => 'Route points';

  @override
  String get rbPanelTapHint => 'Tap on the map to add a point';

  @override
  String get rbPanelMyLocationStart => 'My location as start';

  @override
  String get rbPanelMaxPoints => 'Maximum 10 points';

  @override
  String get rbTooltipUndo => 'Remove last point';

  @override
  String get rbTooltipClear => 'Clear all points';

  @override
  String get rbBuildRoute => 'Build route';

  @override
  String get rbLoadingTitle => 'Building route…';

  @override
  String get rbLoadingSubtitle => 'Requesting Yandex Maps data';

  @override
  String get rbStatDistance => 'Distance';

  @override
  String rbStatDistanceKm(Object km) {
    return '$km km';
  }

  @override
  String get rbStatTime => 'Time';

  @override
  String get rbStatTimeLessHour => '< 1 h';

  @override
  String rbStatTimeHours(Object h) {
    return '$h h';
  }

  @override
  String get rbStatByRoad => 'By road';

  @override
  String get rbStatStraightLine => 'Straight line';

  @override
  String get rbStatYandex => 'Yandex';

  @override
  String get rbStatEstimate => 'Estimate';

  @override
  String get rbReset => 'Reset';

  @override
  String get rbContinue => 'Continue';

  @override
  String get rbWaypointStart => 'Start';

  @override
  String get rbWaypointFinish => 'Finish';

  @override
  String rbWaypointMid(int n) {
    return 'Stop $n';
  }

  @override
  String get rbMyLocationLabel => 'My location';

  @override
  String get rbDefaultRouteTitle => 'My route';

  @override
  String get rbErrorFallback =>
      'Road-based route unavailable — showing straight-line distance';

  @override
  String get rbErrorBuild => 'Error building the route';

  @override
  String get settingsLoading => 'Loading...';

  @override
  String get settingsFieldFirstName => 'First name';

  @override
  String get settingsFieldLastName => 'Last name';

  @override
  String get settingsFieldEmail => 'Email';

  @override
  String get settingsFieldPhone => 'Phone';

  @override
  String get settingsFieldBirthDate => 'Date of birth';

  @override
  String get settingsSaveChanges => 'Save changes';

  @override
  String get settingsDataSaved => 'Data saved';

  @override
  String get settingsApplyButton => 'Apply';

  @override
  String get settingsDeleteButton => 'Delete';

  @override
  String get roleMountainGuide => 'Mountain Guide';

  @override
  String get roleCityGuide => 'City Guide';

  @override
  String get roleSuvDriver => 'SUV Driver';

  @override
  String get roleBusDriver => 'Bus Driver';

  @override
  String get roleMinibusDriver => 'Minibus Driver';

  @override
  String get roleMinivanDriver => 'Minivan Driver';

  @override
  String partnerProfileReviews(int count) {
    return '($count reviews)';
  }

  @override
  String get partnerProfileAboutMe => 'About Me';

  @override
  String get partnerProfileCarDetails => 'Car Details';

  @override
  String get partnerProfileVehicleModel => 'Model';

  @override
  String get partnerProfileVehicleClass => 'Class';

  @override
  String get partnerProfileVehicleCapacity => 'Capacity';

  @override
  String partnerProfileVehicleCapacityValue(int count) {
    return '$count ppl (incl. driver)';
  }

  @override
  String get partnerProfileRate => 'Rate';

  @override
  String partnerProfileRatePerKm(int amount) {
    return '$amount ₸ / km';
  }

  @override
  String partnerProfileRatePerDay(int amount) {
    return '$amount ₸ / day';
  }

  @override
  String get partnerProfileSpecialization => 'Specialization';

  @override
  String get partnerProfileExperience => 'Experience';

  @override
  String partnerProfileExperienceYears(int count) {
    return '$count years';
  }

  @override
  String get partnerProfileLanguages => 'Languages';

  @override
  String get partnerProfileDestinations => 'Destinations';

  @override
  String get settingsRelationWife => 'Wife';

  @override
  String get settingsRelationHusband => 'Husband';

  @override
  String get settingsRelationFriend => 'Friend';

  @override
  String get settingsRelationEmergency => 'Emergency Service';
}
