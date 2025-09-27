import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projectgt/core/common/app_router.dart';

/// Действие AppBar: переход к экрану сопоставления материалов (алиасы → сметные позиции).
///
/// Кнопка-шестерёнка открывает отдельный экран настройки/просмотра сопоставлений.
class MaterialsMappingAction extends StatelessWidget {
  /// Конструктор действия перехода к экрану сопоставления материалов.
  const MaterialsMappingAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Сопоставление материалов',
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => context.push(AppRoutes.materialMapping),
    );
  }
}
