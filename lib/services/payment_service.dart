import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Инициализирует платеж через Freedom Pay и открывает WebView.
  /// Возвращает Future<bool>, где true - успешная оплата, false - отмена/ошибка.
  Future<bool> startPaymentFlow({
    required BuildContext context,
    required double amount,
    required String description,
    required String routeId,
    required String userId,
  }) async {
    try {
      // 1. Вызываем Cloud Function
      final result = await _functions.httpsCallable('initFreedomPayment').call({
        'amount': amount,
        'description': description,
        'routeId': routeId,
        'userId': userId,
      });

      final data = result.data;
      if (data['success'] != true || data['redirectUrl'] == null) {
        throw Exception('Failed to get redirect URL');
      }

      final String redirectUrl = data['redirectUrl'];
      final String orderId = data['orderId'];

      // 2. Открываем In-App WebView
      final Uri url = Uri.parse(redirectUrl);
      if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
        throw Exception('Could not launch payment URL');
      }

      // 3. Слушаем изменения в Firestore для этого заказа
      Completer<bool> completer = Completer();
      StreamSubscription? subscription;

      subscription = _firestore
          .collection('payments')
          .doc(orderId)
          .snapshots()
          .listen((snapshot) {
        if (!snapshot.exists) return;

        final status = snapshot.data()?['status'] as String?;
        if (status == 'success') {
          // Оплата прошла успешно
          try {
            closeInAppWebView();
          } catch (e) {
            debugPrint('Error closing webview: $e');
          }
          subscription?.cancel();
          if (!completer.isCompleted) completer.complete(true);
        } else if (status == 'failed') {
          // Ошибка оплаты
          try {
            closeInAppWebView();
          } catch (e) {
            debugPrint('Error closing webview: $e');
          }
          subscription?.cancel();
          if (!completer.isCompleted) completer.complete(false);
        }
      });

      // Также нужно обработать случай, если пользователь сам закрыл WebView
      // (url_launcher не дает прямого коллбека на закрытие, но мы можем проверять,
      // если он вернулся в приложение, а статус все еще pending)
      // В идеале возвращаем результат через completer
      return completer.future.timeout(
        const Duration(minutes: 10),
        onTimeout: () {
          subscription?.cancel();
          closeInAppWebView();
          return false;
        },
      );
    } catch (e) {
      debugPrint('Payment Flow Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при инициализации платежа: $e')),
        );
      }
      return false;
    }
  }
}
