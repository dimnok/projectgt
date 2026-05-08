import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/utils/snackbar_utils.dart';
import 'package:projectgt/core/widgets/desktop_dialog_content.dart';
import 'package:projectgt/core/widgets/gt_buttons.dart';
import 'package:projectgt/core/widgets/gt_section_title.dart';
import 'package:projectgt/domain/entities/contract.dart';
import 'package:projectgt/features/company/presentation/providers/company_providers.dart';
import 'package:projectgt/features/estimates/presentation/providers/estimate_providers.dart';
import 'package:projectgt/features/roles/presentation/widgets/permission_guard.dart';

/// Строка списка ДС по данным [estimate_revisions] / [estimate_revision_items].
///
/// [displayIndex] — порядковый номер в списке по договору (1, 2, 3…).
/// [deltaTotal] — разница суммы позиций этой ревизии и ревизии
/// из поля `based_on_revision_id` в БД (основная или предыдущая); `null`, если
/// сумма базы не найдена.
class ContractAddendumDisplayRow {
  /// Порядковый номер строки в UI (глобально по договору).
  final int displayIndex;

  /// Дата для отображения в списке: `effective_from`, иначе подписание/создание.
  final DateTime displayDate;

  /// Название сметы (заголовок файла).
  final String estimateTitle;

  /// Метка ревизии из БД (например «ДС-1»).
  final String revisionLabel;

  /// Статус ревизии: draft / approved / archived.
  final String status;

  /// Идентификатор ревизии в БД (для «Применить к смете» и правок метаданных).
  final String revisionId;

  /// Краткое описание ДС (поле `user_description`).
  final String? userDescription;

  /// Дата действия ДС (`effective_from`).
  final DateTime? effectiveFrom;

  /// Момент переноса строк ДС в основную таблицу `estimates` (`null` — ещё не применено).
  final DateTime? appliedToEstimatesAt;

  /// Сумма по строкам этой ревизии.
  final double revisionTotal;

  /// Разница суммы этой ревизии и суммы ревизии из `based_on_revision_id` в БД.
  final double? deltaTotal;

  /// Создаёт строку отображения ДС.
  const ContractAddendumDisplayRow({
    required this.displayIndex,
    required this.displayDate,
    required this.estimateTitle,
    required this.revisionLabel,
    required this.status,
    required this.revisionId,
    this.userDescription,
    this.effectiveFrom,
    this.appliedToEstimatesAt,
    required this.revisionTotal,
    required this.deltaTotal,
  });
}

