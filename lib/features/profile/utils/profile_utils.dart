import 'package:projectgt/domain/entities/profile.dart';

/// Утилиты для работы с профилем пользователя.
class ProfileUtils {
  /// Генерирует сокращенное имя из полного в формате "Фамилия И.О.".
  static String? generateShortName(String fullName) {
    if (fullName.isEmpty) return null;

    final nameParts = fullName.split(' ');
    if (nameParts.length > 1) {
      final lastName = nameParts[0];
      final initials = nameParts
          .sublist(1)
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0]}.')
          .join('');
      return '$lastName $initials';
    }
    return fullName;
  }

  /// Подготавливает обновленный профиль перед сохранением.
  ///
  /// Обрабатывает логику обновления object (employee_id), генерации shortName
  /// и учета прав доступа (если isAdmin=false, некоторые поля не меняются).
  static Profile prepareProfileForUpdate({
    required Profile originalProfile,
    required String fullName,
    required String phone,
    required List<String> selectedObjectIds,
    required String? employeeId,
    required String? roleId,
    required bool isAdmin,
  }) {
    // Генерируем сокращенное имя
    final shortName = generateShortName(fullName);

    // Обновляем связь с сотрудником в поле object
    final newObject = originalProfile.object == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(originalProfile.object!);

    if (employeeId != null && employeeId.isNotEmpty) {
      newObject['employee_id'] = employeeId;
    } else {
      newObject.remove('employee_id');
    }

    // Если пользователь НЕ админ - используем оригинальные значения для критических полей
    final objectIdsToSave = isAdmin
        ? selectedObjectIds
        : originalProfile.objectIds ?? [];
    final roleIdToSave = isAdmin ? roleId : originalProfile.roleId;

    return originalProfile.copyWith(
      fullName: fullName,
      shortName: shortName,
      phone: phone,
      objectIds: objectIdsToSave,
      roleId: roleIdToSave,
      object: newObject,
      updatedAt: DateTime.now(),
    );
  }
}
