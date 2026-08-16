/// Ошибка репозитория заявок: не выбрана активная компания.
class PurchaseRequestCompanyRequiredException implements Exception {
  /// Создаёт исключение.
  const PurchaseRequestCompanyRequiredException();

  @override
  String toString() => 'Не выбрана активная компания';
}
