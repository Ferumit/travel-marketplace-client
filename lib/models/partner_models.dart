import '../l10n/app_localizations.dart';

/// Роль партнёра в системе Explora.
enum PartnerRole {
  /// Гид пешеходных / эко маршрутов
  guide,

  /// Городской обзорный гид
  cityGuide,

  /// Водитель внедорожника
  suvDriver,

  /// Водитель автобуса (большие группы)
  busDriver,

  /// Водитель микроавтобуса (до 15 чел.)
  minibusDriver,

  /// Водитель минивена (комфорт до 7 чел.)
  minivanDriver,
}

/// Расширение для получения читаемого названия роли на русском.
extension PartnerRoleX on PartnerRole {
  String getLocalizedName(AppLocalizations l10n) => switch (this) {
    PartnerRole.guide => l10n.roleMountainGuide,
    PartnerRole.cityGuide => l10n.roleCityGuide,
    PartnerRole.suvDriver => l10n.roleSuvDriver,
    PartnerRole.busDriver => l10n.roleBusDriver,
    PartnerRole.minibusDriver => l10n.roleMinibusDriver,
    PartnerRole.minivanDriver => l10n.roleMinivanDriver,
  };

  /// Читаемое название роли (по умолчанию на русском, рекомендуется использовать getLocalizedName).
  String get displayName => switch (this) {
    PartnerRole.guide => 'Горный гид',
    PartnerRole.cityGuide => 'Городской обзорный гид',
    PartnerRole.suvDriver => 'Водитель внедорожника',
    PartnerRole.busDriver => 'Водитель автобуса',
    PartnerRole.minibusDriver => 'Водитель микроавтобуса',
    PartnerRole.minivanDriver => 'Водитель минивена',
  };

  bool get isDriver => switch (this) {
    PartnerRole.suvDriver ||
    PartnerRole.busDriver ||
    PartnerRole.minibusDriver ||
    PartnerRole.minivanDriver => true,
    _ => false,
  };

  bool get isGuide => !isDriver;

  /// guideType-совместимое значение для обратной совместимости.
  /// 'city' для городского гида, 'hiking' для всех остальных.
  String get guideType => this == PartnerRole.cityGuide ? 'city' : 'hiking';
}

