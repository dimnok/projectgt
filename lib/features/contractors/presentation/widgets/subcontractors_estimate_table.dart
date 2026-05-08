import 'package:flutter/material.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_mode.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_contractor_unit_prices_provider.dart';
import 'package:projectgt/features/contractors/presentation/providers/subcontractors_execution_progress_provider.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_view.dart';

export 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_mode.dart'
    show SubcontractorsEstimateTableMode;

/// Таблица сметы для модуля «Подрядчики».
///
/// Оборачивает [SubcontractorsEstimateTableView] (реализация в модуле
/// `contractors`, не зависит от виджета смет). Данные и действия задаются
/// снаружи; [onAddPosition] добавляет в контекстное меню создание позиции сметы
/// (см. права `estimates` / `update` в [SubcontractorsEstimateTableView]);
/// [onEstimateAddendumHistory] — пункт «История по ДС» (право `estimates` / `read`).
class SubcontractorsEstimateTable extends StatelessWidget {
  /// Создаёт таблицу.
  const SubcontractorsEstimateTable({
    super.key,
    this.items = const [],
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onAddPosition,
    this.onRowTap,
    this.selectedId,
    this.subcontractorPricingByEstimateId,
    this.executionByEstimateId,
    this.mode = SubcontractorsEstimateTableMode.rates,
    this.expandSections = false,
    this.selectedEstimateIds = const <String>{},
    this.onSelectedEstimateIdsChanged,
    this.showInEstimatesModuleColumn = false,
    this.onVisibleInEstimatesModuleTap,
    this.onDeleteSelected,
    this.onEstimateAddendumHistory,
  });

  /// Позиции сметы.
  final List<Estimate> items;

  /// Расценки и объёмы подрядчика по id позиции; null — без дополнительных колонок.
  final Map<String, SubcontractorPricingForEstimate>?
  subcontractorPricingByEstimateId;

  /// Факт выполнения подрядчика по id позиции; нужен для режима
  /// [SubcontractorsEstimateTableMode.execution].
  final Map<String, SubcontractorExecutionProgress>? executionByEstimateId;

  /// Режим набора колонок таблицы.
  final SubcontractorsEstimateTableMode mode;

  /// После обновления списка позиций держать разделы раскрытыми (`true`) или свернуть все
  /// (`false`). Переключение по названию группы см. в [SubcontractorsEstimateTableView].
  final bool expandSections;

  /// ID позиций, отмеченных чекбоксами.
  final Set<String> selectedEstimateIds;

  /// Вызывается при изменении набора отмеченных позиций.
  final ValueChanged<Set<String>>? onSelectedEstimateIdsChanged;

  /// Показывать колонку «видна в модуле Сметы» (карточка договора).
  final bool showInEstimatesModuleColumn;

  /// Нажатие на индикатор видимости в модуле «Сметы».
  final void Function(Estimate estimate)? onVisibleInEstimatesModuleTap;

  /// Удалить отмеченные чекбоксами позиции (контекстное меню «Удалить выбранное»).
  final void Function(BuildContext context)? onDeleteSelected;

  /// История по ДС для строки (карточка договора); `null` — пункт меню скрыт.
  final void Function(Estimate estimate)? onEstimateAddendumHistory;

  /// Редактирование позиции.
  final void Function(Estimate)? onEdit;

  /// Дублирование позиции.
  final void Function(Estimate)? onDuplicate;

  /// Удаление позиции по id.
  final void Function(String id)? onDelete;

  /// Добавить позицию в ту же смету, что и строка, по которой открыли меню (см. [SubcontractorsEstimateTableView.onAddPosition]).
  final void Function(Estimate contextRow)? onAddPosition;

  /// Нажатие на строку.
  final void Function(Estimate)? onRowTap;

  /// ID выбранной позиции (подсветка строки).
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: SubcontractorsEstimateTableView(
        items: items,
        selectedId: selectedId,
        subcontractorPricingByEstimateId: subcontractorPricingByEstimateId,
        executionByEstimateId: executionByEstimateId,
        mode: mode,
        expandSections: expandSections,
        selectedEstimateIds: selectedEstimateIds,
        onSelectedEstimateIdsChanged: onSelectedEstimateIdsChanged,
        onRowTap: onRowTap,
        onEdit: onEdit ?? (_) {},
        onDuplicate: onDuplicate ?? (_) {},
        onDelete: onDelete ?? (_) {},
        onAddPosition: onAddPosition,
        showInEstimatesModuleColumn: showInEstimatesModuleColumn,
        onVisibleInEstimatesModuleTap: onVisibleInEstimatesModuleTap,
        onDeleteSelected: onDeleteSelected,
        onEstimateAddendumHistory: onEstimateAddendumHistory,
      ),
    );
  }
}
