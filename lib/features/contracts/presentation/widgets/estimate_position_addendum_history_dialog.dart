import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/mobile_bottom_sheet_content.dart';
import 'package:projectgt/features/contracts/presentation/providers/estimate_position_addendum_history_provider.dart';

/// Тело read-only диалога истории позиции по ревизиям ДС.
class EstimatePositionAddendumHistoryBody extends ConsumerWidget {
  /// Создаёт тело с загрузкой [estimatePositionAddendumHistoryProvider].
  const EstimatePositionAddendumHistoryBody({
    super.key,
    required this.request,
    required this.rowSubtitle,
  });

  /// Параметры загрузки.
  final EstimatePositionHistoryRequest request;

  /// Подзаголовок (например наименование позиции).
  final String rowSubtitle;

  static String _changeTypeRu(String raw) {
    switch (raw) {
      case 'added':
        return 'Добавлено';
      case 'removed':
        return 'Удалено';
      case 'qty_changed':
        return 'Изм. кол-ва';
      case 'price_changed':
        return 'Изм. цены';
      case 'unchanged':
        return 'Без изменений';
      case 'current':
        return 'Текущее';
      default:
        return raw.isEmpty ? '—' : raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(estimatePositionAddendumHistoryProvider(request));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          rowSubtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Смета: ${request.estimateTitle}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            'Показаны только снимки из ревизий (основная + ДС). '
            'Ручные правки в смете без повторного импорта ДС здесь не отображаются.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ),
        const SizedBox(height: 16),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => SelectableText(
            'Не удалось загрузить историю: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return Text('Нет данных.', style: theme.textTheme.bodyMedium);
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                ),
                itemBuilder: (ctx, i) {
                  final r = rows[i];
                  final dateStr = formatRuDateTime(r.displayDate);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.revisionLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.55,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Кол-во: ${formatQuantity(r.quantity)} · '
                          'Цена: ${formatCurrency(r.price)} · '
                          'Сумма: ${formatCurrency(r.total)} · '
                          '${_changeTypeRu(r.changeType)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Точка входа: диалог (десктоп) или bottom sheet (мобильный).
class EstimatePositionAddendumHistoryDialog {
  EstimatePositionAddendumHistoryDialog._();

  /// Показывает read-only историю по ДС для строки [estimates].
  static Future<void> show(
    BuildContext context, {
    required String contractId,
    required String estimateTitle,
    required String estimateRowId,
    required String rowSubtitle,
  }) async {
    final req = EstimatePositionHistoryRequest(
      contractId: contractId,
      estimateTitle: estimateTitle,
      estimateRowId: estimateRowId,
    );

    final body = EstimatePositionAddendumHistoryBody(
      request: req,
      rowSubtitle: rowSubtitle,
    );

    final footer = Align(
      alignment: Alignment.centerRight,
      child: GTSecondaryButton(
        text: 'Закрыть',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );

    final isLarge = MediaQuery.sizeOf(context).width > 900;

    if (isLarge) {
      await DesktopDialogContent.show<void>(
        context,
        title: 'История по ДС',
        width: 560,
        footer: footer,
        onClose: () => Navigator.of(context).maybePop(),
        child: body,
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final sheetFooter = Align(
            alignment: Alignment.centerRight,
            child: GTSecondaryButton(
              text: 'Закрыть',
              onPressed: () => Navigator.of(ctx).maybePop(),
            ),
          );
          return MobileBottomSheetContent(
            title: 'История по ДС',
            footer: sheetFooter,
            child: body,
          );
        },
      );
    }
  }
}