/// Загружает доп. соглашения по договору из таблиц ревизий смет.
final contractAddendumRowsProvider = FutureProvider.autoDispose
    .family<List<ContractAddendumDisplayRow>, String>((ref, contractId) async {
      final companyId = ref.watch(activeCompanyIdProvider);
      if (companyId == null || companyId.isEmpty) {
        return const [];
      }

      final client = ref.watch(supabaseClientProvider);

      final revResponse = await client
          .from('estimate_revisions')
          .select(
            'id, estimate_title, revision_label, status, created_at, approved_at, effective_from, based_on_revision_id, user_description, applied_to_estimates_at',
          )
          .eq('company_id', companyId)
          .eq('contract_id', contractId)
          .eq('revision_type', 'addendum')
          .order('created_at', ascending: true);

      final revList = (revResponse as List).cast<Map<String, dynamic>>();
      if (revList.isEmpty) {
        return const [];
      }

      final revisionIds = <String>{};
      final basedOnIds = <String>{};
      for (final r in revList) {
        final id = r['id']?.toString();
        if (id != null && id.isNotEmpty) {
          revisionIds.add(id);
        }
        final bo = r['based_on_revision_id']?.toString();
        if (bo != null && bo.isNotEmpty) {
          basedOnIds.add(bo);
        }
      }

      final allIdsForSums = {...revisionIds, ...basedOnIds};
      if (allIdsForSums.isEmpty) {
        return const [];
      }

      final sums = <String, double>{};
      const chunk = 80;
      final idList = allIdsForSums.toList();
      for (var i = 0; i < idList.length; i += chunk) {
        final slice = idList.sublist(
          i,
          i + chunk > idList.length ? idList.length : i + chunk,
        );
        final itemsResponse = await client
            .from('estimate_revision_items')
            .select('revision_id, total')
            .eq('company_id', companyId)
            .inFilter('revision_id', slice);

        for (final row in itemsResponse as List) {
          final m = row as Map<String, dynamic>;
          final rid = m['revision_id']?.toString() ?? '';
          final t = (m['total'] as num?)?.toDouble() ?? 0.0;
          sums[rid] = (sums[rid] ?? 0) + t;
        }
      }

      DateTime? parseDateOnly(dynamic v) {
        if (v == null) return null;
        final s = v.toString().trim();
        if (s.isEmpty) return null;
        final normalized = s.length <= 10 ? '${s}T00:00:00' : s;
        return DateTime.tryParse(normalized);
      }

      DateTime? parseTimestamptz(dynamic v) {
        if (v == null) return null;
        final s = v.toString().trim();
        if (s.isEmpty) return null;
        return DateTime.tryParse(s);
      }

      DateTime displayDateFor(Map<String, dynamic> r) {
        final eff = parseDateOnly(r['effective_from']);
        if (eff != null) {
          return DateTime(eff.year, eff.month, eff.day);
        }
        final approved = r['approved_at'];
        if (approved != null) {
          final d = DateTime.tryParse(approved.toString());
          if (d != null) return d;
        }
        final c = r['created_at'];
        return DateTime.tryParse(c?.toString() ?? '') ?? DateTime.now();
      }

      final out = <ContractAddendumDisplayRow>[];
      var displayIndex = 0;
      for (final r in revList) {
        displayIndex++;
        final id = r['id']!.toString();
        final basedOn = r['based_on_revision_id']?.toString();
        final revTotal = sums[id] ?? 0.0;
        double? delta;
        if (basedOn != null && basedOn.isNotEmpty) {
          final prev = sums[basedOn];
          if (prev != null) {
            delta = revTotal - prev;
          }
        }

        final descRaw = r['user_description']?.toString().trim();
        final userDescription = descRaw != null && descRaw.isNotEmpty
            ? descRaw
            : null;

        final effParsed = parseDateOnly(r['effective_from']);
        final effectiveFromCal = effParsed == null
            ? null
            : DateTime(effParsed.year, effParsed.month, effParsed.day);

        out.add(
          ContractAddendumDisplayRow(
            displayIndex: displayIndex,
            displayDate: displayDateFor(r),
            estimateTitle:
                (r['estimate_title'] as String?)?.trim().isNotEmpty == true
                ? (r['estimate_title'] as String).trim()
                : 'Без названия',
            revisionLabel:
                (r['revision_label'] as String?)?.trim().isNotEmpty == true
                ? (r['revision_label'] as String).trim()
                : 'ДС',
            status: (r['status'] as String?)?.trim() ?? 'draft',
            revisionId: id,
            userDescription: userDescription,
            effectiveFrom: effectiveFromCal,
            appliedToEstimatesAt: parseTimestamptz(
              r['applied_to_estimates_at'],
            ),
            revisionTotal: revTotal,
            deltaTotal: delta,
          ),
        );
      }

      return out;
    });

/// Список доп. соглашений по договору из ревизий смет (таблицы `estimate_revisions`).
///
/// Используется на вкладке «Доп. соглашения» и в полной карточке договора.
/// Заголовок вкладки на десктопе — в [ContractDetailsPanel] (как у «Сметы»);
/// при [showSectionHeader] внутри секции остаётся только подпись блока в карточке.
class ContractAddendaFromRevisionsSection extends ConsumerWidget {
  /// Совпадает с подписью в toolbar встроенной детали договора.
  static const String embeddedScreenTitle =
      'Дополнительные соглашения по договору';

  /// Договор, для которого строится список.
  final Contract contract;

  /// Показать подпись блока над списком (в полной карточке договора без дубля toolbar).
  final bool showSectionHeader;

  /// Создаёт секцию списка ДС по [contract].
  const ContractAddendaFromRevisionsSection({
    super.key,
    required this.contract,
    this.showSectionHeader = true,
  });

  static String _formatSignedDelta(double? delta) {
    if (delta == null) {
      return '—';
    }
    if (delta.abs() < 0.005) {
      return formatCurrency(0);
    }
    final abs = formatCurrency(delta.abs());
    if (delta > 0) {
      return '+ $abs';
    }
    return '− $abs';
  }

