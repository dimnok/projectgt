import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/responsive_utils.dart';
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
  PhotoUploadHelper({required this.context, required this.ref});

  /// Загружает фото с индикатором и диалогами успеха/ошибки.
  ///
  /// Индикатор крутится, пока идёт сжатие и отправка файла. Процент не
  /// имитируется: клиент хранилища не сообщает долю загруженных байт.
  ///
  /// [photoType] - тип фото (утреннее или вечернее)
  /// [entity] - сущность для Supabase ('work', 'shift')
  /// [entityId] - ID сущности
  /// [displayName] - имя для сохранения ('morning', 'evening')
  /// [photoBytes] - байты фото (для web)
  /// [photoFile] - файл фото (для mobile)
  /// [workDate] - дата смены (опционально, для path в Supabase)
  /// [onLoadingComplete] - callback после успешной отправки файла
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
    var overlayShown = false;
    try {
      final photoService = ref.read(photoServiceProvider);

      if (!context.mounted) return null;

      _presentLoadingOverlay(photoType);
      overlayShown = true;

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

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        if (overlayShown) {
          _dismissLoadingOverlay();
          overlayShown = false;
        }
        if (context.mounted) {
          AppSnackBar.show(
            context: context,
            message: 'Не удалось загрузить фото. Пожалуйста, попробуйте снова.',
            kind: AppSnackBarKind.warning,
          );
        }
        return null;
      }

      if (!context.mounted) {
        if (overlayShown) {
          _dismissLoadingOverlay();
        }
        return null;
      }

      await onLoadingComplete?.call(uploadedUrl);

      if (overlayShown) {
        _dismissLoadingOverlay();
        overlayShown = false;
      }

      if (!context.mounted) {
        return null;
      }

      // ✅ Используем Completer для ожидания нажатия кнопки "Готово"
      final successCompleter = Completer<void>();

      final useSheet = ResponsiveUtils.isMobile(context);
      if (useSheet) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          constraints: BoxConstraints(maxWidth: screenWidth),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isDismissible: false,
          enableDrag: false,
          builder: (sheetContext) {
            return PhotoLoadingDialog(
              useBottomSheet: true,
              progress: 1.0,
              isComplete: true,
              photoType: photoType,
              onDone: () {
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext, rootNavigator: true).pop();
                }
                successCompleter.complete();
                onSuccess?.call(uploadedUrl!);
              },
            );
          },
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return PhotoLoadingDialog(
              useBottomSheet: false,
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
      }

      // ✅ ЖДЕМ пока пользователь нажмет "Готово"
      await successCompleter.future;

      return uploadedUrl;
    } catch (e) {
      if (overlayShown) {
        _dismissLoadingOverlay();
      }
      if (!context.mounted) return null;

      AppSnackBar.show(
        context: context,
        message: 'Ошибка при загрузке фото: $e',
        kind: AppSnackBarKind.error,
      );
      return null;
    }
  }

  /// Показывает окно загрузки. Вызывать до отправки файла, чтобы закрытие
  /// не сняло форму смены.
  void _presentLoadingOverlay(PhotoType photoType) {
    final useSheet = ResponsiveUtils.isMobile(context);
    if (useSheet) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(maxWidth: screenWidth),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) {
          return PhotoLoadingDialog(
            useBottomSheet: true,
            progress: null,
            isComplete: false,
            photoType: photoType,
          );
        },
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PhotoLoadingDialog(
          useBottomSheet: false,
          progress: null,
          isComplete: false,
          photoType: photoType,
        );
      },
    );
  }

  /// Закрывает окно загрузки, если контекст ещё жив.
  void _dismissLoadingOverlay() {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}
