import 'package:projectgt/features/procurement/data/models/bot_user_model.dart';

/// Состояние экрана настроек модуля закупок.
class ProcurementSettingsState {
  /// Текущая конфигурация согласования (этап -> список ID пользователей).
  final Map<String, List<String>> config;

  /// Список доступных пользователей (для выбора ответственных).
  final List<BotUserModel> users;

  /// Создаёт состояние настроек.
  const ProcurementSettingsState({
    required this.config,
    required this.users,
  });

  /// Создаёт копию состояния с обновленными полями.
  ProcurementSettingsState copyWith({
    Map<String, List<String>>? config,
    List<BotUserModel>? users,
  }) {
    return ProcurementSettingsState(
      config: config ?? this.config,
      users: users ?? this.users,
    );
  }
}
