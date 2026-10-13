import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../models/review_models.dart';
import '../models/sos_signal.dart';
import '../services/auth_service.dart';

class FirestoreDataRepository {
  static final FirestoreDataRepository instance = FirestoreDataRepository._();
  FirestoreDataRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Routes ---


  Future<List<Route>> getRoutes() async {
    try {
      final snapshot = await _firestore.collection('routes').get();
      return snapshot.docs.map((doc) => Route.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка загрузки маршрутов: $e');
      return [];
    }
  }

  Future<void> seedAlmatyPopularRoutes() async {
    try {
      final existing = await getSharedRoutes();
      if (existing.isNotEmpty) return; // Уже есть

      final routes = [
        Route(
          id: _firestore.collection('routes').doc().id,
          title: 'Большое Алматинское Озеро (БАО)',
          description:
              'Потрясающий маршрут к высокогорному озеру в ущелье реки Большой Алматинки, расположенному на высоте 2511 метров. Завершен туристами за 5 часов с потрясающими впечатлениями.',
          region: 'Алматы, Иле-Алатауский нац. парк',
          duration: 1,
          price: 25000,
          difficulty: Difficulty.moderate,
          format: TourFormat.group,
          transport: TransportType.minivan4x4,
          season: 'Май-Октябрь',
          guideLanguage: 'Русский',
          rating: 4.9,
          reviewCount: 342,
          imageUrl:
              'https://images.unsplash.com/photo-1572886071665-276632c02787?q=80&w=600&auto=format&fit=crop', // Almaty mountains placeholder
          latitude: 43.0506,
          longitude: 76.9845,
          availableDates: [],
          maxGroupSize: 7,
          highlights: ['Вид на горы', 'Чистейшая вода', 'Хвойный лес'],
          included: ['Трансфер', 'Гид-проводник', 'Экосбор'],
          excluded: ['Питание'],
          isShared: true,
        ),
        Route(
          id: _firestore.collection('routes').doc().id,
          title: 'Кольсайские озёра и Каинды',
          description:
              'Двухдневный затяжной маршрут к самым красивым озерам региона. Погружение в мистическую атмосферу затонувшего леса Каинды и ночевка в гостевых домах в Саты.',
          region: 'Алматинская область, Кеген',
          duration: 2,
          price: 45000,
          difficulty: Difficulty.easy,
          format: TourFormat.group,
          transport: TransportType.minibus,
          season: 'Лето-Осень',
          guideLanguage: 'Казахский / Русский',
          rating: 4.8,
          reviewCount: 512,
          imageUrl:
              'https://images.unsplash.com/photo-1692291535265-d01c7ce51390?q=80&w=600&auto=format&fit=crop', // Kolsai/Kaindy placeholder
          latitude: 42.9892,
          longitude: 78.3243,
          availableDates: [],
          maxGroupSize: 15,
          highlights: ['Затонувший лес', 'Три озера', 'Лошадиные прогулки'],
          included: ['Трансфер туда/обратно', 'Проживание', 'Экосбор'],
          excluded: ['Аренда лодки'],
          isShared: true,
        ),
        Route(
          id: _firestore.collection('routes').doc().id,
          title: 'Чарынский каньон (Долина Замков)',
          description:
              'Путешествие в одно из самых уникальных мест Казахстана. Каньон, формировавшийся миллионы лет, предлагает невероятные виды и марсианские пейзажи. Идеально для фотосессий.',
          region: 'Алматинская область, Чарын',
          duration: 1,
          price: 18000,
          difficulty: Difficulty.easy,
          format: TourFormat.group,
          transport: TransportType.bus,
          season: 'Круглый год',
          guideLanguage: 'Русский / English',
          rating: 4.7,
          reviewCount: 890,
          imageUrl:
              'https://images.unsplash.com/photo-1628173428989-bca16fbde4b0?q=80&w=600&auto=format&fit=crop', // Charyn placeholder
          latitude: 43.3486,
          longitude: 79.0805,
          availableDates: [],
          maxGroupSize: 40,
          highlights: ['Марсианские пейзажи', 'Река Чарын', 'Долина Замков'],
          included: ['Трансфер автобусом', 'Входные билеты'],
          excluded: ['Обед в кафе'],
          isShared: true,
        ),
      ];

      final batch = _firestore.batch();
      for (var r in routes) {
        batch.set(_firestore.collection('routes').doc(r.id), r.toJson());
      }
      await batch.commit();
      debugPrint(
        '[FirestoreDataRepository] Успешно добавлены 3 тестовых маршрута.',
      );
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка при добавлении тестовых маршрутов: $e',
      );
    }
  }

