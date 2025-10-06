/// Утилита для работы с версиями приложения.
class VersionUtils {
  /// Сравнивает две версии в формате major.minor.patch.
  ///
  /// Возвращает:
  /// - 1 если [current] > [minimum]
  /// - 0 если [current] == [minimum]
  /// - -1 если [current] < [minimum]
  ///
  /// Пример:
  /// ```dart
  /// compareVersions('1.2.3', '1.2.0') // returns 1
  /// compareVersions('1.0.0', '1.0.0') // returns 0
  /// compareVersions('0.9.0', '1.0.0') // returns -1
  /// ```
  static int compareVersions(String current, String minimum) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minimumParts = minimum.split('.').map(int.parse).toList();

      // Дополняем нулями если версии разной длины
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (minimumParts.length < 3) {
        minimumParts.add(0);
      }

      // Сравниваем major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] > minimumParts[i]) return 1;
        if (currentParts[i] < minimumParts[i]) return -1;
      }

      return 0; // Версии равны
    } catch (e) {
      // В случае ошибки парсинга считаем версии несовместимыми
      return -1;
    }
  }

  /// Проверяет, поддерживается ли текущая версия.
  ///
  /// Возвращает true если текущая версия >= минимальной.
  static bool isVersionSupported(String current, String minimum) {
    return compareVersions(current, minimum) >= 0;
  }
}
