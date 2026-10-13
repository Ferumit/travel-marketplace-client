import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Отказоустойчивый виджет для отображения сетевых изображений.
///
/// • Поддерживает Firebase Storage (пути типа 'assets/images/...')
/// • При ошибке загрузки показывает [placeholder].
/// • Во время загрузки показывает shimmer-skeleton.
class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveUrl = url;

    // Автоматическое исправление ссылок: если путь начинается с assets/images/ и содержит timestamp (например _177...),
    // значит картинка была загружена в Firebase Storage, но в БД сохранился локальный путь.
    if (effectiveUrl != null &&
        effectiveUrl.startsWith('assets/images/') &&
        effectiveUrl.contains('_17')) {
      final fileName = effectiveUrl.split('/').last;
      effectiveUrl = 'gs://travel-marketplace-demo.firebasestorage.app/routes/$fileName';
    }

    Widget image;

    if (effectiveUrl == null || effectiveUrl.isEmpty) {
      image = placeholder ?? const _ImagePlaceholder();
    } else if (effectiveUrl.startsWith('http')) {
      image = _buildNetworkImage(effectiveUrl);
    } else if (effectiveUrl.startsWith('gs://')) {
      image = FutureBuilder<String>(
        future: FirebaseStorage.instance.refFromURL(effectiveUrl).getDownloadURL(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ImagePlaceholder(isLoading: true);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            debugPrint('[SafeNetworkImage] Failed to resolve gs:// url: $effectiveUrl — ${snapshot.error}');
            return placeholder ?? const _ImagePlaceholder();
          }
          return Image.network(
            snapshot.data!,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[SafeNetworkImage] Failed to load resolved url: ${snapshot.data} — $error');
              return placeholder ?? const _ImagePlaceholder();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const _ImagePlaceholder(isLoading: true);
            },
          );
        },
      );
    } else if (effectiveUrl.startsWith('assets/')) {
      // Сначала пытаемся из Firebase Storage ('routes/...')
      String storagePath = effectiveUrl;
      if (storagePath.startsWith('assets/images/')) {
        storagePath = storagePath.replaceFirst('assets/images/', 'routes/');
      }

      image = FutureBuilder<String>(
        future: FirebaseStorage.instance.ref(storagePath).getDownloadURL(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ImagePlaceholder(isLoading: true);
          }
          if (snapshot.hasError || !snapshot.hasData) {
            // ФОЛЛБЕК 1: Если мы искали в 'routes/', попробуем оригинальный URL без замены (вдруг он лежит прямо в assets/images/ в Storage)
            if (storagePath != effectiveUrl) {
                return FutureBuilder<String>(
                    future: FirebaseStorage.instance.ref(effectiveUrl).getDownloadURL(),
                    builder: (context, snapshot2) {
                        if (snapshot2.connectionState == ConnectionState.waiting) {
                            return const _ImagePlaceholder(isLoading: true);
                        }
                        if (snapshot2.hasError || !snapshot2.hasData) {
                            // ФОЛЛБЕК 2: Локальный ассет (добавляем префикс lib/ так как он прописан в pubspec.yaml)
                            return Image.asset(
                              'lib/$effectiveUrl',
                              fit: fit,
                              width: width,
                              height: height,
                              errorBuilder: (context, error, stackTrace) {
                                return placeholder ?? const _ImagePlaceholder();
                              },
                            );
                        }
                        return _buildNetworkImage(snapshot2.data!);
                    }
                );
            }
            
            // Если и так не вышло, пробуем локальный ассет
            return Image.asset(
                'lib/$effectiveUrl',
                fit: fit,
                width: width,
                height: height,
                errorBuilder: (context, error, stackTrace) {
                    return placeholder ?? const _ImagePlaceholder();
                },
            );
          }
          return _buildNetworkImage(snapshot.data!);
        },
      );
    } else {
      // Истинные локальные ассеты (например, lib/assets/images/...)
      image = Image.asset(
        effectiveUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            '[SafeNetworkImage] Ошибка локального ассета: $effectiveUrl — $error',
          );
          return placeholder ?? const _ImagePlaceholder();
        },
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        debugPrint(
          '[SafeNetworkImage] Failed to load: $imageUrl — $error',
        );
        return placeholder ?? const _ImagePlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _ImagePlaceholder(isLoading: true);
      },
    );
  }
}

/// Внутренний плейсхолдер — нейтральный серый фон с иконкой горы.
class _ImagePlaceholder extends StatelessWidget {
  final bool isLoading;

  const _ImagePlaceholder({this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: YandexColors.border,
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: YandexColors.textSecondary,
                ),
              )
            : const Icon(
                Icons.image_not_supported_outlined,
                color: YandexColors.textSecondary,
                size: 28,
              ),
      ),
    );
  }
}