  Future<List<Route>> getSharedRoutes() async {
    try {
      final snapshot = await _firestore
          .collection('routes')
          .where('isShared', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => Route.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка загрузки расшаренных маршрутов: $e',
      );
      return [];
    }
  }

  Future<void> shareRoute(String routeId) async {
    try {
      await _firestore.collection('routes').doc(routeId).update({
        'isShared': true,
      });
      debugPrint(
        '[FirestoreDataRepository] Маршрут $routeId теперь доступен публично.',
      );
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка при расшаривании маршрута: $e',
      );
    }
  }

  Future<Route?> getRouteById(String id) async {
    try {
      final doc = await _firestore.collection('routes').doc(id).get();
      if (doc.exists && doc.data() != null) {
        return Route.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка загрузки маршрута $id: $e');
    }
    return null;
  }

  /// Converts a custom Booking into a public Route and saves it.
  Future<void> saveCompletedCustomRoute(Booking booking) async {
    try {
      if (!booking.isCustomRoute) return;

      final durationDays = DateTime.parse(
        booking.endDate,
      ).difference(DateTime.parse(booking.startDate)).inDays.clamp(1, 100);

      // Create a deterministic or completely new ID
      final newRouteId = _firestore.collection('routes').doc().id;

      final newRoute = Route(
        id: newRouteId,
        title: booking.routeTitle,
        description: 'Пользовательский маршрут, успешно пройденный туристами.',
        region: 'Казахстан',
        duration: durationDays,
        price: booking.totalPrice,
        difficulty: Difficulty.moderate,
        format: TourFormat.private,
        transport: TransportType.none,
        season: 'Любой',
        guideLanguage: 'Русский',
        rating: 5.0,
        reviewCount: 1,
        imageUrl:
            'https://images.unsplash.com/photo-1558507652-2d9626c4e67a?auto=format&fit=crop&q=80',
        latitude: booking.customRouteCoordinates?.firstOrNull?.$1 ?? 43.2220,
        longitude: booking.customRouteCoordinates?.firstOrNull?.$2 ?? 76.8512,
        availableDates: [],
        maxGroupSize: booking.participants,
        highlights: ['Индивидуальный план', 'Проверенный гид/авто'],
        included: booking.insuranceIncluded ? ['Страховка'] : [],
        excluded: [],
      );

      await _firestore
          .collection('routes')
          .doc(newRouteId)
          .set(newRoute.toJson());
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка сохранения кастомного маршрута: $e',
      );
    }
  }

  // --- Partners (replaces separate guides + drivers collections) ---

  /// Получить всех партнёров с опциональной фильтрацией по ролям.
  Future<List<PartnerProfile>> getPartners({List<PartnerRole>? roles}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('partners');
      if (roles != null && roles.isNotEmpty) {
        query = query.where('role', whereIn: roles.map((r) => r.name).toList());
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => PartnerProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreDataRepository] getPartners error: $e');
      return [];
    }
  }

  /// Обратная совместимость — возвращает гидов из partners.
  Future<List<PartnerProfile>> getGuides() =>
      getPartners(roles: [PartnerRole.guide, PartnerRole.cityGuide]);

  /// Обратная совместимость — возвращает водителей из partners.
  Future<List<PartnerProfile>> getDrivers() => getPartners(
    roles: [
      PartnerRole.suvDriver,
      PartnerRole.busDriver,
      PartnerRole.minibusDriver,
      PartnerRole.minivanDriver,
    ],
  );

  /// Stream профиля конкретного партнёра (для экрана профиля/чата).
  Stream<PartnerProfile?> streamPartner(String uid) {
    return _firestore.collection('partners').doc(uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return PartnerProfile.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // --- Tourist Zones ---
  Future<List<TouristZone>> getTouristZones() async {
    try {
      final snapshot = await _firestore.collection('tourist_zones').get();
      return snapshot.docs
          .map((doc) => TouristZone.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка загрузки туристических зон: $e',
      );
      return [];
    }
  }

  // --- Users ---
  Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка загрузки юзера $uid: $e');
    }
    return null;
  }

  Stream<User?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return User.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> saveUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка сохранения юзера ${user.id}: $e',
      );
    }
  }

  Future<void> toggleFavoriteRoute(String uid, String routeId) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final currentIds = List<String>.from(
        doc.data()?['favoriteRouteIds'] ?? [],
      );
      if (currentIds.contains(routeId)) {
        currentIds.remove(routeId);
      } else {
        currentIds.add(routeId);
      }

      await docRef.update({'favoriteRouteIds': currentIds});
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка toggleFavoriteRoute: $e');
    }
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка updateUserData: $e');
      rethrow;
    }
  }

  Future<void> toggleFavoriteGuide(String uid, String guideId) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final currentIds = List<String>.from(
        doc.data()?['favoriteGuideIds'] ?? [],
      );
      if (currentIds.contains(guideId)) {
        currentIds.remove(guideId);
      } else {
        currentIds.add(guideId);
      }

      await docRef.update({'favoriteGuideIds': currentIds});
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка toggleFavoriteGuide: $e');
    }
  }

  Future<void> toggleFavoriteDriver(String uid, String driverId) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final currentIds = List<String>.from(
        doc.data()?['favoriteDriverIds'] ?? [],
      );
      if (currentIds.contains(driverId)) {
        currentIds.remove(driverId);
      } else {
        currentIds.add(driverId);
      }

      await docRef.update({'favoriteDriverIds': currentIds});
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка toggleFavoriteDriver: $e');
    }
  }

  Future<void> updateUserProfilePhoto(String uid, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'photoUrl': photoUrl,
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка обновления аватара: $e');
    }
  }

  Future<void> addAlbumPhoto(String uid, String photoUrl) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final doc = await docRef.get();
      if (!doc.exists) return;

      final currentUrls = List<String>.from(doc.data()?['albumUrls'] ?? []);
      currentUrls.add(photoUrl);

      await docRef.update({'albumUrls': currentUrls});
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка добавления в альбом: $e');
    }
  }

  // --- Bookings ---
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => Booking.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка загрузки бронирований: $e');
      return [];
    }
  }

  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists && doc.data() != null) {
        return Booking.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка загрузки бронирования $bookingId: $e',
      );
    }
    return null;
  }

  Future<void> saveBooking(Booking booking) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(booking.id)
          .set(booking.toJson());
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка сохранения бронирования ${booking.id}: $e',
      );
    }
  }

  // --- Active Trips ---
  Future<bool> hasActiveTrips(String userId) async {
    try {
      // Ищем по participantIds (включает компаньонов), и по userId (для старых документов без поля)
      final byParticipant = await _firestore
          .collection('active_trips')
          .where('participantIds', arrayContains: userId)
          .where('status', whereIn: ['scheduled', 'waiting', 'in_progress'])
          .limit(1)
          .get();
      if (byParticipant.docs.isNotEmpty) return true;
      // Fallback для старых документов без participantIds
      final byUserId = await _firestore
          .collection('active_trips')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['scheduled', 'waiting', 'in_progress'])
          .limit(1)
          .get();
      return byUserId.docs.isNotEmpty;
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка при проверке hasActiveTrips: $e',
      );
      return false;
    }
  }

  /// Checks if a partner (driver or guide) is currently on an active trip.
  /// Used to prevent double-booking before a new booking is saved.
  /// Returns true if the partner is free, false if busy.
  /// On error, returns true to avoid blocking the booking (soft guard).
  Future<bool> isPartnerAvailable(String partnerId) async {
    if (AuthService.bypassFirebaseInitAndAuth) return true;
    try {
      final statuses = ['scheduled', 'waiting', 'in_progress'];
      // Check if busy as driver
      final byDriver = await _firestore
          .collection('active_trips')
          .where('driverId', isEqualTo: partnerId)
          .where('status', whereIn: statuses)
          .limit(1)
          .get();
      if (byDriver.docs.isNotEmpty) return false;
      // Check if busy as guide
      final byGuide = await _firestore
          .collection('active_trips')
          .where('guideId', isEqualTo: partnerId)
          .where('status', whereIn: statuses)
          .limit(1)
          .get();
      return byGuide.docs.isEmpty;
    } catch (e) {
      debugPrint('[FirestoreDataRepository] isPartnerAvailable error: $e');
      return true; // don't block booking on error
    }
  }

  /// Atomically cancels a trip and its associated booking in a single batch write.
  Future<void> cancelTrip({
    required String tripId,
    required String bookingId,
  }) async {
    final batch = _firestore.batch();
    batch.update(
      _firestore.collection('active_trips').doc(tripId),
      {'status': 'cancelled'},
    );
    batch.update(
      _firestore.collection('bookings').doc(bookingId),
      {'status': BookingStatus.cancelled.name},
    );
    await batch.commit();
  }

  Future<void> createActiveTrip(ActiveTrip trip) async {
    try {
      if (await hasActiveTrips(trip.userId)) {
        throw Exception(
          'У вас уже есть активный маршрут. Завершите его перед созданием нового.',
        );
      }
      await _firestore
          .collection('active_trips')
          .doc(trip.id)
          .set(trip.toJson());
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка создания активного пути ${trip.id}: $e',
      );
      rethrow;
    }
  }

  Future<void> updateClientLocation(
    String tripId,
    double lat,
    double lng,
  ) async {
    try {
      await _firestore.collection('active_trips').doc(tripId).update({
        'clientLocation': {'lat': lat, 'lng': lng},
      });
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка обновления локации клиента: $e',
      );
    }
  }

  Stream<List<ActiveTrip>> streamActiveTrips(String userId) {
    // ΑarrayContains по participantIds: владелец и компаньоны видят один и тот же маршрут
    return _firestore
        .collection('active_trips')
        .where('participantIds', arrayContains: userId)
        .where('status', whereIn: ['scheduled', 'waiting', 'in_progress'])
        .snapshots()
        .map((snapshot) {
          final trips = snapshot.docs
              .map((doc) => ActiveTrip.fromJson(doc.data()))
              .toList();
          trips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return trips;
        });
  }

  Stream<ActiveTrip?> streamSpecificActiveTrip(String tripId) {
    return _firestore.collection('active_trips').doc(tripId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return ActiveTrip.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<ActiveTrip?> getActiveTripById(String tripId) async {
    try {
      final doc = await _firestore.collection('active_trips').doc(tripId).get();
      if (doc.exists && doc.data() != null) {
        return ActiveTrip.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка загрузки ActiveTrip: $e');
    }
    return null;
  }

  Future<ActiveTrip?> getActiveTripByBookingId(String bookingId) async {
    try {
      final snapshot = await _firestore
          .collection('active_trips')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return ActiveTrip.fromJson(snapshot.docs.first.data());
      }
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка getActiveTripByBookingId: $e',
      );
    }
    return null;
  }

  /// Updates the customName field of an ActiveTrip document.
  Future<void> updateTripName(String tripId, String newName) async {
    try {
      await _firestore.collection('active_trips').doc(tripId).update({
        'customName': newName,
      });
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка обновления имени поездки: $e',
      );
    }
  }

  /// Updates the Firestore status field of an ActiveTrip document.
  Future<void> updateTripStatus(String tripId, String newStatus) async {
    try {
      await _firestore.collection('active_trips').doc(tripId).update({
        'status': newStatus,
      });
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка обновления статуса поездки: $e',
      );
    }
  }

  /// Updates the Firestore status field of a Booking document.
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus.name,
      });
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка обновления статуса бронирования: $e',
      );
    }
  }

  /// Atomically updates trip status AND booking status in a single batch write.
  /// This halves the number of Firestore write operations vs two separate calls,
  /// and makes the update atomic. Throws on error (caller handles retry).
  Future<void> completeTripBatch({
    required String tripId,
    required String tripStatus,
    String? bookingId,
    BookingStatus? bookingStatus,
    List<dynamic>? initialWaypoints,
  }) async {
    final batch = _firestore.batch();

    final tripRef = _firestore.collection('active_trips').doc(tripId);
    
    final tripUpdates = <String, dynamic>{'status': tripStatus};
    if (initialWaypoints != null) {
      tripUpdates['waypoints'] = initialWaypoints;
      tripUpdates['currentWaypointIndex'] = 0;
    }
    
    batch.update(tripRef, tripUpdates);

    if (bookingId != null && bookingStatus != null) {
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      batch.update(bookingRef, {'status': bookingStatus.name});
    }

    await batch.commit(); // single network round-trip
  }

  /// Mark the client as ready at the meeting point
  Future<void> setClientReady(String tripId) async {
    await _firestore.collection('active_trips').doc(tripId).update({
      'clientReady': true,
    });
  }

  /// Get the current state of a trip synchronously
  Future<ActiveTrip?> getTripById(String tripId) async {
    try {
      final doc = await _firestore.collection('active_trips').doc(tripId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ActiveTrip.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('[FirestoreDataRepository] getTripById Error: $e');
      return null;
    }
  }

  Future<void> checkInAtWaypoint(
    String tripId,
    int waypointIndex,
    String role,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tripRef = _firestore.collection('active_trips').doc(tripId);
        final tripSnapshot = await transaction.get(tripRef);
        if (!tripSnapshot.exists) return;

        final data = tripSnapshot.data()!;
        final trip = ActiveTrip.fromJson(data);

        List<dynamic> waypoints = List<dynamic>.from(data['waypoints'] as List? ?? []);
        if (waypointIndex >= waypoints.length) return;

        final pt = Map<String, dynamic>.from(waypoints[waypointIndex] as Map);
        final checkIns = pt['checkIns'] != null
            ? Map<String, dynamic>.from(pt['checkIns'] as Map)
            : <String, dynamic>{};

        checkIns[role] = true;
        pt['checkIns'] = checkIns;
        waypoints[waypointIndex] = pt;

        final bool clientOk = checkIns['client'] == true;

        final bool hasDriver = trip.driverId != null;
        final bool driverOk = !hasDriver || checkIns['driver'] == true;

        final bool hasGuide = trip.guideId != null;
        final bool guideOk = !hasGuide || checkIns['guide'] == true;

        bool companionsOk = true;
        for (var companion in trip.companions) {
          if (checkIns['companion_${companion.uid}'] != true) {
            companionsOk = false;
            break;
          }
        }

        int nextWaypointIndex = trip.currentWaypointIndex;
        if (clientOk && driverOk && guideOk && companionsOk && waypointIndex == trip.currentWaypointIndex) {
          nextWaypointIndex++;
        }

        transaction.update(tripRef, {
          'waypoints': waypoints,
          'currentWaypointIndex': nextWaypointIndex,
        });
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка checkInAtWaypoint: $e');
    }
  }

  /// Step 1: driver requests completion.
  /// Sets both the role-specific flag and the legacy flag for UI compatibility.
  Future<void> requestTripCompletion(String tripId) async {
    await _firestore.collection('active_trips').doc(tripId).update({
      'completionRequested': true,
      'driverCompletionRequested': true, // used by the new three-way completion UI
    });
  }

  /// Step 2: client confirms — atomically sets status=completed and clears flag.
  Future<void> confirmTripCompletion({
    required String tripId,
    required String bookingId,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('active_trips').doc(tripId), {
      'status': 'completed',
      'completionRequested': false,
    });
    batch.update(_firestore.collection('bookings').doc(bookingId), {
      'status': BookingStatus.completed.name,
    });
    await batch.commit();
    debugPrint('[FirestoreDataRepository] confirmTripCompletion: $tripId');
  }

  // --- FCM Tokens ---

  /// Saves the FCM push notification token for the specified user or partner.
  Future<void> saveFcmToken(
    String uid,
    String token, {
    bool isPartner = false,
  }) async {
    try {
      final collection = isPartner ? 'partners' : 'users';
      await _firestore.collection(collection).doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
      debugPrint(
        '[FirestoreDataRepository] FCM Token saved to $collection/$uid',
      );
    } catch (e) {
      debugPrint(
        '[FirestoreDataRepository] Ошибка при сохранении FCM токена: $e',
      );
    }
  }

  // --- Saved Chats ---

  /// Adds a chat (tripId) to the user's hidden chats list
  Future<void> hideChat(String userId, String tripId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'hiddenChatIds': FieldValue.arrayUnion([tripId]),
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] hideChat error: $e');
    }
  }

  /// Streams the list of hidden chat IDs for a specific user
  Stream<List<String>> streamHiddenChats(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      final data = snapshot.data();
      return (data?['hiddenChatIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    });
  }

  /// Маркирует пользователя на удаление (установка метки времени).
  Future<void> markUserForDeletion(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'deletionRequestedAt': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint(
        '[FirestoreDataRepository] Пользователь $uid помечен на удаление.',
      );
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка markUserForDeletion: $e');
      rethrow;
    }
  }

  /// Отменяет удаление пользователя (удаление метки времени).
  Future<void> cancelUserDeletion(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'deletionRequestedAt': FieldValue.delete(),
      });
      debugPrint(
        '[FirestoreDataRepository] Удаление пользователя $uid отменено.',
      );
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка cancelUserDeletion: $e');
    }
  }

  // ── Reviews ──────────────────────────────────────────────────────────────

  Future<bool> hasReviewed(String bookingId, String authorId, String targetId) async {
    final snap = await _firestore
        .collection('reviews')
        .where('bookingId', isEqualTo: bookingId)
        .where('authorId', isEqualTo: authorId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> submitReview(Review review) async {
    await _firestore.runTransaction((tx) async {
      final reviewRef = _firestore.collection('reviews').doc();
      final reviewWithId = Review(
        id: reviewRef.id,
        bookingId: review.bookingId,
        authorId: review.authorId,
        authorName: review.authorName,
        authorRole: review.authorRole,
        targetId: review.targetId,
        targetRole: review.targetRole,
        rating: review.rating,
        comment: review.comment,
        createdAt: DateTime.now(),
      );
      tx.set(reviewRef, reviewWithId.toJson());

      final String targetCollection = (review.targetRole == 'client') ? 'users' : 'partners';
      final targetRef = _firestore.collection(targetCollection).doc(review.targetId);
      final targetSnap = await tx.get(targetRef);
      if (targetSnap.exists) {
        final data = targetSnap.data()!;
        final oldCount = (data['reviewCount'] as int?) ?? 0;
        final oldRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final newCount = oldCount + 1;
        final newRating = ((oldRating * oldCount) + review.rating) / newCount;
        tx.update(targetRef, {
          'rating': double.parse(newRating.toStringAsFixed(2)),
          'reviewCount': newCount,
        });
      }
    });
  }

  // ── SOS Signals ──────────────────────────────────────────────────────────

  /// Записывает SOS-сигнал в коллекцию `sos_signals`.
  ///
  /// Дедупликация: если документ с [signal.signalId] уже существует,
  /// запись игнорируется (ALREADY_EXISTS пойман в [SosService]).
  Future<void> uploadSosSignal(SosSignal signal) async {
    await _firestore
        .collection('sos_signals')
        .doc(signal.signalId)
        .set(signal.toJson()); // Не используем merge — перезапись невозможна по правилам Firestore
    debugPrint('[FirestoreDataRepository] SOS сигнал ${signal.signalId} записан');
  }

  /// Возвращает первую активную поездку пользователя (для SOSScreen).
  ///
  /// Используется для автоматического определения [tripId] при нажатии SOS.
  /// Возвращает null, если активных поездок нет.
  Future<ActiveTrip?> getActiveTripForUser(String userId) async {
    try {
      // Проверяем по participantIds (новые документы)
      final snap = await _firestore
          .collection('active_trips')
          .where('participantIds', arrayContains: userId)
          .where('status', whereIn: ['scheduled', 'waiting', 'in_progress'])
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return ActiveTrip.fromJson(snap.docs.first.data());
      }
      // Fallback для старых документов
      final snap2 = await _firestore
          .collection('active_trips')
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: ['scheduled', 'waiting', 'in_progress'])
          .limit(1)
          .get();
      if (snap2.docs.isNotEmpty) {
        return ActiveTrip.fromJson(snap2.docs.first.data());
      }
    } catch (e) {
      debugPrint('[FirestoreDataRepository] getActiveTripForUser error: $e');
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Companion helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Поиск пользователей по имени (для приглашения компаньонов).
  /// Выполняет параллельный префикс-поиск по полям [name] и [displayName],
  /// чтобы находить как пользователей из email-регистрации, так и через Google Auth.
  Future<List<User>> searchUsersByName(String query, {String? excludeUid}) async {
    if (query.trim().isEmpty) return [];
    try {
      final q = query.trim();
      final end = '$q\uf8ff';

      // Run both field queries in parallel
      final results = await Future.wait([
        _firestore
            .collection('users')
            .where('name', isGreaterThanOrEqualTo: q)
            .where('name', isLessThanOrEqualTo: end)
            .limit(10)
            .get(),
        _firestore
            .collection('users')
            .where('displayName', isGreaterThanOrEqualTo: q)
            .where('displayName', isLessThanOrEqualTo: end)
            .limit(10)
            .get(),
      ]);

      // Merge, deduplicate by id, exclude self
      final seen = <String>{};
      final users = [
        ...results[0].docs,
        ...results[1].docs,
      ]
          .map((d) => User.fromJson(d.data()))
          .where((u) => u.id != excludeUid && seen.add(u.id))
          .take(5)
          .toList();

      return users;
    } catch (e) {
      debugPrint('[FirestoreDataRepository] searchUsersByName error: $e');
      return [];
    }
  }

  /// Добавляет компаньона к маршруту.
  /// Если маршрут уже в состоянии in_progress — инициализирует слоты check-in
  /// для нового компаньона, чтобы waypoint-система не зависала в ожидании
  /// его check-in которого никогда не было при старте.
  Future<void> addCompanionToTrip(String tripId, CompanionInfo companion) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tripRef = _firestore.collection('active_trips').doc(tripId);
        final snap = await transaction.get(tripRef);
        if (!snap.exists) return;

        final data = snap.data()!;
        
        List<dynamic> waypointsDyn = List<dynamic>.from(data['waypoints'] ?? []);
        for (int i = 0; i < waypointsDyn.length; i++) {
          final pt = Map<String, dynamic>.from(waypointsDyn[i] as Map);
          final checkIns = pt['checkIns'] != null 
              ? Map<String, dynamic>.from(pt['checkIns'] as Map)
              : <String, dynamic>{};
          checkIns.putIfAbsent('companion_${companion.uid}', () => false);
          pt['checkIns'] = checkIns;
          waypointsDyn[i] = pt;
        }

        final currentParticipants = List<dynamic>.from(data['participantIds'] ?? []);
        final currentCompanions = List<dynamic>.from(data['companions'] ?? []);

        if (!currentParticipants.contains(companion.uid)) {
          currentParticipants.add(companion.uid);
        }
        // Replace companion entry if already exists (e.g. re-add after remove)
        currentCompanions.removeWhere((c) => (c as Map)['uid'] == companion.uid);
        currentCompanions.add(companion.toJson());

        transaction.update(tripRef, {
          'participantIds': currentParticipants,
          'companions': currentCompanions,
          'waypoints': waypointsDyn,
        });
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] addCompanionToTrip error: $e');
      rethrow;
    }
  }

  /// Удаляет компаньона из маршрута.
  Future<void> removeCompanionFromTrip(
    String tripId,
    CompanionInfo companion,
  ) async {
    try {
      await _firestore.collection('active_trips').doc(tripId).update({
        'participantIds': FieldValue.arrayRemove([companion.uid]),
        'companions': FieldValue.arrayRemove([companion.toJson()]),
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] removeCompanionFromTrip error: $e');
      rethrow;
    }
  }

  /// Обновляет геопозицию компаньона.
  Future<void> updateCompanionLocation(
    String tripId,
    String companionUid,
    double lat,
    double lng,
  ) async {
    try {
      await _firestore.collection('active_trips').doc(tripId).update({
        'companionLocations.$companionUid': {'lat': lat, 'lng': lng},
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] updateCompanionLocation error: $e');
    }
  }

  /// Устанавливает статус "Готов" (ready = true) для конкретного компаньона
  Future<void> setCompanionReady(String tripId, String companionUid) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final tripRef = _firestore.collection('active_trips').doc(tripId);
        final snapshot = await transaction.get(tripRef);
        if (!snapshot.exists) return;

        final companionsList = List<Map<String, dynamic>>.from(
          snapshot.data()!['companions'] ?? [],
        );
        for (var i = 0; i < companionsList.length; i++) {
          if (companionsList[i]['uid'] == companionUid) {
            companionsList[i]['ready'] = true;
            break;
          }
        }
        transaction.update(tripRef, {'companions': companionsList});
      });
    } catch (e) {
      debugPrint('[FirestoreDataRepository] Ошибка setCompanionReady: $e');
    }
  }

  Future<void> startTrip(String tripId, String bookingId) async {
    final tripRef = _firestore.collection('active_trips').doc(tripId);
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await _firestore.runTransaction((transaction) async {
      final tripSnap = await transaction.get(tripRef);
      if (!tripSnap.exists) return;

      final tripData = tripSnap.data()!;
      final trip = ActiveTrip.fromJson(tripData);

      // Idempotency guard
      // Another participant may have already called startTrip() a split-second
      // before us. Skip the write to avoid resetting waypointCheckIns.
      if (trip.status != 'waiting') {
        debugPrint('[FirestoreDataRepository] startTrip: trip=$tripId already ${trip.status}, skipping');
        return;
      }

      final waypoints = List<MeetingPoint>.from(trip.waypoints);

      // 1. Ensure "Return to Start" requirement
      if (waypoints.isNotEmpty) {
        final first = waypoints.first;
        final last = waypoints.last;
        if (first.latitude != last.latitude || first.longitude != last.longitude) {
          waypoints.add(first);
        }
      }

      // 2. Write back waypoints with empty checkIns embedded in each point
      transaction.update(tripRef, {
        'status': 'in_progress',
        'waypoints': waypoints.map((w) {
          final json = w.toJson();
          json['checkIns'] = <String, dynamic>{};
          return json;
        }).toList(),
      });

      transaction.update(bookingRef, {
        'status': 'in_progress',
      });
    });

    debugPrint('[FirestoreDataRepository] startTrip: $tripId (with return logic)');
  }
}
