import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/employee.dart';

/// Утилитарный класс для форматирования и отображения данных сотрудника.
///
/// Содержит методы для получения текстовых представлений и цветовых индикаторов
/// для статусов и типов занятости сотрудников.
class EmployeeUIUtils {
  /// Возвращает текстовое представление и цвет для [status] сотрудника.
  ///
  /// Используется для отображения статуса сотрудника в интерфейсе.
  /// Возвращает кортеж из строки и цвета.
  static (String, Color) getStatusInfo(EmployeeStatus status) {
    switch (status) {
      case EmployeeStatus.working:
        return ('Работает', Colors.green);
      case EmployeeStatus.vacation:
        return ('Отпуск', Colors.blue);
      case EmployeeStatus.sickLeave:
        return ('Больничный', Colors.orange);
      case EmployeeStatus.unpaidLeave:
        return ('Без содержания', Colors.purple);
      case EmployeeStatus.fired:
        return ('Уволен', Colors.red);
    }
  }

  /// Возвращает текстовое представление для [type] трудоустройства.
  ///
  /// Используется для отображения типа трудоустройства сотрудника в интерфейсе.
  static String getEmploymentTypeText(EmploymentType type) {
    switch (type) {
      case EmploymentType.official:
        return 'Официально';
      case EmploymentType.unofficial:
        return 'Неофициально';
    }
  }
}
