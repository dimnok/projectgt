import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectgt/core/widgets/gt_dropdown.dart';
import 'package:projectgt/core/utils/formatters.dart';
import 'package:projectgt/core/di/providers.dart';
import 'package:projectgt/domain/entities/contract_act_ks2_preview.dart';
import 'package:projectgt/domain/entities/vor.dart';
import 'package:projectgt/core/utils/supabase_function_error.dart';
import 'package:projectgt/features/contracts/presentation/providers/contract_act_ks2_providers.dart';

/// Таблица позиций КС-2 по выбранной утверждённой ВОР (данные превью `ks2_operations`).
///
/// Используется в форме «Акт КС-2» в модуле «Договоры»; не тянет провайдеры модуля «Сметы».
class ContractKs2VorPositionsSection extends ConsumerStatefulWidget {
  /// Создаёт секцию таблицы по ВОР.
  const ContractKs2VorPositionsSection({super.key, required this.contractId});

  /// Идентификатор договора.
  final String contractId;

  @override
  ConsumerState<ContractKs2VorPositionsSection> createState() =>
      ContractKs2VorPositionsSectionState();
}

/// Состояние [ContractKs2VorPositionsSection] (для [GlobalKey] при выгрузке Excel).
class ContractKs2VorPositionsSectionState
    extends ConsumerState<ContractKs2VorPositionsSection> {
  Vor? _selectedVor;
  ContractActKs2Preview? _preview;
  bool _loading = false;
  String? _error;

  /// Выбранная утверждённая ВОР (`null`, если не выбрана).
  String? get selectedVorId => _selectedVor?.id;

  Future<void> _loadPreview(String vorId) async {
    setState(() {
      _loading = true;
      _error = null;
      _preview = null;
    });
    try {
      final repo = ref.read(contractActRepositoryProvider);
      final data = await repo.previewKs2(
        contractId: widget.contractId,
        vorId: vorId,
      );
      if (!mounted) return;
      setState(() {
        _preview = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = formatInvokeErrorMessage(e);
        _loading = false;
        _preview = null;
      });
    }
  }

  void _onVorChanged(Vor? vor) {
    setState(() {
      _selectedVor = vor;
      _preview = null;
      _error = null;
    });
    if (vor != null) {
      unawaited(_loadPreview(vor.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vorsAsync = ref.watch(
      contractActApprovedVorsProvider(widget.contractId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Позиции по утверждённой ведомости ВОР (в акт входят только строки без '
          'превышения сметы — как при формировании акта).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.62),
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: vorsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            'Не удалось загрузить ВОР: $e',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
          ),
          data: (approved) {
                if (_selectedVor != null &&
                    !approved.any((v) => v.id == _selectedVor!.id)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _selectedVor = null;
                      _preview = null;
                    });
                  });
                }
                if (approved.isEmpty) {
                  return Text(
                    'Нет утверждённых ВОР без сохранённого акта КС-2 по этому договору.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GTDropdown<Vor>(
                      items: approved,
                      itemDisplayBuilder: (v) =>
                          'ВОР №${v.number} (${formatRuDate(v.startDate)} — ${formatRuDate(v.endDate)})',
                      labelText: 'Ведомость ВОР',
                      hintText: 'Выберите ВОР для таблицы',
                      selectedItem: _selectedVor,
                      onSelectionChanged: _onVorChanged,
                      prefixIcon: CupertinoIcons.doc_text,
                      allowClear: true,
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 16),
                      const Center(child: CircularProgressIndicator()),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.error,
                        ),
                      ),
                    ],
                    if (!_loading && _preview != null) ...[
                      const SizedBox(height: 12),
                      Expanded(
                        child: _Ks2PositionsTable(
                          preview: _preview!,
                          scheme: scheme,
                          theme: theme,
                        ),
                      ),
                    ],
                  ],
                );
          },
        ),
      ),
      ],
    );
  }
}

