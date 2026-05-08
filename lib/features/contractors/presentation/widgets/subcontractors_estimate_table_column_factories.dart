import 'package:flutter/material.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/domain/entities/estimate.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_cells.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_column_config.dart';
import 'package:projectgt/features/contractors/presentation/widgets/subcontractors_estimate_table_math.dart';

/// Колонки таблицы расценок подрядчика (базовые поля сметы + блок суба при [showSubcontractorPricing]).
///
/// При [showInEstimatesModuleColumn] добавляется колонка «в модуле Сметы» (для карточки договора).
List<SubcontractorColumnConfig> buildSubcontractorsRatesTableColumns({
  required SubcontractorsEstimateTableMath math,
  required bool showSubcontractorPricing,
  required bool showInEstimatesModuleColumn,
  required Widget Function(Estimate estimate) selectionForRow,
  void Function(Estimate estimate)? onVisibleInEstimatesModuleTap,
}) {
  return [
    SubcontractorColumnConfig(
      title: '',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.5,
      minWidth: 42,
      builder: (e, _) => selectionForRow(e),
    ),
    SubcontractorColumnConfig(
      title: '№',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.7,
      minWidth: 40,
      measureText: (e) => e.number,
      builder: (e, _) => Text(e.number),
    ),
    SubcontractorColumnConfig(
      title: 'Наименование',
      headerAlign: TextAlign.center,
      flex: 4.2,
      isFlexible: true,
      minWidth: 220,
      measureText: (e) => e.name,
      builder: (e, _) =>
          Text(e.name, maxLines: 3, overflow: TextOverflow.ellipsis),
    ),
    SubcontractorColumnConfig(
      title: 'Артикул',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.8,
      minWidth: 76,
      measureText: (e) => e.article,
      builder: (e, _) => Text(e.article),
    ),
    SubcontractorColumnConfig(
      title: 'Производитель',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.8,
      minWidth: 102,
      measureText: (e) => e.manufacturer,
      builder: (e, _) => Text(e.manufacturer),
    ),
    SubcontractorColumnConfig(
      title: 'Ед. изм.',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.8,
      minWidth: 78,
      measureText: (e) => e.unit,
      builder: (e, _) => Text(e.unit),
    ),
    SubcontractorColumnConfig(
      title: 'Кол-во',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.8,
      minWidth: 70,
      measureText: (e) => formatQuantity(e.quantity),
      builder: (e, _) => Text(formatQuantity(e.quantity)),
    ),
    SubcontractorColumnConfig(
      title: 'Цена',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.centerRight,
      flex: 1.1,
      minWidth: 90,
      measureText: (e) => formatCurrency(e.price),
      builder: (e, t) => SubcontractorsEstimateTableCells.singleLineMoney(
        formatCurrency(e.price),
        TextStyle(color: t.colorScheme.primary),
        Alignment.centerRight,
      ),
    ),
    SubcontractorColumnConfig(
      title: 'Сумма',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.centerRight,
      flex: 1.2,
      minWidth: 100,
      measureText: (e) => formatCurrency(e.total),
      builder: (e, _) => SubcontractorsEstimateTableCells.singleLineMoney(
        formatCurrency(e.total),
        const TextStyle(),
        Alignment.centerRight,
      ),
    ),
    if (showInEstimatesModuleColumn)
      SubcontractorColumnConfig(
        title: '',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.55,
        minWidth: 36,
        headerBuilder: (theme) => Tooltip(
          message: 'Видимость в модуле «Сметы»',
          child: Icon(
            Icons.visibility_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        measureText: (_) => '●',
        builder: (e, _) {
          final ok = e.visibleInEstimatesModule;
          const double kDiameter = 22;
          final core = Semantics(
            label: ok ? 'Показана в модуле Сметы' : 'Скрыта в модуле Сметы',
            button: onVisibleInEstimatesModuleTap != null,
            child: Center(
              child: Container(
                width: kDiameter,
                height: kDiameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ok ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  ok ? Icons.check : Icons.close,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          );
          final tap = onVisibleInEstimatesModuleTap;
          if (tap == null) return core;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => tap(e),
            child: core,
          );
        },
      ),
    if (showSubcontractorPricing) ...[
      SubcontractorColumnConfig(
        title: 'Кол-во суб',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.center,
        flex: 0.85,
        minWidth: 76,
        isSubcontractorBlock: true,
        subBlockEdge: SubcontractorTableBlockEdge.start,
        measureText: (e) {
          final q = math.effectiveSubQuantity(e);
          return q != null ? formatQuantity(q) : '';
        },
        builder: (e, t) {
          final q = math.effectiveSubQuantity(e);
          return Text(
            q != null ? formatQuantity(q) : '—',
            style: TextStyle(
              color: q != null
                  ? t.colorScheme.secondary
                  : t.colorScheme.outline,
            ),
          );
        },
      ),
      SubcontractorColumnConfig(
        title: 'Цена суб',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.centerRight,
        flex: 1.0,
        minWidth: 86,
        isSubcontractorBlock: true,
        subBlockEdge: SubcontractorTableBlockEdge.inner,
        measureText: (e) {
          final p = math.subUnitPrice(e);
          return p != null ? formatCurrency(p) : '';
        },
        builder: (e, t) {
          final p = math.subUnitPrice(e);
          if (p == null) {
            return Text('—', style: TextStyle(color: t.colorScheme.outline));
          }
          return SubcontractorsEstimateTableCells.singleLineMoney(
            formatCurrency(p),
            TextStyle(color: t.colorScheme.secondary),
            Alignment.centerRight,
          );
        },
      ),
      SubcontractorColumnConfig(
        title: 'Сумма суб',
        headerAlign: TextAlign.center,
        cellAlignment: Alignment.centerRight,
        flex: 1.1,
        minWidth: 92,
        isSubcontractorBlock: true,
        subBlockEdge: SubcontractorTableBlockEdge.end,
        measureText: (e) {
          final s = math.subLineAmount(e);
          return s != null ? formatCurrency(s) : '';
        },
        builder: (e, t) {
          final s = math.subLineAmount(e);
          if (s == null) {
            return Text('—', style: TextStyle(color: t.colorScheme.outline));
          }
          return SubcontractorsEstimateTableCells.singleLineMoney(
            formatCurrency(s),
            TextStyle(color: t.colorScheme.secondary),
            Alignment.centerRight,
          );
        },
      ),
    ],
  ];
}

/// Колонки таблицы план-факт выполнения (план по данным суба + блок факта).
List<SubcontractorColumnConfig> buildSubcontractorsExecutionTableColumns({
  required SubcontractorsEstimateTableMath math,
  required Widget Function(Estimate estimate) selectionForRow,
}) {
  return [
    SubcontractorColumnConfig(
      title: '',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.5,
      minWidth: 42,
      builder: (e, _) => selectionForRow(e),
    ),
    SubcontractorColumnConfig(
      title: '№',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.7,
      minWidth: 40,
      measureText: (e) => e.number,
      builder: (e, _) => Text(e.number),
    ),
    SubcontractorColumnConfig(
      title: 'Наименование',
      headerAlign: TextAlign.center,
      flex: 4.2,
      isFlexible: true,
      minWidth: 220,
      measureText: (e) {
        final mark = math.executionVolumeAlert(e) ? '! ' : '';
        return '$mark${e.name}';
      },
      builder: (e, t) {
        if (!math.executionVolumeAlert(e)) {
          return Text(e.name, maxLines: 3, overflow: TextOverflow.ellipsis);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6, top: 1),
              child: Semantics(
                label:
                    'Предупреждение: перевыполнение по плану подрядчика или факт больше объёма по смете',
                child: Text(
                  '!',
                  style: TextStyle(
                    color: t.colorScheme.error,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(e.name, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
          ],
        );
      },
    ),
    SubcontractorColumnConfig(
      title: 'Ед. изм.',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.75,
      minWidth: 72,
      measureText: (e) => e.unit,
      builder: (e, _) => Text(e.unit),
    ),
    SubcontractorColumnConfig(
      title: 'Кол-во',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.9,
      minWidth: 82,
      measureText: (e) {
        final q = math.effectiveSubQuantity(e);
        return q != null ? formatQuantity(q) : '';
      },
      builder: (e, t) {
        final q = math.effectiveSubQuantity(e);
        return Text(
          q != null ? formatQuantity(q) : '—',
          style: TextStyle(color: q != null ? null : t.colorScheme.outline),
        );
      },
    ),
    SubcontractorColumnConfig(
      title: 'Цена',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.centerRight,
      flex: 1.0,
      minWidth: 86,
      measureText: (e) {
        final p = math.subUnitPrice(e);
        return p != null ? formatCurrency(p) : '';
      },
      builder: (e, t) {
        final p = math.subUnitPrice(e);
        if (p == null) {
          return Text('—', style: TextStyle(color: t.colorScheme.outline));
        }
        return SubcontractorsEstimateTableCells.singleLineMoney(
          formatCurrency(p),
          const TextStyle(),
          Alignment.centerRight,
        );
      },
    ),
    SubcontractorColumnConfig(
      title: 'Сумма',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.centerRight,
      flex: 1.15,
      minWidth: 96,
      measureText: (e) {
        final s = math.subLineAmount(e);
        return s != null ? formatCurrency(s) : '';
      },
      builder: (e, t) {
        final s = math.subLineAmount(e);
        if (s == null) {
          return Text('—', style: TextStyle(color: t.colorScheme.outline));
        }
        return SubcontractorsEstimateTableCells.singleLineMoney(
          formatCurrency(s),
          const TextStyle(),
          Alignment.centerRight,
        );
      },
    ),
    SubcontractorColumnConfig(
      title: 'Выполнено',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.95,
      minWidth: 88,
      isSubcontractorBlock: true,
      subBlockEdge: SubcontractorTableBlockEdge.start,
      measureText: (e) => formatQuantity(math.completedQuantity(e)),
      builder: (e, t) => Text(
        formatQuantity(math.completedQuantity(e)),
        style: TextStyle(color: t.colorScheme.primary),
      ),
    ),
    SubcontractorColumnConfig(
      title: 'Сумма вып.',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.centerRight,
      flex: 1.15,
      minWidth: 102,
      isSubcontractorBlock: true,
      subBlockEdge: SubcontractorTableBlockEdge.inner,
      measureText: (e) {
        final s = math.completedAmount(e);
        return s != null ? formatCurrency(s) : '';
      },
      builder: (e, t) {
        final s = math.completedAmount(e);
        if (s == null) {
          return Text('—', style: TextStyle(color: t.colorScheme.outline));
        }
        return SubcontractorsEstimateTableCells.singleLineMoney(
          formatCurrency(s),
          TextStyle(color: t.colorScheme.primary),
          Alignment.centerRight,
        );
      },
    ),
    SubcontractorColumnConfig(
      title: '%',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.65,
      minWidth: 62,
      isSubcontractorBlock: true,
      subBlockEdge: SubcontractorTableBlockEdge.inner,
      measureText: (e) {
        final p = math.completionPercent(e);
        return p == null
            ? ''
            : GtFormatters.formatPercentage(p, decimalDigits: 1);
      },
      builder: (e, t) {
        final p = math.completionPercent(e);
        return Text(
          p == null ? '—' : GtFormatters.formatPercentage(p, decimalDigits: 1),
          style: TextStyle(
            color: p == null ? t.colorScheme.outline : t.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    ),
    SubcontractorColumnConfig(
      title: 'Остаток',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.center,
      flex: 0.95,
      minWidth: 86,
      isSubcontractorBlock: true,
      subBlockEdge: SubcontractorTableBlockEdge.inner,
      measureText: (e) {
        final q = math.remainingQuantity(e);
        return q != null ? formatQuantity(q) : '';
      },
      builder: (e, t) {
        final q = math.remainingQuantity(e);
        final isOverPlan = q != null && q < 0;
        return Text(
          q != null ? formatQuantity(q) : '—',
          style: TextStyle(
            color: q == null
                ? t.colorScheme.outline
                : isOverPlan
                ? t.colorScheme.error
                : t.colorScheme.secondary,
            fontWeight: isOverPlan ? FontWeight.w700 : null,
          ),
        );
      },
    ),
    SubcontractorColumnConfig(
      title: 'Сумма ост.',
      headerAlign: TextAlign.center,
      cellAlignment: Alignment.centerRight,
      flex: 1.15,
      minWidth: 102,
      isSubcontractorBlock: true,
      subBlockEdge: SubcontractorTableBlockEdge.end,
      measureText: (e) {
        final s = math.remainingAmount(e);
        return s != null ? formatCurrency(s) : '';
      },
      builder: (e, t) {
        final s = math.remainingAmount(e);
        if (s == null) {
          return Text('—', style: TextStyle(color: t.colorScheme.outline));
        }
        final isOverPlan = s < 0;
        return SubcontractorsEstimateTableCells.singleLineMoney(
          formatCurrency(s),
          TextStyle(
            color: isOverPlan ? t.colorScheme.error : t.colorScheme.secondary,
            fontWeight: isOverPlan ? FontWeight.w700 : null,
          ),
          Alignment.centerRight,
        );
      },
    ),
  ];
}
