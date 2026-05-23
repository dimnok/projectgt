import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/contract.dart';

/// Выбранный объект для контекста модуля «Материалы» (фильтр и импорт).
final selectedMaterialsObjectIdProvider = StateProvider<String?>((ref) => null);

/// Выбранный договор (id из справочника [contracts]) для модуля «Материалы».
final selectedMaterialsContractIdProvider = StateProvider<String?>((ref) => null);

/// Активные договоры выбранного объекта (справочник [contracts]).
bool isMaterialsActiveContract(Contract contract) {
  return contract.status == ContractStatus.active;
}

/// Выбран ли договор для загрузки материалов и действий экрана.
bool hasMaterialsContractSelection(String? contractNumber) {
  return contractNumber != null && contractNumber.trim().isNotEmpty;
}