  static Color _deltaColor(ThemeData theme, double? delta) {
    if (delta == null) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.45);
    }
    if (delta > 0.005) {
      return theme.brightness == Brightness.dark
          ? const Color(0xFF69F0AE)
          : const Color(0xFF1B5E20);
    }
    if (delta < -0.005) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.onSurface.withValues(alpha: 0.55);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(contractAddendumRowsProvider(contract.id));

    final listBody = async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SelectableText(
          'Не удалось загрузить доп. соглашения: $e',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                ),
              _AddendumOneLineRow(
                contract: contract,
                row: rows[i],
                theme: theme,
                formatSignedDelta: _formatSignedDelta,
                deltaColor: _deltaColor,
              ),
            ],
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showSectionHeader) ...[
          const GTSectionTitle(title: embeddedScreenTitle),
          const SizedBox(height: 8),
        ],
        listBody,
      ],
    );
  }
}

Future<bool> _showApplyDsConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: DesktopDialogContent(
          title: 'Применить ДС к смете?',
          width: 480,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GTSecondaryButton(
                text: 'Отмена',
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              const SizedBox(width: 12),
              GTPrimaryButton(
                text: 'Применить',
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
          child: Text(
            'Строки основной сметы по этому договору и заголовку сметы будут '
            'приведены в соответствие с данными этого ДС. При расхождении с '
            'текущими строками сметы побеждают данные ДС (в т.ч. после ручных правок).',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
        ),
      );
    },
  );
  return result == true;
}

class _AddendumOneLineRow extends StatelessWidget {
  const _AddendumOneLineRow({
    required this.contract,
    required this.row,
    required this.theme,
    required this.formatSignedDelta,
    required this.deltaColor,
  });

  final Contract contract;
  final ContractAddendumDisplayRow row;
  final ThemeData theme;
  final String Function(double? delta) formatSignedDelta;
  final Color Function(ThemeData theme, double? delta) deltaColor;

  @override
  Widget build(BuildContext context) {
    final dateStr = formatRuDate(row.displayDate);
    final title =
        'Дополнительное соглашение №${row.displayIndex} (${row.revisionLabel})';
    final deltaStr = formatSignedDelta(row.deltaTotal);
    final statusSuffix = row.status == 'approved'
        ? ''
        : row.status == 'draft'
        ? ' · черновик'
        : ' · ${row.status}';
    final applied = row.appliedToEstimatesAt;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Tooltip(
        message:
            'Смета: ${row.estimateTitle}\nСумма по ревизии: ${formatCurrency(row.revisionTotal)}$statusSuffix',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    dateStr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  deltaStr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: deltaStr == '—'
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
                        : deltaColor(theme, row.deltaTotal),
                  ),
                ),
              ],
            ),
            if (row.userDescription != null &&
                row.userDescription!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                row.userDescription!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (applied != null)
                  Text(
                    'В смете · ${formatRuDateTime(applied)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const Spacer(),
                _AddendumRevisionToolbar(contract: contract, row: row),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddendumRevisionToolbar extends ConsumerStatefulWidget {
  const _AddendumRevisionToolbar({required this.contract, required this.row});

  final Contract contract;
  final ContractAddendumDisplayRow row;

  @override
  ConsumerState<_AddendumRevisionToolbar> createState() =>
      _AddendumRevisionToolbarState();
}

class _AddendumRevisionToolbarState
    extends ConsumerState<_AddendumRevisionToolbar> {
  bool _busy = false;

  Future<void> _apply() async {
    if (!context.mounted) return;
    final ok = await _showApplyDsConfirmationDialog(context);
    if (!ok || !context.mounted) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(estimateRepositoryProvider);
      final result = await repo.applyAddendumRevisionToEstimates(
        revisionId: widget.row.revisionId,
      );
      if (!mounted) return;
      final s = result.summary;
      SnackBarUtils.showSuccess(
        context,
        'ДС применено к смете: обновлено ${s.updated}, добавлено ${s.inserted}.',
      );
      final cid = widget.contract.id;
      ref.invalidate(contractAddendumRowsProvider(cid));
      ref.invalidate(contractEstimatesProvider(cid));
      ref.invalidate(contractEstimateFilesProvider(cid));
      ref.invalidate(estimateGroupsProvider);
      ref.invalidate(contractVorCompletionProvider(cid));
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(context, '$e');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApply = widget.row.appliedToEstimatesAt == null;
    if (!canApply) {
      return const SizedBox.shrink();
    }
    return PermissionGuard(
      module: 'estimates',
      permission: 'update',
      child: GTSecondaryButton(
        text: 'Применить к смете',
        onPressed: _busy ? null : _apply,
      ),
    );
  }
}
