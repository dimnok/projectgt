import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/widgets/app_snackbar.dart';
import 'package:projectgt/features/works/presentation/widgets/photo_loading_dialog.dart';

/// Вспомогательный класс для загрузки фото с единой логикой.
///
/// Централизует логику загрузки фото (утреннего и вечернего) из разных мест
/// приложения, избегая дублирования кода.
class PhotoUploadHelper {
  /// Контекст приложения для отображения диалогов и сообщений об ошибках.
  final BuildContext context;

  /// Ссылка на провайдеры Riverpod для доступа к сервисам.
  final WidgetRef ref;

  /// Создаёт помощник для загрузки фото.
  ///
  /// [context] используется для показа диалогов и уведомлений.
  /// [ref] необходим для доступа к провайдерам Riverpod.
  PhotoUploadHelper({
    required this.context,
    required this.ref,
  });

  /// Загружает фото с отображением прогресса и диалогов успеха/ошибки.
  ///
  /// [photoType] - тип фото (утреннее или вечернее)
  /// [entity] - сущность для Supabase ('work', 'shift')
  /// [entityId] - ID сущности
  /// [displayName] - имя для сохранения ('morning', 'evening')
  /// [photoBytes] - байты фото (для web)
  /// [photoFile] - файл фото (для mobile)
  /// [workDate] - дата смены (опционально, для path в Supabase)
  /// [onLoadingComplete] - callback когда загрузка завершена (100%)
  /// [onSuccess] - callback после нажатия "Готово"
  ///
  /// Возвращает URL загруженного фото или null при ошибке.
  Future<String?> uploadPhoto({
    required PhotoType photoType,
    required String entity,
    required String entityId,
    required String displayName,
    Uint8List? photoBytes,
    File? photoFile,
    DateTime? workDate,
    Function(String)? onLoadingComplete,
    Function(String)? onSuccess,
  }) async {
    try {
      final photoService = ref.read(photoServiceProvider);

      // ✅ Используем ValueNotifier для отслеживания прогресса
      final progressNotifier = ValueNotifier<double>(0.0);

      if (!context.mounted) return null;

      // ✅ Показываем диалог загрузки
      Future.microtask(() {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, child) {
                return PhotoLoadingDialog(
                  progress: progress,
                  isComplete: false,
                  photoType: photoType,
                  onDone: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                );
              },
            );
          },
        );
      });

      // ✅ Имитируем прогресс загрузки (0-95%)
      for (int i = 0; i < 95; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        if (context.mounted) {
          progressNotifier.value = (i + 1) / 100;
        }
      }

      // ✅ Загружаем фото на сервер
      String? uploadedUrl;
      if (photoBytes != null) {
        uploadedUrl = await photoService.uploadPhotoBytes(
          entity: entity,
          id: entityId,
          bytes: photoBytes,
          displayName: displayName,
          workDate: workDate,
        );
      } else if (photoFile != null) {
        uploadedUrl = await photoService.uploadPhoto(
          entity: entity,
          id: entityId,
          file: photoFile,
          displayName: displayName,
        );
      }

      // ✅ Проверяем что фото успешно загружено
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          progressNotifier.dispose();
          AppSnackBar.show(
            context: context,
            message: 'Не удалось загрузить фото. Пожалуйста, попробуйте снова.',
            kind: AppSnackBarKind.warning,
          );
        }
        return null;
      }

      // ✅ Завершаем прогресс до 100%
      if (context.mounted) {
        progressNotifier.value = 1.0;
      }

      if (!context.mounted) return null;

      // ✅ Вызываем callback для длительных операций
      // Это происходит ДО закрытия диалога загрузки
      await onLoadingComplete?.call(uploadedUrl);

      if (!context.mounted) return null;

      // ✅ Закрываем диалог загрузки
      Navigator.of(context, rootNavigator: true).pop();

      // ✅ Очищаем ValueNotifier
      progressNotifier.dispose();

      // ✅ Показываем диалог успеха
      if (!context.mounted) {
        return null;
      }

      // ✅ Используем Completer для ожидания нажатия кнопки "Готово"
      final successCompleter = Completer<void>();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PhotoLoadingDialog(
            progress: 1.0,
            isComplete: true,
            photoType: photoType,
            onDone: () {
              Navigator.of(dialogContext, rootNavigator: true).pop();
              successCompleter.complete();
              onSuccess?.call(uploadedUrl!);
            },
          );
        },
      );

      // ✅ ЖДЕМ пока пользователь нажмет "Готово"
      await successCompleter.future;

      return uploadedUrl;
    } catch (e) {
      if (!context.mounted) return null;

      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}

      AppSnackBar.show(
        context: context,
        message: 'Ошибка при загрузке фото: $e',
        kind: AppSnackBarKind.error,
      );
      return null;
    }
  }
}
