// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procurement_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$procurementSettingsControllerHash() =>
    r'a257ebb7aefab5a2072420e38791624959016145';

/// Контроллер для управления настройками закупок.
///
/// Отвечает за:
/// - Загрузку списка пользователей и текущей конфигурации согласования.
/// - Обновление ответственных за этапы согласования.
///
/// Copied from [ProcurementSettingsController].
@ProviderFor(ProcurementSettingsController)
final procurementSettingsControllerProvider = AutoDisposeAsyncNotifierProvider<
    ProcurementSettingsController, ProcurementSettingsState>.internal(
  ProcurementSettingsController.new,
  name: r'procurementSettingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$procurementSettingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProcurementSettingsController
    = AutoDisposeAsyncNotifier<ProcurementSettingsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
