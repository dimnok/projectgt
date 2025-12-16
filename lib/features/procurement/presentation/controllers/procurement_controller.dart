import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:projectgt/features/procurement/domain/entities/procurement_application.dart';
import 'package:projectgt/features/procurement/data/repositories/procurement_repository.dart';

part 'procurement_controller.g.dart';

/// Контроллер для управления списком заявок на закупку.
///
/// Отвечает за загрузку и обновление списка заявок.
@riverpod
class ProcurementController extends _$ProcurementController {
  @override
  Future<List<ProcurementApplication>> build() async {
    return _fetchApplications();
  }

  Future<List<ProcurementApplication>> _fetchApplications() async {
    final repository = ref.read(procurementRepositoryProvider);
    return repository.getApplications();
  }

  /// Обновляет список заявок.
  ///
  /// Принудительно перезагружает данные из репозитория.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchApplications());
  }
}
