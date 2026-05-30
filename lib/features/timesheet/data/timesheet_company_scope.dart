/// Сообщение для UI, если активная компания не выбрана.
const String timesheetNoActiveCompanyMessage =
    'Не выбрана активная компания. Выберите компанию в профиле, чтобы загрузить табель.';

/// Проверяет, что [companyId] пригоден для multi-tenant запросов табеля.
///
/// Согласовано с [SupabaseEmployeeDataSource]: пустая строка и литерал `'null'`
/// считаются отсутствием компании.
bool timesheetHasActiveCompany(String? companyId) {
  if (companyId == null) return false;
  final id = companyId.trim();
  return id.isNotEmpty && id != 'null';
}

/// Исключение: нет активной компании для операций табеля с записью в БД.
class TimesheetCompanyNotSelectedException implements Exception {
  /// Создаёт исключение с [timesheetNoActiveCompanyMessage].
  const TimesheetCompanyNotSelectedException();

  @override
  String toString() => timesheetNoActiveCompanyMessage;
}
