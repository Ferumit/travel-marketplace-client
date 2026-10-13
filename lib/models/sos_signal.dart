import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель SOS-сигнала, сохраняемого в Firebase Firestore (коллекция `sos_signals`).
///
/// Запись иммутабельна — обновление и удаление запрещены правилами Firestore.
/// Дедупликация обеспечивается по полю [signalId] (документ создаётся один раз).
class SosSignal {
  /// Уникальный ID сигнала (UUID, генерируется при нажатии SOS).
  final String signalId;

  /// Firebase UID пользователя, нажавшего SOS.
  final String senderId;

  /// Отображаемое имя отправителя.
  final String senderName;

  /// ID активной поездки, если удалось определить.
  final String? tripId;

  /// Широта местоположения отправителя в момент SOS.
  final double? lat;

  /// Долгота местоположения отправителя в момент SOS.
  final double? lng;

  /// Время нажатия SOS на устройстве отправителя.
  final DateTime sentAt;

  /// Время сохранения записи в Firebase (может отличаться при отложенной отправке).
  final DateTime uploadedAt;

  /// UID устройства, которое записало сигнал в Firebase.
  /// Совпадает с [senderId], если отправитель был онлайн.
  /// Отличается от [senderId], если запись сделана relay-агентом.
  final String uploadedBy;

  /// true — запись сделана другим устройством, получившим SOS по MESH.
  final bool isRelay;

  /// Статус сигнала: 'active' или 'resolved'.
  final String status;

  const SosSignal({
    required this.signalId,
    required this.senderId,
    required this.senderName,
    this.tripId,
    this.lat,
    this.lng,
    required this.sentAt,
    required this.uploadedAt,
    required this.uploadedBy,
    this.isRelay = false,
    this.status = 'active',
  });

  factory SosSignal.fromJson(Map<String, dynamic> json) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.parse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    return SosSignal(
      signalId: json['signalId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Участник',
      tripId: json['tripId'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      sentAt: parseTimestamp(json['sentAt']),
      uploadedAt: parseTimestamp(json['uploadedAt']),
      uploadedBy: json['uploadedBy'] as String? ?? '',
      isRelay: json['isRelay'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'signalId': signalId,
        'senderId': senderId,
        'senderName': senderName,
        if (tripId != null) 'tripId': tripId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'sentAt': Timestamp.fromDate(sentAt),
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'uploadedBy': uploadedBy,
        'isRelay': isRelay,
        'status': status,
      };
}
