import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/domain/entities/employee.dart';
import 'package:projectgt/presentation/state/employee_state.dart';

/// Провайдер операций с аватаром сотрудника (загрузка, удаление, сохранение файла/в галерею).
final employeeAvatarControllerProvider =
    StateNotifierProvider<EmployeeAvatarController, AsyncValue<void>>((ref) {
  return EmployeeAvatarController(ref);
});

/// Контроллер операций с аватаром: загрузка/удаление везде; скачивание —
/// веб и десктоп (файл / «Загрузки»), **iOS/Android** — сохранение в системную галерею ([Gal]).
class EmployeeAvatarController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  /// Создает контроллер для управления аватаром.
  EmployeeAvatarController(this._ref) : super(const AsyncValue.data(null));

  /// Загружает новый аватар для сотрудника.
  Future<void> uploadAvatar(
    Employee employee,
    ImageSource source,
    BuildContext context,
  ) async {
    state = const AsyncValue.loading();
    try {
      final photoService = _ref.read(photoServiceProvider);
      final file = await photoService.pickImage(source);
      if (file == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final url = await photoService.uploadPhoto(
        entity: 'employee',
        id: employee.id,
        file: file,
        displayName: employee.fullName,
      );

      if (url != null) {
        final updatedEmployee = employee.copyWith(photoUrl: url);
        await _ref.read(employeeProvider.notifier).updateEmployee(updatedEmployee);
        if (context.mounted) {
          SnackBarUtils.showSuccessOverlay(context, 'Фото успешно обновлено');
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (context.mounted) {
        SnackBarUtils.showErrorOverlay(context, 'Ошибка загрузки фото: $e');
      }
    }
  }

  /// Удаляет текущий аватар сотрудника.
  Future<void> deleteAvatar(Employee employee, BuildContext context) async {
    state = const AsyncValue.loading();
    try {
      final photoService = _ref.read(photoServiceProvider);
      await photoService.deletePhoto(
        entity: 'employee',
        id: employee.id,
        displayName: employee.fullName,
      );

      final updatedEmployee = employee.copyWith(photoUrl: null);
      await _ref.read(employeeProvider.notifier).updateEmployee(updatedEmployee);

      state = const AsyncValue.data(null);
      if (context.mounted) {
        SnackBarUtils.showSuccessOverlay(context, 'Фото успешно удалено');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (context.mounted) {
        SnackBarUtils.showErrorOverlay(context, 'Ошибка удаления фото: $e');
      }
    }
  }

  /// Скачивает или сохраняет аватар: веб/десктоп — файл; iOS/Android — галерея ([Gal]).
  Future<void> downloadAvatar(BuildContext context, Employee employee) async {
    if (employee.photoUrl == null) return;

    state = const AsyncValue.loading();
    try {
      final response = await http.get(Uri.parse(employee.photoUrl!));

      if (response.statusCode != 200) {
        throw Exception('Не удалось скачать изображение');
      }

      final lastName =
          employee.lastName.trim().isNotEmpty ? employee.lastName.trim() : 'Неизвестно';
      final firstName =
          employee.firstName.trim().isNotEmpty ? employee.firstName.trim() : 'Имя';
      final middleName = employee.middleName?.trim().isNotEmpty == true
          ? '_${employee.middleName!.trim()}'
          : '';

      final cleanFileName = '${lastName}_$firstName$middleName'
          .replaceAll(RegExp(r'[^\w\s\-\._а-яА-Я]', unicode: true), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'_+'), '_');

      final finalFileName = cleanFileName.replaceAll(RegExp(r'^_+|_+$'), '');
      final safeFileName = finalFileName.isNotEmpty ? finalFileName : 'employee_avatar';

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: safeFileName,
          bytes: response.bodyBytes,
          ext: 'jpg',
          mimeType: MimeType.jpeg,
        );
      } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception('Не удалось найти папку загрузок');
        }
        final file = File('${directory.path}/$safeFileName.jpg');
        await file.writeAsBytes(response.bodyBytes);
      } else if (Platform.isAndroid || Platform.isIOS) {
        final granted = await Gal.requestAccess(toAlbum: false);
        if (!granted) {
          throw Exception('Нет разрешения на сохранение в галерею');
        }
        final name = safeFileName.length > 100
            ? safeFileName.substring(0, 100)
            : safeFileName;
        await Gal.putImageBytes(response.bodyBytes, name: name);
      } else {
        throw UnsupportedError(
          'Сохранение фото не поддерживается на этой платформе.',
        );
      }

      state = const AsyncValue.data(null);
      if (context.mounted) {
        final message = kIsWeb
            ? 'Фото скачано в папку «Загрузки»'
            : (Platform.isAndroid || Platform.isIOS)
                ? 'Фото сохранено в галерею'
                : 'Фото сохранено в папку «Загрузки»';
        SnackBarUtils.showSuccessOverlay(context, message);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      if (context.mounted) {
        SnackBarUtils.showErrorOverlay(context, 'Ошибка скачивания: ${e.toString()}');
      }
    }
  }
}
