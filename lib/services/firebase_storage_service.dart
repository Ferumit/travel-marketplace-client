import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  static final FirebaseStorageService instance = FirebaseStorageService._();
  FirebaseStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Загружает файл в Firebase Storage и возвращает публичный URL
  Future<String?> uploadFile({required File file, required String path}) async {
    try {
      final Reference ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e, stack) {
      debugPrint('[FirebaseStorageService] Ошибка загрузки файла: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseStorageService.uploadFile', fatal: false);
      return null;
    }
  }

  /// Получает изображение из галереи или камеры
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Сжатие для экономии места
      );
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
    } catch (e, stack) {
      debugPrint('[FirebaseStorageService] Ошибка выбора изображения: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseStorageService.pickImage', fatal: false);
    }
    return null;
  }

  /// Комплексный метод: выбрать фото и сразу загрузить в папку (например, 'avatars/userId.jpg')
  Future<String?> pickAndUploadImage({
    required String storagePath,
    ImageSource source = ImageSource.gallery,
  }) async {
    final file = await pickImage(source: source);
    if (file == null) return null;
    return uploadFile(file: file, path: storagePath);
  }

  /// Удаляет файл из Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e, stack) {
      debugPrint('[FirebaseStorageService] Ошибка удаления файла: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'FirebaseStorageService.deleteFile', fatal: false);
      return false;
    }
  }
}

