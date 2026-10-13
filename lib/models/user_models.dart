// User and client-profile data models.
// Guide and Driver classes have been moved to partner_models.dart.
// Use PartnerProfile from partner_models.dart instead.

class TrustedContact {
  final String name;
  final String phoneNumber;

  const TrustedContact({required this.name, required this.phoneNumber});

  factory TrustedContact.fromJson(Map<String, dynamic> json) {
    return TrustedContact(
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phoneNumber': phoneNumber};
  }
}

class User {
  final String id;
  final String phoneNumber;
  final String? name; // Full name
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? birthDate;
  final String? photoUrl;
  final double balance;
  final String? savedCard;
  final List<TrustedContact> trustedContacts;
  final bool isGuest;
  final List<String> favoriteRouteIds;
  final List<String> favoriteGuideIds;
  final List<String> favoriteDriverIds;
  final List<String> albumUrls;
  final List<String> hiddenChatIds;
  final String? fcmToken;
  final DateTime? deletionRequestedAt;
  final double rating;
  final int reviewCount;

  const User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.birthDate,
    this.photoUrl,
    required this.balance,
    this.savedCard,
    required this.trustedContacts,
    required this.isGuest,
    this.favoriteRouteIds = const [],
    this.favoriteGuideIds = const [],
    this.favoriteDriverIds = const [],
    this.albumUrls = const [],
    this.hiddenChatIds = const [],
    this.fcmToken,
    this.deletionRequestedAt,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      birthDate: json['birthDate'] as String?,
      photoUrl: json['photoUrl'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      savedCard: json['savedCard'] as String?,
      trustedContacts:
          (json['trustedContacts'] as List<dynamic>?)
              ?.map((e) => TrustedContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isGuest: json['isGuest'] as bool? ?? false,
      favoriteRouteIds:
          (json['favoriteRouteIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      favoriteGuideIds:
          (json['favoriteGuideIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      favoriteDriverIds:
          (json['favoriteDriverIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      albumUrls:
          (json['albumUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hiddenChatIds:
          (json['hiddenChatIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      fcmToken: json['fcmToken'] as String?,
      deletionRequestedAt: json['deletionRequestedAt'] != null 
          ? DateTime.parse(json['deletionRequestedAt'] as String) 
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'birthDate': birthDate,
      'photoUrl': photoUrl,
      'balance': balance,
      'savedCard': savedCard,
      'trustedContacts': trustedContacts.map((e) => e.toJson()).toList(),
      'isGuest': isGuest,
      'favoriteRouteIds': favoriteRouteIds,
      'favoriteGuideIds': favoriteGuideIds,
      'favoriteDriverIds': favoriteDriverIds,
      'albumUrls': albumUrls,
      'hiddenChatIds': hiddenChatIds,
      'fcmToken': fcmToken,
      'deletionRequestedAt': deletionRequestedAt?.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  bool get isPendingDeletion => deletionRequestedAt != null;

  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? birthDate,
    String? photoUrl,
    double? balance,
    String? savedCard,
    List<TrustedContact>? trustedContacts,
    bool? isGuest,
    List<String>? favoriteRouteIds,
    List<String>? favoriteGuideIds,
    List<String>? favoriteDriverIds,
    List<String>? albumUrls,
    List<String>? hiddenChatIds,
    String? fcmToken,
    DateTime? deletionRequestedAt,
    double? rating,
    int? reviewCount,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      balance: balance ?? this.balance,
      savedCard: savedCard ?? this.savedCard,
      trustedContacts: trustedContacts ?? this.trustedContacts,
      isGuest: isGuest ?? this.isGuest,
      favoriteRouteIds: favoriteRouteIds ?? this.favoriteRouteIds,
      favoriteGuideIds: favoriteGuideIds ?? this.favoriteGuideIds,
      favoriteDriverIds: favoriteDriverIds ?? this.favoriteDriverIds,
      albumUrls: albumUrls ?? this.albumUrls,
      hiddenChatIds: hiddenChatIds ?? this.hiddenChatIds,
      fcmToken: fcmToken ?? this.fcmToken,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

