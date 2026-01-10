import 'package:flutter/material.dart';
import 'package:projectgt/core/widgets/gt_text_field.dart';

/// Виджет формы создания/редактирования объекта недвижимости.
class ObjectFormContent extends StatelessWidget {
  /// Флаг: true — форма создания, false — форма редактирования.
  final bool isNew;

  /// Флаг: true — форма/кнопки заблокированы, отображается индикатор загрузки.
  final bool isLoading;

  /// Контроллер для поля "Наименование".
  final TextEditingController nameController;

  /// Контроллер для поля "Адрес".
  final TextEditingController addressController;

  /// Контроллер для поля "Описание".
  final TextEditingController descriptionController;

  /// Ключ формы для валидации.
  final GlobalKey<FormState> formKey;

  /// Колбэк для отмены и закрытия формы.
  final VoidCallback onCancel;

  /// Создаёт содержимое формы объекта.
  const ObjectFormContent({
    super.key,
    required this.isNew,
    required this.isLoading,
    required this.nameController,
    required this.addressController,
    required this.descriptionController,
    required this.formKey,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Наименование
          GTTextField(
            controller: nameController,
            labelText: 'Наименование *',
            hintText: 'Введите наименование',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите наименование' : null,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          // Адрес
          GTTextField(
            controller: addressController,
            labelText: 'Адрес *',
            hintText: 'Введите адрес',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Введите адрес' : null,
            enabled: !isLoading,
          ),
          const SizedBox(height: 16),
          // Описание
          GTTextField(
            controller: descriptionController,
            labelText: 'Описание',
            hintText: 'Введите описание',
            maxLines: 4,
            enabled: !isLoading,
          ),
        ],
      ),
    );
  }
}