class _Ks2PositionsTable extends StatefulWidget {
  const _Ks2PositionsTable({
    required this.preview,
    required this.scheme,
    required this.theme,
  });

  final ContractActKs2Preview preview;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  State<_Ks2PositionsTable> createState() => _Ks2PositionsTableState();
}

class _Ks2PositionsTableState extends State<_Ks2PositionsTable> {
  static const double _wNo = 88;
  static const double _wUnit = 72;
  static const double _wQty = 96;
  static const double _wPrice = 112;
  static const double _wSum = 128;
  static const double _minName = 200;

  static double get _minTableWidth =>
      _wNo + _minName + _wUnit + _wQty + _wPrice + _wSum;

  late final ScrollController _verticalScroll = ScrollController();
  late final ScrollController _horizontalScroll = ScrollController();

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  List<_Ks2PreviewRow> get _rows {
    return widget.preview.candidates.map((c) {
      final m = Map<String, dynamic>.from(c as Map);
      return _Ks2PreviewRow(
        sectionTitle: '${m['sectionTitle'] ?? ''}'.trim(),
        estimateNumber: '${m['estimateNumber'] ?? ''}'.trim().isEmpty
            ? '—'
            : '${m['estimateNumber']}'.trim(),
        name: (m['name'] ?? '—').toString(),
        unit: (m['unit'] ?? '—').toString(),
        quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
        price: (m['price'] as num?)?.toDouble() ?? 0,
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  /// Группирует строки по разделу сметы ([_Ks2PreviewRow.sectionTitle] / поле `sectionTitle` в API).
  List<_Ks2SectionBucket> _bucketsBySection(List<_Ks2PreviewRow> rows) {
    final buckets = <_Ks2SectionBucket>[];
    for (final r in rows) {
      final key = r.sectionTitle.isEmpty ? '—' : r.sectionTitle;
      if (buckets.isEmpty || buckets.last.sectionKey != key) {
        buckets.add(_Ks2SectionBucket(sectionKey: key)..rows.add(r));
      } else {
        buckets.last.rows.add(r);
      }
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final scheme = widget.scheme;
    final theme = widget.theme;

    if (rows.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
          color: scheme.surfaceContainerLow.withValues(alpha: 0.35),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Нет строк для акта (все позиции исключены: превышение сметы или нет '
            'привязки к смете).',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }

    final borderColor = scheme.outline.withValues(alpha: 0.2);
    return LayoutBuilder(
      builder: (context, constraints) {
        var availW = constraints.maxWidth;
        if (!availW.isFinite || availW <= 0) {
          availW = MediaQuery.sizeOf(context).width * 0.72;
        }
        final tableWidth = math.max(availW, _minTableWidth);
        final needsHorizontalScroll = availW < _minTableWidth;

        final sections = _bucketsBySection(rows);

        const columnWidths = {
          0: FixedColumnWidth(_wNo),
          1: FlexColumnWidth(1),
          2: FixedColumnWidth(_wUnit),
          3: FixedColumnWidth(_wQty),
          4: FixedColumnWidth(_wPrice),
          5: FixedColumnWidth(_wSum),
        };

        final stackChildren = <Widget>[
          Table(
            border: TableBorder.all(color: borderColor),
            columnWidths: columnWidths,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                ),
                children: [
                  _th(theme, scheme, '№'),
                  _th(theme, scheme, 'Наименование работ и затрат'),
                  _th(theme, scheme, 'Ед. изм.'),
                  _th(theme, scheme, 'Кол-во'),
                  _th(theme, scheme, 'Цена за ед., ₽'),
                  _th(theme, scheme, 'Сумма, ₽'),
                ],
              ),
            ],
          ),
        ];

        for (final sec in sections) {
          final showHeading = sections.length > 1 || sec.sectionKey != '—';
          if (showHeading) {
            stackChildren.add(
              _sectionHeading(theme, scheme, borderColor, sec.displayTitle),
            );
          }
          stackChildren.add(
            Table(
              border: TableBorder.all(color: borderColor),
              columnWidths: columnWidths,
              children: [
                for (final r in sec.rows) _buildDataTableRow(theme, scheme, r),
                _buildSectionTotalRow(
                  theme,
                  scheme,
                  sec.rows.fold<double>(0, (s, r) => s + r.amount),
                ),
              ],
            ),
          );
        }

        final table = SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: stackChildren,
          ),
        );

        final scrollableTable = needsHorizontalScroll
            ? Scrollbar(
                controller: _horizontalScroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: table,
                ),
              )
            : table;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.25),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _verticalScroll,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalScroll,
                      scrollDirection: Axis.vertical,
                      primary: false,
                      child: scrollableTable,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.12),
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Итого:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        formatCurrency(widget.preview.totalAmount),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildSectionTotalRow(
    ThemeData theme,
    ColorScheme scheme,
    double sectionTotal,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.28),
      ),
      children: [
        _td(theme, scheme, ''),
        _td(
          theme,
          scheme,
          'Итого по разделу:',
          align: TextAlign.end,
          strong: true,
        ),
        _td(theme, scheme, ''),
        _td(theme, scheme, ''),
        _td(theme, scheme, ''),
        _td(
          theme,
          scheme,
          formatCurrency(sectionTotal),
          align: TextAlign.end,
          strong: true,
        ),
      ],
    );
  }

  TableRow _buildDataTableRow(
    ThemeData theme,
    ColorScheme scheme,
    _Ks2PreviewRow r,
  ) {
    return TableRow(
      children: [
        _td(
          theme,
          scheme,
          r.estimateNumber,
          align: TextAlign.center,
          wrap: true,
        ),
        _td(theme, scheme, r.name, align: TextAlign.start, wrap: true),
        _td(theme, scheme, r.unit, align: TextAlign.center),
        _td(theme, scheme, formatQuantity(r.quantity), align: TextAlign.end),
        _td(theme, scheme, formatAmount(r.price), align: TextAlign.end),
        _td(
          theme,
          scheme,
          formatAmount(r.amount),
          align: TextAlign.end,
          strong: true,
        ),
      ],
    );
  }

  /// Заголовок блока раздела сметы над строками таблицы.
  Widget _sectionHeading(
    ThemeData theme,
    ColorScheme scheme,
    Color borderColor,
    String title,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.42),
        border: Border(
          left: BorderSide(color: borderColor),
          right: BorderSide(color: borderColor),
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _th(ThemeData theme, ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          height: 1.2,
          color: scheme.onSurface.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _td(
    ThemeData theme,
    ColorScheme scheme,
    String text, {
    TextAlign align = TextAlign.start,
    bool strong = false,
    bool wrap = false,
  }) {
    final cell = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        softWrap: wrap,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: cell,
    );
  }
}

class _Ks2SectionBucket {
  /// [sectionKey] — значение `sectionTitle` из API (пустое нормализуется в «—»).
  _Ks2SectionBucket({required this.sectionKey});

  /// Ключ группировки (как в JSON).
  final String sectionKey;

  /// Строки раздела.
  final List<_Ks2PreviewRow> rows = [];

  /// Подпись для UI.
  String get displayTitle =>
      sectionKey == '—' ? 'Без названия раздела' : sectionKey;
}

class _Ks2PreviewRow {
  const _Ks2PreviewRow({
    required this.sectionTitle,
    required this.estimateNumber,
    required this.name,
    required this.unit,
    required this.quantity,
    required this.price,
    required this.amount,
  });

  /// Название раздела сметы (`estimates.estimate_title`), из Edge `ks2_operations`.
  final String sectionTitle;

  /// Номер позиции как в смете (`estimates.number`).
  final String estimateNumber;
  final String name;
  final String unit;
  final double quantity;
  final double price;
  final double amount;
}