/// Единый профиль партнёра (водителя или гида).
///
/// Хранится в коллекции `partners/{uid}`.
/// Читается обоими приложениями — explora_app и explora_partners_app.
class PartnerProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final PartnerRole role;

  // ── Публичные данные ───────────────────────────────────────────────────────
  final String? photoUrl;
  final double rating;
  final int reviewCount;
  final String level; // Bronze, Silver, Gold, Platinum
  final int priority;
  final bool isVerified;
  final bool isOnline;
  final String bio;
  final String description;
  final List<String> languages;

  // ── Guide-специфичные ─────────────────────────────────────────────────────
  final List<String> specializations;
  final int experience; // лет опыта
  final List<String> certifications;
  final double pricePerDay;

  // ── Driver-специфичные ────────────────────────────────────────────────────
  final String vehicleModel;
  final String vehicleType; // suv | bus | minibus | minivan
  final int vehicleCapacity; // общее кол-во мест в авто (включая водителя)
  final double pricePerKm;
  final int dailyMileageLimit; // Лимит пробега водителя в день (default 300)
  final double overagePricePerKm; // Стоимость километра перепробега
  final double driverStayPerDay; // Суточные/командировочные водителя

  // ── Системные ─────────────────────────────────────────────────────────────
  final String? fcmToken; // для push-уведомлений и будущих чатов
  final double balance; // Баланс партнера
  final String? savedCard; // Привязанная карта партнера для выплат

  const PartnerProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.photoUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.level = 'Bronze',
    this.priority = 0,
    this.isVerified = false,
    this.isOnline = false,
    this.bio = '',
    this.description = '',
    this.languages = const [],
    this.specializations = const [],
    this.experience = 0,
    this.certifications = const [],
    this.pricePerDay = 0.0,
    this.vehicleModel = '',
    this.vehicleType = '',
    this.vehicleCapacity = 0,
    this.pricePerKm = 0.0,
    this.dailyMileageLimit = 300,
    this.overagePricePerKm = 300.0,
    this.driverStayPerDay = 15000.0,
    this.fcmToken,
    this.balance = 0.0,
    this.savedCard,
  });

  // ── Вычисляемые поля ──────────────────────────────────────────────────────

  /// «Ерлан А.»
  String get shortName {
    if (lastName.isEmpty) return firstName;
    return '$firstName ${lastName[0]}.';
  }

  /// «Ерлан Алиев»
  String get fullName => '$firstName $lastName'.trim();

  /// Совместимость с booking_screen (ранее driver.ownerName).
  String get ownerName => fullName;

  /// Совместимость с booking_screen (ранее driver.name).
  String get name => shortName;

  // ── Serialization ─────────────────────────────────────────────────────────

  factory PartnerProfile.fromJson(Map<String, dynamic> json) {
    return PartnerProfile(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role:
          PartnerRole.values.asNameMap()[json['role'] as String?] ??
          PartnerRole.guide,
      photoUrl: json['photoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      level: json['level'] as String? ?? 'Bronze',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      bio: json['bio'] as String? ?? '',
      description: json['description'] as String? ?? '',
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      specializations:
          (json['specializations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      certifications:
          (json['certifications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      vehicleModel: json['vehicleModel'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
      vehicleCapacity: (json['vehicleCapacity'] as num?)?.toInt() ?? 0,
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble() ?? 0.0,
      dailyMileageLimit: (json['dailyMileageLimit'] as num?)?.toInt() ?? 300,
      overagePricePerKm:
          (json['overagePricePerKm'] as num?)?.toDouble() ?? 300.0,
      driverStayPerDay:
          (json['driverStayPerDay'] as num?)?.toDouble() ?? 15000.0,
      fcmToken: json['fcmToken'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      savedCard: json['savedCard'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role.name,
    'photoUrl': photoUrl,
    'rating': rating,
    'reviewCount': reviewCount,
    'level': level,
    'priority': priority,
    'isVerified': isVerified,
    'isOnline': isOnline,
    'bio': bio,
    'description': description,
    'languages': languages,
    'specializations': specializations,
    'experience': experience,
    'certifications': certifications,
    'pricePerDay': pricePerDay,
    'vehicleModel': vehicleModel,
    'vehicleType': vehicleType,
    'vehicleCapacity': vehicleCapacity,
    'pricePerKm': pricePerKm,
    'dailyMileageLimit': dailyMileageLimit,
    'overagePricePerKm': overagePricePerKm,
    'driverStayPerDay': driverStayPerDay,
    'fcmToken': fcmToken,
    'balance': balance,
    'savedCard': savedCard,
  };

  PartnerProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    PartnerRole? role,
    String? photoUrl,
    double? rating,
    int? reviewCount,
    String? level,
    int? priority,
    bool? isVerified,
    bool? isOnline,
    String? bio,
    String? description,
    List<String>? languages,
    List<String>? specializations,
    int? experience,
    List<String>? certifications,
    double? pricePerDay,
    String? vehicleModel,
    String? vehicleType,
    int? vehicleCapacity,
    double? pricePerKm,
    int? dailyMileageLimit,
    double? overagePricePerKm,
    double? driverStayPerDay,
    String? fcmToken,
    double? balance,
    String? savedCard,
  }) {
    return PartnerProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      level: level ?? this.level,
      priority: priority ?? this.priority,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      bio: bio ?? this.bio,
      description: description ?? this.description,
      languages: languages ?? this.languages,
      specializations: specializations ?? this.specializations,
      experience: experience ?? this.experience,
      certifications: certifications ?? this.certifications,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleCapacity: vehicleCapacity ?? this.vehicleCapacity,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      dailyMileageLimit: dailyMileageLimit ?? this.dailyMileageLimit,
      overagePricePerKm: overagePricePerKm ?? this.overagePricePerKm,
      driverStayPerDay: driverStayPerDay ?? this.driverStayPerDay,
      fcmToken: fcmToken ?? this.fcmToken,
      balance: balance ?? this.balance,
      savedCard: savedCard ?? this.savedCard,
    );
  }
}

