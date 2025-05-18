import 'package:flutter/material.dart';
import 'package:projectgt/features/employees/presentation/screens/employee_form_screen.dart';

/// Утилитарный класс для работы с модальными окнами.
///
/// Содержит методы для отображения различных типов модальных окон в приложении.
class ModalUtils {
  /// Показывает модальное окно с формой редактирования/создания сотрудника.
  ///
  /// [context] - контекст для отображения модального окна.
  /// [employeeId] - ID сотрудника для редактирования (null для создания нового).
  static Future<void> showEmployeeFormModal(BuildContext context, {String? employeeId}) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    Widget modalContent = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 1.0,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: EmployeeFormScreen(employeeId: employeeId),
          ),
        ),
      ),
    );
    
    // Обернём в Center с точной шириной 50% для десктопов
    if (isDesktop) {
      modalContent = Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: modalContent,
        ),
      );
    }
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height - 
                  MediaQuery.of(context).padding.top - 
                  kToolbarHeight,
      ),
      builder: (context) => modalContent,
    );
  }
} 