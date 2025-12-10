import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:projectgt/features/procurement/data/models/bot_user_model.dart';
import 'package:projectgt/features/procurement/data/repositories/procurement_repository.dart';
import 'package:projectgt/features/procurement/presentation/controllers/procurement_settings_state.dart';

part 'procurement_settings_controller.g.dart';

/// Контроллер для управления настройками закупок.
///
/// Отвечает за:
/// - Загрузку списка пользователей и текущей конфигурации согласования.
/// - Обновление ответственных за этапы согласования.
@riverpod
class ProcurementSettingsController extends _$ProcurementSettingsController {
  @override
  Future<ProcurementSettingsState> build() async {
    final repository = ref.read(procurementRepositoryProvider);
    final results = await Future.wait([
      repository.getBotUsers(),
      repository.getApprovalConfig(),
    ]);

    return ProcurementSettingsState(
      users: results[0] as List<BotUserModel>,
      config: results[1] as Map<String, List<String>>,
    );
  }

  /// Обновляет список ответственных для указанного этапа.
  ///
  /// Использует оптимистичное обновление состояния и откатывает изменения
  /// в случае ошибки сохранения.
  Future<void> updateStage(String stage, List<String> userIds) async {
    final currentState = state.value;
    if (currentState == null) return;

    // Optimistic update
    final newConfig = Map<String, List<String>>.from(currentState.config);
    newConfig[stage] = userIds;
    state = AsyncValue.data(currentState.copyWith(config: newConfig));

    try {
      await ref
          .read(procurementRepositoryProvider)
          .saveStageApprovers(stage, userIds);
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }
}
