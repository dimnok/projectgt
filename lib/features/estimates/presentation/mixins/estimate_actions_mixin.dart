import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/providers.dart'; // Добавлен для estimateNotifierProvider
import '../../../../domain/entities/estimate.dart';
import '../../../../presentation/widgets/cupertino_dialog_widget.dart';
import '../providers/estimate_providers.dart';
import '../widgets/estimate_edit_dialog.dart';

/// Миксин, инкапсулирующий бизнес-логику управления позициями сметы.
/// Предназначен для использования в ConsumerState.
///
/// Требует реализации геттера [currentEstimateArgs] для корректного обновления UI.
mixin EstimateActionsMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final Uuid _uuid = const Uuid();

  /// Аргументы текущей открытой сметы.
  /// Используются для инвалидации провайдера после изменений.
  EstimateDetailArgs? get currentEstimateArgs;

  /// Открытие диалога редактирования/создания позиции.
  void openEditDialog(
    BuildContext context, {
    Estimate? estimate,
    required String? estimateTitle,
    String? objectId,
    String? contractId,
  }) {
    // Если передан estimate, берем ID из него, иначе используем переданные параметры (или параметры текущего контекста)
    final targetObjectId = estimate?.objectId ?? objectId ?? currentEstimateArgs?.objectId;
    final targetContractId = estimate?.contractId ?? contractId ?? currentEstimateArgs?.contractId;
    final targetTitle = estimateTitle ?? currentEstimateArgs?.estimateTitle;

    EstimateEditDialog.show(
      context,
      estimate: estimate,
      estimateTitle: targetTitle,
      objectId: targetObjectId,
      contractId: targetContractId,
    );
  }

  /// Удаление позиции сметы.
  Future<void> deleteEstimateItem(BuildContext context, String id) async {
    final confirmed = await CupertinoDialogs.showDeleteConfirmDialog<bool>(
      context: context,
      title: 'Удаление позиции',
      message: 'Вы действительно хотите удалить эту позицию?',
      onConfirm: () {}, // Логика вынесена ниже для удобства await
    );

    if (confirmed == true && mounted) {
      await ref.read(estimateNotifierProvider.notifier).deleteEstimate(id);
      _invalidateCurrentList();
    }
  }

  /// Дублирование позиции сметы.
  Future<void> duplicateEstimateItem(BuildContext context, Estimate estimate, {bool isSwipe = false}) async {
    if (isSwipe) {
      await _createDuplicate(estimate);
      return;
    }

    final confirmed = await CupertinoDialogs.showDuplicateConfirmDialog<bool>(
      context: context,
      title: 'Дублирование позиции',
      message: 'Вы действительно хотите создать дубликат позиции №${estimate.number}?',
      onConfirm: () {}, // Логика вынесена ниже
    );

    if (confirmed == true && mounted) {
      await _createDuplicate(estimate);
    }
  }

  /// Внутренняя логика создания дубликата.
  Future<void> _createDuplicate(Estimate estimate) async {
    String newNumber = estimate.number;
    
    // Умная инкрементация номера
    if (RegExp(r'^\d+$').hasMatch(estimate.number)) {
      try {
        final numValue = int.parse(estimate.number);
        newNumber = (numValue + 1).toString();
      } catch (_) {
        newNumber = "${estimate.number}-копия";
      }
    } else {
      newNumber = "${estimate.number}-копия";
    }

    final newItem = estimate.copyWith(
      id: _uuid.v4(),
      number: newNumber,
    );

    await ref.read(estimateNotifierProvider.notifier).addEstimate(newItem);
    _invalidateCurrentList();
  }

  /// Обновление списка элементов.
  void _invalidateCurrentList() {
    if (currentEstimateArgs != null) {
      ref.invalidate(estimateItemsProvider(currentEstimateArgs!));
    }
  }
}
